module Datadog
  module Sampling
    # Defines a custom rule that can be applied to sampling.
    class Rule
      KNUTH_FACTOR = 1111111111111111111

      attr_accessor \
        :attributes,
        :matcher,
        :sample_rate

      def initialize(options = {}, &block)
        self.sample_rate = options.delete(:sample_rate) || 1.0
        self.attributes = options
        self.matcher = block_given? ? block : method(:attributes_match?)
      end

      def sample?(span)
        ((span.trace_id * KNUTH_FACTOR) % Span::MAX_ID) <= (sample_rate * Span::MAX_ID)
      end

      def matches?(span)
        matcher.call(span)
      end

      def attributes_match?(span)
        attributes.all? do |(name, comparator)|
          break false unless span.respond_to?(name)

          case comparator
          when Regex
            comparator.match(value)
          else
            value == comparator
          end
        end
      end
    end
  end
end
