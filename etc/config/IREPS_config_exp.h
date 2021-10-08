# -*- shell-script -*-
# HARMONIE experiment configuration file
#
# Please read the documentation on https://hirlam.org/trac/wiki/HarmonieSystemDocumentation first
#
# NB! All combinations may not be valid or well tested
#
# Set a few host-specific variables (ECMWF vs KNMI)
if [ "$COMPCENTRE" == "ECMWF" ]
then
    OBDIR=$TCWORK/lb/obs_all
    NBDMAX=6
    MULTITASK=no
    BDDIR=$TCWORK/lb/ECMWF_IREPS_boundaries/@YYYY@/@MM@/@DD@/@HH@
    ENSMSEL=0-1
    MAKEGRIB_LISTENERS=5
    MAKEGRIB_ENS_LISTENERS=1
    ME_APPS=yes
elif [ "$COMPCENTRE" == "KNMI" ]
then
    OBDIR=$HOME/scratch/obs/for_ireps
    NBDMAX=57
    MULTITASK=yes
    BDDIR=/lustre1/operation/prodharm/scratch/boundaries
    ENSMSEL=0-5
    MAKEGRIB_LISTENERS=4
    MAKEGRIB_ENS_LISTENERS=4
    ME_APPS=no
fi



# **** Build and bin paths ****
# Definitions about Build, should fit with hm_rev
BUILD=${BUILD-yes}                            # Turn on or off the compilation and binary build ( yes|no)
BINDIR=${BINDIR-$HM_DATA/bin}                 # Binary directory

COMPILE_ENKF=${COMPILE_ENKF-"no"}             # Compile LETKF code (yes|no)
COMPILE_DABYFA=${COMPILE_DABYFA-"no"}         # Compile FA/VC code (yes|no)
SURFEX_OFFLINE_BINARIES="no"                  # Switch to compile and use offline SURFEX binaries

# **** Misc, defined first because it's used later ****

CNMEXP=HARM                             # Four character experiment identifier
WRK=$HM_DATA/$CYCLEDIR                  # Work directory

# **** Paths to archive ****
# We need to define ARCHIVE early since it might be used further down


ARCHIVE_ROOT=$HM_DATA/archive           # Archive root directory
ECFSLOC=                                # Archiving site at ECMWF-ECFS: "ec" or ECFS-TMP "ectmp"
ECFSGROUP=hirald                        # Group in which to chgrp the ECMWF archive, "default" or "hirald"
EXTRARCH=$ARCHIVE_ROOT/extract          # Archive for fld/obs-extractions


# **** Running mode ****
RUNNING_MODE=operational                # Research or operational mode (research|operational)
                                        # operational implies that the suite will continue even if e.g.
                                        # observations are missing or assimilation fails

SIMULATION_TYPE=nwp                     # Type of simulation (nwp|climate)
FP_PRECISION=double                     # double|single  (if makeup config file updated)

# **** Model geometry ****
DOMAIN=IRELAND25_090                    # See definitions in scr/Harmonie_domains.pm
TOPO_SOURCE=gmted2010                   # Input source for orography. Available are (gmted2010|gtopo30)
GRID_TYPE=QUADRATIC                     # Type of grid (LINEAR|QUADRATIC|CUBIC)
VLEV=65                                 # Vertical level definition name
                                        # HIRLAM_60, MF_60,HIRLAM_40, or
                                        # BOUNDARIES = same number of levs as on boundary file.
                                        # See the other choices from scr/Vertical_levels.pl

# **** High level forecast options ****
DYNAMICS="nh"                           # Hydrostatic or non-hydrostatic dynamics (h|nh)
VERT_DISC=vfd                           # Discretization in the vertical (vfd,vfe)
                                        # Note that vfe does not yet work in non-hydrostatic mode
PHYSICS="arome"                         # Main model physics flag (arome|alaro)
DFI="none"                              # Digital filter initialization (idfi|fdfi|none)
                                        # idfi : Incremental dfi
                                        # fdfi : Full dfi
                                        # none : No initialization (AROME default case)
LSPBDC=no                               # Spectral upper boundary contions option (no|yes)
LGRADSP=yes                             # Apply Wedi/Hortal vorticity dealiasing (yes|no)
LUNBC=yes                               # Apply upper nested boundary condition (yes|no)

