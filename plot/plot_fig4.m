%PLOT_FIG4 Manuscript Figure 4: integrated CO2 uptake anomaly vs patch characteristics.
%   LaTeX label fig:ensemble_corr; published file Fig4.pdf.
%   60-day domain-integrated air-sea CO2 flux anomaly (OIF - control) vs
%   (a) 60-day mean patch area, (b) patch-mean control PHYC, (c) patch-
%   integrated control PHYC; dashed: least-squares fit, Pearson R and p.
%
%   Notes on the published panels (reproduced here):
%   - PHYC is the surface phytoplankton carbon of the control run. The x
%     value of (c) is the sum of 60 daily patch integrals of the surface
%     concentration (mmol m-3 x m2 per day), labelled mmol m^-1. Table S1
%     describes this quantity in its PHYC column, but its published values
%     are the domain-integrated PHYC anomaly (OIF - control); see
%     tables/make_table_S1.m.
%   - p is printed with three decimals ('p = 0.000' for p < 5e-4).
%
%   Input:  data/ens_metrics.mat
%   Output: figures/Fig4.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
E = load(fullfile(C.data_dir, 'ens_metrics.mat'));
S = oif_ens_style(E);
fs = 8;
ylab = '$\mathrm{\int_{A}^T(\Delta CO_2\ FLUX),\ (mmol)}$';
pn = {'dCO2_FLUX_int_vs_PatchArea', 'dCO2_FLUX_int_vs_ctrlPHYC_wavg', 'dCO2_FLUX_int_vs_ctrlPHYC_int'};
xlab = {'Patch area (km^2)', '$\mathrm{\overline{PHYC_{ctrl}}\ (mmol\ m^{-3})}$', ...
        '$\mathrm{\int_{A}^T(PHYC_{ctrl}),\ (mmol\ m^{-1})}$'};
xint = {'tex','latex','latex'};
xlims = {[1 4]*1e4, [0.5 3], []};

fig = oif_figure('Units','centimeters','Position',[2 2 8.4 14.3],'Color','w','Visible','off');
for k = 1:3
    ax = axes('Position', [0.19 0.715-(k-1)*0.318 0.76 0.245], 'FontSize', fs);
    plot_ens_corr(ax, E.corr.(pn{k}), S, S.msize, fs);
    xlabel(xlab{k}, 'Interpreter', xint{k}); ylabel(ylab, 'Interpreter','latex');
    ylim([0 8e12]); if ~isempty(xlims{k}); xlim(xlims{k}); else; axis tight; ylim([0 8e12]); end
    text(ax, 0.98, 0.1, ['(' char('a'+k-1) ')'], 'Units','normalized', 'HorizontalAlignment','right', 'FontSize', fs+2);
    if k == 1
        hm = gobjects(1,4); hr = gobjects(1,3);
        for j = 1:4; hm(j) = scatter(ax, nan, nan, S.msize, 'o', 'MarkerEdgeColor','k', 'MarkerFaceColor', S.month_col(j,:)); end
        for j = 1:3; hr(j) = scatter(ax, nan, nan, S.msize, S.region_marker{j}, 'MarkerEdgeColor','k', 'MarkerFaceColor', S.region_face); end
        % lower right, as published: right of Case 9 (12KM_Jul, 2.75e4 km2), which stays visible
        legend(ax, [hm hr], [E.month_names(:)', E.region_names(:)'], 'NumColumns', 2, 'Position', [0.655 0.719 0.222 0.115], ...
            'FontSize', fs-1, 'Box','on');
    end
end

exportgraphics(fig, fullfile(C.fig_dir,'Fig4.png'), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir,'Fig4.pdf'), 'ContentType','vector');
close(fig);
fprintf('Fig4: R = %.2f/%.2f/%.2f, p = %.3f/%.3f/%.3f\n', E.corr.(pn{1}).R, E.corr.(pn{2}).R, E.corr.(pn{3}).R, ...
    E.corr.(pn{1}).P, E.corr.(pn{2}).P, E.corr.(pn{3}).P);
