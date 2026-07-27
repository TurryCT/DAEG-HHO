clc; clear; close all;
Nrun = 20;       
Npop = 200;     
Max_it = 200;    

compare_inversionsA(Nrun, Npop, Max_it);


load(sprintf('Inversion_Results_Nrun%d_Npop%d_Maxit%d.mat', Nrun, Npop, Max_it));

figure; 
set(gcf, 'Color', 'w');  
hold on; 
grid off;               
box on;       

xq = 1:0.5:Max_it;         
marker_step = 10;           
x_mark_idx = 1:marker_step:length(xq);  

% --- WOA ---
h_WOA = plot(xq, interp1(1:Max_it, Convergence_means.WOA, xq, 'pchip'), ...
             '-or', 'LineWidth',2, 'MarkerIndices', x_mark_idx, 'MarkerSize',4);

% --- QPSO ---
h_QPSO = plot(xq, interp1(1:Max_it, Convergence_means.QPSO, xq, 'pchip'), ...
              '-sb', 'LineWidth',2, 'MarkerIndices', x_mark_idx, 'MarkerSize',4);
 
% --- BWO ---
h_BWO = plot(xq, interp1(1:Max_it, Convergence_means.BWO, xq, 'pchip'), ...
             '-^g', 'LineWidth',2, 'MarkerIndices', x_mark_idx, 'MarkerSize',4);

% --- SABO ---
h_SABO = plot(xq, interp1(1:Max_it, Convergence_means.SABO, xq, 'pchip'), ...
              '-dm', 'LineWidth',2, 'MarkerIndices', x_mark_idx, 'MarkerSize',4);

% --- GOA ---
h_GOA = plot(xq, interp1(1:Max_it, Convergence_means.GOA, xq, 'pchip'), ...
             '-vc', 'LineWidth',2, 'MarkerIndices', x_mark_idx, 'MarkerSize',4);

% --- ACOR ---
h_ACOR = plot(xq, interp1(1:Max_it, Convergence_means.ACOR, xq, 'pchip'), ...
              '-xk', 'LineWidth',2, 'MarkerIndices', x_mark_idx, 'MarkerSize',4);

% --- HHO ---
h_HHO = plot(xq, interp1(1:Max_it, Convergence_means.HHO, xq, 'pchip'), ...
             '-py', 'LineWidth',2, 'MarkerIndices', x_mark_idx, 'MarkerSize',4);

% --- ACE-DLHHO ---
h_ACE = plot(xq, interp1(1:Max_it, Convergence_means.ACE_DLHHO, xq, 'pchip'), ...
             '-h', 'Color',[0.85 0.33 0.1], 'LineWidth',2, 'MarkerIndices', x_mark_idx, 'MarkerSize',4);

