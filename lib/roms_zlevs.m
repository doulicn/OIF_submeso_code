function [z, Cs, sc] = roms_zlevs(h, zeta, theta_s, theta_b, hc, N, type, scoord_type, alpha, beta)
%ROMS_ZLEVS  Depths of ROMS rho or w points for terrain-following s-coordinates.
%
%   [z, Cs, sc] = roms_zlevs(h, zeta, theta_s, theta_b, hc, N, type, scoord_type)
%   [z, Cs, sc] = roms_zlevs(..., alpha, beta)      % bottom weights, 'new2008'
%
%   h            bottom depth (m, positive): scalar, vector or M x L array
%   zeta         free-surface elevation (m): scalar or same size as h
%   theta_s      surface stretching parameter
%   theta_b      bottom stretching parameter
%   hc           critical depth (m)
%   N            number of vertical rho levels
%   type         'w' for w points (N+1 levels); anything else gives rho points
%   scoord_type  'old1994'  Vtransform 1, Vstretching 1 (Song and Haidvogel 1994)
%                'new2006'  Vtransform 2, Vstretching 1
%                'new2008'  Vtransform 2, Vstretching 2 (A. Shchepetkin 2005),
%                           bottom weights alpha, beta (defaults 0 and 1)
%                'new2012'  Vtransform 2, Vstretching 4 (A. Shchepetkin 2010)
%   alpha, beta  optional, used for 'new2008' only
%
%   z            depths (m, negative below the surface), N x M x L
%                (N+1 x M x L for w points), double
%   Cs           stretching curve C(s), 1 x N (1 x N+1 for w points)
%   sc           s-coordinate s, 1 x N (1 x N+1 for w points)
%
%   Equations (ROMS documentation, wiki page 'Vertical S-coordinate',
%   https://www.myroms.org/wiki/Vertical_S-coordinate; Shchepetkin and
%   McWilliams 2005, 2009):
%     s = (k - N)/N, k = 0..N (w points);  s = (k - N - 1/2)/N, k = 1..N (rho)
%     Vtransform 1:  z = S + zeta (1 + S/h),       S = hc s + (h - hc) C(s)
%     Vtransform 2:  z = zeta + (zeta + h) S,      S = (hc s + h C(s)) / (hc + h)
%     Vstretching 1: C = (1 - theta_b) sinh(theta_s s) / sinh(theta_s)
%                      + theta_b [tanh(theta_s (s + 1/2)) / (2 tanh(theta_s/2)) - 1/2]
%     Csur = (1 - cosh(theta_s s)) / (cosh(theta_s) - 1)
%     Vstretching 2: C = mu Csur + (1 - mu) Cbot,
%                    Cbot = sinh(theta_b (s + 1)) / sinh(theta_b) - 1,
%                    mu = (s + 1)^alpha [1 + (alpha/beta) (1 - (s + 1)^beta)]
%     Vstretching 4: C = (exp(theta_b Csur) - 1) / (1 - exp(-theta_b))
%     (Vstretching 2 and 4 use C = Csur when theta_b <= 0.)
%   References: Shchepetkin, A. F., and J. C. McWilliams (2005), Ocean
%   Modelling, 9, 347-404. Shchepetkin, A. F., and J. C. McWilliams (2009),
%   Handbook of Numerical Analysis, 14, 121-183. Song, Y., and D. Haidvogel
%   (1994), J. Comput. Phys., 115, 228-244.
%
%   Written for this package from the published equations above, with the
%   interface of the ROMSTOOLS function zlevs4 used in the original analysis;
%   it contains none of that code and reproduces its depths to round-off
%   (checked before release). Differences: no console message, no
%   5 <= hc <= 12 m check for 'old1994', and an unknown scoord_type is an
%   error. Used by prep/prep_validation.m (station grid of Figs. S1 and S2).

if nargin < 8
    error('roms_zlevs:nargin', 'Not enough input arguments.');
end
if nargin < 9 || isempty(alpha); alpha = 0; end
if nargin < 10 || isempty(beta);  beta  = 1; end

% s-coordinate of the requested points
if strcmp(type, 'w')
    sc = ((0:N) - N) / N;
else
    sc = ((1:N) - N - 0.5) / N;
end
nz = numel(sc);

% stretching curve C(s)
switch scoord_type
    case {'new2008', 'new2012'}
        csur = (1 - cosh(theta_s * sc)) ./ (cosh(theta_s) - 1);
        if theta_b > 0
            if strcmp(scoord_type, 'new2012')
                Cs = (exp(theta_b * csur) - 1) ./ (1 - exp(-theta_b));
            else
                sp1  = sc + 1;
                mu   = sp1.^alpha .* (1 + (alpha/beta) * (1 - sp1.^beta));
                cbot = sinh(theta_b * sp1) ./ sinh(theta_b) - 1;
                Cs   = mu .* csur + (1 - mu) .* cbot;
            end
        else
            Cs = csur;
        end
        vtransform = 2;
    case {'old1994', 'new2006'}
        Cs = (1 - theta_b) * sinh(theta_s * sc) / sinh(theta_s) ...
           + theta_b * (tanh(theta_s * (sc + 0.5)) / (2 * tanh(0.5 * theta_s)) - 0.5);
        vtransform = 1 + strcmp(scoord_type, 'new2006');
    otherwise
        error('roms_zlevs:type', 'Unknown scoord_type ''%s''.', scoord_type);
end

% depths: levels along the first dimension, horizontal grid along dims 2-3
[M, L] = size(h);
h3 = reshape(h, 1, M, L);
if isscalar(zeta)
    zeta3 = zeta;
else
    zeta3 = reshape(zeta, 1, M, L);
end
s3 = reshape(sc, nz, 1);
c3 = reshape(Cs, nz, 1);
if vtransform == 1
    S = hc * s3 + (h3 - hc) .* c3;
    z = S + zeta3 .* (1 + S ./ h3);
else
    S = (hc * s3 + h3 .* c3) ./ (hc + h3);
    z = zeta3 + (zeta3 + h3) .* S;
end
z = double(reshape(z, nz, M, L));
end
