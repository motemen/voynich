require 'spec_helper'
require 'voynich/parser'

describe Voynich::Parser do
  subject(:parser) { Voynich::Parser.new }

  describe '#parse' do
    it 'should return a Document' do
      expect(parser.parse(sample_content('help-random.txt'))).to be_a(Voynich::Document)
      # puts parser.parse(sample_content('help-random.txt')).to_html
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
        [{:type=>:plain, :lines=>[["  blah blah blah: >"]]},
         {:type=>:example, :lines=>[["    $ vim"]]},
         {:type=>:plain, :lines=>[["< blah blah blah."]]}]
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
      expect(parser.parse(<<VIMDOC).to_a)
A SAMPLE HEADER ~
VIMDOC
      .to eq([
        {:type=>:header,
         :lines=>
          [[[:header, "A SAMPLE HEADER"],
            " "] ]}
      ])
    end

    it 'should recognize successive example blocks' do
      expect(parser.parse(<<VIMDOC).to_a)
                        Example for case sensitive search: >
                                :helpgrep Uganda
<                       Example for case ignoring search: >
                                :helpgrep uganda\c
<                       The pattern does not support line breaks, it must
VIMDOC
      .to eq([
        {:type=>:plain,
         :lines=>[["                        Example for case sensitive search: >"]]},
        {:type=>:example,
         :lines=>[["                                :helpgrep Uganda"]]},
        {:type=>:plain,
         :lines=>[["<                       Example for case ignoring search: >"]]},
        {:type=>:example,
         :lines=>[["                                :helpgrep uganda"]]},
        {:type=>:plain,
         :lines=>[["<                       The pattern does not support line breaks, it must"]]},
      ])
    end

    context 'with hyper_text_entries' do
      before do
        parser.parse(<<-VIMDOC, { file: 'foobar.txt' })
foo *foo*
bar *bar*
        VIMDOC
      end

      it 'should collect tags' do
        expect(parser.tags).to eq({
          'foo' => ['foobar.txt'],
          'bar' => ['foobar.txt'],
        })
      end
    end
  end

  describe '#parse_inline' do
    before do
      parser.instance_eval do
        @document = Voynich::Document.new
      end
    end

    context 'N' do
      before { parser.parse_inline('N-1 times. N.') }

      it 'should recognize helpSpecial' do
        expect(parser.document.blocks.last.lines.last).to eq([
          [ :special, 'N' ], '-1 times. ',
          [ :special, 'N' ], '.'
        ])
      end
    end

    context '<S-Up>' do
      before { parser.parse_inline('<S-Up> or <PageUp>') }

      it 'should recognize helpSpecial' do
        expect(parser.document.blocks.last.lines.last).to eq([
          [ :special, '<S-Up>' ],
          ' or ',
          [ :special, '<PageUp>' ],
        ])
      end
    end
  end
end
