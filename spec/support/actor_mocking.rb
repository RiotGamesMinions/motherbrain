RSpec.configuration.before(:each) do
  class Celluloid::ActorProxy
    [ :should_receive, :should_not_receive, :stub, :stub_chain, :should, :should_not ].each do |method|
      undef_method(method) if method_defined?(method)
    end
  end
end
