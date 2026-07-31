module UploadCleanup
  private

  def attached_blob_ids(record, attachment_name)
    attachments = record.public_send(attachment_name)
    attachments = [ attachments ] unless attachments.respond_to?(:each)
    attachments.filter_map { |attachment| attachment.blob&.id }
  end

  def purge_new_uploads(record, attachment_name, previous_blob_ids: [])
    attachments = record.public_send(attachment_name)
    attachments = [ attachments ] unless attachments.respond_to?(:each)

    attachments.each do |attachment|
      attached = attachment.respond_to?(:attached?) ? attachment.attached? : attachment.persisted?
      attachment.purge if attached && !previous_blob_ids.include?(attachment.blob.id)
    end
  end
end
