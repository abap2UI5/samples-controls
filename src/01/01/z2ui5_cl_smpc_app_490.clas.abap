" @keywords multicombobox multi combo box sap.m verticallayout item
" @summary Choose one or more out of multiple options with the MultiComboBox control.
" @origin sap.m.sample.MultiComboBox - https://sdk.openui5.org/entity/sap.m.MultiComboBox/sample/sap.m.sample.MultiComboBox (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_490 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid TYPE string,
        name      TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    DATA t_products     TYPE ty_t_product.
    DATA t_selected_key TYPE string_table.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_490 IMPLEMENTATION.

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
    INSERT `MESSAGE_TOAST` INTO TABLE temp1.
    INSERT `show` INTO TABLE temp1.
    INSERT `Event 'selectionChange': {0?Selected:Deselected} '{1}'` INTO TABLE temp1.
    INSERT `${$parameters>/selected}` INTO TABLE temp1.
    INSERT `${$parameters>/changedItem}.getText()` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->ele( `MultiComboBox`
                " handleSelectionChange toasts the changed item and its new state -
                " composed on the client from the two event parameters
                )->a( n = `selectionChange` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                          t_arg = temp1 )
                " handleSelectionFinish lists every selected item; a UI5 expression has
                " no loop, so the selection travels as the bound selectedKeys and ABAP
                " builds the same line
                )->a( n = `selectionFinish` v = client->_event( `SELECTION_FINISH` )
                )->a( n = `selectedKeys`    v = client->_bind( t_selected_key )
                )->a( n = `width`           v = `350px`
                )->a( n = `items`           v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{PRODUCTID}`
                    )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
      DATA list TYPE string.
      DATA key LIKE LINE OF t_selected_key.
        DATA temp3 TYPE string.
        DATA temp4 TYPE z2ui5_cl_smpc_app_490=>ty_s_product.
      DATA temp5 TYPE string_table.
      DATA temp1 LIKE LINE OF temp5.

    IF client->get_event( ) = `SELECTION_FINISH`.

      " "Event 'selectionFinished': ['A','B']" - the texts of the selected keys in
      " SELECTION order: the original reads the selectedItems event parameter, which
      " MultiComboBox fills by addAssociation per pick, so looping the bound keys
      " (not the product table) is what reproduces it - the app-281 form
      
      list = ``.
      
      LOOP AT t_selected_key INTO key.
        IF list IS NOT INITIAL.
          list = list && `,`.
        ENDIF.
        
        CLEAR temp3.
        
        READ TABLE t_products INTO temp4 WITH KEY productid = key.
        IF sy-subrc = 0.
          temp3 = temp4-name.
        ENDIF.
        list = list && |'{ temp3 }'|.
      ENDLOOP.

      " width is a sap.m.MessageToast option - set on the control, in the
      " option object of the global call
      
      CLEAR temp5.
      INSERT `MESSAGE_TOAST` INTO TABLE temp5.
      INSERT `show` INTO TABLE temp5.
      
      temp1 = |Event 'selectionFinished': [{ list }]|.
      INSERT temp1 INTO TABLE temp5.
      INSERT `{"width":"auto"}` INTO TABLE temp5.
      client->follow_up_action(
          val   = client->cs_event-control_global
          t_arg = temp5 ).

    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    DATA temp7 TYPE z2ui5_cl_smpc_app_490=>ty_t_product.
    DATA temp8 LIKE LINE OF temp7.
    CLEAR temp7.
    
    temp8-productid = `HT-1000`.
    temp8-name = `Notebook Basic 15`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1001`.
    temp8-name = `Notebook Basic 17`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1002`.
    temp8-name = `Notebook Basic 18`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1003`.
    temp8-name = `Notebook Basic 19`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1007`.
    temp8-name = `ITelO Vault`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1010`.
    temp8-name = `Notebook Professional 15`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1011`.
    temp8-name = `Notebook Professional 17`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1020`.
    temp8-name = `ITelO Vault Net`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1021`.
    temp8-name = `ITelO Vault SAT`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1022`.
    temp8-name = `Comfort Easy`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1023`.
    temp8-name = `Comfort Senior`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1030`.
    temp8-name = `Ergo Screen E-I`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1031`.
    temp8-name = `Ergo Screen E-II`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1032`.
    temp8-name = `Ergo Screen E-III`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1035`.
    temp8-name = `Flat Basic`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1036`.
    temp8-name = `Flat Future`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1037`.
    temp8-name = `Flat XL`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1040`.
    temp8-name = `Laser Professional Eco`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1041`.
    temp8-name = `Laser Basic`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1042`.
    temp8-name = `Laser Allround`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1050`.
    temp8-name = `Ultra Jet Super Color`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1051`.
    temp8-name = `Ultra Jet Mobile`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1052`.
    temp8-name = `Ultra Jet Super Highspeed`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1055`.
    temp8-name = `Multi Print`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1056`.
    temp8-name = `Multi Color`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1060`.
    temp8-name = `Cordless Mouse`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1061`.
    temp8-name = `Speed Mouse`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1062`.
    temp8-name = `Track Mouse`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1063`.
    temp8-name = `Ergonomic Keyboard`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1064`.
    temp8-name = `Internet Keyboard`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1065`.
    temp8-name = `Media Keyboard`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1066`.
    temp8-name = `Mousepad`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1067`.
    temp8-name = `Ergo Mousepad`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1068`.
    temp8-name = `Designer Mousepad`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1069`.
    temp8-name = `Universal card reader`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1070`.
    temp8-name = `Proctra X`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1071`.
    temp8-name = `Gladiator MX`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1072`.
    temp8-name = `Hurricane GX`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1073`.
    temp8-name = `Hurricane GX/LN`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1080`.
    temp8-name = `Photo Scan`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1081`.
    temp8-name = `Power Scan`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1082`.
    temp8-name = `Jet Scan Professional`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1083`.
    temp8-name = `Jet Scan Professional`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1085`.
    temp8-name = `Copymaster`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1090`.
    temp8-name = `Surround Sound`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1091`.
    temp8-name = `Blaster Extreme`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1092`.
    temp8-name = `Sound Booster`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1095`.
    temp8-name = `Lovely Sound 5.1 Wireless`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1096`.
    temp8-name = `Lovely Sound 5.1`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1097`.
    temp8-name = `Lovely Sound Stereo`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1100`.
    temp8-name = `Smart Office`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1101`.
    temp8-name = `Smart Design`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1102`.
    temp8-name = `Smart Network`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1103`.
    temp8-name = `Smart Multimedia`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1104`.
    temp8-name = `Smart Games`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1105`.
    temp8-name = `Smart Internet Antivirus`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1106`.
    temp8-name = `Smart Firewall`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1107`.
    temp8-name = `Smart Money`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1110`.
    temp8-name = `PC Lock`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1111`.
    temp8-name = `Notebook Lock`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1112`.
    temp8-name = `Web cam reality`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1113`.
    temp8-name = `Screen clean`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1114`.
    temp8-name = `Fabric bag professional`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1115`.
    temp8-name = `Wireless DSL Router`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1116`.
    temp8-name = `Wireless DSL Router / Repeater`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1117`.
    temp8-name = `Wireless DSL Router / Repeater and Print Server`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1118`.
    temp8-name = `USB Stick`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1119`.
    temp8-name = `Travel Adapter`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1120`.
    temp8-name = `Cordless Bluetooth Keyboard, english international`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1137`.
    temp8-name = `Flat XXL`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1138`.
    temp8-name = `Pocket Mouse`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1210`.
    temp8-name = `PC Power Station`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1251`.
    temp8-name = `Astro Laptop 1516`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1252`.
    temp8-name = `Astro Phone 6`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1253`.
    temp8-name = `Benda Laptop 1408`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1254`.
    temp8-name = `Bending Screen 21HD`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1255`.
    temp8-name = `Broad Screen 22HD`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1256`.
    temp8-name = `Cerdik Phone 7`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1257`.
    temp8-name = `Cepat Tablet 10.5`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1258`.
    temp8-name = `Cepat Tablet 8`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1500`.
    temp8-name = `Server Basic`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1501`.
    temp8-name = `Server Professional`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1502`.
    temp8-name = `Server Power Pro`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1600`.
    temp8-name = `Family PC Basic`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1601`.
    temp8-name = `Family PC Pro`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1602`.
    temp8-name = `Gaming Monster`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-1603`.
    temp8-name = `Gaming Monster Pro`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-2000`.
    temp8-name = `7" Widescreen Portable DVD Player w MP3`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-2001`.
    temp8-name = `10" Portable DVD player`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-2002`.
    temp8-name = `Portable DVD Player with 9" LCD Monitor`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-2025`.
    temp8-name = `CD/DVD case: 264 sleeves`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-2026`.
    temp8-name = `Audio/Video Cable Kit - 4m`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-2027`.
    temp8-name = `Removable CD/DVD Laser Labels`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6100`.
    temp8-name = `Beam Breaker B-1`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6101`.
    temp8-name = `Beam Breaker B-2`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6102`.
    temp8-name = `Beam Breaker B-3`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6110`.
    temp8-name = `Play Movie`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6111`.
    temp8-name = `Record Movie`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6120`.
    temp8-name = `ITelo MusicStick`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6121`.
    temp8-name = `ITelo Jog-Mate`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6122`.
    temp8-name = `Power Pro Player 40`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6123`.
    temp8-name = `Power Pro Player 80`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6130`.
    temp8-name = `Flat Watch HD32`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6131`.
    temp8-name = `Flat Watch HD37`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-6132`.
    temp8-name = `Flat Watch HD41`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-7000`.
    temp8-name = `Copperberry`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-7010`.
    temp8-name = `Silverberry`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-7020`.
    temp8-name = `Goldberry`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-7030`.
    temp8-name = `Platinberry`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-8000`.
    temp8-name = `ITelO FlexTop I4000`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-8001`.
    temp8-name = `ITelO FlexTop I6300c`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-8002`.
    temp8-name = `ITelO FlexTop I9100`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-8003`.
    temp8-name = `ITelO FlexTop I9800`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9991`.
    temp8-name = `Smartphone Leather Case`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9992`.
    temp8-name = `Smartphone Alpha`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9993`.
    temp8-name = `Mini Tablet`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9994`.
    temp8-name = `Camcorder View`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9995`.
    temp8-name = `Tablet Pouch`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9996`.
    temp8-name = `Tablet Pouch`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9997`.
    temp8-name = `e-Book Reader ReadMe`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9998`.
    temp8-name = `Smartphone Beta`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `HT-9999`.
    temp8-name = `Maxi Tablet`.
    INSERT temp8 INTO TABLE temp7.
    temp8-productid = `PF-1000`.
    temp8-name = `Flyer`.
    INSERT temp8 INTO TABLE temp7.
    t_products = temp7.

  ENDMETHOD.

ENDCLASS.
