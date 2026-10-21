function C = setup_paths()
%SETUP_PATHS Add the package folders and external toolboxes to the MATLAB path.
%
%   C = setup_paths() adds the package root, lib/, plot/, prep/ and tables/,
%   then M_Map (map figures) and the GSW toolbox (prep_validation only) when
%   they are found, creates figures/ and data/ if missing, and returns the
%   configuration of oif_config.m. External locations: see oif_config.m.
C = oif_config();
tab_dir = fullfile(C.pkg_dir, 'tables');
if ~isfolder(tab_dir); mkdir(tab_dir); end
addpath(C.pkg_dir, fullfile(C.pkg_dir, 'lib'), fullfile(C.pkg_dir, 'plot'), ...
        fullfile(C.pkg_dir, 'prep'), tab_dir);
% M_Map: a copy that is already on the path is used as it is
if exist('m_proj', 'file') == 2
    % nothing to do
elseif isfile(fullfile(C.mmap_dir, 'm_proj.m'))
    addpath(C.mmap_dir);
else
    warning('OIF:noMMap', ['M_Map not found (not on the MATLAB path, and no m_proj.m in %s). ' ...
        'Fig. 1 and Figs. S3-S6 (plot_fig1, plot_figS3, plot_figS4, plot_figS5_S6) need it: ' ...
        'set the environment variable OIF_MMAP_DIR to the M_Map folder, or put M_Map ' ...
        'into external/m_map in the package.'], C.mmap_dir);
end
% TEOS-10 GSW: only prep_validation uses it (and checks for it itself)
if isfolder(C.gsw_dir)
    addpath(genpath(C.gsw_dir));
end
if ~isfolder(C.fig_dir); mkdir(C.fig_dir); end
if ~isfolder(C.data_dir); mkdir(C.data_dir); end
end
