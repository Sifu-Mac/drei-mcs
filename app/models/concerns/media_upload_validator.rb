module MediaUploadValidator
  ALLOWED_IMAGE_TYPES = %w[
    image/jpeg
    image/png
    image/webp
    image/gif
  ].freeze

  MAX_IMAGE_SIZE = 5.megabytes
end
