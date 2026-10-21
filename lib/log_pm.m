function [log_data, minmax, tick_pos, tick_label] = log_pm(data, order_min, order_max)
%LOG_PM  Signed logarithmic scaling of data of both signs, with colorbar ticks.
%
%   [log_data, minmax, tick_pos, tick_label] = log_pm(data, order_min, order_max)
%
%   Maps magnitudes between 10^order_min and 10^order_max onto a logarithmic
%   axis that is symmetric about zero:
%
%       log_data = sign(data) .* (log10(|data|) - order_min)
%
%   with |data| limited to [10^order_min, 10^order_max]. Values with
%   |data| < 10^order_min, zeros and NaNs map to (numerically) zero; +-Inf
%   map to the limits. Computed as the sum of a positive-branch term
%   log10(min(max(data,cmin),cmax)) - order_min and a negative-branch term
%   -log10(-max(min(data,-cmin),-cmax)) + order_min (cmin = 10^order_min,
%   cmax = 10^order_max), each set to 0 where data is NaN.
%
%   minmax      [min(tick_pos) max(tick_pos)], i.e. +-floor(order_max - order_min)
%               (+-(order_max - order_min) for whole decades, as used here)
%   tick_pos    colorbar tick positions (row) at +-j*10^d, j = 1..9, for each
%               decade d = order_min, ..., order_max-1, and at +-10^order_max
%   tick_label  cell array of labels: '10^{d}' / '-10^{d}' at the decades,
%               '\pm10^{order_min}' at the centre, '' elsewhere
%
%   Written for this package with built-in MATLAB functions. It has the
%   name and interface of a helper used in the original analysis, whose
%   author and license are unknown, contains none of its code, and
%   reproduces its outputs exactly (checked before release). Used by
%   lib/plot_log_contour.m (Figs. S11 and S12).

nd = floor(order_max - order_min);          % number of whole decades shown
if ~(nd >= 1)
    error('log_pm:range', 'order_max must exceed order_min by at least one decade.');
end

% ---- ticks ------------------------------------------------------------------
decades = order_min + (1:nd) - 1;            % 1 x nd
vals = (1:9)' .* 10.^decades;                % 9 x nd: j*10^d, decade by decade
vals = [vals(:); 10 * 10^decades(end)].';    % ... followed by 10^order_max
pos = log10(vals) - order_min;               % 0 .. (order_max - order_min)

lab_pos = repmat({''}, 1, numel(vals));
lab_neg = lab_pos;
first_of_decade = 1 + 9*(0:nd-1);
for q = 1:nd
    lab_pos{first_of_decade(q)} = ['10^{' num2str(decades(q)) '}'];
    lab_neg{first_of_decade(q)} = ['-10^{' num2str(decades(q)) '}'];
end
lab_pos{end} = ['10^{' num2str(decades(end) + 1) '}'];
lab_neg{end} = ['-10^{' num2str(decades(end) + 1) '}'];
lab_neg{1}   = ['\pm10^{' num2str(decades(1)) '}'];

% negative side (mirrored, largest magnitude first), shared centre, positive side
tick_pos   = [-fliplr(pos), pos(2:end)];
tick_label = [fliplr(lab_neg), lab_pos(2:end)];
minmax = [min(tick_pos), max(tick_pos)];

% ---- data -------------------------------------------------------------------
cmin = 10^order_min;
cmax = 10^order_max;
isn = isnan(data);
lp = log10(min(max(data, cmin), cmax)) - order_min;      % positive branch
ln = -log10(-max(min(data, -cmin), -cmax)) + order_min;  % negative branch
lp(isn) = 0;
ln(isn) = 0;
log_data = ln + lp;
end
