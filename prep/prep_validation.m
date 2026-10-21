%PREP_VALIDATION Build the data behind Figs. S1 and S2 (model-observation
% comparison at Ocean Station Papa, 2010, ROMS-BEC at 1/4/12/25 km).
%
% Reads (data root C.box_root, environment variable OIF_DATA_ROOT; see oif_config.m):
%   ROMS/<domain>/Analysis/figures/extract_stations_data_2010.mat   (station Papa time series)
%   ROMS model grids (station depth / layer thickness, bathymetry check)
%   Station P in situ, Argo, MODIS products, WOA23 monthly 1-degree climatology
% Writes (data/):
%   valid_model_papa.mat  model upper-30 m series (raw + smoothed), monthly MLD,
%                         JJA mean profiles, station vertical grid, bathymetry check
%   valid_obs_papa.mat    in situ / Argo / MODIS monthly values (CLM and 2003-2024
%                         monthly records) and July-September mean +- std profiles
%   valid_woa23_papa.mat  WOA23 Papa column: monthly profiles, upper-30 m means,
%                         MLD (drho>0.03 re 10 m), JJA mean profiles
% Needs the TEOS-10 GSW toolbox (environment variable OIF_GSW_DIR).
%
% Provenance: re-implements the station comparison of the original analysis
% script PACMED12_Process_marbl_8p6z.m (block plot_stations_validation_cmp_tests,
% icomb=21, station_data_filetype='legacy'): density and MLD2 of SECTION 1,
% monthly series of SECTION 6, seasonal profiles of SECTION 7, and the WOA23
% loader load_woa23_profile_8p6z.m (lib/woa23_profile.m). The inputs are
% intermediate products made by code that is not part of this package: the
% station extractions (extract_stations_data_2010.mat) of the ROMS output, the
% processed Station P / Argo / MODIS files and the observation seasonal
% profiles (the Argo ones by argo_plot_v2.m).
%
% Smoothing of the model upper-30 m series (ts30s, Fig. S1a-e). As in the
% original code the window is edata_freq*30 samples, with edata_freq = 48 for
% the 1/4/12 km runs (half-hourly output assumed) and 1 for the daily 25 km
% run. The station files are sampled every 0.5, 1, 0.6 and 24 h, so the
% effective windows are 1440/1440/1440/30 samples = 30/60/36/30 days at
% 1/4/12/25 km; the published Fig. S1 shows these. Set uniform_30day_window =
% true before running the script to use round(30/median(diff(time))) samples
% instead (1440/720/1200/30 samples = 30 days for every run; this changes
% Fig. S1, e.g. the 4 km chlorophyll peak).
%
% Seasons: model and WOA23 profiles are June-August means (as in the
% published Fig. S2). The in situ and Argo profiles are column 3 of their
% seasonal source files, which is July-September (months [7 8 9] in the Argo
% builder; the Argo file labels this column 'fall'); they are stored as
% insitu_jas* and argo_jas*.

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~isfolder(C.box_root)
    error('OIF:noDataRoot', ['prep_validation needs the data root, the folder that contains ROMS/, ' ...
        'noaa/, Iron/ and MODIS/. Set the environment variable OIF_DATA_ROOT to that folder ' ...
        '(current value: ''%s''); see oif_config.m.'], C.box_root);
end
if exist('gsw_rho','file') ~= 2 || exist('gsw_CT_from_t','file') ~= 2
    error('OIF:noGSW', ['prep_validation needs the TEOS-10 GSW toolbox (gsw_rho, gsw_CT_from_t), ' ...
        'which was not found (folder tried: %s). Set the environment variable OIF_GSW_DIR to ' ...
        'the GSW folder, or put GSW into external/gsw in the package (see oif_config.m).'], C.gsw_dir);
end
if ~exist('uniform_30day_window','var'); uniform_30day_window = false; end   % false = published Fig. S1
R = C.box_root;
depth_lim = 30;                        % m
station   = 'Papa';
lon_st = mod(-145,360); lat_st = 50;   % Ocean Station Papa
season_months = [6 7 8];               % June-August (model and WOA23 profiles)

