require 'shellwords'

module Chef::Libraries
  module Pacemaker
    module CIBObjects
      include Chef::Mixin::ShellOut

      def get_cib_object_definition(name)
        cmd = Mixlib::ShellOut.new("crm configure show #{name}")
        cmd.environment['HOME'] = ENV.fetch('HOME', '/root')
        cmd.run_command
        begin
          cmd.error!
          cmd.stdout
        rescue
          nil
        end
      end

      def cib_object_exists?(name)
        dfn = get_cib_object_definition(name)
        !! (dfn && ! dfn.empty?)
      end

      def cib_object_type(obj_definition)
        unless obj_definition =~ /\A(\w+)\s/
          raise "Couldn't extract CIB object type from '#{obj_definition}'"
        end
        return $1
      end

      def pacemaker_resource_running?(name)
        cmd = shell_out! "crm", "resource", "status", name
        Chef::Log.info cmd.stdout
        cmd.stdout.include? "resource #{name} is running"
      end

      def resource_params_string(params)
        return "" if ! params or params.empty?
        s = " params"
        params.sort.each do |key, value|
          s << %' #{key}="#{value}"'
        end
        s
      end

      def resource_meta_string(meta)
        return "" if ! meta or meta.empty?
        s = " meta"
        meta.sort.each do |key, value|
          s << %' #{key}="#{value}"'
        end
        s
      end

      def resource_op_string(ops)
        return "" if ! ops or ops.empty?
        s = " op"
        ops.sort.each do |op, attrs|
          s << " #{op}"
          attrs.sort.each do |key, value|
            s << %' #{key}="#{value}"'
          end
        end
        s
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
      def extract_hash(name, obj_definition, data_type)
        unless obj_definition =~ /^\s+#{data_type} (.+?)(\s*\\)?$/
          raise "Couldn't retrieve #{data_type} for '#{name}' CIB object from [#{obj_definition}]"
        end

        h = {}
        Shellwords.split($1).each do |kvpair|
          unless kvpair =~ /^(.+?)=(.+)$/
            raise "Couldn't understand '#{kvpair}' for #{data_type} section of '#{name}' primitive"
          end
          h[$1] = $2.sub(/^"(.*)"$/, "\1")
        end
        h
      end

    end
  end
end
