require File.expand_path('../../libraries/pacemaker/resource/ms',
                         File.dirname(__FILE__))

module Chef::RSpec
  module Pacemaker
    module Config
      MS_RESOURCE = ::Pacemaker::Resource::MasterSlave.new('ms1')
      MS_RESOURCE.rsc = 'primitive1'
      MS_RESOURCE.meta = [
        [ "globally-unique", "true" ],
        [ "clone-max",       "2"    ],
        [ "clone-node-max",  "2"    ],
        [ "master-max",      "1"    ],
        [ "master-node-max", "1"    ]
      ]
      MS_RESOURCE_DEFINITION = <<'EOF'.chomp
ms ms1 primitive1 \
         meta clone-max="2" clone-node-max="2" globally-unique="true" master-max="1" master-node-max="1"
EOF
    end
  end
end
