source 'https://rubygems.org'

#gem 'berkshelf',  '~> 2.0'

group :test, :development do
  gem 'chefspec', '~> 3.0'
  gem 'rubydeps'
end

group :development do
  gem 'foodcritic', '~> 3.0'
  gem 'rubocop'
  gem 'jazz_hands'
  gem 'guard-rspec'
  gem 'guard-bundler'
  # Prevent "Error: can't modify string; temporarily locked"
  # http://stackoverflow.com/a/19505033/179332
  gem "rb-readline", "~> 0.5.0"
end

