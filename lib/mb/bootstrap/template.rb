module MotherBrain
  module Bootstrap
    # @author Michael Ivey <muchael.ivey@riotgames.com>
    #
    class Template
      class << self
        def find(name_or_path=nil)
          name_or_path ||= MB::Application.config.bootstrap.default_template
          installed = MB::FileSystem.templates.join("#{name_or_path}.erb").to_s
          if File.exists?(installed)
            return installed
          end
          if File.exists?(name_or_path)
            return name_or_path
          else
            raise MB::BootstrapTemplateNotFound
          end
        end
      end
    end
  end
end
