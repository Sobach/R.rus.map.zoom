# -*- coding: utf-8 -*-
# Cleaning working space
rm(list = ls())

# Loading required packages
library(ggplot2)
library(grid)
library(sp)
library(maptools)
library(mapproj)
library(gpclib)
library(RColorBrewer)

# Texts on choroplet map
text.title <- 'Internet penetration - households (2011)'
text.footer <- 'Russian Federal State Statistics Service data (http://fedstat.ru/indicator/data.do?id=34078)'
text.note <- c('45,7%', 'of Russians\nhave internet access')

# Setting working directiory
setwd('/WRITE/YOUR/WD/HERE')

# Required files (should be placed in working dir):
# - RUS_adm1.RData - Russia administrative areas borders polygons
# - stat.csv - Data to be visualised, based on template-table

# Loadin data
# Data-file is taken from here: http://www.gadm.org/country
# These data are freely available for academic and other non-commercial use.
rusdf <- load('RUS_adm1.RData')

# Recalculating negative longitudes ("connecting" two parts of Chukotka)
for(i in 1:length(gadm@polygons)){
  for(j in 1:length(gadm@polygons[[i]]@Polygons)){
    gadm@polygons[[i]]@Polygons[[j]]@coords[,1]<- sapply(gadm@polygons[[i]]@Polygons[[j]]@coords[,1], function(x){
        if(x < 0){
          x<-359.999+x
        }
        else{x}
      })
  }
}

gpclibPermit()

# Removing "Int Date Line" on Chuckotka
chuk1 <- Polygons(gadm@polygons[[28]]@Polygons[1:4], ID = 'a')
chuk2 <- Polygons(gadm@polygons[[28]]@Polygons[5:38], ID = 'b')
chuk <- SpatialPolygons(list(chuk1, chuk2))
chuk <- unionSpatialPolygons(chuk, c('a', 'a'))
gadm@polygons[[28]]@Polygons <- chuk@polygons[[1]]@Polygons

# "Creating" new regions (established in 2003-2008 by unioning)
# New regions created with new ID's, so it's possible to use old regions
# for historical data visualisations
united.reg <- gadm$ID_1

# Zabaikalsky krai (Chitinskaya obl. + Aginskiy Buryatskiy AOk)
united.reg[united.reg == 2 | united.reg == 13] <- 91

# Kamchatsky krai (Koryak. AO + Kamchatsk. odl.)
united.reg[united.reg == 37 | united.reg == 27] <- 92

# Permsky krai (Komi-Perm. AO + Permskaya odl.)
united.reg[united.reg == 35 | united.reg == 60] <- 93

# Krasnoyarsky krai (Krasnoyarsky krai + Taimyrsky AO + Evenkisky AO)
united.reg[united.reg == 40 | united.reg == 74 | united.reg == 18] <- 94

# Irkutskaya oblast (Irkutskaya oblast + Ust-ordunsky AO)
united.reg[united.reg == 21 | united.reg == 82] <- 95

united.reg <- as.character(united.reg)
rus.map <- unionSpatialPolygons(gadm, united.reg)

# Returning old regions (before unioning)
old.regions <- list()
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==2,]@polygons[[1]]@Polygons, ID = '2'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==13,]@polygons[[1]]@Polygons, ID = '13'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==37,]@polygons[[1]]@Polygons, ID = '37'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==27,]@polygons[[1]]@Polygons, ID = '27'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==21,]@polygons[[1]]@Polygons, ID = '21'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==35,]@polygons[[1]]@Polygons, ID = '35'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==40,]@polygons[[1]]@Polygons, ID = '40'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==60,]@polygons[[1]]@Polygons, ID = '60'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==74,]@polygons[[1]]@Polygons, ID = '74'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==82,]@polygons[[1]]@Polygons, ID = '82'))
old.regions <- c(old.regions, Polygons(gadm[gadm$ID_1==18,]@polygons[[1]]@Polygons, ID = '18'))

rus.map <- SpatialPolygons(c(slot(rus.map,'polygons'), old.regions))

# Function for cleaning region-borders after uniting
clean.borders <- function(map, id){
  cleaned.polys <-list()
  for(i in 1:length(map[id,]@polygons[[1]]@Polygons)){
    if(map[id,]@polygons[[1]]@Polygons[[i]]@area > .1e-11 | map[id,]@polygons[[1]]@Polygons[[i]]@hole == F){
      cleaned.polys <- c(cleaned.polys, map[id,]@polygons[[1]]@Polygons[[i]])
    }
  }
  map@polygons[[which(names(map)==id)]] <- Polygons(cleaned.polys, ID = id)
  map
}

# Cleaning Kamchatsky krai borders
rus.map <- clean.borders(rus.map, '92')

# Cleaning Krasnoyarsly krai borders
rus.map <- clean.borders(rus.map, '94')

# Loading datatable with data to visualise
map.data <- read.csv('stat.csv', header=T, encoding = 'UTF-8')
row.names(map.data) <- as.character(map.data$ID)

