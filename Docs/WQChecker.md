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

### Setup
The downloaded data needs to be imported and site and measurement metadata associated with the results.

The site list for data import is provided by a csv file containing a Sites column containing the names of the sites to be downloaded from the web service. Additional columns in this csv file provide the expected MCI collection method for the site, and other metadata can be provided, eg catchments. The measurements list csv file has additional columns that need to be populated to allow the process to run, these columns are used within the checker routines.

Column | Use | Description
--------------|------------------|--------------------------------------
Measurements | Used to request the data from the server. | The measurement name that needs to be used within the url to request the data.  The fully specified Hilltop name is the default.
AgencyMeasurement | Used to link the csv measurement data to the data table of results from the server. | The measurement name once the data has been imported, this should be the first part of the name from Measurements, without the square brackets or the contents of them.
StdMeasurementName | Used by the code to identify parameters. | This is the name that the R script uses to subset and assess the data.  If any name in this column is changed then the R script will need to be assessed and any occurrences of the name changed within the script, otherwise errors may occur.  This name has been set to a ‘safe R column name’.  Spaces have been replaced with ‘.’ And special characters removed.
AcceptableMethod | Used to check that the correct analysis method has been used. | This is the current acceptable method for the measurement.  It is compared with the method used and if the values are not exactly the same it will flag the measurement result for checking. (Watch for typos!!).
MaxCode | Used to define the maximum quality a measurement can attain. | This is the maximum quality code that is able to be given for the measurement.  This is used to assign the final code to the data.  If the value is 200 or 300 then this will be assigned to all results for that measurement.  Otherwise the value will be assigned to results that have not already been coded to 200.  Calculated values may be set to 300.  Most parameters with QA processes will be able to attain 600, but if only 500 is possible this can be entered in this sheet and the maximum QC assigned will be 500.
LLD | Used to determine the expected less than figure. | This is the expected less than figure for the measurement.  If it is provided and a less than figure for the measurement doesn’t match this value then the result will be coded 200.  Any measurements where this is blank do not get this test done on them.
MeasurementTypeStdText | Used to check for sampling issues flagged in the field, or during verification. | This is the relevant flag square brackets with a text flag inside that indicates the type of issue identified.  Field forms automatically generate these flags and during import they get entered into a data base field.  During result verification comments can be manually added.


The 3 measurement columns are required in order to allow the data to be processed, the use column describes what they do.  This format has 2 significant potential benefits:-

1.	It allows measurements to be aggregated, eg council data pH (field) and pH (Lab) stored as 2 separate parameters can be combined for coding purposes, while allowing them to remain as discrete data sets.

2.	It allows the same coding script to be used on other agencies web services with minimal changes.  There are a few metadata fields that are used within the script to assess against (lab and sampling comments) but otherwise the coding is done using standard fields.

The non-standard metadata fields that are used in the QC scripts are:-

Metadata Field name | Name in script | Description
---------------|------------|----------------------------------------------
Lab Comment | Lab.Comment | A Measurement Parameter that contains any comments provided by the lab regarding the test.
Sampling Issue | Sampling.Issue | A Sampling Parameter that contains any sampling comments entered from the field.
Puddle verified | Puddle.verified | Has the sample been verified within Puddle (the water quality database / import system).
Measurement QC Comment | Measurement.QC.Comment | Comments from the QC process for the measurement.  Any results that are autocoded will have a comment stating that they were autocoded on a date, this field can also be populated in the csv file when doing the final checks with any manual coding comments.

If these fields aren’t present then they are added but populated with NA, except for Puddle verified, this is populated with a 1, so that the verified check passes.  If other councils want to use this code but use different names for these fields then the code will need to be modified to allow these checks to be done.  It should be possible to provide these fields within a csv file, simplifying the process for councils (removing the need to edit the code).

### Quality Coder
#### Overview
The data from the Hilltop export is split into 2 working datasets, one that contains only data that has previously been assessed as good data (based on draft NEMS standards), and one that contains uncoded data (a date to check from can be included if the data to be checked needs to be limited).
The good dataset is processed in 2 ways to provide useful checks for the coding process:-

1.	Summary statistics are produced for each site – measurement combination, allowing results that fall outside of the 5th the 95th percentile range to be flagged for checking, along with sites that don’t yet have enough results for good stats to be generated (currently set at 12).
2.	Predictive models are created for the relationships between Turbidity, Suspended Solids, Total Phosphorus, E. Coli, and Black Disc so that results that appear unusual can be flagged for checking.

The uncoded dataset is checked in a variety of ways, and any questionable results are coded to 200, indicating that manual checks are required.  The checks undertaken are:-

