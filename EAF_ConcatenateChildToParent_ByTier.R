#EAF_ConcatenateChildToParent_ByTier
#Amalia Skilton 2020-06-17
#This script works on an EAF.
#It allows you to concatenate annotation values from *ONE* child/referring tier (with stereotype Symbolic Subdivision) to the tier's parent/root tier.
#All annotation values on the parent/root tier will be overwritten by the values from the source tier.

### REQUIRED USER INPUT ###

#State the path to the file (include the .eaf extension)
input_file <- "./current_input_file"

#State the name of the tier with blank annotations (target for copy)
target_tier_name <- "A_phrase-segnum-en"

#State the name of the tier with contentful annotations (source for copy)
source_tier_name <- "A_word-txt-yaa"

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

#Load the annotations on the parent tier.
parent_path = paste(".//TIER[@TIER_ID='",target_tier_name,"']//ANNOTATION//ALIGNABLE_ANNOTATION",sep="")
parent_annotations = xml_find_all(eaf,parent_path)

#Load the annotations on the child tier.
child_path = paste(".//TIER[@TIER_ID='",source_tier_name,"']//ANNOTATION//REF_ANNOTATION",sep="")
child_annotations = xml_find_all(eaf,child_path)
child_table <- data.frame(
    child_refs = xml_attr(child_annotations,"ANNOTATION_REF"),
    child_text = xml_text(child_annotations),
    stringsAsFactors = FALSE
  ) 

#For each annotation on the parent tier,
#Concatenate all annotations on the child tier.
child_table <- child_table %>%
  group_by(child_refs) %>%
  summarize(concatenated_text=paste(child_text,sep = " ", collapse = " "))

#Replace parent with child
xml_text(parent_annotations) <- child_table$concatenated_text

#Change self-closing annotation value tags (caused by read_xml) to explicit
eaf <- gsub("(?<!      )</ALIGNABLE_ANNOTATION>","</ANNOTATION_VALUE>\n      </ALIGNABLE_ANNOTATION>",eaf,perl = TRUE)
eaf <- gsub("><ANNOTATION_VALUE/>","> \n      <ANNOTATION_VALUE>",eaf)

writeLines(eaf,output_file)
