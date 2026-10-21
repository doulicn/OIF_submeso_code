%% calculate_roms_surface_diagnostic_period_pdfs
% Aggregate near-surface ROMS diagnostic PDFs across a date range.
%
% This script is based on plot_roms_surface_diagnostics.m, but it is
% reorganized for efficient multi-day PDF calculations:
%   1. Resolve the common *his*.nc files that exist for all datasets in the
%      requested time window.
%   2. Read each ROMS grid only once and crop the 1 km target domain once.
%   3. First pass: stream through all files to determine pooled PDF limits.
%   4. Second pass: stream through all files again and accumulate histogram
%      counts without storing the daily maps in memory.
%   5. Save the aggregated PDFs and generate a single PDF figure.

clearvars;
close all;
clc;

%% User configuration
topLevelMode = 'last';          % 'last', 'first', or 'auto'
plotDepthMeters = [];         % [] -> use topLevelMode; scalar depth in meters otherwise
paramFile = locate_param_file();
machineChoice = 1       % [] -> auto-detect from available paths
startDateString = "20100602";
endDateString = "20100831";
dataFileType = 'avg';           % 'his' or 'avg'
normalizeVorticity = true;      % true -> plot zeta/f, false -> raw zeta
normalizeStrain = true;         % true -> plot S/f, false -> raw S
removeDomainMeanW = true;       % true -> use w - <w> on cropped 1 km target domain; false -> use raw w
useGeoSubset = false;           % true -> crop source data to subsetBox before interpolation
subsetBox = [-180, 180, -90, 90];
spongeWidth = 15;
targetDatasetIndex = 3;         % 1 km target grid
nBins = 160;
useSavedMatIfAvailable = true;  % true -> load saved .mat results when available and skip recalculation
saveComputedMatFile = true;     % true -> save computed results to .mat for later reuse
useLogYAxis = true;
saveFigFiles = false;
pngDPI = 300;
outputDir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

dataFileType = lower(string(dataFileType));
assert(any(dataFileType == ["his", "avg"]), 'dataFileType must be ''his'' or ''avg''.');
dataFileLabel = sprintf('%s files', upper(char(dataFileType)));
dataFileTag = char(dataFileType);

V.u = 'u';
V.v = 'v';
V.w = 'w';
V.pm = 'pm';
V.pn = 'pn';
V.f = 'f';
V.zeta = 'zeta';
V.angle = 'angle';
V.h = 'h';
V.mask_rho = 'mask_rho';
V.lon_rho = 'lon_rho';
V.lat_rho = 'lat_rho';

datasets = struct([]);
datasets(1).label = '12 km';
datasets(1).color = [0.20, 0.60, 0.20];
datasets(1).domain_num = 72;
datasets(1).filePattern = sprintf('pacmed_%s.*.nc', dataFileTag);

datasets(2).label = '4 km';
datasets(2).color = [0.90, 0.45, 0.10];
datasets(2).domain_num = 68;
datasets(2).filePattern = sprintf('nepac_%s.*.nc', dataFileTag);

datasets(3).label = '1 km';
datasets(3).color = [0.50, 0.25, 0.70];
datasets(3).domain_num = 96;
datasets(3).filePattern = sprintf('ospnw5_%s.*.nc', dataFileTag);

for k = 1:numel(datasets)
    [datasets(k).rootDir, datasets(k).grdfile, datasets(k).machineUsed] = ...
        resolve_dataset_paths_from_param(paramFile, datasets(k).domain_num, machineChoice);
    datasets(k).gridData = read_roms_grid(datasets(k).grdfile, V);
    if useGeoSubset
        datasets(k).subsetMask = datasets(k).gridData.lon_rho >= subsetBox(1) & ...
                                 datasets(k).gridData.lon_rho <= subsetBox(2) & ...
                                 datasets(k).gridData.lat_rho >= subsetBox(3) & ...
                                 datasets(k).gridData.lat_rho <= subsetBox(4);
    else
        datasets(k).subsetMask = true(size(datasets(k).gridData.lon_rho));
    end
end

targetGridFull = datasets(targetDatasetIndex).gridData;
targetGrid = crop_target_grid(targetGridFull, spongeWidth);
nSets = numel(datasets);
plotOrder = [3, 2, 1];  % plot PDFs as 1 km, 4 km, then 12 km
depthTag = format_depth_tag(plotDepthMeters, topLevelMode);
rangeTag = sprintf('%s_to_%s', char(startDateString), char(endDateString));
baseName = sprintf('period_pdf_vorticity_strain_w_three_resolutions_%s_%s_%s_%d', dataFileTag, rangeTag, depthTag,removeDomainMeanW);
matFile = fullfile(outputDir, strcat(baseName, '.mat'));

fprintf('Target interpolation grid: %s (cropped %d cells from each boundary)\n', ...
    datasets(targetDatasetIndex).label, spongeWidth);

if normalizeVorticity
    vorticityLabel = 'Ro = \zeta/f';
    vorticityTitle = 'Normalized Vorticity';
else
    vorticityLabel = '\zeta (s^{-1})';
    vorticityTitle = 'Vorticity';
end

if normalizeStrain
    strainLabel = 'S/f';
    strainTitle = 'Normalized Strain';
else
    strainLabel = 'S (s^{-1})';
    strainTitle = 'Strain';
end

if removeDomainMeanW
    wLabel = 'w - <w> (m s^{-1})';
    wTitle = 'Vertical Velocity';
else
    wLabel = 'w (m s^{-1})';
    wTitle = 'Vertical Velocity';
end

