# Magick %)
module DataMigration
  module MagickConfig
    class << self
      def read_configuration
        config_file = Rails.root.join("config", "mongoid.yml")
        config = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env] if config_file.file?
        return config if config
        {}
      end
    end
  end
end
