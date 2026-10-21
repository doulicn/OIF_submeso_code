function [h, nhit] = add_skew_text(ax, skew, colors, varargin)
%ADD_SKEW_TEXT Block of 'skew=' labels placed where it covers the fewest curve points.
%   [h, nhit] = add_skew_text(ax, skew, colors, Name, Value, ...)
%   skew   : skewness values, one text line each, top to bottom (NaN: no line)
%   colors : matching colours, n x 3 matrix or cell array of RGB triplets
%   Name, Value : further text properties (e.g. 'FontSize', 9)
%   h      : text handles; nhit : number of curve points under the block
%
%   The left-aligned block is put at the best of 25 x 25 candidate positions
%   (x, y) of its top-left corner: the one whose box (with a 0.02 margin)
%   contains the fewest points of the line objects in AX (each segment
%   sampled every 0.005 in normalized axes units, log axes in log space) and
%   does not overlap the legend. Among equal counts, high and then right
%   positions are preferred (score = count + 0.01*(1-y) + 0.001*(1-x)).
%   Call it once the axis limits, labels and legend are final.
%   Port of add_skew_text in calculate_roms_surface_diagnostic_period_pdfs.m
%   (Fig. 1c-e).
oif_drawnow;                            % final axis limits and legend layout
if ~iscell(colors); colors = num2cell(colors, 2); end
h = gobjects(0);
for j = 1:numel(skew)
    if ~isfinite(skew(j)); continue; end
    h(end+1) = text(ax, 0, 0, sprintf('skew=%.2f', skew(j)), 'Units','normalized', ...
        'HorizontalAlignment','left', 'VerticalAlignment','top', 'Color',colors{j}, varargin{:}); %#ok<AGROW>
end
nhit = 0;
if isempty(h); return; end
ext = vertcat(h.Extent);                % [x y w h], normalized axes units
lineH = max(ext(:,4)); boxW = max(ext(:,3)); boxH = lineH*numel(h);

% points of the plotted lines in normalized axes units
xl = ax.XLim; yl = ax.YLim;
logx = strcmp(ax.XScale,'log'); logy = strcmp(ax.YScale,'log');
if logx; xl = log10(xl); end
if logy; yl = log10(yl); end
pts = cell(1,0);
hl = findobj(ax, 'Type','line');
for il = 1:numel(hl)
    xd = double(hl(il).XData(:)); yd = double(hl(il).YData(:));
    if logx; xd(xd <= 0) = NaN; xd = log10(xd); end
    if logy; yd(yd <= 0) = NaN; yd = log10(yd); end
    xn = (xd - xl(1))/diff(xl); yn = (yd - yl(1))/diff(yl);
    for ip = 1:numel(xn)-1                % densify the segments
        if ~all(isfinite([xn(ip) xn(ip+1) yn(ip) yn(ip+1)])); continue; end
        t = linspace(0, 1, max(2, ceil(hypot(xn(ip+1)-xn(ip), yn(ip+1)-yn(ip))/0.005)));
        pts{end+1} = [xn(ip) + t*(xn(ip+1)-xn(ip)); yn(ip) + t*(yn(ip+1)-yn(ip))]; %#ok<AGROW>
    end
end
pts = [zeros(2,0), pts{:}];

% legend box in normalized axes units
leg = [];
lg = ax.Legend;
if ~isempty(lg) && isvalid(lg) && strcmp(lg.Visible, 'on')
    pa = getpixelposition(ax, true); pl = getpixelposition(lg, true);
    leg = [(pl(1)-pa(1))/pa(3), (pl(2)-pa(2))/pa(4), pl(3)/pa(3), pl(4)/pa(4)];
end

% least-overlap search over the top-left corner of the block
gap = 0.02;
xc = linspace(gap, max(gap, 1 - boxW - gap), 25);
yc = linspace(1 - gap, min(1 - gap, boxH + gap), 25);
best = inf; bx = xc(end); by = yc(1);
for x0 = xc
    for y0 = yc
        b = [x0 - gap, x0 + boxW + gap, y0 - boxH - gap, y0 + gap];     % x0 x1 y0 y1
        n = sum(pts(1,:) >= b(1) & pts(1,:) <= b(2) & pts(2,:) >= b(3) & pts(2,:) <= b(4));
        if ~isempty(leg) && b(1) < leg(1)+leg(3) && b(2) > leg(1) && b(3) < leg(2)+leg(4) && b(4) > leg(2)
            n = n + 1e6;                % never cover the legend
        end
        score = n + 0.01*(1 - y0) + 0.001*(1 - x0);
        if score < best
            best = score; bx = x0; by = y0; nhit = n;
        end
    end
end
for j = 1:numel(h)
    h(j).Position = [bx, by - (j-1)*lineH, 0];
end
end
