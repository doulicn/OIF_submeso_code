%PLOT_FIG3 Manuscript Figure 3: ensemble response, variance attribution and controls on CO2 uptake.
%   LaTeX label fig:ensemble; published file Fig3_4.pdf (the revision merged
%   Figures 3 and 4 of the original submission into this figure).
%   (a) mean filamentation index (first two release months), (b) 60-day mean
%   patch area, (c) 60-day air-sea CO2 flux anomaly integrated over the
%   OSP-1KM domain (right axis tons C), (d) balanced two-way variance partition
%   (R1: timing x resolution; June: region x resolution) of FI, patch area
%   and the domain-integrated CO2 flux anomaly, (e,f) the CO2 flux anomaly of
%   (c) vs (e) the 60-day mean patch area and (f) the patch-integrated
%   control-run PHYC; dashed: least-squares fit, Pearson R and p.
%
%   (c), (e) and (f) use the same domain integral as (d) and Table S1 (label
%   int_A, A = OSP-1KM domain).
%
%   Differences from the caption and legend:
%   - Red and blue error bars (lib/ens_resolution_stats.m, as in the
%     original analysis): red = mean/std of the four release-month means at
%     each resolution, the June value pooling regions R1-R3; blue = mean/std
%     of the three release-region means, the R1 value pooling May-August.
%     Both use all six runs of a resolution. Caption and legend ('R1, n=12',
%     'June, n=9') describe statistics of the R1 runs and of the June runs.
%   - FI is P^2/(4*pi*A) (perimeter P, area A), as in the original
%     analysis; the manuscript defines FI = P/sqrt(A).
%   - (f): PHYC is the surface phytoplankton carbon of the control run; the
%     x value is the sum of 60 daily patch integrals of the surface
%     concentration (mmol m-3 x m2 per day), labelled mmol m^-1 as in the
%     published panel (see tables/make_table_S1.m).
%   - p is printed with three decimals ('p = 0.000' for p < 5e-4).
%   - The patch-mean control PHYC regression (Figure 4b of the original
%     submission, R = 0.73) is no longer plotted; it is still computed by
%     prep_timeseries_ensemble (E.corr.dCO2_FLUX_int_vs_ctrlPHYC_wavg).
%
%   Options (set the variables in the workspace before running the script):
%     errorbar_stat = 'pooled'  (default) red/blue error bars as above
%                     'subset'  red: the four R1 runs (May-Aug), blue: the
%                               three June runs (R1-R3) of each resolution;
%                               legend n from the data
%   With a non-default option the output is figures/Fig3_<options>.png/.pdf.
%
%   Input:  data/ens_metrics.mat
%   Output: figures/Fig3.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~exist('errorbar_stat', 'var'); errorbar_stat = 'pooled'; end
errorbar_stat = validatestring(errorbar_stat, {'pooled', 'subset'});
E = load(fullfile(C.data_dir, 'ens_metrics.mat'));
S = oif_ens_style(E);
tonsC = C.mmolC_to_tC;
fs = 8;

% layout of Fig3_4.pdf: (a)-(c) stacked on the left with their legends below,
% (d)-(f) stacked on the right
fig = oif_figure('Units','centimeters','Position',[2 2 19.6 15.4],'Color','w','Visible','off');
pa = [0.075 0.755 0.36 0.215];  pb = [0.075 0.485 0.36 0.215];  pc = [0.075 0.215 0.36 0.215];
pd = [0.600 0.755 0.255 0.215]; pe = [0.600 0.430 0.355 0.235]; pf = [0.600 0.105 0.355 0.235];

% ---- (a) filamentation index ----
ax = axes('Position', pa, 'FontSize', fs);
plot_ens_resolution(ax, E.fi_mean, E, S, [], errorbar_stat);
ylabel('$\mathrm{Filamentation\ index}$', 'Interpreter','latex');
text(ax, 0.02, 0.12, '(a)', 'Units','normalized', 'FontSize', fs+2);

% ---- (b) patch area ----
ax = axes('Position', pb, 'FontSize', fs);
plot_ens_resolution(ax, E.patch_area_60, E, S, [], errorbar_stat);
yticks(ax, (1:4)*1e4);                        % as published
ylabel('$\mathrm{Patch\ area\ (km^2)}$', 'Interpreter','latex');
text(ax, 0.02, 0.12, '(b)', 'Units','normalized', 'FontSize', fs+2);

