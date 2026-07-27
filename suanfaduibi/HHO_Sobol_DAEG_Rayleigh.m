function [f_best, X_best, histout, diagnostics] = ...
    HHO_Sobol_DAEG_Rayleigh( ...
    nPop, maxIter, lb, ub, fun, useParallel, searchSeed, cfg)
% =========================================================================
% HHO_Sobol_DAEG_Rayleigh
%
% Sobol initialization + diversity-adaptive search +
% progressive elite guidance + stagnation repair
%
% Strategies enabled by default:
%   1) Sobol low-discrepancy initialization;
%   2) Diversity-adaptive energy amplitude E;
%   3) Diversity-adaptive jump factor J;
%   4) Progressive elite guidance;
%   5) Conditional stagnation repair.
%
% Parameter vector:
% x = [Vs1 Vs2 Vs3 Vs4 H1 H2 H3 Vp1 Vp2 Vp3 Vp4]
%
% Inputs:
% nPop         : population size
% maxIter      : maximum number of iterations
% lb, ub       : lower and upper parameter bounds, both 1-by-D vectors
% fun          : objective-function handle
% useParallel  : whether to use parfor
% searchSeed   : random seed for the search stage; may be empty []
% cfg          : optional structure containing strategy switches
%
% Supported cfg fields:
% cfg.useAdaptiveEJ        = true / false
% cfg.useEliteGuidance     = true / false
% cfg.useStagnationRepair  = true / false
%
% If cfg is not provided, all three strategies are enabled by default.
%
% Outputs:
% f_best       : final best objective-function value
% X_best       : best parameter vector
% histout      : historical best value at each iteration
% diagnostics  : diagnostic information, including diversity,
%                repair triggers, and objective-function evaluations
% =========================================================================


%% ====================== Input Validation ===============================

if nargin < 6 || isempty(useParallel)
    useParallel = true;
end

if nargin < 7
    searchSeed = [];
end

if nargin < 8 || isempty(cfg)
    cfg = struct();
end

if ~isa(fun, 'function_handle')
    error('fun must be an objective-function handle.');
end

if ~isscalar(nPop) || ~isfinite(nPop) || nPop < 4 || nPop ~= floor(nPop)
    error('nPop must be an integer greater than or equal to 4.');
end

if ~isscalar(maxIter) || ~isfinite(maxIter) || ...
        maxIter < 1 || maxIter ~= floor(maxIter)
    error('maxIter must be a positive integer.');
end

if ~isscalar(useParallel)
    error('useParallel must be a logical value or numeric scalar.');
end

useParallel = logical(useParallel);

if ~isempty(searchSeed)
    if ~isscalar(searchSeed) || ~isfinite(searchSeed)
        error('searchSeed must be empty or a finite scalar.');
    end
end

