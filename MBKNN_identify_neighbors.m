function candidate_indices = MBKNN_identify_neighbors(sim_monthly_inflows, sim_lastday_inflows, this_db, elig_candidates, options)

%% if this is the first month, do knn using monthly flows
if isempty(sim_lastday_inflows)

    % K most similar neighbor months based on monthly means
    candidate_indices = MBKNN_identify_neighbors_firstmonth(sim_monthly_inflows, this_db, options);

    % replace RMS differences: rank neighbor months from K (most similar) to 1 (kth most similar)
    k = size(candidate_indices, 1);
    candidate_indices.SimilarityLowerIsBetter = (k:-1:1)';

    % normalize ranks to sum to 1 (most importantly, all values are between
    % 0 and 1)
    candidate_indices.SimilarityLowerIsBetter = candidate_indices.SimilarityLowerIsBetter ./ k;
    
    % rename columns so that these results cam be used by remaining MBKNN
    % code
    candidate_indices.Properties.VariableNames = {'CentralityScore', 'CandidateRownum'};
    return;
end

%% initial candidate list
num_db = size(this_db.pattern_sums,1);
a = (1:num_db)';
b = nan(size(a));
candidate_indices = [b, a];
candidate_indices = array2table(candidate_indices, 'VariableNames', {'CentralityScore', 'CandidateRownum'});

%% screen candidates for eligibility
elnum = find(elig_candidates.Eligible);
ix = ismember(candidate_indices.CandidateRownum, elnum);
candidate_indices = candidate_indices(ix,:);

%% step through candidates, calculate centrality scores
candidate_indices = MBKNN_centrality_scores(sim_monthly_inflows, sim_lastday_inflows, ...
    this_db, candidate_indices);

%% sort candidates by increasing centrality scores
candidate_indices = sortrows(candidate_indices, 'CentralityScore', 'descend');

%% get KNN
krequest = options.disagg.k;
if isempty(krequest)
    krequest = ceil(sqrt(size(candidate_indices, 1)));
end
k = min(krequest, size(candidate_indices, 1));
candidate_indices = candidate_indices(1:k,:);








