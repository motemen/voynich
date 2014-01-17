module Voynich
  class Parser
    def initialize
      @blocks = []
    end

    def found_block(type)
      if current_block_type != type
        @blocks << { :type => type }
      else
        current_lines << []
      end
    end

    def found_inline(type, text)
      if type
        current_line << [ type, text ]
      else
        current_line << text
      end
    end

    def current_block
      @blocks << { :type => :plain } if @blocks.empty?
      @blocks.last
    end

    def current_lines
      current_block[:lines] ||= [ [] ]
      current_block[:lines]
    end

    def current_line
      current_lines.last
    end

    def current_block_type
      not @blocks.empty? and current_block[:type]
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
            current_lines << line
          end
        else
          case line
          when /^([-A-Z .][-A-Z0-9 .()]*?)([ \t]+)(\*.*)/
            # helpHeadline
            found_block :headline
            current_line << [ :headline, $1 ]
            current_line << $2
            parse_inline($3)
          when /^(\s*)(.+?)(\s*)~$/
            # helpHeader
            found_block :header
            current_line << $1 unless $1.empty?
            current_line << [ :header, $2 ]
            current_line << $3 unless $3.empty?
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

      @blocks
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