# Filtering NA rows 
# (NA must be used for regions, not to be drawn, i.e. old, deprecated regions)
# For regions that sould be drawn, but have no data 
# (they will be filled with grey) use 0 (zero value)
map.data <- subset(map.data, !is.na(TEST_DATA))
map.data[map.data$TEST_DATA == 0,'TEST_DATA'] <- NA
rus.map <- rus.map[row.names(rus.map) %in% row.names(map.data),]

# Creating dataframe with both polygons & data to be visualised
map.df <- merge(fortify(rus.map), map.data, by.x='id', by.y='ID')

# PLOTTING
# Creating gradient from RColorBrewer without light colours
# 1. Sequential palette
# palette <- colorRampPalette(brewer.pal(9, 'Blues')[3:9])

# 2. Diverging palette
palette <- colorRampPalette(brewer.pal(11, 'RdYlGn')[2:10])

# Creating main plot object - choropleth map without background, margins, title, etc.
p <- ggplot(map.df)
p <- p + aes(x = long, y = lat, group=group, fill=TEST_DATA)
p <- p + geom_polygon(data = subset(map.df, id != '1' & id != '48'), colour='grey90')
p <- p + geom_polygon(data = subset(map.df, id == '1' | id == '48'), colour='grey90')
p <- p + scale_fill_gradientn(colours = palette(100), na.value='grey80', name = '%')
p <- p + theme(axis.line=element_blank(),axis.text.x=element_blank(),
               axis.text.y=element_blank(),axis.ticks=element_blank(),
               axis.title.x=element_blank(),
               axis.title.y=element_blank(),
               legend.position = 'none',
               panel.margin = unit(c(0,0,0,0), 'cm'),
               axis.ticks.margin = unit(0, 'cm'),
               axis.ticks.length = unit(0.001, 'cm'),
               plot.margin = unit(c(0,0,0,0), 'cm'),
               panel.grid = element_blank(),
               panel.background = element_blank()
              )
p <- p + labs(x=NULL, y = NULL)

# Creating two views of base choroplet: zoomed and regular
p1 <- p + coord_map(projection = 'azequidist', 
                    orientation = c(90, -10, 105), 
                    xlim = c(26, 57), 
                    ylim=c(47.5, 67))
p2 <- p + coord_map(projection = 'azequidist', 
                    orientation = c(90, 5, 95), 
                    xlim = c(79, 155), 
                    ylim=c(47, 90))
p2 <- p2 + theme(legend.position = 'bottom',
                 legend.text = element_text(colour = 'grey50'),
                 legend.title = element_text(colour = 'grey50', 
                                             size = 15)
                )

# Combining two views on one plot, adding title, legend, etc. 

# Drawing magnif. glass
magnif.glass <- function(vport){
  grid.circle(x=.6,y=.6,r=.3, gp=gpar(lwd=1.5, col='grey70'), vp = vport)
  grid.lines(x=c(.6,.6), y=c(.5,.7), gp=gpar(lwd=1.5, col='grey70'), vp = vport)
  grid.lines(x=c(.5,.7), y=c(.6,.6), gp=gpar(lwd=1.5, col='grey70'), vp = vport)
  grid.lines(x=c(.1,.4), y=c(.1,.4), gp=gpar(lwd=1.5, col='grey70'), vp = vport)
  grid.lines(x=c(.1,.3), y=c(.1,.3), gp=gpar(lwd=3, col='grey70'), vp = vport)
}

# Setting up final graph. regions
title = viewport(x = .5, y = .96, width = .5, height = .03)
zoomed = viewport(x = .25, y = .47, width = .5, height = .9)
regular = viewport(x = .75, y = .47, width = .5, height = .9)
zoomsign1 = viewport(x = .48, y = .8, width = .02, height = .02)
zoomsign2 = viewport(x = .48, y = .1, width = .02, height = .02)
footer = viewport(x = .02, y = .03, width = .5, height = .05)
note.number = viewport(x = .7, y = .823, width = .2, height = .1)
note.text = viewport(x = .7, y = .817, width = .2, height = .1)


# Plotting and saving map to .png
png('map.png', width=1200, height=700)
grid.newpage()
print(p1, vp=zoomed)
print(p2, vp=regular)
grid.text(text.title, gp=gpar(fontsize=20, col='grey50', fontface='bold'), vp = title)
grid.text(text.footer, 
          just = 'left', gp=gpar(fontsize=10, col='grey50'), vp = footer)
grid.lines(x = c(.5, .5), y = c(.05, .8), gp=gpar(col='grey70'))
magnif.glass(zoomsign1)
magnif.glass(zoomsign2)
grid.text(text.note[1], 
          gp=gpar(fontsize=30, col=palette(3)[3], fontface='bold'), 
          just = c('left', 'bottom'),
          vp = note.number)

grid.text(text.note[2], 
          gp=gpar(fontsize=10, col='grey50', fontface='bold', lineheight=.8), 
          just = c('left', 'top'),
          vp = note.text)
dev.off()

# FIN
