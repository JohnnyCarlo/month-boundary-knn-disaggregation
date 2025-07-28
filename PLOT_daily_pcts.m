function PLOT_daily_pcts(simulated, folderout)

%% prep
fn = {'simulated_daily_flows_Nowak', ...
    'simulated_daily_flows_MBKNN_NoInline', ...
    'simulated_daily_flows_MBKNN_2Inline', ...
    'simulated_daily_flows_MBKNN_4Inline'};

nodes = simulated.simulated_daily_flows_Nowak{1}.Properties.VariableNames;

plotdata = cell(numel(nodes), 12, 4);
histdata = cell(numel(nodes), 12);

historical_daily = simulated.daily_historical;
historical_monthly = retime(historical_daily,"monthly","sum");

ndim = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];



%% historical daily_pcts
for i = 1:numel(nodes)
    disp(['Processing node ' int2str(i) ': ' nodes{i}]);

    for m = 1:size(historical_monthly, 1)
        this_mandy = historical_monthly.Date(m);
        ix = historical_daily.Date.Year == this_mandy.Year & historical_daily.Date.Month == this_mandy.Month;
        historical_daily.(nodes{i})(ix) = historical_daily.(nodes{i})(ix) ./ historical_monthly.(nodes{i})(m);
    end

    for m = 1:12
        ix = historical_daily.Date.Month == m;
        these_daily = reshape(historical_daily.(nodes{i})(ix), ndim(m), []);  % ndim by # months
        for u = 1:size(these_daily, 2)
            these_daily(:,u) = sort(these_daily(:,u));
        end


        daily_max =    max(these_daily, [], 2);
        daily_min =    min(these_daily, [], 2);
        daily_90 = prctile(these_daily, 90, 2);
        daily_10 = prctile(these_daily, 10, 2);
        daily_25 = prctile(these_daily, 25, 2);
        daily_75 = prctile(these_daily, 75, 2);
        daily_50 = prctile(these_daily, 50, 2);


        data.daily_range = [daily_max;flip(daily_min)];
        data.daily_9010 =  [daily_90; flip(daily_10)];
        data.daily_7525 =  [daily_75; flip(daily_25)];
        data.daily_med =    daily_50;
        data.daily_percentiles = (0.5:1:ndim(m)-0.5)'./ndim(m);
        data.daily_percentiles_envelope = [data.daily_percentiles; flip(data.daily_percentiles)];
        histdata{i,m} = data;
    end
end

%% simulated intermonth and intramonth
for f = 1:4

    for i = 1:numel(nodes)
        disp(['Processing node ' int2str(i) ': ' nodes{i}]);
        simulated_daily = simulated.(fn{f}){1};
        simulated_monthly = simulated.simulated_monthly_flows{1};

        for m = 1:size(simulated_monthly, 1)
            this_mandy = simulated_monthly.Date(m);
            ix = simulated_daily.Date.Year == this_mandy.Year & simulated_daily.Date.Month == this_mandy.Month;
            simulated_daily.(nodes{i})(ix) = simulated_daily.(nodes{i})(ix) ./ simulated_monthly.(nodes{i})(m);
        end

        for m = 1:12
            ix = simulated_daily.Date.Month == m;
            these_daily = reshape(simulated_daily.(nodes{i})(ix), ndim(m), []);  % ndim by # months
            for u = 1:size(these_daily, 2)
                these_daily(:,u) = sort(these_daily(:,u));
            end


            daily_max =    max(these_daily, [], 2);
            daily_min =    min(these_daily, [], 2);
            daily_90 = prctile(these_daily, 90, 2);
            daily_10 = prctile(these_daily, 10, 2);
            daily_25 = prctile(these_daily, 25, 2);
            daily_75 = prctile(these_daily, 75, 2);
            daily_50 = prctile(these_daily, 50, 2);


            data.daily_range = [daily_max;flip(daily_min)];
            data.daily_9010 =  [daily_90; flip(daily_10)];
            data.daily_7525 =  [daily_75; flip(daily_25)];
            data.daily_med =    daily_50;
            data.daily_percentiles = (0.5:1:ndim(m)-0.5)'./ndim(m);
            data.daily_percentiles_envelope = [data.daily_percentiles; flip(data.daily_percentiles)];
            plotdata{i,m,f} = data;
        end
    end
end

%% plot

simtypes = {'Nowak', 'MBKNN (2PC no inline)', 'MBKNN (2PC inline)', 'MBKNN (4PC inline)'};
mos = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
X = {'daily_percentiles_envelope', 'daily_percentiles_envelope', 'daily_percentiles_envelope', 'daily_percentiles'};
Y = {'daily_range', 'daily_9010', 'daily_7525', 'daily_med'};

for m = 1:12
    for xy = 1:4
        for i = 1:numel(nodes)
            thisx = X{xy};
            thisy = Y{xy};
            stn = nodes{i};
            figure('position', [162 362 1127 220]);
            filename = [stn '_' mos{m} '_' thisy '_percs' ];

            for f = 1:4

                subplot(1,4,f);
                hold on;

                if xy==4
                    plot(plotdata{i,m,f}.(thisx), plotdata{i,m,f}.(thisy) .* 100, 'color', [1 0 0], 'linewidth', 2, 'LineStyle', '-');
                    plot(histdata{i,m  }.(thisx), histdata{i,m  }.(thisy) .* 100, 'color', [0 0 1], 'linewidth', 2, 'LineStyle', '-');
                else
                    patch(plotdata{i,m,f}.(thisx), plotdata{i,m,f}.(thisy) .* 100, [1 0 0], 'facealpha', 0.4, 'edgecolor', 'none');
                    patch(histdata{i,m  }.(thisx), histdata{i,m  }.(thisy) .* 100, [0 0 1], 'facealpha', 0.4, 'edgecolor', 'none');
                end

                grid on;
                set(gca, 'Layer', 'top');
                hold off;
                xlabel('frequency');
                ylabel('Daily flow, % of monthly');
                legend({'sim', 'hist'}, 'location', 'northwest');
                set(gca, 'xlim', [0,1])
                set(gca, 'ylim', [0 30])
                title({[mos{m} strrep(nodes{i}, 'USGS_', ' ')], simtypes{f}});
            end
            saveas(gcf, [folderout '\' filename '.fig']);
            saveas(gcf, [folderout '\' filename '.png']);
            saveas(gcf, [folderout '\' filename '.pdf']);
            close(gcf);
        end
    end
end
