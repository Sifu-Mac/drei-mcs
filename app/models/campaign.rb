class Campaign < ApplicationRecord
  belongs_to :workspace
  has_many :boards, dependent: :restrict_with_error

  validates :name, presence: true
  validates :position, presence: true

  before_create :set_position

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def restore!
    update!(archived_at: nil)
  end

  def duplicate_for!(user:)
    Campaign.transaction do
      copy = workspace.campaigns.create!(name: "#{name} Kopie", position: next_position)

      boards.unscoped.where(campaign_id: id, archived_at: nil).reorder(:position, :created_at).find_each do |board|
        board.duplicate_to!(campaign: copy, user: user)
      end

      copy
    end
  end

  private

  def set_position
    return if position.present? && position.positive?

    self.position = next_position
  end

  def next_position
    (Campaign.unscoped.where(workspace_id: workspace_id).maximum(:position) || 0) + 1
  end
end
