%PLOT_FIGS9 Supporting Information Figure S9: ensemble variability of POC export at 100 m.
%   LaTeX label fig:si_ens_POC; published file Fig_SI_ens_variance_POC.pdf.
%   (a) 60-day POC flux anomaly integrated over the OSP-1KM domain vs
%   resolution (right axis tons C), (b) variance partition of the domain-integrated
%   POC flux anomaly (R1: timing x resolution; June: region x resolution),
%   (c-e) POC flux anomaly vs (c) patch area, (d) patch-integrated control
%   PHYC and (e) patch-area mean control-run mixed-layer depth, (f) air-sea
%   CO2 flux anomaly vs the same mixed-layer depth, (g,h) POC export (g) and
%   CO2 flux (h) anomalies vs release month; lines: mean of each resolution
%   (1, 4, 12 km; darker = finer), error bars in June: std across R1-R3.
%
%   (a)-(h) all use the integral over the OSP-1KM domain (label int_A).
%
%   Differences from the caption:
%   - Red and blue error bars in (a) pool runs as described in plot_fig3.m
%     (all six runs of a resolution enter both); the caption describes
%     statistics of the R1 runs (red) and of the June runs (blue).
%   - In (g,h) the June runs of a resolution are spread by +/-0.07 month so
%     that they do not overlap, as in the original code.
%
%   Options (set the variables in the workspace before running the script),
%   as in plot_fig3.m:
%     errorbar_stat = 'pooled'  (default) or 'subset' (red: the four R1 runs,
%                               blue: the three June runs of a resolution)
%   With a non-default option the output is figures/FigS9_<options>.png/.pdf.
%
%   Input:  data/ens_metrics.mat, data/ens_mld.mat (from prep/prep_ensemble_mld.m)
%   Output: figures/FigS9.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~exist('errorbar_stat', 'var'); errorbar_stat = 'pooled'; end
errorbar_stat = validatestring(errorbar_stat, {'pooled', 'subset'});
E = load(fullfile(C.data_dir, 'ens_metrics.mat'));
M = load(fullfile(C.data_dir, 'ens_mld.mat'));
S = oif_ens_style(E);
tonsC = C.mmolC_to_tC; fs = 8;

fig = oif_figure('Units','centimeters','Position',[2 2 18.5 19],'Color','w','Visible','off');
yr = [0.795 0.548 0.300 0.055]; hr = 0.175;     % bottom of the four rows, row height
P = {[0.08 yr(1) 0.37 hr], [0.585 yr(1) 0.37 hr], [0.08 yr(2) 0.37 hr], [0.585 yr(2) 0.37 hr], ...
     [0.08 yr(3) 0.37 hr], [0.585 yr(3) 0.37 hr], [0.08 yr(4) 0.37 hr], [0.585 yr(4) 0.37 hr]};

% ---- (a) ----
va = E.int_dom_POC100;                 % A = OSP-1KM domain, as in (b)-(d)
lab = @(u) ['$\mathrm{\int_{A}^T(\Delta POC\ FLUX),\ (' u ')}$'];
ax = axes('Position', P{1}, 'FontSize', fs);
yyaxis(ax, 'left'); set(ax, 'YColor', 'k');
plot_ens_resolution(ax, va, E, S, [], errorbar_stat);
ylabel(lab('mmol\ C'), 'Interpreter','latex', 'Color','k');
yl = ylim(ax); dy = diff(yticks(ax));         % automatic, top on a tick
yl(2) = ceil(yl(2)/dy(1))*dy(1);
ylim(ax, yl);
yyaxis(ax, 'right'); set(ax, 'YColor', 'k'); ylim(ax, yl*tonsC);
ylabel(lab('Tons\ C'), 'Interpreter','latex', 'Color','k');
yyaxis(ax, 'left');
text(ax, 0.02, 0.1, '(a)', 'Units','normalized', 'FontSize', fs+2);

% ---- (b) variance partition (bars) ----
ax = axes('Position', P{2}, 'FontSize', fs); hold on;
im = find(strcmp(E.var.metric, 'POC_FLUX_100m'));
h = [E.var.pct_R1(im,:), E.var.pct_June(im,:)];
xp = [1 2 3 5 6 7];
bc = [S.col_time; S.col_res; S.col_int; S.col_reg; S.col_res; S.col_int];
for k = 1:6
    bar(xp(k), h(k), 0.7, 'FaceColor', bc(k,:), 'EdgeColor','none');