% ---- model runs (order of test_cmp=[98 97 71 49]) ----------------------------
M.res_label  = {'1KM','4KM','12KM','25KM'};
M.domain     = {'OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear', ...
                'NEPAC4KM_INI_BEC_V2_daily_diaT2_nw5_allyear', ...
                'PACMED12KM_INI_BEC_V2_param2_daily_diaT2', ...
                'PACMED25KM_INI_BEC_V2_param2'};
M.edata_freq = [48 48 48 1];           % domain_list{:,5}: smoothing window = edata_freq*30 samples
grid_file    = {C.grd{1}, C.grd{2}, C.grd{3}, ...
                fullfile(C.roms_dir,'Work/PACMED25KMnew/FORCINGS/pacmed25_grd.nc')};
M.grid_file  = cellfun(@(f) rel_to_root(f, R), grid_file, 'UniformOutput', false);
theta_s=6; theta_b=6; hc=250; N=100; sc_type='new2012';

% ---- station vertical grid ---------------------------------------------------
% The paper's code built station_depth/station_dz from the grid of the domain
% being processed (domain 98 = OSP-1KM, ospnw5_grd.nc) and applied it to all
% four runs. Reproduce that, and also compute each run's own column for checking.
M.grid_h = nan(1,4); M.grid_ij = nan(4,2); M.grid_lonlat = nan(4,2);
z_r_own = nan(N,4); dz_own = nan(N,4);
for ig = 1:4
    lon = ncread(grid_file{ig},'lon_rho'); lat = ncread(grid_file{ig},'lat_rho');
    lon = mod(lon,360);
    [ii,jj] = station_index(lon,lat,lon_st,lat_st);
    h0 = double(ncread(grid_file{ig},'h',[ii jj],[1 1]));
    M.grid_h(ig) = h0; M.grid_ij(ig,:) = [ii jj]; M.grid_lonlat(ig,:) = [lon(ii,jj) lat(ii,jj)];
    zr = roms_zlevs(h0,0,theta_s,theta_b,hc,N,'r',sc_type);
    zw = roms_zlevs(h0,0,theta_s,theta_b,hc,N,'w',sc_type);
    z_r_own(:,ig) = zr(:); dz_own(:,ig) = diff(zw(:));
    fprintf('%-5s grid: Papa column (i,j)=(%d,%d) at %.3fE %.3fN, h = %.1f m\n', ...
        M.res_label{ig},ii,jj,lon(ii,jj),lat(ii,jj),h0);
    clear lon lat
end
M.station_depth = z_r_own(:,1);        % used for all runs (as in the paper)
M.station_dz    = dz_own(:,1);
M.station_depth_own = z_r_own; M.station_dz_own = dz_own;
station_dz2 = M.station_dz; station_dz2(M.station_depth < -depth_lim) = nan;
M.station_dz2 = station_dz2;
M.depth_lim = depth_lim;

