#require ::File.join(::File.dirname(__FILE__), *%w(.. .. libraries pacemaker clone))
require_relative 'keystone_primitive'

module Chef::RSpec
  module Pacemaker
    module Config
      include Chef::RSpec::Pacemaker::Config

      CLONE = ::Pacemaker::Clone.new('clone1')
      CLONE.primitive = KEYSTONE
    end
  end
end
