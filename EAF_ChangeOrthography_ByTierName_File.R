#EAF_ChangeOrthography_OneTier
#Amalia Skilton 2020-06-11
#This script makes user-directed changes in the orthography used in A USER-DEFINED SET OF TIERS in an EAF file.

### REQUIRED USER INPUTS ###

#State the path to the input file
input_file <- "/Users/amaliaskilton/Desktop/EAF_Scripts/EAF_ChangeOrthography/test_eafs/tca_20180613_abs-nwg_visit.eaf"

#List the names of the tiers to change as a vector of form c("a","b","c")
target_tier_names <- c("NWG-tca","ABS-tca")
#List the stereotypes of the tiers to change - "ALIGNABLE" (time-aligned) or "REF" (symbolic association)
target_tier_stereotypes <- c("ALIGNABLE","ALIGNABLE")

#State the path to a csv file with a key to the practical orthography for your tiers.
key_file1 <- "/Users/amaliaskilton/Desktop/EAF_Scripts/EAF_ChangeOrthography/orthographykey.csv"

### OPTIONAL USER INPUTS ###

## OUTPUT LOCATION ##

#By default the output is in the same directory as the input.
#Filename is the input file + "_edited".
#Replace this line with a different file path here if you want to change this behavior.
output_file <- gsub("\\.eaf","_edited.eaf",input_file)

## COMMENTS ## 

#Do your tiers contain comments, like nonvisual behaviors in double parentheses ((nods)) or markers such as [unintell] in single brackets?
#If so, define your comment delimiters here.

#Delimiters that are also metacharacters in R need to be escaped with \\.
#If you use the same character as an opening and closing delimiter (e.g. $comment$), you need to add it once in each list.
#All delimiters must be balanced.

#If you don't use comments, comment these lines out.

comment_openers <- c("\\[","\\(\\(")
comment_closers <- c("\\]","\\)\\)")

## MULTIPLE ORTHOGRAPHIES ##

#Does your target tier contain multiple orthographies?
#If not, comment all of the following text out.

#The orthography you defined above is the orthography for "type 1 content".
#If you have another kind of content *on the same tier*, such as Spanish words in non-Spanish text, you can define a separate orthography for it, provided that it is delimited.
#Content in your second orthography is "type 2 content".

#State the path to a csv file with a key to the orthography for type 2 content
key_file2 <- "/Users/amaliaskilton/Desktop/EAF_Scripts/EAF_ChangeOrthography/orthographykey_sp.csv"

#State the delimiters for type2 content on the target tier
type2_openers <- c("\\[Sp\\]","\\[Port\\]","\\[BP\\]")

#State any delimiters for type1 content on the target tier - these will be taken as *closing* type 2 content
type1_openers <- c("\\[Tca\\]")

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

#Define the main orthography mapping.
key1 <- read.csv(key_file1, header=TRUE, stringsAsFactors = FALSE)

#Define the orthography substitution function.
keysub <- function(text,key){
  for (i in 1:nrow(key)) 
    text <- gsub(key[i,1],key[i,2],text, perl = TRUE)
  return(text)}

#Are we using comments?
if (exists("comment_openers") & exists("comment_closers")){
  #Define the comment delimiters.
  comment_openers <- data.frame(delimiter=comment_openers,tag_number=seq(1:length(comment_openers))) %>%
    mutate(tag=paste(delimiter,"<start_cmt",tag_number,">",sep=""))
  comment_closers <- data.frame(delimiter=comment_closers,tag_number=seq(1:length(comment_closers))) %>%
    mutate(tag=paste("<end_cmt",tag_number,">",delimiter,sep="")) 
  comment_delimiters <- rbind(comment_openers,comment_closers) %>%
    mutate(delimiter=as.character(delimiter),tag=as.character(tag)) %>%
    mutate(tag_no_delimiter=regmatches(tag,regexpr("<.*>",tag))) %>%
    mutate(human_delimiter=gsub("\\\\","",delimiter))
  
  #Define the comment-marking function.
  mark_comments <- function(text){
    for (i in 1:nrow(comment_delimiters))
      text <- gsub(comment_delimiters[i,1],comment_delimiters[i,3],text) %>%
        str_split(pattern = comment_delimiters[i,1]) %>%
        unlist() 
    return(text)}
  
  #Define the comment-tag removal function.
  unmark_comments <- function(text){
    for (i in 1:nrow(comment_delimiters))
      text <- gsub(comment_delimiters[i,4],comment_delimiters[i,5],text)
    return(text)}
}

