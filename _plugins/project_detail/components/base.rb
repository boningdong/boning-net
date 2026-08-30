# frozen_string_literal: true

module BoningNet
  module ProjectDetail
    module Components
      class Base
        class << self
          attr_reader :type

          def register_as(value)
            @type = value.freeze
          end
        end

        def compile(_node, _context)
          raise NotImplementedError, "#{self.class} must implement #compile"
        end
      end
    end
  end
end
