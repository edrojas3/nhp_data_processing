# genearte BN tsv
library(tidyr)
library(purrr)
library(dplyr)
library(stringr)

`%notin%` <- Negate(`%in%`)
bn_areas <- read.table("BNA_subregions.tsv",sep = "\t", header = T)


str(bn_areas)

# trim White Spaces
char_cols <- c(1,2,3,6,8,9)
cols_trimmed <- map_dfc(char_cols,~str_trim(string = bn_areas[[.x]],side = "both") 
                        %>% str_to_title) %>%
  set_names(names(bn_areas)[char_cols])
bn_areas[,char_cols] <- cols_trimmed


### Fix the lobe column
Lobe_index <- which(bn_areas$Lobe != "")
Lobe_names <- bn_areas$Lobe[Lobe_index]
inf_Lobe_limit <- c(Lobe_index[-1] -1, nrow(bn_areas))
Lobe_times <- diff(c(0,inf_Lobe_limit))
bn_areas$Lobe <- map(1:7, ~rep(Lobe_names[.x],Lobe_times[.x])) %>%
  unlist() 

## arrange Girus Column 

gyrus_index <- which(bn_areas$Gyrus != "")
gyrus_names <- bn_areas$Gyrus[gyrus_index]
inf_gyrus_limit <- c(gyrus_index[-1] -1, nrow(bn_areas))
gyrus_times <- diff(c(0,inf_gyrus_limit))
bn_areas$Gyrus<- map(1:24, ~rep(gyrus_names[.x],gyrus_times[.x])) %>%
  unlist() 

## arrange problematic strings
bn_areas$X[34] <- "A4ll;Area4,(Lower Limb Region)"
bn_areas$X[37] <- "Te1.0/Te1.2,Te1.0 And Te1.2"
bn_areas$X[57] <- "Tl, Area Tl (Lateral Pphc; Posterior Parahippocampal Gyrus)"
bn_areas$X[58] <-  "A28/34, Area 28/34 (Ec;Entorhinal Cortex)"
bn_areas$X[78] <- "A1/2/3ulhf,Area 1/2/3(Upper Limb; Head And Face Region)"

# split the X column. 
bn_areas2 <- separate(bn_areas,`X`, into = c("Abbreviation","Area"),sep = ",") %>%
separate(.,Gyrus,into = c("Gy.Abrevv","Gyrus"),sep = ",")
bn_areas2$Gy.Abrevv <- toupper(bn_areas2$Gy.Abrevv)
check_later <- c(34,37,57,58,78)
### we will now generate a diferent dataset for right and left hemispheres

#arrange problematic rows




# Left hemisfere

bn_areas_Left <- bn_areas2 %>%
                 select(-c(6, 9,11))


bn_areas_Left$Abbreviation <- paste("L.",bn_areas_Left$Abbreviation,sep = "")
bn_areas_Left$Area <- paste("Left",bn_areas_Left$Area,sep = "")
names(bn_areas_Left)[c(5,8)] <- c("Label.ID","MNI.X.Y.Z")



bn_areas_Right <- bn_areas2 %>%
  select(-c(5, 9,10))

bn_areas_Right$Abbreviation <- paste("R.",bn_areas_Right$Abbreviation,sep = "")
bn_areas_Right$Area <- paste("Right",bn_areas_Right$Area,sep = "")
names(bn_areas_Right) <- names(bn_areas_Left)

bn_areas3 <- bind_rows(bn_areas_Left,bn_areas_Right) %>%
arrange(Label.ID)

### Create Targets Filce
Targets <- bn_areas3 %>% 
filter(Gy.Abrevv %in% c("ORG", "BG"))
Targets$Index <- 1:nrow(Targets)
Targets_coords <- select(Targets,MNI.X.Y.Z)
write.table(Targets_coords,file = "BNA_Targets_MNI.csv",sep = ",",
            quote = F,row.names = F,col.names = F)
targets_voox <- read.table("BNA_Targets_vox.csv",sep = ' ')
Targets <- Targets %>%
  select(Index, Area, Abbreviation) %>%
  mutate(Voxels = targets_voox$V1, Coordinates = Targets$MNI.X.Y.Z)



### Seeds File

Seeds <- bn_areas3 %>% 
  filter(Gy.Abrevv %notin% c("ORG", "BG"))
seeds_coords <- Seeds %>%
  select(MNI.X.Y.Z)
Seeds$Index <- 1:nrow(Seeds)
write.table(seeds_coords,"BNA_seeds_MNI.csv",quote = F,col.names = F,row.names = F,sep = ,)
seeds_vox <- read.table("BNA_seeds_vox.csv")

Seeds <- Seeds %>%
  select(Index,Area,Abbreviation) %>%
  mutate(Voxels = seeds_vox$V1, Coordinates = Seeds$MNI.X.Y.Z)

# Write table
write.table(Targets,"BNA_Targets.tsv",quote = F,row.names = F,sep = "\t")
write.table(Seeds,"BNA_Seeds.tsv",quote = F,row.names = F,sep = "\t")

save(list = c("bn_areas3"),file = "bn_areas3.Rdata")





