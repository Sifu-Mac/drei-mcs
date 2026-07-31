require "vips"

module MediaUploadValidator
  ALLOWED_IMAGE_TYPES = %w[
    image/jpeg
    image/png
    image/webp
    image/gif
  ].freeze

  MAX_IMAGE_SIZE = 5.megabytes
  MAX_COMMENT_IMAGES = 5

  module_function

  def validate_image(record, attachment, attribute:, max_size: MAX_IMAGE_SIZE, allowed_types: ALLOWED_IMAGE_TYPES)
    return if attachment.respond_to?(:attached?) && !attachment.attached?
    return unless attachment.blob.present?

    blob = attachment.blob
    if blob.byte_size.zero?
      record.errors.add(attribute, "#{blob.filename} must not be empty")
      return
    end

    if blob.byte_size > max_size
      record.errors.add(attribute, "#{blob.filename} must be #{ActiveSupport::NumberHelper.number_to_human_size(max_size)} or smaller")
      return
    end

    detected_type = inspect_image(record, attribute, blob)
    unless detected_type && allowed_types.include?(detected_type)
      record.errors.add(attribute, "#{blob.filename} must be a valid JPEG, PNG, WebP, or GIF image")
      return
    end

    declared_type = normalize_type(blob.content_type)
    if declared_type != detected_type
      record.errors.add(attribute, "#{blob.filename} content type does not match its contents")
    end
  end

  def inspect_image(record, attribute, blob)
    unless blob.service.exist?(blob.key)
      return inspect_io(pending_upload_io(record, attribute, blob))
    end

    blob.open do |file|
      inspect_io(file)
    end
  rescue ActiveStorage::FileNotFoundError, Vips::Error, Errno::ENOENT
    nil
  end

  def inspect_io(io)
    return unless io

    source = io.respond_to?(:open) ? io.open : io
    source = source.fetch(:io) if source.is_a?(Hash)
    source.rewind if source.respond_to?(:rewind)
    detected_type = normalize_type(Marcel::MimeType.for(source, name: nil, declared_type: nil))
    return unless ALLOWED_IMAGE_TYPES.include?(detected_type)

    source.rewind if source.respond_to?(:rewind)
    image = source.respond_to?(:path) ? Vips::Image.new_from_file(source.path, access: :sequential) : Vips::Image.new_from_buffer(source.read, "")
    return unless image.width.positive? && image.height.positive?

    detected_type
  ensure
    source.rewind if source&.respond_to?(:rewind)
  end

  def pending_upload_io(record, attribute, blob)
    change = record.attachment_changes[attribute.to_s]
    return unless change

    if change.respond_to?(:attachables)
      index = change.blobs.index(blob)
      index && change.attachables[index]
    elsif change.respond_to?(:attachable) && change.blob == blob
      change.attachable
    end
  end

  def normalize_type(content_type)
    content_type == "image/jpg" ? "image/jpeg" : content_type
  end
end
