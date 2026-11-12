%PLOT_FIG2 Manuscript Figure 2: OIF response of the June-R1 release at 1, 4 and 12 km.
%   LaTeX label fig:line_cmp; published file fig2_lines.pdf.
%   (a) patch area; (b-d) patch-mean surface dFe, dNO3, dChl (thick), patch
%   max/min (thin) and 5-95th percentile (shading); (e,f) cumulative
%   in-patch POC export (100 m solid, 500 m dash-dot) and air-sea CO2 flux
%   anomalies (right axis in tons C).
%
%   Differences from the caption (the published panels are reproduced):
%   the caption says that (e,f) are integrated over the OSP-1KM domain, and
%   their labels read int_A, the notation of Table S1 for domain integrals;
%   the published curves are sums over the fertilized patch (dFe > 2e-5
%   mmol m-3 within that domain), as in the original analysis. After 60 days
%   the whole-domain integrals, which the text and Table S1 quote, are
%   14-25% (POC at 100 m, CO2) and 24-37% (POC at 500 m) larger. The 500 m
%   curves are dash-dotted (caption: dashed).
%
%   Option (set the variable in the workspace before running the script; the
%   default reproduces the published figure):
%     integral_area = 'patch'   (default) (e,f) summed over the patch
%                     'domain'  summed over the whole OSP-1KM domain (ts.dom);
%                               the y-labels then read int_domain, the
%                               y-limits follow the data and the output is
%                               figures/Fig2_domain.png/.pdf
%
%   Input:  data/ts_patch_timeseries.mat
%   Output: figures/Fig2.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~exist('integral_area', 'var'); integral_area = 'patch'; end
integral_area = validatestring(integral_area, {'patch', 'domain'});
T = load(fullfile(C.data_dir, 'ts_patch_timeseries.mat'));
runs = find(T.exp_id == 1);              % June R1 at 1/4/12 km
col = C.col_res; lbl = {'1KM','4KM','12KM'};
ndays = 90;                              % first 90 valid days (as in the original)
mk = {'Marker','s','MarkerSize',2,'MarkerEdgeColor','k'};
xt = linspace(datenum(2010,6,1), datenum(2010,8,1), 7);
xl = [xt(1)-10, xt(end)];
tonsC = C.mmolC_to_tC;                   % mmol C -> metric tons C

fig = oif_figure('Units','centimeters','Position',[2 2 18.6 12.7],'Color','w','Visible','off');
fs = 8;
W = 0.36; H = 0.235; X = [0.075 0.565]; Y = [0.725 0.425 0.105];
pos = @(r,c) [X(c) Y(r) W H];
ax = gobjects(6,1);

% ---- (a) patch area ----
ax(1) = axes('Position',pos(1,1)); hold on;
h = gobjects(3,1);
for k = 1:3
    i = runs(k); a = T.Fe_surf.area(:,i)*1e-6;
    iu = find(~isnan(a)); iu = iu(1:min(ndays,numel(iu)));
    h(k) = plot(T.date(iu), a(iu), '-', 'Color', col(k,:), 'LineWidth', 1.5, mk{:}, ...
        'MarkerIndices', 1:14:numel(iu), 'MarkerFaceColor', col(k,:));
end
ylabel('$\mathrm{patch\ area\ (km^2)}$','Interpreter','latex');
legend(h, lbl, 'Location','northwest','FontSize',fs-1);

