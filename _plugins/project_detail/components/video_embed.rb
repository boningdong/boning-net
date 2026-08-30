# frozen_string_literal: true

require "cgi"
require "kramdown"
require "uri"
require_relative "base"
require_relative "markdown_validator"
require_relative "../primitives/caption"

module BoningNet
  module ProjectDetail
    module Components
      class VideoEmbed < Base
        VIDEO_ID = /\A[A-Za-z0-9_-]{11}\z/
        WATCH_HOSTS = %w[youtube.com www.youtube.com].freeze
        SHARE_HOSTS = %w[youtu.be www.youtu.be].freeze
        EMBED_HOSTS = %w[
          youtube.com
          www.youtube.com
          youtube-nocookie.com
          www.youtube-nocookie.com
        ].freeze

        register_as "video-embed"

        def compile(node, context)
          reject_attributes!(node, context)
          document = Kramdown::Document.new(node.body, context.kramdown_options)
          children = document.root.children.reject { |child| child.type == :blank }
          if children.empty?
            context.error!(
              "video-embed must contain standalone Markdown links",
              line: node.start_line
            )
          end
          unless children.all? { |child| standalone_link_paragraph?(child) }
            context.error!(
              "video-embed may contain only standalone Markdown links separated by blank lines",
              line: node.start_line
            )
          end

          MarkdownValidator.validate_safety!(
            document.root,
            component: self.class.type,
            context: context,
            line: node.start_line
          )
          items = children.map { |paragraph| compile_link(paragraph, node, context) }
          { "type" => self.class.type, "items" => items }
        end

        private

        def reject_attributes!(node, context)
          attribute = node.attributes.keys.first
          return unless attribute

          context.error!(
            %(video-embed does not accept attribute "#{attribute}"),
            line: node.start_line
          )
        end

        def standalone_link_paragraph?(paragraph)
          paragraph.type == :p && paragraph.children.length == 1 &&
            paragraph.children.first.type == :a
        end

        def compile_link(paragraph, node, context)
          link = paragraph.children.first
          title = plain_text(link).strip
          if title.empty?
            context.error!(
              "video-embed link text is required for the iframe title",
              line: source_line(paragraph, node)
            )
          end

          item = {
            "embed_url" => normalized_embed_url(link.attr.fetch("href", ""), node, context),
            "title" => title
          }
          caption = link.attr["title"]
          caption = normalized_caption(caption) if caption
          number = context.next_figure_number
          if caption && !caption.empty?
            item["caption"] = Primitives::Caption.new(
              text: caption,
              heading_label: context.current_heading_label,
              number: number
            ).to_h
          end
          item
        end

        def normalized_embed_url(value, node, context)
          uri = URI.parse(value)
          video_id = video_id_from(uri)
          unless video_id&.match?(VIDEO_ID)
            context.error!(
              "video-embed supports only valid YouTube video URLs",
              line: node.start_line
            )
          end

          "https://www.youtube-nocookie.com/embed/#{video_id}"
        rescue URI::InvalidURIError, ArgumentError
          context.error!(
            "video-embed supports only valid YouTube video URLs",
            line: node.start_line
          )
        end

        def normalized_caption(value)
          decoded = value.gsub(/&([A-Za-z][A-Za-z0-9]+);/) do |entity_reference|
            entity = Kramdown::Utils::Entities.entity(Regexp.last_match(1))
            entity.code_point.chr(Encoding::UTF_8)
          rescue Kramdown::Error
            entity_reference
          end

          CGI.unescapeHTML(decoded).gsub(/\A\p{Space}+|\p{Space}+\z/, "")
        end

        def video_id_from(uri)
          return unless %w[http https].include?(uri.scheme&.downcase)
          return if uri.userinfo

          host = uri.host&.downcase
          if WATCH_HOSTS.include?(host) && uri.path == "/watch"
            values = URI.decode_www_form(uri.query.to_s).select { |key, _value| key == "v" }
            return values.first.last if values.length == 1
          end
          if SHARE_HOSTS.include?(host)
            match = uri.path.match(%r{\A/([^/]+)\z})
            return match[1] if match
          end
          if EMBED_HOSTS.include?(host)
            match = uri.path.match(%r{\A/embed/([^/]+)\z})
            return match[1] if match
          end

          nil
        end

        def plain_text(element)
          case element.type
          when :text, :codespan
            element.value.to_s
          when :entity
            element.value.code_point.chr(Encoding::UTF_8)
          when :br
            " "
          when :smart_quote, :typographic_sym
            Kramdown::Utils::Entities.entity(element.value.to_s).code_point.chr(Encoding::UTF_8)
          else
            element.children.map { |child| plain_text(child) }.join
          end
        end

        def source_line(paragraph, node)
          node.start_line + paragraph.options.fetch(:location)
        end
      end
    end
  end
end
