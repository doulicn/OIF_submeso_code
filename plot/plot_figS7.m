%PLOT_FIGS7 Supporting Information Figure S7: June-R1 patch statistics, June-September 2010.
%   LaTeX label fig:si_lines_cmp_max; published file Fig_SI_lines_cmp_max2.pdf.
%   Patch statistics of the June-R1 release at 1/4/12 km.
%   Columns: OIF run, control run, OIF-control. Rows: surface Fe, NO3, CHL,
%   POC flux at 100 m, air-sea CO2 flux. Thick: patch-area mean
%   (area-weighted sum / patch area); thin: patch max/min; shading: 5-95th
%   percentile. Black: SERIES 2002 observations (difference column).
%
%   The caption does not give the shading, the depth of the POC flux or the
%   timing of the observations: the SERIES 2002 in-patch minus out-patch
%   series (Boyd et al., 2005; Fe, NO3, CHL and POC flux, none for CO2) are
%   shifted by -29 days (O.time_offset) so that the SERIES release lines up
%   with the model release on 2 June.
%   Panels a, c, f-i, l and n use the y-limits and ticks of the published
%   panels, which come from separate per-row figures with other automatic
%   limits; the other panels keep their automatic limits, which equal the
%   published ones.
%
%   Input:  data/ts_patch_timeseries.mat, data/obs_series2002.mat
%   Output: figures/FigS7.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
T = load(fullfile(C.data_dir, 'ts_patch_timeseries.mat'));
O = load(fullfile(C.data_dir, 'obs_series2002.mat'));
runs = find(T.exp_id == 1);
col = C.col_res; lbl = {'1KM','4KM','12KM'};
tend = datenum(2010,9,30);
xt = datenum(2010,6:9,1); xl = [xt(1)-10, datenum(2010,10,1)];

vs  = {'Fe_surf','NO3_surf','CHL_surf','POC_FLUX_100m','CO2_FLUX_surf'};
obs = {'Fe','NO3','CHL','POC_FLUX_100m',''};
nm  = {'Fe','NO_3','CHL','POC\ FLUX','CO_2\ FLUX'};
un  = {'mmol\ m^{-3}','mmol\ m^{-3}','mg\ m^{-3}','mmol\ m^{-2}\ d^{-1}','mmol\ m^{-2}\ d^{-1}'};
ttl = {'OIF','Control','OIF-Control'};
% y-limits and y-ticks of the published panels a-o ([] = automatic; Inf =
% automatic upper limit)
ylim_pub  = {[0 0.025], [], [0 0.025], [], [], [], [], [0 2.5], [-2 8], ...
             [], [], [-20 Inf], [], [-30 Inf], []};
ytick_pub = {0:0.005:0.025, [], 0:0.005:0.025, [], [], -10:2:0, 0:2:10, 0:0.5:2.5, -2:2:8, ...
             [], [], -20:20:60, [], -30:10:10, []};

fig = oif_figure('Units','centimeters','Position',[2 2 21.8 17.7],'Color','w','Visible','off');
fs = 7;
W = 0.255; H = 0.135; X = [0.075 0.405 0.735]; Y = 0.785 - (0:4)*0.181;
letters = 'abcdefghijklmno'; n = 0;
for r = 1:5
    D = T.(vs{r});
    for k = 1:3
        n = n + 1;
        ax = axes('Position',[X(k) Y(r) W H]); hold on;
        yline(0,'k--','LineWidth',1.2,'HandleVisibility','off');
        h = gobjects(3,1);
        for j = 1:3
            i = runs(j);
            s = D.stats(:,:,k,i); a = D.area(:,i);
            iu = find(~isnan(s(:,5)) & T.date <= tend);
            t = T.date(iu)';
            fill([t, fliplr(t)], [s(iu,1); flipud(s(iu,2))]', col(j,:), 'EdgeColor','none', 'FaceAlpha',0.1, 'HandleVisibility','off');
            plot(t, s(iu,4), '-', 'Color', col(j,:), 'LineWidth', 0.5, 'HandleVisibility','off');
            plot(t, s(iu,3), '-', 'Color', col(j,:), 'LineWidth', 0.5, 'HandleVisibility','off');
            h(j) = plot(t, s(iu,5)./a(iu), '-', 'Color', col(j,:), 'LineWidth', 1.5);
        end
        if k == 3 && ~isempty(obs{r})
            plot(O.(obs{r}).time + O.time_offset, O.(obs{r}).data, '-', 'Color','k', 'LineWidth',1);
        end
        set(ax, 'XTick', xt, 'XTickLabel', datestr(xt,'mmm'), 'XLim', xl, 'FontSize', fs, 'Box','on');
        if ~isempty(ylim_pub{n});  ylim(ax, ylim_pub{n});   end
        if ~isempty(ytick_pub{n}); yticks(ax, ytick_pub{n}); end
        grid on;
        if k == 3; pre = '\Delta '; else; pre = ''; end
        ylabel(['$\mathrm{' pre nm{r} '\ (' un{r} ')}$'], 'Interpreter','latex', 'FontSize', fs-1);
        text(0.02, 0.85, ['(' letters(n) ')'], 'Units','normalized', 'FontSize', fs+3);
        if r == 1; title(ttl{k}, 'FontSize', fs+5, 'FontWeight','normal'); end
        if k == 1 && (r == 1 || r == 4); legend(h, lbl, 'Location','northeast', 'FontSize', fs-1); end
        if k == 1 && r == 5; xlabel('Month of 2010'); end
    end
end

exportgraphics(fig, fullfile(C.fig_dir,'FigS7.png'), 'Resolution', 300);
exportgraphics(fig, fullfile(C.fig_dir,'FigS7.pdf'), 'ContentType','vector');
close(fig);
fprintf('FigS7 written.\n');
