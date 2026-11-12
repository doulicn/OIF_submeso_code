%PREP_ENSEMBLE_MLD Build data/ens_mld.mat: control-run mixed-layer depth under the patch (Fig. S9e,f).
%
%   Reads (from C.roms_dir, the ROMS/ folder of the data root C.box_root,
%   environment variable OIF_DATA_ROOT; see oif_config.m):
%     <1km June run>/Analysis/figures/Correlation_d<VAR>_int_vs_ctrlMLD_wavg<LS11>.mat
%        (VAR = POC_FLUX, CO2_FLUX) cached figure data of the original
%        analysis: x = patch-area weighted mean mixed-layer depth (hbls) of the
%        control run over the 60-day window, y = 60-day domain-integrated
%        OIF - control flux, one value per run in Case order
%     data/ens_metrics.mat (from prep_timeseries_ensemble)
%
%   Writes:
%     data/ens_mld.mat   mld_ctrl_wavg (18x1, m, positive down) and the two
%                        regressions of Figure S9e,f (structs as in
%                        ens_metrics.mat corr: x, y, fit_coef, R, P)
%
%   The x values come from the "Control run" sheet (variable hbls, column
%   'Patch-area weighted average in') of
%   Statistics_InOutPatch_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50.xlsx,
%   which the original analysis script PACMED12_Process_marbl_8p6z.m read
%   when it wrote these caches (section 'correlation of the patch-area
%   spatiotemporally integrated flux', icomb = 34). The script checks that
%   the runs and the y values of the caches are those of ens_metrics.mat
%   (xls_POC100, xls_CO2) and recomputes the fits and R, p.
%
%   Re-runnable; only data/ens_mld.mat is (over)written.

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~isfolder(C.box_root)
    error('OIF:noDataRoot', ['prep_ensemble_mld needs the data root, the folder that ' ...
        'contains ROMS/. Set the environment variable OIF_DATA_ROOT to that folder ' ...
        '(current value: ''%s''); see oif_config.m.'], C.box_root);
end
LS11 = '_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50';
ref_dir = fullfile(C.roms_dir, C.oif{1,1}, 'Analysis', 'figures');
E = load(fullfile(C.data_dir, 'ens_metrics.mat'));

vars = {'POC_FLUX', 'CO2_FLUX'};
yref = {E.xls_POC, E.xls_CO2};
M = struct();
M.README = ['Control-run mixed-layer depth (hbls, m, positive down), patch-area weighted mean over ' ...
    'the 60-day window, one value per run in Case order (label), and the regressions of the ' ...
    '60-day domain-integrated POC flux (100 m) and CO2 flux anomalies on it (Figure S9e,f). ' ...
    'Source: cached figure data of the original analysis (see prep/prep_ensemble_mld.m).'];
M.label = E.label;
mld = cell(1,2);
for k = 1:2
    f = fullfile(ref_dir, ['Correlation_d' vars{k} '_int_vs_ctrlMLD_wavg' LS11 '.mat']);
    c = load(f);
    if ~isequal(c.test(:), E.label(:))
        error('OIF:mldRuns', '%s: runs differ from ens_metrics.mat', f);
    end
    dy = max(abs(c.y(:) - yref{k}(:)) ./ abs(yref{k}(:)));
    if dy > 1e-10
        error('OIF:mldFlux', '%s: y differs from ens_metrics.mat (max rel. diff. %.2g)', f, dy);
    end
    mld{k} = c.x(:);
    r.x = c.x(:); r.y = yref{k}(:);
    ok = ~isnan(r.x) & ~isnan(r.y);
    r.fit_coef = polyfit(r.x(ok), r.y(ok), 1);
    [Rm, Pm] = corrcoef(r.x(ok), r.y(ok));
    r.R = Rm(1,2); r.P = Pm(1,2);
    M.check_vs_cache.(['d' vars{k} '_int_vs_ctrlMLD_wavg']) = [r.R - c.R, r.P - c.P];
    M.corr.(['d' vars{k} '_int_vs_ctrlMLD_wavg']) = r;
    fprintf('%s vs MLD: R = %.3f, p = %.3f (cache: %.3f, %.3f)\n', vars{k}, r.R, r.P, c.R, c.P);
end
if ~isequal(mld{1}, mld{2})
    error('OIF:mldX', 'the MLD values of the POC and CO2 caches differ');
end
M.mld_ctrl_wavg = mld{1};
M.units.mld_ctrl_wavg = 'm';
save(fullfile(C.data_dir, 'ens_mld.mat'), '-struct', 'M');
fprintf('wrote %s\n', fullfile(C.data_dir, 'ens_mld.mat'));
