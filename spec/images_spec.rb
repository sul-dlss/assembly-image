# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Assembly::Images do
  before { cleanup }

  describe '#batch_generate_jp2' do
    it 'does not run if no input folder is passed in' do
      expect{ described_class.batch_generate_jp2('') }.to raise_error(RuntimeError)
    end

    it 'does not run if a non-existent input folder is passed in' do
      expect{ described_class.batch_generate_jp2('/junk/path') }.to raise_error(RuntimeError)
    end

    it 'runs and batch produces jp2s from input tiffs' do
      ['test1', 'test2', 'test3'].each { |image| generate_test_image(File.join(TEST_INPUT_DIR, "#{image}.tif"), profile: 'AdobeRGB1998') }
      described_class.batch_generate_jp2(TEST_INPUT_DIR, output: TEST_OUTPUT_DIR)
      expect(File.directory?(TEST_OUTPUT_DIR)).to be true
      ['test1', 'test2', 'test3'].each { |image| expect(File.join(TEST_OUTPUT_DIR, "#{image}.jp2")).to be_a_jp2 }
    end
  end

  describe '#batch_add_exif_profile_descr' do
    it 'runs and batch adds color profile descriptions to input tiffs that had no color profile descriptions' do
      ['test1', 'test2', 'test3'].each { |image| generate_test_image(File.join(TEST_INPUT_DIR, "#{image}.tif")) }
      ['test1', 'test2', 'test3'].each { |image| expect(Assembly::Image.new(File.join(TEST_INPUT_DIR, "#{image}.tif")).exif.profiledescription).to be_nil }
      described_class.batch_add_exif_profile_descr(TEST_INPUT_DIR, 'Adobe RGB 1998')
      ['test1', 'test2', 'test3'].each { |image| expect(Assembly::Image.new(File.join(TEST_INPUT_DIR, "#{image}.tif")).exif.profiledescription).to eq 'Adobe RGB (1998)' }
    end

    it 'runs and batch adds color profile descriptions to input tiffs, forcing over existing color profile descriptions' do
      ['test1', 'test2', 'test3'].each { |image| generate_test_image(File.join(TEST_INPUT_DIR, "#{image}.tif"), profile: 'sRGBIEC6196621') }
      ['test1', 'test2', 'test3'].each { |image| expect(Assembly::Image.new(File.join(TEST_INPUT_DIR, "#{image}.tif")).exif.profiledescription).to eq 'sRGB IEC61966-2.1' }
      described_class.batch_add_exif_profile_descr(TEST_INPUT_DIR, 'Adobe RGB 1998', force: true) # force overwrite
      ['test1', 'test2', 'test3'].each { |image| expect(Assembly::Image.new(File.join(TEST_INPUT_DIR, "#{image}.tif")).exif.profiledescription).to eq 'Adobe RGB (1998)' }
    end

    it 'runs and batch adds color profile descriptions to input tiffs, not overwriting existing color profile descriptions' do
      ['test1', 'test2', 'test3'].each { |image| generate_test_image(File.join(TEST_INPUT_DIR, "#{image}.tif"), profile: 'sRGBIEC6196621') }
      ['test1', 'test2', 'test3'].each { |image| expect(Assembly::Image.new(File.join(TEST_INPUT_DIR, "#{image}.tif")).exif.profiledescription).to eq 'sRGB IEC61966-2.1' }
      described_class.batch_add_exif_profile_descr(TEST_INPUT_DIR, 'Adobe RGB 1998') # do not force overwrite
      ['test1', 'test2', 'test3'].each { |image| expect(Assembly::Image.new(File.join(TEST_INPUT_DIR, "#{image}.tif")).exif.profiledescription).to eq 'sRGB IEC61966-2.1' }
    end
  end
end
