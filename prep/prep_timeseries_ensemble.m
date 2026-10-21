%PREP_TIMESERIES_ENSEMBLE Build the compact data files behind Figs. 2-4, S7, S8 and Table A1.
%
%   Reads (from C.roms_dir, the ROMS/ folder of the data root C.box_root,
%   environment variable OIF_DATA_ROOT; see oif_config.m):
%     <run>/Analysis/figures/<VAR>_time_series_at_locations_of_maximum_difference<LS>.mat
%        per-run daily patch statistics ("composite" structs; 365 days of 2010)
%        LS11 = patch mask (in-patch statistics), LS12 = whole OSP-1KM domain
%        ('_2em5_50' in these tags: patch threshold dFe > 2e-5 mmol m-3 and a
%        50 km out-of-patch zone, patch_define of PACMED12_Process_param_8p6z.m)
%     <1km June run>/Analysis/figures/Statistics_InOutPatch_*.xlsx
%        60-day summary tables (domain-integrated fluxes, 60-day patch area,
%        control-run PHYC)
%     <1km June run>/Analysis/figures/FilamentationIndex_Ensemble_by_resolution_first2months*.mat
%        daily filamentation index (first two release months) of all 18 runs
%     <1km June run>/Analysis/figures/VarianceDecomposition_*.mat, Correlation_*.mat
%        cached figure data of the original analysis (only used for checks)
%     <data root>/Iron/Boyd2005_Figure2_data_table.mat   (SERIES 2002 data)
%
%   Writes:
%     data/ts_patch_timeseries.mat  daily patch statistics, all 18 runs
%     data/ens_metrics.mat          per-run 60-day ensemble metrics, variance
%                                   partition and correlations (Figs. 3, 4, S8,
%                                   Table A1)
%     data/obs_series2002.mat       SERIES 2002 observations (Boyd et al. 2004/2005)
%
%   Analysis windows. The 60-day sums (int_patch_*, int_dom_*) and the 60-day
%   patch area start at the first day with a non-empty patch in the composite
%   used (patch area > 0) and cover 60 days. That is day 2 of the release
%   month for the patch composites of all runs and for the domain composites
%   of most runs, but day 3 for the domain composites of the 4 km May, July
%   and August runs; the xlsx tables of the original analysis use the same
%   windows (int_dom_* reproduces their values). The filamentation index
%   (fi_series, fi_mean) covers day 2 of the release month to the end of the
%   following month (60 days; 61 for the July runs).
%
%   Provenance: re-implements the ensemble analysis of the original analysis
%   script PACMED12_Process_marbl_8p6z.m (block
%   plot_horizontal_surface_int200m_daily_zoom_test_cmp_more, section
%   'plot_time_series of max, min, median, mean and 5-95 percentile ...',
%   icomb = 34) and checks the variance partition and the correlations
%   against the results cached by that script (E.check_vs_cache). The daily
%   composites, the xlsx tables and the filamentation-index cache are
%   intermediate products made from the ROMS output by the original analysis
%   code, which is not part of this package.
%
%   Re-runnable; only the data/ files are (over)written.

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~isfolder(C.box_root)
    error('OIF:noDataRoot', ['prep_timeseries_ensemble needs the data root, the folder that ' ...
        'contains ROMS/ and Iron/. Set the environment variable OIF_DATA_ROOT to that folder ' ...
        '(current value: ''%s''); see oif_config.m.'], C.box_root);
end
R = C.roms_dir;
LS11 = '_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50';  % patch mask
LS12 = '_patch_center_OSPnw5_domain_RMSpg15_2em5_50';       % whole-domain mask
figdir = @(run) fullfile(R, run, 'Analysis', 'figures');
ref_dir = figdir(C.oif{1,1});    % summary tables / caches live in the 1-km June R1 folder

% ---------------------------------------------------------------- runs ----
[nexp, nres] = size(C.oif);
nrun = nexp*nres;
run_name = cell(nrun,1); label = cell(nrun,1);
res_id = zeros(nrun,1); exp_id = zeros(nrun,1);
month_lbl = cell(nrun,1); region_lbl = cell(nrun,1); res_lbl = cell(nrun,1);
mon_abbr = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
i = 0;
for ie = 1:nexp                  % test order of the original analysis (icomb = 34)
    for ir = 1:nres
        i = i + 1;
        run_name{i} = C.oif{ie,ir};
        res_id(i) = ir; exp_id(i) = ie;
        res_lbl{i} = C.res_label{ir};
        month_lbl{i} = mon_abbr{C.exp_month(ie)};
        region_lbl{i} = sprintf('R%d', C.exp_region(ie));
        label{i} = [res_lbl{i} '_' month_lbl{i}];
        if C.exp_region(ie) > 1; label{i} = [label{i} '_' region_lbl{i}]; end
    end
