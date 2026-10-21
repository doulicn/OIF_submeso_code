%PREP_MAPS Build the compact map data behind Fig. 1 and Figs. S3-S6.
%
%   Reads intermediate model products from the data root (C.box_root,
%   environment variable OIF_DATA_ROOT; see oif_config.m): the daily surface
%   caches hori_surf_100m_200m_500m_daily_<VAR>_2010MM_Papa_extend2.mat, the
%   model grids, WOA23 nitrate, the NEPAC-4KM summer NO3 cache and the
%   period-PDF cache of the surface diagnostics, and writes
%     data/fig1_ab.mat              Fig. 1a,b  (WOA23 JJA NO3, model JJA NO3,
%                                    grid outlines, release regions)
%     data/fig1_pdfs.mat            Fig. 1c-e  (pooled PDFs of Ro, S/f, w-<w>)
%     data/patchmaps_grid.mat       cropped lon/lat of the 1/4/12 km grids
%     data/patchmaps_occurrence.mat Fig. 1f-h, S5, S6 (occurrence maps and
%                                    daily filamentation indices, 18 runs)
%     data/patchmaps_S4_contours.mat Fig. S4 (dFe of the June-R1 runs on cache
%                                    days 1, 11, 21 and the last day of each
%                                    month, Jun-Sep, clipped to [0 2*thr])
%     data/patchmaps_S3_july1.mat   Fig. S3 (dFe, dCHL, velocity on 1 Jul 2010)
%
%   Switches (set them in the workspace before running the script; the
%   defaults give the full rebuild):
%     do_fig1ab  = true    Fig. 1a,b data (fig1_ab.mat)
%     do_pdfs    = true    Fig. 1c-e data (fig1_pdfs.mat)
%     do_patches = true    occurrence, filamentation index, S4 contours and S3
%                          fields (the four patchmaps_*.mat; reads ~11 GB of
%                          daily caches, ~8 GB of them at 1 km)
%     do_s4_only = false   true: rebuild only patchmaps_S4_contours.mat, from
%                          the June-R1 OIF and control Fe caches of June-
%                          September (the three switches above are ignored)
%     res_list   = 1:3     resolutions processed by do_patches / do_s4_only
%                          (1, 2, 3 = 1, 4, 12 km). With a subset, the
%                          processed resolutions are merged into the existing
%                          patchmaps_*.mat files and the others are kept.
%   Example (12 km patch maps only):
%     do_fig1ab = false; do_pdfs = false; res_list = 3; prep_maps
%
%   Provenance. Fig. 1a,b and the patch maps re-implement blocks of the
%   original analysis script PACMED12_Process_marbl_8p6z.m: plot_domain_WOA23,
%   plot_domain_model_no3, and, in plot_horizontal_surface_int200m_daily_zoom_
%   test_cmp_more, the sections plot_patch_occurency (occurrence, filamentation
%   index) and plot_patch_distributions_among_cases (Fig. S4, with the
%   published day selection [1 11 21 last] that is commented out there), plus
%   the 1 July maps of plot_horizontal_surface_int200m_daily_zoom_test_cmp2 and
%   the release regions of PACMED12_Process_param_8p6z.m (region_defs).
%   The Fig. 1c-e block computes nothing: it copies the pooled histograms, and
%   their provenance, from the cache written by the author's script
%   calculate_roms_surface_diagnostic_period_pdfs.m, which is included
%   unchanged as upstream/calculate_roms_surface_diagnostic_period_pdfs.m.
%   The code that produced the daily surface caches and the NEPAC-4KM summer
%   NO3 cache from the ROMS output is not part of this package.
%
%   Filamentation index FI = P^2/(4 pi A) of the daily patch (dFe > thr): A is
%   the summed cell area and P the summed length of the patch boundary faces.
%   As in the original code, the faces found along the first array dimension
%   (xi) are weighted with dx = 1/pm and those along the second (eta) with
%   dy = 1/pn, although a face normal to xi has length dy. With dx/dy of about
%   0.98/0.97/1.00 over the patch cells at 1/4/12 km this changes P by at most
%   about 1.5/3/0.1 % (FI by 3/6/0.1 %); the convention is kept so that the
%   published FI values are reproduced.
%   fig1_ab.mat: inpaintn fills the land/missing cells of the WOA23 field; its
%   initial guess uses the Image Processing Toolbox (bwdist) when available,
%   and without the toolbox the filled cells differ slightly (observed cells
%   are unchanged).
%   The daily caches are read one file at a time (each 1 km file is ~300 MB).

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));  % package root
C = setup_paths();
if ~isfolder(C.box_root)
    error('OIF:noDataRoot', ['prep_maps needs the data root, the folder that contains ROMS/, ' ...
        'noaa/ and code_process/. Set the environment variable OIF_DATA_ROOT to that folder ' ...
        '(current value: ''%s''); see oif_config.m.'], C.box_root);
