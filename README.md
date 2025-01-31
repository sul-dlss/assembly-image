[![CircleCI](https://circleci.com/gh/sul-dlss/assembly-image/tree/main.svg?style=svg)](https://circleci.com/gh/sul-dlss/assembly-image/tree/main)
[![Test Coverage](https://codecov.io/github/sul-dlss/assembly-image/graph/badge.svg?token=3tCIFjd8Xn)](https://codecov.io/github/sul-dlss/assembly-image)
[![Gem Version](https://badge.fury.io/rb/assembly-image.svg)](https://badge.fury.io/rb/assembly-image)

# Assembly Image Gem

## Overview
This gem contains classes used by the Stanford University Digital Library to create JP2 image derivatives.

Requires image processing software - see [prerequisites section](#prerequisites) below.

## Notes

1. The gem assumes that the user context in which it is executed has write access to the 'tmp' folder.
This is to create the temporary tiffs used;  we need temporary tiffs to reliably compress the image using KDUcompress, which doesn’t support arbitrary image types
2. If any errors occur during JP2 generation for any reason, a runtime exception will be thrown with a description of the error.
3. If an image is passed in with a color profile that cannot be determined, an exception will be thrown. This can commonly occur in basic test TIFs that are black/white and have no profile, so beware during testing.

## Usage

To use the JP2 creation method, you first instantiate the image object with an input image and then operate on it.

```ruby
require 'assembly-image'
input_image = Assembly::Image.new('/full/path/to/file.tif')
output = input_image.create_jp2(output: '/full/path/to/output.jp2') # generate a new JP2 in the specified location
```

## Running tests

```bash
bundle exec rspec
```

## Prerequisites

1. Kakadu Proprietary Software Binaries - for JP2 generation
1. Libvips
1. Exiftool - upstream dependency of assembly-objectfile (used by specs to check mimetype of produced jp2, and because there is no libvips package available for circleci that speaks jp2)

### Kakadu

Download and install demonstration binaries from Kakadu:
http://kakadusoftware.com/downloads/

### Libvips
Note: libvips may require a significant amount of space for temporary files. The location for this can be controlled by the TMPDIR environment variable.

#### Mac

```bash
brew install libvips
```

### Exiftool

#### Linux
Download latest version from: http://www.sno.phy.queensu.ca/~phil/exiftool

```bash
tar -xf Image-ExifTool-#.##.tar.gz
cd Image-ExifTool-#.##
perl Makefile.PL
make test
sudo make install
```

#### Mac
```bash
brew install exiftool
```
