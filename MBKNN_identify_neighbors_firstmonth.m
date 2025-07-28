function candidate_indices = MBKNN_identify_neighbors_firstmonth(sim_monthly_inflows, ...
    this_db, options)

%% predim - number of potential candidates for this simulated month
num_db = size(this_db.pattern_sums,1);
tot_sq_diffs = NaN(num_db, 1);

%% step through candidates
for i = 1:num_db
       
    % month-period monthly flows for each candidate (for each site)
    hist_inflow_monthly = this_db.pattern_sums(i,:);
    
    % root mean square difference between candidate and simulated flow
    % vectors
    histsim_inflow_diff = hist_inflow_monthly - sim_monthly_inflows;
    histsim_inflow_diff2 = histsim_inflow_diff.^2;
    tot_sq_diffs(i) = sqrt(nansum(histsim_inflow_diff2));
end

% number candidates and then sort by increasing sum sq diff
tot_sq_diffs(:,2) = (1:num_db)';
tot_sq_diffs = sortrows(tot_sq_diffs, 1);

% how many neighbors?
k = options.disagg.k;
if isempty(k)
    k = ceil(sqrt(num_db));
end
k = min(k, num_db);

candidate_indices = tot_sq_diffs(1:k,:);
candidate_indices = array2table(candidate_indices, 'VariableNames', {'SimilarityLowerIsBetter', 'CandidateRownum'});

end








