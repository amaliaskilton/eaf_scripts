#EAF_CopyChildToParent_ByTier
#Amalia Skilton 2020-06-11
#This script works on an EAF.
#It allows you to copy annotation values from *ONE* referring tier (with stereotype symbolic association) to its parent tier.
#All annotation values on the target tier will be overwritten by the values from the source tier.

### REQUIRED USER INPUT ###

#State the path to the file
input_file <- "/Users/amaliaskilton/Desktop/EAF_Scripts/EAF_CopyChildToParent/single_file_version/tca_201907_child_child1-child2_cci_video_ahs.eaf"

#State the name of the tier with blank annotations (target for copy)
target_tier_name <- "Child1-parenttier"

#State the name of the tier with contentful annotations (source for copy)
source_tier_name <- "Child1-tca"

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
child_text = xml_text(child_annotations)

#Replace parent with child
xml_text(parent_annotations) <- child_text

#Change self-closing annotation value tags (caused by read_xml) to explicit
eaf <- gsub("(?<!      )</ALIGNABLE_ANNOTATION>","</ANNOTATION_VALUE>\n      </ALIGNABLE_ANNOTATION>",eaf,perl = TRUE)
eaf <- gsub("><ANNOTATION_VALUE/>","> \n      <ANNOTATION_VALUE>",eaf)

writeLines(eaf,output_file)
