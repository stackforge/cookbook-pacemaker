this_dir = File.dirname(__FILE__)
require File.expand_path('../resource', this_dir)
require File.expand_path('../mixins/resource_meta', this_dir)

class Pacemaker::Resource::Group < Pacemaker::Resource
  TYPE = 'group'
  register_type TYPE

  include Pacemaker::Mixins::Resource::Meta

  # FIXME: need to handle params as well as meta

  attr_accessor :members

  def self.attrs_to_copy_from_chef
    %w(members meta)
  end

  def parse_definition
    unless definition =~ /^#{self.class::TYPE} (\S+) (.+?)(\s+\\)?$/
      raise Pacemaker::CIBObject::DefinitionParseError, \
        "Couldn't parse definition '#{definition}'"
    end
    self.name    = $1
    members = $2.split
    trim_from = members.find_index('meta')
    members = members[0..trim_from-1] if trim_from
    self.members = members
    self.meta    = self.class.extract_hash(definition, 'meta')
  end

  def definition_string
    str = "#{self.class::TYPE} #{name} " + members.join(' ')
    unless meta.empty?
      str << continuation_line(meta_string)
    end
    str
  end

end
