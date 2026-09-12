" @keywords popover sap.m controlling click behavior html app table toolbar title column text
" @summary In some cases the closing behavior of the Popover can lead to drill down navigation. This sample demonstrates how you can control this.
" @origin sap.m.sample.PopoverControllingCloseBehavior - https://sdk.openui5.org/entity/sap.m.Popover/sample/sap.m.sample.PopoverControllingCloseBehavior (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_094 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        quantity      TYPE string,
        uom           TYPE string,
        weightmeasure TYPE string,
        weightunit    TYPE string,
        price         TYPE p LENGTH 8 DECIMALS 2,
        currencycode  TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_094 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      " onInit: oModel.setSizeLimit( 10 ) - the model-level limit 1:1, so the
      " table renders the ten rows the original shows, not all 123
      client->follow_up_action( val   = client->cs_event-set_size_limit
                                t_arg = VALUE #( ( `10` ) ( client->cs_view-main ) ) ).
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
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        " the rule behind disablePointerEvents/enablePointerEvents. The css
        " control method cannot carry it - pointer-events is not on the
        " framework's CSS_PROPERTIES whitelist - so the popover toggles a
        " style CLASS instead, which is. \{ \} escaped: the XMLView parser
        " reads an unescaped brace as a binding
        )->tag( n = `HTML` ns = `core`
            )->a( n = `content` v = `<style>.tableNoPointerEvents\{pointer-events:none\}</style>`

        )->ele( `App`
            )->ele( `pages`
                )->ele( `Page`
                    )->a( n = `class` v = `sapUiContentPadding`
                    )->a( n = `title` v = `Header`
                    )->ele( `content`
                        )->ele( `Table`
                            )->a( n = `id`        v = `idProductsTable`
                            )->a( n = `mode`      v = `MultiSelect`
                            )->a( n = `inset`     v = `false`
                            )->a( n = `items`     v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|
                            )->a( n = `itemPress` v = client->_event( `DRILL` )

                            )->ele( `headerToolbar`
                                )->ele( `Toolbar`
                                    )->tag( `Title`
                                        )->a( n = `text`  v = `Table - click events are disabled while a popover is open`
                                        )->a( n = `level` v = `H2`

                                )->end(
                            )->end(

                            )->ele( `columns`
                                )->ele( `Column`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `Product`

                                )->end(
                                )->ele( `Column`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `ID (Example feature)`

                                )->end(
                                )->ele( `Column`
                                    )->a( n = `hAlign`         v = `End`
                                    )->a( n = `width`          v = `12em`
                                    )->a( n = `minScreenWidth` v = `Tablet`
                                    )->a( n = `demandPopin`    v = `true`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `Quantity`

                                )->end(
                                )->ele( `Column`
                                    )->a( n = `minScreenWidth` v = `Tablet`
                                    )->a( n = `demandPopin`    v = `true`
                                    )->a( n = `hAlign`         v = `End`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `Weight`

                                )->end(
                                )->ele( `Column`
                                    )->a( n = `hAlign` v = `End`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `Unit Price`

                                )->end(
                            )->end(

                            )->ele( `items`
                                )->ele( `ColumnListItem`
                                    )->a( n = `vAlign` v = `Middle`
                                    )->a( n = `type`   v = `Navigation`
                                    )->ele( `cells`
                                        )->tag( `ObjectIdentifier`
                                            )->a( n = `title` v = `{NAME}`
                                        )->tag( `Link`
                                            )->a( n = `text`         v = `{PRODUCTID}`
                                            )->a( n = `press`        v = client->_event( val   = `POPOVER`
                                                                                         t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath().split('/').pop()` ) ( `$event.oSource.sId` ) ) )
                                            )->a( n = `ariaHasPopup` v = `Dialog`
                                        )->tag( `Input`
                                            )->a( n = `value`       v = `{QUANTITY}`
                                            " the ORIGINAL writes type="{Text}"
                                            " (PopoverControllingCloseBehavior.view.xml): it meant the literal
                                            " enum value and wrote a binding, so the property falls back to
                                            " its default. Ported verbatim rather than repaired
                                            " abap2ui5lint-disable-next-line unknown-binding-path -- the sample's own quirk
                                            )->a( n = `type`        v = `{Text}`
                                            )->a( n = `description` v = `{UOM}`
                                            )->a( n = `fieldWidth`  v = `{60%}`
                                        )->tag( `ObjectNumber`
                                            )->a( n = `number` v = `{WEIGHTMEASURE}`
                                            )->a( n = `unit`   v = `{WEIGHTUNIT}`
                                        )->tag( `ObjectNumber`
                                            )->a( n = `number` v = |\{ parts:[\{path:'PRICE'\},\{path:'CURRENCYCODE'\}], type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: false\} \}|
                                            )->a( n = `unit`   v = `{CURRENCYCODE}`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
      WHEN `DRILL`.
        client->message_toast_display( `Drill down activated.` ).
      WHEN `ACTION`.
        " the popover's Action button: toast + close (1:1 with the original
        " handleActionPress - MessageToast.show + myPopover.close())
        client->message_toast_display( `Action has been pressed` ).
        client->follow_up_action( client->cs_event-popover_close ).
      WHEN `POPOVER`.
        " the original opens a Popover bound to the pressed row (title=ProductId,
        " Name + Image). Instead of copying each field into an event arg, the
        " popover uses relative bindings and follow_up_action element-binds the
        " popover slot to t_products/<index>; the row index and the Link's control
        " id arrive as the two event args.
        DATA(idx) = client->get_event_arg( ).
        DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).
        popup->ele( n = `FragmentDefinition` ns = `core`
            )->a( n = `xmlns`      v = `sap.m`
            )->a( n = `xmlns:core` v = `sap.ui.core`
            )->ele( `Popover`
                )->a( n = `id`           v = `myPopover`
                )->a( n = `title`        v = `{PRODUCTID}`
                )->a( n = `class`        v = `sapUiContentPadding`
                )->a( n = `placement`    v = `Right`
                )->a( n = `initialFocus` v = `action`
                " attachAfterOpen -> disablePointerEvents, afterClose -> enable:
                " clicks on the table are dead while the popover is open, which
                " is the behaviour the page header advertises
                )->a( n = `afterOpen`    v = client->follow_up_action(
                                                val   = client->cs_event-control_by_id
                                                t_arg = VALUE #( ( `idProductsTable` ) ( `addStyleClass` ) ( `tableNoPointerEvents` ) ) )
                )->a( n = `afterClose`   v = client->follow_up_action(
                                                val   = client->cs_event-control_by_id
                                                t_arg = VALUE #( ( `idProductsTable` ) ( `removeStyleClass` ) ( `tableNoPointerEvents` ) ) )
                )->ele( `footer`
                    )->ele( `Toolbar`
                        )->tag( `ToolbarSpacer`
                        )->tag( `Button`
                            )->a( n = `id`    v = `action`
                            )->a( n = `text`  v = `Action`
                            )->a( n = `press` v = client->_event( `ACTION` )

                    )->end(
                )->end(
                )->ele( `VBox`
                    )->tag( `Title`
                        )->a( n = `text` v = `{NAME}`
                    )->tag( `Image`
                        )->a( n = `src`          v = `{PRODUCTPICURL}`
                        )->a( n = `width`        v = `15em`
                        )->a( n = `densityAware` v = `false`

                )->end(
            )->end( ).
        client->popover_display( xml   = popup->stringify( )
                                 by_id = client->get_event_arg( 2 ) ).
        client->follow_up_action( val   = client->cs_event-bind_element
                                  view  = client->cs_view-popover
                                  t_arg = VALUE #( ( idx ) ( client->_bind( t_products ) ) ) ).
    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection (sap/ui/demo/mock/products.json), verbatim
    t_products = VALUE #(
      ( name = `Notebook Basic 15` productid = `HT-1000` quantity = `10` uom = `PC` weightmeasure = `4.2` weightunit = `KG`
        price = '956.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg` )
      ( name = `Notebook Basic 17` productid = `HT-1001` quantity = `20` uom = `PC` weightmeasure = `4.5` weightunit = `KG`
        price = '1249.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg` )
      ( name = `Notebook Basic 18` productid = `HT-1002` quantity = `10` uom = `PC` weightmeasure = `4.2` weightunit = `KG`
        price = '1570.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg` )
      ( name = `Notebook Basic 19` productid = `HT-1003` quantity = `15` uom = `PC` weightmeasure = `4.2` weightunit = `KG`
        price = '1650.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg` )
      ( name = `ITelO Vault` productid = `HT-1007` quantity = `15` uom = `PC` weightmeasure = `0.2` weightunit = `KG`
        price = '299.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg` )
      ( name = `Notebook Professional 15` productid = `HT-1010` quantity = `16` uom = `PC` weightmeasure = `4.3` weightunit = `KG`
        price = '1999.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg` )
      ( name = `Notebook Professional 17` productid = `HT-1011` quantity = `17` uom = `PC` weightmeasure = `4.1` weightunit = `KG`
        price = '2299.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg` )
      ( name = `ITelO Vault Net` productid = `HT-1020` quantity = `14` uom = `PC` weightmeasure = `0.16` weightunit = `KG`
        price = '459.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg` )
      ( name = `ITelO Vault SAT` productid = `HT-1021` quantity = `50` uom = `PC` weightmeasure = `0.18` weightunit = `KG`
        price = '149.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg` )
      ( name = `Comfort Easy` productid = `HT-1022` quantity = `30` uom = `PC` weightmeasure = `0.2` weightunit = `KG`
        price = '1679.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg` )
      ( name = `Comfort Senior` productid = `HT-1023` quantity = `24` uom = `PC` weightmeasure = `0.8` weightunit = `KG`
        price = '512.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg` )
      ( name = `Ergo Screen E-I` productid = `HT-1030` quantity = `14` uom = `PC` weightmeasure = `21` weightunit = `KG`
        price = '230.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg` )
      ( name = `Ergo Screen E-II` productid = `HT-1031` quantity = `24` uom = `PC` weightmeasure = `21` weightunit = `KG`
        price = '285.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg` )
      ( name = `Ergo Screen E-III` productid = `HT-1032` quantity = `50` uom = `PC` weightmeasure = `21` weightunit = `KG`
        price = '345.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg` )
      ( name = `Flat Basic` productid = `HT-1035` quantity = `23` uom = `PC` weightmeasure = `14` weightunit = `KG`
        price = '399.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg` )
      ( name = `Flat Future` productid = `HT-1036` quantity = `22` uom = `PC` weightmeasure = `15` weightunit = `KG`
        price = '430.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg` )
      ( name = `Flat XL` productid = `HT-1037` quantity = `23` uom = `PC` weightmeasure = `17` weightunit = `KG`
        price = '1230.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg` )
      ( name = `Laser Professional Eco` productid = `HT-1040` quantity = `21` uom = `PC` weightmeasure = `32` weightunit = `KG`
        price = '830.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg` )
      ( name = `Laser Basic` productid = `HT-1041` quantity = `8` uom = `PC` weightmeasure = `23` weightunit = `KG`
        price = '490.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg` )
      ( name = `Laser Allround` productid = `HT-1042` quantity = `9` uom = `PC` weightmeasure = `17` weightunit = `KG`
        price = '349.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg` )
      ( name = `Ultra Jet Super Color` productid = `HT-1050` quantity = `17` uom = `PC` weightmeasure = `3` weightunit = `KG`
        price = '139.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg` )
      ( name = `Ultra Jet Mobile` productid = `HT-1051` quantity = `18` uom = `PC` weightmeasure = `1.9` weightunit = `KG`
        price = '99.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg` )
      ( name = `Ultra Jet Super Highspeed` productid = `HT-1052` quantity = `25` uom = `PC` weightmeasure = `18` weightunit = `KG`
        price = '170.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg` )
      ( name = `Multi Print` productid = `HT-1055` quantity = `16` uom = `PC` weightmeasure = `6.3` weightunit = `KG`
        price = '99.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg` )
      ( name = `Multi Color` productid = `HT-1056` quantity = `5` uom = `PC` weightmeasure = `4.3` weightunit = `KG`
        price = '119.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg` )
      ( name = `Cordless Mouse` productid = `HT-1060` quantity = `25` uom = `PC` weightmeasure = `0.09` weightunit = `KG`
        price = '9.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg` )
      ( name = `Speed Mouse` productid = `HT-1061` quantity = `12` uom = `PC` weightmeasure = `0.09` weightunit = `KG`
        price = '7.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg` )
      ( name = `Track Mouse` productid = `HT-1062` quantity = `12` uom = `PC` weightmeasure = `0.03` weightunit = `KG`
        price = '11.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg` )
      ( name = `Ergonomic Keyboard` productid = `HT-1063` quantity = `50` uom = `PC` weightmeasure = `2.1` weightunit = `KG`
        price = '14.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg` )
      ( name = `Internet Keyboard` productid = `HT-1064` quantity = `35` uom = `PC` weightmeasure = `1.8` weightunit = `KG`
        price = '16.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg` )
      ( name = `Media Keyboard` productid = `HT-1065` quantity = `26` uom = `PC` weightmeasure = `2.3` weightunit = `KG`
        price = '26.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg` )
      ( name = `Mousepad` productid = `HT-1066` quantity = `12` uom = `PC` weightmeasure = `80` weightunit = `G`
        price = '6.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg` )
      ( name = `Ergo Mousepad` productid = `HT-1067` quantity = `16` uom = `PC` weightmeasure = `80` weightunit = `G`
        price = '8.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg` )
      ( name = `Designer Mousepad` productid = `HT-1068` quantity = `26` uom = `PC` weightmeasure = `90` weightunit = `G`
        price = '12.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg` )
      ( name = `Universal card reader` productid = `HT-1069` quantity = `22` uom = `PC` weightmeasure = `45` weightunit = `G`
        price = '14.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg` )
      ( name = `Proctra X` productid = `HT-1070` quantity = `15` uom = `PC` weightmeasure = `0.255` weightunit = `KG`
        price = '70.90' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg` )
      ( name = `Gladiator MX` productid = `HT-1071` quantity = `16` uom = `PC` weightmeasure = `0.3` weightunit = `KG`
        price = '81.70' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg` )
      ( name = `Hurricane GX` productid = `HT-1072` quantity = `13` uom = `PC` weightmeasure = `0.4` weightunit = `KG`
        price = '101.20' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg` )
      ( name = `Hurricane GX/LN` productid = `HT-1073` quantity = `5` uom = `PC` weightmeasure = `0.4` weightunit = `KG`
        price = '139.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg` )
      ( name = `Photo Scan` productid = `HT-1080` quantity = `8` uom = `PC` weightmeasure = `2.3` weightunit = `KG`
        price = '129.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg` )
      ( name = `Power Scan` productid = `HT-1081` quantity = `11` uom = `PC` weightmeasure = `2.4` weightunit = `KG`
        price = '89.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg` )
      ( name = `Jet Scan Professional` productid = `HT-1082` quantity = `13` uom = `PC` weightmeasure = `3.2` weightunit = `KG`
        price = '169.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg` )
      ( name = `Jet Scan Professional` productid = `HT-1083` quantity = `10` uom = `PC` weightmeasure = `3.2` weightunit = `KG`
        price = '189.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg` )
      ( name = `Copymaster` productid = `HT-1085` quantity = `10` uom = `PC` weightmeasure = `23.2` weightunit = `KG`
        price = '1499.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg` )
      ( name = `Surround Sound` productid = `HT-1090` quantity = `20` uom = `PC` weightmeasure = `3` weightunit = `KG`
        price = '39.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg` )
      ( name = `Blaster Extreme` productid = `HT-1091` quantity = `15` uom = `PC` weightmeasure = `1.4` weightunit = `KG`
        price = '26.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg` )
      ( name = `Sound Booster` productid = `HT-1092` quantity = `50` uom = `PC` weightmeasure = `2.1` weightunit = `KG`
        price = '45.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg` )
      ( name = `Lovely Sound 5.1 Wireless` productid = `HT-1095` quantity = `12` uom = `PC` weightmeasure = `80` weightunit = `G`
        price = '49.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg` )
      ( name = `Lovely Sound 5.1` productid = `HT-1096` quantity = `18` uom = `PC` weightmeasure = `130` weightunit = `G`
        price = '39.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg` )
      ( name = `Lovely Sound Stereo` productid = `HT-1097` quantity = `21` uom = `PC` weightmeasure = `60` weightunit = `G`
        price = '29.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg` )
      ( name = `Smart Office` productid = `HT-1100` quantity = `25` uom = `PC` weightmeasure = `1.2` weightunit = `KG`
        price = '89.90' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg` )
      ( name = `Smart Design` productid = `HT-1101` quantity = `26` uom = `PC` weightmeasure = `0.8` weightunit = `KG`
        price = '79.90' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg` )
      ( name = `Smart Network` productid = `HT-1102` quantity = `28` uom = `PC` weightmeasure = `0.8` weightunit = `KG`
        price = '69.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg` )
      ( name = `Smart Multimedia` productid = `HT-1103` quantity = `9` uom = `PC` weightmeasure = `0.8` weightunit = `KG`
        price = '77.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg` )
      ( name = `Smart Games` productid = `HT-1104` quantity = `13` uom = `PC` weightmeasure = `1.1` weightunit = `KG`
        price = '55.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg` )
      ( name = `Smart Internet Antivirus` productid = `HT-1105` quantity = `17` uom = `PC` weightmeasure = `0.7` weightunit = `KG`
        price = '29.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg` )
      ( name = `Smart Firewall` productid = `HT-1106` quantity = `19` uom = `PC` weightmeasure = `0.9` weightunit = `KG`
        price = '34.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg` )
      ( name = `Smart Money` productid = `HT-1107` quantity = `18` uom = `PC` weightmeasure = `0.5` weightunit = `KG`
        price = '29.90' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg` )
      ( name = `PC Lock` productid = `HT-1110` quantity = `14` uom = `PC` weightmeasure = `0.03` weightunit = `KG`
        price = '8.90' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg` )
      ( name = `Notebook Lock` productid = `HT-1111` quantity = `20` uom = `PC` weightmeasure = `0.02` weightunit = `KG`
        price = '6.90' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg` )
      ( name = `Web cam reality` productid = `HT-1112` quantity = `27` uom = `PC` weightmeasure = `0.075` weightunit = `KG`
        price = '39.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg` )
      ( name = `Screen clean` productid = `HT-1113` quantity = `17` uom = `PC` weightmeasure = `0.05` weightunit = `KG`
        price = '2.30' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg` )
      ( name = `Fabric bag professional` productid = `HT-1114` quantity = `14` uom = `PC` weightmeasure = `1.8` weightunit = `KG`
        price = '31.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg` )
      ( name = `Wireless DSL Router` productid = `HT-1115` quantity = `16` uom = `PC` weightmeasure = `0.45` weightunit = `KG`
        price = '49.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg` )
      ( name = `Wireless DSL Router / Repeater` productid = `HT-1116` quantity = `12` uom = `PC` weightmeasure = `0.45` weightunit = `KG`
        price = '59.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg` )
      ( name = `Wireless DSL Router / Repeater and Print Server` productid = `HT-1117` quantity = `12` uom = `PC` weightmeasure = `0.45` weightunit = `KG`
        price = '69.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg` )
      ( name = `USB Stick` productid = `HT-1118` quantity = `14` uom = `PC` weightmeasure = `0.015` weightunit = `KG`
        price = '35.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg` )
      ( name = `Travel Adapter` productid = `HT-1119` quantity = `10` uom = `PC` weightmeasure = `88` weightunit = `G`
        price = '79.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg` )
      ( name = `Cordless Bluetooth Keyboard, english international` productid = `HT-1120` quantity = `13` uom = `PC` weightmeasure = `1` weightunit = `KG`
        price = '29.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg` )
      ( name = `Flat XXL` productid = `HT-1137` quantity = `10` uom = `PC` weightmeasure = `18` weightunit = `KG`
        price = '1430.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg` )
      ( name = `Pocket Mouse` productid = `HT-1138` quantity = `20` uom = `PC` weightmeasure = `0.02` weightunit = `KG`
        price = '23.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg` )
      ( name = `PC Power Station` productid = `HT-1210` quantity = `22` uom = `PC` weightmeasure = `2.3` weightunit = `KG`
        price = '2399.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg` )
      ( name = `Astro Laptop 1516` productid = `HT-1251` quantity = `23` uom = `PC` weightmeasure = `4.2` weightunit = `KG`
        price = '989.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg` )
      ( name = `Astro Phone 6` productid = `HT-1252` quantity = `28` uom = `PC` weightmeasure = `0.75` weightunit = `KG`
        price = '649.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg` )
      ( name = `Benda Laptop 1408` productid = `HT-1253` quantity = `27` uom = `PC` weightmeasure = `4.2` weightunit = `KG`
        price = '976.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg` )
      ( name = `Bending Screen 21HD` productid = `HT-1254` quantity = `23` uom = `PC` weightmeasure = `15` weightunit = `KG`
        price = '250.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg` )
      ( name = `Broad Screen 22HD` productid = `HT-1255` quantity = `5` uom = `PC` weightmeasure = `16` weightunit = `KG`
        price = '270.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg` )
      ( name = `Cerdik Phone 7` productid = `HT-1256` quantity = `19` uom = `PC` weightmeasure = `0.75` weightunit = `KG`
        price = '549.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg` )
      ( name = `Cepat Tablet 10.5` productid = `HT-1257` quantity = `17` uom = `PC` weightmeasure = `2.8` weightunit = `KG`
        price = '549.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg` )
      ( name = `Cepat Tablet 8` productid = `HT-1258` quantity = `24` uom = `PC` weightmeasure = `2.5` weightunit = `KG`
        price = '529.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg` )
      ( name = `Server Basic` productid = `HT-1500` quantity = `24` uom = `PC` weightmeasure = `18` weightunit = `KG`
        price = '5000.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg` )
      ( name = `Server Professional` productid = `HT-1501` quantity = `26` uom = `PC` weightmeasure = `25` weightunit = `KG`
        price = '15000.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg` )
      ( name = `Server Power Pro` productid = `HT-1502` quantity = `34` uom = `PC` weightmeasure = `35` weightunit = `KG`
        price = '25000.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg` )
      ( name = `Family PC Basic` productid = `HT-1600` quantity = `10` uom = `PC` weightmeasure = `4.8` weightunit = `KG`
        price = '600.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg` )
      ( name = `Family PC Pro` productid = `HT-1601` quantity = `20` uom = `PC` weightmeasure = `5.3` weightunit = `KG`
        price = '900.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg` )
      ( name = `Gaming Monster` productid = `HT-1602` quantity = `24` uom = `PC` weightmeasure = `5.9` weightunit = `KG`
        price = '1200.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg` )
      ( name = `Gaming Monster Pro` productid = `HT-1603` quantity = `25` uom = `PC` weightmeasure = `6.8` weightunit = `KG`
        price = '1700.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg` )
      ( name = `7" Widescreen Portable DVD Player w MP3` productid = `HT-2000` quantity = `20` uom = `PC` weightmeasure = `0.79` weightunit = `KG`
        price = '249.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg` )
      ( name = `10" Portable DVD player` productid = `HT-2001` quantity = `21` uom = `PC` weightmeasure = `0.84` weightunit = `KG`
        price = '449.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg` )
      ( name = `Portable DVD Player with 9" LCD Monitor` productid = `HT-2002` quantity = `50` uom = `PC` weightmeasure = `0.72` weightunit = `KG`
        price = '853.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg` )
      ( name = `CD/DVD case: 264 sleeves` productid = `HT-2025` quantity = `26` uom = `PC` weightmeasure = `0.65` weightunit = `KG`
        price = '44.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg` )
      ( name = `Audio/Video Cable Kit - 4m` productid = `HT-2026` quantity = `16` uom = `PC` weightmeasure = `0.2` weightunit = `KG`
        price = '29.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg` )
      ( name = `Removable CD/DVD Laser Labels` productid = `HT-2027` quantity = `25` uom = `PC` weightmeasure = `0.15` weightunit = `KG`
        price = '8.99' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg` )
      ( name = `Beam Breaker B-1` productid = `HT-6100` quantity = `32` uom = `PC` weightmeasure = `1.7` weightunit = `KG`
        price = '469.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg` )
      ( name = `Beam Breaker B-2` productid = `HT-6101` quantity = `18` uom = `PC` weightmeasure = `2` weightunit = `KG`
        price = '679.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg` )
      ( name = `Beam Breaker B-3` productid = `HT-6102` quantity = `16` uom = `PC` weightmeasure = `2.5` weightunit = `KG`
        price = '889.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg` )
      ( name = `Play Movie` productid = `HT-6110` quantity = `15` uom = `PC` weightmeasure = `2.4` weightunit = `KG`
        price = '130.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg` )
      ( name = `Record Movie` productid = `HT-6111` quantity = `24` uom = `PC` weightmeasure = `3.1` weightunit = `KG`
        price = '288.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg` )
      ( name = `ITelo MusicStick` productid = `HT-6120` quantity = `15` uom = `PC` weightmeasure = `134` weightunit = `G`
        price = '45.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg` )
      ( name = `ITelo Jog-Mate` productid = `HT-6121` quantity = `24` uom = `PC` weightmeasure = `134` weightunit = `G`
        price = '63.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg` )
      ( name = `Power Pro Player 40` productid = `HT-6122` quantity = `23` uom = `PC` weightmeasure = `266` weightunit = `G`
        price = '167.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg` )
      ( name = `Power Pro Player 80` productid = `HT-6123` quantity = `13` uom = `PC` weightmeasure = `267` weightunit = `G`
        price = '299.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg` )
      ( name = `Flat Watch HD32` productid = `HT-6130` quantity = `16` uom = `PC` weightmeasure = `2.6` weightunit = `KG`
        price = '1459.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg` )
      ( name = `Flat Watch HD37` productid = `HT-6131` quantity = `14` uom = `PC` weightmeasure = `2.2` weightunit = `KG`
        price = '1199.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg` )
      ( name = `Flat Watch HD41` productid = `HT-6132` quantity = `13` uom = `PC` weightmeasure = `1.8` weightunit = `KG`
        price = '899.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg` )
      ( name = `Copperberry` productid = `HT-7000` quantity = `5` uom = `PC` weightmeasure = `0.5` weightunit = `KG`
        price = '549.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg` )
      ( name = `Silverberry` productid = `HT-7010` quantity = `9` uom = `PC` weightmeasure = `0.5` weightunit = `KG`
        price = '549.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg` )
      ( name = `Goldberry` productid = `HT-7020` quantity = `11` uom = `PC` weightmeasure = `0.5` weightunit = `KG`
        price = '549.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg` )
      ( name = `Platinberry` productid = `HT-7030` quantity = `12` uom = `PC` weightmeasure = `0.5` weightunit = `KG`
        price = '549.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg` )
      ( name = `ITelO FlexTop I4000` productid = `HT-8000` quantity = `11` uom = `PC` weightmeasure = `4` weightunit = `KG`
        price = '799.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg` )
      ( name = `ITelO FlexTop I6300c` productid = `HT-8001` quantity = `20` uom = `PC` weightmeasure = `4.2` weightunit = `KG`
        price = '799.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg` )
      ( name = `ITelO FlexTop I9100` productid = `HT-8002` quantity = `20` uom = `PC` weightmeasure = `3.5` weightunit = `KG`
        price = '1199.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg` )
      ( name = `ITelO FlexTop I9800` productid = `HT-8003` quantity = `22` uom = `PC` weightmeasure = `3.8` weightunit = `KG`
        price = '1388.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg` )
      ( name = `Smartphone Leather Case` productid = `HT-9991` quantity = `12` uom = `PC` weightmeasure = `0.02` weightunit = `KG`
        price = '25.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg` )
      ( name = `Smartphone Alpha` productid = `HT-9992` quantity = `13` uom = `PC` weightmeasure = `0.75` weightunit = `KG`
        price = '599.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg` )
      ( name = `Mini Tablet` productid = `HT-9993` quantity = `10` uom = `PC` weightmeasure = `3.8` weightunit = `KG`
        price = '833.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg` )
      ( name = `Camcorder View` productid = `HT-9994` quantity = `50` uom = `PC` weightmeasure = `3.8` weightunit = `KG`
        price = '1388.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg` )
      ( name = `Tablet Pouch` productid = `HT-9995` quantity = `34` uom = `PC` weightmeasure = `0.03` weightunit = `KG`
        price = '20.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg` )
      ( name = `Tablet Pouch` productid = `HT-9996` quantity = `34` uom = `PC` weightmeasure = `0.03` weightunit = `KG`
        price = '20.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg` )
      ( name = `e-Book Reader ReadMe` productid = `HT-9997` quantity = `23` uom = `PC` weightmeasure = `3.8` weightunit = `KG`
        price = '33.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg` )
      ( name = `Smartphone Beta` productid = `HT-9998` quantity = `21` uom = `PC` weightmeasure = `0.75` weightunit = `KG`
        price = '30.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg` )
      ( name = `Maxi Tablet` productid = `HT-9999` quantity = `20` uom = `PC` weightmeasure = `3.8` weightunit = `KG`
        price = '749.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg` )
      ( name = `Flyer` productid = `PF-1000` quantity = `33` uom = `PC` weightmeasure = `0.01` weightunit = `KG`
        price = '0.00' currencycode = `EUR` productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg` ) ).

  ENDMETHOD.

ENDCLASS.
