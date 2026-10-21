function [kz, xs, mld] = cg_depth_scale(H, scale, mld_all, avg_months, t)
%CG_DEPTH_SCALE  Depth-scale k[w*] = d(w*)/d(scale) averaged over a set of months.
%
%   [kz, xs, mld] = cg_depth_scale(H, scale, mld_all, avg_months, t)
%   H          : struct from data/coarsegrain_hovmoller.mat (fields wz_month, nday_month, valid)
%   scale      : filter scales (km)
%   mld_all    : daily MLD (m, positive), 365 x 1
%   avg_months : calendar months to average (e.g. [6 7])
%   t          : date numbers of the days of mld_all and H.valid (cg.time)
%   kz         : depth x (nscale-1) scale derivative of the mean cumulative flux
%   xs         : mid-point scales (km)
%   mld        : mean MLD over the same valid days (m, positive)
%
%   The mean over all valid days of the selected months is the valid-day
%   weighted mean of the monthly means stored by the prep script.
if numel(t) ~= numel(mld_all) || numel(t) ~= numel(H.valid)
    error('cg_depth_scale:size', 't, mld_all and H.valid must have one value per day.');
end
n = H.nday_month(avg_months);
wz = zeros(size(H.wz_month,1), size(H.wz_month,2));
for i = 1:numel(avg_months)
    if n(i) > 0; wz = wz + H.wz_month(:,:,avg_months(i)) * n(i); end
end
wz = wz / sum(n);
scale = scale(:)';
kz = diff(wz,1,2) ./ diff(scale);
xs = (scale(1:end-1) + scale(2:end)) / 2;
dv = datevec(t(:));
mld = mean(mld_all(H.valid(:) & ismember(dv(:,2), avg_months)), 'omitnan');
end
