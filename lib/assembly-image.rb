# frozen_string_literal: true

module Assembly
  # the path to the gem, used to access profiles stored with the gem
  PATH_TO_IMAGE_GEM = File.expand_path("#{File.dirname(__FILE__)}/..")
  PATH_TO_PROFILES = File.join(Assembly::PATH_TO_IMAGE_GEM, 'profiles')
  SRGB_ICC = File.join(PATH_TO_PROFILES, 'sRGBIEC6196621.icc')
  CMYK_ICC = File.join(PATH_TO_PROFILES, 'cmyk.icc')
end

require 'assembly-image/image'
