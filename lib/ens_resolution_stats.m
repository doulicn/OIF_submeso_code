function S = ens_resolution_stats(val, res_id, month_id, region_id, sel_month, sel_region)
%ENS_RESOLUTION_STATS Ensemble mean/std per resolution (Fig. 3a-c, Fig. S9a).
%
%   S = ens_resolution_stats(val, res_id, month_id, region_id)
%   S = ens_resolution_stats(val, res_id, month_id, region_id, sel_month, sel_region)
%
%   val       : case values (18 x 1)
%   res_id    : resolution index of each case (1 = 1 km, 2 = 4 km, 3 = 12 km)
%   month_id  : release-month group index of each case
%   region_id : release-region group index of each case
%   sel_month, sel_region : optional logical masks of the cases that enter
%               the per-month (red) and the per-region (blue) statistics;
%               default all cases (the published figures). With sel_month =
%               the R1 runs and sel_region = the June runs every group holds
%               a single run, which gives the R1-only and June-only
%               statistics that the captions describe (errorbar_stat =
%               'subset' in plot_fig3 and plot_figS9).
%
%   For each resolution ir (as in the original analysis code):
%     S.mean_all/std_all       : mean/std over all cases at that resolution
%     S.mean_month/std_month   : cases averaged within each release month
%                                first (pooling regions), then mean/std of
%                                those per-month values   (red error bars)
%     S.mean_region/std_region : cases averaged within each release region
%                                first (pooling months), then mean/std of
%                                those per-region values  (blue error bars)
%     S.n_all/n_month/n_region : number of (non-NaN) cases behind each value
%   std uses the N-1 normalisation. NaN values are ignored, with a warning.

val = val(:); res_id = res_id(:); month_id = month_id(:); region_id = region_id(:);
if nargin < 5 || isempty(sel_month);  sel_month  = true(size(val)); end
if nargin < 6 || isempty(sel_region); sel_region = true(size(val)); end
sel_month = logical(sel_month(:)); sel_region = logical(sel_region(:));
if any(isnan(val))
    warning('OIF:nanIgnored', 'ens_resolution_stats: NaN value(s) of case(s) %s ignored.', ...
        mat2str(find(isnan(val))'));
end
nres = max(res_id);
S.mean_all = nan(1,nres);    S.std_all = nan(1,nres);
S.mean_month = nan(1,nres);  S.std_month = nan(1,nres);
S.mean_region = nan(1,nres); S.std_region = nan(1,nres);
S.n_all = zeros(1,nres); S.n_month = zeros(1,nres); S.n_region = zeros(1,nres);
for ir = 1:nres
    ind = find(res_id == ir);
    if isempty(ind); continue; end
    S.mean_all(ir) = mean(val(ind), 'omitnan');
    S.std_all(ir)  = std(val(ind), 0, 'omitnan');
    S.n_all(ir)    = nnz(~isnan(val(ind)));
    [S.mean_month(ir),  S.std_month(ir),  S.n_month(ir)]  = group_stats(val, ind(sel_month(ind)),  month_id);
    [S.mean_region(ir), S.std_region(ir), S.n_region(ir)] = group_stats(val, ind(sel_region(ind)), region_id);
end
end

function [m, s, n] = group_stats(val, ind, gid)
% Mean and std of the group means of val(ind); groups gid(ind) in stable order.
m = NaN; s = NaN; n = nnz(~isnan(val(ind)));
if isempty(ind); return; end
g = unique(gid(ind), 'stable');
gv = nan(numel(g),1);
for k = 1:numel(g)
    gv(k) = mean(val(ind(gid(ind) == g(k))), 'omitnan');
end
m = mean(gv, 'omitnan');
s = std(gv, 0, 'omitnan');
end
