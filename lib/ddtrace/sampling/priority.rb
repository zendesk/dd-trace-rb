require 'ddtrace/ext/priority'

module Datadog
  module Sampling
    # Defines behavior for priority sampling
    module Priority
      module_function

      def assigned?(span)
        span.context && !span.context.sampling_priority.nil?
      end

      def assign!(span, priority)
        if span.context
          span.context.sampling_priority = priority
        else
          # Set the priority directly on the span instead, since otherwise
          # it won't receive the appropriate tag.
          span.set_metric(
            Ext::DistributedTracing::SAMPLING_PRIORITY_KEY,
            priority
          )
        end
      end
    end
  end
end