% ---- model station data ------------------------------------------------------
vars30  = {'temp','rho','NO3','Fe','CHL'};          % Fig. S1 a-e (upper-30 m mean)
varsjja = {'temp','rho','NO3','Fe','CHL','O2'};     % Fig. S2 a-f
dep = M.station_depth;
smooth_samples = zeros(1,4); smooth_days = zeros(1,4);   % ts30s windows (see header)
for i = 1:4
    f = fullfile(C.roms_dir,M.domain{i},'Analysis','figures','extract_stations_data_2010.mat');
    fprintf('Reading %s\n',rel_to_root(f, R));
    S = load(f,'data'); P = S.data.(station); clear S
    t = P.ocean_time/86400 + C.date_ref;
    M.time{i} = t(:)';
    % SECTION 1: potential density and MLD2 (not stored in the station files).
    % Pressure argument = station depth (negative), exactly as in the original.
    temp = squeeze(P.temp); salt = squeeze(P.salt);
    CT  = gsw_CT_from_t(salt,temp,dep);
    rho = double(gsw_rho(salt,CT,0)-1000);
    P.rho = rho;
    ind2 = find(abs(dep+10)==min(abs(dep+10)));
    mld2 = zeros(1,size(rho,2));
    for k = 1:size(rho,2)
        ind = find(rho(:,k)-rho(ind2,k) > 0.03, 1, 'last');
        if ~isempty(ind); mld2(k) = dep(ind); end
    end
    % same MLD2 but with this run's own vertical grid (sensitivity check)
    dep_own = z_r_own(:,i);
    CTo = gsw_CT_from_t(salt,temp,dep_own); rho_o = double(gsw_rho(salt,CTo,0)-1000);
    ind2o = find(abs(dep_own+10)==min(abs(dep_own+10)));
    mld2o = zeros(1,size(rho_o,2));
    for k = 1:size(rho_o,2)
        ind = find(rho_o(:,k)-rho_o(ind2o,k) > 0.03, 1, 'last');
        if ~isempty(ind); mld2o(k) = dep_own(ind); end
    end
    clear CT CTo rho_o temp salt
    % SECTION 6: upper-30 m dz-weighted means, low-pass filtered with
    % fft_lowpass (same FFT smoothing method as the original code; windows:
    % see header)
    dt_med = median(diff(t(:)));                     % sampling interval (days)
    if uniform_30day_window
        smooth_samples(i) = round(30/dt_med);        % 30 days for every run
    else
        smooth_samples(i) = M.edata_freq(i)*30;      % published Fig. S1
    end
    smooth_days(i) = smooth_samples(i)*dt_med;
    dzo = dz_own(:,i); dzo(dep_own < -depth_lim) = nan;
    for v = 1:numel(vars30)
        x  = squeeze(P.(vars30{v}));
        ts = sum(x.*station_dz2,1,'omitnan')./sum(station_dz2,1,'omitnan');
        M.ts30.(vars30{v}){i}  = single(ts);
        M.ts30s.(vars30{v}){i} = single(fft_lowpass(ts,smooth_samples(i)));
        tso = sum(x.*dzo,1,'omitnan')./sum(dzo,1,'omitnan');
        M.ts30s_owngrid.(vars30{v}){i} = single(fft_lowpass(tso,smooth_samples(i)));
    end
    % calendar-month means of MLD2 (plotted on the 15th)
    tv = datevec(t(:)); [ym,~,gm] = unique(tv(:,1)*100+tv(:,2));
    M.mld2_month{i}      = accumarray(gm,mld2(:),[],@(x) mean(x,'omitnan'))';
    M.mld2_month_own{i}  = accumarray(gm,mld2o(:),[],@(x) mean(x,'omitnan'))';
    M.mld2_month_time{i} = datenum(floor(ym/100),mod(ym,100),15)';
    % SECTION 7: JJA mean profiles
    ijja = ismember(tv(:,2),season_months);
    for v = 1:numel(varsjja)
        x = squeeze(P.(varsjja{v}));
        M.prof_jja.(varsjja{v}){i} = mean(x(:,ijja),2,'omitnan');
    end
    M.n_samples(i) = numel(t); M.n_jja(i) = sum(ijja);
    clear P rho x
end
fprintf('ts30s smoothing windows (1/4/12/25 km): %s samples = %s days\n', ...
    mat2str(smooth_samples), mat2str(round(smooth_days,1)));
M.vars30 = vars30; M.varsjja = varsjja; M.season_months = season_months;
M.smooth_samples = smooth_samples; M.smooth_days = smooth_days;
if uniform_30day_window
    win_txt = 'round(30/median(diff(time))) samples, i.e. 30 days for every run (uniform_30day_window = true; differs from the published Fig. S1)';
else
    win_txt = 'edata_freq*30 samples as in the original code (published Fig. S1)';
