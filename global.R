##############################
# CoViD-19 Italia * global.R #
##############################

# legge le librerie
pkg <- c('popiFun',
    'Cairo', 'classInt', 'data.table', 'DT', 'fontawesome', 'fst', 
    'ggplot2', 'ggthemes', 'leaflet', 'leaflet.extras', 'leafpop', 'RColorBrewer',
    'shiny', 'shinycssloaders', 'shinyjs', 'shinythemes', 'shinyWidgets'
)
invisible(lapply(pkg, require, char = TRUE))

# alcune opzioni 
options(spinner.color = '#333399', spinner.size = 1, spinner.type = 4)
options(bitmapType = 'cairo', shiny.usecairo = TRUE)
options(warn = -1)

# inizializza costanti e liste
app_path <- file.path(pub_path, 'datasets', 'shiny_apps', 'it_covid')

msr.lst <- c('Totale Casi' = 'N', 'Variazione' = 'V1', 'Attack Rate' = 'R')

bnd <- list()
dts <- list()
lcn <- list()

# carica i poligoni per le mappe
bnd[['RGN']] <- readRDS(file.path(app_path, 'RGN'))
bnd[['PRV']] <- readRDS(file.path(app_path, 'PRV'))

# carica i dati per le province
y <- fread('https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-province/dpc-covid19-ita-province.csv')
y <- y[codice_provincia < 900]
lcn[['PRV']] <- unique(y[, .(
        RGN = codice_regione, regione = denominazione_regione, 
        PRV = codice_provincia, provincia = denominazione_provincia, sigla = sigla_provincia, 
        x_lon = long, y_lat = lat
)])
y <- y[, .(data = as.Date(data), PRV = codice_provincia, N = totale_casi)]
dts[['PRV']] <- copy(y)

# carica i dati per le regioni
y <- fread('https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-regioni/dpc-covid19-ita-regioni.csv')
lcn[['RGN']] <- unique(y[, .(RGN = codice_regione, regione = denominazione_regione, x_lon = long, y_lat = lat)])
y <- y[, .(
    data = as.Date(data), RGN = codice_regione, 
    sintomi = ricoverati_con_sintomi, terapia = terapia_intensiva, ricoverati = totale_ospedalizzati, 
    isolati = isolamento_domiciliare,
    attuali = totale_positivi, nuovi = nuovi_positivi,
    guariti = dimessi_guariti, deceduti, N = totale_casi, tamponi
)]
dts[['RGN']] <- copy(y)

last_updated <- dts[['RGN']][, max(data)]
dates <- unique(dts[['RGN']][, data])

# aggiunge testo sul lato destro del menu principale della pagina
navbarPageWithText <- function(..., text) {
    navbar <- navbarPage(...)
    textEl <- tags$p(class = "navbar-text", text)
    navbar[[3]][[1]]$children[[1]] <- tagAppendChild( navbar[[3]][[1]]$children[[1]], textEl)
    navbar
}

# basemap
mp <- leaflet(options = leafletOptions(minZoom = 6)) %>% 
        addProviderTiles(providers$Wikimedia, group = 'Wikimedia') %>%
        addProviderTiles(providers$OpenStreetMap.Mapnik, group = 'OSM Mapnik') %>%
        addProviderTiles(providers$OpenStreetMap.BlackAndWhite, group = 'OSM B&W') %>%
        addProviderTiles(providers$Stamen.Toner, group = 'Stamen Toner') %>%
        addProviderTiles(providers$Stamen.TonerLite, group = 'Stamen Toner Lite') %>%
        addProviderTiles(providers$Hydda.Full, group = 'Hydda Full') %>%
        addProviderTiles(providers$Hydda.Base, group = 'Hydda Base') %>% 
        addResetMapButton()

# opzioni per etichette map hover
lbl.options <- labelOptions(
    textsize = '12px', 
    direction = 'right', 
    sticky = FALSE, 
    opacity = 0.8,
    offset = c(60, -40), 
    style = list('font-weight' = 'normal', 'padding' = '2px 6px')
)

# opzioni per highlight map hover
hlt.options <- highlightOptions(
          weight = 6,
          color = 'white',
          opacity = 1,
          bringToFront = TRUE
)

