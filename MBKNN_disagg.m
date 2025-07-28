function [DailySim, disagg_diagnostics] = MBKNN_disagg(MonthlySimSum, DailyHist, options)

%% we don't need WaterYear Columns here
DailyHist.WaterYear = [];

%% dimension
num_sim_realizations = numel(MonthlySimSum);	
num_hist_days = size(DailyHist, 1);	
numflows = numel(options.Gages_to_use);

num_hist_years = num_hist_days ./ 365;
num_sim_months = size(MonthlySimSum{1}, 1);
num_sim_years = num_sim_months ./ 12;

%% set up historical inflow data for disaggregation

disp('Setting up disaggregation database...');
tic

% disaggregation database
disagg_pattern_database = cell(12,1);

% flows from timetable to matrix
DailyHist_mat = table2array(DailyHist);
MonthlySimSum_mat = cell(num_sim_realizations, 1);
for s = 1:num_sim_realizations
    MonthlySimSum_mat{s} = table2array(MonthlySimSum{s});
end

% daily seasonal position matrix
dates = DailyHist.Date;
seasvec = [dates.Month, dates.Day, repmat((1:365)', num_hist_years, 1)];
seasvec365 = seasvec(1:365, :);

% we will cycle through the three different month lengths
NDAY = [31, 30, 28];
mths = {[1 3 5 7 8 10 12], [4 6 9 11], 2};

% we will apply an offset to prevent zeros in denominators
% for m = 1:3
%     ix = ismember(DailyHist.Date.Month, mths{m});
%     DailyHist_mat(ix,:) = DailyHist_mat(ix,:) + (options.disagg.monthflowoffset)/NDAY(m);
% end

% cycle through month lengths
for i = 1:3

    disp(['    ' int2str(NDAY(i)) '-day months']);

    % flows
    nday = NDAY(i);
    nstep = nday-1;

    patternzeros = NaN(num_hist_days-nstep, nday, numflows);
    patternflows = NaN(num_hist_days-nstep, nday, numflows);

    for fd = 1:nday
        ld = fd + num_hist_days - nday;
        patternflows(:,fd,:) = DailyHist_mat(fd:ld,:);
        patternzeros(:,fd,:) = DailyHist_mat(fd:ld,:) == 0;
    end

    % dates of fds
    patterndates = dates(1:num_hist_days-nstep);

    % season vector
    patternseasvec = seasvec(1:num_hist_days-nstep, :);

    % monthly sums of fds
    pattern_sum = squeeze(sum(patternflows, 2));
    pattern_sum0 = squeeze(sum(patternzeros, 2));

    % first daily flows
    firstflows = squeeze(patternflows(:,1,:));

    % flow changes
    flowchanges = NaN(size(firstflows));
    flowchanges(2:end,:) = firstflows(2:end,:) - firstflows(1:end-1,:);

    % patterns
    patterns_d2m_fractions = NaN(size(patternflows));
    for d = 1:nday
        patterns_d2m_fractions(:,d,:) = squeeze(patternflows(:,d,:)) ./ pattern_sum;
    end

    % zap patterns that are not "clean"
    ix = sum(isnan(pattern_sum), 2) > 0 ...
        | max(pattern_sum0, [], 2) > options.disagg.dailyZeroLimit ...
        | sum(isnan(firstflows), 2) > 0 ...
        | sum(isnan(flowchanges), 2) > 0 ...
        | sum(isnan(patterns_d2m_fractions), [3 2]) > 0;
    patterndates(ix) = [];
    pattern_sum(ix,:) = [];
    firstflows(ix,:) = [];
    flowchanges(ix,:) = [];
    patterns_d2m_fractions(ix,:,:) = [];
    this_seasvec = patternseasvec;
    this_seasvec(ix,:) = [];
    patternflows(ix,:,:) = [];

    % the list of months with this length
    this_mths = mths{i};

    % cycle through months
    for m = 1:numel(this_mths)

        disp(['        Month ' int2str(this_mths(m))]);

        % identify dates for +/- window
        ix = seasvec365(:,1) == this_mths(m) & seasvec365(:,2) == 1;
        this_fd = seasvec365(ix, 3) - options.disagg.w;
        ix = seasvec365(:,1) == this_mths(m) & seasvec365(:,2) == nday;
        this_ld = seasvec365(ix, 3) + options.disagg.w;
        
        if this_fd < 1
            this_fd = this_fd + 365;
            rows = [this_fd:365, 1:this_ld]';
        elseif this_ld > 365
            this_ld = this_ld - 365;
            rows = [this_fd:365, 1:this_ld]';
        else
            rows = (this_fd:this_ld)';
        end

        % get the rows for potential candidates
        indices = ismember(this_seasvec(:,3), rows);

        % build this month's database
        disagg_pattern_element.m = this_mths(m);
        disagg_pattern_element.Month = string(datetime(2000, this_mths(m), 1, 'Format', 'MMMM'));
        disagg_pattern_element.patterns_ratios = patterns_d2m_fractions(indices,:,:);
        disagg_pattern_element.date = patterndates(indices);  
        disagg_pattern_element.pattern_sums = pattern_sum(indices,:); 
        disagg_pattern_element.firstflows = firstflows(indices,:);
        disagg_pattern_element.flowchanges = flowchanges(indices,:);
        disagg_pattern_element.patternflows = patternflows(indices,:,:);
        disagg_pattern_database{this_mths(m)} = disagg_pattern_element;
    end
end

%% do the PCAs and standardization on the flowchanges here
% store the weights, mu, and sigma to apply to candidates
for m = 1:12
    
    % PCA first (don't center)
    [coeffs, scores, ~, ~, ~] = pca(disagg_pattern_database{m}.flowchanges, 'Centered',false);
    
    % standardize 
    mu = mean(scores, "omitmissing");
    sigma = std(scores, "omitmissing");
    scores_STD = (scores - repmat(mu, size(scores, 1), 1)) ./ repmat(sigma, size(scores, 1), 1);
    
    % keep the PC's we need
    if isempty(options.disagg.n_PC)
        keepix = true(numflows, 1);
    else
        keepix = false(numflows, 1);
        keepix(1:options.disagg.n_PC) = true;
    end

    disagg_pattern_database{m}.flowchangesPCA = scores(:,keepix);
    disagg_pattern_database{m}.flowchangesPCASTD = scores_STD(:,keepix);
    disagg_pattern_database{m}.flowchangesPCASTD_distances = sqrt(sum(scores_STD(:,keepix).^2, 2));
    disagg_pattern_database{m}.flowchangesPCA_coeffs = coeffs(:,keepix);
    disagg_pattern_database{m}.flowchangesPCA_mu = mu(keepix);
    disagg_pattern_database{m}.flowchangesPCA_sigma = sigma(keepix);

end
disp(['Build of disaggregation database took ' num2str(toc, '%4.1f') ' seconds.']);
 

%% predimension output
sim_daily_flows = nan(num_sim_realizations, num_sim_years.*365, numflows);

%% diagnostics
if options.disagg.diagnosticsYN
    disagg_diagnostics.disagg_pattern_database = disagg_pattern_database;
    diagnostics = cell(num_sim_realizations, 1);
else
    disagg_diagnostics = [];
end

%% keep track of eligible candidates on stepbacks
eligible_candidates = cell(num_sim_months, num_sim_realizations);
for i = 1:num_sim_months
    this_m = MonthlySimSum{1}.Date.Month(i);
    this_db = disagg_pattern_database{this_m};
    CandidateRownum = (1:size(this_db.date, 1))';
    Eligible = true(size(CandidateRownum));
    tt = table(CandidateRownum,Eligible);
    eligible_candidates(i,:) = repmat({tt}, 1, num_sim_realizations);
end


%% step through realizations and disaggregate - format as we go
for r=1:num_sim_realizations %1:num_sim_realizations
    t_real = tic;
    disp(['Disaggregating realization ' int2str(r) ' of ' int2str(num_sim_realizations)]);

    smf = MonthlySimSum_mat{r};
    ec = eligible_candidates(:,r);
    [sim_daily_flows(r,:,:), d] = MBKNN_disagg_1_ensemble(smf, disagg_pattern_database, r, ec, options);
    if options.disagg.diagnosticsYN
        diagnostics{r} = d;
    end

    disp(['Disaggregation of realization ' int2str(r) ' took ' num2str(toc(t_real), '%4.1f') ' seconds.']);
end

if options.disagg.diagnosticsYN
    disagg_diagnostics.ensemble_diagnostics = diagnostics;
end

%% format outputs
disp('Formatting Daily Output ...');
tic
dstart = min(MonthlySimSum{1}.Date);
dend = max(MonthlySimSum{1}.Date);
dstart.Day = 1;
if options.WaterYears  
    dend.Day = 30;
else
    dend.Day = 31;
end
Date = (dstart:dend)';
indices = Date.Month == 2 & Date.Day == 29;
Date(indices) = [];

vars = DailyHist.Properties.VariableNames;
DailySim = cell(num_sim_realizations, 1);
for r = 1:num_sim_realizations
    this_daily = squeeze(sim_daily_flows(r,:,:));
    this_daily = array2timetable(this_daily,"VariableNames",vars,"RowTimes",Date,"DimensionNames",{'Date', 'Variables'});
    DailySim{r} = this_daily;
end
disp(['     ... took ' int2str(toc) ' seconds.']);

