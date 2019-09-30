# WQFromHilltop

## Operation

1. Check that the input sites and measurements csv files are correct.
2. Check that the start date and end date are correct (the start date should be the start of the record so that the already coded data can be used to help code new data).  If the end date is an empty string then the data will be imported through until the end of the record for the site and measurement.
3. Ctrl A to select all of the code and then run.  A progress window and message should show, if not fix any errors and try again.  This code extracts the data from Hilltop (Puddle and Hilltop combined) and then outputs a csv timestamped with the date.  The file will be in 2011_Checks\Data (the working directory for the project and be of the form yyyymmddWQResults.csv  This is the raw data file that is used as the input for the coder.

## Overview

The import script uses 2 csv files to provide the site list and measurement list.  This allows the inputs to be easily modified if required, without the need to modify any code.  