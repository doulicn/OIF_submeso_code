function T = make_table_S1(tex_file)
%MAKE_TABLE_S1 Manuscript Table S1: the 18 OIF experiments and their 60-day responses.
%   LaTeX label tab:oif_experiments (Supporting Information, Table S1).
%
%   make_table_S1             write tables/table_S1.csv and tables/table_S1.tex
%                             and print the table
%   T = make_table_S1         also return it as a MATLAB table
%   make_table_S1(tex_file)   also compare every cell with the table
%                             tab:oif_experiments in tex_file (e.g. the
%                             SI source SI_revised_v5_clean.tex, read only)
%
%   Cases 1-18 are the runs of data/ens_metrics.mat in their stored order.
%   All quantities cover the 60 days from the first day with a patch:
%     Patch area  mean surface patch area (dFe > 2e-5 mmol m-3), 10^4 km2
%     PHYC        see below
%     dCO2 FLUX   air-sea CO2 flux anomaly (OIF - control), integrated over
%                 the OSP-1KM domain and the 60 days, 10^12 mmol C
%     dPOC FLUX   the same for the POC flux across 100 m and across 500 m
%     (t C)       each carbon column is followed by the same quantity in
%                 10^4 metric tons of carbon, computed as in the manuscript
%                 from the rounded value: 10^12 mmol C = 1.2011 x 10^4 t C
%                 (12.011 g C mol-1), e.g. 5.89 -> 7.07 (not 7.08 from the
%                 unrounded 5.894)
%   The LaTeX rows follow the column order of the manuscript; patch area,
%   CO2 and the t C values of CO2 and 100-m POC have 2 decimals, the others 3. The manuscript gives the seven 100-m
%   POC values of 10 or more to four significant digits, so six of these
%   cells differ by up to 0.005 (e.g. 10.674 here, 10.670 there; README
%   section 5.7). The CSV has six decimals.
%   For 4KM_May, 4KM_Jul and 4KM_Aug the domain composites have no data on
%   1-2 days of the window (the first day of a month); the domain sums leave
%   these days out, as do the published values (a warning lists them).
%
%   PHYC column: the published values are reproduced. They are the 60-day
%   sums of the domain-integrated surface PHYC anomaly (OIF - control) from
%   data/ts_patch_timeseries.mat (dom.PHYC_surf). The table caption
%   describes the control-run PHYC integrated over the fertilized patch,
%   which is the quantity plotted in Fig. 3f (E.xls_ctrlPHYC_int); the CSV
%   holds it in an extra column. Both are sums of 60 daily area integrals of
%   a surface concentration (mmol m-3 x m2 x d = mmol m-1 d); the table
%   header gives 10^12 mmol C and the axis of Fig. 3f mmol m^-1.
%
%   Input:  data/ens_metrics.mat, data/ts_patch_timeseries.mat
%   Output: tables/table_S1.csv, tables/table_S1.tex

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if nargin < 1; tex_file = ''; end
E  = load(fullfile(C.data_dir, 'ens_metrics.mat'));
TS = load(fullfile(C.data_dir, 'ts_patch_timeseries.mat'), 'dom');
tab_dir = fullfile(C.pkg_dir, 'tables');
n = numel(E.label);

% ---- columns (table units) ------------------------------------------------
case_no = (1:n)';
res_km  = cellfun(@(s) sscanf(s, '%dKM'), E.res(:));
area    = E.xls_area_all(:) / 1e4;        % 10^4 km2   (= E.patch_area_60, Fig. 3b)
co2     = E.xls_CO2(:) / 1e12;            % 10^12 mmol C (= E.int_dom_CO2, Fig. 3c,e,f)
poc100  = E.xls_POC100(:) / 1e12;         % (= E.int_dom_POC100)
poc500  = E.xls_POC500(:) / 1e12;         % (= E.int_dom_POC500)
% PHYC as published: domain-integrated surface PHYC anomaly (OIF - control),
% summed over the 60 days from the first day with a patch in the domain
% composite (the window of E.int_dom_*)
phyc_pub = nan(n,1); nmiss = zeros(n,1);
for i = 1:n
    a = TS.dom.PHYC_surf.area(:,i);
    d0 = find(~isnan(a) & a > 0, 1);
    w = d0:min(numel(a), d0+59);
    x = TS.dom.PHYC_surf.sum(w,3,i);
    nmiss(i) = 60 - nnz(~isnan(x));
    phyc_pub(i) = sum(x, 'omitnan') / 1e12;
