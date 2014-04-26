require 'chef/mixin/shell_out'
require File.expand_path('cib_object', File.dirname(__FILE__))

module Pacemaker
  class Resource < Pacemaker::CIBObject
    include Chef::Mixin::ShellOut

    def self.description
      type = self.to_s.split('::').last.downcase
      "#{type} resource"
    end

    def running?
      cmd = shell_out! "crm", "resource", "status", name
      Chef::Log.info cmd.stdout
      !! cmd.stdout.include?("resource #{name} is running")
    end

    def crm_start_command
      "crm --force resource start '#{name}'"
    end

    def crm_stop_command
      "crm --force resource stop '#{name}'"
    end

    # CIB object definitions look something like:
    #
    # primitive keystone ocf:openstack:keystone \
    #         params os_username="crowbar" os_password="crowbar" os_tenant_name="openstack" \
    #         meta target-role="Started" is-managed="true" \
    #         op monitor interval="10" timeout=30s \
    #         op start interval="10s" timeout="240" \
    #
    # This method extracts a Hash from one of the params / meta / op lines.
    def self.extract_hash(obj_definition, data_type)
      unless obj_definition =~ /\s+#{data_type} (.+?)\s*\\?$/
        return {}
      end

      h = {}
      Shellwords.split($1).each do |kvpair|
        break if kvpair == 'op'
        unless kvpair =~ /^(.+?)=(.*)$/
          raise "Couldn't understand '#{kvpair}' for '#{data_type}' section "\
            "of #{name} primitive (definition was [#{obj_definition}])"
        end
        h[$1] = $2.sub(/^"(.*)"$/, "\1")
      end
      h
    end
  end
end
