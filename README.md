# <p align="center"> Lossless Image Compression Ratio Benchmark for JPEG-LS, PNG, QOI and JPEG2000

### Description
This repository is created as an accompaniment to the Lossless Compression Efficiency of JPEG-LS, PNG, QOI and JPEG2000 – A Comparative Study whitepaper published by the author and CAST. The repository contains the scripts used to produce the results highlighted in the whitepaper, as well as the corresponding detailed compression ratio measurements.

The following image sets were used for the measurements:
- The image included in the [QOI benchmark suite](https://qoiformat.org/benchmark/), with some few exceptions.
- The RGB 8-bit variants of the [New Test Images](https://imagecompression.info/test_images/).
  
The complete list of the images, as well as the detailed results are reported in ./doc/comp_ratio_rgb24_detailed.pdf.
  
### Dependencies
The scripts are written in bash and require the following applications:

- The [QOI](https://qoiformat.org/) reference encoder/decoder: https://github.com/phoboslab/qoi
- The STB libraries, as some are used by the QOI encoder/decoder: https://github.com/nothings/stb
- [FFMPEG](https://www.ffmpeg.org/) including the libopenjpeg codec: https://github.com/FFmpeg/FFmpeg

The scripts expect to find the qoi and stb implementation under the ./sw_lib/ directory.
Alternatively, they are also referenced as submodules and can be cloned along with this repository as:

`git clone https://github.com/dbozikas/lossless_comp_benchmark.git --recursive --shallow-submodules`
  
FFMPEG can be installed though its the official packages, or compiled from scratch, but it must be included to PATH.
The following configuration was used to compile FFMPEG, according to the [installation instructions](https://github.com/FFmpeg/FFmpeg/blob/master/INSTALL.md):

`./configure --enable-zlib --enable-libopenjpeg --enable-libjxl --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --incdir=/usr/include/x86_64-linux-gnu --arch=amd64 --enable-shared --enable-muxer=image2 --enable-demuxer=image2`
  
### Execution
To execute the compression script simply point it towards a directory contained either PNG or PPM images.

`bash compress_img_dir.sh -d <path/to/dir>`

The process_img_lib.sh script simply iterates all subdirectories under ./img_lib/ and executes compress_img_dir.sh for each one.
If more than one image directory is to be processed, simply add it under ./img_lib/ and run the script.
  
`bash process_img_lib.sh`

The scripts will create one directory for each image format containing the encoded images and logs from the encoding process.
The results for each image set will be stored in csv format under ./results/\<image set\>/results.csv.
