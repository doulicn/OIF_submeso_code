# Third-party notices

This package (OIF_submeso_code) includes the third-party components listed in
section 1. Each one is redistributed under its own licence, and the full
licence texts are in the folder `LICENSES/`. All other code files, namely the
top-level scripts and the files in `lib/`, `plot/`, `prep/` and `tables/`
(written for this package) and the author's analysis script in `upstream/`,
are under the MIT License (`LICENSE`). The data in `data/`, the tables
(`tables/table_A1.csv`, `tables/table_A1.tex`) and the figures in `figures/`
are under CC BY 4.0 (`LICENSE`, `LICENSES/CC-BY-4.0.txt`).

Section 2 lists the package-written files that replace helper functions of the
original analysis code. Those helpers could not be redistributed, or their
origin was undocumented. Section 3 lists the external software that is
required but not included. The sources of the observational and
climatological data in `data/`, with the citations and acknowledgements they
require, are listed in `README.md`.

## 1. Third-party components included in `lib/`

### 1.1 cbrewer

- **Files:** `lib/cbrewer.m` (modified), `lib/interpolate_cbrewer.m`
  (modified), `lib/colorbrewer.mat` (unmodified).
- **Author:** Charles Robert.
- **Source:** MATLAB File Exchange 34087, "cbrewer : colorbrewer schemes for
  Matlab". The submission has been removed from File Exchange (its page,
  <https://www.mathworks.com/matlabcentral/fileexchange/34087>, returned
  HTTP 410 Gone on 2026-10-20).
- **Version:** the File Exchange release of 18 September 2015, the date of
  all files in the download (`cbrewer.m` dated 06.12.2011, with minor fixes
  of 18.09.2015; `interpolate_cbrewer.m` dated 14.10.2011).