# Highlighted physics switches
CISBA="3-L"                             # Type of ISBA scheme in SURFEX. Options: "3-L"|"2-L"|"DIF"
CSNOW="D95"                             # Type of snow scheme in SURFEX. Options: "D95" and "3-L"
CROUGH="NONE"                           # SSO scheme used in SURFEX "NONE"|"Z01D"|"BE04"|"OROT"
SURFEX_SEA_ICE="none"                   # Treatment of sea ice in surfex (none|sice)
MODIFY_LAKES=F                          # Use Vanern/VAttern as Sea, requires new climate files
SURFEX_LAKES="FLAKE"                    # Treatment of lakes in surfex (WATFLX|FLAKE)
MASS_FLUX_SCHEME=edmfm                  # Version of EDMF scheme (edkf|edmfm)
                                        # Only applicable if PHYSICS=arome
                                        # edkf is the AROME-MF version
                                        # edmfm is the KNMI implementation of Eddy Diffusivity Mass Flux scheme for Meso-scale
STATNW="yes"                            # Switch for new set up cloud scheme (yes|no)
HARATU="yes"                            # Switch for HARATU turbulence scheme (yes|no)
HGT_QS="no"                             # Switch for height dependent VQSIGSAT (yes|no)
ALARO_VERSION=0                         # Alaro version (1|0)
NPATCH=2                                # Number of patches over land in SURFEX (see also LISBA_CANOPY)
LISBA_CANOPY=".FALSE."                  # Activates surface boundary multi layer scheme over land in SURFEX (must be .FALSE. for NPATCH>1)
XRIMAX=0.0                              # Maximum allowed Richardson number in the surface layer (cy40h default was 0.0)
RADSCHEME="IFS"                         # Choose between the default IFS scheme ("IFS") or the ALARO ACRANBE2 scheme ("ACRA") for use in AROME physics.

# Rsmin settings
RSMIN_DECIDUOUS_FACTOR=1.13             # Multiply forest and trees default RSMIN values with this factor
RSMIN_CONIFEROUS_FACTOR=1.44            # Multiply coniferous trees default RSMIN values with this factor
RSMIN_C3_FACTOR=1.5                     # Multiply C3 crops and grass default RSMIN values with this factor
RSMIN_C4_FACTOR=1.13                    # Multiply C4 crops default RSMIN values with this factor


# Coefficients for soil, vegetation and snow heat capacities
XCGMAX=2.0E-5				# Maximum value for soil heat capacity; default=2.0E-5
CV_LOWVEG=2.0E-5			# Value for low vegetation heat capacity; default=2.0E-5
CV_HIGHVEG=1.0E-5			# Value for high vegetation heat capacity; default=1.0E-5
XCSMAX=2.0E-4				# Maximum value for snow heat capacity; default=2.0E-4

# Coefficients for vegetation roughness length for grass and crops
XALLEN_TERM=2.5                         # crops: zallen=exp((LAI-XALLEN_TERM)/1.3); default=3.5
XGRASS_H_DNM=3.0                        # grass: z0=0.13*LAI/XGRASS_H_DNM; default=6.0

# Coefficients for exchange coefficients CD and CH in stable case over nature tile
XCD_COEFF1=10.0				# ZFM = 1. + XCD_COEFF1*PRI(JJ) / SQRT( 1.+XCD_COEFF2*PRI(JJ) )
XCD_COEFF2=5.0                          # ZFM = 1. + XCD_COEFF1*PRI(JJ) / SQRT( 1.+XCD_COEFF2*PRI(JJ) )
XCH_COEFF1=15.0                         # PAC(JJ) = ZCDN(JJ)*ZVMOD(JJ)/(1.+XCH_COEFF1*ZSTA(JJ)*ZDI(JJ)

# **** Assimilation ****
ANAATMO=3DVAR                           # Atmospheric analysis (3DVAR|4DVAR|blending|none)
AUGMENT_CV=NO                           # Augment control vector (NO|ENS)
Q_IN_SP=no                              # Transform humidity to spectral space for minimization using AROME(no|yes)    
ANASURF=CANARI_OI_MAIN                  # Surface analysis (CANARI_OI_MAIN|OI|CANARI_EKF_SURFEX|EKF|fgcopy|none)
                                        # CANARI_OI_MAIN    : CANARI + SURFEX OI
                                        # CANARI_EKF_SURFEX : CANARI + SURFEX EKF ( experimental )
                                        # OI                : TITAN + gridPP + SODA
                                        # EKF               : TITAN + gridPP + SODA
                                        # fgcopy            : Copy initial from previous cycle
                                        # none              : No surface assimilation, cold start each cycle
