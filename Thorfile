# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require 'bundler'
require 'bundler/setup'
require 'thor/rake_compat'

require 'motherbrain'
MB::Logging.setup(location: '/dev/null')

class Default < Thor
  include Thor::Actions
  include Thor::RakeCompat
  Bundler::GemHelper.install_tasks

  desc "build", "Build motherbrain-#{MotherBrain::VERSION}.gem into the pkg directory"
  def build
    Rake::Task["build"].execute
  end

  desc "install", "Build and install motherbrain-#{MotherBrain::VERSION}.gem into system gems"
  def install
    Rake::Task["install"].execute
  end

  desc "release", "Create tag v#{MotherBrain::VERSION} and build and push motherbrain-#{MotherBrain::VERSION}.gem to gem in a box"
  def release
    unless clean?
      say "There are files that need to be committed first.", :red
      exit 1
    end

    gem_location = File.join(source_root, "pkg", "motherbrain-#{MotherBrain::VERSION}.gem")

    tag_version do
      build
      run "bundle exec gem nexus #{gem_location}"
    end
  end

  desc "ci", "Run all tests"
  def ci
    ENV['CI'] = 'true' # Travis-CI also sets this, but set it here for local testing
    run "rspec --tag ~focus --color --format=progress spec"
    exit $?.exitstatus unless $?.success?
    run "cucumber --format progress"
    exit $?.exitstatus unless $?.success?
  end

  desc "routes", "Print all registered REST API routes"
  def routes
    puts MB::API::Application.routes
  end

  desc "manpage", "Re-generate the man pages"
  def manpage
    require MB.app_root.join('man', 'man_helper')
    say "Generating man page ronn source"
    MB::ManHelper.generate('man/mb.1.ronn.erb', 'man/mb.1.ronn')
    run "ronn man/mb.1.ronn"
  end

  class Cucumber < Thor
    namespace :cucumber
    default_task :all

    desc "all", "run all tests"
    def all
      exec "cucumber --require features --tags ~@wip"
    end
  end

  class Spec < Thor
    namespace :spec
    default_task :all

    desc "all", "run all tests"
    def all
      exec "rspec --color --format=documentation spec"
    end

    desc "unit", "run only unit tests"
    def unit
      exec "rspec --color --format=documentation spec --tag ~type:acceptance"
    end

    desc "acceptance", "run only acceptance tests"
    def acceptance
      exec "rspec --color --format=documentation spec --tag type:acceptance"
    end
  end

  private

    def clean?
      sh_with_excode("git diff --exit-code")[1] == 0
    end

    def tag_version
      sh "git tag -a -m \"Version #{MotherBrain::VERSION}\" #{MotherBrain::VERSION}"
      say "Tagged: #{MotherBrain::VERSION}", :green
      yield if block_given?
      sh "git push --tags"
    rescue => e
      say "Untagging: #{MotherBrain::VERSION} due to error", :red
      sh_with_excode "git tag -d #{MotherBrain::VERSION}"
      say e, :red
      exit 1
    end

    def source_root
      Pathname.new File.dirname(File.expand_path(__FILE__))
    end

    def sh(cmd, dir = source_root, &block)
      out, code = sh_with_excode(cmd, dir, &block)
      code == 0 ? out : raise(out.empty? ? "Running `#{cmd}` failed. Run this command directly for more detailed output." : out)
    end

    def sh_with_excode(cmd, dir = source_root, &block)
      cmd << " 2>&1"
      outbuf = ''

      Dir.chdir(dir) {
        outbuf = `#{cmd}`
        if $? == 0
          block.call(outbuf) if block
        end
      }

      [ outbuf, $? ]
    end
end
