%PLOT_FIGS12 Supporting Information Figure S12: depth-scale vertical Fe and DIC fluxes.
%   LaTeX label fig:si_coarse_grain_seasonal; published file Fig_coarse_grain_FeDIC.pdf.
%   Vertical (a,b) Fe and (c,d) DIC fluxes, control (left) vs OIF Case 1
%   (June R1, 1 km; right), averaged over June-July.
%   Control: the full-year (2010) 1-km control run
%   (OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear, C.cg_ctrl, also used in Fig. S11),
%   as in the published figure; not C.ctrl{1}, the May-September 1-km control
%   paired with the OIF runs elsewhere, for which no coarse-grained fluxes exist.
%   Black line: mean control MLD over the same days, drawn in all four panels,
%   the OIF panels included (the MLD cache of the OIF run is empty, and the
%   published OIF panels show the same 32.6-m line).
%   Units: k[wFe] and k[wDIC] in mmol m-2 s-1 km-1 (see plot_figS11.m).
%   Ported from PACMED12_Process_budget.m
%   (plot_buoy_flux_spectrum_hovmoller_v1 seasonal block, run_num 3 and 5).
%   avg_months = [6 7 8], set in the workspace before running the script,
%   gives the JJA average of the original code's iseason = 3 (output
%   FigS12_months_6_7_8). The OIF run has coarse-grained fluxes for
%   June-September only, so avg_months must lie within 6-9.
%   Input:  data/coarsegrain_hovmoller.mat
%   Output: figures/FigS12.png/.pdf (FigS12_months_<months>.png/.pdf with
%           avg_months other than [6 7])

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
load(fullfile(C.data_dir, 'coarsegrain_hovmoller.mat'), 'cg');

if ~exist('avg_months', 'var'); avg_months = [6 7]; end
if ~isnumeric(avg_months) || isempty(avg_months) || ~all(ismember(avg_months, 1:12)) ...
        || numel(unique(avg_months)) ~= numel(avg_months)
    error('OIF:FigS12:months', 'avg_months must be distinct calendar months, e.g. [6 7] or [6 7 8].');
end
if any(cg.wFe_oif.nday_month(avg_months) == 0) || any(cg.wDIC_oif.nday_month(avg_months) == 0)
    error('OIF:FigS12:months', ['avg_months = %s: the OIF run (Case 1) has coarse-grained ' ...
        'fluxes for June-September only.'], mat2str(avg_months));
end
fs = 9; ncm = 20; depshow = -120;
cmap = oif_cmocean('balance', 20);
ord.wFe = [-13 -11]; ord.wDIC = [-7 -5];

fig = oif_figure('visible','off','units','centimeters','position',[2 2 17 14.5],'color','w');
colormap(fig, cmap);
W = 0.33; Hh = 0.32; xl = [0.10 0.565]; yb = [0.565 0.085]; cbw = 0.012; cbg = 0.012;
flds = {'wFe_ctrl','wFe_oif'; 'wDIC_ctrl','wDIC_oif'};
vars = {'wFe','wDIC'}; coltit = {'Control','OIF'};
lett = {'(a)','(b)'; '(c)','(d)'};
for r = 1:2
    for c = 1:2
        [kz, xs, mld] = cg_depth_scale(cg.(flds{r,c}), cg.scale, cg.mld_all, avg_months, cg.time);
        [xx, yy] = meshgrid(xs, -cg.dep);
        ax = axes('position', [xl(c) yb(r) W Hh]);
        o = ord.(vars{r});
        plot_log_contour(xx, yy, kz, ~isnan(kz), o(1), o(2), ncm, cmap, [xl(c)+W+cbg yb(r) cbw Hh]);
        set(ax, 'xscale','log', 'xtick',[1 10 100 1000], 'ytick',[-600:100:-300 -200:50:-100 -80:20:-5], ...
            'layer','top', 'fontsize', fs);
        xlim([1 1000]); xlabel('Spatial scale (km)');
        if c == 1; ylabel('Depth (m)'); end
        box on; grid on; set(ax, 'XMinorTick','on', 'MinorGridLineStyle',':');
        yline(-mld, 'color','k', 'linew', 1); ylim([depshow 0]);
        title(['$\mathrm{k[' vars{r} ']}$'], 'interpreter','latex');
        text(ax, 0, 1.03, lett{r,c}, 'Units','normalized', 'VerticalAlignment','bottom', 'FontSize', fs+1);
        if r == 1
            text(ax, 0.5, 1.16, coltit{c}, 'Units','normalized', 'HorizontalAlignment','center', ...
                'VerticalAlignment','bottom', 'FontSize', fs+2);
        end
    end
end
fprintf('FigS12: months %s, mean control MLD = %.2f m\n', mat2str(avg_months), mld);

outname = 'FigS12';
if ~isequal(avg_months(:)', [6 7]); outname = ['FigS12_months' sprintf('_%d', avg_months)]; end
exportgraphics(fig, fullfile(C.fig_dir, [outname '.png']), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir, [outname '.pdf']), 'ContentType', 'vector');
close(fig);
fprintf('%s written.\n', outname);
