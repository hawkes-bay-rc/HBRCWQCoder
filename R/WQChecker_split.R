#WQ data processing
# Takes in an output dataframe from a Hilltop url read.
# returns a datatbl dataframe ready for xml output to Hilltop

#Updated December 2018 to reduce manual processing.

#Install the required packages
pkgs <- c('dplyr', 'reshape2', 'ggplot2', 'gridextra', 'grid', "stringr")
if(!all(pkgs %in% installed.packages()[, 'Package']))
  install.packages(pkgs, dep = T)


require(dplyr)
require(reshape2)
#Need this to get group_by working from dplyr!
detach(package:plyr) 

require(ggplot2)
#library(modelr)
#library(tidyverse)
require(gridExtra)
require(grid)
require(stringr)

source("R/WQCoderFunctions.R")

#Import data from csv (change csv name as appropriate)
output <- read.csv("data/20190827WQResults.csv", stringsAsFactors = FALSE)

WQSites<-read.csv("data/SiteListAll201904.csv", stringsAsFactors=FALSE) #Read sites in from csv

WQSites<-WQSites[complete.cases(WQSites$Site), ] #remove any missing lines

#merge sites info and output

output <- merge(output, WQSites, by = "Site", all.x = TRUE)


output$QualityCode <- as.character(output$QualityCode)

#Trim "DateTime_" from the Time field and convert to a date format
output$Time <- gsub("DateTime_","",output$Time)

output$Time <- as.POSIXct(output$Time)

#Convert the Time field into DateTime format


#Create a working table
processed <- NULL

#Check if there is a QualityCode column, if not create one and populate it with NA
if (!("QualityCode" %in% colnames(output))) {output$QualityCode <- NA}


#Convert the quality code to a numeric field for processing
output$numericQC <- as.numeric(output$QualityCode)

#Subset the good data and get the bounds for each measurement type for each site (Summary Stats)
goodProcessedData <- subset(output, (numericQC == 300 | numericQC >= 500) & !is.na(result)) #NA removal required for safety, NA can come in if greater than results are in the data set.

summarySiteMeas <- summarise(group_by(goodProcessedData, Site, StdMeasurementName), min = min(result), p01 = quantile(result, 0.01), p05 = quantile(result, 0.05), median = median(result), p95 = quantile(result, 0.95), p99 = quantile(result, 0.99), max = max(result), N = n())
#clean up dataframe
summarySiteMeas <- subset(summarySiteMeas, !is.na(StdMeasurementName))
#Raw data is data that doesn't have a quality code, or may have been coded to 200, this is the data that will be auto assessed
working <- subset(output, is.na(QualityCode) | QualityCode == "200")


#Set Quality Code column to blank.
working$QualityCode <- ""

names(working) <- make.names(names(working), unique = TRUE)


      #Only process data collected after 1 January 2016, prior to this has been coded already and non-coded data is not SoE.
#working <- subset(working, Time >= "2016-01-01")

#Only code data up to 30 June 2019
working <- subset(working, Time <= "2019-06-30")

#Only code data from certain projects
working <- subset(working, Project.ID %in% c("415 01", "ECOHS", "MBWS", "312704", "339301"))

#Join the data summaries for later checking against

working <- merge(working, summarySiteMeas, by = c("Site", "StdMeasurementName"), all.x = TRUE)

#Import and append acceptable lab comments
okLabComments <- read.csv("data/Acceptable_Lab_Comments.csv", stringsAsFactors = FALSE)
working <- merge(working, okLabComments, by = "StdMeasurementName", all.x = TRUE)

#Create summary stats, max min and mean for each site measurement at a time
resultsSummary <- summarise(group_by(working, Site, StdMeasurementName, Time), Res.Min = min(result), Res.Max = max(result), Res.Mean = mean(result))
working <- merge(working, resultsSummary, by = c("Site", "StdMeasurementName", "Time"), all.x = TRUE)
working$Res.Proportion.Difference <- (working$Res.Max - working$Res.Min)/working$Res.Mean

#Process the data, add processing comment column to record why 200 codes entered
working$Issues <- 0
working$TimeCheck <- ""
working$SampleIssueCheck <- ""
working$LabCommentCheck <- ""
working$RangeCheck <-""
working$MethodCheck <- ""
working$VerifiedCheck <- ""
working$DetectionLimitCheck <- ""
working$DuplicateCheck <- ""
working$CollectionMethodCheck <- ""


