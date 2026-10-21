%PLOT_FIGS10 Supporting Information Figure S10: Fe and DIC profiles and relative OIF anomalies.
%   LaTeX label fig:si_fe_dic_profiles; published file Fig_SI_Fe_DIC_profile.pdf.
%   Control Fe and DIC profiles (a) and relative OIF anomalies (b), Cases 1-3.
%   Domain-mean June-July profiles for the June R1 OIF runs at 1/4/12 km
%   (Cases 1-3 = C.oif(1,:)) and their controls (C.ctrl); lighter colours =
%   coarser resolution. Panel letters at the top right, as published.
%   Ported from PACMED12_Process_marbl_8p6z.m (plot_variables_profile_cmp_more, icomb 22).
%   Input:  data/profile_Fe_DIC.mat
%   Output: figures/FigS10.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
load(fullfile(C.data_dir, 'profile_Fe_DIC.mat'), 'prof');

Fe_color = [1 0 0]; DIC_color = [0 0 1]; fs = 10;
z = -prof.dep;
dFe  = (prof.Fe_oif  - prof.Fe_ctrl)  ./ prof.Fe_ctrl  * 100;
dDIC = (prof.DIC_oif - prof.DIC_ctrl) ./ prof.DIC_ctrl * 100;
nres = numel(prof.res_label);

fig = oif_figure('visible','off','units','centimeters','position',[2 2 20 9.5],'color','w');
pos = {[0.09 0.14 0.37 0.68], [0.59 0.14 0.37 0.68]};
xb = {prof.Fe_ctrl, dFe}; xt = {prof.DIC_ctrl, dDIC};
xlab_b = {'$\mathrm{Fe}_{control}\ (mmol\ m^{-3})$', '$\Delta \mathrm{Fe}/\mathrm{Fe}_{control}\times100\%$'};
xlab_t = {'$\mathrm{DIC}_{control}\ (mmol\ m^{-3})$', '$\Delta \mathrm{DIC}/\mathrm{DIC}_{control}\times100\%$'};
leg_loc = {'southwest','south'}; letters = {'(a)','(b)'};
for ip = 1:2
    % bottom axis: Fe
    ax1 = axes('Position', pos{ip}); hold(ax1,'on');
    for i = 1:nres
        plot(ax1, xb{ip}(:,i), z, 'Color', [Fe_color, 1/i], 'LineWidth', 2);
    end
    if ip == 2; xline(ax1, 0, '--', 'Color', Fe_color, 'LineWidth', 1, 'HandleVisibility','off'); end
    set(ax1, 'XColor', Fe_color, 'YColor', 'k', 'Box', 'off', 'FontSize', fs, 'TickLabelInterpreter', 'latex');
    xlabel(ax1, xlab_b{ip}, 'Color', Fe_color, 'Interpreter', 'latex', 'FontSize', fs);
    ylabel(ax1, 'Depth (m)', 'FontSize', fs);
    ylim(ax1, [-200 0]); grid(ax1, 'on'); yticks(ax1, -200:50:0);
    legend(ax1, prof.res_label, 'Location', leg_loc{ip});
    % top axis: DIC
    ax2 = axes('Position', pos{ip}, 'XAxisLocation','top', 'YAxisLocation','right', 'Color','none', ...
        'XColor', DIC_color, 'YColor','none', 'Box','off', 'FontSize', fs, 'TickLabelInterpreter','latex');
    hold(ax2,'on');
    for i = 1:nres
        line(ax2, xt{ip}(:,i), z, 'Color', [DIC_color, 1/i], 'LineWidth', 2);
    end
    if ip == 2; xline(ax2, 0, '--', 'Color', DIC_color, 'LineWidth', 1); end
    xlabel(ax2, xlab_t{ip}, 'Color', DIC_color, 'Interpreter', 'latex', 'FontSize', fs);
    ylim(ax2, [-200 0]); linkaxes([ax1 ax2], 'y'); grid(ax2, 'on'); yticks(ax2, -200:50:0);
    text(ax1, 0.97, 0.97, letters{ip}, 'Units','normalized', 'HorizontalAlignment','right', ...
        'VerticalAlignment','top', 'FontSize', fs+2);
end

exportgraphics(fig, fullfile(C.fig_dir, 'FigS10.png'), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir, 'FigS10.pdf'), 'ContentType', 'vector');
close(fig);
fprintf('FigS10 written.\n');
