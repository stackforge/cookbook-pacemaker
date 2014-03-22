this_dir = File.dirname(__FILE__)
require File.expand_path('../resource', this_dir)
require File.expand_path('../mixins/resource_meta', this_dir)

class Pacemaker::Resource::Clone < Pacemaker::Resource
  TYPE = 'clone'
  register_type TYPE

  include Pacemaker::Mixins::Resource::Meta

  # FIXME: need to handle params as well as meta

  attr_accessor :rsc

  def self.attrs_to_copy_from_chef
    %w(rsc meta)
  end

  def definition_string
    str = "#{self.class::TYPE} #{name} #{rsc}"
    unless meta.empty?
      str << continuation_line(meta_string)
    end
    str
  end

  def parse_definition
    unless definition =~ /^#{self.class::TYPE} (\S+) (\S+)/
      raise Pacemaker::CIBObject::DefinitionParseError, \
        "Couldn't parse definition '#{definition}'"
    end
    self.name = $1
    self.rsc  = $2
    self.meta = self.class.extract_hash(definition, 'meta')
  end

end
