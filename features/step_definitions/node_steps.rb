Given(/^I have a node named "(.*?)"$/) do |node_name|
  ridley.node.create(name: node_name)
end
