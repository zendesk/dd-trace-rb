require 'bundler/gem_tasks'
require 'ddtrace/version'
require 'rubocop/rake_task' if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.1.0')
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'appraisal'
require 'yard'

Dir.glob('tasks/*.rake').each { |r| import r }

desc 'Run RSpec'
# rubocop:disable Metrics/BlockLength
namespace :spec do
  task all: [:main,
             :rails, :railsredis, :railssidekiq, :railsactivejob,
             :elasticsearch, :http, :redis, :sidekiq, :sinatra]

  RSpec::Core::RakeTask.new(:main) do |t, args|
    t.pattern = 'spec/**/*_spec.rb'
    t.exclude_pattern = 'spec/**/{contrib,benchmark,redis,opentracer}/**/*_spec.rb'
    t.rspec_opts = args.to_a.join(' ')
  end

  RSpec::Core::RakeTask.new(:opentracer) do |t, args|
    t.pattern = 'spec/ddtrace/opentracer/**/*_spec.rb'
    t.rspec_opts = args.to_a.join(' ')
  end

  RSpec::Core::RakeTask.new(:rails) do |t, args|
    t.pattern = 'spec/ddtrace/contrib/rails/**/*_spec.rb'
    t.exclude_pattern = 'spec/ddtrace/contrib/rails/**/*{sidekiq,active_job,disable_env}*_spec.rb'
    t.rspec_opts = args.to_a.join(' ')
  end

  RSpec::Core::RakeTask.new(:railsredis) do |t, args|
    t.pattern = 'spec/ddtrace/contrib/rails/**/*redis*_spec.rb'
    t.rspec_opts = args.to_a.join(' ')
  end

  RSpec::Core::RakeTask.new(:railssidekiq) do |t, args|
    t.pattern = 'spec/ddtrace/contrib/rails/**/*sidekiq*_spec.rb'
    t.rspec_opts = args.to_a.join(' ')
  end

  RSpec::Core::RakeTask.new(:railsactivejob) do |t, args|
    t.pattern = 'spec/ddtrace/contrib/rails/**/*active_job*_spec.rb'
    t.rspec_opts = args.to_a.join(' ')
  end

  RSpec::Core::RakeTask.new(:railsdisableenv) do |t, args|
    t.pattern = 'spec/ddtrace/contrib/rails/**/*disable_env*_spec.rb'
    t.rspec_opts = args.to_a.join(' ')
  end

  RSpec::Core::RakeTask.new(:contrib) do |t, args|
    # rubocop:disable Metrics/LineLength
    t.pattern = 'spec/**/contrib/{analytics,configurable,extensions,integration,patchable,patcher,registerable,registry,configuration/*}_spec.rb'
    t.rspec_opts = args.to_a.join(' ')
  end

  [
    :action_pack,
    :action_view,
    :active_model_serializers,
    :active_record,
    :active_support,
    :aws,
    :concurrent_ruby,
    :dalli,
    :delayed_job,
    :elasticsearch,
    :ethon,
    :excon,
    :faraday,
    :grape,
    :graphql,
    :grpc,
    :http,
    :mongodb,
    :mysql2,
    :racecar,
    :rack,
    :rake,
    :redis,
    :resque,
    :rest_client,
    :sequel,
    :sidekiq,
    :sinatra,
    :sucker_punch,
    :shoryuken
  ].each do |contrib|
    RSpec::Core::RakeTask.new(contrib) do |t, args|
      t.pattern = "spec/ddtrace/contrib/#{contrib}/**/*_spec.rb"
      t.rspec_opts = args.to_a.join(' ')
    end
  end
end