end
% group indices in stable order of first appearance (Jun, May, Jul, Aug / R1, R2, R3)
[month_names, ~, month_id] = unique(month_lbl, 'stable');
[region_names, ~, region_id] = unique(region_lbl, 'stable');

% ------------------------------------------------ daily patch time series --
% series: {name, VAR, depth field, factor}; CO2_FLUX is stored per second in
% the composites -> x86400 to mmol m-2 d-1. POC_FLUX already mmol m-2 d-1.
series = {'Fe_surf',       'Fe',       'tmp_surf', 1
          'NO3_surf',      'NO3',      'tmp_surf', 1
          'CHL_surf',      'CHL',      'tmp_surf', 1
          'POC_FLUX_100m', 'POC_FLUX', 'tmp_100m', 1
          'POC_FLUX_500m', 'POC_FLUX', 'tmp_500m', 1
          'CO2_FLUX_surf', 'CO2_FLUX', 'tmp_surf', 86400};
dom_series = {'POC_FLUX_100m', 'POC_FLUX', 'tmp_100m', 1
              'POC_FLUX_500m', 'POC_FLUX', 'tmp_500m', 1
              'CO2_FLUX_surf', 'CO2_FLUX', 'tmp_surf', 86400
              'PHYC_surf',     'PHYC',     'tmp_surf', 1};
stat_cols = [2 3 4 5 7];
ts = struct();
ts.README = ['Daily in-patch statistics (patch mask, dFe > 2e-5 mmol m-3) of the 18 OIF runs. ' ...
    '<series>.stats(day, stat, k, run): stat = 1 p5, 2 p95, 3 max, 4 min, 5 area-weighted sum (value x m2); ' ...
    'k = 1 OIF, 2 control, 3 OIF-control. <series>.area(day, run) = patch area (m2). ' ...
    'CO2_FLUX in mmol m-2 d-1 (x86400 applied); POC_FLUX mmol m-2 d-1; Fe, NO3 mmol m-3; CHL mg m-3. ' ...
    'dom.<series>.sum(day,k,run): area-weighted sum over the whole OSP-1KM analysis domain (LS12 mask).'];
ts.date = datenum(2010,1,1) + (0:364)';   % composites hold 2010 day-of-year rows (dates NaN outside the run)
ts.stat_names = {'p5','p95','max','min','area_sum'};
ts.run = run_name; ts.label = label; ts.res_id = res_id; ts.exp_id = exp_id;
ts.series = series(:,1)';
for is = 1:size(series,1)
    ts.(series{is,1}).stats = nan(365, numel(stat_cols), 3, nrun);
    ts.(series{is,1}).area  = nan(365, nrun);
end
for is = 1:size(dom_series,1)
    ts.dom.(dom_series{is,1}).sum  = nan(365, 3, nrun);
    ts.dom.(dom_series{is,1}).area = nan(365, nrun);
end

cache = struct();
for i = 1:nrun
    for is = 1:size(series,1)
        [nm, vname, fld, fac] = series{is,:};
        key = [vname '_LS11'];
        if ~isfield(cache, key) || ~strcmp(cache.([key '_run']), run_name{i})
            f = fullfile(figdir(run_name{i}), [vname '_time_series_at_locations_of_maximum_difference' LS11 '.mat']);
            s = load(f, 'composite'); cache.(key) = s.composite; cache.([key '_run']) = run_name{i};
        end
        cp = cache.(key).(fld);
        d = cp.time_series_date(:);
        ok = ~isnan(d); assert(isequal(ts.date(ok), d(ok)), 'date mismatch');
        ts.(nm).stats(:,:,:,i) = cp.data_stats_OIF(:, stat_cols, :) * fac;
        ts.(nm).area(:,i) = cp.patch_area_in_ts(:);
    end
    for is = 1:size(dom_series,1)
        [nm, vname, fld, fac] = dom_series{is,:};
        f = fullfile(figdir(run_name{i}), [vname '_time_series_at_locations_of_maximum_difference' LS12 '.mat']);
        s = load(f, 'composite'); cp = s.composite.(fld);
        ts.dom.(nm).sum(:,:,i) = squeeze(cp.data_stats_OIF(:, 7, :)) * fac;
        ts.dom.(nm).area(:,i)  = cp.patch_area_in_ts(:);
    end
    fprintf('read composites %2d/%d %s\n', i, nrun, run_name{i});
end
save(fullfile(C.data_dir, 'ts_patch_timeseries.mat'), '-struct', 'ts', '-v7');

