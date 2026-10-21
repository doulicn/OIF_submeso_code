function [dep_out,val_out,std_out] = woa23_profile(woa_dir,varname,month,target_lat,target_lon_e,precision)
%WOA23_PROFILE Nearest-gridpoint WOA23 1-degree monthly profile (mean and std).
%   [dep,val,sd] = woa23_profile(woa_dir,varname,month,lat,lon_e)
%   [dep,val,sd] = woa23_profile(woa_dir,varname,month,lat,lon_e,precision)
%   varname: 'temp','salt','O2','NO3','PO4','SiO3' or 'rho' (sigma0 from WOA23 T,S
%   via TEOS-10/GSW). month: 1..12 (monthly climatology) or [] (annual, 00 file).
%   O2 and nutrients are converted from umol/kg to mmol/m3 with a factor 1.025.
%   Depth is returned negative (m). Only the single (lon,lat) column is read.
%   precision: 'double' (default) returns double values; 'native' keeps the
%   classes that ncread returns, as the original loader did: the depth axis is
%   single (the values come back as double because ncread replaces their fill
%   values), so 'rho' is then computed with single-precision pressure, i.e. in
%   single precision (WOA23 MLD of Fig. S1f, see prep/prep_validation.m).
%   Port of load_woa23_profile_8p6z.m (original analysis code), with the WOA23
%   base directory passed in instead of a machine switch.
if nargin < 6 || isempty(precision); precision = 'double'; end
if ~any(strcmp(precision,{'double','native'}))
    error('woa23_profile: precision must be ''double'' or ''native''');
end
target_lon = mod(target_lon_e+180,360)-180;

if strcmp(varname,'rho')
    [dep_out,t_an,t_sd] = woa23_profile(woa_dir,'temp',month,target_lat,target_lon_e,precision);
    [~,s_an,s_sd]       = woa23_profile(woa_dir,'salt',month,target_lat,target_lon_e,precision);
    press = -dep_out; % dbar, positive down
    CT = gsw_CT_from_t(s_an,t_an,press);
    val_out = double(gsw_rho(s_an,CT,0)-1000);
    CT_hi = gsw_CT_from_t(s_an+s_sd,t_an+t_sd,press);
    CT_lo = gsw_CT_from_t(s_an-s_sd,t_an-t_sd,press);
    rho_hi = double(gsw_rho(s_an+s_sd,CT_hi,0)-1000);
    rho_lo = double(gsw_rho(s_an-s_sd,CT_lo,0)-1000);
    std_out = abs(rho_hi-rho_lo)/2;
    return
end

switch varname
    case 'temp'; prefix='t'; subdir='Temp';      mdir='woa23_temperature_monthly'; fbase='woa23_decav_t'; uc=1;
    case 'salt'; prefix='s'; subdir='Salt';      mdir='woa23_salinity_monthly';    fbase='woa23_decav_s'; uc=1;
    case 'O2';   prefix='o'; subdir='Oxygen';    mdir='woa23_oxygen_monthly';      fbase='woa23_all_o';   uc=1.025;
    case 'NO3';  prefix='n'; subdir='Nitrate';   mdir='woa23_nitrate_monthly';     fbase='woa23_all_n';   uc=1.025;
    case 'PO4';  prefix='p'; subdir='Phosphate'; mdir='woa23_phosphate_monthly';   fbase='woa23_all_p';   uc=1.025;
    case 'SiO3'; prefix='i'; subdir='Silicate';  mdir='woa23_silicate_monthly';    fbase='woa23_all_i';   uc=1.025;
    otherwise; error('woa23_profile: unknown variable %s',varname);
end
if isempty(month)
    fname = fullfile(woa_dir,subdir,[fbase,'00_01.nc']);
else
    fname = fullfile(woa_dir,mdir,[fbase,sprintf('%02d',month),'_01.nc']);
end
lon_woa = ncread(fname,'lon');
lat_woa = ncread(fname,'lat');
dep_woa = ncread(fname,'depth');
[~,ilon] = min(abs(lon_woa-target_lon));   % ties -> first (western/southern) point, as in the original
[~,ilat] = min(abs(lat_woa-target_lat));
an = squeeze(ncread(fname,[prefix,'_an'],[ilon ilat 1 1],[1 1 length(dep_woa) 1]));
sd = squeeze(ncread(fname,[prefix,'_sd'],[ilon ilat 1 1],[1 1 length(dep_woa) 1]));
if strcmp(precision,'native')   % as load_woa23_profile_8p6z.m (no conversion; depth single)
    val_out = uc*an; std_out = uc*sd; dep_out = -dep_woa;
else
    val_out = uc*double(an); std_out = uc*double(sd); dep_out = -double(dep_woa);
end
end
