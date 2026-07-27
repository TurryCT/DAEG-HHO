function [fmin, xmin, histout, Traj, fitness_history, ...
    position_history] = GOA_AdaptiveA( ...
    N, Max_it, lb, ub, dim, fobj)

GrassHopperPositions = ...
    repmat(lb, N, 1) + ...
    rand(N, dim) .* repmat((ub - lb), N, 1);

GrassHopperFitness = zeros(1, N);

fitness_history = zeros(N, Max_it);
position_history = zeros(N, Max_it, dim);
Convergence_curve = zeros(1, Max_it);
Traj = zeros(N, Max_it);

for i = 1:N

    GrassHopperFitness(i) = ...
        fobj(GrassHopperPositions(i, :));

    fitness_history(i, 1) = ...
        GrassHopperFitness(i);

    position_history(i, 1, :) = ...
        GrassHopperPositions(i, :);
end

Traj(:, 1) = GrassHopperPositions(:, 1);

[sorted_fitness, idx] = sort(GrassHopperFitness);

Sorted_grasshopper = ...
    GrassHopperPositions(idx, :);

TargetPosition = ...
    Sorted_grasshopper(1, :);

TargetFitness = ...
    sorted_fitness(1);

Convergence_curve(1) = ...
    TargetFitness;

cMax = 1;
cMin = 0.00004;

for l = 2:Max_it

    c = cMax - ...
        l * ((cMax - cMin) / Max_it);

    for i = 1:N

        S_i_total = zeros(dim, 1);

        for k = 1:dim

            S_i = 0;

            for j = 1:N

                if i ~= j

                    Dist = norm( ...
                        GrassHopperPositions(j, k) - ...
                        GrassHopperPositions(i, k));

                    r_ij_vec = ...
                        (GrassHopperPositions(j, k) - ...
                        GrassHopperPositions(i, k)) / ...
                        (Dist + eps);

                    xj_xi = 2 + rem(Dist, 2);

                    s_ij = ...
                        ((ub(k) - lb(k)) * c / 2) * ...
                        ( ...
                            0.5 * exp(-xj_xi / 1.5) - ...
                            exp(-xj_xi) ...
                        ) * ...
                        r_ij_vec;

                    S_i = S_i + s_ij;
                end
            end

            S_i_total(k) = ...
                S_i_total(k) + S_i;
        end

        X_new = ...
            c * S_i_total' + TargetPosition;

        GrassHopperPositions(i, :) = ...
            min(max(X_new, lb), ub);
    end

    for i = 1:N

        GrassHopperFitness(i) = ...
            fobj(GrassHopperPositions(i, :));

        fitness_history(i, l) = ...
            GrassHopperFitness(i);

        position_history(i, l, :) = ...
            GrassHopperPositions(i, :);

        if GrassHopperFitness(i) < TargetFitness

            TargetFitness = ...
                GrassHopperFitness(i);

            TargetPosition = ...
                GrassHopperPositions(i, :);
        end
    end

    Traj(:, l) = ...
        GrassHopperPositions(:, 1);

    Convergence_curve(l) = ...
        TargetFitness;
end

xmin = TargetPosition;
fmin = TargetFitness;
histout = Convergence_curve;

end