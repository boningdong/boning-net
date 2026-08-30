# frozen_string_literal: true

require_relative "errors"

module BoningNet
  module ProjectDetail
    class ComponentRegistry
      def initialize
        @components = {}
      end

      def register(component_class)
        type = component_class.type
        if @components.key?(type)
          raise ConfigurationError, %(duplicate directive registration "#{type}")
        end

        @components[type] = component_class
        self
      end

      def fetch(type, source_path:, line:)
        @components.fetch(type) do
          raise ConfigurationError, %(#{source_path}:#{line}: unknown directive "#{type}")
        end
      end

      def types
        @components.keys.freeze
      end
    end
  end
end
