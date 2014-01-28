require 'mixlib/shellout'

module Pacemaker
  class ObjectTypeMismatch < StandardError
  end

  class CIBObject
    attr_accessor :name, :definition

    @@subclasses = { }

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

      def type(definition)
        unless definition =~ /\A(\w+)\s/
          raise "Couldn't extract CIB object type from '#{definition}'"
        end
        return $1
      end

      def from_name(name)
        definition = get_definition(name)
        return nil unless definition
        obj_type = type(definition)
        subclass = @@subclasses[obj_type]
        unless subclass
          raise "No subclass of #{self.name} was registered with type '#{obj_type}'"
        end
        obj = subclass.from_definition(definition)
        unless name == obj.name
          raise "Name '#{obj.name}' in definition didn't match name '#{name}' used for retrieval"
        end
        obj
      end

      def from_definition(definition)
        obj = new(name)
        obj.definition = definition
        obj.parse_definition
        obj
      end
    end

    def initialize(name)
      @name = name
      @definition = nil
    end

    def load_definition
      @definition = self.class.get_definition(name)

      if @definition and ! @definition.empty? and type != self.class.object_type
        raise ObjectTypeMismatch, "Expected #{self.class.object_type} type but loaded definition was type #{type}"
      end
    end

    def parse_definition
      raise NotImplementedError, "#{self.class} must implement #parse_definition"
    end

    def exists?
      !! (definition && ! definition.empty?)
    end

    def type
      self.class.type(definition)
    end

    def delete_command
      "crm configure delete '#{name}'"
    end
  end
end
