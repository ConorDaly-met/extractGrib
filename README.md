# extractGrib

A utility to dynamically generate namelists for gl and to extract data from Harmonie FA/GRIB files

## Introduction

**extractGrib** deconstructs gl namelists and builds them up again.

### Installation

- `git clone` this repo
- create your local file structure:
	```
	etc/griblists/cccc/
	etc/namelist_inc/cccc/
	etc/paramlists/
	```
- Populate with parameter lists, sub-domains/projections, griblists
- Create environment variable USERAREA pointing to your `etc/griblists`

### Workflow

#### Setup
1. Generate your parameter lists
1. Generate your sub-domains
1. Generate your griblists

#### Routine
1. Extract data

### Parameter lists

- `etc/paramlists/param_source.cfg` knows where the data is to be found

- You need to use `bin/grib_paramlist.sh` to extract a list of parameters from an existing grib file
- Or you can create one by hand.
- These should be saved as some `<param>.list`

### Parameter namelists

- Parameter namelist fragments are stored in `etc/namelist_inc/30-<paramlist>_P-b.inc`

- You need to use `bin/do_paramset.sh` to create the fragments
- Or you can use `bin/read_paramlist.sh` to see an individual fragment

### Sub-domains and Thinning

- Subdomain namelist fragments are stored in `etc/namelist_inc/20-<proj>.inc`

- Use `bin/make_subdomain.sh` to construct a sub-domain/thinned namelist fragment.
- Or you can use `bin/grib_proj.sh` to extract the fragment from an existing grib file

### Griblists

- Griblists define the set of namelist fragments to be used for a specific product
- Griblists are stored in `etc/griblists/cccc/standing.list` and `etc/griblists/cccc/user.list`
- Samples are in `etc/griblists/`

### Extraction

- `bin/extract_fa.sh` does the actual namelist generation and extraction of data

- `bin/extractGrib` performs the functionality of Makegrib if called with the correct switches.

### Usage

	Usage:	bin/extractGrib [-a <USERAREA>] [-f <FCST/PATH>] [-m] [-t <type> [-t <type>]] [-h] [-i] [-k] [-n]
		bin/extractGrib -h

	Extracts requested dataset(s) from Harmonie FA outputs using user-supplied request lists.

	-a <USERAREA> 		Sets the source area for user lists (currently: etc/griblists)
	-f <FCST/PATH> 		Sets the input path for the forecast (currently: .)
	-m			Sets a member path of the form mbrXXX to be appended to <FCST/PATH>
	-t <type> 		Sets the input file type(s) for the forecast (currently: fp his)
					 Available types are	fp  - fullpos
								his - history
								sfx - SURFEX

	-i		Fetch the forecast files directly from the I/O servers
	-k		Do not delete the namelist
	-n		Dry-run.  Does not execute the gl run, just makes and displays the namelist

	-h		Show this help

	Environment Variables:

	extractGrib expects the following environment variables to be set:

		Variable	Current Value	Comment
		FCSTPATH	.
						Path to the input forecast
		EXPT		HARM	
						The experiment name
		DOMAIN		IRELAND25_090
						The forecast domain name
		EZONE		11
						The boundary zone to remove from his/sfx files

		DTG		2021061006	
						The date/time group for the forecast
		STEP		3	
						The forecast step
		ENSMBR		-1
						The ensemble member
		NUMMBR		16
						The number of forecasts in the ensemble

