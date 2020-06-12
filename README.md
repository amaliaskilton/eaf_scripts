# eaf_scripts
# Extending the functions of ELAN
ELAN is a media annotation application produced by MPI for Psycholinguistics (https://archive.mpi.nl/tla/elan). It's widely used for annotating audio and video in language documentation.

This is a repository of scripts I've created to add functions that aren't present in the current version of ELAN (5.9).

The content is NOT endorsed or written by the creators of ELAN.

## Multiple Find and Replace (Orthography Conversion)

ELAN has a find and replace function that works with regular expressions. But you need to carry out every find and replace individually, making it hard to use the function to transliterate between orthographies with very different character sets. For example, I transcribe Ticuna using an ASCII-based orthography which requires 37 substitutions to produce IPA.

This repository contains group of R scripts which carry out find and replace inside ELAN files based on an external CSV file with find-replace pairs. All of the scripts support comments: you can exclude text that is inside certain delimiters from the find-and-replace. They also support multiple orthographies: you can change text on one tier according to the equivalences in one CSV file, and text on another tier according to equivalences in another CSV.

EAF_ChangeOrthography_ByTierName_File.R

User selects a set of tiers (they can be of any type) in a single ELAN file. Script finds and replaces characters  in the tiers according to equivalences in an external CSV. All tiers must use the same CSV.

EAF_ChangeOrthography_ByTierType_File.R

User selects up to two tier types in a single ELAN file. Script finds and replaces characters in all tiers of each type according to equivalences in an external CSV. Types can use different CSVs.

EAF_ChangeOrthography_ByTierType_Directory.zip

Version of the above script for batch processing. Includes a batch-friendly version of the ChangeOrthography_ByTierType script plus a bash script for running it over a directory.

orthographykey.csv

Sample CSV file for orthography replacement scripts. This shows the required format for the CSV file used to define replacements in the above scripts.

## Copying to Parent Tiers

ELAN has limited functionality for copying annotation values onto a parent (time-aligned) tier. If you copy onto a parent tier with annotations on its child (dependent) tiers, all of the annotations on the child tier are removed.

I wrote a group of R scripts which allow you to copy onto parent tiers without affecting their child annotations.

### Copying a parent tier to another parent tier

EAF_CopyParentToParent_File.R

User selects two parent tiers in a single ELAN file. Script finds all annotations on the source tier which have the same timepoints as annotations on the target tier. Then it copies the source annotation values to the target tier.

To use this script, you must already have blank annotations on your target tier with exactly the same timepoints as the annotations on the source tier.

EAF_CopyParentToParent_Directory.zip

Version of the above script for batch processing. Includes a batch-friendly version of the CopyParentToParent_File script plus a bash script for running it over a directory.

### Copying a child tier to a parent tier

EAF_CopyChildToParent_ByTier.R

User selects a parent tier and a child tier in a single ELAN file. Script copies all annotations on the child tier onto the parent tier. Child tier must have the stereotype 'Symbolic Association.'

EAF_CopyChildToParent_ByType.R

User selects a parent tier type and a child tier type in a single ELAN file. In each parent-child pair of tiers, script copies all annotations from the child tier onto the parent tier. Child tier type must have the stereotype 'Symbolic Association.' All child tiers must be dependent on parent tiers of the selected parent type.

EAF_CopyChildToParent_ByType_Directory.zip

Version of the above script for batch processing. Includes a batch-friendly version of the EAF_CopyChildToParent_ByType script plus a bash script for running it over a directory.
