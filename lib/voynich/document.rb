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

        case type
        when :hyper_text_entry, :hyper_text_jump
          s, entry, e = text.partition(/(?<=^.).*(?=.$)/)

          attr = if type === :hyper_text_entry
            { name: entry, :class => 'entry' }
          elsif type === :hyper_text_jump
            href = "##{entry}"
            if tags && tags[entry]
              href = "#{tags[entry][0]}#{href}"
            end
            { href: href, :class => 'jump' }
          end

          mk_tag 'a', attr, [
            mk_tag('span.sep', nil, s),
            escape_html(entry),
            mk_tag('span.sep', nil, e)
          ]
        when :option, :command, :note, :special
          tag = {
            option:  'code.option',
            command: 'code.command',
            note:    'span.note',
            special: 'code.special'
          }.fetch(type)

          mk_tag tag, nil, escape_html(text)
        when :url
          mk_tag 'a.url', { href: text }, escape_html(text)
        when :headline, :header
          escape_html(text)
        when :example_marker_begin, :example_marker_end
          mk_tag 'span', { :class => type.to_s.gsub(/_/, '-') }, escape_html(text)
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
        html = html.join('') if html.is_a?(Array)

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
