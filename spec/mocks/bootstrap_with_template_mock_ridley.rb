require 'rspec/mocks'

RSpec::Mocks::setup(self)

RSpec::Mocks::setup(Application.ridley.wrapped_object)
ridley = double('ridley')
Application.ridley.wrapped_object.should_receive(:connection).and_return(ridley)
ridley.should_receive(:get).with("environments/awesomedprod").and_return(stub(:response, :body => {}))
ridley.should_receive(:get).with("cookbooks").and_return(stub(:response, :body => {}))
ridley.should_receive(:get).with("nodes").and_return(stub(:response, :body => []))
ridley.should_receive(:alive?).and_return(true)
ridley.should_receive(:terminate).and_return(true)
ridley.should_receive(:url_prefix).and_return("http://chef.example.com")

node = double('node')
Application.ridley.wrapped_object.should_receive(:node).and_return(node)
ssh = double('ssh')
node.should_receive(:bootstrap) do |hostnames, options|
  raise "Template not set!" unless options[:template]
  raise "Template not right!" unless options[:template] =~ /extra_bootstrap_template/
  [ssh]
end
node.should_receive(:all).and_return([])
ssh.should_receive(:host).and_return("foo.example.com")
ssh.should_receive(:error?).and_return(false)

RSpec::Mocks::setup(Application.node_querier.wrapped_object)
Application.node_querier.wrapped_object.should_receive(:node_name).and_return("foo.example.com")


# RSpec::Mocks::setup(Application.bootstrap_manager.wrapped_object)
# bootstrapper = double('bootstrapper')
# Application.bootstrap_manager.wrapped_object.class_eval do
#   def bootstrap(job, environment, manifest, plugin, options = {})
#     job.report_running
#     job.report_success
#     job.terminate if job.alive?
#   end
# end

