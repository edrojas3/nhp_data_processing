#!/bin/Rscript
library(tidyverse)
load("bn_areas3.Rdata")

label_ids <- c(223,224,219,220,227,228,221,
               222,225,226,13,14,47,48,
               49,50,187,188,167,168,215,216,211,212)

which(bn_areas3$Label.ID %in% label_ids)


bn_areas4 <- bn_areas3 %>%
  filter(Label.ID %in% c(223,224,219,220,227,228,221,
                         222,225,226,13,14,47,48,
                         49,50,187,188,167,168,215,216,211,212))
indexes <- c()
indexes <- bn_areas4$Area %>%
  str_detect("Accumbens") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("Caudate") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("Globus") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("Putamen") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("10") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("11") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("13") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("32") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("Insula") %>%
 which() %>%
  append(indexes)

indexes <- bn_areas4$Area %>%
  str_detect("Hippocampus") %>%
 which() %>%
  append(indexes)


indexes <- bn_areas4$Area %>%
  str_detect("Amygdala") %>%
 which() %>%
  append(indexes)


indexes <- rev(indexes)

write.table(bn_areas4$MNI.X.Y.Z[indexes],file = "Frey_rois_mni.csv",
          col.names = F,row.names = F,quote = F,sep = ',')

voxels <- read.table("Frey_rois_vox.csv",sep = "\t")


bn_areas_final <- bn_areas4[indexes,] %>%
  mutate(Index = 1:24, Coordinates = MNI.X.Y.Z, Voxels = voxels$V1) %>%
  select(Index,Area, Abbreviation,Voxels, Coordinates)

write.table(bn_areas_final,"nhp-chmx_targets.tsv",sep = "\t",quote = F,row.names = F)

  



