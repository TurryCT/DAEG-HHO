clear;
close all;
clc;


fmin = 2;
df   = 0.5;
fmax = 80;

freq = (fmin:df:fmax).';
flen = numel(freq);

VS_true = [];

VP_true = [3];

H_true = [];

den = [];

nMode = 2;


noiseLevel = 0.1;      

rng(2026);           
if noiseLevel > 0

       pv(validMask) = pv(validMask) + ...
        noiseMatrix(validMask) .* ...
        pv(validMask) .* ...
        noiseLevel;
end



Npop = 200;


Max_it =200;


Nrun = 10;


nD = ;
lb = [];
ub = [];


weights = [0.5 0.5];

fitness_func = @(x) compute_fitness_mask( ...
    x, freq, pv, den, weights, nMode);



x_all_dlh = nan(Nrun, nD);

f_all_dlh = nan(Nrun, 1);

hist_all_dlh = nan(Nrun, Max_it);

for irun = 1:Nrun

       [f_best, x_best, histout] = HHO_Sobol_DAEG_Rayleigh( ...
        Npop, Max_it, lb, ub, fitness_func, false);

    x_all_dlh(irun, :) = x_best;

    f_all_dlh(irun) = f_best;

    histout = histout(:).';

    nHist = min(numel(histout), Max_it);

    hist_all_dlh(irun, 1:nHist) = histout(1:nHist);

    end

x_mean_dlh = mean(x_all_dlh, 1, 'omitnan');

[~, idx_best] = min(f_all_dlh);

x_best_dlh = x_all_dlh(idx_best, :);



VS_mean = x_mean_dlh(1:5);

H_mean = x_mean_dlh(6:9);

VP_mean = x_mean_dlh(10:14);



VS_best = x_best_dlh(1:5);

H_best = x_best_dlh(6:9);

VP_best = x_best_dlh(10:14);



pv_fit_mean = calcmulti( ...
    freq, VS_mean, H_mean, VP_mean, den, nMode);

pv_fit_mean(~isfinite(pv_fit_mean)) = NaN;
pv_fit_mean(pv_fit_mean <= 0) = NaN;



pv_fit_best = calcmulti( ...
    freq, VS_best, H_best, VP_best, den, nMode);

pv_fit_best(~isfinite(pv_fit_best)) = NaN;
pv_fit_best(pv_fit_best <= 0) = NaN;




requiredVars = { ...
    'Npop', 'Max_it', 'Nrun', 'nD', ...
    'lb', 'ub', ...
    'VS_true', 'VP_true', 'H_true', 'den', ...
    'x_all_dlh', 'x_mean_dlh', 'x_best_dlh', ...
    'f_all_dlh', 'hist_all_dlh', ...
    'idx_best', ...
    'freq', 'pv', 'pv_fit_mean', 'pv_fit_best'};

for iVar = 1:numel(requiredVars)

    if ~exist(requiredVars{iVar}, 'var')
        error('。', ...
            requiredVars{iVar});
    end
end


freq_save = freq(:);

pv_obs_save = pv;

pv_mean_save = pv_fit_mean;

pv_best_save = pv_fit_best;

nFreq = numel(freq_save);



if exist('nMode', 'var') && ~isempty(nMode)

    nMode_save = nMode;

elseif exist('n_mode', 'var') && ~isempty(n_mode)

    nMode_save = n_mode;

else

    nMode_save = size(pv_obs_save, 2);
end

if ~isscalar(nMode_save) || ...
        ~isfinite(nMode_save) || ...
        nMode_save < 1 || ...
        nMode_save ~= round(nMode_save)

    error('。');
end

nMode_save = round(nMode_save);



pv_obs_save = pv_obs_save(:, 1:nMode_save);

pv_mean_save = pv_mean_save(:, 1:nMode_save);

pv_best_save = pv_best_save(:, 1:nMode_save);




nLayer = numel(VS_true);

