%PLOT_FIGS1 Supporting Information Figure S1: seasonal cycles at Ocean Station Papa in 2010.
%   LaTeX label fig:si_validation_monthly; published file fig_s1.pdf.
%   Seasonal cycle of upper-30 m temperature, density, NO3, Fe, chlorophyll
%   and MLD at Ocean Station Papa in 2010: ROMS-BEC at 1/4/12/25 km vs. in situ
%   Station P, Argo, WOA23 and MODIS.
%
%   Differences from the caption (the published panels are reproduced):
%   panel (b) shows potential density (sigma0, kg m-3), not salinity. The
%   legends use other names than the caption: 'Argo CLM', 'MODIS CLM' and
%   'in situ OBS CLM' in (a) / 'Obs Papa CLM' in (e) are the caption's
%   Argo_CLM, MODIS_CLM and Obs_Papa_CLM (monthly climatologies, lines);
%   'Argo', 'MODIS' and 'in situ OBS' / 'Obs Papa' are Argo_2010, MODIS_2010
%   and Obs_Papa_2010 (monthly values, triangles; the records cover in situ
%   1985-2019, Argo 2003-2024 and MODIS 2003-2022, and only 2010 lies inside
%   the axes).
%
%   Model series (a-e): dz-weighted means over the model levels above 30 m,
%   low-pass filtered over edata_freq*30 samples as in the original code.
%   With station output every 0.5, 1, 0.6 and 24 h this is 30, 60, 36 and 30
%   days at 1, 4, 12 and 25 km (M.smooth_days); the caption does not mention
%   the smoothing. prep/prep_validation.m with uniform_30day_window = true
%   uses 30 days for every run instead, which changes the figure (e.g. the
%   4 km chlorophyll maximum rises from 0.53 to 0.65 mg m-3).
%   MLD (f): first depth where sigma0 exceeds its value at 10 m by more than
%   0.03 kg m-3, for the model (monthly means) and the WOA23 monthly profiles
%   (prep/prep_validation.m). The Argo values are the MLD2 of the precomputed
%   Argo files, which do not record the criterion. Of the two versions of the
%   Argo processing script (argo_plot_v2.m, not part of this package), one
%   takes the first depth where sigma0 exceeds its value at the shallowest
%   valid level by more than 0.1 kg m-3, the other uses the criterion above.
%   The Argo standard deviations stored in these files are consistent only
%   with the second one, which ignores missing values.
%
%   Panel letters: the letters of the published PDF were added on top of the
%   exported figure; here they are drawn last, above the legends, at the same
%   positions.
%   Input:  data/valid_model_papa.mat, data/valid_obs_papa.mat,
%           data/valid_woa23_papa.mat (built by prep/prep_validation.m)
%   Output: figures/FigS1.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
M = load(fullfile(C.data_dir,'valid_model_papa.mat'));
O = load(fullfile(C.data_dir,'valid_obs_papa.mat'));
W = load(fullfile(C.data_dir,'valid_woa23_papa.mat'));

col = cbrewer('qual','Dark2',4);
yr  = 2010;
time_clm = linspace(datenum(yr,1,15),datenum(yr,12,15),12)';
% x-axis range: full sample time of the last run plotted (25 km), as in the original
time_ax = M.time{4};

% panel layout (sbpos23 of the original parameter file, top three rows)
stpos=0.07; wdpos=0.18; high=0.13; highst=0.05; dwdpos=0.05; dhigh=0.046;
pos = {[stpos highst+(high+dhigh)*4 wdpos high],[stpos+wdpos+dwdpos highst+(high+dhigh)*4 wdpos high], ...
       [stpos highst+(high+dhigh)*3 wdpos high],[stpos+wdpos+dwdpos highst+(high+dhigh)*3 wdpos high], ...
       [stpos highst+(high+dhigh)*2 wdpos high],[stpos+wdpos+dwdpos highst+(high+dhigh)*2 wdpos high]};

