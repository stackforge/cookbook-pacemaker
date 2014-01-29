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

require ::File.join(::File.dirname(__FILE__), *%w(.. libraries pacemaker))

# For vagrant env, switch to the following 'require' command.
#require "/srv/chef/file_store/cookbooks/pacemaker/providers/helper"

action :create do
  name = new_resource.name

  if @current_resource_definition.nil?
    create_resource(name)
  else
    if @current_resource.agent != new_resource.agent
      raise "Existing resource primitive '%s' has agent '%s' " \
            "but recipe wanted '%s'" % \
            [ name, @current_resource.agent, new_resource.agent ]
    end

    modify_resource(name)
  end
end

action :delete do
  name = new_resource.name
  next unless @current_resource
  rsc = Pacemaker::Resource::Primitive.new(name)
  if rsc.running?
    raise "Cannot delete running resource primitive #{name}"
  end
  execute rsc.delete_command do
    action :nothing
  end.run_action(:run)
  new_resource.updated_by_last_action(true)
  Chef::Log.info "Deleted primitive '#{name}'."
end

action :start do
  name = new_resource.name
  unless @current_resource
    raise "Cannot start non-existent resource primitive '#{name}'"
  end
  rsc = Pacemaker::Resource::Primitive.new(name)
  next if rsc.running?
  execute rsc.start_command do
    action :nothing
  end.run_action(:run)
  new_resource.updated_by_last_action(true)
  Chef::Log.info "Successfully started primitive '#{name}'."
end

action :stop do
  name = new_resource.name
  unless @current_resource
    raise "Cannot stop non-existent resource primitive '#{name}'"
  end
  rsc = Pacemaker::Resource::Primitive.new(name)
  next unless rsc.running?
  execute rsc.stop_command do
    action :nothing
  end.run_action(:run)
  new_resource.updated_by_last_action(true)
  Chef::Log.info "Successfully stopped primitive '#{name}'."
end

# Instantiate @current_resource and read details about the existing
# primitive (if any) via "crm configure show" into it, so that we
# can compare it against the resource requested by the recipe, and
# create / delete / modify as necessary.

# http://docs.opscode.com/lwrp_custom_provider_ruby.html#load-current-resource
def load_current_resource
  name = @new_resource.name

  primitive = Pacemaker::CIBObject.from_name(name)
  unless primitive
    Chef::Log.debug "CIB object definition nil or empty"
    return
  end

  unless primitive.is_a? Pacemaker::Resource::Primitive
    Chef::Log.warn "CIB object '#{name}' was a #{primitive.type} not a resource primitive"
    return
  end

  Chef::Log.debug "CIB object definition #{primitive.definition}"
  @current_resource_definition = primitive.definition
  primitive.parse_definition

  @current_primitive = primitive
  @current_resource = Chef::Resource::PacemakerPrimitive.new(name)
  @current_resource.agent(primitive.agent)
  %w(params meta).each do |data_type|
    method = data_type.to_sym
    value = primitive.send(method)
    @current_resource.send(method, value)
    Chef::Log.debug "detected #{name} has #{data_type} #{value}"
  end
end

def create_resource(name)
  primitive = Pacemaker::Resource::Primitive.from_chef_resource(new_resource)
  cmd = primitive.crm_configure_command

  Chef::Log.info "Creating new resource primitive #{name}"

  execute cmd do
    action :nothing
  end.run_action(:run)

  if primitive.exists?
    new_resource.updated_by_last_action(true)
    Chef::Log.info "Successfully configured primitive '#{name}'."
  else
    Chef::Log.error "Failed to configure primitive #{name}."
  end
end

def modify_resource(name)
  Chef::Log.info "Checking existing resource primitive #{name} for modifications"

  cmds = []
  modify_params(name, cmds, :params)
  modify_params(name, cmds, :meta)

  cmds.each do |cmd|
    execute cmd do
      action :nothing
    end.run_action(:run)
  end

  new_resource.updated_by_last_action(true) unless cmds.empty?
end

def modify_params(name, cmds, data_type)
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
