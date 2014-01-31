require ::File.join(::File.dirname(__FILE__),
                    *%w(.. .. libraries pacemaker resource clone))
require_relative 'keystone_primitive'

module Chef::RSpec
  module Pacemaker
    module Config
      include Chef::RSpec::Pacemaker::Config

      CLONE = ::Pacemaker::Resource::Clone.new('clone1')
      CLONE.primitive = KEYSTONE
    end
  end
end
