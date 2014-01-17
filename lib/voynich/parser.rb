require 'voynich/document'

module Voynich
  class Parser
    def initialize
      @doc = Document.new
    end

    def append_block!(type)
      if current_block_type != type
        @doc.blocks << Document::Block.new(type)
      else
        current_block.lines << []
      end
    end

    def append_line!(line)
      current_block.lines << line
    end

    def append_inline_part!(part)
      append_line! [] if current_block.lines.empty?
      current_block.lines.last << part
    end

    def found_block(type)
      if current_block_type != type
        append_block! type
      else
        append_line! []
      end
    end

    def found_inline(type, text)
      if type
        append_inline_part! [ type, text ]
      else
        append_inline_part! text
      end
    end

    def current_block
      append_block! :plain if @doc.blocks.empty?
      @doc.blocks.last
    end

    def current_block_type
      not @doc.blocks.empty? and current_block.type
    end

    def parse(source)
      source.each_line.map do |line|
        # TODO helpGraphic
        if current_block_type == :example
          case line
          when /^</
            found_block :plain
          when /^[^ \t]/
            found_block :plain
            parse_inline(line)
          else
            append_line! [line]
          end
        else
          case line
          when /^([-A-Z .][-A-Z0-9 .()]*?)([ \t]+)(\*.*)/
            # helpHeadline
            found_block :headline
            append_inline_part! [ :headline, $1 ]
            append_inline_part! $2
            parse_inline($3)
          when /^(\s*)(.+?)(\s*)~$/
            # helpHeader
            found_block :header
            append_inline_part! $1 unless $1.empty?
            append_inline_part! [ :header, $2 ]
            append_inline_part! $3 unless $3.empty?
          when /^(|.* )>$/
            parse_inline($1)
            found_block :example
          when /^===.*===$/, /^---.*--$/
            # helpSectionDelim
            found_block :section_delim
          else
            found_block :plain
            parse_inline(line)
          end
        end
      end

      @doc
    end

    # TODO helpSpecial
    RE_INLINE_PARTS = {
      hyper_text_entry: /\*[#-)!+-~]+\*(?=\s|$)/,
      hyper_text_jump: /(?!\\)\|[#-)!+-~]+\|/,
      option: /'(?:[a-z]{2,}|t_..)'/,
      command: /`[^` \t]+`/,
      note: /(note:?|Notes?:?|NOTE:?)/,
      url: %r#\b(((https?|ftp|gopher)://|(mailto|file|news):)[^' \t<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^' \t<>"]+)[a-zA-Z0-9/]#,
    }
    RE_INLINE = Regexp.new('(?<plain>.+?)?(?:' + RE_INLINE_PARTS.map { |name,re| "(?<#{name}>#{re})" }.join('|') + ')|(?<plain>.+)')
    def parse_inline(line)
      line.scan(RE_INLINE) do
        m = Regexp.last_match

        if m['plain']
          found_inline nil, m['plain']
        end

        m.names.each do |n|
          if n != 'plain' && m[n]
            found_inline n.to_sym, m[n]
          end
        end
      end
    end
  end
end
