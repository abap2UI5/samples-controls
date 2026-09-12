" @keywords columnlistitem column list item sap.m opa test app product table toolbar title
" @summary The following example simulates a click on a list item in a table.
" @origin sap.m.sample.TableTest - https://sdk.openui5.org/entity/sap.m.ColumnListItem/sample/sap.m.sample.TableTest (status: checked)
CLASS z2ui5_cl_smpc_app_010 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid     TYPE string,
        suppliername  TYPE string,
        weightmeasure TYPE p LENGTH 8 DECIMALS 3,
        weightunit    TYPE string,
        weight_state  TYPE string,
        name          TYPE string,
        currencycode  TYPE string,
        price         TYPE p LENGTH 8 DECIMALS 2,
        width         TYPE p LENGTH 4 DECIMALS 1,
        depth         TYPE p LENGTH 4 DECIMALS 1,
        height        TYPE p LENGTH 4 DECIMALS 1,
        dimunit       TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA popin_layout TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS popup_message_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_010 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core`   v = `sap.ui.core`
        )->a( n = `xmlns`        v = `sap.m`

        )->ele( `Table`
            )->a( n = `id`          v = `idProductsTable`
            )->a( n = `inset`       v = `false`
            )->a( n = `items`       v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|
            " the controller's onPopinLayoutChanged switch lives in this expression binding (as app 009) - never emits an empty enum value
            )->a( n = `popinLayout` v = |\{= ${ client->_bind( popin_layout ) } === 'GridLarge' \|\| ${ client->_bind( popin_layout ) } === 'GridSmall' ? ${ client->_bind( popin_layout ) } : 'Block' \}|

            )->ele( `headerToolbar`
                )->ele( `Toolbar`
                    )->ele( `content`
                        )->tag( `Title`
                            )->a( n = `text`  v = `Products`
                            )->a( n = `level` v = `H2`
                        )->tag( `ToolbarSpacer`

                        )->ele( `ComboBox`
                            )->a( n = `id`          v = `idPopinLayout`
                            )->a( n = `placeholder` v = `Popin layout options`
                            " original change handler dropped - the two-way selectedKey feeds the popinLayout expression binding
                            )->a( n = `selectedKey` v = client->_bind( popin_layout )

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
                    )->end(
                )->end(
            )->end(
            )->ele( `columns`
                )->ele( `Column`
                    )->a( n = `width` v = `12em`

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
                    )->a( n = `type`  v = `Navigation`
                    )->a( n = `press` v = client->_event( `MESSAGE_DIALOG_PRESS` )

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

    IF client->get_event( ) = `MESSAGE_DIALOG_PRESS`.
      popup_message_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD popup_message_display.

    " the controller-built message Dialog, shown as a popup fragment
    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `Dialog`
            )->a( n = `title` v = `Message`
            )->a( n = `type`  v = `Message`

            )->ele( `content`
                )->tag( `Text`
                    )->a( n = `text` v = `Success`

            )->end(
            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `OK`
                    )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    t_products = VALUE #(
      ( productid = `HT-1000` suppliername = `Very Best Screens` weightmeasure = '4.2' weightunit = `KG` name = `Notebook Basic 15` currencycode = `EUR` price = '956' width = '30' depth = '18' height = '3' dimunit = `cm` )
      ( productid = `HT-1001` suppliername = `Very Best Screens` weightmeasure = '4.5' weightunit = `KG` name = `Notebook Basic 17` currencycode = `EUR` price = '1249' width = '29' depth = '17' height = '3.1' dimunit = `cm` )
      ( productid = `HT-1002` suppliername = `Very Best Screens` weightmeasure = '4.2' weightunit = `KG` name = `Notebook Basic 18` currencycode = `EUR` price = '1570' width = '28' depth = '19' height = '2.5' dimunit = `cm` )
      ( productid = `HT-1003` suppliername = `Smartcards` weightmeasure = '4.2' weightunit = `KG` name = `Notebook Basic 19` currencycode = `EUR` price = '1650' width = '32' depth = '21' height = '4' dimunit = `cm` )
      ( productid = `HT-1007` suppliername = `Technocom` weightmeasure = '0.2' weightunit = `KG` name = `ITelO Vault` currencycode = `EUR` price = '299' width = '32' depth = '22' height = '3' dimunit = `cm` )
      ( productid = `HT-1010` suppliername = `Very Best Screens` weightmeasure = '4.3' weightunit = `KG` name = `Notebook Professional 15` currencycode = `EUR` price = '1999' width = '33' depth = '20' height = '3' dimunit = `cm` )
      ( productid = `HT-1011` suppliername = `Very Best Screens` weightmeasure = '4.1' weightunit = `KG` name = `Notebook Professional 17` currencycode = `EUR` price = '2299' width = '33' depth = '23' height = '2' dimunit = `cm` )
      ( productid = `HT-1020` suppliername = `Technocom` weightmeasure = '0.16' weightunit = `KG` name = `ITelO Vault Net` currencycode = `EUR` price = '459' width = '10' depth = '1.8' height = '17' dimunit = `cm` )
      ( productid = `HT-1021` suppliername = `Technocom` weightmeasure = '0.18' weightunit = `KG` name = `ITelO Vault SAT` currencycode = `EUR` price = '149' width = '11' depth = '1.7' height = '18' dimunit = `cm` )
      ( productid = `HT-1022` suppliername = `Technocom` weightmeasure = '0.2' weightunit = `KG` name = `Comfort Easy` currencycode = `EUR` price = '1679' width = '84' depth = '1.5' height = '14' dimunit = `cm` )
      ( productid = `HT-1023` suppliername = `Technocom` weightmeasure = '0.8' weightunit = `KG` name = `Comfort Senior` currencycode = `EUR` price = '512' width = '80' depth = '1.6' height = '13' dimunit = `cm` )
      ( productid = `HT-1030` suppliername = `Very Best Screens` weightmeasure = '21' weightunit = `KG` name = `Ergo Screen E-I` currencycode = `EUR` price = '230' width = '37' depth = '12' height = '36' dimunit = `cm` )
      ( productid = `HT-1031` suppliername = `Very Best Screens` weightmeasure = '21' weightunit = `KG` name = `Ergo Screen E-II` currencycode = `EUR` price = '285' width = '40.8' depth = '19' height = '43' dimunit = `cm` )
      ( productid = `HT-1032` suppliername = `Very Best Screens` weightmeasure = '21' weightunit = `KG` name = `Ergo Screen E-III` currencycode = `EUR` price = '345' width = '40.8' depth = '19' height = '43' dimunit = `cm` )
      ( productid = `HT-1035` suppliername = `Very Best Screens` weightmeasure = '14' weightunit = `KG` name = `Flat Basic` currencycode = `EUR` price = '399' width = '39' depth = '20' height = '41' dimunit = `cm` )
      ( productid = `HT-1036` suppliername = `Very Best Screens` weightmeasure = '15' weightunit = `KG` name = `Flat Future` currencycode = `EUR` price = '430' width = '45' depth = '26' height = '46' dimunit = `cm` )
      ( productid = `HT-1037` suppliername = `Very Best Screens` weightmeasure = '17' weightunit = `KG` name = `Flat XL` currencycode = `EUR` price = '1230' width = '54.5' depth = '22.1' height = '39.1' dimunit = `cm` )
      ( productid = `HT-1040` suppliername = `Alpha Printers` weightmeasure = '32' weightunit = `KG` name = `Laser Professional Eco` currencycode = `EUR` price = '830' width = '51' depth = '46' height = '30' dimunit = `cm` )
      ( productid = `HT-1041` suppliername = `Alpha Printers` weightmeasure = '23' weightunit = `KG` name = `Laser Basic` currencycode = `EUR` price = '490' width = '48' depth = '42' height = '26' dimunit = `cm` )
      ( productid = `HT-1042` suppliername = `Alpha Printers` weightmeasure = '17' weightunit = `KG` name = `Laser Allround` currencycode = `EUR` price = '349' width = '53' depth = '50' height = '65' dimunit = `cm` )
      ( productid = `HT-1050` suppliername = `Alpha Printers` weightmeasure = '3' weightunit = `KG` name = `Ultra Jet Super Color` currencycode = `EUR` price = '139' width = '41' depth = '41' height = '28' dimunit = `cm` )
      ( productid = `HT-1051` suppliername = `Printer for All` weightmeasure = '1.9' weightunit = `KG` name = `Ultra Jet Mobile` currencycode = `EUR` price = '99' width = '46' depth = '32' height = '25' dimunit = `cm` )
      ( productid = `HT-1052` suppliername = `Printer for All` weightmeasure = '18' weightunit = `KG` name = `Ultra Jet Super Highspeed` currencycode = `EUR` price = '170' width = '41' depth = '41' height = '28' dimunit = `cm` )
      ( productid = `HT-1055` suppliername = `Printer for All` weightmeasure = '6.3' weightunit = `KG` name = `Multi Print` currencycode = `EUR` price = '99' width = '55' depth = '45' height = '29' dimunit = `cm` )
      ( productid = `HT-1056` suppliername = `Printer for All` weightmeasure = '4.3' weightunit = `KG` name = `Multi Color` currencycode = `EUR` price = '119' width = '51' depth = '41.3' height = '22' dimunit = `cm` )
      ( productid = `HT-1060` suppliername = `Oxynum` weightmeasure = '0.09' weightunit = `KG` name = `Cordless Mouse` currencycode = `EUR` price = '9' width = '6' depth = '14.5' height = '3.5' dimunit = `cm` )
      ( productid = `HT-1061` suppliername = `Oxynum` weightmeasure = '0.09' weightunit = `KG` name = `Speed Mouse` currencycode = `EUR` price = '7' width = '7' depth = '15' height = '3.1' dimunit = `cm` )
      ( productid = `HT-1062` suppliername = `Oxynum` weightmeasure = '0.03' weightunit = `KG` name = `Track Mouse` currencycode = `EUR` price = '11' width = '3' depth = '7' height = '4' dimunit = `cm` )
      ( productid = `HT-1063` suppliername = `Oxynum` weightmeasure = '2.1' weightunit = `KG` name = `Ergonomic Keyboard` currencycode = `EUR` price = '14' width = '50' depth = '21' height = '3.5' dimunit = `cm` )
      ( productid = `HT-1064` suppliername = `Oxynum` weightmeasure = '1.8' weightunit = `KG` name = `Internet Keyboard` currencycode = `EUR` price = '16' width = '52' depth = '25' height = '3' dimunit = `cm` )
      ( productid = `HT-1065` suppliername = `Oxynum` weightmeasure = '2.3' weightunit = `KG` name = `Media Keyboard` currencycode = `EUR` price = '26' width = '51.4' depth = '23' height = '4' dimunit = `cm` )
      ( productid = `HT-1066` suppliername = `Oxynum` weightmeasure = '80' weightunit = `G` name = `Mousepad` currencycode = `EUR` price = '6.99' width = '15' depth = '6' height = '0.2' dimunit = `cm` )
      ( productid = `HT-1067` suppliername = `Oxynum` weightmeasure = '80' weightunit = `G` name = `Ergo Mousepad` currencycode = `EUR` price = '8.99' width = '15' depth = '6' height = '0.2' dimunit = `cm` )
      ( productid = `HT-1068` suppliername = `Fasttech` weightmeasure = '90' weightunit = `G` name = `Designer Mousepad` currencycode = `EUR` price = '12.99' width = '24' depth = '24' height = '0.6' dimunit = `cm` )
      ( productid = `HT-1069` suppliername = `Fasttech` weightmeasure = '45' weightunit = `G` name = `Universal card reader` currencycode = `EUR` price = '14' width = '6' depth = '6' height = '3' dimunit = `cm` )
      ( productid = `HT-1070` suppliername = `Ultrasonic United` weightmeasure = '0.255' weightunit = `KG` name = `Proctra X` currencycode = `EUR` price = '70.9' width = '22' depth = '35' height = '17' dimunit = `cm` )
      ( productid = `HT-1071` suppliername = `Ultrasonic United` weightmeasure = '0.3' weightunit = `KG` name = `Gladiator MX` currencycode = `EUR` price = '81.7' width = '22' depth = '35' height = '17' dimunit = `cm` )
      ( productid = `HT-1072` suppliername = `Ultrasonic United` weightmeasure = '0.4' weightunit = `KG` name = `Hurricane GX` currencycode = `EUR` price = '101.2' width = '22' depth = '35' height = '17' dimunit = `cm` )
      ( productid = `HT-1073` suppliername = `Smartcards` weightmeasure = '0.4' weightunit = `KG` name = `Hurricane GX/LN` currencycode = `EUR` price = '139.99' width = '22' depth = '35' height = '17' dimunit = `cm` )
      ( productid = `HT-1080` suppliername = `Printer for All` weightmeasure = '2.3' weightunit = `KG` name = `Photo Scan` currencycode = `EUR` price = '129' width = '34' depth = '48' height = '5' dimunit = `cm` )
      ( productid = `HT-1081` suppliername = `Printer for All` weightmeasure = '2.4' weightunit = `KG` name = `Power Scan` currencycode = `EUR` price = '89' width = '31' depth = '43' height = '7' dimunit = `cm` )
      ( productid = `HT-1082` suppliername = `Printer for All` weightmeasure = '3.2' weightunit = `KG` name = `Jet Scan Professional` currencycode = `EUR` price = '169' width = '33' depth = '41' height = '12' dimunit = `cm` )
      ( productid = `HT-1083` suppliername = `Printer for All` weightmeasure = '3.2' weightunit = `KG` name = `Jet Scan Professional` currencycode = `EUR` price = '189' width = '35' depth = '40' height = '10' dimunit = `cm` )
      ( productid = `HT-1085` suppliername = `Alpha Printers` weightmeasure = '23.2' weightunit = `KG` name = `Copymaster` currencycode = `EUR` price = '1499' width = '45' depth = '42' height = '22' dimunit = `cm` )
      ( productid = `HT-1090` suppliername = `Speaker Experts` weightmeasure = '3' weightunit = `KG` name = `Surround Sound` currencycode = `EUR` price = '39' width = '12' depth = '10' height = '16' dimunit = `cm` )
      ( productid = `HT-1091` suppliername = `Speaker Experts` weightmeasure = '1.4' weightunit = `KG` name = `Blaster Extreme` currencycode = `EUR` price = '26' width = '13' depth = '11' height = '17.5' dimunit = `cm` )
      ( productid = `HT-1092` suppliername = `Speaker Experts` weightmeasure = '2.1' weightunit = `KG` name = `Sound Booster` currencycode = `EUR` price = '45' width = '12.4' depth = '10.4' height = '18.1' dimunit = `cm` )
      ( productid = `HT-1100` suppliername = `Technocom` weightmeasure = '1.2' weightunit = `KG` name = `Smart Office` currencycode = `EUR` price = '89.9' width = '15' depth = '6.5' height = '2.1' dimunit = `cm` )
      ( productid = `HT-1101` suppliername = `Technocom` weightmeasure = '0.8' weightunit = `KG` name = `Smart Design` currencycode = `EUR` price = '79.9' width = '14' depth = '6.7' height = '24' dimunit = `cm` )
      ( productid = `HT-1102` suppliername = `Technocom` weightmeasure = '0.8' weightunit = `KG` name = `Smart Network` currencycode = `EUR` price = '69' width = '16' depth = '6' height = '27' dimunit = `cm` )
      ( productid = `HT-1103` suppliername = `Technocom` weightmeasure = '0.8' weightunit = `KG` name = `Smart Multimedia` currencycode = `EUR` price = '77' width = '11' depth = '3.4' height = '22' dimunit = `cm` )
      ( productid = `HT-1104` suppliername = `Technocom` weightmeasure = '1.1' weightunit = `KG` name = `Smart Games` currencycode = `EUR` price = '55' width = '10' depth = '3' height = '30' dimunit = `cm` )
      ( productid = `HT-1105` suppliername = `Brainsoft` weightmeasure = '0.7' weightunit = `KG` name = `Smart Internet Antivirus` currencycode = `EUR` price = '29' width = '16' depth = '4' height = '21' dimunit = `cm` )
      ( productid = `HT-1106` suppliername = `Brainsoft` weightmeasure = '0.9' weightunit = `KG` name = `Smart Firewall` currencycode = `EUR` price = '34' width = '17.9' depth = '4.2' height = '23.1' dimunit = `cm` )
      ( productid = `HT-1107` suppliername = `Brainsoft` weightmeasure = '0.5' weightunit = `KG` name = `Smart Money` currencycode = `EUR` price = '29.9' width = '12' depth = '1.5' height = '19' dimunit = `cm` )
      ( productid = `HT-1110` suppliername = `Red Point Stores` weightmeasure = '0.03' weightunit = `KG` name = `PC Lock` currencycode = `EUR` price = '8.9' width = '20' depth = '8' height = '4.3' dimunit = `cm` )
      ( productid = `HT-1111` suppliername = `Red Point Stores` weightmeasure = '0.02' weightunit = `KG` name = `Notebook Lock` currencycode = `EUR` price = '6.9' width = '31' depth = '9' height = '7' dimunit = `cm` )
      ( productid = `HT-1112` suppliername = `Red Point Stores` weightmeasure = '0.075' weightunit = `KG` name = `Web cam reality` currencycode = `EUR` price = '39' width = '9' depth = '8.2' height = '1.3' dimunit = `cm` )
      ( productid = `HT-1113` suppliername = `Red Point Stores` weightmeasure = '0.05' weightunit = `KG` name = `Screen clean` currencycode = `EUR` price = '2.3' width = '2' depth = '2' height = '0.1' dimunit = `cm` )
      ( productid = `HT-1114` suppliername = `Red Point Stores` weightmeasure = '1.8' weightunit = `KG` name = `Fabric bag professional` currencycode = `EUR` price = '31' width = '42' depth = '32' height = '7' dimunit = `cm` )
      ( productid = `HT-1115` suppliername = `Red Point Stores` weightmeasure = '0.45' weightunit = `KG` name = `Wireless DSL Router` currencycode = `EUR` price = '49' width = '19.3' depth = '18' height = '5' dimunit = `cm` )
      ( productid = `HT-1116` suppliername = `Red Point Stores` weightmeasure = '0.45' weightunit = `KG` name = `Wireless DSL Router / Repeater` currencycode = `EUR` price = '59' width = '19.3' depth = '18' height = '5' dimunit = `cm` )
      ( productid = `HT-1117` suppliername = `Technocom` weightmeasure = '0.45' weightunit = `KG` name = `Wireless DSL Router / Repeater and Print Server` currencycode = `EUR` price = '69' width = '19.3' depth = '18' height = '5' dimunit = `cm` )
      ( productid = `HT-1118` suppliername = `Technocom` weightmeasure = '0.015' weightunit = `KG` name = `USB Stick` currencycode = `EUR` price = '35' width = '1.5' depth = '8.7' height = '1.2' dimunit = `cm` )
      ( productid = `HT-1120` suppliername = `Technocom` weightmeasure = '1' weightunit = `KG` name = `Cordless Bluetooth Keyboard, english international` currencycode = `EUR` price = '29' width = '51.4' depth = '23' height = '4' dimunit = `cm` )
      ( productid = `HT-1137` suppliername = `Technocom` weightmeasure = '18' weightunit = `KG` name = `Flat XXL` currencycode = `EUR` price = '1430' width = '54' depth = '22' height = '38' dimunit = `cm` )
      ( productid = `HT-1138` suppliername = `Technocom` weightmeasure = '0.02' weightunit = `KG` name = `Pocket Mouse` currencycode = `EUR` price = '23' width = '0.3' depth = '0.5' height = '1' dimunit = `cm` )
      ( productid = `HT-1210` suppliername = `Technocom` weightmeasure = '2.3' weightunit = `KG` name = `PC Power Station` currencycode = `EUR` price = '2399' width = '28' depth = '31' height = '43' dimunit = `cm` )
      ( productid = `HT-1500` suppliername = `Technocom` weightmeasure = '18' weightunit = `KG` name = `Server Basic` currencycode = `EUR` price = '5000' width = '34' depth = '35' height = '23' dimunit = `cm` )
      ( productid = `HT-1501` suppliername = `Technocom` weightmeasure = '25' weightunit = `KG` name = `Server Professional` currencycode = `EUR` price = '15000' width = '29' depth = '30' height = '27' dimunit = `cm` )
      ( productid = `HT-1502` suppliername = `Technocom` weightmeasure = '35' weightunit = `KG` name = `Server Power Pro` currencycode = `EUR` price = '25000' width = '22' depth = '27.3' height = '37' dimunit = `cm` )
      ( productid = `HT-6130` suppliername = `Very Best Screens` weightmeasure = '2.6' weightunit = `KG` name = `Flat Watch HD32` currencycode = `EUR` price = '1459' width = '78' depth = '22.1' height = '55' dimunit = `cm` )
      ( productid = `HT-6131` suppliername = `Very Best Screens` weightmeasure = '2.2' weightunit = `KG` name = `Flat Watch HD37` currencycode = `EUR` price = '1199' width = '99.1' depth = '26' height = '61' dimunit = `cm` )
      ( productid = `HT-6132` suppliername = `Very Best Screens` weightmeasure = '1.8' weightunit = `KG` name = `Flat Watch HD41` currencycode = `EUR` price = '899' width = '128' depth = '23' height = '79.1' dimunit = `cm` )
      ( productid = `HT-7030` suppliername = `Fasttech` weightmeasure = '0.5' weightunit = `KG` name = `Platinberry` currencycode = `EUR` price = '549' width = '8.1' depth = '13' height = '12.1' dimunit = `cm` )
      ( productid = `HT-7020` suppliername = `Fasttech` weightmeasure = '0.5' weightunit = `KG` name = `Goldberry` currencycode = `EUR` price = '549' width = '8.1' depth = '13' height = '12.1' dimunit = `cm` )
      ( productid = `HT-7010` suppliername = `Fasttech` weightmeasure = '0.5' weightunit = `KG` name = `Silverberry` currencycode = `EUR` price = '549' width = '8.1' depth = '13' height = '12.1' dimunit = `cm` )
      ( productid = `HT-7000` suppliername = `Fasttech` weightmeasure = '0.5' weightunit = `KG` name = `Copperberry` currencycode = `EUR` price = '549' width = '8.1' depth = '13' height = '12.1' dimunit = `cm` )
      ( productid = `HT-1095` suppliername = `Fasttech` weightmeasure = '80' weightunit = `G` name = `Lovely Sound 5.1 Wireless` currencycode = `EUR` price = '49' width = '24' depth = '19' height = '23' dimunit = `cm` )
      ( productid = `HT-1096` suppliername = `Fasttech` weightmeasure = '130' weightunit = `G` name = `Lovely Sound 5.1` currencycode = `EUR` price = '39' width = '25' depth = '17' height = '19' dimunit = `cm` )
      ( productid = `HT-1097` suppliername = `Fasttech` weightmeasure = '60' weightunit = `G` name = `Lovely Sound Stereo` currencycode = `EUR` price = '29' width = '21.3' depth = '2.4' height = '19.7' dimunit = `cm` )
      ( productid = `HT-6123` suppliername = `Fasttech` weightmeasure = '267' weightunit = `G` name = `Power Pro Player 80` currencycode = `EUR` price = '299' width = '4' depth = '6' height = '0.8' dimunit = `cm` )
      ( productid = `HT-6122` suppliername = `Fasttech` weightmeasure = '266' weightunit = `G` name = `Power Pro Player 40` currencycode = `EUR` price = '167' width = '5.1' depth = '8' height = '9.2' dimunit = `cm` )
      ( productid = `HT-6121` suppliername = `Fasttech` weightmeasure = '134' weightunit = `G` name = `ITelo Jog-Mate` currencycode = `EUR` price = '63' width = '5.1' depth = '8' height = '9.2' dimunit = `cm` )
      ( productid = `HT-6120` suppliername = `Fasttech` weightmeasure = '134' weightunit = `G` name = `ITelo MusicStick` currencycode = `EUR` price = '45' width = '1.5' depth = '6' height = '1' dimunit = `cm` )
      ( productid = `HT-6111` suppliername = `Fasttech` weightmeasure = '3.1' weightunit = `KG` name = `Record Movie` currencycode = `EUR` price = '288' width = '38' depth = '26' height = '6.2' dimunit = `cm` )
      ( productid = `HT-6110` suppliername = `Fasttech` weightmeasure = '2.4' weightunit = `KG` name = `Play Movie` currencycode = `EUR` price = '130' width = '37' depth = '24' height = '6' dimunit = `cm` )
      ( productid = `HT-6102` suppliername = `Technocom` weightmeasure = '2.5' weightunit = `KG` name = `Beam Breaker B-3` currencycode = `EUR` price = '889' width = '30.4' depth = '23.1' height = '23' dimunit = `cm` )
      ( productid = `HT-6101` suppliername = `Technocom` weightmeasure = '2' weightunit = `KG` name = `Beam Breaker B-2` currencycode = `EUR` price = '679' width = '30.4' depth = '23.1' height = '23' dimunit = `cm` )
      ( productid = `HT-2002` suppliername = `Technocom` weightmeasure = '0.72' weightunit = `KG` name = `Portable DVD Player with 9" LCD Monitor` currencycode = `EUR` price = '853.99' width = '21' depth = '16.5' height = '14' dimunit = `cm` )
      ( productid = `HT-6100` suppliername = `Titanium` weightmeasure = '1.7' weightunit = `KG` name = `Beam Breaker B-1` currencycode = `EUR` price = '469' width = '30.4' depth = '23.1' height = '23' dimunit = `cm` )
      ( productid = `HT-2027` suppliername = `Titanium` weightmeasure = '0.15' weightunit = `KG` name = `Removable CD/DVD Laser Labels` currencycode = `EUR` price = '8.99' width = '5.5' depth = '2' height = '2' dimunit = `cm` )
      ( productid = `HT-2026` suppliername = `Titanium` weightmeasure = '0.2' weightunit = `KG` name = `Audio/Video Cable Kit - 4m` currencycode = `EUR` price = '29.99' width = '21' depth = '10.2' height = '13' dimunit = `cm` )
      ( productid = `HT-2025` suppliername = `Titanium` weightmeasure = '0.65' weightunit = `KG` name = `CD/DVD case: 264 sleeves` currencycode = `EUR` price = '44.99' width = '13' depth = '13' height = '20' dimunit = `cm` )
      ( productid = `HT-2001` suppliername = `Titanium` weightmeasure = '0.84' weightunit = `KG` name = `10" Portable DVD player` currencycode = `EUR` price = '449.99' width = '24' depth = '19.5' height = '29' dimunit = `cm` )
      ( productid = `HT-2000` suppliername = `Titanium` weightmeasure = '0.79' weightunit = `KG` name = `7" Widescreen Portable DVD Player w MP3` currencycode = `EUR` price = '249.99' width = '21.4' depth = '19' height = '27.6' dimunit = `cm` )
      ( productid = `HT-1603` suppliername = `Titanium` weightmeasure = '6.8' weightunit = `KG` name = `Gaming Monster Pro` currencycode = `EUR` price = '1700' width = '27' depth = '28' height = '42' dimunit = `cm` )
      ( productid = `HT-1602` suppliername = `Titanium` weightmeasure = '5.9' weightunit = `KG` name = `Gaming Monster` currencycode = `EUR` price = '1200' width = '26.5' depth = '34' height = '47' dimunit = `cm` )
      ( productid = `HT-1601` suppliername = `Titanium` weightmeasure = '5.3' weightunit = `KG` name = `Family PC Pro` currencycode = `EUR` price = '900' width = '25' depth = '31.7' height = '40.2' dimunit = `cm` )
      ( productid = `HT-1600` suppliername = `Titanium` weightmeasure = '4.8' weightunit = `KG` name = `Family PC Basic` currencycode = `EUR` price = '600' width = '21.4' depth = '29' height = '38' dimunit = `cm` )
      ( productid = `HT-1119` suppliername = `Titanium` weightmeasure = '88' weightunit = `G` name = `Travel Adapter` currencycode = `EUR` price = '79' width = '2' depth = '3.1' height = '3.9' dimunit = `cm` )
      ( productid = `HT-8000` suppliername = `Titanium` weightmeasure = '4' weightunit = `KG` name = `ITelO FlexTop I4000` currencycode = `EUR` price = '799' width = '31' depth = '19' height = '3.1' dimunit = `cm` )
      ( productid = `HT-8001` suppliername = `Titanium` weightmeasure = '4.2' weightunit = `KG` name = `ITelO FlexTop I6300c` currencycode = `EUR` price = '799' width = '32' depth = '20' height = '3.4' dimunit = `cm` )
      ( productid = `HT-8002` suppliername = `Titanium` weightmeasure = '3.5' weightunit = `KG` name = `ITelO FlexTop I9100` currencycode = `EUR` price = '1199' width = '38' depth = '21' height = '4.1' dimunit = `cm` )
      ( productid = `HT-8003` suppliername = `Titanium` weightmeasure = '3.8' weightunit = `KG` name = `ITelO FlexTop I9800` currencycode = `EUR` price = '1388' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `PF-1000` suppliername = `Titanium` weightmeasure = '0.01' weightunit = `KG` name = `Flyer` currencycode = `EUR` price = '0' width = '46' depth = '30' height = '3' dimunit = `cm` )
      ( productid = `HT-9999` suppliername = `Titanium` weightmeasure = '3.8' weightunit = `KG` name = `Maxi Tablet` currencycode = `EUR` price = '749' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9998` suppliername = `Titanium` weightmeasure = '0.75' weightunit = `KG` name = `Smartphone Beta` currencycode = `EUR` price = '30' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9997` suppliername = `Titanium` weightmeasure = '3.8' weightunit = `KG` name = `e-Book Reader ReadMe` currencycode = `EUR` price = '33' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9996` suppliername = `Titanium` weightmeasure = '0.03' weightunit = `KG` name = `Tablet Pouch` currencycode = `EUR` price = '20' width = '25' depth = '40' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9995` suppliername = `Titanium` weightmeasure = '0.02' weightunit = `KG` name = `Smartphone Cover` currencycode = `EUR` price = '15' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9994` suppliername = `Ultrasonic United` weightmeasure = '3.8' weightunit = `KG` name = `Camcorder View` currencycode = `EUR` price = '1388' width = '48' depth = '31' height = '27' dimunit = `cm` )
      ( productid = `HT-9993` suppliername = `Ultrasonic United` weightmeasure = '3.8' weightunit = `KG` name = `Mini Tablet` currencycode = `EUR` price = '833' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9992` suppliername = `Ultrasonic United` weightmeasure = '0.75' weightunit = `KG` name = `Smartphone Alpha` currencycode = `EUR` price = '599' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-9991` suppliername = `Ultrasonic United` weightmeasure = '0.02' weightunit = `KG` name = `Smartphone Leather Case` currencycode = `EUR` price = '25' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-1251` suppliername = `Ultrasonic United` weightmeasure = '4.2' weightunit = `KG` name = `Astro Laptop 1516` currencycode = `EUR` price = '989' width = '30' depth = '18' height = '3' dimunit = `cm` )
      ( productid = `HT-1252` suppliername = `Ultrasonic United` weightmeasure = '0.75' weightunit = `KG` name = `Astro Phone 6` currencycode = `EUR` price = '649' width = '8' depth = '6' height = '1.5' dimunit = `cm` )
      ( productid = `HT-1253` suppliername = `Ultrasonic United` weightmeasure = '4.2' weightunit = `KG` name = `Benda Laptop 1408` currencycode = `EUR` price = '976' width = '30' depth = '18' height = '3' dimunit = `cm` )
      ( productid = `HT-1254` suppliername = `Ultrasonic United` weightmeasure = '15' weightunit = `KG` name = `Bending Screen 21HD` currencycode = `EUR` price = '250' width = '37' depth = '12' height = '36' dimunit = `cm` )
      ( productid = `HT-1255` suppliername = `Ultrasonic United` weightmeasure = '16' weightunit = `KG` name = `Broad Screen 22HD` currencycode = `EUR` price = '270' width = '39' depth = '12' height = '38' dimunit = `cm` )
      ( productid = `HT-1256` suppliername = `Ultrasonic United` weightmeasure = '0.75' weightunit = `KG` name = `Cerdik Phone 7` currencycode = `EUR` price = '549' width = '9' depth = '15' height = '1.5' dimunit = `cm` )
      ( productid = `HT-1257` suppliername = `Ultrasonic United` weightmeasure = '2.8' weightunit = `KG` name = `Cepat Tablet 10.5` currencycode = `EUR` price = '549' width = '48' depth = '31' height = '4.5' dimunit = `cm` )
      ( productid = `HT-1258` suppliername = `Ultrasonic United` weightmeasure = '2.5' weightunit = `KG` name = `Cepat Tablet 8` currencycode = `EUR` price = '529' width = '38' depth = '21' height = '3.5' dimunit = `cm` ) ).


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