% panel definitions: model var, title, units, ylim, in situ name, argo name, woa name
P = struct( ...
 'var',  {'temp','rho','NO3','Fe','CHL','MLD2'}, ...
 'show', {'temp','rho','NO_3^-','Fe','CHL','MLD'}, ...
 'unit', {'^oC','kg m^{-3}','mmol\ m^{-3}','mmol\ m^{-3}','mg\ m^{-3}','m'}, ...
 'ylim', {[0 15],[23 27],[5 20],[0 2]*1e-4,[0 2],[-200 0]}, ...
 'obs',  {'temp','rho','no3','fe','chl',''}, ...
 'argo', {'temp','rho','NO3','','CHL','MLD2'}, ...
 'woa',  {'temp','rho','NO3','','','MLD2'});
letters = 'abcdef';
% panel letters: baseline-left positions in the normalized units of each
% panel, as measured on the published PDF
lpos = [0.039 0.883; 0.027 0.883; 0.038 0.880; 0.027 0.880; 0.039 0.873; 0.027 0.873];

% 39.6875 cm = 1500 px at 96 px per inch, the size of the original figure
fig = oif_figure('visible','off','Units','centimeters','Position',[2 2 39.6875 39.6875],'color','w');
for j = 1:6
    p = P(j);
    ax = subplot('position',pos{j}); hold(ax,'on');
    % legend entries, collected in plotting order
    hl = gobjects(0);  %#ok<*SAGROW>
    % as published, the legends call the in situ data 'in situ OBS' in (a)
    % and 'Obs Papa' in (e)
    if strcmp(p.var,'CHL'); obs_name = 'Obs Papa'; else; obs_name = 'in situ OBS'; end
    % ---- models ----
    for i = 1:4
        if strcmp(p.var,'MLD2')
            t = M.mld2_month_time{i}; y = M.mld2_month{i};
        else
            t = M.time{i}; y = double(M.ts30s.(p.var){i});
        end
        mk = month_marker_index(t);
        hl(end+1) = plot(t,y,'color',col(i,:),'LineWidth',1.5,'Marker','o','MarkerIndices',mk, ...
            'MarkerSize',2,'MarkerEdgeColor','k','MarkerFaceColor','k','DisplayName',M.res_label{i});
    end
    % ---- climatologies ----
    if ~isempty(p.woa)
        if strcmp(p.woa,'MLD2')
            ym = W.mld2; es = nan(12,1);
        else
            ym = W.upper30.(p.woa); es = W.upper30_std.(p.woa);
        end
        % opaque markers as in the published figure (the original code also set a
        % marker transparency through an undocumented property, which does not
        % reach the exported figure)
        hl(end+1) = plot(time_clm,ym,'o-','Color','m','LineWidth',1.5,'MarkerSize',5,'MarkerFaceColor','m','DisplayName','WOA23');
        if any(isfinite(es))
            fill([time_clm; flipud(time_clm)],[ym+es; flipud(ym-es)],'m','EdgeColor','none','FaceAlpha',0.1,'HandleVisibility','off');
        end
    end
    if ~isempty(p.argo)
        y = O.argo_clm.(p.argo); e = O.argo_clm_std.(p.argo);
        hl(end+1) = plot(time_clm,y,'ro-','LineWidth',1,'MarkerSize',5,'DisplayName','Argo CLM');
        fill([time_clm; flipud(time_clm)],[y+e; flipud(y-e)],'r','EdgeColor','none','FaceAlpha',0.1,'HandleVisibility','off');
    end
    if ~isempty(p.obs)
        y = O.insitu_clm.(p.obs); e = O.insitu_clm_std.(p.obs);
        seg = segments(~isnan(time_clm) & ~isnan(y) & ~isnan(e));
        for s = 1:numel(seg)
            k = seg{s};
            fill([time_clm(k); flipud(time_clm(k))],[y(k)+e(k); flipud(y(k)-e(k))],'b','EdgeColor','none','FaceAlpha',0.1,'HandleVisibility','off');
            if s==1
                hl(end+1) = plot(time_clm(k),y(k),'bo-','LineWidth',1,'MarkerSize',5,'DisplayName',[obs_name,' CLM']);
            else
                plot(time_clm(k),y(k),'bo-','LineWidth',1,'MarkerSize',5,'HandleVisibility','off');
            end
        end
    end
    if strcmp(p.var,'CHL')
        y = O.modis_clm(:); e = O.modis_clm_std(:); ok = ~isnan(y);
        hl(end+1) = plot(time_clm,y,'go-','LineWidth',1,'MarkerSize',5,'DisplayName','MODIS CLM');
        fill([time_clm(ok); flipud(time_clm(ok))],[y(ok)+e(ok); flipud(y(ok)-e(ok))],'g','EdgeColor','none','FaceAlpha',0.1,'HandleVisibility','off');
    end
    % ---- monthly records (all years; only 2010 is inside the axis range) ----
    if ~isempty(p.argo)
        x = O.argo_mon_time; y = O.argo_mon.(p.argo); e = O.argo_mon_std.(p.argo);
        ok = ~isnan(x) & ~isnan(y) & ~isnan(e);
        if any(ok)
            hl(end+1) = scatter(x(ok),y(ok),80,'r^','filled','DisplayName','Argo');
        end
    end
    if ~isempty(p.obs)
        hl(end+1) = scatter(O.insitu_mon_time,O.insitu_mon.(p.obs),80,'b^','filled','DisplayName',obs_name);
    end
    if strcmp(p.var,'CHL')
        hl(end+1) = scatter(O.modis_mon_time,O.modis_mon,80,'g^','filled','DisplayName','MODIS');
    end
    % legends in (a) and (e), from the handles collected above
    if j==1 || strcmp(p.var,'CHL')
        legend(hl,get(hl,'DisplayName'),'location','best','interpreter','none','NumColumns',2);
    end
    title(['$\mathrm{',p.show,'}$'],'interpreter','latex');
    xlim(time_ax([1 end])); ylim(p.ylim);
    % seven evenly spaced ticks labelled with their month, as in the original
    xt = linspace(time_ax(1),time_ax(end),7);
    set(gca,'xtick',xt,'xticklabel',datestr(xt,'mmm'));
    if j==5; xlabel(sprintf('Time in %d',yr)); end
    ylabel(['$\mathrm{',p.show,'\ (',p.unit,')}$'],'Interpreter','latex');
    grid on; box on;
