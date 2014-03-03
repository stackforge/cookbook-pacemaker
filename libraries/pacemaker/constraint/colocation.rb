require File.expand_path('../constraint', File.dirname(__FILE__))

class Pacemaker::Constraint::Colocation < Pacemaker::Constraint
  TYPE = 'colocation'
  register_type TYPE

  attr_accessor :score, :resources

  def self.attrs_to_copy_from_chef
    %w(score resources)
  end

  def parse_definition
    rsc_re = /(\S+?)(?::(Started|Stopped))?/
    unless definition =~ /^#{TYPE} (\S+) (\d+|[-+]?inf): (.+?)\s*$/
      raise Pacemaker::CIBObject::DefinitionParseError, \
        "Couldn't parse definition '#{definition}'"
    end
    self.name  = $1
    self.score = $2
    self.resources = $3.split
  end

  def definition_string
    "#{TYPE} #{name} #{score}: " + resources.join(' ')
  end

  def crm_configure_command
    "crm configure " + definition_string
  end

end
