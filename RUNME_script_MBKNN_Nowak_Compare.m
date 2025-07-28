%% What kind of run
options = [];
options.RunNamePrefix = 'Manuscript_MBKNN_vs_Nowak';
options.WaterYears = true;

%% specify flows for modeling


% Available here
%     'USGS_01350000', ...
%     'USGS_01362500', ...
%     'USGS_01365000', ...
%     'USGS_01413500', ...
%     'USGS_01423000', ...

% Gage Flows
options.Gages_to_use = {'USGS_01350000', ...
    'USGS_01362500', ...
    'USGS_01365000', ...
    'USGS_01413500', ...
    'USGS_01423000', ...
    'USGS_01435000'};
options.Gage_hist_years_to_use = [1960, 2020];

%% monthly simulation 
options.num_sim_years = numel(options.Gage_hist_years_to_use(1):options.Gage_hist_years_to_use(2));
options.num_realizations = 1;

% log-transform?
% STRONG RECOMMENDATION - true
options.monthlysim.logtransform = true;

% if log-transforming, Specify an offset if needed.
options.monthlysim.Data_offset_for_0_or_negative_flows = 0.1;

%% disaggregation candidate settings

% k - number of neighbors for each month
% k = []: use default number for k: sqrt of size of month database
% k = NaN: use all database entries as candidates
options.disagg.k = 2500; 

% w: +/- days window length for candidates 
options.disagg.w = 30;

% omit candidates that have at least 1 site with more than this many zero
% inflows - might be good to revise procedure to better accommodate
% ephemeral streams
options.disagg.dailyZeroLimit = 10;

%% disaggregation selection probabilities

% if we want KNN to be identified using inter-month daily differences instead of
% monthly differences
% options.disagg.interdiff_first = true;

% selection probability exponent pi_sel \in [0 Inf) 
% pi_sel == 1: selection weights = centrality/sum of centralities
% pi_sel < 1: increase selection weights for lower centralities
% pi_sel == 0: uniform random selection
% pi_sel > 1: increase selection weights for higher centralities
% pi_sel -> Inf: converge to deterministic selection of highest centrality
%                score
% See Equation 30
options.disagg.pi_sel = 8;

% minimum centrality score gamma_floor \in [0 1] - 
% centrality scores less than this value get censored to that value
% for random selection, this ensures that all candidates below that value
% are equally likely for selection
% See Equation 30
options.disagg.gamma_floor = 1/5000;

% true: override selection: take candidate with highest centrality score
% false: randomly select candidate using centrality scores as weights
options.disagg.takebest = false;

% number of principal components to use n_PC \in [1, # of gages]
% []: use all PCs
% See Equations 27 and 28 
%options.disagg.n_PC = 2;

% NOTE - normally n_PC would be set here
% However, the combined_generator script has been modified to control this
% option in lines 38, 46, and 54 to produce MBKNN configurations compared 
% in Section 4 of the manuscript.  Any setting of n_PC here is
% going to be overwritten.


%% disaggregation inline validation

% turns inline validation on or off directly
% if set to false, n_max pi_val and rn_mu (below) are irrelevant
%options.disagg.inline_active = true;

% NOTE - normally inline_active would be set here
% However, the combined_generator script has been modified to control this
% option in lines 37, 45, and 53 to produce MBKNN configurations compared 
% in Section 4 of the manuscript.  Any setting of inline_active here is
% going to be overwritten.


% max number of times allowed to step back from any month: n_max > 0
% See Equation 34
options.disagg.n_max = 5;

% basic acceptance probability is centrality score to an acceptance power
% pi_val \in [0, Inf)
% See Equation 35
options.disagg.pi_val = 0.5; 

% each time a month is stepped back from, multiply pi_val
% by an acceptance probability relaxer rn_mu \in [0, Inf) - 
% See Equation 36
options.disagg.rn_mu = 0.9;

% prevents zero daily fractions
% options.disagg.monthflowoffset = 1/1000;

%% disaggregation execution

% verbosity
options.disagg.verbose = true;

%% disaggregation diagnostics
options.disagg.diagnosticsYN = false;


%% random seed
rng('default');

%% run it
[results, options] = combined_generator(options);  

