require 'chef/application'
require ::File.expand_path('standard_cib_object', ::File.dirname(__FILE__))

# Common code used by Pacemaker LWRP providers for resources supporting
# the :run action.

class Chef
  module Mixin::Pacemaker
    module RunnableResource
      include StandardCIBObject

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
