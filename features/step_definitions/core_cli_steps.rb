When /^I run MB with no arguments$/ do
  run_simple(unescape("mb"), false)
end

When /^I run the "(.*?)" command$/ do |command|
  run_simple(unescape("mb #{command}"), false)
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
  exit_status = MB.const_get(konstant).status_code
  assert_exit_status(exit_status)
end
