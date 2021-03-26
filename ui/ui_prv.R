######################################################
# CoViD-19 Italia * PROVINCE (prv) * ui.R (ui_prv.R) #
######################################################

tabPanel('PROVINCE', icon = icon('rocket'),
         
    # SIDEBAR PANEL -----------------------------------------------------------
    sidebarPanel(
    
        # Scegli DATA RIFERIMENTO
        dateInput('dte_prv_ref', 'DATA:', last_updated, min(dates), max(dates), 'dd MM', weekstart = 1, language = 'it'),

        # Scegli MISURA
        radioGroupButtons('rdo_prv_mtc', 'MISURA:',
            choices = msr.lst,
            individual = TRUE,
            direction = "vertical",
            checkIcon = list( 
                yes = tags$i(class = "fa fa-circle", style = "color: steelblue"),
                no = tags$i(class = "fa fa-circle-o", style = "color: steelblue")
            )
        ),

        # Scegli RITARDO (se MISURA = '2')
        uiOutput('ui_prv_rtd'),

        # AGGIUNGI POPUP ?
        switchInput('swt_prv_pop', 'Aggiungi POPUP TREND', onLabel = 'SI', offLabel = 'NO'),

        width = 3

    ),

    # MAIN PANEL --------------------------------------------------------------
    mainPanel(
        tabsetPanel(id = 'tabs_prv',

            tabPanel('TABELLA', icon = icon('equalizer', lib = 'glyphicon'), 

                withSpinner( DTOutput('out_prv_tbl') ) 
                
            ),

            tabPanel('MAPPA', icon = icon('globe', lib = 'glyphicon'), withSpinner( leafletOutput('out_prv_mps', height = 800) ) )

        )
    )

)