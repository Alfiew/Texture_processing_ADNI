#!/bin/sh

#  run_TA_roi_prep.sh
#  
#
#  Created by Alfie Wearn on 2021-08-23.
#  
# This will be the single wrapper script that calls the entire TA processing pipeline.
# Requires all registrations to be complete already.

# Max number of parallel runs (default):
N=45

# Two arguments must be given. 1st is the input subjects list. the second is the another list, that will serve as an input to the R scripts that follow.
input_list=$1
R_list=$2

# Source constituent functions
source ./bin/extract_chunks.sh
source ./bin/normalize_chunks.sh


while IFS=, read -r subj_id ses_id roi_name desc mri_path roi_path output_dir || [ -n "$output_dir" ]; do

    # Paralellisation limiter
    ((i=i%N)); ((i++==0)) && wait

    run_TA_roi_prep() {
    
            echo ""
            echo "ID: $subj_id"
            echo "Session: $ses_id"
            echo "ROI: $roi_name"
            echo "Descriptor: $desc"
            echo "MRI Path: $mri_path"
            echo "ROI Path: $roi_path"
            echo "Output directory: $output_dir"
            echo ""

#
#        if [[ "$roi_name" == "LeftCA12" ]]; then
#            echo "Deleting cockups for $subj_id $ses_id"
#            rm $output_dir/${roi_name}_chunk.nii.gz
#            rm $output_dir/${roi_name}_chunk_normalized.nii.gz
#        fi
#
        # Make the output directory if it doesn't already exist
        mkdir -p $output_dir

        if [ ! -f $output_dir/${roi_name}_chunk_${desc}.nii.gz ]; then
            # Extract chunks of the MRI input using the ROI input
            extract_chunks $mri_path $roi_path $output_dir/${roi_name}_chunk_${desc}.nii.gz
        fi
        
        if [ ! -f $output_dir/${roi_name}_chunk_normalized_${desc}.nii.gz ]; then
            # Normalize those created chunks using the μ +/- 3σ method
            normalize_chunks $output_dir/${roi_name}_chunk_${desc}.nii.gz $output_dir/${roi_name}_chunk_normalized_${desc}.nii.gz
        fi
        
    }

# Run the ROI prep in parallel
run_TA_roi_prep &

done < $input_list


# Wait for that step to finish before starting the next
wait $!

# Create a list for input into R function
# [ID][Session][roi_name][roi_path (normalized chunk)]

# Remove list if it already exists
if [ -f $R_list ]; then
    echo "Removing exisiting $R_list"
    rm $R_list.txt
fi

while IFS=, read -r subj_id ses_id roi_name desc mri_path roi_path output_dir || [ -n "$output_dir" ]; do

    echo "$subj_id,$ses_id,$roi_name,$output_dir/${roi_name}_chunk_normalized_${desc}.nii.gz" >> $R_list

done < $input_list


echo "$R_list created. Next step:"
echo "Open R environment and run run_TA_parallel with input = \"$R_list\" and  threads = \$N"