expectedDim = 3 * nLayer - 1;


mask_obs = isfinite(pv_obs_save) & pv_obs_save > 0;

mask_mean = isfinite(pv_mean_save) & pv_mean_save > 0;

mask_best = isfinite(pv_best_save) & pv_best_save > 0;

nValid_obs = sum(mask_obs, 1);

nValid_mean = sum(mask_mean, 1);

nValid_best = sum(mask_best, 1);

result_3p = struct();



result_3p.methodName = 'Three-parameter multimodal inversion';

result_3p.parameterMode = 'Vs-H-Vp inversion';

result_3p.inversionType = 'Multimodal Rayleigh-wave inversion with mask handling';

result_3p.algorithm = 'HHO';



result_3p.Npop = Npop;

result_3p.Max_it = Max_it;

result_3p.Nrun = Nrun;

result_3p.nD = nD;

result_3p.nLayer = nLayer;

result_3p.nMode = nMode_save;

if exist('weights', 'var')
    result_3p.weights = weights(:).';
else
    result_3p.weights = ones(1, nMode_save) ./ nMode_save;
end

result_3p.modeLabels = arrayfun( ...
    @(iMode) sprintf('Mode %d', iMode), ...
    1:nMode_save, ...
    'UniformOutput', false);



result_3p.lb = lb(:).';

result_3p.ub = ub(:).';



result_3p.VS_true = VS_true(:).';

result_3p.VP_true = VP_true(:).';

result_3p.H_true = H_true(:).';

result_3p.den = den(:).';



result_3p.x_all = x_all_dlh;

result_3p.x_mean = x_mean_dlh(:).';


result_3p.x_best = x_best_dlh(:).';


result_3p.f_all = f_all_dlh(:);

s
result_3p.f_best = min(f_all_dlh);


result_3p.idx_best = idx_best;


result_3p.f_mean = mean(f_all_dlh, 'omitnan');

result_3p.f_median = median(f_all_dlh, 'omitnan');

result_3p.f_std = std(f_all_dlh, 0, 'omitnan');

-

result_3p.VS_mean = x_mean_dlh(1:nLayer);

result_3p.H_mean = x_mean_dlh(nLayer + 1 : 2*nLayer - 1);

result_3p.VP_mean = x_mean_dlh(2*nLayer : 3*nLayer - 1);



result_3p.VS_best = x_best_dlh(1:nLayer);

result_3p.H_best = x_best_dlh(nLayer + 1 : 2*nLayer - 1);

result_3p.VP_best = x_best_dlh(2*nLayer : 3*nLayer - 1);



result_3p.hist_all = hist_all_dlh;

result_3p.hist_mean = mean(hist_all_dlh, 1, 'omitnan');

result_3p.hist_median = median(hist_all_dlh, 1, 'omitnan');

result_3p.hist_std = std(hist_all_dlh, 0, 1, 'omitnan');

result_3p.hist_best = min(hist_all_dlh, [], 1);

result_3p.iteration = 1:Max_it;

result_3p.freq = freq_save;


result_3p.pv_obs = pv_obs_save;


result_3p.pv_true = pv_obs_save;


result_3p.pv_mean = pv_mean_save;


result_3p.pv_best = pv_best_save;


result_3p.pv_fit_mean = pv_mean_save;

result_3p.pv_fit_best = pv_best_save;



result_3p.mask_obs = mask_obs;

result_3p.mask_mean = mask_mean;

result_3p.mask_best = mask_best;

result_3p.nValid_obs = nValid_obs;

result_3p.nValid_mean = nValid_mean;

result_3p.nValid_best = nValid_best;



saveFileName = 'result_3pz_multimode.mat';

save(saveFileName, 'result_3p');




for iMode = 1:nMode_save
    fprintf(['，', ...
             ''], ...
             iMode, ...
             nValid_obs(iMode), ...
             nValid_mean(iMode), ...
             nValid_best(iMode));
end


