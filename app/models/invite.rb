class Invite < ApplicationRecord
  belongs_to :invited_by, class_name: "User"

  # internal remains readable for historic records only. New invitations are clients.
  enum :role, { internal: 0, client: 1 }, default: :client

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :pending, -> { where(accepted_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil, revoked_at: nil).where("expires_at <= ?", Time.current) }

  def usable?
    accepted_at.nil? && revoked_at.nil? && expires_at.future?
  end

  def status
    return "revoked"  if revoked_at.present?
    return "accepted" if accepted_at.present?
    return "expired"  if expires_at.past?
    "pending"
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end
end
