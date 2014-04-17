#
# Author:: Robert Choi
# Cookbook Name:: pacemaker
# Recipe:: setup
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

crm_conf = node[:pacemaker][:crm][:initial_config_file]

template crm_conf do
  source "crm-initial.conf.erb"
  owner "root"
  group "root"
  mode 0600
  variables(
    :stonith_enabled => (node[:pacemaker][:stonith][:mode] != "disabled"),
    :no_quorum_policy => node[:pacemaker][:crm][:no_quorum_policy],
    :op_default_timeout => node[:pacemaker][:crm][:op_default_timeout]
  )
end

execute "crm initial configuration" do
  user "root"
  command "crm configure load replace #{crm_conf}"
  subscribes :run, resources(:template => crm_conf), :immediately
  action :nothing
end
