# frozen_string_literal: true

module BoningNet
  module ProjectDetail
    module Primitives
      class Collection
        def initialize(items:, layouts:, overflow_layout:)
          @items = items
          @layouts = layouts
          @overflow_layout = overflow_layout
        end

        def to_h
          {
            "layout" => @layouts.fetch(@items.length, @overflow_layout),
            "items" => @items
          }
        end
      end
    end
  end
end
