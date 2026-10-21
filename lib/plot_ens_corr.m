function plot_ens_corr(ax, c, S, msize, fs)
%PLOT_ENS_CORR Scatter of the 18 runs with linear fit and Pearson R, p.
%   plot_ens_corr(ax, c, S, msize, fs)
%   c : struct with x, y (18 x 1), fit_coef (polyfit order 1), R, P
%   S : oif_ens_style(E); msize : scatter size (points^2), default S.msize
%   Runs with NaN x or y are not drawn (with a warning).
if nargin < 4 || isempty(msize); msize = S.msize; end
if nargin < 5; fs = 8; end
hold(ax, 'on');
bad = isnan(c.x(:)) | isnan(c.y(:));
if any(bad)
    warning('OIF:nanIgnored', 'plot_ens_corr: run(s) %s with NaN x or y not drawn.', mat2str(find(bad)'));
end
for i = 1:numel(c.x)
    if bad(i); continue; end
    scatter(ax, c.x(i), c.y(i), msize, S.marker{i}, 'MarkerEdgeColor','k', 'MarkerFaceColor', S.color(i,:), ...
        'HandleVisibility','off');
end
ok = ~bad;
xf = linspace(min(c.x(ok)), max(c.x(ok)), 50);
plot(ax, xf, polyval(c.fit_coef, xf), 'k--', 'LineWidth', 1.5, 'HandleVisibility','off');
text(ax, 0.05, 0.93, {sprintf('R = %.2f', c.R), sprintf('p = %.3f', c.P)}, 'Units','normalized', ...
    'FontSize', fs, 'FontWeight','bold', 'VerticalAlignment','top');
grid(ax, 'on'); box(ax, 'on');
end
