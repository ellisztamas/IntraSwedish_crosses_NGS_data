# Rename fastq files to have informative names

The raw data files come from the NGS sequencing facility with names like
```
375339_AACAAGTACAGGATATATCC_S183_R2_001.fastq.gz
```
These names are not informative about the biological information they contain, so this directory renames them to something more helpful to downstream users.
To be consistent with ENA's schema for organising data in terms of samples, experiments and runs, I have used a naming convention that follows the following pieces of information:

* Sample alias
* Library ID
* Run ID
* Read mate pair

in that order.
In practice these units are separated by underscores, so expect filenames of the general structure as follows:
```
samplealias_library_run_matepair.fastq.gz
```

## Cross lines

* Cross lines have a line name starting with "ISC" (short for Intra-Swedish Crosses) followed by a number (e.g. `ISC_003.1`).
* Their **sample alias** is the line name, plus the batch name (e.g. `ISC_003.1_F8_lowcov`).
* Samples were processed in multiple 96-well plates, with one sample per well. For the **library ID** I used the plate number, and the position in the plate (rows A-H, columns 1-12), in the absence of any better ideas (e.g. plate 3, row D column 1 would be `3D1`).
* In most cases, each sample has only been sequenced once, so there is a single **run** (`run1`). For four plates in the F8 sequencing batch only, sequencing was split over two lanes, so each sample has fastq files for `run1` and `run2`.
* Data are paired-end Illumina data, so there are files for the forward (`R1`) and reverse (`R2`) reads.

Here is an example file name with that information:
```
ISC_003.1_F8_lowcov_3D1_run2_R2.fastq.gz
```


## Parental lines

The data for the parental lines sequenced in this study are more complicated than the crossed lines because:

* Parental lines are ecotypes from the global collection of *A. thaliana*.
    * They have a name (e.g. Ale-Stenar-44-4) and a numerical ID (e.g. 992)
    * For the most up-to-date list of the collection and their metadata, go to [1001genomes.org](https://1001genomes.org/), and click on "Master list" at the bottom of the page.
* We sequenced multiple replicate individual plants, and also processed multiple libraries per individual (to increase coverage).

With that in mind:

* The **sample alias** for the parental lines in this dataset is the ecotype's numeric accession ID, plus an indicator of which plant the tissue was from (e.g. `992_ISCPlant1`).
* As for the crossed lines there is one sequence library per well, the **library** describes the plate name and the row and column of the well in that plate.
    * For example, the library in row D column 6 of plate 2025-033 would have a library ID `2025-033_D6`.
    * In this case I used the plate IDs used internally in the Nordborg group. In hindsight I am not sure this was helpful.
* All parental lines were only sequenced in a single run, so all files are labelled `run1`.
* As for crossed lines data are paired-end Illumina data, so there are files for the forward (`R1`) and reverse (`R2`) reads.
 
Here is an example file name with that information:
```
992_ISCplant1_2025-033_D6_run1_R1.fastq.gz
```