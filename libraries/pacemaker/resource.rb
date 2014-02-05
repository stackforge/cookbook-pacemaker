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

    def start_command
      "crm resource start '#{name}'"
    end

    def stop_command
      "crm resource stop '#{name}'"
    end

  end
end
