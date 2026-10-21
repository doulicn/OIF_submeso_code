function [xf, yf] = oif_ax2fig(ax, x, y)
%OIF_AX2FIG Convert data coordinates of axes AX to normalized figure units.
%   Accounts for the shrunken plot box of axes with a fixed data aspect
%   ratio (e.g. M_Map axes). Used to draw annotation arrows across panels.
oif_drawnow;
u = ax.Units; ax.Units = 'normalized'; p = ax.Position; ax.Units = u;
fig = ancestor(ax, 'figure');
fu = fig.Units; fig.Units = 'pixels'; fp = fig.Position; fig.Units = fu;
xl = ax.XLim; yl = ax.YLim;
wpx = p(3)*fp(3); hpx = p(4)*fp(4);
if strcmp(ax.DataAspectRatioMode, 'manual')
    dar = ax.DataAspectRatio;
    ar = (diff(yl)/dar(2)) / (diff(xl)/dar(1));   % height/width of the data box
    if hpx/wpx > ar
        h = wpx*ar; p(2) = p(2) + (hpx - h)/2/fp(4); p(4) = h/fp(4);
    else
        w = hpx/ar; p(1) = p(1) + (wpx - w)/2/fp(3); p(3) = w/fp(3);
    end
end
xf = p(1) + (x - xl(1))/diff(xl)*p(3);
yf = p(2) + (y - yl(1))/diff(yl)*p(4);
end