* Sampling error flags
* Lab error flags
* Verification check
* The correct analysis method was used.
* The correct MCI collection method was used.
* Detection limit check
* Samples taken outside of normal working / sampling hours
* There are enough results to generate some summary statistics (12 good results).
* The results are within the 5th to 95th percentile range for the site / measurement combination.
* Lab and Field results are similar (Duplicate Checks)
* Sanity checks for Phosphorous, Nitrogen and Suspended Solids parameters
* Results align with predictions based on related measurements for Turbidity, Suspended Solids, Total Phosphorus, E. Coli, and Black Disc. (These related measurements are specified in a csv file so additional relationships can easily be added without adjusting the code).

Comments are created that describe any issues or downcoding. Plots of the models used for the predictions can be produced and saved for manual checks and records.

Dissolved Inorganic Nitrogen and Total Organic Nitrogen are calculated in Puddle so they are coded as Synthetic (QC300), unless an issue is identified (QC200).  The QC300 is set using the Maxcode field in the measurements csv file.

After all of the checks are complete then any uncoded results are coded to the MaxCode value (usually QC600 good data) as they have passed all of the automatic checks.

To prepare the data for exporting to Hilltop a column is added that contains the time in mowsecs (number of seconds since 1 January 1940) and the data is sorted into Site, Measurement, then date order.

A csv of the coded data is exported for checking / record and further processing.  A csv of the nitrogen results is also exported to aid with the checking process.

[QA Process Diagram](../Docs/Overview_flowchart.pdf)

#### Detail
##### Sampling Errors
Any field sampling comments are imported from Puddle into the Hilltop field Sampling Issue.  This field is checked for standardised text flags (text contained in square brackets).  The flags indicate what measurements have an identified issue, either from the field or from the verification. If relevant text is found then a comment is added to the SampleIssueCheck field and the result is coded to 400 for a manual check.  If a flag is found, but the text inside it is unexpected then all of the results for that sample are coded to 200 and will require a manual check.

##### Lab Errors
Any comments from the Laboratory are now imported into Puddle and through to Hilltop in the Lab Comment field.  This field is checked for any text and if text is found then a comment is added to the LabCommentCheck field and the result is coded to 400 for a manual check unless the comment is exactly the same as an Acceptable Lab Comment for the measurement contained in the Acceptable_Lab_Comments.csv file.

The Acceptable_Lab_Comments.csv file contains the following columns.

Field | Description
-----------------------|---------------------------------------------------
StdMeasurementName | The StdMeasurementName as per the WQMeasurements file.
Acceptable.Lab.Comment | The acceptable Lab.Comment, as provided by the lab.

##### Verified Check
Any results that have not been verified in the Water Quality Database / import system (Puddle) are coded to 200 and a comment added to the VerifiedCheck column.

##### Method Check
Any results where the contents of the Method field does not match the contents of the AcceptableMethod field are coded to 200 and a comment added to the MethodCheck column.

There are some exceptions allowed within the script, these are hardcoded in, but can be adjusted as required. 

During commissioning it was noted that historical data had previously been manually coded with more lenient criteria regarding the allowed methods.  An option within the function call, allows the criteria to be set to “full” or “old”.  If the “old” option is chosen then the more lenient version of the method check is used.

##### Detection Limit Check
Any less than results for parameters that have an entry in the LLD field where the result doesn’t match the LLD are coded 400 and a comment added to the DetectionLimitCheck column.

##### Sampling Time
The sample time (in hours) is checked to be between 06:00 and 19:00.  If the sample time is outside of this range then the result is coded to 200 and a comment added in the TimeCheck column.

##### Duplicate Result Check
Laboratory and Field data for the same parameter may be collected at the same time, and these should be similar. The Maximum, Minimum and Mean results for a StdMeasurementName at a site and time are calculated.  If (Max – Min) / Mean > 0.05 (5% difference) then the results are flagged, but each result is coded independently according to all other criteria.

##### Result Range
Using the good data (QC500 and QC600) summary statistics (Min, 5th Percentile, Median, Mean, 95th Percentile, Maximum and Number of results) are generated for each site – measurement combination.  The resulting data frame is incorporated into the working data frame (results for quality coding) and the result compared with the 5th and 95th percentiles.  If the result is not a less than result and is outside of the 5 – 95 percentile range it is flagged (but not down coded) and a comment added in the RangeCheck column.

##### Sanity Check
These checks are that the totals are greater than components for Nitrogen, Phosphorous and Suspended solids parameters.

