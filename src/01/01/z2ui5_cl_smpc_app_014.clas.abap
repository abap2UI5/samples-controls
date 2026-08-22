" @keywords customlistitem custom list item sap.m content hbox vbox link label dialog image
" @summary With the Custom List Item you can add any kind of content to lists.
CLASS z2ui5_cl_smpc_app_014 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        product_id      TYPE string,
        name            TYPE string,
        product_pic_url TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.
    METHODS popup_display_image
      IMPORTING
        pic_url TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_014 IMPLEMENTATION.

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
    INSERT `${PRODUCT_PIC_URL}` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `List`
            )->a( n = `headerText` v = `Custom Content`
            )->a( n = `mode`       v = `Delete`
            )->a( n = `items`      v = client->_bind( t_products )

            )->ele( `CustomListItem`
                )->ele( `HBox`
                    )->tag( n = `Icon` ns = `core`
                        )->a( n = `size`  v = `2rem`
                        )->a( n = `src`   v = `sap-icon://attachment-photo`
                        )->a( n = `class` v = `sapUiSmallMarginBegin sapUiSmallMarginTopBottom`

                    )->ele( `VBox`
                        )->a( n = `class` v = `sapUiSmallMarginBegin sapUiSmallMarginTopBottom`

                        )->tag( `Link`
                            )->a( n = `text`   v = `{NAME}`
                            )->a( n = `target` v = `{PRODUCT_PIC_URL}`
                            )->a( n = `press`  v = client->_event( val   = `LINK_PRESS`
                                                                   t_arg = temp1 )
                        )->tag( `Label`
                            )->a( n = `text` v = `{PRODUCT_ID}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `LINK_PRESS`.
      popup_display_image( client->get_event_arg( ) ).
    ENDIF.

  ENDMETHOD.


  METHOD popup_display_image.

    " the controller-built Dialog (handlePress), rebuilt as a fragment shown via popup_display
    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Dialog`
            )->tag( `Image`
                )->a( n = `src` v = pic_url

            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Close`
                    )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " mock /ProductCollection flattened to the three bound columns (ProductId, Name, ProductPicUrl)
    DATA temp3 LIKE t_products.
    DATA temp4 LIKE LINE OF temp3.
    FIELD-SYMBOLS <s_product> LIKE LINE OF t_products.
    CLEAR temp3.
    
    temp4-product_id = `HT-1000`.
    temp4-name = `Notebook Basic 15`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1001`.
    temp4-name = `Notebook Basic 17`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1002`.
    temp4-name = `Notebook Basic 18`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1003`.
    temp4-name = `Notebook Basic 19`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1007`.
    temp4-name = `ITelO Vault`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1010`.
    temp4-name = `Notebook Professional 15`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1011`.
    temp4-name = `Notebook Professional 17`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1020`.
    temp4-name = `ITelO Vault Net`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1021`.
    temp4-name = `ITelO Vault SAT`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1022`.
    temp4-name = `Comfort Easy`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1023`.
    temp4-name = `Comfort Senior`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1030`.
    temp4-name = `Ergo Screen E-I`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1031`.
    temp4-name = `Ergo Screen E-II`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1032`.
    temp4-name = `Ergo Screen E-III`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1035`.
    temp4-name = `Flat Basic`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1036`.
    temp4-name = `Flat Future`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1037`.
    temp4-name = `Flat XL`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1040`.
    temp4-name = `Laser Professional Eco`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1041`.
    temp4-name = `Laser Basic`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1042`.
    temp4-name = `Laser Allround`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1050`.
    temp4-name = `Ultra Jet Super Color`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1051`.
    temp4-name = `Ultra Jet Mobile`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1052`.
    temp4-name = `Ultra Jet Super Highspeed`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1055`.
    temp4-name = `Multi Print`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1056`.
    temp4-name = `Multi Color`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1060`.
    temp4-name = `Cordless Mouse`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1061`.
    temp4-name = `Speed Mouse`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1062`.
    temp4-name = `Track Mouse`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1063`.
    temp4-name = `Ergonomic Keyboard`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1064`.
    temp4-name = `Internet Keyboard`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1065`.
    temp4-name = `Media Keyboard`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1066`.
    temp4-name = `Mousepad`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1067`.
    temp4-name = `Ergo Mousepad`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1068`.
    temp4-name = `Designer Mousepad`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1069`.
    temp4-name = `Universal card reader`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1070`.
    temp4-name = `Proctra X`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1071`.
    temp4-name = `Gladiator MX`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1072`.
    temp4-name = `Hurricane GX`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1073`.
    temp4-name = `Hurricane GX/LN`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1080`.
    temp4-name = `Photo Scan`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1081`.
    temp4-name = `Power Scan`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1082`.
    temp4-name = `Jet Scan Professional`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1083`.
    temp4-name = `Jet Scan Professional`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1085`.
    temp4-name = `Copymaster`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1090`.
    temp4-name = `Surround Sound`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1091`.
    temp4-name = `Blaster Extreme`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1092`.
    temp4-name = `Sound Booster`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1095`.
    temp4-name = `Lovely Sound 5.1 Wireless`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1096`.
    temp4-name = `Lovely Sound 5.1`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1097`.
    temp4-name = `Lovely Sound Stereo`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1100`.
    temp4-name = `Smart Office`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1101`.
    temp4-name = `Smart Design`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1102`.
    temp4-name = `Smart Network`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1103`.
    temp4-name = `Smart Multimedia`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1104`.
    temp4-name = `Smart Games`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1105`.
    temp4-name = `Smart Internet Antivirus`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1106`.
    temp4-name = `Smart Firewall`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1107`.
    temp4-name = `Smart Money`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1110`.
    temp4-name = `PC Lock`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1111`.
    temp4-name = `Notebook Lock`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1112`.
    temp4-name = `Web cam reality`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1113`.
    temp4-name = `Screen clean`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1114`.
    temp4-name = `Fabric bag professional`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1115`.
    temp4-name = `Wireless DSL Router`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1116`.
    temp4-name = `Wireless DSL Router / Repeater`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1117`.
    temp4-name = `Wireless DSL Router / Repeater and Print Server`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1118`.
    temp4-name = `USB Stick`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1119`.
    temp4-name = `Travel Adapter`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1120`.
    temp4-name = `Cordless Bluetooth Keyboard, english international`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1137`.
    temp4-name = `Flat XXL`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1138`.
    temp4-name = `Pocket Mouse`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1210`.
    temp4-name = `PC Power Station`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1251`.
    temp4-name = `Astro Laptop 1516`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1252`.
    temp4-name = `Astro Phone 6`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1253`.
    temp4-name = `Benda Laptop 1408`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1254`.
    temp4-name = `Bending Screen 21HD`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1255`.
    temp4-name = `Broad Screen 22HD`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1256`.
    temp4-name = `Cerdik Phone 7`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1257`.
    temp4-name = `Cepat Tablet 10.5`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1258`.
    temp4-name = `Cepat Tablet 8`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1500`.
    temp4-name = `Server Basic`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1501`.
    temp4-name = `Server Professional`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1502`.
    temp4-name = `Server Power Pro`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1600`.
    temp4-name = `Family PC Basic`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1601`.
    temp4-name = `Family PC Pro`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1602`.
    temp4-name = `Gaming Monster`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-1603`.
    temp4-name = `Gaming Monster Pro`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-2000`.
    temp4-name = `7" Widescreen Portable DVD Player w MP3`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-2001`.
    temp4-name = `10" Portable DVD player`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-2002`.
    temp4-name = `Portable DVD Player with 9" LCD Monitor`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-2025`.
    temp4-name = `CD/DVD case: 264 sleeves`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-2026`.
    temp4-name = `Audio/Video Cable Kit - 4m`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-2027`.
    temp4-name = `Removable CD/DVD Laser Labels`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6100`.
    temp4-name = `Beam Breaker B-1`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6101`.
    temp4-name = `Beam Breaker B-2`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6102`.
    temp4-name = `Beam Breaker B-3`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6110`.
    temp4-name = `Play Movie`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6111`.
    temp4-name = `Record Movie`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6120`.
    temp4-name = `ITelo MusicStick`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6121`.
    temp4-name = `ITelo Jog-Mate`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6122`.
    temp4-name = `Power Pro Player 40`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6123`.
    temp4-name = `Power Pro Player 80`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6130`.
    temp4-name = `Flat Watch HD32`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6131`.
    temp4-name = `Flat Watch HD37`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-6132`.
    temp4-name = `Flat Watch HD41`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-7000`.
    temp4-name = `Copperberry`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-7010`.
    temp4-name = `Silverberry`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-7020`.
    temp4-name = `Goldberry`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-7030`.
    temp4-name = `Platinberry`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-8000`.
    temp4-name = `ITelO FlexTop I4000`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-8001`.
    temp4-name = `ITelO FlexTop I6300c`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-8002`.
    temp4-name = `ITelO FlexTop I9100`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-8003`.
    temp4-name = `ITelO FlexTop I9800`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9991`.
    temp4-name = `Smartphone Leather Case`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9992`.
    temp4-name = `Smartphone Alpha`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9993`.
    temp4-name = `Mini Tablet`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9994`.
    temp4-name = `Camcorder View`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9995`.
    temp4-name = `Tablet Pouch`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9996`.
    temp4-name = `Tablet Pouch`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9997`.
    temp4-name = `e-Book Reader ReadMe`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9998`.
    temp4-name = `Smartphone Beta`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `HT-9999`.
    temp4-name = `Maxi Tablet`.
    INSERT temp4 INTO TABLE temp3.
    temp4-product_id = `PF-1000`.
    temp4-name = `Flyer`.
    INSERT temp4 INTO TABLE temp3.
    t_products = temp3.

    " the mock rows' ProductPicUrl, rebuilt per row on the OpenUI5 host
    
    LOOP AT t_products ASSIGNING <s_product>.
      <s_product>-product_pic_url = |https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/{ <s_product>-product_id }.jpg|.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
