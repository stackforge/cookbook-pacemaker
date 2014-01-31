require 'chef/application'
require ::File.join(::File.dirname(__FILE__),
                    *%w(.. libraries pacemaker cib_object))

class Chef
  module Mixin::PacemakerCommon
    # Instantiate @current_resource and read details about the existing
    # primitive (if any) via "crm configure show" into it, so that we
    # can compare it against the resource requested by the recipe, and
    # create / delete / modify as necessary.
    #
    # http://docs.opscode.com/lwrp_custom_provider_ruby.html#load-current-resource
    def load_current_resource
      name = @new_resource.name

      cib_object = Pacemaker::CIBObject.from_name(name)
      unless cib_object
        ::Chef::Log.debug "CIB object definition nil or empty"
        return
      end

      unless cib_object.is_a? cib_object_class
        expected_type = cib_object_class.description
        ::Chef::Log.warn "CIB object '#{name}' was a #{cib_object.type} not a #{expected_type}"
        return
      end

      ::Chef::Log.debug "CIB object definition #{cib_object.definition}"
      @current_resource_definition = cib_object.definition
      cib_object.parse_definition

      @current_cib_object = cib_object
      init_current_resource
    end
  end
end