if useSavedMatIfAvailable && isfile(matFile)
    cacheData = load(matFile);
    results = cacheData.results;
    datasetMeta = cacheData.datasetMeta;
    commonDays = cacheData.commonDays;
    selectedDepthMeters = cacheData.selectedDepthMeters;
    selectedLevel = cacheData.selectedLevel;
    selectedMode = cacheData.selectedMode;
    validPointCount = cacheData.validPointCount;
    limits = cacheData.limits;
    vorticityEdges = cacheData.vorticityEdges;
    strainEdges = cacheData.strainEdges;
    wEdges = cacheData.wEdges;
    nDays = numel(commonDays);
    fprintf('Loaded cached period PDF data:\n  %s\n', matFile);
else
    commonDays = resolve_common_days_in_range(datasets, startDateString, endDateString);
    nDays = numel(commonDays);
    fprintf('Common daily files found for %d days from %s to %s.\n', ...
        nDays, startDateString, endDateString);

    for k = 1:nSets
        datasets(k).files = resolve_files_for_days(datasets(k).rootDir, datasets(k).filePattern, commonDays);
    end

    %% Pass 1: determine pooled histogram limits across the full period
    limits.vorticity = 0;
    limits.strain = 0;
    limits.w = 0;
    selectedDepthMeters = NaN(nSets, nDays);
    selectedLevel = NaN(nSets, nDays);
    selectedMode = strings(nSets, nDays);
    validPointCount = zeros(nSets, nDays);

    fprintf('\nPass 1/2: scanning limits across all files...\n');
    for iDay = 1:nDays
        dayString = commonDays(iDay);
        fprintf('  Day %s (%d/%d)\n', dayString, iDay, nDays);

        for k = 1:nSets
            diagFields = compute_daily_diagnostics(datasets(k), datasets(k).files{iDay}, targetGrid, V, ...
                topLevelMode, plotDepthMeters, normalizeVorticity, normalizeStrain, removeDomainMeanW);

            selectedDepthMeters(k, iDay) = diagFields.selectedDepthMeters;
            selectedLevel(k, iDay) = diagFields.selectedLevel;
            selectedMode(k, iDay) = string(diagFields.selectedMode);
            validPointCount(k, iDay) = nnz(isfinite(diagFields.vorticityPlot));

            limits.vorticity = max(limits.vorticity, max(abs(diagFields.vorticityPlot(:)), [], 'omitnan'));
            limits.strain = max(limits.strain, max(diagFields.strainPlot(:), [], 'omitnan'));
            limits.w = max(limits.w, max(abs(diagFields.w(:)), [], 'omitnan'));
        end
    end

    limits = sanitize_limits(limits);
    vorticityEdges = make_edges(limits.vorticity, nBins, 'symmetric');
    strainEdges = make_edges(limits.strain, nBins, 'positive');
    wEdges = make_edges(limits.w, nBins, 'symmetric');

    %% Pass 2: accumulate histogram counts
    fprintf('\nPass 2/2: accumulating histogram counts...\n');
    results = repmat(struct(), nSets, 1);
    for k = 1:nSets
        results(k).label = datasets(k).label;
        results(k).color = datasets(k).color;
        results(k).fileCount = nDays;
        results(k).vorticityCounts = zeros(1, numel(vorticityEdges) - 1);
        results(k).strainCounts = zeros(1, numel(strainEdges) - 1);
        results(k).wCounts = zeros(1, numel(wEdges) - 1);
        results(k).vorticitySamples = 0;
        results(k).strainSamples = 0;
        results(k).wSamples = 0;
        results(k).wMeanRemoved = NaN(1, nDays);
    end

    for iDay = 1:nDays
        dayString = commonDays(iDay);
        fprintf('  Day %s (%d/%d)\n', dayString, iDay, nDays);

        for k = 1:nSets
            diagFields = compute_daily_diagnostics(datasets(k), datasets(k).files{iDay}, targetGrid, V, ...
                topLevelMode, plotDepthMeters, normalizeVorticity, normalizeStrain, removeDomainMeanW);

            values = diagFields.vorticityPlot(isfinite(diagFields.vorticityPlot));
            results(k).vorticityCounts = results(k).vorticityCounts + histcounts(values, vorticityEdges);
            results(k).vorticitySamples = results(k).vorticitySamples + numel(values);

            values = diagFields.strainPlot(isfinite(diagFields.strainPlot));
            results(k).strainCounts = results(k).strainCounts + histcounts(values, strainEdges);
            results(k).strainSamples = results(k).strainSamples + numel(values);

            values = diagFields.w(isfinite(diagFields.w));
            results(k).wCounts = results(k).wCounts + histcounts(values, wEdges);
            results(k).wSamples = results(k).wSamples + numel(values);
            results(k).wMeanRemoved(iDay) = diagFields.wDomainMean;
        end
    end

    for k = 1:nSets
        [results(k).vorticityPdf, results(k).vorticityCenters] = counts_to_pdf(results(k).vorticityCounts, vorticityEdges, results(k).vorticitySamples);
        [results(k).strainPdf, results(k).strainCenters] = counts_to_pdf(results(k).strainCounts, strainEdges, results(k).strainSamples);
        [results(k).wPdf, results(k).wCenters] = counts_to_pdf(results(k).wCounts, wEdges, results(k).wSamples);
    end

    datasetMeta = strip_dataset_metadata(datasets);
    if saveComputedMatFile
        save(matFile, 'results', 'datasetMeta', 'commonDays', 'startDateString', 'endDateString', ...
            'topLevelMode', 'plotDepthMeters', 'depthTag', 'dataFileType', 'normalizeVorticity', 'normalizeStrain', 'removeDomainMeanW', ...
            'spongeWidth', 'targetDatasetIndex', 'nBins', 'vorticityEdges', 'strainEdges', 'wEdges', ...
            'selectedDepthMeters', 'selectedLevel', 'selectedMode', 'validPointCount', 'limits');
        fprintf('Saved cached period PDF data:\n  %s\n', matFile);
    end
