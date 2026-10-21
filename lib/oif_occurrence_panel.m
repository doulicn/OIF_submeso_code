function oif_occurrence_panel(ax, lon, lat, occ, reg_lon, reg_lat, meanFI, ttl, showlabels, fs)
%OIF_OCCURRENCE_PANEL One patch-occurrence map (Fig. 1f-h, Figs. S5, S6).
%   Port of the plot block of plot_patch_occurency in
%   PACMED12_Process_marbl_8p6z.m: occurrence = fraction of days with
%   dFe > 2e-5 mmol m-3 during the first two months after release, grey
%   contours at 0.3:0.3:1, black release box, blue OSP triangle, dashed red
%   analysis polygon and the mean filamentation index (FI) at the bottom right.
C = oif_config();
% make ax the current axes (M_Map draws into gca); unlike axes(ax), this
% keeps an invisible figure invisible
fig = ancestor(ax, 'figure');
set(groot, 'CurrentFigure', fig); set(fig, 'CurrentAxes', ax);
m_proj('robinson','lon',C.map_lon,'lat',C.map_lat);
hold on; m_pcolor(double(lon), double(lat), double(occ)); shading interp; caxis([0 1]);
hold on; m_contour(double(lon), double(lat), double(occ), 0.3:0.3:1, 'color', [1 1 1]*0.3, 'linew', 1);
hold on; m_scatter(C.osp(1), C.osp(2), 20, 'b', '^', 'filled');
hold on; m_plot(reg_lon, reg_lat, 'k', 'LineWidth', 1);
hold on; m_plot(C.ana_lon, C.ana_lat, 'r--', 'LineWidth', 1);
title(ttl, 'interpreter', 'none', 'fontsize', fs);
colormap(ax, oif_cmocean('amp', 20));
m_coast('patch', [1 1 1]*0.8);
if showlabels
    m_grid('tickdir','in','yaxislocation','left','xaxislocation','bottom','ticklen',.01, ...
        'fontsize',fs,'xtick',180:4:240,'ytick',40:4:60);
else
    m_grid('tickdir','in','yaxislocation','left','xaxislocation','bottom','ticklen',.01, ...
        'fontsize',fs,'xtick',180:4:240,'ytick',40:4:60,'xticklabels',[],'yticklabels',[]);
end
text(0.97, 0.04, ['FI=', sprintf('%.2f', meanFI)], 'Units','normalized', ...
    'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',fs*1.3, ...
    'BackgroundColor','w','Margin',1);
end