# etichette map hover
add_label_prv <- function(y, x, add_v1){
    z <- paste0(
            '<hr>',
                '<b>Provincia</b>: ', y$descrizione[x], '<br>',
            '<hr>',
                '<b>Totale Casi</b>: ', format(y$N[x], big.mark = ','), '<br>',
                '<b>Variazione giornaliera</b>: ', format(y$V0[x], big.mark = ','), '%<br>',
                '<b>Attack Rate</b>: ', format(y$R[x], big.mark = ','), '%<br>'
    )
    if(!is.null(add_v1))
        if(add_v1 > 1) z <- paste0(z, '<br><b>Variazione a ', V1, ' giorni</b>: ', format(y$V1[x], big.mark = ','), '%<br>')
    z <- paste0(z, '<hr>')
    HTML(z)
}

# helper per la funzione sottostante "get_map_legend"
get_fxb_labels <- function(y, dec.fig = 1){
    y <- gsub('^ *|(?<= ) | *$', '', gsub('(?!\\+|-|\\.)[[:alpha:][:punct:]]', ' ', y, perl = TRUE), perl = TRUE)
    y <- paste(y, collapse = ' ')
    y <- gsub('*\\+', Inf, y)
    y <- gsub('*\\-', -Inf, y)
    y <- unique(sort(as.numeric(unlist(strsplit(y, split = ' ')))))
    lbl_brks <- format(round(y, 3), nsmall = dec.fig)
    lbl_brks <- stringr::str_pad(lbl_brks, max(nchar(lbl_brks)), 'left')
    data.table( 
        'lim_inf' = lbl_brks[1:(length(lbl_brks) - 1)],
        'lim_sup' = lbl_brks[2:length(lbl_brks)],
        'label' = sapply(1:(length(lbl_brks) - 1), function(x) paste0(lbl_brks[x], ' ─ ', lbl_brks[x + 1]) )
    )
}
# Costruisce le etichette colore + testo per la legenda
get_map_legend <- function(mtc, brks, dec.fig = 1) {
    lbl <- get_fxb_labels(brks, dec.fig)
    brks <- sort(as.numeric(unique(c(lbl$lim_inf, lbl$lim_sup))))
    mtc <- data.table('value' = mtc)
    mtc <- mtc[, .N, value][!is.na(value)]
    mtc[, label := cut(value, brks, lbl$label, ordered = TRUE)]
    mtc <- mtc[, .(N = sum(N)), label][order(label)][!is.na(label)]
    mtc <- mtc[lbl[, .(label)], on = 'label'][is.na(N), N := 0]
    mtc[, N := format(N, big.mark = ',')]
    ypad <- max(nchar(as.character(mtc$N))) + 3
    mtc[, label := paste0(label, stringr::str_pad(paste0(' (', N, ')'), ypad, 'left'))]
    mtc$label
}

# crea grafici per popups
get_plot <- function(x, z = 'PRV'){
    y <- dts[[z]][N > 0 & get(z) == x, .(data, T = N)][, N := T - shift(T)][is.na(N), N := T]
    ggplot(y) + 
        geom_line(aes(data, T, group = 1)) +
        geom_col(aes(data, N)) +
        geom_text(aes(label = T, x = data, y = T), colour = 'black', size = 2, hjust = 1, vjust = -2, show.legend = FALSE) +
        labs(title = paste('Provincia di', lcn[[z]][get(z) == x, provincia]), x = '', y = '') +
        theme_minimal()
}

# costanti da sostituirsi con controlli in app
lvlStrokeWeight = 5
lvlStrokeColor = 'black'
areaFillOpacity = 0.5
areaStrokeWeight = 2
areaStrokeOpacity = 0.7
areaStrokeColor = 'slateblue'
areaStrokeDash = '3'
n_breaks <- 7
fxd_brks <- c(0, 0.10, 0.25, 0.5, 1.00, 2.5, 5.0, 10.00, 25.00, 50.00, 75.00, 100.00)
cls_mth <- 'equal' # choose from: fixed, equal, quantile, pretty, hclust, kmeans
n_brks <- ifelse(cls_mth == 'fixed', length(fxd_brks) - 1, n_breaks )
use_palette <- FALSE
br_pal = 'OrRd' # see ColorBrewer website for sequential Palettes: http://colorbrewer2.org/#type=sequential&n=9
rev_cols <- FALSE
fxd_cols <- c('#ffeda0', '#feb24c', '#f03b20')

