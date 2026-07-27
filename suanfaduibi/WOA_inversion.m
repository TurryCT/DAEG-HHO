function [Leader_pos, Leader_score, pv1, Convergence_curve] = ...
    WOA_inversion(freq, VS, VP, H, den, Npop, Max_it, lb, ub)

freq = freq(:).';

VS  = VS(:).';
VP  = VP(:).';
H   = H(:).';
den = den(:).';

lb = lb(:).';
ub = ub(:).';



if ~isvector(pv)
    pv = pv(:, 1);
end

pv = pv(:).';


nD = numel(lb);

Leader_pos = zeros(1, nD);
Leader_score = inf;

X = zeros(Npop, nD);

for j = 1:nD
    X(:, j) = lb(j) + rand(Npop, 1) .* (ub(j) - lb(j));
end

Convergence_curve = zeros(1, Max_it);

for t = 1:Max_it

      fit_vals = 1e30 .* ones(Npop, 1);

    parfor i = 1:Npop

        Xi = X(i, :);

                Xi = max(min(Xi, ub), lb);

             fit_vals(i) = fitness( ...
            pv, ...
            nD - 7, ...
            Xi(1:4), ...
            Xi(5:7), ...
            Xi(8:11), ...
            den, ...
            freq, ...
            lb(1), ...
            ub(4));
    end

     [min_fit, min_idx] = min(fit_vals);

    if min_fit < Leader_score
        Leader_score = min_fit;
        Leader_pos = X(min_idx, :);
    end

      a = 2 - 2 * t / Max_it;
    a2 = -1 - t / Max_it;

    for i = 1:Npop

        r1 = rand();
        r2 = rand();

        A = 2 * a * r1 - a;
        C = 2 * r2;

        b = 1;
        l = (a2 - 1) * rand() + 1;
        p = rand();

        for j = 1:nD

            if p < 0.5

                if abs(A) >= 1

                    rand_leader_index = randi(Npop);
                    X_rand = X(rand_leader_index, :);

                    X(i, j) = X_rand(j) - ...
                        A * abs(C * X_rand(j) - X(i, j));

                else

                    X(i, j) = Leader_pos(j) - ...
                        A * abs(C * Leader_pos(j) - X(i, j));
                end

            else

                distance2Leader = abs(Leader_pos(j) - X(i, j));

                X(i, j) = distance2Leader * exp(b * l) * ...
                    cos(2 * pi * l) + Leader_pos(j);
            end
        end


        X(i, :) = max(min(X(i, :), ub), lb);
    end

      Convergence_curve(t) = Leader_score;

    fprintf('WOA: Iteration %d/%d, Best Fitness = %.8e\n', ...
        t, Max_it, Leader_score);
end

pv1 = calcmulti( ...
    freq, ...
    Leader_pos(1:4), ...
    Leader_pos(5:7), ...
    Leader_pos(8:11), ...
    den);

if ~isvector(pv1)
    pv1 = pv1(:, 1);
end

pv1 = pv1(:).';

end