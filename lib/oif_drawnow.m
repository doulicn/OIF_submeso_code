function oif_drawnow()
%OIF_DRAWNOW DRAWNOW that keeps the current figure.
%   drawnow can make another figure the current one, e.g. a figure that the
%   user created but MATLAB had not drawn yet when a package script started.
%   The plot scripts create axes and graphics without an explicit parent, so
%   that figure would receive them. oif_drawnow restores the current figure
%   after the update.
cf = get(groot, 'CurrentFigure');
drawnow;
if isgraphics(cf)
    set(groot, 'CurrentFigure', cf);
end
end
