" @keywords table sap.m tableoutdated overflowtoolbar combobox item button toolbarspacer segmentedbutton segmentedbuttonitem verticallayout column
" @summary You can use the 'showOverlay' property to indicate that the table data is no longer up to date. When the user modifies the filter values of the table, this results in displaying an overlay, which disables operations on the table.
" @origin sap.m.sample.TableOutdated - https://sdk.openui5.org/entity/sap.m.Table/sample/sap.m.sample.TableOutdated (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_505 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        suppliername  TYPE string,
        width         TYPE string,
        depth         TYPE string,
        height        TYPE string,
        dimunit       TYPE string,
        weightmeasure TYPE p LENGTH 8 DECIMALS 2,
        weightunit    TYPE string,
        weightstate   TYPE string,
        price         TYPE p LENGTH 8 DECIMALS 2,
        currencycode  TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_filter,
        text TYPE string,
      END OF ty_s_filter.
    TYPES ty_t_filter TYPE STANDARD TABLE OF ty_s_filter WITH DEFAULT KEY.

    DATA t_products TYPE ty_t_product.
    DATA t_filters  TYPE ty_t_filter.
    DATA supplier   TYPE string.
    DATA overlay    TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " the unfiltered mock, so Reset can put every row back
    DATA t_all TYPE ty_t_product.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_505 IMPLEMENTATION.

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
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `OverflowToolbar`

            " onChange only switches the overlay on; the selected supplier is two-way
            " bound and the filter is applied by the Filter button
            )->ele( `ComboBox`
                )->a( n = `id`          v = `oComboBox`
                )->a( n = `change`      v = client->_event( `CHANGE` )
                )->a( n = `selectedKey` v = client->_bind( supplier )
                )->a( n = `items`       v = client->_bind( t_filters )

                )->tag( n = `Item` ns = `core`
                    )->a( n = `text` v = `{TEXT}`
                    )->a( n = `key`  v = `{TEXT}`

            )->end(

            )->tag( `Button`
                )->a( n = `text`  v = `Filter`
                )->a( n = `press` v = client->_event( `SEARCH` )
                )->a( n = `icon`  v = `sap-icon://filter`
            )->tag( `Button`
                )->a( n = `text`  v = `Reset`
                )->a( n = `press` v = client->_event( `RESET` )
                )->a( n = `type`  v = `Transparent`
            )->tag( `ToolbarSpacer`

            )->ele( `SegmentedButton`
                )->a( n = `enabled` v = `false`

                )->ele( `items`
                    )->tag( `SegmentedButtonItem`
                        )->a( n = `icon` v = `sap-icon://settings`
                    )->tag( `SegmentedButtonItem`
                        )->a( n = `icon` v = `sap-icon://settings`
                    )->tag( `SegmentedButtonItem`
                        )->a( n = `icon` v = `sap-icon://settings`

                )->end(
            )->end(
        )->end(

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `id` v = `tableLayout`

            " the original inserts the sap.m.sample.Table component's table here and
            " hides its header toolbar - the same table is declared inline, without
            " that toolbar
            )->ele( `Table`
                )->a( n = `id`          v = `idProductsTable`
                )->a( n = `inset`       v = `false`
                " NOT `b = <field>`: that parameter writes the LITERAL 'true' or
                " 'false' into the attribute at render time (view_builder->a),
                " so a field the event handler changes never reaches the
                " control - none of these apps re-renders after an event
                " (e2e-caught on app 505, 2026-08-22)
                )->a( n = `showOverlay` v = client->_bind( overlay )
                )->a( n = `items`       v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

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
                                )->a( n = `state`  v = `{WEIGHTSTATE}`
                            )->tag( `ObjectNumber`
                                )->a( n = `number` v = |\{ parts: [\{path: 'PRICE'\}, \{path: 'CURRENCYCODE'\}], type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: false\} \}|
                                )->a( n = `unit`   v = `{CURRENCYCODE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp1 TYPE z2ui5_cl_smpc_app_505=>ty_t_product.
        DATA row LIKE LINE OF t_all.
        DATA temp3 TYPE string.

    CASE client->get_event( ).

      WHEN `CHANGE`.
        " onChange: any change to the ComboBox puts the outdated overlay on
        overlay = abap_true.

      WHEN `SEARCH`.
        " onSearch: filter by the selected supplier and take the overlay off
        overlay = abap_false.
        
        CLEAR temp1.
        
        LOOP AT t_all INTO row WHERE suppliername = supplier.
          INSERT row INTO TABLE temp1.
        ENDLOOP.
        t_products = temp1.

      WHEN `RESET`.
        " onReset: clear the filter, the overlay and the ComboBox selection
        overlay = abap_false.
        
        CLEAR temp3.
        supplier = temp3.
        t_products = t_all.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " /ProductCollectionStats/Filters/1/values of ui5/mock/products.json
    DATA temp4 TYPE z2ui5_cl_smpc_app_505=>ty_t_filter.
    DATA temp5 LIKE LINE OF temp4.
    DATA temp6 TYPE z2ui5_cl_smpc_app_505=>ty_t_product.
    DATA temp7 LIKE LINE OF temp6.
    DATA temp8 LIKE LINE OF t_all.
    DATA product LIKE REF TO temp8.
      DATA weight_kg LIKE product->weightmeasure.
      DATA temp9 TYPE z2ui5_cl_smpc_app_505=>ty_s_product-weightstate.
    CLEAR temp4.
    
    temp5-text = `Titanium`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Technocom`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Red Point Stores`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Very Best Screens`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Smartcards`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Alpha Printers`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Printer for All`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Oxynum`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Fasttech`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Ultrasonic United`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Speaker Experts`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Brainsoft`.
    INSERT temp5 INTO TABLE temp4.
    t_filters = temp4.

    " full mock /ProductCollection (the bound fields); weightstate is computed
    " below, not seeded
    
    CLEAR temp6.
    
    temp7-name = `Notebook Basic 15`.
    temp7-productid = `HT-1000`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `30`.
    temp7-depth = `18`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-price = `956`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 17`.
    temp7-productid = `HT-1001`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `29`.
    temp7-depth = `17`.
    temp7-height = `3.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.5`.
    temp7-weightunit = `KG`.
    temp7-price = `1249`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 18`.
    temp7-productid = `HT-1002`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `28`.
    temp7-depth = `19`.
    temp7-height = `2.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-price = `1570`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 19`.
    temp7-productid = `HT-1003`.
    temp7-suppliername = `Smartcards`.
    temp7-width = `32`.
    temp7-depth = `21`.
    temp7-height = `4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-price = `1650`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault`.
    temp7-productid = `HT-1007`.
    temp7-suppliername = `Technocom`.
    temp7-width = `32`.
    temp7-depth = `22`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.2`.
    temp7-weightunit = `KG`.
    temp7-price = `299`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Professional 15`.
    temp7-productid = `HT-1010`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `33`.
    temp7-depth = `20`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.3`.
    temp7-weightunit = `KG`.
    temp7-price = `1999`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Professional 17`.
    temp7-productid = `HT-1011`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `33`.
    temp7-depth = `23`.
    temp7-height = `2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.1`.
    temp7-weightunit = `KG`.
    temp7-price = `2299`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault Net`.
    temp7-productid = `HT-1020`.
    temp7-suppliername = `Technocom`.
    temp7-width = `10`.
    temp7-depth = `1.8`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.16`.
    temp7-weightunit = `KG`.
    temp7-price = `459`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault SAT`.
    temp7-productid = `HT-1021`.
    temp7-suppliername = `Technocom`.
    temp7-width = `11`.
    temp7-depth = `1.7`.
    temp7-height = `18`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.18`.
    temp7-weightunit = `KG`.
    temp7-price = `149`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Comfort Easy`.
    temp7-productid = `HT-1022`.
    temp7-suppliername = `Technocom`.
    temp7-width = `84`.
    temp7-depth = `1.5`.
    temp7-height = `14`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.2`.
    temp7-weightunit = `KG`.
    temp7-price = `1679`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Comfort Senior`.
    temp7-productid = `HT-1023`.
    temp7-suppliername = `Technocom`.
    temp7-width = `80`.
    temp7-depth = `1.6`.
    temp7-height = `13`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.8`.
    temp7-weightunit = `KG`.
    temp7-price = `512`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-I`.
    temp7-productid = `HT-1030`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `37`.
    temp7-depth = `12`.
    temp7-height = `36`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `21`.
    temp7-weightunit = `KG`.
    temp7-price = `230`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-II`.
    temp7-productid = `HT-1031`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `40.8`.
    temp7-depth = `19`.
    temp7-height = `43`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `21`.
    temp7-weightunit = `KG`.
    temp7-price = `285`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-III`.
    temp7-productid = `HT-1032`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `40.8`.
    temp7-depth = `19`.
    temp7-height = `43`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `21`.
    temp7-weightunit = `KG`.
    temp7-price = `345`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Basic`.
    temp7-productid = `HT-1035`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `39`.
    temp7-depth = `20`.
    temp7-height = `41`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `14`.
    temp7-weightunit = `KG`.
    temp7-price = `399`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Future`.
    temp7-productid = `HT-1036`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `45`.
    temp7-depth = `26`.
    temp7-height = `46`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `15`.
    temp7-weightunit = `KG`.
    temp7-price = `430`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat XL`.
    temp7-productid = `HT-1037`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `54.5`.
    temp7-depth = `22.1`.
    temp7-height = `39.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `17`.
    temp7-weightunit = `KG`.
    temp7-price = `1230`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Professional Eco`.
    temp7-productid = `HT-1040`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `51`.
    temp7-depth = `46`.
    temp7-height = `30`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `32`.
    temp7-weightunit = `KG`.
    temp7-price = `830`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Basic`.
    temp7-productid = `HT-1041`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `48`.
    temp7-depth = `42`.
    temp7-height = `26`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `23`.
    temp7-weightunit = `KG`.
    temp7-price = `490`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Allround`.
    temp7-productid = `HT-1042`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `53`.
    temp7-depth = `50`.
    temp7-height = `65`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `17`.
    temp7-weightunit = `KG`.
    temp7-price = `349`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Super Color`.
    temp7-productid = `HT-1050`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `41`.
    temp7-depth = `41`.
    temp7-height = `28`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3`.
    temp7-weightunit = `KG`.
    temp7-price = `139`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Mobile`.
    temp7-productid = `HT-1051`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `46`.
    temp7-depth = `32`.
    temp7-height = `25`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.9`.
    temp7-weightunit = `KG`.
    temp7-price = `99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Super Highspeed`.
    temp7-productid = `HT-1052`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `41`.
    temp7-depth = `41`.
    temp7-height = `28`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `18`.
    temp7-weightunit = `KG`.
    temp7-price = `170`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Multi Print`.
    temp7-productid = `HT-1055`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `55`.
    temp7-depth = `45`.
    temp7-height = `29`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `6.3`.
    temp7-weightunit = `KG`.
    temp7-price = `99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Multi Color`.
    temp7-productid = `HT-1056`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `51`.
    temp7-depth = `41.3`.
    temp7-height = `22`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.3`.
    temp7-weightunit = `KG`.
    temp7-price = `119`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cordless Mouse`.
    temp7-productid = `HT-1060`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `6`.
    temp7-depth = `14.5`.
    temp7-height = `3.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.09`.
    temp7-weightunit = `KG`.
    temp7-price = `9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Speed Mouse`.
    temp7-productid = `HT-1061`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `7`.
    temp7-depth = `15`.
    temp7-height = `3.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.09`.
    temp7-weightunit = `KG`.
    temp7-price = `7`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Track Mouse`.
    temp7-productid = `HT-1062`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `3`.
    temp7-depth = `7`.
    temp7-height = `4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.03`.
    temp7-weightunit = `KG`.
    temp7-price = `11`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergonomic Keyboard`.
    temp7-productid = `HT-1063`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `50`.
    temp7-depth = `21`.
    temp7-height = `3.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.1`.
    temp7-weightunit = `KG`.
    temp7-price = `14`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Internet Keyboard`.
    temp7-productid = `HT-1064`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `52`.
    temp7-depth = `25`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.8`.
    temp7-weightunit = `KG`.
    temp7-price = `16`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Media Keyboard`.
    temp7-productid = `HT-1065`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `51.4`.
    temp7-depth = `23`.
    temp7-height = `4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.3`.
    temp7-weightunit = `KG`.
    temp7-price = `26`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Mousepad`.
    temp7-productid = `HT-1066`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `15`.
    temp7-depth = `6`.
    temp7-height = `0.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `80`.
    temp7-weightunit = `G`.
    temp7-price = `6.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Mousepad`.
    temp7-productid = `HT-1067`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `15`.
    temp7-depth = `6`.
    temp7-height = `0.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `80`.
    temp7-weightunit = `G`.
    temp7-price = `8.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Designer Mousepad`.
    temp7-productid = `HT-1068`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `24`.
    temp7-depth = `24`.
    temp7-height = `0.6`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `90`.
    temp7-weightunit = `G`.
    temp7-price = `12.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Universal card reader`.
    temp7-productid = `HT-1069`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `6`.
    temp7-depth = `6`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `45`.
    temp7-weightunit = `G`.
    temp7-price = `14`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Proctra X`.
    temp7-productid = `HT-1070`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `22`.
    temp7-depth = `35`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.255`.
    temp7-weightunit = `KG`.
    temp7-price = `70.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gladiator MX`.
    temp7-productid = `HT-1071`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `22`.
    temp7-depth = `35`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.3`.
    temp7-weightunit = `KG`.
    temp7-price = `81.7`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Hurricane GX`.
    temp7-productid = `HT-1072`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `22`.
    temp7-depth = `35`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.4`.
    temp7-weightunit = `KG`.
    temp7-price = `101.2`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Hurricane GX/LN`.
    temp7-productid = `HT-1073`.
    temp7-suppliername = `Smartcards`.
    temp7-width = `22`.
    temp7-depth = `35`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.4`.
    temp7-weightunit = `KG`.
    temp7-price = `139.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Photo Scan`.
    temp7-productid = `HT-1080`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `34`.
    temp7-depth = `48`.
    temp7-height = `5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.3`.
    temp7-weightunit = `KG`.
    temp7-price = `129`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Scan`.
    temp7-productid = `HT-1081`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `31`.
    temp7-depth = `43`.
    temp7-height = `7`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.4`.
    temp7-weightunit = `KG`.
    temp7-price = `89`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Jet Scan Professional`.
    temp7-productid = `HT-1082`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `33`.
    temp7-depth = `41`.
    temp7-height = `12`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.2`.
    temp7-weightunit = `KG`.
    temp7-price = `169`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Jet Scan Professional`.
    temp7-productid = `HT-1083`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `35`.
    temp7-depth = `40`.
    temp7-height = `10`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.2`.
    temp7-weightunit = `KG`.
    temp7-price = `189`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Copymaster`.
    temp7-productid = `HT-1085`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `45`.
    temp7-depth = `42`.
    temp7-height = `22`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `23.2`.
    temp7-weightunit = `KG`.
    temp7-price = `1499`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Surround Sound`.
    temp7-productid = `HT-1090`.
    temp7-suppliername = `Speaker Experts`.
    temp7-width = `12`.
    temp7-depth = `10`.
    temp7-height = `16`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3`.
    temp7-weightunit = `KG`.
    temp7-price = `39`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Blaster Extreme`.
    temp7-productid = `HT-1091`.
    temp7-suppliername = `Speaker Experts`.
    temp7-width = `13`.
    temp7-depth = `11`.
    temp7-height = `17.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.4`.
    temp7-weightunit = `KG`.
    temp7-price = `26`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Sound Booster`.
    temp7-productid = `HT-1092`.
    temp7-suppliername = `Speaker Experts`.
    temp7-width = `12.4`.
    temp7-depth = `10.4`.
    temp7-height = `18.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.1`.
    temp7-weightunit = `KG`.
    temp7-price = `45`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound 5.1 Wireless`.
    temp7-productid = `HT-1095`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `24`.
    temp7-depth = `19`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `80`.
    temp7-weightunit = `G`.
    temp7-price = `49`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound 5.1`.
    temp7-productid = `HT-1096`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `25`.
    temp7-depth = `17`.
    temp7-height = `19`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `130`.
    temp7-weightunit = `G`.
    temp7-price = `39`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound Stereo`.
    temp7-productid = `HT-1097`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `21.3`.
    temp7-depth = `2.4`.
    temp7-height = `19.7`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `60`.
    temp7-weightunit = `G`.
    temp7-price = `29`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Office`.
    temp7-productid = `HT-1100`.
    temp7-suppliername = `Technocom`.
    temp7-width = `15`.
    temp7-depth = `6.5`.
    temp7-height = `2.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.2`.
    temp7-weightunit = `KG`.
    temp7-price = `89.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Design`.
    temp7-productid = `HT-1101`.
    temp7-suppliername = `Technocom`.
    temp7-width = `14`.
    temp7-depth = `6.7`.
    temp7-height = `24`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.8`.
    temp7-weightunit = `KG`.
    temp7-price = `79.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Network`.
    temp7-productid = `HT-1102`.
    temp7-suppliername = `Technocom`.
    temp7-width = `16`.
    temp7-depth = `6`.
    temp7-height = `27`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.8`.
    temp7-weightunit = `KG`.
    temp7-price = `69`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Multimedia`.
    temp7-productid = `HT-1103`.
    temp7-suppliername = `Technocom`.
    temp7-width = `11`.
    temp7-depth = `3.4`.
    temp7-height = `22`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.8`.
    temp7-weightunit = `KG`.
    temp7-price = `77`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Games`.
    temp7-productid = `HT-1104`.
    temp7-suppliername = `Technocom`.
    temp7-width = `10`.
    temp7-depth = `3`.
    temp7-height = `30`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.1`.
    temp7-weightunit = `KG`.
    temp7-price = `55`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Internet Antivirus`.
    temp7-productid = `HT-1105`.
    temp7-suppliername = `Brainsoft`.
    temp7-width = `16`.
    temp7-depth = `4`.
    temp7-height = `21`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.7`.
    temp7-weightunit = `KG`.
    temp7-price = `29`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Firewall`.
    temp7-productid = `HT-1106`.
    temp7-suppliername = `Brainsoft`.
    temp7-width = `17.9`.
    temp7-depth = `4.2`.
    temp7-height = `23.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.9`.
    temp7-weightunit = `KG`.
    temp7-price = `34`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Money`.
    temp7-productid = `HT-1107`.
    temp7-suppliername = `Brainsoft`.
    temp7-width = `12`.
    temp7-depth = `1.5`.
    temp7-height = `19`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-price = `29.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `PC Lock`.
    temp7-productid = `HT-1110`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `20`.
    temp7-depth = `8`.
    temp7-height = `4.3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.03`.
    temp7-weightunit = `KG`.
    temp7-price = `8.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Lock`.
    temp7-productid = `HT-1111`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `31`.
    temp7-depth = `9`.
    temp7-height = `7`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.02`.
    temp7-weightunit = `KG`.
    temp7-price = `6.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Web cam reality`.
    temp7-productid = `HT-1112`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `9`.
    temp7-depth = `8.2`.
    temp7-height = `1.3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.075`.
    temp7-weightunit = `KG`.
    temp7-price = `39`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Screen clean`.
    temp7-productid = `HT-1113`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `2`.
    temp7-depth = `2`.
    temp7-height = `0.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.05`.
    temp7-weightunit = `KG`.
    temp7-price = `2.3`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Fabric bag professional`.
    temp7-productid = `HT-1114`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `42`.
    temp7-depth = `32`.
    temp7-height = `7`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.8`.
    temp7-weightunit = `KG`.
    temp7-price = `31`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router`.
    temp7-productid = `HT-1115`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `19.3`.
    temp7-depth = `18`.
    temp7-height = `5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.45`.
    temp7-weightunit = `KG`.
    temp7-price = `49`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router / Repeater`.
    temp7-productid = `HT-1116`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `19.3`.
    temp7-depth = `18`.
    temp7-height = `5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.45`.
    temp7-weightunit = `KG`.
    temp7-price = `59`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router / Repeater and Print Server`.
    temp7-productid = `HT-1117`.
    temp7-suppliername = `Technocom`.
    temp7-width = `19.3`.
    temp7-depth = `18`.
    temp7-height = `5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.45`.
    temp7-weightunit = `KG`.
    temp7-price = `69`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `USB Stick`.
    temp7-productid = `HT-1118`.
    temp7-suppliername = `Technocom`.
    temp7-width = `1.5`.
    temp7-depth = `8.7`.
    temp7-height = `1.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.015`.
    temp7-weightunit = `KG`.
    temp7-price = `35`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Travel Adapter`.
    temp7-productid = `HT-1119`.
    temp7-suppliername = `Titanium`.
    temp7-width = `2`.
    temp7-depth = `3.1`.
    temp7-height = `3.9`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `88`.
    temp7-weightunit = `G`.
    temp7-price = `79`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cordless Bluetooth Keyboard, english international`.
    temp7-productid = `HT-1120`.
    temp7-suppliername = `Technocom`.
    temp7-width = `51.4`.
    temp7-depth = `23`.
    temp7-height = `4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1`.
    temp7-weightunit = `KG`.
    temp7-price = `29`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat XXL`.
    temp7-productid = `HT-1137`.
    temp7-suppliername = `Technocom`.
    temp7-width = `54`.
    temp7-depth = `22`.
    temp7-height = `38`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `18`.
    temp7-weightunit = `KG`.
    temp7-price = `1430`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Pocket Mouse`.
    temp7-productid = `HT-1138`.
    temp7-suppliername = `Technocom`.
    temp7-width = `0.3`.
    temp7-depth = `0.5`.
    temp7-height = `1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.02`.
    temp7-weightunit = `KG`.
    temp7-price = `23`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `PC Power Station`.
    temp7-productid = `HT-1210`.
    temp7-suppliername = `Technocom`.
    temp7-width = `28`.
    temp7-depth = `31`.
    temp7-height = `43`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.3`.
    temp7-weightunit = `KG`.
    temp7-price = `2399`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Astro Laptop 1516`.
    temp7-productid = `HT-1251`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `30`.
    temp7-depth = `18`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-price = `989`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Astro Phone 6`.
    temp7-productid = `HT-1252`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `8`.
    temp7-depth = `6`.
    temp7-height = `1.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.75`.
    temp7-weightunit = `KG`.
    temp7-price = `649`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Benda Laptop 1408`.
    temp7-productid = `HT-1253`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `30`.
    temp7-depth = `18`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-price = `976`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Bending Screen 21HD`.
    temp7-productid = `HT-1254`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `37`.
    temp7-depth = `12`.
    temp7-height = `36`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `15`.
    temp7-weightunit = `KG`.
    temp7-price = `250`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Broad Screen 22HD`.
    temp7-productid = `HT-1255`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `39`.
    temp7-depth = `12`.
    temp7-height = `38`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `16`.
    temp7-weightunit = `KG`.
    temp7-price = `270`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cerdik Phone 7`.
    temp7-productid = `HT-1256`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `9`.
    temp7-depth = `15`.
    temp7-height = `1.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.75`.
    temp7-weightunit = `KG`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cepat Tablet 10.5`.
    temp7-productid = `HT-1257`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.8`.
    temp7-weightunit = `KG`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cepat Tablet 8`.
    temp7-productid = `HT-1258`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `38`.
    temp7-depth = `21`.
    temp7-height = `3.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.5`.
    temp7-weightunit = `KG`.
    temp7-price = `529`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Basic`.
    temp7-productid = `HT-1500`.
    temp7-suppliername = `Technocom`.
    temp7-width = `34`.
    temp7-depth = `35`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `18`.
    temp7-weightunit = `KG`.
    temp7-price = `5000`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Professional`.
    temp7-productid = `HT-1501`.
    temp7-suppliername = `Technocom`.
    temp7-width = `29`.
    temp7-depth = `30`.
    temp7-height = `27`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `25`.
    temp7-weightunit = `KG`.
    temp7-price = `15000`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Power Pro`.
    temp7-productid = `HT-1502`.
    temp7-suppliername = `Technocom`.
    temp7-width = `22`.
    temp7-depth = `27.3`.
    temp7-height = `37`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `35`.
    temp7-weightunit = `KG`.
    temp7-price = `25000`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Family PC Basic`.
    temp7-productid = `HT-1600`.
    temp7-suppliername = `Titanium`.
    temp7-width = `21.4`.
    temp7-depth = `29`.
    temp7-height = `38`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.8`.
    temp7-weightunit = `KG`.
    temp7-price = `600`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Family PC Pro`.
    temp7-productid = `HT-1601`.
    temp7-suppliername = `Titanium`.
    temp7-width = `25`.
    temp7-depth = `31.7`.
    temp7-height = `40.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `5.3`.
    temp7-weightunit = `KG`.
    temp7-price = `900`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gaming Monster`.
    temp7-productid = `HT-1602`.
    temp7-suppliername = `Titanium`.
    temp7-width = `26.5`.
    temp7-depth = `34`.
    temp7-height = `47`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `5.9`.
    temp7-weightunit = `KG`.
    temp7-price = `1200`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gaming Monster Pro`.
    temp7-productid = `HT-1603`.
    temp7-suppliername = `Titanium`.
    temp7-width = `27`.
    temp7-depth = `28`.
    temp7-height = `42`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `6.8`.
    temp7-weightunit = `KG`.
    temp7-price = `1700`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `7" Widescreen Portable DVD Player w MP3`.
    temp7-productid = `HT-2000`.
    temp7-suppliername = `Titanium`.
    temp7-width = `21.4`.
    temp7-depth = `19`.
    temp7-height = `27.6`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.79`.
    temp7-weightunit = `KG`.
    temp7-price = `249.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `10" Portable DVD player`.
    temp7-productid = `HT-2001`.
    temp7-suppliername = `Titanium`.
    temp7-width = `24`.
    temp7-depth = `19.5`.
    temp7-height = `29`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.84`.
    temp7-weightunit = `KG`.
    temp7-price = `449.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Portable DVD Player with 9" LCD Monitor`.
    temp7-productid = `HT-2002`.
    temp7-suppliername = `Technocom`.
    temp7-width = `21`.
    temp7-depth = `16.5`.
    temp7-height = `14`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.72`.
    temp7-weightunit = `KG`.
    temp7-price = `853.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `CD/DVD case: 264 sleeves`.
    temp7-productid = `HT-2025`.
    temp7-suppliername = `Titanium`.
    temp7-width = `13`.
    temp7-depth = `13`.
    temp7-height = `20`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.65`.
    temp7-weightunit = `KG`.
    temp7-price = `44.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Audio/Video Cable Kit - 4m`.
    temp7-productid = `HT-2026`.
    temp7-suppliername = `Titanium`.
    temp7-width = `21`.
    temp7-depth = `10.2`.
    temp7-height = `13`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.2`.
    temp7-weightunit = `KG`.
    temp7-price = `29.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Removable CD/DVD Laser Labels`.
    temp7-productid = `HT-2027`.
    temp7-suppliername = `Titanium`.
    temp7-width = `5.5`.
    temp7-depth = `2`.
    temp7-height = `2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.15`.
    temp7-weightunit = `KG`.
    temp7-price = `8.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-1`.
    temp7-productid = `HT-6100`.
    temp7-suppliername = `Titanium`.
    temp7-width = `30.4`.
    temp7-depth = `23.1`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.7`.
    temp7-weightunit = `KG`.
    temp7-price = `469`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-2`.
    temp7-productid = `HT-6101`.
    temp7-suppliername = `Technocom`.
    temp7-width = `30.4`.
    temp7-depth = `23.1`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2`.
    temp7-weightunit = `KG`.
    temp7-price = `679`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-3`.
    temp7-productid = `HT-6102`.
    temp7-suppliername = `Technocom`.
    temp7-width = `30.4`.
    temp7-depth = `23.1`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.5`.
    temp7-weightunit = `KG`.
    temp7-price = `889`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Play Movie`.
    temp7-productid = `HT-6110`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `37`.
    temp7-depth = `24`.
    temp7-height = `6`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.4`.
    temp7-weightunit = `KG`.
    temp7-price = `130`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Record Movie`.
    temp7-productid = `HT-6111`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `38`.
    temp7-depth = `26`.
    temp7-height = `6.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.1`.
    temp7-weightunit = `KG`.
    temp7-price = `288`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelo MusicStick`.
    temp7-productid = `HT-6120`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `1.5`.
    temp7-depth = `6`.
    temp7-height = `1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `134`.
    temp7-weightunit = `G`.
    temp7-price = `45`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelo Jog-Mate`.
    temp7-productid = `HT-6121`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `5.1`.
    temp7-depth = `8`.
    temp7-height = `9.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `134`.
    temp7-weightunit = `G`.
    temp7-price = `63`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Pro Player 40`.
    temp7-productid = `HT-6122`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `5.1`.
    temp7-depth = `8`.
    temp7-height = `9.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `266`.
    temp7-weightunit = `G`.
    temp7-price = `167`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Pro Player 80`.
    temp7-productid = `HT-6123`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `4`.
    temp7-depth = `6`.
    temp7-height = `0.8`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `267`.
    temp7-weightunit = `G`.
    temp7-price = `299`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD32`.
    temp7-productid = `HT-6130`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `78`.
    temp7-depth = `22.1`.
    temp7-height = `55`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.6`.
    temp7-weightunit = `KG`.
    temp7-price = `1459`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD37`.
    temp7-productid = `HT-6131`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `99.1`.
    temp7-depth = `26`.
    temp7-height = `61`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.2`.
    temp7-weightunit = `KG`.
    temp7-price = `1199`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD41`.
    temp7-productid = `HT-6132`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `128`.
    temp7-depth = `23`.
    temp7-height = `79.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.8`.
    temp7-weightunit = `KG`.
    temp7-price = `899`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Copperberry`.
    temp7-productid = `HT-7000`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `8.1`.
    temp7-depth = `13`.
    temp7-height = `12.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Silverberry`.
    temp7-productid = `HT-7010`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `8.1`.
    temp7-depth = `13`.
    temp7-height = `12.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Goldberry`.
    temp7-productid = `HT-7020`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `8.1`.
    temp7-depth = `13`.
    temp7-height = `12.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Platinberry`.
    temp7-productid = `HT-7030`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `8.1`.
    temp7-depth = `13`.
    temp7-height = `12.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I4000`.
    temp7-productid = `HT-8000`.
    temp7-suppliername = `Titanium`.
    temp7-width = `31`.
    temp7-depth = `19`.
    temp7-height = `3.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4`.
    temp7-weightunit = `KG`.
    temp7-price = `799`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I6300c`.
    temp7-productid = `HT-8001`.
    temp7-suppliername = `Titanium`.
    temp7-width = `32`.
    temp7-depth = `20`.
    temp7-height = `3.4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-price = `799`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I9100`.
    temp7-productid = `HT-8002`.
    temp7-suppliername = `Titanium`.
    temp7-width = `38`.
    temp7-depth = `21`.
    temp7-height = `4.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.5`.
    temp7-weightunit = `KG`.
    temp7-price = `1199`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I9800`.
    temp7-productid = `HT-8003`.
    temp7-suppliername = `Titanium`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-price = `1388`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Leather Case`.
    temp7-productid = `HT-9991`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.02`.
    temp7-weightunit = `KG`.
    temp7-price = `25`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Alpha`.
    temp7-productid = `HT-9992`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.75`.
    temp7-weightunit = `KG`.
    temp7-price = `599`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Mini Tablet`.
    temp7-productid = `HT-9993`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-price = `833`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Camcorder View`.
    temp7-productid = `HT-9994`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `27`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-price = `1388`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Tablet Pouch`.
    temp7-productid = `HT-9995`.
    temp7-suppliername = `Titanium`.
    temp7-width = `25`.
    temp7-depth = `40`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.03`.
    temp7-weightunit = `KG`.
    temp7-price = `20`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Tablet Pouch`.
    temp7-productid = `HT-9996`.
    temp7-suppliername = `Titanium`.
    temp7-width = `25`.
    temp7-depth = `40`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.03`.
    temp7-weightunit = `KG`.
    temp7-price = `20`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `e-Book Reader ReadMe`.
    temp7-productid = `HT-9997`.
    temp7-suppliername = `Titanium`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-price = `33`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Beta`.
    temp7-productid = `HT-9998`.
    temp7-suppliername = `Titanium`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.75`.
    temp7-weightunit = `KG`.
    temp7-price = `30`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Maxi Tablet`.
    temp7-productid = `HT-9999`.
    temp7-suppliername = `Titanium`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-price = `749`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flyer`.
    temp7-productid = `PF-1000`.
    temp7-suppliername = `Titanium`.
    temp7-width = `46`.
    temp7-depth = `30`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.01`.
    temp7-weightunit = `KG`.
    temp7-price = `0`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    t_all = temp6.

    " weightState is business logic (KG conversion + Success/Warning/Error
    " thresholds), not presentation - abap2UI5 is a thin frontend, so the
    " ObjectNumber state is computed here in the backend. TableOutdated reuses the
    " sap.m.sample.Table COMPONENT, so it inherits that sample's Formatter.js:
    " thresholds 1 and 5 KG with G converted, NOT the 1000/2000 raw thresholds the
    " TableSelectDialog family uses (app 009 computes the identical rule).
    
    
    LOOP AT t_all REFERENCE INTO product.
      
      weight_kg = product->weightmeasure.
      IF product->weightunit = `G`.
        weight_kg = weight_kg / 1000.
      ENDIF.
      
      IF weight_kg < 0.
        temp9 = `None`.
      ELSEIF weight_kg < 1.
        temp9 = `Success`.
      ELSEIF weight_kg < 5.
        temp9 = `Warning`.
      ELSE.
        temp9 = `Error`.
      ENDIF.
      product->weightstate = temp9.
    ENDLOOP.

    t_products = t_all.

  ENDMETHOD.

ENDCLASS.
