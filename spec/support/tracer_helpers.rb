require 'ddtrace/tracer'
require 'ddtrace/span'
require 'support/faux_writer'

module TracerHelpers
  # Return a test tracer instance with a faux writer.
  def tracer
    @tracer ||= new_tracer
  end

  def new_tracer(options = {})
    Datadog::Tracer.new(options)
  end

  def writer
    @writer ||= new_writer
  end

  def new_writer(options = {})
    defaults = {
      transport: Datadog::Transport::HTTP.default do |t|
        t.adapter :test
      end
    }

    FauxWriter.new(defaults.merge(options))
  end

  # TODO: Replace references to `get_test_tracer` with `tracer`.
  # TODO: Use `new_tracer` instead if custom options are provided.
  alias get_test_tracer new_tracer
  alias get_test_writer new_writer

  # Return some test traces
  def get_test_traces(n)
    traces = []

    defaults = {
      service: 'test-app',
      resource: '/traces',
      span_type: 'web'
    }

    n.times do
      span1 = Datadog::Span.new(nil, 'client.testing', defaults).finish()
      span2 = Datadog::Span.new(nil, 'client.testing', defaults).finish()
      span2.set_parent(span1)
      traces << [span1, span2]
    end

    traces
  end

  def spans
    @spans ||= writer.spans
  end

  # Returns the only span in the current tracer writer.
  #
  # This method will not allow for ambiguous use,
  # meaning it will throw an error when more than
  # one span is available.
  def span
    @span ||= begin
      expect(spans).to have(1).item, "Requested the only span, but #{spans.size} spans are available"
      spans.first
    end
  end

  def clear_spans
    writer.spans(:clear)

    @spans = nil
    @span = nil
  end

  shared_context 'completed traces' do
    let(:trace_writer) { FauxWriter.new }
    let(:traces) { [] }

    before do
      tracer.trace_completed.subscribe(:test) do |trace|
        traces << trace
        trace_writer.write(trace)
      end
    end

    let(:spans) { trace_writer.spans }
    let(:span) { spans.first }
  end

  shared_context 'trace components' do
    let(:global_settings) do
      Datadog::Configuration::Settings.new.tap do |settings|
        settings.tracer.instance = tracer
        settings.trace_writer.instance = trace_writer
      end
    end

    let(:tracer) { new_tracer }
    let(:trace_writer) { FauxWriter.new }

    let(:spans) { trace_writer.spans }
    let(:span) { spans.first }
  end
end
