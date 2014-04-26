# A mixin for Pacemaker::Resource subclasses which support meta attributes
# (priority, target-role, is-managed, etc.)

module Pacemaker
  module Mixins
    module Resource
      module Meta
        def self.included(base)
          base.extend ClassMethods
        end

        attr_accessor :meta

        def meta_string
          self.class.meta_string(meta)
        end

        module ClassMethods
          def meta_string(meta)
            return "" if ! meta or meta.empty?
            "meta " +
              meta.sort.map do |key, value|
              %'#{key}="#{value}"'
            end.join(' ')
          end
        end
      end
    end
  end
end
