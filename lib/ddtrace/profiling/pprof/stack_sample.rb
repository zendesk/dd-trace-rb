require 'forwardable'

require 'ddtrace/profiling/events/stack'
require 'ddtrace/profiling/pprof/converter'

module Datadog
  module Profiling
    module Pprof
      # Builds a profile from a StackSample
      class StackSample
        include Pprof::Converter
        extend Forwardable

        LABEL_KEY_THREAD_ID = 'thread id'.freeze
        VALUE_TYPE_WALL = 'wall'.freeze
        VALUE_UNIT_NANOSECONDS = 'nanoseconds'.freeze

        attr_reader :stack_samples

        def initialize(builder, stack_samples)
          @builder = builder
          @stack_samples = stack_samples
        end

        def add_events!
          add_sample_types!
          add_samples!
        end

        def add_sample_types!
          # Add the value type
          sample_types.fetch(VALUE_TYPE_WALL, VALUE_UNIT_NANOSECONDS) do |id, type, unit|
            @wall_time_ns_index = id
            builder.build_value_type(type, unit)
          end
        end

        def add_samples!
          builder.samples.concat(build_samples)
        end

        def build_samples(stack_samples)
          group_events(stack_samples) do |stack_sample, values|
            build_sample(stack_sample, values)
          end
        end

        def event_group_key(stack_sample)
          [
            stack_sample.thread_id,
            [
              stack_sample.frames.collect(&:to_s),
              stack_sample.total_frame_count
            ]
          ].hash
        end

        def build_sample(stack_sample, values)
          locations = builder.build_locations(
            stack_sample.frames,
            stack_sample.total_frame_count
          )

          Perftools::Profiles::Sample.new(
            location_id: locations.collect(&:id), # TODO: Lazy enumerate?
            value: values,
            label: build_sample_labels(stack_sample)
          )
        end

        def build_sample_values(stack_sample)
          raise UnknownSampleValueIndex(:wall_time_ns) unless instance_variable_defined?(:@wall_time_ns_index)

          # Build a value array that matches the length of the sample types
          # Populate all values with "no value" by default
          values = Array.new(builder.sample_types.length, Builder::SAMPLE_VALUE_NO_VALUE)

          # Add values at appropriate index.
          # There may be other sample types present; be sure to put this value
          # matching the correct index of the actual sample type we want to match.
          values[@wall_time_ns_index] = stack_sample.wall_time_interval_ns
        end

        def build_sample_labels(stack_sample)
          [
            Perftools::Profiles::Label.new(
              key: string_table.fetch(LABEL_KEY_THREAD_ID),
              str: string_table.fetch(stack_sample.thread_id.to_s)
            )
          ]
        end

        class UnknownSampleValueIndex < StandardError
          attr_reader :value

          def initialize(value)
            @value = value
          end

          def message
            "Sample value index for '#{value}' unknown."
          end
        end
      end
    end
  end
end
