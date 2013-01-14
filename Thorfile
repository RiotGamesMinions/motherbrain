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

  desc "build", "Build MotherBrain-#{MotherBrain::VERSION}.gem into the pkg directory"
  def build
    Rake::Task["build"].execute
  end

  desc "install", "Build and install MotherBrain-#{MotherBrain::VERSION}.gem into system gems"
  def install
    Rake::Task["install"].execute
  end

  desc "release", "Create tag v#{MotherBrain::VERSION} and build and push MotherBrain-#{MotherBrain::VERSION}.gem to Rubygems"
  def release
    Rake::Task["release"].execute
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
    puts MB::Api.routes
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
end
