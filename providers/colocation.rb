# Author:: Robert Choi
# Cookbook Name:: pacemaker
# Provider:: colocation
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
require ::File.join(::File.dirname(__FILE__), 'common')

include Chef::Mixin::PacemakerCommon

action :create do
  name = new_resource.name

  if @current_resource_definition.nil?
    create_resource(name)
  else
    maybe_modify_resource(name)
  end
end

action :delete do
  name = new_resource.name
  next unless @current_resource
  rsc = cib_object_class.new(name)
  execute rsc.delete_command do
    action :nothing
  end.run_action(:run)
  new_resource.updated_by_last_action(true)
  Chef::Log.info "Deleted #{@current_cib_object}'."
end

def cib_object_class
  Pacemaker::Constraint::Colocation
end

def init_current_resource
  name = @new_resource.name
  @current_resource = Chef::Resource::PacemakerColocation.new(name)
  attrs = [:score, :resources]
  @current_cib_object.copy_attrs_to_chef_resource(@current_resource, *attrs)
end

def create_resource(name)
  standard_create_resource
end

def maybe_modify_resource(name)
  Chef::Log.info "Checking existing #{@current_cib_object} for modifications"

  desired_colocation = cib_object_class.from_chef_resource(new_resource)
  if desired_colocation.definition_string != @current_cib_object.definition_string
    Chef::Log.debug "changed from [#{@current_cib_object.definition_string}] to [#{desired_colocation.definition_string}]"
    to_echo = desired_colocation.definition_string.chomp
    to_echo.gsub!('\\') { '\\\\' }
    to_echo.gsub!("'", "\\'")
    cmd = "echo '#{to_echo}' | crm configure load update -"
    execute cmd do
      action :nothing
    end.run_action(:run)
    new_resource.updated_by_last_action(true)
  end
end