names(working) <- make.names(names(working), unique = TRUE) #Tidy up the column names

#Check sampling parameters code 200 if issue, otherwise blank

#Check if there is are Sampling.Issue and Lab.Comment columns, if not create them and populate it with NA
if (!("Sampling.Issue" %in% colnames(working))) {working$Sampling.Issue <- NA}
if (!("Lab.Comment" %in% colnames(working))) {working$Lab.Comment <- NA}

#Check whether there's a sampling issue
working <- SamplingIssueCheck(working)

#Check whether there is a lab comment that isn't in the acceptable comments list.
working <- LabCommentCheck(working)

#Check whether the data has been verified
working <- VerifiedCheck(working)

#Check analysis method (full for new, old for old)
working <- QCMethodCheck(working, criteria = "full")

#Check collection method
working <- MCICollectionMethodCheck(working)

#Check LLD (omit for old)
working <- LLDCheck(working)

#Check Sample Time
working <- SampleTimeCheck(working)

#Check result in range for site and measurement
working <- RangeCheck(working)

#Check duplicate measurements in range
working <- DuplicateMeasCheck(working)

#Check P results
working <- PChecks(working)

#Check N results
working <- NChecks(working)

#Check SS
working <- SSChecks(working)

#Check ScatterPlots
####Removed for debugging
working <- scatterPlotCheck(working, WQSites, goodProcessedData, graphing = FALSE)

#Check if there is a Measurement.QC.Comment column, if there isn't add one, but leave the contents blank.
if (!("Measurement.QC.Comment" %in% colnames(working))) {working$Measurement.QC.Comment <- ""}

#Move the Measurement.QC.Comment column to the 5th column.
leftside_columns <- c("Site", "StdMeasurementName", "Time", "Measurement", "Measurement.QC.Comment")
working <- working[c(leftside_columns, setdiff(names(working),leftside_columns))]

#Count the number of comparison errors (may be useful for refining the coding)
if (!("Comparison.Comment" %in% colnames(working))) {working$Comparison.Comment <- NA}
working$CompFails <- str_count(working$Comparison.Comment, ";")

#Code 200 if there is a comment
#working$QualityCode[!is.na(working$Comparison.Comment)] <- "200"

#Code 500 if there is a comparison comment and the result hasn't already been coded to 200 or 400 and the maxcode was 600 and compfails >1
#Changed from previous version
working$QualityCode[working$MaxCode == 600 & working$QualityCode != "200" & working$QualityCode != "400" & !is.na(working$Comparison.Comment) & working$CompFails > 1] <- "500"
working$Measurement.QC.Comment[working$MaxCode == 600 & working$QualityCode != "200" & working$QualityCode != "400" & !is.na(working$Comparison.Comment) & working$CompFails > 1] <- paste0("Autocoded to QC500, due to unexpected relationship with complementary measurement, on ", format(Sys.Date(), "%d-%m-%Y"), ".")

#Code 300 if max code is 300 and the result hasn't already been downcoded.
working$QualityCode[working$MaxCode == 300 & working$QualityCode != "200" & working$QualityCode != "400"] <- "300"
working$Measurement.QC.Comment[working$MaxCode == 300 & working$QualityCode != "200" & working$QualityCode != "400"] <- paste0("Autocoded to QC300, synthetic data, on ", format(Sys.Date(), "%d-%m-%Y"), ".")

#Code 200 if max code is 200
working$QualityCode[working$MaxCode == 200] <- "200"
working$Measurement.QC.Comment[working$MaxCode == 200] <- paste0("Autocoded to QC200, based on the maximum possible code provided, on ", format(Sys.Date(), "%d-%m-%Y"), ".")



#Code to maxcode if a downgraded QC hasn't been assigned.
working$Measurement.QC.Comment[working$QualityCode == ""] <- paste0("Autocoded based on the maximum possible code provided, on ", format(Sys.Date(), "%d-%m-%Y"), ".")
working$QualityCode[working$QualityCode == ""] <- as.character(working$MaxCode[working$QualityCode == ""])#"600"



#convert date fields to date format so meaningful results
working$Entered.to.Puddle.date<-as.character(working$Entered.to.Puddle.date)
working$Updated.date<-as.character(working$Updated.date)
working$Puddle.verified.date<-as.character(working$Puddle.verified.date)

#Remove NA values.
working[is.na(working)] <- ""

