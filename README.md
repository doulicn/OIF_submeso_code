# Code and data for: Processes Regulating the Response to Ocean Iron Fertilization in the Subarctic Eastern North Pacific

Dou Li<sup>1</sup>, Daniele Bianchi<sup>1</sup>, Pierre Damien<sup>1</sup>, Jerome Guiet<sup>1</sup>,
Anh Le-Duy Pham<sup>1</sup>, Ling Feng<sup>1</sup>, Dennis J. McGillicuddy Jr<sup>2</sup>,
Ken O. Buesseler<sup>2</sup>, Zihua Liu<sup>2</sup>, Fei Chai<sup>3</sup>, Peng Xiu<sup>3</sup>

<sup>1</sup> Department of Atmospheric and Oceanic Sciences, University of California, Los Angeles, Los Angeles, California, USA<br>
<sup>2</sup> Woods Hole Oceanographic Institution, Woods Hole, MA, USA<br>
<sup>3</sup> State Key Laboratory of Marine Environmental Science & College of Ocean and Earth Sciences, Xiamen University, Xiamen, China

- **Article:** Geophysical Research Letters (in review)
- **This archive:** version 1.0.0, Zenodo, DOI [10.5281/zenodo.XXXXXXX](https://doi.org/10.5281/zenodo.XXXXXXX) (placeholder, assigned at release)
- **Contact:** Dou Li (corresponding author), douli@atmos.ucla.edu

## Contents

1. [Overview](#1-overview)
2. [Quick start](#2-quick-start)
3. [Figures and table](#3-figures-and-table)
4. [Options](#4-options)
5. [Method notes](#5-method-notes)
6. [Folder layout](#6-folder-layout)
7. [Data dictionary](#7-data-dictionary)
8. [Rebuilding data/ from the intermediate products](#8-rebuilding-data-from-the-intermediate-products)
9. [Provenance](#9-provenance)
10. [Third-party software and data](#10-third-party-software-and-data)
11. [Licence and citation](#11-licence-and-citation)

## 1. Overview

This package contains the MATLAB code and the processed model output needed to
reproduce every figure of the article, Figures 1-5 of the main text and
Figures S1-S12 of the Supporting Information, and its Table A1.

The study uses nested ROMS-BEC simulations around Ocean Station Papa (OSP,
50°N, 145°W) in 2010 at 12, 4 and 1 km horizontal resolution (configurations
PACMED-12KM, NEPAC-4KM and OSP-1KM), with 18 ocean iron fertilization (OIF)
experiments, Cases 1-18 of Table A1: iron releases on 2 May, 2 June, 2 July and
2 August at region R1, and on 2 June at regions R2 and R3, each at the three
resolutions, compared with control runs without iron addition (Section 9).

The package has two layers.

- **Plotting.** The 16 scripts in `plot/` and `tables/make_table_A1.m` read only
  the 15 MAT files in `data/` (30 MB) and write the figures to `figures/` and
  Table A1 to `tables/`. This layer runs on any computer with MATLAB, plus the
  free M_Map toolbox for the map figures.
- **Data preparation.** The 4 scripts in `prep/` rebuild `data/` from
  intermediate products of the analysis of the model output (650 files, about
  13.7 GB). These products are not public, so this layer documents how `data/`
  was made but cannot be run without them (Section 8).

Not included: the ROMS-BEC code, model configurations, forcing and model
output, and the analysis code that made the intermediate products from the
model output (Section 9 lists it; one of these scripts is included in
`upstream/`).

`figures/` holds the reference output of `make_all_figures`, made with MATLAB
R2025b Update 5 on macOS. The plot scripts reproduce the content of the
published figures (the PDF files included by the manuscript). Small
differences in layout and typography remain (fonts, panel sizes and spacing,
label and legend positions, tick spacing), because most published figures
were assembled from separately exported panels; the script headers describe
the larger ones. Where a published figure differs from its caption, the
header of the plot script describes the difference, and the package follows
the published figure. One difference goes beyond layout: in the published
Figure S3 the dChl panels (d) and (e) were drawn with colour limits of ±6 mg
m-3 under the ±4 mg m-3 colour bar of panel (f); the package uses ±4 in all
three panels, so (d) and (e) look more saturated (see `plot/plot_figS3.m`).

## 2. Quick start

### Requirements

| Software | Needed for | Version |
|---|---|---|
| MATLAB | everything | R2020b or later recommended; tested only on R2025b Update 5 (25.2.0.3177638). `exportgraphics` needs at least R2020a. No toolbox is needed for plotting. |
| [M_Map](https://www.eoas.ubc.ca/~rich/map.html) | Figure 1 and Figures S3-S6 | 1.4 (tested with 1.4m; the current download, 1.4o, also works) |
| TEOS-10 GSW toolbox, Image Processing Toolbox, intermediate products | rebuilding `data/` only | see Section 8 |

The reference figures were made with a copy of M_Map 1.4m in which `m_grid.m`
and `m_contour.m` carry small local edits. With the stock 1.4o download the map
figures differ slightly, in grid lines and labels, velocity vectors and the
anti-aliasing of contour lines (about 1-4 % of the pixels).

### Make M_Map available

Use one of these three ways:

1. Set the environment variable `OIF_MMAP_DIR` to the M_Map folder, the one
   that contains `m_proj.m`, before you start MATLAB
   (`export OIF_MMAP_DIR=/path/to/m_map`), or in MATLAB with
   `setenv('OIF_MMAP_DIR','/path/to/m_map')` before you call
   `make_all_figures` or `setup_paths`.
2. Copy or link the M_Map folder to `external/m_map` inside the package.
   `external/` is not part of the package; create it.
3. Put M_Map on the MATLAB path yourself. A copy that is already on the path is
   used as it is.

### Make all figures and Table A1

In MATLAB:

```matlab
addpath('/path/to/OIF_submeso_code')   % the package root
make_all_figures
```

From a shell:

```sh
export OIF_MMAP_DIR=/path/to/m_map
matlab -batch "addpath('/path/to/OIF_submeso_code'); make_all_figures"
```

The run takes about 90-100 s (86 s in MATLAB and 91 s wall time in our test,
R2025b on an Apple-silicon Mac). It writes `figures/Fig1.png` ... `FigS12.png`
and the matching PDF files (34 files), and `tables/table_A1.csv` and
`tables/table_A1.tex`. Existing files with these names are overwritten.

`make_all_figures` runs each script in its own workspace and prints the time of
each script and a summary. A script that fails is reported, the other scripts
still run, and the run ends with an error that names the failed scripts, so
`matlab -batch` exits with status 1. Without M_Map, `plot_fig1`, `plot_figS3`,
`plot_figS4` and `plot_figS5_S6` fail with the message `M_Map not found ...`,
and all other figures and the table are still made. Figures that were open
before the run are left alone.

A normal run prints three warnings, all expected:

- `MATLAB:print:ContentTypeImageSuggested` from the vector PDF export of
  Figures S1 and S11 (the PDF files are correct);
- `OIF:nanIgnored` from `make_table_A1`, about days without data in three
  domain composites (Section 5.2).

### One figure at a time

```matlab
addpath('/path/to/OIF_submeso_code'); setup_paths();
plot_fig3            % writes figures/Fig3.png and figures/Fig3.pdf
```

Every script in `plot/`, `prep/` and `tables/` adds the package root to the
path itself, so it can also be run from the MATLAB editor or with
`run('/path/to/OIF_submeso_code/plot/plot_fig3.m')`. `plot_figS5_S6` writes
both Figure S5 and Figure S6.

`setup_paths` puts the package folders at the top of the MATLAB path for the
rest of the session, so the helpers in `lib/` take precedence over functions
of the same name elsewhere on the path: `cbrewer`, `interpolate_cbrewer`,
`inpaintn` and `redblue` (versions equivalent to the File Exchange functions
of these names), and `rot` and `log_pm`. The other helpers carry the prefix
`oif_` or names that are specific to the package (the cmocean colour maps,
for example, are `oif_cmocean`). To take the package off the path again, call
`rmpath` on the folders that `setup_paths` added (the package root, `lib`,
`plot`, `prep` and `tables`); `restoredefaultpath` also removes them, but
resets the whole path to the MATLAB default, M_Map and GSW included.

Figures are always exported in the light graphics theme, also when MATLAB
(R2025a or later) uses a dark theme. The outputs in `figures/` are reproduced
pixel for pixel on the MATLAB release and platform named above; other releases
or operating systems may render fonts and anti-aliasing slightly differently,
and Figures 1 and S3-S6, whose size is set in pixels, may come out at a
slightly different size.

## 3. Figures and table

| Manuscript | LaTeX label | Published file | Script | Output | Data files (`data/`) | M_Map |
|---|---|---|---|---|---|---|
| Figure 1 | `fig:downscale` | `Fig1.pdf` | `plot/plot_fig1.m` | `figures/Fig1.png`, `.pdf` | `fig1_ab`, `fig1_pdfs`, `patchmaps_grid`, `patchmaps_occurrence` | yes |
| Figure 2 | `fig:line_cmp` | `fig2_lines.pdf` | `plot/plot_fig2.m` | `figures/Fig2.png`, `.pdf` | `ts_patch_timeseries` | no |
| Figure 3 | `fig:ensemble` | `Fig4_ensem_var.pdf` | `plot/plot_fig3.m` | `figures/Fig3.png`, `.pdf` | `ens_metrics` | no |
| Figure 4 | `fig:ensemble_corr` | `Fig5_ens_corr.pdf` | `plot/plot_fig4.m` | `figures/Fig4.png`, `.pdf` | `ens_metrics` | no |
| Figure 5 | `fig:budget_cmp` | `Fig3_ens_budget.pdf` | `plot/plot_fig5.m` | `figures/Fig5.png`, `.pdf` | `budget_ensemble` | no |
| Figure S1 | `fig:si_validation_monthly` | `fig_s1.pdf` | `plot/plot_figS1.m` | `figures/FigS1.png`, `.pdf` | `valid_model_papa`, `valid_obs_papa`, `valid_woa23_papa` | no |
| Figure S2 | `fig:si_validation_vertical` | `fig_s2.pdf` | `plot/plot_figS2.m` | `figures/FigS2.png`, `.pdf` | `valid_model_papa`, `valid_obs_papa`, `valid_woa23_papa` | no |
| Figure S3 | `fig:map_cmp` | `Fig_SI_map_diff_July1.pdf` | `plot/plot_figS3.m` | `figures/FigS3.png`, `.pdf` | `patchmaps_grid`, `patchmaps_S3_july1` | yes |
| Figure S4 | `fig:si_patch_distribution` | `Fig_SI_patch_distribution.pdf` | `plot/plot_figS4.m` | `figures/FigS4.png`, `.pdf` | `patchmaps_grid`, `patchmaps_S4_contours` | yes |
| Figure S5 | `fig:si_occurence_regions` | `Fig_SI_patch_occurence_Regions.pdf` | `plot/plot_figS5_S6.m` | `figures/FigS5.png`, `.pdf` | `patchmaps_grid`, `patchmaps_occurrence` | yes |
| Figure S6 | `fig:si_occurence_months` | `Fig_SI_patch_occurence_Months.pdf` | `plot/plot_figS5_S6.m` | `figures/FigS6.png`, `.pdf` | `patchmaps_grid`, `patchmaps_occurrence` | yes |
| Figure S7 | `fig:si_lines_cmp_max` | `Fig_SI_lines_cmp_max2.pdf` | `plot/plot_figS7.m` | `figures/FigS7.png`, `.pdf` | `ts_patch_timeseries`, `obs_series2002` | no |
| Figure S8 | `fig:si_ens_POC` | `Fig_SI_ens_variance_POC.pdf` | `plot/plot_figS8.m` | `figures/FigS8.png`, `.pdf` | `ens_metrics` | no |
| Figure S9 | `fig:si_ens_budget_groups` | `Fig_ens_budget_groups.pdf` | `plot/plot_figS9.m` | `figures/FigS9.png`, `.pdf` | `budget_ensemble` | no |
| Figure S10 | `fig:si_fe_dic_profiles` | `Fig_SI_Fe_DIC_profile.pdf` | `plot/plot_figS10.m` | `figures/FigS10.png`, `.pdf` | `profile_Fe_DIC` | no |
| Figure S11 | `fig:si_coarse_grain_winter` | `Fig_SI_coarse_grain678.pdf` | `plot/plot_figS11.m` | `figures/FigS11.png`, `.pdf` | `coarsegrain_hovmoller` | no |
| Figure S12 | `fig:si_coarse_grain_seasonal` | `Fig_coarse_grain_FeDIC.pdf` | `plot/plot_figS12.m` | `figures/FigS12.png`, `.pdf` | `coarsegrain_hovmoller` | no |
| Table A1 | `tab:oif_experiments` | (table in the main text) | `tables/make_table_A1.m` | `tables/table_A1.csv`, `tables/table_A1.tex` | `ens_metrics`, `ts_patch_timeseries` | no |

- "Published file" is the file that the manuscript source includes for the
  figure. The files of Figures 3-5 carry their numbers from before the
  revision: `Fig4_ensem_var.pdf` is Figure 3, `Fig5_ens_corr.pdf` is Figure 4
  and `Fig3_ens_budget.pdf` is Figure 5. Script names, output names and code
  comments of the package use the numbers of the compiled manuscript.
- PNG files are written at 400 dpi, except Figures 1 and S3-S7 (300 dpi). The
  PDF files are vector graphics, except Figures 1 and S3-S6, which are 300-dpi
  images.
- `make_table_A1` writes `table_A1.csv` (six decimals, units in the column
  names) and `table_A1.tex` (the body rows of the LaTeX table in the column
  order of the manuscript; patch area and CO2 with 2 decimals, the other
  columns with 3). Six 100-m POC values in `table_A1.tex` differ from the
  manuscript by up to 0.005, because the manuscript gives the POC values of
  10 or more to four significant digits (Section 5.7). `T = make_table_A1`
  also returns the table, and
  `make_table_A1('main_revised.tex')` compares every cell with the table in a
  manuscript source file.

## 4. Options

The defaults reproduce the published figures, except that Figures 3c and S8a
now use the domain integral by default (`integral_area = 'patch'` reproduces
the originally published panels). `make_all_figures` always uses the defaults.
To use an option, run the script by hand.

| Option | Script | Values (default first) | Effect | Output |
|---|---|---|---|---|
| `integral_area` | `plot_fig2` | `'patch'`, `'domain'` | Integrals of Figure 2e,f over the fertilized patch (as published) or over the OSP-1KM analysis domain (the integral of Figures 3c,d, S8 and 4 and Table A1) | `Fig2_domain` (`.png`, `.pdf`) |
| `integral_area` | `plot_fig3`, `plot_figS8` | `'domain'`, `'patch'` | Integrals of Figures 3c and S8a over the OSP-1KM analysis domain (label int_A, as in Figures 3d and 4 and Table A1) or over the fertilized patch (label int_P, as originally published) | `Fig3_patch`, `FigS8_patch` (`.png`, `.pdf`) |
| `errorbar_stat` | `plot_fig3`, `plot_figS8` | `'pooled'`, `'subset'` | Statistic of the red and blue error bars (Section 5.3) | `Fig3_subset`, `FigS8_subset`; with both options `Fig3_patch_subset`, `FigS8_patch_subset` |
| `use_caption_seasons` | `plot_figS11` | `false`, `true` | Months of Figure S11(e,f): June-July and December-January (as published) or June-August and December-February | `FigS11_caption_seasons` |
| `avg_months` | `plot_figS12` | `[6 7]`, any months within 6-9 | Months averaged in Figure S12; `[6 7 8]` gives June-August. The OIF run has coarse-grained fluxes for June-September only. | `FigS12_months_6_7_8` (for `[6 7 8]`) |
| `uniform_30day_window` | `prep_validation` | `false`, `true` | Smoothing of the model series of Figure S1(a-e): `edata_freq*30` samples as in the original code (30/60/36/30 days at 1/4/12/25 km) or 30 days for every run (Section 5.4). Needs the intermediate products. | rewrites `data/valid_model_papa.mat`; run `plot_figS1` afterwards |
| `do_fig1ab`, `do_pdfs`, `do_patches` | `prep_maps` | `true`, `false` | Rebuild the data of Figure 1a,b, of Figure 1c-e, and of the patch maps (Figures 1f-h and S3-S6) | `data/fig1_ab.mat`, `fig1_pdfs.mat`, the four `patchmaps_*.mat` |
| `do_s4_only` | `prep_maps` | `false`, `true` | Rebuild only `patchmaps_S4_contours.mat` (the three switches above are then ignored) | `data/patchmaps_S4_contours.mat` |
| `res_list` | `prep_maps` | `1:3` | Resolutions processed (1, 2, 3 = 1, 4, 12 km). With a subset, the processed resolutions are merged into the existing `patchmaps_*.mat` files. | as above |

Workspace switches are set as variables before the script runs, for example

```matlab
integral_area = 'patch'; errorbar_stat = 'subset';
plot_fig3                          % writes figures/Fig3_patch_subset.png and .pdf
clear integral_area errorbar_stat  % otherwise they stay in effect for later scripts
```

```matlab
do_fig1ab = false; do_pdfs = false; res_list = 3;
prep_maps                          % rebuilds the 12-km patch maps only
clear do_fig1ab do_pdfs res_list   % otherwise they stay in effect
```

The same applies to `use_caption_seasons`, `avg_months`,
`uniform_30day_window`, `do_patches` and `do_s4_only`: clear them after use.
The plot options write their own output files and never overwrite the default
figures; `uniform_30day_window` and the `prep_maps` switches rewrite files in
`data/`.

## 5. Method notes

These notes describe what the code computes. Each plot script header gives the
details for its figure.

### 5.1 Fertilized patch and filamentation index (FI)

- The fertilized patch of a day is the set of grid cells where the surface
  dissolved-iron anomaly, OIF minus control, exceeds 2e-5 mmol m-3
  (`C.patch_threshold` in `oif_config.m`).
- FI is computed as **`FI = P^2/(4*pi*A)`**. A is the summed area of the patch
  cells, and P is the summed length of the cell faces on the patch boundary.
  FI equals 1 for an ideal circle. Because P is measured along the grid-cell
  faces, a well-resolved disk on the grid gives FI of about 1.6-1.8; FI grows
  as the patch becomes more elongated.
- As in the original code, faces found along the first grid dimension are
  weighted with dx = 1/pm and faces along the second dimension with
  dy = 1/pn. Over the patch cells dx/dy is about 0.98, 0.97 and 1.00 at 1, 4 and
  12 km, so this changes P by at most about 1.5, 3 and 0.1 % compared with
  exact face lengths.
- All FI values in the figures use this formula: the mean FI in Figures
  1f-h, S5 and S6, the FI of Figure 3a and its variance partition in Figure 3d.
  The mean is taken over the first two months: day 2 of the release month to the
  end of the following month (60 days; 61 for the July releases).
- The manuscript defines FI = `P/sqrt(A)`. `data/patchmaps_occurrence.mat` also
  stores this ratio (`fi_Psqrt`, `meanFI_Psqrt`). For Cases 1-3 the two
  definitions give 39.43, 17.23 and 6.53 (`P^2/(4*pi*A)`) and 21.04, 13.83 and
  8.65 (`P/sqrt(A)`).

### 5.2 Patch integrals and domain integrals

Two spatial integrals are used. The **patch** integral sums over the fertilized
patch of each day. The **domain** integral sums over the OSP-1KM analysis
domain: the 1-km model domain without a 15-cell band along its open
boundaries, mapped onto the grid of each resolution (shown as the dashed red
polygon in the maps; area 7.48e5 km2 on the 1-km grid, 7.27e5 km2 on the 4-km
grid and 7.28e5 km2 on the 12-km grid). In the file names of the original
analysis these are the composites with the tags LS11 and LS12 (Section 9.4).

| Panel | Quantity | Integral |
|---|---|---|
| Fig. 2a-d | patch area; patch mean, maximum, minimum and 5th-95th percentiles of surface dFe, dNO3, dChl | patch |
| Fig. 2e,f | cumulative POC flux anomaly at 100 m and 500 m and air-sea CO2 flux anomaly | patch (`integral_area = 'domain'` for the domain) |
| Fig. 3a,b | mean FI; 60-day mean patch area | patch |
| Fig. 3c | 60-day CO2 flux anomaly | domain (`integral_area = 'patch'` for the patch, as originally published) |
| Fig. 3d | variance partition of FI, patch area and the 60-day CO2 flux anomaly | domain (CO2) |
| Fig. 4 | y: 60-day CO2 flux anomaly; x: (a) 60-day mean patch area, (b) patch-area weighted mean control-run PHYC, (c) patch-integrated control-run PHYC | y: domain; x: patch |
| Fig. 5, S9 | Fe and DIC budget terms, upper 50 m, two-month window | domain |
| Fig. S7 | patch mean (area-weighted sum / patch area), maximum, minimum, 5th-95th percentiles | patch |
| Fig. S8a | 60-day POC flux anomaly at 100 m | domain (`integral_area = 'patch'` for the patch, as originally published) |
| Fig. S8b-d | variance partition and correlations of the POC flux anomaly | domain |
| Fig. S10 | Fe and DIC profiles, June-July mean | domain |
| Table A1 | CO2 and POC flux anomalies; patch area; PHYC (Section 5.7) | domain; patch area: patch |

- In the published figures, panels with patch integrals and panels with domain
  integrals carry the same label, an integral with subscript A, which Table A1
  uses for domain integrals. After 60 days the domain integrals of Cases 1-3
  are 14-25 % (POC at 100 m, CO2) and 24-37 % (POC at 500 m) larger than the
  patch integrals.
- **60-day windows.** The 60-day sums and the 60-day mean patch area start at
  the first day with a non-empty patch in the composite used. That is day 2 of
  the release month, except for the domain composites of Cases 5, 8 and 11
  (4 km; May, July and August releases), where it is day 3.
- **Missing days.** The domain composites of Cases 5, 8 and 11 have no data on
  2, 1 and 2 days of their 60-day windows, the first day of a month. These days
  are left out of the sums, as in the original analysis and the published
  values. `make_table_A1` prints a warning about it.
- **Units.** Time-integrated fluxes are in mmol C (sums of daily integrals in
  mmol C d-1). The right axes in tons of carbon use 1 mmol C = 1.2e-8 t C
  (`C.mmolC_to_tC`, 12 g C per mol). The air-sea CO2 flux is positive into the
  ocean.

### 5.3 Ensemble error bars (Figures 3a-c and S8a)

The red and blue error bars are computed by `lib/ens_resolution_stats.m`,
separately at each resolution. Standard deviations use N-1.

- `errorbar_stat = 'pooled'` (default, as published):
  - **red:** mean and standard deviation of the four release-month values
    (May, June, July, August). The June value is the mean of the three June
    runs (regions R1-R3).
  - **blue:** mean and standard deviation of the three release-region values
    (R1, R2, R3). The R1 value is the mean of the four R1 runs (May-August).
  - Both statistics therefore use all six runs of a resolution. The legend
    labels 'R1, n=12' and 'June, n=9' are those of the published figure.
- `errorbar_stat = 'subset'`: red from the four R1 runs (May-August) and blue
  from the three June runs (R1-R3) of each resolution, the subsets that the
  captions describe. The legend gives n from the data.

**Variance partition (Figures 3d and S8b).** `lib/variance_two_way.m` computes
a balanced two-way partition of the sum of squares (Appendix B of the
article). It is applied to two subsets: R1 (Cases 1-12; release month x
resolution) and June (Cases 1-3 and 13-18; release region x resolution).

**Budgets (Figures 5 and S9).** Each budget term, OIF minus control, is
integrated over the upper 50 m and the analysis domain. It is accumulated over
the days after the first day of the release month up to the end of the
following month, keeping the days on which the domain sums of both runs are
non-zero. The bars are ensemble means and the error bars +-1 standard
deviation, over the 18 runs in Figure 5 and over the runs of each resolution
or group in Figure S9. The numbers in Figure 5 are the mean term and its
standard deviation, both divided by the mean surface-flux term; the numbers in
Figure S9 are the group-mean term divided by the group-mean surface-flux term.

### 5.4 Model-observation comparison (Figures S1 and S2)

- **Station column.** The model series are taken from the station output of
  four runs at 1, 4, 12 and 25 km (Section 9.2). Upper-30 m means use the layer
  thicknesses of the OSP-1KM grid column at the station for all four runs, as
  in the original code.
- **Smoothing (Figure S1a-e).** The model series are low-pass filtered with
  `lib/fft_lowpass.m` (FFT smoothing, method of Press et al., 1986) over
  `edata_freq*30` samples, as in the original code. The station output is
  sampled every 0.5, 1, 0.6 and 24 h at 1, 4, 12 and 25 km, so the effective
  windows are 30, 60, 36 and 30 days (`smooth_samples`, `smooth_days` in
  `data/valid_model_papa.mat`). The option `uniform_30day_window` (Section 4)
  uses 30 days for every run.
- **Mixed-layer depth (Figure S1f).** Model and WOA23 MLD is the shallowest
  level at which potential density (sigma0) exceeds its 10-m value by more
  than 0.03 kg m-3. The Argo values are the `MLD2` of the processed Argo files,
  which do not record their criterion (see the header of `plot/plot_figS1.m`).
- **Seasons (Figure S2).** The model profiles are June-August 2010 means. The
  WOA23 profiles are means of the June, July and August climatologies, with
  shading = mean of the monthly standard deviations. The in situ (Line P /
  Station P) and Argo profiles are column 3 of their seasonal composite files,
  which holds July-September (months 7-9 in the Argo processing script; the
  Argo file labels the column 'fall'), with shading = +-1 standard deviation.
  They are stored as `insitu_jas*` and `argo_jas*` in
  `data/valid_obs_papa.mat`.
- **Density.** Panel (b) of Figures S1 and S2 shows potential density sigma0
  (kg m-3). For the model and WOA23 it is computed with the GSW toolbox in
  `prep/prep_validation.m`; the observed values come from the processed
  observation files.

### 5.5 Patch evolution (Figure S4)

The contours show dFe = 2e-5 mmol m-3 of the June-R1 runs on cache days 1, 11
and 21 and on the last day of each monthly file, June-September 2010:
2, 12, 22 and 30 June; 1, 11, 21 and 31 July; 1, 11, 21 and 31 August; and
1, 11, 21 and 30 September. The June file starts on 2 June. The colour of a
contour follows its date (16 colours, 4 per month); the 31 July contour is
drawn in black on top of its coloured contour.

### 5.6 Coarse-grained vertical fluxes (Figures S11 and S12)

- **Run.** All panels of Figure S11 show the full-year (2010) 1-km control run
  without iron addition, `OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear`
  (`C.cg_ctrl`).
- **Months of S11(e,f).** June-July and December-January means; the mean MLD
  lines are 32.6 m and 101.2 m. `use_caption_seasons = true` uses June-August
  and December-February (29.8 m and 101.9 m).
- **Figure S12.** Control = the same full-year 1-km run; OIF = Case 1 (June
  release at R1, 1 km), whose coarse-grained fluxes cover 2 June-30 September.
  Both are averaged over June-July. The black line is the mean control-run MLD
  over the same days, drawn in all four panels. The 1-km control run paired
  with the OIF runs elsewhere (`C.ctrl{1}`, May-September) has no coarse-grained
  fluxes.
- **Diagnostic.** k[w*] = d(w*)/d(scale), the difference of the cumulative
  sub-filter-scale flux between adjacent filter scales. Units: k[wb] in
  m2 s-3 km-1; k[wFe] and k[wDIC] in mmol m-2 s-1 km-1. The fluxes are
  horizontal averages over the 690 x 1050 interior cells of the OSP-1KM grid,
  i.e. without a 20-cell band along its open boundaries (208.3-219.7°E,
  46.2-57.7°N).

### 5.7 Table A1, PHYC column

- **As published.** The published values of the PHYC column are the 60-day sums
  of the domain-integrated surface phytoplankton carbon anomaly, OIF minus
  control (`dom.PHYC_surf` in `data/ts_patch_timeseries.mat`; 18 of 18 values
  agree).
- **As described by the caption.** The table caption describes the control-run
  PHYC integrated over the fertilized patch. That is the x-axis quantity of
  Figure 4c (`xls_ctrlPHYC_int` in `data/ens_metrics.mat`).
- `tables/table_A1.tex` reproduces the published column, and
  `tables/table_A1.csv` holds both quantities (columns
  `PHYC_published_dPHYC_domain_...` and `PHYCctrl_patch_Fig4c_...`).
- Both are sums of 60 daily area integrals of a surface concentration, with
  units mmol m-3 x m2 x d = mmol m-1 d (1e12 in the table).
- Compared with `main_revised.tex`, 174 of the 180 cells agree. The other six
  are 100-m POC values of 10 or more, which the manuscript gives to four
  significant digits.

## 6. Folder layout

```
OIF_submeso_code/
├── README.md               this file
├── LICENSE                 MIT licence of the package code
├── LICENSES/               CC BY 4.0 (data, tables, figures) and the third-party licences
├── THIRD_PARTY_NOTICES.md  third-party code, package-written replacements, external software
├── CITATION.cff            citation metadata
├── .zenodo.json            Zenodo metadata
├── make_all_figures.m      driver: all figures and Table A1; make_all_figures(true) first rebuilds data/
├── oif_config.m            paths (environment variables), run names, constants
├── setup_paths.m           adds the package folders, M_Map and GSW to the MATLAB path
├── plot/                   16 plot scripts (plot_fig1 ... plot_figS12; plot_figS5_S6 makes two figures)
├── tables/                 make_table_A1.m and its outputs table_A1.csv, table_A1.tex
├── prep/                   4 scripts that rebuild data/ from the intermediate products
├── lib/                    helper functions (package-written and third-party, see THIRD_PARTY_NOTICES.md)
├── data/                   15 MAT files with the processed data behind every figure (Section 7)
├── figures/                reference output of the plot scripts (PNG and PDF)
├── upstream/               author's script that computed the Figure 1c-e PDFs (not run by the package)
└── external/               (not included) optional place for M_Map (external/m_map) and GSW (external/gsw)
```

## 7. Data dictionary

All files are MATLAB v7 MAT files. They can be read with `load` in MATLAB or
with `scipy.io.loadmat` in Python.

**Conventions**

- Times are MATLAB datenums (days; `datenum(2010,1,1)` = 734139).
- Longitude is in degrees east (0-360) and latitude in degrees north unless
  stated.
- Depth is in m, negative downward, unless stated.
- "OIF - control" is the difference of the OIF run and its control run.
- Run order is Case 1-18 of Table A1 unless stated. Resolution index 1, 2, 3 =
  1, 4, 12 km.
- Units are as stored. "Not recorded" means that neither the file nor the code
  states them.

**Overview**

| File | Size | Written by | Used by | Contents |
|---|---|---|---|---|
| `budget_ensemble.mat` | 9 kB | `prep_budgets_profiles_coarsegrain` | Fig. 5, S9 | Fe and DIC budget terms of the 18 runs |
| `coarsegrain_hovmoller.mat` | 0.7 MB | `prep_budgets_profiles_coarsegrain` | Fig. S11, S12 | coarse-grained vertical fluxes, MLD, Zeu |
| `ens_metrics.mat` | 16 kB | `prep_timeseries_ensemble` | Fig. 3, 4, S8, Table A1 | 60-day metrics, FI, variance partition, correlations |
| `fig1_ab.mat` | 3.4 MB | `prep_maps` | Fig. 1a,b | WOA23 and model surface NO3, grid outlines, release regions |
| `fig1_pdfs.mat` | 23 kB | `prep_maps` (copy of the cache of `upstream/`) | Fig. 1c-e | PDFs of Ro, S/f, `w - <w>` |
| `obs_series2002.mat` | 2 kB | `prep_timeseries_ensemble` | Fig. S7 | SERIES 2002 observations |
| `patchmaps_grid.mat` | 6.7 MB | `prep_maps` | Fig. 1, S3-S6 | longitude and latitude of the map sub-domains |
| `patchmaps_occurrence.mat` | 0.7 MB | `prep_maps` | Fig. 1f-h, S5, S6 | patch occurrence maps, daily FI |
| `patchmaps_S3_july1.mat` | 1.1 MB | `prep_maps` | Fig. S3 | dFe, dChl and velocity on 1 July 2010 |
| `patchmaps_S4_contours.mat` | 15.9 MB | `prep_maps` | Fig. S4 | dFe of the June-R1 runs on 16 dates |
| `profile_Fe_DIC.mat` | 5 kB | `prep_budgets_profiles_coarsegrain` | Fig. S10 | Fe and DIC profiles, Cases 1-3 and controls |
| `ts_patch_timeseries.mat` | 1.0 MB | `prep_timeseries_ensemble` | Fig. 2, S7, Table A1 | daily patch and domain statistics of the 18 runs |
| `valid_model_papa.mat` | 2.0 MB | `prep_validation` | Fig. S1, S2 | model series and profiles at Ocean Station Papa |
| `valid_obs_papa.mat` | 0.1 MB | `prep_validation` | Fig. S1, S2 | in situ, Argo and MODIS observations at Station Papa |
| `valid_woa23_papa.mat` | 37 kB | `prep_validation` | Fig. S1, S2 | WOA23 climatology at Station Papa |

Several files also contain a `README`, `note` or `units` text, which `load`
shows.

### `budget_ensemble.mat`

Variable `budget` (struct). Its 18 columns follow the order of the original
analysis, **not** Case order: 1-km May, Jun, Jul, Aug; 4-km May-Aug; 12-km
May-Aug; June-R2 at 1, 4, 12 km; June-R3 at 1, 4, 12 km. The Case number of a
column is `3*(run_row-1) + run_res`.

| Field | Class, size | Units | Meaning |
|---|---|---|---|
| `budget.Fe`, `budget.DIC` | struct | | Fe budget (10 terms) and DIC budget (9 terms), fields below |
| `.var` | cell 1×10 / 1×9 | | term names in the composite files: `Fe_NET Fe_PHY Fe_BIO Fe_FLUXsurf Fe_HADV Fe_ADZ Fe_MIX Fe_PHOTO Fe_PROD Fe_SCAVENGE` and `DIC_NET DIC_PHY DIC_BIO DIC_FGCO2 DIC_HADV DIC_ADZ DIC_MIX DIC_PHOTOC DIC_PROD` |
| `.label` | cell 1×10 / 1×9 | | LaTeX tick labels: NET, PHY, BIO, FLUX^surf, HADV, VADV (= ADZ), MIX, UPTAKE (= PHOTO, PHOTOC), ReGen (Fe_PROD) or REMIN (DIC_PROD), SCAV |
| `.factor` | double 1×10 / 1×9 | | sign applied to each term: -1 for uptake and scavenging (sinks), +1 otherwise |
| `.name` | char | | tracer name of the original variable lists (`'Fe'`, `'C'`) |
| `.oif`, `.ctrl`, `.diff` | double 10×18 / 9×18 (term × run) | mmol (Fe: mmol Fe; DIC: mmol C) | term integrated over the upper 50 m and the analysis domain and accumulated over the analysis window, for the OIF run, the control run and OIF - control (sign factor applied) |
| `.ndays` | double, term × run | days | days in the analysis window (59-61) |
| `.dims` | char | | `'term x run'` |
| `budget.run_name` | cell 1×18 | | OIF run of each column |
| `budget.run_label` | cell 1×18 | | label of each column, e.g. `1KM_May`, `12KM_Jun_R3` |
| `budget.run_res` | double 1×18 | | resolution index (1, 2, 3 = 1, 4, 12 km) |
| `budget.run_row` | double 1×18 | | release experiment: row of `C.oif` (1 Jun-R1, 2 May-R1, 3 Jul-R1, 4 Aug-R1, 5 Jun-R2, 6 Jun-R3) |
| `budget.win_month` | double 18×2 | month | first and last month of the analysis window (release month and the following month) |
| `budget.units`, `budget.note` | char | | units and definition of the integral |

### `coarsegrain_hovmoller.mat`

Variable `cg` (struct). Fluxes are horizontal averages over the 690 × 1050
interior cells of the OSP-1KM grid (Section 5.6).

| Field | Class, size | Units | Meaning |
|---|---|---|---|
| `cg.ctrl_run` | char | | full-year 1-km control run (Figure S11 and the control panels of Figure S12) |
| `cg.oif_run` | char | | Case 1 run (OIF panels of Figure S12) |
| `cg.months_S11` | cell 1×2 | month | `{[6 7], [12 1]}`: months averaged in Figure S11(e) and (f) |
| `cg.months_S12` | double 1×2 | month | `[6 7]`: months averaged in Figure S12 |
| `cg.time` | double 365×1 | datenum | days of 2010 (time axis of `w50`, `valid50`, `valid`, `mld_all`) |
| `cg.scale` | double 69×1 | km | filter scales l (1.0-621 km) |
| `cg.dep` | double 20×1 | m, positive downward | depths of `wz_month` (5-150 m) |
| `cg.dep50` | double 1×1 | m | depth of the Hovmöller panels (50 m) |
| `cg.mld_all` | double 365×1 | m, positive downward | daily mean mixed-layer depth of the control run over the analysis domain (LS12 composite; the MLD definition of the model-output caches is not recorded in this package); NaN on one day |
| `cg.mld_date`, `cg.mld` | double 364×1 | datenum, m | the days with an MLD value and those values (Figure S11a) |
| `cg.mld_all_oif` | double 365×1 | m | the same for the Case 1 run; all NaN (the cache holds no values) |
| `cg.zeu_time` | double 12×1 | datenum | 15th of each month |
| `cg.zeu` | double 12×1 | m, positive downward | monthly mean euphotic depth of the control run (mean over the cells of the OSP-1KM domain without its 15-cell boundary band) |
| `cg.wb_ctrl`, `cg.wFe_ctrl`, `cg.wDIC_ctrl` | struct | | cumulative sub-filter-scale vertical fluxes F(l) of buoyancy, Fe and DIC of the control run, fields below |
| `cg.wFe_oif`, `cg.wDIC_oif` | struct | | the same for Case 1 (data 2 June-30 September only) |
| `.w50` | single 365×69 (day × scale) | wb: m2 s-3; wFe, wDIC: mmol m-2 s-1 | F(l) at 50 m; NaN on days without data |
| `.valid50` | logical 365×1 | | days drawn in the 50-m Hovmöller panels |
| `.valid` | logical 365×1 | | days that pass the validity test of the original code (all true) |
| `.wz_month` | double 20×69×12 (depth × scale × month) | as `w50` | monthly mean of F(l) over the valid days of each month of 2010 (NaN for months without data) |
| `.nday_month` | double 1×12 | days | number of days behind each monthly mean (weights for averages over several months) |
| `.file` | char | | source netCDF file, relative to the data root |
| `cg.units` | struct | | units of `wb`, `wFe`, `wDIC`, `filtscale`, `depth`, `time` |
| `cg.note` | char | | definitions, units and averaging domain |

### `ens_metrics.mat`

36 variables, one value per run in Case order. "60-day" quantities cover the
window of Section 5.2.

| Variable | Class, size | Units | Meaning |
|---|---|---|---|
| `README` | char | | description |
| `run` | cell 18×1 | | OIF run directory |
| `label` | cell 18×1 | | experiment label (Table A1), e.g. `1KM_Jun`, `4KM_Jun_R2` |
| `res_id`, `exp_id` | double 18×1 | | resolution index (1, 2, 3 = 1, 4, 12 km); release experiment (row of `C.oif`, see `budget_ensemble.mat`) |
| `month`, `region`, `res` | cell 18×1 | | release month (`'Jun'` ...), region (`'R1'` ...), resolution (`'1KM'` ...) |
| `month_id`, `region_id` | double 18×1 | | index into `month_names`, `region_names` |
| `month_names`, `region_names` | cell 4×1, 3×1 | | `{Jun, May, Jul, Aug}`, `{R1, R2, R3}` |
| `patch_area_60` | double 18×1 | km2 | 60-day mean surface patch area (Figure 3b, Table A1) |
| `int_patch_CO2`, `int_patch_POC100`, `int_patch_POC500` | double 18×1 | mmol C | 60-day sum of the daily patch integral of the OIF - control air-sea CO2 flux, POC flux at 100 m and POC flux at 500 m (Figures 3c, S8a with `integral_area = 'patch'`) |
| `int_dom_CO2`, `int_dom_POC100`, `int_dom_POC500` | double 18×1 | mmol C | the same over the analysis domain; equal to `xls_CO2`, `xls_POC100`, `xls_POC500` (Figures 3c, S8a, Table A1) |
| `units` | struct | | unit strings: `units.patch_area_60` (km2), `units.int` (the `int_*` integrals), `units.xls` (the `xls_*` values) |
| `fi_series` | cell 18×1 of double 1×60 or 1×61 | | daily FI = `P^2/(4*pi*A)`, day 2 of the release month to the end of the following month |
| `fi_time` | cell 18×1 | datenum | days of `fi_series` |
| `fi_mean` | double 18×1 | | mean FI (Figure 3a); equal to `meanFI_P2` of `patchmaps_occurrence.mat` to 7e-15 |
| `xls_CO2`, `xls_POC100`, `xls_POC500` | double 18×1 | mmol C | 60-day domain integrals from the summary tables of the original analysis (`Statistics_InOutPatch_*.xlsx`); used for Figures 3d, 4, S8b-d and Table A1 |
| `xls_POC` | double 18×1 | mmol C | first POC row of that table (= `xls_POC100`); y-axis of Figure S8c,d |
| `xls_CO2_patchfile` | double 18×1 | mmol C | CO2 integral from the patch table (= `int_patch_CO2`) |
| `xls_area_CO2`, `xls_area_POC`, `xls_area_all` | double 18×1 | km2 | 60-day mean patch area from the patch table: CO2 rows (x-axis of Figure 4a), POC rows (x-axis of Figure S8c), mean of all rows (= `patch_area_60` to 5e-16) |
| `xls_ctrlPHYC_wavg` | double 18×1 | mmol C m-3 | patch-area weighted mean surface PHYC of the control run over the 60 days (Figure 4b) |
| `xls_ctrlPHYC_int` | double 18×1 | mmol C m-1 d | sum of the 60 daily patch integrals of the control-run surface PHYC (Figure 4c, Figure S8d; Section 5.7) |
| `var` | struct | % | variance partition: `metric` (FI, PatchArea, CO2_FLUX, POC_FLUX_100m, POC_FLUX_500m); `pct_R1` (5×3: release time, resolution, interaction; Cases 1-12); `pct_June` (5×3: region, resolution, interaction; Cases 1-3, 13-18); `R1_names`, `June_names`; `pct_R1_patchCO2`, `pct_June_patchCO2`, `pct_R1_patchPOC100`, `pct_June_patchPOC100` (the same applied to the patch integrals; not plotted). Inputs: `fi_mean`, `xls_area_all`, `xls_CO2`, `xls_POC100`, `xls_POC500`. |
| `corr` | struct | | six regressions, each a struct with `x`, `y` (18×1), `fit_coef` (slope and intercept of the least-squares line), `R` (Pearson) and `P` (p-value): `dCO2_FLUX_int_vs_PatchArea`, `dCO2_FLUX_int_vs_ctrlPHYC_wavg`, `dCO2_FLUX_int_vs_ctrlPHYC_int` (Figure 4a-c; y = `xls_CO2`) and `dPOC_FLUX_int_vs_PatchArea`, `dPOC_FLUX_int_vs_ctrlPHYC_wavg`, `dPOC_FLUX_int_vs_ctrlPHYC_int` (y = `xls_POC`; Figure S8c,d use the first and the third) |
| `check_vs_cache` | struct | | differences of the recomputed values from the cached results of the original analysis (all below 5e-14): `var_stacked_R1`, `var_stacked_June`, `var_FilamentationIndex`, `var_PatchArea`, `var_CO2_FLUX`, `var_POC_FLUX_100m`, `var_POC_FLUX_500m` (maximum absolute difference of the variance percentages) and `corr_<regression>` for the six regressions of `corr` (1×4: difference of R, difference of P, maximum relative difference of x and of y) |

### `fig1_ab.mat`

| Variable / field | Class, size | Units | Meaning |
|---|---|---|---|
| `woa.lon`, `woa.lat` | single 1×360, 1×180 | °E, °N | WOA23 1-degree grid |
| `woa.no3_jja` | single 180×360 (lat × lon) | µmol kg-1 (WOA23 as distributed, not converted) | WOA23 objectively analysed nitrate (`n_an`, all-period monthly climatology) at the surface, mean of June, July and August; land and missing cells filled with `inpaintn` (Figure 1a) |
| `outline` | struct 1×3 | | outlines of the model grids: (1) 12 km, (2) 4 km, (3) 1 km |
| `outline(k).lon`, `.lat` | single 1×N | °E (grid longitude + 360), °N | perimeter of the rho-point grid |
| `outline(k).label` | char | | `'12KM'`, `'4KM'`, `'1KM'` |
| `model.no3_jja` | single 600×521 | mmol m-3 | June-August 2010 mean surface NO3 of the 4-km control run, cropped 4-km grid (Figure 1b) |
| `model.lon`, `model.lat` | single 600×521 | °E, °N | coordinates of `model.no3_jja` |
| `model.ndays` | double 1×1 | | number of valid point × day samples behind the mean |
| `model.source` | char | | source cache, relative to the data root |
| `region_lon_OIF`, `region_lat_OIF` | cell 1×3 of double 1×5 | °E, °N | closed outlines of the release regions R1, R2, R3 |

### `fig1_pdfs.mat`

Copy of the cache written by `upstream/calculate_roms_surface_diagnostic_period_pdfs.m`
(see `upstream/README.md`). Nothing in it is computed by the package.

| Variable / field | Class, size | Units | Meaning |
|---|---|---|---|
| `results` | struct 1×3 | | (1) 12 km, (2) 4 km, (3) 1 km; fields below |
| `.label` | char | | `'12 km'`, `'4 km'`, `'1 km'` |
| `.vorticityCounts`, `.strainCounts`, `.wCounts` | double 1×160 | counts | pooled histograms of Ro = zeta/f, S/abs(f) and `w - <w>` |
| `.vorticityCenters`, `.strainCenters`, `.wCenters` | double 1×160 | dimensionless; dimensionless; m s-1 | bin centres |
| `.vorticityPdf`, `.strainPdf`, `.wPdf` | double 1×160 | inverse of the variable's unit | PDF = counts / (samples × bin width); NaN for empty bins |
| `.fileCount` | double | days | number of daily files (91) |
| `.vorticitySamples`, `.strainSamples`, `.wSamples` | double | | number of values pooled |
| `pdfmeta.commonDays` | char 91×8 | yyyymmdd | days used (2 June-31 August 2010) |
| `pdfmeta.startDate`, `.endDate` | char | yyyymmdd | `'20100602'`, `'20100831'` |
| `pdfmeta.dataFileType` | char | | `'avg'` (daily-mean output files) |
| `pdfmeta.topLevelMode`, `.depthTag` | char | | `'last'`, `'depth_last'`: the top model level is used |
| `pdfmeta.removeDomainMeanW` | logical | | true: the daily domain mean of w is removed |
| `pdfmeta.spongeWidth` | double | grid cells | 15: band removed along the boundaries of the 1-km target grid |
| `pdfmeta.edges` | struct | | bin edges (1×161) of `vorticity`, `strain`, `w` |
| `pdfmeta.nBins` | double | | 160 |
| `pdfmeta.targetDatasetIndex` | double | | 3: all fields are interpolated to the 1-km grid |
| `pdfmeta.normalizeVorticity`, `.normalizeStrain` | logical | | true: zeta and S are divided by f and abs(f) |
| `pdfmeta.selectedLevel` | double 3×91 | | s-level used (100 of 100) per dataset and day |
| `pdfmeta.selectedDepthMeters` | double 3×91 | m | nominal depth of that level (0.76-1.33 m) |
| `pdfmeta.validPointCount` | double 3×91 | | valid grid points per dataset and day |
| `pdfmeta.datasets` | struct 1×3 | | `label`, `domain_num` (run ID, Section 9.4), `run` (run directory), `grid_file` (relative to the model-output root of the computer that ran the script), `filePattern`, `files` (91×1 cell, relative to the run directory) |
| `pdfmeta.source` | char | | the cache file, relative to the data root |
| `pdfmeta.note` | char | | description |

### `obs_series2002.mat`

SERIES 2002 in-patch minus out-of-patch observations, digitised from Boyd et
al. (2005, Figure 2). The 2002 dates are mapped onto 2010, and Figure S7 adds
`time_offset` so that the SERIES release lines up with the model release of
2 June.

| Variable / field | Class, size | Units | Meaning |
|---|---|---|---|
| `README` | char | | description |
| `time_offset` | double | days | -29 |
| `Fe`, `NO3`, `CHL`, `POC_FLUX_100m` | struct | | one series each, fields below |
| `.time` | double 20×1, 19×1, 15×1, 10×1 | datenum | dates (1-26 July 2010 before the offset) |
| `.data` | double, same size | not recorded; plotted on the model axes of Figure S7: Fe and NO3 mmol m-3, CHL mg m-3, POC flux mmol m-2 d-1 | in-patch minus out-of-patch values |
| `.source_name` | char | | variable name in the digitised table |

### `patchmaps_grid.mat`

| Variable | Class, size | Units | Meaning |
|---|---|---|---|
| `lon`, `lat` | cell 1×3 of single 701×1066, 600×521, 171×191 | °E, °N | rho points of the map sub-domain ("Papa_extend2") of the 1, 4 and 12 km grids (index ranges `C.indx`, `C.indy` in `oif_config.m`) |
| `res_label` | cell 1×3 | | `1KM`, `4KM`, `12KM` |
| `region_lon_OIF`, `region_lat_OIF` | cell 1×3 of double 1×5 | °E, °N | outlines of the release regions R1, R2, R3 |

### `patchmaps_occurrence.mat`

Rows follow `exp_label` (Jun-R1, May-R1, Jul-R1, Aug-R1, Jun-R2, Jun-R3) and
columns the resolution (1, 4, 12 km), so that Case = 3*(row-1) + column. The
daily values cover day 2 of the release month to the end of the following
month.

| Variable | Class, size | Units | Meaning |
|---|---|---|---|
| `occ` | cell 6×3 of single (grid of `patchmaps_grid.mat`) | fraction (0-1) | patch occurrence: fraction of days with surface dFe > `threshold` (Figures 1f-h, S5, S6) |
| `ndays` | double 6×3 | days | days counted (60; 61 for July) |
| `fi_time` | cell 6×3 of double 1×60 or 1×61 | datenum | days |
| `fi_P2` | cell 6×3 | | daily FI = `P^2/(4*pi*A)` |
| `fi_Psqrt` | cell 6×3 | | daily `P/sqrt(A)` |
| `fi_P` | cell 6×3 | m | daily patch perimeter P |
| `fi_A` | cell 6×3 | m2 | daily patch area A |
| `meanFI_P2`, `meanFI_Psqrt` | double 6×3 | | means of `fi_P2` and `fi_Psqrt` (printed in the maps: `meanFI_P2`) |
| `exp_label`, `exp_month`, `exp_region` | cell 1×6, double 1×6, double 1×6 | | release experiment, month and region of each row |
| `oif_runs` | cell 6×3 | | OIF run directories |
| `ctrl_runs` | cell 1×3 | | control run directories (1, 4, 12 km) |
| `threshold` | double | mmol m-3 | 2e-5, the patch threshold |

### `patchmaps_S3_july1.mat`

| Variable / field | Class, size | Units | Meaning |
|---|---|---|---|
| `s3` | struct 1×3 | | (1) 1 km, (2) 4 km, (3) 12 km, June-R1 runs (Cases 1-3) on 1 July 2010; fields below |
| `.dfe` | single (grid of `patchmaps_grid.mat`) | mmol m-3 | surface dFe, OIF - control |
| `.dchl` | single, same size | mg m-3 | surface chlorophyll, OIF - control |
| `.qlon`, `.qlat` | single (subsampled grid) | °E, °N | positions of the velocity vectors (every 40, 15 and 10 cells) |
| `.qu`, `.qv` | single (subsampled grid) | m s-1 | eastward and northward surface velocity of the OIF run |
| `.time` | double | datenum | 1 July 2010 |
| `s3_quiver_step` | double 1×3 | grid cells | `[40 15 10]` |
| `threshold` | double | mmol m-3 | 2e-5 |

### `patchmaps_S4_contours.mat`

| Variable / field | Class, size | Units | Meaning |
|---|---|---|---|
| `s4` | struct 1×3 | | (1) 1 km, (2) 4 km, (3) 12 km, June-R1 runs; fields below |
| `.dfe` | single nx × ny × 16 | mmol m-3 | surface dFe, OIF - control, on the 16 dates of Section 5.5, clipped to [0, 2 × `threshold`] |
| `.time` | double 1×16 | datenum | the 16 dates |
| `.dfe0731` | single nx × ny | mmol m-3 | the same on 31 July 2010 (black contour) |
| `s4_sampling` | char | | description of the dates |
| `threshold` | double | mmol m-3 | 2e-5 |

### `profile_Fe_DIC.mat`

Variable `prof` (struct): domain-mean profiles averaged over June-July 2010, for
the June-R1 runs (Cases 1-3) and their control runs. Columns: 1, 4, 12 km.

| Field | Class, size | Units | Meaning |
|---|---|---|---|
| `prof.run_oif`, `prof.run_ctrl` | cell 1×3 | | OIF and control run directories |
| `prof.res_label` | cell 1×3 | | `1KM`, `4KM`, `12KM` |
| `prof.Fe_oif`, `prof.Fe_ctrl` | double 45×3 | mmol m-3 | dissolved Fe of the OIF and control runs |
| `prof.DIC_oif`, `prof.DIC_ctrl` | double 45×3 | mmol m-3 | DIC of the OIF and control runs |
| `prof.dep` | double 45×1 | m, positive downward | 5-600 m |
| `prof.units` | char | | units statement |

### `ts_patch_timeseries.mat`

Daily statistics of the 18 OIF runs and their controls, one row per day of
2010 (NaN outside the period of each composite).

| Variable / field | Class, size | Units | Meaning |
|---|---|---|---|
| `README` | char | | description |
| `date` | double 365×1 | datenum | 1 January-31 December 2010 |
| `stat_names` | cell 1×5 | | `p5 p95 max min area_sum` |
| `run`, `label`, `res_id`, `exp_id` | cell 18×1, cell 18×1, double 18×1, double 18×1 | | as in `ens_metrics.mat` (Case order) |
| `series` | cell 1×6 | | names of the six patch series below |
| `Fe_surf`, `NO3_surf`, `CHL_surf`, `POC_FLUX_100m`, `POC_FLUX_500m`, `CO2_FLUX_surf` | struct | | patch statistics, fields below |
| `.stats` | double 365×5×3×18 (day × stat × k × run) | Fe, NO3: mmol m-3; CHL: mg m-3; POC and CO2 flux: mmol C m-2 d-1; `area_sum`: these units × m2 | over the patch cells of each day: stat 1 5th percentile, 2 95th percentile, 3 maximum, 4 minimum, 5 area-weighted sum; k 1 OIF run, 2 control run, 3 OIF - control. Patch mean = stat 5 / `area`. CO2 flux positive into the ocean. |
| `.area` | double 365×18 | m2 | patch area |
| `dom` | struct | | domain sums: `POC_FLUX_100m`, `POC_FLUX_500m`, `CO2_FLUX_surf`, `PHYC_surf`, fields below |
| `dom.*.sum` | double 365×3×18 (day × k × run) | value × m2 (PHYC: mmol C m-3 × m2) | area-weighted sum over the analysis domain; k as above |
| `dom.*.area` | double 365×18 | m2 | area of the analysis domain at that resolution (constant; NaN on days without data) |

### `valid_model_papa.mat`

Model series at Ocean Station Papa from the station output of the four
validation runs (Section 9.2). Index 1-4 = 1, 4, 12, 25 km.

| Variable | Class, size | Units | Meaning |
|---|---|---|---|
| `res_label`, `domain` | cell 1×4 | | resolution labels and run directories |
| `edata_freq` | double 1×4 | samples per day (nominal) | `[48 48 48 1]`; smoothing window = `edata_freq*30` samples |
| `grid_file` | cell 1×4 | | grid files, relative to the data root |
| `grid_h` | double 1×4 | m | bottom depth of the station column in each grid |
| `grid_ij`, `grid_lonlat` | double 4×2 | grid index; °E, °N | station column in each grid |
| `station_depth`, `station_dz` | double 100×1 | m | depths (z_r, negative) and layer thicknesses of the OSP-1KM station column, used for all runs |
| `station_depth_own`, `station_dz_own` | double 100×4 | m | the same for each run's own grid (sensitivity check, not plotted) |
| `station_dz2` | double 100×1 | m | `station_dz` with NaN below 30 m (weights of the upper-30 m mean) |
| `depth_lim` | double | m | 30 |
| `time` | cell 1×4 of double 1×N | datenum | sample times covering 2010 (to 1-2 January 2011 at 1, 4 and 12 km): N = 17496 (every 0.5 h), 8760 (1 h), 14538 (0.6 h), 364 (daily) |
| `ts30` | struct of cells 1×4 (single 1×N): `temp`, `rho`, `NO3`, `Fe`, `CHL` | °C; sigma0 kg m-3; mmol m-3; mmol m-3; mg m-3 | dz-weighted means over the levels above 30 m |
| `ts30s` | as `ts30` | as `ts30` | `ts30` low-pass filtered over `smooth_samples` samples (Figure S1a-e) |
| `ts30s_owngrid` | as `ts30` | as `ts30` | the same with each run's own grid column (not plotted) |
| `mld2_month`, `mld2_month_own` | cell 1×4 of double 1×13 (25 km: 1×12) | m (negative) | monthly mean MLD (Section 5.4; a sample in which no level exceeds the threshold counts as 0) with the OSP-1KM column and with each run's own column (Figure S1f uses `mld2_month`) |
| `mld2_month_time` | cell 1×4 | datenum | 15th of each month |
| `prof_jja` | struct of cells 1×4 (100×1): `temp`, `rho`, `NO3`, `Fe`, `CHL`, `O2` | °C; sigma0 kg m-3; mmol m-3; mmol m-3; mg m-3; mmol m-3 | June-August 2010 mean profiles on `station_depth` (Figure S2); single, except `rho` (double) |
| `n_samples`, `n_jja` | double 1×4 | | number of samples in total and in June-August |
| `vars30`, `varsjja` | cell | | variable names of `ts30` and `prof_jja` |
| `season_months` | double 1×3 | month | `[6 7 8]` |
| `smooth_samples`, `smooth_days` | double 1×4 | samples, days | effective smoothing windows: `[1440 1440 1440 30]` samples = `[30 60 36 30]` days |
| `note` | char | | description |

### `valid_obs_papa.mat`

Observations at Ocean Station Papa. Upper-30 m monthly values and profiles,
as in the processed source files. The only conversion applied is dissolved Fe
from nM to mmol m-3 (in situ data). The source files do not record units; the
values are plotted on the axes of the model units (°C, kg m-3, mmol m-3,
mg m-3, m). For Argo NO3 and O2, Argo distributes µmol kg-1.

| Variable | Class, size | Units | Meaning |
|---|---|---|---|
| `insitu_clm`, `insitu_clm_std` | struct of double 12×1: `temp`, `rho`, `no3`, `fe`, `chl` | see above | Line P / Station P bottle and CTD data: upper-30 m monthly climatology and standard deviation (Figure S1, lines) |
| `insitu_mon`, `insitu_mon_time` | struct of double 84×1; double 84×1 | see above; datenum | monthly upper-30 m values, May 1985-June 2019 (Figure S1, triangles) |
| `argo_clm`, `argo_clm_std` | struct of double 12×1: `temp`, `O2`, `CHL`, `NO3`, `rho`, `MLD2` | see above; MLD2 in m (negative) | Argo 2003-2024 upper-30 m monthly climatology and standard deviation |
| `argo_mon`, `argo_mon_std`, `argo_mon_time` | struct of double 264×1; datenum 264×1 | see above | Argo monthly values, January 2003-December 2024 |
| `modis_clm`, `modis_clm_std` | double 12×1 | mg m-3 | MODIS-Aqua chlorophyll-a, 2003-2022 monthly climatology and standard deviation (December: NaN) |
| `modis_mon`, `modis_mon_time` | double 240×1 | mg m-3; datenum | MODIS-Aqua monthly values, January 2003-December 2022 |
| `insitu_jas_dep` | double 45×1 | m | depths of the in situ profiles (-975 to -2.5 m) |
| `insitu_jas`, `insitu_jas_std` | struct of double 45×1: `temp`, `rho`, `NO3`, `Fe`, `CHL`, `O2` | see above | July-September in situ mean profiles and standard deviation (Figure S2; the standard deviations are stored as in the source and include a few negative values) |
| `argo_jas_dep` | double 1001×1 | m | depths of the Argo profiles (0 to -1000 m, 1-m steps) |
| `argo_jas`, `argo_jas_std` | struct of double 1001×1: `temp`, `O2`, `CHL`, `NO3`, `rho` | see above | July-September Argo mean profiles and standard deviation (Figure S2) |
| `argo_season_labels_in_file` | cell 1×5 | | season labels stored in the Argo seasonal file (`spring summer fall winter annual`) |
| `argo_seasons_all_surface` | struct of double 1×4 | see above | values of the four seasonal columns of the Argo file at the shallowest level where column 3 has data (not plotted) |
| `note` | char | | description |

### `valid_woa23_papa.mat`

World Ocean Atlas 2023, 1-degree monthly climatologies at the grid point
nearest to Ocean Station Papa (145.5°W, 49.5°N). Temperature and salinity are
the decadal-average fields (`decav`), oxygen and nitrate the all-period fields
(`all`). O2 and NO3 are converted from µmol kg-1 to mmol m-3 with the factor
1.025.

| Variable | Class, size | Units | Meaning |
|---|---|---|---|
| `prof`, `prof_std` | struct: `temp`, `salt`, `O2`, `rho` (double 57×12), `NO3` (double 43×12) | °C; WOA23 salinity (unitless); mmol m-3; sigma0 kg m-3; mmol m-3 | monthly profiles (month = column) and WOA23 standard deviations; `rho` from GSW, its standard deviation from +-1 standard deviation of T and S |
| `dep` | struct: `temp`, `salt`, `O2`, `rho` (57×1, 0 to -1500 m), `NO3` (43×1, 0 to -800 m) | m | depths |
| `upper30`, `upper30_std` | struct of double 12×1 | as `prof` | means over the levels shallower than 30 m (Figure S1) |
| `mld2` | double 12×1 | m (negative) | monthly MLD (Section 5.4; density computed in single precision as in the original analysis) |
| `jja`, `jja_std` | struct (57×1; NO3 43×1) | as `prof` | means of the June, July and August profiles and of their standard deviations (Figure S2) |
| `lonlat` | double 1×2 | °E (-180 to 180), °N | grid point used |
| `note` | char | | description |

## 8. Rebuilding data/ from the intermediate products

`make_all_figures(true)` first runs the four prep scripts and then all plot
scripts. If a prep script fails, the plot scripts and `make_table_A1` are
skipped, so that no figure is drawn from a partly rebuilt `data/`:

```sh
export OIF_DATA_ROOT=/path/to/data_root   # folder with ROMS/, noaa/, Iron/, MODIS/, code_process/
export OIF_GSW_DIR=/path/to/gsw           # TEOS-10 GSW toolbox (prep_validation only)
export OIF_MMAP_DIR=/path/to/m_map
matlab -batch "addpath('/path/to/OIF_submeso_code'); make_all_figures(true)"
```

Each prep script can also be run on its own, for example `prep_maps` with the
switches of Section 4. A prep script stops at once with error `OIF:noDataRoot`
if `OIF_DATA_ROOT` is not set or is not a folder. `prep_validation` stops with
`OIF:noGSW` if GSW is not found. GSW can also be put into `external/gsw`. A
missing input file stops a prep script with an error before it writes the
data file that needs the input (`prep_budgets_profiles_coarsegrain` reports
all missing or empty budget composites and lists the first ten, and
`prep_timeseries_ensemble` names the first run that is missing from a summary
table, both with error `OIF:missingInput`), so `data/` never receives NaN in
place of missing inputs.

**Requirements**

- The intermediate products: 650 files, about 13.7 GB, laid out below the data
  root as listed in the table below (the layout of the authors' storage).
  They are not public.
- The TEOS-10 GSW toolbox, tested with version 3.03/3.04 (2013), for
  `prep_validation`.
- Optionally, the Image Processing Toolbox. `inpaintn` uses `bwdist` for its
  initial guess when this toolbox is available. Without it, the gap-filled
  land and missing cells of the WOA23 nitrate field of Figure 1a
  (`fig1_ab.mat`) differ slightly: by up to about 0.55 µmol kg-1 within the
  map region of Figure 1a, largest at filled land cells, which the figure
  covers with the land mask, and by up to about 0.2 µmol kg-1 at filled cells
  next to observed cells. Observed cells are unchanged.
- About 2 minutes of run time in our test (R2025b, Apple-silicon Mac, inputs
  on a local disk): about 30 s for the four prep scripts (20 s of it in
  `prep_maps`, which opens about 11 GB of daily model fields) and about 95 s
  for the plots and the table. It takes longer when the inputs first have to
  be fetched from network or cloud storage (about 8 minutes for the prep
  scripts in a test that fetched 4.1 GB).

With the inputs used for the article, a rebuild reproduces the 15 files in
`data/` exactly, apart from the creation time stored in the MAT-file header.
The prep scripts write only to `data/`.

**Inputs of each prep script** (paths relative to the data root; `<run>` is
a run directory of Section 9, `MM` a month)

| Script | Input files | Number | Size |
|---|---|---|---|
| `prep_validation` | `ROMS/Work/OSP1KM/FORCINGS_nw5/ospnw5_grd.nc`, `ROMS/Work/NEPAC/FORCINGS/nepac4km_grd.nc`, `ROMS/Work/PACMED12KMnew/FORCINGS/pacmed12_grd_fixedMSK.nc`, `ROMS/Work/PACMED25KMnew/FORCINGS/pacmed25_grd.nc` (model grids) | 4 | 325 MB |
| | `ROMS/<validation run>/Analysis/figures/extract_stations_data_2010.mat` (station output at Papa) | 4 | 232 MB |
| | `Iron/hydrographic_data_NEPAC/hydrographic_data_NEPAC/Papap_exp_np_obs_Station_Papa_upper30.mat`, `Papap_exp_np_monthly_obs_Station_Papa_upper30.mat`, `Papap_exp_npseasonal_mean_obs_scatter_Station_Papa_upper1000.mat` (Line P / Station P) | 3 | < 0.1 MB |
| | `noaa/argo/figures_v2/Papatime_climatological_monthly_mean_upper_30m_2003_2024.mat`, `Papatime_monthly_mean_upper_30m_2003_2024.mat`, `PapaArgo_profile_seasonal_mean_composaition_300m_01-Jan-2003_31-Dec-2024.mat` (Argo) | 3 | 0.5 MB |
| | `MODIS/Chl_2003_2022/figures/Papa_zoom0_MODIS_monthly_series_chlor_a.mat` | 1 | < 0.1 MB |
| | `noaa/woa23/woa23_temperature_monthly/woa23_decav_tMM_01.nc`, `woa23_salinity_monthly/woa23_decav_sMM_01.nc`, `woa23_nitrate_monthly/woa23_all_nMM_01.nc`, `woa23_oxygen_monthly/woa23_all_oMM_01.nc` (WOA23, MM = 01-12, as distributed by NOAA NCEI) | 48 | 2.07 GB |
| `prep_maps` | the 1, 4 and 12 km grids (above) and `noaa/woa23/woa23_nitrate_monthly/woa23_all_n06_01.nc` ... `n08_01.nc` | 6 | 0.35 GB |
| | `ROMS/NEPAC4KM_INI_BEC_V2_daily_diaT2/Analysis/figures/NEPAC4KM_INI_BEC_V2_daily_diaT2_NO3_model_summer_OSP.mat` (June-August surface NO3, Figure 1b) | 1 | 5.6 MB |
| | `code_process/figures/period_pdf_vorticity_strain_w_three_resolutions_avg_20100602_to_20100831_depth_last_1.mat` (Figure 1c-e PDFs) | 1 | 27 kB |
| | `ROMS/<run>/Analysis/figures/hori_surf_100m_200m_500m_daily_<VAR>_2010MM_Papa_extend2.mat` (daily surface fields; per resolution: Fe of the control run, May-September; Fe of the OIF runs, release month and the following month, and June-September for June-R1; CHL of the June-R1 and control runs and u, v of the June-R1 run, July) | 69 | 10.97 GB |
| `prep_timeseries_ensemble` | `ROMS/<OIF run>/Analysis/figures/<VAR>_time_series_at_locations_of_maximum_difference_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50.mat` (patch composites; VAR = Fe, NO3, CHL, POC_FLUX, CO2_FLUX) | 90 | 7.9 MB |
| | `ROMS/<OIF run>/Analysis/figures/<VAR>_time_series_at_locations_of_maximum_difference_patch_center_OSPnw5_domain_RMSpg15_2em5_50.mat` (domain composites; VAR = POC_FLUX, CO2_FLUX, PHYC) | 54 | 4.0 MB |
| | in `ROMS/OSP1KM_INI_BEC_V2_OIF_Jun_diaT2_nw5/Analysis/figures/`: `Statistics_InOutPatch_patch_center_OSPnw5_domain_RMSpg15_2em5_50.xlsx`, `Statistics_InOutPatch_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50.xlsx` (60-day summary tables), `FilamentationIndex_Ensemble_by_resolution_first2months<18 run IDs>.mat` (daily FI), `VarianceDecomposition_*_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50.mat` and `Correlation_*_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50.mat` (cached results, used only for checks) | 15 | 0.2 MB |
| | `Iron/Boyd2005_Figure2_data_table.mat` (SERIES 2002, digitised) | 1 | < 0.1 MB |
| `prep_budgets_profiles_coarsegrain` | `ROMS/<OIF run>/Analysis/figures/<TERM>_time_series_at_locations_of_maximum_difference_patch_center_OSPnw5_domain_RMSpg15_2em5_50.mat` (budget composites; the 19 terms of `budget_ensemble.mat` × 18 runs) | 342 | 9.8 MB |
| | `MLD_time_series_at_locations_of_maximum_difference_patch_center_OSPnw5_domain_RMSpg15_2em5_50.mat` of the full-year 1-km control run and of Case 1 | 2 | 0.1 MB |
| | `ROMS/<run>/Analysis/figures/zslice_file_domain_mean_profile67.mat` of Cases 1-3 and their control runs | 6 | 0.3 MB |
| | `ROMS/OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear/Analysis/figures/Zeu_monthly_mean_timeseries_OSPnw5_domain_RMSpg15_Papa_extend2_2010.mat` | 1 | < 0.1 MB |
| | `ROMS/<run>/Analysis/figures/hovmoller_flux_depth_t_within_papa_mask_buoy_avg_v4.nc` (control), `..._avg_v4.nc` (Fe) and `..._DIC_avg_v4.nc` (control and Case 1) | 5 | 50 MB |

The grids and the WOA23 nitrate files used by both `prep_validation` and
`prep_maps` are counted once in the total of 650 files.

## 9. Provenance

### 9.1 The 18 OIF experiments (Table A1)

Iron was added continuously for one week at 0.02 mol m-2 yr-1 within a
50 km × 50 km box (Methods of the article), starting on the 2nd day of the
release month. The release regions R1, R2 and R3 are stored in
`region_lon_OIF` and `region_lat_OIF`:

- R1: 213.70-214.41°E, 52.03-52.50°N;
- R2: a 50-km box centred on OSP;
- R3: a 50-km box centred midway between the centres of R1 and R2.

| Case | Experiment | Release | Region | Resolution | OIF run directory | Control run directory | Run ID |
|---|---|---|---|---|---|---|---|
| 1 | `1KM_Jun` | 2 June | R1 | 1 km | `OSP1KM_INI_BEC_V2_OIF_Jun_diaT2_nw5` | `OSP1KM_INI_BEC_V2_daily_diaT2_nw5` | 96 |
| 2 | `4KM_Jun` | 2 June | R1 | 4 km | `NEPAC4KM_INI_BEC_V2_OIF_Jun_diaT` | `NEPAC4KM_INI_BEC_V2_daily_diaT2` | 68 |
| 3 | `12KM_Jun` | 2 June | R1 | 12 km | `PACMED12KM_INI_BEC_V2_param2_OIF_Jun_diaT` | `PACMED12KM_INI_BEC_V2_param2_daily_diaT2` | 72 |
| 4 | `1KM_May` | 2 May | R1 | 1 km | `OSP1KM_INI_BEC_V2_OIF_May_diaT2_nw5` | `OSP1KM_INI_BEC_V2_daily_diaT2_nw5` | 105 |
| 5 | `4KM_May` | 2 May | R1 | 4 km | `NEPAC4KM_INI_BEC_V2_OIF_May_diaT` | `NEPAC4KM_INI_BEC_V2_daily_diaT2` | 79 |
| 6 | `12KM_May` | 2 May | R1 | 12 km | `PACMED12KM_INI_BEC_V2_param2_OIF_May_diaT` | `PACMED12KM_INI_BEC_V2_param2_daily_diaT2` | 73 |
| 7 | `1KM_Jul` | 2 July | R1 | 1 km | `OSP1KM_INI_BEC_V2_OIF_Jul_diaT2_nw5` | `OSP1KM_INI_BEC_V2_daily_diaT2_nw5` | 106 |
| 8 | `4KM_Jul` | 2 July | R1 | 4 km | `NEPAC4KM_INI_BEC_V2_OIF_Jul_diaT` | `NEPAC4KM_INI_BEC_V2_daily_diaT2` | 80 |
| 9 | `12KM_Jul` | 2 July | R1 | 12 km | `PACMED12KM_INI_BEC_V2_param2_OIF_Jul_diaT` | `PACMED12KM_INI_BEC_V2_param2_daily_diaT2` | 74 |
| 10 | `1KM_Aug` | 2 August | R1 | 1 km | `OSP1KM_INI_BEC_V2_OIF_Aug_diaT2_nw5` | `OSP1KM_INI_BEC_V2_daily_diaT2_nw5` | 107 |
| 11 | `4KM_Aug` | 2 August | R1 | 4 km | `NEPAC4KM_INI_BEC_V2_OIF_Aug_diaT` | `NEPAC4KM_INI_BEC_V2_daily_diaT2` | 81 |
| 12 | `12KM_Aug` | 2 August | R1 | 12 km | `PACMED12KM_INI_BEC_V2_param2_OIF_Aug_diaT` | `PACMED12KM_INI_BEC_V2_param2_daily_diaT2` | 75 |
| 13 | `1KM_Jun_R2` | 2 June | R2 | 1 km | `OSP1KM_INI_BEC_V2_OIF_Jun_diaT2_nw5_reg2` | `OSP1KM_INI_BEC_V2_daily_diaT2_nw5` | 110 |
| 14 | `4KM_Jun_R2` | 2 June | R2 | 4 km | `NEPAC4KM_INI_BEC_V2_OIF_Jun_diaT2_reg2` | `NEPAC4KM_INI_BEC_V2_daily_diaT2` | 112 |
| 15 | `12KM_Jun_R2` | 2 June | R2 | 12 km | `PACMED12KM_INI_BEC_V2_param2_OIF_Jun_diaT_reg2` | `PACMED12KM_INI_BEC_V2_param2_daily_diaT2` | 108 |
| 16 | `1KM_Jun_R3` | 2 June | R3 | 1 km | `OSP1KM_INI_BEC_V2_OIF_Jun_diaT2_nw5_reg3` | `OSP1KM_INI_BEC_V2_daily_diaT2_nw5` | 111 |
| 17 | `4KM_Jun_R3` | 2 June | R3 | 4 km | `NEPAC4KM_INI_BEC_V2_OIF_Jun_diaT2_reg3` | `NEPAC4KM_INI_BEC_V2_daily_diaT2` | 113 |
| 18 | `12KM_Jun_R3` | 2 June | R3 | 12 km | `PACMED12KM_INI_BEC_V2_param2_OIF_Jun_diaT_reg3` | `PACMED12KM_INI_BEC_V2_param2_daily_diaT2` | 109 |

The run IDs of the control runs are 95 (1 km), 67 (4 km) and 71 (12 km). The
run names are also in `oif_config.m` (`C.oif`, `C.ctrl`).

### 9.2 Other runs

| Used for | Resolution | Run directory | Run ID |
|---|---|---|---|
| Figures S1, S2 (validation) | 1 km | `OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear` | 98 |
| | 4 km | `NEPAC4KM_INI_BEC_V2_daily_diaT2_nw5_allyear` | 97 |
| | 12 km | `PACMED12KM_INI_BEC_V2_param2_daily_diaT2` (the 12-km control run) | 71 |
| | 25 km | `PACMED25KM_INI_BEC_V2_param2` | 49 |
| Figure S11; control panels of Figure S12 | 1 km | `OSP1KM_INI_BEC_V2_daily_diaT2_nw5_allyear` (full year 2010, no iron addition) | 98 |
| Figure 1b | 4 km | `NEPAC4KM_INI_BEC_V2_daily_diaT2` (4-km control run) | 67 |
| Figure 1c-e | 12, 4, 1 km | the June-R1 OIF runs (Cases 3, 2, 1) | 72, 68, 96 |

The validation and coarse-graining runs are listed in `oif_config.m` for
reference (`C.valid_runs`, `C.cg_ctrl`).

### 9.3 Code that produced the intermediate products

The intermediate products were made from the model output by the authors'
analysis code. Except `upstream/calculate_roms_surface_diagnostic_period_pdfs.m`,
this code is not part of the package. The prep scripts re-implement the parts
of it that turn the intermediate products into the figure data; their headers
name the block of the original code that each part follows.

| Intermediate product | Produced by |
|---|---|
| `extract_stations_data_2010.mat` (station series) | `PACMED12_Process_marbl_8p6z.m`, block `extract_stations_validation`, from the ROMS station output |
| `hori_surf_100m_200m_500m_daily_<VAR>_2010MM_Papa_extend2.mat` (daily fields at the top level and at 50, 100, 200 and 500 m) | `PACMED12_Process_marbl_8p6z.m`, block `plot_horizontal_surface_int200m_daily_zoom` |
| `NEPAC4KM_INI_BEC_V2_daily_diaT2_NO3_model_summer_OSP.mat` | `PACMED12_Process_marbl_8p6z.m`, block `plot_domain_model_no3` |
| `period_pdf_vorticity_strain_w_three_resolutions_avg_20100602_to_20100831_depth_last_1.mat` | `upstream/calculate_roms_surface_diagnostic_period_pdfs.m` (included; see `upstream/README.md`) |
| `<VAR>_time_series_at_locations_of_maximum_difference_patch_center<tag>.mat` for Fe, NO3, CHL, PHYC, POC_FLUX, CO2_FLUX and MLD (daily patch and domain composites) | `PACMED12_Process_marbl_8p6z.m`, block `plot_horizontal_surface_int200m_daily_zoom_test_cmp2`, section on the time series within and outside the patch (`define_region_mask` 11 and 12) |
| the same file names for the Fe and DIC budget terms | `PACMED12_Process_budget.m`, block `OIF_budget_test_cmp` (budget variable lists of `PACMED12_Process_param_8p6z.m`) |
| `Statistics_InOutPatch_*.xlsx`, `VarianceDecomposition_*.mat`, `Correlation_*.mat`, `FilamentationIndex_Ensemble_by_resolution_first2months*.mat` | `PACMED12_Process_marbl_8p6z.m`, block `plot_horizontal_surface_int200m_daily_zoom_test_cmp_more` (60-day summary tables, variance decomposition, correlations, filamentation index) |
| `Zeu_monthly_mean_timeseries_OSPnw5_domain_RMSpg15_Papa_extend2_2010.mat` | `PACMED12_Process_marbl_8p6z.m`, block `plot_horizontal_surface_int200m_daily_zoom_test_cmp2` (euphotic-depth section), from daily Zeu fields |
| `zslice_file_domain_mean_profile67.mat` (June-July domain-mean profiles) | `budgets_OIF/get_budgets_OIF_50m_nc.m` of the same analysis code, flag `get_variables_profile` |
| `hovmoller_flux_depth_t_within_papa_mask_*avg_v4.nc` (coarse-grained fluxes, Text S1) | the authors' Python coarse-graining scripts (`spectrum_eke_*_flux_output_monthly.py`, `spectrum_eke_common.py`) |
| Line P / Station P, Argo and MODIS files at Station Papa | the authors' processing scripts for these observations (the Argo files by `argo_plot_v2.m`); the in situ and MODIS scripts are not identified |
| `Iron/Boyd2005_Figure2_data_table.mat` | values digitised from Boyd et al. (2005, Figure 2) |

`PACMED12_Process_param_8p6z.m` is the parameter file of the original
analysis: the run list with the run IDs, the grid files, the variable lists,
the patch definition (`patch_define = '_2em5_50'`) and the release regions
(`region_defs`).

### 9.4 Glossary

| Term | Meaning |
|---|---|
| PACMED-12KM, NEPAC-4KM, OSP-1KM | the nested configurations: Pacific parent domain at 12 km, eastern North Pacific subdomain at 4 km, child domain around OSP at 1 km. PACMED-25KM is the 25-km Pacific configuration used for the spin-up (Methods) and as the 25-km run of Figures S1 and S2. |
| Case 1-18 | experiment numbers of Table A1 (Section 9.1); also the run order of `ens_metrics.mat` and `ts_patch_timeseries.mat` |
| R1, R2, R3 | release regions (Section 9.1) |
| Run directory names | `<configuration>_INI_BEC_V2[_param2]_<type>[...]`. `OIF_<Mon>`: OIF run released in that month; `_reg2`, `_reg3`: release region R2 or R3 (no suffix: R1); `daily`: run without iron addition; `_allyear`: run covering all of 2010; `nw5`: in the 1-km run names, the 1-km grid `ospnw5_grd.nc` (the full-year 4-km run carries the same tag). `INI`, `BEC_V2`, `param2`, `diaT` and `diaT2` are version tags of the authors' run naming and are not documented further here. |
| Run ID | number of a run in the run list (`domain_list`) of `PACMED12_Process_param_8p6z.m`, for example 96 = Case 1 and 98 = the full-year 1-km control run. It appears in comments ("domain 98"), in `pdfmeta.datasets.domain_num` of `fig1_pdfs.mat` and in the name of the FI cache, `FilamentationIndex_Ensemble_by_resolution_first2months<run IDs>.mat`, which lists the run IDs of the 18 OIF runs in Case order (96, 68, 72, 105, ..., 109, separated by two or three spaces; the exact name is in `prep/prep_timeseries_ensemble.m`). |
| OSPnw5 | the OSP-1KM grid (`ospnw5_grd.nc`) and its domain |
| RMSpg15 | the 15-cell sponge band along the open boundaries of the OSP-1KM grid is excluded ("exclude sponge layer 15 grid" in the original code) |
| `_2em5_50` | patch definition of the original analysis (`patch_define`): threshold dFe > 2e-5 mmol m-3 ("2em5") and a 50-km zone around the patch for out-of-patch statistics ("50"; not used by this package) |
| LS11 | the file tag `_patch_center_patch_stats_OSPnw5_RMSpg15_2em5_50` (`define_region_mask = 11`): statistics over the fertilized patch within the OSP-1KM domain without its 15-cell boundary band ("patch" integrals) |
| LS12 | the file tag `_patch_center_OSPnw5_domain_RMSpg15_2em5_50` (`define_region_mask = 12`): statistics over the whole OSP-1KM domain without that band ("domain" integrals, the analysis domain). `prep_budgets_profiles_coarsegrain.m` reads the budget and MLD composites with this tag. |
| `patch_center` | fixed part of the composite file names of the original analysis |
| Papa_extend2 | name of the map sub-domain of the daily field caches (`region_num = 3` of the original code). Its grid index ranges are `C.indx` and `C.indy` in `oif_config.m`; at 4 and 12 km it extends beyond the 1-km domain. |
| `profile67` | months 6-7 (June-July) of the domain-mean profiles |
| `edata_freq` | nominal number of station-output samples per day assumed by the original code (48 at 1, 4 and 12 km; 1 at 25 km) |
| `icomb`, `iplot_type`, `plot_list`, `month_plot_all`, `iseason`, `run_num`, `sbpos23`, `clim_tmp_all`, ... | variables of the original analysis scripts. Script headers quote them only to point into that code (for example, `icomb` selects a predefined set of runs). |

## 10. Third-party software and data

### 10.1 Software

| Component | Files | Licence | Used for |
|---|---|---|---|
| cbrewer, Charles Robert (MATLAB File Exchange 34087, no longer on File Exchange) | `lib/cbrewer.m` and `lib/interpolate_cbrewer.m` (both modified, marked in the headers), `lib/colorbrewer.mat` | BSD 2-Clause, `LICENSES/cbrewer_BSD-2-Clause.txt` | colours of Figures 1, S1, S2, S4 |
| ColorBrewer colour schemes, Cynthia A. Brewer, Mark Harrower and The Pennsylvania State University | colour tables in `lib/colorbrewer.mat`; the 'Dark2' colours written out in `oif_config.m` and `lib/oif_ens_style.m` | Apache 2.0, `LICENSES/Apache-2.0.txt` | through cbrewer; run and month colours of Figures 2-4, S7-S9 |
| inpaintn, Damien Garcia (MATLAB File Exchange 27994) | `lib/inpaintn.m` | BSD 3-Clause, `LICENSES/inpaintn_BSD-3-Clause.txt` | gap filling of the WOA23 field of Figure 1a (`prep_maps`) |
| cmocean colour maps 'balance' and 'amp', Kristen M. Thyng; MATLAB tables by Chad A. Greene | the colour tables in `lib/oif_cmocean.m` | MIT, `LICENSES/cmocean_MIT.txt` | Figures 1f-h, S5, S6, S11, S12 |
| M_Map 1.4, Rich Pawlowicz (not included) | | its own licence | map figures |
| TEOS-10 GSW Oceanographic Toolbox (not included) | | its own licence | `prep_validation` |
| MATLAB, The MathWorks (not included) | | commercial | everything |

This product includes color specifications and designs developed by Cynthia
Brewer (http://colorbrewer.org/).

Several helpers of the original analysis code could not be redistributed or
had no documented origin. They are replaced by functions written for this
package (`lib/fft_lowpass.m`, `roms_zlevs.m`, `log_pm.m`, `rot.m`, `redblue.m`,
`oif_cmocean.m`, `colormap_isleofdogs.m`), which reproduce the original helpers
to round-off or exactly. `THIRD_PARTY_NOTICES.md` gives the details, sources,
versions and modifications of all third-party components; `LICENSES/` holds
the licence texts.

Software citations:

- Pawlowicz, R. (2020). M_Map: A mapping package for MATLAB, version 1.4m
  [Computer software]. https://www.eoas.ubc.ca/~rich/map.html
- McDougall, T. J., & Barker, P. M. (2011). Getting started with TEOS-10 and
  the Gibbs Seawater (GSW) Oceanographic Toolbox. SCOR/IAPSO WG127, 28 pp.,
  ISBN 978-0-646-55621-5. (GSW-MATLAB version 3.03/3.04 was used.)
- Thyng, K. M., Greene, C. A., Hetland, R. D., Zimmerle, H. M., & DiMarco,
  S. F. (2016). True colors of oceanography: Guidelines for effective and
  accurate colormap selection. Oceanography, 29(3), 9-13.
  https://doi.org/10.5670/oceanog.2016.66
- Harrower, M., & Brewer, C. A. (2003). ColorBrewer.org: An online tool for
  selecting colour schemes for maps. The Cartographic Journal, 40(1), 27-37.
  https://doi.org/10.1179/000870403235002042
- Garcia, D. (2010). Robust smoothing of gridded data in one and higher
  dimensions with missing values. Computational Statistics & Data Analysis,
  54(4), 1167-1178. https://doi.org/10.1016/j.csda.2009.09.020
- Wang, G., Garcia, D., Liu, Y., de Jeu, R., & Dolman, A. J. (2012). A
  three-dimensional gap filling method for large geophysical datasets:
  Application to global satellite soil moisture observations. Environmental
  Modelling & Software, 30, 139-142. https://doi.org/10.1016/j.envsoft.2011.10.015
- Press, W. H., Flannery, B. P., Teukolsky, S. A., & Vetterling, W. T. (1986).
  Numerical Recipes: The Art of Scientific Computing (1st ed.), section 13.9,
  Smoothing of Data. Cambridge University Press. (Method of `lib/fft_lowpass.m`;
  no Numerical Recipes code is included.)

### 10.2 Data

`data/` contains values derived from the following third-party data sets. They
remain under the terms of their providers. Please cite them when you reuse
these values.

| Data set | In | Figures | Source and terms |
|---|---|---|---|
| World Ocean Atlas 2023 (NOAA NCEI): monthly 1-degree temperature, salinity, oxygen and nitrate | `fig1_ab.mat` (`woa`), `valid_woa23_papa.mat` | 1a, S1, S2 | https://www.ncei.noaa.gov/products/world-ocean-atlas. U.S. Government work, no restrictions on use; please cite. |
| Argo and BGC-Argo float data near Ocean Station Papa, 2003-2024 | `valid_obs_papa.mat` (`argo_*`) | S1, S2 | Argo Global Data Assembly Centre, https://doi.org/10.17882/42182. The monthly snapshot used is not recorded in the files. Freely available; please cite and acknowledge (below). |
| MODIS-Aqua chlorophyll-a, 2003-2022 (NASA Ocean Biology Processing Group) | `valid_obs_papa.mat` (`modis_*`) | S1 | NASA OB.DAAC, https://doi.org/10.5067/AQUA/MODIS/L3M/CHL/2022 (DOI of the R2022.0 reprocessing; the processing version used for the files is not recorded). NASA data are freely available; please cite. |
| Line P / Ocean Station Papa bottle and CTD data, including dissolved iron | `valid_obs_papa.mat` (`insitu_*`) | S1, S2 | Line P Program, Fisheries and Oceans Canada, Institute of Ocean Sciences (https://www.waterproperties.ca/linep/). The files do not record the source, years of download or access date, nor the source of the dissolved-iron values. |
| SERIES 2002 iron-enrichment experiment | `obs_series2002.mat` | S7 | values digitised from Boyd et al. (2005), Figure 2 |

References for the data:

- Reagan, J. R., et al. (2023). World Ocean Atlas 2023 [Dataset]. NOAA National
  Centers for Environmental Information. https://doi.org/10.25921/va26-hv25
- Locarnini, R. A., et al. (2024). World Ocean Atlas 2023, Volume 1:
  Temperature. NOAA Atlas NESDIS 89. https://doi.org/10.25923/54bh-1613
- Reagan, J. R., et al. (2024). World Ocean Atlas 2023, Volume 2: Salinity.
  NOAA Atlas NESDIS 90. https://doi.org/10.25923/70qt-9574
- Garcia, H. E., et al. (2024). World Ocean Atlas 2023, Volume 3: Dissolved
  Oxygen, Apparent Oxygen Utilization, and Dissolved Oxygen Saturation. NOAA
  Atlas NESDIS 91. https://doi.org/10.25923/rb67-ns53
- Garcia, H. E., et al. (2024). World Ocean Atlas 2023, Volume 4: Dissolved
  Inorganic Nutrients (phosphate, nitrate and nitrate+nitrite, silicate). NOAA
  Atlas NESDIS 92. https://doi.org/10.25923/39qw-7j08
- Argo (2000). Argo float data and metadata from Global Data Assembly Centre
  (Argo GDAC) [Dataset]. SEANOE. https://doi.org/10.17882/42182
- NASA Ocean Biology Processing Group (2022). Aqua MODIS Level 3 Mapped
  Chlorophyll Data, Version R2022.0 [Dataset]. NASA Ocean Biology Distributed
  Active Archive Center. https://doi.org/10.5067/AQUA/MODIS/L3M/CHL/2022
- Boyd, P. W., Strzepek, R., Takeda, S., Jackson, G., Wong, C. S., McKay,
  R. M., Law, C., Kiyosawa, H., Saito, H., Sherry, N., Johnson, K., Gower, J.,
  & Ramaiah, N. (2005). The evolution and termination of an iron-induced
  mesoscale bloom in the northeast subarctic Pacific. Limnology and
  Oceanography, 50(6), 1872-1886. https://doi.org/10.4319/lo.2005.50.6.1872

Argo acknowledgement: These data were collected and made freely available by
the International Argo Program and the national programs that contribute to it
(https://argo.ucsd.edu, https://www.ocean-ops.org). The Argo Program is part of
the Global Ocean Observing System.

## 11. Licence and citation

- **Code.** The code written for this package, the top-level scripts, `plot/`,
  `prep/`, `tables/make_table_A1.m`, the package-written files in `lib/` and the
  author's script in `upstream/`, is released under the MIT License (`LICENSE`).
- **Third-party code** in `lib/` keeps its own licence (Section 10.1,
  `THIRD_PARTY_NOTICES.md`, `LICENSES/`).
- **Data, tables and figures.** The files in `data/`, the tables
  `tables/table_A1.csv` and `tables/table_A1.tex` and the figures in `figures/`
  are released under the Creative Commons Attribution 4.0 International licence
  (CC BY 4.0, `LICENSES/CC-BY-4.0.txt`). Third-party data contained in `data/`
  remain under the terms of their providers (Section 10.2).

If you use this package, please cite the article and this archive. The
machine-readable metadata are in `CITATION.cff` and `.zenodo.json`.

- Li, D., Bianchi, D., Damien, P., Guiet, J., Pham, A. L.-D., Feng, L.,
  McGillicuddy, D. J., Jr., Buesseler, K. O., Liu, Z., Chai, F., & Xiu, P.
  (in review). Processes Regulating the Response to Ocean Iron Fertilization in the Subarctic Eastern North Pacific. Geophysical Research Letters.
- Li, D., Bianchi, D., Damien, P., Guiet, J., Pham, A. L.-D., Feng, L.,
  McGillicuddy, D. J., Jr., Buesseler, K. O., Liu, Z., Chai, F., & Xiu, P.
  (2026). Code and data for: Processes Regulating the Response to Ocean Iron Fertilization in the Subarctic Eastern North Pacific (Version 1.0.0)
  [Software]. Zenodo. https://doi.org/10.5281/zenodo.XXXXXXX
