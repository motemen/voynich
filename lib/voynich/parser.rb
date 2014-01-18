require 'voynich/document'

module Voynich
  class Parser
    attr_reader :document, :tags

    def initialize
      @tags = Hash.new { |h,k| h[k] = [] }
    end

    def parse(source, options = {})
      @document = Document.new

      source.each_line.map do |line|
        line.chomp!

        if current_block_type == :example
          case line
          when /^<.*/
            # end example
          when /^[^ \t]/
            # end example
          else
            append_line! [line]
            next
          end
        elsif current_block_type == :graphic
          case line
          when /^.* `$/
            # helpGraphic
            parse_inline(line, options)
            next
          end
        end

        case line
        when /^([-A-Z .][-A-Z0-9 .()]*?)([ \t]+)(\*.*)/
          # helpHeadline
          found_block :headline
          append_inline_part! [ :headline, $1 ]
          append_inline_part! $2
          parse_inline($3, options)
        when /^(\s*)(.+?)(\s*)~$/
          # helpHeader
          found_block :header
          append_inline_part! $1 unless $1.empty?
          append_inline_part! [ :header, $2 ]
          append_inline_part! $3 unless $3.empty?
        when /^.* `$/
          # helpGraphic
          found_block :graphic
          parse_inline(line, options)
        when /^(?:|.* )>$/
          # helpExample
          found_block :plain
          parse_inline(line, options)
          found_block :example
        when /^===.*===$/, /^---.*--$/
          # helpSectionDelim
          found_block :section_delim
        else
          found_block :plain
          parse_inline(line, options)
        end
      end

      @document
    end

    RE_INLINE_PARTS = {
      hyper_text_entry: /\*[#-)!+-~]+\*(?=\s|$)/,
       hyper_text_jump: /(?!\\)\|[#-)!+-~]+\|/,
                option: /'(?:[a-z]{2,}|t_..)'/,
               command: /`[^` \t]+`/,
               special: Regexp.union(
                          /(?:(?:^|\b)N(?:\b|(?=\.(?:$|\s)|th|-1)))/,
                          %r|{[-a-zA-Z0-9'"*+/:%#=\[\]<>.,]+}|,
                          /(?<=\s)\[[-a-z^A-Z0-9_]{2,}\]/,
                          /<(?:[SCM]-.|[-a-zA-Z0-9_]+)>/,
                          /\[(?:range|line|count|offset|\+?cmd|[+-]?num|\+\+opt|arg(?:uments)?|ident|addr|group)\]/,
                          /CTRL-(?:\.|Break|PageUp|PageDown|Insert|Del|-{char})/,
                        ),
                   url: %r#\b(((https?|ftp|gopher)://|(mailto|file|news):)[^' \t<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^' \t<>"]+)[a-zA-Z0-9/]#,
                  note: /(note:?|Notes?:?|NOTE:?)/,
    }
    RE_INLINE = Regexp.new('(?<plain>.*?)(?:' + RE_INLINE_PARTS.map { |name,re| "(?<#{name}>#{re})" }.join('|') + ')|(?<plain>.+)')

    # `

    def parse_inline(line, options = {})
      line.scan(RE_INLINE) do
        m = Regexp.last_match

        if not m['plain'].nil? and not m['plain'].empty?
          found_inline nil, m['plain']
        end

        m.names.each do |n|
          if n != 'plain' && m[n]
            found_inline n.to_sym, m[n]
          end
        end

        if not m['hyper_text_entry'].nil? and not m['hyper_text_entry'].empty?
          found_hyper_text_entry m['hyper_text_entry'][1..-2], options[:file]
        end
      end
    end

    private

    def append_block!(type)
      if current_block_type != type
        @document.blocks << Document::Block.new(type)
      else
        # connectable, add one line
        append_line! []
      end
    end

    def append_line!(parts)
      current_block.lines << parts
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

    def found_hyper_text_entry(entry, file)
      if file
        tags[entry] << file
      end
    end

    def current_block
      append_block! :plain if @document.blocks.empty?
      @document.blocks.last
    end

    def current_block_type
      not @document.blocks.empty? and current_block.type
    end
  end
end
