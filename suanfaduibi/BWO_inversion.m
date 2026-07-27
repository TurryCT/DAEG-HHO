function [xposbest, fvalbest, Curve] = BWO_inversion( ...
    freq, VS_init, H_init, VP_init, den, Npop, Max_it)

nVS = length(VS_init);
nH = length(H_init);
nVP = length(VP_init);

nD = nVS + nH + nVP;

lb = [ ...
    150 187.5 225 300 ...
    1.5 2.5 4.5 ...
    323.25 399 510.75 707.25];

ub = [ ...
    250 312.5 375 500 ...
    2.5 3.5 5.5 ...
    538.75 665 851.25 1178.75];

pv = calcmulti(freq, VS_init, H_init, VP_init, den);

pos = rand(Npop, nD) .* (ub - lb) + lb;
fit = inf(Npop, 1);
Curve = inf(1, Max_it + 1);

parfor i = 1:Npop

    VS_i = pos(i, 1:nVS);

    H_i = pos( ...
        i, ...
        nVS + 1:nVS + nH);

    VP_i = pos( ...
        i, ...
        nVS + nH + 1:end);

    fit(i) = fitness( ...
        pv, ...
        nVS, ...
        VS_i, ...
        H_i, ...
        VP_i, ...
        den, ...
        freq, ...
        lb(1), ...
        ub(nVS));
end

[fvalbest, index] = min(fit);
xposbest = pos(index, :);
Curve(1) = fvalbest;

tt = 0;
Max_tt = 50;
fitd = 1e-5;
T = 1;

while T <= Max_it

    newpos = pos;

    kk = (1 - 0.5 * T / Max_it) .* rand(Npop, 1);

    temp_pos = pos;
    temp_fit = fit;

    parfor i = 1:Npop

        newpos_i = newpos(i, :);

        if kk(i) > 0.45

            RJ = randi(Npop);

            while RJ == i
                RJ = randi(Npop);
            end

            r1 = rand();
            r2 = rand();

            params = randperm(nD, 2);

            newpos_i(params(1)) = ...
                pos(i, params(1)) + ...
                (pos(RJ, params(1)) - pos(i, params(2))) .* ...
                (r1 + 1) .* sin(r2 * 360);

            newpos_i(params(2)) = ...
                pos(i, params(2)) + ...
                (pos(RJ, params(1)) - pos(i, params(2))) .* ...
                (r1 + 1) .* cos(r2 * 360);

        else

            RJ = randi(Npop);

            while RJ == i
                RJ = randi(Npop);
            end

            r3 = rand();
            r4 = rand();

            C1 = 2 * r4 * (1 - T / Max_it);

            alpha = 1.5;

            sigma = ( ...
                gamma(1 + alpha) .* ...
                sin(pi * alpha / 2) ./ ...
                ( ...
                    gamma((1 + alpha) / 2) .* ...
                    alpha .* ...
                    2 ^ ((alpha - 1) / 2) ...
                ) ...
                ) ^ (1 / alpha);

            u = randn(1, nD) .* sigma;
            v = randn(1, nD);

            S = u ./ (abs(v) .^ (1 / alpha) + eps);

            LevyFlight = 0.05 .* S;

            newpos_i = ...
                r3 .* xposbest ...
                - r4 .* pos(i, :) ...
                + C1 .* LevyFlight .* ...
                (pos(RJ, :) - pos(i, :));
        end

        newpos_i = max(min(newpos_i, ub), lb);

        VS_i = newpos_i(1:nVS);

        H_i = newpos_i( ...
            nVS + 1:nVS + nH);

        VP_i = newpos_i( ...
            nVS + nH + 1:end);

        newfit_i = fitness( ...
            pv, ...
            nVS, ...
            VS_i, ...
            H_i, ...
            VP_i, ...
            den, ...
            freq, ...
            lb(1), ...
            ub(nVS));

        if newfit_i < fit(i)
            temp_pos(i, :) = newpos_i;
            temp_fit(i) = newfit_i;
        end
    end

    pos = temp_pos;
    fit = temp_fit;

    [fval, index] = min(fit);

    if fval < fvalbest
        fvalbest = fval;
        xposbest = pos(index, :);
    end

    Curve(T + 1) = fvalbest;

    if abs(Curve(T + 1) - Curve(T)) < fitd
        tt = tt + 1;
    else
        tt = 0;
    end

    if tt > Max_tt
        Curve = Curve(1:T + 1);
        break;
    end

    T = T + 1;
end

end