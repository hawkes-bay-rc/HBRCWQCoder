# WQDuplicateChecks

## Overview

If sample metadata has been edited in Puddle then this could be out of sync with data that has already been processed through to Hilltop, and there could be issues showing in the coded data file.
Before loading the coded data to the Hilltop archive the duplicate checks should be run and only non-duplicated data should be transferred to the archive.  To check this open the R script file WQCoderDuplicateChecks.R.
This script checks what is in the archive against the new data that has just been coded.  You need to edit the filenames for the newly coded results and the archive data, lines 5 and 8 of the script.  These filenames need to be the most current versions output from the Coder.
The results are output to csv files so that any issues can be identified and worked through.

* WQCodedResultsClean - Newly coded results that do not have duplicates (ready to get imported into the archive).
* RawRawDuplicates - Newly coded duplicates that have duplicates in the newly coded dataset.  These are either duplicates in Puddle, or there is an issue with the Puddle Hilltop link.
* Raw_RawArchiveDuplicates - Newly coded results that are duplicated in the archive.  The reasons for the duplication need to be investigated and appropriate actions determined.
* Archive_RawArchiveDuplicates - Archived results that are duplicates in the archive.  Indicates an issue with the archive, there should be no results in this file.