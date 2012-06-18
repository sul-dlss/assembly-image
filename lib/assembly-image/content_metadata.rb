require 'nokogiri'

module Assembly

  # This class generates content metadata for image files
  class ContentMetadata
    
      # Generates image content XML metadata for a repository object.
      # This method only produces content metadata for images
      # and does not depend on a specific folder structure.  Note that it is class level method.
      #
      # @param [String] druid the repository object's druid id as a string
      # @param [Array]  file_sets an array of arrays of files
      # @param [Hash] params (optional) hash specifying publish, preserve and shelved by mimetype (true or false for each type), e.g. :publish=>\{'TIFF'=>'no','JPEG'=>'yes'}
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
                xml.label "Item #{sequence}"
                file_set.each do |filename|
                  obj=Assembly::ObjectFile.new(filename)
                  id       = filename
                  mimetype = obj.mimetype
                  size     = obj.filesize
                  width    = obj.exif.imagewidth
                  height   = obj.exif.imageheight                
                  file_attributes=Assembly::FILE_ATTRIBUTES[mimetype] || Assembly::FILE_ATTRIBUTES['default']
                  # add a new file element to the XML for this file
                  xml_file_params = {
                    :id       => id,
                    :mimetype => mimetype,
                    :preserve => file_attributes[:preserve],
                    :publish  => file_attributes[:publish],
                    :shelve   => file_attributes[:shelve],
                    :size     => size
                  }
                  xml.file(xml_file_params) {
                    xml.imageData(:height => height, :width => width)
                    xml.checksum obj.sha1, :type => 'sha1'
                    xml.checksum obj.md5, :type => 'md5'
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
