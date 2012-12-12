module KlassHelper
  def klass
    described_class
  end
end

RSpec.configure do |config|
  config.include KlassHelper
end

