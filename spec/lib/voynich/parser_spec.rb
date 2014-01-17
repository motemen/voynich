require 'spec_helper'
require 'voynich/parser'

describe Voynich::Parser do
  subject(:parser) { Voynich::Parser.new }

  describe '#parse' do
    it 'should return an Array' do
      expect(parser.parse(sample_content('help-random.txt')).to_a).to be_a(Array)
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
end
