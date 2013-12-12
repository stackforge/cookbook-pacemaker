require 'base64'

# Install haveged to create entropy so keygen doesn't take an hour
%w{ corosync pacemaker }.each do |pkg|
  package pkg
end

authkey = ""

# Find the master node:
if !File.exists?("/etc/corosync/authkey")
  master = search(:node, "corosync:authkey")
  if master.nil? or (master.length > 1)
    Chef::Application.fatal! "You must have one node with the pacemaker::master recipe in their run list to be a client."
  end
  Chef::Log.info "Found pacemaker::master node: #{master[0].name}"
  authkey = Base64.decode64(master[0]['corosync']['authkey'])
end

file "/etc/corosync/authkey" do
  not_if {File.exists?("/etc/corosync/authkey")}
  content authkey
  owner "root"
  mode "0400"
  action :create
end

#manage the corosync services
include_recipe "pacemaker::default"
