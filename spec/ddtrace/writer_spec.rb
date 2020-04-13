require 'spec_helper'

require 'ddtrace'
require 'json'

RSpec.describe Datadog::Writer do
  include HttpHelpers

  describe 'instance' do
    subject(:writer) { described_class.new(options) }
    let(:options) { { transport: transport } }
    let(:transport) { instance_double(Datadog::Transport::HTTP::Client) }

    describe 'behavior' do
      describe '#initialize' do
        context 'with priority sampling' do
          let(:options) { { priority_sampler: sampler } }
          let(:sampler) { instance_double(Datadog::PrioritySampler) }

          context 'and default transport options' do
            it do
              expect(Datadog::Transport::HTTP).to receive(:default) do |options|
                expect(options).to be_a_kind_of(Hash)
                expect(options[:api_version]).to eq(Datadog::Transport::HTTP::API::V4)
              end

              expect(writer.priority_sampler).to be(sampler)
            end
          end

          context 'and custom transport options' do
            let(:options) { super().merge(transport_options: { api_version: api_version }) }
            let(:api_version) { double('API version') }

            it do
              expect(Datadog::Transport::HTTP).to receive(:default) do |options|
                expect(options).to include(
                  api_version: api_version
                )
              end
              expect(writer.priority_sampler).to be(sampler)
            end
          end
        end
      end

      describe '#send_spans' do
        subject(:send_spans) { writer.send_spans(traces, writer.transport) }
        let(:traces) { get_test_traces(1) }
        let(:transport_stats) { instance_double(Datadog::Transport::Statistics) }

        before do
          allow(transport).to receive(:send_traces)
            .with(traces)
            .and_return(response)

          allow(transport).to receive(:stats).and_return(transport_stats)
        end

        context 'which returns a response that is' do
          let(:response) { instance_double(Datadog::Transport::HTTP::Traces::Response) }

          context 'successful' do
            before do
              allow(response).to receive(:ok?).and_return(true)
              allow(response).to receive(:server_error?).and_return(false)
              allow(response).to receive(:internal_error?).and_return(false)
            end

            it do
              is_expected.to be true
              expect(writer.stats[:traces_flushed]).to eq(1)
            end
          end

          context 'a server error' do
            before do
              allow(response).to receive(:ok?).and_return(false)
              allow(response).to receive(:server_error?).and_return(true)
              allow(response).to receive(:internal_error?).and_return(false)
            end

            it do
              is_expected.to be false
              expect(writer.stats[:traces_flushed]).to eq(0)
            end
          end

          context 'an internal error' do
            let(:response) { Datadog::Transport::InternalErrorResponse.new(double('error')) }
            let(:error) { double('error') }

            it do
              is_expected.to be true
              expect(writer.stats[:traces_flushed]).to eq(0)
            end
          end
        end

        context 'with report hostname' do
          let(:hostname) { 'my-host' }
          let(:response) { instance_double(Datadog::Transport::HTTP::Traces::Response) }

          before do
            allow(Datadog::Runtime::Socket).to receive(:hostname).and_return(hostname)
            allow(response).to receive(:ok?).and_return(true)
            allow(response).to receive(:server_error?).and_return(false)
            allow(response).to receive(:internal_error?).and_return(false)
          end

          context 'enabled' do
            around do |example|
              Datadog.configuration.report_hostname = Datadog.configuration.report_hostname.tap do
                Datadog.configuration.report_hostname = true
                example.run
              end
            end

            it do
              expect(transport).to receive(:send_traces) do |traces|
                root_span = traces.first.first
                expect(root_span.get_tag(Datadog::Ext::NET::TAG_HOSTNAME)).to eq(hostname)
                response
              end

              send_spans
            end
          end

          context 'disabled' do
            around do |example|
              Datadog.configuration.report_hostname = Datadog.configuration.report_hostname.tap do
                Datadog.configuration.report_hostname = false
                example.run
              end
            end

            it do
              expect(writer.transport).to receive(:send_traces) do |traces|
                root_span = traces.first.first
                expect(root_span.get_tag(Datadog::Ext::NET::TAG_HOSTNAME)).to be nil
                response
              end

              send_spans
            end
          end
        end
      end

      describe '#flush_completed' do
        subject(:flush_completed) { writer.flush_completed }
        it { is_expected.to be_a_kind_of(described_class::FlushCompleted) }
      end

      describe described_class::FlushCompleted do
        subject(:event) { described_class.new }

        describe '#name' do
          subject(:name) { event.name }
          it { is_expected.to be :flush_completed }
        end
      end
    end
  end
end
