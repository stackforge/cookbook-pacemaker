require File.join(File.dirname(__FILE__), 'cib_object')

module Pacemaker
  class Constraint < Pacemaker::CIBObject
    def self.description
      type = self.to_s.split('::').last
      "#{type} constraint"
    end
  end
end
