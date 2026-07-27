function fitness = compute_fitness_mask( ...
    x, freq, pv_obs, den, weights, nMode)
penaltyValue = 1e30;

fitness = penaltyValue;


x = double(x(:).');
den = double(den(:).');

nLayer = numel(den);

expectedDim = 3 * nLayer - 1;

if numel(x) ~= expectedDim
    return;
end

if nargin < 6 || isempty(nMode)
    nMode = size(pv_obs, 2);
end

if ~isscalar(nMode) || ...
        ~isfinite(nMode) || ...
        nMode < 1 || ...
        nMode ~= round(nMode)

    return;
end

nMode = round(nMode);

weights = double(weights(:).');

if isempty(weights)
    weights = ones(1, nMode);
end



VS = x(1:nLayer);

H = x(nLayer + 1 : 2 * nLayer - 1);

VP = x(2 * nLayer : 3 * nLayer - 1);


if any(~isfinite(x)) || ...
        any(VS <= 0) || any(H <= 0) || ...
        any(VP <= 0)

    return;
end


if any(VP <= VS)
    return;
end


try
    pv_pred = calcmulti(freq, VS, H, VP, den, nMode);
catch
    return;
end

if isempty(pv_pred)
    return;
end

nUse = min([ ...
    size(pv_obs, 2), ...
    size(pv_pred, 2), ...
    numel(weights), ...
    nMode]);

if nUse < 1
    return;
end

modeRMSE = nan(1, nUse);
modeWeight = zeros(1, nUse);



for iMode = 1:nUse

    obs = pv_obs(:, iMode);
    pred = pv_pred(:, iMode);

    obsMask = isfinite(obs) & obs > 0;

    nObs = sum(obsMask);

    if nObs < 3
        continue;
    end

    validMask = obsMask & isfinite(pred) & pred > 0;

    nValid = sum(validMask);


    minValidNumber = max(3, ceil(0.80 * nObs));

    if nValid < minValidNumber
        return;
    end

    residual = pred(validMask) - obs(validMask);

    modeRMSE(iMode) = sqrt(mean(residual .^ 2));

    modeWeight(iMode) = weights(iMode);
end



validMode = isfinite(modeRMSE) & modeWeight > 0;

if ~any(validMode)
    return;
end

fitness = sum( ...
    modeWeight(validMode) .* modeRMSE(validMode)) / ...
    sum(modeWeight(validMode));

if ~isfinite(fitness)
    fitness = penaltyValue;
end

end