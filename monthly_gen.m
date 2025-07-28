function one_monthly_ensemble = monthly_gen(MonthlyHistSum_cellaray, num_years_per_realization, options, p, n)

%% Input error checking
if iscell(MonthlyHistSum_cellaray)
    num_sites = length(MonthlyHistSum_cellaray);
else
    error(['MonthlyHistSum_cellaray must be a cell array, one cell per site, ' ...
        'each containing a 2-D matrix of num_hist_years x 12 monthly flows.']);
end

num_hist_years = length(MonthlyHistSum_cellaray{1}(:,1));
for i=2:num_sites
    if length(MonthlyHistSum_cellaray{i}(:,1)) ~= num_hist_years
        error('All matrices in MonthlyHistSum_cellaray must be the same size.');
    end
end

num_years_per_realization = num_years_per_realization+1; % this adjusts for the new corr technique
if nargin == 3
    nQ = num_hist_years;
elseif nargin == 5
    n = n-1; % (input n=2 to double the frequency, i.e. repmat 1 additional time)
    nQ = num_hist_years + floor(p*num_hist_years+1)*n;
else
    error('Incorrect number of arguments.');
end

%% use the same sample years for all stations... this preserves cross correlation
Random_Matrix = randi(nQ, num_years_per_realization, 12);

for k=1:num_sites
    this_station_historical_matrix = MonthlyHistSum_cellaray{k};
    
    % don't know what this does. we never use it
    if nargin == 4
        temp = sort(this_station_historical_matrix);
        append = temp(1:ceil(p*num_hist_years),:); % find lowest p% of values for each month
        this_station_historical_matrix = vertcat(this_station_historical_matrix, repmat(append, n, 1));
    end

    % offset for logs
    if options.monthlysim.logtransform
        if ~isempty(options.monthlysim.Data_offset_for_0_or_negative_flows)
            this_station_historical_matrix = this_station_historical_matrix ...
                + options.monthlysim.Data_offset_for_0_or_negative_flows;
        end
        modelspace_this_station_historical_matrix = log(this_station_historical_matrix);
    else
        modelspace_this_station_historical_matrix = this_station_historical_matrix;
    end

    monthly_modelspace_mean = zeros(1,12);
    monthly_modelspace_stdev = zeros(1,12);
    stdnorm_modelspace_uncorr_hist_matrix = zeros(nQ, 12);



    for i=1:12
        monthly_modelspace_mean(i) = mean(modelspace_this_station_historical_matrix(:,i));
        monthly_modelspace_stdev(i) = std(modelspace_this_station_historical_matrix(:,i));
        stdnorm_modelspace_uncorr_hist_matrix(:,i) = (modelspace_this_station_historical_matrix(:,i) - monthly_modelspace_mean(i)) / monthly_modelspace_stdev(i);
    end
    stdnorm_modelspace_uncorr_hist_vector = reshape(stdnorm_modelspace_uncorr_hist_matrix',1,[]);
    stdnorm_modelspace_uncorr_hist_matrix_shifted = reshape(stdnorm_modelspace_uncorr_hist_vector(7:(nQ*12-6)),12,[])';

    % The correlation matrices should use the historical Z's
    % (the "appended years" do not preserve correlation)
    U = chol_corr(stdnorm_modelspace_uncorr_hist_matrix(1:num_hist_years,:));
    U_shifted = chol_corr(stdnorm_modelspace_uncorr_hist_matrix_shifted(1:num_hist_years-1,:));

    % pull the Z-score samples from history
    for i=1:12
        stdnorm_modelspace_uncorr_sim_matrix(:,i) = stdnorm_modelspace_uncorr_hist_matrix(Random_Matrix(:,i), i);
    end

    stdnorm_modelspace_uncorr_sim_vector = reshape(stdnorm_modelspace_uncorr_sim_matrix(:,:)',1,[]);
    stdnorm_modelspace_uncorr_sim_matrix_shifted(:,:) = reshape(stdnorm_modelspace_uncorr_sim_vector(7:(num_years_per_realization*12-6)),12,[])';
    stdnorm_modelspace_corr_sim_matrix(:,:) = stdnorm_modelspace_uncorr_sim_matrix(:,:)*U;
    stdnorm_modelspace_corr_sim_matrix_shifted(:,:) = stdnorm_modelspace_uncorr_sim_matrix_shifted(:,:)*U_shifted;

    stdnorm_modelspace_sim(:,1:6) = stdnorm_modelspace_corr_sim_matrix_shifted(:,7:12);
    stdnorm_modelspace_sim(:,7:12) = stdnorm_modelspace_corr_sim_matrix(2:num_years_per_realization,7:12);

    for i=1:12
        if options.monthlysim.logtransform
            realspace_sim(:,i) = exp(stdnorm_modelspace_sim(:,i)*monthly_modelspace_stdev(i) + monthly_modelspace_mean(i));
             
            % offset for logs
            if ~isempty(options.monthlysim.Data_offset_for_0_or_negative_flows)
                realspace_sim = realspace_sim ...
                    - options.monthlysim.Data_offset_for_0_or_negative_flows;
            end
        else
            realspace_sim(:,i) = stdnorm_modelspace_sim(:,i)*monthly_modelspace_stdev(i) + monthly_modelspace_mean(i);
        end
    end
    one_monthly_ensemble{k} = realspace_sim;
end
    
end

