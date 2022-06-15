#!bin/bash

#------------------------------------------------------------------------
#
#  Project       : Lossless Compression Ratio Benchmark
#
#  File          : compress_img_dir.sh
#
#  Dependencies  : ffmpeg, qoiconv, stb_libs
#
#  Model Type:   : Bash script
#
#  Description   : Perform batch conversion to different image formats and report metrics
#
#  Designer      : dbozikas
#
#  Creation Date : 12-May-2022
#
#  Last Update   : 17-May-2022
#
#  File Version  : 1.01
#
#  File History  :
#       1.00 - 12-May-2022 - Created
#       1.01 - 17-May-2022 - Added filter to convert alpha to white for png->rgb24
#
#------------------------------------------------------------------------

 # -------------------------- #
#     GENERAL DECLARATIONS     #
 # ---------------------------#

# Image formats
#
allFormats=(rgb png jls qoi jp2)

# Codec information
#

# RGB Input
RGB_CODEC="rawvideo"
RGB_FMT="rgb24"
RGB_FMTR="bgr24"
ALPHA_FILTER="-filter_complex color=white,format=rgb24[c];[c][0]scale2ref[c][i];[c][i]overlay=format=auto:shortest=1,setsar=1"

# JPEG2000
JP2_CODEC="libopenjpeg"
JP2_ARGS=""

# JPEG-LS
JLS_CODEC="jpegls"
JLS_ARGS=""

# PNG
PNG_CODEC="png"
PNG_ARGS="-pred 5"

# Main directories
#
IMG_DIR=""
IMG_BASE=""
RES_DIR="../results"
SCRIPTS_DIR="."
QOI_ROOT="../sw_lib/qoi"
STB_ROOT="../sw_lib/stb"

# Output sample/log directories
#
declare -A allDir
declare -A allDLog
declare -A allDImg
declare -A allSize
for fmt in ${allFormats[@]}; do
   allDir+=([${fmt}]="../${fmt}_samples")
   allDLog+=([${fmt}]="../${fmt}_samples/log")
   allDImg+=([${fmt}]="../${fmt}_samples/img")
done

 # --------------- #
#     FUNCTIONS     #
 # ----------------#

# Prints usage message
#
usage() { 
   echo ;
   echo "   Usage: bash $0 [-h] [-c] [-a] [-d] <path>"
   echo ;
   echo "   Options:"
   echo "      -h     Prints this message."
   echo "      -c     Clear log and image directories."
   echo "      -a     Append results to existing files."
   echo "      -d     Specify directory to look for input samples."
   echo ;
   echo "      * By default the script will look for samples in ../img_samples"
   echo ;
   exit 1;
}

# Clear generate output image/log directories
#
clear() {
   for fmt in ${allFormats[@]}; do
      rm -r ${allDir[${fmt}]}
   done
   exit 1;
}

# Loop for all image formats and grab size of produced files
#
get_file_size() {
   for fmt in ${allFormats[@]}; do
      allSize+=([${fmt}]=$(ls -l ${allDImg[${fmt}]}/${IMG_BASE}/"${formattedname}".${fmt} | awk -F' ' '{print $5}'))
   done
}

get_file_size_ppm() {
   for fmt in ${allFormats[@]}; do
      allSize+=([${fmt}]=$(ls -l ${allDImg[${fmt}]}/${IMG_BASE}/"${formattedname}".${fmt} | awk -F' ' '{print $5}'))
   done
}

# Simple timestamp
#
timestamp() {
   cur_time=$(date +"%Y%m%d-%T")
}

# Create previous results sheet backup -- better safe
#
backup_results() {
   if test -f "${RES_DIR}/${IMG_BASE}/results.csv"; then
      timestamp
      cp ${RES_DIR}/${IMG_BASE}/results.csv ${RES_DIR}/${IMG_BASE}/results_${cur_time}.csv
   fi
}

# Create new results sheet and write header
create_new_sheet() {
   echo "IMAGE NAME,WIDTH (px),HEIGHT (px),RAW SIZE (B),PNG SIZE (B),JPEG-LS SIZE (B),QOI SIZE (B),JPEG2000 SIZE (B)" > ${RES_DIR}/${IMG_BASE}/results.csv
}

 # ------------------------ #
#     START OF EXECUTION     #
 # -------------------------#

