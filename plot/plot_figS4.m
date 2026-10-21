%PLOT_FIGS4 Supporting Information Figure S4: evolution of the June-R1 patch.
%   LaTeX label fig:si_patch_distribution; published file Fig_SI_patch_distribution.pdf.
%   dFe = 2e-5 mmol m-3 contours from June to September 2010 at 1/4/12 km,
%   coloured by date (cbrewer Paired, 16 colours = 4 per month, colourbar =
%   month), with the 31 July contour in black.
%   Port of plot_patch_distributions_among_cases in PACMED12_Process_marbl_8p6z.m.
%   The published figure shows days 1, 11 and 21 and the last day of each
%   monthly daily cache: 2, 12, 22, 30 June (the June cache starts on 2 June),
%   1, 11, 21, 31 July and August, and 1, 11, 21, 30 September. This is the
%   commented alternative [1 11 21 length(iron1.time_need)] of the day loop
%   there; the active code samples every 5 days with 10 colours per month.
%   The caption's "every 10 days" describes this sampling approximately.
%   Each contour gets the colour slot of its date, slot = 4*(month-6) + k,
%   with k = 1, 2, 3 for (cache) days 1, 11, 21 and k = 4 for the last day of
%   the month, so the colours match the colourbar for any subset of these
%   dates (e.g. an older data file sampled every 10 days, without 30 June and
%   30 September). The 31 July contour (slot 8) lies under the black one, as
%   in the published figure.
%   Input:  data/patchmaps_grid.mat, data/patchmaps_S4_contours.mat
%   Output: figures/FigS4.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
G = load(fullfile(C.data_dir,'patchmaps_grid.mat'));
S = load(fullfile(C.data_dir,'patchmaps_S4_contours.mat'));
thr = S.threshold;
s4_months = 6:9;
color3 = cbrewer('qual','Paired', numel(s4_months)*4, 'spline');
coltitle = {'1 km','4 km','12 km'};
letters = 'abc';
fs = 8;
reg_lon = G.region_lon_OIF{1}; reg_lat = G.region_lat_OIF{1};

fig = oif_figure('Color','w','Position',[50 50 760 320],'visible','off');
for ires = 1:3
    ax = axes('Position',[0.035+(ires-1)*0.30, 0.07, 0.29, 0.80]);
    lon = double(G.lon{ires}); lat = double(G.lat{ires});
    slot = date_slot(S.s4(ires).time, s4_months(1));   % colour slot of each contour
    assert(all(slot >= 1 & slot <= size(color3,1)), 'OIF:figS4Dates', ...
        'S4 contour dates outside June-September: %s', strjoin(cellstr(datestr(S.s4(ires).time,'yyyy-mm-dd')), ' '));
    m_proj('robinson','long',C.map_lon,'lat',C.map_lat);
    m_coast('patch',[1 1 1]*0.8);
    for it = 1:size(S.s4(ires).dfe,3)
        hold on; m_contour(lon, lat, double(S.s4(ires).dfe(:,:,it)), [thr thr], 'color', color3(slot(it),:), 'linew', 0.5);
    end
    if ~isempty(S.s4(ires).dfe0731)
        hold on; m_contour(lon, lat, double(S.s4(ires).dfe0731), [thr thr], 'color', 'k', 'linew', 1);
    end
    hold on; m_scatter(C.osp(1), C.osp(2), 20, 'b', '^', 'filled');
    hold on; m_plot(reg_lon, reg_lat, 'k', 'LineWidth', 1.5);
    hold on; m_plot(C.ana_lon, C.ana_lat, 'r--', 'LineWidth', 1.5);
    if ires == 1
        m_grid('tickdir','in','yaxislocation','left','xaxislocation','bottom','ticklen',.01,'fontsize',fs);
    else
        m_grid('tickdir','in','yaxislocation','left','xaxislocation','bottom','ticklen',.01,'fontsize',fs,'xticklabels',[],'yticklabels',[]);
    end
    title(coltitle{ires}, 'fontsize', 13, 'fontweight', 'normal');
    text(0.97, 0.03, ['(' letters(ires) ')'], 'Units','normalized','fontsize',11, ...
        'HorizontalAlignment','right','VerticalAlignment','bottom');
    if ires == 3
        colormap(ax, color3); caxis(ax, [0 1]);
        cb = colorbar(ax, 'Position', [0.935 0.10 0.015 0.74]);
        cb.Ticks = linspace(0, 1, numel(s4_months)+1);
        cb.TickLabels = [s4_months, s4_months(end)+1];
        cb.FontSize = fs;
    end
end
exportgraphics(fig, fullfile(C.fig_dir,'FigS4.png'), 'Resolution', 300);
exportgraphics(fig, fullfile(C.fig_dir,'FigS4.pdf'), 'ContentType','image','Resolution',300);
close(fig);
fprintf('saved FigS4: %d contours per panel (%s), colour slots %s\n', size(S.s4(1).dfe,3), ...
    strjoin(cellstr(datestr(S.s4(1).time,'mmdd')), ' '), mat2str(date_slot(S.s4(1).time, s4_months(1))'));

function slot = date_slot(t, month1)
% colour slot 4*(month-month1) + k of datenums t: k = 1, 2, 3 for days 1-10,
% 11-20 and 21 to the day before the last of the month, k = 4 for the last day
dv = datevec(t(:));
k = min(ceil(dv(:,3)/10), 3);
k(dv(:,3) == eomday(dv(:,1), dv(:,2))) = 4;
slot = 4*(dv(:,2) - month1) + k;
end