ANASURF_OI_COEFF="POLYNOMES_ISBA_MF6"   # Specify use of OI coefficients file (POLYNOMES_ISBA|POLYNOMES_ISBA_MF6)
                                        # POLYNOMES_ISBA_MF6 means 6 times smaller coefficients for WG2 increments
ANASURF_MODE="before"                   # When ANASURF should be done
                                        # before            : Before ANAATMO
                                        # after             : After ANAATMO
                                        # both              : Before and after ANAATMO (Only for ANAATMO=4DVAR)
NNCV="1,1,1,1"                          # Active EKF control variables. 1=WG2 2=WG1 3=TG2 4=TG1
NNCO="1,1,0,0,1"                        # Active observation types (Element 1=T2m, element 2=RH2m and element 3=Soil moisture, element 5=SWE)
CFORCING_FILETYPE="NETCDF"              # Offline surfex forcing format (NETCDF/ASCII)

MAKEODB2=no                             # Conversion of ODB-1 to ODB-2 using odb_migrator

SST_SOURCES="IFS"                       # List of external SST sources like IFS|HIROMB|NEMO|ROMS
                                        # See util/gl/ala/merge_ocean.F90 for more details

LSMIXBC=no                              # Spectral mixing of LBC0 file before assimilation
JB_INTERPOL=no                          # Interpolation of structure functions from a pre-defined domain to your domain
JB_REF_DOMAIN=DKCOEXP                   # Reference domain used for interpolation of structure functions.
                                        # Note that the vertical level definition has to be the same

# **** Observations ****
OBDIR=$OBDIR                            # Observation file directory
SINGLEOBS=no                            # Run single obs experiment with observation created by scr/Create_single_obs (no|yes)

USE_MSG=no                              # Use MSG data for adjustment of inital profiles, EXPERIMENTAL! (no|yes)
MSG_PATH=$SCRATCH/CLOUDS/               # Location of input MSG FA file, expected name is MSGcloudYYYYMMDDHH

# **** 4DVAR settings ****
NOUTERLOOP=2                            # 4DVAR outer loops, need to be 1 at present
ILRES=2,2                               # Resolution (in parts of full) of outer loops
TSTEP4D=120,120                         # Timestep length (seconds) of outer loops TL+AD
TSTEPTRAJ=600                           # How often the model state is saved for linearization
TL_TEST=yes                             # Only active for playfile tlad_tests
AD_TEST=yes                             # Only active for playfile tlad_tests
CH_RES_SPEC=yes                         # yes => change of resolution of the increment spectrally; no => by FULLPOS
FORCE1=no                               # yes => tendency increment; no => analysis increment in loop 1
FORCE2=no                               # yes => tendency increment; no => analysis increment in loop 2

# **** LETKF ****
HYBRID=no                               # Dummy here, needed by CheckOptions.pl
LETKF_3DSCREEN="yes"                    # Dummy here, needed by include.ass
LETKF_LAG="no"
if [ $ANAATMO = LETKF ]; then
  ANASURF_MODE="after"                  # Highly recommended so far. Better scores than "before". This needs research...
  ADDITIVE_INFLATION="TRUE"             # Default option... So far better scores
  HYBRID=no                             # (yes|no) to allow hybrid 3DVAR/LETKF analysis. Gain recentred ensemble method
  KHYBRID=0.5                           # Weight factor for hybrid analysis (only valid if HYBRID=yes)
  LETKF_3DSCREEN="yes"                  # (yes|no) to compute H(x) in Screening (no integration along analysis window, much cheaper computing)
  LSMIXBC="no"                          # LSMIXBC is yes only for the control member (see harmonie.pm). LSMIX has very positive impact
  CH_RES_SPEC=no                        # This is for when using LETKF_3DSCREEN="no"
  NOUTERLOOP=1                          # This is for when using LETKF_3DSCREEN="no"
  AI_ARCH=$HM_DATA/add_infl             # archive directory for additive inflation. Useful if one reruns an experiment not to use MARS again
  LETKF_LAG="no"                        # (yes|no) to double ensemble size by using ENSSIZE members from previous run
  LETKF_CONTROL="yes"                   # (yes|no) to use background from control member to construct LETKF analysis (KENDA approximation)
fi

# **** DFI setting ****
TAUS=5400                               # cut-off frequency in second
TSPAN=5400                              # 7200s or 5400s

# **** Nesting ****
HOST_MODEL="ifs"                        # Host model (ifs|hir|ald|ala|aro)
                                        # ifs : ecmwf data
                                        # hir : hirlam data
                                        # ald : Output from aladin physics
                                        # ala : Output from alaro physics
                                        # aro : Output from arome physics

