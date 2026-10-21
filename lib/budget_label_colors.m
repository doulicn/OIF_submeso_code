function cols = budget_label_colors(labels, surf_color)
% RGB color per Fe/DIC budget term: physical terms blue, biological terms green,
% surface flux surf_color (if given), everything else black.
if nargin < 2; surf_color = []; end
blue_terms  = {'PHY','HADV','VADV','MIX'};
green_terms = {'BIO','REPROD','REGEN','UPTAKE','SCAV','REMIN'};
labels = cellstr(labels);
cols = zeros(numel(labels),3);
for k = 1:numel(labels)
    term = regexp(labels{k}, '_\{([^{}]*)\}\$$', 'tokens', 'once');
    if isempty(term); term = {''}; end
    if any(strcmpi(term{1}, blue_terms))
        cols(k,:) = [0 0 1];
    elseif any(strcmpi(term{1}, green_terms))
        cols(k,:) = [0 0.6 0];
    elseif ~isempty(surf_color) && contains(labels{k},'surf') && contains(labels{k},'FLUX')
        cols(k,:) = surf_color;
    end
end
end
