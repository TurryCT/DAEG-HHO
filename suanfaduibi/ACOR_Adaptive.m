function [best_x, best_f, histout, Traj, fitness_history, ...
    position_history] = ACOR_Adaptive( ...
    fobj_acor, nD, lb, ub, N, k, q, xi, T, seedX0)

M = k;

Archive.X = zeros(M, nD);

for d = 1:nD
    Archive.X(:, d) = ...
        lb(d) + rand(M, 1) .* (ub(d) - lb(d));
end

if ~isempty(seedX0)
    Archive.X(1, :) = min(max(seedX0, lb), ub);
end

Archive.f = evaluate_pop(fobj_acor, Archive.X);

[Archive.f, idx] = sort(Archive.f, 'ascend');
Archive.X = Archive.X(idx, :);

ranks = (0:M-1)';

w = (1 / (q * sqrt(2 * pi))) .* ...
    exp(-(ranks .^ 2) ./ (2 * q ^ 2));

w = w ./ sum(w);

histout = zeros(1, T);
Traj = zeros(M, T);
fitness_history = zeros(M, T);
position_history = zeros(M, T, nD);

best_x = Archive.X(1, :);
best_f = Archive.f(1);

for t = 1:T

    New = zeros(N, nD);

    for i = 1:N

        idx_mu = roulette(w);
        mu = Archive.X(idx_mu, :);

        sigma = zeros(1, nD);

        for d = 1:nD

            s = 0;

            for m = 1:M
                s = s + ...
                    w(m) * abs(Archive.X(m, d) - mu(d));
            end

            sigma(d) = xi * s + 1e-12;
        end

        z = mu + sigma .* randn(1, nD);

        New(i, :) = min(max(z, lb), ub);
    end

    allX = [Archive.X; New];
    allf = evaluate_pop(fobj_acor, allX);

    [allf, id2] = sort(allf, 'ascend');
    allX = allX(id2, :);

    Archive.X = allX(1:M, :);
    Archive.f = allf(1:M);

    if Archive.f(1) < best_f
        best_f = Archive.f(1);
        best_x = Archive.X(1, :);
    end

    histout(t) = best_f;

    fitness_history(:, t) = Archive.f;
    position_history(:, t, :) = Archive.X;
    Traj(:, t) = Archive.X(:, 1);
end

end


function f = evaluate_pop(obj, X)

n = size(X, 1);
f = zeros(n, 1);

parfor i = 1:n
    f(i) = obj(X(i, :));
end

end


function idx = roulette(p)

cp = cumsum(p(:));
r = rand();
idx = find(cp >= r, 1, 'first');

end