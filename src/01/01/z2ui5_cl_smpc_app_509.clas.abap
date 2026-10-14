" @keywords input sap.m inputsuggestionsopensearch verticallayout label item
" @summary If you need to use an Open Search Provider (OSP) to supply possible values, you can do this with the Input control's suggest event, and build the suggestionItems dynamically according to the results of the Open Search call.
" @origin sap.m.sample.InputSuggestionsOpenSearch - https://sdk.openui5.org/entity/sap.m.Input/sample/sap.m.sample.InputSuggestionsOpenSearch (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_509 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    DATA t_suggestions TYPE ty_t_product.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS products_all RETURNING VALUE(result) TYPE ty_t_product.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_509 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp2 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    temp1-check_queue_last = abap_true.
    temp1-check_no_busy = abap_true.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Product`
                )->a( n = `labelFor` v = `productInput`
            " onSuggest asks an OpenSearchProvider (a mock server) and replaces the
            " suggestion items with what it answers - the same search runs in ABAP and
            " fills the bound aggregation
            )->ele( `Input`
                )->a( n = `id`              v = `productInput`
                )->a( n = `placeholder`     v = `Enter product`
                )->a( n = `showSuggestion`  v = `true`
                )->a( n = `suggestionItems` v = client->_bind( t_suggestions )
                )->a( n = `suggest`         v = client->_event( val = `SUGGEST` arg = `${$parameters>/suggestValue}` s_ctrl = temp1 )

                )->ele( `suggestionItems`
                    )->tag( n = `Item` ns = `core`
                        )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).
    " the original builds its suggestions imperatively (addSuggestionItem), which no
    " size limit applies to; this port binds the aggregation, so the limit has to be
    " raised - a one-character term matches over 100 of the 123 products
    
    CLEAR temp2.
    INSERT `100000` INTO TABLE temp2.
    INSERT client->cs_view-main INTO TABLE temp2.
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = temp2 ).

  ENDMETHOD.


  METHOD on_event.
      DATA term TYPE string.
      DATA temp4 TYPE z2ui5_cl_smpc_app_509=>ty_t_product.
        DATA temp5 TYPE z2ui5_cl_smpc_app_509=>ty_t_product.
        DATA product LIKE LINE OF temp5.

    IF client->get_event( ) = `SUGGEST`.

      
      term = to_upper( client->get_event_arg( ) ).
      
      CLEAR temp4.
      t_suggestions = temp4.
      IF term IS NOT INITIAL.
        
        temp5 = products_all( ).
        
        LOOP AT temp5 INTO product.
          IF to_upper( product-name ) CS term.
            APPEND product TO t_suggestions.
          ENDIF.
        ENDLOOP.
      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD products_all.

    " the product names the sample's mock search service answers with
    DATA temp6 TYPE z2ui5_cl_smpc_app_509=>ty_t_product.
    DATA temp7 LIKE LINE OF temp6.
    CLEAR temp6.
    
    temp7-name = `Notebook Basic 15`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 17`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 18`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 19`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Professional 15`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Professional 17`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault Net`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault SAT`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Comfort Easy`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Comfort Senior`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-I`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-II`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-III`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Basic`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Future`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat XL`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Professional Eco`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Basic`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Allround`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Super Color`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Mobile`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Super Highspeed`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Multi Print`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Multi Color`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cordless Mouse`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Speed Mouse`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Track Mouse`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergonomic Keyboard`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Internet Keyboard`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Media Keyboard`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Mousepad`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Mousepad`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Designer Mousepad`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Universal card reader`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Proctra X`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gladiator MX`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Hurricane GX`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Hurricane GX/LN`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Photo Scan`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Scan`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Jet Scan Professional`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Jet Scan Professional`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Copymaster`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Surround Sound`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Blaster Extreme`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Sound Booster`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound 5.1 Wireless`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound 5.1`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound Stereo`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Office`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Design`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Network`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Multimedia`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Games`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Internet Antivirus`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Firewall`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Money`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `PC Lock`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Lock`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Web cam reality`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Screen clean`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Fabric bag professional`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router / Repeater`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router / Repeater and Print Server`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `USB Stick`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Travel Adapter`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cordless Bluetooth Keyboard, english international`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat XXL`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Pocket Mouse`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `PC Power Station`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Astro Laptop 1516`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Astro Phone 6`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Benda Laptop 1408`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Bending Screen 21HD`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Broad Screen 22HD`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cerdik Phone 7`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cepat Tablet 10.5`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cepat Tablet 8`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Basic`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Professional`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Power Pro`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Family PC Basic`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Family PC Pro`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gaming Monster`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gaming Monster Pro`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `7" Widescreen Portable DVD Player w MP3`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `10" Portable DVD player`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Portable DVD Player with 9" LCD Monitor`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `CD/DVD case: 264 sleeves`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Audio/Video Cable Kit - 4m`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Removable CD/DVD Laser Labels`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-1`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-2`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-3`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Play Movie`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Record Movie`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelo MusicStick`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelo Jog-Mate`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Pro Player 40`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Pro Player 80`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD32`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD37`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD41`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Copperberry`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Silverberry`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Goldberry`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Platinberry`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I4000`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I6300c`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I9100`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I9800`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Leather Case`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Alpha`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Mini Tablet`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Camcorder View`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Tablet Pouch`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Tablet Pouch`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `e-Book Reader ReadMe`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Beta`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Maxi Tablet`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flyer`.
    INSERT temp7 INTO TABLE temp6.
    result = temp6.

  ENDMETHOD.

ENDCLASS.
