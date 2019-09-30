#Functions to help QC process.

#Create a decimal places calculator function.
decimalplaces <- function(x) {
  if (!is.na(x)) {
    if ((x %% 1) != 0) {
      nchar(strsplit(sub('0+$', '', as.character(x)), ".", fixed=TRUE)[[1]][[2]])
    } else {
      return(0)
    }
  } else {NA}
  
}

#For debugging
eskTurb <- function(dataTable, namePart) {
  debugoutput <- subset(dataTable, Site=="Clive River U/S Whakatu rail bridge" & StdMeasurementName=="Turbidity")
  write.csv(debugoutput, paste("Data/", format(Sys.Date(), "%Y%m%d"),"EskTurb", namePart,".csv", sep =""), row.names = FALSE)
}

SamplingIssueCheck <- function(working) {
  #Specific sampling issue check using standard text
  
  #List of standard text associated with sampling issue comments
  stdtextlist <- c("[DO]", 
                   "[EC]", 
                   "[pH]", 
                   "[Turbidity]", 
                   "[BD]", 
                   "[Temp]", 
                   "[Sample]", 
                   "[VISPER]", 
                   "[Macrophyte]", 
                   "[Other]", 
                   "[Chla]",
                   "[MCI]")
  
  #working$SamplingIssueStdText <- mapply(grep, pattern = "\\[(.*?)\\]", x=working$Sampling.Issue, value = TRUE)
  
  working$SamplingIssueStdList <- mapply(str_extract_all, string = tolower(working$Sampling.Issue), pattern = "\\[(.*?)\\]")
  #working$SamplingIssueStdList <- tolower(working$SamplingIssueStdList) Removed as was causing a bug, put in line above
  
  working$SamplingIssueStdText <- mapply(toString, working$SamplingIssueStdList)
  
  #working$SamplingIssueStd <- mapply(grepl, pattern=working$MeasurementTypeStdText, x=working$Sampling.Issue)
  #working$SamplingIssueStd <- mapply(grepl, pattern=working$MeasurementTypeStdText, x=working$SamplingIssueStdText)
  #TEST ignore case during match
  working$SamplingIssueStd <- mapply(grepl, pattern=tolower(working$MeasurementTypeStdText), x=tolower(working$SamplingIssueStdText), fixed = TRUE)
  
  #Check for standard text that isn't associated with a measurement
  #working$SamplingStdTxtIssue[working$SamplingIssueStdText != ""] <- mapply(intersect, working$SamplingIssueStdList[working$SamplingIssueStdText != ""], stdtextlist)
  #working$SamplingStdTxtIssue <- mapply(setdiff, working$SamplingIssueStdList, stdtextlist)
  #working$SamplingStdTxtIssue <- any(!(working$SamplingIssueStdList %in% stdtextlist))
  #working$SamplingStdTxtIssue <- str_detect(working$SamplingIssueStdText, stdtextlist)
  working$SamplingStdTxtMatch <- (sapply(working$SamplingIssueStdList, intersect, tolower(stdtextlist)))
  working$SamplingStdTxtMissing <- (mapply(setdiff, working$SamplingIssueStdList, working$SamplingStdTxtMatch))
  working$SamplingStdTxtMissingTxt <- mapply(toString, working$SamplingStdTxtMissing)
  
  #Check for [time] tag and flag in a column
  working$SamplingIssueTime <- mapply(grepl, pattern = "[time]", x = tolower(working$SamplingStdTxtMissingTxt), fixed = TRUE)
  
  #remove the columns that contain lists so that the data will export as a csv
  working <- subset(working, select=-c(SamplingIssueStdList, SamplingStdTxtMatch, SamplingStdTxtMissing))
  
  #Check whether there is a sampling Issue, code 200 if there is, updated to look for standard text
  #working$QualityCode <- ifelse(!is.na(working$Sampling.Issue), "200", "")
  #working$Sampling.Issue[is.na(working$Sampling.Issue)] <- ""
  #working$SampleIssueCheck[working$Sampling.Issue != ""] <- "Unacceptable sampling issue. "
  #working$QualityCode[working$SampleIssueCheck != ""] <- "200"
  
  #Clean up NA's and convert to ""
  working$Sampling.Issue[is.na(working$Sampling.Issue)] <- ""
  working$SamplingStdTxtMissingTxt[working$SamplingStdTxtMissingTxt == "NA"] <- ""
  working$SamplingIssueStd[working$SamplingIssueStd == "NA"] <- ""
  working$SamplingIssueStdText[working$SamplingIssueStdText == "NA"] <- ""
  
  
  working$SampleIssueCheck[working$Sampling.Issue != "" & working$SamplingIssueStdText == ""] <- "Missing standard text."
  
  #TODO Unexpected std text implies it may be Other and therefore need an extra step to move these to Sampling Issue Identified
  working$SampleIssueCheck[working$SamplingStdTxtMissingTxt != ""] <- "Unexpected standard text."
  working$SampleIssueCheck[working$SamplingIssueStd == TRUE] <- "Sampling Issue Identified."
  working$SampleIssueCheck[working$SamplingIssueTime == TRUE] <- "Sampling Time Issue."
  #Set Sampling issues that aren't "Sampling Issue Identified" to 200, as they need to be checked.
  working$QualityCode[!(working$SampleIssueCheck %in% c("", "Sampling Time Issue.", "Sampling Issue Identified."))] <- "200"
  
  #Set "Sampling Time Issue" to 400
  working$QualityCode[working$SampleIssueCheck == "Sampling Time Issue."] <- "400"
  
  #Set "Sampling Issue Identified" to 400
  working$QualityCode[working$SampleIssueCheck == "Sampling Issue Identified."] <- "400"
  
  
  #working$Issues[!is.na(working$Sampling.Issue)] <- working$Issues[!is.na(working$Sampling.Issue)] + 1
  working
}

