require 'ddtrace/ext/net'
require 'ddtrace/runtime/socket'
require 'ddtrace/runtime/metrics'

module Datadog
  # SyncWriter flushes both services and traces synchronously
  class SyncWriter
    attr_reader \
      :priority_sampler,
      :runtime_metrics,
      :transport

    def initialize(options = {})
      @transport = options.fetch(:transport) do
        transport_options = options.fetch(:transport_options, {})
        Transport::HTTP.default(transport_options)
      end

      # Runtime metrics
      @runtime_metrics = options.fetch(:runtime_metrics) do
        Runtime::Metrics.new
      end
    end

    def write(trace, services = nil)
      unless services.nil?
        Datadog::Patcher.do_once('SyncWriter#write') do
          Datadog::Tracer.log.warn(%(
            write: Writing services has been deprecated and no longer need to be provided.
            write(traces, services) can be updted to write(traces)
          ))
        end
      end

      perform_concurrently(
        proc { flush_trace(trace) }
      )
    rescue => e
      Tracer.log.debug(e)
    end

    private

    def perform_concurrently(*tasks)
      tasks.map { |task| Thread.new(&task) }.each(&:join)
    end

    def flush_trace(trace)
      processed_traces = Pipeline.process!([trace])
      inject_hostname!(processed_traces.first) if Datadog.configuration.report_hostname

      # Send traces but don't bother handling the response.
      # Normally we would update the sampler's service rates from this response.
      # However, the SyncWriter is normally used in short-lived forks.
      # These service updates would not propagate to the parent process anyways.
      transport.send(:traces, processed_traces)
    end

    def inject_hostname!(trace)
      unless trace.first.nil?
        hostname = Datadog::Runtime::Socket.hostname
        unless hostname.nil? || hostname.empty?
          trace.first.set_tag(Ext::NET::TAG_HOSTNAME, hostname)
        end
      end
    end
  end
end
