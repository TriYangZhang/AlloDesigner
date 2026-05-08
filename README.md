# AlloDesigner

AlloDesigner, an end-to-end computational framework that integrates geometric deep learning with physics-based enhanced sampling to discover cryptic functional states.

## Overview

The repository contains three main components:

| Module | Purpose |
| --- | --- |
| `AlphaFlow/` | Generates large numbers of apo protein conformations from input sequences. The environment and model setup follow the AlphaFlow project. |
| `Allo-PocketMiner/` | Trains and applies the Allo-PocketMiner GNN model for residue-level allosteric/cryptic-pocket prediction. |
| `Allo_af_claseq/` | Runs the downstream MSA purification and iterative sampling strategy for AI-guided preferred initial conformation sampling. |

The intended workflow is:

1. Generate apo conformational ensembles from protein sequences with `AlphaFlow/`.
2. Predict pocket-related residues or score candidate apo structures with `Allo-PocketMiner/`.
3. Refine the sampling space with the MSA purification and iterative sequence/structure selection pipeline in `Allo_af_claseq/`.

## Repository Structure

```text
AlloDesigner/
|-- AlphaFlow/
|   |-- 1-mmseqs_search_helper.py
|   |-- 2-predict_test.sh
|   `-- GLP1_chain_seqres.csv
|-- Allo-PocketMiner/
|   |-- data/
|   |-- model_weight/
|   |-- outputs/
|   |-- case_predict.py
|   |-- test.py
|   |-- train_DiceBCELoss.py
|   |-- *_datasets.py
|   |-- models.py
|   |-- gvp.py
|   `-- util.py
`-- Allo_af_claseq/
    |-- 1_* to 13_* pipeline scripts
    |-- select_random_msa_predict.py
    |-- combined_a3m.py
    |-- 11_sequence_voting.py
    |-- 12_recompile.py
    `-- scoring/metric helper scripts
```

## 1. AlphaFlow: Apo Conformation Generation

`AlphaFlow/` contains helper scripts for sequence-based apo ensemble generation.

Typical inputs include a CSV file with protein names and sequences, for example:

```text
pdb,seqres,release_date,msa_id,seqlen
```

Main files:

- `GLP1_chain_seqres.csv`: example sequence input.
- `1-mmseqs_search_helper.py`: prepares A3M MSA files with MMseqs/ColabFold-style database search.
- `2-predict_test.sh`: example AlphaFlow/ESMFlow prediction command for generating multiple apo conformations.

Environment installation and model-weight preparation can follow the official AlphaFlow repository:

- https://github.com/bjing2016/alphaflow

Example workflow:

```bash
cd AlphaFlow

python 1-mmseqs_search_helper.py \
  --split ./GLP1_chain_seqres.csv \
  --db_dir ./dbbase \
  --outdir ./alignment_dir/alignment_dir_GLP1

bash 2-predict_test.sh
```

Before running, update the input CSV path, MSA directory, model weights, sample number, and output directory in the scripts.

## 2. Allo-PocketMiner: GNN Pocket Prediction

`Allo-PocketMiner/` contains the trained GNN model used by AlloDesigner. The model follows the Geometric Vector Perceptron/PocketMiner style and performs residue-level prediction from protein structural features.

Main files:

- `models.py`, `gvp.py`: neural network architecture.
- `train_DiceBCELoss.py`: training script using Dice + binary cross-entropy loss.
- `test.py`: test-set evaluation script.
- `case_predict.py`: case-level residue prediction script.
- `train_datasets.py`, `test_datasets.py`, `case_datasets.py`: data loaders for preprocessed `.npy` datasets.
- `model_weight/`: included model checkpoint files.
- `data/`: small included example/case data. The full training data is not fully stored in this repository because of its size.

The complete data package is available at:

- https://zenodo.org/records/19234183

Environment installation can follow the PocketMiner/GVP `pocket_pred` branch:

- https://github.com/Mickdub/gvp/tree/pocket_pred

Example commands:

```bash
cd Allo-PocketMiner

# Evaluate on the configured test dataset
python test.py

# Train or fine-tune the model
python train_DiceBCELoss.py

# Predict residue-level probabilities for a configured case
python case_predict.py
```

Notes:

- `train_datasets.py` expects preprocessed training arrays under `data/holo-apo-chain/`.
- `test_datasets.py` and `case_datasets.py` currently point to specific local test/case `.npy` files.
- Modify dataset paths and prediction thresholds in the scripts for new targets.

## 3. Allo_af_claseq: MSA Purification and Iterative Sampling

`Allo_af_claseq/` implements the downstream sampling pipeline. It further uses MSA purification and iterative selection to enrich preferred initial conformations under AI-guided scoring.

The scripts cover:

- extracting and shuffling PDB/MSA inputs;
- running fpocket on sampled structures;
- calculating pocket centers and pocket-to-cluster distances;
- clustering residues and candidate pockets;
- scoring structures with Allo-PocketMiner, DeepAllo-style scores, and PLB-related metrics;
- voting on sequence/MSA bins;
- recompiling purified MSA subsets for the next sampling iteration.

Representative files:

- `select_random_msa_predict.py`: randomly samples sequences from an A3M file to create control/prediction MSA files.
- `combined_a3m.py`: combines selected A3M sequences after iterative sampling.
- `6_inference_case_pocketminer_cluster_to_deepallo_run.py`: maps pocket-miner cluster outputs into DeepAllo-style scoring.
- `7_plb_calculation_pocketminer_apo_dir_step3.py`: PLB-related scoring workflow.
- `8_cluster_residues.py`: residue clustering.
- `11_sequence_voting.py`: sequence voting and binning.
- `12_recompile.py`: recompiles sequences from selected voting bins for the next prediction round.

Many scripts are case-specific and contain hard-coded example paths such as `GLP1`, `CB1R`, `PCSK9`, or `1HZB`. Before running the pipeline on a new protein, update:

- input apo/holo PDB paths;
- chain IDs;
- A3M/MSA paths;
- AlphaFlow prediction output paths;
- fpocket output directories;
- Allo-PocketMiner result paths;
- iteration and shuffle directory names.

## Data

Because the Allo-PocketMiner training data is large, this repository only keeps a lightweight subset and example case data. Download the complete dataset from Zenodo:

```text
https://zenodo.org/records/19234183
```

After downloading, place the preprocessed arrays in the expected `Allo-PocketMiner/data/` subdirectories or update the loader paths in:

- `Allo-PocketMiner/train_datasets.py`
- `Allo-PocketMiner/test_datasets.py`
- `Allo-PocketMiner/case_datasets.py`

## External Dependencies

The project relies on the environments and tools used by its component workflows:

- AlphaFlow/ESMFlow and OpenFold-style dependencies for ensemble generation.
- TensorFlow, NumPy, SciPy, pandas, tqdm, and GVP/PocketMiner dependencies for Allo-PocketMiner.
- BioPython, PyTorch, transformers, AutoGluon/XGBoost, fpocket, and structure-processing utilities for the Allo_af_claseq downstream pipeline.

For reproducible setup, start from the environment instructions in:

- AlphaFlow: https://github.com/bjing2016/alphaflow
- PocketMiner/GVP: https://github.com/Mickdub/gvp/tree/pocket_pred

## Citation and Acknowledgements

This project builds on AlphaFlow and PocketMiner/GVP-style geometric deep learning components. Please cite the corresponding upstream methods when using this workflow:

- AlphaFlow: https://github.com/bjing2016/alphaflow
- PocketMiner/GVP: https://github.com/Mickdub/gvp/tree/pocket_pred
