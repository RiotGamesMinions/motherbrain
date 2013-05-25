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
          MB.log.info "Installing bootstrap template `#{name}` from #{filename_or_url}"
          name += ".erb"
          if filename_or_url.match(URI.regexp(['http','https']))
            uri = URI.parse(filename_or_url)
            begin
              Net::HTTP.start(uri.host) do |http|
                resp = http.get(uri.path)
                MB::FileSystem.templates.join(name).open("w+") do |file|
                  file.write(resp.body)
                end
              end
            rescue Exception => e
              MB.log.warn e.to_s
              raise MB::BootstrapTemplateNotFound
            end
          elsif File.exists?(filename_or_url)
            FileUtils.copy(filename_or_url, MB::FileSystem.templates.join(name).to_s)
          else
            MB.log.warn "Couldn't install template"
            raise MB::BootstrapTemplateNotFound
          end
        end

        # Find and validate a user-chosen template
        #
        # @param [String] name_or_path
        #  User's choice of template
        #
        # @return [String] the actual path the the chosen template
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
