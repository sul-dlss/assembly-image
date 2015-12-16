# Assembly Image Gem

## Overview
This gem contains classes used by the Stanford University Digital Library to
perform image operations necessary for accessioning of content.

## Releases

* 0.0.1 initial release
* 0.0.2 small bug fixes
* 0.0.3 more bug fixes
* 0.0.4 update jp2 creation method to restrict allowed input types and improve color profile handling
* 0.0.5 updated documentation to yard format
* 0.0.6 updated dependency declarations
* 0.1.0 move color profile extraction to tmp folder instead of gem profiles folder
* 0.1.1 fix problem with digest require statement
* 0.1.2 move check for file existence to when an action occurs instead of object initialization; more error checking and messages on command execution
* 0.1.3 added a filesize attribute to the file object to allow easy access to filesize in bytes
* 0.1.4 added a new images class that allows you batch create jp2s from an input TIFF directory
* 0.2.0 added a new method to the image class to handle TIFF "sanity-check" -- can be used to ensure TIFFs are valid before JP2 generation
* 1.0.0 bump the version number up to an official production level release
* 1.1.0 remove common object file behaviors to a separate gem and use that gem as a dependency
* 1.1.1 minor changes to spec tests
* 1.1.2 remove the addition of 'format' node to file types in content metadata generation
* 1.1.3 changes to content metadata generation method: change md5 and sha1 computations so that they come from the assembly-objectfile gem,
    and set preserve/publish/shelve attributes using mimetype defaults
* 1.2.0 support tiffs that have embedded thumbnails when creating jp2
* 1.2.1 raise a SecurityError if the user attempts to overwrite an existing jp2 when creating it, to make it easier to catch in assembly
* 1.2.2 add height and width methods for an image that gets it from exif
* 1.2.4 prepare for release listing on DLSS release board
* 1.2.5 small change to use the jp2able method instead of the valid? method when creating jp2s
* 1.2.6 update how version number is set to make it easier to show
* 1.3.0 added a new method to the Assembly::Images class to allow for batch adding of color profiles to all tiffs in a directory; allow batch methods to run recursively
* 1.3.1 remove content metadata generation method and add to assembly-objectfile gem instead
* 1.3.3 update gemspec to force use of latest assembly-objectfile gem to allow gem to work in Ruby 1.9 projects
* 1.3.4 update to latest version of lyberteam gems
* 1.3.5 fix a problem that could occur if there were spaces in input filenames
* 1.3.6 add new attribute to give you default jp2 filename that will be used
* 1.3.7 add new attribute to give you default dpg jp2 filename
* 1.3.8 allow for batch processing of image extensions other than tif
* 1.3.9 create new methods for getting a color profile from exif and for force adding color profile to a single image
* 1.4.0 and 1.4.1 set the imagemagick tmp folder location environment variable when creating jp2
* 1.5.0 allow images with a color profile to have jp2 derivatives generated
* 1.5.1 relax nokogiri version requirement
* 1.6.1 bump version number of assembly-objectfile required to fix UTF-8 errors during JP2-create
* 1.6.2-1.6.3 small change to jp2 generation to try and fix bug with tiffs that have multiple input profile layers
* 1.6.4 added in some additional checks to try and create jp2s with mismatching exif data
* 1.6.5 fix problem with lack of extension in incoming tif causing a problem when creating jp2
* 1.6.7 release to github/rubygems

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
bundle exec rspec spec
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

1. Perl - you probably already have it
2. Kakadu Proprietary Software Binaries - for JP2 generation
3. ImageMagick 6.5.4 or higher
4. Exiftool

### Kakadu

Download and install demonstration binaries from Kakadu:
http://kakadusoftware.com/downloads/

### Imagemagick

#### RHEL 6

The version of ImageMagick included with RHEL 6 has all of the dependency libraries included:

```bash
yum install ImageMagick
```
#### RHEL 5

The version of ImageMagick included with RHEL 5 is too old and does not have all the proper binaries included/built:

```bash
yum install lcms lcms-devel libjpeg libjpeg-devel libpng libpng-devel
```
Required libraries from source:
* libtiff (version 3.9.4 or higher)

Build Imagemagick from source:
http://www.imagemagick.org/download/ImageMagick.tar.gz

#### Mac

```bash
brew install jasper libtiff
brew install imagemagick --use-tiff --use-jpeg2000
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

