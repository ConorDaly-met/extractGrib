# extractGrib

A utility to dynamically generate namelists for gl and to extract data from Harmonie FA/GRIB files

## Introduction

**extractGrib** deconstructs gl namelists and builds them up again.

### Author
Conor Daly
Met Éireann
<conor.daly@met.ie>

### Installation

- `git clone` this repo
-       ```
        $~> mkdir build
        $~> cd build
        $~> cmake .. -DCMAKE_INSTALL_PREFIX=/path/to/installation
        $~> make
        $~> make install
        $~> export PATH=/path/to/installation/bin:$PATH
        ```
- create your local file structure:
	```
	share/griblists/cccc/
	share/namelist_inc/cccc/
	share/paramlists/
	```
- [Populate](#setup) with parameter lists, sub-domains/projections, griblists
- Create environment variable USERAREA pointing to your `share/griblists` (Default is `~/hm_home/extractGrib/share/griblists`)

### ecFlow suite generation

An ecFlow suite can be generated given a list of model experiments defined in the config file.

- bin/create_suite.sh

A suite definition file will be created using the configuration of each model experiment. The script expects to find such model configuration files at ~/hm_home/${model_exp}/Env_system where ${model_exp} is the name of the model experiment.


### Workflow

#### Setup
1. Generate your [Parameter lists](#parameter-lists)
1. Generate your [Parameter namelists](#parameter-namelists)
1. Generate your [Sub-domains](#sub-domains-and-thinning)
1. Generate your [Griblists](#griblists)

#### Routine
1. [Extract](#extraction) data

### Parameter lists

- `${bindir}/share/paramlists/param_source.cfg` knows where the data is to be found

- You need to use [`${bindir}/bin/grib_paramlist.sh`](#grib_paramlistsh) to extract a list of parameters from an existing grib file
- Or you can create one by hand.
- These should be saved as some `share/paramlists/cccc/<param>.list`

### Parameter namelists

- Parameter namelist fragments are stored in `share/namelist_inc/cccc/30-<paramlist>_P-b.inc`

- You need to use [`${bindir}/bin/do_paramset.sh`](#do_paramsetsh) to create the fragments
- Or you can use [`${bindir}/bin/read_paramlist.sh`](#read_paramlistsh) to see an individual fragment

### Sub-domains and Thinning

- Subdomain namelist fragments are stored in `share/namelist_inc/cccc/20-<proj>.inc`

- Use [`${bindir}/bin/make_subdomain.sh`](#make_subdomainsh) to construct a sub-domain/thinned namelist fragment.
- Or you can use [`${bindir}/bin/grib_proj.sh`](#grib_projsh) to extract the fragment from an existing grib file

### Griblists

- Griblists define the set of namelist fragments to be used for a specific product
- Griblists are stored in `share/griblists/cccc/standing.list` and `share/griblists/cccc/user.list`
- [Samples](#griblist-samples) are in `${bindir}/share/griblists/`

### Extraction

- `${bindir}/bin/extract_fa.sh` does the actual namelist generation and extraction of data

- `${bindir}/bin/extractGrib` performs the functionality of Makegrib if called with the correct switches.

### Usage

	Usage:	bin/extractGrib [-a <USERAREA>] [-f <FCST/PATH>] [-m] [-t <type> [-t <type>]] [-h] [-i] [-k] [-n]
		bin/extractGrib -h

	Extracts requested dataset(s) from Harmonie FA outputs using user-supplied request lists.

	-a <USERAREA> 		Sets the source area for user lists (currently: $HOME/hm_home/extractGrib/share/griblists)
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

		DTG		2021062106	
						The date/time group for the forecast
		STEP		-1
						The forecast step
		ENSMBR		10
						The ensemble member
		NUMMBR		16
						The number of forecasts in the ensemble


#### grib_paramlist.sh

	Usage:	bin/grib_paramlist.sh </path/to/grib.file>
		bin/grib_paramlist.sh -h

	Extracts shortName,typeOfLevel,stepType,level from GRIB and translates to gl namelist
	
	-h	Show this help

Produces output of the form:

	#
	#/data/cdaly/cdtemp/bullnwpdata/mbr000/eidb/fc2021062106+012grib2_pp
	#14:of:14:messages:in:/data/cdaly/cdtemp/bullnwpdata/mbr000/eidb/fc2021062106+012grib2_pp
	#14:of:14:total:messages:in:1:files
	shortName:typeOfLevel:tri:level
	ct:entireAtmosphere:0:0
	cwat_cond:entireAtmosphere:0:0
	icei2:heightAboveGround:0:1524
	icei2:heightAboveGround:0:305
	icei2:heightAboveGround:0:610
	icei2:heightAboveGround:0:914
	lgt:entireAtmosphere:0:0
	mld:heightAboveGround:0:0
	prtp:heightAboveGround:0:0
	pscw:heightAboveGround:0:0
	pstbc:heightAboveGround:0:0
	pstb:heightAboveGround:0:0
	tcc:heightAboveGround:0:2
	vis:heightAboveGround:0:0

This output should be saved as the appropriate <param.list>.

Entries may be consolidated by merging the 'level' column with comma separated values and/or ranges thus

	icei2:heightAboveGround:0:305,610,914,1524

which will translate to four 'icei2' entries or

	w:hybrid:0:0-65

which will translate to 66 'w, hybrid' entries.  

A 'level' range of '-1' is passed through to gl unchanged, gl will expand this to 'all available'.

#### make_subdomain.sh

	Usage:	bin/make_subdomain.sh [-c <comment>] [(-r <resolution> | -rt <latres> -rn <lonres>)]
		(-sw <LATSOUTH>,<LONWEST> | -np <NLAT>,<NLON> | -lc <CLAT>,<CLON> | -ne <LATNORTH>,<LATEAST>) 

		bin/make_subdomain.sh -l <LAT>,<LON> [-c <comment>]

	Creates a gl namelist for the extraction of subdomain or point data
	
	-c <comment>	Adds a comment to the output

	############ Point extraction #####################
	-l <LAT>,<LON>	Specifies the point to be extracted.
			Output will be a csv file.

	############ Subdomain extraction #####################
	-sw <LAT>,<LON>		Coordinates of SouthWest corner
	-np <NLAT>,<NLON>	Number of grid points 
	-lc <LAT>,<LON>		Coordinates of Centre point
	-ne <LAT>,<LON>		Coordinates of NorthEast corner

	-r  <resolution>		Size of grid box in metres.  (Currently:  x )
	-rt <Latitude  resolution>	N-S length of gridbox in metres (Currently: )
	-rn <Longitude resolution>	W-E length of gridbox in metres (Currently: )

	The subdomain is specified by two of:
		The SouthWest corner,
		The number of grid points,
		The centre point,
		The NorthEast corner.
	
		The default gridbox size is  x 

		Output will be a grib subdomain
	

Produces output of the form:


	# Comment line
	  outgeo%dlon = 2500.
	  outgeo%dlat = 2500.
	  outgeo%gridtype = 'lambert'
	  outgeo%projlat = 53.5
	  outgeo%projlat2 = 53.5
	  outgeo%south = 49.8834
	  outgeo%west = -10.961
	  outgeo%projlon = 5.
	  outgeo%nlon = 236
	  outgeo%nlat = 271

The values:
- dlon,dlat specify the spatial resolution in metres
- nlon,nlat specify the number of gridpoints
- south,west specify the SW corner of the (sub-)domain.

This output should be saved to `share/namelist_inc/20-<proj>.inc where 'proj' is the name of the projection to be used in a [griblist](#griblists)

#### grib_proj.sh

	Usage:	bin/grib_proj.sh </path/to/grib.file>
		bin/grib_proj.sh -h

	Extracts projection information from GRIB and translates to gl namelist
	
	-h	Show this help

Produces output of the form:


	# /data/cdaly/cdtemp/bullnwpdata/mbr000/eidb/fc2021062106+012grib2_mlIoI
	  outgeo%dlon = 2500.
	  outgeo%dlat = 2500.
	  outgeo%gridtype = 'lambert'
	  outgeo%projlat = 53.5
	  outgeo%projlat2 = 53.5
	  outgeo%south = 49.8834
	  outgeo%west = -10.961
	  outgeo%projlon = 5.
	  outgeo%nlon = 236
	  outgeo%nlat = 271


or

	# /data/cdaly/cdtemp/bullnwpdata/mbr000/knmi/fc2021062106+010grib2_en_10k
	  outgeo%dlon = 10000.
	  outgeo%dlat = 10000.
	  outgeo%gridtype = 'lambert'
	  outgeo%projlat = 53.5
	  outgeo%projlat2 = 53.5
	  outgeo%south = 46.834
	  outgeo%west = -14.609
	  outgeo%projlon = 5.
	  outgeo%nlon = 129
	  outgeo%nlat = 145

The values:
- dlon,dlat specify the spatial resolution in metres
- nlon,nlat specify the number of gridpoints
- south,west specify the SW corner of the (sub-)domain.

This output should be saved to `share/namelist_inc/20-<proj>.inc where 'proj' is the name of the projection to be used in a [griblist](#griblists)

#### read_paramlist.sh

	Usage:	bin/read_paramlist.sh (-d|p|b) (-I|P) <path/to/param.list>
		bin/read_paramlist.sh -h

	Read param.list and write out a gl namelist stanza for the contained parameters.

	-d	Diagnostic    params (readkey%...)
	-p	Postprocessed params (pppkey%...)
	-b	Diag + Post_p params (pppkey%...)

	-I	ICMSHHARM... is the source FA file
	-P	PFHARM... is the source FA file

	-h	Show this help

produces output of the form:

	bin/read_paramlist.sh -b -P /data/cdaly/cdtemp/bullnwpdata/share/paramlists/eidb/pp.list 
	readkey%shortname='tcc',
	readkey%levtype='heightAboveGround',
	readkey%level=2,
	readkey%tri=0,

or:

	bin/read_paramlist.sh -b -B /data/cdaly/cdtemp/bullnwpdata/share/paramlists/eidb/pp.list 
	readkey%shortname='cb','ct','cwat_cond','icei2','icei2','icei2','icei2','lgt','mld','prtp','pscw','pstbc','pstb','tcc','vis',
	readkey%levtype='entireAtmosphere','entireAtmosphere','entireAtmosphere','heightAboveGround','heightAboveGround','heightAboveGround','heightAboveGround','entireAtmosphere','heightAboveGround','heightAboveGround','heightAboveGround','heightAboveGround','heightAboveGround','heightAboveGround','heightAboveGround',
	readkey%level=0,0,0,305,610,914,1524,0,0,0,0,0,0,2,0,
	readkey%tri=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

#### do_paramset.sh

	Usage:	bin/do_paramset.sh [-b] -o <path/to/namelists/> [-n <namelist_name>] <path/to/parameter.list> 
		bin/do_paramset.sh -h

	Reads <path/to/parameter.list> and outputs appropriate namelist entries for
		each of 'direct' and 'postprocessed' data from ICMSHHARM and PFHARM forecast files.

	-b Write both Diagnostic and Postprocessed params to a single namelist

	-o Output path.
		Files will be written of the form '30-parameter_P-d.inc' where 'parameter' is the
		name of the <parameter.list> with the '.list' extension removed.

	-n Namelist name.
		This will replace the 'parameter' element of the output filename.

	-h Show this help

This runs `${bindir}/bin/read_paramlist.sh` with the various switches necessary and saves output to `<path/to/namelists>/30-<param>_X-n.inc` where:

- X is one of B,I,P meaning: B - both, I - his, P - fullpos
- n is one of b,d,p meaning: b - both, d - direct, p - postprocessed

Typical usage is:

	bin/do_paramset.sh -o share/namelist_inc/cccc/ share/paramlists/cccc/<param>.list

#### Griblist Samples

	# Standing orders list for knmi files
	#
	# This file may not contain blank lines
	#
	# MEMORY keyword postprocesses data into memory.  This is used later to extract post-processed data to file.
	# A MEMORY keyword must precede the first extraction of postprocessed data to file
	#MEMORY		-C centre	-T	-p Parameter list
	# -T implies store to memory.
	#
	# A grib_extension is used to generate a file of the form: fcYYYYMMDDHH+SSS.grib_extension
	# Parameter list and Projection/sub-domain entries must exist in share/namelist_inc/centre/
	#grib_extension     -C centre -g grib1|2 -k packingType  -p Parameter list -r Projection|sub-domain
	MEMORY       -C knmi -T             -p en_B-p
	grib2_enIoI  -C knmi -g 2 -k ccsds  -p en_B-b -r IofIE
	MEMORY       -C knmi -T             -p en_B-p
	grib2_en_10k -C knmi -g 2 -k ccsds  -p en_B-b -r IRELAND25-10k

In the sample above, the following steps occur:

1. Input datafiles are read into memory

2. The [parameter](#parameter-lists) file `share/namelist_inc/knmi/30-en_B-p.inc` is used to to generate a `pppkey%...` namelist to be stored in memory 

	MEMORY       -C knmi -T             -p en_B-p

3. The [parameter](#parameter-lists) file `share/namelist_inc/knmi/30-en_B-b.inc` is used to to generate a `readkey%...` namelist to be reprojected using [projection](#sub-domain-and-thinning) file `share/namelist_inc/knmi/20-IofIE.inc` (Island of Ireland subdomain at standard model resolution) and written as 'grib2' using packingType 'ccsds' to output file: `knmi/fcYYYYMMDDHH+SSSgrib2_enIoI`

	grib2_enIoI  -C knmi -g 2 -k ccsds  -p en_B-b -r IofIE

4. The [parameter](#parameter-lists) file `share/namelist_inc/knmi/30-en_B-p.inc` is used to to generate a `pppkey%...` namelist to be stored in memory 

	MEMORY       -C knmi -T             -p en_B-p

5. The [parameter](#parameter-lists) file `share/namelist_inc/knmi/30-en_B-b.inc` is used to to generate a `readkey%...` namelist to be reprojected using [projection](#sub-domain-and-thinning) file `share/namelist_inc/knmi/20-IRELAND25-10k.inc` (full domain @10km resolution) and written as 'grib2' using packingType 'ccsds' to output file: `knmi/fcYYYYMMDDHH+SSSgrib2_enIoI`

	grib2_en_10k -C knmi -g 2 -k ccsds  -p en_B-b -r IRELAND25-10k

6. Finally, the various `pppkey%...` stanzas are merged into one to avoid unnecessary duplication of post-processing.
