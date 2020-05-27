require 'ddtrace/profiling/pprof/message_set'
require 'ddtrace/profiling/pprof/pprof_pb'
require 'ddtrace/profiling/pprof/string_table'

module Datadog
  module Profiling
    module Pprof
      # Helper functions for modules that convert events to pprof
      module Converter
        attr_reader :builder

        def_delegators \
          :builder,
          :functions,
          :locations,
          :mappings,
          :sample_types,
          :samples,
          :string_table

        def group_events(events)
          # Event grouping in format:
          # [key, (event, [values, ...])]
          event_groups = {}

          events.each do |event|
            key = event_group_key(event) || rand
            values = build_sample_values(event)

            unless key.nil?
              if event_groups.key?(key)
                # Update values for group
                group_values = event_groups[key][1]
                group_values.each_with_index do |group_value, i|
                  group_values[i] = group_value + values[i]
                end
              else
                # Add new group
                event_groups[key] = [event, values]
              end
            end
          end

          event_groups.collect do |_group_key, group|
            yield(
              # Event
              group[0],
              # Values
              group[1]
            )
          end
        end

        def event_group_key(event)
          raise NotImplementedError
        end

        def build_sample_values(event)
          raise NotImplementedError
        end
      end
    end
  end
end
