require ::File.expand_path('standard_cib_object', File.dirname(__FILE__))

# Common code used by Pacemaker LWRP providers for resources supporting
# the :run action.

class Chef
  module Mixin::Pacemaker
    module RunnableResource
      include StandardCIBObject

      def start_runnable_resource
        name = new_resource.name
        unless @current_resource
          raise "Cannot start non-existent #{cib_object_class.description} '#{name}'"
        end
        return if @current_cib_object.running?
        execute @current_cib_object.crm_start_command do
          action :nothing
        end.run_action(:run)
        new_resource.updated_by_last_action(true)
        Chef::Log.info "Successfully started #{@current_cib_object}"
      end

      def stop_runnable_resource
        name = new_resource.name
        unless @current_resource
          raise "Cannot stop non-existent #{cib_object_class.description} '#{name}'"
        end
        return unless @current_cib_object.running?
        execute @current_cib_object.crm_stop_command do
          action :nothing
        end.run_action(:run)
        new_resource.updated_by_last_action(true)
        Chef::Log.info "Successfully stopped #{@current_cib_object}"
      end

      def delete_runnable_resource
        return unless @current_resource
        if @current_cib_object.running?
          raise "Cannot delete running #{@current_cib_object}"
        end
        standard_delete_resource
      end
    end
  end
end
