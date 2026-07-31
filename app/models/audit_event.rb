class AuditEvent < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true

  validates :action, :target_type, :target_label, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.record!(actor:, action:, target:, target_label:, metadata: {})
    create!(
      actor: actor,
      action: action,
      target_type: target.is_a?(Class) ? target.name : target.class.name,
      target_id: target.is_a?(Class) ? nil : target.id,
      target_label: target_label.to_s.truncate(160),
      metadata: metadata.compact
    )
  end
end
