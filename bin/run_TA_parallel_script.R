

  # This script will run texture analysis (using the RIA.R package) on a given list of ROIs.
  # The ROIs should be chunks of an MRI scan, normalized approrpriately.
  
  # The main input is a csv, with each ROI on a separate line, and each line has the following four fields:
    # [Subject ID],  [Session ID], [ROI name], [ROI Path]
  
  # Optionally, the number of bins in which to discretize the data can be set with the 'bins' option. 
  # Multiple bins can be given with the format e.g. bins = c(4,8,16). If this does not make sense, read ??RIA. 
  # Default is to run on 4 bins only. 4 must always be included, or else will crash! Shoud also be a square number.
  
  # Also optionally, the number of 'threads' may be specified (Default = 5). This is number of parallel runs
  # that will occur, and should not exceed the number of threads available on the machine on which it is run. 
  
  # THe final option (save_csv) is to choose whether csv files are outputted or not. Default is true. 

  # The output is a dataframe containing all texture analysis data, with one row per row in the input file,
  # for each bin given. 
  
  # May need to run 'source("get_TA_stats_single") if it's not in the .Rprofile. 
  
# Written by Alfie Wearn 2021-08-20. 

# install.packages(c("RIA","fslr","tidyverse","R.utils","foreach","doParallel","parallel"))

# Load packages
library(RIA)
library(fslr)
library(tidyverse)
library(R.utils)
library(methods)
library(foreach)
library(doParallel)

# Get command arguments. Notes args[1] is "--args".
args <- commandArgs(trailingOnly = TRUE)

input <- args[2]
bins <- eval(parse(text=args[3]))
threads <- args[4]
save_csv <- args[5]
  
source("bin/get_TA_stats_single.R")

## Set up parallelisation. 
doParallel::registerDoParallel(threads) #Define how many threads to use. Albany has ~50 cores, 2 threads each. 

# Make output data directory
# dir.create("data")

# Read in the input file
input_data <- input %>%
  read.csv(header=FALSE, col.names = c("ID","Session","roi_name","roi_path"))


# RUN PARALLELISATION LOOP
ta_stats_all <- foreach(i=1:nrow(input_data), .combine = "rbind", .inorder = FALSE,
          .packages=c('RIA','fslr','tidyverse','R.utils','get_TA_stats_single','foreach','doParallel','parallel'), .errorhandling = c("pass"), .verbose=TRUE) %dopar% {
  
          # Calculate TA stats for a single line of the input file
          input_line <- input_data[i,] 
          
          ta_stats_single <- get_TA_stats_single(input = input_line, bins = bins)
          }

  # Reformat session ID (VISCODE) so that it matches ADNIMERGE
  ta_stats_all$VISCODE <- str_replace_all(ta_stats_all$VISCODE, "ses-M", "m") %>%
     str_replace_all("m00","bl")


  if (isTRUE(save_csv)) {
    write.csv(ta_stats_all,
              file = "data/ta_stats.csv",
              row.names = FALSE)
  }
 
 # return(ta_stats_all)

      


