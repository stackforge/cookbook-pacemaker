#
# Author:: Matt Ray (<matt@opscode.com>)
# Cookbook Name:: pacemaker
# Provider:: service
#
# Copyright:: 2011, Opscode, Inc
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

# actions :create, :remove

# attribute :service, :kind_of => String, :name_attribute => true
# attribute :vip, :kind_of => String
# attribute :active, :default => false
# attribute :path, :kind_of => String

action :create do
  service = new_resource.service
  vip = new_resource.vip
  active = new_resource.active
  path = new_resource.path
  Chef::Log.info "pacemaker_service #{service} #{vip} #{active} #{path}"
  oldservice = node['pacemaker']['services'][service]
  newservice = {}
  newservice['vip'] = vip
  if active
    newservice['active'] = node.name
  else
    #search for active?
    #newservice['active'] =
    if oldservice
      newservice['active'] = oldservice['active']
      newservice['passive'] = oldservice['passive']
      newservice['passive'].push(node.name)
      newservice['passive'].uniq!.sort!
    else
      newservice['passive'] = [node.name]
    end
  end
  #compare with previous state
  if newservice != oldservice
    #put the service into the attributes of the node
    node['pacemaker']['services'][service] = newservice
    #figure out how pacemaker handles services
    new_resource.updated_by_last_action(true)
  end
end

action :remove do
  service = new_resource.service
  if node['pacemaker']['services'][service]
    #remove the parameters into the attributes of the node
    node['pacemaker']['services'].delete(service)
    #figure out how to restore services from pacemaker control
    new_resource.updated_by_last_action(true)
  end
end
