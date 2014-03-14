module UserRepository
  extend ActiveSupport::Concern

  included do
    scope :with_not_blank_email, -> { where("email IS NOT NULL AND email != ''") }
    scope :ordered, -> { order('name ASC') }
  end
end
