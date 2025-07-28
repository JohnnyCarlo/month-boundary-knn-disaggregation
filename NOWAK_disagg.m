function simulated_daily_flows = NOWAK_disagg(historical_daily_flows, simulated_monthly_flows, options)

%% we don't need WaterYear Columns here
historical_daily_flows.WaterYear = [];

%% dimension
num_sim_realizations = numel(simulated_monthly_flows);
num_sim_months = size(simulated_monthly_flows{1}, 1);
num_sim_years = num_sim_months ./ 12;
sim_Date = simulated_monthly_flows{1}.Date;

num_hist_days = size(historical_daily_flows, 1);	
inflow_names = options.Gages_to_use;
num_flows = numel(options.Gages_to_use);

%% build disaggregation database
plusminus = options.disagg.w;
ndim = [31 28 31 30 31 30 31 31 30 31 30 31];
historical_daily_flows_mat = table2array(historical_daily_flows);
all_candidate_indices = cell(12,1);
all_candidate_monthlies = cell(12,1);

for M = 1:12

    % identify day indices of candidates: starts and ends
    days_in_this_month = find(historical_daily_flows.Date.Month == M);
    start_days = days_in_this_month;
    for p = 1:plusminus
        backward = days_in_this_month - p;
        forward = days_in_this_month + p;
        start_days = [start_days;backward;forward];
    end
    start_days = unique(start_days);
    end_days = start_days + ndim(M) - 1;
    start_end_days = [start_days, end_days];
    ix = start_days < 1 | end_days > num_hist_days;
    start_end_days(ix,:) = [];

    % determine candidate monthly flows
    num_candidates = size(start_end_days, 1);
    candidate_monthlies = zeros(num_candidates, num_flows);
    
    for c = 1:num_candidates
        F = start_end_days(c,1);
        L = start_end_days(c,2);
        candidate_monthlies(c,:) = sum(historical_daily_flows_mat(F:L,:));
    end

    all_candidate_monthlies{M} = candidate_monthlies;
    all_candidate_indices{M} = start_end_days;

end

%% predimension output
DailyDate = [];
for m = 1:numel(sim_Date)
    thisM = sim_Date(m).Month;
    this_dim = ndim(thisM);
    DailyDate = [DailyDate;datetime(sim_Date.Year(m),thisM,(1:this_dim)')];
end
simulated_daily_flows = cell(num_sim_realizations,1);


%% disaggregate
for r = 1:num_sim_realizations
    
    disp(['NOWAK Disaggregation realization ' int2str(r) ' of ' int2str(num_sim_realizations)]);
    this_realization = simulated_monthly_flows{r};
    this_realization_mat = table2array(this_realization);
    one_daily_realization = NaN(num_sim_years.*365, num_flows);

    for M = 1:num_sim_months

        % this month of year
        thisM = this_realization.Date.Month(M);

        % monthly value for all sites
        this_sim_month_flows = this_realization_mat(M,:);

        % KNN and weights
        [knn_candidates, weights] = NOWAK_KNN_identification(this_sim_month_flows, all_candidate_monthlies{thisM}, all_candidate_indices{thisM}, options.disagg.k);
        cumulative_weight = cumsum(weights);
            
        % sampling of one KNN
        pattern = NOWAK_KNN_sampling(knn_candidates, all_candidate_indices{thisM}, cumulative_weight, historical_daily_flows_mat);
        
        % apply
        this_sim_daily_flows = pattern .* repmat(this_sim_month_flows, ndim(thisM), 1);
        indices = DailyDate.Year == this_realization.Date.Year(M) & DailyDate.Month == this_realization.Date.Month(M);
        one_daily_realization(indices,:) = this_sim_daily_flows;

        
    end
    one_daily_realization = array2timetable(one_daily_realization,"VariableNames",inflow_names,"RowTimes",DailyDate,"DimensionNames", {'Date', 'Variable'});
    simulated_daily_flows{r} = one_daily_realization;


end