LabCommentCheck <- function(working) {
  #Check whether there is a lab comment that isn't in the acceptable comments list.
  
  #working$QualityCode <- ifelse(!is.na(working$Lab.Comment), "200", "")
  #working$QualityCode <- ifelse(!is.na(working$Lab.Comment) & working$Lab.Comment != working$Acceptable.Lab.Comment, "200", "")
  working$Lab.Comment[is.na(working$Lab.Comment)] <- ""
  working$Acceptable.Lab.Comment[is.na(working$Acceptable.Lab.Comment)] <- ""
  working$Acceptable.Lab.Comment.2[is.na(working$Acceptable.Lab.Comment.2)] <- ""
  working$Acceptable.Lab.Comment.3[is.na(working$Acceptable.Lab.Comment.3)] <- ""
  working$LabCommentCheck[(working$Lab.Comment != "") & (working$Lab.Comment != working$Acceptable.Lab.Comment) & (working$Lab.Comment != working$Acceptable.Lab.Comment.2) & (working$Lab.Comment != working$Acceptable.Lab.Comment.3)] <- "Unexpected Lab Comment. "
  #working$LabCommentCheck[(working$Lab.Comment != "") & working$Lab.Comment != working$Acceptable.Lab.Comment] <- "Unexpected Lab Comment. "
  #working$LabCommentCheck[working$Lab.Comment != working$Acceptable.Lab.Comment] <- "Unexpected Lab Comment. "
  #working$LabCommentCheck[!is.na(working$Lab.Comment) & working$Lab.Comment != working$Acceptable.Lab.Comment] <- "Unexpected Lab Comment. "
  #working$LabCommentCheck <- ifelse(!is.na(working$Lab.Comment) & working$Lab.Comment != working$Acceptable.Lab.Comment, "Unexpected Lab Comment. ", "")
  #working$Issues[!is.na(working$Lab.Comment) & (working$Lab.Comment != working$Acceptable.Lab.Comment)] <- working$Issues[!is.na(working$Lab.Comment) & (working$Lab.Comment != working$Acceptable.Lab.Comment)] + 1
  
  #Laboratory analysis issue so code to 400
  working$QualityCode[working$QualityCode != "200" & working$LabCommentCheck != ""] <- "400"
  
  working
}

VerifiedCheck <- function(working) {
  #Check if there is a Puddle.verified column, if not create one and populate it with 1 (indicating verified data).
  if (!("Puddle.verified" %in% colnames(working))) {working$Puddle.verified <- 1}
  
  #Check if the data has been verified, code to 200 if not and comment.
  working$QualityCode[working$Puddle.verified != 1] <- "200"
  working$VerifiedCheck[working$Puddle.verified != 1] <- "Result not verified in Puddle."
  
  working
}

QCMethodCheck <- function(working, criteria = "full") {
  unacceptableMethods <- c("NA", 
                           "No Method Assigned", 
                           "Thermometer Mercury/Red spirit", 
                           "Hawke's Bay Regional Council - In House",
                           "C4 - soft bottom quantitative")
  #Check if the correct method was used, code to 200 if not and add comment
  working$Method[is.na(working$Method)] <- ""
  working$AcceptableMethod[is.na(working$AcceptableMethod)] <- ""
  if(criteria == "full"){
    #TODO Downgrade unexpected lab comments
    
    working$QualityCode[working$Method != working$AcceptableMethod] <- "200"
    working$MethodCheck[working$Method != working$AcceptableMethod] <- "Analysis method different to approved method."
    #Remove downcode in specific circumstances.
    working$MethodCheck[working$StdMeasurementName == "Dissolved.Reactive.Phosphorus" & working$Method == "Molybdenum Blue Colorimetry" & working$Time >= "2018-03-06" & working$Time <= "2018-06-30"] <- "Analysis method different to approved method, but accepted."
    working$QualityCode[working$StdMeasurementName == "Dissolved.Reactive.Phosphorus" & working$Method == "Molybdenum Blue Colorimetry" & working$Time >= "2018-03-06" & working$Time <= "2018-06-30"] <- ""
    
    
    working
  } else if(criteria == "old"){
    #This is for old data and allows data to be autocoded in a way that is consistent with old manual methods.
    working$QualityCode[working$Method %in% unacceptableMethods] <- "200"
    working$MethodCheck[working$Method %in% unacceptableMethods] <- "Analysis method unacceptable."
    #Remove downcode in specific circumstances.
    working$MethodCheck[working$StdMeasurementName %in% c("Percent.EPT.Taxa", "Periphyton.Chlorophyll.a") & working$Method == "No Method Assigned"] <- "Analysis method different to approved method, but accepted."
    working$QualityCode[working$StdMeasurementName %in% c("Percent.EPT.Taxa", "Periphyton.Chlorophyll.a") & working$Method == "No Method Assigned"] <- ""
    working
  } else {message("criteria must be 'full' or 'old'.")}
}


MCICollectionMethodCheck <- function(working) {
  #Check if the correct collection method was used, code to 200 if not and add comment
  #TODO Downgrade unexpected lab comments
  working$MCI.Collection.Method[is.na(working$MCI.Collection.Method)] <- ""
  working$Collection.Method[is.na(working$Collection.Method)] <- ""
  
  #working$QualityCode[working$MeasurementTypeStdText == "[MCI]" & working$MCI.Collection.Method != "" & (working$Collection.Method != working$MCI.Collection.Method | (working$MCI.Collection.Method.2 != "" & working$Collection.Method != working$MCI.Collection.Method.2))] <- "200"
  #working$CollectionMethodCheck[working$MeasurementTypeStdText == "[MCI]" & working$MCI.Collection.Method != "" & ((working$Collection.Method != working$MCI.Collection.Method) | (working$MCI.Collection.Method.2 != "" & working$Collection.Method != working$MCI.Collection.Method.2))] <- "MCI Collection method different to approved method for site."
  working$CollectionMethodCheck[working$MeasurementTypeStdText == "[MCI]" & working$MCI.Collection.Method != "" & ((working$Collection.Method != working$MCI.Collection.Method) & (working$Collection.Method != working$MCI.Collection.Method.2))] <- "MCI Collection method different to approved method for site."
  working$QualityCode[working$MeasurementTypeStdText == "[MCI]" & working$MCI.Collection.Method != "" & ((working$Collection.Method != working$MCI.Collection.Method) & (working$Collection.Method != working$MCI.Collection.Method.2))] <- "200"
  #Remove downcode in specific circumstances.
  
  
  working
}

LLDCheck <- function(working) {
  #Check if the detection limit for the method matches the reported less than figure, code 200 if not
  #Check coding doesn't worry if reported LLD is less than required, then downcode to 400
  working$QualityCode[working$QualityCode != "200" & !is.na(working$LLD) & working$valueprefix == "<" & working$LLD != working$result] <- "400"
  working$DetectionLimitCheck[!is.na(working$LLD) & working$valueprefix == "<" & working$LLD != working$result] <- "Detection limit greater than expected."
  
  working
}

