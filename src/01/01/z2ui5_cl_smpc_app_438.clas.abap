" @keywords pulltorefresh pull refresh sap.m refreshresponsive bar searchfield list standardlistitem
" @summary An 'Responsive Refresh' can be achieved by the combination of a Search Field's refresh button and a Pull To Refresh, both of which appear depending on whether the device is touch-enabled. A growing stream of backend data is simulated here.
" @origin sap.m.sample.RefreshResponsive - https://sdk.openui5.org/entity/sap.m.PullToRefresh/sample/sap.m.sample.RefreshResponsive (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_438 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    DATA t_products TYPE ty_t_product.
    DATA search     TYPE string.

  PROTECTED SECTION.
    DATA client        TYPE REF TO z2ui5_if_client.
    DATA product_count TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS list_refresh.
    METHODS products_all RETURNING VALUE(result) TYPE ty_t_product.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_438 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `Page`
            )->a( n = `id`         v = `page`
            )->a( n = `showHeader` v = `false`

            )->ele( `subHeader`
                )->ele( `Bar`
                    )->a( n = `id` v = `searchBar`

                    )->ele( `contentMiddle`
                        " the original's own device model (isNoTouch / isTouch) folds onto
                        " the framework's raw device> model
                        )->tag( `SearchField`
                            )->a( n = `id`                v = `searchField`
                            )->a( n = `showRefreshButton` v = `{= !${device>/support/touch} }`
                            )->a( n = `value`             v = client->_bind( search )
                            )->a( n = `search`            v = client->_event( `REFRESH` )
                            )->a( n = `width`             v = `100%`

                    )->end(
                )->end(
            )->end(

            )->ele( `content`
                )->tag( `PullToRefresh`
                    )->a( n = `id`      v = `pullToRefresh`
                    )->a( n = `visible` v = `{= ${device>/support/touch} }`
                    )->a( n = `refresh` v = client->_event( `REFRESH` )

                )->ele( `List`
                    )->a( n = `id`    v = `list`
                    )->a( n = `items` v = client->_bind( t_products )

                    )->tag( `StandardListItem`
                        )->a( n = `title`            v = `{NAME}`
                        )->a( n = `description`      v = `{PRODUCTID}`
                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                        )->a( n = `iconDensityAware` v = `false`
                        )->a( n = `iconInset`        v = `false` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
      DATA temp1 TYPE string_table.

    IF client->get_event( ) = `REFRESH`.

      list_refresh( ).

      " the original hides the PullToRefresh spinner when the refresh is through
      
      CLEAR temp1.
      INSERT `pullToRefresh` INTO TABLE temp1.
      INSERT `hide` INTO TABLE temp1.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = temp1 ).

    ENDIF.

  ENDMETHOD.


  METHOD list_refresh.

    " _pushNewProduct adds one more record of the mock per refresh, and
    " handleRefresh then filters the list binding by the search field's value -
    " both are done in the backend here, on the one table the List binds
    DATA all TYPE z2ui5_cl_smpc_app_438=>ty_t_product.
    DATA temp3 TYPE z2ui5_cl_smpc_app_438=>ty_t_product.
    DATA product LIKE LINE OF all.
    all = products_all( ).
    IF product_count < lines( all ).
      product_count = product_count + 1.
    ENDIF.

    
    CLEAR temp3.
    t_products = temp3.
    
    LOOP AT all INTO product TO product_count.
      IF search IS INITIAL OR to_upper( product-name ) CS to_upper( search ).
        INSERT product INTO TABLE t_products.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD products_all.

    " /ProductCollection of ui5/mock/products.json, verbatim - the "backend" the
    " sample loads with jQuery.getJSON and hands out one record at a time
    DATA temp4 TYPE z2ui5_cl_smpc_app_438=>ty_t_product.
    DATA temp5 LIKE LINE OF temp4.
    CLEAR temp4.
    
    temp5-name = `Notebook Basic 15`.
    temp5-productid = `HT-1000`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Notebook Basic 17`.
    temp5-productid = `HT-1001`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Notebook Basic 18`.
    temp5-productid = `HT-1002`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Notebook Basic 19`.
    temp5-productid = `HT-1003`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelO Vault`.
    temp5-productid = `HT-1007`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Notebook Professional 15`.
    temp5-productid = `HT-1010`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Notebook Professional 17`.
    temp5-productid = `HT-1011`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelO Vault Net`.
    temp5-productid = `HT-1020`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelO Vault SAT`.
    temp5-productid = `HT-1021`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Comfort Easy`.
    temp5-productid = `HT-1022`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Comfort Senior`.
    temp5-productid = `HT-1023`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Ergo Screen E-I`.
    temp5-productid = `HT-1030`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Ergo Screen E-II`.
    temp5-productid = `HT-1031`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Ergo Screen E-III`.
    temp5-productid = `HT-1032`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Flat Basic`.
    temp5-productid = `HT-1035`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Flat Future`.
    temp5-productid = `HT-1036`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Flat XL`.
    temp5-productid = `HT-1037`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Laser Professional Eco`.
    temp5-productid = `HT-1040`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Laser Basic`.
    temp5-productid = `HT-1041`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Laser Allround`.
    temp5-productid = `HT-1042`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Ultra Jet Super Color`.
    temp5-productid = `HT-1050`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Ultra Jet Mobile`.
    temp5-productid = `HT-1051`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Ultra Jet Super Highspeed`.
    temp5-productid = `HT-1052`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Multi Print`.
    temp5-productid = `HT-1055`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Multi Color`.
    temp5-productid = `HT-1056`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Cordless Mouse`.
    temp5-productid = `HT-1060`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Speed Mouse`.
    temp5-productid = `HT-1061`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Track Mouse`.
    temp5-productid = `HT-1062`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Ergonomic Keyboard`.
    temp5-productid = `HT-1063`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Internet Keyboard`.
    temp5-productid = `HT-1064`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Media Keyboard`.
    temp5-productid = `HT-1065`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Mousepad`.
    temp5-productid = `HT-1066`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Ergo Mousepad`.
    temp5-productid = `HT-1067`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Designer Mousepad`.
    temp5-productid = `HT-1068`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Universal card reader`.
    temp5-productid = `HT-1069`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Proctra X`.
    temp5-productid = `HT-1070`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Gladiator MX`.
    temp5-productid = `HT-1071`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Hurricane GX`.
    temp5-productid = `HT-1072`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Hurricane GX/LN`.
    temp5-productid = `HT-1073`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Photo Scan`.
    temp5-productid = `HT-1080`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Power Scan`.
    temp5-productid = `HT-1081`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Jet Scan Professional`.
    temp5-productid = `HT-1082`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Jet Scan Professional`.
    temp5-productid = `HT-1083`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Copymaster`.
    temp5-productid = `HT-1085`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Surround Sound`.
    temp5-productid = `HT-1090`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Blaster Extreme`.
    temp5-productid = `HT-1091`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Sound Booster`.
    temp5-productid = `HT-1092`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Lovely Sound 5.1 Wireless`.
    temp5-productid = `HT-1095`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Lovely Sound 5.1`.
    temp5-productid = `HT-1096`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Lovely Sound Stereo`.
    temp5-productid = `HT-1097`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smart Office`.
    temp5-productid = `HT-1100`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smart Design`.
    temp5-productid = `HT-1101`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smart Network`.
    temp5-productid = `HT-1102`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smart Multimedia`.
    temp5-productid = `HT-1103`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smart Games`.
    temp5-productid = `HT-1104`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smart Internet Antivirus`.
    temp5-productid = `HT-1105`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smart Firewall`.
    temp5-productid = `HT-1106`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smart Money`.
    temp5-productid = `HT-1107`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `PC Lock`.
    temp5-productid = `HT-1110`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Notebook Lock`.
    temp5-productid = `HT-1111`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Web cam reality`.
    temp5-productid = `HT-1112`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Screen clean`.
    temp5-productid = `HT-1113`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Fabric bag professional`.
    temp5-productid = `HT-1114`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Wireless DSL Router`.
    temp5-productid = `HT-1115`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Wireless DSL Router / Repeater`.
    temp5-productid = `HT-1116`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Wireless DSL Router / Repeater and Print Server`.
    temp5-productid = `HT-1117`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `USB Stick`.
    temp5-productid = `HT-1118`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Travel Adapter`.
    temp5-productid = `HT-1119`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Cordless Bluetooth Keyboard, english international`.
    temp5-productid = `HT-1120`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Flat XXL`.
    temp5-productid = `HT-1137`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Pocket Mouse`.
    temp5-productid = `HT-1138`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `PC Power Station`.
    temp5-productid = `HT-1210`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Astro Laptop 1516`.
    temp5-productid = `HT-1251`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Astro Phone 6`.
    temp5-productid = `HT-1252`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Benda Laptop 1408`.
    temp5-productid = `HT-1253`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Bending Screen 21HD`.
    temp5-productid = `HT-1254`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Broad Screen 22HD`.
    temp5-productid = `HT-1255`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Cerdik Phone 7`.
    temp5-productid = `HT-1256`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Cepat Tablet 10.5`.
    temp5-productid = `HT-1257`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Cepat Tablet 8`.
    temp5-productid = `HT-1258`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Server Basic`.
    temp5-productid = `HT-1500`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Server Professional`.
    temp5-productid = `HT-1501`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Server Power Pro`.
    temp5-productid = `HT-1502`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Family PC Basic`.
    temp5-productid = `HT-1600`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Family PC Pro`.
    temp5-productid = `HT-1601`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Gaming Monster`.
    temp5-productid = `HT-1602`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Gaming Monster Pro`.
    temp5-productid = `HT-1603`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `7" Widescreen Portable DVD Player w MP3`.
    temp5-productid = `HT-2000`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `10" Portable DVD player`.
    temp5-productid = `HT-2001`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Portable DVD Player with 9" LCD Monitor`.
    temp5-productid = `HT-2002`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `CD/DVD case: 264 sleeves`.
    temp5-productid = `HT-2025`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Audio/Video Cable Kit - 4m`.
    temp5-productid = `HT-2026`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Removable CD/DVD Laser Labels`.
    temp5-productid = `HT-2027`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Beam Breaker B-1`.
    temp5-productid = `HT-6100`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Beam Breaker B-2`.
    temp5-productid = `HT-6101`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Beam Breaker B-3`.
    temp5-productid = `HT-6102`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Play Movie`.
    temp5-productid = `HT-6110`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Record Movie`.
    temp5-productid = `HT-6111`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelo MusicStick`.
    temp5-productid = `HT-6120`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelo Jog-Mate`.
    temp5-productid = `HT-6121`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Power Pro Player 40`.
    temp5-productid = `HT-6122`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Power Pro Player 80`.
    temp5-productid = `HT-6123`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Flat Watch HD32`.
    temp5-productid = `HT-6130`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Flat Watch HD37`.
    temp5-productid = `HT-6131`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Flat Watch HD41`.
    temp5-productid = `HT-6132`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Copperberry`.
    temp5-productid = `HT-7000`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Silverberry`.
    temp5-productid = `HT-7010`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Goldberry`.
    temp5-productid = `HT-7020`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Platinberry`.
    temp5-productid = `HT-7030`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelO FlexTop I4000`.
    temp5-productid = `HT-8000`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelO FlexTop I6300c`.
    temp5-productid = `HT-8001`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelO FlexTop I9100`.
    temp5-productid = `HT-8002`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `ITelO FlexTop I9800`.
    temp5-productid = `HT-8003`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smartphone Leather Case`.
    temp5-productid = `HT-9991`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smartphone Alpha`.
    temp5-productid = `HT-9992`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Mini Tablet`.
    temp5-productid = `HT-9993`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Camcorder View`.
    temp5-productid = `HT-9994`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Tablet Pouch`.
    temp5-productid = `HT-9995`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Tablet Pouch`.
    temp5-productid = `HT-9996`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `e-Book Reader ReadMe`.
    temp5-productid = `HT-9997`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Smartphone Beta`.
    temp5-productid = `HT-9998`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Maxi Tablet`.
    temp5-productid = `HT-9999`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    INSERT temp5 INTO TABLE temp4.
    temp5-name = `Flyer`.
    temp5-productid = `PF-1000`.
    temp5-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    INSERT temp5 INTO TABLE temp4.
    result = temp4.

  ENDMETHOD.


  METHOD model_init.

    " the sample starts with an empty collection and pushes the first record
    " as soon as the mock is loaded
    list_refresh( ).

  ENDMETHOD.

ENDCLASS.
