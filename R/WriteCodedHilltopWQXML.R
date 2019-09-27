## Load libraries ------------------------------------------------

#Install the required packages
pkgs <- c('XML', 'dplyr', 'lubridate')
if(!all(pkgs %in% installed.packages()[, 'Package']))
  install.packages(pkgs, dep = T)

require(XML)     ### XML library to write hilltop XML
require(dplyr)
require(lubridate)  ###Date handling library


#Read in the data

datatbl <- read.csv("Data/20190927WQCodedResultsClean.csv", stringsAsFactors = FALSE)

#Subset so that only coded data is kept
datatbl <- subset(datatbl, QualityCode > 200 & QualityCode != 400)

#Subset to remove impossible pH
datatbl <- subset(datatbl, !(StdMeasurementName == "pH" & result >= 14))
datatbl <- subset(datatbl, (result >= 0))

#Add in a blank Sampling.Issue column if one doesn't exist
if (!("Sampling.Issue" %in% colnames(datatbl))) {datatbl$Sampling.Issue <- ""}

#Need to convert Time to time date format

#Trim "DateTime_" from the Time field and convert to a date format
datatbl$Time <- gsub("DateTime_","",datatbl$Time)

#Trim "DateTime_" from the entered date, updated dates, and verified date fields, remove any NA values
datatbl$Entered.to.Puddle.date <- gsub("DateTime_","",datatbl$Entered.to.Puddle.date)
datatbl$Updated.date <- gsub("DateTime_","",datatbl$Updated.date)
datatbl$Puddle.verified.date <- gsub("DateTime_","",datatbl$Puddle.verified.date)

datatbl[datatbl$Entered.to.Puddle.date == "NA",]$Entered.to.Puddle.date <- ""
datatbl[datatbl$Updated.date == "NA",]$Updated.date <- ""
datatbl[datatbl$Puddle.verified.date == "NA",]$Puddle.verified.date <- ""

#datatbl$Time <- as.POSIXct(datatbl$Time)

#Create / update mowsecs column (making sure NZ time correction done) 
#Hilltop / sample time is NZ time zone, Mowsecs are the number of seconds since 1 Jan 1940 in UTC time!  Lubridate helps a lot.
mowsecRefDate <- with_tz(ymd("1940-01-01"), "UTC")

datatbl$mowsecs <- difftime(with_tz(parse_date_time(datatbl$Time, "Ymd HMS"), "NZ"), mowsecRefDate, unit="secs")

#Make sure it is ordered by site, measurement and mowsecs
datatbl <- datatbl[order(datatbl$Site, datatbl$Measurement, datatbl$mowsecs),]
#Remove NA values
datatbl[is.na(datatbl)] <- ""
datatbl$DataSource <- gsub(".*\\[|\\].*", "", datatbl$Measurements)

## Build XML Document --------------------------------------------
tm<-Sys.time()
cat("Building XML\n")
cat("Creating:",Sys.time()-tm,"\n")

con <- xmlOutputDOM("Hilltop")
con$addTag("Agency", "HBRC")

max<-nrow(datatbl)


