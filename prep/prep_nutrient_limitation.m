%PREP_NUTRIENT_LIMITATION Build data/nutrient_limit_R1.mat: limiting nutrient at the R1 centre (Fig. S8).
%
%   Reads (from C.roms_dir, the ROMS/ folder of the data root C.box_root,
%   environment variable OIF_DATA_ROOT; see oif_config.m):
%     <run>/Analysis/figures/vertical_profile_monthly_2010_from_ncfile_OIFCT.mat
%        daily vertical profiles (100 levels) at station OIFCT, the centre of
%        release region R1 (52.27 N, 145.95 W), extracted from the ROMS
%        output by the original analysis code; runs: the 1-km control run
%        (C.ctrl{1}) and the 1-km June-R1 OIF run (C.oif{1,1}, Case 1)
%
%   Writes:
%     data/nutrient_limit_R1.mat   for each run: time (datenum), depth (m,
%        negative down), lim_type (3 x nz x nt; 1 N, 2 Fe, 3 P, 4 Si) and
%        lim_factor (3 x nz x nt, the minimum limitation factor) for small
%        phytoplankton, diatoms and diazotrophs; for the OIF run also dFe
%        (OIF - control dissolved Fe, mmol m-3, control interpolated to the
%        OIF days) for the patch contour; the half-saturation constants used
%
%   Limitation factors (BEC, as in the original analysis script
%   PACMED12_Process_marbl_8p6z.m, section 'plot nutrient limitations
%   vertical profile'):
%     N:  sum over NO3, NO2, NH4 of (X/kX) / (1 + NO3/kNO3 + NO2/kNO2 + NH4/kNH4)
%         (set to 1 for diazotrophs, which fix N2)
%     Fe: Fe / (Fe + kFe)
%     P:  sum over PO4, DOP of (X/kX) / (1 + PO4/kPO4 + DOP/kDOP), where DOP
%         is the DOC profile of the station file, as in the published figure
%         (see below)
%     Si: SiO3 / (SiO3 + kSiO3) (kSiO3 = 0 for small phytoplankton and
%         diazotrophs, i.e. factor 1)
%   The limiting nutrient is the one with the smallest factor.
%
%   Known difference from the method: the original code takes 'DOP' from
%   position 12 of the station variable list of the BEC runs (varlist{4,1}
%   of PACMED12_Process_param_8p6z.m), which is DOC. With DOC (up to
%   ~45 mmol m-3) in place of DOP (< 0.23 mmol m-3) the P factor is close to
%   1, so P never limits. The published Figure S8 was made this way and the
%   default (use_dop = false) reproduces it. Set use_dop = true in the
%   workspace before running the script to use the DOP profile instead; P
%   then limits small phytoplankton and diazotrophs, and diatoms in part of
%   the area where Si limits in the published figure, in the upper ~40 m
%   in early June (output data/nutrient_limit_R1_DOP.mat, plotted by
%   plot_figS8 with the same option).
%
%   Re-runnable; only data/nutrient_limit_R1.mat is (over)written.

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~exist('use_dop', 'var'); use_dop = false; end
if ~isfolder(C.box_root)
    error('OIF:noDataRoot', ['prep_nutrient_limitation needs the data root, the folder that ' ...
        'contains ROMS/. Set the environment variable OIF_DATA_ROOT to that folder ' ...
        '(current value: ''%s''); see oif_config.m.'], C.box_root);
end
station = 'OIFCT';
sfile = @(run) fullfile(C.roms_dir, run, 'Analysis', 'figures', ...
    ['vertical_profile_monthly_2010_from_ncfile_' station '.mat']);

% half-saturation constants: small phytoplankton, diatoms, diazotrophs
K.Fe   = [0.025e-3, 0.05e-3, 0.025e-3];   % mmol Fe m-3
K.PO4  = [0.0075, 0.06, 0.015];           % mmol P m-3
K.DOP  = [0.22, 0.6, 0.05];               % mmol P m-3
K.NO3  = [0.2, 0.6, 2.0];                 % mmol N m-3
K.NO2  = [0.03, 0.24, 0.8];               % mmol N m-3
K.NH4  = [0.0025, 0.02, 0.0667];          % mmol N m-3
K.SiO3 = [0.0, 0.6, 0.0];                 % mmol Si m-3

L = struct();
L.README = ['Limiting nutrient (lim_type: 1 N, 2 Fe, 3 P, 4 Si) and minimum limitation factor ' ...
    '(lim_factor) of small phytoplankton, diatoms and diazotrophs (first dimension) at station ' ...
    'OIFCT (R1 centre, 52.27 N, 145.95 W) in the 1-km control run (ctrl) and the 1-km June-R1 ' ...
    'OIF run (oif, Case 1); depth x day. oif.dFe: OIF - control dissolved Fe (mmol m-3) for ' ...
    'the patch contour (threshold patch_threshold). See prep/prep_nutrient_limitation.m.'];
L.phyto = {'SP', 'DIAT', 'DIAZ'};
L.type_names = {'N', 'Fe', 'P', 'Si'};
L.K = K;
L.use_dop = use_dop;
L.station = station; L.station_lonlat = [-145.95 52.27];
L.patch_threshold = C.patch_threshold;

runs = {C.ctrl{1}, C.oif{1,1}}; tags = {'ctrl', 'oif'};
raw = cell(1,2);
for k = 1:2
    d = load(sfile(runs{k}), 'data'); d = d.data.(station);
    raw{k} = d;
    [L.(tags{k}).lim_type, L.(tags{k}).lim_factor] = limitation(d, K, use_dop);
    L.(tags{k}).time = double(d.time(:)')/86400 + C.date_ref;
    L.(tags{k}).depth = double(d.depth(:));
    L.(tags{k}).run = runs{k};
end
% OIF - control Fe on the OIF days
fe_ctrl = interp1(double(raw{1}.time(:)), double(raw{1}.Fe)', double(raw{2}.time(:)))';
L.oif.dFe = double(raw{2}.Fe) - fe_ctrl;
% plotted window: the first two months of the OIF run
t1 = L.oif.time(1);
L.time_lim = [t1, min(L.oif.time(end), addtodate(t1, 2, 'month'))];

outfile = fullfile(C.data_dir, 'nutrient_limit_R1.mat');
if use_dop; outfile = fullfile(C.data_dir, 'nutrient_limit_R1_DOP.mat'); end
save(outfile, '-struct', 'L');
for k = 1:2
    in = L.(tags{k}).time >= L.time_lim(1) & L.(tags{k}).time <= L.time_lim(2);
    z = L.(tags{k}).depth >= -200;
    lt = L.(tags{k}).lim_type(:, z, in);
    fprintf('%s: fraction Fe-limited (upper 200 m, window) SP %.3f, DIAT %.3f, DIAZ %.3f\n', tags{k}, ...
        mean(lt(1,:)==2), mean(lt(2,:)==2), mean(lt(3,:)==2));
end
fprintf('wrote %s\n', outfile);

function [ltype, lfac] = limitation(d, K, use_dop)
% Limitation type and factor (3 x nz x nt) from the station profiles d.
NO3 = double(d.NO3); NO2 = double(d.NO2); NH4 = double(d.NH4);
PO4 = double(d.PO4); Fe = double(d.Fe); SiO3 = double(d.SiO3);
if use_dop; DOP = double(d.DOP); else; DOP = double(d.DOC); end   % see the header
[nz, nt] = size(NO3);
F = nan(3, nz, nt, 4);
for a = 1:3
    dn = 1 + NO3/K.NO3(a) + NO2/K.NO2(a) + NH4/K.NH4(a);
    F(a,:,:,1) = (NO3/K.NO3(a) + NO2/K.NO2(a) + NH4/K.NH4(a)) ./ dn;
    F(a,:,:,2) = Fe ./ (Fe + K.Fe(a));
    dp = 1 + PO4/K.PO4(a) + DOP/K.DOP(a);
    F(a,:,:,3) = (PO4/K.PO4(a) + DOP/K.DOP(a)) ./ dp;
    F(a,:,:,4) = SiO3 ./ (SiO3 + K.SiO3(a));
end
F(3,:,:,1) = 1;                          % diazotrophs: no N limitation
[lfac, ltype] = min(F, [], 4);
end
