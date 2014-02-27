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

# required to run hb_gui
if platform_family? "suse"
  cmd = "SuSEconfig --module gtk2"
  execute cmd do
    user "root"
    command cmd
    not_if { File.exists? "/etc/gtk-2.0/gdk-pixbuf64.loaders" }
  end
end

if Chef::Config[:solo]
  ::Chef::Log.warn "Using Chef Solo, you are expected to manually include the corosync default recipe!"
else
  include_recipe "corosync::default"
end

if node[:pacemaker][:founder]
  include_recipe "pacemaker::setup"
end
