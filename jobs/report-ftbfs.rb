#
# call bash script that creates virtualenv, then runs python script to publish
# report-ftbfs status
#
feeder_script = "generate-report-ftbfs.sh /tmp/ftbfs_report.csv"
feeder_log = "generate-report-ftbfs.log"

SCHEDULER.every '15m', first_in: '0m' do

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