#Add a comment to QC400 data
working$QCComment <- paste(working$SampleIssueCheck, working$LabCommentCheck, working$MethodCheck, working$CollectionMethodCheck, working$VerifiedCheck, working$DetectionLimitCheck, working$PSumFinalComment, working$NSumComment, working$SSSumComment)
working$Measurement.QC.Comment[working$QualityCode == "400"] <- paste0("Autocoded to QC400, on ", format(Sys.Date(), "%d-%m-%Y"), ".")

working$Measurement.QC.Comment <- paste(working$Measurement.QC.Comment, working$QCComment)

#Add up the total number of issues 
FinalCommentsCols <- c("TimeCheck", "SampleIssueCheck", "LabCommentCheck", "RangeCheck", "MethodCheck", "CollectionMethodCheck", "VerifiedCheck", "DetectionLimitCheck", "DuplicateCheck", "PSumFinalComment", "NSumComment", "SSSumComment", "Comparison.Comment")
working$Issues <- rowSums(working[FinalCommentsCols][!is.null(working[FinalCommentsCols])] != "")

#Create the output datatbl.
workingmain <- subset(working, select=-c(SamplingIssueStdText, SamplingIssueStd, SamplingStdTxtMissingTxt))
workingend <- subset(working, select=c(SamplingIssueStdText, SamplingIssueStd, SamplingStdTxtMissingTxt))

#datatbl <- working
datatbl <- cbind(workingmain, workingend)

#convert date fields to date format so meaningful results
#datatbl$Entered.to.Puddle.date<-as.character(datatbl$Entered.to.Puddle.date)
#datatbl$Updated.date<-as.character(datatbl$Updated.date)
#datatbl$Puddle.verified.date<-as.character(datatbl$Puddle.verified.date)

#Add a mowsecs column - moved to the import code
#datatbl$Time<-as.POSIXct(datatbl$Time, tz="NZ") #TZ doesn't seem to have an effect
#datatbl$mowsecs <- unclass(datatbl$Time) + 946771200

#Tidy column headers
names(datatbl)<-make.names(names(datatbl), unique = TRUE)

#Remove NA values.
#datatbl[is.na(datatbl)] <- ""

#Sort by Site, Then Measurement, then mowsecs

#datatbl <- datatbl[order(datatbl$Site, datatbl$Measurement, datatbl$mowsecs),]
datatbl <- datatbl[order(datatbl$Site, datatbl$Measurement, datatbl$Time),]

datatbl$ExcelTime <- format(datatbl$Time, format = "%d/%m/%Y %H:%M")
datatbl$Time <- paste0("DateTime_", as.character(datatbl$Time))

goodProcessedData <- goodProcessedData[order(goodProcessedData$Site, goodProcessedData$Measurement, goodProcessedData$Time),]
goodProcessedData$Time <- paste0("DateTime_", as.character(goodProcessedData$Time))
goodProcessedData$ExcelTime <- format(goodProcessedData$Time, format = "%d/%m/%Y %H:%M")

write.csv(datatbl, paste("Data/", format(Sys.Date(), "%Y%m%d"),"WQCodedResultsTestV3.csv", sep =""), row.names = FALSE)
write.csv(goodProcessedData, paste("Data/", format(Sys.Date(), "%Y%m%d"),"ArchiveData.csv", sep =""), row.names = FALSE)

#write.csv(wideWorkingCVDataPredictions, paste("Data/", format(Sys.Date(), "%Y%m%d"),"WideWorkingCVDataPredictions.csv", sep =""), row.names = FALSE)

##Possible Improvements

# Don't code 200 if less than figure and outside lower bound. -DONE
# Add in error checking for if stats (DONE) or models not available, ie new sites
# Improve models so narrower band, unsure how, is current method acceptable? See option below.
# Add 95 percentile lines to the model plots so that the overall flagged range will show (added comfort, meaning less need to refine models) DONE
# Improve Nitrogen sum handling - DONE
# Add in flow correlations and handling (maybe)
# Move the plotting functions to the bottom of the loop (DONE) and add plots to show uncoded data and how that compares with the base data (maybe)
# Functionise linear model so code tidier (DONE)
# Generalise so can work for any Hilltop web service WQ data. (Partial)
# Add black disc to the correlative checks (5 more models per site, unless just do BD Turb checks and BD SS checks) DONE (Just BD Turb and BD SS)
# Sort import and handling of greater than results, code 200 at the start, but need to handle in the censured functions.
