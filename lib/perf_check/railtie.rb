class PerfCheck
  class Railtie < Rails::Railtie

    config.before_initialize do

      if defined?(Rack::MiniProfiler)
        # Integrate with rack-mini-profiler
        tmp = "#{Rails.root}/tmp/perf_check/miniprofiler"
        FileUtils.mkdir_p(tmp)

        Rack::MiniProfiler.config.storage_instance =
          Rack::MiniProfiler::FileStore.new(:path => tmp)
      end

      # Force cache_classes = true .... :\
      Rails::Application::Configuration.send(:define_method, :cache_classes){ true }
    end
  end
end