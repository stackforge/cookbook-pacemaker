IGNORED_CLASSES = ['RSpec::Core::ExampleGroup']
DUMP_FILE = 'rubydeps.dump'
DOT_FILE  = 'rubydeps.dot'
SVG_FILE  = 'rubydeps.svg'

task :default => "rubydeps:svg"

file DUMP_FILE do
  sh 'RUBYDEPS=y rspec'
end

file DOT_FILE => DUMP_FILE do
  ignore_regexp = IGNORED_CLASSES.join "|"
  sh "rubydeps --class-name-filter='^(?!#{ignore_regexp})'"
  dot = File.read(DOT_FILE)
  dot.gsub!('rankdir=LR', 'rankdir=TB')
  # Unfortunately due to https://github.com/dcadenas/rubydeps/issues/4
  # we need to manually exclude some superfluous dependencies which
  # go in the wrong direction.
  dot.gsub!(/\\\n/, '')
  dot.gsub!(/^(?=\s+Object )/, '#')
  dot.gsub!(/^(?=\s+"Pacemaker::Resource::Meta" ->)/, '#')
  dot.gsub!(/^(?=\s+"Pacemaker::CIBObject" ->)/, '#')
  dot.gsub!(/^(?=\s+"Chef::Mixin::Pacemaker::StandardCIBObject" -> "(?!Pacemaker::CIBObject))/, '#')
  dot.gsub!(/^(?=\s+"Chef::Mixin::Pacemaker::RunnableResource" -> "(?!Pacemaker::CIBObject))/, '#')
  File.open(DOT_FILE, 'w') { |f| f.write(dot) }
end

file SVG_FILE => DOT_FILE do
  sh "dot -Tsvg #{DOT_FILE} > #{SVG_FILE}"
end

namespace :rubydeps do
  desc "Clean rubydeps dump"
  task :clean do
    FileUtils.rm_f([DUMP_FILE])
  end

  desc "Regenerate #{DUMP_FILE}"
  task :dump => DUMP_FILE

  desc "Regenerate #{DOT_FILE}"
  task :dot  => DOT_FILE

  desc "Regenerate #{SVG_FILE}"
  task :svg  => SVG_FILE
end
