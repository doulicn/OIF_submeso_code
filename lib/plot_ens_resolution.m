function [h, St] = plot_ens_resolution(ax, val, E, S, msize, errorbar_stat)
%PLOT_ENS_RESOLUTION Scatter of the 18 runs vs resolution + ensemble error bars.
%
%   [h, St] = plot_ens_resolution(ax, val, E, S, msize, errorbar_stat)
%   val : 18 x 1 values; E : data/ens_metrics.mat; S : oif_ens_style(E)
%   msize : scatter marker size (points^2); default S.msize
%   errorbar_stat : 'pooled' (default, as published) or 'subset': which runs
%       enter the red and blue error bars, see ens_resolution_stats
%   Runs are jittered by linspace(-0.18,0.18,n) around each resolution (a
%   single run is drawn at the resolution itself).
%   Error bars (see ens_resolution_stats): black = all runs at that
%   resolution (x), red = across release months (x+0.25), blue = across
%   release regions (x-0.25). h = [black red blue] errorbar handles, St =
%   the statistics.

if nargin < 5 || isempty(msize); msize = S.msize; end
if nargin < 6 || isempty(errorbar_stat); errorbar_stat = 'pooled'; end
hold(ax, 'on');
nres = max(E.res_id);
for ir = 1:nres
    ind = find(E.res_id == ir);
    if numel(ind) > 1
        jit = linspace(-0.18, 0.18, numel(ind));
    else
        jit = 0;
    end
    for k = 1:numel(ind)
        i = ind(k);
        if isnan(val(i)); continue; end    % reported by ens_resolution_stats
        scatter(ax, ir + jit(k), val(i), msize, S.marker{i}, 'MarkerFaceColor', S.color(i,:), ...
            'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
    end
end
switch validatestring(errorbar_stat, {'pooled', 'subset'})
    case 'pooled'    % red: release months, regions pooled; blue: regions, months pooled
        St = ens_resolution_stats(val, E.res_id, E.month_id, E.region_id);
    case 'subset'    % red: the R1 runs only; blue: the June runs only
        St = ens_resolution_stats(val, E.res_id, E.month_id, E.region_id, ...
            strcmp(E.region, 'R1'), strcmp(E.month, 'Jun'));
end
eb = S.errorbar;
h(1) = errorbar(ax, 1:nres,        St.mean_all,    St.std_all,    'ks-', 'MarkerFaceColor', 'k', eb{:});
h(2) = errorbar(ax, (1:nres)+0.25, St.mean_month,  St.std_month,  'rs-', 'MarkerFaceColor', 'r', eb{:});
h(3) = errorbar(ax, (1:nres)-0.25, St.mean_region, St.std_region, 'bs-', 'MarkerFaceColor', 'b', eb{:});
set(ax, 'XLim', [0.5 nres+0.5], 'XTick', 1:nres, 'XTickLabel', {'1KM','4KM','12KM'}, 'Box', 'on');
grid(ax, 'on');
end
