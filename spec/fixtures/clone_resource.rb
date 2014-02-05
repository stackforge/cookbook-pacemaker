require ::File.expand_path('../../libraries/pacemaker/resource/clone',
                           ::File.dirname(__FILE__))
require ::File.expand_path('keystone_primitive', ::File.dirname(__FILE__))

module Chef::RSpec
  module Pacemaker
    module Config
      include Chef::RSpec::Pacemaker::Config

      CLONE = ::Pacemaker::Resource::Clone.new('clone1')
      CLONE.primitive = KEYSTONE
    end
  end
end