% ------------------------------------------------ 60-day ensemble metrics --
E = struct();
E.README = ['Per-run 60-day OIF metrics (18 runs, order = rows of C.oif x 1/4/12 km). ' ...
    'int_patch_*: 60-day sum of the daily in-patch area-weighted OIF-control sum (patch mask, LS11 composites; Figs. 2e,f, 3c, S8a). ' ...
    'int_dom_*: same over the whole OSP-1KM domain (LS12 composites); equal to the xls_* values. ' ...
    'int_dom_* / xls_* (xls_*: values of the 60-day summary tables Statistics_InOutPatch_*.xlsx) are used for Figs. 3d, 4, S8b-d and Table A1. ' ...
    'Windows: 60 days from the first day with a non-empty patch in each composite (day 2 of the release month; day 3 for the LS12 composites of 4KM_May, 4KM_Jul and 4KM_Aug); ' ...
    'fi_*: day 2 of the release month to the end of the following month. ' ...
    'Figure numbers as in the compiled manuscript.'];
E.run = run_name; E.label = label; E.res_id = res_id; E.exp_id = exp_id;
E.month = month_lbl; E.region = region_lbl; E.res = res_lbl;
E.month_id = month_id; E.region_id = region_id;
E.month_names = month_names; E.region_names = region_names;

% 60-day window starts at the first day with a non-empty patch
first_day = @(a) find(~isnan(a) & a > 0, 1);
win60 = @(a) first_day(a):min(numel(a), first_day(a)+59);
E.patch_area_60 = nan(nrun,1);          % km2, Fe composite, surface patch
E.int_patch_CO2 = nan(nrun,1);  E.int_patch_POC100 = nan(nrun,1); E.int_patch_POC500 = nan(nrun,1);
E.int_dom_CO2   = nan(nrun,1);  E.int_dom_POC100   = nan(nrun,1); E.int_dom_POC500   = nan(nrun,1);
for i = 1:nrun
    a = ts.Fe_surf.area(:,i);
    E.patch_area_60(i) = mean(a(win60(a))*1e-6, 'omitnan');
    nm = {'CO2_FLUX_surf','POC_FLUX_100m','POC_FLUX_500m'}; out = {'CO2','POC100','POC500'};
    for k = 1:3
        a = ts.(nm{k}).area(:,i);
        E.(['int_patch_' out{k}])(i) = sum(ts.(nm{k}).stats(win60(a),5,3,i), 'omitnan');
        a = ts.dom.(nm{k}).area(:,i);   % domain composites carry the patch area too
        E.(['int_dom_' out{k}])(i) = sum(ts.dom.(nm{k}).sum(win60(a),3,i), 'omitnan');
    end
end
E.units.patch_area_60 = 'km2'; E.units.int = 'mmol C (60-day sum of mmol d-1)';

% ---- filamentation index (daily, first two release months) ----
fi_file = fullfile(ref_dir, ['FilamentationIndex_Ensemble_by_resolution_first2months' ...
    '96   68   72  105   79   73  106   80   74  107   81   75  110  112  108  111  113  109.mat']);
fi_cache = load(fi_file);
E.fi_series = fi_cache.filamentation_index_all(:);
E.fi_time = fi_cache.filamentation_time_all(:);
E.fi_mean = cellfun(@(x) mean(x, 'omitnan'), E.fi_series);

% ---- 60-day summary tables ----
xls_dom   = fullfile(ref_dir, 'Statistics_InOutPatch_patch_center_OSPnw5_domain_RMSpg15_2em5_50.xlsx');
xls_patch = fullfile(ref_dir, 'Statistics_InOutPatch_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50.xlsx');
E.xls_CO2      = xls_get(xls_dom, 'Difference', 'CO2_FLUX', '', 'Spatiotemporal integration in', label, 'first');
E.xls_POC      = xls_get(xls_dom, 'Difference', 'POC_FLUX', '', 'Spatiotemporal integration in', label, 'first');
E.xls_POC100   = xls_get(xls_dom, 'Difference', 'POC_FLUX', 'tmp_100m', 'Spatiotemporal integration in', label, 'mean');
E.xls_POC500   = xls_get(xls_dom, 'Difference', 'POC_FLUX', 'tmp_500m', 'Spatiotemporal integration in', label, 'mean');
E.xls_CO2_patchfile = xls_get(xls_patch, 'Difference', 'CO2_FLUX', '', 'Spatiotemporal integration in', label, 'first');
E.xls_area_CO2 = xls_get(xls_patch, 'Difference', 'CO2_FLUX', '', 'Patch area in', label, 'first') * 1e-6;  % km2
E.xls_area_POC = xls_get(xls_patch, 'Difference', 'POC_FLUX', '', 'Patch area in', label, 'first') * 1e-6;
E.xls_area_all = xls_get(xls_patch, 'Difference', '', '', 'Patch area in', label, 'mean') * 1e-6;
E.xls_ctrlPHYC_wavg = xls_get(xls_patch, 'Control run', 'PHYC', '', 'Patch-area weighted average in', label, 'first');
E.xls_ctrlPHYC_int  = xls_get(xls_patch, 'Control run', 'PHYC', '', 'Spatiotemporal integration in', label, 'first');
E.units.xls = 'fluxes: mmol C (60-day, whole domain); area: km2; PHYC wavg: mmol m-3; PHYC int: as in table';