##### Phosphorus
If the DRP result is greater than the TP result and there isn’t a lab comment saying that this is within lab error then both are coded to 400 and a comment entered in the PSumComment column to say that DRP > TP.  If there is a lab comment, or one of the results is missing then this is flagged in the comments.

##### Suspended Solids
If the VSS result is greater than the SS result and there isn’t a lab comment saying that this is within lab error then both are coded to 400 and a comment entered in the SSSumComment column to say that VSS > SS.  If there is a lab comment, or one of the results is missing then this is flagged in the comments.

##### Nitrogen
The data is subset and converted to wide format so that all of the results are in a single row.

Missing results are checked for and a comment added if any are found and related results are coded to 200.

The number of decimal places for each result are calculated (for rounding checks and calculating allowed error margins).

If the Ammoniacal N result is greater than the TKN result then both are coded to 200 and a comment entered in the NSumComment column to say that Ammoniacal N > TKN.

Results are coded 200, and a comment added in the NSumComment column, if the magnitude of the difference between the TN Result and the Sum of TKN and NNN is less than one unit at the minimum number of decimal places (ie if min no. decimal places of the results is 2 then the maximum difference would be 0.01, if the min no. decimal places was 1 then the maximum difference would be 0.1).  This algorithm removes false positives while retaining the checks.

If the Nitrate N result is greater than the NNN result then both are coded to 200 and a comment entered in the NSumComment column to say that NNN result less than nitrate result.

If the difference between the NNN result and the sum of nitrate and nitrite nitrogen is greater than one unit at the minimum number of decimal places (ie if min no. decimal places of the results is 2 then the maximum difference would be 0.01, if the min no. decimal places was 1 then the maximum difference would be 0.1) then the results are coded to 200 and a comment entered in the NSumComment column to say that the NNN sum has an error.

Dissolved Inorganic Nitrogen and Total Organic Nitrogen are both calculated in Puddle, but checks are done to ensure the calculated values are correct, if there is a discrepancy a comment is added and the results will be downcoded to 200,  the results for these parameters are coded 300, synthetic data unless they have been downcoded to 200.

##### Related Measurements
A csv file (Model_Info.csv) provides details of the related measurements to be checked.  Each line provides details of a relationship to be checked.  For each check, for each site, linear models of the logs of the results are produced from the good data. Graphs of these are plotted to file (log – log and linear plats are produced, and the predicted bounds and the 95th percentile of the good data are also shown on the plots) for checking and records.  The graphs are contained in a folder within the working directory with the name format yyyymmdd.

For each combination the un-coded results are compared with the predicted bounds from the other variable and if the result is outside the predicted bounds (95th percentile) then the result is coded 200 and a comment added to the CombinationComment field describing what relationship caused the downgrade.

The relationships that have currently been entered are:-

* Turbidity – Suspended Solids
* Turbidity – Total Phosphorus
* Turbidity – E. Coli
* Suspended Solids – Total Phosphorus
* Suspended Solids – E. Coli
* Total Phosphorus – E. Coli
* Turbidity – Black Disc
* Suspended Solids – Black Disc

These can be added to (or changed) by editing the csv file.

The fields within the Model_Info.csv file are:-

Column | Description
-------------|----------------------------------------------
Name | The simple name used to describe the relationship
Param.x | The ‘x’ parameter, exactly as per the StdMeasurementName in the Measurements.csv file.
Param.y | The ‘y’ parameter, exactly as per the StdMeasurementName in the Measurements.csv file.
Description | A basic description of the relationship being tested, will be the base text in the comment field.
Col.Name | The base of the column name for the test results. This should use an abbreviation of the parameter names, separated with ‘From’.  There are no spaces in the name ‘.’ Are used instead of spaces.

#### Final Steps
Once the checks have been completed a variety of operations are performed on the data before it is exported.  These are:-

* If the MaxCode is 300 then code any uncoded results for that parameter to 300 (synthetic). 
*	If the Maxcode is 200 then code all of the results for that parameter to 200.
*	Otherwise code all of the uncoded results to the Maxcode Value (usually 600, but could be less).
*	Sort the data so that it is ordered by site, then measurement, then sample time.
*	Add a Mowsecs column (may move to the export to Hilltop section as it is only required for the import into Hilltop XML format).
*	The Measurement.QC.Comment field is populated with the text  “Autocoded to x on date” as appropriate for non QC200 data.
*	Remove any residual NA values
*	Remove any impossible results

#### Manual Checks
The ouptutted csv file contains the autocoded resulst.  Results that weren't able to be autocoded can be manually edited in the csv file (change the quality code and add a comment).  If the same operations are being done repeatedly then there may be a case to edit the operation of the autocoder.

