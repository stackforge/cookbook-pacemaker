require File.expand_path('../resource', File.dirname(__FILE__))
require File.expand_path('../mixins/resource_meta', File.dirname(__FILE__))

class Pacemaker::Resource::Group < Pacemaker::Resource
  TYPE = 'group'
  register_type TYPE

  include Pacemaker::Resource::Meta

  attr_accessor :members

  def self.from_chef_resource(resource)
    attrs = %w(members meta)
    new(resource.name).copy_attrs_from_chef_resource(resource, *attrs)
  end

  def parse_definition
    rsc_re = /(\S+?)(?::(Started|Stopped))?/
    unless definition =~ /^#{TYPE} (\S+) (.+?)(\s+\\)?$/
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
    str = "#{TYPE} #{name} " + members.join(' ')
    unless meta.empty?
      str << continuation_line(meta_string)
    end
    str
  end

  def crm_configure_command
    "crm configure " + definition_string
  end

end
