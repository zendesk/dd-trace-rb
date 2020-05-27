require 'ddtrace/profiling/events/stack'
require 'ddtrace/profiling/pprof/stack_sample'

module Datadog
  module Profiling
    module Encoding
      module Profile
        # Encodes events to pprof
        module Protobuf
          module_function

          def encode(flushes)
            return if flushes.empty?

            builder = Pprof::Builder.new

            flushes.each do |flush|
              converter = case flush.event_class
                          when Profiling::Events::StackSample
                            Pprof::StackSample.new(builder, flush.events)
                          else
                            raise UnknownEventTypeError, flush.event_class
                          end

              converter.add_events!
            end

            profile = builder.to_profile
            Perftools::Profiles::Profile.encode(profile)
          end

          # Error when an unknown event type is given to be encoded
          class UnknownEventTypeError < ArgumentError
            attr_reader :type

            def initialize(type)
              @type = type
            end

            def message
              "Unknown event type cannot be encoded to pprof: #{type}"
            end
          end
        end
      end
    end
  end
end
