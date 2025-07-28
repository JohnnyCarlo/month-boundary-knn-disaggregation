function out = TABLE_month_boundary_freqs(results, folderout)

%% prep
fn = {'simulated_daily_flows_Nowak', ...
    'simulated_daily_flows_MBKNN_NoInline', ...
    'simulated_daily_flows_MBKNN_2Inline', ...
    'simulated_daily_flows_MBKNN_4Inline'};
snames = {'historical', '(Nowak 2010)', 'MBKNN (2PC no inline)', 'MBKNN (2PC inline)', 'MBKNN (4PC inline)'};
dates = results.simulated_daily_flows_Nowak{1}.Date;
nodes = results.simulated_daily_flows_Nowak{1}.Properties.VariableNames;
historical = results.daily_historical;

blankout = array2table(NaN(7,5), 'VariableNames', snames, 'RowNames',{'5th', '20th', '25th', '50th', '75th', '90th', '95th'});
out = [];

%% populate table
for i = 1:numel(nodes)
    disp(['Processing node ' int2str(i) ': ' nodes{i}]);
    diffs = historical.(nodes{i})(2:end) - historical.(nodes{i})(1:end-1);
    out.(nodes{i}) = blankout;
    ix = historical.Date.Day(2:end) == 1;
    inter = diffs(ix);
    out.(nodes{i}).historical = prctile(inter, [5 10 25 50 75 90 95])';
    
    for f = 1:4
        daily = results.(fn{f}){1};
        diffs = (daily.(nodes{i})(2:end) - daily.(nodes{i})(1:end-1));
        ix = dates.Day(2:end) == 1;
        inter = diffs(ix);
        out.(nodes{i}).(snames{f+1}) = prctile(inter, [5 10 25 50 75 90 95])';
    end
end

%% write table to pipe-dlm file
for i = 1:numel(nodes)
    writetable(out.(nodes{i}), [folderout '\boundaryfreqstables.xlsx'], 'Sheet', nodes{i});
end

