# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Assembly::Image do
  let(:assembly_image) { described_class.new(input_path) }
  let(:input_path) { TEST_TIF_INPUT_FILE }

  before { cleanup }

  describe '#jp2_filename' do
    it 'indicates the default jp2 filename' do
      expect(assembly_image.jp2_filename).to eq input_path.gsub('.tif', '.jp2')
    end

    context 'with a file with no extension' do
      let(:input_path) { '/path/to/a/file_with_no_extension' }

      it 'indicates the default jp2 filename' do
        expect(assembly_image.jp2_filename).to eq '/path/to/a/file_with_no_extension.jp2'
      end
    end
  end
end
