require ::File.join(::File.dirname(__FILE__),
                    *%w(.. .. libraries pacemaker constraint colocation))

module Chef::RSpec
  module Pacemaker
    module Config
      COLOCATION_CONSTRAINT = \
        ::Pacemaker::Constraint::Colocation.new('colocation1')
      COLOCATION_CONSTRAINT.score = 'inf'
      COLOCATION_CONSTRAINT.resources = ['foo']
      COLOCATION_CONSTRAINT_DEFINITION = 'colocation colocation1 inf: foo'
    end
  end
end
