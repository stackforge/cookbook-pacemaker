#
# Author:: Vincent Untz
# Cookbook Name:: pacemaker
# Recipe:: stonith
#
# Copyright 2014, SUSE
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# FIXME: delete old resources when switching mode (or agent!)

case node[:pacemaker][:stonith][:mode]
when "disabled"
when "manual"
  # nothing!

when "sbd"
  require 'shellwords'

  sbd_devices = nil
  sbd_devices ||= (node[:pacemaker][:stonith][:sbd][:nodes][node[:fqdn]][:devices] rescue nil)
  sbd_devices ||= (node[:pacemaker][:stonith][:sbd][:nodes][node[:hostname]][:devices] rescue nil)
  raise "No SBD devices defined!" if sbd_devices.nil? || sbd_devices.empty?

  sbd_cmd = "sbd"
  sbd_devices.each do |sbd_device|
    sbd_cmd += " -d #{Shellwords.shellescape(sbd_device)}"
  end

  execute "Check if watchdog is present" do
    command "test -c /dev/watchdog"
  end

  execute "Check that SBD was initialized using '#{sbd_cmd} create'." do
    command "#{sbd_cmd} dump &> /dev/null"
  end

  if node.platform == 'suse'
    # We will want to explicitly allocate a slot the first time we come here
    # (hence the use of a notification to trigger this execute).
    # According to the man page, it should not be required, but apparently,
    # I've hit bugs where I had to do that. So better be safe.
    execute "Allocate SBD slot" do
      command "#{sbd_cmd} allocate #{node[:hostname]}"
      not_if "#{sbd_cmd} list | grep -q \" #{node[:hostname]} \""
      action :nothing
    end

    template "/etc/sysconfig/sbd" do
      source "sysconfig_sbd.erb"
      owner "root"
      group "root"
      mode 0644
      variables(
        :sbd_devices => sbd_devices
      )
      # We want to allocate slots before restarting corosync
      notifies :run, "execute[Allocate SBD slot]", :immediately
      notifies :restart, "service[#{node[:corosync][:platform][:service_name]}]", :immediately
      # After restarting corosync, we need to wait for the cluster to be online again
      notifies :create, "ruby_block[wait for cluster to be online]", :immediately
    end
  end

  pacemaker_primitive "stonith-sbd" do
    agent "stonith:external/sbd"
    action :create
  end

when "shared"
  agent = node[:pacemaker][:stonith][:shared][:agent]
  params = node[:pacemaker][:stonith][:shared][:params]

  # This needs to be done in the second phase of chef, because we need
  # cluster-glue to be installed first; hence ruby_block
  ruby_block "Check if STONITH fencing agent #{agent} is available" do
    block do
      PacemakerStonithHelper.assert_stonith_agent_valid agent
    end
  end

  if params.respond_to?('to_hash')
    primitive_params = params.to_hash
  elsif params.is_a?(String)
    primitive_params = ::Pacemaker::Resource.extract_hash(" params #{params}", "params")
  else
    message = "Unknown format for shared fencing agent parameters: #{params.inspect}."
    Chef::Log.fatal(message)
    raise message
  end

  unless primitive_params.has_key?("hostlist")
    message = "Missing hostlist parameter for shared fencing agent!"
    Chef::Log.fatal(message)
    raise message
  end

  pacemaker_primitive "stonith-shared" do
    agent "stonith:#{agent}"
    params primitive_params
    action :create
  end

when "per_node"
  agent = node[:pacemaker][:stonith][:per_node][:agent]

  # This needs to be done in the second phase of chef, because we need
  # cluster-glue to be installed first; hence ruby_block
  ruby_block "Check if STONITH fencing agent #{agent} is available" do
    block do
      PacemakerStonithHelper.assert_stonith_agent_valid agent
    end
  end

  node[:pacemaker][:stonith][:per_node][:nodes].keys.each do |node_name|
    if node[:pacemaker][:stonith][:per_node][:mode] == "self"
      next unless node_name == node[:hostname]
    end

    stonith_resource = "stonith-#{node_name}"
    params = node[:pacemaker][:stonith][:per_node][:nodes][node_name][:params]

    if params.respond_to?('to_hash')
      primitive_params = params.to_hash
    elsif params.is_a?(String)
      primitive_params = ::Pacemaker::Resource.extract_hash(" params #{params}", "params")
    else
      message = "Unknown format for per-node fencing agent parameters of #{node_name}: #{params.inspect}."
      Chef::Log.fatal(message)
      raise message
    end

    # Only set one of hostname / hostlist param if none of them are present; we
    # do not overwrite it as the user might have passed more information than
    # just the hostname (some agents accept hostname:data in hostlist)
    unless primitive_params.has_key?("hostname") || primitive_params.has_key?("hostlist")
      primitive_params["hostname"] = node_name
    end

    pacemaker_primitive stonith_resource do
      agent "stonith:#{agent}"
      params primitive_params
      action :create
    end

    pacemaker_location "l-#{stonith_resource}" do
      rsc stonith_resource
      score "-inf"
      node node_name
      action :create
    end
  end

else
  message = "Unknown STONITH mode: #{node[:pacemaker][:stonith][:mode]}."
  Chef::Log.fatal(message)
  raise message
end
