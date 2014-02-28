module Errbit::Version
  MAJOR = 0
  MINOR = 4
  PATCH = 0

  def self.to_s
    "#{MAJOR}.#{MINOR}.#{PATCH}.dev"
  end
end
