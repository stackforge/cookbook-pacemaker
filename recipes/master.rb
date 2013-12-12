require 'base64'

# Install haveged to create entropy so keygen doesn't take an hour
# odd errors coming out of automated installation, gets restarted next
package "haveged" do
  ignore_failure true
end

%w{ corosync pacemaker }.each do |pkg|
  package pkg
end

service "haveged" do
  supports :restart => true, :status => :true
  action [:enable, :start]
end

#create authkey
execute "corosync-keygen" do
  creates "/etc/corosync/authkey"
  user "root"
  umask "0400"
  action :run
end

# Read authkey (it's binary) into encoded format and save to chef server
ruby_block "Store authkey" do
  block do
    file = File.new('/etc/corosync/authkey', 'r')
    contents = ""
    file.each do |f|
      contents << f
    end
    packed = Base64.encode64(contents)
    node.set_unless['corosync']['authkey'] = packed
    node.save
  end
  action :nothing
  subscribes :create, resources(:execute => "corosync-keygen"), :immediately
end

#manage the corosync services
include_recipe "pacemaker::default"
