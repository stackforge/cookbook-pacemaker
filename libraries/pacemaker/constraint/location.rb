require File.expand_path('../constraint', File.dirname(__FILE__))

class Pacemaker::Constraint::Location < Pacemaker::Constraint
  TYPE = 'location'
  register_type TYPE

  attr_accessor :rsc, :score, :node

  def self.attrs_to_copy_from_chef
    %w(rsc score node)
  end

  def parse_definition
    # FIXME: this is woefully incomplete, and doesn't cope with any of
    # the rules syntax.  See the crm(8) man page for the official BNF
    # grammar.
    unless definition =~ /^#{self.class::TYPE} (\S+) (\S+) (\d+|[-+]?inf): (\S+)\s*$/
      raise Pacemaker::CIBObject::DefinitionParseError, \
        "Couldn't parse definition '#{definition}'"
    end
    self.name  = $1
    self.rsc   = $2
    self.score = $3
    self.node  = $4
  end

  def definition_string
    "#{self.class::TYPE} #{name} #{rsc} #{score}: #{node}"
  end

end
