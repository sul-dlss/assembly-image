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

  describe '#multi_page?' do
    context 'with a single page TIFF' do
      before { generate_test_image(input_path) }

      it 'returns false' do
        expect(assembly_image.multi_page?).to be false
      end
    end

    context 'with a multi-page TIFF' do
      let(:input_path) { TEST_MULTIPAGE_TIF_FILE } # this image exists and is in our checked in codebase

      it 'returns true' do
        expect(assembly_image.multi_page?).to be true
      end
    end

    context 'with a non-TIFF image' do
      before { generate_test_image(input_path) }

      let(:input_path) { TEST_JPEG_INPUT_FILE }

      it 'returns false (JPEG cannot have multiple pages)' do
        expect(assembly_image.multi_page?).to be false
      end
    end

    context 'when Vips raises an error' do
      before { generate_test_image(input_path) }

      let(:input_path) { TEST_TIF_INPUT_FILE }

      it 'rescues the error and returns false' do
        allow(assembly_image.vips_image).to receive(:get).and_raise(Vips::Error, 'Test error')
        expect(assembly_image.multi_page?).to be false
      end
    end
  end

  describe '#extract_first_page' do
    let(:output_path) { File.join(TEST_OUTPUT_DIR, 'extracted.tif') }

    after { FileUtils.rm_f(output_path) }

    context 'with a single page TIFF' do
      let(:input_path) { TEST_TIF_INPUT_FILE }

      before { generate_test_image(input_path) }

      it 'extracts and saves the first page' do
        expect(assembly_image.multi_page?).to be false
        result = assembly_image.extract_first_page(output_path)
        expect(result).to be true
        expect(File.exist?(output_path)).to be true
        extracted = described_class.new(output_path)
        expect(extracted.width).to eq assembly_image.width
        expect(extracted.height).to eq assembly_image.height
        expect(extracted.multi_page?).to be false
      end
    end

    context 'with a multi-page TIFF' do
      let(:input_path) { TEST_MULTIPAGE_TIF_FILE } # this is a test multi-page image that exists and is in our checked in codebase

      it 'extracts only the first page' do
        expect(assembly_image.multi_page?).to be true
        result = assembly_image.extract_first_page(output_path)
        expect(result).to be true
        expect(File.exist?(output_path)).to be true
        extracted = described_class.new(output_path)
        expect(extracted.width).to eq assembly_image.width
        expect(extracted.height).to eq assembly_image.height
        expect(extracted.multi_page?).to be false
      end
    end

    context 'with different image formats' do
      before { generate_test_image(input_path) }

      let(:input_path) { TEST_JPEG_INPUT_FILE }

      it 'raises an error' do
        expect { assembly_image.extract_first_page(output_path) }.to raise_error(RuntimeError, 'Cannot extract first page from mimetype image/jpeg')
      end
    end
  end
end
