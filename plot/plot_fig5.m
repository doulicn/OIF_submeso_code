%PLOT_FIG5 Manuscript Figure 5: ensemble-mean OIF-induced changes in the Fe and DIC budgets.
%   LaTeX label fig:budget_cmp; published file Fig3_ens_budget.pdf (pre-revision
%   number in the file name).
%   Panels: (a) Fe budget, (b) DIC budget.
%   Bars: ensemble mean (n = 18) of the OIF-control budget anomaly integrated over
%   the upper 50 m, the analysis domain and the two-month analysis window.
%   Error bars: +/-1 standard deviation across the 18 experiments (not defined
%   in the caption). Numbers: mean +/- std normalised by the surface flux term
%   (Fe: imposed surface Fe flux; DIC: air-sea CO2 flux, positive into the
%   ocean). As in the published figure (and the original code), both surface
%   flux terms are drawn without error bar and number, although only the Fe
%   flux is imposed; the spread of the CO2 flux (std/mean = 0.45, printed below)
%   is shown in Fig. S9 (b,d).
%   Ported from PACMED12_Process_budget.m (icomb 31, iplot_type 2).
%   Input:  data/budget_ensemble.mat (from prep/prep_budgets_profiles_coarsegrain.m)
%   Output: figures/Fig5.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
load(fullfile(C.data_dir, 'budget_ensemble.mat'), 'budget');
tr_list = {'Fe','DIC'}; letters = {'(a)','(b)'};
for ip = 1:2
    if ~any(isfinite(budget.(tr_list{ip}).diff(:)))
        error('OIF:Fig5:noData', '%s budget in budget_ensemble.mat has no finite values', tr_list{ip});
    end
end

fs = 10;                                   % axis font size
surf_color = [0.4940 0.1840 0.5560];       % purple for the surface-flux term
fig = oif_figure('visible','off','units','centimeters','position',[2 2 17 18],'color','w');
pos = {[0.13 0.585 0.84 0.37], [0.13 0.085 0.84 0.37]};
for ip = 1:2
    T = budget.(tr_list{ip});
    bar_data = T.diff;                     % term x run
    nv = size(bar_data,1); x_b = 1:nv;
    ens_mean = mean(bar_data, 2, 'omitnan');
    ens_std  = std(bar_data, 0, 2, 'omitnan');
    if ~all(isfinite(bar_data(:)))
        warning('OIF:Fig5:missingMembers', '%s: %d term value(s) missing, left out of the means', ...
            tr_list{ip}, nnz(~isfinite(bar_data)));
    end
    is_surf = contains(T.label,'FLUX') & contains(T.label,'surf');
    iref = find(is_surf, 1);
    hide_row = is_surf(:);                 % no error bar / ratio label for the surface flux itself
    std_show = ens_std; std_show(hide_row) = nan;

    ax = axes('position', pos{ip}); hold on;
    bar(x_b, ens_mean, 0.5, 'FaceColor','flat', 'CData', budget_label_colors(T.label, surf_color), 'EdgeColor','none');
    errorbar(x_b, ens_mean, std_show, 'k', 'LineStyle','none','LineWidth',0.5,'CapSize',4);
    bar_ratio = ens_mean ./ ens_mean(iref);
    for i = 1:nv
        if isfinite(bar_ratio(i)) && ~hide_row(i)
            s = ens_std(i); if ~isfinite(s); s = 0; end
            ypos = ens_mean(i) + sign(ens_mean(i))*(s + 0.15*max(abs(ens_mean)));
            text(x_b(i), ypos, sprintf('%.2f\\pm%.2f', bar_ratio(i), ens_std(i)/abs(ens_mean(iref))), ...
                'HorizontalAlignment','center','FontSize',fs*0.7,'Color','k');
        end
    end
    yl = ylim; ymax = max(abs(yl));
    % symmetric limits rounded up to 1/2/5 x 10^n (the coarse auto-limits of the original small panels)
    nice = [1 2 5 10]*10^floor(log10(ymax)); ymax = nice(find(nice >= ymax*0.999, 1)); ylim([-ymax ymax]);
    yticks(-ymax:ymax/2:ymax);             % as published: -2:1:2 x 1e9 (Fe), -1:0.5:1 x 1e14 (DIC)
    % \displaystyle: display-size fraction also in the vector PDF (as in the PNG)
    text(1, ymax*0.75, ['$\displaystyle a = \frac{\mathrm{\Delta Budget}}{\Delta ' ...
        strip(T.label{iref}, 'both', '$') '}$'], 'Interpreter','latex','FontSize',fs+1,'Color','k');
    xline(4.5, '--k', 'LineWidth', 1.5);
    xlim([0.5 nv+0.5]); xticks(x_b);
    grid on; box on; set(ax,'fontsize',fs);
    color_budget_xticklabels(ax, T.label, surf_color);  % blue: physical, green: biological, purple: surface flux
    ylabel(['Integrated Difference in ' T.name ' (mmol)'], 'Interpreter','latex');
    text(0.985, 0.96, letters{ip}, 'Units','normalized','HorizontalAlignment','right', ...
        'VerticalAlignment','top','FontSize',fs+2);
    % print the numbers used in the manuscript text
    fprintf('\n%s budget (n=%d): term, mean/surf, std/surf\n', tr_list{ip}, sum(any(isfinite(bar_data),1)));
    for i = 1:nv
        fprintf('  %-28s %8.2f %8.2f\n', T.label{i}, bar_ratio(i), ens_std(i)/abs(ens_mean(iref)));
    end
end

% The PNG is exported twice: in a fresh MATLAB session the first export can
% come out a few pixels smaller (the PDF is not affected).
exportgraphics(fig, fullfile(C.fig_dir, 'Fig5.png'), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir, 'Fig5.png'), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir, 'Fig5.pdf'), 'ContentType', 'vector');
close(fig);
