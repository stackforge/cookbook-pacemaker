# Copyright 2011, Dell, Inc.
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

case node.platform
when 'suse'
  default[:pacemaker][:platform][:packages] = %w(pacemaker)

  # pacemaker-mgmt-client provides hb_gui, which it's useful
  # to run over ssh.
  default[:pacemaker][:platform][:packages] += %w(
    pacemaker-mgmt-client xorg-x11-xauth
  )
else
  Chef::Application.fatal! "FIXME: #{node.platform} platform not supported yet"
  return
end

default[:pacemaker][:crm][:initial_config_file] = "/etc/corosync/crm-initial.conf"


default['pacemaker']['primitive']['cinder-volume']['agent'] = "ocf:openstack:cinder-volume"
default['pacemaker']['primitive']['cinder-volume']['meta']['is-managed'] = "true"
default['pacemaker']['primitive']['cinder-volume']['meta']['target-role'] = "Started"
default['pacemaker']['primitive']['cinder-volume']['op']['monitor']['interval'] = "10s"

default['pacemaker']['primitive']['clvm']['agent'] = "ocf:lvm2:clvmd"
default['pacemaker']['primitive']['clvm']['params']['daemon_timeout'] = "30"
default['pacemaker']['primitive']['clvm']['op']['monitor']['interval'] = "5s"
default['pacemaker']['primitive']['clvm']['op']['monitor']['on-fail'] = "restart"

# Vip address might be replaced by cinder-volume's myip specified in the environment.
default['pacemaker']['primitive']['vip']['agent'] = "ocf:heartbeat:IPaddr2"
default['pacemaker']['primitive']['vip']['params']['ip'] = "10.5.2.200"
default['pacemaker']['primitive']['vip']['params']['cidr_netmask'] = "24"
default['pacemaker']['primitive']['vip']['op']['monitor']['interval'] = "3s"
default['pacemaker']['primitive']['vip']['op']['monitor']['nic'] = "eth0"
default['pacemaker']['primitive']['vip']['meta']['target-role'] = "Started"

default['pacemaker']['location']['l-st-node1']['rsc_name'] = "st-node1"
default['pacemaker']['location']['l-st-node1']['priority'] = "-inf"

default['pacemaker']['location']['l-st-node2']['rsc_name'] = "st-node2"
default['pacemaker']['location']['l-st-node2']['priority'] = "-inf"

default['pacemaker']['clone']['clvm-clone']['rsc_name'] = "clvm"
default['pacemaker']['clone']['clvm-clone']['meta']['globally-unique'] = "false"
default['pacemaker']['clone']['clvm-clone']['meta']['interleave'] = "true"
default['pacemaker']['clone']['clvm-clone']['meta']['ordered'] = "true"

default['pacemaker']['colocation']['c-cinder-volume']['priority'] = "inf"
default['pacemaker']['colocation']['c-cinder-volume']['is_multiple'] = "yes"

# Single colocation (if multiple is 'no')
default['pacemaker']['colocation']['c-cinder-volume']['rsc'] = nil
default['pacemaker']['colocation']['c-cinder-volume']['with_rsc'] = nil

# Multiple colocation (if multiple is 'yes')
default['pacemaker']['colocation']['c-cinder-volume']['multiple_rscs'] = ['drbd-cluster', 'vip', 'cinder-volume']

default['pacemaker']['order']['o-lvm']['priority'] = "inf"
default['pacemaker']['order']['o-lvm']['resources'] = ['drbd-cluster', 'clvm-clone', 'vip', 'cinder-volume']

default['pacemaker']['property']['no-quorum-policy'] = "ignore"
