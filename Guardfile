#!/usr/bin/ruby
#
# More info at https://github.com/guard/guard#readme

guard_opts = {
  all_on_start:   true,
  all_after_pass: true,
}

def all_specs;      'spec'           end
def library_specs;  'spec/libraries' end
def provider_specs; 'spec/providers' end

group :rspec do
  guard 'rspec', guard_opts do
    watch(%r{^Gemfile$})                   { all_specs }
    watch(%r{^Gemfile.lock$})              { all_specs }
    watch(%r{^spec/spec_helper\.rb$})      { all_specs }
    watch(%r{^spec/helpers/(.+)\.rb$})     { all_specs }
    watch(%r{^spec/fixtures/(.+)\.rb$})    { all_specs }
    watch(%r{^libraries/pacemaker\.rb$})   { all_specs }
    watch(%r{^libraries/(.*mixin.*)\.rb$}) { library_specs }
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^libraries/(.+)\.rb$})  { |m|
      "spec/libraries/#{m[1]}_spec.rb"
    }
    watch(%r{^providers/common\.rb$})      { provider_specs }
    watch(%r{^providers/(.*mixin.*)\.rb$}) { provider_specs }
    watch(%r{^(resources|providers)/(.+)\.rb$}) { |m|
      "spec/providers/#{m[1]}_spec.rb"
    }
  end
end

group :bundler do
  guard 'bundler' do
    watch('Gemfile')
  end
end
