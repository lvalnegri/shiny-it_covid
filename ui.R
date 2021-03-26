##########################
# CoViD-19 Italia * ui.R #
##########################

shinyUI(fluidPage(
    
    includeCSS(file.path(pub_path, 'styles', 'datamaps.css')),
#    includeScript(file.path(app_path, 'scripts.js')),
    tags$head(
        tags$link(rel="shortcut icon", href="favicon.ico"),
        tags$link(rel="stylesheet", href="https://use.fontawesome.com/releases/v5.8.1/css/all.css")
    ),
    
    navbarPageWithText(
        header = '',
        title = HTML('<div><img src="logo.png" class="logo"><span class = "title">CoVid-19 Italia</span></div>'),
        windowTitle = 'CoVid-19 Italia', 
        id = 'mainNav',
        theme = shinytheme('united'), inverse = TRUE,
        
        # PROVINCE (prv) -------------------------------------------------------
        source(file.path("ui", "ui_prv.R"),  local = TRUE)$value,
        
        # REGIONI (rgn) -------------------------------------------------------
        source(file.path("ui", "ui_rgn.R"),  local = TRUE)$value,
        
        # CREDITI (crd) ---------------------------------------------------
#        source(file.path("ui", "ui_crd.R"),  local = TRUE)$value,

        # LAST UPDATED AT -----------------------------------------------------
        text = paste('Ultimo Aggiornamento:', format(last_updated, '%d %b') )
    
    ),

    useShinyjs()

))
