require "stringio"
require "tempfile"

module ImageUploadTestHelper
  def png_bytes
    @png_bytes ||= Vips::Image.black(1, 1).write_to_buffer(".png").freeze
  end

  def attach_png(attachment, filename: "image.png", content_type: "image/png", bytes: png_bytes)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(bytes),
      filename: filename,
      content_type: content_type,
      identify: false
    )
    attachment.attach(blob)
  end

  def uploaded_png(filename: "image.png", content_type: "image/png", bytes: png_bytes)
    file = Tempfile.new([ "upload", File.extname(filename) ])
    file.binmode
    file.write(bytes)
    file.flush
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end
end
