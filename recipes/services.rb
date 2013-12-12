#
# Author:: Matt Ray (<matt@opscode.com>)
# Cookbook Name:: pacemaker
# Recipe:: services
#
# Copyright 2011, Opscode, Inc.
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

node['pacemaker']['services'].keys.each do |svc|
  Chef::Log.debug "Pacemaker::services #{svc}"
  Chef::Log.debug node['pacemaker']['services'][svc]
  isactive = false
  if node['pacemaker']['services'][svc]['active'].eql?(node.name)
    isactive = true
  end
  pacemaker_service svc do
    vip node['pacemaker']['services'][svc]['vip']
    active isactive
    path node['pacemaker']['services'][svc]['path']
    action :create
  end
end
