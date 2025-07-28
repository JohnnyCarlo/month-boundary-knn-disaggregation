function [DailyHist, MonthlyHistSum, options] = prep_hist_data_gage_flows(options)

%% DailyHist

% load multi-site observations of daily gage flow 
DailyHist = load('./data/Monthly and Daily Gage Flows/Historical_Daily_Gage_Data.mat');
DailyHist = DailyHist.Historical_Daily_Gage_Data;

% convert from cfs to kL/s
DailyHist = DailyHist .* 28.31685 ./ 1000;

% throw away leap year days
DaiyHist_dt = DailyHist.Properties.DimensionNames{1};
ix = DailyHist.(DaiyHist_dt).Month == 2 ...
    & DailyHist.(DaiyHist_dt).Day == 29;
DailyHist(ix,:) = [];

% keep only the gages we need
if ~isempty(options.Gages_to_use)

    varnames = DailyHist.Properties.VariableNames;
    ix = false(size(varnames));
    for i = 1:numel(options.Gages_to_use)
        ix = ix | strcmp(varnames, options.Gages_to_use{i});
    end
    DailyHist = DailyHist(:,ix);
else
    options.Gages_to_use = DailyHist.Properties.VariableNames;
end

% Assign Water Year column
WaterYearVec = DailyHist.(DaiyHist_dt).Year;
ix = DailyHist.(DaiyHist_dt).Month >= 10;
WaterYearVec(ix) = WaterYearVec(ix) + 1;
DailyHist.WaterYear = WaterYearVec;

% only keep complete years (water years or regular years)
if options.WaterYears
    YearVec = DailyHist.WaterYear;
else
    YearVec = DailyHist.(DaiyHist_dt).Year;
end

YearNumDays = accumarray(YearVec, ones(size(YearVec)), [], @sum);
CompleteYears = find(YearNumDays == 365);
ix = ismember(YearVec, CompleteYears);
DailyHist = DailyHist(ix,:);

% filter to portion of historical record we will use 
b = options.Gage_hist_years_to_use(1);
e = options.Gage_hist_years_to_use(2);
if options.WaterYears
    if isnan(b)
        options.Gage_hist_years_to_use(1) = min(DailyHist.WaterYear);
    end
    if isnan(e)
        options.Gage_hist_years_to_use(2) = max(DailyHist.WaterYear);
    end
else
    if isnan(b)
        options.Gage_hist_years_to_use(1) = min(DailyHist.(DaiyHist_dt).Year);
    end
    if isnan(e)
        options.Gage_hist_years_to_use(2) = max(DailyHist.(DaiyHist_dt).Year);
    end
end
b = options.Gage_hist_years_to_use(1);
e = options.Gage_hist_years_to_use(2);

ix = true(size(DailyHist, 1), 1);
if options.WaterYears
    ix = ix & DailyHist.WaterYear >= b;
    ix = ix & DailyHist.WaterYear <= e;
else
    ix = ix & DailyHist.(DaiyHist_dt).Year >= b;
    ix = ix & DailyHist.(DaiyHist_dt).Year <= e;
end
DailyHist = DailyHist(ix,:);


%% MonthlyHistSum
% roll up to multi-site observations of historical gage inflow 
MonthlyHistSum = retime(DailyHist, "Month", @sum);
monthly_gage_timecol = MonthlyHistSum.Properties.DimensionNames{1};

% Assign Water Year column
MonthlyHistSum.WaterYear = MonthlyHistSum.(monthly_gage_timecol).Year;
ix = MonthlyHistSum.(monthly_gage_timecol).Month >= 10;
MonthlyHistSum.WaterYear(ix) = MonthlyHistSum.WaterYear(ix) + 1;

