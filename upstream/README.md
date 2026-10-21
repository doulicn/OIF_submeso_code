# upstream/

This folder holds one script of the authors' original analysis code,
`calculate_roms_surface_diagnostic_period_pdfs.m`, for provenance. It is a
byte-for-byte copy of the authors' script (38,319 bytes; SHA-256
`34065b4176fa5d65fab4f9191c00a2dabc80992e9f42338bf29da6cd56cc7fe6`).

The package never runs this script. `setup_paths` does not put this folder on
the MATLAB path, and no package code calls the script.

## Role in the package

The script computed the probability density functions (PDFs) shown in
Figure 1c-e and saved them in a cache file. `prep/prep_maps.m` (switch
`do_pdfs`) only copies the cached histograms and their metadata into
`data/fig1_pdfs.mat`; it recomputes nothing. The cache file is

`code_process/figures/period_pdf_vorticity_strain_w_three_resolutions_avg_20100602_to_20100831_depth_last_1.mat`

below the data root (the script writes to a `figures/` folder next to itself).

`lib/add_skew_text.m` of the package is a port of the local function
`add_skew_text` of this script. It places the skewness labels of Figure 1c-e.

## What the script computes

With the settings in the script:

- **Runs.** The three June-release OIF runs at R1, given by their run IDs in
  `datasets`: 72 (12 km, `PACMED12KM_INI_BEC_V2_param2_OIF_Jun_diaT`, Case 3),
  68 (4 km, `NEPAC4KM_INI_BEC_V2_OIF_Jun_diaT`, Case 2) and 96 (1 km,
  `OSP1KM_INI_BEC_V2_OIF_Jun_diaT2_nw5`, Case 1).
- **Files and days.** The daily-mean output files (`dataFileType = 'avg'`;
  file patterns `pacmed_avg.*.nc`, `nepac_avg.*.nc`, `ospnw5_avg.*.nc`) of the
  days from 2 June to 31 August 2010 (`startDateString`, `endDateString`) that
  exist for all three runs: 91 days. The header comment of the script speaks
  of `his` files; the configured file type is `avg`.
- **Level.** The top model level (`topLevelMode = 'last'`; level 100 of 100).
- **Target grid.** u and v are moved to rho points and rotated to east and
  north. With w, they are interpolated (linear `scatteredInterpolant`) to the
  1-km grid, from which a band of 15 cells is removed along each boundary
  (`spongeWidth = 15`, `targetDatasetIndex = 3`). The 4- and 12-km fields are
  interpolated to this grid, and the 1-km fields go through the same step.
- **Fields.** On the target grid the velocities are rotated back to grid
  directions, and the script computes:
  - the relative vorticity zeta divided by f, Ro = zeta/f;
  - the strain rate S = sqrt((u_x - v_y)^2 + (v_x + u_y)^2) divided by abs(f);
  - w minus its daily mean over the ocean points of the target grid
    (`removeDomainMeanW = true`).
- **PDFs.**
  1. A first pass over all days and runs finds the pooled limits, the largest
     absolute value of each field.
  2. A second pass accumulates histogram counts in 160 bins (`nBins`). The bins
     are symmetric about zero for Ro and w and span [0, maximum] for S/f.
  3. PDF = counts / (number of values × bin width).
- **Output.** The skewness of each pooled histogram, a 1 × 3 figure (PNG),
  and the cache file named above.

## Requirements (not provided by the package)

- The raw daily-mean ROMS output of the three runs (variables u, v, w and zeta;
  global attributes hc, Cs_r and Cs_w) and their grid files.
- The authors' parameter file `PACMED12_Process_param_8p6z.m`, which is not
  included. The script finds it with its function `locate_param_file`. It
  evaluates the file up to the line `Vtransform=2;` to obtain the output folder
  and grid file of each run ID on the chosen computer (`machineChoice = 1`).
- `cbrewer` (in `lib/` of this package) for the line colours, and MATLAB
  R2021a or later (the script uses the `tiledlayout` option
  `'TileSpacing','tight'`).
- With `useSavedMatIfAvailable = true` the script loads an existing cache
  instead of recomputing it.

## Personal paths

The function `locate_param_file` (lines 1015-1030) lists two absolute paths
on the authors' computers where the parameter file was kept. They are left in
place because the file is an unchanged copy. They show the user name of the
first author and the folder layout on a Linux server and on a Mac, and
nothing else (no host names or credentials).

They are the only absolute personal paths in the package; no other file of the
package contains such paths.

## Licence

The script was written by the author of this package. It is covered by the
package licence (`../LICENSE`, MIT).

The other analysis scripts that made the intermediate products are not
included; see Section 9.3 of `../README.md`.
