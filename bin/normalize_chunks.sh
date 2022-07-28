#!/bin/sh

#  normalize_chunks.sh
#  
#
#  Created by Alfie Wearn on 2021-08-18.
#  
# Inputs: Input chunk, Output (normalized) chunk name.
# Outputs: Chunks the original MRI scan for each ROI, ready to be normalized.

normalize_chunks() {
     
##  Set input names
    chunk_input=$1
    chunk_output=$2
    
    ## Normalise the brain regions using the μ +/- 3σ method
    
    echo "Normalizing masks using μ +/- 3σ method"
    mean=$(fslstats ${chunk_input} -M) # Mean
    stdev=$(fslstats ${chunk_input} -S) # Standard Deviation
    
    uthr=$(awk "BEGIN {print $mean + (3 * $stdev)}")
    lthr=$(awk "BEGIN {print $mean - (3 * $stdev)}")
    
    fslmaths ${chunk_input} \
            -thr ${lthr} \
            -uthr ${uthr} \
            ${chunk_output}
    
    if [ -f ${chunk_output} ]; then
        echo "Chunk normalization complete"
    else
        echo "Oops! Something has gone wrong and ROI extraction was not completed properly"
    fi
}
