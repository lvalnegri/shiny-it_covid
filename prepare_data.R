#######################################
# CoViD-19 Italia * Preparazione dati #
#######################################

pkg <- c('popiFun', 'data.table', 'rgdal', 'rmapshaper')
invisible(lapply(pkg, require, char = TRUE))

in_path <- file.path(pub_path, 'ext_data', 'it', 'geography', 'boundaries')
out_path <- file.path(pub_path, 'datasets', 'shiny_apps', 'it_covid')

pop <- fread(file.path(pub_path, 'ext_data', 'it', 'istat', 'POP_PRV_122019.csv'))
pop[Territorio == "Valle d'Aosta / Vallée d'Aoste", Territorio := 'Aosta']
pop[Territorio == 'Bolzano / Bozen', Territorio := 'Bolzano']
pop[Territorio == 'Forlì-Cesena', Territorio := "Forli'-Cesena"]
pop[Territorio == 'Massa-Carrara', Territorio := "Massa Carrara"]
pop[Territorio == 'Trentino Alto Adige / Südtirol', Territorio := 'Trentino-Alto Adige']
pop[Territorio == 'Friuli-Venezia Giulia', Territorio := 'Friuli Venezia Giulia']
pop[Territorio == 'Nord-ovest', Territorio := 'Nord-Ovest']
pop[Territorio == 'Nord-est', Territorio := 'Nord-Est']
pop <- unique(pop[
            Sesso == 'totale' & ETA1 == 'TOTAL' & `Stato civile` == 'totale', 
            .(descrizione = Territorio, popolazione = Value)
])

y <- readOGR(file.path(in_path, 'PRV'), 'PRV', stringsAsFactors = FALSE)
y <- spTransform(y, CRS(crs.wgs))
y <- y[, c('COD_RIP', 'COD_REG', 'COD_PROV', 'DEN_UTS', 'SIGLA', 'Shape_Leng', 'Shape_Area')]
colnames(y@data) <- c('RPT', 'RGN', 'PRV', 'descrizione', 'sigla', 'Perimetro', 'Area')
y <- spChFIDs(y, y$PRV)
y <- ms_simplify(y, 0.10)
y <- merge(y, pop, by = 'descrizione')
saveRDS(y, file.path(out_path, 'PRV'))

y <- readOGR(file.path(in_path, 'RGN'), 'RGN', stringsAsFactors = FALSE)
y <- spTransform(y, CRS(crs.wgs))
colnames(y@data) <- c('RPT', 'RGN', 'descrizione', 'Perimetro', 'Area')
y <- spChFIDs(y, y$RGN)
y <- ms_simplify(y, 0.20)
pop[descrizione == 'Aosta', descrizione := "Valle d'Aosta"]
y <- merge(y, pop, by = 'descrizione')
saveRDS(y, file.path(out_path, 'RGN'))

y <- readOGR(file.path(in_path, 'RPT'), 'RPT', stringsAsFactors = FALSE)
y <- spTransform(y, CRS(crs.wgs))
colnames(y@data) <- c('RPT', 'descrizione', 'Perimetro', 'Area')
y <- spChFIDs(y, y$RPT)
y <- ms_simplify(y, 0.40)
y <- merge(y, pop, by = 'descrizione')
saveRDS(y, file.path(out_path, 'RPT'))

