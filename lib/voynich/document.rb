require 'cgi'

module Voynich
  class Document
    attr_reader :blocks

    def initialize
      @blocks = []
    end

    def to_a
      @blocks.map { |b| b.to_h }
    end

    def to_html
      @blocks.map { |b| b.to_html } .join("\n")
    end

    class Block
      attr_reader :type

      def initialize(type)
        @type = type
      end

      def lines
        @lines ||= []
      end

      def to_h
        { type: @type, lines: @lines }
      end

      def to_html
        content = lines.map do |parts|
          parts.map do |part|
            part_to_html part
          end.join
        end.join("\n")

        wrap block_tag, nil, content
      end

      def escape_html(string)
        CGI::escape_html(string)
      end

      def part_to_html(part)
        return '' unless part
        return escape_html part if part.is_a?(String)

        case part[0]
        when :hyper_text_entry
          %Q(<a name="TODO">#{escape_html part[1]}</a>)
        when :hyper_text_jump
          %Q(<a href="#TODO">#{escape_html part[1]}</a>)
        when :option
          wrap 'code.option', nil, escape_html(part[1])
        when :command
          wrap 'code.command', nil, escape_html(part[1])
        when :note
          wrap 'span.note', nil, escape_html(part[1])
        when :url
          wrap 'a', nil, escape_html(part[1])
        when :special
          wrap 'code.special', nil, escape_html(part[1])
        else
          '<!-- TODO -->'
        end
      end

      def block_tag
        case type
        when :plain
          'p'
        when :headline
          'h1'
        when :header
          'h2'
        when :example
          'code.example'
        end
      end

      def wrap(tag, attrs, html)
        if tag
          "<#{tag}>#{html}</#{tag}>"
        else
          html
        end
      end
    end
  end
end
