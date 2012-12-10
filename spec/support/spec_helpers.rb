module MotherBrain
  module SpecHelpers
    def app_root_path
      Pathname.new(File.expand_path('../../../', __FILE__))
    end

    def tmp_path
      app_root_path.join('spec/tmp')
    end

    def fixtures_path
      app_root_path.join('spec/fixtures')
    end

    def clean_tmp_path
      FileUtils.rm_rf(tmp_path)
      FileUtils.mkdir_p(tmp_path)
    end

    def set_mb_config_path(path = mb_config_path)
      ENV["MB_CONFIG"] = path.to_s
    end

    def set_plugin_path(path = plugin_path)
      ENV["MB_PLUGIN_PATH"] = path.to_s
    end

    def mb_config_path
      app_root_path.join("spec", "tmp", ".mb", "config.json")
    end

    def plugin_path
      app_root_path.join("spec", "tmp", ".mb", "plugins")
    end

    def generate_valid_config(path)
      FileUtils.rm_rf(path)
      MB::Config.new.tap do |mb|
        mb.chef.api_url = "https://api.opscode.com/organizations/vialstudio"
        mb.chef.api_client = "reset"
        mb.chef.api_key = "/Users/reset/.chef/reset.pem"
        mb.ssh.user = "root"
        mb.ssh.password = "secretpass"
      end.save(path)
    end

    def generate_invalid_config(path)
      FileUtils.rm_rf(path)
      MB::Config.new.save(path)
    end

    def generate_plugin(name, version, path)
      FileUtils.mkdir_p(path)
      file = "#{name}-#{version}.rb"

      File.open(File.join(path, file), 'w+') do |f|
        f.write <<-EOH
        name '#{name}'
        version '#{version}'
        description "whatever"
        author "Jamie Winsor"
        email "jamie@vialstudios.com"
        EOH
      end
    end

    def klass
      described_class
    end
  end
end
