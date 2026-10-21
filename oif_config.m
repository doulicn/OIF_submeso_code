function C = oif_config()
%OIF_CONFIG Paths and constants shared by all prep/ and plot/ scripts.
%
%   No file has to be edited on a new machine. The three external locations
%   are read from environment variables (set them before starting MATLAB, or
%   with setenv in the session before calling setup_paths):
%
%     OIF_MMAP_DIR   M_Map 1.4 folder (the one that contains m_proj.m). Needed
%                    only by the map figures, Fig. 1 and Figs. S3-S6, and not
%                    at all if M_Map is already on the MATLAB path.
%                    Default: external/m_map in this package.
%     OIF_GSW_DIR    TEOS-10 GSW toolbox folder. Needed only by
%                    prep/prep_validation.m. Default: external/gsw.
%     OIF_DATA_ROOT  Data root: the folder that contains ROMS/, noaa/, Iron/,
%                    MODIS/ and code_process/ with the intermediate model and
%                    observation products (laid out as on the authors' Box
%                    drive). Needed only by the prep/ scripts, which rebuild
%                    data/. Default: '' (not available).
%
%   The plot/ scripts read only C.data_dir and need neither GSW nor the data
%   root.

C.pkg_dir  = fileparts(mfilename('fullpath'));
C.data_dir = fullfile(C.pkg_dir, 'data');      % processed figure data (*.mat)
C.fig_dir  = fullfile(C.pkg_dir, 'figures');   % figure output (*.png, *.pdf)

