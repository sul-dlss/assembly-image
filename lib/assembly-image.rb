# frozen_string_literal: true

module Assembly
  # the path to the gem, used to access profiles stored with the gem
  PATH_TO_IMAGE_GEM = File.expand_path(File.dirname(__FILE__) + '/..')
end

require 'assembly-image/image'
require 'assembly-image/images'
