%PLOT_FIGS11 Supporting Information Figure S11: seasonal and scale-dependent vertical transport.
%   LaTeX label fig:si_coarse_grain_winter; published file Fig_SI_coarse_grain678.pdf.
%   Vertical transport diagnostics of the full-year 1-km control run.
%   (a) MLD (black) and euphotic depth Zeu (blue, top axis);
%   (b-d) 50-m scale decomposition k[wb], k[wFe], k[wDIC] versus time;
%   (e,f) depth-scale k[wb] in summer and winter; black line = mean MLD.
%   Ported from PACMED12_Process_budget.m
%   (plot_buoy_flux_spectrum_hovmoller_v1, domain 98, plot_mode 'logcontour').
%
%   Run: every panel shows the full-year (2010) 1-km control run without iron
%   addition (OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear, C.cg_ctrl), as in the
%   published figure; the caption says 'in Case 1'. Case 1, the June R1 1-km
%   OIF run, has coarse-grained Fe and DIC fluxes for 2 June-30 September
%   only (used in Fig. S12).
%   season_months: the published panels (e,f) correspond to June-July and
%   December-January averages (their MLD lines are 32.6 m and 101.2 m); the
%   caption describes JJA and DJF (29.8 m and 101.9 m). Set
%   use_caption_seasons = true in the workspace before running the script to
%   use the three-month seasons instead (output FigS11_caption_seasons).
%   Units (derived from the coarse-graining code: w in m s-1, b = -g*rho/rho0
%   in m s-2, Fe and DIC in mmol m-3, filter scale in km): k[wb] in
%   m2 s-3 km-1, k[wFe] and k[wDIC] in mmol m-2 s-1 km-1. As published, the
%   colour bars are unlabelled and panel (f) has no x-axis label (of the
%   depth-scale panels only (e) is labelled).
%
%   Input:  data/coarsegrain_hovmoller.mat
%   Output: figures/FigS11.png/.pdf (FigS11_caption_seasons.png/.pdf with
%           use_caption_seasons = true)

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
load(fullfile(C.data_dir, 'coarsegrain_hovmoller.mat'), 'cg');

if ~exist('use_caption_seasons', 'var'); use_caption_seasons = false; end
if ~(islogical(use_caption_seasons) || isnumeric(use_caption_seasons)) || ~isscalar(use_caption_seasons) ...
        || ~ismember(use_caption_seasons, [0 1])
    error('OIF:FigS11:option', 'use_caption_seasons must be true or false.');
end
if use_caption_seasons
    season_months = {[6 7 8], [12 1 2]};
else
    season_months = {[6 7], [12 1]};
end
season_title = {'summer','winter'};

fs = 9; ncm = 20; depshow = -120;
cmap = oif_cmocean('balance', 20);
% log10 colour ranges (clim_tmp_all{1} of the original: wb, wFe, wDIC)
ord.wb = [-11 -9]; ord.wFe = [-13 -11]; ord.wDIC = [-7 -5];
xtime_label = datenum(2010, 1:13, 1);

fig = oif_figure('visible','off','units','centimeters','position',[2 2 17 22],'color','w');
colormap(fig, cmap);
W = 0.33; Hh = 0.225; xl = [0.10 0.565]; yb = [0.705 0.38 0.055]; cbw = 0.012; cbg = 0.012;
P = @(c,r) [xl(c) yb(r) W Hh];
CB = @(c,r) [xl(c)+W+cbg yb(r) cbw Hh];

%% (a) MLD and Zeu
ax = axes('position', P(1,1)); hold on;
plot(cg.mld, cg.mld_date, '-', 'LineWidth', 1.5, 'Color', 'k');
set(ax, 'ytick', xtime_label(1:end-1), 'yticklabel', datestr(xtime_label(1:end-1), 'mmm'), 'fontsize', fs);
ylim([xtime_label(1)-10, xtime_label(end)]);
xlabel('MLD (m)'); xlim([0 150]);
box off; grid on; ax.XMinorTick = 'on'; ax.YMinorTick = 'on'; ax.MinorGridLineStyle = ':';
ax2 = axes('position', ax.Position, 'XAxisLocation','top', 'YAxisLocation','right', ...
    'color','none', 'XColor','b', 'YColor','none', 'fontsize', fs);