namespace :test do
  task all: [:main,
             :rails, :railsredis, :railssidekiq, :railsactivejob,
             :sidekiq, :monkey]

  Rake::TestTask.new(:main) do |t|
    t.libs << %w[test lib]
    t.test_files = FileList['test/**/*_test.rb'].reject do |path|
      path.include?('contrib') ||
        path.include?('benchmark') ||
        path.include?('redis') ||
        path.include?('monkey_test.rb')
    end
  end

  Rake::TestTask.new(:rails) do |t|
    t.libs << %w[test lib]
    t.test_files = FileList['test/contrib/rails/**/*_test.rb'].reject do |path|
      path.include?('redis') ||
        path.include?('sidekiq') ||
        path.include?('active_job') ||
        path.include?('disable_env')
    end
  end

  Rake::TestTask.new(:railsredis) do |t|
    t.libs << %w[test lib]
    t.test_files = FileList['test/contrib/rails/**/*redis*_test.rb']
  end

  Rake::TestTask.new(:railssidekiq) do |t|
    t.libs << %w[test lib]
    t.test_files = FileList['test/contrib/rails/**/*sidekiq*_test.rb']
  end

  Rake::TestTask.new(:railsactivejob) do |t|
    t.libs << %w[test lib]
    t.test_files = FileList['test/contrib/rails/**/*active_job*_test.rb']
  end

  Rake::TestTask.new(:railsdisableenv) do |t|
    t.libs << %w[test lib]
    t.test_files = FileList['test/contrib/rails/**/*disable_env*_test.rb']
  end

  [
    :grape,
    :sidekiq,
    :sucker_punch
  ].each do |contrib|
    Rake::TestTask.new(contrib) do |t|
      t.libs << %w[test lib]
      t.test_files = FileList["test/contrib/#{contrib}/*_test.rb"]
    end
  end

  Rake::TestTask.new(:monkey) do |t|
    t.libs << %w[test lib]
    t.test_files = FileList['test/monkey_test.rb']
  end
end

Rake::TestTask.new(:benchmark) do |t|
  t.libs << %w[test lib]
  t.test_files = FileList['test/benchmark_test.rb']
end

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.1.0')
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.options << ['-D', '--force-exclusion']
    t.patterns = ['lib/**/*.rb', 'test/**/*.rb', 'spec/**/*.rb', 'Gemfile', 'Rakefile']
  end
end

YARD::Rake::YardocTask.new(:docs) do |t|
  t.options += ['--title', "ddtrace #{Datadog::VERSION::STRING} documentation"]
  t.options += ['--markup', 'markdown']
  t.options += ['--markup-provider', 'redcarpet']
end

# Deploy tasks
S3_BUCKET = 'gems.datadoghq.com'.freeze
S3_DIR = ENV['S3_DIR']

desc 'release the docs website'
task :'release:docs' => :docs do
  raise 'Missing environment variable S3_DIR' if !S3_DIR || S3_DIR.empty?
  sh "aws s3 cp --recursive doc/ s3://#{S3_BUCKET}/#{S3_DIR}/docs/"
end