i<-1
#for each site
while(i<=max){
  s<-datatbl$Site[i]
  # store first counter going into while loop to use later in writing out sample values
  start<-i
  
  cat(i,datatbl$Site[i],"\n")   ### Monitoring progress as code runs
  
  while(datatbl$Site[i]==s){
    #for each measurement
    #cat(datatbl$SiteName[i],"\n")
    con$addTag("Measurement",  attrs=c(SiteName=datatbl$Site[i]), close=FALSE)
    #con$addTag("DataSource",  attrs=c(Name=datatbl$Measurement[i],NumItems=datatbl$NumberOfItems[i]), close=FALSE)
    con$addTag("DataSource",  attrs=c(Name=datatbl$DataSource[i],NumItems=2), close=FALSE)
    con$addTag("TSType", "StdSeries")
    con$addTag("DataType", "WQData")
    con$addTag("Interpolation", "Discrete")
    con$addTag("ItemInfo", attrs=c(ItemNumber="1"),close=FALSE)
    con$addTag("ItemName", datatbl$Measurement[i])
    con$addTag("ItemFormat", "F")
    con$addTag("Divisor", "1")
    con$addTag("Units", datatbl$Units[i])
    #con$addTag("Units", "Joking")
    #con$addTag("Format", datatbl$Format[i])
    con$addTag("Format", '$$$')
    con$closeTag() # ItemInfo
    con$closeTag() # DataSource
    #saveXML(con$value(), file="out.xml")
    
    # for the TVP and associated measurement water quality parameters
    con$addTag("Data", attrs=c(DateFormat="mowsecs", NumItems="2"),close=FALSE)
    d<- datatbl$Measurement[i]
    
    cat("       - ",datatbl$Measurement[i],"\n")   ### Monitoring progress as code runs
    
    while(datatbl$Measurement[i]==d){
      # for each tvp
      con$addTag("E",close=FALSE)
      con$addTag("T",datatbl$mowsecs[i]) 
      con$addTag("I1", datatbl$result[i])
      con$addTag("I2", paste("Method\t",datatbl$Method[i],"\t",
                             "Entered to Puddle by\t",datatbl$Entered.to.Puddle.by[i],"\t",
                             "Entered to Puddle date\t",datatbl$Entered.to.Puddle.date[i],"\t",
                             "Updated by\t",datatbl$Updated.by[i],"\t",
                             "Updated date\t",datatbl$Updated.date[i],"\t",
                             "Measurement QC Comment\t", datatbl$Measurement.QC.Comment[i], "\t",
                             "Lab Comment\t", datatbl$Lab.Comment[i], "\t",
                             #"Collection Method\t", datatbl$CollectionMethod[i], "\t",
                             "Collection Method\t", datatbl$Collection.Method[i], "\t",
                             if(datatbl$valueprefix[i] == "<"){paste("$ND\t", "<;", "\t", sep="")} else if(datatbl$valueprefix[i] == ">") {paste("$ND\t", ">;", "\t", sep="")}, 
                             "$QC\t", datatbl$QualityCode[i], "\t",sep=""))
      
      con$closeTag() # E
      i<-i+1 # incrementing overall for loop counter
      if(i>max){break}
    }
    # next
    con$closeTag() # Data
    con$closeTag() # Measurement
    if(i>max){break}
    # Next 
  }
  # store last counter going out of while loop to use later in writing out sample values
  end<-i-1
  
  # Adding WQ Sample Datasource to finish off this Site
  # along with Sample parameters
  con$addTag("Measurement",  attrs=c(SiteName=datatbl$Site[start]), close=FALSE)
  con$addTag("DataSource",  attrs=c(Name="WQ Sample", NumItems="1"), close=FALSE)
  con$addTag("TSType", "StdSeries")
  con$addTag("DataType", "WQSample")
  con$addTag("Interpolation", "Discrete")
  con$addTag("ItemInfo", attrs=c(ItemNumber="1"),close=FALSE)
  con$addTag("ItemName", "WQ Sample")
  con$addTag("ItemFormat", "S")
  con$addTag("Divisor", "1")
  con$addTag("Units")
  con$addTag("Format", "$$$")
  con$closeTag() # ItemInfo
  con$closeTag() # DataSource
  
  # for the TVP and associated measurement water quality parameters
  con$addTag("Data", attrs=c(DateFormat="mowsecs", NumItems="1"),close=FALSE)
  # for each tvp
  ## THIS NEEDS SOME WORK.....
  ## just pulling out SampleID, ProjectName and mowsecs
  sampleParams <- c("mowsecs", 
                    "Observer", 
                    "Project.ID", 
                    "Puddle.Comment", 
                    "Puddle.verified", 
                    "Puddle.verified.date", 
                    "Sample.Number", 
                    "Sample.Type", 
                    "Sub.location.ID", 
                    "Sampling.Issue",
                    "Puddle.verified.by") #, 
                    #"DiscreteSampleDepth", 
                    #"CompositeIntegratedSampleDepthTop", 
                    #"CompositeIntegratedSampleDepthBottom") # Last 3 fields will need to be checked.
  sample<-datatbl[sampleParams]
  sample<-sample[start:end,]
  sample<-distinct(sample,mowsecs, .keep_all = TRUE)
  sample<-sample[order(sample$mowsecs),]
  
  for(a in 1:nrow(sample)){ 
    con$addTag("E",close=FALSE)
    con$addTag("T",sample$mowsecs[a])
    con$addTag("I1", paste("Observer\t",sample$Observer[a],"\t",
                           "Project ID\t",sample$Project.ID[a],"\t",
                           "Puddle Comment\t",sample$Puddle.Comment[a],"\t",
                           "Puddle verified\t",sample$Puddle.verified[a],"\t",
                           "Puddle verified date\t",sample$Puddle.verified.date[a],"\t",
                           "Sample Number\t",sample$Sample.Number[a],"\t",
                           "Sample Type\t",sample$Sample.Type[a],"\t",
                           "Sub location ID\t",sample$Sub.location.ID[a],"\t",
                           "Sampling Issue\t", sample$Sampling.Issue[a], "\t",
                           "Puddle verified by\t",sample$Puddle.verified.by[a],"\t",
                           "Discrete Sample Depth\t", sample$DiscreteSampleDepth[a], "\t",
                           "Depth Top\t", sample$CompositeIntegratedSampleDepthTop[a], "\t",
                           "Depth Bottom\t", sample$CompositeIntegratedSampleDepthBottom[a], "\t",sep=""))
    con$closeTag() # E
  }
  
  con$closeTag() # Data
  con$closeTag() # Measurement    
  
}
cat("Saving: ",Sys.time()-tm,"\n")
saveXML(con$value(), file=paste("WriteHilltopXML-",Sys.Date(),".xml",sep=""))
cat("Finished",Sys.time()-tm,"\n")
