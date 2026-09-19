" @keywords list sap.m listselectionsearch overflowtoolbar searchfield label standardlistitem
" @summary When searching a list with multi selection the previously selected items will stay selected. This is managed by the list control for you.
" @origin sap.m.sample.ListSelectionSearch - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListSelectionSearch (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_499 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
        selected      TYPE abap_bool,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    DATA t_products    TYPE ty_t_product.
    DATA info_visible  TYPE abap_bool.
    DATA filter_label  TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_499 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    temp1-check_queue_last = abap_true.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `height`    v = `100%`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( `subHeader`
                )->ele( `OverflowToolbar`
                    " onSearch filters the items binding by Name - the same declarative
                    " filter on the aggregation binding, the model untouched
                    )->tag( `SearchField`
                        )->a( n = `liveChange` v = client->_event( val = `SEARCH` arg = `${$parameters>/newValue}` s_ctrl = temp1 )
                        )->a( n = `width`      v = `80%`

                )->end(
            )->end(

            )->ele( `List`
                )->a( n = `id`                     v = `idList`
                )->a( n = `items`                  v = client->_bind( t_products )
                " onSelectionChange counts the selected contexts and drives the info
                " toolbar - the selection is a bound row field, counted in ABAP
                )->a( n = `selectionChange`        v = client->_event( `SELECTION_CHANGE` )
                )->a( n = `mode`                   v = `MultiSelect`
                )->a( n = `growing`                v = `true`
                )->a( n = `growingThreshold`       v = `50`
                )->a( n = `includeItemInSelection` v = `true`

                )->ele( `infoToolbar`
                    )->ele( `OverflowToolbar`
                        )->a( n = `visible` v = client->_bind( info_visible )
                        )->a( n = `id`      v = `idInfoToolbar`

                        )->tag( `Label`
                            )->a( n = `id`   v = `idFilterLabel`
                            )->a( n = `text` v = client->_bind( filter_label )

                    )->end(
                )->end(

                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `description`      v = `{PRODUCTID}`
                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `selected`         v = `{SELECTED}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA term TYPE string.
        DATA temp2 TYPE string.
        DATA filter LIKE temp2.
        DATA temp3 TYPE string_table.
        DATA temp5 TYPE i.
        DATA n TYPE i.
        DATA row LIKE LINE OF t_products.
          DATA temp1 TYPE i.
        DATA count LIKE temp5.
        DATA temp4 TYPE xsdboolean.
        DATA temp6 TYPE string.

    CASE client->get_event( ).

      WHEN `SEARCH`.
        
        term = client->get_event_arg( ).
        " free text spliced into a JSON string literal - backslash first, then the quote (app 218/420)
        REPLACE ALL OCCURRENCES OF `\` IN term WITH `\\`.
        REPLACE ALL OCCURRENCES OF `"` IN term WITH `\"`.
        " The compound payload is an array of GROUPS, each group an array of
        " [path, operator, value1] ROWS (app 022's shape). It was written as an
        " array of objects, which buildFilterGroups drops as not-an-array - and
        " an empty group list CLEARS the filter, so every search showed the full
        " list (e2e-caught 2026-08-22).
        
        IF term IS INITIAL.
          temp2 = `[]`.
        ELSE.
          temp2 = |[[["NAME","Contains","{ term }"]]]|.
        ENDIF.
        
        filter = temp2.
        
        CLEAR temp3.
        INSERT `idList` INTO TABLE temp3.
        INSERT `items` INTO TABLE temp3.
        INSERT `filter` INTO TABLE temp3.
        INSERT filter INTO TABLE temp3.
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = temp3 ).

      WHEN `SELECTION_CHANGE`.
        " getSelectedContexts(true) counts across the current filter - the bound
        " selected flag does the same, because it lives on the row
        
        
        n = 0.
        
        LOOP AT t_products INTO row.
          
          IF row-selected = abap_true.
            temp1 = n + 1.
          ELSE.
            temp1 = n.
          ENDIF.
          n = temp1.
        ENDLOOP.
        temp5 = n.
        
        count = temp5.
        
        temp4 = boolc( count > 0 ).
        info_visible = temp4.
        
        IF count > 0.
          temp6 = |{ count } selected|.
        ELSE.
          temp6 = ``.
        ENDIF.
        filter_label = temp6.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    DATA temp7 TYPE z2ui5_cl_smpc_app_499=>ty_t_product.
    DATA temp8 LIKE LINE OF temp7.
    CLEAR temp7.
    
    temp8-name = `Notebook Basic 15`.
    temp8-productid = `HT-1000`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Basic 17`.
    temp8-productid = `HT-1001`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Basic 18`.
    temp8-productid = `HT-1002`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Basic 19`.
    temp8-productid = `HT-1003`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO Vault`.
    temp8-productid = `HT-1007`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Professional 15`.
    temp8-productid = `HT-1010`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Professional 17`.
    temp8-productid = `HT-1011`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO Vault Net`.
    temp8-productid = `HT-1020`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO Vault SAT`.
    temp8-productid = `HT-1021`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Comfort Easy`.
    temp8-productid = `HT-1022`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Comfort Senior`.
    temp8-productid = `HT-1023`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergo Screen E-I`.
    temp8-productid = `HT-1030`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergo Screen E-II`.
    temp8-productid = `HT-1031`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergo Screen E-III`.
    temp8-productid = `HT-1032`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Basic`.
    temp8-productid = `HT-1035`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Future`.
    temp8-productid = `HT-1036`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat XL`.
    temp8-productid = `HT-1037`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Laser Professional Eco`.
    temp8-productid = `HT-1040`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Laser Basic`.
    temp8-productid = `HT-1041`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Laser Allround`.
    temp8-productid = `HT-1042`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ultra Jet Super Color`.
    temp8-productid = `HT-1050`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ultra Jet Mobile`.
    temp8-productid = `HT-1051`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ultra Jet Super Highspeed`.
    temp8-productid = `HT-1052`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Multi Print`.
    temp8-productid = `HT-1055`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Multi Color`.
    temp8-productid = `HT-1056`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cordless Mouse`.
    temp8-productid = `HT-1060`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Speed Mouse`.
    temp8-productid = `HT-1061`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Track Mouse`.
    temp8-productid = `HT-1062`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergonomic Keyboard`.
    temp8-productid = `HT-1063`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Internet Keyboard`.
    temp8-productid = `HT-1064`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Media Keyboard`.
    temp8-productid = `HT-1065`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Mousepad`.
    temp8-productid = `HT-1066`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergo Mousepad`.
    temp8-productid = `HT-1067`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Designer Mousepad`.
    temp8-productid = `HT-1068`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Universal card reader`.
    temp8-productid = `HT-1069`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Proctra X`.
    temp8-productid = `HT-1070`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Gladiator MX`.
    temp8-productid = `HT-1071`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Hurricane GX`.
    temp8-productid = `HT-1072`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Hurricane GX/LN`.
    temp8-productid = `HT-1073`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Photo Scan`.
    temp8-productid = `HT-1080`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Power Scan`.
    temp8-productid = `HT-1081`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Jet Scan Professional`.
    temp8-productid = `HT-1082`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Jet Scan Professional`.
    temp8-productid = `HT-1083`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Copymaster`.
    temp8-productid = `HT-1085`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Surround Sound`.
    temp8-productid = `HT-1090`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Blaster Extreme`.
    temp8-productid = `HT-1091`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Sound Booster`.
    temp8-productid = `HT-1092`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Lovely Sound 5.1 Wireless`.
    temp8-productid = `HT-1095`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Lovely Sound 5.1`.
    temp8-productid = `HT-1096`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Lovely Sound Stereo`.
    temp8-productid = `HT-1097`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Office`.
    temp8-productid = `HT-1100`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Design`.
    temp8-productid = `HT-1101`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Network`.
    temp8-productid = `HT-1102`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Multimedia`.
    temp8-productid = `HT-1103`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Games`.
    temp8-productid = `HT-1104`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Internet Antivirus`.
    temp8-productid = `HT-1105`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Firewall`.
    temp8-productid = `HT-1106`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Money`.
    temp8-productid = `HT-1107`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `PC Lock`.
    temp8-productid = `HT-1110`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Lock`.
    temp8-productid = `HT-1111`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Web cam reality`.
    temp8-productid = `HT-1112`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Screen clean`.
    temp8-productid = `HT-1113`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Fabric bag professional`.
    temp8-productid = `HT-1114`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Wireless DSL Router`.
    temp8-productid = `HT-1115`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Wireless DSL Router / Repeater`.
    temp8-productid = `HT-1116`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Wireless DSL Router / Repeater and Print Server`.
    temp8-productid = `HT-1117`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `USB Stick`.
    temp8-productid = `HT-1118`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Travel Adapter`.
    temp8-productid = `HT-1119`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cordless Bluetooth Keyboard, english international`.
    temp8-productid = `HT-1120`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat XXL`.
    temp8-productid = `HT-1137`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Pocket Mouse`.
    temp8-productid = `HT-1138`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `PC Power Station`.
    temp8-productid = `HT-1210`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Astro Laptop 1516`.
    temp8-productid = `HT-1251`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Astro Phone 6`.
    temp8-productid = `HT-1252`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Benda Laptop 1408`.
    temp8-productid = `HT-1253`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Bending Screen 21HD`.
    temp8-productid = `HT-1254`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Broad Screen 22HD`.
    temp8-productid = `HT-1255`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cerdik Phone 7`.
    temp8-productid = `HT-1256`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cepat Tablet 10.5`.
    temp8-productid = `HT-1257`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cepat Tablet 8`.
    temp8-productid = `HT-1258`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Server Basic`.
    temp8-productid = `HT-1500`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Server Professional`.
    temp8-productid = `HT-1501`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Server Power Pro`.
    temp8-productid = `HT-1502`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Family PC Basic`.
    temp8-productid = `HT-1600`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Family PC Pro`.
    temp8-productid = `HT-1601`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Gaming Monster`.
    temp8-productid = `HT-1602`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Gaming Monster Pro`.
    temp8-productid = `HT-1603`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `7" Widescreen Portable DVD Player w MP3`.
    temp8-productid = `HT-2000`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `10" Portable DVD player`.
    temp8-productid = `HT-2001`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Portable DVD Player with 9" LCD Monitor`.
    temp8-productid = `HT-2002`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `CD/DVD case: 264 sleeves`.
    temp8-productid = `HT-2025`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Audio/Video Cable Kit - 4m`.
    temp8-productid = `HT-2026`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Removable CD/DVD Laser Labels`.
    temp8-productid = `HT-2027`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Beam Breaker B-1`.
    temp8-productid = `HT-6100`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Beam Breaker B-2`.
    temp8-productid = `HT-6101`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Beam Breaker B-3`.
    temp8-productid = `HT-6102`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Play Movie`.
    temp8-productid = `HT-6110`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Record Movie`.
    temp8-productid = `HT-6111`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelo MusicStick`.
    temp8-productid = `HT-6120`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelo Jog-Mate`.
    temp8-productid = `HT-6121`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Power Pro Player 40`.
    temp8-productid = `HT-6122`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Power Pro Player 80`.
    temp8-productid = `HT-6123`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Watch HD32`.
    temp8-productid = `HT-6130`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Watch HD37`.
    temp8-productid = `HT-6131`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Watch HD41`.
    temp8-productid = `HT-6132`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Copperberry`.
    temp8-productid = `HT-7000`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Silverberry`.
    temp8-productid = `HT-7010`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Goldberry`.
    temp8-productid = `HT-7020`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Platinberry`.
    temp8-productid = `HT-7030`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO FlexTop I4000`.
    temp8-productid = `HT-8000`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO FlexTop I6300c`.
    temp8-productid = `HT-8001`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO FlexTop I9100`.
    temp8-productid = `HT-8002`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO FlexTop I9800`.
    temp8-productid = `HT-8003`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smartphone Leather Case`.
    temp8-productid = `HT-9991`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smartphone Alpha`.
    temp8-productid = `HT-9992`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Mini Tablet`.
    temp8-productid = `HT-9993`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Camcorder View`.
    temp8-productid = `HT-9994`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Tablet Pouch`.
    temp8-productid = `HT-9995`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Tablet Pouch`.
    temp8-productid = `HT-9996`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `e-Book Reader ReadMe`.
    temp8-productid = `HT-9997`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smartphone Beta`.
    temp8-productid = `HT-9998`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Maxi Tablet`.
    temp8-productid = `HT-9999`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flyer`.
    temp8-productid = `PF-1000`.
    temp8-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    INSERT temp8 INTO TABLE temp7.
    t_products = temp7.

  ENDMETHOD.

ENDCLASS.
