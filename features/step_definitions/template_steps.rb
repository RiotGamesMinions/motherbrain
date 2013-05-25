Given(/^I have no templates installed$/) do
  FileUtils.rm_rf Dir.glob(MB::FileSystem.templates.join("*"))
end

Then(/^I should have no templates installed$/) do
  expect(Dir.glob(MB::FileSystem.templates.join("*"))).to have(0).items
end