end
M.note = ['Model station series at Ocean Station Papa (215E,50N), 2010. ts30: dz-weighted mean ', ...
    'over model levels with z_r>-30 m (station_dz2 from the OSP-1KM grid column, used for all runs). ', ...
    'ts30s: ts30 low-pass filtered with fft_lowpass over smooth_samples samples = ', win_txt, '; ', ...
    sprintf('effective windows %s samples = %s days at 1/4/12/25 km (smooth_days). ', ...
    mat2str(smooth_samples), mat2str(round(smooth_days,1))), ...
    'mld2_month: monthly mean of MLD2 (shallowest level with ', ...
    'rho-rho(10 m)>0.03). prof_jja: Jun-Aug mean profiles on station_depth. *_own: same computed ', ...
    'with each run''s own grid column (sensitivity check, not used in the figures). ', ...
    'grid_file: relative to the data root (OIF_DATA_ROOT).'];
save(fullfile(C.data_dir,'valid_model_papa.mat'),'-struct','M','-v7');

% ---- observations ------------------------------------------------------------
hyd_dir  = fullfile(R,'Iron','hydrographic_data_NEPAC','hydrographic_data_NEPAC');
argo_dir = fullfile(R,'noaa','argo','figures_v2');
O = struct();
obsvars = {'temp','rho','no3','fe','chl'};   % in situ names (case-insensitive match to model)
% in situ Station P climatology (upper 30 m, monthly) and monthly record
oc = load(fullfile(hyd_dir,sprintf('Papap_exp_np_obs_Station_Papa_upper%d.mat',depth_lim)));
oc.tmp_monthly(:,12) = oc.tmp_monthly(:,12)/1000; oc.tmp_monthly_std(:,12) = oc.tmp_monthly_std(:,12)/1000;
oc.varname{12} = 'fe'; oc.varname{6} = 'sio3';
om = load(fullfile(hyd_dir,sprintf('Papap_exp_np_monthly_obs_Station_Papa_upper%d.mat',depth_lim)));
om.tmp_monthly(:,12) = om.tmp_monthly(:,12)/1000; om.tmp_monthly_std(:,12) = om.tmp_monthly_std(:,12)/1000;
om.varname{12} = 'fe'; om.varname{6} = 'sio3';
for v = 1:numel(obsvars)
    k = find(strcmpi(oc.varname,obsvars{v}));
    O.insitu_clm.(obsvars{v})     = oc.tmp_monthly(:,k);
    O.insitu_clm_std.(obsvars{v}) = oc.tmp_monthly_std(:,k);
    k = find(strcmpi(om.varname,obsvars{v}));
    O.insitu_mon.(obsvars{v}) = om.tmp_monthly(:,k);
end
O.insitu_mon_time = om.x;
% Argo (2003-2024): monthly climatology and monthly record, upper 30 m
ac = load(fullfile(argo_dir,sprintf('Papatime_climatological_monthly_mean_upper_%dm_2003_2024.mat',depth_lim)));
am = load(fullfile(argo_dir,sprintf('Papatime_monthly_mean_upper_%dm_2003_2024.mat',depth_lim)));
argo_names = {'temp','DO','Chl','NO3','density','MLD2'};
argo_out   = {'temp','O2','CHL','NO3','rho','MLD2'};
for v = 1:numel(argo_names)
    k = find(strcmp(ac.argo_mean_clm.varshow,argo_names{v}));
    O.argo_clm.(argo_out{v})     = ac.argo_mean_clm.data{k}(:);
    O.argo_clm_std.(argo_out{v}) = ac.argo_mean_clm.data_std{k}(:);
    k = find(strcmp(am.argo_mean_clm.varshow,argo_names{v}));
    O.argo_mon.(argo_out{v})     = am.argo_mean_clm.data{k}(:);
    O.argo_mon_std.(argo_out{v}) = am.argo_mean_clm.data_std{k}(:);
