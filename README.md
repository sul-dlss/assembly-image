[![CircleCI](https://circleci.com/gh/sul-dlss/assembly-image/tree/main.svg?style=svg)](https://circleci.com/gh/sul-dlss/assembly-image/tree/main)
[![Test Coverage](https://api.codeclimate.com/v1/badges/5bcd886bed28b1979ac0/test_coverage)](https://codeclimate.com/github/sul-dlss/assembly-image/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/5bcd886bed28b1979ac0/maintainability)](https://codeclimate.com/github/sul-dlss/assembly-image/maintainability)
[![Gem Version](https://badge.fury.io/rb/assembly-image.svg)](https://badge.fury.io/rb/assembly-image)

# Assembly Image Gem

## Overview
This gem contains classes used by the Stanford University Digital Library to
perform image operations necessary for accessioning of content.

Requires image processing software - see PreRequisites section below.

## Notes

1. The gem assumes that the user context in which it is executed has write access to the 'tmp' folder.
This is because color profiles can be extracted from images during the JP2
creation process, and these profiles need to be stored as local files, and it
is beneficial to cache them for later usage by images with the same color profile.
If you know there are color profiles which are commonly used, it is better to
capture them in the gem itself in the profile folder so they can be re-used
and do not need to be extracted.
1. If any errors occur during JP2 generation for any reason, a runtime exception will be thrown with a description of the error.
2. If an image is passed in with a color profile that cannot be determined by examining the exif header data, an exception will be thrown.

This can commonly occur in basic test TIFs that are black/white and have no profile, so beware during testing.

## Usage

To use the JP2 creation method, you first instantiate the image object with an input image and then operate on it.

```ruby
require 'assembly-image'
input = Assembly::Image.new('/full/path/to/file.tif')
puts input.exif   # show exif header information for the TIF
output = input.create_jp2(:output=>'/full/path/to/output.jp2') # generate a new JP2 in the specified location
puts output.exif  # show exif header information for the JP2
```

## Running tests

```bash
bundle exec rake
```

## Generate documentation
To generate documentation into the "doc" folder:

```bash
yard
```

To keep a local server running with up to date code documentation that you can view in your browser:

```bash
yard server --reload
```

## Prerequisites

1. Kakadu Proprietary Software Binaries - for JP2 generation
1. Libvips
1. Exiftool

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

#### RHEL
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
