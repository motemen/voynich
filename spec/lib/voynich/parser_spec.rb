require 'spec_helper'
require 'voynich/parser'

describe Voynich::Parser do
  subject(:parser) { Voynich::Parser.new }

  describe '#parse' do
    it 'should return a Document' do
      expect(parser.parse(sample_content('help-random.txt'))).to be_a(Voynich::Document)
      puts parser.parse(sample_content('help-random.txt')).to_html
    end

    it 'should recognize headline block' do
      expect(parser.parse("INTRODUCTION\t*introduction*").to_a).to eq([
        {
          :type => :headline,
          :lines => [
            [
              [ :headline, 'INTRODUCTION' ],
              "\t",
              [ :hyper_text_entry, '*introduction*' ],
            ]
          ],
        }
      ])
    end

    it 'should recognize example block' do
      expect(parser.parse(<<-VIMDOC).to_a).to eq(
  blah blah blah: >
    $ vim
< blah blah blah.
      VIMDOC
        [{:type=>:plain, :lines=>[["  blah blah blah: "]]},
         {:type=>:example, :lines=>[["    $ vim\n"]]},
         {:type=>:plain, :lines=>[[" blah blah blah."]]}]
      )
    end

    it 'should recognize inline hypertextjump' do
      expect(parser.parse(<<VIMDOC).to_a).to eq([
It is well known that to read |:help| again and again is the best way for Vim
newbies. But what is to start with? The Vim help is so vast, that the
beginners often are in lost.
VIMDOC
        {:type=>:plain,
         :lines=>
          [["It is well known that to read ",
            [:hyper_text_jump, "|:help|"],
            " again and again is the best way for Vim"],
           ["newbies. But what is to start with? The Vim help is so vast, that the"],
           ["beginners often are in lost."]]}
      ])
    end

    it 'should recognize header' do
      expect(parser.parse(<<VIMDOC).to_a).to eq([
A SAMPLE HEADER ~
VIMDOC
        {:type=>:header,
         :lines=>
          [[[:header, "A SAMPLE HEADER"],
            " "] ]}
      ])
    end
  end

  describe '#parse_inline' do
    before { parser.parse_inline('N-1 times. N.') }

    it 'should recognize helpSpecial' do
      expect(parser.document.blocks.last.lines.last).to eq([
        [ :special, 'N' ], '-1 times. ',
        [ :special, 'N' ], '.'
      ])
    end
  end
end
