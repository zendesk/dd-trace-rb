require 'ddtrace/contrib/rails/rails_helper'

RSpec.xdescribe 'Rails error' do
  include_context 'Rails test application'

  #let(:tracer) { get_test_tracer }

  #before do
  #  @original_tracer = Datadog.configuration[:rails][:tracer]
  #  Datadog.configuration[:rails][:tracer] = @tracer
  #end

  #after do
  #  Datadog.configuration[:rails][:tracer] = @original_tracer
  #end

  #def get(controller)
  #  there's no port we are listening to :( maybe our rails it too fake?
  #  can we initialize the server manually?
  #
  #  rails_test_application
  #  puts 'now!'
  #  sleep 90
  #
  #  Net::HTTP.start('127.0.0.1', 8080) do |http|
  #    request = Net::HTTP::Get.new '/index'
  #    response = http.request(request)
  #  end
  #end

  subject(:request) { get :error }

  it 'error in the controller must be traced' do
    #headers = {
    #  "ACCEPT" => "application/json",     # This is what Rails 4 accepts
    #  "HTTP_ACCEPT" => "application/json" # This is what Rails 3 accepts
    #}
    #post "/widgets", :params => { :widget => {:name => "My Widget"} }, :headers => headers
    #
    #expect(response.content_type).to eq("application/json")
    #expect(response).to have_http_status(:created)



  end

  it '404 should not be traced as errors' do
    #assert_raises ActionController::RoutingError do
    #  get :not_found
    #end
    #
    #spans = @tracer.writer.spans()
    #expect(spans).to have(1).items
    #
    #span = spans[0]
    #expect(span.name).to eq('rails.action_controller')
    #expect(span.span_type).to eq('web')
    #expect(span.resource).to eq('TracingController#not_found')
    #expect(span.get_tag('rails.route.action')).to eq('not_found')
    #expect(span.get_tag('rails.route.controller')).to eq('TracingController')
    ## Stop here for old Rails versions, which have no ActionDispatch::ExceptionWrapper
    #return if Rails.version < '3.2.22.5'
    #expect(span.status).to eq(0)
    #assert_nil(span.get_tag('error.type'))
    #assert_nil(span.get_tag('error.msg'))
  end

  it 'missing rendering should close the template Span' do
    skip 'Recent versions use events, and cannot suffer from this issue' if Rails.version >= '4.0.0'

    # this route raises an exception, but the notification `render_template.action_view`
    # is not fired, causing unfinished spans; this it protects from regressions
    assert_raises ::ActionView::MissingTemplate do
      get :missing_template
    end
    spans = @tracer.writer.spans()
    expect(spans).to have(2).items

    span_request, span_template = spans

    expect(span_request.name).to eq('rails.action_controller')
    expect(span_request.status).to eq(1)
    expect(span_request.span_type).to eq('web')
    expect(span_request.resource).to eq('TracingController#missing_template')
    expect(span_request.get_tag('rails.route.action')).to eq('missing_template')
    expect(span_request.get_tag('rails.route.controller')).to eq('TracingController')
    expect(span_request.get_tag('error.type')).to eq('ActionView::MissingTemplate')
    assert_includes(span_request.get_tag('error.msg'), 'Missing template views/tracing/ouch.not.here')

    expect(span_template.name).to eq('rails.render_template')
    expect(span_template.status).to eq(1)
    expect(span_template.span_type).to eq('template')
    expect(span_template.resource).to eq('rails.render_template')
    assert_nil(span_template.get_tag('rails.template_name'))
    assert_nil(span_template.get_tag('rails.layout'))
    expect(span_template.get_tag('error.type')).to eq('ActionView::MissingTemplate')
    assert_includes(span_template.get_tag('error.msg'), 'Missing template views/tracing/ouch.not.here')
  end

  it 'missing partial rendering should close the template Span' do
    skip 'Recent versions use events, and cannot suffer from this issue' if Rails.version >= '4.0.0'

    # this route raises an exception, but the notification `render_partial.action_view`
    # is not fired, causing unfinished spans; this it protects from regressions
    assert_raises ::ActionView::Template::Error do
      get :missing_partial
    end

    error_msg = if Rails.version > '3.2.22.5'
                  'Missing partial tracing/_ouch.html.erb'
                else
                  'Missing partial tracing/ouch.html'
                end

    spans = @tracer.writer.spans()
    expect(spans).to have(3).items
    span_request, span_partial, span_template = spans

    expect(span_request.name).to eq('rails.action_controller')
    expect(span_request.status).to eq(1)
    expect(span_request.span_type).to eq('web')
    expect(span_request.resource).to eq('TracingController#missing_partial')
    expect(span_request.get_tag('rails.route.action')).to eq('missing_partial')
    expect(span_request.get_tag('rails.route.controller')).to eq('TracingController')
    expect(span_request.get_tag('error.type')).to eq('ActionView::Template::Error')
    assert_includes(span_request.get_tag('error.msg'), error_msg)

    expect(span_partial.name).to eq('rails.render_partial')
    expect(span_partial.status).to eq(1)
    expect(span_partial.span_type).to eq('template')
    expect(span_partial.resource).to eq('rails.render_partial')
    assert_nil(span_partial.get_tag('rails.template_name'))
    assert_nil(span_partial.get_tag('rails.layout'))
    expect(span_partial.get_tag('error.type')).to eq('ActionView::MissingTemplate')
    assert_includes(span_partial.get_tag('error.msg'), error_msg)

    expect(span_template.name).to eq('rails.render_template')
    expect(span_template.status).to eq(1)
    expect(span_template.span_type).to eq('template')
    expect(span_template.resource).to eq('tracing/missing_partial.html.erb')
    expect(span_template.get_tag('rails.template_name')).to eq('tracing/missing_partial.html.erb')
    expect(span_template.get_tag('rails.layout')).to eq('layouts/application')
    assert_includes(span_template.get_tag('error.msg'), error_msg)
    expect(span_template.get_tag('error.type')).to eq('ActionView::Template::Error')
  end

  it 'error in the template must be traced' do
    assert_raises ::ActionView::Template::Error do
      get :error_template
    end
    spans = @tracer.writer.spans()
    expect(spans).to have(2).items

    span_request, span_template = spans

    expect(span_request.name).to eq('rails.action_controller')
    expect(span_request.status).to eq(1)
    expect(span_request.span_type).to eq('web')
    expect(span_request.resource).to eq('TracingController#error_template')
    expect(span_request.get_tag('rails.route.action')).to eq('error_template')
    expect(span_request.get_tag('rails.route.controller')).to eq('TracingController')
    expect(span_request.get_tag('error.type')).to eq('ActionView::Template::Error')
    expect(span_request.get_tag('error.msg')).to eq('divided by 0')

    expect(span_template.name).to eq('rails.render_template')
    expect(span_template.status).to eq(1)
    expect(span_template.span_type).to eq('template')
    assert_includes(span_template.resource, 'tracing/error.html')
    if Rails.version >= '3.2.22.5'
      expect(span_template.resource).to eq('tracing/error.html.erb')
      expect(span_template.get_tag('rails.template_name')).to eq('tracing/error.html.erb')
    end
    assert_includes(span_template.get_tag('rails.template_name'), 'tracing/error.html')
    if Rails.version >= '3.2.22.5'
      expect(span_template.get_tag('rails.layout')).to eq('layouts/application')
    end
    assert_includes(span_template.get_tag('rails.layout'), 'layouts/application')
    expect(span_template.get_tag('error.type')).to eq('ActionView::Template::Error')
    expect(span_template.get_tag('error.msg')).to eq('divided by 0')
  end

  it 'error in the template partials must be traced' do
    assert_raises ::ActionView::Template::Error do
      get :error_partial
    end
    spans = @tracer.writer.spans()
    expect(spans).to have(3).items

    span_request, span_partial, span_template = spans

    expect(span_request.name).to eq('rails.action_controller')
    expect(span_request.status).to eq(1)
    expect(span_request.span_type).to eq('web')
    expect(span_request.resource).to eq('TracingController#error_partial')
    expect(span_request.get_tag('rails.route.action')).to eq('error_partial')
    expect(span_request.get_tag('rails.route.controller')).to eq('TracingController')
    expect(span_request.get_tag('error.type')).to eq('ActionView::Template::Error')
    expect(span_request.get_tag('error.msg')).to eq('divided by 0')

    expect(span_partial.name).to eq('rails.render_partial')
    expect(span_partial.status).to eq(1)
    expect(span_partial.span_type).to eq('template')
    assert_includes(span_partial.resource, 'tracing/_inner_error.html')
    if Rails.version >= '3.2.22.5'
      expect(span_partial.resource).to eq('tracing/_inner_error.html.erb')
      expect(span_partial.get_tag('rails.template_name')).to eq('tracing/_inner_error.html.erb')
    end
    assert_includes(span_partial.get_tag('rails.template_name'), 'tracing/_inner_error.html')
    expect(span_partial.get_tag('error.type')).to eq('ActionView::Template::Error')
    expect(span_partial.get_tag('error.msg')).to eq('divided by 0')

    expect(span_template.name).to eq('rails.render_template')
    expect(span_template.status).to eq(1)
    expect(span_template.span_type).to eq('template')
    assert_includes(span_template.resource, 'tracing/error_partial.html')
    if Rails.version >= '3.2.22.5'
      expect(span_template.get_tag('rails.template_name')).to eq('tracing/error_partial.html.erb')
    end
    assert_includes(span_template.get_tag('rails.template_name'), 'tracing/error_partial.html')
    if Rails.version >= '3.2.22.5'
      expect(span_template.get_tag('rails.layout')).to eq('layouts/application')
    end
    assert_includes(span_template.get_tag('rails.layout'), 'layouts/application')
    expect(span_template.get_tag('error.type')).to eq('ActionView::Template::Error')
    expect(span_template.get_tag('error.msg')).to eq('divided by 0')
  end
end
