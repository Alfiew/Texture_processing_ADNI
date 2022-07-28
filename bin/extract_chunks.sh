#!/bin/sh

#  extract_chunks.sh
#  
#
#  Created by Alfie Wearn on 2021-08-18.
#   This function is for extracting ROIs from an MRI scan. Will be part of the texture analysis pipeline.
# Inputs: Path to MRI scan, Path to ROI mask, Output chunk name.
# Outputs: Chunks the original MRI scan for each ROI, ready to be normalized.
#
# Input MRI scan and ROI need to have been registered to the same space.

extract_chunks() {

##  Set input names
    mri_input=$1
    roi_input=$2
    output=$3

   ## Extract Chunks
    echo "Getting chunk"
    fslmaths $mri_input -mas $roi_input $output

    if [ -f $output ]; then
        echo "ROI extraction complete"
    else
        echo "Oops! Something has gone wrong and ROI extraction was not completed properly"
    fi
}