# Parse input arguments
create_result_sheet="1"
while getopts hcad: opt 
do
   case "${opt}" in
      h) usage
         ;;
      c) clear
         ;;
      a) create_result_sheet="0"
         ;;
      d) IMG_DIR=${OPTARG}
         ;;
      *) usage
         ;;
   esac
done
shift $((OPTIND -1))

# Check if directory exists
if [ ! -d "${IMG_DIR}" ]; then
   echo "Directory '${IMG_DIR}' NOT found, exiting."
   exit 1
fi

# Get the basename of the input directory
IMG_BASE=$(basename -- "${IMG_DIR}")

# Backup previous results file
backup_results

# Create directories if they do not exist
mkdir -p ${RES_DIR}/${IMG_BASE}
for fmt in ${allFormats[@]}; do
   mkdir -p ${allDLog[${fmt}]}/${IMG_BASE}
   mkdir -p ${allDImg[${fmt}]}/${IMG_BASE}
done

# Create new result sheet if needed
if create_result_sheet="1"; then
   create_new_sheet
fi

# Rebuild QOI app just in case
gcc -I ${STB_ROOT}/ ${QOI_ROOT}/qoiconv.c -o ${QOI_ROOT}/qoiconv

# Process PNG input  images
if compgen -G "${IMG_DIR}/*.png" > /dev/null; then
   for inp_file in ${IMG_DIR}/*.png; do

      # Get filename without extension
      filepath=$(dirname -- "${inp_file}")
      filename=$(basename -- "${inp_file}")
      filename="${filename%.*}"
      otherdir=$(basename -- "${filepath}")

      # Print current file
      echo "Processing file "${inp_file}""

      # Get original image dimensions
      dimensions=$(file ${filepath}/"${filename}".png | awk -F', ' '{print $2}')
      width=$(echo ${dimensions} | awk -F' x ' '{print $1}')
      height=$(echo ${dimensions} | awk -F' x ' '{print $2}')

      # Remove %s from name for ffmpeg . . .
      formattedname=$(echo ${filename} | sed 's/\%//g')

      # Convert to raw RGB to have common point of reference
      ffmpeg -y -pattern_type none -f image2 -i ${filepath}/"${filename}".png -f image2 -codec ${RGB_CODEC} -pix_fmt ${RGB_FMT} ${ALPHA_FILTER} ${allDImg[rgb]}/${IMG_BASE}/"${formattedname}".rgb > ${allDLog["rgb"]}/${IMG_BASE}/"${formattedname}"_rgb.log 2>&1

      # Convert from raw to PNG
      ffmpeg -y -pattern_type none -f image2 -codec ${RGB_CODEC} -pix_fmt ${RGB_FMT} -s ${width}x${height} -i ${allDImg[rgb]}/${IMG_BASE}/"${formattedname}".rgb -f image2 -codec ${PNG_CODEC} ${PNG_ARGS} ${allDImg[png]}/${IMG_BASE}/"${formattedname}".png > ${allDLog[png]}/${IMG_BASE}/"${formattedname}"_png.log 2>&1

      # Convert from raw to JPEG-LS
      ffmpeg -y -pattern_type none -f image2 -codec ${RGB_CODEC} -pix_fmt ${RGB_FMT} -s ${width}x${height} -i ${allDImg[rgb]}/${IMG_BASE}/"${formattedname}".rgb -f image2 -codec ${JLS_CODEC} ${JLS_ARGS} ${allDImg[jls]}/${IMG_BASE}/"$formattedname".jls > ${allDLog[jls]}/${IMG_BASE}/"${formattedname}"_jls.log 2>&1

      # Convert from raw to JPEG2000
      ffmpeg -y -pattern_type none -f image2 -codec ${RGB_CODEC} -pix_fmt ${RGB_FMT} -s ${width}x${height} -i ${allDImg[rgb]}/${IMG_BASE}/"${formattedname}".rgb -f image2 -codec ${JP2_CODEC} ${JP2_ARGS} ${allDImg[jp2]}/${IMG_BASE}/"$formattedname".jp2 > ${allDLog[jp2]}/${IMG_BASE}/"${formattedname}"_jp2.log 2>&1

      # Convert from PNG to QOI
      ${QOI_ROOT}/qoiconv ${allDImg[png]}/${IMG_BASE}/"${formattedname}".png ${allDImg[qoi]}/${IMG_BASE}/"${formattedname}".qoi > ${allDLog[qoi]}/${IMG_BASE}/"${formattedname}"_qoi.log 2>&1

      # Get results from logs
      get_file_size

      # Append results to file
      echo "\""$filename".png\",$width,$height,${allSize[rgb]},${allSize[png]},${allSize[jls]},${allSize[qoi]},${allSize[jp2]}" >> ${RES_DIR}/${IMG_BASE}/results.csv
   done
fi

# Process PPM input images (lazy duplication of previous loop for different input)
if compgen -G "${IMG_DIR}/*.ppm" > /dev/null; then
   for inp_file in ${IMG_DIR}/*.ppm; do
      # Get filename without extension
      filepath=$(dirname -- "${inp_file}")
      filename=$(basename -- "${inp_file}")
      filename="${filename%.*}"
      otherdir=$(basename -- "${filepath}")

      # Print current file
      echo "Processing file "${inp_file}""

      # Get original image dimensions
      dimensions=$(file ${filepath}/"${filename}".ppm | awk -F', ' '{print $2}')
      dimensions=$(echo ${dimensions} | awk -F' = ' '{print $2}')
      width=$(echo ${dimensions} | awk -F' x ' '{print $1}')
      height=$(echo ${dimensions} | awk -F' x ' '{print $2}')

      # Remove %s from name for ffmpeg . . .
      formattedname=$(echo ${filename} | sed 's/\%//g')

      # Convert to raw RGB to have common point of reference
      ffmpeg -y -pattern_type none -f image2 -i ${filepath}/"${filename}".ppm -f image2 -codec ${RGB_CODEC} -pix_fmt ${RGB_FMT} ${ALPHA_FILTER} ${allDImg[rgb]}/${IMG_BASE}/"${formattedname}".rgb > ${allDLog["rgb"]}/${IMG_BASE}/"${formattedname}"_rgb.log 2>&1

      # Convert from raw to PNG
      ffmpeg -y -pattern_type none -f image2 -codec ${RGB_CODEC} -pix_fmt ${RGB_FMT} -s ${width}x${height} -i ${allDImg[rgb]}/${IMG_BASE}/"${formattedname}".rgb -f image2 -codec ${PNG_CODEC} ${PNG_ARGS} ${allDImg[png]}/${IMG_BASE}/"${formattedname}".png > ${allDLog[png]}/${IMG_BASE}/"${formattedname}"_png.log 2>&1

      # Convert from raw to JPEG-LS
      ffmpeg -y -pattern_type none -f image2 -codec ${RGB_CODEC} -pix_fmt ${RGB_FMT} -s ${width}x${height} -i ${allDImg[rgb]}/${IMG_BASE}/"${formattedname}".rgb -f image2 -codec ${JLS_CODEC} ${JLS_ARGS} ${allDImg[jls]}/${IMG_BASE}/"$formattedname".jls > ${allDLog[jls]}/${IMG_BASE}/"${formattedname}"_jls.log 2>&1

      # Convert from raw to JPEG2000
      ffmpeg -y -pattern_type none -f image2 -codec ${RGB_CODEC} -pix_fmt ${RGB_FMT} -s ${width}x${height} -i ${allDImg[rgb]}/${IMG_BASE}/"${formattedname}".rgb -f image2 -codec ${JP2_CODEC} ${JP2_ARGS} ${allDImg[jp2]}/${IMG_BASE}/"$formattedname".jp2 > ${allDLog[jp2]}/${IMG_BASE}/"${formattedname}"_jp2.log 2>&1

      # Convert from PNG to QOI
      ${QOI_ROOT}/qoiconv ${allDImg[png]}/${IMG_BASE}/"${formattedname}".png ${allDImg[qoi]}/${IMG_BASE}/"${formattedname}".qoi > ${allDLog[qoi]}/${IMG_BASE}/"${formattedname}"_qoi.log 2>&1

      # Get results from logs
      get_file_size_ppm

      # Append results to file
      echo "\""$filename".ppm\",$width,$height,${allSize[rgb]},${allSize[png]},${allSize[jls]},${allSize[qoi]},${allSize[jp2]}" >> ${RES_DIR}/${IMG_BASE}/results.csv
   done
fi