%PREP_BUDGETS_PROFILES_COARSEGRAIN  Build the compact data files for Fig. 5 and Figs. S9-S12.
%
%   Reads intermediate products in C.roms_dir/<run>/Analysis/figures/ (ROMS/
%   folder of the data root C.box_root, environment variable OIF_DATA_ROOT;
%   see oif_config.m) and writes
%     data/budget_ensemble.mat        (Fig. 5, Fig. S9)
%     data/profile_Fe_DIC.mat         (Fig. S10)
%     data/coarsegrain_hovmoller.mat  (Fig. S11, Fig. S12)
%
%   Provenance: re-implements blocks of the original analysis scripts
%   PACMED12_Process_budget.m (flags OIF_budgets_times_series_cmp_more, icomb
%   31: budgets; plot_buoy_flux_spectrum_hovmoller_v1: coarse-graining panels)
%   and PACMED12_Process_marbl_8p6z.m (section plot_variables_profile_cmp_more,
%   icomb 22: profiles). The inputs are intermediate products made from the
%   ROMS output by code that is not part of this package: the daily budget
%   composites (*_time_series_at_locations_of_maximum_difference*.mat), the
%   domain-mean profiles, the MLD and Zeu caches (original analysis code) and
%   the coarse-grained flux files hovmoller_flux_depth_t_within_papa_mask_*
%   _avg_v4.nc (Python coarse-graining scripts spectrum_eke_*_flux_output_
%   monthly.py). Re-runnable.

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~isfolder(C.box_root)
    error('OIF:noDataRoot', ['prep_budgets_profiles_coarsegrain needs the data root, the folder ' ...
        'that contains ROMS/. Set the environment variable OIF_DATA_ROOT to that folder ' ...
        '(current value: ''%s''); see oif_config.m.'], C.box_root);
end
figdir = @(runname) fullfile(C.roms_dir, runname, 'Analysis', 'figures');
% file tag of the whole-domain caches (= LS12 of prep_timeseries_ensemble.m;
% '_2em5_50': patch threshold 2e-5 mmol m-3, 50 km out-of-patch zone)
LS12 = '_patch_center_OSPnw5_domain_RMSpg15_2em5_50';
yearnum = 2010;
date_yearly = datenum(yearnum,1,1):datenum(yearnum+1,1,1)-1;

%% ======================= 1. Fe and DIC budgets ==========================
% Ensemble order of icomb 31 in the original script:
% 1KM May,Jun,Jul,Aug | 4KM May..Aug | 12KM May..Aug | R2 1/4/12 | R3 1/4/12
rows = [2 1 3 4];                 % C.oif rows for May, Jun, Jul, Aug (R1)
run_name = {}; run_label = {}; run_res = []; run_row = [];
for ires = 1:3
    for r = rows
        run_name{end+1} = C.oif{r,ires}; run_res(end+1) = ires; run_row(end+1) = r; %#ok<*SAGROW>
    end
end
for r = [5 6]
    for ires = 1:3
        run_name{end+1} = C.oif{r,ires}; run_res(end+1) = ires; run_row(end+1) = r;
    end
end
mon_lab = {'Jun','May','Jul','Aug','Jun','Jun'}; reg_lab = {'','','','','_R2','_R3'};
for i = 1:numel(run_name)
    run_label{i} = [C.res_label{run_res(i)} '_' mon_lab{run_row(i)} reg_lab{run_row(i)}];
end
% two-month analysis window from the release month (month_plot_all{31})
win_month = zeros(numel(run_name),2);
for i = 1:numel(run_name)
    m0 = C.exp_month(run_row(i)); win_month(i,:) = [m0 m0+1];
end

% Budget terms (plot_list{5,1}/{6,1} of the icomb-31 block) with sign factors
B.Fe.var  = {'Fe_NET','Fe_PHY','Fe_BIO','Fe_FLUXsurf','Fe_HADV','Fe_ADZ','Fe_MIX','Fe_PHOTO','Fe_PROD','Fe_SCAVENGE'};
B.Fe.label = {'$\mathrm{Fe}_{NET}$','$\mathrm{Fe}_{PHY}$','$\mathrm{Fe}_{BIO}$','$\mathrm{Fe}^{surf}_{FLUX}$', ...
    '$\mathrm{Fe}_{HADV}$','$\mathrm{Fe}_{VADV}$','$\mathrm{Fe}_{MIX}$','$\mathrm{Fe}_{UPTAKE}$', ...
    '$\mathrm{Fe}_{ReGen}$','$\mathrm{Fe}_{SCAV}$'};
