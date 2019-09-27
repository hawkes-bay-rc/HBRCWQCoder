# HBRCWQCoder

Automating the quality coding of water quality results stored in Hilltop data files.
The coding reflects the Hawke's Bay Regional Council criteria and is broadlysimilar to an early draft of NEMS, but has different criteria to the final NEMS that was published.

## Getting Started

Clone the repository to your local machine.

### Prerequisites

You will need an up to date version of R Studio to run the code.
R packages should install as required, however you may need to install some manually if errors occur.

You need access to a Hilltop server endpoint that contains previously coded water quality data and raw (newly collected) water quality data.

### Configuration

To run the scripts you will need to specify the url for the Hilltop server end point that provides the data, and the time range to extract the data.  These parameters are set in the WQualityFromHilltop.R file (between lines 50 and 100).
The list of sites and measurements is obtained from csv files, the names of these also need to be specified (in the same part of the file).

#### Csv Files

Csv files have been used to provide some of the 'user editable' information for the scripts to work.

Csv files are also used as the intermediary files between each step, in order to enable manual edits to the coded information.  The coder can assess a high proportion of the cases, but some will still need to be manually assessed.

## Operation

Once the relevant configuration has been done then the scripts can be run in order to process the data and produce a file that can be copied into a Hilltop archive.

### Data Flow / Script Order

1. Extract the data - [WQualityFromHilltop.R](../Docs/WQFromHilltop.md)
2. Autocode the data - [WQChecker_split.R](../Docs/WQChecker.md)  (calls functions from WQCoderFunctions.R)
3. Check for duplicates - [WQCoderDuplicateChecks.R](../Docs/WQDuplicateChecks.md)
4. Create a Hilltop XML file of the results - [WriteCodedHilltopWQXML.R](../Docs/WriteHilltopXML.md)
5. Copy the Hilltop XML into the Hilltop Archive (standard Hilltop copy).

## Limitations

Puddle is currently the HBRC raw data store and importing database.  Some of the field names and entries refer to Puddle.  These references will need to be changed in order to use these scripts for other systems.

HBRC have a system for tagging samples with comments from the field or the user.  [] indicates a comment that may affect the processing of the results.  These are handled in specific ways.

## Authors

* Jeff Cooke

## Acknowledgments

* Sean Hodges - Horizons Regional council for sharing their initial scripts for interacting with Hilltop servers.

## Licence

This project is licenced under the MIT Licence - see the [LICENCE](LICENSE)
 file for details.