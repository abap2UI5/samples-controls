" @keywords multiinput multi input sap.m multiinputvaluehelp selectdialog standardlistitem label token
" @summary MultiInput that includes a SelectDialog as a value help dialog
CLASS z2ui5_cl_smpc_app_290 DEFINITION PUBLIC.

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
    TYPES:
      BEGIN OF ty_s_token,
        text TYPE string,
      END OF ty_s_token.
    TYPES ty_t_token TYPE STANDARD TABLE OF ty_s_token WITH DEFAULT KEY.

    DATA t_products TYPE ty_t_product.
    DATA t_tokens   TYPE ty_t_token.
    DATA value      TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_290 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `valueHelpDialog` INTO TABLE temp1.
    INSERT `items` INTO TABLE temp1.
    INSERT `filter` INTO TABLE temp1.
    INSERT `NAME` INTO TABLE temp1.
    INSERT `Contains` INTO TABLE temp1.
    INSERT `${$parameters>/value}` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        " the value help of Dialog.fragment.xml, declared as a dependent and
        " opened by id - the fragment root itself has no counterpart
        )->ele( n = `dependents` ns = `mvc`

            )->ele( `SelectDialog`
                )->a( n = `id`          v = `valueHelpDialog`
                )->a( n = `title`       v = `Products`
                )->a( n = `items`       v = client->_bind( t_products )
                )->a( n = `search`      v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                      t_arg = temp1 )
                )->a( n = `confirm`     v = client->_event( `VALUE_HELP_CLOSE` )
                )->a( n = `cancel`      v = client->_event( `VALUE_HELP_CLOSE` )
                )->a( n = `multiSelect` v = `true`

                )->tag( `StandardListItem`
                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `description`      v = `{PRODUCTID}`
                    " added: the confirmed selection is read server-side from the
                    " rows instead of from the event's selectedItems controls
                    )->a( n = `selected`         v = `{SELECTED}`

            )->end(
        )->end(

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Enter a search term, e.g. “Notebook”, and add matching products as tokens`
                )->a( n = `width`    v = `100%`
                )->a( n = `labelFor` v = `multiInput`

            )->ele( `MultiInput`
                )->a( n = `width`            v = `40%`
                )->a( n = `id`               v = `multiInput`
                )->a( n = `value`            v = client->_bind( value )
                )->a( n = `tokens`           v = client->_bind( t_tokens )
                )->a( n = `suggestionItems`  v = |\{ path: '{ client->_bind( val = t_products path = abap_true ) }', sorter: \{ path: 'NAME' \} \}|
                )->a( n = `valueHelpRequest` v = client->_event( `VALUE_HELP` )

                )->ele( `tokens`
                    )->tag( `Token`
                        )->a( n = `text` v = `{TEXT}`

                )->end(

                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{PRODUCTID}`
                    )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string_table.
        DATA temp5 TYPE string_table.
        DATA temp7 LIKE LINE OF t_products.
        DATA product LIKE REF TO temp7.
          DATA temp8 TYPE z2ui5_cl_smpc_app_290=>ty_t_token.
          DATA temp9 LIKE LINE OF temp8.

    CASE client->get_event( ).

      WHEN `VALUE_HELP`.
        " handleValueHelp: filter the dialog binding by what was typed, then
        " open it with that same value in its search field
        
        CLEAR temp3.
        INSERT `valueHelpDialog` INTO TABLE temp3.
        INSERT `items` INTO TABLE temp3.
        INSERT `filter` INTO TABLE temp3.
        INSERT `NAME` INTO TABLE temp3.
        INSERT `Contains` INTO TABLE temp3.
        INSERT value INTO TABLE temp3.
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = temp3 ).
        
        CLEAR temp5.
        INSERT `valueHelpDialog` INTO TABLE temp5.
        INSERT `open` INTO TABLE temp5.
        INSERT value INTO TABLE temp5.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp5 ).

      WHEN `VALUE_HELP_CLOSE`.
        " _handleValueHelpClose adds one Token per selected item; the selection
        " arrives in the rows themselves, so the tokens are built from them
        
        
        LOOP AT t_products REFERENCE INTO product WHERE selected = abap_true.
          
          CLEAR temp8.
          temp8 = t_tokens.
          
          temp9-text = product->name.
          INSERT temp9 INTO TABLE temp8.
          t_tokens = temp8.
          product->selected = abap_false.
        ENDLOOP.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " the shared demo ProductCollection (sap/ui/demo/mock/products.json) the
    " Component loads; the columns the view binds
    DATA temp10 TYPE z2ui5_cl_smpc_app_290=>ty_t_product.
    DATA temp11 LIKE LINE OF temp10.
    CLEAR temp10.
    
    temp11-name = `Notebook Basic 15`.
    temp11-productid = `HT-1000`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Notebook Basic 17`.
    temp11-productid = `HT-1001`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Notebook Basic 18`.
    temp11-productid = `HT-1002`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Notebook Basic 19`.
    temp11-productid = `HT-1003`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelO Vault`.
    temp11-productid = `HT-1007`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Notebook Professional 15`.
    temp11-productid = `HT-1010`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Notebook Professional 17`.
    temp11-productid = `HT-1011`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelO Vault Net`.
    temp11-productid = `HT-1020`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelO Vault SAT`.
    temp11-productid = `HT-1021`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Comfort Easy`.
    temp11-productid = `HT-1022`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Comfort Senior`.
    temp11-productid = `HT-1023`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Ergo Screen E-I`.
    temp11-productid = `HT-1030`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Ergo Screen E-II`.
    temp11-productid = `HT-1031`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Ergo Screen E-III`.
    temp11-productid = `HT-1032`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat Basic`.
    temp11-productid = `HT-1035`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat Future`.
    temp11-productid = `HT-1036`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat XL`.
    temp11-productid = `HT-1037`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Laser Professional Eco`.
    temp11-productid = `HT-1040`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Laser Basic`.
    temp11-productid = `HT-1041`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Laser Allround`.
    temp11-productid = `HT-1042`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Ultra Jet Super Color`.
    temp11-productid = `HT-1050`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Ultra Jet Mobile`.
    temp11-productid = `HT-1051`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Ultra Jet Super Highspeed`.
    temp11-productid = `HT-1052`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Multi Print`.
    temp11-productid = `HT-1055`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Multi Color`.
    temp11-productid = `HT-1056`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Cordless Mouse`.
    temp11-productid = `HT-1060`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Speed Mouse`.
    temp11-productid = `HT-1061`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Track Mouse`.
    temp11-productid = `HT-1062`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Ergonomic Keyboard`.
    temp11-productid = `HT-1063`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Internet Keyboard`.
    temp11-productid = `HT-1064`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Media Keyboard`.
    temp11-productid = `HT-1065`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Mousepad`.
    temp11-productid = `HT-1066`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Ergo Mousepad`.
    temp11-productid = `HT-1067`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Designer Mousepad`.
    temp11-productid = `HT-1068`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Universal card reader`.
    temp11-productid = `HT-1069`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Proctra X`.
    temp11-productid = `HT-1070`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Gladiator MX`.
    temp11-productid = `HT-1071`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Hurricane GX`.
    temp11-productid = `HT-1072`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Hurricane GX/LN`.
    temp11-productid = `HT-1073`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Photo Scan`.
    temp11-productid = `HT-1080`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Power Scan`.
    temp11-productid = `HT-1081`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Jet Scan Professional`.
    temp11-productid = `HT-1082`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Jet Scan Professional`.
    temp11-productid = `HT-1083`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Copymaster`.
    temp11-productid = `HT-1085`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Surround Sound`.
    temp11-productid = `HT-1090`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Blaster Extreme`.
    temp11-productid = `HT-1091`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Sound Booster`.
    temp11-productid = `HT-1092`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Lovely Sound 5.1 Wireless`.
    temp11-productid = `HT-1095`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Lovely Sound 5.1`.
    temp11-productid = `HT-1096`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Lovely Sound Stereo`.
    temp11-productid = `HT-1097`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smart Office`.
    temp11-productid = `HT-1100`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smart Design`.
    temp11-productid = `HT-1101`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smart Network`.
    temp11-productid = `HT-1102`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smart Multimedia`.
    temp11-productid = `HT-1103`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smart Games`.
    temp11-productid = `HT-1104`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smart Internet Antivirus`.
    temp11-productid = `HT-1105`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smart Firewall`.
    temp11-productid = `HT-1106`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smart Money`.
    temp11-productid = `HT-1107`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `PC Lock`.
    temp11-productid = `HT-1110`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Notebook Lock`.
    temp11-productid = `HT-1111`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Web cam reality`.
    temp11-productid = `HT-1112`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Screen clean`.
    temp11-productid = `HT-1113`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Fabric bag professional`.
    temp11-productid = `HT-1114`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Wireless DSL Router`.
    temp11-productid = `HT-1115`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Wireless DSL Router / Repeater`.
    temp11-productid = `HT-1116`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Wireless DSL Router / Repeater and Print Server`.
    temp11-productid = `HT-1117`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `USB Stick`.
    temp11-productid = `HT-1118`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Travel Adapter`.
    temp11-productid = `HT-1119`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Cordless Bluetooth Keyboard, english international`.
    temp11-productid = `HT-1120`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat XXL`.
    temp11-productid = `HT-1137`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Pocket Mouse`.
    temp11-productid = `HT-1138`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `PC Power Station`.
    temp11-productid = `HT-1210`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Astro Laptop 1516`.
    temp11-productid = `HT-1251`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Astro Phone 6`.
    temp11-productid = `HT-1252`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Benda Laptop 1408`.
    temp11-productid = `HT-1253`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Bending Screen 21HD`.
    temp11-productid = `HT-1254`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Broad Screen 22HD`.
    temp11-productid = `HT-1255`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Cerdik Phone 7`.
    temp11-productid = `HT-1256`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Cepat Tablet 10.5`.
    temp11-productid = `HT-1257`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Cepat Tablet 8`.
    temp11-productid = `HT-1258`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Server Basic`.
    temp11-productid = `HT-1500`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Server Professional`.
    temp11-productid = `HT-1501`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Server Power Pro`.
    temp11-productid = `HT-1502`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Family PC Basic`.
    temp11-productid = `HT-1600`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Family PC Pro`.
    temp11-productid = `HT-1601`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Gaming Monster`.
    temp11-productid = `HT-1602`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Gaming Monster Pro`.
    temp11-productid = `HT-1603`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `7" Widescreen Portable DVD Player w MP3`.
    temp11-productid = `HT-2000`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `10" Portable DVD player`.
    temp11-productid = `HT-2001`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Portable DVD Player with 9" LCD Monitor`.
    temp11-productid = `HT-2002`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `CD/DVD case: 264 sleeves`.
    temp11-productid = `HT-2025`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Audio/Video Cable Kit - 4m`.
    temp11-productid = `HT-2026`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Removable CD/DVD Laser Labels`.
    temp11-productid = `HT-2027`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Beam Breaker B-1`.
    temp11-productid = `HT-6100`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Beam Breaker B-2`.
    temp11-productid = `HT-6101`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Beam Breaker B-3`.
    temp11-productid = `HT-6102`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Play Movie`.
    temp11-productid = `HT-6110`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Record Movie`.
    temp11-productid = `HT-6111`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelo MusicStick`.
    temp11-productid = `HT-6120`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelo Jog-Mate`.
    temp11-productid = `HT-6121`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Power Pro Player 40`.
    temp11-productid = `HT-6122`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Power Pro Player 80`.
    temp11-productid = `HT-6123`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat Watch HD32`.
    temp11-productid = `HT-6130`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat Watch HD37`.
    temp11-productid = `HT-6131`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat Watch HD41`.
    temp11-productid = `HT-6132`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Copperberry`.
    temp11-productid = `HT-7000`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Silverberry`.
    temp11-productid = `HT-7010`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Goldberry`.
    temp11-productid = `HT-7020`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Platinberry`.
    temp11-productid = `HT-7030`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelO FlexTop I4000`.
    temp11-productid = `HT-8000`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelO FlexTop I6300c`.
    temp11-productid = `HT-8001`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelO FlexTop I9100`.
    temp11-productid = `HT-8002`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `ITelO FlexTop I9800`.
    temp11-productid = `HT-8003`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smartphone Leather Case`.
    temp11-productid = `HT-9991`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smartphone Alpha`.
    temp11-productid = `HT-9992`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Mini Tablet`.
    temp11-productid = `HT-9993`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Camcorder View`.
    temp11-productid = `HT-9994`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Tablet Pouch`.
    temp11-productid = `HT-9995`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Tablet Pouch`.
    temp11-productid = `HT-9996`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `e-Book Reader ReadMe`.
    temp11-productid = `HT-9997`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smartphone Beta`.
    temp11-productid = `HT-9998`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Maxi Tablet`.
    temp11-productid = `HT-9999`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flyer`.
    temp11-productid = `PF-1000`.
    temp11-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    INSERT temp11 INTO TABLE temp10.
    t_products = temp10.

  ENDMETHOD.

ENDCLASS.
