function pv = calcbase(f, VS, H, VP, den)

if nargin <= 4
    [~, c] = size(VS);
    den = 2000 * ones(1, c);
end

if nargin <= 3
    VP = 2 * VS;
end

global mode_base

[~, N] = size(f);

mode_base = [f(N), VS, H, VP, den];

pv = zeros(1, N);

pv(N) = fzero(@fastcalc, 0.88 * min(VS));

for i = N - 1:-1:1
    mode_base(1) = f(i);
    pv(i) = fzero(@fastcalc, pv(i + 1));
end

end