HOST_SURFEX="no"                        # yes if the host model is run with SURFEX

NBDMAX=$NBDMAX                          # Number of parallel interpolation tasks

MULTITASK=$MULTITASK                    # Submit jobs through the multi task script
BDLIB=ECMWF                             # Boundary experiment, set:
                                        # ECMWF to use MARS data
                                        # RCRa  to use RCRa data from ECFS
                                        # Other HARMONIE/HIRLAM experiment

BDDIR=$BDDIR                                            # Boundary file directory,
                                                        # For more information, read in scr/Boundary_strategy.pl
INT_BDFILE=$WRK/ELSCF${CNMEXP}ALBC@NNN@                 # Interpolated boundary file name and location

BDSTRATEGY=available            # Which boundary strategy to follow
                                # as defined in scr/Boundary_strategy.pl
                                #
                                # available            : Search for available files in BDDIR, try to keep forecast consistency
                                #                        This is ment to be used operationally.
                                # available_dis_[ens|det] : Search for available ENS/HRES files in BDDIR expecting dissemination style file content, 
                                #                           try to keep forecast consistency. This is ment to be used operationally. 
                                # simulate_operational[_dis[_ens|_det]] : Mimic the behaviour of the operational runs using ECMWF LBC, ie
                                #                        6h old boundaries at 00,06,12,18
                                #                        7-11h at the other cycles
                                # simulate_metcoop     : Mimic the behaviour of the MetCoOp operational runs using ECMWF LBC ie
                                #                        6h old boundaries at 00,06,12,18
                                #                        3h old boundaries at 03,09,15,21
                                # same_forecast        : Use all boundaries from the same forecast, start from analysis
                                # analysis_only        : Use only analysises as boundaries
                                # era                  : As for analysis_only but using ERA interim data
                                # e40                  : As for analysis_only but using ERA40 data
                                # era5                 : As for analysis_only but using ERA5 data
                                # latest               : Use the latest possible boundary with the shortest forecast length
                                # RCR_operational      : Mimic the behaviour of the RCR runs, ie
                                #                        12h old boundaries at 00 and 12 and
                                #                        06h old boundaries at 06 and 18

                                # Special ensemble strategies
                                # Only meaningful with ENSMSEL non-empty, i.e., ENSSIZE > 0

                                # enda                 : use ECMWF ENDA data for running ensemble data assimilation
                                #                        or generation of background statistic.
                                #                        Note that only LL up to 9h is supported
                                #                        with this you should set your ENSMSEL members
                                # eps_ec               : ECMWF ENS members from the GLAMEPS ECFS archive.
                                #                        Data available from Feb 2013 - June 2019
                                # eps_ec_oper          : ECMWF ENS members from the operational archives
                                #                        note that data has a limited lifetime in MARS

BDINT=1                         # Boundary interval in hours
PERTDIA_BDINT=6                 # Perturbation diagnostics interval

# *** Ensemble mode general settings. ***
# *** For member specific settings use suites/harmonie.pm ***
ENSMSEL=$ENSMSEL                        # Ensemble member selection, comma separated list, and/or range(s):
                                        # m1,m2,m3-m4,m5-m6:step    mb-me == mb-me:1 == mb,mb+1,mb+2,...,me
                                        # 0=control. ENSMFIRST, ENSMLAST, ENSSIZE derived automatically from ENSMSEL.
ENSINIPERT=                            # Ensemble perturbation method (bnd|randb)
                                        # bnd     : PertAna
                                        # randb   : Perturbation of B-matrix
EPERT_MODE="after"                      # add IC perturbations before/after analysis in EPS mode
ENSCTL=                                 # Which member is my control member? Needed for ENSINIPERT=bnd. See harmonie.pm.
ENSBDMBR=                               # Which host member is used for my boundaries? Use harmonie.pm to set.

SCALE_PERT=yes                          # Scale perturbations based on energy norm and
EREF=35000.                             # energy reference
SLAFK=1.0                               # best set in harmonie.pm
SLAFLAG=0                               # --- " ---
SLAFDIFF=0                              # --- " ---

ENS_BD_CLUSTER=no                       # Switch on clustering for ENS data. Only has a meaning if BDSTRATEGY=eps_ec_oper
REARCHIVE_EPS_EC_OPER=no                # Rearchive ENS data on ECFS
USE_REARCHIVE_EPS_EC_OPER=no            # Use rearchived ENS data on ECFS
ECFS_EPS_EC_BD_PATH=${ECFSLOC}:/$USER/harmonie/$EXP    # Location for rearchiving

