# Author:: Robert Choi
# Cookbook Name:: pacemaker
# Provider:: primitive
#
# Copyright:: 2013, Robert Choi
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

require ::File.expand_path('../libraries/pacemaker', ::File.dirname(__FILE__))
require ::File.expand_path('../libraries/chef/mixin/pacemaker',
                           ::File.dirname(__FILE__))

include Chef::Mixin::Pacemaker::StandardCIBObject

action :create do
  name = new_resource.name

  if @current_resource_definition.nil?
    create_resource(name)
  else
    if @current_resource.agent != new_resource.agent
      raise "Existing %s has agent '%s' " \
            "but recipe wanted '%s'" % \
            [ @current_cib_object, @current_resource.agent, new_resource.agent ]
    end

    maybe_modify_resource(name)
  end
end

action :delete do
  name = new_resource.name
  next unless @current_resource
  rsc = cib_object_class.new(name)
  if rsc.running?
    raise "Cannot delete running #{@current_cib_object}"
  end
  execute rsc.delete_command do
    action :nothing
  end.run_action(:run)
  new_resource.updated_by_last_action(true)
  Chef::Log.info "Deleted #{@current_cib_object}"
end

action :start do
  name = new_resource.name
  unless @current_resource
    raise "Cannot start non-existent #{cib_object_class.description} '#{name}'"
  end
  rsc = cib_object_class.new(name)
  next if rsc.running?
  execute rsc.start_command do
    action :nothing
  end.run_action(:run)
  new_resource.updated_by_last_action(true)
  Chef::Log.info "Successfully started #{@current_cib_object}"
end

action :stop do
  name = new_resource.name
  unless @current_resource
    raise "Cannot stop non-existent #{cib_object_class.description} '#{name}'"
  end
  rsc = cib_object_class.new(name)
  next unless rsc.running?
  execute rsc.stop_command do
    action :nothing
  end.run_action(:run)
  new_resource.updated_by_last_action(true)
  Chef::Log.info "Successfully stopped #{@current_cib_object}"
end

def cib_object_class
  ::Pacemaker::Resource::Primitive
end

def load_current_resource
  standard_load_current_resource
end

def init_current_resource
  name = @new_resource.name
  @current_resource = Chef::Resource::PacemakerPrimitive.new(name)
  @current_cib_object.copy_attrs_to_chef_resource(@current_resource,
                                                  :agent, :params, :meta)
end

def create_resource(name)
  standard_create_resource
end

def maybe_modify_resource(name)
  Chef::Log.info "Checking existing #{@current_cib_object} for modifications"

  cmds = []

  desired_primitive = cib_object_class.from_chef_resource(new_resource)
  if desired_primitive.op_string != @current_cib_object.op_string
    Chef::Log.debug "op changed from [#{@current_cib_object.op_string}] to [#{desired_primitive.op_string}]"
    cmds = [desired_primitive.reconfigure_command]
  else
    maybe_configure_params(name, cmds, :params)
    maybe_configure_params(name, cmds, :meta)
  end

  cmds.each do |cmd|
    execute cmd do
      action :nothing
    end.run_action(:run)
  end

  new_resource.updated_by_last_action(true) unless cmds.empty?
end

def maybe_configure_params(name, cmds, data_type)
  configure_cmd_prefix = "crm_resource --resource #{name}"

  new_resource.send(data_type).each do |param, new_value|
    current_value = @current_resource.send(data_type)[param]
    # Value from recipe might be a TrueClass instance, but the same
    # value would be retrieved from the cluster resource as the String
    # "true".  So we force a string-wise comparison to adhere to
    # Postel's Law whilst minimising activity on the Chef client node.
    if current_value.to_s == new_value.to_s
      Chef::Log.info("#{name}'s #{param} #{data_type} didn't change")
    else
      Chef::Log.info("#{name}'s #{param} #{data_type} changed from #{current_value} to #{new_value}")
      cmd = configure_cmd_prefix + %' --set-parameter "#{param}" --parameter-value "#{new_value}"'
      cmd += " --meta" if data_type == :meta
      cmds << cmd
    end
  end

  @current_resource.send(data_type).each do |param, value|
    unless new_resource.send(data_type).has_key? param
      Chef::Log.info("#{name}'s #{param} #{data_type} was removed")
      cmd = configure_cmd_prefix + %' --delete-parameter "#{param}"'
      cmd += " --meta" if data_type == :meta
      cmds << cmd
    end
  end
end