end
% panel letters last, in invisible axes on top of the panels, so that they lie
% above the legends (the legend of (e) covers the position of its letter)
for j = 1:6
    axl = axes(fig,'Position',pos{j},'Visible','off');
    text(axl,lpos(j,1),lpos(j,2),['(',letters(j),')'],'Units','normalized', ...
        'FontSize',14,'VerticalAlignment','baseline');
end
exportgraphics(fig,fullfile(C.fig_dir,'FigS1.png'),'Resolution',400);
exportgraphics(fig,fullfile(C.fig_dir,'FigS1.pdf'),'ContentType','vector');
close(fig);
disp('Fig. S1 written.')

% -----------------------------------------------------------------------------
function mk = month_marker_index(t)
% one marker per calendar month: the sample closest to the 15th
tv = datevec(t(:)); [~,~,g] = unique(tv(:,1)*100+tv(:,2));
mk = accumarray(g,(1:numel(t))',[],@(k) k(find(abs(tv(k,3)-15)==min(abs(tv(k,3)-15)),1)));
mk = mk(:)';
end

function seg = segments(valid)
% contiguous runs of true values (replaces bwconncomp of the original)
valid = valid(:); d = diff([false; valid; false]);
st = find(d==1); en = find(d==-1)-1;
seg = arrayfun(@(a,b) (a:b)',st,en,'UniformOutput',false);
end
