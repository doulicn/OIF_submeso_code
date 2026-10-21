function c = redblue(m)
%REDBLUE  Blue-white-red diverging colormap.
%
%   c = redblue(m) returns an m x 3 colormap that runs linearly from pure
%   blue [0 0 1] to white and then to pure red [1 0 0]. For even m the two
%   halves have m/2 entries each and both end in white; for odd m the middle
%   entry is white and each side ramps over (m-1)/2 entries towards it.
%   c = redblue uses the length of the current figure's colormap.
%
%   Written for this package with built-in MATLAB functions; equivalent to
%   the File Exchange function redblue by A. Auton (File Exchange 25536),
%   whose output it reproduces exactly (checked before release), but
%   contains none of its code. Used by plot/plot_figS3.m.

if nargin < 1
    m = size(get(gcf, 'colormap'), 1);
end
half = floor(m/2);                     % entries on each side of the centre
if mod(m, 2) == 0
    t = (0:half-1)' / max(half-1, 1);  % 0 (saturated) ... 1 (white)
    centre = zeros(0, 3);
else
    t = (0:half-1)' / max(half, 1);    % 0 ... (half-1)/half, centre is white
    centre = [1 1 1];
end
blue_side = [t, t, ones(half, 1)];
red_side  = flipud([ones(half, 1), t, t]);
c = [blue_side; centre; red_side];
end
