##############################
# CoViD-19 Italia * global.R #
##############################

pkg <- c('popiFun',
    'Cairo', 'data.table', 'DT', 'dygraphs', 'fontawesome', 'fst', 'leaflet', 'leaflet.extras', 'RColorBrewer',
    'shiny', 'shinycssloaders', 'shinyjs', 'shinythemes', 'shinyWidgets'
)
invisible(lapply(pkg, require, char = TRUE))

options(spinner.color = '#333399', spinner.size = 1, spinner.type = 4)
options(bitmapType = 'cairo', shiny.usecairo = TRUE)
options(knitr.table.format = 'html')

app_path <- file.path(pub_path, 'datasets', 'shiny_apps', 'it_covid')


bnd <- list()
bnd[['RGN']] <- readRDS(file.path(app_path, 'RGN'))
bnd[['PRV']] <- readRDS(file.path(app_path, 'PRV'))

dts <- list()
dts[['RGN']] <- fread('https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-regioni/dpc-covid19-ita-regioni.csv')
dts[['PRV']] <- fread('https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-province/dpc-covid19-ita-province.csv')

