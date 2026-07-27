function y = fastcalc(x, modelBase)
% =========================================================================
% fastcalc
% Rayleigh-wave characteristic function calculation for a single frequency
% and candidate phase velocity
%
% Input:
% x         : candidate phase velocity (scalar)
% modelBase : [f, nLayer, VS(1:n), H(1:n-1), VP(1:n), den(1:n)]
%
% Output:
% y         : real part of Rayleigh-wave characteristic function
%
% This version does not use global mode_base.
% =========================================================================

y = NaN;

%% ==================== 1. Input Check ====================

if nargin ~= 2
    error('fastcalc requires two inputs: x and modelBase.');
end

if ~isscalar(x) || ~isfinite(x) || x <= 0
    return;
end

modelBase = double(modelBase(:).');

if numel(modelBase) < 9
    error('modelBase length is insufficient for layered model parsing.');
end

f = modelBase(1);
nLayer = modelBase(2);

if ~isscalar(nLayer) || ...
        ~isfinite(nLayer) || ...
        nLayer < 2 || ...
        nLayer ~= round(nLayer)

    error('nLayer in modelBase must be an integer greater than or equal to 2.');
end

nLayer = round(nLayer);

% modelBase =
% [f, nLayer, VS(1:n), H(1:n-1), VP(1:n), den(1:n)]
%
% Length:
% 1 + 1 + n + (n-1) + n + n = 4*n + 1

expectedLength = 4 * nLayer + 1;

if numel(modelBase) ~= expectedLength
    error(['Incorrect modelBase length. Current length = ', ...
        num2str(numel(modelBase)), ...
        '; for ', num2str(nLayer), ...
        '-layer model it should be ', ...
        num2str(expectedLength), '.']);
end


%% ==================== 2. Parse Model Parameters ====================

idx = 3;

% VS: nLayer values
VS = modelBase(idx : idx + nLayer - 1);
idx = idx + nLayer;

% H: nLayer-1 values
H = modelBase(idx : idx + nLayer - 2);
idx = idx + nLayer - 1;

% VP: nLayer values
VP = modelBase(idx : idx + nLayer - 1);
idx = idx + nLayer;

% Density: nLayer values
den = modelBase(idx : idx + nLayer - 1);


if any(~isfinite(VS)) || ...
   any(~isfinite(H)) || ...
   any(~isfinite(VP)) || ...
   any(~isfinite(den)) || ...
   any(VS <= 0) || ...
   any(H <= 0) || ...
   any(VP <= 0) || ...
   any(den <= 0)

    return;
end


%% ==================== 3. Initialize Half-Space ====================

k = 2 * pi * f / x;
xs = x ^ 2;

btv = VS(nLayer) ^ 2;
bt = den(nLayer) * btv;

af = VP(nLayer) ^ 2;

g = xs / (btv + btv);
t = 1 - g;

r = xs / af;
r = r - 1;

s = g + g - 1;

r1 = sqrt(r);
s1 = sqrt(s);

ps = r1 * s1;

bt1 = bt;

x1 = 1 + ps;
x2 = t + ps;
x3 = -t ^ 2 - ps;
x4 = 1i * s1 * g;
x5 = -1i * r1 * g;


%% ==================== 4. Upward Recursion ====================

for ii = nLayer - 1 : -1 : 1

    btv = VS(ii) ^ 2;
    bt = den(ii) * btv;

    af = VP(ii) ^ 2;

    g = xs / (btv + btv);
    t = 1 - g;

    r = xs / af;
    r = r - 1;

    s = g + g - 1;

    r1 = sqrt(r);
    s1 = sqrt(s);

    l = bt1 / bt;
    bt1 = bt;

    x1 = x1 / l;
    x3 = x3 * l;

    k1 = k * H(ii);

    p = k1 * r1;
    q = k1 * s1;

    tx1 = t * x1;
    ttx1 = t * tx1;

    tx2 = t * x2;

    p1 = x1 - x2 - x2 - x3;
    p2 = -ttx1 + tx2 + tx2 + x3;
    p3 = g * x4;
    p4 = g * x5;
    p5 = -tx1 + x2 + tx2 + x3;


    %% Case 1: x >= VP(ii)

    if x >= VP(ii)

        if r1 == 0
            c = k1;
        else
            c = sin(p) / r1;
        end

        d = sin(q) / s1;

        a = cos(p);
        b = cos(q);

        ab = a * b;
        ad = a * d;
        cd = c * d;
        bc = b * c;

        ads = ad * s;
        bcr = bc * r;

        cdr = cd * r;
        cdrs = cdr * s;

        cds = cd * s;

        q1 = ab * p1 + cd * p2 - ad * p3 + bc * p4;

        q2 = cdrs * p1 + ab * p2 + bcr * p3 - ads * p4;

        q3 = ads * p1 - bc * p2 + ab * p3 + cds * p4;

        q4 = -bcr * p1 + ad * p2 + cdr * p3 + ab * p4;

        tq1 = t * q1;
        ttq1 = t * tq1;

        tp5 = t * p5;

        x1 = q1 - q2 + p5 + p5;
        x2 = tq1 - q2 + p5 + tp5;
        x3 = -ttq1 + q2 - tp5 - tp5;
        x4 = g * q3;
        x5 = g * q4;

    end


    %% Case 2: VS(ii) <= x < VP(ii)

    if x < VP(ii) && x >= VS(ii)

        if s1 == 0
            d = k1;
        else
            d = sin(q) / s1;
        end

        ar1 = abs(r1);
        ark1 = ar1 * k1;

        ee = exp(-2 * ark1);

        b = cos(q);

        c = (1 - ee) / (1 + ee) / ar1;

        ds = d * s;
        br = b * r;

        dr = d * r;
        drs = dr * s;

        q1 = b * p1 + c * d * p2 - d * p3 + b * c * p4;

        q2 = c * drs * p1 + b * p2 + c * br * p3 - ds * p4;

        q3 = ds * p1 - b * c * p2 + b * p3 + c * ds * p4;

        q4 = -c * br * p1 + d * p2 + c * dr * p3 + b * p4;

        tq1 = t * q1;
        ttq1 = t * tq1;

        if ark1 < 20
            p5 = p5 / cos(p);
        else
            p5 = 0;
        end

        tp5 = t * p5;

        x1 = q1 - q2 + p5 + p5;
        x2 = tq1 - q2 + p5 + tp5;
        x3 = -ttq1 + q2 - tp5 - tp5;
        x4 = g * q3;
        x5 = g * q4;

    end


    %% Case 3: x < VS(ii)

    if x < VS(ii)

        ar1 = abs(r1);
        ark1 = ar1 * k1;

        ee = exp(-2 * ark1);

        as1 = abs(s1);
        ask1 = as1 * k1;

        ees = exp(-2 * ask1);

        c = (1 - ee) / (1 + ee) / ar1;

        d = (1 - ees) / (1 + ees) / as1;

        ds = d * s;
        cr = c * r;
        cd = c * d;

        cds = c * ds;
        cdr = cr * d;
        cdrs = ds * cr;

        q1 = p1 + cd * p2 - d * p3 + c * p4;

        q2 = cdrs * p1 + p2 + cr * p3 - ds * p4;

        q3 = ds * p1 - c * p2 + p3 + cds * p4;

        q4 = -cr * p1 + d * p2 + cdr * p3 + p4;

        tq1 = t * q1;
        ttq1 = t * tq1;

        if (ask1 + ark1) < 20
            p5 = p5 / cos(p) / cos(q);
        else
            p5 = 0;
        end

        tp5 = t * p5;

        x1 = q1 - q2 + p5 + p5;
        x2 = tq1 - q2 + p5 + tp5;
        x3 = -ttq1 + q2 - tp5 - tp5;
        x4 = g * q3;
        x5 = g * q4;

    end

end


%% ==================== 5. Output Characteristic Function ====================

y = real(x3);

if ~isfinite(y)
    y = NaN;
end

end