end
if any(nmiss)
    warning('OIF:nanIgnored', ['make_table_S1: the domain composites of %s have no data on %s ' ...
        'of the 60 days; these days are left out of the sums, as in the published table.'], ...
        strjoin(E.label(nmiss > 0)', ', '), mat2str(nmiss(nmiss > 0)'));
end
% PHYC described by the caption: control-run PHYC integrated over the patch
% (x-axis of Fig. 3f)
phyc_ctrl = E.xls_ctrlPHYC_int(:) / 1e12;
% the summary-table values equal the package's own integrals of the composites
chk = [max(abs(E.xls_area_all - E.patch_area_60) ./ E.patch_area_60, [], 'includenan'), ...
       max(abs(E.xls_CO2 - E.int_dom_CO2) ./ abs(E.int_dom_CO2), [], 'includenan'), ...
       max(abs(E.xls_POC100 - E.int_dom_POC100) ./ abs(E.int_dom_POC100), [], 'includenan'), ...
       max(abs(E.xls_POC500 - E.int_dom_POC500) ./ abs(E.int_dom_POC500), [], 'includenan')];

% ---- cells as printed in the manuscript -------------------------------------
num = [area phyc_pub co2 poc100 poc500];    % unrounded values of columns 6-10
bad = find(any(~isfinite([num phyc_ctrl]), 2));
if ~isempty(bad)
    error('OIF:tableA1:missing', 'make_table_S1: missing (NaN) values in data/ens_metrics.mat for case(s) %s (%s).', ...
        mat2str(bad'), strjoin(E.label(bad)', ', '));
end
fmt = {'%.2f', '%.3f', '%.2f', '%.3f', '%.3f'};
tC_per_1e12mmol = 1.2011;                   % 10^12 mmol C in 10^4 t C (12.011 g C mol-1)
fmt_t = {'', '', '%.2f', '%.2f', '%.3f'};   % t C columns after CO2, POC100, POC500
cells = cell(n, 13); num_col = nan(n, 13);  % num_col: unrounded value of each numeric cell
for i = 1:n
    cells(i,1:5) = {sprintf('%d', case_no(i)), E.label{i}, sprintf('%d', res_km(i)), E.month{i}, E.region{i}};
    jc = 5;
    for j = 1:5
        jc = jc + 1;
        cells{i,jc} = sprintf(fmt{j}, num(i,j)); num_col(i,jc) = num(i,j);
        if ~isempty(fmt_t{j})
            jc = jc + 1;
            cells{i,jc} = sprintf(fmt_t{j}, str2double(cells{i,jc-1}) * tC_per_1e12mmol);
            num_col(i,jc) = num(i,j) * tC_per_1e12mmol;
        end
    end
end
tC = [co2 poc100 poc500] * tC_per_1e12mmol;   % unrounded, for the CSV
% horizontal rule between the R1 block (Cases 1-12) and the other regions
rule_after = find(strcmp(E.region(1:end-1), 'R1') & ~strcmp(E.region(2:end), 'R1'))';

% ---- print ------------------------------------------------------------------
hdr = {'Case','Experiment','Res(km)','Month','Region','Area(1e4km2)','PHYC(1e12)', ...
       'dCO2(1e12)','dCO2(1e4tC)','dPOC100(1e12)','dPOC100(1e4tC)','dPOC500(1e12)','dPOC500(1e4tC)'};
