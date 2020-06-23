#EAF_iqu-txt-to-phrasesegnum
#Amalia Skilton 2020-06-18
#This script works on an EAF imported from a FLExText file.
#It assumes that the EAF contains
#1. a root tier with blank phrase-level annotations called A_phrase-segnum-en, 
#2. a tier of the stereotype with punctuation called "A_word-txt-es", child of the root tier, and
#3. a tier of the stereotype with words called ""A_word-txt-iqu", child of the punctuation tier.
#(Tier names can be changed below).
#It concatenates the words and punctuation together from the punctuation and word tiers,
#Then pastes them onto the corresponding annotations on the parent tier.

### REQUIRED USER INPUT ###

#State the path to the file
input_file <- "./current_input_file"

#State the name of the tier with blank annotations (target for copy)
target_tier_name <- "A_phrase-segnum-en"

#State the name of the tier with punctuation for contentful annotations (source for copy)
source_tier_name_punct <- "A_word-txt-es"

#State the name of the tier with words for contentful annotations (source for copy)
source_tier_name_words <- "A_word-txt-iqu"

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
#Load the annotations on the parent tier.
parent_path = paste(".//TIER[@TIER_ID='",target_tier_name,"']//ANNOTATION//ALIGNABLE_ANNOTATION",sep="")
parent_annotations = xml_find_all(eaf,parent_path)
parent_aids = xml_attr(parent_annotations,"ANNOTATION_ID")

#Load the annotations on the punctuation child tier + their AIDs.
child_path_punct = paste(".//TIER[@TIER_ID='",source_tier_name_punct,"']//ANNOTATION//REF_ANNOTATION",sep="")
child_annotations_punct = xml_find_all(eaf,child_path_punct)
child_table_punct = data.frame(child_text_punct = xml_text(child_annotations_punct),
                               parent_ref = xml_attr(child_annotations_punct,"ANNOTATION_REF"),
                                    aid = xml_attr(child_annotations_punct,"ANNOTATION_ID"),
                                    stringsAsFactors = FALSE)

#Load the annotations on the words child tier.
child_path_words = paste(".//TIER[@TIER_ID='",source_tier_name_words,"']//ANNOTATION//REF_ANNOTATION",sep="")
child_annotations_words = xml_find_all(eaf,child_path_words)
child_table_words = data.frame(child_text_words = xml_text(child_annotations_words),
                                    aid = xml_attr(child_annotations_words,"ANNOTATION_REF"),
                                    stringsAsFactors = FALSE)                  

#Combine the punctuation and the words.
child_table <- left_join(child_table_punct,child_table_words,by="aid") %>%
  mutate(child_text_words=ifelse(!is.na(child_text_words),child_text_words,child_text_punct)) %>%
  group_by(parent_ref) %>%
  summarize(concatenated_text=paste(child_text_words,sep = " ", collapse = " ")) %>%
  #Remove extra space after opening punctuation, defined as ( [ { and "
  mutate(concatenated_text=gsub("(?<=[“\\(\\[\\{])\\s","",concatenated_text, perl = TRUE)) %>%
  #Remove extra space before closing punctuation, defined as all other punctuation marks
  mutate(concatenated_text=gsub("\\s(?=[[:punct:]])","",concatenated_text, perl = TRUE))
  
#Column to rownames
child_table <- column_to_rownames(child_table, var = "parent_ref")

#Move text
replace_by_aid <- function(parent_aid){
  aid_path = paste(parent_path,"[@ANNOTATION_ID='",parent_aid,"']",sep="")
  aid_node = xml_find_all(eaf,aid_path)
  xml_text(aid_node) <- child_table[parent_aid,1]
}

for (i in 1:length(parent_aids)) (
  replace_by_aid(parent_aids[i])
)

write_xml(eaf,output_file)
