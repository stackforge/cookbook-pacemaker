#
# Author:: Vincent Untz
# Cookbook Name:: pacemaker
# Recipe:: notifications
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

smtp_resource = "smtp-notifications"
clone_smtp_resource = "cl-#{smtp_resource}"

if node[:pacemaker][:notifications][:smtp][:enabled]
  raise "No SMTP server for mail notifications!" if node[:pacemaker][:notifications][:smtp][:server].empty?
  raise "No sender address for mail notifications!" if node[:pacemaker][:notifications][:smtp][:to].empty?
  raise "No recipient address for mail notifications!" if node[:pacemaker][:notifications][:smtp][:from].empty?

  require 'shellwords'

  server = Shellwords.shellescape(node[:pacemaker][:notifications][:smtp][:server])
  to = Shellwords.shellescape(node[:pacemaker][:notifications][:smtp][:to])
  from = Shellwords.shellescape(node[:pacemaker][:notifications][:smtp][:from])

  options = "-H #{server}"
  options += " -T #{to}"
  options += " -F #{from}"

  unless node[:pacemaker][:notifications][:smtp][:prefix].nil? || node[:pacemaker][:notifications][:smtp][:prefix].empty?
    prefix = Shellwords.shellescape(node[:pacemaker][:notifications][:smtp][:prefix])
    options += " -P #{prefix}"
  end

  pacemaker_primitive smtp_resource do
    agent node[:pacemaker][:notifications][:agent]
    params ({ "extra_options" => options })
    action :create
  end

  pacemaker_clone clone_smtp_resource do
    rsc smtp_resource
    action [:create, :start]
  end
else
  pacemaker_clone clone_smtp_resource do
    rsc smtp_resource
    action [:stop, :delete]
    only_if "crm configure show #{clone_smtp_resource}"
  end

  pacemaker_primitive smtp_resource do
    agent node[:pacemaker][:notifications][:agent]
    action [:stop, :delete]
    only_if "crm configure show #{smtp_resource}"
  end
end