B.Fe.factor = [1 1 1 1 1 1 1 -1 1 -1];     % uptake and scavenging are sinks
B.Fe.name = 'Fe';
B.DIC.var = {'DIC_NET','DIC_PHY','DIC_BIO','DIC_FGCO2','DIC_HADV','DIC_ADZ','DIC_MIX','DIC_PHOTOC','DIC_PROD'};
B.DIC.label = {'$\mathrm{DIC}_{NET}$','$\mathrm{DIC}_{PHY}$','$\mathrm{DIC}_{BIO}$','$\mathrm{DIC}^{surf}_{FLUX}$', ...
    '$\mathrm{DIC}_{HADV}$','$\mathrm{DIC}_{VADV}$','$\mathrm{DIC}_{MIX}$','$\mathrm{DIC}_{UPTAKE}$', ...
    '$\mathrm{DIC}_{REMIN}$'};
B.DIC.factor = [1 1 1 1 1 1 1 -1 1];
B.DIC.name = 'C';                            % vname_filelist{5}

missing = {};                      % composites missing or without data in the window
for tr = {'Fe','DIC'}
    T = B.(tr{1}); nv = numel(T.var); nr = numel(run_name);
    integ = nan(nv, nr, 3);        % integrated (mmol) for k = 1 OIF, 2 control, 3 OIF-control
    ndays = nan(nv, nr);
    for iv = 1:nv
        for ir = 1:nr
            f = fullfile(figdir(run_name{ir}), [T.var{iv} '_time_series_at_locations_of_maximum_difference' LS12 '.mat']);
            if ~isfile(f); missing{end+1} = [f ' (file not found)']; continue; end
            S = load(f, 'composite'); cs = S.composite.avg_50m;
            ind_use0 = find(date_yearly > datenum(yearnum, win_month(ir,1), 1) & ...
                            date_yearly < datenum(yearnum, win_month(ir,2)+1, 1));
            ind2 = find(cs.data_stats_OIF(:,7,1)~=0 & cs.data_stats_OIF(:,7,2)~=0);
            ind_use = intersect(intersect(1:365, ind_use0), ind2);
            if isempty(ind_use); missing{end+1} = [f ' (no day with OIF and control data in the window)']; continue; end
            ind_end = find(~isnan(cs.time_series_date(ind_use)));
            if isempty(ind_end); missing{end+1} = [f ' (no dated day in the window)']; continue; end
            for k = 1:3
                ts = cs.data_stats_OIF(ind_use, 7, k) * T.factor(iv);   % area-integrated rate (mmol s-1)
                ts(ts > 1e30) = nan; ts(isnan(ts)) = 0;
                cum = cumsum(ts) * 86400;
                integ(iv, ir, k) = cum(ind_end(end));
            end
            ndays(iv, ir) = numel(ind_use);
        end
    end
    T.oif  = integ(:,:,1);
    T.ctrl = integ(:,:,2);
    T.diff = integ(:,:,3);
    T.ndays = ndays;
    T.dims = 'term x run';
    budget.(tr{1}) = T;
end
if ~isempty(missing)
    list = strjoin(missing(1:min(end, 10)), newline);     % the first ten
    if numel(missing) > 10; list = sprintf('%s\n... and %d more', list, numel(missing) - 10); end
    error('OIF:missingInput', ['prep_budgets_profiles_coarsegrain: %d budget composite(s) missing ' ...
        'or without data in the analysis window (budget_ensemble.mat not written):\n%s'], ...
        numel(missing), list);
end
budget.run_name  = run_name;
budget.run_label = run_label;
budget.run_res   = run_res;      % 1/2/3 = 1/4/12 km
budget.run_row   = run_row;      % row index into C.oif / C.exp_label
budget.win_month = win_month;    % analysis window (months, inclusive)
budget.units = 'mmol, upper-50 m and analysis-domain integrated, accumulated over the analysis window';
budget.note = ['Integral of data_stats_OIF(:,7,k) (area-integrated 0-50 m tendency, mmol s-1) * 86400 over days ' ...
    'strictly after the 1st day of the release month up to the end of the following month, ' ...
    'keeping days where both OIF and control are non-zero (PACMED12_Process_budget.m, icomb 31).'];
save(fullfile(C.data_dir, 'budget_ensemble.mat'), 'budget', '-v7');

