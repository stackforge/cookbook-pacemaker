require File.expand_path('../constraint', File.dirname(__FILE__))

class Pacemaker::Constraint::Order < Pacemaker::Constraint
  TYPE = 'order'
  register_type TYPE

  attr_accessor :score, :ordering

  def self.attrs_to_copy_from_chef
    %w(score ordering)
  end

  def parse_definition
    # FIXME: add support for symmetrical=<bool>
    # Currently we take the easy way out and don't bother parsing the ordering.
    # See the crm(8) man page for the official BNF grammar.
    score_regexp = %r{\d+|[-+]?inf|Mandatory|Optional|Serialize}
    unless definition =~ /^#{self.class::TYPE} (\S+) (#{score_regexp}): (.+?)\s*$/
      raise Pacemaker::CIBObject::DefinitionParseError, \
        "Couldn't parse definition '#{definition}'"
    end
    self.name  = $1
    self.score = $2
    self.ordering = $3
  end

  def definition_string
    "#{self.class::TYPE} #{name} #{score}: #{ordering}"
  end

end