fprintf('\nTable S1 (tab:oif_experiments), 60 days after the release\n');
fprintf('%-4s %-12s %-7s %-5s %-6s %12s %10s %10s %11s %13s %14s %13s %14s | %s\n', hdr{:}, 'PHYCctrl_patch(1e12)');
for i = 1:n
    fprintf('%-4s %-12s %-7s %-5s %-6s %12s %10s %10s %11s %13s %14s %13s %14s | %10.3f\n', cells{i,:}, phyc_ctrl(i));
    if ismember(i, rule_after); fprintf('%s\n', repmat('-', 1, 160)); end
end
fprintf(['Summary tables vs integrals of the composites (max. rel. difference): ' ...
    'area %.1e, CO2 %.1e, POC100 %.1e, POC500 %.1e\n'], chk);
r_pub  = corrcoef(phyc_pub, co2);
r_ctrl = corrcoef(phyc_ctrl, co2);
fprintf(['Note on the PHYC column: it reproduces the published values, which are the\n' ...
    '  60-day sums of the domain-integrated surface PHYC anomaly (OIF - control),\n' ...
    '  in 10^12 mmol m-1 d (Pearson R with the CO2 column %.2f). The caption\n' ...
    '  describes the control-run PHYC integrated over the fertilized patch: the\n' ...
    '  quantity plotted in Fig. 3f, E.xls_ctrlPHYC_int, in 10^12 mmol m-1 d (sum\n' ...
    '  of 60 daily patch integrals of the surface concentration; Fig. 3f labels it\n' ...
    '  mmol m^-1; R with CO2 %.2f as in Fig. 3f). It is the last column above and\n' ...
    '  the column PHYCctrl_patch_Fig3f of table_S1.csv.\n'], r_pub(1,2), r_ctrl(1,2));

% ---- write tables/table_S1.tex (body rows) and tables/table_S1.csv ----------
tex_rows = cell(n,1);
for i = 1:n
    tex_rows{i} = sprintf('%-2d & %-13s & %-2d & %s & %s & %s & %s & %s & %s & %6s & %5s & %s & %s \\\\', case_no(i), ...
        strrep(E.label{i}, '_', '\_'), res_km(i), E.month{i}, E.region{i}, cells{i,6:13});
end
fid = fopen(fullfile(tab_dir, 'table_S1.tex'), 'w');
fprintf(fid, '%% Body of Table S1 (tab:oif_experiments), written by tables/make_table_S1.m\n');
fprintf(fid, '%% from data/ens_metrics.mat and data/ts_patch_timeseries.mat. Columns: Case &\n');
fprintf(fid, '%% Experiment & Resolution (km) & Release month & Release region & Patch area\n');
fprintf(fid, '%% (10^4 km^2) & PHYC & dCO2 FLUX & (t C) & dPOC FLUX 100 m & (t C) & dPOC FLUX 500 m &\n');
fprintf(fid, '%% (t C); carbon in 10^12 mmol C, (t C) the same in 10^4 t C (x 1.2011, from the rounded value).\n');
fprintf(fid, '%% PHYC as published: 60-day sum of the domain-integrated surface PHYC anomaly\n');
fprintf(fid, '%% (OIF - control), 10^12 mmol m-1 d (see make_table_S1.m).\n');
for i = 1:n
    fprintf(fid, '%s\n', tex_rows{i});
    if ismember(i, rule_after); fprintf(fid, '\\midrule\n'); end
end
fclose(fid);
fid = fopen(fullfile(tab_dir, 'table_S1.csv'), 'w');
fprintf(fid, ['Case,Experiment,Resolution_km,Release_month,Release_region,PatchArea_1e4km2,' ...
    'PHYC_published_dPHYC_domain_1e12_mmol_m-1_d,dCO2_FLUX_domain_1e12_mmolC,' ...
    'dPOC_FLUX_100m_domain_1e12_mmolC,dPOC_FLUX_500m_domain_1e12_mmolC,' ...
    'PHYCctrl_patch_Fig3f_1e12_mmol_m-1_d,dCO2_FLUX_domain_1e4_tC,dPOC_FLUX_100m_domain_1e4_tC,' ...
    'dPOC_FLUX_500m_domain_1e4_tC\n']);
