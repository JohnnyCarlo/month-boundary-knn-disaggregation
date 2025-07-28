function MonthlySimSum = monthly_main(MonthlyHistSum, options)

%% dimension
num_simulation_years = options.num_sim_years;
num_sim_realizations = options.num_realizations;
sitenames = MonthlyHistSum.Properties.VariableNames;
ix = strcmp(sitenames, 'WaterYear');
sitenames(ix) = [];
num_sites = numel(sitenames);

%% initialize monthly_realizations that contains monthly sims 
MonthlySimSum = cell(num_sim_realizations, 1);

%% convert historical flows to monthly and reshape
% historical_monthly_flows is cell(1, num_sites)
% each cell has a matrix num_historical_years x 12
MonthlyHistSum_cellaray = convert_data_to_monthly(MonthlyHistSum, options);

%% make monthly simulations
for r=1:num_sim_realizations    

    disp(['Creating monthly realization ' int2str(r)]);
    one_monthly_gage_ensemble = monthly_gen(MonthlyHistSum_cellaray, ...
        num_simulation_years, options); 

    % unpack the results
    for s=1:num_sites

        % get the site name
        this_site = sitenames{s};  

        % reshape and store the raw realization
        one_monthly_gage_realization = reshape(one_monthly_gage_ensemble{s}',[],1);
        MonthlySimSum{r}.(this_site) = one_monthly_gage_realization;

    end
end                                                                         

%% reshape to output matrix
simulation_years = (1:options.num_sim_years)';
if options.WaterYears
    monthvec = [(10:12),(1:9)]';
    monthvec = repmat(monthvec, num_simulation_years, 1);
    simulation_years = sort(repmat(simulation_years, 12, 1));
    ix = monthvec >= 10;
    simulation_years(ix) = simulation_years(ix) - 1;
else
    monthvec = repmat((1:12)', numel(simulation_years,1));
    simulation_years = sort(repmat(simulation_years, 12, 1));
end
dv = [simulation_years, monthvec];
dv(:,3) = 1;
Date = datetime(dv);

for r = 1:num_sim_realizations 

    disp(['Reshaping realization ' int2str(r)]);
    this_realization = struct2array(MonthlySimSum{r});
    this_realization = array2timetable(this_realization, 'Rowtimes', Date, 'VariableNames', sitenames, 'DimensionNames', {'Date', 'Variables'});
    MonthlySimSum{r} = this_realization;

end





