%PLOT_FIGS3 Supporting Information Figure S3: fertilized patch on 1 July 2010 (June release, R1).
%   LaTeX label fig:map_cmp; published file Fig_SI_map_diff_July1.pdf.
%   (a-c) surface dFe (OIF - control) with OIF-run surface velocity vectors
%         and the dFe = 2e-5 mmol m-3 patch boundary (blue)
%   (d-f) surface dCHL (OIF - control) with velocity vectors
%   Port of the (commented) absolute-difference panel of
%   plot_horizontal_surface_int200m_daily_zoom_test_cmp2 in
%   PACMED12_Process_marbl_8p6z.m (redblue, shading flat, quiver scale 2,
%   grey 0.7), for the June-R1 run pairs (combinations [21 19 41] there).
%   The colour limits, +/-4e-4 mmol m-3 for dFe and +/-4 mg m-3 for dCHL, are
%   those of the colour bars of the published figure and are set here
%   directly: in the present version of that script the block scales
%   clim_var_diff by 0.1, which gives +/-4e-5 and +/-0.6 with the current
%   parameter file. In the published PDF the dCHL panels (d) 1 km and (e)
%   4 km were exported with +/-6 mg m-3 (clim_list_diff{3,1}{1} of
%   PACMED12_Process_param.m; their own colour bars are hidden in the
%   composite, which shows only the +/-4 colour bar of (f)), so they look
%   paler there than here.
%   As in the published figure, the velocity vectors are also drawn in (d-f);
%   the caption mentions them for (a-c).
%   Input:  data/patchmaps_grid.mat, data/patchmaps_S3_july1.mat
%   Output: figures/FigS3.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
G = load(fullfile(C.data_dir,'patchmaps_grid.mat'));
S = load(fullfile(C.data_dir,'patchmaps_S3_july1.mat'));
thr = S.threshold;
cax = {[-4 4]*1e-4, [-4 4]};           % limits of the published colour bars (see above for (d,e))
cblab = {'\Delta Fe (mmol m^{-3})', '\DeltaChl (mg m^{-3})'};
coltitle = {'1 km','4 km','12 km'};
letters = 'abcdef';
fs = 7;
reg_lon = G.region_lon_OIF{1}; reg_lat = G.region_lat_OIF{1};

fig = oif_figure('Color','w','Position',[50 50 660 500],'visible','off');
ip = 0;
for iv = 1:2
    for ires = 1:3
        ip = ip + 1;
        ax = axes('Position',[0.04+(ires-1)*0.295, 0.515-(iv-1)*0.485, 0.28, 0.44]);
        m_proj('robinson','long',C.map_lon,'lat',C.map_lat);
        lon = double(G.lon{ires}); lat = double(G.lat{ires});
        if iv == 1; fld = double(S.s3(ires).dfe); else; fld = double(S.s3(ires).dchl); end
        m_pcolor(lon, lat, fld); shading flat; caxis(cax{iv}); colormap(ax, redblue(256));
        hold on; m_scatter(C.osp(1), C.osp(2), 20, 'b', '^', 'filled');
        m_coast('patch',[1 1 1]*0.8);
        if ires == 1
            if iv == 2
                m_grid('tickdir','in','yaxislocation','left','xaxislocation','bottom','ticklen',.01,'fontsize',fs,'xtick',180:4:240,'ytick',40:4:60);
            else
                m_grid('tickdir','in','yaxislocation','left','xaxislocation','bottom','ticklen',.01,'fontsize',fs,'xtick',180:4:240,'ytick',40:4:60,'xticklabels',[]);
            end
        else
            m_grid('tickdir','in','yaxislocation','left','xaxislocation','bottom','ticklen',.01,'fontsize',fs,'xtick',180:4:240,'ytick',40:4:60,'xticklabels',[],'yticklabels',[]);
        end
        hold on; m_quiver(double(S.s3(ires).qlon), double(S.s3(ires).qlat), double(S.s3(ires).qu), double(S.s3(ires).qv), 2, 'color', [1 1 1]*0.7);
        hold on; m_plot(reg_lon, reg_lat, 'k', 'LineWidth', 1.5);
        if iv == 1
            hold on; m_contour(lon, lat, double(S.s3(ires).dfe), [1 1]*thr, 'color', 'b', 'linew', 0.7);
            title(coltitle{ires}, 'fontsize', 12, 'fontweight', 'normal');
        end
        text(0.03, 0.03, ['(' letters(ip) ')'], 'Units','normalized','fontsize',10,'VerticalAlignment','bottom');
        if ires == 3
            cb = colorbar(ax); cb.Position = [0.925, 0.53-(iv-1)*0.485, 0.015, 0.41];
            cb.FontSize = fs; cb.Label.String = cblab{iv}; cb.Label.FontSize = fs+2;
        end
    end
end
exportgraphics(fig, fullfile(C.fig_dir,'FigS3.png'), 'Resolution', 300);
exportgraphics(fig, fullfile(C.fig_dir,'FigS3.pdf'), 'ContentType','image','Resolution',300);
close(fig);
fprintf('saved FigS3\n');
