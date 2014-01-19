require 'spec_helper'
require 'voynich/document'

describe Voynich::Document::Block do
  subject(:document) { Voynich::Document.new }

  describe 'a plain block' do
    subject(:block) { document.mk_block(:plain) }

    before {
      block.lines << [ 'blah blah blah ', [ :hyper_text_jump, '|:h|' ] ]
    }
    it 'turns into <p>' do
      expect(block.to_html).to match(Regexp.new(<<-HTML.chomp))
<p>blah blah blah <a[^>]*>|:h|</a></p>
      HTML
    end
  end

  describe '#part_to_html' do
    subject(:block) { document.mk_block(:plain) }

    before {
      tags = {
        'foo' => [ 'foohelp.txt' ]
      }
      block.instance_eval do
        @document = Voynich::Document.new(tags: tags)
      end
    }

    it do
      expect(block.part_to_html([ :hyper_text_jump, '|foo|' ])).to include('<a href="foohelp.txt#foo">|foo|</a>')
    end
  end
end
