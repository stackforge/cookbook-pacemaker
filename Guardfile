#!/usr/bin/ruby
#
# More info at https://github.com/guard/guard#readme

guard_opts = {
  all_on_start:   true,
  all_after_pass: true,
}

def startup_guards
  watch(%r{^Gemfile$})                      { yield }
  watch(%r{^Gemfile.lock$})                 { yield }
  watch(%r{^spec/spec_helper\.rb$})         { yield }
end

group :rspec do
  guard 'rspec', guard_opts do
    startup_guards { 'spec' }
    watch(%r{^spec/.+_spec\.rb$})
  end
end

group :bundler do
  guard 'bundler' do
    watch('Gemfile')
  end
end
