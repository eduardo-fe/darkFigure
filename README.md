# Partial Identification of the Dark Figure of Crime with Survey Data under Misreporting Errors

**Version 1.1 (September 30th, 2024)**

This repository contains the Stata files used in the analysis for the paper:

**"Partial Identification of the Dark Figure of Crime with Survey Data under Misreporting Errors"**

The paper is currently under "revise and resubmit" status at the *Journal of Quantitative Criminology*.

## Description

The provided Stata files are designed to analyze data from the **Crime Survey for England and Wales (CSEW)**. The purpose of this analysis is to account for misreporting errors in survey data, providing a partial identification of the "dark figure" of crime – the portion of crimes that go unreported.

## Requirements

- **Stata**: You will need Stata to run the scripts provided in this repository.
- **Crime Survey for England and Wales (CSEW)**: The survey data can be downloaded from the [U.K. Data Archive](https://www.data-archive.ac.uk/).

## Setup Instructions

1. **Download the CSEW data**: Ensure that you have downloaded the Crime Survey for England and Wales dataset from the U.K. Data Archive.
   
2. **Set directories**: Modify the paths in the Stata files to point to the directory where you have stored the CSEW data. You will find the paths indicated in the relevant scripts.

3. **Outputs**: The analysis is set up to save results in a folder named `outputs`, which should be created inside the same directory where the Stata files are stored. If needed, you can adjust this path according to your preferred directory structure.

## Directory Structure

```
|-- /your-directory/
    |-- /outputs/               # Folder where output files will be saved
    |-- main.ado                # Main Stata file
    |-- datapreparation.do      # Prepare the data for analysis (run this first)
    |-- functions.ado           # To be called from main.ado
```

Make sure the CSEW data files are located in the correct directories and that the output folder is created before running the scripts.

## Usage

After setting up the directories, simply run the Stata `.do` files in the appropriate order to generate the outputs. Ensure that any required dependencies (e.g., custom libraries, additional Stata commands) are installed in your Stata environment.

## Contact

For any questions related to the analysis or the paper, please reach out to the authors via email.

---

**Note**: The current version is 1.1, dated September 30th, 2024. Make sure to check back for updates if any revisions or corrections are made to the scripts.

