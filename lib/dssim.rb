
require "dssim/version"
require "securerandom"
require "fileutils"

module Dssim
  def self.optimize(path, dssim_path: "dssim", qualities: [50, 55, 60, 65, 70, 75, 80, 85, 90, 95], jpegoptim_options: "--strip-all", max: 0.0005)
    begin
      png_path = "/tmp/#{SecureRandom.hex}.png"

      system("convert", path, "-format", "png", png_path) || raise("convert error")

      qualities.each do |quality|
        random = SecureRandom.hex

        destination_jpg = "/tmp/#{random}.jpg"
        destination_png = "/tmp/#{random}.png"

        begin
          FileUtils.cp(path, destination_jpg)

          system("jpegoptim #{jpegoptim_options} -m #{quality} #{destination_jpg} &> /dev/null") || raise("jpegoptim error")
          system("convert #{destination_jpg} -format png #{destination_png} &> /dev/null") || raise("convert error")

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