end

%% Skewness of every simulation (computed from the pooled histograms so
%% it works whether results came from cache or a fresh computation)
skewAll.vorticity = nan(1, nSets);
skewAll.strain    = nan(1, nSets);
skewAll.w         = nan(1, nSets);
for k = 1:nSets
    skewAll.vorticity(k) = weighted_skewness(results(k).vorticityCenters, results(k).vorticityCounts);
    skewAll.strain(k)    = weighted_skewness(results(k).strainCenters, results(k).strainCounts);
    skewAll.w(k)         = weighted_skewness(results(k).wCenters, results(k).wCounts);
end

%% Plot PDFs
pdfFig = figure('Color', 'w', 'Position', [100, 650, 800, 250]);
tlo = tiledlayout(pdfFig, 1, 3, 'Padding', 'compact', 'TileSpacing', 'tight');

if machineChoice==1
    baseColor2 = cbrewer('qual','Dark2',3);
    alphaLevels = [1.00, 0.70, 0.40];
    color2 = [
        alphaLevels(1) * baseColor2 + (1 - alphaLevels(1)) * [1, 1, 1];
        alphaLevels(2) * baseColor2 + (1 - alphaLevels(2)) * [1, 1, 1];
        alphaLevels(3) * baseColor2 + (1 - alphaLevels(3)) * [1, 1, 1]
    ];
    results(1).color=color2(3,:);
    results(2).color=color2(2,:);
    results(3).color=color2(1,:);
end


nexttile(tlo, 1);
hold on;
for idx = 1:nSets
    k = plotOrder(idx);
    plot(results(k).vorticityCenters, results(k).vorticityPdf, 'LineWidth', 1.8, 'Color', results(k).color);
end
hold off;
grid on;box on;
if useLogYAxis
    set(gca, 'YScale', 'log');
end
xlabel(vorticityLabel);
ylabel('PDF');
add_skew_text(gca, skewAll.vorticity, results, plotOrder);
% legend({results(plotOrder).label}, 'Location', 'best');
title(vorticityTitle)

nexttile(tlo, 2);
hold on;
for idx = 1:nSets
    k = plotOrder(idx);
    plot(results(k).strainCenters, results(k).strainPdf, 'LineWidth', 1.8, 'Color', results(k).color);
end
hold off;
grid on;box on;
if useLogYAxis
    set(gca, 'YScale', 'log');
end
xlabel(strainLabel);
legend({results(plotOrder).label}, 'Location', 'east');
add_skew_text(gca, skewAll.strain, results, plotOrder);   % after legend so it avoids it
title(strainTitle);

nexttile(tlo, 3);
hold on;
legendEntries = strings(0, 1);
for idx = 1:nSets
    k = plotOrder(idx);
    if any(isfinite(results(k).wPdf))
        plot(results(k).wCenters, results(k).wPdf, 'LineWidth', 1.8, 'Color', results(k).color);
        legendEntries(end + 1, 1) = string(results(k).label); %#ok<AGROW>
    end
end
hold off;
grid on;box on;
if useLogYAxis
    set(gca, 'YScale', 'log');
end
xlabel(wLabel);
add_skew_text(gca, skewAll.w, results, plotOrder);
title(wTitle);

% if ~isempty(legendEntries)
%     legend(legendEntries, 'Location', 'best');
% end

pdfPng = fullfile(outputDir, strcat(baseName, '.png'));
exportgraphics(pdfFig, pdfPng, 'Resolution', pngDPI);
if saveFigFiles
    savefig(pdfFig, fullfile(outputDir, strcat(baseName, '.fig')));
end

fprintf('\nSaved outputs:\n');
fprintf('  %s\n', matFile);
fprintf('  %s\n', pdfPng);

%% Local functions
function diagFields = compute_daily_diagnostics(dataset, ncfile, targetGrid, V, topLevelMode, plotDepthMeters, normalizeVorticity, normalizeStrain, removeDomainMeanW)
    gridData = dataset.gridData;
    subsetMask = dataset.subsetMask;

    fieldData = read_surface_fields(ncfile, gridData, V, topLevelMode, plotDepthMeters);

    [uRhoNative, vRhoNative] = uv_to_rho(fieldData.u, fieldData.v);
    [uEast, vNorth] = rotate_velocity(uRhoNative, vRhoNative, gridData.angle, 'grid_to_geo');
    uEastTarget = interpolate_to_target(gridData, uEast, targetGrid, subsetMask & gridData.mask_rho);
    vNorthTarget = interpolate_to_target(gridData, vNorth, targetGrid, subsetMask & gridData.mask_rho);

    if ~isempty(fieldData.w)
        wRho = interpolate_to_target(gridData, fieldData.w, targetGrid, subsetMask & gridData.mask_rho);
    else
        wRho = NaN(size(targetGrid.lon_rho));
    end

    [uTarget, vTarget] = rotate_velocity(uEastTarget, vNorthTarget, targetGrid.angle, 'geo_to_grid');

    analysisMask = targetGrid.mask_rho;
    [zetaRho, roRho] = compute_vorticity_rho(uTarget, vTarget, targetGrid.pm, targetGrid.pn, targetGrid.f);
    if normalizeVorticity
        vorticityPlotField = roRho;
    else
        vorticityPlotField = zetaRho;
    end

    if normalizeStrain
        [~, strainPlotField] = compute_strain_rho(uTarget, vTarget, targetGrid.pm, targetGrid.pn, targetGrid.f);
    else
        [strainRho, ~] = compute_strain_rho(uTarget, vTarget, targetGrid.pm, targetGrid.pn, targetGrid.f);
        strainPlotField = strainRho;
    end

    vorticityPlotField(~analysisMask) = NaN;
    strainPlotField(~analysisMask) = NaN;
    wRho(~analysisMask) = NaN;
    if removeDomainMeanW
        wDomainMean = mean(wRho(analysisMask), 'omitnan');
        wRho = wRho - wDomainMean;
    else
        wDomainMean = NaN;
    end
    wRho(~analysisMask) = NaN;

    diagFields.vorticityPlot = vorticityPlotField;
    diagFields.strainPlot = strainPlotField;
    diagFields.w = wRho;
    diagFields.wDomainMean = wDomainMean;
    diagFields.selectedDepthMeters = fieldData.selectedDepthMeters;
    diagFields.selectedLevel = fieldData.selectedLevel;
    diagFields.selectedMode = fieldData.selectedMode;