% ---- (b-d) patch-mean anomalies ----
vs = {'Fe_surf','NO3_surf','CHL_surf'};
yl = {'$\mathrm{\Delta Fe\ (mmol\ m^{-3})}$', '$\mathrm{\Delta NO_3^-\ (mmol\ m^{-3})}$', '$\mathrm{\Delta CHL\ (mg\ m^{-3})}$'};
pp = [1 2; 2 1; 2 2];
for v = 1:3
    ax(v+1) = axes('Position',pos(pp(v,1),pp(v,2))); hold on;
    yline(0,'k--','LineWidth',1.2,'HandleVisibility','off');
    D = T.(vs{v});
    h = gobjects(3,1);
    for k = 1:3
        i = runs(k);
        s = D.stats(:,:,3,i); a = D.area(:,i);
        iu = find(~isnan(s(:,5))); iu = iu(1:min(ndays,numel(iu)));
        t = T.date(iu)';
        fill([t, fliplr(t)], [s(iu,1); flipud(s(iu,2))]', col(k,:), 'EdgeColor','none', 'FaceAlpha',0.1, 'HandleVisibility','off');
        plot(t, s(iu,4), '-', 'Color', col(k,:), 'LineWidth', 0.5, 'HandleVisibility','off');
        plot(t, s(iu,3), '-', 'Color', col(k,:), 'LineWidth', 0.5, 'HandleVisibility','off');
        h(k) = plot(t, s(iu,5)./a(iu), '-', 'Color', col(k,:), 'LineWidth', 1.5, mk{:}, ...
            'MarkerIndices', 1:14:numel(iu), 'MarkerFaceColor', col(k,:));
    end
    ylabel(yl{v},'Interpreter','latex');
    if v == 1; legend(h, lbl, 'Location','northeast','FontSize',fs-1); end
end

% ---- (e,f) cumulative POC export and CO2 uptake ----
vs = {'POC_FLUX_100m','CO2_FLUX_surf'};
nm = {'POC\ FLUX','CO_2\ FLUX'};
if strcmp(integral_area, 'domain'); sub = '{domain}'; else; sub = 'A'; end   % 'A' as published
for v = 1:2
    ax(4+v) = axes('Position',pos(3,v)); hold on;
    yyaxis left; set(gca,'YColor','k');
    h = gobjects(3,1); yv = [];          % yv: plotted values up to 08-01
    for k = 1:3
        i = runs(k);
        D = T.(vs{v});
        iu = find(~isnan(D.stats(:,1,1,i))); iu = iu(1:min(ndays,numel(iu)));
        y = cumsum(daily_anomaly(T, vs{v}, iu, i, integral_area));
        h(k) = plot(T.date(iu), y, '-', 'Color', col(k,:), 'LineWidth', 1.5, mk{:}, ...
            'MarkerIndices', 1:14:numel(iu), 'MarkerFaceColor', col(k,:));
        yv = [yv; y(T.date(iu) <= xl(2))]; %#ok<AGROW>
        if v == 1   % 500 m (same day selection as at 100 m, as in the original)
            y = cumsum(daily_anomaly(T, 'POC_FLUX_500m', iu, i, integral_area));
            plot(T.date(iu), y, '-.', 'Color', col(k,:), 'LineWidth', 1.5, 'HandleVisibility','off');
            yv = [yv; y(T.date(iu) <= xl(2))]; %#ok<AGROW>
        end
    end
    ylabel(['$\mathrm{\int_' sub '^T(\Delta ' nm{v} '),\ (mmol\ C)}$'],'Interpreter','latex','Color','k');
    if strcmp(integral_area, 'patch')
        % y-limits of the published panels, i.e. the automatic limits of the
        % original single-panel figures (the smaller axes of this layout
        % would get other automatic limits and ticks)
        yl_pub = {[-2 12]*1e12, [0 6]*1e12};
        yl2 = yl_pub{v};
    else
        % the domain sums exceed the published limits: range of the values
        % up to 08-01 (the curves continue outside XLim), rounded to a step
        % of 1, 2 or 5 x 10^k, with 20% room at the top for the depth labels
        dt = nice_step(max(yv) - min(yv));
        yl2 = [floor(min(yv)/dt), ceil(1.2*max(yv)/dt)]*dt;
    end
    ylim(yl2);
    yyaxis right; set(gca,'YColor','k'); ylim(yl2*tonsC);
    ylabel(['$\mathrm{\int_' sub '^T(\Delta ' nm{v} '),\ (Tons\ C)}$'],'Interpreter','latex','Color','k');
    yyaxis left;
    if v == 1
        legend(h, lbl, 'Location','northwest','FontSize',fs-1);
        text(datenum(2010,7,5), 0.80*yl2(2), '100m', 'FontSize', fs+2);   % starts on 5 July, as published
        text(datenum(2010,7,11), 0.27*yl2(2), '500m', 'FontSize', fs+2);
    end
end

letters = 'abcdef';
for k = 1:6
    set(ax(k), 'XTick', xt, 'XTickLabel', datestr(xt,'mm-dd'), 'XLim', xl, 'FontSize', fs, 'Box','on');
    grid(ax(k),'on');
    text(ax(k), 0.02, 0.12, ['(' letters(k) ')'], 'Units','normalized', 'FontSize', fs+2);
    if k >= 5; xlabel(ax(k), 'Date in  2010'); end
end

outname = 'Fig2';
if ~strcmp(integral_area, 'patch'); outname = [outname '_' integral_area]; end
exportgraphics(fig, fullfile(C.fig_dir,[outname '.png']), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir,[outname '.pdf']), 'ContentType','vector');
close(fig);
fprintf('%s written.\n', outname);

% =========================================================================
function d = nice_step(r)
% Smallest step of 1, 2 or 5 x 10^k that divides the range r into at most 6 parts.
p = 10^floor(log10(r/6));
m = [1 2 5 10];
d = p*m(find(r ./ (p*m) <= 6, 1));
end

function y = daily_anomaly(T, name, iu, i, integral_area)
% Daily OIF-control sum (value x m2) of series NAME on days IU of run I,
% over the patch or the whole domain. Missing days count as 0 in the
% cumulative sums (as in the original), with a warning.
if strcmp(integral_area, 'domain')
    y = T.dom.(name).sum(iu,3,i);
else
    y = T.(name).stats(iu,5,3,i);
end
if any(isnan(y))
    warning('OIF:nanAsZero', 'plot_fig2: %s, %s: %d NaN day(s) counted as 0 in the cumulative sum.', ...
        name, T.label{i}, nnz(isnan(y)));
    y(isnan(y)) = 0;
end
end
