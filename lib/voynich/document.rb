require 'cgi'

module Voynich
  class Document
    attr_reader :blocks, :tags, :filename

    def initialize(options = {})
      @blocks = []
      @tags = options[:tags]
      @filename = options[:filename]
    end

    def to_a
      @blocks.map { |b| b.to_h }
    end

    def to_html
      @blocks.map { |b| b.to_html } .join("\n")
    end

    def mk_block(type)
      Block.new(type, self)
    end

    def append_block!(type)
      @blocks << mk_block(type)
    end

    class Block
      attr_reader :type

      def initialize(type, document)
        @type = type
        @document = document
      end

      def lines
        @lines ||= []
      end

      def tags
        @document && @document.tags
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

        mk_tag block_tag, nil, content
      end

      def escape_html(string)
        CGI::escape_html(string)
      end

      def part_to_html(part)
        return '' unless part
        return escape_html part if part.is_a?(String)

        type, text = part
        html = escape_html text

        case type
        when :hyper_text_entry
          mk_tag 'a', { name: text[1..-2] }, html
        when :hyper_text_jump
          entry = text[1..-2]
          href = "##{entry}"
          if tags && tags[entry]
            href = "#{tags[entry][0]}#{href}"
          end
          mk_tag 'a', { href: href }, html
        when :option
          mk_tag 'code.option', nil, html
        when :command
          mk_tag 'code.command', nil, html
        when :note
          mk_tag 'span.note', nil, html
        when :url
          mk_tag 'a', { href: text, target: '_blank' }, html
        when :special
          mk_tag 'code.special', nil, html
        when :headline, :header
          html
        else
          "<!-- TODO (#{type}) -->"
        end
      end

      def block_tag
        case type
        when :plain
          'div.plain'
        when :headline
          'div.headline'
        when :header
          'div.header'
        when :example
          'pre.example'
        when :grahic
          'pre.graphic'
        when :section_delim
          'hr'
        end
      end

      def mk_tag(tag, attrs, html)
        attrs = attrs || {}

        if tag
          tag.gsub!(/\.([^.]+)/) do
            attrs[:class] ||= []
            attrs[:class] << $1
            ''
          end

          attrs.each do |k,v|
            tag += %Q( #{k}="#{escape_html(v.is_a?(Array) ? v.join(' ') : v)}")
          end
          "<#{tag}>#{html}</#{tag.sub(/ .*/, '')}>"
        else
          html
        end
      end
    end
  end
end
