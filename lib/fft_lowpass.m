function out = fft_lowpass(y, pts)
%FFT_LOWPASS  FFT low-pass smoothing of an evenly sampled series.
%
%   out = fft_lowpass(y, pts)
%
%   y    evenly sampled series, row vector (1 x n). A column vector is
%        smoothed along its length and returned as a column.
%   pts  smoothing width in samples (real scalar >= 0, need not be an
%        integer). Fluctuations with periods shorter than about pts samples
%        are removed.
%   out  smoothed series, same size and class (double or single) as y
%
%   Method (FFT smoothing as described by Press et al. 1986, Numerical
%   Recipes, 1st ed., sec. 13.9 'Smoothing of Data', routine SMOOFT):
%     1. The straight line through the first and the last sample is
%        subtracted, so that the series starts and ends at zero and the
%        periodic transform has no jump at the ends.
%     2. The result is zero-padded to m samples, the smallest power of two
%        (m >= 2) with m >= n + 2*pts.
%     3. Its discrete Fourier transform (fft) is multiplied by the real,
%        zero-phase window
%            W(k) = max(0, 1 - (pts*k/m)^2),   k = 0, 1, ..., m/2,
%        with W(m-k) = W(k) for the negative frequencies.
%     4. The inverse transform (ifft) is truncated to the first n samples
%        and the line of step 1 is added back.
%   The computation is done in double precision; single input gives single
%   output. Any NaN or Inf in y makes the whole result NaN, and a scalar y
%   gives NaN (the end-point line is undefined).
%
%   An independent implementation of the FFT low-pass smoothing described in
%   Press et al. (Numerical Recipes, 1st ed., 1986, sec. 13.9), written for
%   this package with the MATLAB functions fft and ifft; it contains no
%   Numerical Recipes code. For row vectors it reproduces the smoother of the
%   original analysis code to round-off (checked before release). Used by
%   prep/prep_validation.m (smoothed upper-30 m series of Fig. S1).

if ~isnumeric(y) || ~isreal(y) || ~isvector(y) || isempty(y)
    error('fft_lowpass:input', 'y must be a non-empty real numeric vector.');
end
if ~isscalar(pts) || ~isnumeric(pts) || ~isreal(pts) || ~(pts >= 0) || ~isfinite(pts)
    error('fft_lowpass:pts', 'pts must be a finite real scalar >= 0.');
end
pts = double(pts);
cls = class(y);
is_col = iscolumn(y) && ~isscalar(y);
x = double(reshape(y, 1, []));
n = numel(x);

% padded length: smallest power of two (at least 2) not shorter than n + 2*pts
m = 2;
while m < n + 2*pts
    m = 2*m;
end

% straight line through the end points (NaN for a scalar, since 1/(n-1) = Inf)
k = 1:n;
trend = (1/(n - 1)) * (x(1)*(n - k) + x(n)*(k - 1));

% detrend, zero-pad, filter in the frequency domain, transform back
r = zeros(1, m);
r(1:n) = x - trend;
freq = [0:m/2, m/2-1:-1:1];                  % |frequency index| of each fft bin
W = max(0, 1 - (pts/m)^2 * freq.^2);
s = real(ifft(fft(r) .* W));

out = cast(s(1:n) + trend, cls);
if is_col
    out = out.';
end
end