SampleTimeCheck <- function(working) {
  #Check within sampling time range, code to 200 if outside and add a comment
  #TODO Change so doesn't flag if there is a [Other] tag for sampling issue
  #TODO Change so doesn't downcode.
  earliestSampleTime <- "06:00:00"
  latestSampleTime <- "19:00:00"
  #Flag that the sample was taken outside of the normal time range, code to 200 so manual check required.
  working$QualityCode[strftime(working$Time, format="%H:%M:%S") < earliestSampleTime] <- "200"
  working$TimeCheck[strftime(working$Time, format="%H:%M:%S") < earliestSampleTime] <- "Sampled outside normal working time range."
  working$QualityCode[strftime(working$Time, format="%H:%M:%S") > latestSampleTime] <- "200"
  working$TimeCheck[strftime(working$Time, format="%H:%M:%S") > latestSampleTime] <- "Sampled outside normal working time range."
  
  working
}

RangeCheck <- function(working) {
  #Check within 5 - 95% range, code to 200 if not, unless it is in the lower 5% and a less than figure.
  #Changed to check within Min Max range.
  #working$QualityCode[working$result < working$p05 & working$valueprefix != "<"] <- "200"
  #working$RangeCheck[working$result < working$p05 & working$valueprefix != "<"] <- "Result in lower 5% for site and parameter."
  #working$QualityCode[working$result > working$p95] <- "200"
  #working$RangeCheck[working$result > working$p95] <- "Result in upper 5% for site and parameter."
  
  #Check within Min - Max range, code to 200 if not, unless it is a less than figure.
  #Changed to check within 1% to 99% range.
  #working$QualityCode[working$result < working$min & working$valueprefix != "<"] <- "200"
  #working$RangeCheck[working$result < working$min & working$valueprefix != "<"] <- "Result below minimum for site and parameter."
  #working$QualityCode[working$result > working$max] <- "200"
  #working$RangeCheck[working$result > working$max] <- "Result above maximum for site and parameter."
  
  #Check within 1 - 99% range, used to code to 200 if not, unless it is in the lower 1% and a less than figure.
  #If there's no statistic then used to code to 200 and comment to say that there isn't a statistic.
  #Now allow the results to pass through, ie don't down code, but keep the flags
  
  #working$QualityCode[is.na(working$p01) | is.na(working$p99)] <- "200"
  working$RangeCheck[is.na(working$p01) | is.na(working$p99)] <- "No percentiles available to check data against."
  #working$QualityCode[working$result < working$p01 & working$valueprefix != "<"] <- "200"
  working$RangeCheck[working$result < working$p01 & working$valueprefix != "<"] <- "Result in lower 1% for site and parameter."
  #working$QualityCode[working$result > working$p99] <- "200"
  working$RangeCheck[working$result > working$p99] <- "Result in upper 1% for site and parameter."
  
  #Check that  the stats have been generated from at least 12 results.
  #Removed and max min check used instead
  #working$QualityCode[working$N < 12] <- "200"
  #working$RangeCheck[working$N < 12] <- "Less than 12 results for this parameter at this site."
  
  #If there were no percentiles to check against then code to 200
  #working$QualityCode[is.na(working$p05)] <- "200"
  #working$RangeCheck[is.na(working$p05)] <- "No percentile statistic for site and parameter."
  #working$QualityCode[is.na(working$p95)] <- "200"
  #working$RangeCheck[is.na(working$p95)] <- "No percentile statistic for site and parameter."
  
  #If there were no min or max to check against then used to code to 200, now just comment
  #working$QualityCode[is.na(working$min)] <- "200"
  working$RangeCheck[is.na(working$min)] <- "No min or max statistic for site and parameter."
  #working$QualityCode[is.na(working$max)] <- "200"
  working$RangeCheck[is.na(working$max)] <- "No min or max statistic for site and parameter."
  
  working
}

DuplicateMeasCheck <- function(working) {
  #Duplicate measurement checks (eg Lab Field) check that they are within a percentage of each other.
  AcceptableProportionDifference <- 0.05
  
  #Removed downgrade in quality and just flag discrepancy
  
  #working$QualityCode[working$Res.Proportion.Difference > AcceptableProportionDifference] <- "200"
  working$DuplicateCheck[working$Res.Proportion.Difference > AcceptableProportionDifference] <- "Unexpected difference between lab and field results. "
  
  working
}

PChecks <- function(working) {
  #Subset to get P data
  
  workingP <- subset(working, StdMeasurementName %in% c("Total.Phosphorus", "Dissolved.Reactive.Phosphorus"))
  #wideP <- dcast(workingP, Site + Time ~ Measurement, value.var = "result")
  wideP <- dcast(workingP, Site + Time ~ StdMeasurementName, value.var = "result")
  wideP$PSumComment <-NA
  names(wideP) <- make.names(names(wideP), unique = TRUE)
  wideP$PSumComment[is.na(wideP$Dissolved.Reactive.Phosphorus)] <- "No DRP result."
  wideP$PSumComment[is.na(wideP$Total.Phosphorus)] <- "No TP result."
  wideP$PSumComment[(!is.na(wideP$Total.Phosphorus)) & (!is.na(wideP$Dissolved.Reactive.Phosphorus)) & (wideP$Total.Phosphorus < wideP$Dissolved.Reactive.Phosphorus)] <- "DRP result > TP result."
  workingP <- merge(workingP, wideP[c("Site","Time", "PSumComment")], by = c("Site", "Time"))
  
  working <- merge(working, workingP[c("Site", "StdMeasurementName", "Time", "PSumComment")], by = c("Site", "StdMeasurementName", "Time"), all.x = TRUE)
  
  #working$QualityCode[!is.na(working$PSumComment)] <- "200"
  #Refined so only down codes if the lab hasn't flagged it as acceptable.
  #Refine so don't downcode for missing data, and if DRP >TP and not within lab range then 400
  #working$QualityCode[working$PSumComment != "DRP result > TP result."] <- "200"
  #working$QualityCode[working$PSumComment == "DRP result > TP result." & (working$LabCommentCheck != "" | working$TestOverride != "DRP>TP")] <- "200"
  
  working$PSumFinalComment[working$PSumComment == "DRP result > TP result." & (working$Lab.Comment != working$Acceptable.Lab.Comment)] <- "DRP result > TP result."
  working$PSumFinalComment[working$PSumComment == "DRP result > TP result." & (working$Lab.Comment == working$Acceptable.Lab.Comment)] <- "DRP result > TP result, but within lab error."
  
  working$QualityCode[working$QualityCode != "200" & working$PSumFinalComment == "DRP result > TP result."] <- "400"
  
  working
}

