# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/ExampleLength
RSpec.describe Assembly::Image::Jp2Creator do
  let(:jp2creator) { described_class.new(assembly_image, output: jp2_output_file) }
  let(:assembly_image) { Assembly::Image.new(input_path) }
  let(:jp2_output_file) { File.join(TEST_OUTPUT_DIR, 'test.jp2') }

  describe '.create' do
    subject(:result) { jp2creator.create }

    let(:input_path) { TEST_TIF_INPUT_FILE }

    before { cleanup }

    context 'when input path is blank' do
      let(:input_path) { '' }

      it 'raises error' do
        expect { assembly_image.create_jp2 }.to raise_error(RuntimeError, 'input file  does not exist or is a directory')
      end
    end

    context 'when tmp folder does not exist' do
      before do
        generate_test_image(input_path)
      end

      it 'raises error' do
        bogus_folder = '/nonexisting'
        expect(File).not_to exist bogus_folder
        expect { assembly_image.create_jp2(tmp_folder: bogus_folder) }.to raise_error(RuntimeError, 'tmp_folder /nonexisting does not exist')
      end
    end

    context 'when no output file is specified' do
      let(:jp2creator) { described_class.new(assembly_image) }
      let(:jp2_output_file) { File.join(TEST_INPUT_DIR, File.basename(input_path).gsub('.tif', '.jp2')) }

      before do
        generate_test_image(input_path)
      end

      it 'creates a jp2 of the same filename and in the same location as the input' do
        expect(File).to exist input_path # test image was generated
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.srgb?).to be true
        expect(assembly_image.has_profile?).to be false

        expect(result).to be_a Assembly::Image
        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'
        # check srgb on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.srgb?).to be true
          expect(tmp_tiff_image.has_profile?).to be false
        end
      end
    end

    context 'when the output file exists and no overwriting' do
      before do
        generate_test_image(input_path)
        FileUtils.touch(jp2_output_file) # just need a file with this name, don't care what
      end

      it 'raises error' do
        expect(File).to exist input_path # test image was generated
        expect { assembly_image.create_jp2(output: jp2_output_file) }.to raise_error(SecurityError, %r{spec/test_data/output/test.jp2 exists, cannot overwrite})
      end
    end

    context 'when the output file exists and overwriting allowed' do
      before do
        generate_test_image(input_path)
        FileUtils.touch(jp2_output_file) # just need a file with this name, don't care what
      end

      it 'recreates jp2' do
        expect(File).to exist input_path # test image was generated
        expect(File).to exist jp2_output_file
        expect(assembly_image.srgb?).to be true
        expect(assembly_image.has_profile?).to be false

        result = assembly_image.create_jp2(output: jp2_output_file, overwrite: true)
        expect(result).to be_a Assembly::Image
        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'
        # check srgb on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.srgb?).to be true
          expect(tmp_tiff_image.has_profile?).to be false
        end
      end
    end

    context 'when the input file is a jp2' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'for_jp2.tif') }

      before do
        generate_test_image(input_path)
      end

      it 'raises error' do
        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'

        expect { described_class.new(Assembly::Image.new(jp2_output_file)).create }.to raise_error(RuntimeError, 'input file is not a valid image, or is the wrong mimetype')
      end
    end

    context 'when given a tiff' do
      before do
        generate_test_image(input_path)
      end

      it 'gets the correct image, creates the temporary tiff' do
        expect(File).to exist input_path # test image was generated
        expect(File).not_to exist jp2_output_file

        expect(result).to be_a Assembly::Image
        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'
        # check height and width on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.height).to eq 36
          expect(tmp_tiff_image.width).to eq 43
        end
      end
    end

    context 'when given an LZW compressed RGB tif' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'lzw.tif') }

      before do
        generate_test_image(input_path, compress: 'lzw')
      end

      it 'creates the jp2' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file

        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'
        # check height and width on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.height).to eq 36
          expect(tmp_tiff_image.width).to eq 43
        end
      end
    end

    context 'when given a cmyk tif' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'test-cmyk.tif') }

      before do
        generate_test_image(input_path, color: 'cmyk', cg_type: 'cmyk', profile: 'cmyk', bands: 4)
      end

      it 'creates an srgb jp2' do
        expect(File).to exist input_path
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.srgb?).to be false
        expect(assembly_image.vips_image.interpretation).to eq :cmyk
        expect(assembly_image.has_profile?).to be true

        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'

        # NOTE: we verify the CMYK has been converted to an SRGB JP2 correctly by using ruby-vips;
        #   we have to verify this on the *temporary tiff because lipvips pkg available for circleci does not speak JP2
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.srgb?).to be true
          expect(tmp_tiff_image.has_profile?).to be true
        end
      end
    end

    context 'when the input file is a JPEG' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'test.jpg') }

      before do
        generate_test_image(input_path)
      end

      it 'creates jp2 when given a JPEG' do
        expect(File).to exist input_path # test image was generated
        expect(File).not_to exist jp2_output_file

        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'
        # check height and width on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.height).to eq 36
          expect(tmp_tiff_image.width).to eq 43
        end
      end
    end

    context 'when the source image has no profile' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'no_profile.tif') }

      before do
        generate_test_image(input_path)
      end

      it 'creates color jp2 without ICC profile' do
        expect(File).to exist input_path # test image was generated
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.srgb?).to be true
        expect(assembly_image.has_profile?).to be false

        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'

        # check srgb on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.srgb?).to be true
          expect(tmp_tiff_image.has_profile?).to be false
        end
      end
    end

    context 'when given a bitonal tif with bitonal image data' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'bitonal.tif') }

      before do
        # depth of 1 says 1 bit per pixel.
        generate_test_image(input_path, color: 'bin', bands: 1, depth: 1)
      end

      it 'creates bitonal jp2 without ICC profile' do
        expect(File).to exist input_path # test image was generated
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.srgb?).to be false
        expect(assembly_image.vips_image.interpretation).to eq :'b-w'
        expect(assembly_image.has_profile?).to be false

        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'

        # check srgb on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.srgb?).to be false
          expect(tmp_tiff_image.has_profile?).to be false
          vips_for_tmp_tiff = tmp_tiff_image.vips_image
          expect(vips_for_tmp_tiff.bands).to eq 1
          expect(vips_for_tmp_tiff.interpretation).to eq :'b-w'
        end
      end
    end

    context 'when given a color tif but bitonal image data' do
      # NOTE: this spec was created due to ImageMagick weirdness processing this wrinkle
      let(:input_path) { File.join(TEST_INPUT_DIR, 'color.tif') }

      before do
        # from Tony Calavano:
        #  color: bin should threshold the pixel data to 0 or 255, bands: 3 forces it to be rgb.
        #  It should then create a 8 bits per pixel image
        generate_test_image(input_path, color: 'bin', bands: 3)
      end

      it 'creates color jp2 without ICC profile' do
        expect(File).to exist input_path # test image was generated
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.srgb?).to be true
        expect(assembly_image.has_profile?).to be false

        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'

        # check srgb on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.srgb?).to be true
          expect(tmp_tiff_image.has_profile?).to be false
          expect(tmp_tiff_image.vips_image.bands).to eq 3
        end
      end
    end

    context 'when given a grayscale tif but with bitonal image data' do
      # NOTE: this spec was created due to ImageMagick weirdness processing this wrinkle
      let(:input_path) { File.join(TEST_INPUT_DIR, 'gray.tif') }

      before do
        # from Tony Calavano:  color: grey, bands: 1 would be a normal grayscale image with 8 bits per pixel
        generate_test_image(input_path, color: 'bin', bands: 1)
      end

      it 'creates grayscale jp2 without ICC profile' do
        expect(File).to exist input_path # test image was generated
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.srgb?).to be false
        expect(assembly_image.has_profile?).to be false
        expect(assembly_image.vips_image.interpretation).to eq :'b-w'

        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'

        # check srgb on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.srgb?).to be false
          expect(tmp_tiff_image.has_profile?).to be false
          vips_for_tmp_tiff = tmp_tiff_image.vips_image
          expect(vips_for_tmp_tiff.bands).to eq 1
          expect(vips_for_tmp_tiff.interpretation).to eq :'b-w'
        end
      end
    end

    context 'when given a color tif but with grayscale image data (3 channels and 8 bits per pixel)' do
      let(:input_path) { File.join(TEST_INPUT_DIR, 'color_gray.tif') }

      before do
        # this is bands: 3 with 8 bits per pixel
        generate_test_image(input_path, color: 'grey')
      end

      it 'creates color jp2 without ICC profile' do
        expect(File).to exist input_path # test image was generated
        expect(File).not_to exist jp2_output_file
        expect(assembly_image.srgb?).to be true
        expect(assembly_image.has_profile?).to be false

        expect(result.path).to eq jp2_output_file
        expect(result.mimetype).to eq 'image/jp2'

        # check srgb on temporary tiff (due to CI libvips not speaking jp2)
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          tmp_tiff_image = Assembly::Image.new(tmp_tiff_path)
          expect(tmp_tiff_image.srgb?).to be true
          expect(tmp_tiff_image.has_profile?).to be false
          vips_for_tmp_tiff = tmp_tiff_image.vips_image
          expect(vips_for_tmp_tiff.bands).to eq 3
        end
      end
    end
  end

  describe '#make_tmp_tiff' do
    let(:input_path) { 'spec/test_data/color_rgb_srgb_rot90cw.tif' }
    let(:plum) { [94.0, 58.0, 101.0] }

    context 'when given a tiff with a rotation hint' do
      it 'rotates it' do
        expect(Vips::Image.new_from_file(input_path).getpoint(3, 3)).not_to eq plum
        Dir.mktmpdir('assembly-image-test') do |tmp_tiff_dir|
          tmp_tiff_path = File.join(tmp_tiff_dir, 'temp.tif')
          jp2creator.send(:make_tmp_tiff, tmp_tiff_path)
          expect(Vips::Image.new_from_file(tmp_tiff_path).getpoint(3, 3)).to eq plum
        end
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength
