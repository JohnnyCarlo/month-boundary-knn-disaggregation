
%% disaggregation of one realization (threadsafe, called in parfor)
function [sim_daily_flows, diagnostics] = MBKNN_disagg_1_ensemble(sim_monthly_flows, disagg_pattern_database, realization_num, elig_candidates, options)

%% predim and predim
num_flows = size(sim_monthly_flows, 2);
num_sim_months = size(sim_monthly_flows, 1);
num_sim_years = num_sim_months ./ 12;
num_sim_days = num_sim_years * 365;
sim_daily_flows = nan(num_sim_days, num_flows);

diagnostics_element.candidates = [];
diagnostics_element.num_stepbacks = [];
diagnostics_element.accept_power = [];
diagnostics_element.selection = [];
diagnostics = cell(num_sim_months, 1);

%% helper variables

% # days in month
if options.WaterYears
    ndim = repmat([31 30 31 31 28 31 30 31 30 31 31 30 ]', num_sim_years, 1);
else
    ndim = repmat([31 28 31 30 31 30 31 31 30 31 30 31]', num_sim_years, 1);
end

% first and last days of each month in each sim year
fd = zeros(num_sim_months, 1);
ld = zeros(num_sim_months, 1);
ld(1) = 31;
fd(1) = 1;
for monthnum=2:num_sim_months
    fd(monthnum) = fd(monthnum-1) + ndim(monthnum-1);
    ld(monthnum) = ld(monthnum-1) + ndim(monthnum);
end
    
%% set up stepback counters and probabilities
num_stepbacks = zeros(num_sim_months, 1);
accept_powers = ones(num_sim_months, 1) .* options.disagg.pi_val;

%% step through months
monthnum = 1;

while monthnum <= num_sim_months

    % month number
    if options.WaterYears
        wi = monthnum+9;
        if wi > 12
            wi = wi - 12;
        end
        m = mod(wi,12);
    else
        m = mod(monthnum,12);
    end
    if m == 0
        m = 12;
    end
    this_db = disagg_pattern_database{m};

    this_sim_monthly_inflows = sim_monthly_flows(monthnum,:);
    if monthnum == 1
        this_sim_lastday_inflows = []; %= zeros(1, num_inflows);
    else
        this_sim_lastday_inflows = sim_daily_flows(ld(monthnum-1),:);
    end
    
    % get candidates
    candidate_indices = MBKNN_identify_neighbors(this_sim_monthly_inflows, ...
        this_sim_lastday_inflows, this_db, elig_candidates{monthnum}, options);

    % check for and update stepbacks
    if options.disagg.inline_active
        [stepbackyn, num_stepbacks, accept_powers, monthnum] = MBKNN_check_for_stepback(candidate_indices, num_stepbacks, ...
            accept_powers, options, monthnum, realization_num);
        if stepbackyn
    
            % once we step forward again, reset eligibility
            elig_candidates{monthnum}.Eligible = true(size(elig_candidates{monthnum}.Eligible));
            monthnum = monthnum - 1;
            continue;
        end
    end

    % select pattern
    [selection_index, candidate_indices] = MBKNN_select_pattern(candidate_indices, options, monthnum);
    ix = candidate_indices.CandidateRownum == selection_index;
    disp(['     selected index: ' int2str(selection_index) '    centrality score: ' num2str(candidate_indices.CentralityScore(ix), '%5.3f') ]);

    % when pattern selected, cannot be reconsidered on a stepback
    elig_candidates{monthnum}.Eligible(selection_index) = false;
    
    % disaggregate (remove monthly offset first)
    pattern = squeeze(this_db.patterns_ratios(selection_index,:,:));
    monthly_flows_remove_offset = this_sim_monthly_inflows; % - options.disagg.monthflowoffset;
    sim_daily_flows(fd(monthnum):ld(monthnum),:) = repmat(monthly_flows_remove_offset, ndim(monthnum), 1) .* pattern;

    if options.disagg.diagnosticsYN
    
        this_diagnostics_element = diagnostics_element;
        this_diagnostics_element.candidates = candidate_indices;
            
        this_diagnostics_element.num_stepbacks = num_stepbacks(monthnum);
        this_diagnostics_element.accept_power = accept_powers(monthnum);
        this_diagnostics_element.selection = selection_index;
        diagnostics{monthnum} = this_diagnostics_element;
    end

    if options.disagg.verbose
        disp(['Stepping ahead to month ' int2str(monthnum+1) ' of realization ' int2str(realization_num)]);
    end
    monthnum = monthnum + 1;
    
end