%% ======================= 2. Fe / DIC profiles (Fig. S10) =================
prof.run_oif  = C.oif(1,:);  prof.run_ctrl = C.ctrl;  prof.res_label = C.res_label;
for ires = 1:3
    P1 = load(fullfile(figdir(C.oif{1,ires}), 'zslice_file_domain_mean_profile67.mat'), 'profile');
    P2 = load(fullfile(figdir(C.ctrl{ires}),  'zslice_file_domain_mean_profile67.mat'), 'profile');
    prof.Fe_oif(:,ires)   = squeeze(P1.profile.Fe);
    prof.DIC_oif(:,ires)  = squeeze(P1.profile.DIC);
    prof.Fe_ctrl(:,ires)  = squeeze(P2.profile.Fe);
    prof.DIC_ctrl(:,ires) = squeeze(P2.profile.DIC);
end
prof.dep = squeeze(P1.profile.dep);            % positive depth (m)
prof.units = 'mmol m-3; analysis-domain mean, June-July';
save(fullfile(C.data_dir, 'profile_Fe_DIC.mat'), 'prof', '-v7');

%% ======================= 3. Coarse-graining fluxes (Figs. S11, S12) =======
ctrl_run = 'OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear';   % domain 98 (full-year 1 km control)
oif_run  = C.oif{1,1};                                    % June R1 1 km (Case 1)
ilay = 10;              % 50 m layer
zmax = 150;             % keep depths <= 150 m (plots show 0-120 m)

% months averaged in the published depth-scale panels (plot_figS11.m,
% plot_figS12.m): S11(e) 'summer' = Jun-Jul, S11(f) 'winter' = Dec-Jan,
% S12(a-d) = Jun-Jul
cg.months_S11 = {[6 7], [12 1]};
cg.months_S12 = [6 7];
cg.ctrl_run = ctrl_run; cg.oif_run = oif_run;

% MLD (control) and Zeu
S = load(fullfile(figdir(ctrl_run), ['MLD_time_series_at_locations_of_maximum_difference' LS12 '.mat']), 'composite');
mld_all = S.composite.tmp_surf.data_stats_OIF(:,6,1);        % 365 x 1 (m, positive)
ind_mld = find(~isnan(mld_all));
cg.mld_date = S.composite.tmp_surf.time_series_date(ind_mld)';
cg.mld      = mld_all(ind_mld);
cg.mld_all  = mld_all;
Z = load(fullfile(figdir(ctrl_run), 'Zeu_monthly_mean_timeseries_OSPnw5_domain_RMSpg15_Papa_extend2_2010.mat'));
cg.zeu_time = Z.zeu_time; cg.zeu = Z.zeu_mean(:,1);
S = load(fullfile(figdir(oif_run), ['MLD_time_series_at_locations_of_maximum_difference' LS12 '.mat']), 'composite');
cg.mld_all_oif = S.composite.tmp_surf.data_stats_OIF(:,6,1);  % all NaN in the available cache

% name, file, variable
spec = {'wb',   ctrl_run, 'hovmoller_flux_depth_t_within_papa_mask_buoy_avg_v4.nc';
        'wFe',  ctrl_run, 'hovmoller_flux_depth_t_within_papa_mask_avg_v4.nc';
        'wDIC', ctrl_run, 'hovmoller_flux_depth_t_within_papa_mask_DIC_avg_v4.nc';
        'wFe',  oif_run,  'hovmoller_flux_depth_t_within_papa_mask_avg_v4.nc';
        'wDIC', oif_run,  'hovmoller_flux_depth_t_within_papa_mask_DIC_avg_v4.nc'};
tag = {'ctrl','ctrl','ctrl','oif','oif'};
% units: the 'units' attributes of the netCDF variables where present; the
% coarse-graining code writes none, so the units implied by that code are
% used (w in m s-1; b = -g rho/rho0 with rho in kg m-3, g = 9.8 m s-2,
% rho0 = 1027.4 kg m-3; Fe, DIC in mmol m-3; filtscale = filter width in km)
unit_code = struct('wb','m2 s-3', 'wFe','mmol m-2 s-1', 'wDIC','mmol m-2 s-1', ...
    'filtscale','km', 'depth','m', 'time','days (MATLAB datenum)');
