# WQWriteHilltopXML

## Overview

The results need to be converted into a Hilltop format.  It may be possible to write a csv import to get the data into Hilltop, but currently the csv file is converted into a Hilltop xml file.  This file can then be dragged into Hilltop and processed as a normal Hilltop file.
Open the R script file WriteCodedHilltopWQXML.R.  Change the filename to the name of the csv file that has the clean results to be converted into Hilltop XML format.
The script only writes data with a good >500 or 300 quality code.  Raw and poor results are not sent.  There is also a line to remove impossible values from pH, this may be better as an extra step in the coder part.
Running the script will generate an XML file in a format that Hilltop can read.  Just drag the file into a hilltop site tree and the file will open.  Once it’s opened in Hilltop it can be copied and accessed in the same way as any other Hilltop file.
