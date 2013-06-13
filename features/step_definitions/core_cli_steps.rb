When /^I run MB with no arguments$/ do
  run_simple(unescape("mb"), false)
end

When /^I run the "(.*?)" command$/ do |command|
  run_simple(unescape("mb #{command}"), false)
end

When /^I run the "(.*?)" command with:$/ do |command, arguments|
  run_simple(unescape("mb #{command} #{arguments.raw.join(' ')}"), false)
end

When /^I run the "(.*?)" command interactively$/ do |command|
  run_interactive("mb #{command}")
end

When /^I run the "(.*?)" command interactively with:$/ do |command, arguments|
  run_interactive("mb #{command} #{arguments.raw.join(' ')}")
end

When /^I run a command that requires a config$/ do
  step %Q{I run the "plugins" command}
end

Then /^the exit status should be the code for error "(.*?)"$/ do |konstant|
  assert_exit_status(exit_code_for(konstant))
end

Given /^we have AWS credentials$/ do
  set_env "AWS_ACCESS_KEY", "022QF06E7MXBSAMPLE"
  set_env "AWS_SECRET_KEY", "kWcrlUX5JEDGM/SAMPLE/aVmYvHNif5zB+d9+ct"
  set_env "EC2_URL", "https://ec2.us-east-1.amazonaws.com"
end