NChecks <- function(working) {
  #Check N data
  #Dissolved Inorganic Nitrogen and Total Organic Nitrogen are calculated in Puddle so code as Synthetic.
  #Maybe change to look for calculation in the method and code to 300 any that are calculated. Now done at the end based on MaxCode field.
  
  #working$QualityCode[working$StdMeasurementName == "Dissolved.Inorganic.Nitrogen"] <- "300"
  #working$QualityCode[working$StdMeasurementName == "Total.Organic.Nitrogen"] <- "300"
  
  #Subset to get N data for calc checks
  
  workingN <- subset(working, StdMeasurementName %in% c("Total.Nitrogen", "Ammoniacal.Nitrogen", "Nitrate.Nitrite.Nitrogen", "Nitrate.Nitrogen", "Nitrite.Nitrogen", "Total.Kjeldahl.Nitrogen", "Total.Organic.Nitrogen", "Dissolved.Inorganic.Nitrogen"))
  wideN <- dcast(workingN, Site + Time + Sample.Number ~ StdMeasurementName, value.var = "result")
  wideN$NSumComment <-""
  wideN$TKNCheck <-""
  wideN$NNNCheck <-""
  wideN$TNCheck <-""
  wideN$NNN.NO3Check <- ""
  
  wideN$NNN.SumCheck <- ""
  wideN$TONCheck <- ""
  wideN$DINCheck <- ""
  names(wideN) <- make.names(names(wideN), unique = TRUE)
  #calculate the number of decimal places of the results, for later rounding checks
  wideN$NH4.DP <- sapply(wideN$Ammoniacal.Nitrogen, decimalplaces)
  
  wideN$NNN.DP <- sapply(wideN$Nitrate.Nitrite.Nitrogen, decimalplaces)
  wideN$NO3.DP <- sapply(wideN$Nitrate.Nitrogen, decimalplaces)
  wideN$NO2.DP <- sapply(wideN$Nitrite.Nitrogen, decimalplaces)
  wideN$TKN.DP <- sapply(wideN$Total.Kjeldahl.Nitrogen, decimalplaces)
  wideN$TN.DP <- sapply(wideN$Total.Nitrogen, decimalplaces)
  
  #TKN and TN check sums
  wideN$TKNMissingCheck[is.na(wideN$Total.Kjeldahl.Nitrogen) | is.na(wideN$Ammoniacal.Nitrogen)] <- "Missing Ammoniacal-N or TKN result. "
  wideN$TKNCheckMinDigits <- pmin(wideN$TKN.DP, wideN$NH4.DP, na.rm = TRUE)
  wideN$TKNCheckTKNValue <- round(wideN$Total.Kjeldahl.Nitrogen, digits = wideN$TKNCheckMinDigits)
  wideN$TKNCheckAmmNValue <- round(wideN$Ammoniacal.Nitrogen, digits = wideN$TKNCheckMinDigits)
  wideN$TKNSumCheck[wideN$TKNCheckTKNValue < wideN$TKNCheckAmmNValue] <- "Ammoniacal N result > TKN result. "
  wideN$TKNSumCheck[is.na(wideN$TKNSumCheck)] <- ""
  wideN$TKNMissingCheck[is.na(wideN$TKNMissingCheck)] <- ""
  
  wideN$TNCheckMinDigits <- pmin(wideN$TN.DP, wideN$TKN.DP, wideN$NNN.DP, na.rm = TRUE)
  wideN$TNCheckTNValue <- round(wideN$Total.Nitrogen, digits = wideN$TNCheckMinDigits)
  wideN$TNCheckTKN.NNNValue <- round(wideN$Total.Kjeldahl.Nitrogen + wideN$Nitrate.Nitrite.Nitrogen, digits = wideN$TNCheckMinDigits)
  #wideN$TNCheck[wideN$TNCheckTNValue < wideN$TNCheckTKN.NNNValue] <- "Total N less than TKN + NNN. "
  #TKN.LLD <- WQMeasurements$LLD[WQMeasurements$StdMeasurementName == "Total.Kjeldahl.Nitrogen"]
  #wideN$TNCheck[!is.na(wideN$TNCheckTNValue) & !is.na(wideN$TNCheckTKN.NNNValue) & wideN$TNCheckTNValue < wideN$TNCheckTKN.NNNValue] <- ifelse((wideN$Total.Kjeldahl.Nitrogen[!is.na(wideN$TNCheckTNValue) & !is.na(wideN$TNCheckTKN.NNNValue) & wideN$TNCheckTNValue < wideN$TNCheckTKN.NNNValue] == TKN.LLD) & (wideN$Nitrate.Nitrite.Nitrogen[!is.na(wideN$TNCheckTNValue) & !is.na(wideN$TNCheckTKN.NNNValue) & wideN$TNCheckTNValue < wideN$TNCheckTKN.NNNValue] <= wideN$Total.Nitrogen[!is.na(wideN$TNCheckTNValue) & !is.na(wideN$TNCheckTKN.NNNValue) & wideN$TNCheckTNValue < wideN$TNCheckTKN.NNNValue]) & (wideN$Total.Nitrogen[!is.na(wideN$TNCheckTNValue) & !is.na(wideN$TNCheckTKN.NNNValue) & wideN$TNCheckTNValue < wideN$TNCheckTKN.NNNValue] < (TKN.LLD + wideN$Nitrate.Nitrite.Nitrogen[!is.na(wideN$TNCheckTNValue) & !is.na(wideN$TNCheckTKN.NNNValue) & wideN$TNCheckTNValue < wideN$TNCheckTKN.NNNValue])),"","Total N less than TKN + NNN. ")
  wideN$TNCheckAllowedDiff <- exp(-wideN$TNCheckMinDigits)
  wideN$TNCheckActualDiff <- abs(wideN$TNCheckTNValue - wideN$TNCheckTKN.NNNValue)
  wideN$TNSumCheck[wideN$TNCheckAllowedDiff < wideN$TNCheckActualDiff] <- "Total N unexpected from TKN + NNN. "
  wideN$TNMissingCheck[is.na(wideN$Total.Nitrogen) | is.na(wideN$Total.Kjeldahl.Nitrogen) | is.na(wideN$Nitrate.Nitrite.Nitrogen)] <- "Missing TN, TKN or NNN result. "
  wideN$TNSumCheck[is.na(wideN$TNSumCheck)] <- ""
  wideN$TNMissingCheck[is.na(wideN$TNMissingCheck)] <- ""
  
  
  #NNN, Nitrate and Nitrite Checks
  #NNN > Nitrate
  #wideN$NNNCheck[wideN$Nitrate...Nitrite.Nitrogen < wideN$Nitrate.Nitrogen] <- "NNN result less than Nitrate result. "
  wideN$NNNCheck[wideN$Nitrate.Nitrite.Nitrogen < wideN$Nitrate.Nitrogen] <- "NNN result less than Nitrate result. "
  
  
  #NNN sum check
  wideN$NNNCheckMinDigits <- pmin(wideN$NNN.DP, wideN$NO3.DP, wideN$NO2.DP, na.rm = TRUE)
  wideN$NNNCheck.NNNValue <- round(wideN$Nitrate.Nitrite.Nitrogen, digits = wideN$NNNCheckMinDigits)
  wideN$NNNCheck.NO3.NO2.Value <- round(wideN$Nitrate.Nitrogen + wideN$Nitrite.Nitrogen, digits = wideN$NNNCheckMinDigits)
  wideN$NNNCheckAllowedDiff <- exp(-wideN$NNNCheckMinDigits)
  wideN$NNNCheckActualDiff <- abs(wideN$NNNCheck.NNNValue - wideN$NNNCheck.NO3.NO2.Value)
  wideN$NNN.SumCheck[(wideN$NNNCheckAllowedDiff < wideN$NNNCheckActualDiff)] <- "NNN sum error. "
  #wideN$NNN.SumCheck[((wideN$Nitrate.Nitrogen + wideN$Nitrite.Nitrogen) > (wideN$Nitrate.Nitrite.Nitrogen + 0.001)) & ((wideN$Nitrite.Nitrogen/wideN$Nitrate.Nitrogen) > 0.01)] <- "NNN sum error. "
  
  #TON Check
  
  wideN$Calc.TON <- wideN$Total.Kjeldahl.Nitrogen - wideN$Ammoniacal.Nitrogen
  #wideN$TONCheck[!is.na(wideN$Total.Kjeldahl.Nitrogen) & !is.na(wideN$Ammoniacal.Nitrogen) & !is.na(wideN$Total.Organic.Nitrogen) & (wideN$Total.Organic.Nitrogen != wideN$Calc.TON)] <- "TON different to TKN - Ammoniacal N. "
  wideN$TONSumCheck <- ifelse(round(wideN$Total.Organic.Nitrogen, digits = 4) != round(wideN$Calc.TON, digits = 4), "TON different to TKN - Ammoniacal N. ", wideN$TONCheck)
  wideN$TONMissingCheck[is.na(wideN$Total.Kjeldahl.Nitrogen) | is.na(wideN$Ammoniacal.Nitrogen) | is.na(wideN$Total.Organic.Nitrogen)] <- "Missing TKN, Ammoniacal-N or TON result. "
  wideN$TONSumCheck[is.na(wideN$TONSumCheck)] <- ""
  wideN$TONMissingCheck[is.na(wideN$TONMissingCheck)] <- ""
  
  #DIN Check
  
  wideN$Calc.DIN <- wideN$Ammoniacal.Nitrogen + wideN$Nitrate.Nitrogen + wideN$Nitrite.Nitrogen
  #wideN$DINCheck[!is.na(wideN$Dissolved.Inorganic.Nitrogen) & !is.na(wideN$Ammoniacal.Nitrogen) & !is.na(wideN$Nitrate.Nitrogen) & !is.na(wideN$Nitrite.Nitrogen) & (wideN$Dissolved.Inorganic.Nitrogen != wideN$Calc.DIN)] <- "DIN different to Ammoniacal N + NO3 + NO2. "
  wideN$DINSumCheck <- ifelse(round(wideN$Dissolved.Inorganic.Nitrogen, digits = 4) != round(wideN$Calc.DIN, digits = 4), "DIN different to Ammoniacal N + NO3 + NO2. ", wideN$DINCheck)
  wideN$DINMissingCheck[is.na(wideN$Dissolved.Inorganic.Nitrogen) | is.na(wideN$Ammoniacal.Nitrogen) | is.na(wideN$Nitrate.Nitrogen) | is.na(wideN$Nitrite.Nitrogen)] <- "Missing DIN, Ammoniacal-N, NO3-N, or NO2-N result. "
  wideN$DINSumCheck[is.na(wideN$DINSumCheck)] <- ""
  wideN$DINMissingCheck[is.na(wideN$DINMissingCheck)] <- ""
  
  #Aggregate the N checks
  #Don't aggregate sum checks (so can split out what is affected later)
  #wideN$NSumComment <- paste(wideN$TKNSumCheck, wideN$TNSumCheck, wideN$NNNCheck, wideN$NNN.SumCheck, wideN$TONSumCheck, wideN$DINSumCheck, sep = "")
  #wideN$NSumComment[wideN$NSumComment == ""] <- NA
  
  wideN$NMissingComment <- paste(wideN$TKNMissingCheck, wideN$TNMissingCheck, wideN$TONMissingCheck, wideN$DINMissingCheck, sep = "")
  wideN$NMissingComment[wideN$NMissingComment == ""] <- NA
  
  #Output N results as csv for checking
  write.csv(wideN, paste("Data/", format(Sys.Date(), "%Y%m%d"),"NResultsAndChecks.csv", sep =""), row.names = FALSE)
  
  #Merge N checks with working data frame, aggregated missing checks, but individual sum checks
  #workingN <- merge(workingN, wideN[c("Site","Time", "NSumComment", "NMissingComment")], by = c("Site", "Time"))
  workingN <- merge(workingN, wideN[c("Site","Time", "TKNSumCheck", "TNSumCheck", "NNN.SumCheck", "TONSumCheck", "DINSumCheck", "NMissingComment")], by = c("Site", "Time"))
  #For each N sum check need to remove comments for species that aren't relevant
  if(length(workingN$TONSumCheck[workingN$TONSumCheck != "" & !(workingN$StdMeasurementName %in% c("Total.Organic.Nitrogen", "Ammoniacal.Nitrogen", "Total.Kjeldahl.Nitrogen"))] > 0)) {
    workingN$TONSumCheck[workingN$TONSumCheck != "" & !(workingN$StdMeasurementName %in% c("Total.Organic.Nitrogen", "Ammoniacal.Nitrogen", "Total.Kjeldahl.Nitrogen"))] <- ""
  }
  
  if(length(workingN$DINSumCheck[workingN$DINSumCheck != "" & !(workingN$StdMeasurementName %in% c("Ammoniacal.Nitrogen", "Nitrate.Nitrogen", "Nitrite.Nitrogen", "Nitrate.Nitrite.Nitrogen"))]) > 0) {
    workingN$DINSumCheck[workingN$DINSumCheck != "" & !(workingN$StdMeasurementName %in% c("Ammoniacal.Nitrogen", "Nitrate.Nitrogen", "Nitrite.Nitrogen", "Nitrate.Nitrite.Nitrogen"))] <- ""
    }
  
  if(length(workingN$NNNSumCheck[workingN$NNNSumCheck != "" & !(workingN$StdMeasurementName %in% c("Nitrate.Nitrogen", "Nitrite.Nitrogen", "Nitrate.Nitrite.Nitrogen"))]) > 0) {
    workingN$NNNSumCheck[workingN$NNNSumCheck != "" & !(workingN$StdMeasurementName %in% c("Nitrate.Nitrogen", "Nitrite.Nitrogen", "Nitrate.Nitrite.Nitrogen"))] <- ""
  }
  
  if(length(workingN$TKNSumCheck[workingN$TKNSumCheck != "" & !(workingN$StdMeasurementName %in% c("Ammoniacal.Nitrogen", "Total.Kjeldahl.Nitrogen"))]) > 0) {
    workingN$TKNSumCheck[workingN$TKNSumCheck != "" & !(workingN$StdMeasurementName %in% c("Ammoniacal.Nitrogen", "Total.Kjeldahl.Nitrogen"))] <- ""
    }
  
  
  #Add NSum comment in here so takes into account above cleansing
  workingN$NSumComment <- paste(workingN$TKNSumCheck, workingN$TNSumCheck, workingN$NNNCheck, workingN$NNN.SumCheck, workingN$TONSumCheck, workingN$DINSumCheck, sep = "")
  
  
  #TODO Refine downcoding so only if results out of sync it goes to 400
  working <- merge(working, workingN[c("Site", "StdMeasurementName", "Time", "NSumComment", "NMissingComment")], by = c("Site", "StdMeasurementName", "Time"), all.x = TRUE)
  
  
  
  
  working$QualityCode[working$NSumComment != ""] <- "200"
  
  #Sort handling less than figures
  
  working
}

