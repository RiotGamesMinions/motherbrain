module MotherBrain
  module Bootstrap
    # @author Michael Ivey <michael.ivey@riotgames.com>
    class Template
      class << self
        # Install a bootstrap template into the templates directory
        #
        # @param [String] name
        #   the name of the template
        # @param [String] filename_or_url
        #   a local filename or URL to download
        #
        # @raise [MB::BootstrapTemplateNotFound] if the file cannot be installed
        def install(name, filename_or_url)
          template_path = MB::FileSystem.templates.join(name)
          if template_path.exist?
            raise MB::BootstrapTemplateNotFound, "Template named `#{name}` already installed"
          end
          MB.log.info "Installing bootstrap template `#{name}` from #{filename_or_url}"
          name += ".erb"
          if filename_or_url.match(URI.regexp)
            if filename_or_url.match(URI.regexp(['http','https']))
              uri = URI.parse(filename_or_url)
              begin
                Net::HTTP.start(uri.host) do |http|
                  resp = http.get(uri.path)
                  MB::FileSystem.templates.join(name).open("w+") do |file|
                    file.write(resp.body)
                  end
                end
              rescue Exception => ex
                raise MB::BootstrapTemplateNotFound, ex
              end
            else
              raise MB::BootstrapTemplateNotFound, "Only http/https URLs are supported"
            end
          elsif File.exists?(filename_or_url)
            FileUtils.copy(filename_or_url, template_path.to_s)
          else
            raise MB::BootstrapTemplateNotFound, "Couldn't find the template to install or the protocol given is not supported."
          end
        end

        # Find and validate a user-chosen template
        #
        # @param [String] name_or_path
        #  User's choice of template
        #
        # @return [String] the actual path the the chosen template
        # @return [nil] if there is no template
        #
        # @raise [MB::BootstrapTemplateNotFound] if the template file
        #   does not exist
        def find(name_or_path=nil)
          name_or_path ||= MB::Application.config.bootstrap.default_template
          return unless name_or_path
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
