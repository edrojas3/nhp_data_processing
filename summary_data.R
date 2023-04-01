#!/usr/bin/Rscript

library(googledrive)
library(tidyverse)
drive_auth(email = "faj.alf@gmail.com")
library(googlesheets4)
library(gridExtra)

nhp <- drive_find(pattern = "Registration",type = "spreadsheet",n_max = 1)$id %>%
  as_id() %>%
  googlesheets4::read_sheet(skip = 1)

nhp$Ready [nhp$Ready != "yes"] <- "no"
nhp$Ready [is.na(nhp$Ready)] <- "no"

# graficos de frecuencia

nhp %>% select(site,Ready) %>%
  table() %>%
  grid.table()
nhp %>% select(site,Ready) %>%
  table() %>%
  plot(col = "skyblue", main = "RS-fMRI datasets")




table(nhp$`cost function`) %>%
  barplot( main = "Funciones de costo",ylab = "Frecuencia", col = "tomato2")
 
nhp %>%
  select(site,Align_Centers,unifize_epi,cmass,rigid_body) %>%
  table() %>%
  plot(main = "Parameters", col = "tomato1")

