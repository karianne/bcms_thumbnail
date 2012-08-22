require 'mini_magick'
require 'uri'
module ActionView
  module Helpers
    module_function


    def thumbnail_to_fill(attachment_obj,width,height, quality = "85", gravity = "Center")
      thumbnail_engine(attachment_obj, "fill_#{width}x#{height}_#{quality}") do |image|
        quality = quality.to_s

        image.quality quality
        cols, rows = image[:dimensions]
        image.combine_options do |cmd|
          if width != cols || height != rows
            scale = [width/cols.to_f, height/rows.to_f].max
            cols = (scale * (cols + 0.5)).round
            rows = (scale * (rows + 0.5)).round
            cmd.resize "#{cols}x#{rows}"
          end
          cmd.gravity gravity
          cmd.extent "#{width}x#{height}" if cols != width || rows != height
        end
      end
    end

    def thumbnail(attachment_obj,geometry,quality)
      thumbnail_to_fit(attachment_obj,geometry,quality)
    end

    def thumbnail_to_fit(attachment_obj,geometry = '100x100', quality = "85")
      quality = quality.to_s
      #thumbnail_engine(attachment_obj, geometry, false, quality)
      thumbnail_engine(attachment_obj, "fit_#{geometry}_#{quality}") do |image|
        image.quality quality
        image.resize geometry
      end
    end

    def thumbnail_square(attachment_obj,geometry = '100', quality = "85")
      quality = quality.to_s
      thumbnail_engine(attachment_obj, "square_#{geometry}_#{quality}") do |image|
        image.quality quality
          if image[:width] < image[:height]
            remove = ((image[:height] - image[:width])/2).round
            image.shave "0x#{remove}"
          elsif image[:width] > image[:height]
            remove = ((image[:width] - image[:height])/2).round
            image.shave "#{remove}x0"
          end
          image.resize "#{geometry}x#{geometry}"
      end
    end

    def thumbnail_engine(attachment_obj, name = nil)
      if ! attachment_obj.blank? && attachment_obj.respond_to?('attachment') && ['jpg','png','gif','bmp'].include?(attachment_obj.attachment.file_extension.downcase)
        thumbnail_location = "/bcms_thumbnail_cache/#{name}/#{attachment_obj.attachment.file_location.gsub(/[\\\/]/,'-')}.jpg"
        if ! File.exists?("#{RAILS_ROOT}/public#{thumbnail_location}")
          if ! File.exists?("#{RAILS_ROOT}/public/bcms_thumbnail_cache/#{name}")
            FileUtils.mkdir_p("#{RAILS_ROOT}/public/bcms_thumbnail_cache/#{name}")
            FileUtils.chmod 0755, "#{RAILS_ROOT}/public/bcms_thumbnail_cache/"
            FileUtils.chmod 0755, "#{RAILS_ROOT}/public/bcms_thumbnail_cache/#{name}"
          end
          image = MiniMagick::Image.open("#{RAILS_ROOT}/tmp/uploads/#{attachment_obj.attachment.file_location}")
          yield image
          image.write("#{RAILS_ROOT}/public#{thumbnail_location}")
          FileUtils.chmod 0644, "#{RAILS_ROOT}/public#{thumbnail_location}"
          URI::escape(thumbnail_location)
        else
          URI::escape(thumbnail_location)
        end
      else
        logger.warn("bcms_thumbnail: Either the attachment object doesn't accept attachments, you passed us a blank object, or the attachment type can't be thumbnailed.")
        '/image-not-found'
      end
    end

  end
end