end

function grid = read_roms_grid(grdfile, V)
    grid.pm = read_grid_field(grdfile, V.pm);
    grid.pn = read_grid_field(grdfile, V.pn);
    grid.h = read_grid_field(grdfile, V.h);

    if has_var(grdfile, V.f)
        grid.f = read_grid_field(grdfile, V.f);
    else
        lat = read_grid_field(grdfile, V.lat_rho);
        omegaEarth = 7.2921e-5;
        grid.f = 2 * omegaEarth * sind(lat);
    end

    grid.lon_rho = read_grid_field(grdfile, V.lon_rho);
    grid.lat_rho = read_grid_field(grdfile, V.lat_rho);
    if has_var(grdfile, V.angle)
        grid.angle = read_grid_field(grdfile, V.angle);
        if max(abs(grid.angle(:)), [], 'omitnan') > 2 * pi
            grid.angle = deg2rad(grid.angle);
        end
    else
        grid.angle = zeros(size(grid.pm));
    end

    if has_var(grdfile, V.mask_rho)
        grid.mask_rho = logical(read_grid_field(grdfile, V.mask_rho) > 0.5);
    else
        grid.mask_rho = true(size(grid.pm));
    end
end

function out = read_surface_fields(ncfile, gridData, V, topLevelMode, plotDepthMeters)
    out.zeta = read_2d_field(ncfile, V.zeta);

    uLevel = choose_vertical_level(ncfile, V.u, topLevelMode, plotDepthMeters, gridData, out.zeta);
    vLevel = choose_vertical_level(ncfile, V.v, topLevelMode, plotDepthMeters, gridData, out.zeta);
    if uLevel ~= vLevel
        error('Selected u and v levels differ for %s.', ncfile);
    end

    out.selectedLevel = uLevel;
    out.selectedMode = topLevelMode;
    out.selectedDepthMeters = infer_level_depth(ncfile, uLevel, gridData, out.zeta, false);
    out.u = read_surface_slice(ncfile, V.u, uLevel);
    out.v = read_surface_slice(ncfile, V.v, vLevel);

    if has_var(ncfile, V.w)
        wLevel = choose_vertical_level(ncfile, V.w, topLevelMode, plotDepthMeters, gridData, out.zeta);
        out.w = read_surface_slice(ncfile, V.w, wLevel);
    else
        out.w = [];
        warning('Variable "%s" not found in %s. Vertical-velocity PDF will omit this dataset.', V.w, ncfile);
    end
end

function levelIndex = choose_vertical_level(ncfile, varname, topLevelMode, plotDepthMeters, gridData, zeta)
    info = ncinfo(ncfile, varname);
    dimNames = string({info.Dimensions.Name});
    dimLens = [info.Dimensions.Length];

    zDim = find(contains(dimNames, 's_rho') | contains(dimNames, 's_w'), 1, 'first');
    if isempty(zDim)
        levelIndex = 1;
        return;
    end

    nz = dimLens(zDim);
    if ~isempty(plotDepthMeters)
        isWLevel = contains(dimNames(zDim), 's_w');
        levelIndex = choose_level_from_depth(ncfile, nz, plotDepthMeters, gridData, zeta, isWLevel);
        return;
    end

    switch lower(topLevelMode)
        case 'first'
            levelIndex = 1;
        case 'last'
            levelIndex = nz;
        case 'auto'
            levelIndex = infer_top_level_from_cs(ncfile, nz);
        otherwise
            error('Unsupported topLevelMode: %s', topLevelMode);
    end
end

function levelIndex = choose_level_from_depth(ncfile, nz, plotDepthMeters, gridData, zeta, isWLevel)
    depths = compute_reference_depth_profile(ncfile, nz, gridData, zeta, isWLevel);
    [~, levelIndex] = min(abs(depths + plotDepthMeters));
end

function depthMeters = infer_level_depth(ncfile, levelIndex, gridData, zeta, isWLevel)
    if nargin < 5
        isWLevel = false;
    end
    nz = numel(get_vertical_curve(ncfile, isWLevel));
    depths = compute_reference_depth_profile(ncfile, nz, gridData, zeta, isWLevel);
    depthMeters = abs(depths(levelIndex));
end

