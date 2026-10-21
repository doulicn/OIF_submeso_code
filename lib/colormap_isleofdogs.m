function cmap = colormap_isleofdogs()
%COLORMAP_ISLEOFDOGS  Sequential indigo-teal-mustard-red colormap (113 colours).
%
%   cmap = colormap_isleofdogs() returns the 113 x 3 RGB colormap used for
%   surface nitrate in Fig. 1a,b. It is the piecewise-linear interpolation
%   between the four anchor colours
%       #25245D (indigo), #73BCAA (teal), #E9C662 (mustard), #E64E46 (red)
%   placed at entries 1, 38, 75 and 113, rounded to 9 decimals. This is
%   exactly the table of the data file colormap_IsleOfDogs.dat (rows
%   indexed 32..144) used in the original analysis.
%
%   Written for this package.

knots   = [32 69 106 144];                                       % row indices of that table
anchors = [37 36 93; 115 188 170; 233 198 98; 230 78 70] / 255;  % RGB of the anchor colours
cmap = round(interp1(knots, anchors, (32:144)'), 9);             % 9 decimals, as stored in the file
end
