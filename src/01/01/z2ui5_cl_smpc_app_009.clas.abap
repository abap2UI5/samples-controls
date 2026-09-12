" @keywords column sap.m allows define specific properties table overflowtoolbar title toolbarspacer combobox item
" @summary The table shares many features with the list and, in addition, introduces columns. The table is fully responsive and can hide columns or shown them in-place if the screen space is not sufficient.
" @origin sap.m.sample.Table - https://sdk.openui5.org/entity/sap.m.Column/sample/sap.m.sample.Table (status: checked)
CLASS z2ui5_cl_smpc_app_009 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid     TYPE string,
        name          TYPE string,
        suppliername  TYPE string,
        weightmeasure TYPE p LENGTH 8 DECIMALS 3,
        weightunit    TYPE string,
        weight_state  TYPE string,
        price         TYPE p LENGTH 8 DECIMALS 2,
        currencycode  TYPE string,
        width         TYPE p LENGTH 4 DECIMALS 1,
        depth         TYPE p LENGTH 4 DECIMALS 1,
        height        TYPE p LENGTH 4 DECIMALS 1,
        dimunit       TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_sticky TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA popin_key TYPE string.
    DATA toggle_pressed TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_009 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`        v = `sap.m`
        )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core`   v = `sap.ui.core`

        " sticky + popinLayout are set imperatively by the original controller (onSelect / onPopinLayoutChanged) - bound properties here
        )->ele( `Table`
            )->a( n = `id`          v = `idProductsTable`
            )->a( n = `inset`       v = `false`
            )->a( n = `items`       v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|
            )->a( n = `sticky`      v = client->_bind( t_sticky )
            )->a( n = `popinLayout` v = |\{= ${ client->_bind( popin_key ) } === 'GridLarge' \|\| ${ client->_bind( popin_key ) } === 'GridSmall' ? ${ client->_bind( popin_key ) } : 'Block' \}|

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->ele( `content`
                        )->tag( `Title`
                            )->a( n = `text`  v = `Products`
                            )->a( n = `level` v = `H2`
                        )->tag( `ToolbarSpacer`

                        " the original change handler's PopinLayout switch lives in the Table's popinLayout expression binding
                        )->ele( `ComboBox`
                            )->a( n = `id`          v = `idPopinLayout`
                            )->a( n = `placeholder` v = `Popin layout options`
                            )->a( n = `selectedKey` v = client->_bind( popin_key )

                            )->ele( `items`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `text` v = `Block`
                                    )->a( n = `key`  v = `Block`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `text` v = `Grid Large`
                                    )->a( n = `key`  v = `GridLarge`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `text` v = `Grid Small`
                                    )->a( n = `key`  v = `GridSmall`

                            )->end(
                        )->end(
                        )->tag( `Label`
                            )->a( n = `text` v = `Sticky options:`
                        )->tag( `CheckBox`
                            )->a( n = `text`   v = `ColumnHeaders`
                            )->a( n = `select` v = client->_event( val   = `STICKY_SELECT`
                                                                   t_arg = VALUE #( ( `${$source>/text}` ) ( `${$parameters>/selected}` ) ) )
                        )->tag( `CheckBox`
                            )->a( n = `text`   v = `HeaderToolbar`
                            )->a( n = `select` v = client->_event( val   = `STICKY_SELECT`
                                                                   t_arg = VALUE #( ( `${$source>/text}` ) ( `${$parameters>/selected}` ) ) )
                        )->tag( `CheckBox`
                            )->a( n = `text`   v = `InfoToolbar`
                            )->a( n = `select` v = client->_event( val   = `STICKY_SELECT`
                                                                   t_arg = VALUE #( ( `${$source>/text}` ) ( `${$parameters>/selected}` ) ) )
                        " the original press handler (infoToolbar.setVisible(!pressed)) is the visible expression binding on the infoToolbar below
                        )->tag( `ToggleButton`
                            )->a( n = `id`      v = `toggleInfoToolbar`
                            )->a( n = `text`    v = `Hide/Show InfoToolbar`
                            )->a( n = `pressed` v = client->_bind( toggle_pressed )

                    )->end(
                )->end(
            )->end(
            )->ele( `infoToolbar`
                )->ele( `OverflowToolbar`
                    )->a( n = `visible` v = |\{= !${ client->_bind( toggle_pressed ) } \}|

                    )->tag( `Label`
                        )->a( n = `text` v = `Wide range of available products`

                )->end(
            )->end(
            )->ele( `columns`
                )->ele( `Column`
                    )->a( n = `width` v = `12em`

                    " p:ColumnAIAction dependents dropped - plugin class newer than 1.71, see DROPPED_171 (as app 022)
                    )->tag( `Text`
                        )->a( n = `text` v = `Product`

                )->end(
                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Tablet`
                    )->a( n = `demandPopin`    v = `true`

                    )->tag( `Text`
                        )->a( n = `text` v = `Supplier`

                )->end(
                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Desktop`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Dimensions`

                )->end(
                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Desktop`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `Center`

                    )->tag( `Text`
                        )->a( n = `text` v = `Weight`

                )->end(
                )->ele( `Column`
                    )->a( n = `hAlign` v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Price`

                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->a( n = `vAlign` v = `Middle`

                    )->ele( `cells`
                        )->tag( `ObjectIdentifier`
                            )->a( n = `title` v = `{NAME}`
                            )->a( n = `text`  v = `{PRODUCTID}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{SUPPLIERNAME}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{WIDTH} x {DEPTH} x {HEIGHT} {DIMUNIT}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{WEIGHTMEASURE}`
                            )->a( n = `unit`   v = `{WEIGHTUNIT}`
                            )->a( n = `state`  v = `{WEIGHT_STATE}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{ parts: [{path: 'PRICE'}, {path: 'CURRENCYCODE'}], type: 'sap.ui.model.type.Currency', formatOptions: {showMeasure: false} }`
                            )->a( n = `unit`   v = `{CURRENCYCODE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    DATA selected TYPE abap_bool.

    IF client->get_event( ) = `STICKY_SELECT`.
      DATA(sticky_text) = client->get_event_arg( ).
      selected = client->get_event_arg( 2 ).
      IF selected = abap_true.
        INSERT sticky_text INTO TABLE t_sticky.
      ELSE.
        DELETE t_sticky WHERE table_line = sticky_text.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " the shared mock /ProductCollection flattened to the bound columns, all 123 rows kept verbatim (see the model-flattening NOTE)
    t_products = VALUE #(
      ( productid = `HT-1000` name = `Notebook Basic 15` suppliername = `Very Best Screens`
        weightmeasure = '4.2' weightunit = `KG` price = '956' currencycode = `EUR` width = '30' depth = '18' height = '3' dimunit = `cm` )
      ( productid = `HT-1001` name = `Notebook Basic 17` suppliername = `Very Best Screens`
        weightmeasure = '4.5' weightunit = `KG` price = '1249' currencycode = `EUR` width = '29' depth = '17' height = '3.1' dimunit = `cm` )
      ( productid = `HT-1002` name = `Notebook Basic 18` suppliername = `Very Best Screens`
        weightmeasure = '4.2' weightunit = `KG` price = '1570' currencycode = `EUR` width = '28' depth = '19' height = '2.5' dimunit = `cm` )
      ( productid = `HT-1003` name = `Notebook Basic 19` suppliername = `Smartcards`
        weightmeasure = '4.2' weightunit = `KG` price = '1650' currencycode = `EUR` width = '32' depth = '21' height = '4' dimunit = `cm` )
      ( productid = `HT-1007` name = `ITelO Vault` suppliername = `Technocom`
        weightmeasure = '0.2' weightunit = `KG` price = '299' currencycode = `EUR` width = '32' depth = '22' height = '3' dimunit = `cm` )
      ( productid = `HT-1010` name = `Notebook Professional 15` suppliername = `Very Best Screens`
        weightmeasure = '4.3' weightunit = `KG` price = '1999' currencycode = `EUR` width = '33' depth = '20' height = '3' dimunit = `cm` )
      ( productid = `HT-1011` name = `Notebook Professional 17` suppliername = `Very Best Screens`
        weightmeasure = '4.1' weightunit = `KG` price = '2299' currencycode = `EUR` width = '33' depth = '23' height = '2' dimunit = `cm` )
      ( productid = `HT-1020` name = `ITelO Vault Net` suppliername = `Technocom`
        weightmeasure = '0.16' weightunit = `KG` price = '459' currencycode = `EUR` width = '10' depth = '1.8' height = '17' dimunit = `cm` )
      ( productid = `HT-1021` name = `ITelO Vault SAT` suppliername = `Technocom`
        weightmeasure = '0.18' weightunit = `KG` price = '149' currencycode = `EUR` width = '11' depth = '1.7' height = '18' dimunit = `cm` )
      ( productid = `HT-1022` name = `Comfort Easy` suppliername = `Technocom`
        weightmeasure = '0.2' weightunit = `KG` price = '1679' currencycode = `EUR` width = '84' depth = '1.5' height = '14' dimunit = `cm` )
      ( productid = `HT-1023` name = `Comfort Senior` suppliername = `Technocom`
        weightmeasure = '0.8' weightunit = `KG` price = '512' currencycode = `EUR` width = '80' depth = '1.6' height = '13' dimunit = `cm` )
      ( productid = `HT-1030` name = `Ergo Screen E-I` suppliername = `Very Best Screens`
        weightmeasure = '21' weightunit = `KG` price = '230' currencycode = `EUR` width = '37' depth = '12' height = '36' dimunit = `cm` )
      ( productid = `HT-1031` name = `Ergo Screen E-II` suppliername = `Very Best Screens`
        weightmeasure = '21' weightunit = `KG` price = '285' currencycode = `EUR` width = '40.8' depth = '19' height = '43' dimunit = `cm` )
      ( productid = `HT-1032` name = `Ergo Screen E-III` suppliername = `Very Best Screens`
        weightmeasure = '21' weightunit = `KG` price = '345' currencycode = `EUR` width = '40.8' depth = '19' height = '43' dimunit = `cm` )
      ( productid = `HT-1035` name = `Flat Basic` suppliername = `Very Best Screens`
        weightmeasure = '14' weightunit = `KG` price = '399' currencycode = `EUR` width = '39' depth = '20' height = '41' dimunit = `cm` )
      ( productid = `HT-1036` name = `Flat Future` suppliername = `Very Best Screens`
        weightmeasure = '15' weightunit = `KG` price = '430' currencycode = `EUR` width = '45' depth = '26' height = '46' dimunit = `cm` )
      ( productid = `HT-1037` name = `Flat XL` suppliername = `Very Best Screens`
        weightmeasure = '17' weightunit = `KG` price = '1230' currencycode = `EUR` width = '54.5' depth = '22.1' height = '39.1' dimunit = `cm` )
      ( productid = `HT-1040` name = `Laser Professional Eco` suppliername = `Alpha Printers`
        weightmeasure = '32' weightunit = `KG` price = '830' currencycode = `EUR` width = '51' depth = '46' height = '30' dimunit = `cm` )
      ( productid = `HT-1041` name = `Laser Basic` suppliername = `Alpha Printers`
        weightmeasure = '23' weightunit = `KG` price = '490' currencycode = `EUR` width = '48' depth = '42' height = '26' dimunit = `cm` )
      ( productid = `HT-1042` name = `Laser Allround` suppliername = `Alpha Printers`
        weightmeasure = '17' weightunit = `KG` price = '349' currencycode = `EUR` width = '53' depth = '50' height = '65' dimunit = `cm` )
      ( productid = `HT-1050` name = `Ultra Jet Super Color` suppliername = `Alpha Printers`
        weightmeasure = '3' weightunit = `KG` price = '139' currencycode = `EUR` width = '41' depth = '41' height = '28' dimunit = `cm` )
      ( productid = `HT-1051` name = `Ultra Jet Mobile` suppliername = `Printer for All`
        weightmeasure = '1.9' weightunit = `KG` price = '99' currencycode = `EUR` width = '46' depth = '32' height = '25' dimunit = `cm` )
      ( productid = `HT-1052` name = `Ultra Jet Super Highspeed` suppliername = `Printer for All`
        weightmeasure = '18' weightunit = `KG` price = '170' currencycode = `EUR` width = '41' depth = '41' height = '28' dimunit = `cm` )
      ( productid = `HT-1055` name = `Multi Print` suppliername = `Printer for All`
        weightmeasure = '6.3' weightunit = `KG` price = '99' currencycode = `EUR` width = '55' depth = '45' height = '29' dimunit = `cm` )
      ( productid = `HT-1056` name = `Multi Color` suppliername = `Printer for All`
        weightmeasure = '4.3' weightunit = `KG` price = '119' currencycode = `EUR` width = '51' depth = '41.3' height = '22' dimunit = `cm` )
      ( productid = `HT-1060` name = `Cordless Mouse` suppliername = `Oxynum`
        weightmeasure = '0.09' weightunit = `KG` price = '9' currencycode = `EUR` width = '6' depth = '14.5' height = '3.5' dimunit = `cm` )
      ( productid = `HT-1061` name = `Speed Mouse` suppliername = `Oxynum`
        weightmeasure = '0.09' weightunit = `KG` price = '7' currencycode = `EUR` width = '7' depth = '15' height = '3.1' dimunit = `cm` )
      ( productid = `HT-1062` name = `Track Mouse` suppliername = `Oxynum`
        weightmeasure = '0.03' weightunit = `KG` price = '11' currencycode = `EUR` width = '3' depth = '7' height = '4' dimunit = `cm` )
      ( productid = `HT-1063` name = `Ergonomic Keyboard` suppliername = `Oxynum`
        weightmeasure = '2.1' weightunit = `KG` price = '14' currencycode = `EUR` width = '50' depth = '21' height = '3.5' dimunit = `cm` )
      ( productid = `HT-1064` name = `Internet Keyboard` suppliername = `Oxynum`
        weightmeasure = '1.8' weightunit = `KG` price = '16' currencycode = `EUR` width = '52' depth = '25' height = '3' dimunit = `cm` )
      ( productid = `HT-1065` name = `Media Keyboard` suppliername = `Oxynum`
        weightmeasure = '2.3' weightunit = `KG` price = '26' currencycode = `EUR` width = '51.4' depth = '23' height = '4' dimunit = `cm` )
      ( productid = `HT-1066` name = `Mousepad` suppliername = `Oxynum`
        weightmeasure = '80' weightunit = `G` price = '6.99' currencycode = `EUR` width = '15' depth = '6' height = '0.2' dimunit = `cm` )
      ( productid = `HT-1067` name = `Ergo Mousepad` suppliername = `Oxynum`
        weightmeasure = '80' weightunit = `G` price = '8.99' currencycode = `EUR` width = '15' depth = '6' height = '0.2' dimunit = `cm` )
      ( productid = `HT-1068` name = `Designer Mousepad` suppliername = `Fasttech`
        weightmeasure = '90' weightunit = `G` price = '12.99' currencycode = `EUR` width = '24' depth = '24' height = '0.6' dimunit = `cm` )
      ( productid = `HT-1069` name = `Universal card reader` suppliername = `Fasttech`
        weightmeasure = '45' weightunit = `G` price = '14' currencycode = `EUR` width = '6' depth = '6' height = '3' dimunit = `cm` )
      ( productid = `HT-1070` name = `Proctra X` suppliername = `Ultrasonic United`
        weightmeasure = '0.255' weightunit = `KG` price = '70.9' currencycode = `EUR` width = '22' depth = '35' height = '17' dimunit = `cm` )
      ( productid = `HT-1071` name = `Gladiator MX` suppliername = `Ultrasonic United`
        weightmeasure = '0.3' weightunit = `KG` price = '81.7' currencycode = `EUR` width = '22' depth = '35' height = '17' dimunit = `cm` )
      ( productid = `HT-1072` name = `Hurricane GX` suppliername = `Ultrasonic United`
        weightmeasure = '0.4' weightunit = `KG` price = '101.2' currencycode = `EUR` width = '22' depth = '35' height = '17' dimunit = `cm` )
      ( productid = `HT-1073` name = `Hurricane GX/LN` suppliername = `Smartcards`
        weightmeasure = '0.4' weightunit = `KG` price = '139.99' currencycode = `EUR` width = '22' depth = '35' height = '17' dimunit = `cm` )
      ( productid = `HT-1080` name = `Photo Scan` suppliername = `Printer for All`
        weightmeasure = '2.3' weightunit = `KG` price = '129' currencycode = `EUR` width = '34' depth = '48' height = '5' dimunit = `cm` )
      ( productid = `HT-1081` name = `Power Scan` suppliername = `Printer for All`
        weightmeasure = '2.4' weightunit = `KG` price = '89' currencycode = `EUR` width = '31' depth = '43' height = '7' dimunit = `cm` )
      ( productid = `HT-1082` name = `Jet Scan Professional` suppliername = `Printer for All`
        weightmeasure = '3.2' weightunit = `KG` price = '169' currencycode = `EUR` width = '33' depth = '41' height = '12' dimunit = `cm` )
      ( productid = `HT-1083` name = `Jet Scan Professional` suppliername = `Printer for All`
        weightmeasure = '3.2' weightunit = `KG` price = '189' currencycode = `EUR` width = '35' depth = '40' height = '10' dimunit = `cm` )
      ( productid = `HT-1085` name = `Copymaster` suppliername = `Alpha Printers`
        weightmeasure = '23.2' weightunit = `KG` price = '1499' currencycode = `EUR` width = '45' depth = '42' height = '22' dimunit = `cm` )
      ( productid = `HT-1090` name = `Surround Sound` suppliername = `Speaker Experts`
        weightmeasure = '3' weightunit = `KG` price = '39' currencycode = `EUR` width = '12' depth = '10' height = '16' dimunit = `cm` )
      ( productid = `HT-1091` name = `Blaster Extreme` suppliername = `Speaker Experts`
        weightmeasure = '1.4' weightunit = `KG` price = '26' currencycode = `EUR` width = '13' depth = '11' height = '17.5' dimunit = `cm` )
      ( productid = `HT-1092` name = `Sound Booster` suppliername = `Speaker Experts`
        weightmeasure = '2.1' weightunit = `KG` price = '45' currencycode = `EUR` width = '12.4' depth = '10.4' height = '18.1' dimunit = `cm` )
      ( productid = `HT-1095` name = `Lovely Sound 5.1 Wireless` suppliername = `Fasttech`
        weightmeasure = '80' weightunit = `G` price = '49' currencycode = `EUR` width = '24' depth = '19' height = '23' dimunit = `cm` )
      ( productid = `HT-1096` name = `Lovely Sound 5.1` suppliername = `Fasttech`
        weightmeasure = '130' weightunit = `G` price = '39' currencycode = `EUR` width = '25' depth = '17' height = '19' dimunit = `cm` )
      ( productid = `HT-1097` name = `Lovely Sound Stereo` suppliername = `Fasttech`
        weightmeasure = '60' weightunit = `G` price = '29' currencycode = `EUR` width = '21.3' depth = '2.4' height = '19.7' dimunit = `cm` )
      ( productid = `HT-1100` name = `Smart Office` suppliername = `Technocom`
        weightmeasure = '1.2' weightunit = `KG` price = '89.9' currencycode = `EUR` width = '15' depth = '6.5' height = '2.1' dimunit = `cm` )
      ( productid = `HT-1101` name = `Smart Design` suppliername = `Technocom`
        weightmeasure = '0.8' weightunit = `KG` price = '79.9' currencycode = `EUR` width = '14' depth = '6.7' height = '24' dimunit = `cm` )
      ( productid = `HT-1102` name = `Smart Network` suppliername = `Technocom`
        weightmeasure = '0.8' weightunit = `KG` price = '69' currencycode = `EUR` width = '16' depth = '6' height = '27' dimunit = `cm` )
      ( productid = `HT-1103` name = `Smart Multimedia` suppliername = `Technocom`
        weightmeasure = '0.8' weightunit = `KG` price = '77' currencycode = `EUR` width = '11' depth = '3.4' height = '22' dimunit = `cm` )
      ( productid = `HT-1104` name = `Smart Games` suppliername = `Technocom`
        weightmeasure = '1.1' weightunit = `KG` price = '55' currencycode = `EUR` width = '10' depth = '3' height = '30' dimunit = `cm` )
      ( productid = `HT-1105` name = `Smart Internet Antivirus` suppliername = `Brainsoft`
        weightmeasure = '0.7' weightunit = `KG` price = '29' currencycode = `EUR` width = '16' depth = '4' height = '21' dimunit = `cm` )
      ( productid = `HT-1106` name = `Smart Firewall` suppliername = `Brainsoft`
        weightmeasure = '0.9' weightunit = `KG` price = '34' currencycode = `EUR` width = '17.9' depth = '4.2' height = '23.1' dimunit = `cm` )
      ( productid = `HT-1107` name = `Smart Money` suppliername = `Brainsoft`
        weightmeasure = '0.5' weightunit = `KG` price = '29.9' currencycode = `EUR` width = '12' depth = '1.5' height = '19' dimunit = `cm` )
      ( productid = `HT-1110` name = `PC Lock` suppliername = `Red Point Stores`
        weightmeasure = '0.03' weightunit = `KG` price = '8.9' currencycode = `EUR` width = '20' depth = '8' height = '4.3' dimunit = `cm` )
      ( productid = `HT-1111` name = `Notebook Lock` suppliername = `Red Point Stores`
        weightmeasure = '0.02' weightunit = `KG` price = '6.9' currencycode = `EUR` width = '31' depth = '9' height = '7' dimunit = `cm` )
      ( productid = `HT-1112` name = `Web cam reality` suppliername = `Red Point Stores`
        weightmeasure = '0.075' weightunit = `KG` price = '39' currencycode = `EUR` width = '9' depth = '8.2' height = '1.3' dimunit = `cm` )
      ( productid = `HT-1113` name = `Screen clean` suppliername = `Red Point Stores`
        weightmeasure = '0.05' weightunit = `KG` price = '2.3' currencycode = `EUR` width = '2' depth = '2' height = '0.1' dimunit = `cm` )
      ( productid = `HT-1114` name = `Fabric bag professional` suppliername = `Red Point Stores`
        weightmeasure = '1.8' weightunit = `KG` price = '31' currencycode = `EUR` width = '42' depth = '32' height = '7' dimunit = `cm` )
      ( productid = `HT-1115` name = `Wireless DSL Router` suppliername = `Red Point Stores`
        weightmeasure = '0.45' weightunit = `KG` price = '49' currencycode = `EUR` width = '19.3' depth = '18' height = '5' dimunit = `cm` )
      ( productid = `HT-1116` name = `Wireless DSL Router / Repeater` suppliername = `Red Point Stores`
        weightmeasure = '0.45' weightunit = `KG` price = '59' currencycode = `EUR` width = '19.3' depth = '18' height = '5' dimunit = `cm` )
      ( productid = `HT-1117` name = `Wireless DSL Router / Repeater and Print Server` suppliername = `Technocom`
        weightmeasure = '0.45' weightunit = `KG` price = '69' currencycode = `EUR` width = '19.3' depth = '18' height = '5' dimunit = `cm` )
      ( productid = `HT-1118` name = `USB Stick` suppliername = `Technocom`
        weightmeasure = '0.015' weightunit = `KG` price = '35' currencycode = `EUR` width = '1.5' depth = '8.7' height = '1.2' dimunit = `cm` )
      ( productid = `HT-1119` name = `Travel Adapter` suppliername = `Titanium`
        weightmeasure = '88' weightunit = `G` price = '79' currencycode = `EUR` width = '2' depth = '3.1' height = '3.9' dimunit = `cm` )
      ( productid = `HT-1120` name = `Cordless Bluetooth Keyboard, english international` suppliername = `Technocom`
        weightmeasure = '1' weightunit = `KG` price = '29' currencycode = `EUR` width = '51.4' depth = '23' height = '4' dimunit = `cm` )
      ( productid = `HT-1137` name = `Flat XXL` suppliername = `Technocom`
        weightmeasure = '18' weightunit = `KG` price = '1430' currencycode = `EUR` width = '54' depth = '22' height = '38' dimunit = `cm` )
      ( productid = `HT-1138` name = `Pocket Mouse` suppliername = `Technocom`
        weightmeasure = '0.02' weightunit = `KG` price = '23' currencycode = `EUR` width = '0.3' depth = '0.5' height = '1' dimunit = `cm` )
      ( productid = `HT-1210` name = `PC Power Station` suppliername = `Technocom`
        weightmeasure = '2.3' weightunit = `KG` price = '2399' currencycode = `EUR` width = '28' depth = '31' height = '43' dimunit = `cm` )
      ( productid = `HT-1251` name = `Astro Laptop 1516` suppliername = `Ultrasonic United`
        weightmeasure = '4.2' weightunit = `KG` price = '989' currencycode = `EUR` width = '30' depth = '18' height = '3' dimunit = `cm` )
      ( productid = `HT-1252` name = `Astro Phone 6` suppliername = `Ultrasonic United`
        weightmeasure = '0.75' weightunit = `KG` price = '649' currencycode = `EUR` width = '8' depth = '6' height = '1.5' dimunit = `cm` )
      ( productid = `HT-1253` name = `Benda Laptop 1408` suppliername = `Ultrasonic United`
        weightmeasure = '4.2' weightunit = `KG` price = '976' currencycode = `EUR` width = '30' depth = '18' height = '3' dimunit = `cm` )
      ( productid = `HT-1254` name = `Bending Screen 21HD` suppliername = `Ultrasonic United`
        weightmeasure = '15' weightunit = `KG` price = '250' currencycode = `EUR` width = '37' depth = '12' height = '36' dimunit = `cm` )
      ( productid = `HT-1255` name = `Broad Screen 22HD` suppliername = `Ultrasonic United`
        weightmeasure = '16' weightunit = `KG` price = '270' currencycode = `EUR` width = '39' depth = '12' height = '38' dimunit = `cm` )
      ( productid = `HT-1256` name = `Cerdik Phone 7` suppliername = `Ultrasonic United`
        weightmeasure = '0.75' weightunit = `KG` price = '549' currencycode = `EUR` width = '9' depth = '15' height = '1.5' dimunit = `cm` )
      ( productid = `HT-1257` name = `Cepat Tablet 10.5` suppliername = `Ultrasonic United`
        weightmeasure = '2.8' weightunit = `KG` price = '549' currencycode = `EUR` width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-1258` name = `Cepat Tablet 8` suppliername = `Ultrasonic United`
        weightmeasure = '2.5' weightunit = `KG` price = '529' currencycode = `EUR` width = '38' depth = '21' height = '3.5' dimunit = `cm` )
      ( productid = `HT-1500` name = `Server Basic` suppliername = `Technocom`
        weightmeasure = '18' weightunit = `KG` price = '5000' currencycode = `EUR` width = '34' depth = '35' height = '23' dimunit = `cm` )
      ( productid = `HT-1501` name = `Server Professional` suppliername = `Technocom`
        weightmeasure = '25' weightunit = `KG` price = '15000' currencycode = `EUR` width = '29' depth = '30' height = '27' dimunit = `cm` )
      ( productid = `HT-1502` name = `Server Power Pro` suppliername = `Technocom`
        weightmeasure = '35' weightunit = `KG` price = '25000' currencycode = `EUR` width = '22' depth = '27.3' height = '37' dimunit = `cm` )
      ( productid = `HT-1600` name = `Family PC Basic` suppliername = `Titanium`
        weightmeasure = '4.8' weightunit = `KG` price = '600' currencycode = `EUR` width = '21.4' depth = '29' height = '38' dimunit = `cm` )
      ( productid = `HT-1601` name = `Family PC Pro` suppliername = `Titanium`
        weightmeasure = '5.3' weightunit = `KG` price = '900' currencycode = `EUR` width = '25' depth = '31.7' height = '40.2' dimunit = `cm` )
      ( productid = `HT-1602` name = `Gaming Monster` suppliername = `Titanium`
        weightmeasure = '5.9' weightunit = `KG` price = '1200' currencycode = `EUR` width = '26.5' depth = '34' height = '47' dimunit = `cm` )
      ( productid = `HT-1603` name = `Gaming Monster Pro` suppliername = `Titanium`
        weightmeasure = '6.8' weightunit = `KG` price = '1700' currencycode = `EUR` width = '27' depth = '28' height = '42' dimunit = `cm` )
      ( productid = `HT-2000` name = `7" Widescreen Portable DVD Player w MP3` suppliername = `Titanium`
        weightmeasure = '0.79' weightunit = `KG` price = '249.99' currencycode = `EUR` width = '21.4' depth = '19' height = '27.6' dimunit = `cm` )
      ( productid = `HT-2001` name = `10" Portable DVD player` suppliername = `Titanium`
        weightmeasure = '0.84' weightunit = `KG` price = '449.99' currencycode = `EUR` width = '24' depth = '19.5' height = '29' dimunit = `cm` )
      ( productid = `HT-2002` name = `Portable DVD Player with 9" LCD Monitor` suppliername = `Technocom`
        weightmeasure = '0.72' weightunit = `KG` price = '853.99' currencycode = `EUR` width = '21' depth = '16.5' height = '14' dimunit = `cm` )
      ( productid = `HT-2025` name = `CD/DVD case: 264 sleeves` suppliername = `Titanium`
        weightmeasure = '0.65' weightunit = `KG` price = '44.99' currencycode = `EUR` width = '13' depth = '13' height = '20' dimunit = `cm` )
      ( productid = `HT-2026` name = `Audio/Video Cable Kit - 4m` suppliername = `Titanium`
        weightmeasure = '0.2' weightunit = `KG` price = '29.99' currencycode = `EUR` width = '21' depth = '10.2' height = '13' dimunit = `cm` )
      ( productid = `HT-2027` name = `Removable CD/DVD Laser Labels` suppliername = `Titanium`
        weightmeasure = '0.15' weightunit = `KG` price = '8.99' currencycode = `EUR` width = '5.5' depth = '2' height = '2' dimunit = `cm` )
      ( productid = `HT-6100` name = `Beam Breaker B-1` suppliername = `Titanium`
        weightmeasure = '1.7' weightunit = `KG` price = '469' currencycode = `EUR` width = '30.4' depth = '23.1' height = '23' dimunit = `cm` )
      ( productid = `HT-6101` name = `Beam Breaker B-2` suppliername = `Technocom`
        weightmeasure = '2' weightunit = `KG` price = '679' currencycode = `EUR` width = '30.4' depth = '23.1' height = '23' dimunit = `cm` )
      ( productid = `HT-6102` name = `Beam Breaker B-3` suppliername = `Technocom`
        weightmeasure = '2.5' weightunit = `KG` price = '889' currencycode = `EUR` width = '30.4' depth = '23.1' height = '23' dimunit = `cm` )
      ( productid = `HT-6110` name = `Play Movie` suppliername = `Fasttech`
        weightmeasure = '2.4' weightunit = `KG` price = '130' currencycode = `EUR` width = '37' depth = '24' height = '6' dimunit = `cm` )
      ( productid = `HT-6111` name = `Record Movie` suppliername = `Fasttech`
        weightmeasure = '3.1' weightunit = `KG` price = '288' currencycode = `EUR` width = '38' depth = '26' height = '6.2' dimunit = `cm` )
      ( productid = `HT-6120` name = `ITelo MusicStick` suppliername = `Fasttech`
        weightmeasure = '134' weightunit = `G` price = '45' currencycode = `EUR` width = '1.5' depth = '6' height = '1' dimunit = `cm` )
      ( productid = `HT-6121` name = `ITelo Jog-Mate` suppliername = `Fasttech`
        weightmeasure = '134' weightunit = `G` price = '63' currencycode = `EUR` width = '5.1' depth = '8' height = '9.2' dimunit = `cm` )
      ( productid = `HT-6122` name = `Power Pro Player 40` suppliername = `Fasttech`
        weightmeasure = '266' weightunit = `G` price = '167' currencycode = `EUR` width = '5.1' depth = '8' height = '9.2' dimunit = `cm` )
      ( productid = `HT-6123` name = `Power Pro Player 80` suppliername = `Fasttech`
        weightmeasure = '267' weightunit = `G` price = '299' currencycode = `EUR` width = '4' depth = '6' height = '0.8' dimunit = `cm` )
      ( productid = `HT-6130` name = `Flat Watch HD32` suppliername = `Very Best Screens`
        weightmeasure = '2.6' weightunit = `KG` price = '1459' currencycode = `EUR` width = '78' depth = '22.1' height = '55' dimunit = `cm` )
      ( productid = `HT-6131` name = `Flat Watch HD37` suppliername = `Very Best Screens`
        weightmeasure = '2.2' weightunit = `KG` price = '1199' currencycode = `EUR` width = '99.1' depth = '26' height = '61' dimunit = `cm` )
      ( productid = `HT-6132` name = `Flat Watch HD41` suppliername = `Very Best Screens`
        weightmeasure = '1.8' weightunit = `KG` price = '899' currencycode = `EUR` width = '128' depth = '23' height = '79.1' dimunit = `cm` )
      ( productid = `HT-7000` name = `Copperberry` suppliername = `Fasttech`
        weightmeasure = '0.5' weightunit = `KG` price = '549' currencycode = `EUR` width = '8.1' depth = '13' height = '12.1' dimunit = `cm` )
      ( productid = `HT-7010` name = `Silverberry` suppliername = `Fasttech`
        weightmeasure = '0.5' weightunit = `KG` price = '549' currencycode = `EUR` width = '8.1' depth = '13' height = '12.1' dimunit = `cm` )
      ( productid = `HT-7020` name = `Goldberry` suppliername = `Fasttech`
        weightmeasure = '0.5' weightunit = `KG` price = '549' currencycode = `EUR` width = '8.1' depth = '13' height = '12.1' dimunit = `cm` )
      ( productid = `HT-7030` name = `Platinberry` suppliername = `Fasttech`
        weightmeasure = '0.5' weightunit = `KG` price = '549' currencycode = `EUR` width = '8.1' depth = '13' height = '12.1' dimunit = `cm` )
      ( productid = `HT-8000` name = `ITelO FlexTop I4000` suppliername = `Titanium`
        weightmeasure = '4' weightunit = `KG` price = '799' currencycode = `EUR` width = '31' depth = '19' height = '3.1' dimunit = `cm` )
      ( productid = `HT-8001` name = `ITelO FlexTop I6300c` suppliername = `Titanium`
        weightmeasure = '4.2' weightunit = `KG` price = '799' currencycode = `EUR` width = '32' depth = '20' height = '3.4' dimunit = `cm` )
      ( productid = `HT-8002` name = `ITelO FlexTop I9100` suppliername = `Titanium`
        weightmeasure = '3.5' weightunit = `KG` price = '1199' currencycode = `EUR` width = '38' depth = '21' height = '4.1' dimunit = `cm` )
      ( productid = `HT-8003` name = `ITelO FlexTop I9800` suppliername = `Titanium`
        weightmeasure = '3.8' weightunit = `KG` price = '1388' currencycode = `EUR` width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9991` name = `Smartphone Leather Case` suppliername = `Ultrasonic United`
        weightmeasure = '0.02' weightunit = `KG` price = '25' currencycode = `EUR` width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9992` name = `Smartphone Alpha` suppliername = `Ultrasonic United`
        weightmeasure = '0.75' weightunit = `KG` price = '599' currencycode = `EUR` width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9993` name = `Mini Tablet` suppliername = `Ultrasonic United`
        weightmeasure = '3.8' weightunit = `KG` price = '833' currencycode = `EUR` width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9994` name = `Camcorder View` suppliername = `Ultrasonic United`
        weightmeasure = '3.8' weightunit = `KG` price = '1388' currencycode = `EUR` width = '48' depth = '31' height = '27' dimunit = `cm` )
      ( productid = `HT-9995` name = `Tablet Pouch` suppliername = `Titanium`
        weightmeasure = '0.03' weightunit = `KG` price = '20' currencycode = `EUR` width = '25' depth = '40' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9996` name = `Tablet Pouch` suppliername = `Titanium`
        weightmeasure = '0.03' weightunit = `KG` price = '20' currencycode = `EUR` width = '25' depth = '40' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9997` name = `e-Book Reader ReadMe` suppliername = `Titanium`
        weightmeasure = '3.8' weightunit = `KG` price = '33' currencycode = `EUR` width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9998` name = `Smartphone Beta` suppliername = `Titanium`
        weightmeasure = '0.75' weightunit = `KG` price = '30' currencycode = `EUR` width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9999` name = `Maxi Tablet` suppliername = `Titanium`
        weightmeasure = '3.8' weightunit = `KG` price = '749' currencycode = `EUR` width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `PF-1000` name = `Flyer` suppliername = `Titanium`
        weightmeasure = '0.01' weightunit = `KG` price = '0' currencycode = `EUR` width = '46' depth = '30' height = '3' dimunit = `cm` ) ).


    " weightState is business logic (KG conversion + Success/Warning/Error
    " thresholds), not presentation - abap2UI5 is a thin frontend, so the
    " ObjectNumber state is computed here in the backend (the original does it in
    " its frontend Formatter.js, which a faithful port moves server-side).
    LOOP AT t_products REFERENCE INTO DATA(product).
      DATA(weight_kg) = product->weightmeasure.
      IF product->weightunit = `G`.
        weight_kg = weight_kg / 1000.
      ENDIF.
      product->weight_state = COND #( WHEN weight_kg < 0 THEN `None`
                                         WHEN weight_kg < 1 THEN `Success`
                                         WHEN weight_kg < 5 THEN `Warning`
                                         ELSE `Error` ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
