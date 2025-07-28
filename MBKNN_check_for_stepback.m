function [stepbackyn, num_stepbacks, accept_powers, i] = MBKNN_check_for_stepback(candidate_indices, num_stepbacks, ...
        accept_powers, options, i, r)

stepbackyn = false;

%% first time step: no stepback
if i == 1
    return;
end

%% classic stepback
% maximum centrality score
max_centrality = max(candidate_indices.CentralityScore);
acceptprob = (max_centrality .^ accept_powers(i)); 
rn = rand(); 
acceptyn = rn <= acceptprob;

% accepted
if acceptyn
    return;
end

% would step back, but we've stepped back too many times already
if num_stepbacks(i) >= options.disagg.n_max 
    if options.disagg.verbose
        disp(['    Month ' int2str(i) ' of realization ' int2str(r) ': maximum stepbacks reached']);
    end
    return;
end

% step back
stepbackyn = true;
num_stepbacks(i) = num_stepbacks(i) + 1;
accept_powers(i) = accept_powers(i) .* options.disagg.rn_mu; 

if options.disagg.verbose
    disp(['            Best centrality score = ' num2str(max_centrality, '%5.3f') '   acceptprob = ' num2str(acceptprob, '%5.3f') '    rand = ' num2str(rn, '%5.3f')])
    disp(['            Candidate set is poor: Stepping back to month ' int2str(i-1) ' of realization ' int2str(r)]);
end