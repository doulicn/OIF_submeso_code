%PLOT_FIGS2 Supporting Information Figure S2: summer-mean profiles at Ocean Station Papa.
%   LaTeX label fig:si_validation_vertical; published file fig_s2.pdf.
%   Summer-mean vertical profiles (0-200 m) of temperature, density, NO3, Fe,
%   chlorophyll and O2 at Ocean Station Papa: ROMS-BEC at 1/4/12/25 km
%   (2010) vs. in situ Station P, Argo and WOA23 (mean +- std).
%
%   Differences from the caption (the published panels are reproduced):
%   the caption describes all profiles as June-August means. The model
%   profiles are June-August 2010 means and the WOA23 profiles June-August
%   means of the monthly climatology, but the in situ and Argo profiles are
%   column 3 of their seasonal source files, which holds July-September
%   (months 7-9 in the Argo processing script; the in situ values are
%   consistent with July-September, not with June-August); they are stored
%   as O.insitu_jas* and O.argo_jas*. Shading: +- 1 standard deviation of the
%   in situ and Argo composites, and for WOA23 (magenta) the mean monthly
%   WOA23 standard deviation; the caption mentions neither WOA23 nor its
%   shading. Panel (b) shows potential density (sigma0, kg m-3).
%
%   Panel letters: in the published PDF they were added on top of the
%   exported figure, (a) and (b) in a margin above it; here they are drawn
%   last at the same positions, so the exported image includes that margin.
%   Input:  data/valid_model_papa.mat, data/valid_obs_papa.mat,
%           data/valid_woa23_papa.mat (built by prep/prep_validation.m)
%   Output: figures/FigS2.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
M = load(fullfile(C.data_dir,'valid_model_papa.mat'));
O = load(fullfile(C.data_dir,'valid_obs_papa.mat'));
W = load(fullfile(C.data_dir,'valid_woa23_papa.mat'));

col = cbrewer('qual','Dark2',4);
stpos=0.07; wdpos=0.18; high=0.13; highst=0.05; dwdpos=0.05; dhigh=0.046;
pos = {[stpos highst+(high+dhigh)*4 wdpos high],[stpos+wdpos+dwdpos highst+(high+dhigh)*4 wdpos high], ...
       [stpos highst+(high+dhigh)*3 wdpos high],[stpos+wdpos+dwdpos highst+(high+dhigh)*3 wdpos high], ...
       [stpos highst+(high+dhigh)*2 wdpos high],[stpos+wdpos+dwdpos highst+(high+dhigh)*2 wdpos high]};
P = struct( ...
 'var',  {'temp','rho','NO3','Fe','CHL','O2'}, ...
 'show', {'temp','rho','NO_3^-','Fe','CHL','O_2'}, ...
 'unit', {'^oC','kg m^{-3}','mmol\ m^{-3}','mmol\ m^{-3}','mg\ m^{-3}','mmol\ m^{-3}'}, ...
 'argo', {'temp','rho','NO3','','CHL','O2'}, ...
 'woa',  {'temp','rho','NO3','','','O2'});
letters = 'abcdef';
% panel letters: baseline-left positions in the normalized units of each
% panel (above the panel), as measured on the published PDF
lpos = [0.032 1.059; 0.010 1.059; 0.031 1.052; 0.039 1.052; 0.032 1.055; 0.010 1.055];
dep = M.station_depth;

% 39.6875 cm = 1500 px at 96 px per inch, the size of the original figure
fig = oif_figure('visible','off','Units','centimeters','Position',[2 2 39.6875 39.6875],'color','w');
for j = 1:6
    p = P(j);
    ax = subplot('position',pos{j}); hold(ax,'on');
    % in situ Station P July-September mean +- std
    m = O.insitu_jas.(p.var); s = O.insitu_jas_std.(p.var); z = O.insitu_jas_dep;
    fill([m-s; flipud(m+s)],[z; flipud(z)],[0 0 1],'FaceAlpha',0.3,'EdgeColor','none','HandleVisibility','off');
    plot(m,z,'b','LineWidth',1,'DisplayName','in situ OBS');
    % Argo July-September mean +- std
    if ~isempty(p.argo)
        m = O.argo_jas.(p.argo); s = O.argo_jas_std.(p.argo); z = O.argo_jas_dep; k = ~isnan(m);
        fill([m(k)-s(k); flipud(m(k)+s(k))],[z(k); flipud(z(k))],[1 0 0],'FaceAlpha',0.3,'EdgeColor','none','HandleVisibility','off');
        plot(m,z,'r','LineWidth',1,'DisplayName','Argo');
    end
    % WOA23 JJA mean +- mean monthly std
    if ~isempty(p.woa)
        m = W.jja.(p.woa); s = W.jja_std.(p.woa); z = W.dep.(p.woa); k = ~isnan(m);
        fill([m(k)-s(k); flipud(m(k)+s(k))],[z(k); flipud(z(k))],'m','FaceAlpha',0.3,'EdgeColor','none','HandleVisibility','off');
        plot(m,z,'color','m','LineWidth',1,'DisplayName','WOA23');
    end
    % models (JJA 2010), 12 markers evenly spaced over 0-200 m
    for i = 1:4
        x = M.prof_jja.(p.var){i};
        iv = find(isfinite(x(:)) & dep(:)>=-200 & dep(:)<=0);
        [~,imk] = min(abs(dep(iv)-linspace(-200,0,12)),[],1);
        mk = unique(iv(imk))';
        plot(x,dep,'color',col(i,:),'LineWidth',1.5,'Marker','o','MarkerIndices',mk, ...
            'MarkerSize',2,'MarkerEdgeColor','k','MarkerFaceColor','k','DisplayName',M.res_label{i});
    end
    axis tight; box on; grid on;
    if j==1; legend('location','best','interpreter','none'); end
    ylim([-200 0]);
    xlabel(['$\mathrm{',p.show,'\ (',p.unit,')}$'],'interpreter','latex');
    if any(j==[1 3 5]); ylabel('$\mathrm{Depth\ (m)}$','Interpreter','latex'); end
end
% panel letters last, in invisible axes on top of the panels ((a)-(f) lie
% above the panels, as in the published PDF)
for j = 1:6
    axl = axes(fig,'Position',pos{j},'Visible','off');
    text(axl,lpos(j,1),lpos(j,2),['(',letters(j),')'],'Units','normalized', ...
        'FontSize',14,'VerticalAlignment','baseline');
end
exportgraphics(fig,fullfile(C.fig_dir,'FigS2.png'),'Resolution',400);
exportgraphics(fig,fullfile(C.fig_dir,'FigS2.pdf'),'ContentType','vector');
close(fig);
disp('Fig. S2 written.')
