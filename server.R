##############################
# CoViD-19 Italia * server.R #
##############################

shinyServer(function(input, output, session) {
    
    # PROVINCE (prv) -------------------------------------------------------
    source(file.path("server", "srv_prv.R"),  local = TRUE)$value
    
    # REGIONI (rgn) -------------------------------------------------------
    source(file.path("server", "srv_rgn.R"),  local = TRUE)$value
    
    # CREDITI (crd) ---------------------------------------------------
    # source(file.path("server", "srv_crd.R"),  local = TRUE)$value

})