# **** SPPT Stochastic Perturbed Parameterisation Tendencies ****
SPPT=no                                 # Activate SPPT (no/yes)
SDEV_SDT=0.20                           # 0.50   0.20
TAU_SDT=28800                           # 28800            (8 hours)
XLCOR_SDT=2000000                       # 500000 2000000   (500 km)
XCLIP_RATIO_SDT=5.0                     # 2.0    5.0
LSPG_SDT='.FALSE.'                      # .TRUE. to activate SPG
SPGQ_SDT=0.5                            # only used for LSPG_SDT=T
SPGADTMIN_SDT=0.15                      # -"-
SPGADTMAX_SDT=3.0                       # -"-
export LSPSDT SDEV_SDT TAU_SDT XLCOR_SDT XCLIP_RATIO_SDT
export LSPG_SDT SPGQ_SDT SPGADTMIN_SDT SPGADTMAX_SDT

# **** SPP Stochastically Perturbed Parameterizations ***
SPP=no                                  # Activate LSPP (no|yes)
SDEV_SPP=0.2                            # Standard deviation
TAU_SPP=21600.                          # Time scale (seconds)
XLCOR_SPP=1000000.                      # Length scale (m)
SPGQ_SPP=0.5                            # only used for LSPG_SDT=T
SPGADTMIN_SPP=0.15                      # -"-
SPGADTMAX_SPP=3.0                       # -"-
NPATFR_SPP=-1                           # Frequencey to evolve pattern >0 in timesteps, <0 in hours
export LSPP SDEV_SPP TAU_SPP XLCOR_SPP SPGQ_SPP SPGADTMIN_SPP SPGADTMAX_SPP NPATFR_SPP

# Physics diagnostics
TEND_DIAG=no                           # Output of tendencies from physics (no|yes)

# *** This part is for EDA with observations perturbation
# Only active in ensemble mode
PERTATMO=CCMA                           # ECMAIN  : In-line observation perturbation using the default IFS way.
                                        # CCMA    : Perturbation of the active observations only (CCMA content)
                                        #           before the Minimization, using the PERTCMA executable.
                                        # none    : no perturbation of upper-air observations

PERTSURF=model                          # ECMA    : perturb also the surface observation before Canari (recommended
                                        #         : for EDA to have full perturbation of the initial state).
                                        # model   : perturb surface fields in grid-point space (recursive filter)
                                        # none    : no perturbation for surface observations.

FESTAT=no                               # Extract differences and do Jb calculations (no|yes)


# **** Climate files ****
CREATE_CLIMATE=${CREATE_CLIMATE-yes}    # Run climate generation (yes|no)
CLIMDIR=$HM_DATA/climate/$DOMAIN        # Climate files directory
BDCLIM=$HM_DATA/${BDLIB}/climate        # Boundary climate files (ald2ald,ald2aro)
                                        # This should point to intermediate aladin
                                        # climate file in case of hir2aro,ifs2aro processes.
ECOCLIMAP_PARAM_BINDIR=$HM_DATA/climate # Binary cover param files directory
CAERO=tegen                             # Climatological aerosol (AOD) tegen | camsaod | camsmmr

# Physiography input for SURFEX
ECOCLIMAP_VERSION=SG                    # Version of ECOCLIMAP for surfex
                                        # Available versions are 1.1-1.5,2.0-2.2,2.2.1,2.5_plus and SG
                                        # FLake requires 2.5_plus or SG
XSCALE_H_TREE=1.0                       # Scale the tree height with this factor
LDB_VERSION=3.0                         # Lake database version.
SOIL_TEXTURE_VERSION=SOILGRID           # Soil texture input data FAO|HWSD_v2|SOILGRID

# Path to pre-generated domains, in use if USE_REF_CLIMDIR=yes set in Env_system
# Saves time for quick experiments
REF_CLIMDIR=

# **** Archiving settings ****
ARCHIVE_ECMWF=yes                       # Archive to $ECFSLOC at ECMWF (yes|no)
# Archiving selection syntax, settings done below
#
# [fc|an|pp]_[fa|gr|nc] : Output from
#  an : All steps from upper air and surface analysis
#  fc : Forecast model state files from upper air and surfex
#  pp : Output from FULLPOS and SURFEX_LSELECT=yes (ICMSHSELE+NNNN.sfx)
# in any of the formats if applicable
#  fa : FA files
#  gr : GRIB[1|2] files
#  nc : NetCDF files
# sqlite|odb|VARBC|bdstrategy : odb and sqlite files stored in odb_stuff.tar
# fldver|ddh|vobs|vfld : fldver/ddh/vobs/vfld files
# climate : Climate files from PGD and E923
# Some macros
# odb_stuff=odb:VARBC:bdstrategy:sqlite
# verif=vobs:vfld
# fg : Required files to run the next cycle


