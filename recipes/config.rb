#
# Author:: Robert Choi
# Cookbook Name:: pacemaker
# Recipe:: config
#
# Copyright 2013, Robert Choi
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

include_recipe "pacemaker::setup"

directory "/usr/lib/ocf/resource.d/openstack" do
  owner "root"
  group "root"
  mode 0755
  action :create
  notifies :create, "cookbook_file[/usr/lib/ocf/resource.d/openstack/cinder-volume]", :immediately
end

cookbook_file "/usr/lib/ocf/resource.d/openstack/cinder-volume" do
  source "cinder-volume"
  owner "root"
  group "root"
  mode 0755
  action :nothing
end

# Get cinder-volume's myip which might have been set by 'ktc-cinder' cookbook.
if node['pacemaker']['primitive'].include?('vip') and node['cinder'] and node['cinder']['services']['volume']['myip']
  node.default['pacemaker']['primitive']['vip']['params']['ip'] = node['cinder']['services']['volume']['myip']
end

node['pacemaker']['primitive'].each do |name, attr|
  pacemaker_primitive name do
    agent attr['agent']
    params attr['params']
    meta attr['meta']
    op attr['op']
    action :create
    only_if { attr['active'].include?(node.name.partition(".")[0]) }
  end
end

node['pacemaker']['location'].each do |name, attr|
  pacemaker_location name do
    rsc attr['rsc_name']
    priority attr['priority']
    loc attr['loc']
    action :create
    only_if { attr['active'].include?(node.name.partition(".")[0]) }
  end
end

node['pacemaker']['ms'].each do |name, attr|
  pacemaker_ms name do
    rsc attr['rsc_name']
    meta attr['meta']
    action :create
    only_if { attr['active'].include?(node.name.partition(".")[0]) }
  end
end

node['pacemaker']['clone'].each do |name, attr|
  pacemaker_clone name do
    rsc attr['rsc_name']
    meta attr['meta']
    action :create
    only_if { attr['active'].include?(node.name.partition(".")[0]) }
  end
end

node['pacemaker']['colocation'].each do |name, attr|
  pacemaker_colocation name do
    priority attr['priority']
    multiple attr['is_multiple']
    rsc attr['rsc']
    with_rsc attr['with_rsc']
    multiple_rscs attr['multiple_rscs']
    action :create
    only_if { attr['active'].include?(node.name.partition(".")[0]) }
  end
end

node['pacemaker']['order'].each do |name, attr|
  pacemaker_order name do
    priority attr['priority']
    resources attr['resources']
    action :create
    only_if { attr['active'].include?(node.name.partition(".")[0]) }
  end
end

node['pacemaker']['property'].each do |name, val|
  pacemaker_property name do
    value val
    action :create
  end
end
