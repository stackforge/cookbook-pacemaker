require File.expand_path('cib_object', File.dirname(__FILE__))

module Pacemaker
  class Constraint < Pacemaker::CIBObject
    def self.description
      type = self.to_s.split('::').last
      "#{type} constraint"
    end
  end
end