function depths = compute_reference_depth_profile(ncfile, nz, gridData, zeta, isWLevel)
    cs = get_vertical_curve(ncfile, isWLevel);
    if numel(cs) ~= nz
        error('Vertical stretching size mismatch in %s.', ncfile);
    end

    hc = read_global_attr(ncfile, 'hc');
    meanH = mean(gridData.h(gridData.mask_rho), 'omitnan');
    meanZeta = mean(zeta(gridData.mask_rho), 'omitnan');

    if isWLevel
        sCoord = ((0:nz-1) - nz) ./ max(nz - 1, 1);
    else
        sCoord = ((1:nz) - nz - 0.5) ./ nz;
    end

    depths = meanZeta + (meanZeta + meanH) .* ((hc .* sCoord(:) + meanH .* cs(:)) ./ (hc + meanH));
end

function cs = get_vertical_curve(ncfile, isWLevel)
    if isWLevel
        attrName = 'Cs_w';
    else
        attrName = 'Cs_r';
    end
    cs = double(read_global_attr(ncfile, attrName));
end

function value = read_global_attr(ncfile, attrName)
    value = ncreadatt(ncfile, '/', attrName);
    value = double(value);
end

function levelIndex = infer_top_level_from_cs(ncfile, nz)
    levelIndex = nz;
    try
        cs = ncreadatt(ncfile, '/', 'Cs_r');
        [~, levelIndex] = max(cs);
        if numel(cs) ~= nz
            levelIndex = nz;
        end
    catch
        levelIndex = nz;
    end
end

function field = read_surface_slice(ncfile, varname, levelIndex)
    info = ncinfo(ncfile, varname);
    dimNames = string({info.Dimensions.Name});
    dimLens = [info.Dimensions.Length];
    nd = numel(dimLens);
    start = ones(1, nd);
    count = dimLens;

    timeDim = find(contains(dimNames, 'time'), 1, 'first');
    if ~isempty(timeDim)
        start(timeDim) = 1;
        count(timeDim) = 1;
    end

    zDim = find(contains(dimNames, 's_rho') | contains(dimNames, 's_w'), 1, 'first');
    if ~isempty(zDim)
        start(zDim) = levelIndex;
        count(zDim) = 1;
    end

    field = double(squeeze(ncread(ncfile, varname, start, count)));
    field = apply_fill_mask(field, ncfile, varname);
    field = orient_roms_2d_slice(field, dimNames, count);
end

function field = read_2d_field(ncfile, varname)
    info = ncinfo(ncfile, varname);
    dimNames = string({info.Dimensions.Name});
    dimLens = [info.Dimensions.Length];
    nd = numel(dimLens);
    start = ones(1, nd);
    count = dimLens;

    timeDim = find(contains(dimNames, 'time'), 1, 'first');
    if ~isempty(timeDim)
        count(timeDim) = 1;
    end

    field = double(squeeze(ncread(ncfile, varname, start, count)));
    field = apply_fill_mask(field, ncfile, varname);
    field = orient_roms_2d_slice(field, dimNames, count);
end

function data = apply_fill_mask(data, ncfile, varname)
    attrs = ncinfo(ncfile, varname).Attributes;
    attrNames = string({attrs.Name});
    for name = ["_FillValue", "missing_value"]
        idx = find(attrNames == name, 1, 'first');
        if ~isempty(idx)
            fillValue = double(attrs(idx).Value);
            data(abs(data - fillValue) < max(1e-12, abs(fillValue) * 1e-12)) = NaN;
        end
    end
end

function [zetaRho, roRho] = compute_vorticity_rho(u, v, pm, pn, f)
    if isequal(size(u), size(pm)) && isequal(size(v), size(pm))
        dVdx = derivative_x_rho(v, pm);
        dUdy = derivative_y_rho(u, pn);
        zetaRho = dVdx - dUdy;
    else
        pmPsi = rho_to_psi(pm);
        pnPsi = rho_to_psi(pn);
        dVdxPsi = diff(v, 1, 2) .* pmPsi;
        dUdyPsi = diff(u, 1, 1) .* pnPsi;
        zetaPsi = dVdxPsi - dUdyPsi;
        zetaRho = psi_to_rho(zetaPsi);
    end
    roRho = zetaRho ./ f;
end

function [strainRho, strainNormRho] = compute_strain_rho(u, v, pm, pn, f)
    if isequal(size(u), size(pm)) && isequal(size(v), size(pm))
        uRho = u;
        vRho = v;
    else
        [uRho, vRho] = uv_to_rho(u, v);
    end
    duDx = derivative_x_rho(uRho, pm);
    duDy = derivative_y_rho(uRho, pn);
    dvDx = derivative_x_rho(vRho, pm);
    dvDy = derivative_y_rho(vRho, pn);

    normalStrain = duDx - dvDy;
    shearStrain = dvDx + duDy;
    strainRho = sqrt(normalStrain.^2 + shearStrain.^2);
    strainNormRho = strainRho ./ abs(f);
end

function [uRho, vRho] = uv_to_rho(u, v)
    uRho = NaN(size(u, 1), size(u, 2) + 1);
    uRho(:, 2:end-1) = 0.5 * (u(:, 1:end-1) + u(:, 2:end));
    uRho(:, 1) = u(:, 1);
    uRho(:, end) = u(:, end);

    vRho = NaN(size(v, 1) + 1, size(v, 2));
    vRho(2:end-1, :) = 0.5 * (v(1:end-1, :) + v(2:end, :));
    vRho(1, :) = v(1, :);
    vRho(end, :) = v(end, :);
end

function dfdx = derivative_x_rho(field, pm)
    dx = 1 ./ pm;
    dfdx = NaN(size(field));
    dfdx(:, 2:end-1) = (field(:, 3:end) - field(:, 1:end-2)) ./ ...
                       (dx(:, 3:end) + dx(:, 2:end-1));
    dfdx(:, 1) = (field(:, 2) - field(:, 1)) ./ dx(:, 1);
    dfdx(:, end) = (field(:, end) - field(:, end-1)) ./ dx(:, end);
