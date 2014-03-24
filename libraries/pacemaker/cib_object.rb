require 'mixlib/shellout'

module Pacemaker
  class CIBObject
    attr_accessor :name, :definition

    @@subclasses = { } unless class_variable_defined?(:@@subclasses)

    class << self
      attr_reader :object_type

      def register_type(type_name)
        @object_type = type_name
        @@subclasses[type_name] = self
      end

      def get_definition(name)
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

      def definition_type(definition)
        unless definition =~ /\A(\w+)\s/
          raise "Couldn't extract CIB object type from '#{definition}'"
        end
        return $1
      end

      def from_name(name)
        definition = get_definition(name)
        return nil unless definition and ! definition.empty?
        from_definition(definition)
      end

      # Make sure this works on Ruby 1.8.7 which is missing
      # Object#singleton_class.
      def singleton_class
        class << self; self; end
      end

      def from_definition(definition)
        calling_class = self.singleton_class
        this_class = method(__method__).owner
        if calling_class == this_class
          # Invoked via (this) base class
          obj_type = definition_type(definition)
          subclass = @@subclasses[obj_type]
          unless subclass
            raise "No subclass of #{self.name} was registered with type '#{obj_type}'"
          end
          return subclass.from_definition(definition)
        else
          # Invoked via subclass
          obj = new(name)
          unless name == obj.name
            raise "Name '#{obj.name}' in definition didn't match name '#{name}' used for retrieval"
          end
          obj.definition = definition
          obj.parse_definition
          obj
        end
      end

      def from_chef_resource(resource)
        new(resource.name).copy_attrs_from_chef_resource(resource,
                                                         *attrs_to_copy_from_chef)
      end

      def attrs_to_copy_from_chef
        raise NotImplementedError, "#{self.class} didn't implement attrs_to_copy_from_chef"
      end
    end

    def initialize(name)
      @name = name
      @definition = nil
    end

    def copy_attrs_from_chef_resource(resource, *attrs)
      attrs.each do |attr|
        value = resource.send(attr.to_sym)
        writer = (attr + '=').to_sym
        send(writer, value)
      end
      self
    end

    def copy_attrs_to_chef_resource(resource, *attrs)
      attrs.each do |attr|
        value = send(attr.to_sym)
        writer = attr.to_sym
        resource.send(writer, value)
      end
    end

    def load_definition
      @definition = self.class.get_definition(name)

      if @definition and ! @definition.empty? and type != self.class.object_type
        raise CIBObject::TypeMismatch, \
          "Expected #{self.class.object_type} type but loaded definition was type #{type}"
      end
    end

    def parse_definition
      raise NotImplementedError, "#{self.class} must implement #parse_definition"
    end

    def exists?
      !! (definition && ! definition.empty?)
    end

    def type
      self.class.definition_type(definition)
    end

    def to_s
      "%s '%s'" % [self.class.description, name]
    end

    def definition_indent
      ' ' * 9
    end

    def continuation_line(text)
      " \\\n#{definition_indent}#{text}"
    end

    # Returns a single-quoted shell-escaped version of the definition
    # string, suitable for use in a command like:
    #
    #     echo '...' | crm configure load update -
    def quoted_definition_string
      "'%s'" % \
      definition_string \
        .gsub('\\') { '\\\\' } \
        .gsub("'")  { "\\'" }
    end

    def configure_command
      "crm configure " + definition_string
    end

    def reconfigure_command
      "echo #{quoted_definition_string} | crm configure load update -"
    end

    def delete_command
      "crm configure delete '#{name}'"
    end
  end

  class CIBObject::DefinitionParseError < StandardError
  end

  class CIBObject::TypeMismatch < StandardError
  end
end