% ---- variance partition (Fig. 3d, Fig. S8b) ----
% metrics as in the original analysis: FI (daily cache), patch area (patch
% table, mean of all rows), CO2 and POC(100 m) from the domain table.
vm = {'FI', E.fi_mean; 'PatchArea', E.xls_area_all; 'CO2_FLUX', E.xls_CO2; ...
      'POC_FLUX_100m', E.xls_POC100; 'POC_FLUX_500m', E.xls_POC500};
selR1 = strcmp(region_lbl, 'R1'); selJun = strcmp(month_lbl, 'Jun');
V = struct('metric', {vm(:,1)'}, 'R1_names', {{'Time','Res','Int'}}, 'June_names', {{'Reg','Res','Int'}});
V.pct_R1 = nan(size(vm,1),3); V.pct_June = nan(size(vm,1),3);
for k = 1:size(vm,1)
    v = vm{k,2};
    V.pct_R1(k,:)   = variance_two_way(v(selR1),  month_lbl(selR1),   res_lbl(selR1));
    V.pct_June(k,:) = variance_two_way(v(selJun), region_lbl(selJun), res_lbl(selJun));
end
% same partition applied to the patch-mask integrals (for reference only)
V.pct_R1_patchCO2   = variance_two_way(E.int_patch_CO2(selR1),  month_lbl(selR1),   res_lbl(selR1));
V.pct_June_patchCO2 = variance_two_way(E.int_patch_CO2(selJun), region_lbl(selJun), res_lbl(selJun));
V.pct_R1_patchPOC100   = variance_two_way(E.int_patch_POC100(selR1),  month_lbl(selR1),   res_lbl(selR1));
V.pct_June_patchPOC100 = variance_two_way(E.int_patch_POC100(selJun), region_lbl(selJun), res_lbl(selJun));
E.var = V;

% ---- correlations (Fig. 4, Fig. S8c,d) ----
cp = {'dCO2_FLUX_int_vs_PatchArea',    E.xls_area_CO2,      E.xls_CO2
      'dCO2_FLUX_int_vs_ctrlPHYC_wavg', E.xls_ctrlPHYC_wavg, E.xls_CO2
      'dCO2_FLUX_int_vs_ctrlPHYC_int',  E.xls_ctrlPHYC_int,  E.xls_CO2
      'dPOC_FLUX_int_vs_PatchArea',    E.xls_area_POC,      E.xls_POC
      'dPOC_FLUX_int_vs_ctrlPHYC_wavg', E.xls_ctrlPHYC_wavg, E.xls_POC
      'dPOC_FLUX_int_vs_ctrlPHYC_int',  E.xls_ctrlPHYC_int,  E.xls_POC};
for k = 1:size(cp,1)
    x = cp{k,2}; y = cp{k,3}; ok = ~isnan(x) & ~isnan(y);
    pf = polyfit(x(ok), y(ok), 1);
    [Rm, Pm] = corrcoef(x(ok), y(ok));
    E.corr.(cp{k,1}) = struct('x', x, 'y', y, 'fit_coef', pf, 'R', Rm(1,2), 'P', Pm(1,2));
end

% ---- checks against the cached figure data of the original analysis ----
chk = struct(); tol = 1e-6;
st = load(fullfile(ref_dir, ['VarianceDecomposition_stacked_FI_PatchArea_CO2_FLUX' LS11 '.mat']));
chk.var_stacked_R1   = max(abs(st.pct_R1_Time_Res_Int(:)  - reshape(V.pct_R1(1:3,:),[],1)));
chk.var_stacked_June = max(abs(st.pct_June_Reg_Res_Int(:) - reshape(V.pct_June(1:3,:),[],1)));
vc = {'FilamentationIndex', 1; 'PatchArea', 2; 'CO2_FLUX', 3; 'POC_FLUX_100m', 4; 'POC_FLUX_500m', 5};
for k = 1:size(vc,1)
    s = load(fullfile(ref_dir, ['VarianceDecomposition_' vc{k,1} LS11 '.mat']));
    chk.(['var_' vc{k,1}]) = max(abs([s.pct_R1.Time s.pct_R1.Res s.pct_R1.Int s.pct_June.Reg s.pct_June.Res s.pct_June.Int] ...
        - [V.pct_R1(vc{k,2},:) V.pct_June(vc{k,2},:)]));
end
for k = 1:size(cp,1)
    s = load(fullfile(ref_dir, ['Correlation_' cp{k,1} LS11 '.mat']));
    c = E.corr.(cp{k,1});
    chk.(['corr_' cp{k,1}]) = [abs(s.R - c.R), abs(s.P - c.P), max(abs(s.x(:)-c.x(:))./abs(s.x(:))), max(abs(s.y(:)-c.y(:))./abs(s.y(:)))];
end
E.check_vs_cache = chk;
fprintf('\nChecks vs cached analysis output (max abs diff; corr: dR dP rel_dx rel_dy):\n'); disp(chk);
flds = fieldnames(chk);
for k = 1:numel(flds)
    if any(chk.(flds{k}) > tol); warning('prep:check', 'check %s exceeds tolerance', flds{k}); end
end

fprintf('\n%-12s %10s %10s %10s %10s %10s %8s\n', 'run', 'area60', 'CO2patch', 'CO2dom', 'CO2xls', 'POC100p', 'FI');
for i = 1:nrun
    fprintf('%-12s %10.0f %10.3g %10.3g %10.3g %10.3g %8.2f\n', label{i}, E.patch_area_60(i), ...
        E.int_patch_CO2(i), E.int_dom_CO2(i), E.xls_CO2(i), E.int_patch_POC100(i), E.fi_mean(i));
end
save(fullfile(C.data_dir, 'ens_metrics.mat'), '-struct', 'E', '-v7');

% ------------------------------------------------ SERIES 2002 observations --
b = load(fullfile(C.box_root, 'Iron', 'Boyd2005_Figure2_data_table.mat'), 'Boyd');
O = struct();
O.README = ['SERIES 2002 in-patch minus out-patch time series digitised from Boyd et al. (2005, Fig. 2); ' ...
    'time in datenum (2002 dates mapped onto 2010); plotted with time_offset (days) so that the ' ...
    'SERIES release aligns with the June-2010 model release.'];
O.time_offset = -29;
map = {'Fe','Fe'; 'NO3','NO3'; 'CHL','Chl'; 'POC_FLUX_100m','POCflux_100m'};
for k = 1:size(map,1)
    O.(map{k,1}) = struct('time', b.Boyd.(map{k,2}).time(:), 'data', b.Boyd.(map{k,2}).data(:), 'source_name', map{k,2});
end
save(fullfile(C.data_dir, 'obs_series2002.mat'), '-struct', 'O', '-v7');
fprintf('done.\n');

% =========================================================================
function v = xls_get(file, sheet, var, depth, col, labels, mode)
%XLS_GET Value per run label from a 60-day summary table.
%   var/depth '' = no filter; mode 'first' = first matching row (as used for
%   the correlations), 'mean' = mean over matching rows (variance partition).
raw = readcell(file, 'Sheet', sheet);
hdr = raw(1,:); body = raw(2:end,:);
cvar = find(strcmpi(hdr, 'Variable'), 1); ct = find(strcmpi(hdr, 'Test'), 1);
cdep = find(strcmpi(hdr, 'Depth'), 1);    cm = find(strcmpi(hdr, col), 1);
assert(~isempty(cm), 'column %s not found in %s', col, file);
keep = true(size(body,1),1);
if ~isempty(var);   keep = keep & strcmp(body(:,cvar), var); end
if ~isempty(depth); keep = keep & strcmp(body(:,cdep), depth); end
v = nan(numel(labels),1);
for i = 1:numel(labels)
    r = find(keep & strcmp(body(:,ct), labels{i}));
    if isempty(r)
        error('OIF:missingInput', 'xls_get: no row for run %s (Variable ''%s'', Depth ''%s'') in sheet ''%s'' of %s.', ...
            labels{i}, var, depth, sheet, file);
    end
    x = nan(numel(r),1);
    for k = 1:numel(r)
        c = body{r(k), cm};
        if isnumeric(c) && ~isempty(c) && ~any(ismissing(c)); x(k) = c; end
    end
    if strcmp(mode, 'first'); v(i) = x(1); else; v(i) = mean(x, 'omitnan'); end
end
end
