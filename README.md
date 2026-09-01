# IntraSwedish_crosses_NGS_data

A repository to manage raw short-read DNA sequencing data files for a panel of *Arabidopsis thaliana* Intra-Swedish crosses.

Briefly this project involves:

* 219 ecotypes of *A. thaliana* collected from diverse habitats around Sweden that show strong population structure
* Putting those ecotypes through one round of random mating by controlled crossing
* Propogating offspring of those crosses by self fertilisation to remove heterozygosity.

This repository manages the processing of raw short-read NGS data generated as part of this project, and its submission to the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home).
It does not contain any sequence data - this is hosted on ENA under project PRJEB123735.
It also does not include details of downstream processing - see the [accompanying draft repository](https://github.com/ellisztamas/1001crosses).

Note that I am submitting the raw data before the publication of a formal manuscript about this project.
This is because ENA requires a DOI for a publicly accessible page giving the experimental details at submission, but a publication would require the data to be submitted already.
This repo is a pragmatic attempt to square that circle by giving me a DOI I can use for the ENA submission.


## Experimental details

### Growth and wet-lab procedures

We sowed seeds onto a 4:1 mixture of soil (K Substrat 2) and perlite (Gramoflor) in 5cm pots.
After treating with nematodes to control blackfly we stratified seeds at 4°C for one week.
We moved plants to a climate-controlled growth chamber at the Plant-Science facility of the Gregor Mendel Institute (Dr.-Bohr-Gasse 3, 1030 Vienna, Austria) at 10°C and a 16:8-hour light:dark schedule under LED lighting.
Once plants had flowered we moved them to a green house at 21°C under sodium lighting.
Where plants were to be sequenced, we harvested mature leaf tissue from one plant each of each line and placed it at -70°C.
Once all siliques had fully formed we ceased irrigation to allow seeds to dry.
After collection, we stored seeds at 16°C.

We extracted DNA with [kit name] and processed them with [library kit].
Libraries were sequenced by the Next Generation Sequencing Facility at Vienna BioCenter Core Facilities (VBCF), on an S2 flow cell of an Illumina NovaSeq X, using manufacturer’s standard cluster generation and sequencing tools.

### Sequencing

#### Parental lines

Data on most parental lines are available from the [1001 genomes project](https://1001genomes.org/) (see also the "Master list" link at the bottom of this link for sample metadata of the global collection).
28 additional lines were sequenced by [Brachi *et al.* (2022)](https://doi.org/10.1073/pnas.2201285119), who also repeated the SNP calls from raw data using more modern methods than the original study.
For most parental lines, we use SNP calls from the latter paper (available [here](https://doi.org/10.1073/pnas.2201285119)) for further analysis, and are not included in this repostory.

This repository includes new sequence data for several ecotypes:

* Lines Brösarp-61-162 and Gårdby-22-213 (accession IDs 1074 and 1137) that had not previously been included in any genotyping efforts.
* Lines Röd-17-319 and Bil-3 (accession IDs 1435 and 5835) had been previously sequenced (Brachi et al 2022), but we suspected that the seed stock used in that study had been mixed up with other Swedish lines. We resequenced these ecotypes using older seed stock dating from the time of the crosses.
* We also resequenced ecotypes where we suspected there may have been sequencing errors or unresolved segregating haplotypes. For this reason we sequenced multiple independent plants per ecotype. In fact, these data were not helpful in this regard, but I include them here for completeness. The ecotypes were:
    * TDr-14 (6199)
    * Ale-Stenar-44-4 (992)
    * Ängsö-80-432 (1318)
    * Hamm-1 (9399)
    * Löv-1 (6043)

#### Cross lines

We sequenced crossed lines at the F8 and F10 generations.
These samples were processed in several batches, and this repository handles each batch separately:

* **F8 low coverage**: 429 samples at the F8 generation, split over five 96-well plates. Plates 1-4 were sequenced across two lanes. These data were sequenced with 100bp paired-end reads aiming for nominal coverage of 10x.
* **F8 high coverage**: a repetition of 91 samples of F8 lines that either did not produce usable data initially, or appeared to show mismatching genotypes from their parents due to sample mix-ups, residual heterozygosity, or segregating haplotypes in the parental seed stock. These data were sequenced with 150bp paired-end reads aiming for nominal coverage of 30x.
* **F10 batch 1**: 414 samples of F10 lines, split across five 96-well plates. These data were sequenced with 150bp paired-end reads aiming for nominal coverage of 10x.
* **F10 batch 2**: Additional F10 lines that were missing or could not be validated in batch 1. At the time of writing, processing these files is ongoing.



## Submission to ENA

### Overview

Here is an overview of the steps involved to process raw Fastq files and submit them to ENA:

1. Extract raw data
2. Create 'input' sample sheet
3. Rename the raw Fastq files to have meaningful names
4. Generate checksums for each raw data file
5. Use the input sheet and checksums to create 'Sample' and 'Reads' sample sheets for ENA 
6. Submit submission files to ENA
7. Retain submission data (?)

Steps one to five are done programatically - see the relevant directories in this repo.

### Submit the data to ENA

Submissions to ENA are done via the [ENA Webin Submissions Portal](https://www.ebi.ac.uk/ena/submit/webin/).

The submission is structured into four parts:

1. Register a project. Data from this repo are submitted to project PRJEB123735.
2. Upload raw fastq or bam files. I did this using FTP (see the [ENA documentation](https://ena-docs.readthedocs.io/en/latest/submit/fileprep/upload.html#uploading-files-using-command-line-ftp-client) on how to do this).
3. [Submit](https://www.ebi.ac.uk/ena/submit/webin/app-checklist/sample/true) a 'Samples' submission sheet.
4. [Submit](https://www.ebi.ac.uk/ena/submit/webin/read-submission) a 'Reads' submission sheet.



## Retrieve data from ENA


## Dependencies


## Contributions

* This repository: Thomas James Ellis
* Crosses by Fernando Rabanal, Polina Novikova, Viktoria Nizhynska, Pamela Korte and Viktor Voronin.
* Maintenance of subsequent generations, phenotyping and tissue collection by Joanna Gunis.
* Wet lab work by Viktoria Nyzhynska
* Principle investigator: Magnus Nordborg


## AI usage statement

Parts of the code developed for this work (specifically, a SLURM shell script for parallelised MD5 checksum computation) were drafted with the assistance of Abacus AI Agent (Abacus.AI, Inc.), an AI-powered coding assistant. The generated code was reviewed, tested, and modified by the authors prior to use. AI assistance was not used in experimental design, data collection, or interpretation of results.

## Citation

There is not currently a manuscript accompanying this repository.
If you need to cite these data, please use the following citation.

> Thomas James Ellis, Joanna Gunis, Viktoria Nizhynska, Almudena Molla Morales, Polina Novikova, Fernando Rabanal, Pieter Clauw, Magnus Nordborg (2026) "Raw sequence data for the Intra-Swedish cross: a panel of *Arabidopsis thaliana* lines derived from random mating between 219 Swedish ecotypes". European Nucleotide Archive project PRJEB123735 (https://www.ebi.ac.uk/ena/browser/view/PRJEB123735)


## Licensing

Unless otherwise indicated, software and scripts in this repository are licensed under the [MIT License](https://opensource.org/license/mit/).
Documentation and submission templates are licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

This repository does not contain raw sequencing data. Raw-read data and associated public metadata are deposited in the European Nucleotide Archive under the relevant ENA accession(s). Any conditions governing access to or reuse of those records are determined by the ENA record and applicable consent, ethics, institutional, funder, and legal requirements.