shared_context "keystone config" do
  before(:all) do
    @params = {
      "os_password"    => "adminpw",
      "os_auth_url"    => "http://node1:5000/v2.0",
      "os_username"    => "admin",
      "os_tenant_name" => "openstack"
    }
    params_string = @params.map { |k,v| %'#{k}="#{v}"' }.join(" ")
    @config = <<EOF
primitive keystone ocf:openstack:keystone \\
        params #{params_string} \\
        meta target-role="Started" is-managed="true" \\
        op monitor interval="10s"
EOF
  end
end