# **** Cycles to run, and their forecast length ****
TFLAG="h"                               # Time flag for model output. (h|min)
                                        # h   = hour based output
                                        # min = minute based output

# The unit of HWRITUPTIMES, FULLFATIMES, ..., SFXFWFTIMES should be:
#   - hours   if TFLAG="h"
#   - minutes if TFLAG="min"

# Writeup times of # history,surfex and fullpos files
# Comma separated list, and/or range(s) like:
# t1,t2,t3-t4,t5-t6:step    tb-te == tb-te:1 == tb,tb+1,tb+2,...,te

if [ "$SIMULATION_TYPE" == climate ]; then  

  # Specific settings for climate simulations

  HH_LIST="00"                            # Which cycles to run, replaces FCINT                             | Irrelevant for climate simulations, but needs to be set
  LL_LIST="57"                             # Forecast lengths for the cycles [h], replaces LL, LLMAIN        | Irrelevant for climate simulations, but needs to be set
                                          # The LL_LIST list is wrapped around if necessary, to fit HH_LIST
  HWRITUPTIMES="00-760:1"                 # History file output times
  FULLFAFTIMES="$HWRITUPTIMES"            # History FA file IO server gather times. Must be equal to HWRITUPTIMES as convertFA cannot handle IOserver parts
  PWRITUPTIMES=$HWRITUPTIMES              # Postprocessing times
  VERITIMES=$HWRITUPTIMES                 # Verification output times, changes PWRITUPTIMES/SFXELTIMES
  SFXSELTIMES=$HWRITUPTIMES               # Surfex select file output times - Only meaningful if SURFEX_LSELECT=yes
  SWRITUPTIMES="00-760:12"                # Surfex model state output times
  SFXWFTIMES=$SWRITUPTIMES                # SURFEX history FA file IO server gathering times

  ARSTRATEGY="climate:fg:pp_nc"           # Files to archive on ECFS, see above for syntax

elif [ -z "$ENSMSEL" ] ; then

  # Standard deterministic run

  HH_LIST="00-21:3"                       # Which cycles to run, replaces FCINT
  LL_LIST="57"             # Forecast lengths for the cycles [h], replaces LL, LLMAIN
                                          # The LL_LIST list is wrapped around if necessary, to fit HH_LIST
  HWRITUPTIMES="00-60:1"                  # History file output times
  FULLFAFTIMES=$HWRITUPTIMES              # History FA file IO server gather times
  PWRITUPTIMES="00-60:1"                  # Postprocessing times
  PFFULLWFTIMES=$PWRITUPTIMES             # Postprocessing FA file IO server gathering times
  VERITIMES="00-60:1"                     # Verification output times, changes PWRITUPTIMES/SFXSELTIMES
  SFXSELTIMES="00-57:3"                   # Surfex select file output times
                                          # Only meaningful if SURFEX_LSELECT=yes
  SFXSWFTIMES=$SFXSELTIMES                # SURFEX select FA file IO server gathering times
  SWRITUPTIMES="00-06:3"                  # Surfex model state output times
  SFXWFTIMES=$SWRITUPTIMES                # SURFEX history FA file IO server gathering times

  ARSTRATEGY="fg:pp_nc"           # Files to archive on ECFS, see above for syntax
  CONVERTFA=yes

else

  # EPS settings
  # Note that member specific settings like e.g. for the control member (0)
  # is found in suites/harmonie.pm

  HH_LIST="00-21:3"                       # Which cycles to run, replaces FCINT
  LL_LIST="3"                             # Forecast lengths for the cycles [h], replaces LL, LLMAIN
  HWRITUPTIMES="00-57:1"                  # History file output times
  FULLFAFTIMES=$HWRITUPTIMES              # History FA file IO server gather times
  PWRITUPTIMES="00-57:1"                  # Postprocessing times
  PFFULLWFTIMES=$PWRITUPTIMES             # Postprocessing FA file IO server gathering times
  VERITIMES="00-57:1"                     # Verification output times, changes PWRITUPTIMES/SFXSELTIMES
  SFXSELTIMES="00-57:3"                   # Surfex select file output times
                                          # Only meaningful if SURFEX_LSELECT=yes
  SFXSWFTIMES=$SFXSELTIMES                # SURFEX select FA file IO server gathering times
  SWRITUPTIMES="00-06:3"                  # Surfex model state output times
  SFXWFTIMES=$SWRITUPTIMES                # SURFEX history FA file IO server gathering times

  ARSTRATEGY="fg:verif:odb_stuff: \
              [an|fc|pp]_fa"              # Files to archive on ECFS, see above for syntax


  CONVERTFA=yes

