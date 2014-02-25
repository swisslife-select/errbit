module ServiceLocator
  class << self
    def differ
      @differ || Differ
    end

    def differ=(d)
      @differ = d
    end
  end
end