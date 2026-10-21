function fig = oif_figure(varargin)
%OIF_FIGURE Create a figure in the light graphics theme (drop-in for FIGURE).
%
%   fig = oif_figure(Name, Value, ...)
%
%   Same as fig = figure(Name, Value, ...), followed by setting the light
%   graphics theme. From R2025a on, a new figure follows the theme of the
%   MATLAB desktop (setting matlab.appearance.figure.GraphicsTheme = 'auto'),
%   so in a desktop session with a dark theme the figures would be exported
%   with black axes and light-grey labels. Forcing the light theme makes the
%   PNG/PDF output independent of the desktop theme. Releases without figure
%   themes are not affected; there the call reduces to figure(...).
fig = figure(varargin{:});
if ~isprop(fig, 'Theme')
    return                                  % no figure themes in this release
end
if exist('theme', 'file') == 2
    theme(fig, 'light');                    % R2025a and later
else
    % Theme property without the theme() function (New Desktop beta of
    % R2023b-R2024b): set the property directly
    try
        fig.Theme = 'light';
    catch
        % property not settable here: keep the release default
    end
end
end
