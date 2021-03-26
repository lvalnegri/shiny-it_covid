#####################################################
# CoViD-19 Italia * REGIONI (rgn) * ui.R (ui_rgn.R) #
#####################################################

tabPanel('REGIONI', icon = icon('rocket'),
         
    # SIDEBAR PANEL -----------------------------------------------------------
    sidebarPanel(
    
        # SHOWS --------------------------------------------------------------
        a(id = 'tgl_rgn_shw', 'Show/Hide SHOWS', class = 'toggle-choices'),
        div(id = 'hdn_rgn_shw', class = 'toggle-choices-content',
            p()

            # Choose venue
            # pickerInput('cbo_rgn_vns', 'VENUE:', c('Choose a venue...' = '0', vnames)),

            # Choose dates
            # uiOutput('ui_rgn_vdt')
        

        # END OF SHOWS Controls -----------------------------------------------
        ),

 
        width = 3

    ),

    # MAIN PANEL --------------------------------------------------------------
    mainPanel(
        tabsetPanel(id = 'tabs_rgn',

            tabPanel('table', icon = icon('equalizer', lib = 'glyphicon'), 

                div(style="display:inline-block;vertical-align:top;width:40px;padding-top:15px;",
                    dropdownButton( 
                        DTOutput('out_sms', height = '100%'),
                        size = 'sm', circle = TRUE, status = 'primary', icon = icon('filter'), 
                        tooltip = TRUE, label = 'Click to see similar shows'
                    )
                ),

                withSpinner( DTOutput('out_rgn_tbl') ) 
                
            ),

            tabPanel('map', icon = icon('globe', lib = 'glyphicon'), withSpinner( leafletOutput('out_mps', height = 800) ) )

        )
    )

)