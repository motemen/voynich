module Voynich
  class Document
    attr_reader :blocks

    def initialize
      @blocks = []
    end

    def to_a
      @blocks.map { |b| b.to_h }
    end

    class Block
      attr_reader :type

      def initialize(type)
        @type = type
      end

      def lines
        @lines ||= []
      end

      def to_h
        { type: @type, lines: @lines }
      end
    end
  end
end
