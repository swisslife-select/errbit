class Backtrace < ActiveRecord::Base
  include BacktraceRepository

  has_many :notices
  has_one :notice

  has_many :lines, -> { order("created_at ASC") }, class_name: 'BacktraceLine'

  after_initialize :generate_fingerprint, :if => :new_record?

  delegate :app, :to => :notice

  def raw=(raw)
    return if raw.compact.blank?
    raw.compact.each do |raw_line|
      lines << BacktraceLine.new(BacktraceLineNormalizer.new(raw_line).call)
    end
  end

  private
  def generate_fingerprint
    self.fingerprint = Digest::SHA1.hexdigest(lines.map(&:to_s).join)
  end

end
