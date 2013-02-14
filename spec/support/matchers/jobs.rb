RSpec::Matchers.define :complete_as do |state, message|
  match do |actual|
    sleep 0.1 until actual.completed?

    if message.nil?
      actual.state == state
    else
      actual.state == state && actual.result == message
    end
  end
end
