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

# FIXME: delete old resources when switching mode (or plugin!)

case node[:pacemaker][:stonith][:mode]
when "disabled"
when "manual"
  # nothing!

when "clone"
  plugin = node[:pacemaker][:stonith][:clone][:plugin]
  params = node[:pacemaker][:stonith][:clone][:params]

  # This needs to be done in the second phase of chef, because we need
  # cluster-glue to be installed first; hence ruby_block
  ruby_block "Check if STONITH #{plugin} is available" do
    block do
      PacemakerStonithHelper.assert_stonith_plugin_valid plugin
    end
  end

  if params.respond_to?('to_hash')
    primitive_params = params.to_hash
  elsif params.is_a?(String)
    primitive_params = ::Pacemaker::Resource.extract_hash("params #{params}", "params")
  else
    message = "Unknown format for STONITH clone parameters: #{params.inspect}."
    Chef::Log.fatal(message)
    raise message
  end

  unless primitive_params.has_key?("hostlist")
    message = "Missing hostlist parameter for STONITH clone!"
    Chef::Log.fatal(message)
    raise message
  end

  pacemaker_primitive "stonith-clone" do
    agent "stonith:#{plugin}"
    params primitive_params
    action :create
  end

  pacemaker_clone "fencing" do
    rsc "stonith-clone"
    action :create
  end

when "per_node"
  plugin = node[:pacemaker][:stonith][:per_node][:plugin]

  # This needs to be done in the second phase of chef, because we need
  # cluster-glue to be installed first; hence ruby_block
  ruby_block "Check if STONITH #{plugin} is available" do
    block do
      PacemakerStonithHelper.assert_stonith_plugin_valid plugin
    end
  end

  node[:pacemaker][:stonith][:per_node][:nodes].keys.each do |node_name|
    stonith_resource = "stonith-#{node_name}"
    params = node[:pacemaker][:stonith][:per_node][:nodes][node_name][:params]

    if params.respond_to?('to_hash')
      primitive_params = params.to_hash
    elsif params.is_a?(String)
      primitive_params = ::Pacemaker::Resource.extract_hash("params #{params}", "params")
    else
      message = "Unknown format for STONITH per-node parameters of #{node_name}: #{params.inspect}."
      Chef::Log.fatal(message)
      raise message
    end

    # Only set hostlist param if it's missing; we do not overwrite it as the
    # user might have passed more information than just the hostname (some
    # plugins accept hostname:data in hostlist)
    unless primitive_params.has_key?("hostlist")
      primitive_params["hostlist"] = node_name
    end

    pacemaker_primitive stonith_resource do
      agent "stonith:#{plugin}"
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