end
O.argo_mon_time = datenum(am.argo_mean_clm.timevec);
% MODIS chlorophyll (2003-2022)
md = load(fullfile(R,'MODIS','Chl_2003_2022','figures','Papa_zoom0_MODIS_monthly_series_chlor_a.mat'));
O.modis_clm = md.chl_clm(:); O.modis_clm_std = md.chl_clm_std(:);
O.modis_mon = md.chl_t(:);   O.modis_mon_time = md.time(:);
% July-September profiles: column 3 (iseason=3 of the original) of the in situ
% and Argo seasonal files; months [7 8 9] in the Argo builder (see header)
sp = load(fullfile(hyd_dir,'Papap_exp_npseasonal_mean_obs_scatter_Station_Papa_upper1000.mat'));
pv_mod = {'temp','rho','NO3','Fe','CHL','O2'};
pv_obs = {'temp','rho','no3','dfe','chl','o2'};
O.insitu_jas_dep = sp.tmp_prof_mean.dep(:);
for v = 1:numel(pv_mod)
    sc = 1; if strcmp(pv_obs{v},'dfe'); sc = 1/1000; end
    O.insitu_jas.(pv_mod{v})     = sp.tmp_prof_mean_seasons.(pv_obs{v})(:,3)*sc;
    O.insitu_jas_std.(pv_mod{v}) = sp.tmp_prof_std_seasons.(pv_obs{v})(:,3)*sc;
end
ap = load(fullfile(argo_dir,'PapaArgo_profile_seasonal_mean_composaition_300m_01-Jan-2003_31-Dec-2024.mat'));
O.argo_jas_dep = ap.argo_mean_seasons.dep_inp(:);
O.argo_season_labels_in_file = ap.argo_mean_seasons.seasons;
for v = 1:numel(argo_names)-1
    k = find(strcmp(ap.argo_mean_seasons.varshow,argo_names{v}));
    O.argo_jas.(argo_out{v})     = ap.argo_mean_seasons.mean{k}(:,3);
    O.argo_jas_std.(argo_out{v}) = ap.argo_mean_seasons.std{k}(:,3);
    O.argo_seasons_all_surface.(argo_out{v}) = ap.argo_mean_seasons.mean{k}(find(~isnan(ap.argo_mean_seasons.mean{k}(:,3)),1),:);
end
O.note = ['Observations at Ocean Station Papa. insitu_clm/_std: Line P / Station P bottle+CTD ', ...
    'upper-30 m monthly climatology (dFe converted nM->mmol m-3). insitu_mon: monthly upper-30 m ', ...
    'values (all years). argo_clm/_std and argo_mon: Argo 2003-2024 upper-30 m. modis_*: MODIS ', ...
    'chlor_a 2003-2022. insitu_jas*/argo_jas*: July-September mean (+- std) profiles, column 3 of ', ...
    'the in situ and Argo seasonal source files (the Argo builder defines this column as months ', ...
    '7-9; the season labels stored in that file, argo_season_labels_in_file, call it ''fall''). ', ...
    'The model and WOA23 profiles of Fig. S2 are June-August means, as in the published figure.'];
save(fullfile(C.data_dir,'valid_obs_papa.mat'),'-struct','O','-v7');

% ---- WOA23 Papa column -------------------------------------------------------
woa_dir = fullfile(R,'noaa','woa23');
W = struct();
wv = {'temp','salt','NO3','O2'};
for v = 1:numel(wv)
    for im = 1:12
        [d,val,sd] = woa23_profile(woa_dir,wv{v},im,lat_st,lon_st);
        W.prof.(wv{v})(:,im) = val; W.prof_std.(wv{v})(:,im) = sd;
    end
    W.dep.(wv{v}) = d;   % monthly T/S reach 1500 m (57 levels), NO3/O2 800 m (43 levels)
end
W.dep.rho = W.dep.temp;
% density from the stored T,S (identical to load_woa23_profile_8p6z('rho',...)
% evaluated in double precision)
press = -W.dep.temp;
for im = 1:12
    t = W.prof.temp(:,im); s = W.prof.salt(:,im); ts = W.prof_std.temp(:,im); ss = W.prof_std.salt(:,im);
    W.prof.rho(:,im) = double(gsw_rho(s,gsw_CT_from_t(s,t,press),0)-1000);
    hi = double(gsw_rho(s+ss,gsw_CT_from_t(s+ss,t+ts,press),0)-1000);
    lo = double(gsw_rho(s-ss,gsw_CT_from_t(s-ss,t-ts,press),0)-1000);
    W.prof_std.rho(:,im) = abs(hi-lo)/2;