end

function dfdy = derivative_y_rho(field, pn)
    dy = 1 ./ pn;
    dfdy = NaN(size(field));
    dfdy(2:end-1, :) = (field(3:end, :) - field(1:end-2, :)) ./ ...
                       (dy(3:end, :) + dy(2:end-1, :));
    dfdy(1, :) = (field(2, :) - field(1, :)) ./ dy(1, :);
    dfdy(end, :) = (field(end, :) - field(end-1, :)) ./ dy(end, :);
end

function psiField = rho_to_psi(rhoField)
    psiField = 0.25 * (rhoField(1:end-1, 1:end-1) + rhoField(2:end, 1:end-1) + ...
                       rhoField(1:end-1, 2:end) + rhoField(2:end, 2:end));
end

function rhoField = psi_to_rho(psiField)
    [m, n] = size(psiField);
    rhoField = NaN(m + 1, n + 1);
    rhoField(2:end-1, 2:end-1) = 0.25 * (psiField(1:end-1, 1:end-1) + psiField(2:end, 1:end-1) + ...
                                         psiField(1:end-1, 2:end) + psiField(2:end, 2:end));
    rhoField(1, 2:end-1) = mean(psiField(1:min(2, m), 1:end-1), 1, 'omitnan');
    rhoField(end, 2:end-1) = mean(psiField(max(1, m-1):m, 1:end-1), 1, 'omitnan');
    rhoField(2:end-1, 1) = mean(psiField(1:end-1, 1:min(2, n)), 2, 'omitnan');
    rhoField(2:end-1, end) = mean(psiField(1:end-1, max(1, n-1):n), 2, 'omitnan');
    rhoField(1, 1) = mean(psiField(1:min(2, m), 1:min(2, n)), 'all', 'omitnan');
    rhoField(1, end) = mean(psiField(1:min(2, m), max(1, n-1):n), 'all', 'omitnan');
    rhoField(end, 1) = mean(psiField(max(1, m-1):m, 1:min(2, n)), 'all', 'omitnan');
    rhoField(end, end) = mean(psiField(max(1, m-1):m, max(1, n-1):n), 'all', 'omitnan');
end

function [pdfVals, centers] = counts_to_pdf(counts, edges, sampleCount)
    centers = edges(1:end-1) + 0.5 * diff(edges);
    if sampleCount <= 0
        pdfVals = NaN(size(centers));
        return;
    end
    binWidths = diff(edges);
    pdfVals = counts ./ (sampleCount .* binWidths);
    pdfVals(pdfVals <= 0) = NaN;
end

function skew = weighted_skewness(centers, counts)
    counts = double(counts(:));
    centers = double(centers(:));
    totalCount = sum(counts);
    if totalCount <= 0 || numel(centers) ~= numel(counts)
        skew = NaN;
        return;
    end
    meanVal = sum(centers .* counts) / totalCount;
    m2 = sum(counts .* (centers - meanVal).^2) / totalCount;
    m3 = sum(counts .* (centers - meanVal).^3) / totalCount;
    if m2 <= 0
        skew = NaN;
    else
        skew = m3 / m2^1.5;
    end
end

function add_skew_text(ax, skewVals, results, plotOrder)
    % one "skew=" line per simulation (in plot order), coloured like its
    % PDF line. The stacked block is placed automatically at the spot in
    % the axes that overlaps the fewest plotted line points (and avoids
    % the legend, if one exists), preferring the upper part of the panel.
    drawnow;   % make sure axis limits / legend layout are final

    % --- create the text objects (temporarily at the origin) ---
    hTxt = gobjects(0);
    for idx = 1:numel(plotOrder)
        k = plotOrder(idx);
        if ~isfinite(skewVals(k))
            continue;
        end
        hTxt(end + 1) = text(ax, 0, 0, sprintf('skew=%.2f', skewVals(k)), ...
            'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
            'Color', results(k).color); %#ok<AGROW>
    end
    if isempty(hTxt)
        return;
    end
    ext = vertcat(hTxt.Extent);            % [x y w h] in normalized axes units
    lineH = max(ext(:, 4));
    boxW = max(ext(:, 3));
    boxH = lineH * numel(hTxt);

    % --- plotted line points in normalized axes coordinates ---
    xl = ax.XLim; yl = ax.YLim;
    isLogX = strcmp(ax.XScale, 'log'); isLogY = strcmp(ax.YScale, 'log');
    if isLogX; xl = log10(xl); end
    if isLogY; yl = log10(yl); end
    ptsX = []; ptsY = [];
    hLines = findobj(ax, 'Type', 'line');
    for il = 1:numel(hLines)
        xd = double(hLines(il).XData(:)); yd = double(hLines(il).YData(:));
        if isLogX; xd(xd <= 0) = NaN; xd = log10(xd); end
        if isLogY; yd(yd <= 0) = NaN; yd = log10(yd); end
        xn = (xd - xl(1)) / diff(xl);
        yn = (yd - yl(1)) / diff(yl);
        % densify each segment so steep/sparse parts of the curve still count
        for ip = 1:numel(xn) - 1
            if any(~isfinite([xn(ip) xn(ip+1) yn(ip) yn(ip+1)])); continue; end
            nSub = max(2, ceil(hypot(xn(ip+1) - xn(ip), yn(ip+1) - yn(ip)) / 0.005));
            tt = linspace(0, 1, nSub);
            ptsX = [ptsX, xn(ip) + tt * (xn(ip+1) - xn(ip))]; %#ok<AGROW>
            ptsY = [ptsY, yn(ip) + tt * (yn(ip+1) - yn(ip))]; %#ok<AGROW>
        end
    end

    % --- legend box in normalized axes coordinates (if any) ---
    legBox = [];
    lg = ax.Legend;
    if ~isempty(lg) && isvalid(lg) && strcmp(lg.Visible, 'on')
        try
            axPx = getpixelposition(ax, true);
            lgPx = getpixelposition(lg, true);
            legBox = [(lgPx(1) - axPx(1)) / axPx(3), (lgPx(2) - axPx(2)) / axPx(4), ...
                lgPx(3) / axPx(3), lgPx(4) / axPx(4)];
        catch
            legBox = [];
        end
    end

    % --- search candidate top-left anchors for the least-overlap spot ---
    pad = 0.02;
    xCand = linspace(pad, max(pad, 1 - boxW - pad), 25);
    yCand = linspace(1 - pad, min(1 - pad, boxH + pad), 25);   % top edge of the block
    bestScore = inf; bestX = xCand(end); bestY = yCand(1);
    for xc = xCand
        for yc = yCand
            bx0 = xc - pad; bx1 = xc + boxW + pad;
            by0 = yc - boxH - pad; by1 = yc + pad;
            nHit = sum(ptsX >= bx0 & ptsX <= bx1 & ptsY >= by0 & ptsY <= by1);
            if ~isempty(legBox) && bx0 < legBox(1) + legBox(3) && bx1 > legBox(1) && ...
                    by0 < legBox(2) + legBox(4) && by1 > legBox(2)
                nHit = nHit + 1e6;   % never cover the legend
            end
            % small preference for the top of the panel, then the right side
            score = nHit + 0.01 * (1 - yc) + 0.001 * (1 - xc);
            if score < bestScore
                bestScore = score; bestX = xc; bestY = yc;
            end
        end
    end

    for it = 1:numel(hTxt)
        hTxt(it).Position = [bestX, bestY - (it - 1) * lineH, 0];
    end
