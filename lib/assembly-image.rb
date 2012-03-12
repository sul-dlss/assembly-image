# The gem is used by Stanford University Libraries
# to prepare and assemble collections to be
# accessioned.  It defines common image tools used
# by Stanford to prepare digital materials.
#
# Author::    SULAIR DLSS
# see README for prerequisites

module Assembly
  PATH_TO_GEM = File.expand_path(File.dirname(__FILE__) + '/..')
  ALLOWED_MIMETYPES=["image/jpeg","image/tiff"] # if input image is not one of these mime types, an error will be raised
end