#Are we using a second orthography?
if (exists("key_file2") & exists("type2_openers")){
  #Define the type 2-marking function
  type2_openers <- data.frame(delimiter=type2_openers,tag_number=seq(1:length(type2_openers))) %>%
    mutate(tag=paste(delimiter,"<start_type2_lg",tag_number,">",sep="")) %>%
    select(-tag_number)
  type1_openers <- data.frame(delimiter=type1_openers) %>%
    mutate(tag=paste(delimiter,"<start_type1_lg>",sep=""))
  type2_delimiters <- rbind(type2_openers,type1_openers) %>%
    mutate(delimiter=as.character(delimiter),tag=as.character(tag)) %>%
    mutate(tag_no_delimiter=regmatches(tag,regexpr("<.*>",tag))) %>%
    mutate(human_delimiter=gsub("\\\\","",delimiter))
  
  #Define the type2-marking function.
  mark_type2 <- function(text){
    for (i in 1:nrow(type2_delimiters))
      text <- gsub(type2_delimiters[i,1],type2_delimiters[i,2],text) %>%
        str_split(pattern = type2_delimiters[i,1]) %>%
        unlist() 
    return(text)}
  
  #Define the type2-tag removal function.
  unmark_type2 <- function(text){
    for (i in 1:nrow(type2_delimiters))
      text <- gsub(type2_delimiters[i,3],type2_delimiters[i,4],text)
    return(text)}
  key2 <- read.csv(key_file2, header=TRUE, stringsAsFactors = FALSE)
}

#Define the master substitution function for type 1 (which can have some type 2 on it).
keysub_master <- function(text){
  #If we are using multiple mappings, identify the type 2 content
  if (exists("key_file2") & exists("type2_openers")){
    text <- mark_type2(text)}
  #If we are using comments, identify them
  if (exists("comment_openers") & exists("comment_closers")){
    text <- mark_comments(text)}
  newtext <- data.frame(newtext=text) %>%
    #Filter out blank strings
    filter(!newtext=="") %>%
    #Identify comment strings
    mutate(IsComment=str_detect(newtext,"<start_cmt")) %>%
    #Identify type 2 strings
    mutate(IsType2=str_detect(newtext,"<start_type2")) %>%
    #Replace type1 text per key1
    mutate(newtext=ifelse(!IsComment & !IsType2,keysub(newtext,key1),paste(newtext)))
  #If we are using multiple mappings, replace type 2 text per key 2
  if (exists("key_file2") & exists("type2_openers")){
    newtext <- newtext %>%
      mutate(newtext=ifelse(!IsComment & IsType2,keysub(newtext,key2),paste(newtext))) %>%
    #Then replace gsub-readable type2 tags with human-readable ones
      mutate(newtext=unmark_type2(newtext))
  }
  #If we are using comments, replace comment tags with human-readable ones
  if (exists("comment_openers") & exists("comment_closers")){
    newtext <- newtext %>%
    mutate(newtext=unmark_comments(newtext))
  }
  newtext <- paste(newtext$newtext, sep = " ", collapse = " ")
  newtext <- gsub("  "," ",newtext)
  return(newtext)
}

#Code for tier replacement
tierpaths <- paste(".//TIER[@TIER_ID='",target_tier_names,"']//ANNOTATION//",target_tier_stereotypes,"_ANNOTATION",sep="")
replace_tier <- function(tierpath){
  tiernode = xml_find_all(eaf,tierpath)
  for (i in 1:length(tiernode)) (
    xml_text(tiernode[[i]]) <- keysub_master(xml_text(tiernode[[i]]))
  )
}
for (i in 1:length(tierpaths)) (
  replace_tier(tierpaths[i])
)

write_xml(eaf,output_file)