end

function limits = sanitize_limits(limits)
    names = fieldnames(limits);
    for i = 1:numel(names)
        value = limits.(names{i});
        if ~isfinite(value) || value <= 0
            limits.(names{i}) = 1;
        end
    end
end

function edges = make_edges(limitValue, nBins, mode)
    pad = max(eps(limitValue), 1e-12);
    switch mode
        case 'symmetric'
            edges = linspace(-(limitValue + pad), limitValue + pad, nBins + 1);
        case 'positive'
            edges = linspace(0, limitValue + pad, nBins + 1);
        otherwise
            error('Unsupported edge mode: %s', mode);
    end
end

function tf = has_var(ncfile, varname)
    info = ncinfo(ncfile);
    tf = any(strcmp({info.Variables.Name}, varname));
end

function field = orient_roms_2d_slice(field, dimNames, count)
    keepDims = count > 1;
    keptNames = dimNames(keepDims);
    keptNames = keptNames(~contains(keptNames, 'time') & ...
                          ~contains(keptNames, 's_rho') & ...
                          ~contains(keptNames, 's_w'));

    field = orient_to_eta_xi(field, keptNames);
end

function field = read_grid_field(ncfile, varname)
    info = ncinfo(ncfile, varname);
    dimNames = string({info.Dimensions.Name});
    field = double(ncread(ncfile, varname));
    field = apply_fill_mask(field, ncfile, varname);
    field = orient_to_eta_xi(field, dimNames);
end

function field = orient_to_eta_xi(field, dimNames)
    if ~ismatrix(field) || numel(dimNames) ~= 2
        return;
    end

    if contains(dimNames(1), 'xi') && contains(dimNames(2), 'eta')
        field = field.';
    end
end

function commonDays = resolve_common_days_in_range(datasets, startDateString, endDateString)
    commonDays = string(list_days_for_pattern(datasets(1).rootDir, datasets(1).filePattern, startDateString, endDateString));
    for k = 2:numel(datasets)
        thisDays = string(list_days_for_pattern(datasets(k).rootDir, datasets(k).filePattern, startDateString, endDateString));
        commonDays = intersect(commonDays, thisDays, 'stable');
    end

    if isempty(commonDays)
        error('No common day strings were found across the configured his files for %s to %s.', ...
            startDateString, endDateString);
    end
end

function dayStrings = list_days_for_pattern(rootDir, filePattern, startDateString, endDateString)
    files = dir(fullfile(rootDir, '**', filePattern));
    dayStrings = strings(0, 1);
    for i = 1:numel(files)
        match = regexp(files(i).name, '(\d{8})\d{6}', 'tokens', 'once');
        if isempty(match)
            continue;
        end

        thisDay = string(match{1});
        if thisDay >= string(startDateString) && thisDay <= string(endDateString)
            dayStrings(end + 1, 1) = thisDay; %#ok<AGROW>
        end
    end

    dayStrings = unique(dayStrings, 'stable');
end

function fileList = resolve_files_for_days(rootDir, filePattern, dayStrings)
    fileList = cell(numel(dayStrings), 1);
    files = dir(fullfile(rootDir, '**', filePattern));
    if isempty(files)
        error('No files matched pattern %s under %s.', filePattern, rootDir);
    end

    fileNames = string({files.name});
    fileFolders = string({files.folder});
    for i = 1:numel(dayStrings)
        hits = contains(fileNames, char(dayStrings(i)));
        if ~any(hits)
            error('No file matched date %s for pattern %s under %s.', dayStrings(i), filePattern, rootDir);
        end

        matchedPaths = fullfile(fileFolders(hits), fileNames(hits));
        matchedPaths = sort(string(matchedPaths));
        fileList{i} = char(matchedPaths(1));
    end
end

