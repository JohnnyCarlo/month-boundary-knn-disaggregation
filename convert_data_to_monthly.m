function MonthlyHistSum_cellaray = convert_data_to_monthly(MonthlyHistSum, options)

%% handling water years
% the normal Kirch procedure produces monthly realizations for whole
% calendar years. we need to account for water years if needed
timecol = MonthlyHistSum.Properties.DimensionNames{1};
if options.WaterYears
    yearvec = MonthlyHistSum.WaterYear;
    monthorder = [10 11 12 1 2 3 4 5 6 7 8 9];
else
    yearvec = MonthlyHistSum.(timecol).Year;
    monthorder = (1:12);
end

%% dimension
sites = MonthlyHistSum.Properties.VariableNames;
ix = strcmp(sites, 'WaterYear');
sites(ix) = [];
num_sites = numel(sites);
hist_years = unique(yearvec);
num_hist_years = numel(hist_years);
MonthlyHistSum_cellaray = cell(num_sites, 1);
for i=1:num_sites
    MonthlyHistSum_cellaray{i} = zeros(num_hist_years, 12);
end


%% each of these cells is for a station with a matrix having 
% sequential months as columns and years as rows
% if we are doing water years
%   the columns should correspond to monthorder = [10 11 12 1 2 3 4 5 6 7 8 9]
% if we are doing calendar years the columns should correspond to monthorder = (1:12)
for year = 1:num_hist_years
    for month = 1:12
        ix = yearvec == hist_years(year) & MonthlyHistSum.(timecol).Month == monthorder(month);

        % average flow in each month
        for i=1:num_sites
            MonthlyHistSum_cellaray{i}(year,month) = MonthlyHistSum.(sites{i})(ix);
        end
    end
end

