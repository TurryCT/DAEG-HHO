function [f_best, X_best, histout, diagnostics] = ...
    HHO_Sobol_Rayleigh( ...
    nPop, maxIter, lb, ub, fun, useParallel, searchSeed)


if nargin < 6 || isempty(useParallel)
    useParallel = true;
end

if nargin < 7
    searchSeed = [];
end

cfg = struct();

cfg.useAdaptiveEJ = false;
cfg.useEliteGuidance = false;
cfg.useStagnationRepair = false;

cfg.verbose = true;
cfg.algorithmName = 'Sobol-HHO';

[f_best, X_best, histout, diagnostics] = HHO_Core_Rayleigh( ...
    nPop, maxIter, lb, ub, fun, useParallel, ...
    searchSeed, 'sobol', cfg);

end
