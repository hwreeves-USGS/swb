GRID  60  60  2165054       255067        2169887       259900      80.55
GRID_LENGTH_UNITS FEET
GROWING_SEASON 133 268 TRUE
ANSI_COLORS FALSE
SUPPRESS_SCREEN_OUTPUT
RLE_MULTIPLIER 10000
PRECIPITATION SINGLE_STATION
TEMPERATURE SINGLE_STATION
OUTPUT_GRID_SUFFIX asc
INITIAL_ABSTRACTION_METHOD HAWKINS
INITIAL_FROZEN_GROUND_INDEX CONSTANT 100.0
UPPER_LIMIT_CFGI 83.
LOWER_LIMIT_CFGI 55.
FLOW_DIRECTION ARC_GRID input\flowdirmedium_esri.asc
SOIL_GROUP ARC_GRID input\hsgMedium.asc
LAND_USE ARC_GRID input\lulcMedium.asc
LAND_USE_LOOKUP_TABLE std_input\LU_LOOKUP.txt
WATER_CAPACITY ARC_GRID input\awcMedium.asc
SM T-M std_input\soil-moisture-retention-extended.grd
INITIAL_SOIL_MOISTURE CONSTANT 100
INITIAL_SNOW_COVER CONSTANT 0
RUNOFF C-N DOWNHILL
ET T-M 43
#*******************************************************************
# PLOTTING CUSTOMIZATION
#
# This version of the SWB model allows very limited assignment of
# DISLIN plotting parameters for the generation of images.
# See http://www.mps.mpg.de/dislin/ for more information about this
# package.
#
# If no customizations are specified, default values will be used.
#
DISLIN_PARAMETERS RECHARGE
SET_Z_AXIS_RANGE DAILY 0 1.5 0.1
SET_Z_AXIS_RANGE MONTHLY 0 7 1.0
SET_Z_AXIS_RANGE ANNUAL 0 20 2.
Z_AXIS_TITLE RECHARGE, IN INCHES
#
DISLIN_PARAMETERS SOIL_MOISTURE
SET_Z_AXIS_RANGE DAILY 0 10.0 1.0
SET_Z_AXIS_RANGE MONTHLY 0 10.0 1.0
SET_Z_AXIS_RANGE ANNUAL 0 10.0 1.
Z_AXIS_TITLE ROOT ZONE SOIL MOISTURE, IN INCHES
SET_COLOR_TABLE RRAIN
#
DISLIN_PARAMETERS ACT_ET
SET_Z_AXIS_RANGE DAILY 0 0.8 0.05
SET_Z_AXIS_RANGE MONTHLY 0 10. 0.5
SET_Z_AXIS_RANGE ANNUAL 0 40. 5.0
#SET_DEVICE PDF
#SET_FONT Helvetica-Bold
Z_AXIS_TITLE ACTUAL ET, IN INCHES
#
DISLIN_PARAMETERS REFERENCE_ET
SET_Z_AXIS_RANGE DAILY 0 0.8 0.05
SET_Z_AXIS_RANGE MONTHLY 0 10. 0.5
SET_Z_AXIS_RANGE ANNUAL 0 45. 5.
#SET_DEVICE WMF
#SET_FONT Courier New Italic
Z_AXIS_TITLE REFERENCE ET, IN INCHES
#
DISLIN_PARAMETERS RUNOFF_OUTSIDE
SET_Z_AXIS_RANGE DAILY 0 5. 0.5
SET_Z_AXIS_RANGE MONTHLY 0 12. 0.5
SET_Z_AXIS_RANGE ANNUAL 0 20. 2.
Z_AXIS_TITLE RUNOFF OUT OF GRID, IN INCHES
#
DISLIN_PARAMETERS REJECTED_RECHARGE
SET_Z_AXIS_RANGE DAILY 0 5. 0.5
SET_Z_AXIS_RANGE MONTHLY 0 12. 0.5
SET_Z_AXIS_RANGE ANNUAL 0 25. 5.
Z_AXIS_TITLE RUNOFF OUT OF GRID, IN INCHES

#DISLIN_PARAMETERS SNOWCOVER
#SET_Z_AXIS_RANGE DAILY 0 12. 0.5
#Z_AXIS_TITLE SNOW COVER, IN INCHES (WATER EQUIVALENT)
#
DISLIN_PARAMETERS SM_APWL
SET_Z_AXIS_RANGE DAILY -20. 0. 2.0
Z_AXIS_TITLE ACCUMULATED POTENTIAL WATER LOSS, IN INCHES
SET_COLOR_TABLE RRAIN
#*******************************************************************
# OUTPUT OPTIONS
#
# The SWB code can generate image and ARCGIS/Surfer output at the
# daily, monthly, or annual timescale. This section allows the user to
# specify exactly what output should be generated for each of 24
# internal variables at each of the three timescales.
#
# Format for specifying output options is:
# "OUTPUT_OPTIONS variable_name daily_opt monthly_opt annual_opt"
#
# where the possible values for each option are:
# NONE, GRAPH, GRID, or BOTH
#
OUTPUT_OPTIONS RECHARGE NONE NONE PLOT
OUTPUT_OPTIONS SM_APWL NONE NONE NONE
OUTPUT_OPTIONS SOIL_MOISTURE PLOT NONE NONE NONE
#OUTPUT_OPTIONS SNOWCOVER PLOT NONE NONE
OUTPUT_OPTIONS INTERCEPTION NONE NONE PLOT
OUTPUT_OPTIONS RUNOFF_OUTSIDE NONE NONE PLOT
OUTPUT_OPTIONS ACT_ET NONE NONE NONE
OUTPUT_OPTIONS REFERENCE_ET NONE NONE PLOT
OUTPUT_OPTIONS REJECTED_RECHARGE NONE NONE PLOT
OUTPUT_FORMAT ARC_GRID
SOLVE climate\Coshocton_Climate_1999.txt
SOLVE climate\Coshocton_Climate_2000.txt
SOLVE climate\Coshocton_Climate_2001.txt
SOLVE climate\Coshocton_Climate_2002.txt
SOLVE climate\Coshocton_Climate_2003.txt
EOJ
