#
# Author:: Robert Choi
# Cookbook Name:: pacemaker
# Recipe:: default
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

node[:pacemaker][:platform][:packages].each do |pkg|
  package pkg
end

if node[:pacemaker][:setup_hb_gui]
  node[:pacemaker][:platform][:graphical_packages].each do |pkg|
    package pkg
  end

  # required to run hb_gui
  if platform_family? "suse"
    cmd = "SuSEconfig --module gtk2"
    execute cmd do
      user "root"
      command cmd
      not_if { File.exists? "/etc/gtk-2.0/gdk-pixbuf64.loaders" }
    end
  end
end

if Chef::Config[:solo]
  unless ENV['RSPEC_RUNNING']
    Chef::Application.fatal! \
      "pacemaker::default needs corosync::default which uses search, " \
      "but Chef Solo does not support search."
    return
  end
else
  include_recipe "corosync::default"
end

ruby_block "wait for cluster to be online" do
  block do
    require 'timeout'
    begin
      Timeout.timeout(60) do
        cmd = "crm_mon -1 | grep -qi online"
        while ! ::Kernel.system(cmd)
          Chef::Log.debug("cluster not online yet")
          sleep(5)
        end
      end
    rescue Timeout::Error
      message = "Pacemaker cluster not online yet; our first configuration changes might get lost (but will be reapplied on next chef run)."
      Chef::Log.warn(message)
    end
  end # block
end # ruby_block

if node[:pacemaker][:founder]
  include_recipe "pacemaker::setup"
end

if platform_family? "rhel"
  execute "sleep 2"

  service "pacemaker" do
    action [ :enable, :start ]
    notifies :restart, "service[clvm]", :immediately
  end
end

include_recipe "pacemaker::stonith"
include_recipe "pacemaker::notifications"
