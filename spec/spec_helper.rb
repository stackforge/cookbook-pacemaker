require 'chefspec'

ENV['RSPEC_RUNNING'] = 'true'

RSpec.configure do |config|
  # config.mock_with :rspec do |mocks|
  #   # This option should be set when all dependencies are being loaded
  #   # before a spec run, as is the case in a typical spec helper. It will
  #   # cause any verifying double instantiation for a class that does not
  #   # exist to raise, protecting against incorrectly spelt names.
  #   mocks.verify_doubled_constant_names = true
  # end

  # Specify the path for Chef Solo to find cookbooks (default: [inferred from
  # the location of the calling spec file])
  #config.cookbook_path = '/var/cookbooks'

  # Specify the path for Chef Solo to find roles (default: [ascending search])
  #config.role_path = '/var/roles'

  # Specify the Chef log_level (default: :warn)
  config.log_level = ENV['CHEF_LOG_LEVEL'].to_sym if ENV['CHEF_LOG_LEVEL']

  # Specify the path to a local JSON file with Ohai data (default: nil)
  #config.path = 'ohai.json'

  # Specify the operating platform to mock Ohai data from (default: nil)
  config.platform = 'suse'

  # Specify the operating version to mock Ohai data from (default: nil)
  config.version = '11.03'

  # Disable deprecated "should" syntax
  # https://github.com/rspec/rspec-expectations/blob/master/Should.md
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.run_all_when_everything_filtered = true
  config.filter_run :focus => true
end

# FIXME
#running_guard = ENV['GUARD_NOTIFY'] && ! ENV['GUARD_NOTIFY'].empty?

if ENV['RUBYDEPS']
  require 'rubydeps'
  Rubydeps.start
end

if false # ! running_guard
  at_exit { ChefSpec::Coverage.report! }
end
