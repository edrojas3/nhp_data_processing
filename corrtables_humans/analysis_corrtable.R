#!/usr/bin/Rscript

###################################################
# PREPARE ALL THE FILES AND SET-UP THE ENVIRONMENT#
####################################################
###################################################

# Load packages
library(tidyverse)
library(corrr)


# first we will load the targets and seeds files into R

targets <- read.table("../files/human_rois/BNA/nhp-chmx_targets.tsv",head = T, sep = "\t")
seeds <- read.table("../files/human_rois/BNA/Frey_seeds_in_MNI.tsv",head = T, sep = "\t")

## correct some typos in the targets file: 
targets$Abbreviation[targets$Abbreviation=="R.Rhipp"] <-  "R.Hipp"
targets$Abbreviation[targets$Abbreviation=="L.Rhipp"] <-  "L.Hipp"


# read a list to select only complete corrtable.tsv  files (subject files with 529 rows)

  complete_files <- read.table("files_lines.txt",sep=",",header = F) %>%
  filter(V2 == 529) %>%
  select(1) %>%
  unlist() %>%
  unname()

# create a vector of those sujects ids of complete files
sujetos <- str_remove(complete_files, pattern = "_corrtable.tsv")


# read all files and append a column with the subject id. all will be stored into a Data.frame

all_corrtables <- map_df(1:41, ~read.table(complete_files[.x],sep = "\t", header = TRUE) %>%
         mutate(subject_id = sujetos[.x])) #%>%
 

# Fix some typos in the target name column

all_corrtables$target[all_corrtables$target == "R.Rhipp"] <- "R.Hipp"
all_corrtables$target[all_corrtables$target == "L.Rhipp"] <- "L.Hipp"

# create a column to idenfity hemisfere of target. 
all_corrtables <- separate(all_corrtables,target, 
                into =  c("Target_side", "Target_region"),
                sep = "\\.")

###################################################################
# From now on we will work on the visualization and analysis of FC. 


#First we will plot the mean correlation matrix of all targets

# read all correlation matrix and transform into a 24x24x47(subjects) array

target_corrs <- read.table("target_corrs/target_corrs_all_subs.tsv",header = F,sep = "\t") %>%
                as.matrix() %>%
                t() %>%
                array(dim = c(24,24,47))
# store the target labels into a variable

target_names <- targets$Abbreviation

#compute the mean functional connectivy matrix

target_corr_mean <- target_corrs %>%
                   matrix(ncol = 47) %>%
                  rowMeans() %>%
               matrix(ncol = 24, nrow = 24, dimnames = list(target_names,target_names))


# load color pallettes 

library(wesanderson)
pal <- wes_palette("Zissou1", 100, type = "continuous")


# get the inferior linear triangle of the matrix

inf_tri <- target_corr_mean[lower.tri(target_corr_mean,diag = T)]

## generate a vector of connections 

node1 <- c()
node2 <- c()

# set a counter 
counter <- 24

for (i in 1:24){
  
  tmp_nodes1 <- rep(target_names[i], counter)
  node1 <- append(node1,tmp_nodes1)
 
  tmp_nodes2 <- target_names[i:24]
  node2 <- append(node2,tmp_nodes2)

  
  counter <- counter - 1
rm(tmp_nodes1)
rm(tmp_nodes2)
rm(i)
}

## create a dataframe to store the vectorized r-values and the name of nodes

corr_mean_ro_long <- data.frame(node1 = factor(node1),node2 = factor(node2),rho = inf_tri)



# visualize average correlation matrix 
ggplot(corr_mean_ro_long, aes(node1, node2, fill = rho)) +
  geom_tile() +
  scale_fill_gradientn(colours = pal) + 
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) + 
  coord_equal() +
  theme(axis.text.x=element_text(angle=90,hjust=1)) 


## SOME TEST WITH THE DATA
diag(target_corr_mean) <- NA
corrplot(target_corr_mean,method = "color",col =pal ,diag = F,col.lim = c(-.1,0.65), )


library(MASS)
corrs <- corr_mean_ro_long %>%
  filter(rho != 1)

truehist(corrs$rho,col = alpha("skyblue3",0.8),prob = T,xlim = c(-.2,0.7), main = "Rho distribution",
         border = NA,bty = NULL)
lines(density(corrs$rho),col = "skyblue4",lwd = 5)

detach("package:MASS", unload=TRUE)
