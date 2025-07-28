function pattern = NOWAK_KNN_sampling( knn_candidates, these_candidate_start_ends, cumulative_weight, historical_daily_flows_mat)

% py = KNN_sampling( KKN_id, indices, Wcum, Qdaily, month )
%
% Selection of one KNN according to the probability distribution defined by
% the weights W.
%
% Input:    KNN_id = indices of the first K-nearest neighbors
%           indices = n x 2 matrix where n is the number of monthly totals
%             and the 2 columns store the historical year in which each
%             monthly total begins, and the number of shift index
%             where 1 is 7 days earlier and 15 is 7 days later
%           Wcum = cumulated probability for each nearest neighbor
%           Qdaily = historical data
%           month = month being disaggregated
% Output:   py = selected proportion vector corresponding to the sampled
%             shifted historical month
%           yearID = randomly selected monthly total (row to select from indices)
%
% MatteoG 31/05/2013

%Randomly select one of the k-NN using the Lall and Sharma density
%estimator
r = rand ;
cumulative_weight = [0, cumulative_weight] ;
for i = 1:length(cumulative_weight)-1
    if (r > cumulative_weight(i)) && (r <= cumulative_weight(i+1))
        selected = knn_candidates(i);
        break;
    end
end

this_startend = these_candidate_start_ends(selected,:);
pattern = historical_daily_flows_mat(this_startend(1):this_startend(2),:);
sumpattern = sum(pattern);
pattern = pattern ./ repmat(sumpattern, size(pattern, 1), 1);

