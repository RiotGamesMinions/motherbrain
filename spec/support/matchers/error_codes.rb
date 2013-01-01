RSpec::Matchers.define :be_error_code do |error_constant|
  match do |actual|
    error_constant.status_code == actual
  end
end