end
ylim([0 100]); xlim([0 9.5]);          % as published (xlim([0, xcur+gap*0.5]) in the original code)
set(ax, 'XTick', xp, 'XTickLabel', {'Time','Res.','Int.','Reg.','Res.','Int.'}, 'TickLength',[0 0], 'Box','on');
text(2, -18, 'R1', 'HorizontalAlignment','center', 'FontWeight','bold', 'FontSize', fs, 'Clipping','off');
text(6, -18, 'June', 'HorizontalAlignment','center', 'FontWeight','bold', 'FontSize', fs, 'Clipping','off');
ylabel('$\mathrm{Variance\ explained\ (\%)}$', 'Interpreter','latex');
title('$\mathrm{POC\ FLUX\ (100\ m)}$', 'Interpreter','latex', 'FontWeight','normal');
grid on;
hv = gobjects(1,4); lc = [S.col_reg; S.col_time; S.col_res; S.col_int];
for k = 1:4; hv(k) = plot(nan, nan, 's', 'MarkerFaceColor', lc(k,:), 'MarkerEdgeColor','none', 'MarkerSize', 7); end
legend(hv, {'Region','Timing','Resolution','Interaction'}, 'Location','northeast', 'Box','off', 'FontSize', fs);
text(ax, 0.98, 0.1, '(b)', 'Units','normalized', 'HorizontalAlignment','right', 'FontSize', fs+2);

% ---- (c,d) correlations ----
ylab = '$\mathrm{\int_{A}^T(\Delta POC\ FLUX),\ (mmol)}$';
pn = {'dPOC_FLUX_int_vs_PatchArea', 'dPOC_FLUX_int_vs_ctrlPHYC_int'};
xlab = {'Patch area (km^2)', '$\mathrm{\int_{A}^T(PHYC_{ctrl}),\ (mmol\ m^{-1})}$'};
xint = {'tex','latex'}; pos_lbl = [0.02 0.98]; ha = {'left','right'};
for k = 1:2
    ax = axes('Position', P{2+k}, 'FontSize', fs);
    plot_ens_corr(ax, E.corr.(pn{k}), S, S.msize, fs);
    xlabel(xlab{k}, 'Interpreter', xint{k}); ylabel(ylab, 'Interpreter','latex');
    ylim([0 15e12]);
    if k == 1
        xlim([1 4]*1e4);
        hm = gobjects(1,4); hr = gobjects(1,3);
        for j = 1:4; hm(j) = scatter(ax, nan, nan, S.msize, 'o', 'MarkerEdgeColor','k', 'MarkerFaceColor', S.month_col(j,:)); end
        for j = 1:3; hr(j) = scatter(ax, nan, nan, S.msize, S.region_marker{j}, 'MarkerEdgeColor','k', 'MarkerFaceColor', S.region_face); end
        legend(ax, [hm hr], [E.month_names(:)', E.region_names(:)'], 'NumColumns', 2, 'Location','southeast', ...
            'FontSize', fs-1, 'Box','on');
    else
        axis tight; ylim([0 15e12]);
    end
    text(ax, pos_lbl(k), 0.1, ['(' char('b'+k) ')'], 'Units','normalized', 'HorizontalAlignment', ha{k}, 'FontSize', fs+2);
end

% ---- (e,f) POC and CO2 flux anomalies vs control-run MLD under the patch ----
pm = {'dPOC_FLUX_int_vs_ctrlMLD_wavg', 'dCO2_FLUX_int_vs_ctrlMLD_wavg'};
ylab = {'$\mathrm{\int_{A}^T(\Delta POC\ FLUX),\ (mmol)}$', '$\mathrm{\int_{A}^T(\Delta CO_2\ FLUX),\ (mmol)}$'};
ylims = {[0 15e12], [0 8e12]};
for k = 1:2
    ax = axes('Position', P{4+k}, 'FontSize', fs);
    plot_ens_corr(ax, M.corr.(pm{k}), S, S.msize, fs);
    xlabel('Patch-area mean MLD_{ctrl} (m)', 'Interpreter','tex'); ylabel(ylab{k}, 'Interpreter','latex');
    axis tight; ylim(ylims{k});
    text(ax, 0.02, 0.1, ['(' char('d'+k) ')'], 'Units','normalized', 'FontSize', fs+2);