fi

SURFEX_LSELECT="yes"                    # Only write selected fields in surfex outpute files. (yes|no)
                                        # Check nam/surfex_selected_output.pm for details.
                                        # Not tested with lfi files.
INT_SINI_FILE=$WRK/SURFXINI.fa          # Surfex initial file name and location

# **** Postprocessing/output ****
IO_SERVER=yes                           # Use IO server (yes|no). Set the number of cores to be used
                                        # in your Env_submit
IO_SERVER_BD=yes                        # Use IO server for reading of boundary data
POSTP="inline"                          # Postprocessing by Fullpos (inline|offline|none).
                                        # See Select_postp.pl for selection of fields.
                                        # inline: this is run inside of the forecast
                                        # offline: this is run in parallel to the forecast in a separate task

FREQ_RESET_TEMP=3                       # Reset frequency of max/min temperature values in hours, controls NRAZTS
FREQ_RESET_GUST=1                       # Reset frequency of max/min gust values in hours, controls NXGSTPERIOD
                                        # Set to -1 to get the same frequency _AND_ reset behaviour as for min/max temperature
                                        # See yomxfu.F90 for further information.

# **** Check SP tendency evolution ****
CHKEVO="no"                             # (yes|no). If "yes" a CHKEVO_SPTEND file is created in $ARCHIVE
[ $CHKEVO = "yes" ] && POSTP="none"

# **** GRIB ****
CONVERTFA=${CONVERTFA-yes}              # Conversion of FA file to GRIB/nc (yes|no)
ARCHIVE_FORMAT=GRIB2                    # Format of archive files (GRIB1|GRIB2|nc). nc format yet only available in climate mode
NCNAMES=nwp                             # Nameing of NetCDF files follows (climate|nwp) convention.
RCR_POSTP=no                            # Produce a subset of fields from the history file for RCR monitoring

                                       # Only applicable if ARCHIVE_FORMAT=grib
MAKEGRIB_LISTENERS=$MAKEGRIB_LISTENERS               # Number of parallel listeners for Makegrib
                                        # Only applicable if ARCHIVE_FORMAT=grib
MAKEGRIB_ENS_LISTENERS=$MAKEGRIB_ENS_LISTENERS                # Number of parallel listeners for Makegrib - non control members


# **** Verification extraction ****
OBSEXTR=no                              # Extract observations from BUFR (yes|no)
FLDEXTR=yes                             # Extract model data for verification from model files (yes|no)
FLDEXTR_TASKS=4                         # Number of parallel tasks for field extraction
VFLDEXP=$EXP                            # Experiment name on vfld files


# *** Field verification ***
FLDVER=yes                               # Main switch for field verification and analysis increments (yes|no)
FLDVER_HOURS="03"                        # Hours for field verification, for ana-increments the cycling 
                                         # interval must be in the list
AI_ACCUMULATION_CYCLES="ALL" #"00 03 06 09 12 15 18 21"            # Accumlate ana-increments for these cycles
AI_ACCUMULATION_HOURS=$((30*24))           # Accumulate ana-increments over 30 days

# *** Observation monitoring ***
OBSMONITOR=no                           # Create Observation statistics plots
                                        # Format: OBSMONITOR=Option1:Option2:...:OptionN
                                        # obstat: Daily usage maps and departures
                                        # no: Nothing at all
                                        #
                                        # obstat is # only active if ANAATMO != none
OBSMON_SYNC=no                          # Sync obsmn sqlite tables to ecgate (yes|no)

# Recipient(s) to send mail to when a task aborts
MAIL_ON_ABORT=nwp.ops@met.ie                          # you@work,you@home

# Directory for applications/post-processing tasks (Met Eireann)
HM_APP=$HM_DATA/app
# Switch Met Eireann applications on or off
ME_APPS=$ME_APPS

