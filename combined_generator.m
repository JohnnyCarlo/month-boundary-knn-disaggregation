function [results, options] = combined_generator(options)                      

%% output naming
basename = options.RunNamePrefix;
timetag = strrep(strrep(strrep(int2str(datevec(now)), ' ', '<>'), '><', ''), '<>', '');
basename = [basename '_' timetag];

folderout = ['./Output/' basename];
mkdir(folderout);

options.simpath = folderout;
options.basename = basename;

results.options = options;

			
%% prep historical daily flows
[DailyHist, MonthlyHistSum, options] = prep_hist_data_gage_flows(options);

%% generation of monthly data via Kirsch et al. (2013):					
% Kirsch, B. R., G. W. Characklis, and H. B. Zeff (2013), 					
% Evaluating the impact of alternative hydro-climate scenarios on transfer 					
% agreements: Practical improvement for generating synthetic streamflows, 					
% Journal of Water Resources Planning and Management, 139(4), 396406.
MonthlySimSum = monthly_main(MonthlyHistSum, options);
results.simulated_monthly_flows = MonthlySimSum;

%% Disaggregate - Nowak
tStart = tic;
DailySim_Nowak = NOWAK_disagg(DailyHist, MonthlySimSum, options);
results.simulated_daily_flows_Nowak = DailySim_Nowak;
a = toc(tStart);
options.Nowak_time = a;

%% disaggregate - MBKNN
tStart = tic;
options.disagg.inline_active = false;
options.disagg.n_PC = 2;
[DailySim_MBKNN_NoInline, ~] = MBKNN_disagg(MonthlySimSum, DailyHist, options);
results.simulated_daily_flows_MBKNN_NoInline = DailySim_MBKNN_NoInline;
a = toc(tStart);
options.MBKNN_NoInline_time = a;

tStart = tic;
options.disagg.inline_active = true;
options.disagg.n_PC = 2;
[Daily_Sim_Gage_Flows_CFS_MBKNN_2Inline, ~] = MBKNN_disagg(MonthlySimSum, DailyHist, options);
results.simulated_daily_flows_MBKNN_2Inline = Daily_Sim_Gage_Flows_CFS_MBKNN_2Inline;
a = toc(tStart);
options.MBKNN_2Inline_time = a;

tStart = tic;
options.disagg.inline_active = true;
options.disagg.n_PC = 4;
[Daily_Sim_Gage_Flows_CFS_MBKNN_4Inline, ~] = MBKNN_disagg(MonthlySimSum, DailyHist, options);
results.simulated_daily_flows_MBKNN_4Inline = Daily_Sim_Gage_Flows_CFS_MBKNN_4Inline;
a = toc(tStart);
options.MBKNN_4Inline_time = a;
results.daily_historical = DailyHist;

%% record options and output
results.options = options;
eval([basename ' = results;']);
save([folderout '/' basename '.mat'], basename, '-v7.3');


%% plots
PLOT_month_boundary_freqs(results, folderout, false, 'histsim');
PLOT_month_boundary_freqs(results, folderout, false, 'sim_intra_inter');
PLOT_daily_pcts(results, folderout);

%% month boundary freq table
TABLE_month_boundary_freqs(results, folderout)




