require 'ddtrace/profiling/pprof/message_set'
require 'ddtrace/profiling/pprof/pprof_pb'
require 'ddtrace/profiling/pprof/string_table'

module Datadog
  module Profiling
    module Pprof
      # Generic profile building behavior
      class Builder
        SAMPLE_VALUE_NO_VALUE = 0
        DESC_FRAME_OMITTED = 'frame omitted'.freeze
        DESC_FRAMES_OMITTED = 'frames omitted'.freeze

        attr_reader \
          :functions,
          :locations,
          :mappings,
          :sample_types,
          :samples,
          :string_table

        def initialize
          @profile = nil
          @sample_types = MessageSet.new
          @samples = []
          @mappings = []
          @locations = MessageSet.new
          @functions = MessageSet.new
          @string_table = StringTable.new
        end

        def to_profile
          @profile ||= build_profile
        end

        def build_profile
          @mappings = build_mappings

          Perftools::Profiles::Profile.new(
            sample_type: @sample_types,
            sample: @samples,
            mapping: @mappings,
            location: @locations.messages,
            function: @functions.messages,
            string_table: @string_table.strings
          )
        end

        def build_value_type(type, unit)
          Perftools::Profiles::ValueType.new(
            type: @string_table.fetch(type),
            unit: @string_table.fetch(unit)
          )
        end

        def build_locations(backtrace_locations, length)
          locations = backtrace_locations.collect do |backtrace_location|
            @locations.fetch(
              # Filename
              backtrace_location.path,
              # Line number
              backtrace_location.lineno,
              # Function name
              backtrace_location.base_label,
              # Build function
              &method(:build_location)
            )
          end

          omitted = length - backtrace_locations.length

          # Add placeholder stack frame if frames were truncated
          if omitted > 0
            desc = omitted == 1 ? DESC_FRAME_OMITTED : DESC_FRAMES_OMITTED
            locations << @locations.fetch(
              '',
              0,
              "#{omitted} #{desc}",
              &method(:build_location)
            )
          end

          locations
        end

        def build_location(id, filename, line_number, function_name = nil)
          Perftools::Profiles::Location.new(
            id: id,
            line: [build_line(
              @functions.fetch(
                filename,
                function_name,
                &method(:build_function)
              ).id,
              line_number
            )]
          )
        end

        def build_line(function_id, line_number)
          Perftools::Profiles::Line.new(
            function_id: function_id,
            line: line_number
          )
        end

        def build_function(id, filename, function_name)
          Perftools::Profiles::Function.new(
            id: id,
            name: @string_table.fetch(function_name),
            filename: @string_table.fetch(filename)
          )
        end

        def build_mappings
          [
            Perftools::Profiles::Mapping.new(
              id: 1,
              filename: @string_table.fetch($PROGRAM_NAME)
            )
          ]
        end
      end
    end
  end
end
