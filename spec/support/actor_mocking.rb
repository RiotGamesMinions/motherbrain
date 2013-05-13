RSpec.configuration.before(:each) do
  class Celluloid::ActorProxy
    unless @rspec_compatible
      @rspec_compatible = true
      undef_method :should_receive
      undef_method :should_not_receive
      undef_method :stub
      undef_method :stub_chain
      undef_method :should
      undef_method :should_not
    end
  end
end
