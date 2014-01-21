require ::File.join(::File.dirname(__FILE__), *%w(.. libraries cib_objects))

module Chef::RSpec
  module Pacemaker
    module Config
      extend Chef::Libraries::Pacemaker::CIBObjects

      RA = {
        :agent  => "ocf:openstack:keystone",
        :params => [
          [ "os_password",    "adminpw"                ],
          [ "os_auth_url",    "http://node1:5000/v2.0" ],
          [ "os_username",    "admin"                  ],
          [ "os_tenant_name", "openstack"              ]
        ],
        :meta   => [
          [ "target-role", "Started" ],
          [ "is-managed", "true" ]
        ],
        :op     => [
          [ "monitor", { "interval" => "10s" } ]
        ],
      }
      RA[:params_string] = resource_params_string(RA[:params])
      RA[:meta_string]   = resource_meta_string(RA[:meta])
      RA[:op_string]     = resource_op_string(RA[:op])
      RA[:config] = <<EOF
primitive keystone ocf:openstack:keystone \\
        #{RA[:params_string]} \\
        #{RA[:meta_string]} \\
        #{RA[:op_string]}
EOF
    end
  end
end
