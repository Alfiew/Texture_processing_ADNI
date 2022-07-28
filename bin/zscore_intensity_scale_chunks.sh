#!/bin/sh

#  zscore_intensity_scale_chunks.sh
#  
#
#  Created by Alfie Wearn on 2021-10-13
#  
# Inputs: Input chunk, Output (normalized) chunk name.
# Outputs: Chunks the original MRI scan for each ROI, ready to be normalized.

zscore_chunks() {
     
##  Set input names
    chunk_input=$1
    chunk_output=$2
    output_dir=$3
    
    ## Normalise the brain regions using the μ +/- 3σ method
    
    echo "Z-scoring masks"
    mean=$(fslstats ${chunk_input} -M) # Mean
    stdev=$(fslstats ${chunk_input} -S) # Standard Deviation
    
    fslmaths ${chunk_input} \
            -sub ${mean} \
            ${chunk_output}

    fslmaths ${chunk_output} \
            -div ${stdev} \
            ${chunk_output}

#    # Make all voxels around the ROI 0 (or -0...). Added on 2021-10-22
#    fslmaths ${chunk_output} \
#    -mas ${chunk_input} \
#    ${chunk_output}
#

    # Try out fslmaths' intensity normalisation tool!
#    fslmaths ${chunk_input} \
#    -inm ${mean} \
#    ${chunk_output}
#
    
    if [ -f ${chunk_output} ]; then
        echo "Chunk z-scoring complete"
    else
        echo "Oops! Something has gone wrong and Z-score normalization was not completed properly"
    fi
}