for i = 1:n
    fprintf(fid, '%d,%s,%d,%s,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n', case_no(i), E.label{i}, res_km(i), ...
        E.month{i}, E.region{i}, area(i), phyc_pub(i), co2(i), poc100(i), poc500(i), phyc_ctrl(i), tC(i,:));
end
fclose(fid);
fprintf('\nLaTeX rows (tables/table_S1.tex):\n');
for i = 1:n
    fprintf('%s\n', tex_rows{i});
    if ismember(i, rule_after); fprintf('\\midrule\n'); end
end
fprintf('Written: %s, %s\n', fullfile(tab_dir, 'table_S1.csv'), fullfile(tab_dir, 'table_S1.tex'));

T = table(case_no, E.label(:), res_km, E.month(:), E.region(:), area, phyc_pub, co2, poc100, poc500, phyc_ctrl, ...
    tC(:,1), tC(:,2), tC(:,3), ...
    'VariableNames', {'Case','Experiment','Resolution_km','Release_month','Release_region','PatchArea_1e4km2', ...
    'PHYC_published','dCO2_FLUX','dPOC_FLUX_100m','dPOC_FLUX_500m','PHYCctrl_patch_Fig3f', ...
    'dCO2_FLUX_1e4tC','dPOC_FLUX_100m_1e4tC','dPOC_FLUX_500m_1e4tC'});

% ---- optional check against the manuscript ----------------------------------
if ~isempty(tex_file)
    compare_with_tex(tex_file, cells, num_col, hdr);
end
if nargout == 0; clear T; end
end

% =============================================================================
function compare_with_tex(tex_file, cells, num, hdr)
% Compare the cells with the body of the table labelled tab:oif_experiments.
ms = read_tex_table(tex_file, 'tab:oif_experiments');
[n, ncol] = size(cells);
fprintf('\nCell-by-cell comparison with %s\n', tex_file);
if ~isequal(size(ms), [n ncol])
    fprintf('  could not read a %d x %d table body (found %d x %d)\n', n, ncol, size(ms,1), size(ms,2));
    return
end
nbad = zeros(1, ncol);
for j = 1:ncol
    for i = 1:n
        a = ms{i,j}; b = cells{i,j};
        if strcmp(a, b); continue; end
        nbad(j) = nbad(j) + 1;
        note = '';
        if j >= 6
            note = sprintf(' (unrounded %.6f)', num(i,j));
            if strcmp(a, sprintf('%.3f', str2double(sprintf('%.4g', num(i,j)))))
                note = [note ', manuscript: 4 significant digits padded with a zero']; %#ok<AGROW>
            end
        end
        fprintf('  MISMATCH case %2d, %-14s manuscript "%s", rebuilt "%s"%s\n', i, hdr{j}, a, b, note);
    end
end
fprintf('  %d of %d cells differ; per column: %s\n', sum(nbad), n*ncol, mat2str(nbad));
end

function rows = read_tex_table(file, label)
% Body cells of the tabular that follows \label{label} (rows starting with a
% number, up to \bottomrule); LaTeX underscores unescaped.
txt = splitlines(string(fileread(file)));
k0 = find(contains(txt, ['\label{' label '}']), 1);
rows = cell(0, 10);
if isempty(k0); return; end
for k = k0:numel(txt)
    L = strtrim(txt(k));
    if startsWith(L, '\bottomrule'); break; end
    if ~isempty(regexp(L, '^\d+\s*&', 'once'))
        L = regexprep(L, '\\\\\s*$', '');
        c = strrep(strtrim(split(L, '&'))', '\_', '_');
        rows(end+1, 1:numel(c)) = cellstr(c); %#ok<AGROW>
    end
end
end
