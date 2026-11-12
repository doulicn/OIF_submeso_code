function S = oif_ens_style(E)
%OIF_ENS_STYLE Colours and markers of the 18 ensemble members (Figs. 3, S9).
%
%   S = oif_ens_style(E)   with E loaded from data/ens_metrics.mat
%
%   Colour = release month (cbrewer Dark2, in order of first appearance:
%   Jun, May, Jul, Aug), blended with white for coarser resolution
%   (alpha 1.00 / 0.55 / 0.25 for 1 / 4 / 12 km). Marker = release region
%   (R1 square, R2 triangle, R3 circle). Marker size and error-bar style as
%   in the original analysis code (scatter size 80 points^2; error bars with
%   line width 1.8, marker size 7 and cap size 8).

S.month_col = [27 158 119; 217 95 2; 117 112 179; 231 41 138]/255;   % Dark2(1:4)
S.alpha_res = [1.00 0.55 0.25];
S.region_marker = {'s','^','o'};
n = numel(E.res_id);
S.color = nan(n,3); S.marker = cell(n,1);
for i = 1:n
    a = S.alpha_res(E.res_id(i));
    S.color(i,:) = a*S.month_col(E.month_id(i),:) + (1-a)*[1 1 1];
    S.marker{i} = S.region_marker{E.region_id(i)};
end
S.region_face = [0.6 0.6 0.6];
S.msize = 80;                                                 % scatter size of the members
S.errorbar = {'LineWidth', 1.8, 'MarkerSize', 7, 'CapSize', 8}; % ensemble mean +/- std
% variance-partition colours (Fig. 3d, S9b)
S.col_reg  = [0.45 0.30 0.65];
S.col_time = [0.85 0.55 0.13];
S.col_res  = [0.20 0.55 0.75];
S.col_int  = [0.60 0.60 0.60];
end
