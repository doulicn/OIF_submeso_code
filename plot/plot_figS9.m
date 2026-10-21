%PLOT_FIGS9 Supporting Information Figure S9: ensemble comparison of Fe and DIC budgets.
%   LaTeX label fig:si_ens_budget_groups; published file Fig_ens_budget_groups.pdf.
%   (a,c) Fe and (b,d) DIC budget terms.
%   (a,b) ensemble mean +/- std for the 1-, 4- and 12-km simulations;
%   (c,d) All (n=18), R1 release (n=12) and June release (n=9) groups.
%   Numbers: group-mean term / group-mean surface flux term.
%   Ported from PACMED12_Process_budget.m (by-resolution block and grouped
%   block of icomb 31).
%
%   Size and fonts: the published figure is a 621 x 312 pt composite of four
%   separately exported panels; this figure reproduces their axes size
%   (9.8 x 4.1 cm), spacing and font sizes (axes 9 pt, legend 7.2 pt,
%   numbers 5.4 pt, panel letters 13 pt). Two layout changes avoid overlaps
%   of the published panels: where numbers reach below the x-axis (Fe UPTAKE
%   in a,c) the tick labels start 6 pt instead of 2 pt below the axis, and
%   the legends sit in the lower-left corner, below the BIO numbers.
%   As in the published figure (and the original code): panel (b) is
%   annotated 'b = dBudget/dDIC_FLUX^surf' while the caption defines 'a' for
%   both tracers (known caption difference); only the imposed Fe surface flux
%   has no error bar and number (the DIC surface flux keeps its spread and
%   1.00); the surface-flux tick labels are black (purple in Fig. 5).
%   Legend n: members with data in each group; a warning is issued if a
%   group misses term values.
%   Input:  data/budget_ensemble.mat
%   Output: figures/FigS9.png/.pdf

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
load(fullfile(C.data_dir, 'budget_ensemble.mat'), 'budget');
for tr = {'Fe','DIC'}
    if ~any(isfinite(budget.(tr{1}).diff(:)))
        error('OIF:FigS9:noData', '%s budget in budget_ensemble.mat has no finite values', tr{1});
    end
end

fs = 9;
% 2 x 2 axes of 9.77 x 4.12 cm with the spacing of the published composite
fig = oif_figure('visible','off','units','centimeters','position',[2 2 22.4 11.5],'color','w');
W = 9.77/22.4; Hh = 4.124/11.5; xl = [1.326 12.377]/22.4; yb = [6.727 1.308]/11.5;
pos = {[xl(1) yb(1) W Hh], [xl(1) yb(2) W Hh], [xl(2) yb(1) W Hh], [xl(2) yb(2) W Hh]};
letters = {'(a)','(b)','(c)','(d)'};
tr_list = {'Fe','DIC','Fe','DIC'};

% groups for (a,b): resolution
res_names = {'1KM','4KM','12KM'};
res_idx = arrayfun(@(r) find(budget.run_res == r), 1:3, 'UniformOutput', false);
res_colors = C.col_res;               % cbrewer Dark2, as in Figs. 2 and S7
% groups for (c,d): All / R1 release / June release
lab = budget.run_label;
grp_names = {'All','R1 release','June release'};
grp_idx = {1:numel(lab), find(~contains(lab,'_R2') & ~contains(lab,'_R3')), find(contains(lab,'Jun'))};
grp_colors = [0.25 0.25 0.25; 0.8500 0.3250 0.0980; 0 0.4470 0.7410];