desc 'CI task; it runs all tests for current version of Ruby'
task :ci do
  ci_node_total = ENV.key?('CIRCLE_NODE_TOTAL') ? ENV['CIRCLE_NODE_TOTAL'].to_i : nil
  ci_node_index = ENV.key?('CIRCLE_NODE_INDEX') ? ENV['CIRCLE_NODE_INDEX'].to_i : nil

  if ci_node_total && ci_node_index && ci_node_total > 1
    test_splitter = Random.new(0)

    define_method(:parallel_sh) do |*args|
      sh(*args) if test_splitter.rand(ci_node_total) == ci_node_index
    end
  else
    define_method(:parallel_sh) { |*args| sh(*args) }
  end

  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new(Datadog::VERSION::MINIMUM_RUBY_VERSION)
    raise NotImplementedError, "Ruby versions < #{Datadog::VERSION::MINIMUM_RUBY_VERSION} are not supported!"
  elsif Gem::Version.new('2.0.0') <= Gem::Version.new(RUBY_VERSION) \
        && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.1.0')
    # Main library
    parallel_sh 'bundle exec rake test:main'
    parallel_sh 'bundle exec rake spec:main'
    parallel_sh 'bundle exec rake spec:contrib'

    if RUBY_PLATFORM != 'java'
      # Contrib minitests
      parallel_sh 'bundle exec appraisal contrib-old rake test:monkey'
      parallel_sh 'bundle exec appraisal contrib-old rake test:sidekiq'
      parallel_sh 'bundle exec appraisal contrib-old rake test:sucker_punch'
      # Contrib specs
      parallel_sh 'bundle exec appraisal contrib-old rake spec:active_model_serializers'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:active_record'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:active_support'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:aws'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:concurrent_ruby'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:dalli'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:delayed_job'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:elasticsearch'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:excon'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:faraday'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:http'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:mongodb'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:mysql2'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:rack'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:rake'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:redis'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:resque'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:rest_client'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:sequel'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:sinatra'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:ethon'
      # Rails minitests
      parallel_sh 'bundle exec appraisal rails30-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails30-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails32-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails30-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails32-postgres-sidekiq rake test:railssidekiq'
      # Rails specs
      parallel_sh 'bundle exec appraisal rails30-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:rails'
      # Rails suite specs
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:action_pack'
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:action_view'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake spec:active_record'
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:active_support'
    end
  elsif Gem::Version.new('2.1.0') <= Gem::Version.new(RUBY_VERSION) \
        && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.2.0')
    # Main library
    parallel_sh 'bundle exec rake test:main'
    parallel_sh 'bundle exec rake spec:main'
    parallel_sh 'bundle exec rake spec:contrib'
    parallel_sh 'bundle exec rake spec:opentracer'

    if RUBY_PLATFORM != 'java'
      # Contrib minitests
      parallel_sh 'bundle exec appraisal contrib-old rake test:monkey'
      parallel_sh 'bundle exec appraisal contrib-old rake test:sidekiq'
      parallel_sh 'bundle exec appraisal contrib-old rake test:sucker_punch'
      # Contrib specs
      parallel_sh 'bundle exec appraisal contrib-old rake spec:active_model_serializers'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:active_record'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:active_support'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:aws'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:concurrent_ruby'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:dalli'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:delayed_job'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:elasticsearch'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:excon'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:faraday'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:http'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:mongodb'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:mysql2'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:rack'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:rake'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:redis'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:resque'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:rest_client'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:sequel'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:sinatra'
      parallel_sh 'bundle exec appraisal contrib-old rake spec:ethon'
      # Rails minitests
      parallel_sh 'bundle exec appraisal rails30-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails30-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails32-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails4-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails4-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails30-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails32-postgres-sidekiq rake test:railssidekiq'
      # Rails specs
      parallel_sh 'bundle exec appraisal rails30-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails4-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres rake spec:rails'
      # Rails suite specs
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:action_pack'
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:action_view'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake spec:active_record'
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:active_support'
    end
  elsif Gem::Version.new('2.2.0') <= Gem::Version.new(RUBY_VERSION)\
        && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3.0')
    # Main library
    parallel_sh 'bundle exec rake test:main'
    parallel_sh 'bundle exec rake spec:main'
    parallel_sh 'bundle exec rake spec:contrib'
    parallel_sh 'bundle exec rake spec:opentracer'

    if RUBY_PLATFORM != 'java'
      # Contrib minitests
      parallel_sh 'bundle exec appraisal contrib rake test:grape'
      parallel_sh 'bundle exec appraisal contrib rake test:sidekiq'
      parallel_sh 'bundle exec appraisal contrib rake test:sucker_punch'
      # Contrib specs
      parallel_sh 'bundle exec appraisal contrib rake spec:action_pack'
      parallel_sh 'bundle exec appraisal contrib rake spec:action_view'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_model_serializers'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_record'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_support'
      parallel_sh 'bundle exec appraisal contrib rake spec:aws'
      parallel_sh 'bundle exec appraisal contrib rake spec:concurrent_ruby'
      parallel_sh 'bundle exec appraisal contrib rake spec:dalli'
      parallel_sh 'bundle exec appraisal contrib rake spec:delayed_job'
      parallel_sh 'bundle exec appraisal contrib rake spec:elasticsearch'
      parallel_sh 'bundle exec appraisal contrib rake spec:excon'
      parallel_sh 'bundle exec appraisal contrib rake spec:faraday'
      parallel_sh 'bundle exec appraisal contrib rake spec:graphql'
      parallel_sh 'bundle exec appraisal contrib rake spec:grpc'
      parallel_sh 'bundle exec appraisal contrib rake spec:http'
      parallel_sh 'bundle exec appraisal contrib rake spec:mongodb'
      parallel_sh 'bundle exec appraisal contrib rake spec:mysql2'
      parallel_sh 'bundle exec appraisal contrib rake spec:racecar'
      parallel_sh 'bundle exec appraisal contrib rake spec:rack'
      parallel_sh 'bundle exec appraisal contrib rake spec:rake'
      parallel_sh 'bundle exec appraisal contrib rake spec:redis'
      parallel_sh 'bundle exec appraisal contrib rake spec:resque'
      parallel_sh 'bundle exec appraisal contrib rake spec:rest_client'
      parallel_sh 'bundle exec appraisal contrib rake spec:sequel'
      parallel_sh 'bundle exec appraisal contrib rake spec:shoryuken'
      parallel_sh 'bundle exec appraisal contrib rake spec:sinatra'
      parallel_sh 'bundle exec appraisal contrib rake spec:ethon'
      # Rails minitests
      parallel_sh 'bundle exec appraisal rails30-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails30-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails32-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails4-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails4-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails4-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails4-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis-activesupport rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:railsdisableenv'
      # Rails specs
      parallel_sh 'bundle exec appraisal rails30-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails4-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake spec:rails'
    end
  elsif Gem::Version.new('2.3.0') <= Gem::Version.new(RUBY_VERSION) \
        && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4.0')
    # Main library
    parallel_sh 'bundle exec rake test:main'
    parallel_sh 'bundle exec rake spec:main'
    parallel_sh 'bundle exec rake spec:contrib'
    parallel_sh 'bundle exec rake spec:opentracer'

    if RUBY_PLATFORM != 'java'
      # Contrib minitests
      parallel_sh 'bundle exec appraisal contrib rake test:grape'
      parallel_sh 'bundle exec appraisal contrib rake test:sidekiq'
      parallel_sh 'bundle exec appraisal contrib rake test:sucker_punch'
      # Contrib specs
      parallel_sh 'bundle exec appraisal contrib rake spec:action_pack'
      parallel_sh 'bundle exec appraisal contrib rake spec:action_view'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_model_serializers'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_record'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_support'
      parallel_sh 'bundle exec appraisal contrib rake spec:aws'
      parallel_sh 'bundle exec appraisal contrib rake spec:concurrent_ruby'
      parallel_sh 'bundle exec appraisal contrib rake spec:dalli'
      parallel_sh 'bundle exec appraisal contrib rake spec:delayed_job'
      parallel_sh 'bundle exec appraisal contrib rake spec:elasticsearch'
      parallel_sh 'bundle exec appraisal contrib rake spec:excon'
      parallel_sh 'bundle exec appraisal contrib rake spec:faraday'
      parallel_sh 'bundle exec appraisal contrib rake spec:graphql'
      parallel_sh 'bundle exec appraisal contrib rake spec:grpc'
      parallel_sh 'bundle exec appraisal contrib rake spec:http'
      parallel_sh 'bundle exec appraisal contrib rake spec:mongodb'
      parallel_sh 'bundle exec appraisal contrib rake spec:mysql2'
      parallel_sh 'bundle exec appraisal contrib rake spec:racecar'
      parallel_sh 'bundle exec appraisal contrib rake spec:rack'
      parallel_sh 'bundle exec appraisal contrib rake spec:rake'
      parallel_sh 'bundle exec appraisal contrib rake spec:redis'
      parallel_sh 'bundle exec appraisal contrib rake spec:resque'
      parallel_sh 'bundle exec appraisal contrib rake spec:rest_client'
      parallel_sh 'bundle exec appraisal contrib rake spec:sequel'
      parallel_sh 'bundle exec appraisal contrib rake spec:shoryuken'
      parallel_sh 'bundle exec appraisal contrib rake spec:sinatra'
      parallel_sh 'bundle exec appraisal contrib rake spec:ethon'
      # Rails minitests
      parallel_sh 'bundle exec appraisal rails30-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails30-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails32-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails4-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails4-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails4-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails4-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis-activesupport rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:railsdisableenv'
      # Rails specs
      parallel_sh 'bundle exec appraisal rails30-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails32-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails32-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails4-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails4-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake spec:rails'
    end
  elsif Gem::Version.new('2.4.0') <= Gem::Version.new(RUBY_VERSION) \
        && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.5.0')
    # Main library
    parallel_sh 'bundle exec rake test:main'
    parallel_sh 'bundle exec rake spec:main'
    parallel_sh 'bundle exec rake spec:contrib'
    parallel_sh 'bundle exec rake spec:opentracer'

    if RUBY_PLATFORM != 'java'
      # Benchmarks
      parallel_sh 'bundle exec rake benchmark'
      # Contrib minitests
      parallel_sh 'bundle exec appraisal contrib rake test:grape'
      parallel_sh 'bundle exec appraisal contrib rake test:sidekiq'
      parallel_sh 'bundle exec appraisal contrib rake test:sucker_punch'
      # Contrib specs
      parallel_sh 'bundle exec appraisal contrib rake spec:action_pack'
      parallel_sh 'bundle exec appraisal contrib rake spec:action_view'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_model_serializers'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_record'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_support'
      parallel_sh 'bundle exec appraisal contrib rake spec:aws'
      parallel_sh 'bundle exec appraisal contrib rake spec:concurrent_ruby'
      parallel_sh 'bundle exec appraisal contrib rake spec:dalli'
      parallel_sh 'bundle exec appraisal contrib rake spec:delayed_job'
      parallel_sh 'bundle exec appraisal contrib rake spec:elasticsearch'
      parallel_sh 'bundle exec appraisal contrib rake spec:excon'
      parallel_sh 'bundle exec appraisal contrib rake spec:faraday'
      parallel_sh 'bundle exec appraisal contrib rake spec:graphql'
      parallel_sh 'bundle exec appraisal contrib rake spec:grpc'
      parallel_sh 'bundle exec appraisal contrib rake spec:http'
      parallel_sh 'bundle exec appraisal contrib rake spec:mongodb'
      parallel_sh 'bundle exec appraisal contrib rake spec:mysql2'
      parallel_sh 'bundle exec appraisal contrib rake spec:racecar'
      parallel_sh 'bundle exec appraisal contrib rake spec:rack'
      parallel_sh 'bundle exec appraisal contrib rake spec:rake'
      parallel_sh 'bundle exec appraisal contrib rake spec:redis'
      parallel_sh 'bundle exec appraisal contrib rake spec:resque'
      parallel_sh 'bundle exec appraisal contrib rake spec:rest_client'
      parallel_sh 'bundle exec appraisal contrib rake spec:sequel'
      parallel_sh 'bundle exec appraisal contrib rake spec:shoryuken'
      parallel_sh 'bundle exec appraisal contrib rake spec:sinatra'
      parallel_sh 'bundle exec appraisal contrib rake spec:ethon'
      # Rails minitests
      # We only test Rails 5+ because older versions require Bundler < 2.0
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis-activesupport rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:railsdisableenv'
      # Rails specs
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake spec:rails'
    end
  elsif Gem::Version.new('2.5.0') <= Gem::Version.new(RUBY_VERSION) \
        && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.6.0')
    # Main library
    parallel_sh 'bundle exec rake test:main'
    parallel_sh 'bundle exec rake spec:main'
    parallel_sh 'bundle exec rake spec:contrib'
    parallel_sh 'bundle exec rake spec:opentracer'

    if RUBY_PLATFORM != 'java'
      # Benchmarks
      parallel_sh 'bundle exec rake benchmark'
      # Contrib minitests
      parallel_sh 'bundle exec appraisal contrib rake test:grape'
      parallel_sh 'bundle exec appraisal contrib rake test:sidekiq'
      parallel_sh 'bundle exec appraisal contrib rake test:sucker_punch'
      # Contrib specs
      parallel_sh 'bundle exec appraisal contrib rake spec:action_pack'
      parallel_sh 'bundle exec appraisal contrib rake spec:action_view'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_model_serializers'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_record'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_support'
      parallel_sh 'bundle exec appraisal contrib rake spec:aws'
      parallel_sh 'bundle exec appraisal contrib rake spec:concurrent_ruby'
      parallel_sh 'bundle exec appraisal contrib rake spec:dalli'
      parallel_sh 'bundle exec appraisal contrib rake spec:delayed_job'
      parallel_sh 'bundle exec appraisal contrib rake spec:elasticsearch'
      parallel_sh 'bundle exec appraisal contrib rake spec:excon'
      parallel_sh 'bundle exec appraisal contrib rake spec:faraday'
      parallel_sh 'bundle exec appraisal contrib rake spec:graphql'
      parallel_sh 'bundle exec appraisal contrib rake spec:grpc'
      parallel_sh 'bundle exec appraisal contrib rake spec:http'
      parallel_sh 'bundle exec appraisal contrib rake spec:mongodb'
      parallel_sh 'bundle exec appraisal contrib rake spec:mysql2'
      parallel_sh 'bundle exec appraisal contrib rake spec:racecar'
      parallel_sh 'bundle exec appraisal contrib rake spec:rack'
      parallel_sh 'bundle exec appraisal contrib rake spec:rake'
      parallel_sh 'bundle exec appraisal contrib rake spec:redis'
      parallel_sh 'bundle exec appraisal contrib rake spec:resque'
      parallel_sh 'bundle exec appraisal contrib rake spec:rest_client'
      parallel_sh 'bundle exec appraisal contrib rake spec:sequel'
      parallel_sh 'bundle exec appraisal contrib rake spec:shoryuken'
      parallel_sh 'bundle exec appraisal contrib rake spec:sinatra'
      parallel_sh 'bundle exec appraisal contrib rake spec:ethon'
      # Rails minitests
      # We only test Rails 5+ because older versions require Bundler < 2.0
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis-activesupport rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails6-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails6-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails6-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails6-postgres-redis-activesupport rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails6-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails6-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails6-postgres rake test:railsdisableenv'
      # Rails specs
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails6-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails6-postgres rake spec:rails'
    end
  elsif Gem::Version.new('2.6.0') <= Gem::Version.new(RUBY_VERSION)
    # Main library
    parallel_sh 'bundle exec rake test:main'
    parallel_sh 'bundle exec rake spec:main'
    parallel_sh 'bundle exec rake spec:contrib'
    parallel_sh 'bundle exec rake spec:opentracer'

    if RUBY_PLATFORM != 'java'
      # Benchmarks
      parallel_sh 'bundle exec rake benchmark'
      # Contrib minitests
      parallel_sh 'bundle exec appraisal contrib rake test:grape'
      parallel_sh 'bundle exec appraisal contrib rake test:sidekiq'
      parallel_sh 'bundle exec appraisal contrib rake test:sucker_punch'
      # Contrib specs
      parallel_sh 'bundle exec appraisal contrib rake spec:action_pack'
      parallel_sh 'bundle exec appraisal contrib rake spec:action_view'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_model_serializers'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_record'
      parallel_sh 'bundle exec appraisal contrib rake spec:active_support'
      parallel_sh 'bundle exec appraisal contrib rake spec:aws'
      parallel_sh 'bundle exec appraisal contrib rake spec:concurrent_ruby'
      parallel_sh 'bundle exec appraisal contrib rake spec:dalli'
      parallel_sh 'bundle exec appraisal contrib rake spec:delayed_job'
      parallel_sh 'bundle exec appraisal contrib rake spec:elasticsearch'
      parallel_sh 'bundle exec appraisal contrib rake spec:excon'
      parallel_sh 'bundle exec appraisal contrib rake spec:faraday'
      parallel_sh 'bundle exec appraisal contrib rake spec:graphql'
      parallel_sh 'bundle exec appraisal contrib rake spec:grpc'
      parallel_sh 'bundle exec appraisal contrib rake spec:http'
      parallel_sh 'bundle exec appraisal contrib rake spec:mongodb'
      parallel_sh 'bundle exec appraisal contrib rake spec:mysql2'
      parallel_sh 'bundle exec appraisal contrib rake spec:racecar'
      parallel_sh 'bundle exec appraisal contrib rake spec:rack'
      parallel_sh 'bundle exec appraisal contrib rake spec:rake'
      parallel_sh 'bundle exec appraisal contrib rake spec:redis'
      parallel_sh 'bundle exec appraisal contrib rake spec:resque'
      parallel_sh 'bundle exec appraisal contrib rake spec:rest_client'
      parallel_sh 'bundle exec appraisal contrib rake spec:sequel'
      parallel_sh 'bundle exec appraisal contrib rake spec:shoryuken'
      parallel_sh 'bundle exec appraisal contrib rake spec:sinatra'
      parallel_sh 'bundle exec appraisal contrib rake spec:ethon'
      # Rails minitests
      # We only test Rails 5+ because older versions require Bundler < 2.0
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-redis-activesupport rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails5-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails5-postgres rake test:railsdisableenv'
      parallel_sh 'bundle exec appraisal rails6-mysql2 rake test:rails'
      parallel_sh 'bundle exec appraisal rails6-postgres rake test:rails'
      parallel_sh 'bundle exec appraisal rails6-postgres-redis rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails6-postgres-redis-activesupport rake test:railsredis'
      parallel_sh 'bundle exec appraisal rails6-postgres-sidekiq rake test:railssidekiq'
      parallel_sh 'bundle exec appraisal rails6-postgres-sidekiq rake test:railsactivejob'
      parallel_sh 'bundle exec appraisal rails6-postgres rake test:railsdisableenv'
      # Rails specs
      parallel_sh 'bundle exec appraisal rails5-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails5-postgres rake spec:rails'
      parallel_sh 'bundle exec appraisal rails6-mysql2 rake spec:rails'
      parallel_sh 'bundle exec appraisal rails6-postgres rake spec:rails'
    end
  end
end

task default: :test
