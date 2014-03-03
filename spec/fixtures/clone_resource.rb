require File.expand_path('../../libraries/pacemaker/resource/clone',
                         File.dirname(__FILE__))

module Chef::RSpec
  module Pacemaker
    module Config
      CLONE_RESOURCE = ::Pacemaker::Resource::Clone.new('clone1')
      CLONE_RESOURCE.rsc = 'primitive1'
      CLONE_RESOURCE.meta = [
        [ "globally-unique", "true" ],
        [ "clone-max",       "2"    ],
        [ "clone-node-max",  "2"    ]
      ]
      CLONE_RESOURCE_DEFINITION = <<'EOF'.chomp
clone clone1 primitive1 \
         meta clone-max="2" clone-node-max="2" globally-unique="true"
EOF
    end
  end
end
