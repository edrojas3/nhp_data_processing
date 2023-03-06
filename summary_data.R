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
  plot(col = "skyblue")


nhp %>% select(site,Ready) %>%
  table() %>%
  grid.table()

table(nhp$`cost function`) %>%
  barplot( main = "Funciones de costo",ylab = "Frecuencia", col = "tomato2")
 

