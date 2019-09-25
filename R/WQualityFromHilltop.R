#Jeff Cooke August 2016
#Modified for Water Quality Checker December 2016
#Modified Nov 2018
#Modified August 2019 due to Hilltop server now bringing WQ parameters through, so no need for extra loop.
# Goal is to build functions that import water quality data to a useable dataframe for plotting and analysis.  
# HBRC use Hilltop as their Time Series server and so the calls have been built for this server.
# This script has been developed as an example of using the Hilltop.R functions to import 
# Water Quality into R data frames.
#Feb 2018 Modification adds a line to ensure that the correct measurement name is entered.  This is to get around aHilltop Server Bug.

#/* -===Include required function libraries===- */ 

#Install the required packages
pkgs <- c('RCurl', 'dplyr', 'lubridate', 'stringr')
if(!all(pkgs %in% installed.packages()[, 'Package']))
  install.packages(pkgs, dep = T)

require(RCurl)
require(dplyr)
require(lubridate)
require(stringr)


#Hilltop.R will be required, need to store it somehwere that will be available for use, or obtain from Github.
#If Hilltop.R (or equivalent) is stored locally then source it directly
#source("Hilltop.R")


#To source direct from Github (requires internet access) (Slow)


script <- getURL("https://raw.githubusercontent.com/jeffcnz/Hilltop/master/Hilltop.R", ssl.verifypeer = FALSE) 

eval(parse(text = script)) 

#Set the default number of decimal places 
options(digits.secs = 3)
  


#set the working directory, where the csv of sites and measurements is (results will be saved here)
#Note the sites and measurements must be exactly as required by Hilltop
#measurement names are the "request as" names, you may need to use the measurement[Datasource] construct



#Bring in a site list and measurement list.
#For testing purposes examples are provided as vectors for the data frame, but csv files preferred.

#If vectors are used then set the variables to null initially
#WQSites<-NULL
#WQMeasurements<-NULL
WQSites <- read.csv("./Data/SiteListAll201904.csv", stringsAsFactors=FALSE) #Read sites in from csv

WQSites < -WQSites[complete.cases(WQSites$Site), ] #remove any missing lines



WQMeasurements <- read.csv("./Data/WQMeasurements.csv", stringsAsFactors=FALSE) #Read sites in from csv

WQMeasurements <- WQMeasurements[complete.cases(WQMeasurements$Measurements), ] #remove any missing lines

#Only request measurements that have a Maxcode > 200
WQMeasurements <- subset(WQMeasurements, MaxCode > 200)

#Set the time range for the requests, no end date so all data brought in
#The start date needs to include all coded data as this data is used in the coder to derive the statistics
startDate <- "1/1/2004"

endDate <- "01/07/2019"
#endDate <- ""

#set the url of the Hilltop service (using internal server initially as external not set up with raw results yet.)

tss_url <- "https://data.hbrc.govt.nz/EnviroData/EMARTest.hts?"

 
#HillSites<-hilltopSiteList(anyXmlParse(paste(tss_url, "Service=Hilltop&Request=SiteList&Location=LatLong", sep="")))

ls <- length(WQSites$Site) #set ls to the number of sites that data is being requested for.
lm <- length(WQMeasurements$Measurements) # set lm to the number of measurements that data is being requested for.

output <- data.frame(Site=character(), 
                   stringsAsFactors=FALSE) # create an empty dataframe to append the results to for eventual output

#Create a Windows progress bar
pb <- winProgressBar(title = "Progress", min = 0,max = ls, width = 300)

