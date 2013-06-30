Given(/^the Chef Server is empty$/) do
  MB::RSpec::ChefServer.clear_data
end
