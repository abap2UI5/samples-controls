" @keywords multicombobox multi combo box sap.m multicomboboxselectall verticallayout item
" @summary MultiComboBox with enabled Select All feature inside suggestions.
" @origin sap.m.sample.MultiComboBoxSelectAll - https://sdk.openui5.org/entity/sap.m.MultiComboBox/sample/sap.m.sample.MultiComboBoxSelectAll (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_281 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid TYPE string,
        name      TYPE string,
      END OF ty_s_product.
    DATA t_products      TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
    DATA t_selected_keys TYPE string_table.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_281 IMPLEMENTATION.

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
    INSERT `${$parameters>/changedItem}.getText()` INTO TABLE temp1.
    INSERT `${$parameters>/selected}` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `height`     v = `100%`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->ele( `MultiComboBox`
                )->a( n = `selectionChange` v = client->_event( val = `SELECTION_CHANGE` t_arg = temp1 )
                )->a( n = `selectionFinish` v = client->_event( `SELECTION_FINISH` )
                )->a( n = `showSelectAll`   v = `true`
                )->a( n = `width`           v = `350px`
                )->a( n = `items`           v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|
                " added binding: the selected keys must reach the backend for the
                " selectionFinish text (the original reads getSelectedItems in the controller)
                )->a( n = `selectedKeys`    v = client->_bind( t_selected_keys )

                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{PRODUCTID}`
                    )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string_table.
        DATA temp1 TYPE string.
        DATA temp8 LIKE LINE OF temp3.
        DATA names TYPE string.
        DATA key LIKE LINE OF t_selected_keys.
          DATA temp5 TYPE string.
          DATA temp6 TYPE z2ui5_cl_smpc_app_281=>ty_s_product.
          DATA temp2 TYPE string.
        DATA temp7 TYPE string_table.
        DATA temp4 LIKE LINE OF temp7.

    CASE client->get_event( ).

      WHEN `SELECTION_CHANGE`.

        " width is a sap.m.MessageToast option - set on the control, in the
        " option object of the global call
        
        CLEAR temp3.
        INSERT `MESSAGE_TOAST` INTO TABLE temp3.
        INSERT `show` INTO TABLE temp3.
        
        IF client->get_event_arg( 2 ) = abap_true.
          temp1 = `Selected`.
        ELSE.
          temp1 = `Deselected`.
        ENDIF.
        
        temp8 = |Event 'selectionChange': { temp1 } '{ client->get_event_arg( ) }'|.
        INSERT temp8 INTO TABLE temp3.
        INSERT `{"width":"auto"}` INTO TABLE temp3.
        client->follow_up_action(
            val   = client->cs_event-control_global
            t_arg = temp3 ).

      WHEN `SELECTION_FINISH`.

        
        names = ``.
        
        LOOP AT t_selected_keys INTO key.
          
          CLEAR temp5.
          
          READ TABLE t_products INTO temp6 WITH KEY productid = key.
          IF sy-subrc = 0.
            temp5 = temp6-name.
          ENDIF.
          
          IF sy-tabix > 1.
            temp2 = `,`.
          ELSE.
            CLEAR temp2.
          ENDIF.
          names = |{ names }{ temp2 }'{ temp5 }'|.
        ENDLOOP.

        " width is a sap.m.MessageToast option - set on the control, in the
        " option object of the global call
        
        CLEAR temp7.
        INSERT `MESSAGE_TOAST` INTO TABLE temp7.
        INSERT `show` INTO TABLE temp7.
        
        temp4 = |Event 'selectionFinished': [{ names }]|.
        INSERT temp4 INTO TABLE temp7.
        INSERT `{"width":"auto"}` INTO TABLE temp7.
        client->follow_up_action(
            val   = client->cs_event-control_global
            t_arg = temp7 ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " /ProductCollection of sap/ui/demo/mock/products.json - the two bound keys of every row
    DATA temp9 LIKE t_products.
    DATA temp10 LIKE LINE OF temp9.
    CLEAR temp9.
    
    temp10-productid = `HT-1000`.
    temp10-name = `Notebook Basic 15`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1001`.
    temp10-name = `Notebook Basic 17`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1002`.
    temp10-name = `Notebook Basic 18`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1003`.
    temp10-name = `Notebook Basic 19`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1007`.
    temp10-name = `ITelO Vault`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1010`.
    temp10-name = `Notebook Professional 15`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1011`.
    temp10-name = `Notebook Professional 17`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1020`.
    temp10-name = `ITelO Vault Net`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1021`.
    temp10-name = `ITelO Vault SAT`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1022`.
    temp10-name = `Comfort Easy`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1023`.
    temp10-name = `Comfort Senior`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1030`.
    temp10-name = `Ergo Screen E-I`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1031`.
    temp10-name = `Ergo Screen E-II`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1032`.
    temp10-name = `Ergo Screen E-III`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1035`.
    temp10-name = `Flat Basic`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1036`.
    temp10-name = `Flat Future`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1037`.
    temp10-name = `Flat XL`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1040`.
    temp10-name = `Laser Professional Eco`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1041`.
    temp10-name = `Laser Basic`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1042`.
    temp10-name = `Laser Allround`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1050`.
    temp10-name = `Ultra Jet Super Color`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1051`.
    temp10-name = `Ultra Jet Mobile`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1052`.
    temp10-name = `Ultra Jet Super Highspeed`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1055`.
    temp10-name = `Multi Print`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1056`.
    temp10-name = `Multi Color`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1060`.
    temp10-name = `Cordless Mouse`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1061`.
    temp10-name = `Speed Mouse`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1062`.
    temp10-name = `Track Mouse`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1063`.
    temp10-name = `Ergonomic Keyboard`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1064`.
    temp10-name = `Internet Keyboard`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1065`.
    temp10-name = `Media Keyboard`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1066`.
    temp10-name = `Mousepad`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1067`.
    temp10-name = `Ergo Mousepad`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1068`.
    temp10-name = `Designer Mousepad`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1069`.
    temp10-name = `Universal card reader`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1070`.
    temp10-name = `Proctra X`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1071`.
    temp10-name = `Gladiator MX`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1072`.
    temp10-name = `Hurricane GX`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1073`.
    temp10-name = `Hurricane GX/LN`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1080`.
    temp10-name = `Photo Scan`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1081`.
    temp10-name = `Power Scan`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1082`.
    temp10-name = `Jet Scan Professional`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1083`.
    temp10-name = `Jet Scan Professional`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1085`.
    temp10-name = `Copymaster`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1090`.
    temp10-name = `Surround Sound`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1091`.
    temp10-name = `Blaster Extreme`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1092`.
    temp10-name = `Sound Booster`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1095`.
    temp10-name = `Lovely Sound 5.1 Wireless`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1096`.
    temp10-name = `Lovely Sound 5.1`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1097`.
    temp10-name = `Lovely Sound Stereo`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1100`.
    temp10-name = `Smart Office`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1101`.
    temp10-name = `Smart Design`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1102`.
    temp10-name = `Smart Network`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1103`.
    temp10-name = `Smart Multimedia`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1104`.
    temp10-name = `Smart Games`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1105`.
    temp10-name = `Smart Internet Antivirus`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1106`.
    temp10-name = `Smart Firewall`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1107`.
    temp10-name = `Smart Money`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1110`.
    temp10-name = `PC Lock`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1111`.
    temp10-name = `Notebook Lock`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1112`.
    temp10-name = `Web cam reality`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1113`.
    temp10-name = `Screen clean`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1114`.
    temp10-name = `Fabric bag professional`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1115`.
    temp10-name = `Wireless DSL Router`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1116`.
    temp10-name = `Wireless DSL Router / Repeater`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1117`.
    temp10-name = `Wireless DSL Router / Repeater and Print Server`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1118`.
    temp10-name = `USB Stick`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1119`.
    temp10-name = `Travel Adapter`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1120`.
    temp10-name = `Cordless Bluetooth Keyboard, english international`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1137`.
    temp10-name = `Flat XXL`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1138`.
    temp10-name = `Pocket Mouse`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1210`.
    temp10-name = `PC Power Station`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1251`.
    temp10-name = `Astro Laptop 1516`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1252`.
    temp10-name = `Astro Phone 6`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1253`.
    temp10-name = `Benda Laptop 1408`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1254`.
    temp10-name = `Bending Screen 21HD`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1255`.
    temp10-name = `Broad Screen 22HD`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1256`.
    temp10-name = `Cerdik Phone 7`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1257`.
    temp10-name = `Cepat Tablet 10.5`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1258`.
    temp10-name = `Cepat Tablet 8`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1500`.
    temp10-name = `Server Basic`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1501`.
    temp10-name = `Server Professional`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1502`.
    temp10-name = `Server Power Pro`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1600`.
    temp10-name = `Family PC Basic`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1601`.
    temp10-name = `Family PC Pro`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1602`.
    temp10-name = `Gaming Monster`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-1603`.
    temp10-name = `Gaming Monster Pro`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-2000`.
    temp10-name = `7" Widescreen Portable DVD Player w MP3`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-2001`.
    temp10-name = `10" Portable DVD player`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-2002`.
    temp10-name = `Portable DVD Player with 9" LCD Monitor`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-2025`.
    temp10-name = `CD/DVD case: 264 sleeves`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-2026`.
    temp10-name = `Audio/Video Cable Kit - 4m`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-2027`.
    temp10-name = `Removable CD/DVD Laser Labels`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6100`.
    temp10-name = `Beam Breaker B-1`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6101`.
    temp10-name = `Beam Breaker B-2`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6102`.
    temp10-name = `Beam Breaker B-3`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6110`.
    temp10-name = `Play Movie`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6111`.
    temp10-name = `Record Movie`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6120`.
    temp10-name = `ITelo MusicStick`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6121`.
    temp10-name = `ITelo Jog-Mate`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6122`.
    temp10-name = `Power Pro Player 40`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6123`.
    temp10-name = `Power Pro Player 80`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6130`.
    temp10-name = `Flat Watch HD32`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6131`.
    temp10-name = `Flat Watch HD37`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-6132`.
    temp10-name = `Flat Watch HD41`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-7000`.
    temp10-name = `Copperberry`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-7010`.
    temp10-name = `Silverberry`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-7020`.
    temp10-name = `Goldberry`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-7030`.
    temp10-name = `Platinberry`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-8000`.
    temp10-name = `ITelO FlexTop I4000`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-8001`.
    temp10-name = `ITelO FlexTop I6300c`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-8002`.
    temp10-name = `ITelO FlexTop I9100`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-8003`.
    temp10-name = `ITelO FlexTop I9800`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9991`.
    temp10-name = `Smartphone Leather Case`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9992`.
    temp10-name = `Smartphone Alpha`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9993`.
    temp10-name = `Mini Tablet`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9994`.
    temp10-name = `Camcorder View`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9995`.
    temp10-name = `Tablet Pouch`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9996`.
    temp10-name = `Tablet Pouch`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9997`.
    temp10-name = `e-Book Reader ReadMe`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9998`.
    temp10-name = `Smartphone Beta`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `HT-9999`.
    temp10-name = `Maxi Tablet`.
    INSERT temp10 INTO TABLE temp9.
    temp10-productid = `PF-1000`.
    temp10-name = `Flyer`.
    INSERT temp10 INTO TABLE temp9.
    t_products = temp9.

  ENDMETHOD.

ENDCLASS.