for (s in 1:ls) { # start the loop for sites
  
  #Update the progress bar
  setWinProgressBar(pb, s, title=paste( round(s/ls*100, 0),"% done"))
  
  #toutput<-NULL #create an empty dataframe for the temporary output (within the loop)
  toutput <- data.frame(Site=character(), 
                        stringsAsFactors=FALSE)
  site <- WQSites$Site[s] #select the site
  for (m in 1:lm) {  #start of the loop for measurement
    
    
    
    measurement <- WQMeasurements$Measurements[m] #select the measurement
    cleanMeasurement <- strsplit(measurement, '\\[')[[1]][1]#grab the text before the [
    cleanMeasurement <- trimws(cleanMeasurement) #Remove leading and trailing whitespace
    message(paste("Requesting", site, measurement))
    #build the request
    testrequest <- paste("service=Hilltop&request=GetData&Site=",site,"&Measurement=",measurement,"&From=",startDate,"&To=",endDate,sep="")
    
    #get the xml data from the server
    url <- paste(tss_url, testrequest, sep="")
    #clean the url
    #url <- str_replace_all(url, " " , "%20")
    url <- URLencode(url)
    
    dataxml <- anyXmlParse(url)
    #convert the xml into a dataframe of measurement results
    #with basic error handling
    wqdata <- tryCatch({
      hilltopMeasurement(dataxml)
      #hilltopMeasurementToDF(dataxml)
    }, error=function(err){message(paste("Error retrieving", site, measurement))}) 
    
    #add a line in here to check the measurement name against what was requested and if it doesn't match change it
    #This is a work around for a bug in version 1.72 of the server
    
    if(!is.null(wqdata)){if(wqdata$Measurement[1] != measurement) {wqdata$Measurement = cleanMeasurement}}
    
    toutput <- bind_rows(toutput,wqdata)#append the data to the dataframe called toutput (temporary dataframe)
    free(dataxml)
    
  }
  #get the WQ Sample parameters for the site NO LONGER REQUIRED Aug 2019
  #build the request
  #WQSampleRequest <- paste("service=Hilltop&request=GetData&Site=",site,"&Measurement=WQ Sample&From=",startDate,"&To=",endDate,sep="")
  #get the xml data from the server
  #message(paste("Requesting", site, "WQ Sample"))
  #url <- paste(tss_url, WQSampleRequest, sep="")
  #clean the url
  #url <- str_replace_all(url, " " , "%20")
  #wqdataxml <- anyXmlParse(url)
  
  ##convert the xml to a dataframe of WQ Sample results
  #with basic error handling added
  #wqSampleData <- tryCatch({
  #  hilltopMeasurementToDF(wqdataxml)
  #}, error=function(err){message(paste("Error retrieving", site, "WQ Sample Information"))})
  
  #merge the WQ Sample data with the measurement data with basic error handling.
  #toutput <- tryCatch({
  #  merge(toutput,wqSampleData,by="Time",all.x=TRUE)
  #}, error=function(err){message(paste("No WQ Sample information, leaving blank"))})
  
  #free(wqdataxml)
  output <- bind_rows(output,toutput) #append the data to the dataframe called output
}

#Close the progress bar
close(pb)

#Convert values to numbers and handle censured data
#TO DO: Put this in a function


censuredlt <- subset(output, substring(output$Value,1,1)=="<")
if (length(censuredlt$Value) > 0) {
  censuredlt$valueprefix<-"<"
  censuredlt$result<-as.numeric(substring(censuredlt$Value,2,nchar(censuredlt$Value)))
  #censured$trendresult<-censured$result/2
}

censuredgt <- subset(output, substring(output$Value,1,1)==">")
if (length(censuredgt$Value) > 0) {
  censuredgt$valueprefix<-">"
  censuredgt$result<-as.numeric(substring(censuredgt$Value,2,nchar(censuredgt$Value)))
  #censured$trendresult<-censured$result/2
}

nocensure <- subset(output, substring(output$Value,1,1)!="<" & substring(output$Value,1,1)!=">")
if (length(nocensure$Value) > 0) {
  nocensure$valueprefix<-"="
  nocensure$result <- as.numeric(nocensure$Value)
  #nocensure$trendresult<-nocensure$result
}
output <- rbind(censuredlt, censuredgt, nocensure)

#convert date fields to character format and add text so spreadsheets keep all of the data
output$Time <- paste0("DateTime_", as.character(output$Time))

output[["Entered to Puddle date"]]<- paste0("DateTime_", as.character(output[["Entered to Puddle date"]]))
output[["Updated date"]]<- paste0("DateTime_", as.character(output[["Updated date"]]))
output[["Puddle verified date"]]<- paste0("DateTime_", as.character(output[["Puddle verified date"]]))

#output <- merge(output,HillSites,by.x="Site", by.y="site",all.x=TRUE)
output <- merge(output,WQMeasurements,by.x="Measurement", by.y="AgencyMeasurement",all.x=TRUE)

#write results to csv
write.csv(output, paste("./Data/",format(Sys.Date(), "%Y%m%d"),"WQResults.csv", sep =""), row.names = FALSE)

