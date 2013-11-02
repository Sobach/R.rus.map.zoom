R.rus.map.zoom
==============

R template for Russia choropleth map with zoom on europe part

Example:

![img/map-diverging.png](https://raw.github.com/Sobach/R.rus.map.zoom/master/img/map-diverging.png)

Russia map with zoom on europe part invented by 
[Ilya Birman](http://ilyabirman.ru/projects/uzp-branches-map/) in 2007.

Later map with zoomed part was used on choropleth by [Tanya Misyutina](http://infotanka.ru/georating.html).

[mapzoom.R](https://github.com/Sobach/R.rus.map.zoom/blob/master/mapzoom.R) script implements this concept is R.

### Required packages (dependencies):

Geospatial data processing:

* [sp](http://cran.r-project.org/web/packages/sp/index.html)
* [maptools](http://cran.r-project.org/web/packages/maptools/index.html)
* [gpclib](http://cran.r-project.org/web/packages/gpclib/index.html)

Plotting:

* [ggplot2](http://docs.ggplot2.org/current/)
* [RColorBrewer](http://cran.r-project.org/web/packages/RColorBrewer/index.html)
* [grid](https://www.stat.auckland.ac.nz/~paul/grid/grid.html)

### Procedure:

1. Specify data, you want to visualise, in [stat.csv](https://github.com/Sobach/R.rus.map.zoom/blob/master/stat.csv) file.
    Don't modify 'ID' column, as it used to merge data with geo-polygons.
    Regions not to be shown at all, should be marked with 'NA' in data column; 
    regions without data (visualised with grey color) require zero values in data column.


2. In 'mapzoom.R' specify working directory. Shape-file 'RUS_adm1.RData' and data-file 'stats.csv' should be placed there:

    ```
    setwd('/WRITE/YOUR/WD/HERE')
    ```

3. Specify text variables to be written on choropleth:
    - Title;
    - Footer;
    - Note - significant number and text about it.
    

    ```
    # Texts on choroplet map
    text.title <- 'Internet penetration - households (2011)'
    text.footer <- 'Russian Federal State Statistics Service data (http://fedstat.ru/indicator/data.do?id=34078)'
    text.note <- c('45,7%', 'of Russians\nhave internet access')
    ```
    
4. Select sequential or diverging palette (alternate should be commented):

    ```
    # Diverging palette selected
    # 1. Sequential palette
    # palette <- colorRampPalette(brewer.pal(9, 'Blues')[3:9])

    # 2. Diverging palette
    palette <- colorRampPalette(brewer.pal(11, 'RdYlGn')[2:10]) 
    ```

5. Specify output file type and name:

    ```
    png('map.png', width=1200, height=700)
    ```

6. Run the script.
