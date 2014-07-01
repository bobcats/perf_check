# coding: utf-8

require 'optparse'
require 'net/http'
require 'digest'
require 'fileutils'
require 'benchmark'
require 'ostruct'

class PerfCheck
  attr_accessor :options, :server, :test_cases

  def self.require_rails
    ENV['RAILS_ENV'] = 'development'
    ENV['PERF_CHECK'] = '1'

    app_root = Dir.pwd
    until app_root == '/' || File.exist?("#{app_root}/config/application.rb")
      app_root = File.dirname(app_root)
    end

    unless File.exist?("#{app_root}/config/application.rb")
      abort("perf_check should be run from a rails directory")
    end

    require "#{app_root}/config/boot"

    require 'rails/all'
    Rails::Application::Configuration.send(:define_method, :cache_classes){ true }

    require "#{app_root}/config/environment"
  end

  def initialize
    self.options = OpenStruct.new
    self.server = Server.new
    self.test_cases = []
  end

  def add_test_case(route)
    route = PerfCheck.normalize_resource(route)
    test_cases.push(TestCase.new(route))
  end

  def sanity_check
    if Git.current_branch == "master"
      puts("Yo, profiling master vs. master isn't too useful, but hey, we'll do it")
    end

    puts "="*77
    print "PERRRRF CHERRRK! Grab a ☕️  and don't touch your working tree "
    puts "(we automate git)"
    puts "="*77
  end

  def run
    (options.reference ? 2 : 1).times do |i|
      if i == 1
        Git.stash_if_needed
        Git.checkout_reference(options.reference)
        test_cases.each{ |x| x.latencies = x.reference_latencies }
      end

      test_cases.each do |test|
        server.restart
        if options.login
          test.cookie = server.login(options.login, test)
        end

        puts("\n\nBenchmarking #{test.resource}:")
        test.run(server, options.number_of_requests)
      end
    end
  end

  def print_results
    puts("==== Results ====")
    test_cases.each do |test|
      puts(test.resource)

      if test.reference_latencies.empty?
        printf("your branch: ".rjust(15)+"%.1fms\n", test.this_latency)
        next
      end

      master_latency = sprintf('%.1fms', test.reference_latency)
      this_latency = sprintf('%.1fms', test.this_latency)

      difference = sprintf('%+.1fms', test.latency_difference)
      if test.latency_difference < 0
        formatted_change = sprintf('%.1fx', test.latency_factor)
        formatted_change = "yours is #{formatted_change} faster!"
      else
        formatted_change = sprintf('%.1fx', 1.0 / test.latency_factor)
        formatted_change = "yours is #{formatted_change} slower!!!"
      end
      formatted_change = difference + " (#{formatted_change})"

      puts("master: ".rjust(15)     + "#{master_latency}")
      puts("your branch: ".rjust(15)+ "#{this_latency}")
      puts("change: ".rjust(15)     + "#{formatted_change}")
    end
  end
end


require 'perf_check/server'
require 'perf_check/test_case'
require 'perf_check/git'
