" @keywords popover sap.m popoverwithinarea button vbox flexitemdata flexbox image list standardlistitem
" @summary Within area of sap.ui.core.Popup determines where all popups (including popovers) are positioned.
CLASS z2ui5_cl_smpc_app_285 DEFINITION PUBLIC.

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

    " the record the original reaches with bindElement( '/ProductCollection/0' )
    " on every popover, seeded at the model root
    DATA name          TYPE string.
    DATA productpicurl TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS popover_image_display.
    METHODS popover_list_display.
    METHODS popover_inner_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_285 IMPLEMENTATION.

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
    DATA temp1 TYPE string_table.
    DATA temp2 TYPE string_table.
    DATA temp4 TYPE string_table.
    DATA temp3 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `$event.oSource.sId` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `$event.oSource.sId` INTO TABLE temp2.
    
    CLEAR temp4.
    INSERT `$event.oSource.sId` INTO TABLE temp4.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( n = `HorizontalLayout` ns = `l`
            )->a( n = `class` v = `sapUiMediumMargin`

            )->tag( `Button`
                )->a( n = `text`         v = `Show Popover With Image`
                )->a( n = `press`        v = client->_event( val = `POPOVER_IMAGE` t_arg = temp1 )
                )->a( n = `class`        v = `sapUiLargeMargin`
                )->a( n = `ariaHasPopup` v = `Dialog`

            )->ele( `VBox`
                )->a( n = `id`               v = `withinArea`
                )->a( n = `backgroundDesign` v = `Solid`
                )->a( n = `height`           v = `30rem`
                )->a( n = `width`            v = `60rem`
                )->a( n = `alignItems`       v = `Center`
                )->a( n = `justifyContent`   v = `Center`

                )->tag( `Button`
                    )->a( n = `text`         v = `Show Inside Popover`
                    )->a( n = `press`        v = client->_event( val = `POPOVER_INNER` t_arg = temp2 )
                    )->a( n = `ariaHasPopup` v = `Dialog`

                )->ele( `layoutData`
                    )->tag( `FlexItemData`
                        )->a( n = `backgroundDesign` v = `Solid`

                )->end(
            )->end(

            )->ele( `FlexBox`
                )->a( n = `direction`      v = `Column`
                )->a( n = `alignItems`     v = `End`
                )->a( n = `justifyContent` v = `End`
                )->a( n = `height`         v = `30rem`

                )->tag( `Button`
                    )->a( n = `text`         v = `Show Popover with List`
                    )->a( n = `press`        v = client->_event( val = `POPOVER_LIST` t_arg = temp4 )
                    )->a( n = `ariaHasPopup` v = `Dialog`
                    )->a( n = `class`        v = `sapUiLargeMargin` ).

    client->view_display( view->stringify( ) ).

    " Popup.setWithinArea confines every popup to the grey VBox instead of the
    " viewport - the sample's point. The original re-sets it in each press
    " handler and releases it in afterClose; here it is set once with the view,
    " because a follow-up action runs AFTER the popover of the same round-trip
    " has opened. This app opens no other popup, so the effect is the same.
    
    CLEAR temp3.
    INSERT `POPUP` INTO TABLE temp3.
    INSERT `setWithinArea` INTO TABLE temp3.
    INSERT `withinArea` INTO TABLE temp3.
    client->follow_up_action( val   = client->cs_event-control_global
                              t_arg = temp3 ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `POPOVER_IMAGE`.
        popover_image_display( ).

      WHEN `POPOVER_INNER`.
        popover_inner_display( ).

      WHEN `POPOVER_LIST`.
        popover_list_display( ).

    ENDCASE.

  ENDMETHOD.


  METHOD popover_image_display.

    DATA popover TYPE REF TO z2ui5_cl_ui5_view_builder.
    popover = z2ui5_cl_ui5_view_builder=>factory( ).

    " the fragment's relative {Name}/{ProductPicUrl} come from the popover's
    " bindElement( '/ProductCollection/0' ); that record is seeded at the model
    " root here, so both bind absolutely
    popover->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Popover`
            )->a( n = `id`            v = `myPopover`
            )->a( n = `title`         v = client->_bind( name )
            )->a( n = `contentHeight` v = `20em`
            )->a( n = `placement`     v = `Right`

            )->tag( `Image`
                )->a( n = `src`          v = client->_bind( productpicurl )
                )->a( n = `width`        v = `18em`
                )->a( n = `densityAware` v = `false` ).

    client->popover_display( xml   = popover->stringify( )
                             by_id = client->get_event_arg( ) ).

  ENDMETHOD.


  METHOD popover_list_display.

    DATA popover TYPE REF TO z2ui5_cl_ui5_view_builder.
    popover = z2ui5_cl_ui5_view_builder=>factory( ).

    popover->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Popover`
            )->a( n = `id`        v = `myListPopover`
            )->a( n = `title`     v = `Products`
            )->a( n = `placement` v = `Left`

            )->ele( `List`
                )->a( n = `id`    v = `list`
                )->a( n = `items` v = client->_bind( t_products )

                )->ele( `items`
                    )->tag( `StandardListItem`
                        )->a( n = `title`            v = `{NAME}`
                        )->a( n = `description`      v = `{PRODUCTID}`
                        )->a( n = `type`             v = `Active`
                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                        )->a( n = `iconDensityAware` v = `false`
                        )->a( n = `iconInset`        v = `false` ).

    client->popover_display( xml   = popover->stringify( )
                             by_id = client->get_event_arg( ) ).

  ENDMETHOD.


  METHOD popover_inner_display.

    DATA popover TYPE REF TO z2ui5_cl_ui5_view_builder.
    popover = z2ui5_cl_ui5_view_builder=>factory( ).

    popover->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Popover`
            )->a( n = `id`        v = `myInnerPopover`
            )->a( n = `placement` v = `Left`

            )->ele( `List`
                )->a( n = `id`    v = `inner-List`
                )->a( n = `items` v = client->_bind( t_products )

                )->ele( `items`
                    )->tag( `StandardListItem`
                        )->a( n = `title`            v = `{NAME}`
                        )->a( n = `description`      v = `{PRODUCTID}`
                        )->a( n = `type`             v = `Active`
                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                        )->a( n = `iconDensityAware` v = `false`
                        )->a( n = `iconInset`        v = `false` ).

    client->popover_display( xml   = popover->stringify( )
                             by_id = client->get_event_arg( ) ).

  ENDMETHOD.


  METHOD model_init.
    DATA temp5 TYPE z2ui5_cl_smpc_app_285=>ty_t_product.
    DATA temp6 LIKE LINE OF temp5.

    " the popovers' bindElement( '/ProductCollection/0' ) record, seeded at the
    " model root (sap/ui/demo/mock/products.json, first row)
    name          = `Notebook Basic 15`.
    productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.

    
    CLEAR temp5.
    
    temp6-name = `Notebook Basic 15`.
    temp6-productid = `HT-1000`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 17`.
    temp6-productid = `HT-1001`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 18`.
    temp6-productid = `HT-1002`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 19`.
    temp6-productid = `HT-1003`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault`.
    temp6-productid = `HT-1007`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Professional 15`.
    temp6-productid = `HT-1010`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Professional 17`.
    temp6-productid = `HT-1011`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault Net`.
    temp6-productid = `HT-1020`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault SAT`.
    temp6-productid = `HT-1021`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Comfort Easy`.
    temp6-productid = `HT-1022`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Comfort Senior`.
    temp6-productid = `HT-1023`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-I`.
    temp6-productid = `HT-1030`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-II`.
    temp6-productid = `HT-1031`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-III`.
    temp6-productid = `HT-1032`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Basic`.
    temp6-productid = `HT-1035`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Future`.
    temp6-productid = `HT-1036`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat XL`.
    temp6-productid = `HT-1037`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Professional Eco`.
    temp6-productid = `HT-1040`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Basic`.
    temp6-productid = `HT-1041`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Allround`.
    temp6-productid = `HT-1042`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Super Color`.
    temp6-productid = `HT-1050`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Mobile`.
    temp6-productid = `HT-1051`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Super Highspeed`.
    temp6-productid = `HT-1052`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Multi Print`.
    temp6-productid = `HT-1055`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Multi Color`.
    temp6-productid = `HT-1056`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cordless Mouse`.
    temp6-productid = `HT-1060`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Speed Mouse`.
    temp6-productid = `HT-1061`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Track Mouse`.
    temp6-productid = `HT-1062`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergonomic Keyboard`.
    temp6-productid = `HT-1063`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Internet Keyboard`.
    temp6-productid = `HT-1064`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Media Keyboard`.
    temp6-productid = `HT-1065`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Mousepad`.
    temp6-productid = `HT-1066`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Mousepad`.
    temp6-productid = `HT-1067`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Designer Mousepad`.
    temp6-productid = `HT-1068`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Universal card reader`.
    temp6-productid = `HT-1069`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Proctra X`.
    temp6-productid = `HT-1070`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gladiator MX`.
    temp6-productid = `HT-1071`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Hurricane GX`.
    temp6-productid = `HT-1072`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Hurricane GX/LN`.
    temp6-productid = `HT-1073`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Photo Scan`.
    temp6-productid = `HT-1080`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Scan`.
    temp6-productid = `HT-1081`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Jet Scan Professional`.
    temp6-productid = `HT-1082`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Jet Scan Professional`.
    temp6-productid = `HT-1083`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Copymaster`.
    temp6-productid = `HT-1085`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Surround Sound`.
    temp6-productid = `HT-1090`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Blaster Extreme`.
    temp6-productid = `HT-1091`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Sound Booster`.
    temp6-productid = `HT-1092`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound 5.1 Wireless`.
    temp6-productid = `HT-1095`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound 5.1`.
    temp6-productid = `HT-1096`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound Stereo`.
    temp6-productid = `HT-1097`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Office`.
    temp6-productid = `HT-1100`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Design`.
    temp6-productid = `HT-1101`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Network`.
    temp6-productid = `HT-1102`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Multimedia`.
    temp6-productid = `HT-1103`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Games`.
    temp6-productid = `HT-1104`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Internet Antivirus`.
    temp6-productid = `HT-1105`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Firewall`.
    temp6-productid = `HT-1106`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Money`.
    temp6-productid = `HT-1107`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `PC Lock`.
    temp6-productid = `HT-1110`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Lock`.
    temp6-productid = `HT-1111`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Web cam reality`.
    temp6-productid = `HT-1112`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Screen clean`.
    temp6-productid = `HT-1113`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Fabric bag professional`.
    temp6-productid = `HT-1114`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router`.
    temp6-productid = `HT-1115`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router / Repeater`.
    temp6-productid = `HT-1116`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router / Repeater and Print Server`.
    temp6-productid = `HT-1117`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `USB Stick`.
    temp6-productid = `HT-1118`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Travel Adapter`.
    temp6-productid = `HT-1119`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cordless Bluetooth Keyboard, english international`.
    temp6-productid = `HT-1120`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat XXL`.
    temp6-productid = `HT-1137`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Pocket Mouse`.
    temp6-productid = `HT-1138`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `PC Power Station`.
    temp6-productid = `HT-1210`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Astro Laptop 1516`.
    temp6-productid = `HT-1251`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Astro Phone 6`.
    temp6-productid = `HT-1252`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Benda Laptop 1408`.
    temp6-productid = `HT-1253`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Bending Screen 21HD`.
    temp6-productid = `HT-1254`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Broad Screen 22HD`.
    temp6-productid = `HT-1255`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cerdik Phone 7`.
    temp6-productid = `HT-1256`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cepat Tablet 10.5`.
    temp6-productid = `HT-1257`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cepat Tablet 8`.
    temp6-productid = `HT-1258`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Basic`.
    temp6-productid = `HT-1500`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Professional`.
    temp6-productid = `HT-1501`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Power Pro`.
    temp6-productid = `HT-1502`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Family PC Basic`.
    temp6-productid = `HT-1600`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Family PC Pro`.
    temp6-productid = `HT-1601`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gaming Monster`.
    temp6-productid = `HT-1602`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gaming Monster Pro`.
    temp6-productid = `HT-1603`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `7" Widescreen Portable DVD Player w MP3`.
    temp6-productid = `HT-2000`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `10" Portable DVD player`.
    temp6-productid = `HT-2001`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Portable DVD Player with 9" LCD Monitor`.
    temp6-productid = `HT-2002`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `CD/DVD case: 264 sleeves`.
    temp6-productid = `HT-2025`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Audio/Video Cable Kit - 4m`.
    temp6-productid = `HT-2026`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Removable CD/DVD Laser Labels`.
    temp6-productid = `HT-2027`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-1`.
    temp6-productid = `HT-6100`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-2`.
    temp6-productid = `HT-6101`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-3`.
    temp6-productid = `HT-6102`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Play Movie`.
    temp6-productid = `HT-6110`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Record Movie`.
    temp6-productid = `HT-6111`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelo MusicStick`.
    temp6-productid = `HT-6120`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelo Jog-Mate`.
    temp6-productid = `HT-6121`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Pro Player 40`.
    temp6-productid = `HT-6122`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Pro Player 80`.
    temp6-productid = `HT-6123`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD32`.
    temp6-productid = `HT-6130`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD37`.
    temp6-productid = `HT-6131`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD41`.
    temp6-productid = `HT-6132`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Copperberry`.
    temp6-productid = `HT-7000`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Silverberry`.
    temp6-productid = `HT-7010`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Goldberry`.
    temp6-productid = `HT-7020`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Platinberry`.
    temp6-productid = `HT-7030`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I4000`.
    temp6-productid = `HT-8000`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I6300c`.
    temp6-productid = `HT-8001`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I9100`.
    temp6-productid = `HT-8002`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I9800`.
    temp6-productid = `HT-8003`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Leather Case`.
    temp6-productid = `HT-9991`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Alpha`.
    temp6-productid = `HT-9992`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Mini Tablet`.
    temp6-productid = `HT-9993`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Camcorder View`.
    temp6-productid = `HT-9994`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Tablet Pouch`.
    temp6-productid = `HT-9995`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Tablet Pouch`.
    temp6-productid = `HT-9996`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `e-Book Reader ReadMe`.
    temp6-productid = `HT-9997`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Beta`.
    temp6-productid = `HT-9998`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Maxi Tablet`.
    temp6-productid = `HT-9999`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flyer`.
    temp6-productid = `PF-1000`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    INSERT temp6 INTO TABLE temp5.
    t_products = temp5.

  ENDMETHOD.

ENDCLASS.
