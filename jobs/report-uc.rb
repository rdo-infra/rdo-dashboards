#
# call bash script that creates virtualenv, then runs python script to publish
# report-uc status
#

feeder_script = "publish-report-uc.sh"
feeder_log = "publish-report-uc.log"

SCHEDULER.every '1d', :first_at => Time.now+3 do

  working_dir = Dir.pwd
  abs_path_feeder_script = "#{working_dir}/#{feeder_script}"
  abs_path_feeder_log    = "#{working_dir}/#{feeder_log}"

  puts("*** RUN --> #{abs_path_feeder_script} ***\n")

  feeder_script_output = `bash #{abs_path_feeder_script} 2>&1`

  # if you are debugging things...
  # puts(feeder_script_output)

  open(abs_path_feeder_log, 'a') { |f|
    f.puts "*** #{Time.now}: updating dashboard... ***"
    f.puts feeder_script_output
  }

end
