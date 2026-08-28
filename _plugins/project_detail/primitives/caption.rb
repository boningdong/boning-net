# frozen_string_literal: true

module BoningNet
  module ProjectDetail
    module Primitives
      class Caption
        def initialize(text:, heading_label:, number:)
          @text = text
          @heading_label = heading_label
          @number = number
        end

        def to_h
          {
            "label" => "#{normalized_heading} / #{format("%02d", @number)}",
            "text" => @text
          }
        end

        private

        def normalized_heading
          label = @heading_label.to_s.strip
          label = "Figure" if label.empty?
          label.upcase
        end
      end
    end
  end
end
