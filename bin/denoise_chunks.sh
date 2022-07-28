#!/bin/sh

#  normalize_chunks.sh
#  
#
#  Created by Alfie Wearn on 2021-08-18.
#  
# Inputs: Input chunk, Output (normalized) chunk name.
# Outputs: Chunks the original MRI scan for each ROI, ready to be normalized.

denoise_chunks() {
     
##  Set input names
    chunk_input=$1
    chunk_output=$2
    
    ## Normalise the brain regions using the μ +/- 3σ method
    
    echo "Denoising chunks using ANTS DenoiseImage"
    
    DenoiseImage -i ${chunk_input} -o ${chunk_output}
    
    if [ -f ${chunk_output} ]; then
        echo "Chunk denoising complete"
    else
        echo "Oops! Something has gone wrong and denoising was not completed properly"
    fi
}
