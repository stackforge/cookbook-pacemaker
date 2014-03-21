require File.expand_path('../constraint', File.dirname(__FILE__))

class Pacemaker::Constraint::Colocation < Pacemaker::Constraint
  TYPE = 'colocation'
  register_type TYPE

  attr_accessor :score, :resources

  def self.attrs_to_copy_from_chef
    %w(score resources)
  end

  def parse_definition
    # FIXME: this is incomplete.  It probably doesn't handle resource
    # sets correctly, and certainly doesn't handle node attributes.
    # See the crm(8) man page for the official BNF grammar.
    unless definition =~ /^#{self.class::TYPE} (\S+) (\d+|[-+]?inf): (.+?)\s*$/
      raise Pacemaker::CIBObject::DefinitionParseError, \
        "Couldn't parse definition '#{definition}'"
    end
    self.name  = $1
    self.score = $2
    self.resources = $3.split
  end

  def definition_string
    "#{self.class::TYPE} #{name} #{score}: " + resources.join(' ')
  end

end
