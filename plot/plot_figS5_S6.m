%PLOT_FIGS5_S6 Supporting Information Figures S5 and S6: patch occurrence probability.
%   LaTeX labels fig:si_occurence_regions (S5) and fig:si_occurence_months (S6);
%   published files Fig_SI_patch_occurence_Regions.pdf and _Months.pdf.
%   S5: June release at R1, R2, R3 (rows) x 1/4/12 km (columns)
%   S6: May, July, August release at R1 (rows) x 1/4/12 km (columns)
%   Occurrence = fraction of days with dFe > 2e-5 mmol m-3 during the first
%   two calendar months starting at the release month. FI is the mean over
%   the same days of the daily filamentation index P^2/(4*pi*A), with P the
%   perimeter and A the area of the patch. This is the formula of the
%   original code and gives all published FI values (e.g. 39.43, 17.23 and
%   6.53 for the June release at R1). The caption of Fig. S5 (and so of S6)
%   defines FI = P/sqrt(A); the means of that ratio are stored as
%   meanFI_Psqrt in data/patchmaps_occurrence.mat.
%   Port of plot_patch_occurency in PACMED12_Process_marbl_8p6z.m.
%   Input:  data/patchmaps_grid.mat, data/patchmaps_occurrence.mat
%   Output: figures/FigS5.png/.pdf, figures/FigS6.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
G = load(fullfile(C.data_dir,'patchmaps_grid.mat'));
O = load(fullfile(C.data_dir,'patchmaps_occurrence.mat'));

figs = struct('name',{'FigS5','FigS6'}, 'rows',{[1 5 6],[2 3 4]});
mon = {'Jun','May','Jul','Aug','Jun','Jun'};
suffix = {'','','','','_R2','_R3'};
letters = 'abcdefghi';
fs = 7;
for ifig = 1:2
    fig = oif_figure('Color','w','Position',[50 50 640 780],'visible','off');
    ip = 0;
    for r = 1:3
        irow = figs(ifig).rows(r);
        for ires = 1:3
            ip = ip + 1;
            ax = axes('Position',[0.055+(ires-1)*0.293, 0.68-(r-1)*0.325, 0.275, 0.30]);
            ttl = [C.res_label{ires}, '_', mon{irow}, suffix{irow}];
            ireg = O.exp_region(irow);
            oif_occurrence_panel(ax, G.lon{ires}, G.lat{ires}, O.occ{irow,ires}, ...
                G.region_lon_OIF{ireg}, G.region_lat_OIF{ireg}, O.meanFI_P2(irow,ires), ttl, ires==1, fs);
            text(0.03, 0.04, ['(' letters(ip) ')'], 'Units','normalized','fontsize',11, ...
                'VerticalAlignment','bottom','BackgroundColor','w','Margin',1);
            if ires == 3
                cb = colorbar(ax); cb.Position = [0.94, 0.69-(r-1)*0.325, 0.015, 0.28]; cb.FontSize = fs; cb.Ticks = 0:0.2:1;
            end
        end
    end
    exportgraphics(fig, fullfile(C.fig_dir,[figs(ifig).name '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(C.fig_dir,[figs(ifig).name '.pdf']), 'ContentType','image','Resolution',300);
    close(fig);
    fprintf('saved %s\n', figs(ifig).name);
end
