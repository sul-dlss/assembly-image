require 'nokogiri'
require 'digest/sha1'
require 'digest/md5'

module Assembly

  class ContentMetadata
    
      # Generates image content XML metadata for a repository object.
      # This method only produces content metadata for images
      # and does not depend on a specific folder structure.  Note that it is class level method.
      #
      # @param [String] druid the repository object's druid id as a string
      # @param [Array]  file_sets an array of arrays of files
      # @param [Hash] publish (optional) hash specifying content types to be published (true or false for each type), e.g. :publish=>\{'TIFF'=>'no','JPEG'=>'yes'}
      # @param [Hash] preserve (optional) hash specifying content types to be preserved (true or false for each type)
      # @param [Hash] shelve (optional) hash specifying content types to be shelved (true or false for each type)
      #
      # Example:
      #    Assembly::Image.create_content_metadata(
      #      'nx288wh8889',
      #      [ ['foo.tif', 'foo.jp2'], ['bar.tif', 'bar.jp2'] ],
      #      :preserve      => { 'TIFF'=>'yes', 'JPEG2000' => 'no'},
      #    )
      def self.create_content_metadata(druid, file_sets, params={})

        content_type_description = "image"

        publish       = params[:publish]     || "yes"
        preserve      = params[:preserve]    || "yes" 
        shelve        = params[:shelve]      || "yes"

        file_sets.flatten.each {|file| return false if !File.exists?(file)}

        sequence = 0

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.contentMetadata(:objectId => "#{druid}",:type => content_type_description) {
            file_sets.each do |file_set|
              sequence += 1
              resource_id = "#{druid}_#{sequence}"
              # start a new resource element
              xml.resource(:id => resource_id,:sequence => sequence,:type => content_type_description) {
                xml.label "Image #{sequence}"
                file_set.each do |filename|
                  id       = filename
                  exif     = MiniExiftool.new(filename)
                  mimetype = exif.mimetype
                  size     = exif.filesize.to_i
                  width    = exif.imagewidth
                  height   = exif.imageheight
                  md5      = Digest::MD5.new
                  sha1     = Digest::SHA1.new
                  File.open(filename, 'rb') do |io|
                    buffer = ''
                    while io.read(4096,buffer)
                      md5.update(buffer)
                      sha1.update(buffer)
                    end
                  end
                  cropped = "uncropped"
                  # add a new file element to the XML for this file
                  xml_file_params = {
                    :publish  => publish,
                    :id       => id,
                    :mimetype => mimetype,
                    :preserve => preserve,
                    :shelve   => shelve,
                    :size     => size
                  }
                  xml.file(xml_file_params) {
                    xml.imageData(:height => height, :width => width)
                    xml.attr cropped, :name => 'representation'
                    xml.checksum sha1, :type => 'sha1'
                    xml.checksum md5, :type => 'md5'
                  }
                end # file_set.each
              }
            end # file_sets.each
          }
        end

        return builder.to_xml

      end

  end
  
end
