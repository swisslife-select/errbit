class BacktraceLineNormalizer
  def initialize(raw_line)
    @raw_line = raw_line || {}
  end

  def call
    {
      'column' => @raw_line['column'],
      'number' => @raw_line['number'],
      'file' => normalized_file,
      'method' => normalized_method,
    }
  end

  private
  def normalized_file
    if @raw_line['file'].blank?
      "[unknown source]"
    else
      file = @raw_line['file'].to_s
      # Detect lines from gem
      file.gsub!(/\[PROJECT_ROOT\]\/.*\/ruby\/[0-9.]+\/gems/, '[GEM_ROOT]/gems')
      # Strip any query strings
      file.gsub!(/\?[^\?]*$/, '')
      @raw_line['file'] = file
    end
  end

  def normalized_method
    if raw_method.blank?
      "[unknown method]"
    else
      raw_method.to_s.gsub(/[0-9_]{10,}+/, "__FRAGMENT__")
    end
  end

  def raw_method
    # https://github.com/errbit/errbit/issues/595
    @raw_line['method'] || @raw_line['method_name']
  end
end
