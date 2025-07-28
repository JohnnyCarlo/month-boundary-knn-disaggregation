function [KNN_id, W] = NOWAK_KNN_identification(this_sim_month_flows, these_candidate_monthlies, these_candidate_start_ends, k)

% [KNN_id, W] = KNN_identification( Z, Qtotals, month, k )
%
% Identification of K-nearest neighbors of Z in the historical annual data
% z and computation of the associated weights W.
%
% Input:    Z = synthetic datum (scalar)
%           Qtotals = total monthly flows at all sites for all historical months 
%             within +/- 7 days of the month being disaggregated
%           month = month being disaggregated
%           k = number of nearest neighbors (by default k=n_year^0.5
%             according to Lall and Sharma (1996))
% Output:   KNN_id = indices of the first K-nearest neighbors of Z in the
%             the historical annual data z
%           W = nearest neighbors weights, according to Lall and Sharma
%             (1996): W(i) = (1/i) / (sum(1/i)) 
%
% MatteoG 31/05/2013

% determine K
num_candidates = size(these_candidate_monthlies,1);
if isempty(k)
    K = round(sqrt(num_candidates));
elseif isnan(k)
    K = num_candidates;
else
    K = k ;
end

% nearest neighbors identification
delta = zeros(num_candidates,1); 
for i=1:num_candidates
    delta(i) = sum((these_candidate_monthlies(i,:) - this_sim_month_flows).^2);
end

Y = [(1:num_candidates)', delta];
Y_ord = sortrows(Y, 2);
KNN_id = Y_ord(1:K,1);

% computation of the weights
f = [1:K];
f1 = 1./f;
W = f1 ./ sum(f1) ;

end