% ---- external toolboxes (not redistributed) ------------------------------
% M_Map 1.4 (https://www.eoas.ubc.ca/~rich/map.html): Fig. 1, Figs. S3-S6
C.mmap_dir = env_or_default('OIF_MMAP_DIR', fullfile(C.pkg_dir, 'external', 'm_map'));
% TEOS-10 GSW toolbox (https://www.teos-10.org/software.htm), prep only
C.gsw_dir  = env_or_default('OIF_GSW_DIR', fullfile(C.pkg_dir, 'external', 'gsw'));

% ---- data root: intermediate model products (prep/ scripts only) ---------
% Folder with ROMS/, noaa/, Iron/, MODIS/ and code_process/, or '' when it
% is not available (the field keeps its historical name box_root). With an
% empty data root the paths below are relative and are not used by plot/.
C.box_root = getenv('OIF_DATA_ROOT');
C.roms_dir = fullfile(C.box_root, 'ROMS');

% ---- simulations ----------------------------------------------------------
% Control runs: 1 km (OSP-1KM), 4 km (NEPAC-4KM), 12 km (PACMED-12KM)
C.res_label = {'1KM', '4KM', '12KM'};
C.ctrl = {'OSP1KM_INI_BEC_V2_daily_diaT2_nw5', ...
          'NEPAC4KM_INI_BEC_V2_daily_diaT2', ...
          'PACMED12KM_INI_BEC_V2_param2_daily_diaT2'};
% 18 OIF experiments (rows: release; columns: 1/4/12 km)
C.exp_label = {'Jun_R1', 'May_R1', 'Jul_R1', 'Aug_R1', 'Jun_R2', 'Jun_R3'};
C.exp_month = [6 5 7 8 6 6];      % release month
C.exp_region = [1 1 1 1 2 3];     % release region R1/R2/R3
C.oif = { ...
  'OSP1KM_INI_BEC_V2_OIF_Jun_diaT2_nw5',      'NEPAC4KM_INI_BEC_V2_OIF_Jun_diaT',       'PACMED12KM_INI_BEC_V2_param2_OIF_Jun_diaT';
  'OSP1KM_INI_BEC_V2_OIF_May_diaT2_nw5',      'NEPAC4KM_INI_BEC_V2_OIF_May_diaT',       'PACMED12KM_INI_BEC_V2_param2_OIF_May_diaT';
  'OSP1KM_INI_BEC_V2_OIF_Jul_diaT2_nw5',      'NEPAC4KM_INI_BEC_V2_OIF_Jul_diaT',       'PACMED12KM_INI_BEC_V2_param2_OIF_Jul_diaT';
  'OSP1KM_INI_BEC_V2_OIF_Aug_diaT2_nw5',      'NEPAC4KM_INI_BEC_V2_OIF_Aug_diaT',       'PACMED12KM_INI_BEC_V2_param2_OIF_Aug_diaT';
  'OSP1KM_INI_BEC_V2_OIF_Jun_diaT2_nw5_reg2', 'NEPAC4KM_INI_BEC_V2_OIF_Jun_diaT2_reg2', 'PACMED12KM_INI_BEC_V2_param2_OIF_Jun_diaT_reg2';
  'OSP1KM_INI_BEC_V2_OIF_Jun_diaT2_nw5_reg3', 'NEPAC4KM_INI_BEC_V2_OIF_Jun_diaT2_reg3', 'PACMED12KM_INI_BEC_V2_param2_OIF_Jun_diaT_reg3'};

% Runs used only by the model evaluation and the coarse-graining diagnostics.
% Documentation only for now: prep/prep_validation.m and
% prep/prep_budgets_profiles_coarsegrain.m still name these runs themselves.
% Validation at Ocean Station Papa (Figs. S1, S2): full-year 1 and 4 km runs,
% the 12 km control run (= C.ctrl{3}) and a 25 km run
C.valid_label = {'1KM', '4KM', '12KM', '25KM'};
C.valid_runs  = {'OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear', ...
                 'NEPAC4KM_INI_BEC_V2_daily_diaT2_nw5_allyear', ...
                 'PACMED12KM_INI_BEC_V2_param2_daily_diaT2', ...
                 'PACMED25KM_INI_BEC_V2_param2'};
% Full-year 1 km control run of the coarse-graining diagnostics (Fig. S11 and
% the control panels of Fig. S12; the OIF panels of S12 use C.oif{1,1}, Case 1)
C.cg_ctrl = 'OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear';

% Model grids
C.grd = {fullfile(C.roms_dir, 'Work/OSP1KM/FORCINGS_nw5/ospnw5_grd.nc'), ...
         fullfile(C.roms_dir, 'Work/NEPAC/FORCINGS/nepac4km_grd.nc'), ...
         fullfile(C.roms_dir, 'Work/PACMED12KMnew/FORCINGS/pacmed12_grd_fixedMSK.nc')};
% Sub-domain (i,j) indices of the daily surface caches (region "Papa_extend2"
% in their file names) within the 1/4/12 km grids
C.indx = {15:715, 1:600, 890:1060};
C.indy = {15:1080, 800:1320, 760:950};

% ---- constants -----------------------------------------------------------
C.date_ref = datenum(1995,1,1);   % ROMS time origin (seconds since)
C.patch_threshold = 2e-5;           % fertilized patch: dFe > 2e-5 mmol m-3
C.osp = [215 50];                   % Ocean Station Papa (lon E, lat N)
% mmol C -> metric tons C: 12 g C per mol x 1e-3 mol per mmol x 1e-6 t per g
% (12 rather than 12.011 g/mol, i.e. rounded as in the published figures)
C.mmolC_to_tC = 1.2e-8;
% Analysis domain (dashed red polygon in the maps)
C.ana_lon = [210 220 218 208 210];
C.ana_lat = [46 48 58 55.5 46];
% Map extent of the patch maps
C.map_lon = [207 220.3];
C.map_lat = [45 59];
% Colours of the 1/4/12 km runs (cbrewer Dark2)
C.col_res   = [27 158 119; 217 95 2; 117 112 179]/255;
end

function v = env_or_default(name, default)
% Value of the environment variable NAME, or DEFAULT when it is unset or empty.
v = getenv(name);
if isempty(v); v = default; end
end
