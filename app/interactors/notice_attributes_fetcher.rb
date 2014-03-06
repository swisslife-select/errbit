module NoticeAttributesFetcher
  class << self
    def from_request(request)
      xml_string = request.parameters['data'] || request.raw_post
      return if xml_string.blank?

      Hoptoad.parse_xml! xml_string
    rescue Hoptoad::BaseError
      nil
    end
  end
end
