#
# call bash script that creates virtualenv, then runs python script to update dashboard
#
# helpful: https://stackoverflow.com/questions/2232/calling-shell-commands-from-ruby
#

feeder_script = "update-dashboard-from-smashingcron.sh"
feeder_log = "feed-dashboard.log"

SCHEDULER.every '15m', :first_at => Time.now do

  working_dir = Dir.pwd
  abs_path_feeder_script = "#{working_dir}/#{feeder_script}"
  abs_path_feeder_log    = "#{working_dir}/#{feeder_log}"

  puts("*** RUN --> #{abs_path_feeder_script} ***\n")

  feeder_script_output = `bash #{abs_path_feeder_script}`

  # if you are debugging things...
  # puts(feeder_script_output)

  open(abs_path_feeder_log, 'a') { |f|
    f.puts "*** #{Time.now}: updating dashboard... ***"
    f.puts feeder_script_output
  }

end