require 'rspec/mocks'

RSpec::Mocks::setup(self)

RSpec::Mocks::setup(Application.ridley.wrapped_object)
ridley = double('ridley')
Application.ridley.wrapped_object.should_receive(:connection).and_return(ridley)
ridley.should_receive(:get).with("environments/awesomedprod").and_return(stub(:response, :body => {}))
ridley.should_receive(:get).with("cookbooks").and_return(stub(:response, :body => {}))
ridley.should_receive(:alive?).and_return(true)

RSpec::Mocks::setup(Application.bootstrap_manager.wrapped_object)
bootstrapper = double('bootstrapper')
Application.bootstrap_manager.wrapped_object.class_eval do
  def bootstrap(job, environment, manifest, plugin, options = {})
    job.report_running
    job.report_success
    job.terminate if job.alive?
  end
end

