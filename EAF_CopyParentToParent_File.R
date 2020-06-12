#EAF_CopyParentToParent
#Amalia Skilton 2020-06-11
#This script allows you to copy annotation values from one time-aligned (root) tier to another time-aligned tier in an ELAN (EAF) file, without affecting annotations on the target tier's child tiers.
#The target tier and source tier must already have annotations with exactly the same timepoints.
#For every pair of identical-timepoints annotations on the source and target tiers,
#All annotation values on the target tier will be overwritten by the values from the source tier.

### REQUIRED USER INPUT ###

#State the path to the file
input_file <- "./eaf2.eaf"

#State the name of the tier with blank annotations (target for copy)
target_tier_name <- "A_phrase-segnum-en"

#State the name of the tier with contentful annotations (source for copy)
source_tier_name <- "A_Transcription-txt-yaa"

#State the name of the output file if you want anything other than input + "_edited"
output_file <- gsub("\\.eaf","_edited\\.eaf",input_file)

### SCRIPT BODY ###

##You must have the following packages for the script to work
packages = c("xml2","tidyverse","magrittr")

##Install packages if not present. When present, load
package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  }
)

#Load the eaf.
eaf = read_xml(input_file)

#Load the time_slot nodes.
time_slots = xml_find_all(eaf, ".//TIME_SLOT")

#Turn these into a data frame.
time_slots_df <- as.data.frame(cbind(TIME_SLOT_ID=as.vector(xml_attr(time_slots, "TIME_SLOT_ID")),
                                  TIME_VALUE=as.vector(xml_attr(time_slots, "TIME_VALUE"))))
time_slots_df$TIME_SLOT_ID <- as.character(time_slots_df$TIME_SLOT_ID) 
time_slots_df$TIME_VALUE <- as.numeric(as.character(time_slots_df$TIME_VALUE))

#Go back to the eaf.

#Find all the annotations on the phrase-segnum tier.
#Get their start and end times and text.

#Start by finding all annotations on the phrase-segnum tier and their text.
target_tier_path <- paste(".//TIER[@TIER_ID='",
                          target_tier_name,
                          "']//ANNOTATION//ALIGNABLE_ANNOTATION",
                          sep="")
target_tier = xml_find_all(eaf,target_tier_path) 
target_tier_aids = as.vector(xml_attr(target_tier, "ANNOTATION_ID"))
target_tier_starttimes = as.vector(xml_attr(target_tier, "TIME_SLOT_REF1"))
target_tier_endtimes = as.vector(xml_attr(target_tier, "TIME_SLOT_REF2"))
target_tier_value_path <- paste(".//TIER[@TIER_ID='",
                                target_tier_name,
                                "']//ANNOTATION//ALIGNABLE_ANNOTATION//ANNOTATION_VALUE",
                                sep="")
target_tier_values = xml_text(xml_find_all(eaf, target_tier_value_path))

target_tier_table <- data.frame(cbind(target_tier_aids,target_tier_starttimes,target_tier_endtimes,target_tier_values))
target_tier_table <- target_tier_table %>%
  rename(TIME_SLOT_REF_1=target_tier_starttimes,TIME_SLOT_REF_2=target_tier_endtimes) %>%
  pivot_longer(cols=starts_with("TIME_SLOT"),names_to="TimeType",values_to="TIME_SLOT_ID")
  
#Now find all the annotations on the transcription-txt tier and their text.
source_tier_path <- paste(".//TIER[@TIER_ID='",
                          source_tier_name,
                          "']//ANNOTATION//ALIGNABLE_ANNOTATION",
                          sep="")
source_tier = xml_find_all(eaf,source_tier_path) 
source_tier_aids = as.vector(xml_attr(source_tier, "ANNOTATION_ID"))
source_tier_starttimes = as.vector(xml_attr(source_tier, "TIME_SLOT_REF1"))
source_tier_endtimes = as.vector(xml_attr(source_tier, "TIME_SLOT_REF2"))
source_tier_value_path <- paste(".//TIER[@TIER_ID='",
                                source_tier_name,
                                "']//ANNOTATION//ALIGNABLE_ANNOTATION//ANNOTATION_VALUE",
                                sep="")
source_tier_values = xml_text(xml_find_all(eaf, source_tier_value_path))

source_tier_table <- data.frame(cbind(source_tier_aids,source_tier_starttimes,source_tier_endtimes,source_tier_values))
source_tier_table <- source_tier_table %>%
  rename(TIME_SLOT_REF_1=source_tier_starttimes,TIME_SLOT_REF_2=source_tier_endtimes) %>%
  pivot_longer(cols=starts_with("TIME_SLOT"),names_to="TimeType",values_to="TIME_SLOT_ID")

#Add the actual time values to each table. Then join.
target_tier_table <- left_join(target_tier_table,time_slots_df, by = "TIME_SLOT_ID") %>%
  pivot_wider(names_from="TimeType",values_from=c("TIME_SLOT_ID","TIME_VALUE"))
source_tier_table <- left_join(source_tier_table,time_slots_df, by = "TIME_SLOT_ID") %>%
  pivot_wider(names_from="TimeType",values_from=c("TIME_SLOT_ID","TIME_VALUE"))
combined_table <- left_join(target_tier_table,source_tier_table, by = c("TIME_VALUE_TIME_SLOT_REF_1","TIME_VALUE_TIME_SLOT_REF_2"))

#Now copy the source_tier_values column of the table into the text of the target_tier ANNOTATION_VALUE tags, using the equivalences defined by the table.

#Make the combined table friendlier to this
combined_table_replace <- combined_table %>% 
  select(target_tier_aids,source_tier_values) %>%
  mutate(source_tier_values=as.character(source_tier_values)) %>%
  column_to_rownames(var = "target_tier_aids")

replace_xml_text <- function(aid) {
  path <- paste(".//TIER[@TIER_ID='",target_tier_name,"']//ANNOTATION//ALIGNABLE_ANNOTATION[@ANNOTATION_ID='",aid,"']",sep="")
  text <- combined_table_replace[aid,1]
  node <- xml_find_all(eaf, path)
  xml_text(node) <- text
}

for (i in combined_table$target_tier_aids) replace_xml_text(i)

#Change self-closing annotation value tags (caused by read_xml) to explicit
eaf <- gsub("(?<!      )</ALIGNABLE_ANNOTATION>","</ANNOTATION_VALUE>\n      </ALIGNABLE_ANNOTATION>",eaf,perl = TRUE)
eaf <- gsub("><ANNOTATION_VALUE/>","> \n      <ANNOTATION_VALUE>",eaf)

writeLines(eaf,output_file)
