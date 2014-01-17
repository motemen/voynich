require 'spec_helper'
require 'voynich/document'

describe Voynich::Document::Block do
  describe 'a plain block' do
    subject(:block) { Voynich::Document::Block.new(:plain) }
    before {
      block.lines << [ 'blah blah blah ', [ :hyper_text_jump, '|:h|' ] ]
    }
    it 'turns into <p>' do
      expect(block.to_html).to match(Regexp.new(<<-HTML.chomp))
<p>blah blah blah <a[^>]*>|:h|</a></p>
      HTML
    end
  end
end