lb = double(lb(:).');
ub = double(ub(:).');

if numel(lb) ~= numel(ub)
    error('lb and ub must have the same dimensions.');
end

if any(~isfinite(lb)) || any(~isfinite(ub))
    error('lb and ub must not contain NaN or Inf.');
end

% ub == lb is allowed because the corresponding parameter is fixed
% and does not participate in the actual search.
% Only ub < lb is prohibited.
if any(ub < lb)
    error('Each dimension must satisfy ub >= lb.');
end

cfg = resolve_strategy_config(cfg);

dim = numel(lb);
penaltyValue = 1e30;

useParallel = prepare_parallel_pool(useParallel);


%% ====================== Fixed Strategy Parameters ======================

% These parameters should not be changed arbitrarily.
% A separate sensitivity analysis should be performed before tuning them.

eliteRatio = 0.20;                 % Proportion of elite individuals
energyGain = 0.35;                 % Energy compensation under low diversity

stagnationLimit = 8;               % Consecutive iterations without improvement
repairRatio = 0.10;                % Proportion of worst individuals repaired
repairStartRatio = 0.20;           % No repair during the first 20% of iterations
repairEndRatio = 0.90;             % No repair during the final 10% of iterations
repairDiversityThreshold = 0.35;   % Repair only under clear aggregation


%% ====================== Sobol Initialization ===========================

try
    p = sobolset(dim, 'Skip', 1024, 'Leap', 3);

    try
        p = scramble(p, 'MatousekAffineOwen');
    catch
        warning(['The current MATLAB version does not support ', ...
                 'MatousekAffineOwen scrambling. ', ...
                 'An unscrambled Sobol sequence will be used.']);
    end

    U = net(p, nPop);

catch ME
    warning(['Sobol initialization failed. ', ...
             'Random initialization will be used instead. Reason: ', ...
             ME.message]);
    U = rand(nPop, dim);
end

X = repmat(lb, nPop, 1) + ...
    U .* repmat((ub - lb), nPop, 1);

f_X = evaluate_population_parallel(X, fun, penaltyValue, useParallel);

if all(f_X >= penaltyValue * 0.999)
    error(['All initial models failed during forward calculation.', newline, ...
           'Please check:', newline, ...
           '1) whether lb and ub are reasonable;', newline, ...
           '2) the index order of Vs, H, and Vp in the parameter vector;', newline, ...
           '3) calcmulti or the underlying forward solver;', newline, ...
           '4) whether compute_fitness_base returns a finite scalar.']);
end

[f_best, bestIndex] = min(f_X);
X_best = X(bestIndex, :);

histout = zeros(1, maxIter);
histout(1) = f_best;

% Reset the random sequence after initialization so that different
% initialization methods can be compared using the same subsequent
% HHO random process.
if ~isempty(searchSeed)
    rng(searchSeed, 'twister');
end


%% ====================== Initial Diversity ==============================

D0 = population_diversity(X, lb, ub);

if ~isfinite(D0) || D0 <= eps
    D0 = 1;
end

noImproveCount = 0;
nEval = nPop;


%% ====================== Diagnostic Variables ===========================

diagnostics = struct();

diagnostics.config = cfg;
diagnostics.initialDiversity = D0;

diagnostics.diversityRatio = nan(1, maxIter);
diagnostics.energyEnvelope = nan(1, maxIter);
diagnostics.guideWeight = nan(1, maxIter);
diagnostics.stagnationCount = nan(1, maxIter);
diagnostics.repairFlag = false(1, maxIter);
diagnostics.evalHistory = nan(1, maxIter);

diagnostics.diversityRatio(1) = 1;
diagnostics.energyEnvelope(1) = 2;
diagnostics.guideWeight(1) = 1;
diagnostics.stagnationCount(1) = 0;
diagnostics.evalHistory(1) = nEval;


fprintf('\n============================================================\n');
fprintf(['DAEG-HHO started: Sobol initialization + adaptive E/J + ', ...
         'elite guidance + stagnation repair\n']);
fprintf('Population size = %d, dimension = %d, iterations = %d\n', ...
    nPop, dim, maxIter);
fprintf('Initial best objective value = %.8e\n', f_best);
fprintf('============================================================\n');


%% ====================== Main HHO Loop ==================================

for t = 2:maxIter

    X_old = X;
    f_old = f_X;

    X_mean = mean(X_old, 1);

    % Normalized iteration progress used for elite weighting and
    % the stagnation-repair activation window, ranging from 0 to 1.
    tau = (t - 1) / (maxIter - 1);

    % Preserve the standard HHO energy-decay rule.
    E1_base = 2 * (1 - t / maxIter);

    %% ====================== Current Diversity ==========================

    D_now = population_diversity(X_old, lb, ub);

    diversityRatio = D_now / (D0 + eps);

    % Restrict the ratio to [0,1] to avoid numerical overflow.
    diversityRatio = min(max(diversityRatio, 0), 1);

    %% ====================== Elite Guidance Position ====================

    if cfg.useEliteGuidance

        [~, rankIndex] = sort(f_old, 'ascend');

        nElite = max(2, round(eliteRatio * nPop));
        eliteIndex = rankIndex(1:nElite);

        X_elite_mean = mean(X_old(eliteIndex, :), 1);

        % The early stage relies mainly on the elite-group mean,
        % whereas the later stage gradually shifts toward the
        % historical best individual.
        wBest = 0.25 + 0.75 * tau;

        X_guide = wBest .* X_best + ...
            (1 - wBest) .* X_elite_mean;

    else

        % When elite guidance is disabled, the algorithm returns
        % to the standard HHO best-rabbit guidance.
        X_guide = X_best;
        wBest = 1;
    end

    %% ====================== Adaptive Energy ============================

    if cfg.useAdaptiveEJ

        % A larger effective update amplitude is retained as
        % the population becomes increasingly aggregated.
        E1_effective = E1_base * ...
            (1 + energyGain * (1 - diversityRatio));

        % Restrict the energy envelope to the original HHO upper limit.
        E1_effective = min(E1_effective, 2);

    else

        E1_effective = E1_base;
    end

    %% ====================== Individual Position Updates ================

    X_new = X_old;

    isDive = false(nPop, 1);
    Y_all = zeros(nPop, dim);
    Z_all = zeros(nPop, dim);

    for i = 1:nPop

        Xi = X_old(i, :);

        E0 = 2 * rand() - 1;

        % E_phase is used only to preserve the standard HHO
        % exploration-exploitation stage division.
        E_phase = E1_base * E0;

        % E is the diversity-adaptive energy used in position updates.
        E = E1_effective * E0;

        %% ==================== Exploration Stage ========================

        if abs(E_phase) >= 1

            q = rand();

            if q >= 0.5

                randIndex = randi(nPop);
                X_rand = X_old(randIndex, :);

                r1 = rand();
                r2 = rand();

                candidate = X_rand ...
                    - r1 .* abs(X_rand - 2 .* r2 .* Xi);

            else

                r3 = rand();
                r4 = rand();

                candidate = (X_guide - X_mean) ...
                    - r3 .* (lb + r4 .* (ub - lb));
            end

            X_new(i, :) = apply_bounds(candidate, lb, ub);

        %% ==================== Exploitation Stage =======================

        else

            r = rand();

            if cfg.useAdaptiveEJ

                % At high diversity, the distribution of J approaches
                % the standard HHO interval [0,2].
                % At low diversity, J approaches 1 so that the search
                % is centered on the local difference X_guide - Xi.
                J = 1 + (2 * rand() - 1) * diversityRatio;

            else

                % Standard HHO jump factor.
                J = 2 * (1 - rand());
            end

            DeltaGuide = X_guide - Xi;

            % B1: Soft besiege
            if r >= 0.5 && abs(E_phase) >= 0.5

                candidate = DeltaGuide ...
                    - E .* abs(J .* X_guide - Xi);

                X_new(i, :) = apply_bounds(candidate, lb, ub);

            % B2: Hard besiege
            elseif r >= 0.5 && abs(E_phase) < 0.5

                candidate = X_guide ...
                    - E .* abs(DeltaGuide);

                X_new(i, :) = apply_bounds(candidate, lb, ub);

            % B3: Soft besiege with progressive rapid dives
            elseif r < 0.5 && abs(E_phase) >= 0.5

                Y = X_guide ...
                    - E .* abs(J .* X_guide - Xi);

                Y = apply_bounds(Y, lb, ub);

                LF = levy_flight(dim, 1.5);

                Z = Y + rand(1, dim) .* LF;
                Z = apply_bounds(Z, lb, ub);

                isDive(i) = true;
                Y_all(i, :) = Y;
                Z_all(i, :) = Z;

            % B4: Hard besiege with progressive rapid dives
            else

                Y = X_guide ...
                    - E .* abs(J .* X_guide - X_mean);

                Y = apply_bounds(Y, lb, ub);

                LF = levy_flight(dim, 1.5);

                Z = Y + rand(1, dim) .* LF;
                Z = apply_bounds(Z, lb, ub);

                isDive(i) = true;
                Y_all(i, :) = Y;
                Z_all(i, :) = Z;
            end
        end
    end

    %% ====================== Rapid-Dive Candidate Evaluation ============

    diveIndex = find(isDive);

    if ~isempty(diveIndex)

        Y_dive = Y_all(diveIndex, :);
        Z_dive = Z_all(diveIndex, :);

        candidatePool = [Y_dive; Z_dive];

        f_candidate = evaluate_population_parallel( ...
            candidatePool, fun, penaltyValue, useParallel);

        nDive = numel(diveIndex);

        % Both Y and Z require one additional forward calculation.
        nEval = nEval + 2 * nDive;

        f_Y = f_candidate(1:nDive);
        f_Z = f_candidate(nDive + 1:end);

        for k = 1:nDive

            i = diveIndex(k);

            % Preserve the standard HHO Y -> Z -> current-position
            % acceptance sequence.
            if f_Y(k) < f_old(i)

                X_new(i, :) = Y_dive(k, :);

            elseif f_Z(k) < f_old(i)

                X_new(i, :) = Z_dive(k, :);

            else

                X_new(i, :) = X_old(i, :);
            end
        end
    end

    %% ====================== Stagnation Repair ==========================

    repairTriggered = false;

    repairCondition = ...
        cfg.useStagnationRepair && ...
        noImproveCount >= stagnationLimit && ...
        tau >= repairStartRatio && ...
        tau <= repairEndRatio && ...
        diversityRatio <= repairDiversityThreshold;

    if repairCondition

        repairTriggered = true;

        % Identify the worst-performing individuals in the previous
        % generation according to their objective-function values.
        [~, worstOrder] = sort(f_old, 'descend');

        nRepair = max(1, round(repairRatio * nPop));
        repairIndex = worstOrder(1:nRepair);

        % Use a relatively broad repair range in the early stage
        % and gradually reduce the perturbation in the later stage.
        sigmaRepair = 0.020 * (1 - tau) + 0.002;

        for k = 1:nRepair

            i = repairIndex(k);

            X_new(i, :) = stagnation_repair( ...
                X_old(i, :), X_guide, lb, ub, sigmaRepair);
        end

        % Prevent repeated repair activation over consecutive
        % iterations under the same stagnation state.
        noImproveCount = 0;
    end

    %% ====================== Population and Best-Value Update ===========

    X = X_new;

    f_X = evaluate_population_parallel(X, fun, penaltyValue, useParallel);

    % The complete population requires nPop objective-function
    % evaluations during each iteration.
    nEval = nEval + nPop;

    [f_curr, bestIndex] = min(f_X);

    f_previous = f_best;

    if f_curr < f_best
        f_best = f_curr;
        X_best = X(bestIndex, :);
    end

    % Determine whether a substantial global improvement occurred.
    improveTolerance = 1e-12 * max(1, abs(f_previous));

    if f_best < f_previous - improveTolerance

        noImproveCount = 0;

    else

        noImproveCount = noImproveCount + 1;
    end

    histout(t) = f_best;

    %% ====================== Store Diagnostic Data ======================

    diagnostics.diversityRatio(t) = diversityRatio;
    diagnostics.energyEnvelope(t) = E1_effective;
    diagnostics.guideWeight(t) = wBest;
    diagnostics.stagnationCount(t) = noImproveCount;
    diagnostics.repairFlag(t) = repairTriggered;
    diagnostics.evalHistory(t) = nEval;

    if mod(t, 10) == 0 || t == 2 || t == maxIter

        if repairTriggered
            repairText = ', stagnation repair triggered';
        else
            repairText = '';
        end

        fprintf(['DAEG-HHO: iteration %d / %d, ', ...
                 'best objective value = %.8e, ', ...
                 'relative diversity = %.3f%s\n'], ...
            t, maxIter, f_best, diversityRatio, repairText);
    end
end

diagnostics.totalEvaluations = nEval;

fprintf('DAEG-HHO completed: final best objective value = %.8e\n', ...
    f_best);
fprintf('Total objective-function evaluations = %d\n', nEval);

end


%% =========================== Local Functions ===========================

function cfg = resolve_strategy_config(cfg)

if ~isstruct(cfg) || numel(cfg) ~= 1
    error('cfg must be a scalar structure.');
end

defaultConfig = struct();

defaultConfig.useAdaptiveEJ = true;
defaultConfig.useEliteGuidance = true;
defaultConfig.useStagnationRepair = true;

fieldList = fieldnames(defaultConfig);

for k = 1:numel(fieldList)

    fieldName = fieldList{k};

    if ~isfield(cfg, fieldName) || isempty(cfg.(fieldName))
        cfg.(fieldName) = defaultConfig.(fieldName);
    end

    if ~isscalar(cfg.(fieldName))
        error('cfg.%s must be a logical scalar.', fieldName);
    end

    cfg.(fieldName) = logical(cfg.(fieldName));
end

end


function useParallel = prepare_parallel_pool(useParallel)

if ~useParallel
    return;
end

try
    if ~license('test', 'Distrib_Computing_Toolbox')

        warning(['Parallel Computing Toolbox was not detected. ', ...
                 'Serial computation will be used instead.']);
        useParallel = false;
        return;
    end

    if isempty(gcp('nocreate'))
        parpool('local');
    end

catch ME

    warning(['The parallel pool could not be started. ', ...
             'Serial computation will be used instead: %s'], ...
             ME.message);
    useParallel = false;
end

end


function Xout = apply_bounds(Xin, lb, ub)

Xout = Xin;

% Replace rare NaN or Inf values generated by Levy-flight
% perturbations or other numerical anomalies.
badMask = ~isfinite(Xout);

if any(badMask(:))

    nRow = size(Xout, 1);
    midpoint = 0.5 .* (lb + ub);

    midpointMatrix = repmat(midpoint, nRow, 1);

    Xout(badMask) = midpointMatrix(badMask);
end

Xout = min(max(Xout, lb), ub);

end


function fvals = evaluate_population_parallel( ...
    pop, fun, penaltyValue, useParallel)

n = size(pop, 1);

fvals = penaltyValue .* ones(n, 1);

if useParallel

    parfor i = 1:n

        try
            temp = fun(pop(i, :));

            if isempty(temp) || ~isscalar(temp) || ...
                    ~isreal(temp) || ~isfinite(temp)

                fvals(i) = penaltyValue;

            else

                fvals(i) = double(temp);
            end

        catch

            fvals(i) = penaltyValue;
        end
    end

else

    for i = 1:n

        try
            temp = fun(pop(i, :));

            if isempty(temp) || ~isscalar(temp) || ...
                    ~isreal(temp) || ~isfinite(temp)

                fvals(i) = penaltyValue;

            else

                fvals(i) = double(temp);
            end

        catch

            fvals(i) = penaltyValue;
        end
    end
end

end


function D = population_diversity(X, lb, ub)
% Calculate population diversity in the normalized parameter space.
% Fixed dimensions satisfying ub == lb are excluded from normalization
% and diversity calculation.

nPop = size(X, 1);

range = ub - lb;

% Only dimensions with different lower and upper bounds participate
% in the actual search.
freeMask = range > eps;

% If all dimensions are fixed, define the population diversity as zero.
if ~any(freeMask)
    D = 0;
    return;
end

X_free = X(:, freeMask);
lb_free = lb(freeMask);
range_free = range(freeMask);

X_normalized = ...
    (X_free - repmat(lb_free, nPop, 1)) ./ ...
    repmat(range_free, nPop, 1);

X_center = mean(X_normalized, 1);

distance = sqrt(sum( ...
    (X_normalized - repmat(X_center, nPop, 1)).^2, 2));

D = mean(distance);

end


function Xrepair = stagnation_repair( ...
    Xi, Xguide, lb, ub, sigmaRepair)
% Repair a poorly performing individual using elite-neighborhood
% relocation and bounded Cauchy perturbation.
%
% Xi          : current poorly performing individual
% Xguide      : current elite guidance position
% sigmaRepair : perturbation scale

dim = numel(Xi);

% Place the repaired individual near the segment between the guidance
% position and its original position, avoiding direct duplication of
% the guidance position or excessive departure from the feasible region.
alpha = 0.15 + 0.15 .* rand(1, dim);

% Bounded Cauchy perturbation preserves the possibility of escaping
% from a local region while preventing extreme values from forcing
% all variables directly onto their bounds.
cauchyNoise = tan(pi .* (rand(1, dim) - 0.5));
cauchyNoise = min(max(cauchyNoise, -3), 3);

Xrepair = Xguide ...
    + alpha .* (Xi - Xguide) ...
    + sigmaRepair .* (ub - lb) .* cauchyNoise;

Xrepair = apply_bounds(Xrepair, lb, ub);

end


function step = levy_flight(dim, beta)

sigma = ( ...
    gamma(1 + beta) .* sin(pi .* beta ./ 2) ./ ...
    (gamma((1 + beta) ./ 2) .* beta .* ...
    2.^((beta - 1) ./ 2)) ...
    ) .^ (1 ./ beta);

u = sigma .* randn(1, dim);
v = randn(1, dim);

step = 0.01 .* u ./ (abs(v) .^ (1 ./ beta) + eps);

end