hold(ax2, 'on');
plot(ax2, cg.zeu, cg.zeu_time, '-o', 'LineWidth', 1.5, 'Color','b', 'MarkerSize', 4, 'MarkerFaceColor','b');
set(ax2, 'ytick', [], 'ylim', ax.YLim, 'XMinorTick','on');
xlabel(ax2, 'Zeu (m)'); xlim(ax2, [0 200]);
linkaxes([ax ax2], 'y');
title(ax2, '{\color{black}MLD} / {\color{blue}Zeu} (m)', 'interpreter','tex');
panel_letter(ax, '(a)', fs);

%% (b-d) 50-m Hovmoller of k[w*]
hv = {'wb_ctrl','wb'; 'wFe_ctrl','wFe'; 'wDIC_ctrl','wDIC'};
cr = [2 1; 1 2; 2 2]; lett = {'(b)','(c)','(d)'};
scale = cg.scale(:)';
for k = 1:3
    H = cg.(hv{k,1});
    iv = find(H.valid50);
    w50 = double(H.w50);
    data = diff(w50(iv,:),1,2) ./ diff(scale);
    [xx, yy] = meshgrid((scale(1:end-1)+scale(2:end))/2, cg.time(iv));
    ax = axes('position', P(cr(k,1), cr(k,2)));
    o = ord.(hv{k,2});
    plot_log_contour(xx, yy, data, ~isnan(data), o(1), o(2), ncm, cmap, CB(cr(k,1), cr(k,2)));
    set(ax, 'xscale','log', 'xtick',[1 10 100 1000], 'ytick', xtime_label(1:end-1), ...
        'yticklabel', datestr(xtime_label(1:end-1),'mmm'), 'layer','top', 'fontsize', fs);
    xlim([1 1000]); xlabel('Spatial scale (km)');
    ylim([xtime_label(1)-10, xtime_label(end)]);
    box on; grid on; set(ax, 'XMinorTick','on', 'MinorGridLineStyle',':');
    title({'$\mathrm{50m:}$', ['$\mathrm{k[' hv{k,2} ']}$']}, 'interpreter','latex');
    panel_letter(ax, lett{k}, fs);
end

%% (e,f) depth-scale k[wb]
lett = {'(e)','(f)'};
for is = 1:2
    [kz, xs, mld] = cg_depth_scale(cg.wb_ctrl, cg.scale, cg.mld_all, season_months{is}, cg.time);
    [xx, yy] = meshgrid(xs, -cg.dep);
    ax = axes('position', P(is,3));
    plot_log_contour(xx, yy, kz, ~isnan(kz), ord.wb(1), ord.wb(2), ncm, cmap, CB(is,3));
    set(ax, 'xscale','log', 'xtick',[1 10 100 1000], 'ytick',[-600:100:-300 -200:50:-100 -80:20:-5], ...
        'layer','top', 'fontsize', fs);
    xlim([1 1000]);
    if is == 1; xlabel('Spatial scale (km)'); ylabel('Depth (m)'); end
    box on; grid on; set(ax, 'XMinorTick','on', 'MinorGridLineStyle',':');
    yline(-mld, 'color','k', 'linew', 1); ylim([depshow 0]);
    title({['$\mathrm{Vertical: ' season_title{is} '}$'], '$\mathrm{k[wb]}$'}, 'interpreter','latex');
    panel_letter(ax, lett{is}, fs);
    fprintf('(%s) months %s: mean MLD = %.2f m\n', lett{is}(2), mat2str(season_months{is}), mld);
end

outname = 'FigS11';
if use_caption_seasons; outname = [outname '_caption_seasons']; end
exportgraphics(fig, fullfile(C.fig_dir, [outname '.png']), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir, [outname '.pdf']), 'ContentType', 'vector');
close(fig);
fprintf('%s written.\n', outname);

function panel_letter(ax, s, fs)
text(ax, 0.97, 0.04, s, 'Units','normalized', 'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', 'FontSize', fs+3);
end
