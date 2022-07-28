run_TA_parallel <- function(input, output, bins = 4, threads = 5, save_csv = TRUE) {

  # This script will run texture analysis (using the RIA.R package) on a given list of ROIs.
  # The ROIs should be chunks of an MRI scan, normalized approrpriately.
  
  # The main input is a csv, with each ROI on a separate line, and each line has the following four fields:
    # [Subject ID],  [Session ID], [ROI name], [ROI Path]
  
  # Optionally, the number of bins in which to discretize the data can be set with the 'bins' option. 
  # Multiple bins can be given with the format e.g. bins = c(4,8,16). If this does not make sense, read ??RIA. 
  # Default is to run on 4 bins only. 4 must always be included, or else will crash! Should also be a square number.
  
  # Also optionally, the number of 'threads' may be specified (Default = 5). This is number of parallel runs
  # that will occur, and should not exceed the number of threads available on the machine on which it is run. 
  
  # THe final option (save_csv) is to choose whether csv files are outputted or not. Default is true. 

  # The output is a dataframe containing all texture analysis data, with one row per row in the input file,
  # for each bin given. 
  
  # May need to run 'source("get_TA_stats_single") if it's not in the .Rprofile. 
  
  # The loop will time out and move on after a few minutes if it's taking too long! This helps weed out errors. 
  
# Written by Alfie Wearn 2021-08-20. 

# install.packages(c("RIA","fslr","tidyverse","R.utils","foreach","doParallel"))

# Load packages
library(RIA)
library(fslr)
library(tidyverse)
library(R.utils)
library(methods)
library(foreach)
library(doParallel)

source("bin/get_TA_stats_single.R")

## Set up parallelisation. 
doParallel::registerDoParallel(threads) #Define how many threads to use. Albany has ~50 cores, 2 threads each. 

# Make output data directory
dir.create("data")

# Name output csv file
filename <- output

# Read it in a previous run, and determine how many rows there are.
# This helps to pick up after a crash. 
# This actually doesn't work correctly - some rows may be missed or duplicated. Better to run it all in one go
if (file.exists(filename)) {
previous_rows <- filename %>% 
  read.csv() %>%
  nrow()/length(bins)
} else {
  previous_rows <- 0
}

# Read in the input file
input_data <- input %>%
  read.csv(header=FALSE, col.names = c("ID","Session","roi_name","roi_path"))

input_rows <- nrow(input_data)

# Split into chunks, and save after each one. Allows one to pick up and carry on after a crash. 
chunk_multiplyer <- 5 # How many lines to run per thread before saving to CSV?
chunk_size <- threads*chunk_multiplyer
chunk_list <- seq(previous_rows+1,input_rows, by = chunk_size)

  for (chunk in chunk_list) {
  
    chunk_end <- chunk+chunk_size-1
    
    # Ensure the loop doesn't try to go further than the end of the input list. 
    if (chunk_end > input_rows) {
      chunk_end <- input_rows
    }
      
    # RUN PARALLELISATION LOOP
    ta_stats_all <- foreach(i=chunk:chunk_end, .combine = "rbind", .inorder = FALSE,
              .packages=c('RIA','fslr','tidyverse','R.utils'), .errorhandling = c("remove"), .verbose=TRUE) %dopar% {
      
              # Calculate TA stats for a single line of the input file
              input_line <- input_data[i,] 
              
              # Run the TA calculation function, with a timeout of 1 minute per subject per chunk 
              # Normal time should be approx 30 seconds (for bins = c(4,8)). Also multiply it by number
              # of bin discretizations to account for longer times for more bins.
              # If a timeout is given, a warning will be given and this value will be skipped.
              # So long as .errorhandling = c("remove") in foreach function arguments. 
              
                ta_stats_single <- withTimeout({
                  get_TA_stats_single(input = input_line, bins = bins);
                }, timeout=chunk_multiplyer*length(bins)*60, onTimeout="error");
 

              # # For people who time out...
              # # Can i also get it to still include subject ID and session ID? And brain region? ...
              # # Probably, because that info is here anyway. Put it all in the if statement.
              #   if (is.character(ta_stats_single)) {
              #     subj <- input_line$ID %>% as.character()
              #     ses <- input_line$Session %>% as.character()
              #     roi <- input_line$roi_name %>% as.character()
              #     # # Convert subject ID to ADNIMERGE-friendly version
              #     subj_id <- paste(substr(subj, 9, 11), substr(subj, 12,12), substr(subj, 13, 16), sep="_")
              #     
              #     ta_stats_single <- matrix(NA, nrow=length(bins), ncol=45+240+11+4)
              #     ta_stats_single <- as.data.frame(ta_stats_single)
              #     ta_stats_single[,1] <- subj_id
              #     ta_stats_single[,2] <- ses
              #     ta_stats_single[,3] <- roi
              #     ta_stats_single[,4] <- bins
              #     ta_stats_single <- ta_stats_single %>% rename(PTID = V1, VISCODE = V2, Region = V3, bins = V4)
              #   }
                

              return(ta_stats_single)  
              }
    
    # If ta_stats_all is NULL (all in chunk timed out), do not save. There will be a problem with column names if the first chunk fails
    if (!is.null(ta_stats_all)) {
      
      # Reformat session ID (VISCODE) so that it matches ADNIMERGE
      ta_stats_all$VISCODE <- str_replace_all(ta_stats_all$VISCODE, "ses-M", "m") %>%
         str_replace_all("m00","bl")
    
     # Save the CSV. Only import column names if it's the first chunk
      if (isTRUE(save_csv)) {
        if (chunk == 1) {
          write.table(ta_stats_all, file = filename,
                      append = TRUE, sep = ",", row.names = FALSE, col.names = TRUE)
        } else {
          write.table(ta_stats_all, file = filename,
                      append = TRUE, sep = ",", row.names = FALSE, col.names = FALSE)
        }
      }
 
    }
  }
return(ta_stats_all)
}

