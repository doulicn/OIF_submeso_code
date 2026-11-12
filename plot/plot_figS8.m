%PLOT_FIGS8 Supporting Information Figure S8: limiting nutrient at the R1 centre.
%   LaTeX label fig:si_nutrient_limit; published file Fig_SI_nutrient_limit.pdf.
%   Limiting nutrient (N, Fe, P, Si) in the upper 200 m at the centre of
%   release region R1 (station OIFCT, 52.27 N, 145.95 W) during the first two
%   months after the June release, for small phytoplankton (SP), diatoms
%   (DIAT) and diazotrophs (DIAZ): (a-c) 1-km control run, (d-f) 1-km
%   June-R1 OIF run (Case 1); black contour: OIF - control dFe = 2e-5
%   mmol m-3 (patch threshold).
%
%   As in the published figure (and the original code), the limitation type
%   is drawn with pcolor and interpolated shading, so that thin bands of the
%   intermediate colour (P, green) mark the edges between Fe- and
%   Si-limited areas; they are not P-limited cells.
%   Ported from PACMED12_Process_marbl_8p6z.m (section 'plot nutrient
%   limitations vertical profile').
%
%   Option (set in the workspace before running the script):
%     use_dop = false (default) as published (DOC in place of DOP in the P
%               factor, see prep/prep_nutrient_limitation.m); true: DOP
%               (needs data/nutrient_limit_R1_DOP.mat; output FigS8_DOP)
%
%   Input:  data/nutrient_limit_R1.mat (from prep/prep_nutrient_limitation.m)
%   Output: figures/FigS8.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~exist('use_dop', 'var'); use_dop = false; end
outname = 'FigS8'; dfile = 'nutrient_limit_R1.mat';
if use_dop; outname = 'FigS8_DOP'; dfile = 'nutrient_limit_R1_DOP.mat'; end
L = load(fullfile(C.data_dir, dfile));
fs = 9;
cmap = cbrewer('qual', 'Set1', 4);       % N red, Fe blue, P green, Si purple
ticks = linspace(L.time_lim(1), L.time_lim(2), 7);
rows = {'ctrl', 'oif'}; row_name = {'1KM\_control', '1KM\_June'};

fig = oif_figure('Units','centimeters','Position',[2 2 19 9.6],'Color','w','Visible','off');
w = 0.255; h = 0.30; x0 = [0.075 0.345 0.615]; y0 = [0.595 0.115];
for ir = 1:2
    D = L.(rows{ir});
    [tt, zz] = meshgrid(D.time, D.depth);
    for ia = 1:3
        ax = axes('Position', [x0(ia) y0(ir) w h], 'FontSize', fs);
        pcolor(ax, tt, zz, squeeze(D.lim_type(ia,:,:))); shading(ax, 'interp'); hold(ax, 'on');
        if ir == 2
            contour(ax, tt, zz, D.dFe, [1 1]*L.patch_threshold, 'Color','k', 'LineWidth', 1.0);
        end
        clim(ax, [0.5 4.5]); colormap(ax, cmap);
        xlim(ax, L.time_lim); ylim(ax, [-200 0]);
        set(ax, 'XTick', ticks, 'XTickLabel', datestr(ticks, 'mm-dd'), 'Layer','top', 'Box','on');
        xtickangle(ax, 0); ax.XAxis.FontSize = fs-1.5;
        grid(ax, 'on');
        if ia == 1
            ylabel(ax, '$\mathrm{Depth\ (m)}$', 'Interpreter','latex');
            xlabel(ax, 'Date in 2010');
            title(ax, {['$\mathrm{' row_name{ir} ',\ OIFCT,\ Nutrient\ Limiting\ Type}$'], ...
                ['$\mathrm{' L.phyto{ia} '}$']}, 'Interpreter','latex', 'FontWeight','normal', ...
                'HorizontalAlignment','left', 'Units','normalized', 'Position',[0 1.0 0]);
        else
            set(ax, 'YTickLabel', []);
            title(ax, ['$\mathrm{' L.phyto{ia} '}$'], 'Interpreter','latex', 'FontWeight','normal');
        end
        text(ax, 0.03, 0.1, ['(' char('a' + (ir-1)*3 + ia - 1) ')'], 'Units','normalized', 'FontSize', fs+4);
        if ia == 3
            cb = colorbar(ax, 'Position', [x0(3)+w+0.012 y0(ir) 0.012 h]);
            cb.Ticks = 1:4; cb.TickLabels = L.type_names; cb.FontSize = fs-1;
        end
    end
end

exportgraphics(fig, fullfile(C.fig_dir,[outname '.png']), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir,[outname '.pdf']), 'ContentType','image', 'Resolution', 400);   % interpolated pcolor shading does not render reliably as vector
close(fig);
fprintf('%s written.\n', outname);
