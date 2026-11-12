function make_all_figures(rebuild_data)
%MAKE_ALL_FIGURES Regenerate all manuscript and Supporting Information figures.
%
%   make_all_figures         % plot from the processed data in data/
%   make_all_figures(true)   % first rebuild data/ from the intermediate model
%                            % products (needs the data root: environment
%                            % variable OIF_DATA_ROOT, see oif_config.m)
%
%   The plot scripts read only data/ and write PNG and PDF files to figures/,
%   numbered as in the compiled manuscript (Fig1-Fig4, FigS1-FigS13);
%   make_table_S1 then builds Table S1. Each script runs in its own
%   workspace. A script that fails is reported and the others still run,
%   except after a failed prep script: then the plot scripts and
%   make_table_S1 are skipped, so that no figure or table is made from a
%   partly rebuilt data/. The run ends with a summary and, if any script
%   failed, with an error that lists the failed scripts (so that
%   matlab -batch exits with a non-zero status). Only the figures that a
%   script creates are closed afterwards.

if nargin < 1; rebuild_data = false; end
C = oif_config();
if rebuild_data && (isempty(C.box_root) || ~isfolder(C.box_root))
    error('OIF:noDataRoot', ['make_all_figures(true) rebuilds data/ from the intermediate ' ...
        'products and needs the data root, the folder that contains ROMS/, noaa/, Iron/, ' ...
        'MODIS/ and code_process/. Set the environment variable OIF_DATA_ROOT to that ' ...
        'folder (current value: ''%s''), or call make_all_figures without argument to ' ...
        'plot from the data/ files.'], C.box_root);
end
C = setup_paths();
% setup_paths has warned once if M_Map is missing; do not repeat it for
% every script (the map scripts are reported in the summary instead)
ws = warning('off', 'OIF:noMMap');
restore_ws = onCleanup(@() warning(ws));

steps = {};
if rebuild_data
    steps = {'prep_validation', ...                    % Figs. S1, S2
             'prep_maps', ...                          % Figs. 1, S3-S6
             'prep_timeseries_ensemble', ...           % Figs. 2, 3, S7, S9, Table S1
             'prep_ensemble_mld', ...                  % Fig. S9e,f (after prep_timeseries_ensemble)
             'prep_nutrient_limitation', ...           % Fig. S8
             'prep_budgets_profiles_coarsegrain'};     % Figs. 4, S10-S13
end
nprep = numel(steps);
steps = [steps, ...
    {'plot_fig1', 'plot_fig2', 'plot_fig3', 'plot_fig4', ...                    % Figures 1-4
     'plot_figS1', 'plot_figS2', 'plot_figS3', 'plot_figS4', ...               % Figures S1-S4
     'plot_figS5_S6', ...                                                      % Figures S5, S6
     'plot_figS7', 'plot_figS8', 'plot_figS9', 'plot_figS10', 'plot_figS11', ... % Figures S7-S13
     'plot_figS12', 'plot_figS13', ...
     'make_table_S1'}];                                                        % Table S1

n = numel(steps);
ok = false(1, n); dt = zeros(1, n); why = cell(1, n); skipped = false(1, n);
t_all = tic;
for k = 1:n
    [ok(k), dt(k), why{k}] = run_one(steps{k});
    if k == nprep && ~all(ok(1:nprep))
        skipped(k+1:n) = true;          % no figures from a partly rebuilt data/
        break
    end
end

fprintf('\n==== make_all_figures: summary (%.1f s) ====\n', toc(t_all));
for k = 1:n
    if ok(k)
        fprintf('  %-34s ok      %6.1f s\n', steps{k}, dt(k));
    elseif skipped(k)
        fprintf('  %-34s skipped (a prep script failed)\n', steps{k});
    else
        fprintf('  %-34s FAILED  %6.1f s   %s\n', steps{k}, dt(k), why{k});
    end
end
failed = ~ok & ~skipped;
if any(failed)
    msg = sprintf('%d of %d scripts failed: %s', nnz(failed), n, strjoin(steps(failed), ', '));
    if any(skipped)
        msg = sprintf('%s; the %d plot and table scripts were skipped', msg, nnz(skipped));
    end
    error('OIF:makeAllFigures', '%s', msg);
end
fprintf('All figures written to %s; Table S1 written to %s\n', C.fig_dir, ...
    fullfile(C.pkg_dir, 'tables'));
end

function [ok, dt, why] = run_one(name)
% Run one script, report (but do not rethrow) its error, and close only the
% figures it created (figures that were already open are left alone).
fprintf('\n--- %s\n', name);
figs0 = findall(groot, 'Type', 'figure');
t0 = tic; ok = true; why = '';
try
    run_isolated(name);
catch ME
    ok = false;
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    why = strtok(ME.message, newline);
    if strcmp(ME.identifier, 'MATLAB:UndefinedFunction') && contains(ME.message, '''m_') ...
            && exist('m_proj', 'file') ~= 2
        why = ['M_Map not found: set OIF_MMAP_DIR to the M_Map folder, or put M_Map ' ...
               'into external/m_map (see oif_config.m)'];
        fprintf('%s needs M_Map (Fig. 1 and Figs. S3-S6). %s.\n', name, why);
    end
end
dt = toc(t0);
figs = findall(groot, 'Type', 'figure');
close(figs(~ismember(figs, figs0)));
if ok
    fprintf('--- %s done (%.1f s)\n', name, dt);
else
    fprintf('--- %s FAILED (%.1f s)\n', name, dt);
end
end

function run_isolated(script_name)
% Run a script in the workspace of this function, so that scripts cannot
% overwrite each other's variables or those of the caller.
run(script_name);
end
