function [f_best, X_best, histout, diagnostics] = ...
   ```matlab
function [f_best, X_best, histout, diagnostics] = ...
    HHO_Core_Rayleigh( ...
    HHO_Core_Rayleigh( ...
    nPop, maxIter, lb, ub, fun, use nPop, maxIter, lb, ub, fun, useParallel, searchSeed, initMethod, cfg)

if nargin < 6 || isempty(useParallel)
    useParallelParallel, searchSeed, initMethod, cfg)

if nargin < 6 || isempty(useParallel)
    useParallel = true;
end

if nargin < 7
    = true;
end

if nargin < 7
    searchSeed = [];
end

if nargin < 8 || isempty searchSeed = [];
end

if nargin < 8 || isempty(initMethod)
    initMethod = 'random';
end

if nargin < 9 ||(initMethod)
    initMethod = 'random';
end

if nargin < 9 || isempty(cfg)
    cfg = struct();
end

if ~isa(fun, ' isempty(cfg)
    cfg = struct();
end

if ~isa(fun, 'function_handle')
    error('fun must be an objective-function handle.');
end

function_handle')
    error('fun must be an objective-function handle.');
end

if ~isscalar(nPop) || ~isfinite(nPop) ||if ~isscalar(nPop) || ~isfinite(nPop) || ...
        nPop < 4 || nPop ~= floor(nPop)
    ...
        nPop < 4 || nPop ~= floor(nPop)
    error('nPop must be an integer greater than or equal to 4.');
 error('nPop must be an integer greater than or equal to 4.');
end

if ~isscalar(maxIter) || ~isfinite(maxIter) ||end

if ~isscalar(maxIter) || ~isfinite(maxIter) || ...
        maxIter < 1 || maxIter ~= floor(maxIter)
    ...
        maxIter < 1 || maxIter ~= floor(maxIter)
    error('maxIter must be a positive integer.');
end

if ~ error('maxIter must be a positive integer.');
end

if ~isscalar(useParallel)
    error('useParallel must be a logical orisscalar(useParallel)
    error('useParallel must be a logical or numeric scalar.');
end

useParallel = logical(useParallel);

if ~isempty(search numeric scalar.');
end

useParallel = logical(useParallel);

if ~isempty(searchSeed)
    if ~isscalar(searchSeed) || ~isfinite(searchSeedSeed)
    if ~isscalar(searchSeed) || ~isfinite(searchSeed)
        error('searchSeed must be empty or a finite scalar.');
    end
)
        error('searchSeed must be empty or a finite scalar.');
    end
end

lb = double(lb(:).');
ub = double(ub(:).');

if numel(lb) ~=end

lb = double(lb(:).');
ub = double(ub(:).');

if numel(lb) ~= numel(ub)
    error('lb and ub must have the same dimensions.');
end

if any(~isfinite numel(ub)
    error('lb and ub must have the same dimensions.');
end

if any(~isfinite(lb)) || any(~isfinite(ub))
    error('lb and ub(lb)) || any(~isfinite(ub))
    error('lb and ub must not contain NaN or Inf.');
end

if any(ub < lb must not contain NaN or Inf.');
end

if any(ub < lb)
    error('Each dimension must satisfy ub >= lb.');
end

initMethod =)
    error('Each dimension must satisfy ub >= lb.');
end

initMethod = lower(char(initMethod));

if ~ismember(initMethod, {'random', ' lower(char(initMethod));

if ~ismember(initMethod, {'random', 'sobol'})
    error('initMethod must be either ''random'' or ''sobol'})
    error('initMethod must be either ''random'' or ''sobol''.');
end

cfg = resolve_config(cfg);

dim = numsobol''.');
end

cfg = resolve_config(cfg);

dim = numel(lb);
penaltyValue = 1e30;

useParallel = prepareel(lb);
penaltyValue = 1e30;

useParallel = prepare_parallel_pool(useParallel);

eliteRatio = 0.20;
energyGain = _parallel_pool(useParallel);

eliteRatio = 0.20;
energyGain = 0.35;

stagnationLimit = max(4, round(0.35;

stagnationLimit = max(4, round(0.05 * maxIter));
repairRatio = 0.15;
repair0.05 * maxIter));
repairRatio = 0.15;
repairStartRatio = 0.15;
repairEndRatio = 0.85StartRatio = 0.15;
repairEndRatio = 0.85;
repairDiversityThreshold = 0.55;
relativeImproveTol = ;
repairDiversityThreshold = 0.55;
relativeImproveTol = 1e-4;
repairCooldown = max(2, round(0.1e-4;
repairCooldown = max(2, round(0.03 * maxIter));

if strcmp(initMethod, 'random')
   03 * maxIter));

if strcmp(initMethod, 'random')
    U = rand(nPop, dim);
else
    U = sobol U = rand(nPop, dim);
else
    U = sobol_points(nPop, dim);
end

X = repmat(lb, nPop_points(nPop, dim);
end

X = repmat(lb, nPop, 1) + ...
    U .* repmat((ub - lb),, 1) + ...
    U .* repmat((ub - lb), nPop, 1);

f_X = evaluate_population(X, fun, penalty nPop, 1);

f_X = evaluate_population(X, fun, penaltyValue, useParallel);

if all(f_X >= penaltyValue * 0.Value, useParallel);

if all(f_X >= penaltyValue * 0.999)
    error([ ...
        'All initial models failed during forward calculation.',999)
    error([ ...
        'All initial models failed during forward calculation.', newline, ...
        'Check the newline, ...
        'Check the parameter bounds, parameter ordering, forward solver, ', ...
        'and objective parameter bounds, parameter ordering, forward solver, ', ...
        'and objective-function output.']);
end

[f_best, bestIndex] = min(f_X);
-function output.']);
end

[f_best, bestIndex] = min(f_X);
X_best = X(bestIndex, :);

histout = zeros(1,X_best = X(bestIndex, :);

histout = zeros(1, maxIter);
histout(1) = f_best;

if ~isempty(searchSeed)
    rng(searchSeed, ' maxIter);
histout(1) = f_best;

if ~isempty(searchSeed)
    rng(searchSeed, 'twister');
end

D0 = population_diversity(X, lb, ub);

if ~isfinite(D0) || D0 <= eps
   twister');
end

D0 = population_diversity(X, lb, ub);

if ~isfinite(D0) || D0 <= eps
    D0 = 1;
end

nEval = nPop;
 D0 = 1;
end

nEval = nPop;
noImproveCount = 0;
lastRepairIter = -inf;

diagnosticsnoImproveCount = 0;
lastRepairIter = -inf;

diagnostics = struct();

diagnostics.algorithmName = cfg.algorithmName;
diagnostics.initialization = initMethod;
diagnostics.config = cfg;

diagnostics.populationSize = n = struct();

diagnostics.algorithmName = cfg.algorithmName;
diagnostics.initialization = initMethod;
diagnostics.config = cfg;

diagnostics.populationSize = nPop;
diagnostics.dimension = dim;
diagnostics.maxIteration = maxIter;
Pop;
diagnostics.dimension = dim;
diagnostics.maxIteration = maxIter;
diagnostics.initialDiversity = D0;
diagnostics.iterationIndex = diagnostics.initialDiversity = D0;
diagnostics.iterationIndex = 1:maxIter;

diagnostics.repairParameters = struct( ...
    'st1:maxIter;

diagnostics.repairParameters = struct( ...
    'stagnationLimit', stagnationLimit, ...
    'repairRatio', repairRatioagnationLimit', stagnationLimit, ...
    'repairRatio', repairRatio, ...
    'repairStartRatio', repairStartRatio, ...
    'repair, ...
    'repairStartRatio', repairStartRatio, ...
    'repairEndRatio', repairEndRatio, ...
    'repairDiversityThreshold', repairEndRatio', repairEndRatio, ...
    'repairDiversityThreshold', repairDiversityThreshold, ...
    'relativeImproveTol', relativeImproveTol, ...
    'DiversityThreshold, ...
    'relativeImproveTol', relativeImproveTol, ...
    'repairCooldown', repairCooldown);

diagnostics.bestFitnessHistory = nan(1,repairCooldown', repairCooldown);

diagnostics.bestFitnessHistory = nan(1, maxIter);
diagnostics.currentBestFitnessHistory = nan(1, maxIter);
diagnostics.currentBestFitnessHistory = nan(1, maxIter);
diagnostics.meanFitnessHistory = nan(1, maxIter);

 maxIter);
diagnostics.meanFitnessHistory = nan(1, maxIter);

diagnostics.bestPositionHistory = nan(maxIter, dim);
diagnostics.currentBestdiagnostics.bestPositionHistory = nan(maxIter, dim);
diagnostics.currentBestPositionHistory = nan(maxIter, dim);
diagnostics.meanPositionHistory = nan(maxIter, dim);

PositionHistory = nan(maxIter, dim);
diagnostics.meanPositionHistory = nan(maxIter, dim);

diagnostics.updateDiversityRatio = nan(1,diagnostics.updateDiversityRatio = nan(1, maxIter);
diagnostics.diversityRatio = nan(1, maxIter);
 maxIter);
diagnostics.diversityRatio = nan(1, maxIter);
diagnostics.collapseDegree = nan(1, maxIter);
diagnostics.stagnationCount =diagnostics.collapseDegree = nan(1, maxIter);
diagnostics.stagnationCount = nan(1, maxIter);
diagnostics nan(1, maxIter);
diagnostics.energyEnvelope = nan(1, maxIter);
diagnostics.guideWeight =.energyEnvelope = nan(1, maxIter);
diagnostics.guideWeight = nan(1, maxIter);
diagnostics.repairFlag = false(1, nan(1, maxIter);
diagnostics.repairFlag = false(1, maxIter);
diagnostics.evalHistory = nan(1, maxIter);

 maxIter);
diagnostics.evalHistory = nan(1, maxIter);

if cfg.savePopulationHistory
    diagnostics.populationHistory = cell(maxIter, if cfg.savePopulationHistory
    diagnostics.populationHistory = cell(maxIter, 1);
    diagnostics.fitnessHistory = cell(maxIter, 1);
else
   1);
    diagnostics.fitnessHistory = cell(maxIter, 1);
else
    diagnostics.populationHistory = [];
    diagnostics.fitnessHistory = [];
end

 diagnostics.populationHistory = [];
    diagnostics.fitnessHistory = [];
end

if cfg.saveIterationData

    [f_current_best, currentBestIndex] = min(f_X);

    diagnostics.bestFitnessHistory(1) =if cfg.saveIterationData

    [f_current_best, currentBestIndex] = min(f_X);

    diagnostics.bestFitnessHistory(1) = f_best;
    diagnostics.currentBestFitnessHistory(1) = f_current_best f_best;
    diagnostics.currentBestFitnessHistory(1) = f_current_best;
    diagnostics.meanFitnessHistory(1) = ...
;
    diagnostics.meanFitnessHistory(1) = ...
        mean_valid_fitness(f_X, penaltyValue);

    diagnostics.best        mean_valid_fitness(f_X, penaltyValue);

    diagnostics.bestPositionHistory(1, :) = X_best;
    diagnostics.currentBestPositionHistoryPositionHistory(1, :) = X_best;
    diagnostics.currentBestPositionHistory(1, :) = ...
        X(currentBestIndex, :);

    diagnostics(1, :) = ...
        X(currentBestIndex, :);

    diagnostics.meanPositionHistory(1, :) = mean(X, 1);

    diagnostics.meanPositionHistory(1, :) = mean(X, 1);

    diagnostics.updateDiversityRatio(1) = 1;
    diagnostics.diversity.updateDiversityRatio(1) = 1;
    diagnostics.diversityRatio(1) = 1;
   Ratio(1) = 1;
    diagnostics.collapseDegree(1) = 0;
    diagnostics.collapseDegree(1) = 0;
    diagnostics.stagnationCount(1) = 0;
    diagnostics.energy diagnostics.stagnationCount(1) = 0;
    diagnostics.energyEnvelope(1) = 2;
    diagnostics.guideWeight(1) = Envelope(1) = 2;
    diagnostics.guideWeight(1) = 1;
    diagnostics.repairFlag(1) = false;
   1;
    diagnostics.repairFlag(1) = false;
    diagnostics.evalHistory(1) = nEval;

    if cfg.savePopulationHistory diagnostics.evalHistory(1) = nEval;

    if cfg.savePopulationHistory
        diagnostics.populationHistory{1} = X;
        diagnostics.fitnessHistory
        diagnostics.populationHistory{1} = X;
        diagnostics.fitnessHistory{1} = f_X;
    end
end

for t = 2:maxIter

   {1} = f_X;
    end
end

for t = 2:maxIter

    X_old = X;
    f_old = f_X;

    X_old = X;
    f_old = f_X;

    X_mean = mean(X_old, 1);

    tau = (t - X_mean = mean(X_old, 1);

    tau = (t - 1) / (maxIter - 1);

    E1 1) / (maxIter - 1);

    E1_base = 2 * (1 - t / maxIter);

    D_now_base = 2 * (1 - t / maxIter);

    D_now = population_diversity(X_old, lb, ub);

    diversityRatio = = population_diversity(X_old, lb, ub);

    diversityRatio = D_now / (D0 + eps);
    D_now / (D0 + eps);
    diversityRatio = min(max(diversityRatio, 0), 1);

 diversityRatio = min(max(diversityRatio, 0), 1);

    if cfg.useEliteGuidance

        [~, rankIndex] =    if cfg.useEliteGuidance

        [~, rankIndex] = sort(f_old, 'ascend');

        nElite = max(2, sort(f_old, 'ascend');

        nElite = max(2, round(eliteRatio * nPop));
        eliteIndex = rankIndex(1 round(eliteRatio * nPop));
        eliteIndex = rankIndex(1:nElite);

        X_elite_mean = mean(X_old(eliteIndex, :), :nElite);

        X_elite_mean = mean(X_old(eliteIndex, :), 1);

        wBest = 0.25 + 0.1);

        wBest = 0.25 + 0.75 * tau;

        X_guide = wBest .* X_best + ...
           75 * tau;

        X_guide = wBest .* X_best + ...
            (1 - wBest) .* X_elite_mean;

    else

        (1 - wBest) .* X_elite_mean;

    else

        wBest = 1;
        X_guide = X_best;
    wBest = 1;
        X_guide = X_best;
    end

    if cfg.useAdaptiveEJ

        E1_effective end

    if cfg.useAdaptiveEJ

        E1_effective = E1_base * ...
            (1 + energyGain * (1 - = E1_base * ...
            (1 + energyGain * (1 - diversityRatio));

        E1_effective = min(E1_effective,  diversityRatio));

        E1_effective = min(E1_effective, 2);

    else

        E1_effective = E1_base;
    end

2);

    else

        E1_effective = E1_base;
    end

    X_new = X_old;

    isDive = false(nPop    X_new = X_old;

    isDive = false(nPop, 1);
    Y_all = zeros(nPop, dim);
    Z_all =, 1);
    Y_all = zeros(nPop, dim);
    Z_all = zeros(nPop, dim);

    for i = 1:nPop zeros(nPop, dim);

    for i = 1:nPop

        Xi = X_old(i, :);

        E0 = 2 *

        Xi = X_old(i, :);

        E0 = 2 * rand() - 1;

        E_phase = E1_base * E rand() - 1;

        E_phase = E1_base * E0;
        E = E1_effective * E0;

        if abs0;
        E = E1_effective * E0;

        if abs(E_phase) >= 1

            q = rand();

            if q >= (E_phase) >= 1

            q = rand();

            if q >= 0.5

                randIndex = randi0.5

                randIndex = randi(nPop);
                X_rand = X_old(randIndex, :);

                r1 =(nPop);
                X_rand = X_old(randIndex, :);

                r1 = rand();
                r2 = rand();

                candidate = X_rand ...
                    - rand();
                r2 = rand();

                candidate = X_rand ...
                    - r1 .* abs(X_rand - 2 .* r2 .* Xi r1 .* abs(X_rand - 2 .* r2 .* Xi);

            else

                r3 = rand();
                r4 = rand();

               );

            else

                r3 = rand();
                r4 = rand();

                candidate = (X_guide - X_mean) ...
                    - r3 .* candidate = (X_guide - X_mean) ...
                    - r3 .* (lb + r4 .* (ub - lb));
            end

            X_new(i, :) = (lb + r4 .* (ub - lb));
            end

            X_new(i, :) = apply_bounds(candidate, lb, ub);

        else

            r = apply_bounds(candidate, lb, ub);

        else

            r = rand();

            if cfg.useAdaptiveEJ
                J =  rand();

            if cfg.useAdaptiveEJ
                J = 1 + (2 * rand() - 1) * diversity1 + (2 * rand() - 1) * diversityRatio;
            else
                J = 2 * (1 - rand());
           Ratio;
            else
                J = 2 * (1 - rand());
            end

            DeltaGuide = X_guide - Xi;

            if r >= end

            DeltaGuide = X_guide - Xi;

            if r >= 0.5 && abs(E_phase) >= 0.5

                0.5 && abs(E_phase) >= 0.5

                candidate = DeltaGuide ...
                    - E .* abs(J .* X_guide candidate = DeltaGuide ...
                    - E .* abs(J .* X_guide - Xi);

                X_new(i, :) = apply_bounds(candidate, lb, - Xi);

                X_new(i, :) = apply_bounds(candidate, lb, ub);

            elseif r >= 0.5 && abs(E_phase) < 0. ub);

            elseif r >= 0.5 && abs(E_phase) < 0.5

                candidate = X_guide ...
                    - E .*5

                candidate = X_guide ...
                    - E .* abs(DeltaGuide);

                X_new(i, :) = apply_bounds(candidate, abs(DeltaGuide);

                X_new(i, :) = apply_bounds(candidate, lb, ub);

            elseif r < 0.5 && abs(E_phase lb, ub);

            elseif r < 0.5 && abs(E_phase) >= 0.5

                Y = X_guide ...
                    - E .*) >= 0.5

                Y = X_guide ...
                    - E .* abs(J .* X_guide - Xi);

                Y = apply_bounds abs(J .* X_guide - Xi);

                Y = apply_bounds(Y, lb, ub);

                LF = levy_flight(dim, 1.(Y, lb, ub);

                LF = levy_flight(dim, 1.5);

                Z = Y + rand(1, dim) .* LF5);

                Z = Y + rand(1, dim) .* LF;
                Z = apply_bounds(Z, lb, ub);

                isDive(i) =;
                Z = apply_bounds(Z, lb, ub);

                isDive(i) = true;
                Y_all(i, :) = Y;
                Z_all(i, true;
                Y_all(i, :) = Y;
                Z_all(i, :) = Z;

            else

                Y = X_guide ...
                    - :) = Z;

            else

                Y = X_guide ...
                    - E .* abs(J .* X_guide - X_mean);

                Y = E .* abs(J .* X_guide - X_mean);

                Y = apply_bounds(Y, lb, ub);

                LF = levy_flight(dim,  apply_bounds(Y, lb, ub);

                LF = levy_flight(dim, 1.5);

                Z = Y + rand(1, dim) .*1.5);

                Z = Y + rand(1, dim) .* LF;
                Z = apply_bounds(Z, lb, ub);

                LF;
                Z = apply_bounds(Z, lb, ub);

                isDive(i) = true;
                Y_all(i, :) = Y;
                isDive(i) = true;
                Y_all(i, :) = Y;
                Z_all(i, :) = Z;
            end
        end
    end

 Z_all(i, :) = Z;
            end
        end
    end

    diveIndex = find(isDive);

    if ~isempty(dive    diveIndex = find(isDive);

    if ~isempty(diveIndex)

        Y_dive = Y_all(diveIndex, :);
       Index)

        Y_dive = Y_all(diveIndex, :);
        Z_dive = Z_all(diveIndex, :);

        candidatePool = [ Z_dive = Z_all(diveIndex, :);

        candidatePool = [Y_dive; Z_dive];

        f_candidate = evaluate_population( ...
           Y_dive; Z_dive];

        f_candidate = evaluate_population( ...
            candidatePool, fun, penaltyValue, useParallel);

        nDive candidatePool, fun, penaltyValue, useParallel);

        nDive = numel(diveIndex);
        nEval = nEval + 2 * = numel(diveIndex);
        nEval = nEval + 2 * nDive;

        f_Y = f_candidate(1:nDive);
        nDive;

        f_Y = f_candidate(1:nDive);
        f_Z = f_candidate(nDive + 1:end);

        for k =  f_Z = f_candidate(nDive + 1:end);

        for k = 1:nDive

            i = diveIndex(k);

            if f_Y(k)1:nDive

            i = diveIndex(k);

            if f_Y(k) < f_old(i)

                X_new(i, :) = Y < f_old(i)

                X_new(i, :) = Y_dive(k, :);

            elseif f_Z(k) < f_old(i)

_dive(k, :);

            elseif f_Z(k) < f_old(i)

                X_new(i, :) = Z_dive(k, :);

            else

                               X_new(i, :) = Z_dive(k, :);

            else

                X_new(i, :) = X_old(i, :);
            end
        X_new(i, :) = X_old(i, :);
            end
        end
    end

    repairTriggered = false;

    repair end
    end

    repairTriggered = false;

    repairCondition = ...
        cfg.useStagnationRepair && ...
        noImproveCount >=Condition = ...
        cfg.useStagnationRepair && ...
        noImproveCount >= stagnationLimit && ...
        tau >= repairStartRatio && ...
        tau stagnationLimit && ...
        tau >= repairStartRatio && ...
        tau <= repairEndRatio && ...
        diversityRatio <= repairDiversityThreshold && ...
        <= repairEndRatio && ...
        diversityRatio <= repairDiversityThreshold && ...
        (t - lastRepairIter >= repairCooldown);

    if repairCondition

        (t - lastRepairIter >= repairCooldown);

    if repairCondition

        repairTriggered = true;

        [~, worstOrder] = sort(f_old repairTriggered = true;

        [~, worstOrder] = sort(f_old, 'descend');

        nRepair = min( ...
           , 'descend');

        nRepair = min( ...
            nPop - 1, ...
            max(1, round(re nPop - 1, ...
            max(1, round(repairRatio * nPop)));

        repairIndex = worstOrder(1pairRatio * nPop)));

        repairIndex = worstOrder(1:nRepair);

        sigmaRepair = 0.04 * (1 - tau:nRepair);

        sigmaRepair = 0.04 * (1 - tau) + 0.006;

        for k = 1:nRepair

            i = repairIndex(k);

            X_new(i, :) = stagnation_repair( ...
                X_old(i, :), ...
                X_guide) + 0.006;

        for k = 1:nRepair

            i = repairIndex(k);

            X_new(i, :) = stagnation_repair( ...
                X_old(i, :), ...
                X_guide, ...
                lb, ...
                ub, ...
                sigmaRepair);
        end

       , ...
                lb, ...
                ub, ...
                sigmaRepair);
        end

        noImproveCount = 0;
        lastRepairIter = t;
    noImproveCount = 0;
        lastRepairIter = t;
    end

    X = X_new;

    f_X = evaluate_population( ...
        end

    X = X_new;

    f_X = evaluate_population( ...
        X, fun, penaltyValue, useParallel);

    nEval = X, fun, penaltyValue, useParallel);

    nEval = nEval + nPop;

    [f_curr, bestIndex] = min nEval + nPop;

    [f_curr, bestIndex] = min(f_X);

    f_previous = f_best;

    if f_curr < f_best
        f_best = f_curr;
        X_best = X(bestIndex, :);
    end

    improveTolerance = max( ...
        1e-10, ...
        relativeImproveTol * max(abs(f_previous), 1e-6));

    if f_best < f_previous - improveTolerance
        noImproveCount = 0;
    else
        noImproveCount = noImproveCount + 1;
    end

    histout(t) = f_best;

    if cfg.saveIterationData

        [f_current_best, currentBestIndex] = min(f_X);

        f_mean = mean_valid_fitness(f_X, penaltyValue);

        D_post = population_diversity(X, lb, ub);

        diversityRatio_post = D_post / (D0 + eps);
        diversityRatio_post = min(max(diversityRatio_post, 0), 1);

        collapseDegree_post = 1 - diversityRatio_post;

        diagnostics.bestFitnessHistory(t) = f_best;
        diagnostics.currentBestFitnessHistory(t) = f_current_best;
        diagnostics.meanFitnessHistory(t) = f_mean;

        diagnostics.bestPositionHistory(t, :) = X_best;
        diagnostics.currentBestPositionHistory(t, :) = ...
            X(currentBestIndex, :);

        diagnostics.meanPositionHistory(t, :) = mean(X, 1);

        diagnostics.updateDiversityRatio(t) = diversityRatio;
        diagnostics.diversityRatio(t) = diversityRatio_post;
        diagnostics.collapseDegree(t) = collapseDegree_post;
        diagnostics.stagnationCount(t) = noImproveCount;
        diagnostics.energyEnvelope(t) = E1_effective;
        diagnostics.guideWeight(t) = wBest;
        diagnostics.repairFlag(t) = repairTriggered;
        diagnostics.evalHistory(t) = nEval;

        if cfg.savePopulationHistory
            diagnostics.populationHistory{t} = X;
            diagnostics.fitnessHistory{t} = f_X;
        end
    end
end

diagnostics.totalEvaluations = nEval;

end


function cfg = resolve_config(cfg)

if ~isstruct(cfg) || numel(cfg) ~= 1
    error('cfg must be a scalar structure.');
end

defaults = struct();

defaults.useAdaptiveEJ = false;
defaults.useEliteGuidance = false;
defaults.useStagnationRepair = false;
defaults.saveIterationData = true;
defaults.savePopulationHistory = true;
defaults.verbose = false;
defaults.algorithmName = 'HHO';

fieldNames = fieldnames(defaults);

for k = 1:numel(fieldNames)

    name = fieldNames(f_X);

    f_previous = f_best;

    if f_curr < f_best
        f_best = f_curr;
        X_best = X(bestIndex, :);
    end

    improveTolerance = max( ...
        1e-10, ...
        relativeImproveTol * max(abs(f_previous), 1e-6));

    if f_best < f_previous - improveTolerance
        noImproveCount = 0;
    else
        noImproveCount = noImproveCount + 1;
    end

    histout(t) = f_best;

    if cfg.saveIterationData

        [f_current_best, currentBestIndex] = min(f_X);

        f_mean = mean_valid_fitness(f_X, penaltyValue);

        D_post = population_diversity(X, lb, ub);

        diversityRatio_post = D_post / (D0 + eps);
        diversityRatio_post = min(max(diversityRatio_post, 0), 1);

        collapseDegree_post = 1 - diversityRatio_post;

        diagnostics.bestFitnessHistory(t) = f_best;
        diagnostics.currentBestFitnessHistory(t) = f_current_best;
        diagnostics.meanFitnessHistory(t) = f_mean;

        diagnostics.bestPositionHistory(t, :) = X_best;
        diagnostics.currentBestPositionHistory(t, :) = ...
            X(currentBestIndex, :);

        diagnostics.meanPositionHistory(t, :) = mean(X, 1);

        diagnostics.updateDiversityRatio(t) = diversityRatio;
        diagnostics.diversityRatio(t) = diversityRatio_post;
        diagnostics.collapseDegree(t) = collapseDegree_post;
        diagnostics.stagnationCount(t) = noImproveCount;
        diagnostics.energyEnvelope(t) = E1_effective;
        diagnostics.guideWeight(t) = wBest;
        diagnostics.repairFlag(t) = repairTriggered;
        diagnostics.evalHistory(t) = nEval;

        if cfg.savePopulationHistory
            diagnostics.populationHistory{t} = X;
            diagnostics.fitnessHistory{t} = f_X;
        end
    end
end

diagnostics.totalEvaluations = nEval;

end


function cfg = resolve_config(cfg)

if ~isstruct(cfg) || numel(cfg) ~= 1
    error('cfg must be a scalar structure.');
end

defaults = struct();

defaults.useAdaptiveEJ = false;
defaults.useEliteGuidance = false;
defaults.useStagnationRepair = false;
defaults.saveIterationData = true;
defaults.savePopulationHistory = true;
defaults.verbose = false;
defaults.algorithmName = 'HHO';

fieldNames = fieldnames(defaults);

for k = 1:numel(fieldNames)

    name = fieldNames{k};

    if ~isfield(cfg, name) || isempty(cfg.(name))
       {k};

    if ~isfield(cfg, name) || isempty(cfg.(name))
        cfg.(name) = defaults.(name);
    end
end

 cfg.(name) = defaults.(name);
    end
end

logicalNames = { ...
    'useAdaptiveEJ', ...
    'uselogicalNames = { ...
    'useAdaptiveEJ', ...
    'useEliteGuidance', ...
    'useStagnationRepair', ...
    'EliteGuidance', ...
    'useStagnationRepair', ...
    'saveIterationData', ...
    'savePopulationHistory', ...
    'verbose'};

saveIterationData', ...
    'savePopulationHistory', ...
    'verbose'};

for k = 1:numel(logicalNames)

    name = logicalfor k = 1:numel(logicalNames)

    name = logicalNames{k};

    if ~isscalar(cfg.(name))
        error('cfgNames{k};

    if ~isscalar(cfg.(name))
        error('cfg.%s must be a logical scalar.', name);
    end

    cfg.(.%s must be a logical scalar.', name);
    end

    cfg.(name) = logical(cfg.(name));
end

if ~(ischar(cfg.algorithmname) = logical(cfg.(name));
end

if ~(ischar(cfg.algorithmName) || isstring(cfg.algorithmName))
    error('cfg.algorithmName mustName) || isstring(cfg.algorithmName))
    error('cfg.algorithmName must be a character vector or be a character vector or string.');
end

cfg.algorithmName = char(cfg.algorithmName);

end


function U = string.');
end

cfg.algorithmName = char(cfg.algorithmName);

end


function U = sobol_points(nPop, dim)

try

    p = sob sobol_points(nPop, dim)

try

    p = sobolset(dim, 'Skip', 1024, 'Leap', 3);

catch ME

   olset(dim, 'Skip', 1024, 'Leap', 3);

catch ME

    error([ ...
        'Unable error([ ...
        'Unable to create the Sobol sequence. Confirm that Statistics to create the Sobol sequence. Confirm that Statistics ', ...
        'and Machine Learning Toolbox is installed. Original error: ', ...
        ', ...
        'and Machine Learning Toolbox is installed. Original error: ', ...
        ME.message]);
end

try

    p = scramble(p, 'Mat ME.message]);
end

try

    p = scramble(p, 'MatousekAffineOwen');

catch

    warning([ ...
        'MatouseousekAffineOwen');

catch

    warning([ ...
        'MatousekAffineOwen scrambling is unavailablekAffineOwen scrambling is unavailable. ', ...
        'An unscr. ', ...
        'An unscrambled Sobol sequence will be used.']);
end

ambled Sobol sequence will be used.']);
end

U = net(p, nPop);

if any(~isfinite(U(:)))U = net(p, nPop);

if any(~isfinite(U(:))) || any(U(:) < 0) || any(U(:) >  || any(U(:) < 0) || any(U(:) > 1)
    error('The generated Sobol sequence is1)
    error('The generated Sobol sequence is invalid.');
end

end


function useParallel = prepare_parallel_pool(useParallel)

if ~ invalid.');
end

end


function useParallel = prepare_parallel_pool(useParallel)

if ~useParallel
    return;
end

try

    if ~license('useParallel
    return;
end

try

    if ~license('test', 'Distrib_Computing_Toolbox')

        warning([ ...
            'test', 'Distrib_Computing_Toolbox')

        warning([ ...
            'Parallel Computing Toolbox was not detected. ', ...
            'Serial computation willParallel Computing Toolbox was not detected. ', ...
            'Serial computation will be used.']);

        be used.']);

        useParallel = false;
        return;
    end

    if isempty(g useParallel = false;
        return;
    end

    if isempty(gcp('nocreate'))
        parpool('local');
    end

catch ME

   cp('nocreate'))
        parpool('local');
    end

catch ME

    warning([ ...
        'The parallel pool could not be started. ', ...
        warning([ ...
        'The parallel pool could not be started. ', ...
        'Serial computation will be used: %s'], ...
        ME.message);

    'Serial computation will be used: %s'], ...
        ME.message);

    useParallel = false;
end

end


function Xout = apply useParallel = false;
end

end


function Xout = apply_bounds(Xin, lb, ub)

Xout = Xin;

badMask = ~_bounds(Xin, lb, ub)

Xout = Xin;

badMask = ~isfinite(Xout);

if any(badMask(:))

    nRowsisfinite(Xout);

if any(badMask(:))

    nRows = size(Xout, 1);

    midpoint = 0.5 .* ( = size(Xout, 1);

    midpoint = 0.5 .* (lb + ub);
    midpointMatrix =lb + ub);
    midpointMatrix = repmat(midpoint, nRows, 1);

    Xout(b repmat(midpoint, nRows, 1);

    Xout(badMask) = midpointMatrix(badadMask) = midpointMatrix(badMask);
end

nRows = size(Xout, 1);

lbMatrix =Mask);
end

nRows = size(Xout, 1);

lbMatrix = repmat(lb, nRows, 1);
ubMatrix = repmat repmat(lb, nRows, 1);
ubMatrix = repmat(ub, nRows, 1);

Xout = min(max(Xout(ub, nRows, 1);

Xout = min(max(Xout, lbMatrix), ubMatrix);

end


function fvals = evaluate_population( ...
   , lbMatrix), ubMatrix);

end


function fvals = evaluate_population( ...
    pop, fun, penaltyValue, useParallel)

n = size(pop pop, fun, penaltyValue, useParallel)

n = size(pop, 1);

fvals = penaltyValue .* ones(n, , 1);

fvals = penaltyValue .* ones(n, 1);

if useParallel

    parfor i = 1:n

1);

if useParallel

    parfor i = 1:n

        try

            value = fun(pop(i, :));

            if isempty        try

            value = fun(pop(i, :));

            if isempty(value) || ...
                    ~isscalar(value) || ...
                    ~isreal(value) || ...
                    ~isscalar(value) || ...
                    ~isreal(value) || ...
                    ~isfinite(value)

                fvals(i) =(value) || ...
                    ~isfinite(value)

                fvals(i) = penaltyValue;

            else

                fvals(i) = double(value);
            end

        penaltyValue;

            else

                fvals(i) = double(value);
            end

        catch

            fvals(i) = penaltyValue;
        end
    end

 catch

            fvals(i) = penaltyValue;
        end
    end

else

    for i = 1:n

        try

           else

    for i = 1:n

        try

            value = fun(pop(i, :));

            if isempty(value) || ...
 value = fun(pop(i, :));

            if isempty(value) || ...
                    ~isscalar(value) || ...
                    ~isreal(value) || ...
                    ~                    ~isscalar(value) || ...
                    ~isreal(value) || ...
                    ~isfinite(value)

                fvals(i) = penaltyValue;

           isfinite(value)

                fvals(i) = penaltyValue;

            else

                fvals(i) = double(value);
            end

        catch

 else

                fvals(i) = double(value);
            end

        catch

            fvals(i)            fvals(i) = penaltyValue;
        end
    end
end

end


function D = population_diversity(X, lb, ub)

nPop = size(X, 1);

range = ub - lb;

freeMask = range > 1e-12;

if ~any(freeMask)
    D = 0;
    return;
end

Xfree = X(:, freeMask);
lbFree = lb(freeMask);
rangeFree = range(freeMask);

X_normalized = ...
    (Xfree - rep = penaltyValue;
        end
    end
end

end


function D = population_diversity(X, lb, ub)

nPop = size(X, 1);

range = ub - lb;

freeMask = range > 1e-12;

if ~any(freeMask)
    D = 0;
    return;
end

Xfree = X(:, freeMask);
lbFree = lb(freeMask);
rangeFree = range(freeMask);

X_normalized = ...
    (Xfree - repmat(lbFree, nPop, 1)) ./ ...
    repmat(rangeFree, nPop, 1);

X_center = mean(X_normalized,mat(lbFree, nPop, 1)) ./ ...
    repmat(rangeFree, nPop, 1);

X_center = mean(X_normalized, 1);

distance = sqrt(sum( 1);

distance = sqrt(sum( ...
    (X_normalized - repmat(X_center, nPop,  ...
    (X_normalized - repmat(X_center, nPop, 1)) .^ 2, ...
1)) .^ 2, ...
    2));

D = mean(distance);

end


function Xrepair = stagn    2));

D = mean(distance);

end


function Xrepair = stagnation_repair( ...
    Xi, Xguide, lb, ub, sigmaation_repair( ...
    Xi, Xguide, lb, ub, sigmaRepair)

dim = numel(Xi);

alpha = 0.15 +Repair)

dim = numel(Xi);

alpha = 0.15 + 0.15 .* rand(1, dim);

cauchyNoise = 0.15 .* rand(1, dim);

cauchyNoise = tan(pi .* (rand(1, dim) tan(pi .* (rand(1, dim) - 0.5));
cauchyNoise = min(max(cauchy - 0.5));
cauchyNoise = min(max(cauchyNoise, -3), 3);

Xrepair = Xguide ...
    +Noise, -3), 3);

Xrepair = Xguide ...
    + alpha .* (Xi - Xguide) ...
    + sigmaRepair .* (ub alpha .* (Xi - Xguide) ...
    + sigmaRepair .* (ub - lb) .* cauchyNoise;

Xrepair = apply_bounds(Xrepair - lb) .* cauchyNoise;

Xrepair = apply_bounds(Xrepair, lb, ub);

end


function step = levy_flight(dim, beta, lb, ub);

end


function step = levy_flight(dim, beta)

sigma = ( ...
    gamma(1 + beta) .* sin(pi .*)

sigma = ( ...
    gamma(1 + beta) .* sin(pi .* beta ./ 2) ./ ...
    ( ...
 beta ./ 2) ./ ...
    ( ...
        gamma((1 + beta) ./ 2) .* ...
        gamma((1 + beta) ./ 2) .* ...
        beta .* ...
        2 .^ ((beta - 1) ./        beta .* ...
        2 .^ ((beta - 1) ./ 2) ...
    ) ...
    ) .^ (1 ./ beta);

 2) ...
    ) ...
    ) .^ (1 ./ beta);

u = sigma .* randn(1, dim);
v = randn(u = sigma .* randn(1, dim);
v = randn(1, dim);

step = 0.01 .* u ./ ...
    (1, dim);

step = 0.01 .* u ./ ...
    (abs(v) .^ (1 ./ beta) + eps);

end


functionabs(v) .^ (1 ./ beta) + eps);

end


function fMean = mean_valid_fitness(fvals, penaltyValue)

validMask = fMean = mean_valid_fitness(fvals, penaltyValue)

validMask = ...
    isfinite(fvals) & ...
    fvals < penaltyValue * ...
    isfinite(fvals) & ...
    fvals < penaltyValue * 0.999;

validFitness = fvals(validMask);

if isempty(valid 0.999;

validFitness = fvals(validMask);

if isempty(validFitness)
    fMean = penaltyValue;
else
    fMean = meanFitness)
    fMean = penaltyValue;
else
    fMean = mean(validFitness);
end

end
```(validFitness);
end

end