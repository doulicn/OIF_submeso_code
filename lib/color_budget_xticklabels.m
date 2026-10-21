function color_budget_xticklabels(ax, labels, surf_color, label_top)
% Color Fe/DIC budget tick labels (physical terms blue, biological terms green)
% while keeping the LaTeX font. The latex interpreter cannot color part of a
% tick label, so the tick labels are hidden and redrawn as latex text objects
% (normalized units, so later ylim changes do not move them; font size follows
% the axes through a listener).
% Optional surf_color colors the surface-flux term (e.g. Fe^{surf}_{FLUX}); default black.
% Optional label_top: normalized y of the top of the labels (default -0.02, just
% below the x-axis); a lower value leaves room for annotations below the axis.
if nargin < 3; surf_color = []; end
if nargin < 4 || isempty(label_top); label_top = -0.02; end
labels = cellstr(labels);
ax.TickLabelInterpreter = 'latex';
is_budget = all(cellfun(@(s) ~isempty(regexp(s,'^\$\\mathrm\{(Fe|DIC)\}','once')), labels));
if ~is_budget
    xticklabels(ax, labels);
    return
end
xticklabels(ax, labels);          % let MATLAB pick the label rotation first
oif_drawnow;
label_rot = ax.XTickLabelRotation;
xt = ax.XTick;
ax.XLim = ax.XLim;                % freeze x-limits so label positions stay valid
xticklabels(ax, repmat({''}, size(xt)));
if label_rot == 0
    halign = 'center';
else
    halign = 'right';
end
label_cols = budget_label_colors(labels, surf_color);
h = gobjects(numel(xt),1);
for k = 1:min(numel(xt), numel(labels))
    col = label_cols(k,:);
    xn = (xt(k) - ax.XLim(1)) / diff(ax.XLim);
    h(k) = text(ax, xn, label_top, labels{k}, 'Units', 'normalized', 'Interpreter', 'latex', ...
        'Color', col, 'FontSize', ax.FontSize, 'Rotation', label_rot, ...
        'HorizontalAlignment', halign, 'VerticalAlignment', 'top', 'Clipping', 'off');
end
h = h(isgraphics(h));
addlistener(ax, 'FontSize', 'PostSet', @(~,~) set(h(isgraphics(h)), 'FontSize', ax.FontSize));
end
