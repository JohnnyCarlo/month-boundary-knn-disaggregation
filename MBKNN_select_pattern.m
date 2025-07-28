function [selection, candidate_indices] = MBKNN_select_pattern(candidate_indices, options, i)

%% short-circuit prob sample if takebest is true
if options.disagg.takebest
    candidate_indices = sortrows(candidate_indices, "CentralityScore", 'descend');
    Probabilities = zeros(size(candidate_indices, 1), 1);
    Probabilities(1) = 1;
    candidate_indices = addvars(candidate_indices, Probabilities);
    selection = candidate_indices.CandidateRownum(1);
    return;
end

%% convert centrality scores to selection probabilities
ix = candidate_indices.CentralityScore < options.disagg.gamma_floor;
Probabilities = candidate_indices.CentralityScore;
Probabilities(ix) = options.disagg.gamma_floor;
Probabilities = Probabilities .^ options.disagg.pi_sel;
Probabilities = Probabilities ./ sum(Probabilities);
candidate_indices = addvars(candidate_indices, Probabilities);

%% select at random
selection = randsample(candidate_indices.CandidateRownum,1,true,candidate_indices.Probabilities);



