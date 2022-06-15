#!bin/bash

#------------------------------------------------------------------------
#
#  Project       : Lossless Compression Ratio Benchmark
#
#  File          : process_img_lib.sh
#
#  Dependencies  : compress_img_dir.sh
#
#  Model Type:   : Bash script
#
#  Description   : Execute compression benchmark script for all subdirectories in img_lib directory
#
#  Designer      : dbozikas
#
#  Creation Date : 13-May-2022
#
#  Last Update   : 13-May-2022
#
#  File Version  : 1.00
#
#  File History  :
#       1.00 - 13-May-2022 - Created
#
#------------------------------------------------------------------------

# Prints usage message
#
usage() { 
   echo ;
   echo "   Usage: bash $0 [-h] [-c]"
   echo ;
   echo "   Options:"
   echo "      -h     Prints this message."
   echo "      -c     Clear log and image directories produced by all associated scripts."
   echo ;
   exit 1;
}

# Clear generate output image/log directories
#
clear() {
   rm img_lib.log
   bash compress_img_dir.sh -c
   echo "Directories Cleared!"
   exit 1;
}

# Parse input arguments
#
while getopts hcad: opt 
do
   case "${opt}" in
      h) usage
         ;;
      c) clear
         ;;
      *) usage
         ;;
   esac
done
shift $((OPTIND -1))

# Loop for all subdirectories in image library
#
echo "   |----------------------------------------------------------------------|" > img_lib.log
echo "   |--  BATCH CONVERTING IMAGES BETWEEN FORMATS AND REPORTING FINAL SIZE--|" >> img_lib.log
echo "   |----------------------------------------------------------------------|" >> img_lib.log
echo "" >> img_lib.log
for the_dir in ../img_lib/*/; do
   echo " -- Procesing directory ${the_dir}" >> img_lib.log 2>&1
   echo "" >> img_lib.log
   bash compress_img_dir.sh -d ${the_dir} >> img_lib.log 2>&1
   echo "" >> img_lib.log
done
