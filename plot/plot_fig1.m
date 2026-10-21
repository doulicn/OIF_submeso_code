%PLOT_FIG1 Manuscript Figure 1: model domains, summer NO3, surface PDFs, patch occurrence.
%   LaTeX label fig:downscale; published file Fig1.pdf.
%   (a) WOA23 JJA surface NO3 with the 12/4/1 km grid outlines
%   (b) NEPAC-4KM JJA surface NO3 around OSP, 1 km domain, release regions
%   (c-e) PDFs of Ro, S/f and w-<w> (summer 2010, 1/4/12 km)
%   (f-h) patch occurrence, June release at R1, 1/4/12 km
%   Ported from PACMED12_Process_marbl_8p6z.m (plot_domain_WOA23,
%   plot_domain_model_no3, plot_patch_occurency) and
%   calculate_roms_surface_diagnostic_period_pdfs.m.
%
%   The axis limits of (c-e) are those of the published panels, i.e. the
%   automatic limits of the original 800 x 250 px figure: tick-aligned,
%   except the upper limits of Ro and w, which end at the centre of the last
%   non-empty 1 km bin. The skewness labels are placed as in the original
%   script (lib/add_skew_text.m: where they cover the fewest curve points).
%
%   FI in (f-h) is the mean over the first two months of the daily
%   filamentation index P^2/(4*pi*A), with P the perimeter and A the area of
%   the patch (dFe > 2e-5 mmol m-3). This is the formula of the original code
%   and gives the published values 39.43, 17.23 and 6.53. The caption and
%   Section 2.2 define FI = P/sqrt(A); the means of that ratio are stored as
%   meanFI_Psqrt in data/patchmaps_occurrence.mat.
%   Input:  data/fig1_ab.mat, data/fig1_pdfs.mat, data/patchmaps_grid.mat,
%           data/patchmaps_occurrence.mat
%   Output: figures/Fig1.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
A  = load(fullfile(C.data_dir,'fig1_ab.mat'));
P  = load(fullfile(C.data_dir,'fig1_pdfs.mat'));
G  = load(fullfile(C.data_dir,'patchmaps_grid.mat'));
O  = load(fullfile(C.data_dir,'patchmaps_occurrence.mat'));

cmap_no3 = colormap_isleofdogs();
fs = 8;

fig = oif_figure('Color','w','Position',[50 50 780 800],'visible','off');

%% (a) WOA23 JJA surface NO3, nested domains
axA = axes('Position',[0.05 0.665 0.47 0.32]); hold(axA,'on');
m_proj('robinson','long',[100 300],'lat',[-50 70]);
[lo, la] = meshgrid(double(A.woa.lon), double(A.woa.lat));
m_pcolor(lo, la, double(A.woa.no3_jja)); shading interp; colormap(axA, cmap_no3);
m_coast('patch',[1 1 1]*0.7); caxis([0 20]);
m_grid('tickdir','in','fontsize',fs);
linecl = {'k','b','r'};                 % 12 km, 4 km, 1 km
for k = 1:3
    m_plot(double(A.outline(k).lon), double(A.outline(k).lat), linecl{k}, 'linestyle','-','LineWidth',1.5);
end
% corners of the 1 km domain in panel (a)
o1 = A.outline(3);
[xa, ya] = m_ll2xy(double(o1.lon), double(o1.lat));
text(0.02, 0.97, '(a)', 'Units','normalized','fontsize',fs+2,'VerticalAlignment','top');

%% (b) NEPAC-4KM JJA surface NO3, 1 km domain and release regions
axB = axes('Position',[0.555 0.665 0.33 0.32]); hold(axB,'on');
m_proj('robinson','long',[205 225],'lat',[45 60]);
m_pcolor(double(A.model.lon), double(A.model.lat), double(A.model.no3_jja)); shading interp
colormap(axB, cmap_no3); caxis([0 20]);
m_coast('patch',[1 1 1]*0.7);
m_grid('tickdir','in','fontsize',fs);
m_plot(double(o1.lon), double(o1.lat), 'r', 'LineStyle','-', 'LineWidth',1.5);
rl = A.region_lon_OIF; rt = A.region_lat_OIF;
m_plot(rl{1}, rt{1}, 'k', 'LineWidth', 1.5);
m_text(rl{1}(3), rt{1}(3), 'R1', 'verticalalignment','bottom','horizontalalignment','left','color','k','fontsize',10);
m_scatter(mean(rl{2}([1 3])), mean(rt{2}([1 3])), 40, 'b', '^', 'filled');
m_text(rl{2}(3), rt{2}(3), 'R2(OSP)', 'verticalalignment','bottom','horizontalalignment','left','color','b','fontsize',10);
m_scatter(mean(rl{3}([1 3])), mean(rt{3}([1 3])), 40, 'r', 'o', 'filled');
m_text(rl{3}(3), rt{3}(3), 'R3', 'verticalalignment','bottom','horizontalalignment','left','color','r','fontsize',10);
cb = colorbar(axB); cb.Position = [0.905 0.69 0.015 0.27]; cb.Ticks = 0:2:20;
cb.Label.String = 'NO_3^{-} (mmol m^{-3})'; cb.Label.FontSize = fs; cb.FontSize = fs;
[xb, yb] = m_ll2xy(double(o1.lon), double(o1.lat));
text(0.97, 0.97, '(b)', 'Units','normalized','fontsize',fs+2,'VerticalAlignment','top','HorizontalAlignment','right');

