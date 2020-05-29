require 'spec_helper'

require 'ddtrace'
require 'ddtrace/opentracer'
require 'ddtrace/opentracer/helper'

if Datadog::OpenTracer.supported?
  RSpec.describe Datadog::OpenTracer::GlobalTracer do
    before { allow(Datadog::Configuration::Components).to receive(:build_tracer).and_call_original }

    include_context 'OpenTracing helpers'

    context 'when included into OpenTracing' do
      describe '#global_tracer=' do
        subject(:global_tracer) { OpenTracing.global_tracer = tracer }
        after(:each) { Datadog.configuration.tracer = Datadog::Tracer.new }

        context 'when given a Datadog::OpenTracer::Tracer' do
          let(:tracer) { Datadog::OpenTracer::Tracer.new }

          it do
            expect(global_tracer).to be(tracer)
            expect(Datadog.tracer).to be(tracer.datadog_tracer)
          end
        end

        context 'when given some unknown kind of tracer' do
          let(:tracer) { double('other tracer') }

          it do
            expect(global_tracer).to be(tracer)
            expect(Datadog.tracer).to_not be(tracer)
          end
        end
      end
    end
  end
end