SSChecks <- function(working) {
  #Check SS
  #Subset to get SS data
  
  workingSS <- subset(working, StdMeasurementName %in% c("Suspended.Solids", "Volatile.Suspended.Solids"))
  wideSS <- dcast(workingSS, Site + Time ~ StdMeasurementName, value.var = "result")
  wideSS$SSSumComment <-NA
  names(wideSS) <- make.names(names(wideSS), unique = TRUE)
  wideSS$SSSumComment[is.na(wideSS$Suspended.Solids)] <- "No SS result."
  wideSS$SSSumComment[is.na(wideSS$Volatile.Suspended.Solids)] <- "No VSS result."
  wideSS$SSSumComment[(!is.na(wideSS$Suspended.Solids)) & (!is.na(wideSS$Volatile.Suspended.Solids)) & (wideSS$Suspended.Solids < wideSS$Volatile.Suspended.Solids)] <- "VSS result > SS result."
  workingSS <- merge(workingSS, wideSS[c("Site","Time", "SSSumComment")], by = c("Site", "Time"))
  
  working <- merge(working, workingSS[c("Site", "StdMeasurementName", "Time", "SSSumComment")], by = c("Site", "StdMeasurementName", "Time"), all.x = TRUE)
  
  #Updated so only flags if there isn't a test override 
  #working$QualityCode[!is.na(working$SSSumComment)] <- "200"
  
  #Refined so only down codes if the lab hasn't flagged it as acceptable.
  #Refined so downcode to 400 if VSS > SS, but passes through if missing.
  #working$QualityCode[working$SSSumComment != "VSS result > SS result."] <- "200"
  working$QualityCode[working$QualityCode != "200" & working$SSSumComment == "VSS result > SS result." & (working$LabCommentCheck != "" | working$TestOverride != "VSS>SS")] <- "400"
  #working$QualityCode[working$SSSumComment == "VSS result > SS result." & (working$LabCommentCheck != "" | working$TestOverride != "VSS>SS")] <- "200"
  working$SSSumComment[working$SSSumComment == "VSS result > SS result." & !(working$LabCommentCheck != "" | working$TestOverride != "VSS>SS")] <- "VSS result > SS result, but accepted by Lab."
  
  working
}

