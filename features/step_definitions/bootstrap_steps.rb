Given /^a cookbook "(.*?)" at version "(.*?)" with a plugin that can bootstrap$/ do |name, version|
  generate_cookbook(name, version: version, with_plugin: true, with_bootstrap: true)
  dir = File.dirname(mb_config_path)
  @bootstrap_manifest = File.join(dir, "#{name}-#{version}-bootstrap.json")
  File.open(@bootstrap_manifest, "w+") do |file|
    file.write %Q|
{
  "nodes": [
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
  @aruba_timeout_seconds = 600
  register_mock "application_init", "bootstrap_mock_ridley"
  run_simple(unescape("mb #{name} bootstrap #{@bootstrap_manifest} --environment #{name}prod -d -L /tmp/aruba-mb.log"), false)
end

Given /^an extra bootstrap template$/ do
  @template = tmp_path.join("extra_bootstrap_template.erb").to_s
  File.open(@template, 'w+') {|f| f.write "echo 'HELLO'" }
end


When /^I bootstrap "(.*?)" with the extra bootstrap template$/ do |name|
  register_mock "application_init", "bootstrap_with_template_mock_ridley"
  run_simple(unescape("mb #{name} bootstrap #{@bootstrap_manifest} --environment #{name}prod --template #{@template} -d -L /tmp/aruba-mb.log"), false)
end

