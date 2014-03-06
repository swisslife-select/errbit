require 'hoptoad/v2'

module Hoptoad
  class BaseError < StandardError
  end

  class ApiVersionError < StandardError
    def initialize
      super "Wrong API Version: Expecting 2.0, 2.1, 2.2, 2.3 or 2.4"
    end
  end

  class IncorrectXml < BaseError
  end

  def self.parse_xml!(xml)
    parsed = ActiveSupport::XmlMini.backend.parse(xml)['notice'] || raise(ApiVersionError)
    processor = get_version_processor(parsed['version'])
    processor.process_notice(parsed)
  rescue Nokogiri::XML::SyntaxError
    raise IncorrectXml
  end

  private
    def self.get_version_processor(version)
      case version
      when /2\.[01234]/; Hoptoad::V2
      else;            raise ApiVersionError
      end
    end
end