# Exporting variables for the system
export ARCHIVE_ROOT EXTRARCH BINDIR HH_LIST LL_LIST WRK CLIMDIR REF_CLIMDIR ECOCLIMAP_PARAM_BINDIR MODEL
export BDLIB BDDIR BDINT BDSTRATEGY NBDMAX MARS_EXPVER HOST_MODEL
export GRID_TYPE
export TFLAG POSTP RCR_POSTP CONVERTFA ARCHIVE_FORMAT MAKEGRIB_LISTENERS MAKEGRIB_ENS_LISTENERS
export ECFSLOC ECFSGROUP NLBC FCINT DOMAIN BDCLIM LSMIXBC CISBA CSNOW NNCV NNCO CROUGH SURFEX_SEA_ICE TOPO_SOURCE SURFEX_LAKES
export VERITIMES OBSEXTR FLDEXTR FLDEXTR_TASKS VFLDEXP
export SURFEX_LSELECT CFORCING_FILETYPE
export BUILD CREATE_CLIMATE
export COMPILE_DABYFA COMPILE_ENKF
export HWRITUPTIMES SWRITUPTIMES PWRITUPTIMES FLDVER_HOURS FLDVER HOST_SURFEX
export FULLFAFTIMES PFFULLWFTIMES
export SFXSELTIMES SFXWFTIMES SFXSWFTIMES
export ANASURF_MODE EXT_BDDIR EXT_BDFILE EXT_ACCESS JB_INTERPOL JB_REF_DOMAIN SINGLEOBS ANASURF_OI_COEFF
export NPATCH LISBA_CANOPY SURFEX_OFFLINE_BINARIES XRIMAX RADSCHEME
export RSMIN_DECIDUOUS_FACTOR RSMIN_CONIFEROUS_FACTOR RSMIN_C3_FACTOR RSMIN_C4_FACTOR
export XSCALE_H_TREE
export BDFILE NCNAMES
export ANAATMO ANASURF VLEV VER_SDATE ARCHIVE_ECMWF FLDEXTR SST_SOURCES
export MAKEODB2
export OBDIR OBSMONITOR OBSMON_SYNC
export DYNAMICS PHYSICS DFI TAUS TSPAN LGRADSP LSPBDC LUNBC
export CNMEXP RUNNING_MODE MASS_FLUX_SCHEME STATNW HARATU HGT_QS
export INT_BDFILE INT_SINI_FILE
export ECOCLIMAP_VERSION SOIL_TEXTURE_VERSION LDB_VERSION
export SIMULATION_TYPE FP_PRECISION
export ARSTRATEGY FREQ_RESET_TEMP FREQ_RESET_GUST
export IO_SERVER IO_SERVER_BD
export MAIL_ON_ABORT
export USE_MSG MSG_PATH
export NOUTERLOOP ILRES TSTEP4D TSTEPTRAJ TL_TEST AD_TEST CH_RES_SPEC
export FORCE1 FORCE2
export ADDITIVE_INFLATION HYBRID KHYBRID LETKF_3DSCREEN AI_ARCH LETKF_LAG LETKF_CONTROL
export AUGMENT_CV Q_IN_SP
export CHKEVO
export VERT_DISC ALARO_VERSION NAMELIST_BASE
export HM_APP ME_APPS

export PERTATMO PERTSURF SLAFLAG SLAFK SLAFDIFF SPPT SPP TEND_DIAG
export MODIFY_LAKES
export ENSMSEL ENSBDMBR ENSINIPERT ENSCTL FESTAT
export EPERT_MODE
export PERTDIA_BDINT MULTITASK
export ENS_BD_CLUSTER REARCHIVE_EPS_EC_OPER USE_REARCHIVE_EPS_EC_OPER ECFS_EPS_EC_BD_PATH
export SCALE_PERT EREF
export XZ0SN XZ0HSN XCGMAX CV_LOWVEG CV_HIGHVEG XCSMAX XALLEN_TERM XGRASS_H_DNM
export XCD_COEFF1 XCD_COEFF2 XCH_COEFF1
export H_TREE_FILE
export CAERO
export AI_ACUUMULATION_CYCLES AI_ACCUMULATION_HOURS
# Define your testbed list here
# The definition of the different configurations can be found in scr/Harmonie_testbed.pl
export TESTBED_LIST="AROME_3DVAR AROME_1D AROME AROME_MUSC \
                     AROME_3DENVAR \
                     AROME_3DVAR_MARSOBS \
                     AROME_3DVAR_ALLOBS \
                     AROME_BD_ARO AROME_BD_ARO_IO_SERV \
                     HarmonEPS HarmonEPS_IFSENS \
                     AROME_EPS_COMP \
                     AROME_JB \
                     AROME_CLIMSIM"

# Let the testbed continue when a child fails
export CONT_ON_FAILURE=0