unit_from_file = struct();
for is = 1:size(spec,1)
    f = fullfile(figdir(spec{is,2}), spec{is,3});
    w = double(squeeze(ncread(f, spec{is,1})));   % filtscale x depth x time (cumulative flux <= scale)
    w(abs(w) > 1e10) = nan;
    scale = double(ncread(f,'filtscale')); dep = double(ncread(f,'depth')); xtime = double(ncread(f,'time'));
    kz = find(dep <= zmax);
    fld = [spec{is,1} '_' tag{is}];
    % 50 m Hovmoller (time x scale) + valid days (surface layer, scale index 2 non-zero)
    ws = squeeze(w(:,1,:))';
    H.w50 = single(squeeze(w(:,ilay,:))');
    H.valid50 = (ws(:,2)~=0 & ~isnan(ws(:,2)));
    % monthly-mean depth-scale structure (any multi-month average is the
    % valid-day-weighted mean of these, see plot_figS11/S12)
    valid = squeeze(w(10,10,:)~=0);            % days used in the original (NaN days included; used for the MLD mean)
    finite_day = squeeze(any(any(~isnan(w(:,kz,:)),1),2));
    nan_partial = squeeze(any(any(isnan(w(:,kz,:)),1),2)) & finite_day;
    assert(~any(nan_partial), 'partially missing days: monthly weighting would not reproduce the original nanmean');
    mvec = datevec(xtime); mvec = mvec(:,2);
    H.valid = valid;
    H.wz_month = nan(numel(kz), numel(scale), 12);
    H.nday_month = zeros(1,12);                % valid days with data (weights for multi-month means)
    for im = 1:12
        id = valid & finite_day & mvec == im;
        H.nday_month(im) = nnz(id);
        if any(id); H.wz_month(:,:,im) = mean(w(:,kz,id), 3, 'omitnan')'; end
    end
    H.file = rel_to_root(f, C.box_root);
    cg.(fld) = H;
    cg.scale = scale; cg.time = xtime; cg.dep = dep(kz); cg.dep50 = dep(ilay);
    for v = {spec{is,1}, 'filtscale', 'depth', 'time'}
        u = nc_units(f, v{1});
        if ~isempty(u); unit_from_file.(v{1}) = u; end
    end
end
uv = fieldnames(unit_code);
for k = 1:numel(uv)
    if isfield(unit_from_file, uv{k}); cg.units.(uv{k}) = unit_from_file.(uv{k});
    else; cg.units.(uv{k}) = unit_code.(uv{k}); end
end
if isempty(fieldnames(unit_from_file))
    unit_src = 'the netCDF files have no units attributes; units of the coarse-graining code';
else
    unit_src = sprintf('from the netCDF units attributes of %s, otherwise from the coarse-graining code', ...
        strjoin(fieldnames(unit_from_file)', ', '));
end
fprintf('coarse-graining units (%s):\n', unit_src); disp(cg.units)
cg.note = ['w*_ctrl/w*_oif: cumulative (scale-filtered) vertical fluxes (filtscale x depth); the plotted k[w*] is d(w*)/d(scale). ' ...
    'w50: 50-m layer, time x scale; valid50: days shown in the 50-m Hovmoller; wz_month(:,:,m): depth x scale mean over the valid days ' ...
    'of month m of 2010 (nday_month days); mld_all: daily control MLD (m, positive), averaged over the same valid days for the MLD lines. ' ...
    sprintf('Units (%s): wb %s, wFe %s, wDIC %s, filtscale %s, depth %s, time %s; k[w*] in the unit of w* per km. ', ...
        unit_src, cg.units.wb, cg.units.wFe, cg.units.wDIC, cg.units.filtscale, cg.units.depth, cg.units.time) ...
    'Horizontal average: over the 690 x 1050 interior cells of the OSP-1KM grid, i.e. the grid without a 20-cell band ' ...
    'along its open boundaries (208.3-219.7E, 46.2-57.7N; the ''papa_mask'' of the file names), for both runs (same grid). ' ...
    'months_S11, months_S12: months averaged in the published depth-scale panels of Figs. S11(e,f) and S12. ' ...
    'file: relative to the data root (OIF_DATA_ROOT).'];
save(fullfile(C.data_dir, 'coarsegrain_hovmoller.mat'), 'cg', '-v7');
fprintf('prep_budgets_profiles_coarsegrain: done\n');

% =========================================================================
function u = nc_units(file, vname)
%NC_UNITS 'units' attribute of a netCDF variable ('' if it has none).
vinfo = ncinfo(file, vname);
u = '';
if ~isempty(vinfo.Attributes)
    k = find(strcmp({vinfo.Attributes.Name}, 'units'), 1);
    if ~isempty(k); u = char(vinfo.Attributes(k).Value); end
end
end

function p = rel_to_root(p, root)
% Path below the data root written as '<OIF_DATA_ROOT>/...' (stored strings
% carry no machine-specific absolute paths).
p = char(p);
root = regexprep(char(root), '[\\/]+$', '');   % without trailing separator
n = numel(root);
if n > 0 && strncmp(p, root, n) && numel(p) > n && any(p(n+1) == '/\')
    p = ['<OIF_DATA_ROOT>/' strrep(p(n+2:end), '\', '/')];
end
end
