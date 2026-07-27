
function f = compute_fitness_base(x, freq, pv_true, den)

    pv_pred = calcmulti(freq, x(1:5), x(6:9), x(10:14), den);

    pv_pred = pv_pred(:,1);


    mask = pv_true ~= 0;

    f = sqrt( mean( (pv_true(mask) - pv_pred(mask)).^2 ) );
end
