# Cookbook Name:: pacemaker
# Provider:: group
#
# Copyright:: 2014, SUSE
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

this_dir = ::File.dirname(__FILE__)
require ::File.expand_path('../libraries/pacemaker', this_dir)
require ::File.expand_path('../libraries/chef/mixin/pacemaker', this_dir)

include Chef::Mixin::Pacemaker::RunnableResource

action :create do
  standard_create_action
end

action :delete do
  delete_runnable_resource
end

action :start do
  start_runnable_resource
end

action :stop do
  stop_runnable_resource
end

def cib_object_class
  ::Pacemaker::Resource::Group
end

def load_current_resource
  standard_load_current_resource
end

def init_current_resource
  name = @new_resource.name
  @current_resource = Chef::Resource::PacemakerGroup.new(name)
  @current_cib_object.copy_attrs_to_chef_resource(@current_resource, :members)
end

def create_resource(name)
  standard_create_resource
end

def maybe_modify_resource(name)
  Chef::Log.info "Checking existing #{@current_cib_object} for modifications"

  desired_group = cib_object_class.from_chef_resource(new_resource)
  if desired_group.definition_string != @current_cib_object.definition_string
    Chef::Log.debug "changed from [#{@current_cib_object.definition_string}] to [#{desired_group.definition_string}]"
    cmd = desired_group.reconfigure_command
    execute cmd do
      action :nothing
    end.run_action(:run)
    new_resource.updated_by_last_action(true)
  end
end