end

% ---- (g,h) POC and CO2 flux anomalies vs release month, by resolution ----
mon_order = {'May','Jun','Jul','Aug'};
res_col = [0 0 0; 0.45 0.45 0.45; 0.72 0.72 0.72];   % 1, 4, 12 km (darker = finer)
res_dx = [-0.25 0 0.25];
[~, mon_id] = ismember(E.month, mon_order);
vmon = {E.int_dom_POC100, E.int_dom_CO2};
lab = {@(u) ['$\mathrm{\int_{A}^T(\Delta POC\ FLUX),\ (' u ')}$'], @(u) ['$\mathrm{\int_{A}^T(\Delta CO_2\ FLUX),\ (' u ')}$']};
for k = 1:2
    v = vmon{k};
    ax = axes('Position', P{6+k}, 'FontSize', fs); hold(ax, 'on');
    yyaxis(ax, 'left'); set(ax, 'YColor', 'k');
    hres = gobjects(1,3);
    for ir = 1:3
        mu = nan(1,4); sd = nan(1,4);
        for im = 1:4
            sel = E.res_id == ir & mon_id == im & ~isnan(v);
            if any(sel); mu(im) = mean(v(sel)); sd(im) = std(v(sel), 0); end
        end
        hres(ir) = errorbar(ax, (1:4)+res_dx(ir), mu, sd, 's-', 'Color', res_col(ir,:), ...
            'MarkerFaceColor', res_col(ir,:), 'LineWidth', 1.2, 'MarkerSize', 4, 'CapSize', 4);
    end
    for ir = 1:3
        for im = 1:4
            sel = find(E.res_id == ir & mon_id == im & ~isnan(v));
            if numel(sel) > 1; jit = linspace(-0.07, 0.07, numel(sel)); else; jit = 0; end
            for j = 1:numel(sel)
                scatter(ax, im+res_dx(ir)+jit(j), v(sel(j)), S.msize*0.6, S.marker{sel(j)}, ...
                    'MarkerFaceColor', S.color(sel(j),:), 'MarkerEdgeColor','k', 'HandleVisibility','off');
            end
        end
    end
    xlim(ax, [0.5 4.5]); xticks(ax, 1:4); xticklabels(ax, mon_order);
    ylabel(ax, lab{k}('mmol\ C'), 'Interpreter','latex', 'Color','k');
    yl = ylim(ax); yl(1) = 0; ylim(ax, yl);
    yyaxis(ax, 'right'); set(ax, 'YColor', 'k'); ylim(ax, yl*tonsC);
    ylabel(ax, lab{k}('Tons\ C'), 'Interpreter','latex', 'Color','k');
    yyaxis(ax, 'left'); grid(ax, 'on'); box(ax, 'on');
    text(ax, 0.02, 0.1, ['(' char('f'+k) ')'], 'Units','normalized', 'FontSize', fs+2);
    if k == 1
        legend(ax, hres, strcat('Ensemble mean \pm std (', C.res_label, ')'), 'Location','northeast', ...
            'FontSize', fs-2, 'Box','on');
    end
end

outname = 'FigS9';
if ~strcmp(errorbar_stat, 'pooled'); outname = [outname '_' errorbar_stat]; end
exportgraphics(fig, fullfile(C.fig_dir,[outname '.png']), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir,[outname '.pdf']), 'ContentType','vector');
close(fig);
fprintf('%s: MLD R = %.2f (POC), %.2f (CO2)\n', outname, M.corr.(pm{1}).R, M.corr.(pm{2}).R);
fprintf('%s: var R1 [Time Res Int] = %s, June [Reg Res Int] = %s; R = %.2f/%.2f, p = %.3f/%.3f\n', ...
    outname, mat2str(round(E.var.pct_R1(im,:),1)), mat2str(round(E.var.pct_June(im,:),1)), ...
    E.corr.(pn{1}).R, E.corr.(pn{2}).R, E.corr.(pn{1}).P, E.corr.(pn{2}).P);
