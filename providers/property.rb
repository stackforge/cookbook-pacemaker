# Author:: Robert Choi
# Cookbook Name:: pacemaker
# Provider:: property
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

this_dir = ::File.dirname(__FILE__)
require ::File.expand_path('../libraries/pacemaker/cib_object', this_dir)

action :create do
  name = new_resource.name
  val = new_resource.value

  unless resource_exists?(name)
    cmd = "crm configure property #{name}=#{val}"

    cmd_ = Mixlib::ShellOut.new(cmd)
    cmd_.environment['HOME'] = ENV.fetch('HOME', '/root')
    cmd_.run_command
    begin
      cmd_.error!
      if resource_exists?(name)
        new_resource.updated_by_last_action(true)
        Chef::Log.info "Successfully configured property '#{name}'."
      else
        Chef::Log.error "Failed to configure property #{name}."
      end
    rescue
      Chef::Log.error "Failed to configure property #{name}."
    end
  end
end
