# This needs to be put into a script, so that it can be run with nohup on the server. 

run_TA_parallel(input = "R_input_list_z_denoise_tail25k.txt",
                output = "data/ta_stats_ASHST1_z_denoise_tail25k.csv",
                bins = c(4,8,16,32),
                threads = 40)
