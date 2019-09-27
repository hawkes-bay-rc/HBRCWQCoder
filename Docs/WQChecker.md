# WQChecker

## Operation

1. Change the filename at line 35 so that it reads the correct csv file (the one output from the export from Hilltop).
2. If you don’t want the scatter plot checks to be done then ensure that line 159 (working <- scatterPlotCheck(working, WQSites, goodProcessedData)) is commented out.  Conversely if you do want the scatter plot checks in then make sure that this line isn’t commented out. The scatter plot checks may downcode 600 data to 500, but shouldn’t affect any other operations.
3. Clear the local environment (using the broom icon in the top right panel), then select all of the code and run it, press no at the message about restarting R.
If the scatter plot checks are being done then the coding process will take a while, if not then it will be quick.
4. The output will be a csv file with the name of the format “yyyymmddWQCodedResultsTestV2.csv”.
If you run the coder again on the same day this file will be overwritten, so if you want to keep the results change the name first.  If the file is open when the data is ready to be saved then an error will occur as the file could not be opened by R for writing.  Close the csv file and rerun line 237 to write the data in csv format.
5. Copy this file to another location for people to check (avoids any overwrite errors etc).
The autocoded results can be edited manually to overwrite the autocoded results.  The QC comment should be updated so that there is a description of the reasons and the file should be saved as a different name to the original autocoded results so that there is a traceable record.
*Note:  Running for historic data.*
For older data some of the criteria can be relaxed to line up with what humans allowed in the past.  
To use these options comment out the lld check (line 150) and set the criteria for the QCMethodCheck to “old”.  Make sure that you revert these back after running so that they are applied for other checks.

## Overview