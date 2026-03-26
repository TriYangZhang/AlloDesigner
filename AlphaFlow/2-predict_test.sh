#!/bin/bash

python predict.py \
    --mode esmfold \
    --input_csv ./GLP-1/GLP1_chain_R_seqres.csv \
    --msa_dir ./alignment_dir/alignment_dir_GPL1 \
    --weights ./weights/esmflow_md_distilled_202402.pt \
    --sample 50 \
    --outpdb ./GLP-1/predict_output
    --noisy_first \
    --no_diffusion \
    --steps 50 \