% ---- (c) CO2 flux anomaly integrated over the OSP-1KM domain (60 days) ----
vc = E.int_dom_CO2;                    % A = OSP-1KM domain, as in Table S1
lab = @(u) ['$\mathrm{\int_{A}^T(\Delta CO_2\ FLUX),\ (' u ')}$'];
ax = axes('Position', pc, 'FontSize', fs);
yyaxis(ax, 'left'); set(ax, 'YColor', 'k');
plot_ens_resolution(ax, vc, E, S, [], errorbar_stat);
ylabel(lab('mmol\ C'), 'Interpreter','latex', 'Color','k');
yl = ylim(ax); dy = diff(yticks(ax));
yl(2) = ceil(yl(2)/dy(1))*dy(1);              % top on a tick, clear of the error-bar caps
ylim(ax, yl);
if isequal(yl, [0 6e12]); yticks(ax, (0:2:6)*1e12); end   % ticks of the published panel
yyaxis(ax, 'right'); set(ax, 'YColor', 'k'); ylim(ax, yl*tonsC);
ylabel(lab('Tons\ C'), 'Interpreter','latex', 'Color','k');
yyaxis(ax, 'left');
text(ax, 0.02, 0.12, '(c)', 'Units','normalized', 'FontSize', fs+2);

% ---- (d) variance partition, stacked bars ----
ax = axes('Position', pd, 'FontSize', fs); hold on;
im = [find(strcmp(E.var.metric,'FI')), find(strcmp(E.var.metric,'PatchArea')), find(strcmp(E.var.metric,'CO2_FLUX'))];
cols = {[S.col_time; S.col_res; S.col_int], [S.col_reg; S.col_res; S.col_int]};
grp = {'R1','June'};
bw = 0.42; dx = 0.45; xsp = 2.5; xc = (1:3)*xsp;
for k = 1:3
    pct = {E.var.pct_R1(im(k),:), E.var.pct_June(im(k),:)};
    for ig = 1:2
        xg = xc(k) + (ig-1.5)*2*dx; y0 = 0;
        for is = 1:3
            hs = max(pct{ig}(is), 0);
            patch([xg-bw/2 xg+bw/2 xg+bw/2 xg-bw/2], [y0 y0 y0+hs y0+hs], cols{ig}(is,:), 'EdgeColor','w', 'LineWidth',0.5);
            text(xg, y0+hs/2, sprintf('%.0f', hs), 'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontSize', 6, 'FontWeight','bold');
            y0 = y0 + hs;
        end
        text(xg, 102, grp{ig}, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', fs, 'FontWeight','bold');
    end
end
ylim([0 112]); yticks(0:20:100); xlim([xc(1)-xsp/2, xc(end)+xsp/2]); xticks(xc);
xticklabels({'$\mathrm{FI}$', '$\mathrm{Patch\ area}$', '$\mathrm{CO_2\ FLUX}$'});
set(ax, 'TickLabelInterpreter','latex', 'TickLength',[0 0], 'FontSize', fs, 'Box','on'); grid on;
ylabel('$\mathrm{Variance\ explained\ (\%)}$', 'Interpreter','latex');
text(ax, 0.02, 0.12, '(d)', 'Units','normalized', 'FontSize', fs+2);
hv = gobjects(1,4); lc = [S.col_reg; S.col_time; S.col_res; S.col_int];
for k = 1:4; hv(k) = plot(nan, nan, 's', 'MarkerFaceColor', lc(k,:), 'MarkerEdgeColor','none', 'MarkerSize', 7); end
legend(hv, {'Region','Timing','Resolution','Interaction'}, 'Position', [0.86 0.79 0.13 0.13], 'Box','off', 'FontSize', fs);

% ---- (e,f) CO2 flux anomaly vs patch area and patch-integrated control PHYC ----
ylab = '$\mathrm{\int_{A}^T(\Delta CO_2\ FLUX),\ (mmol)}$';
pn = {'dCO2_FLUX_int_vs_PatchArea', 'dCO2_FLUX_int_vs_ctrlPHYC_int'};
xlab = {'Patch area (km^2)', '$\mathrm{\int_{A}^T(PHYC_{ctrl}),\ (mmol\ m^{-1})}$'};
xint = {'tex','latex'}; pef = {pe, pf};
for k = 1:2
    ax = axes('Position', pef{k}, 'FontSize', fs);
    plot_ens_corr(ax, E.corr.(pn{k}), S, S.msize, fs);
    xlabel(xlab{k}, 'Interpreter', xint{k}); ylabel(ylab, 'Interpreter','latex');
    if k == 1; xlim([1 4]*1e4); ylim([0 8e12]); else; axis tight; ylim([0 8e12]); end
    text(ax, 0.98, 0.1, ['(' char('d'+k) ')'], 'Units','normalized', 'HorizontalAlignment','right', 'FontSize', fs+2);
    if k == 1
        hm = gobjects(1,4); hr = gobjects(1,3);
        for j = 1:4; hm(j) = scatter(ax, nan, nan, S.msize, 'o', 'MarkerEdgeColor','k', 'MarkerFaceColor', S.month_col(j,:)); end
        for j = 1:3; hr(j) = scatter(ax, nan, nan, S.msize, S.region_marker{j}, 'MarkerEdgeColor','k', 'MarkerFaceColor', S.region_face); end
        % lower right, right of Case 9 (12KM_Jul, 2.75e4 km2), as in the published panel
        axp = get(ax, 'Position');
        legend(ax, [hm hr], [E.month_names(:)', E.region_names(:)'], 'NumColumns', 2, ...
            'Position', [axp(1)+0.62*axp(3) axp(2)+0.06*axp(4) 0.30*axp(3) 0.42*axp(4)], 'FontSize', fs-1, 'Box','on');
    end
end

% ---- legend for (a)-(c) (bottom left) ----
axl = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(axl, 'on');
hm = gobjects(1,4);
for k = 1:4
    hm(k) = plot(axl, nan, nan, 'o', 'MarkerFaceColor', S.month_col(k,:), 'MarkerEdgeColor','k', 'MarkerSize', 6);
end
legend(hm, E.month_names, 'Position', [0.045 0.005 0.07 0.125], 'Box','off', 'FontSize', fs);
axl2 = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(axl2, 'on');
hr = gobjects(1,3);
for k = 1:3
    hr(k) = plot(axl2, nan, nan, S.region_marker{k}, 'MarkerFaceColor', S.region_face, 'MarkerEdgeColor','k', 'MarkerSize', 6);
end
% dummy points outside the limits of the invisible axes (not drawn); the
% legend icons then show the error bar with caps, as in the published legend
hl = [errorbar(axl2, -1, -1, 1, 'ks-', 'MarkerFaceColor','k', S.errorbar{:}), ...
      errorbar(axl2, -1, -1, 1, 'rs-', 'MarkerFaceColor','r', S.errorbar{:}), ...
      errorbar(axl2, -1, -1, 1, 'bs-', 'MarkerFaceColor','b', S.errorbar{:})];
set(axl2, 'XLim', [0 1], 'YLim', [0 1]);
% n = number of runs: all runs, the R1 runs and the June runs. These are the
% samples of the black bars and, with errorbar_stat = 'subset', of the red
% and blue bars; with 'pooled' the red/blue bars use all runs, but the
% published legend gives these subset sizes.
n_all = numel(E.res_id); n_R1 = nnz(strcmp(E.region, 'R1')); n_Jun = nnz(strcmp(E.month, 'Jun'));
legend([hr hl], [E.region_names(:)', {sprintf('Ensemble mean \\pm std (n=%d)', n_all), ...
    sprintf('Ensemble mean \\pm std (R1, n=%d)', n_R1), sprintf('Ensemble mean \\pm std (June, n=%d)', n_Jun)}], ...
    'NumColumns', 2, 'Position', [0.125 0.03 0.34 0.09], 'Box','off', 'FontSize', fs);

outname = 'Fig3';
if ~strcmp(errorbar_stat, 'pooled'); outname = [outname '_' errorbar_stat]; end
exportgraphics(fig, fullfile(C.fig_dir,[outname '.png']), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir,[outname '.pdf']), 'ContentType','vector');
close(fig);
fprintf('%s written: (e,f) R = %.2f/%.2f, p = %.3f/%.3f\n', outname, E.corr.(pn{1}).R, E.corr.(pn{2}).R, ...
    E.corr.(pn{1}).P, E.corr.(pn{2}).P);