scatterPlotCheck <- function(working, WQSites, goodProcessedData, graphing){
  if(missing(graphing)) {graphing = TRUE}
  
  #Check 'scatter plots' compared with 600 data.
  modelInfo <- read.csv("Data/Model_Info.csv", stringsAsFactors=FALSE)
  paramList <- data.frame(param = union(modelInfo$Param.x, modelInfo$Param.y))
  
  compVariables <- paramList$param
  #compVariables <- c("Turbidity", "Suspended.Solids", "Total.Phosphorus", "E.Coli")
  
  goodCVData <- subset(goodProcessedData, StdMeasurementName %in% compVariables)
  #Only use data with results
  goodCVData <- subset(goodCVData, valueprefix == "=")
  #Reformat to wide format
  if (length(goodCVData$Site) > 0) {
    wideGoodCVData <- dcast(goodCVData, Site + Time ~ StdMeasurementName, value.var = "result", fun.aggregate = mean, na.rm = TRUE)
  } else {
    wideGoodCVData <- data.frame(Site = WQSites, Time = "00:00:00", Turbidity = NA, Suspended.Solids = NA, Total.Phosphorus = NA, E.Coli = NA)}
  
  
  #Tidy up the column names
  names(wideGoodCVData) <- make.names(names(wideGoodCVData), unique = TRUE)
  
  #Check all measurements are present in wideGoodCVData, add columns if not
  
  
  #compFields <- c("Turbidity", "Suspended.Solids", "Total.Phosphorus", "E.Coli")
  
  
  missingFields <- setdiff(compVariables, colnames(wideGoodCVData))
  if(length(missingFields) > 0) {for(m in 1:length(missingFields)) {wideGoodCVData[missingFields[m]] <- NA}}
  
  #Check all sites are present in wideGoodCVData, add rows if not
  
  wideGoodCVData <- merge(wideGoodCVData, WQSites, all = TRUE)
  
  
  #Extract data for processing
  workingCVData <- subset(working, StdMeasurementName %in% compVariables)
  
  #eskTurb(workingCVData, "06WorkingCVDataBeforeLoop")
  
  wideWorkingCVData <- dcast(workingCVData, Site + Time ~ StdMeasurementName, value.var = "result", fun.aggregate = mean, na.rm = TRUE)
  
  names(wideWorkingCVData) <- make.names(names(wideWorkingCVData), unique = TRUE)
  
  
  # create an empty dataframe to append the results to for eventual output
  wideWorkingCVDataPredictions<-data.frame(Site=character(), 
                                           stringsAsFactors=FALSE) 
  
  #For each site
  sites <- unique(wideGoodCVData$Site)
  
  #modelInfo <- read.csv("Model_Info.csv", stringsAsFactors=FALSE)
  #create directory to put the model plots in
  dir.create(paste("Data/",format(Sys.Date(), "%Y%m%d"),"_Model_Plots", sep = ""))
  #i <-1
  for (i in 1:length(sites)) {
    cleanSiteString <- gsub('[^a-zA-Z]', '', sites[i])
    
    #Subset the good data by site and create the models for the relationships, check how NA handled so best models produced
    siteGoodData <- NULL
    siteWorkingCVData <- NULL
    
    #Subset the working data by site, apply the models to get confidence intervals for the response variables
    
    siteWorkingCVData <- subset(wideWorkingCVData, Site == sites[i])
    
    siteGoodData <- subset(wideGoodCVData, Site == sites[i])
    
    
    
    #New All in one code
    #m <- 1
    message(sites[i])
    for (m in 1:nrow(modelInfo)) {
      message(modelInfo$Name[m])
      px <- modelInfo$Param.x[m]
      py <- modelInfo$Param.y[m]
      fml <- as.formula(paste("log(", py, ") ~ log(", px, ")", sep = ""))
      #message("Creating Model.")
      #model <- tryCatch({lm(fml, data = siteGoodData, na.action=na.omit)}, warning = function(w) {return(NULL)}, error = function(e) {return(NULL)})
      model <- tryCatch({lm(fml, data = siteGoodData, na.action=na.omit)}, error = function(e) {return(NULL)})
      #message("Model Created")
      #Create a dataframe to fit the model to
      nd <- as.data.frame(siteWorkingCVData[[paste0(px)]])
      names(nd) <- px
      #if(!is.null(model)) {
      #if(exists(turb_SS_Site_model)) {
      #message("Predicting good.")
      #predicted <- tryCatch({data.frame(exp(predict(model, newdata = nd, interval = "prediction", level = 0.95)))}, warning = function(w) {return(NULL)}, error = function(e) {return(NULL)})
      predicted <- tryCatch({data.frame(exp(predict(model, newdata = nd, interval = "prediction", level = 0.95)))}, error = function(e) {return(NULL)})
      #message("Predicted good")
      #Change the names so that they are descriptive and unique
      #names(predicted) <- c(paste0("Predict.",modelInfo$ColName[m]), paste0("Lower.", modelInfo$ColName[m]), paste0("Upper.", modelInfo$ColName[m]))
      #}
      if(!is.null(predicted)) {
        #Change the names so that they are descriptive and unique
        names(predicted) <- c(paste0("Predict.",modelInfo$ColName[m]), paste0("Lower.", modelInfo$ColName[m]), paste0("Upper.", modelInfo$ColName[m]))
        siteWorkingCVData <- bind_cols(siteWorkingCVData, predicted)
      }
      
      #test_data <- tryCatch({as.data.frame(seq(min(siteGoodData[,paste0(modelInfo$Param.x[m])], na.rm = TRUE), max(siteGoodData[,paste0(modelInfo$Param.x[m])], na.rm = TRUE), length.out=100))}, warning = function(w) {return(NULL)}, error = function(e) {return(NULL)})
      test_data <- tryCatch({as.data.frame(seq(min(siteGoodData[[paste0(px)]], na.rm = TRUE), max(siteGoodData[[paste0(px)]], na.rm = TRUE), length.out=100))}, error = function(e) {return(NULL)})
      if(!is.null(test_data)) {names(test_data) <- modelInfo$Param.x[m]}
      #message("Predicting Test")
      #predmodel <- tryCatch({data.frame(exp(predict(model, newdata = test_data, interval = "prediction", level = 0.95)))}, warning = function(w) {return(NULL)}, error = function(e) {return(NULL)})
      predmodel <- tryCatch({data.frame(exp(predict(model, newdata = test_data, interval = "prediction", level = 0.95)))}, error = function(e) {return(NULL)})
      if(!is.null(predmodel)) {
        plotmodel <- cbind(predmodel, test_data)
      } else plotmodel <- NULL
      #plotmodel <- cbind(predmodel, test_data)
      #message("Predicted Test")
      if(!is.null(plotmodel) & graphing == TRUE) {
        
        
        #tryCatch({
        png(filename=paste("Data/", format(Sys.Date(), "%Y%m%d"),"_Model_Plots/", format(Sys.Date(), "%Y%m%d"),cleanSiteString,"_", modelInfo$Name[m],".png", sep =""))
        
        logPlot <- ggplot(data = siteGoodData, aes_string(paste0("log(", px, ")"), paste0("log(", py, ")"))) +
          geom_point() +
          geom_line(data = plotmodel, aes_string(paste0("log(", px, ")"), "log(fit)"), colour = "blue") +
          geom_line(data = plotmodel, aes_string(paste0("log(", px, ")"), "log(lwr)"), colour = "red") +
          geom_line(data = plotmodel, aes_string(paste0("log(", px, ")"), "log(upr)"), colour = "red") +
          geom_hline(aes(yintercept = log(summarySiteMeas$p95[summarySiteMeas$Site==sites[i] & summarySiteMeas$StdMeasurementName == py])), colour = "green") +
          geom_vline(aes(xintercept = log(summarySiteMeas$p95[summarySiteMeas$Site==sites[i] & summarySiteMeas$StdMeasurementName == px])), colour = "green") +
          ggtitle(paste0("log(", px, ") v log(", py, ")"))
        
        scatterPlot <- ggplot(siteGoodData, aes_string(x = paste0(px), y = paste0(py))) +
          geom_point() +
          geom_line(data = plotmodel, aes_string(paste0(px), "fit"), colour = "blue") +
          geom_line(data = plotmodel, aes_string(paste0(px), "lwr"), colour = "red") +
          geom_line(data = plotmodel, aes_string(paste0(px), "upr"), colour = "red") +
          geom_hline(aes(yintercept = summarySiteMeas$p95[summarySiteMeas$Site==sites[i] & summarySiteMeas$StdMeasurementName == py]), colour = "green") +
          geom_vline(aes(xintercept = summarySiteMeas$p95[summarySiteMeas$Site==sites[i] & summarySiteMeas$StdMeasurementName == px]), colour = "green") +
          ggtitle(paste0(px, " v ", py))
        
        textR2 <- textGrob(paste("R2", round(as.numeric(summary(model)$r.squared), 3)))
        
        print(grid.arrange(logPlot, scatterPlot, textR2, ncol = 2, top = sites[i]))
        
        dev.off()
        #}, warning = function(w) {message(w)}, error = function(e) {return(NULL)})
      }
      
      
      
    }
    
    #Add the r2, or F stat for each model so fit can be assessed, doesn't seem to be needed.
    
    #Combine the dataframes
    wideWorkingCVDataPredictions <- bind_rows(wideWorkingCVDataPredictions,siteWorkingCVData)#append the data to the dataframe for all sites
    
    
    
  }
  
  #Make sure there are rows in for all Sites
  
  #Get column names to help with checks
  colNameCheck <- colnames(wideWorkingCVDataPredictions)
  
  #Convert all NA to "".
  wideWorkingCVDataPredictions[is.na(wideWorkingCVDataPredictions)] <- ""
  
  
  for (m in 1:nrow(modelInfo)) {
    wideWorkingCVDataPredictions[, paste0(modelInfo$ColName[m],".Comment")] <- ""
    colName <- modelInfo$ColName[m]
    xParam <- modelInfo$Param.x[m]
    yParam <- modelInfo$Param.y[m]
    if(paste0("Lower.", colName) %in% colNameCheck) {
      
      #wideWorkingCVDataPredictions[[paste0(colName,".Comment")]] <- ifelse(as.numeric(wideWorkingCVDataPredictions[[paste0(yParam)]]) < as.numeric(wideWorkingCVDataPredictions[[paste0("Lower.", colName)]]), paste0(yParam, " unexpected from ", xParam), "")
      #wideWorkingCVDataPredictions[[paste0(colName,".Comment")]] <- ifelse(as.numeric(wideWorkingCVDataPredictions[[paste0(yParam)]]) > as.numeric(wideWorkingCVDataPredictions[[paste0("Upper.", colName)]]), paste0(yParam, " unexpected from ", xParam), "")
      wideWorkingCVDataPredictions[[paste0(colName,".Comment")]] <- ifelse(as.numeric(wideWorkingCVDataPredictions[[paste0(yParam)]]) < as.numeric(wideWorkingCVDataPredictions[[paste0("Lower.", colName)]]), paste0(yParam, " unexpected from ", xParam, "; "), ifelse(as.numeric(wideWorkingCVDataPredictions[[paste0(yParam)]]) > as.numeric(wideWorkingCVDataPredictions[[paste0("Upper.", colName)]]), paste0(yParam, " unexpected from ", xParam, "; "), ""))
      
      wideWorkingCVDataPredictions[[paste0(colName,".Comment")]][wideWorkingCVDataPredictions[[paste0("Lower.", colName)]] == ""] <- paste0("No ", yParam,  " ", xParam, " model bounds ; ")
      wideWorkingCVDataPredictions[[paste0(colName,".Comment")]][wideWorkingCVDataPredictions[[paste0("Upper.", colName)]] == ""] <- paste0("No ", yParam,  " ", xParam, " model bounds ; ")
      
      wideWorkingCVDataPredictions[[paste0(colName,".Comment")]][wideWorkingCVDataPredictions[[xParam]] == ""] <- paste0("Missing ", xParam, " or ", yParam,"; ")
      wideWorkingCVDataPredictions[[paste0(colName,".Comment")]][wideWorkingCVDataPredictions[[yParam]] == ""] <- paste0("Missing ", xParam, " or ", yParam,"; ")
      
    } else {
      wideWorkingCVDataPredictions[, paste0(colName,".Comment")] <- paste0("No ", yParam,  xParam, " model.")
    }
  }
  
  #Convert all NA to "".
  wideWorkingCVDataPredictions[is.na(wideWorkingCVDataPredictions)] <- ""
  
  #Aggregate the comments so that all potential issues with a parameter are combined
  
  
  
  for (p in 1:nrow(paramList)) {
    paramModelInfo <- subset(modelInfo, Param.x==paramList$param[p] | Param.y==paramList$param[p])
    paramModelInfo$CommentCol <- paste0(paramModelInfo$ColName,".Comment")
    wideWorkingCVDataPredictions[, paste0(paramList$param[p], ".Comparison.Comment")] <- trimws(do.call(paste, c(wideWorkingCVDataPredictions[paramModelInfo$CommentCol], sep=" ")))
    
  }
  
  baseList <- data.frame(colName = c("Site", "Time"))
  commentCols <- data.frame(colName = paste0(paramList$param, ".Comparison.Comment"))
  usefulCols <- union(baseList$colName, commentCols$colName)
  
  
  #Combine with working CV data
  
  workingCVData <- merge(workingCVData, wideWorkingCVDataPredictions[usefulCols], by = c("Site", "Time"))
  
  #Condense to single, relevant comment field.  
  
  workingCVData$Comparison.Comment <- NA
  finalWorkingCVData <- NULL
  
  for (pc in 1:nrow(paramList)) {
    templist <- NULL
    templist <- subset(workingCVData, StdMeasurementName == paramList$param[pc])
    templist$Comparison.Comment <- ifelse(templist[,paste0(paramList$param[pc], ".Comparison.Comment")]!="", templist[,paste0(paramList$param[pc], ".Comparison.Comment")], NA)
    #workingCVData$Comparison.Comment[workingCVData$StdMeasurementName == paramList$param[pc]] <- ifelse(workingCVData[,paste0(paramList$param[pc], ".Comparison.Comment")]!="", workingCVData[,paste0(paramList$param[pc], ".Comparison.Comment")], NA)
    
    finalWorkingCVData <- bind_rows(finalWorkingCVData, templist)
    
  }
  
  #Recombine with working
  #working <- merge(working, finalWorkingCVData[c("Site", "StdMeasurementName", "Time", "Comparison.Comment")], by = c("Site", "StdMeasurementName", "Time"), all.x = TRUE)
  working <- merge(working, finalWorkingCVData[c("Site", "Measurement", "Time", "Comparison.Comment")], by = c("Site", "Measurement", "Time"), all.x = TRUE)
  
  #Add in the quality coding here (move from main body)
  
  working
}