% dashed red arrows linking the 1 km domain in (a) to panel (b), as in the
% published figure: from the northernmost and the SW corner of the 1 km
% outline in (a) to its NW and SW corners in (b)
xn = (xb - min(xb))/(max(xb)-min(xb)); yn = (yb - min(yb))/(max(yb)-min(yb));
[~, inw] = min(xn - yn); [~, isw] = min(xn + yn);    % NW and SW corners
[~, inn] = max(ya);                                  % northernmost corner
from = [inn isw]; to = [inw isw];
for k = 1:2
    [x0, y0] = oif_ax2fig(axA, xa(from(k)), ya(from(k)));
    [x1, y1] = oif_ax2fig(axB, xb(to(k)), yb(to(k)));
    annotation(fig, 'arrow', [x0 x1], [y0 y1], 'Color','r','LineStyle','--','LineWidth',1, ...
        'HeadWidth',6,'HeadLength',6);
end

%% (c-e) PDFs
R = P.results;                          % 1: 12 km, 2: 4 km, 3: 1 km
baseColor2 = cbrewer('qual','Dark2',3);
col = {baseColor2(3,:), baseColor2(2,:), baseColor2(1,:)};   % 12 km purple, 4 km orange, 1 km green
plotOrder = [3 2 1];
lab = {'Ro = \zeta/f', 'S/f', 'w - <w> (m s^{-1})'};
ttl = {'Normalized Vorticity','Normalized Strain','Vertical Velocity'};
fld = {'vorticity','strain','w'};
xpos = [0.075 0.395 0.715]; letters = {'(c)','(d)','(e)'};
% limits and ticks of the published panels (see header); the upper Ro and w
% limits, 1.0656 and 5.204e-5 m/s, are the centres of the last non-empty 1 km bins
lastbin = @(f) double(max(R(3).([f 'Centers'])(R(3).([f 'Pdf']) > 0)));
xlims = {[-1 lastbin('vorticity')], [0 1.5], [-1e-4 lastbin('w')]};
ylims = {[1e-6 1e2], [1e-6 1e2], [1e-2 1e6]};
xtick = {-1:0.5:1, 0:0.5:1.5, (-10:5:5)*1e-5};
for ip = 1:3
    ax = axes('Position',[xpos(ip) 0.415 0.265 0.205]); hold(ax,'on');
    for k = plotOrder
        plot(R(k).([fld{ip} 'Centers']), R(k).([fld{ip} 'Pdf']), 'LineWidth', 1.8, 'Color', col{k});
    end
    grid on; box on; set(ax,'YScale','log','fontsize',fs); xlim(xlims{ip}); ylim(ylims{ip});
    set(ax,'XTick',xtick{ip},'YTick',10.^(-6:2:6));
    xlabel(lab{ip}); title(ttl{ip});
    if ip == 1; ylabel('PDF'); end
    if ip == 2
        legend({R(plotOrder).label}, 'Location','east','fontsize',fs);
    end
    % skewness of each pooled histogram, coloured like its line
    sk = zeros(1,3);
    for j = 1:3
        k = plotOrder(j);
        sk(j) = weighted_skewness(R(k).([fld{ip} 'Centers']), R(k).([fld{ip} 'Counts']));
    end
    add_skew_text(ax, sk, col(plotOrder), 'fontsize', fs+1);
    text(0.03, 0.03, letters{ip}, 'Units','normalized','fontsize',fs+2,'VerticalAlignment','bottom');
end

%% (f-h) patch occurrence, June release at R1
xpos = [0.045 0.34 0.635]; letters = {'(f)','(g)','(h)'};
for ires = 1:3
    ax = axes('Position',[xpos(ires) 0.035 0.28 0.31]);
    oif_occurrence_panel(ax, G.lon{ires}, G.lat{ires}, O.occ{1,ires}, ...
        G.region_lon_OIF{1}, G.region_lat_OIF{1}, O.meanFI_P2(1,ires), C.res_label{ires}, ires==1, 7);
    text(0.03, 0.04, letters{ires}, 'Units','normalized','fontsize',fs+2, ...
        'VerticalAlignment','bottom','BackgroundColor','w','Margin',1);
    if ires == 3
        cb = colorbar(ax); cb.Position = [0.935 0.065 0.015 0.25]; cb.FontSize = fs;
        cb.Label.String = 'Patch occurrence'; cb.Label.FontSize = fs+1;
    end
end

exportgraphics(fig, fullfile(C.fig_dir,'Fig1.png'), 'Resolution', 300);
exportgraphics(fig, fullfile(C.fig_dir,'Fig1.pdf'), 'ContentType','image','Resolution',300);
close(fig);
fprintf('saved Fig1\n');

function skew = weighted_skewness(centers, counts)
% skewness from a pooled histogram (calculate_roms_surface_diagnostic_period_pdfs.m)
centers = double(centers(:)); counts = double(counts(:));
N = sum(counts);
if N <= 0 || numel(centers) ~= numel(counts); skew = NaN; return; end
mu = sum(centers.*counts)/N;
m2 = sum(counts.*(centers-mu).^2)/N;
m3 = sum(counts.*(centers-mu).^3)/N;
if m2 <= 0; skew = NaN; else; skew = m3/m2^1.5; end
end
