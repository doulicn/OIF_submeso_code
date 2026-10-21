function out = rot(w, angle)
%ROT  Rotate complex vectors (u + i v) counter-clockwise by ANGLE (radians).
%
%   out = rot(w, angle)
%
%   w      complex array u + i*v (e.g. ROMS grid-relative velocity)
%   angle  rotation angle in radians (e.g. the ROMS grid variable 'angle'),
%          same size as w, or a scalar
%   out    (u cos(angle) - v sin(angle)) + i (u sin(angle) + v cos(angle)),
%          i.e. w .* exp(1i*angle) evaluated component-wise, returned as a
%          2-D array of size [size(w,1), numel(w)/size(w,1)] (equal to
%          size(w) for vectors and matrices)
%
%   Written for this package with built-in MATLAB functions. It has the
%   name and interface of a helper used in the original analysis, whose
%   author and license are unknown, contains none of its code, and gives
%   identical output (checked before release). Used by prep/prep_maps.m
%   (velocity vectors of Fig. S3).

if ~isscalar(angle) && ~isequal(size(angle), size(w))
    error('rot:size', 'angle must be a scalar or have the same size as w.');
end
u = real(w);
v = imag(w);
c = cos(angle);
s = sin(angle);
out = complex(u .* c - v .* s, u .* s + v .* c);
out = reshape(out, size(w, 1), []);
end
