function cb = plot_log_contour(lon, lat, data, mask, order_min, order_max, ...
                               ncm, cmap, cbpos)
%PLOT_LOG_CONTOUR  Plot log-scaled filled contours with custom colorbar
%
% cb = plot_log_contour(lon, lat, data, mask, order_min, order_max, ...
%                       ncm, cmap, cbpos)
%
% Inputs:
%   lon, lat   : x and y grids (longitude and latitude, or e.g. filter scale
%                and time or depth in Figs. S11 and S12)
%   data       : data field to be log-scaled (e.g., SST)
%   mask       : mask applied to data (same size as data). The log-scaled data
%                are multiplied by it, so points with mask = 0 get the log
%                value 0 and are drawn in the central colour, not left blank.
%                NaNs in data are mapped to 0 by log_pm as well.
%   order_min  : minimum log10 order
%   order_max  : maximum log10 order
%   ncm        : number of color levels
%   cmap       : colormap
%   cbpos      : colorbar position (optional)
%
% Output:
%   cb         : handle to colorbar

    % Compute log-scaled data and colorbar info
    [logdata, minmax, tick_pos, tick_label] = log_pm(data, order_min, order_max);

    log_min = minmax(1);
    log_max = minmax(2);

    % Define contour interval
    pint = (log_max - log_min) / ncm;
    clevs = log_min:pint:log_max;

    % Plot filled contours
    hold on
    contourf(lon, lat, logdata .* mask, clevs, 'linestyle', 'none');

    % Color settings
    caxis([log_min log_max]);
    colormap(cmap);

    % Colorbar
    cb = colorbar;
    set(cb, 'ytick', tick_pos, ...
            'yticklabel', tick_label, ...
            'tickdir', 'out');

    % Optional colorbar position
    if nargin >= 9 && ~isempty(cbpos)
        set(cb, 'position', cbpos);
    end
end