
require "dssim/version"
require "securerandom"
require "shellwords"
require "fileutils"

module Dssim
  def self.optimize(path, dssim_path: "dssim", qualities: [50, 55, 60, 65, 70, 75, 80, 85, 90, 95], jpegoptim_options: ["--strip-all"], max: 0.0005)
    begin
      png_path = "/tmp/#{SecureRandom.hex}.png"

      %x{ convert #{Shellwords.shellescape(path)} -format png #{png_path} }

      raise("convert error") unless $?.success?

      qualities.each do |quality|
        random = SecureRandom.hex

        destination_jpg = "/tmp/#{random}.jpg"
        destination_png = "/tmp/#{random}.png"

        begin
          FileUtils.cp(path, destination_jpg)

          %x{ jpegoptim #{jpegoptim_options.map { |option| Shellwords.shellescape(option) }.join(" ")} -m#{quality} #{destination_jpg} }

          raise("jpegoptim error") unless $?.success?

          %x{ convert #{destination_jpg} -format png #{destination_png} }

          raise("convert error") unless $?.success?

          res = %x{ #{dssim_path} #{png_path} #{destination_png} }

          raise("dssim error") unless $?.success?

          if res.to_f <= max
            open(path, "wb") { |stream| stream.write File.binread(destination_jpg) }

            return quality
          end
        ensure
          FileUtils.rm_f destination_jpg
          FileUtils.rm_f destination_png
        end
      end
    ensure
      FileUtils.rm_f png_path
    end
  end
end