end
% upper-30 m monthly means (levels shallower than 30 m)
for v = {'temp','salt','NO3','O2','rho'}
    iu = W.dep.(v{1}) > -depth_lim;
    W.upper30.(v{1})     = mean(W.prof.(v{1})(iu,:),1,'omitnan')';
    W.upper30_std.(v{1}) = mean(W.prof_std.(v{1})(iu,:),1,'omitnan')';
end
% MLD2 (drho>0.03 re 10 m). The density for this criterion is computed as in
% the original analysis (load_woa23_profile_8p6z('rho',...) in SECTION 6),
% which keeps the single-precision WOA23 depth axis as pressure, so that GSW
% returns the density in single precision. April sits on the threshold: the
% step at 55 m is 0.03003 in single and 0.02992 in double precision, so April
% is -55 m (published Fig. S1f) and would be -60 m in double precision.
W.mld2 = nan(12,1);
for im = 1:12
    [dep_s,rho_s] = woa23_profile(woa_dir,'rho',im,lat_st,lon_st,'native');
    i10 = find(abs(dep_s+10)==min(abs(dep_s+10)),1);
    ind = find(rho_s-rho_s(i10) > 0.03, 1, 'first');
    if ~isempty(ind); W.mld2(im) = dep_s(ind); end
end
% JJA mean profiles
for v = {'temp','salt','NO3','O2','rho'}
    W.jja.(v{1})     = mean(W.prof.(v{1})(:,season_months),2,'omitnan');
    W.jja_std.(v{1}) = mean(W.prof_std.(v{1})(:,season_months),2,'omitnan');
end
lonw = ncread(fullfile(woa_dir,'woa23_temperature_monthly','woa23_decav_t01_01.nc'),'lon');
latw = ncread(fullfile(woa_dir,'woa23_temperature_monthly','woa23_decav_t01_01.nc'),'lat');
[~,ilon] = min(abs(lonw-(lon_st-360))); [~,ilat] = min(abs(latw-lat_st));
W.lonlat = double([lonw(ilon) latw(ilat)]);
W.note = ['WOA23 1-degree monthly climatology (decav T/S; all-period NO3, O2 x1.025 umol/kg->mmol/m3), ', ...
    'nearest grid point to Station Papa. rho = sigma0 from GSW. upper30: mean over WOA levels ', ...
    'shallower than 30 m. mld2: first depth where rho-rho(10 m)>0.03, with rho computed in single ', ...
    'precision as in the original analysis (single-precision WOA23 depth as pressure; in double ', ...
    'precision April would be -60 m instead of -55 m). jja: Jun-Aug mean.'];
save(fullfile(C.data_dir,'valid_woa23_papa.mat'),'-struct','W','-v7');
if W.lonlat(1) < 0; ew = 'W'; else; ew = 'E'; end
fprintf('WOA23 column at %.1f%s %.1fN\n',abs(W.lonlat(1)),ew,W.lonlat(2));
fprintf('WOA23 MLD2 (m, Jan-Dec): %s\n', mat2str(W.mld2'));
disp('prep_validation done.')

% =============================================================================
function [ii,jj] = station_index(lon,lat,lon0,lat0)
% Grid column used for the station, reproducing crop_parent + griddata + round
% of the original code: the fractional index there is 0-based and offset by
% -0.5 (rho point k has index k-1.5), so the column is round(k_frac-1.5).
d = (lon-lon0).^2*cosd(lat0)^2 + (lat-lat0).^2;
[~,k] = min(d(:)); [i0,j0] = ind2sub(size(lon),k);
is = max(1,i0-4):min(size(lon,1),i0+4); js = max(1,j0-4):min(size(lon,2),j0+4);
[I,J] = ndgrid(is,js);
lo = lon(is,js); la = lat(is,js);
i_frac = griddata(lo(:),la(:),I(:)-1.5,lon0,lat0);
j_frac = griddata(lo(:),la(:),J(:)-1.5,lon0,lat0);
ii = round(i_frac); jj = round(j_frac);
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
