get_TA_stats_single_ep <- function(input, bins = 4) {
  
  # This function calculates TA statistics for a single ROI. 
# Inputs: input: dataframe with 4 elements: Subject ID, Session value, ROI name, ROI path
        # bins: The number of bins that the TA will be run on (relevant only for GLCM and GLRLM)
  
# Outputs: A single line dataframe containing all texture parameters and 
  # subject details. Ready for combining, with parallisation if neccessary
# Written by Alfie Wearn 2021-08-20. 
  
  # input_data <- input %>%
  #   read.csv(header=FALSE, col.names = c("ID","Session","roi_name","roi_path"))
  
  input_data <- input
  
  # Get lists of subject IDs and ROI names
  subj <- input_data$ID %>% as.character()
  ses <- input_data$Session %>% as.character()
  roi_name <- input_data$roi_name %>% as.character()
  roi_path <- input_data$roi_path %>% as.character()
  
  # Convert subject ID to ADNIMERGE-friendly version
  subj_id <- paste(substr(subj, 9, 11), substr(subj, 12,12), substr(subj, 13, 16), sep="_") 
  
  # Preallocate output matrix sizes with NAs. 
  # Multiply nrows by 10 to account for multiple sessions (over estimate)
  # 1. First-order stats (45 = 44 fo stats + 1 volume)
    fo_stats <- matrix(NA, nrow=1, ncol=45)
  
  # 2. GLCM/GLRLM stats.  
    glcm_stats <-  matrix(NA, nrow=1, ncol=240)
    glrlm_stats <-  matrix(NA, nrow=1, ncol=11)
    
  # 3. All stats
    ta_stats <- matrix(NA, nrow=length(bins), ncol=45+240+11+4)
    
    # Load brain chunk 
    ROI <- load_nifti(roi_path, reorient_in = FALSE)
    
    ## DO THE TEXTURE ANALYSIS! (Run entire process on each brain region).
    # Note: If you're going to change equal_prob to TRUE (which you probably shouldn't), 
    # make sure you Find & Replace all 'es_b' with 'ep_b' and vice versa.
    ROI <- ROI %>%
      radiomics_all(bins_in = bins, equal_prob = TRUE, geometry_discretized = FALSE)
    
  ## Output just the stats 
    # First-order (fo) stats 
    
    # Quartiles and Deciles are lists within the list. So need to reformat them otherwise everything breaks.
    # First save them as their own variables
    quartiles <- ROI$stat_fo$orig[['Quartiles']]
    deciles <- ROI$stat_fo$orig[['Deciles']]
    
    # Then remove 'Quartiles' and 'Deciles' lists 
    ROI$stat_fo$orig[['Quartiles']] <- NULL
    ROI$stat_fo$orig[['Deciles']] <- NULL
    
    # Then add them back in as their own variables.
    stat_fo_orig_fix <- c(ROI$stat_fo$orig, 
                           Quartile_25=quartiles[[1]], 
                           Quartile_75=quartiles[[2]],
                           Decile_10=deciles[[1]],
                           Decile_20=deciles[[2]],
                           Decile_30=deciles[[3]],
                           Decile_40=deciles[[4]],
                           Decile_50=deciles[[5]],
                           Decile_60=deciles[[6]],
                           Decile_70=deciles[[7]],
                           Decile_80=deciles[[8]],
                           Decile_90=deciles[[9]])

  # Add volume data to the first column
  fo_stats[1] <- do.call(cbind,ROI$stat_geometry$orig$volume)
    
  # And add the fo stats to the rest of columns
  fo_stats[2:45] <- do.call(cbind,stat_fo_orig_fix)
  

  # GLCM/GLRLM stats
  # (I couldn't work out how to loop this part for n in bins)
  if(2%in%bins){
    b2_glcm_stats <- do.call(cbind, ROI$stat_glcm_mean$ep_b2_d1_mean)
    b2_glrlm_stats <- do.call(cbind, ROI$stat_glrlm_mean$ep_b2_mean)
  }
  
  if(4%in%bins){
    b4_glcm_stats <- do.call(cbind, ROI$stat_glcm_mean$ep_b4_d1_mean)
    b4_glrlm_stats <- do.call(cbind, ROI$stat_glrlm_mean$ep_b4_mean)
  }
  
  if(8%in%bins){
    b8_glcm_stats <- do.call(cbind, ROI$stat_glcm_mean$ep_b8_d1_mean)
    b8_glrlm_stats <- do.call(cbind, ROI$stat_glrlm_mean$ep_b8_mean)
  }
  
  if(16%in%bins){
    b16_glcm_stats <- do.call(cbind, ROI$stat_glcm_mean$ep_b16_d1_mean)
    b16_glrlm_stats <- do.call(cbind, ROI$stat_glrlm_mean$ep_b16_mean)
  }
  
  if(32%in%bins){
    b32_glcm_stats <- do.call(cbind, ROI$stat_glcm_mean$ep_b32_d1_mean)
    b32_glrlm_stats <- do.call(cbind, ROI$stat_glrlm_mean$ep_b32_mean)
  }
  
  if(64%in%bins){
    b64_glcm_stats <- do.call(cbind, ROI$stat_glcm_mean$ep_b64_d1_mean)
    b64_glrlm_stats <- do.call(cbind, ROI$stat_glrlm_mean$ep_b64_mean)
  }

    
    ## Now save the necessary outputs
    
    # Grab column headers - only needs to be done once per data type (e.g. fo, glcm, glrlm).
    # Also add prefix to signify each data type (fo, glcm, glrlm)
    fo_cols <- paste("fo_", sep="", names(stat_fo_orig_fix))
    glcm_cols <- paste("glcm_", sep="", names(ROI$stat_glcm_mean$ep_b4_d1_mean))
    glrlm_cols <- paste("glrlm_", sep ="", names(ROI$stat_glrlm_mean$ep_b4_mean))
    
    # Volumes and first-order stats don't need to be run for each separate bin discretization,
    # but they do need to be in every output csv. So get column headers here, but
    # then insert into the loop.
    
    # Grab column names, and add 'VISCODE' (session ID) as a new column name.
    colnames(fo_stats) <- insert(fo_cols, 1, "Volume")
    
    
    loopcount <- 0
    # Now get GLCM/GLRLM stats for each discretization bin and write output files
    for (n in bins) {
       print(n)
      loopcount <- loopcount + 1
      
      # 'pre-get' variable names to simplify the rest of the code.
      glcm_stats_tmp <-  get(paste("b",n,"_glcm_stats",sep=""))
      glrlm_stats_tmp <-  get(paste("b",n,"_glrlm_stats",sep=""))
      
      # Add column names
      colnames(glcm_stats_tmp) <- glcm_cols
      colnames(glrlm_stats_tmp) <- glrlm_cols
      
      stats <- cbind(PTID = subj_id, VISCODE = ses, Region=roi_name,
                         bins = n, fo_stats, glcm_stats_tmp, glrlm_stats_tmp) %>%
        as.data.frame()
      
      if (loopcount > 1) {
        ta_stats <- rbind(ta_stats, stats)
      } else { 
        ta_stats <- stats
      }
      
    }
    
    return(ta_stats) 
} 
