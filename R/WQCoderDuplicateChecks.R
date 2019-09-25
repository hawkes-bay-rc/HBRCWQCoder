library(tidyverse)
# Check for duplication issues between archive, newly coded results and puddle before loading newly coded results to Archive

# Read in newly coded data (non Archive data)
newCoded <- read.csv("data/20190903WQCodedResultsTestV3.csv", stringsAsFactors = FALSE)

# Read in Archive Data
archiveData <- read.csv("data/20190903ArchiveData.csv", stringsAsFactors = FALSE)

# Look for duplicate LabID, SubID, Measurement Combinations
fieldList <- c("Measurement", "QualityCode", "Sample.Number", "Sub.location.ID")

newCodedSubset <- subset(newCoded, select = fieldList)
archiveDataSubset <- subset(archiveData, select = fieldList)

# Identify where the duplicates have come from

newCodedDuplicates <- newCodedSubset[duplicated(newCodedSubset[fieldList]),]

archiveDataDuplicates <- archiveDataSubset[duplicated(archiveDataSubset[fieldList]),]

newArchiveDuplicates <- inner_join(archiveDataSubset, newCodedSubset)

# Drop the quality code column from the Duplicate dataframes (so can be used for a filter)

newCodeDupFilter <- subset(newCodedDuplicates, select = -c(QualityCode))
newArchiveDupFilter <- subset(newArchiveDuplicates, select = -c(QualityCode))
# Identify Clean data that can go to the archive.

# Merge the filter datasets
dupFilter <- unique(rbind(newCodeDupFilter, newArchiveDupFilter))

#Remove data that may be duplicated
cleanNewCoded <- anti_join(newCoded, dupFilter)

# Create data frames of duplicates
rawRawDuplicatesFull <- inner_join(newCoded, newCodeDupFilter)
rawArchiveDuplicatesRaw <- inner_join(newCoded, newArchiveDupFilter)
rawArchiveDuplicatesArchive <- inner_join(archiveData, newArchiveDupFilter)

# Output csv's

write.csv(cleanNewCoded, paste("Data/", format(Sys.Date(), "%Y%m%d"),"WQCodedResultsClean.csv", sep =""), row.names = FALSE)
write.csv(rawRawDuplicatesFull, paste("Data/", format(Sys.Date(), "%Y%m%d"),"RawRawDuplicates.csv", sep =""), row.names = FALSE)
write.csv(rawArchiveDuplicatesRaw, paste("Data/", format(Sys.Date(), "%Y%m%d"),"Raw_RawArchiveDuplicates.csv", sep =""), row.names = FALSE)
write.csv(rawArchiveDuplicatesArchive, paste("Data/", format(Sys.Date(), "%Y%m%d"),"Archive_RawArchiveDuplicates.csv", sep =""), row.names = FALSE)


