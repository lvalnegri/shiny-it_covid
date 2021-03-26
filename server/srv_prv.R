############################################################
# CoViD-19 Italia * PROVINCE (prv) * server.R (srv_prv.R)  #
############################################################

### TOGGLES -------------------------------------
onclick('tgl_prv_opt', toggle(id = 'hdn_prv_opt', anim = TRUE) )    # opzioni
onclick('tgl_prv_dwn', toggle(id = 'hdn_prv_dwn', anim = TRUE) )    # scarica

### CONTROLLI DINAMICI --------------------------

output$ui_prv_rtd <- renderUI({
    if(input$rdo_prv_mtc != 'V1') return(NULL)
    if(input$dte_prv_ref == min(dates)) return(NULL)
    sliderInput('sld_prv_rtd', 'RITARDO:', min = 1, max = as.numeric(as.Date(input$dte_prv_ref) - min(dates)), value = 1, step = 1)
})

### DATASETS ------------------------------------

dtsp <- reactive({
    
    y <- dts[['PRV']][data == input$dte_prv_ref, .(PRV, N)]
    y0 <- dts[['PRV']][data == as.Date(input$dte_prv_ref) - 1, .(PRV, N0 = N)]
    y <- y0[y, on = 'PRV'][, V0 := round(100 * (N / N0 - 1), 2)]
    if(input$rdo_prv_mtc == 'V1'){
        if(!is.null(input$sld_prv_rtd)){
            y0 <- dts[['PRV']][data == as.Date(input$dte_prv_ref) - input$sld_prv_rtd, .(PRV, N1 = N)]
            y <- y0[y, on = 'PRV'][, V1 := round(100 * (N / N1 - 1), 2)]
        }
    }
    y <- setDT(bnd[['PRV']]@data)[, .(PRV = as.numeric(PRV), popolazione)][y, on = 'PRV'][, R := round(1000 * N / popolazione, 2)]
    y[, popolazione := NULL]
    setcolorder(y, c('PRV', 'N', 'N0', 'V0', 'R'))
    y
    
})

bndp <- reactive({ 
    print(bnd[['PRV']])
    y <- merge(bnd[['PRV']], dtsp()[, PRV := as.character(PRV)])
    y$m <- y@data[, get(input$rdo_prv_mtc)]
    y
})

### TABLE ------------------------------------

output$out_prv_tbl <- renderDT({
    datatable(bndp()@data, 
        rownames = NULL, 
        # colnames = c('Title', 'Score'),
        class = 'stripe nowrap hover compact row-border',
        selection = 'none', 
        extensions = c('Scroller'),
        options = list(scrollY = 200, scroller = TRUE, dom = 't') # , bSort = FALSE, pageLength = nrow(y) )
    )
})

### MAP ------------------------------------

output$out_prv_mps <- renderLeaflet({
    
    # Calcola i limiti degli intervallli per i colori
    brks_poly <- 
        if(cls_mth == 'fixed'){
            classIntervals(bndp()$m, n = n_brks, style = 'fixed', fixedBreaks = fxd_brks)
        } else {
            classIntervals(bndp()$m, n_brks, cls_mth)
        }
    
    # Determina che palette usare
    if(use_palette){
        col_codes <-
            if(n_brks > brewer.pal.info[br_pal, 'maxcolors']){
                colorRampPalette(brewer.pal(brewer.pal.info[br_pal, 'maxcolors'], br_pal))(n_brks)
            } else {
                brewer.pal(n_brks, br_pal)
            }
        if(rev_cols) col_codes <- rev(col_codes)
    } else {
        col_codes <- colorRampPalette(fxd_cols)(n_brks)
    }
    
    # crea la mappa fra valori e colori, poi aggiungila ai poligoni
    pal_poly <- findColours(brks_poly, col_codes)
    ys <- cbind(bndp()$m, pal_poly)
    
    # aggiungi i poligoni alla mappa base    
    mpc <- mp %>% 
        addPolygons(
            data = bndp(), 
            group = 'prv',
            fillColor = ~pal_poly,
            fillOpacity = areaFillOpacity,
            weight = areaStrokeWeight,
            opacity = areaStrokeOpacity,
            color = areaStrokeColor,
            smoothFactor = 0.2,
            highlightOptions = hlt.options,
            label = ~descrizione,
    #         label = lapply(1:length(bndp()), function(x) add_label_poly(bndp(), x, input$)),
    		labelOptions = lbl.options
        )
    
    # aggiungi la legenda
    print(col_codes)
    print(bndp()$m)
    print(brks_poly$brks)
    print(get_map_legend(bndp()$m, brks_poly$brks))
    # mpc <- mpc %>% 
    #     addLegend(
    #         colors = col_codes,
    #         labels = get_map_legend(bndp()$m, brks_poly$brks),
    #         group = 'Legend',
    #         title = 'Cases (%)',
    #         opacity = areaFillOpacity,
    #         position = "bottomright"
    #     )
    
    # aggiungi il menu controlli
    mpc <- mpc %>% 
        addLayersControl(
        	baseGroups = c('OSM Mapnik', 'OSM B&W', 'Wikimedia', 'Stamen Toner', 'Stamen Toner Lite', 'Hydda Full', 'Hydda Base'),
            overlayGroups = 'Legend'
        ) 


    # se richiesti, aggiungi i popup con il trend
    if(input$swt_prv_pop){
        plots <- lapply(bndp()@data$PRV, get_plot)
        mpc <- mpc %>% addPopupGraphs(plots, group = 'prv', width = 300, height = 400)
    }
    
    # ritorna la mappa finale
    mpc
    
})