end
if ~exist('do_fig1ab','var');  do_fig1ab  = true;  end
if ~exist('do_pdfs','var');    do_pdfs    = true;  end
if ~exist('do_patches','var'); do_patches = true;  end
if ~exist('do_s4_only','var'); do_s4_only = false; end
if ~exist('res_list','var');   res_list   = 1:3;   end
run_fig1ab  = do_fig1ab  && ~do_s4_only;
run_pdfs    = do_pdfs    && ~do_s4_only;
run_patches = do_patches && ~do_s4_only;
nres = 3;
res_list = unique(res_list(:)');
assert(~isempty(res_list) && all(ismember(res_list, 1:nres)), 'res_list must be a subset of 1:3');
full_res = isequal(res_list, 1:nres);   % false: merge into the existing patchmaps_*.mat

thr     = C.patch_threshold;          % 2e-5 mmol m-3
yearnum = 2010;
s4_sampling = ['dFe (OIF - control) of the June-R1 run on cache days 1, 11 and 21 and the last day ' ...
    'of each monthly daily cache, June-September 2010 (as in the published Fig. S4; the June cache ' ...
    'starts on 2 June), clipped to [0 2*threshold]; dfe0731 = 31 July (black contour). ' ...
    'Dates in s4(ires).time.'];
s3_day  = datenum(2010,7,1);          % S3 snapshot
s3_quiver_step = [40 15 10];          % quiver subsampling for 1/4/12 km
figdir  = @(runname) fullfile(C.roms_dir, runname, 'Analysis', 'figures');
cache   = @(runname, var, mm) fullfile(figdir(runname), ...
    sprintf('hori_surf_100m_200m_500m_daily_%s_%d%02d_Papa_extend2.mat', var, yearnum, mm));

%% Release regions R1-R3 (PACMED12_Process_param_8p6z.m, region_defs)
reg(1).lon = mod([-146.3 -145.59], 360);
reg(1).lat = [52.03 52.5];
half_width_km = 25; dlat = half_width_km/111.32;
reg(2).lon = 215 + [-1 1]*half_width_km/(111.32*cosd(50));
reg(2).lat = 50 + [-1 1]*dlat;
clon = mean([mean(reg(1).lon), mean(reg(2).lon)]);
clat = mean([mean(reg(1).lat), mean(reg(2).lat)]);
reg(3).lon = clon + [-1 1]*half_width_km/(111.32*cosd(clat));
reg(3).lat = clat + [-1 1]*dlat;
region_lon_OIF = cell(1,3); region_lat_OIF = cell(1,3);
for ir = 1:3
    region_lon_OIF{ir} = reg(ir).lon([1 2 2 1 1]);
    region_lat_OIF{ir} = reg(ir).lat([1 1 2 2 1]);
end

if ~isfolder(C.data_dir); mkdir(C.data_dir); end

%% ------------------------------------------------------------------------
%% Fig. 1a,b
if run_fig1ab
    % (a) WOA23 JJA surface nitrate
    rootdir = fullfile(C.box_root, 'noaa/woa23/woa23_nitrate_monthly');
    NO3sList = cell(1,3);
    for k = 1:3
        ncfile = fullfile(rootdir, sprintf('woa23_all_n%02d_01.nc', k+5));
        lon_woa = ncread(ncfile,'lon'); lat_woa = ncread(ncfile,'lat');
        depth = ncread(ncfile,'depth'); NO3 = ncread(ncfile,'n_an');
        [~,iz] = min(abs(depth - 0));
        NO3sList{k} = squeeze(NO3(:,:,iz,1));
    end
    NO3s = mean(cat(3, NO3sList{:}), 3, 'omitnan');
    if size(NO3s,1) == numel(lon_woa) && size(NO3s,2) == numel(lat_woa)
        NO3plot = NO3s';
    else
        NO3plot = NO3s;
    end
    lon_woa = mod(lon_woa,360);
    [lon_woa, ind] = sort(lon_woa);
    NO3plot = NO3plot(:,ind);
    NO3plot = inpaintn(NO3plot);
    woa.lon = single(lon_woa(:)'); woa.lat = single(lat_woa(:)');
    woa.no3_jja = single(NO3plot);           % (lat, lon)

    % grid outlines: 12 km (black), 4 km (blue), 1 km (red); order as C.grd reversed
    outline = struct('lon',{},'lat',{},'label',{});
    order = [3 2 1];
    for k = 1:3
        g = C.grd{order(k)};
        lon_rho = ncread(g,'lon_rho'); lat_rho = ncread(g,'lat_rho');
        outline(k).lon = single([lon_rho(1,:), lon_rho(:,end)', flip(lon_rho(end,:)), flip(lon_rho(:,1))'] + 360);
        outline(k).lat = single([lat_rho(1,:), lat_rho(:,end)', flip(lat_rho(end,:)), flip(lat_rho(:,1))']);
        outline(k).label = C.res_label{order(k)};
    end

    % (b) NEPAC-4KM JJA-mean surface NO3 (cache built by plot_domain_model_no3)
    f = fullfile(figdir(C.ctrl{2}), [C.ctrl{2}, '_NO3_model_summer_OSP.mat']);
    S = load(f, 'no3surf','no3surf_lon','no3surf_lat','no3Count');
    model.no3_jja = single(S.no3surf);
    model.lon = single(mod(S.no3surf_lon,360));
    model.lat = single(S.no3surf_lat);
    model.ndays = S.no3Count;   % number of valid (point x day) samples
    model.source = rel_to_root(f, C.box_root);

    save(fullfile(C.data_dir,'fig1_ab.mat'), 'woa','outline','model', ...
        'region_lon_OIF','region_lat_OIF','-v7');
    fprintf('saved fig1_ab.mat\n');
end

%% ------------------------------------------------------------------------
%% Fig. 1c-e: pooled PDFs, copied from the cache written by
%% calculate_roms_surface_diagnostic_period_pdfs.m (upstream/)
if run_pdfs
    f = fullfile(C.box_root, 'code_process/figures', ...
        'period_pdf_vorticity_strain_w_three_resolutions_avg_20100602_to_20100831_depth_last_1.mat');
    P = load(f);
    keep = {'label','vorticityCounts','strainCounts','wCounts','vorticityPdf','vorticityCenters', ...
            'strainPdf','strainCenters','wPdf','wCenters','fileCount','vorticitySamples','strainSamples','wSamples'};
    results = struct();
    for k = 1:numel(P.results)
        for q = 1:numel(keep)
            results(k).(keep{q}) = P.results(k).(keep{q});
        end
    end
    % metadata of the cache; MATLAB string objects are stored as char
    pdfmeta.commonDays = char(P.commonDays); pdfmeta.startDate = char(P.startDateString);
    pdfmeta.endDate = char(P.endDateString);
    pdfmeta.dataFileType = char(P.dataFileType); pdfmeta.topLevelMode = char(P.topLevelMode);
    pdfmeta.removeDomainMeanW = P.removeDomainMeanW; pdfmeta.spongeWidth = P.spongeWidth;
    pdfmeta.edges.vorticity = P.vorticityEdges; pdfmeta.edges.strain = P.strainEdges; pdfmeta.edges.w = P.wEdges;
    pdfmeta.source = rel_to_root(f, C.box_root);
    pdfmeta.nBins = P.nBins;
    pdfmeta.targetDatasetIndex = P.targetDatasetIndex;   % index into datasets: grid all fields are interpolated to
    pdfmeta.normalizeVorticity = P.normalizeVorticity; pdfmeta.normalizeStrain = P.normalizeStrain;
    pdfmeta.depthTag = char(P.depthTag);
    pdfmeta.selectedLevel = P.selectedLevel;              % dataset x day: s-level used (top level)
    pdfmeta.selectedDepthMeters = P.selectedDepthMeters;  % dataset x day: its depth (m)
    pdfmeta.validPointCount = P.validPointCount;          % dataset x day
    % datasets: run (ROMS output folder) and the files read; paths are relative
    % to the ROMS output root of the machine that ran the script
    for k = 1:numel(P.datasetMeta)
        dm = P.datasetMeta(k);
        run_dir = regexprep(char(dm.rootDir), '[\\/]+$', '');
        [out_root, runname] = fileparts(run_dir);
        ds.label = char(dm.label);
        ds.domain_num = dm.domain_num;
        ds.run = runname;
        ds.grid_file = rel_path(dm.grdfile, out_root);
        ds.filePattern = char(dm.filePattern);
        ds.files = cellfun(@(x) rel_path(x, run_dir), cellstr(dm.files), 'UniformOutput', false);
        pdfmeta.datasets(k) = ds;
    end
    pdfmeta.note = ['Pooled daily-mean (avg files) PDFs of the top model level, ' pdfmeta.startDate '-' ...
        pdfmeta.endDate ' (commonDays), of the runs in datasets, interpolated to the grid of dataset ' ...
        'targetDatasetIndex (' pdfmeta.datasets(pdfmeta.targetDatasetIndex).label ') without spongeWidth ' ...
        'cells along its boundaries; ' sprintf('%d', pdfmeta.nBins) ' bins (edges). Computed by ' ...
        'calculate_roms_surface_diagnostic_period_pdfs.m (upstream/); source: the cache it wrote ' ...
        '(relative to the data root). datasets.grid_file is relative to the ROMS output root and ' ...
        'datasets.files to the run folder.'];
    save(fullfile(C.data_dir,'fig1_pdfs.mat'), 'results','pdfmeta','-v7');
    fprintf('saved fig1_pdfs.mat\n');
end

%% ------------------------------------------------------------------------
%% Patch occurrence (Fig. 1f-h, S5, S6), patch distribution (S4), 1 July (S3)
if run_patches || do_s4_only
    nrow = size(C.oif,1);
    lon_c = cell(1,nres); lat_c = cell(1,nres);
    occ = cell(nrow,nres); ndays = zeros(nrow,nres);
    fi_time = cell(nrow,nres); fi_P2 = cell(nrow,nres); fi_Psqrt = cell(nrow,nres);
    fi_P = cell(nrow,nres); fi_A = cell(nrow,nres);
    s4 = struct('dfe',{},'time',{},'dfe0731',{});
    s3 = struct('dfe',{},'dchl',{},'qlon',{},'qlat',{},'qu',{},'qv',{},'time',{});

    for ires = res_list
        ix = C.indx{ires}; iy = C.indy{ires};
        if run_patches
            g = C.grd{ires};
            tmp = mod(ncread(g,'lon_rho'),360); lon = tmp(ix,iy);
            tmp = ncread(g,'lat_rho');          lat = tmp(ix,iy);
            tmp = 1./ncread(g,'pm'); grd_dx = tmp(ix,iy);
            tmp = 1./ncread(g,'pn'); grd_dy = tmp(ix,iy);
            cell_area = grd_dx.*grd_dy;
            tmp = ncread(g,'angle'); ang = tmp(ix,iy);
            clear tmp
            lon_c{ires} = single(lon); lat_c{ires} = single(lat);
        end

        % months needed per OIF row: first two months for occurrence; June-R1
        % additionally June-September for S4 (do_s4_only: June-R1 only)
        need = cell(nrow,1);
        if run_patches
            for irow = 1:nrow
                need{irow} = C.exp_month(irow) + [0 1];
            end
        end
        need{1} = 6:9;
        psum = cell(nrow,1); for irow = 1:nrow; psum{irow} = zeros(numel(ix), numel(iy)); end
        s4(ires).dfe = zeros([numel(ix) numel(iy) 0],'single'); s4(ires).time = [];

        for mm = unique([need{:}])
            rows = find(cellfun(@(x) any(x==mm), need))';
            fc = cache(C.ctrl{ires}, 'Fe', mm);
            fprintf('[%s] ctrl Fe %d: %s\n', datestr(now,'HH:MM:SS'), mm, rel_to_root(fc, C.box_root));
            iron2 = load(fc, 'tmp_surf','time_need');
            assert(size(iron2.tmp_surf,1)==numel(ix) && size(iron2.tmp_surf,2)==numel(iy), ...
                'cache %s has size %s, grid crop is %dx%d', fc, mat2str(size(iron2.tmp_surf)), numel(ix), numel(iy));
            for irow = rows
                runname = C.oif{irow,ires};
                fo = cache(runname, 'Fe', mm);
                fprintf('[%s]   OIF Fe %s %d\n', datestr(now,'HH:MM:SS'), runname, mm);
                iron1 = load(fo, 'tmp_surf','time_need');
                first2 = run_patches && any(mm == C.exp_month(irow) + [0 1]);
                s4_days = [1 11 21 numel(iron1.time_need)];   % cache days drawn in Fig. S4
                for iday = 1:size(iron1.tmp_surf,3)
                    iday_ind2 = find(iron2.time_need == iron1.time_need(iday));
                    if isempty(iday_ind2); continue; end
                    dfe = double(iron1.tmp_surf(:,:,iday)) - double(iron2.tmp_surf(:,:,iday_ind2));
                    tday = floor(iron1.time_need(iday)/86400 + C.date_ref);
                    if first2
                        mask = dfe > thr;
                        psum{irow} = psum{irow} + mask;
                        ndays(irow,ires) = ndays(irow,ires) + 1;
                        A = sum(cell_area(mask),'omitnan');
                        bn = mask & ~[false(1,size(mask,2)); mask(1:end-1,:)];
                        bs = mask & ~[mask(2:end,:); false(1,size(mask,2))];
                        bw = mask & ~[false(size(mask,1),1), mask(:,1:end-1)];
                        be = mask & ~[mask(:,2:end), false(size(mask,1),1)];
                        % as in the original code: dx on the faces found along the
                        % first dimension, dy on those along the second (see header)
                        Pm = sum(grd_dx(bn),'omitnan') + sum(grd_dx(bs),'omitnan') + ...
                             sum(grd_dy(bw),'omitnan') + sum(grd_dy(be),'omitnan');
                        fi_time{irow,ires}(end+1) = tday;
                        fi_P{irow,ires}(end+1) = Pm; fi_A{irow,ires}(end+1) = A;
                        if A > 0
                            fi_P2{irow,ires}(end+1)    = Pm^2/(4*pi*A);   % used in the code
                            fi_Psqrt{irow,ires}(end+1) = Pm/sqrt(A);      % definition in the captions
                        else
                            fi_P2{irow,ires}(end+1) = NaN; fi_Psqrt{irow,ires}(end+1) = NaN;
                        end
                    end
                    if irow == 1   % June-R1: S4 contours and S3 snapshot
                        dclip = single(min(max(dfe,0), 2*thr));
                        if ismember(iday, s4_days)
                            s4(ires).dfe(:,:,end+1) = dclip;
                            s4(ires).time(end+1) = tday;
                        end
                        if tday == datenum(2010,7,31)
                            s4(ires).dfe0731 = dclip;
                        end
                        if run_patches && tday == s3_day
                            s3(ires).dfe = single(dfe);
                            s3(ires).time = tday;
                        end
                    end
                end
                clear iron1
            end
            clear iron2
        end
        fprintf('S4 %s: %d contours (%s)\n', C.res_label{ires}, numel(s4(ires).time), ...
            strjoin(cellstr(datestr(s4(ires).time,'mmdd'))', ' '));
        if ~run_patches; continue; end
        for irow = 1:nrow
            occ{irow,ires} = single(psum{irow}/ndays(irow,ires));
        end

        % S3: CHL anomaly and OIF velocity on 1 July (June-R1 run)
        runname = C.oif{1,ires}; mm = 7;
        d1 = load(cache(runname,'CHL',mm), 'tmp_surf','time_need');
        i1 = find(floor(d1.time_need/86400 + C.date_ref) == s3_day, 1);
        chl1 = double(d1.tmp_surf(:,:,i1)); clear d1
        d2 = load(cache(C.ctrl{ires},'CHL',mm), 'tmp_surf','time_need');
        i2 = find(floor(d2.time_need/86400 + C.date_ref) == s3_day, 1);
        s3(ires).dchl = single(chl1 - double(d2.tmp_surf(:,:,i2))); clear d2
        u1 = load(cache(runname,'u',mm), 'tmp_surf','time_need');
        v1 = load(cache(runname,'v',mm), 'tmp_surf','time_need');
        iu = find(floor(u1.time_need/86400 + C.date_ref) == s3_day, 1);
        uu = double(u1.tmp_surf(:,:,iu)); vv = double(v1.tmp_surf(:,:,iu)); clear u1 v1
        assert(isequal(size(uu), size(lon)), 'u cache size %s differs from grid %s', mat2str(size(uu)), mat2str(size(lon)));
        vel = rot(uu + 1i*vv, ang);
        st = s3_quiver_step(ires);
        s3(ires).qlon = single(lon(1:st:end,1:st:end)); s3(ires).qlat = single(lat(1:st:end,1:st:end));
        s3(ires).qu = single(real(vel(1:st:end,1:st:end))); s3(ires).qv = single(imag(vel(1:st:end,1:st:end)));
    end

    % ---- save; a subset of resolutions is merged into the existing files ----
    threshold = thr; %#ok<NASGU>
    f4 = fullfile(C.data_dir,'patchmaps_S4_contours.mat');
    if ~full_res
        s4 = merge_res(f4, 's4', s4, res_list);
        if isfile(f4)
            old = whos('-file', f4);
            if ~ismember('s4_sampling', {old.name}) || ~isequal(load(f4,'s4_sampling'), struct('s4_sampling', s4_sampling))
                warning('prep_maps:S4sampling', ['%s was written with a different S4 day selection; ' ...
                    'the resolutions not in res_list keep the old one (rebuild them with do_s4_only).'], f4);
            end
        end
    end
    save(f4, 's4','s4_sampling','threshold','-v7');
    fprintf('saved patchmaps_S4_contours.mat (resolutions %s)\n', mat2str(res_list));

    if run_patches
        lon = lon_c; lat = lat_c; res_label = C.res_label; %#ok<NASGU>
        f1 = fullfile(C.data_dir,'patchmaps_grid.mat');
        f2 = fullfile(C.data_dir,'patchmaps_occurrence.mat');
        f3 = fullfile(C.data_dir,'patchmaps_S3_july1.mat');
        if ~full_res
            lon = merge_res(f1, 'lon', lon, res_list); lat = merge_res(f1, 'lat', lat, res_list);
            occ = merge_res(f2, 'occ', occ, res_list); ndays = merge_res(f2, 'ndays', ndays, res_list);
            fi_time = merge_res(f2, 'fi_time', fi_time, res_list); fi_P2 = merge_res(f2, 'fi_P2', fi_P2, res_list);
            fi_Psqrt = merge_res(f2, 'fi_Psqrt', fi_Psqrt, res_list);
            fi_P = merge_res(f2, 'fi_P', fi_P, res_list); fi_A = merge_res(f2, 'fi_A', fi_A, res_list);
            s3 = merge_res(f3, 's3', s3, res_list);
        end
        meanFI_P2 = cellfun(@(x) mean(x,'omitnan'), fi_P2);
        meanFI_Psqrt = cellfun(@(x) mean(x,'omitnan'), fi_Psqrt);
        disp('mean FI = P^2/(4 pi A):'); disp(meanFI_P2)
        disp('mean FI = P/sqrt(A):');    disp(meanFI_Psqrt)
        save(f1, 'lon','lat','res_label','region_lon_OIF','region_lat_OIF','-v7');
        exp_label = C.exp_label; exp_month = C.exp_month; exp_region = C.exp_region; oif_runs = C.oif; ctrl_runs = C.ctrl; %#ok<NASGU>
        save(f2, 'occ','ndays','fi_time','fi_P2','fi_Psqrt','fi_P','fi_A', ...
            'meanFI_P2','meanFI_Psqrt','exp_label','exp_month','exp_region','oif_runs','ctrl_runs','threshold','-v7');
        save(f3, 's3','s3_quiver_step','threshold','-v7');
        fprintf('saved patchmaps_grid/occurrence/S3_july1.mat (resolutions %s)\n', mat2str(res_list));
    end
end

% =============================================================================
function x = merge_res(file, name, x, res_list)
% Variable NAME (resolution = column, or element of a 1 x 3 struct array) with
% the columns res_list taken from x and all others from FILE; without FILE the
% other columns stay empty.
if ~isfile(file)
    warning('prep_maps:noMerge', '%s does not exist: %s holds only resolutions %s.', ...
        file, name, mat2str(res_list));
    return
end
old = load(file, name);
y = old.(name);
if isstruct(x) && ~isequal(fieldnames(x), fieldnames(y))
    error('prep_maps:merge', '%s.%s has different fields; rebuild all resolutions (res_list = 1:3).', file, name);
end
y(:,res_list) = x(:,res_list);
x = y;
end

function p = rel_to_root(p, root)
% Path below the data root written as '<OIF_DATA_ROOT>/...' (stored strings
% carry no machine-specific absolute paths).
p = char(p);
root = regexprep(char(root), '[\\/]+$', '');   % without trailing separator
n = numel(root);
if n > 0 && strncmp(p, root, n) && numel(p) > n && any(p(n+1) == '/\')
    p = ['<OIF_DATA_ROOT>/' strrep(p(n+2:end), '\', '/')];
end
end

function p = rel_path(p, root)
% Path relative to ROOT, or only the file name if it is not below ROOT.
p = char(p);
n = numel(root);
if n > 0 && strncmp(p, root, n) && numel(p) > n && any(p(n+1) == '/\')
    p = strrep(p(n+2:end), '\', '/');
else
    [~, nm, ext] = fileparts(p); p = [nm ext];
end
end