function datasetMeta = strip_dataset_metadata(datasets)
    datasetMeta = struct([]);
    for k = 1:numel(datasets)
        datasetMeta(k).label = datasets(k).label;
        datasetMeta(k).color = datasets(k).color;
        datasetMeta(k).domain_num = datasets(k).domain_num;
        datasetMeta(k).filePattern = datasets(k).filePattern;
        datasetMeta(k).rootDir = datasets(k).rootDir;
        datasetMeta(k).grdfile = datasets(k).grdfile;
        datasetMeta(k).machineUsed = datasets(k).machineUsed;
        datasetMeta(k).files = datasets(k).files;
    end
end

function [rootDir, grdfile, machineUsed] = resolve_dataset_paths_from_param(paramFile, domainNum, machineChoice)
    machineCandidates = machineChoice;
    if isempty(machineCandidates)
        machineCandidates = [1, 2];
    end

    errors = strings(0, 1);
    for i = 1:numel(machineCandidates)
        thisMachine = machineCandidates(i);
        try
            [rootDir, grdfile] = load_paths_from_param(paramFile, domainNum, thisMachine);
            if isfolder(rootDir) && isfile(grdfile)
                machineUsed = thisMachine;
                return;
            end
            errors(end + 1, 1) = sprintf('machine %d -> root exists: %d, grid exists: %d', ...
                thisMachine, isfolder(rootDir), isfile(grdfile)); %#ok<AGROW>
        catch ME
            errors(end + 1, 1) = sprintf('machine %d -> %s', thisMachine, ME.message); %#ok<AGROW>
        end
    end

    error('Could not resolve paths for domain %d from %s. Attempts: %s', ...
        domainNum, paramFile, strjoin(cellstr(errors), ' | '));
end

function [rootDir, grdfile] = load_paths_from_param(paramFile, domainNum, machineNum)
    paramText = fileread(paramFile);
    stopToken = 'Vtransform=2;';
    stopIdx = strfind(paramText, stopToken);
    assert(~isempty(stopIdx), 'Could not find cutoff token in parameter file: %s', paramFile);

    paramPrefix = paramText(1:stopIdx(1) - 1);
    domain_num = domainNum; %#ok<NASGU>
    machine = machineNum; %#ok<NASGU>

    eval(paramPrefix);

    assert(exist('root', 'var') == 1, 'Parameter file did not define root for domain %d, machine %d.', domainNum, machineNum);
    assert(exist('fgrd', 'var') == 1, 'Parameter file did not define fgrd for domain %d, machine %d.', domainNum, machineNum);

    rootDir = root;
    grdfile = fgrd;

    if ~isfolder(rootDir) && exist('root_base', 'var') == 1 && exist('domain', 'var') == 1
        fallbackRoot = fullfile(root_base, domain);
        if isfolder(fallbackRoot)
            rootDir = fallbackRoot;
        end
    end
end

function depthTag = format_depth_tag(plotDepthMeters, topLevelMode)
    if isempty(plotDepthMeters)
        depthTag = sprintf('depth_%s', topLevelMode);
    else
        depthTag = sprintf('depth_%dm', round(plotDepthMeters));
    end
end

function targetGrid = crop_target_grid(gridData, spongeWidth)
    rowIdx = (1 + spongeWidth):(size(gridData.lon_rho, 1) - spongeWidth);
    colIdx = (1 + spongeWidth):(size(gridData.lon_rho, 2) - spongeWidth);
    fields = fieldnames(gridData);
    for i = 1:numel(fields)
        value = gridData.(fields{i});
        if ismatrix(value) && all(size(value) == size(gridData.lon_rho))
            targetGrid.(fields{i}) = value(rowIdx, colIdx);
        else
            targetGrid.(fields{i}) = value;
        end
    end
end

function [uOut, vOut] = rotate_velocity(uIn, vIn, angle, mode)
    switch lower(mode)
        case 'grid_to_geo'
            uOut = uIn .* cos(angle) - vIn .* sin(angle);
            vOut = uIn .* sin(angle) + vIn .* cos(angle);
        case 'geo_to_grid'
            uOut = uIn .* cos(angle) + vIn .* sin(angle);
            vOut = -uIn .* sin(angle) + vIn .* cos(angle);
        otherwise
            error('Unsupported rotation mode: %s', mode);
    end
end

function fieldTarget = interpolate_to_target(sourceGrid, sourceField, targetGrid, sourceMask)
    valid = sourceMask & isfinite(sourceField) & isfinite(sourceGrid.lon_rho) & isfinite(sourceGrid.lat_rho);
    if ~any(valid(:))
        fieldTarget = NaN(size(targetGrid.lon_rho));
        return;
    end

    F = scatteredInterpolant(sourceGrid.lon_rho(valid), sourceGrid.lat_rho(valid), sourceField(valid), ...
        'linear', 'none');
    fieldTarget = F(targetGrid.lon_rho, targetGrid.lat_rho);
end

function paramFile = locate_param_file()
    candidates = [...
        string(fullfile(fileparts(mfilename('fullpath')), 'PACMED12_Process_param_8p6z.m'))
        "/data/project5/douli/MATLAB_scripts/PACMED_process/PACMED12_Process_param_8p6z.m"
        "/Users/douli/Library/CloudStorage/OneDrive-Personal/Program/MATLAB_scripts/PACMED_process/PACMED12_Process_param_8p6z.m"
    ];

    for i = 1:numel(candidates)
        if isfile(candidates(i))
            paramFile = char(candidates(i));
            return;
        end
    end

    error('Could not find PACMED12_Process_param.m. Checked: %s', strjoin(cellstr(candidates), ' | '));
end
