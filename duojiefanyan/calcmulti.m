function pv = calcmulti(f, VS, H, VP, den, nMode)
if nargin < 4 || isempty(VP)
    VP = 2 * VS;
end

if nargin < 5 || isempty(den)
    den = 2 * ones(size(VS));
end

if nargin < 6 || isempty(nMode)
    nMode = 1;
end

f = double(f(:));

VS = double(VS(:).');
H  = double(H(:).');
VP = double(VP(:).');
den = double(den(:).');

nLayer = numel(VS);
nf = numel(f);

if ~isscalar(nMode) || ...
        ~isfinite(nMode) || ...
        nMode < 1 || ...
        nMode ~= round(nMode)

    error('nMode 。');
end

nMode = round(nMode);

if nLayer < 2
    error('。');
end

if numel(H) ~= nLayer - 1
    error('。');
end

if numel(VP) ~= nLayer
    error('。');
end

if numel(den) ~= nLayer
    error('。');
end

if any(~isfinite(VS)) || any(~isfinite(H)) || ...
        any(~isfinite(VP)) || any(~isfinite(den)) || ...
        any(VS <= 0) || any(H <= 0) || ...
        any(VP <= 0) || any(den <= 0)

    error(。');
end



cmin = 0.88 * min(VS);
cmax = max(VS);

if cmax <= cmin
    cmax = cmin + max(1, 0.01 * cmin);
end

nScan = 101;

cc = linspace(cmin, cmax, nScan);

dc = cc(2) - cc(1);


pv = nan(nf, nMode);


modelBase = [0, nLayer, VS, H, VP, den];


rootRepeatTol = 0.20 * dc;


zeroTol = 1e-10;


for iFreq = 1:nf

    modelBase(1) = f(iFreq);

    rootsThisFreq = [];

    prevC = cc(1);
    prevR = fastcalc(prevC, modelBase);

    
    if isfinite(prevR) && abs(prevR) < zeroTol
        rootsThisFreq(end + 1) = prevC; %#ok<AGROW>
    end

    for j = 2:nScan

        currC = cc(j);
        currR = fastcalc(currC, modelBase);

        rootCandidate = NaN;

        if isfinite(currR) && abs(currR) < zeroTol

            rootCandidate = currC;

        elseif isfinite(prevR) && isfinite(currR) && ...
                prevR * currR < 0

            rootCandidate = local_bisection_root( ...
                prevC, currC, prevR, currR, modelBase);
        end

        if isfinite(rootCandidate)

            if isempty(rootsThisFreq) || ...
                    all(abs(rootCandidate - rootsThisFreq) > rootRepeatTol)

                rootsThisFreq(end + 1) = rootCandidate; 
            end
        end

        if numel(rootsThisFreq) >= nMode
            break;
        end

        prevC = currC;
        prevR = currR;
    end

    nRoot = min(numel(rootsThisFreq), nMode);

    if nRoot > 0
        pv(iFreq, 1:nRoot) = rootsThisFreq(1:nRoot);
    end
end

end


function root = local_bisection_root(a, b, fa, fb, modelBase)

root = NaN;

if ~isfinite(fa) || ~isfinite(fb)
    return;
end

if fa == 0
    root = a;
    return;
end

if fb == 0
    root = b;
    return;
end

if fa * fb > 0
    return;
end

for k = 1:20

    c = 0.5 * (a + b);

    fc = fastcalc(c, modelBase);

    if ~isfinite(fc)
        return;
    end

    if abs(fc) < 1e-12
        a = c;
        b = c;
        break;
    end

    if fa * fc < 0
        b = c;
        fb = fc;
    else
        a = c;
        fa = fc;
    end
end

root = 0.5 * (a + b);

end