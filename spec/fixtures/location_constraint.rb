require ::File.expand_path('../../libraries/pacemaker/constraint/location',
                           File.dirname(__FILE__))

module Chef::RSpec
  module Pacemaker
    module Config
      LOCATION_CONSTRAINT = \
        ::Pacemaker::Constraint::Location.new('location1')
      LOCATION_CONSTRAINT.rsc   = 'primitive1'
      LOCATION_CONSTRAINT.score = '-inf'
      LOCATION_CONSTRAINT.node  = 'node1'
      LOCATION_CONSTRAINT_DEFINITION = 'location location1 primitive1 -inf: node1'
    end
  end
end
