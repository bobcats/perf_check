class PerfCheck

  def print_diff_results(diff)
    if diff.changed?
      print(" Diff: #{diff.file}".bold.light_red)
    else
      print(" Diff: Output is identical!".bold.light_green)
    end
  end

  def print_brief_results
    test_cases.each do |test|
      print(test.resource.ljust(40) + ': ')

      codes = (test.this_profiles+test.reference_profiles).map(&:response_code).uniq
      print("(HTTP "+codes.join(',')+") ")

      printf('%.1fms', test.this_latency)

      puts && next if test.reference_profiles.empty?

      print(sprintf(' (%+5.1fms)', test.latency_difference).bold)
      print_diff_results(test.response_diff) if options.verify_no_diff
      puts
    end
  end

  def print_full_results
    puts("==== Results ====")
    test_cases.each do |test|
      puts(test.resource.bold)

      if test.reference_profiles.empty?
        printf("your branch: ".rjust(15)+"%.1fms\n", test.this_latency)
        next
      end

      master_latency = sprintf('%.1fms', test.reference_latency)
      this_latency = sprintf('%.1fms', test.this_latency)
      difference = sprintf('%+.1fms', test.latency_difference)

      if test.latency_difference < 0
        change_factor = test.reference_latency / test.this_latency
      else
        change_factor = test.this_latency / test.reference_latency
      end
      formatted_change = sprintf('%.1fx', change_factor)

      percent_change = 100*(test.latency_difference / test.reference_latency).abs
      if percent_change < 10
        formatted_change = "yours is about the same"
        color = :blue
      elsif test.latency_difference < 0
        formatted_change = "yours is #{formatted_change} faster!"
        color = :green
      else
        formatted_change = "yours is #{formatted_change} slower!!!"
        color = :light_red
      end
      formatted_change = difference + " (#{formatted_change})"

      puts("reference: ".rjust(15)  + "#{master_latency}")
      puts("your branch: ".rjust(15)+ "#{this_latency}")
      puts(("change: ".rjust(15)    + "#{formatted_change}").bold.send(color))

      print_diff_results(test.response_diff) if options.verify_no_diff
    end
  end
end
