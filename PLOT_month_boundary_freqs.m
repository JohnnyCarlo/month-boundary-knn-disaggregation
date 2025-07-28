function PLOT_month_boundary_freqs(simulated, folderout, percyn, plot_type)

%% prep
fn = {'simulated_daily_flows_Nowak', ...
    'simulated_daily_flows_MBKNN_NoInline', ...
    'simulated_daily_flows_MBKNN_2Inline', ...
    'simulated_daily_flows_MBKNN_4Inline'};
dates = simulated.simulated_daily_flows_Nowak{1}.Date;
nodes = simulated.simulated_daily_flows_Nowak{1}.Properties.VariableNames;

plotdata = cell(numel(nodes), 4);
histdata = cell(numel(nodes), 1);

historical = simulated.daily_historical;


%% historical intermonth and intramonth
for i = 1:numel(nodes)
    disp(['Processing node ' int2str(i) ': ' nodes{i}]);

    diffs = historical.(nodes{i})(2:end) - historical.(nodes{i})(1:end-1);
    if percyn
        diffs = diffs .* 100 ./  historical.(nodes{i})(1:end-1);
    end

    ix = historical.Date.Day(2:end) == 1;

    data.inter = sort(diffs(ix));
    data.inter_percentiles = (0.5:1:numel(data.inter)-0.5)'./numel(data.inter);

    for d = 2:28
        ix = dates.Day(2:end) == d;
        if d == 2
            intra = sort(diffs(ix));
        else
            intra = [intra, sort(diffs(ix))];
        end
    end

    intra_max = max(intra, [], 2);
    intra_min = min(intra, [], 2);
    intra_90 = prctile(intra, 90, 2);
    intra_10 = prctile(intra, 10, 2);
    intra_25 = prctile(intra, 25, 2);
    intra_75 = prctile(intra, 75, 2);
    intra_50 = prctile(intra, 50, 2);


    data.intra_range = [intra_max;flip(intra_min)];
    data.intra_9010 =  [intra_90; flip(intra_10)];
    data.intra_7525 =  [intra_75; flip(intra_25)];
    data.intra_med =    intra_50;
    data.intra_percentiles = (0.5:1:numel(intra_50)-0.5)'./numel(intra_50);
    data.intra_percentiles_envelope = [data.intra_percentiles; flip(data.intra_percentiles)];
    histdata{i} = data;

end

%% simulated intermonth and intramonth
for i = 1:numel(nodes)

    for f = 1:4
        disp(['Processing node ' int2str(i) ': ' nodes{i}]);
        daily = simulated.(fn{f}){1};

        diffs = (daily.(nodes{i})(2:end) - daily.(nodes{i})(1:end-1));
        if percyn
            diffs = diffs .* 100 ./  daily.(nodes{i})(1:end-1);

        end

        ix = dates.Day(2:end) == 1;

        data.inter = sort(diffs(ix));
        data.inter_percentiles = (0.5:1:numel(data.inter)-0.5)'./numel(data.inter);

        for d = 2:28
            ix = dates.Day(2:end) == d;
            if d == 2
                intra = sort(diffs(ix));
            else
                intra = [intra, sort(diffs(ix))];
            end
        end

        intra_max = max(intra, [], 2);
        intra_min = min(intra, [], 2);
        intra_90 = prctile(intra, 90, 2);
        intra_10 = prctile(intra, 10, 2);
        intra_25 = prctile(intra, 25, 2);
        intra_75 = prctile(intra, 75, 2);
        intra_50 = prctile(intra, 50, 2);


        data.intra_range = [intra_max;flip(intra_min)];
        data.intra_9010 =  [intra_90; flip(intra_10)];
        data.intra_7525 =  [intra_75; flip(intra_25)];
        data.intra_med =    intra_50;
        data.intra_percentiles = (0.5:1:numel(intra_50)-0.5)'./numel(intra_50);
        data.intra_percentiles_envelope = [data.intra_percentiles; flip(data.intra_percentiles)];
        plotdata{i,f} = data;

    end
end

%% plot
figure('position', [2039   0    650    775]);
simtypes = {'Nowak (2010)', 'MBKNN (no inline)', 'MBKNN (2 PCs)', 'MBKNN (4 PCs)'};
if percyn
    yLab = '% daily flow change';
else
    yLab = {'', 'daily flow', 'change, kL/s'};
end

llpad = 0.1;
rrpad = 0.02;
ttpad = 0.05;
bbpad = 0.05;

cellwidth = (1 - llpad - rrpad) ./4;
cellheight = (1 - ttpad - bbpad) ./6;

xpos = [0:3] .* cellwidth + llpad;
ypos = [5:-1:0] .* cellheight + bbpad;

lpad = 0.01;
rpad = 0.01;

tpad = 0.01;
bpad = 0.01;

for i = 1:numel(nodes)
    for f = 1:4
        p = (i-1) .* 4 + f;
        % subplot(numel(nodes),4,p);
        axes('position', [xpos(f) + lpad, ypos(i) + tpad, cellwidth - lpad - rpad, cellheight - tpad - bpad]);
        hold on;
        set(gca, 'ylim', [-15 15])
        if ~strcmp(plot_type, 'histsim')
            patch(plotdata{i,f}.intra_percentiles_envelope, plotdata{i,f}.intra_9010, [1 0.7 0.7]);
            plot( plotdata{i,f}.intra_percentiles,          plotdata{i,f}.intra_med, 'color', [1 0 0], 'linewidth', 1, 'LineStyle', '--');
            plot( plotdata{i,f}.inter_percentiles,          plotdata{i,f}.inter, 'color', [0 0 0], 'linewidth', 2);
            grid on;
            set(gca, 'Layer', 'top');
            hold off;
            if i == 6
                xlabel('frequency');
            else
                set(gca, 'XTickLabel', []);
            end
            if f == 1
                yLab{1} = strrep(nodes{i}, '_', ' ');
                ylabel(yLab);
            else
                set(gca, 'YTickLabel', []);
            end
            if p == 1
                legend({'intra 90/10', 'intra med', 'inter'}, 'location', 'northwest');
            end
            set(gca, 'xlim', [0,1]);
            if i == 1
                title(simtypes{f});
            end
            filename = 'Sim_Inter_Intra_Flow_Change_Comparison';
        else
            plot( histdata{i}.inter_percentiles,          histdata{i}.inter, '-r', 'linewidth', 2);
            plot( plotdata{i,f}.inter_percentiles,          plotdata{i,f}.inter, '-b', 'linewidth', 2);
            grid on;
            set(gca, 'Layer', 'top');
            hold off;
            if i == 6
                xlabel('frequency');
            else
                set(gca, 'XTickLabel', []);
            end
            if f == 1
                yLab{1} = strrep(nodes{i}, '_', ' ');
                ylabel(yLab);
            else
                set(gca, 'YTickLabel', []);
            end
            if p == 1
                legend({'hist', 'sim'}, 'location', 'northwest');
            end
            set(gca, 'xlim', [0,1]); 
            if i == 1
                title(simtypes{f});
            end
            filename = 'Hist_Sim_Inter_Flow_Change_Comparison';
        end
    end
end

saveas(gcf, [folderout '\' filename '.fig']);
saveas(gcf, [folderout '\' filename '.png']);
saveas(gcf, [folderout '\' filename '.pdf']);
close(gcf);