function [f_best, X_best, histout] = HHO_Rayleigh_Standard( ...
    nPop, maxIter, lb, ub, fun, useParallel, searchSeed)

if nargin < 6 || isempty(useParallel)
    useParallel = true;
end

if nargin < 7
    searchSeed = [];
end

if ~isa(fun, 'function_handle')
    error('fun must be an objective-function handle.');
end

lb = double(lb(:).');
ub = double(ub(:).');

if numel(lb) ~= numel(ub)
    error('lb and ub must have the same dimensions.');
end

if any(~isfinite(lb)) || any(~isfinite(ub))
    error('lb and ub must not contain NaN or Inf.');
end

if any(ub <= lb)
    error('Each dimension must satisfy ub > lb.');
end

if ~isscalar(nPop) || ~isfinite(nPop) || ...
        nPop < 4 || nPop ~= floor(nPop)
    error('nPop must be an integer greater than or equal to 4.');
end

if ~isscalar(maxIter) || ~isfinite(maxIter) || ...
        maxIter < 1 || maxIter ~= floor(maxIter)
    error('maxIter must be a positive integer.');
end

if ~isempty(searchSeed) && ...
        (~isscalar(searchSeed) || ~isfinite(searchSeed))
    error('searchSeed must be empty or a finite scalar.');
end

dim = numel(lb);
penaltyValue = 1e30;

useParallel = prepare_parallel_pool(useParallel);

X = repmat(lb, nPop, 1) + ...
    rand(nPop, dim) .* repmat(ub - lb, nPop, 1);

f_X = evaluate_population_parallel( ...
    X, fun, penaltyValue, useParallel);

if all(f_X >= penaltyValue * 0.999)
    error([ ...
        'All randomly initialized models failed during forward ', ...
        'calculation. Check the parameter bounds, the parameter ', ...
        'ordering, the forward solver, and the objective function.']);
end

[f_best, bestIndex] = min(f_X);
X_best = X(bestIndex, :);

histout = zeros(1, maxIter);
histout(1) = f_best;

if ~isempty(searchSeed)
    rng(searchSeed, 'twister');
end

for t = 2:maxIter

    X_old = X;
    f_old = f_X;

    X_mean = mean(X_old, 1);

    E1 = 2 * (1 - t / maxIter);

    X_new = X_old;

    isDive = false(nPop, 1);
    Y_all = zeros(nPop, dim);
    Z_all = zeros(nPop, dim);

    for i = 1:nPop

        Xi = X_old(i, :);

        E0 = 2 * rand() - 1;
        E = E1 * E0;

        if abs(E) >= 1

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

                candidate = (X_best - X_mean) ...
                    - r3 .* (lb + r4 .* (ub - lb));
            end

            X_new(i, :) = apply_bounds(candidate, lb, ub);

        else

            r = rand();

            J = 2 * (1 - rand());

            DeltaX = X_best - Xi;

            if r >= 0.5 && abs(E) >= 0.5

                candidate = DeltaX ...
                    - E .* abs(J .* X_best - Xi);

                X_new(i, :) = apply_bounds(candidate, lb, ub);

            elseif r >= 0.5 && abs(E) < 0.5

                candidate = X_best ...
                    - E .* abs(DeltaX);

                X_new(i, :) = apply_bounds(candidate, lb, ub);

            elseif r < 0.5 && abs(E) >= 0.5

                Y = X_best ...
                    - E .* abs(J .* X_best - Xi);

                Y = apply_bounds(Y, lb, ub);

                LF = levy_flight(dim, 1.5);

                Z = Y + rand(1, dim) .* LF;
                Z = apply_bounds(Z, lb, ub);

                isDive(i) = true;
                Y_all(i, :) = Y;
                Z_all(i, :) = Z;

            else

                Y = X_best ...
                    - E .* abs(J .* X_best - X_mean);

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

    diveIndex = find(isDive);

    if ~isempty(diveIndex)

        Y_dive = Y_all(diveIndex, :);
        Z_dive = Z_all(diveIndex, :);

        candidatePool = [Y_dive; Z_dive];

        f_candidate = evaluate_population_parallel( ...
            candidatePool, fun, penaltyValue, useParallel);

        nDive = numel(diveIndex);

        f_Y = f_candidate(1:nDive);
        f_Z = f_candidate(nDive + 1:end);

        for k = 1:nDive

            i = diveIndex(k);

            if f_Y(k) < f_old(i)

                X_new(i, :) = Y_dive(k, :);

            elseif f_Z(k) < f_old(i)

                X_new(i, :) = Z_dive(k, :);

            else

                X_new(i, :) = X_old(i, :);
            end
        end
    end

    X = X_new;

    f_X = evaluate_population_parallel( ...
        X, fun, penaltyValue, useParallel);

    [f_curr, bestIndex] = min(f_X);

    if f_curr < f_best
        f_best = f_curr;
        X_best = X(bestIndex, :);
    end

    histout(t) = f_best;
end

end


function useParallel = prepare_parallel_pool(useParallel)

if ~isscalar(useParallel)
    error('useParallel must be a logical value or numeric scalar.');
end

useParallel = logical(useParallel);

if ~useParallel
    return;
end

try

    if ~license('test', 'Distrib_Computing_Toolbox')

        warning([ ...
            'Parallel Computing Toolbox was not detected. ', ...
            'Serial computation will be used instead.']);

        useParallel = false;
        return;
    end

    if isempty(gcp('nocreate'))
        parpool('local');
    end

catch ME

    warning([ ...
        'The parallel pool could not be started. ', ...
        'Serial computation will be used instead: %s'], ...
        ME.message);

    useParallel = false;
end

end


function Xout = apply_bounds(Xin, lb, ub)

Xout = min(max(Xin, lb), ub);

end


function fvals = evaluate_population_parallel( ...
    pop, fun, penaltyValue, useParallel)

n = size(pop, 1);

fvals = penaltyValue .* ones(n, 1);

if useParallel

    parfor i = 1:n

        try

            temp = fun(pop(i, :));

            if isempty(temp) || ...
                    ~isscalar(temp) || ...
                    ~isreal(temp) || ...
                    ~isfinite(temp)

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

            if isempty(temp) || ...
                    ~isscalar(temp) || ...
                    ~isreal(temp) || ...
                    ~isfinite(temp)

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


function step = levy_flight(dim, beta)

sigma = ( ...
    gamma(1 + beta) .* sin(pi .* beta ./ 2) ./ ...
    ( ...
        gamma((1 + beta) ./ 2) .* ...
        beta .* ...
        2 .^ ((beta - 1) ./ 2) ...
    ) ...
    ) .^ (1 ./ beta);

u = sigma .* randn(1, dim);
v = randn(1, dim);

step = 0.01 .* u ./ ...
    (abs(v) .^ (1 ./ beta) + eps);

end