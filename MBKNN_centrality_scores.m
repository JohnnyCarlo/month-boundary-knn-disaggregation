function centralityscores = MBKNN_centrality_scores(this_sim_monthly, this_sim_lastday, ...
    this_db, candidate_indices)

%% first time step: no intermonth flow difference.  just random selection
if isempty(this_sim_lastday)
    centralityscores(:,1) = sort(candidate_indices.CandidateRownum);
    centralityscores(:,2) = NaN(size(centralityscores,1),1);
    centralityscores(:,3) = ones(size(centralityscores(:,2)));
    centralityscores = array2table(centralityscores, 'VariableNames', {'CandidateRownum', 'Num_Hist_Changes_Less_Central', 'CentralityScore'});
    return;
end

%% pull candidates
cand_rownums = sort(candidate_indices.CandidateRownum);
candidates = this_db;
candidates.date = candidates.date(cand_rownums);
candidates.pattern_sum =    candidates.pattern_sums(cand_rownums,:);


candidates.firstflows = candidates.firstflows(cand_rownums,:);
candidates.flowchanges = candidates.flowchanges(cand_rownums,:);
candidates.patterns_ratios = candidates.patterns_ratios(cand_rownums,:,:);
candidates.flowchangesPCASTD_distances = candidates.flowchangesPCASTD_distances(cand_rownums);

%% determine intermonth daily differences for each candidate
num_cand = numel(cand_rownums);
firstpatterns_ratios = squeeze(candidates.patterns_ratios(:,1,:));
shifted_firstflows = firstpatterns_ratios .* repmat(this_sim_monthly, num_cand, 1);
candidate_flowdiffs = shifted_firstflows - repmat(this_sim_lastday, num_cand, 1);

%% rotate daily differences and then standardize
candidate_flowdiffs_PCA = candidate_flowdiffs * candidates.flowchangesPCA_coeffs;
candidate_flowdiffs_PCASTD = (candidate_flowdiffs_PCA - repmat(candidates.flowchangesPCA_mu, num_cand, 1)) ...
    ./ repmat(candidates.flowchangesPCA_sigma, num_cand, 1);


%% calculate fraction of historical flowchange points further from center than each candidate (centrality scores)
num_hist = size(this_db.flowchangesPCASTD_distances, 1);
candidate_hist_comparisons = NaN(num_hist.*num_cand, 4);
c_d = [cand_rownums, sqrt(sum(candidate_flowdiffs_PCASTD.^2, 2))];
c_d = repmat(c_d, num_hist, 1);
c_d = sortrows(c_d, 1);
candidate_hist_comparisons(:,1:2) = c_d;
candidate_hist_comparisons(:,3) = repmat(this_db.flowchangesPCASTD_distances, num_cand, 1);
candidate_hist_comparisons(:,4) = candidate_hist_comparisons(:,3) > candidate_hist_comparisons(:,2);

centralityscores = NaN(num_cand, 3);
c_s = accumarray(candidate_hist_comparisons(:,1), candidate_hist_comparisons(:,4), [], @sum);
c_s = c_s(cand_rownums, 1);
centralityscores(:,1) = cand_rownums;
centralityscores(:,2) = c_s;
centralityscores(:,3) = centralityscores(:,2) ./ num_hist;
centralityscores = array2table(centralityscores, 'VariableNames', {'CandidateRownum', 'Num_Hist_Changes_Less_Central', 'CentralityScore'});



