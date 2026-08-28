

# IgDiscover Pipeline


This guide walks you through setting up and running **IgDiscover** for B-cell receptor (BCR) germline inference using multiplex data and the IgDiscover primer sets. It includes installation, OGRDB database setup, config tuning by chain type, and decision points based on the study (IgM, IgG, IgK, or IgL).

The figure below outlines the high-level steps:

![Pipeline Diagram](pipeline.drawio.svg)

## 1. Installation

IgDiscover requires Python 3.8+ and conda. If you do not have conda set up, use the (mini-forge](https://github.com/conda-forge/miniforge), then install igdiscover using `install.sh`. 

You may also want to install additional tools for QC and converting bcl data to fastq:
- fastqc `conda install bioconda::fastqc`
- multiqc `conda install bioconda::multiqc`
- bcl-convert `https://support.illumina.com/downloads/bcl-convert-v4-5-4-installers.html`

## 2. Download and Prepare the Database (OGRDB)

1. Visit: https://ogrdb.airr-community.org/. See the [database README](ogrdb_database/README.md) for details
2. After download, we can convert them to individual files using the [Extract VDJ Script](extract_VDJ_fasta.py)
3. Download the expected.tsv file from: https://gitlab.com/gkhlab/corecount-genotyping and add to each chain database folder
4. Download the Auxilary file from: https://ftp.ncbi.nih.gov/blast/executables/igblast/release/patch/optional_file/human_gl.aux


## 3. Setting Up a Project

### 3.1 Start a New Project

```bash
igdiscover init --reads1 your_sample_R1.fastq.gz --db output_db_dir my_project
```

### 3.2 Adjust the Config File

Edit `my_project/igdiscover.yaml` to match your experimental setup:

```yaml

# Set pre-CDR3 range depending on chain type:
pre_cdr3_trim:
  IGHV: [-130, -95]      # Default for IgM
  IGKV: [-165, -130]     # For IgK with custom primers
  IGLV: [-125, -90]      # For IgL with custom primers

iterations: 1  # For IgM/IgK/IgL; use 0 for IgG with known genotype

expected_filter: 'expected.tsv'
aux: human_gl.aux
```
The adjustments can be made directly in the config file after the `igdiscover init` step, or an optimised config can be copied to replace the generated config, facilitating easy automation of the run. 


## 4. Running the Pipeline

```bash
cd my_project
igdiscover run | tee igdiscover_run.log
```
On this step, can use the `run_igdiscover.sh` for the full step, including copying the config file. 

Alternatively, one can also use the `igdiscover batch run` to automate the run, where it looks for the `igdiscover.yaml` in the initialized folders, and then runs the full analysis. 


## 5. Post-processing: Corecount

To rescue filtered alleles or correct end-trimming issues:

```bash
igdiscover corecount   --gene V   final/database/V.fasta   final/assigned.tsv.gz   final/corecount_assigned.tsv
```

This helps:
- Rescue low-frequency alleles
- Identify end-corrected variants



## 6. IgG Analysis with Personalized Database

1. Run IgM as usual to infer alleles.
2. Use `final/new_V_germline.fasta` as the personalized DB for IgG.
3. Create IgG project with `iterations: 0`:

```bash
igdiscover init --reads1 IgG_sample.fastq.gz --db path/to/new_V_germline.fasta igg_project
```

Edit config:
```yaml
iterations: 0
```

Run the assignment:
```bash
cd igg_project
igdiscover run
```

# Some things to note:
1. The settings can be adjusted after the initial run based on rescue genes/alleles filtered out based on a single reason. This information can be identified from the `iteration-01/annotated_V_germline.tsv`, by filtering those that have been filtered for a single reason. In most cases, a pattern emerges depending on the data. For those that have been filtered but additional evidence like the number of clusters, presence in other samples in the cohort, etc, can inform adjustment of the cutoffs to be less stringent. 
2. Plotalleles can also be used to identify alleles