for ip = 1:4
    T = budget.(tr_list{ip});
    is_fe = strcmp(tr_list{ip}, 'Fe');
    if ip <= 2
        gidx = res_idx; gcol = res_colors; gname = res_names;
    else
        gidx = grp_idx; gcol = grp_colors; gname = grp_names;
    end
    nv = size(T.diff,1); ng = numel(gidx); x_b = 1:nv;
    gmean = nan(nv,ng); gstd = nan(nv,ng); gn = zeros(1,ng);
    for ig = 1:ng
        gmean(:,ig) = mean(T.diff(:,gidx{ig}), 2, 'omitnan');
        gstd(:,ig)  = std(T.diff(:,gidx{ig}), 0, 2, 'omitnan');
        has = isfinite(T.diff(:,gidx{ig}));
        gn(ig) = sum(any(has,1));                % members with data
        if ~all(has(:))
            warning('OIF:FigS9:missingMembers', ['%s, %s: %d of %d members have data; ' ...
                '%d term value(s) missing, left out of the means'], ...
                tr_list{ip}, gname{ig}, gn(ig), numel(gidx{ig}), nnz(~has));
        end
    end
    if ip > 2
        gname = arrayfun(@(ig) sprintf('%s (n=%d)', gname{ig}, gn(ig)), 1:ng, 'UniformOutput', false);
    end
    is_surf = contains(T.label,'FLUX') & contains(T.label,'surf');
    iref = find(is_surf, 1);
    hide_row = false(nv,1);
    if is_fe; hide_row = is_surf(:); end       % imposed Fe flux: no error bar / ratio label
    std_show = gstd; std_show(hide_row,:) = nan;
    ratio = gmean ./ gmean(iref,:);

    ax = axes('position', pos{ip}); hold on;
    hb = bar(x_b, gmean, 0.7, 'grouped');
    for ig = 1:ng
        hb(ig).FaceColor = gcol(ig,:); hb(ig).EdgeColor = 'none'; hb(ig).DisplayName = gname{ig};
    end
    hr = gobjects(0);                          % ratio labels
    for ig = 1:ng
        xg = hb(ig).XEndPoints;
        errorbar(xg, gmean(:,ig), std_show(:,ig), 'k', 'LineStyle','none','LineWidth',0.5, ...
            'CapSize',4,'HandleVisibility','off');
        for i = 1:nv
            if isfinite(ratio(i,ig)) && ~hide_row(i)
                s = gstd(i,ig); if ~isfinite(s); s = 0; end
                ypos = gmean(i,ig) + sign(gmean(i,ig))*(s + 0.15*max(abs(gmean(:))));
                hr(end+1) = text(xg(i), ypos, sprintf('%.2f', ratio(i,ig)), 'HorizontalAlignment','center', ...
                    'FontSize',fs*0.6,'Color',gcol(ig,:),'Rotation',60); %#ok<SAGROW>
            end
        end
    end
    yl = ylim; ymax = max(abs(yl));
    nice = [1 2 5 10]*10^floor(log10(ymax)); ymax = nice(find(nice >= ymax*0.999, 1)); ylim([-ymax ymax]);
    if ip == 2
        alab = 'b';          % original label of the by-resolution DIC panel
    else
        alab = 'a';
    end
    % \displaystyle: display-size fraction also in the vector PDF (as in the PNG)
    text(1, ymax*0.75, ['$\displaystyle ' alab ' = \frac{\mathrm{\Delta Budget}}{\Delta ' ...
        strip(T.label{iref}, 'both', '$') '}$'], 'Interpreter','latex','FontSize',fs,'Color','k');
    xline(4.5, '--k', 'LineWidth', 1.5, 'HandleVisibility','off');
    xlim([0.5 nv+0.5]); xticks(x_b);
    grid on; box on; set(ax,'fontsize',fs);
    if is_fe
        lg = legend(hb, 'Location','southwest','Interpreter','none','FontSize',fs*0.8,'Box','off');
        oif_drawnow;   % legend layout final before the move (else the first run of a session differs)
        lg.Position(1:2) = ax.Position(1:2) + [0 0.005];   % in the corner, below the BIO numbers
    end
    % tick labels 6 pt (0.05) instead of 2 pt below the axis where ratio
    % numbers reach below it (Fe UPTAKE), so that the two do not overlap
    tick_top = -0.02;
    if ~isempty(hr)
        set(hr, 'Units','normalized'); ext = vertcat(hr.Extent); set(hr, 'Units','data');
        if any(ext(:,2) < tick_top); tick_top = -0.05; end
    end
    color_budget_xticklabels(ax, T.label, [], tick_top);   % blue: physical terms, green: biological terms
    ylabel(['Integrated Difference in ' T.name ' (mmol)'], 'Interpreter','latex');
    text(0.98, 0.985, letters{ip}, 'Units','normalized','HorizontalAlignment','right', ...
        'VerticalAlignment','top','FontSize',fs+4);

    fprintf('\nPanel %s (%s): term / surface flux per group (%s)\n', letters{ip}, tr_list{ip}, strjoin(gname, ', '));
    for i = 1:nv
        fprintf('  %-28s %s\n', T.label{i}, sprintf('%8.2f', ratio(i,:)));
    end
end

exportgraphics(fig, fullfile(C.fig_dir, 'FigS9.png'), 'Resolution', 400);
exportgraphics(fig, fullfile(C.fig_dir, 'FigS9.pdf'), 'ContentType', 'vector');
close(fig);