- **Licence:** BSD 2-Clause, `LICENSES/cbrewer_BSD-2-Clause.txt`. This file
  is the `license.txt` of the File Exchange download ("Copyright (c) 2015,
  Charles Robert"). The copy inside the download's `cbrewer/` folder has the
  same text with the line "Copyright (c) 2011, Charles Robert".
- **Modifications** (both are marked in the file headers):
  - `cbrewer.m`: `colorbrewer.mat` is loaded by its full path from the folder
    of `cbrewer.m`. The original `load('colorbrewer.mat')` reads a file of
    that name from the current folder first, if there is one.
  - `interpolate_cbrewer.m`: the interpolated 0-255 values are clipped to
    [0, 255]. Since MATLAB R2020b, the `interp1` method `'cubic'` falls back
    to `'spline'` for the non-uniform knots of this function, and the spline
    can overshoot (up to 292 for `cbrewer('qual','Paired',16)`, the palette of
    Fig. S4). The knot placement of the original is unchanged, so the colours
    of the published Fig. S4 are reproduced exactly.
- **Used by:** `plot/plot_fig1.m`, `plot/plot_figS1.m`, `plot/plot_figS2.m`
  and `plot/plot_figS4.m`.

### 1.2 ColorBrewer colour schemes

- **Files:** the colour tables in `lib/colorbrewer.mat`, used through
  `cbrewer.m`, and the first four 'Dark2' RGB values, written out in
  `oif_config.m` (`C.col_res`, the colours of the 1, 4 and 12 km runs in
  Figs. 2, S7 and S9) and `lib/oif_ens_style.m` (the month colours of Figs.
  3, 4 and S8). Apart from these values, both files are package code under
  the MIT License (`LICENSE`).
- **Authors:** Cynthia A. Brewer, Mark Harrower and The Pennsylvania State
  University.
- **Source:** <https://colorbrewer2.org>,
  <https://github.com/axismaps/colorbrewer>. C. Robert generated the tables in
  `colorbrewer.mat` from the ColorBrewer spreadsheet (see the header of
  `cbrewer.m`).
- **Version:** the tables of the cbrewer download of 18 September 2015.
- **Licence:** Apache License, Version 2.0, `LICENSES/Apache-2.0.txt`.
- **Modifications:** none.
- **Attribution:** This product includes color specifications and designs
  developed by Cynthia Brewer (http://colorbrewer.org/).

### 1.3 inpaintn

- **Files:** `lib/inpaintn.m` (unmodified).
- **Author:** Damien Garcia (<https://www.biomecardio.com>).
- **Source:** MATLAB File Exchange 27994, "inpaintn",
  <https://www.mathworks.com/matlabcentral/fileexchange/27994>.
- **Version:** 2010/06, last update 2017/08 (file header).
- **Licence:** BSD 3-Clause, `LICENSES/inpaintn_BSD-3-Clause.txt`
  ("Copyright (c) 2017, Damien Garcia"; the third clause forbids using the
  name of CREATIS, Lyon, France, or of its contributors to endorse or
  promote derived products). This is the File Exchange `license.txt` of
  this version of `inpaintn.m`. It was not kept with the copy used for this
  work and was taken from github.com/ABC-iRobotics/irob-saf (commit
  65f8b5ad, folder `irob_vision_support/matlab/inpaint`), which ships a
  byte-identical `inpaintn.m` (SHA-256
  9929aaf7a8b7b444dd0e93abf6486128091b817ad525f0aeffcfe16d3e701050) together
  with this `license.txt`. The current File Exchange release is version 1.4.2
  (20 June 2020).
- **Modifications:** none.
- **References** (requested by the author): Garcia, D. (2010), Robust
  smoothing of gridded data in one and higher dimensions with missing values,
  Computational Statistics & Data Analysis, 54, 1167-1178. Wang, G., D.
  Garcia, et al. (2012), A three-dimensional gap filling method for large
  geophysical datasets: Application to global satellite soil moisture
  observations, Environmental Modelling & Software, 30, 139-142.
- **Used by:** `prep/prep_maps.m`, to fill the gaps of the WOA23 surface
  nitrate field of Fig. 1a. For its initial guess `inpaintn` uses `bwdist`
  from the Image Processing Toolbox when that toolbox is available. Without
  it, `inpaintn` warns and starts from the mean value, which can change the
  filled values slightly.

### 1.4 cmocean colour maps 'balance' and 'amp'

- **Files:** the two 256 x 3 RGB tables in `lib/oif_cmocean.m`. The
  function code around them was written for this package (section 2).
- **Authors:** Kristen M. Thyng (cmocean colour maps); Chad A. Greene (MATLAB
  function `cmocean.m`, from which the tables were taken).
- **Source:** <https://github.com/matplotlib/cmocean>;
  <https://github.com/chadagreene/cmocean> (MATLAB File Exchange 57773).
- **Version:** the tables are textually identical to the 'bal' and 'amp'
  tables of the chadagreene/cmocean `cmocean.m` as downloaded on 2026-10-20.
- **Licence:** MIT License, `LICENSES/cmocean_MIT.txt` ("Copyright (c) 2015
  Kristen M. Thyng"; "Copyright (c) 2021 Chad Greene"). The notice is repeated
  in the header of `lib/oif_cmocean.m`.
- **Modifications:** only the 'balance' and 'amp' tables are included, in a
  new minimal function `oif_cmocean` (default 256 levels, a leading '-'
  reverses the map, linear resampling as in Greene's function), named so
  that it does not shadow a full `cmocean.m` on the MATLAB path.
- **Citation:** Thyng, K. M., C. A. Greene, R. D. Hetland, H. M. Zimmerle,
  and S. F. DiMarco (2016), True colors of oceanography: Guidelines for
  effective and accurate colormap selection, Oceanography, 29(3), 9-13,
  <https://doi.org/10.5670/oceanog.2016.66>.
- **Used by:** `lib/oif_occurrence_panel.m` ('amp'; Figs. 1f-h, S5 and S6),
  `plot/plot_figS11.m` and `plot/plot_figS12.m` ('balance').

## 2. Package-written replacements of helpers of the original analysis code

The files below were written for this package with built-in MATLAB functions
and are covered by the package licence. They contain none of the code they
replace. Before release, each one was compared with the function it replaces
on random inputs and on the inputs used by this package. That comparison needs
the replaced functions and is therefore not part of the package.

| File | Replaces | Agreement with the replaced function |
|---|---|---|
| `lib/fft_lowpass.m` | `smooft.m`, `realft.m` and `four1.m`, MATLAB translations of the Numerical Recipes routines SMOOFT, REALFT and FOUR1, whose licence does not permit redistribution. `fft_lowpass` implements the FFT smoothing method described by Press et al. (1986, Numerical Recipes, 1st ed., sec. 13.9, 'Smoothing of Data') with `fft` and `ifft`. | Relative difference at most 7.1e-15 in double precision (1,804 random series) and 7e-7 in single precision (902 random series). For the 20 model series smoothed for Fig. S1: at most 1.8e-14 (relative 1.8e-15) in double precision, and at most 1.8e-7 of the series maximum in single precision (up to 15 units in the last place at the smallest chlorophyll values), far too small to show in the figure. |
| `lib/roms_zlevs.m` | `zlevs4.m` of ROMSTOOLS (P. Penven; modified by Y. Uchiyama and E. Mason), licensed under the GPL, version 2 or later. `roms_zlevs` implements the ROMS vertical-coordinate equations (ROMS wiki page 'Vertical S-coordinate'; Shchepetkin and McWilliams 2005, 2009). | Depths agree to round-off: at most 1.1e-11 m in random cases with water depths up to 6000 m (1.8e-12 m, relative 5e-16, for the vertical-coordinate type used here), and 9.1e-13 m for the station columns of Figs. S1 and S2. |
| `lib/log_pm.m` | A helper of unknown author and licence (dated 2021-10-08). | Bitwise identical outputs, including all arrays plotted in Figs. S11 and S12. |
| `lib/rot.m` | A helper of unknown author and licence. | Bitwise identical. |
| `lib/redblue.m` | `redblue` by A. Auton (MATLAB File Exchange 25536, BSD licence). | Bitwise identical. |
| `lib/oif_cmocean.m` | A copy of Greene's `cmocean.m` that a third party had extended with further colour maps, including MATLAB's parula and the Turbo colour map. Only the function code is new; the tables are those of section 1.4. | Bitwise identical colour maps for all calls made by the package. |
| `lib/colormap_isleofdogs.m` | The data file `colormap_IsleOfDogs.dat` of undocumented origin (a linear ramp through the colours #25245D, #73BCAA, #E9C662 and #E64E46). | Bitwise identical table. |

The package therefore contains no Numerical Recipes code and no GPL-licensed
code.

## 3. External software required but not included

- **MATLAB** (The MathWorks), tested with R2025b. The plot scripts need base
  MATLAB only. `prep/prep_maps.m` uses the Image Processing Toolbox if it is
  available (`bwdist`, through `inpaintn`; see 1.3).
- **M_Map**, a mapping package for MATLAB by R. Pawlowicz,
  <https://www.eoas.ubc.ca/~rich/map.html>; version 1.4m was used. It is
  needed for the map figures (Figs. 1, S3, S4, S5 and S6) and is distributed
  under its own licence. Citation: Pawlowicz, R. (2020), M_Map: A mapping
  package for MATLAB, version 1.4m [Computer software], available online at
  www.eoas.ubc.ca/~rich/map.html.
- **Gibbs SeaWater (GSW) Oceanographic Toolbox of TEOS-10**,
  <https://www.teos-10.org/software.htm>; version 3.03/3.04 (2013) was used
  (`Contents.m` says 3.03, the function headers 3.04). It is needed
  only by `prep/prep_validation.m` (directly and through
  `lib/woa23_profile.m`) and is distributed under its own licence. Citation:
  McDougall, T. J., and P. M. Barker (2011), Getting started with TEOS-10 and
  the Gibbs Seawater (GSW) Oceanographic Toolbox, 28 pp., SCOR/IAPSO WG127,
  ISBN 978-0-646-55621-5.

`README.md` explains how to make M_Map and GSW available to the package.

## 4. Data

The sources of the data in `data/`, and the citations and acknowledgements
they require, are listed in `README.md`.
