function [pct, G, SS] = variance_two_way(val, facA, facB)
%VARIANCE_TWO_WAY Balanced two-way (A x B) sum-of-squares variance partition.
%
%   [pct, G, SS] = variance_two_way(val, facA, facB)
%
%   val  : vector of case values
%   facA : cellstr (or numeric) level of factor A for each case (e.g. month)
%   facB : cellstr (or numeric) level of factor B for each case (e.g. resolution)
%
%   Cases are first averaged into the nA x nB cell grid G (levels in stable
%   order of first appearance). With grand mean m, row means r_a and column
%   means c_b (all NaN-aware):
%       SS_tot = sum_ab (G_ab - m)^2
%       SS_A   = nB * sum_a (r_a - m)^2
%       SS_B   = nA * sum_b (c_b - m)^2
%       SS_AB  = SS_tot - SS_A - SS_B           (interaction)
%   pct = 100*[SS_A SS_B SS_AB]/SS_tot.
%
%   This reproduces the "balanced two-factor ANOVA" decomposition used for
%   the R1 subset (release month x resolution) and the June subset (release
%   region x resolution) in Fig. 3d and Fig. S9b. The partition assumes a
%   complete grid; NaN values and empty or NaN cells are reported with a
%   warning (the NaN-aware means then describe an unbalanced design).

val = val(:);
if any(isnan(val))
    warning('OIF:nanIgnored', 'variance_two_way: %d NaN value(s) ignored.', nnz(isnan(val)));
end
[~, ~, iA] = unique(facA(:), 'stable');
[~, ~, iB] = unique(facB(:), 'stable');
nA = max(iA); nB = max(iB);
G = nan(nA, nB);
for a = 1:nA
    for b = 1:nB
        sel = (iA == a) & (iB == b);
        if any(sel); G(a,b) = mean(val(sel), 'omitnan'); end
    end
end
if any(isnan(G(:)))
    warning('OIF:unbalanced', ['variance_two_way: %d of the %d cells of the %d x %d grid ' ...
        'are empty or NaN; the partition is meant for a complete grid.'], nnz(isnan(G)), numel(G), nA, nB);
end
m    = mean(G(:), 'omitnan');
rowM = mean(G, 2, 'omitnan');
colM = mean(G, 1, 'omitnan');
SStot = sum((G(:) - m).^2, 'omitnan');
SSA   = nB * sum((rowM - m).^2, 'omitnan');
SSB   = nA * sum((colM - m).^2, 'omitnan');
SSAB  = SStot - SSA - SSB;
SS = [SSA SSB SSAB SStot];
if SStot > 0
    pct = 100 * [SSA SSB SSAB] / SStot;
else
    pct = nan(1,3);
end
end
