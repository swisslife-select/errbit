module DeployRepository
  extend ActiveSupport::Concern

  included do
    scope :by_created_at, order("created_at DESC")
  end

  def previous
    app.deploys.where('created_at < ?', self.created_at).where(environment: self.environment).order(:created_at).last
  end
end
