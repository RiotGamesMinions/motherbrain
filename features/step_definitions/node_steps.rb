Given(/^I have a node named "(.*?)"$/) do |node_name|
  ridley.node.create(name: node_name)
end

Then(/^the node "(.*?)" should be disabled$/) do |node_name|
  ridley.node.find(name: node_name)
  expect(ridley.run_list[0]).to eq("recipe[disabled]")
end
