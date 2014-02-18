Given /^a cookbook "(.*?)" at version "(.*?)" with a plugin that can bootstrap$/ do |name, version|
  generate_cookbook(name, version: version, with_plugin: true, with_bootstrap: true)
  dir = File.dirname(mb_config_path)
  @bootstrap_manifest = File.join(dir, "#{name}-#{version}-bootstrap.json")
  File.open(@bootstrap_manifest, "w+") do |file|
    file.write %Q|
{
  "node_groups": [
    {
      "groups": ["#{name}::server"],
      "hosts": ["#{name}01.fake.cloud.riotgames.com"]
    }
  ]
}
|
  end
end

When /^I bootstrap "(.*?)"$/ do |name|
  set_env "MB_TEST_INIT_ENV", "#{name}prod"
  set_env "MB_TEST_INIT_COOKBOOK", name
  set_env "MB_TEST_INIT_BOOTSTRAP", "true"
  run_simple(unescape("mb #{name} bootstrap #{@bootstrap_manifest} --environment #{name}prod -d -L /tmp/aruba-mb.log"), false)
end

Given /^an extra bootstrap template$/ do
  @template = tmp_path.join("extra_bootstrap_template.erb").to_s
  File.open(@template, 'w+') {|f| f.write "echo 'HELLO'" }
end

Given(/^an installed bootstrap template named "(.*?)"$/) do |template|
  File.open(MB::FileSystem.templates.join("#{template}.erb").to_s, "w+") {|f| f.write "echo 'HELLO'" }
end

When /^I bootstrap "(.*?)" with the "(.*?)" bootstrap template$/ do |name, template|
  template = @template if template == "extra"
  set_env "MB_TEST_INIT_ENV", "#{name}prod"
  set_env "MB_TEST_INIT_COOKBOOK", name
  set_env "MB_TEST_INIT_BOOTSTRAP", "true"
  set_env "MB_TEST_INIT_TEMPLATE", template
  run_simple(unescape("mb #{name} bootstrap #{@bootstrap_manifest} --environment #{name}prod --template #{template} -d -L /tmp/aruba-mb.log"), false)
end

When(/^I install a template named "(.*?)" from "(.*?)"$/) do |name, location|
  if location.match(URI.regexp(['http','https']))
    set_env "MB_TEST_INIT_TEMPLATE_URL", "#{name}###{location}"
  else
    location = tmp_path.join(location).to_s
    File.open(location, 'w+') {|f| f.write "echo 'HELLO'" }
  end
  run_simple(unescape("mb template #{name} #{location} -d -L /tmp/aruba-mb.log"), false)
end

Then(/^the "(.*?)" template should exist$/) do |template|
  MB::FileSystem.templates.join("#{template}.erb").exist?.should be_true
end

