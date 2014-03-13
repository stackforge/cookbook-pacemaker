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

@stonith_plugins = nil

def stonith_plugin_valid?(plugin)
  if plugin.nil? || plugin.empty?
    false
  else
    if @stonith_plugins.nil?
      out = %x{stonith -L}
      if $?.success?
        @stonith_plugins = out.split("\n")
      end
    end

    !@stonith_plugins.nil? && @stonith_plugins.include?(plugin)
  end
end

case node[:pacemaker][:stonith][:mode]
when "disabled"
when "manual"
  # nothing!

when "clone"
  plugin = node[:pacemaker][:stonith][:clone][:plugin]
  params = node[:pacemaker][:stonith][:clone][:params]

  unless stonith_plugin_valid? plugin
    message = "STONITH plugin #{plugin} is not available!"
    Chef::Log.fatal(message)
    raise message
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

  unless stonith_plugin_valid? plugin
    message = "STONITH plugin #{plugin} is not available!"
    Chef::Log.fatal(message)
    raise message
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
