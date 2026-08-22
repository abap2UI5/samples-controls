" @keywords tableselectdialog table select dialog sap.m product row columnlistitem objectidentifier text objectnumber column
" @summary Similar to the Select Dialog, the Table Select Dialog presents selectable items in a table-based dialog, with filter functions. You can have single select or multi select mode.
CLASS z2ui5_cl_smpc_app_104 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " the productInput's value, bound two-way: the value help preselects the
    " row matching WHAT IS IN THE FIELD (original _configValueHelpDialog reads
    " byId('productInput').getValue()), and the close handler writes back into it
    DATA product_value TYPE string.

    TYPES: BEGIN OF ty_s_product,
             name           TYPE string,
             product_id     TYPE string,
             description    TYPE string,
             category       TYPE string,
             main_category  TYPE string,
             supplier_name  TYPE string,
             width          TYPE string,
             depth          TYPE string,
             height         TYPE string,
             dim_unit       TYPE string,
             weight_measure TYPE string,
             weight_unit    TYPE string,
             weight_state   TYPE string,
             quantity       TYPE string,
             price          TYPE p LENGTH 8 DECIMALS 2,
             currency_code  TYPE string,
             selected       TYPE abap_bool,
           END OF ty_s_product.
    TYPES temp1_2011651e41 TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_products TYPE temp1_2011651e41.
    DATA multi_select TYPE abap_bool.
    DATA draggable TYPE abap_bool.
    DATA resizable TYPE abap_bool.
    DATA remember TYPE abap_bool.
    DATA confirm_text TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS open_dialog IMPORTING multi       TYPE abap_bool DEFAULT abap_false
                                  drag        TYPE abap_bool DEFAULT abap_false
                                  resize      TYPE abap_bool DEFAULT abap_false
                                  rem         TYPE abap_bool DEFAULT abap_false
                                  confirmtext TYPE string    DEFAULT ``
                                  responsive  TYPE abap_bool DEFAULT abap_false.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_104 IMPLEMENTATION.

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
    DATA temp3 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `myDialog` INTO TABLE temp1.
    INSERT `items` INTO TABLE temp1.
    INSERT `filter` INTO TABLE temp1.
    INSERT `NAME` INTO TABLE temp1.
    INSERT `Contains` INTO TABLE temp1.
    INSERT `${$parameters>/value}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `valueHelpDialog` INTO TABLE temp2.
    INSERT `items` INTO TABLE temp2.
    INSERT `filter` INTO TABLE temp2.
    INSERT `NAME` INTO TABLE temp2.
    INSERT `Contains` INTO TABLE temp2.
    INSERT `${$parameters>/value}` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `${$parameters>/selectedItem} ? ${$parameters>/selectedItem}.getCells()[0].getTitle() : ''` INTO TABLE temp3.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( n = `dependents` ns = `mvc`
            )->ele( `TableSelectDialog`
                )->a( n = `id`         v = `myDialog`
                )->a( n = `noDataText` v = `No Products Found`
                )->a( n = `title`      v = `Select Product`
                )->a( n = `search`     v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                     t_arg = temp1 )
                )->a( n = `confirm`    v = client->_event( `CONFIRM` )
                )->a( n = `cancel`     v = client->_event( `CONFIRM` )
                )->a( n = `multiSelect`        v = client->_bind( multi_select )
                )->a( n = `draggable`          v = client->_bind( draggable )
                )->a( n = `resizable`          v = client->_bind( resizable )
                )->a( n = `rememberSelections` v = client->_bind( remember )
                )->a( n = `confirmButtonText`  v = client->_bind( confirm_text )
                )->a( n = `items` v = |\{ path: '{ client->_bind( val = t_products path = abap_true ) }', sorter: \{ path: 'NAME', descending: false \} \}|

                )->ele( `ColumnListItem`
                    )->a( n = `vAlign` v = `Middle`
                    )->ele( `cells`
                        )->tag( `ObjectIdentifier`
                            )->a( n = `title` v = `{NAME}`
                            )->a( n = `text`  v = `{PRODUCT_ID}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{SUPPLIER_NAME}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{WIDTH} x {DEPTH} x {HEIGHT} {DIM_UNIT}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{WEIGHT_MEASURE}`
                            )->a( n = `unit`   v = `{WEIGHT_UNIT}`
                            )->a( n = `state`  v = `{WEIGHT_STATE}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = |\{ parts:[\{path:'PRICE'\},\{path:'CURRENCY_CODE'\}], type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: false\} \}|
                            )->a( n = `unit`   v = `{CURRENCY_CODE}`

                    )->end(
                )->end(
                )->ele( `columns`
                    )->ele( `Column`
                        )->a( n = `width` v = `12em`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Product`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `minScreenWidth` v = `Tablet`
                        )->a( n = `demandPopin`    v = `true`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Supplier`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `minScreenWidth` v = `Desktop`
                        )->a( n = `demandPopin`    v = `true`
                        )->a( n = `hAlign`         v = `End`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Dimensions`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `minScreenWidth` v = `Desktop`
                        )->a( n = `demandPopin`    v = `true`
                        )->a( n = `hAlign`         v = `Center`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Weight`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `hAlign` v = `End`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Product`

                        )->end(
                    )->end(
                )->end(
            )->end(

            )->ele( `TableSelectDialog`
                )->a( n = `noDataText`        v = `No Products Found`
                )->a( n = `title`             v = `Select Product`
                )->a( n = `search`            v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                            t_arg = temp2 )
                )->a( n = `searchPlaceholder` v = `Search Products`
                )->a( n = `confirm`           v = client->_event( val   = `VH_CLOSE`
                                                                  t_arg = temp3 )
                )->a( n = `cancel`            v = client->_event( `VH_CLOSE` )
                )->a( n = `showClearButton`   v = `true`
                )->a( n = `id`                v = `valueHelpDialog`
                )->a( n = `items` v = |\{ path: '{ client->_bind( val = t_products path = abap_true ) }', sorter: \{ path: 'NAME', descending: false \} \}|

                )->ele( `ColumnListItem`
                    )->a( n = `selected` v = `{SELECTED}`
                    )->ele( `cells`
                        )->tag( `ObjectIdentifier`
                            )->a( n = `title` v = `{NAME}`
                            )->a( n = `text`  v = `{PRODUCT_ID}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{SUPPLIER_NAME}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{WIDTH} x {DEPTH} x {HEIGHT} {DIM_UNIT}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{WEIGHT_MEASURE}`
                            )->a( n = `unit`   v = `{WEIGHT_UNIT}`
                            )->a( n = `state`  v = `{WEIGHT_STATE}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = |\{ parts:[\{path:'PRICE'\},\{path:'CURRENCY_CODE'\}], type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: false\} \}|
                            )->a( n = `unit`   v = `{CURRENCY_CODE}`

                    )->end(
                )->end(
                )->ele( `columns`
                    )->ele( `Column`
                        )->a( n = `width` v = `12em`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Product`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `minScreenWidth` v = `Tablet`
                        )->a( n = `demandPopin`    v = `true`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Supplier`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `minScreenWidth` v = `Desktop`
                        )->a( n = `demandPopin`    v = `true`
                        )->a( n = `hAlign`         v = `End`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Dimensions`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `minScreenWidth` v = `Desktop`
                        )->a( n = `demandPopin`    v = `true`
                        )->a( n = `hAlign`         v = `Center`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Weight`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `hAlign` v = `End`
                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `Product`

                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Input`
                )->a( n = `id`            v = `productInput`
                )->a( n = `type`          v = `Text`
                )->a( n = `value`         v = client->_bind( product_value )
                )->a( n = `placeholder`   v = `Enter Product ...`
                )->a( n = `showValueHelp` v = `true`
                )->a( n = `valueHelpRequest` v = client->_event( `VALUE_HELP` )
                )->a( n = `width`         v = `15rem`
                )->a( n = `class`         v = `sapUiSmallMarginBottom`

            )->ele( `Button`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
                )->a( n = `text`  v = `Show Table Select Dialog`
                )->a( n = `press` v = client->_event( `OPEN_1` )

            )->end(
            )->ele( `Button`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
                )->a( n = `text`  v = `Show Table Select Dialog (Multi)`
                )->a( n = `press` v = client->_event( `OPEN_2` )
                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
                )->a( n = `text`  v = `Show Table Select Dialog (draggable=true)`
                )->a( n = `press` v = client->_event( `OPEN_3` )
                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `draggable`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Table Select Dialog (resizable=true)`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
                )->a( n = `press` v = client->_event( `OPEN_4` )
                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `resizable`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
                )->a( n = `text`  v = `Show Table Select Dialog (Remember)`
                )->a( n = `press` v = client->_event( `OPEN_5` )
                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `remember`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Table Select Dialog (Custom confirmation button text)`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
                )->a( n = `press` v = client->_event( `OPEN_6` )
                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `confirmButtonText`
                        )->a( n = `value` v = `Save`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Table Select Dialog with Responsive Padding`
                )->a( n = `class` v = `sapUiSmallMarginBottom`
                )->a( n = `press` v = client->_event( `OPEN_7` )
                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `resizable`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `draggable`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `responsivePadding`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
        )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 LIKE LINE OF t_products.
        DATA lr LIKE REF TO temp3.
          DATA temp1 TYPE xsdboolean.
        DATA temp4 TYPE string_table.

    CASE client->get_event( ).

      WHEN `OPEN_1`.
        open_dialog( ).

      WHEN `OPEN_2`.
        open_dialog( multi = abap_true ).

      WHEN `OPEN_3`.
        open_dialog( multi = abap_true drag = abap_true ).

      WHEN `OPEN_4`.
        open_dialog( multi = abap_true resize = abap_true ).

      WHEN `OPEN_5`.
        open_dialog( multi = abap_true rem = abap_true ).

      WHEN `OPEN_6`.
        open_dialog( multi = abap_true confirmtext = `Save` ).

      WHEN `OPEN_7`.
        open_dialog( resize = abap_true drag = abap_true responsive = abap_true ).

      WHEN `VALUE_HELP`.
        " preselect the row matching the current input value (original _configValueHelpDialog)
        
        
        LOOP AT t_products REFERENCE INTO lr.
          
          temp1 = boolc( lr->name = product_value ).
          lr->selected = temp1.
        ENDLOOP.
        
        CLEAR temp4.
        INSERT `valueHelpDialog` INTO TABLE temp4.
        INSERT `open` INTO TABLE temp4.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp4 ).

      WHEN `CONFIRM`.
        client->message_toast_display( `Selection confirmed` ).

      WHEN `VH_CLOSE`.
        " handleValueHelpClose: the picked row's first cell title lands in the
        " input, and a close with no selection resets it (resetProperty)
        product_value = client->get_event_arg( ).

    ENDCASE.

  ENDMETHOD.


  METHOD open_dialog.
      DATA temp6 TYPE string_table.
      DATA temp8 TYPE string_table.
    DATA temp10 TYPE string_table.

    multi_select = multi.
    draggable    = drag.
    resizable    = resize.
    remember     = rem.
    confirm_text = confirmtext.

    IF responsive = abap_true.
      
      CLEAR temp6.
      INSERT `myDialog` INTO TABLE temp6.
      INSERT `addStyleClass` INTO TABLE temp6.
      INSERT `sapUiResponsivePadding--header sapUiResponsivePadding--subHeader sapUiResponsivePadding--content sapUiResponsivePadding--footer` INTO TABLE temp6.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = temp6 ).
    ELSE.
      
      CLEAR temp8.
      INSERT `myDialog` INTO TABLE temp8.
      INSERT `removeStyleClass` INTO TABLE temp8.
      INSERT `sapUiResponsivePadding--header sapUiResponsivePadding--subHeader sapUiResponsivePadding--content sapUiResponsivePadding--footer` INTO TABLE temp8.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = temp8 ).
    ENDIF.

    
    CLEAR temp10.
    INSERT `myDialog` INTO TABLE temp10.
    INSERT `open` INTO TABLE temp10.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp10 ).

  ENDMETHOD.


  METHOD model_init.
    DATA temp12 LIKE t_products.
    DATA temp13 LIKE LINE OF temp12.
    DATA temp14 LIKE LINE OF t_products.
    DATA lr_product LIKE REF TO temp14.
      DATA temp15 TYPE decfloat34.
      DATA weight_num LIKE temp15.
      DATA temp16 TYPE z2ui5_cl_smpc_app_104=>ty_s_product-weight_state.

    " the original's view seeds the input with this product
    product_value = `Astro Phone 6`.

    
    CLEAR temp12.
    
    temp13-name = `Notebook Basic 15`.
    temp13-product_id = `HT-1000`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp13-width = `30`.
    temp13-depth = `18`.
    temp13-height = `3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `10`.
    temp13-price = '956.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Basic 17`.
    temp13-product_id = `HT-1001`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp13-width = `29`.
    temp13-depth = `17`.
    temp13-height = `3.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '1249.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Basic 18`.
    temp13-product_id = `HT-1002`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp13-width = `28`.
    temp13-depth = `19`.
    temp13-height = `2.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `10`.
    temp13-price = '1570.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Basic 19`.
    temp13-product_id = `HT-1003`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Smartcards`.
    temp13-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp13-width = `32`.
    temp13-depth = `21`.
    temp13-height = `4`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `15`.
    temp13-price = '1650.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO Vault`.
    temp13-product_id = `HT-1007`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp13-width = `32`.
    temp13-depth = `22`.
    temp13-height = `3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `15`.
    temp13-price = '299.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Professional 15`.
    temp13-product_id = `HT-1010`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp13-width = `33`.
    temp13-depth = `20`.
    temp13-height = `3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `16`.
    temp13-price = '1999.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Professional 17`.
    temp13-product_id = `HT-1011`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp13-width = `33`.
    temp13-depth = `23`.
    temp13-height = `2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.1`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `17`.
    temp13-price = '2299.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO Vault Net`.
    temp13-product_id = `HT-1020`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp13-width = `10`.
    temp13-depth = `1.8`.
    temp13-height = `17`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.16`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `14`.
    temp13-price = '459.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO Vault SAT`.
    temp13-product_id = `HT-1021`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp13-width = `11`.
    temp13-depth = `1.7`.
    temp13-height = `18`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.18`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `50`.
    temp13-price = '149.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Comfort Easy`.
    temp13-product_id = `HT-1022`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp13-width = `84`.
    temp13-depth = `1.5`.
    temp13-height = `14`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `30`.
    temp13-price = '1679.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Comfort Senior`.
    temp13-product_id = `HT-1023`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp13-width = `80`.
    temp13-depth = `1.6`.
    temp13-height = `13`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `24`.
    temp13-price = '512.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergo Screen E-I`.
    temp13-product_id = `HT-1030`.
    temp13-category = `Flat Screen Monitors`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp13-width = `37`.
    temp13-depth = `12`.
    temp13-height = `36`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `21`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `14`.
    temp13-price = '230.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergo Screen E-II`.
    temp13-product_id = `HT-1031`.
    temp13-category = `Flat Screen Monitors`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp13-width = `40.8`.
    temp13-depth = `19`.
    temp13-height = `43`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `21`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `24`.
    temp13-price = '285.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergo Screen E-III`.
    temp13-product_id = `HT-1032`.
    temp13-category = `Flat Screen Monitors`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp13-width = `40.8`.
    temp13-depth = `19`.
    temp13-height = `43`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `21`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `50`.
    temp13-price = '345.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Basic`.
    temp13-product_id = `HT-1035`.
    temp13-category = `Flat Screen Monitors`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp13-width = `39`.
    temp13-depth = `20`.
    temp13-height = `41`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `14`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `23`.
    temp13-price = '399.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Future`.
    temp13-product_id = `HT-1036`.
    temp13-category = `Flat Screen Monitors`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp13-width = `45`.
    temp13-depth = `26`.
    temp13-height = `46`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `15`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `22`.
    temp13-price = '430.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat XL`.
    temp13-product_id = `HT-1037`.
    temp13-category = `Flat Screen Monitors`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp13-width = `54.5`.
    temp13-depth = `22.1`.
    temp13-height = `39.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `17`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `23`.
    temp13-price = '1230.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Laser Professional Eco`.
    temp13-product_id = `HT-1040`.
    temp13-category = `Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Alpha Printers`.
    temp13-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp13-width = `51`.
    temp13-depth = `46`.
    temp13-height = `30`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `32`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `21`.
    temp13-price = '830.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Laser Basic`.
    temp13-product_id = `HT-1041`.
    temp13-category = `Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Alpha Printers`.
    temp13-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp13-width = `48`.
    temp13-depth = `42`.
    temp13-height = `26`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `23`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `8`.
    temp13-price = '490.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Laser Allround`.
    temp13-product_id = `HT-1042`.
    temp13-category = `Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Alpha Printers`.
    temp13-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp13-width = `53`.
    temp13-depth = `50`.
    temp13-height = `65`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `17`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `9`.
    temp13-price = '349.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ultra Jet Super Color`.
    temp13-product_id = `HT-1050`.
    temp13-category = `Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Alpha Printers`.
    temp13-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp13-width = `41`.
    temp13-depth = `41`.
    temp13-height = `28`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `17`.
    temp13-price = '139.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ultra Jet Mobile`.
    temp13-product_id = `HT-1051`.
    temp13-category = `Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Printer for All`.
    temp13-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp13-width = `46`.
    temp13-depth = `32`.
    temp13-height = `25`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1.9`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `18`.
    temp13-price = '99.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ultra Jet Super Highspeed`.
    temp13-product_id = `HT-1052`.
    temp13-category = `Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Printer for All`.
    temp13-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp13-width = `41`.
    temp13-depth = `41`.
    temp13-height = `28`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `18`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `25`.
    temp13-price = '170.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Multi Print`.
    temp13-product_id = `HT-1055`.
    temp13-category = `Multifunction Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Printer for All`.
    temp13-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp13-width = `55`.
    temp13-depth = `45`.
    temp13-height = `29`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `6.3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `16`.
    temp13-price = '99.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Multi Color`.
    temp13-product_id = `HT-1056`.
    temp13-category = `Multifunction Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Printer for All`.
    temp13-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp13-width = `51`.
    temp13-depth = `41.3`.
    temp13-height = `22`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `5`.
    temp13-price = '119.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cordless Mouse`.
    temp13-product_id = `HT-1060`.
    temp13-category = `Mice`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Oxynum`.
    temp13-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp13-width = `6`.
    temp13-depth = `14.5`.
    temp13-height = `3.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.09`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `25`.
    temp13-price = '9.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Speed Mouse`.
    temp13-product_id = `HT-1061`.
    temp13-category = `Mice`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Oxynum`.
    temp13-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp13-width = `7`.
    temp13-depth = `15`.
    temp13-height = `3.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.09`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `12`.
    temp13-price = '7.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Track Mouse`.
    temp13-product_id = `HT-1062`.
    temp13-category = `Mice`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Oxynum`.
    temp13-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp13-width = `3`.
    temp13-depth = `7`.
    temp13-height = `4`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.03`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `12`.
    temp13-price = '11.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergonomic Keyboard`.
    temp13-product_id = `HT-1063`.
    temp13-category = `Keyboards`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Oxynum`.
    temp13-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp13-width = `50`.
    temp13-depth = `21`.
    temp13-height = `3.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.1`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `50`.
    temp13-price = '14.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Internet Keyboard`.
    temp13-product_id = `HT-1064`.
    temp13-category = `Keyboards`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Oxynum`.
    temp13-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp13-width = `52`.
    temp13-depth = `25`.
    temp13-height = `3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `35`.
    temp13-price = '16.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Media Keyboard`.
    temp13-product_id = `HT-1065`.
    temp13-category = `Keyboards`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Oxynum`.
    temp13-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp13-width = `51.4`.
    temp13-depth = `23`.
    temp13-height = `4`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `26`.
    temp13-price = '26.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Mousepad`.
    temp13-product_id = `HT-1066`.
    temp13-category = `Mousepads`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Oxynum`.
    temp13-description = `Nice mouse pad with ITelO Logo`.
    temp13-width = `15`.
    temp13-depth = `6`.
    temp13-height = `0.2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `80`.
    temp13-weight_unit = `G`.
    temp13-quantity = `12`.
    temp13-price = '6.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergo Mousepad`.
    temp13-product_id = `HT-1067`.
    temp13-category = `Mousepads`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Oxynum`.
    temp13-description = `Ergonomic mouse pad with ITelO Logo`.
    temp13-width = `15`.
    temp13-depth = `6`.
    temp13-height = `0.2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `80`.
    temp13-weight_unit = `G`.
    temp13-quantity = `16`.
    temp13-price = '8.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Designer Mousepad`.
    temp13-product_id = `HT-1068`.
    temp13-category = `Mousepads`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `ITelO Mousepad Special Edition`.
    temp13-width = `24`.
    temp13-depth = `24`.
    temp13-height = `0.6`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `90`.
    temp13-weight_unit = `G`.
    temp13-quantity = `26`.
    temp13-price = '12.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Universal card reader`.
    temp13-product_id = `HT-1069`.
    temp13-category = `Computer System Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `Universal card reader`.
    temp13-width = `6`.
    temp13-depth = `6`.
    temp13-height = `3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `45`.
    temp13-weight_unit = `G`.
    temp13-quantity = `22`.
    temp13-price = '14.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Proctra X`.
    temp13-product_id = `HT-1070`.
    temp13-category = `Graphic Cards`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp13-width = `22`.
    temp13-depth = `35`.
    temp13-height = `17`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.255`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `15`.
    temp13-price = '70.90'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Gladiator MX`.
    temp13-product_id = `HT-1071`.
    temp13-category = `Graphic Cards`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp13-width = `22`.
    temp13-depth = `35`.
    temp13-height = `17`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `16`.
    temp13-price = '81.70'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Hurricane GX`.
    temp13-product_id = `HT-1072`.
    temp13-category = `Graphic Cards`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp13-width = `22`.
    temp13-depth = `35`.
    temp13-height = `17`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.4`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `13`.
    temp13-price = '101.20'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Hurricane GX/LN`.
    temp13-product_id = `HT-1073`.
    temp13-category = `Graphic Cards`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Smartcards`.
    temp13-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp13-width = `22`.
    temp13-depth = `35`.
    temp13-height = `17`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.4`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `5`.
    temp13-price = '139.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Photo Scan`.
    temp13-product_id = `HT-1080`.
    temp13-category = `Scanners`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Printer for All`.
    temp13-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp13-width = `34`.
    temp13-depth = `48`.
    temp13-height = `5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `8`.
    temp13-price = '129.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Power Scan`.
    temp13-product_id = `HT-1081`.
    temp13-category = `Scanners`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Printer for All`.
    temp13-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp13-width = `31`.
    temp13-depth = `43`.
    temp13-height = `7`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.4`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `11`.
    temp13-price = '89.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Jet Scan Professional`.
    temp13-product_id = `HT-1082`.
    temp13-category = `Scanners`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Printer for All`.
    temp13-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp13-width = `33`.
    temp13-depth = `41`.
    temp13-height = `12`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `13`.
    temp13-price = '169.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Jet Scan Professional`.
    temp13-product_id = `HT-1083`.
    temp13-category = `Scanners`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Printer for All`.
    temp13-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp13-width = `35`.
    temp13-depth = `40`.
    temp13-height = `10`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `10`.
    temp13-price = '189.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Copymaster`.
    temp13-product_id = `HT-1085`.
    temp13-category = `Multifunction Printers`.
    temp13-main_category = `Printers & Scanners`.
    temp13-supplier_name = `Alpha Printers`.
    temp13-description = `Copymaster`.
    temp13-width = `45`.
    temp13-depth = `42`.
    temp13-height = `22`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `23.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `10`.
    temp13-price = '1499.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Surround Sound`.
    temp13-product_id = `HT-1090`.
    temp13-category = `Speakers`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Speaker Experts`.
    temp13-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp13-width = `12`.
    temp13-depth = `10`.
    temp13-height = `16`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '39.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Blaster Extreme`.
    temp13-product_id = `HT-1091`.
    temp13-category = `Speakers`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Speaker Experts`.
    temp13-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp13-width = `13`.
    temp13-depth = `11`.
    temp13-height = `17.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1.4`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `15`.
    temp13-price = '26.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Sound Booster`.
    temp13-product_id = `HT-1092`.
    temp13-category = `Speakers`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Speaker Experts`.
    temp13-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp13-width = `12.4`.
    temp13-depth = `10.4`.
    temp13-height = `18.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.1`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `50`.
    temp13-price = '45.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Lovely Sound 5.1 Wireless`.
    temp13-product_id = `HT-1095`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp13-width = `24`.
    temp13-depth = `19`.
    temp13-height = `23`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `80`.
    temp13-weight_unit = `G`.
    temp13-quantity = `12`.
    temp13-price = '49.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Lovely Sound 5.1`.
    temp13-product_id = `HT-1096`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp13-width = `25`.
    temp13-depth = `17`.
    temp13-height = `19`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `130`.
    temp13-weight_unit = `G`.
    temp13-quantity = `18`.
    temp13-price = '39.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Lovely Sound Stereo`.
    temp13-product_id = `HT-1097`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp13-width = `21.3`.
    temp13-depth = `2.4`.
    temp13-height = `19.7`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `60`.
    temp13-weight_unit = `G`.
    temp13-quantity = `21`.
    temp13-price = '29.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Office`.
    temp13-product_id = `HT-1100`.
    temp13-category = `Software`.
    temp13-main_category = `Software`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp13-width = `15`.
    temp13-depth = `6.5`.
    temp13-height = `2.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `25`.
    temp13-price = '89.90'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Design`.
    temp13-product_id = `HT-1101`.
    temp13-category = `Software`.
    temp13-main_category = `Software`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Complete package, 1 User, Image editing, processing`.
    temp13-width = `14`.
    temp13-depth = `6.7`.
    temp13-height = `24`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `26`.
    temp13-price = '79.90'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Network`.
    temp13-product_id = `HT-1102`.
    temp13-category = `Software`.
    temp13-main_category = `Software`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp13-width = `16`.
    temp13-depth = `6`.
    temp13-height = `27`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `28`.
    temp13-price = '69.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Multimedia`.
    temp13-product_id = `HT-1103`.
    temp13-category = `Software`.
    temp13-main_category = `Software`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp13-width = `11`.
    temp13-depth = `3.4`.
    temp13-height = `22`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `9`.
    temp13-price = '77.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Games`.
    temp13-product_id = `HT-1104`.
    temp13-category = `Software`.
    temp13-main_category = `Software`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp13-width = `10`.
    temp13-depth = `3`.
    temp13-height = `30`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1.1`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `13`.
    temp13-price = '55.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Internet Antivirus`.
    temp13-product_id = `HT-1105`.
    temp13-category = `Software`.
    temp13-main_category = `Software`.
    temp13-supplier_name = `Brainsoft`.
    temp13-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp13-width = `16`.
    temp13-depth = `4`.
    temp13-height = `21`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.7`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `17`.
    temp13-price = '29.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Firewall`.
    temp13-product_id = `HT-1106`.
    temp13-category = `Software`.
    temp13-main_category = `Software`.
    temp13-supplier_name = `Brainsoft`.
    temp13-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp13-width = `17.9`.
    temp13-depth = `4.2`.
    temp13-height = `23.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.9`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `19`.
    temp13-price = '34.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Money`.
    temp13-product_id = `HT-1107`.
    temp13-category = `Software`.
    temp13-main_category = `Software`.
    temp13-supplier_name = `Brainsoft`.
    temp13-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp13-width = `12`.
    temp13-depth = `1.5`.
    temp13-height = `19`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `18`.
    temp13-price = '29.90'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `PC Lock`.
    temp13-product_id = `HT-1110`.
    temp13-category = `Computer System Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Red Point Stores`.
    temp13-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp13-width = `20`.
    temp13-depth = `8`.
    temp13-height = `4.3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.03`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `14`.
    temp13-price = '8.90'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Lock`.
    temp13-product_id = `HT-1111`.
    temp13-category = `Computer System Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Red Point Stores`.
    temp13-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp13-width = `31`.
    temp13-depth = `9`.
    temp13-height = `7`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.02`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '6.90'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Web cam reality`.
    temp13-product_id = `HT-1112`.
    temp13-category = `Computer System Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Red Point Stores`.
    temp13-description = `Color webcam, color, High-Speed USB`.
    temp13-width = `9`.
    temp13-depth = `8.2`.
    temp13-height = `1.3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.075`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `27`.
    temp13-price = '39.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Screen clean`.
    temp13-product_id = `HT-1113`.
    temp13-category = `Computer System Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Red Point Stores`.
    temp13-description = `10 separately packed screen wipes`.
    temp13-width = `2`.
    temp13-depth = `2`.
    temp13-height = `0.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.05`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `17`.
    temp13-price = '2.30'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Fabric bag professional`.
    temp13-product_id = `HT-1114`.
    temp13-category = `Computer System Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Red Point Stores`.
    temp13-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp13-width = `42`.
    temp13-depth = `32`.
    temp13-height = `7`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `14`.
    temp13-price = '31.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Wireless DSL Router`.
    temp13-product_id = `HT-1115`.
    temp13-category = `Telecommunications`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Red Point Stores`.
    temp13-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp13-width = `19.3`.
    temp13-depth = `18`.
    temp13-height = `5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.45`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `16`.
    temp13-price = '49.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Wireless DSL Router / Repeater`.
    temp13-product_id = `HT-1116`.
    temp13-category = `Telecommunications`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Red Point Stores`.
    temp13-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp13-width = `19.3`.
    temp13-depth = `18`.
    temp13-height = `5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.45`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `12`.
    temp13-price = '59.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Wireless DSL Router / Repeater and Print Server`.
    temp13-product_id = `HT-1117`.
    temp13-category = `Telecommunications`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp13-width = `19.3`.
    temp13-depth = `18`.
    temp13-height = `5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.45`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `12`.
    temp13-price = '69.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `USB Stick`.
    temp13-product_id = `HT-1118`.
    temp13-category = `Computer System Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `USB 2.0 High-Speed 64 GB`.
    temp13-width = `1.5`.
    temp13-depth = `8.7`.
    temp13-height = `1.2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.015`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `14`.
    temp13-price = '35.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Travel Adapter`.
    temp13-product_id = `HT-1119`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Universal Travel Adapter`.
    temp13-width = `2`.
    temp13-depth = `3.1`.
    temp13-height = `3.9`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `88`.
    temp13-weight_unit = `G`.
    temp13-quantity = `10`.
    temp13-price = '79.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cordless Bluetooth Keyboard, english international`.
    temp13-product_id = `HT-1120`.
    temp13-category = `Keyboards`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Cordless Bluetooth Keyboard with English keys`.
    temp13-width = `51.4`.
    temp13-depth = `23`.
    temp13-height = `4`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `13`.
    temp13-price = '29.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat XXL`.
    temp13-product_id = `HT-1137`.
    temp13-category = `Flat Screen Monitors`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp13-width = `54`.
    temp13-depth = `22`.
    temp13-height = `38`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `18`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `10`.
    temp13-price = '1430.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Pocket Mouse`.
    temp13-product_id = `HT-1138`.
    temp13-category = `Mice`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Portable pocket Mouse with retracting cord`.
    temp13-width = `0.3`.
    temp13-depth = `0.5`.
    temp13-height = `1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.02`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '23.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `PC Power Station`.
    temp13-product_id = `HT-1210`.
    temp13-category = `PCs`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp13-width = `28`.
    temp13-depth = `31`.
    temp13-height = `43`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `22`.
    temp13-price = '2399.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Astro Laptop 1516`.
    temp13-product_id = `HT-1251`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp13-width = `30`.
    temp13-depth = `18`.
    temp13-height = `3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `23`.
    temp13-price = '989.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Astro Phone 6`.
    temp13-product_id = `HT-1252`.
    temp13-category = `Smartphones and Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp13-width = `8`.
    temp13-depth = `6`.
    temp13-height = `1.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.75`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `28`.
    temp13-price = '649.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Benda Laptop 1408`.
    temp13-product_id = `HT-1253`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp13-width = `30`.
    temp13-depth = `18`.
    temp13-height = `3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `27`.
    temp13-price = '976.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Bending Screen 21HD`.
    temp13-product_id = `HT-1254`.
    temp13-category = `Flat Screens`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp13-width = `37`.
    temp13-depth = `12`.
    temp13-height = `36`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `15`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `23`.
    temp13-price = '250.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Broad Screen 22HD`.
    temp13-product_id = `HT-1255`.
    temp13-category = `Flat Screens`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp13-width = `39`.
    temp13-depth = `12`.
    temp13-height = `38`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `16`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `5`.
    temp13-price = '270.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cerdik Phone 7`.
    temp13-product_id = `HT-1256`.
    temp13-category = `Smartphones and Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp13-width = `9`.
    temp13-depth = `15`.
    temp13-height = `1.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.75`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `19`.
    temp13-price = '549.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cepat Tablet 10.5`.
    temp13-product_id = `HT-1257`.
    temp13-category = `Smartphones and Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `17`.
    temp13-price = '549.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cepat Tablet 8`.
    temp13-product_id = `HT-1258`.
    temp13-category = `Smartphones and Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp13-width = `38`.
    temp13-depth = `21`.
    temp13-height = `3.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `24`.
    temp13-price = '529.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Server Basic`.
    temp13-product_id = `HT-1500`.
    temp13-category = `Servers`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp13-width = `34`.
    temp13-depth = `35`.
    temp13-height = `23`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `18`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `24`.
    temp13-price = '5000.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Server Professional`.
    temp13-product_id = `HT-1501`.
    temp13-category = `Servers`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp13-width = `29`.
    temp13-depth = `30`.
    temp13-height = `27`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `25`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `26`.
    temp13-price = '15000.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Server Power Pro`.
    temp13-product_id = `HT-1502`.
    temp13-category = `Servers`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp13-width = `22`.
    temp13-depth = `27.3`.
    temp13-height = `37`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `35`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `34`.
    temp13-price = '25000.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Family PC Basic`.
    temp13-product_id = `HT-1600`.
    temp13-category = `Desktop Computers`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp13-width = `21.4`.
    temp13-depth = `29`.
    temp13-height = `38`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `10`.
    temp13-price = '600.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Family PC Pro`.
    temp13-product_id = `HT-1601`.
    temp13-category = `Desktop Computers`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp13-width = `25`.
    temp13-depth = `31.7`.
    temp13-height = `40.2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `5.3`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '900.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Gaming Monster`.
    temp13-product_id = `HT-1602`.
    temp13-category = `Desktop Computers`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp13-width = `26.5`.
    temp13-depth = `34`.
    temp13-height = `47`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `5.9`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `24`.
    temp13-price = '1200.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Gaming Monster Pro`.
    temp13-product_id = `HT-1603`.
    temp13-category = `Desktop Computers`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp13-width = `27`.
    temp13-depth = `28`.
    temp13-height = `42`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `6.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `25`.
    temp13-price = '1700.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `7" Widescreen Portable DVD Player w MP3`.
    temp13-product_id = `HT-2000`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp13-width = `21.4`.
    temp13-depth = `19`.
    temp13-height = `27.6`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.79`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '249.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `10" Portable DVD player`.
    temp13-product_id = `HT-2001`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp13-width = `24`.
    temp13-depth = `19.5`.
    temp13-height = `29`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.84`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `21`.
    temp13-price = '449.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Portable DVD Player with 9" LCD Monitor`.
    temp13-product_id = `HT-2002`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp13-width = `21`.
    temp13-depth = `16.5`.
    temp13-height = `14`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.72`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `50`.
    temp13-price = '853.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `CD/DVD case: 264 sleeves`.
    temp13-product_id = `HT-2025`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp13-width = `13`.
    temp13-depth = `13`.
    temp13-height = `20`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.65`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `26`.
    temp13-price = '44.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Audio/Video Cable Kit - 4m`.
    temp13-product_id = `HT-2026`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Quality cables for notebooks and projectors`.
    temp13-width = `21`.
    temp13-depth = `10.2`.
    temp13-height = `13`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `16`.
    temp13-price = '29.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Removable CD/DVD Laser Labels`.
    temp13-product_id = `HT-2027`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Removable jewel case labels, zero residues (100)`.
    temp13-width = `5.5`.
    temp13-depth = `2`.
    temp13-height = `2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.15`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `25`.
    temp13-price = '8.99'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Beam Breaker B-1`.
    temp13-product_id = `HT-6100`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp13-width = `30.4`.
    temp13-depth = `23.1`.
    temp13-height = `23`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1.7`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `32`.
    temp13-price = '469.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Beam Breaker B-2`.
    temp13-product_id = `HT-6101`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp13-width = `30.4`.
    temp13-depth = `23.1`.
    temp13-height = `23`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `18`.
    temp13-price = '679.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Beam Breaker B-3`.
    temp13-product_id = `HT-6102`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Technocom`.
    temp13-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp13-width = `30.4`.
    temp13-depth = `23.1`.
    temp13-height = `23`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `16`.
    temp13-price = '889.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Play Movie`.
    temp13-product_id = `HT-6110`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp13-width = `37`.
    temp13-depth = `24`.
    temp13-height = `6`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.4`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `15`.
    temp13-price = '130.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Record Movie`.
    temp13-product_id = `HT-6111`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp13-width = `38`.
    temp13-depth = `26`.
    temp13-height = `6.2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.1`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `24`.
    temp13-price = '288.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelo MusicStick`.
    temp13-product_id = `HT-6120`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `64 GB USB Music-on-Available-Stick`.
    temp13-width = `1.5`.
    temp13-depth = `6`.
    temp13-height = `1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `134`.
    temp13-weight_unit = `G`.
    temp13-quantity = `15`.
    temp13-price = '45.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelo Jog-Mate`.
    temp13-product_id = `HT-6121`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp13-width = `5.1`.
    temp13-depth = `8`.
    temp13-height = `9.2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `134`.
    temp13-weight_unit = `G`.
    temp13-quantity = `24`.
    temp13-price = '63.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Power Pro Player 40`.
    temp13-product_id = `HT-6122`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp13-width = `5.1`.
    temp13-depth = `8`.
    temp13-height = `9.2`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `266`.
    temp13-weight_unit = `G`.
    temp13-quantity = `23`.
    temp13-price = '167.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Power Pro Player 80`.
    temp13-product_id = `HT-6123`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp13-width = `4`.
    temp13-depth = `6`.
    temp13-height = `0.8`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `267`.
    temp13-weight_unit = `G`.
    temp13-quantity = `13`.
    temp13-price = '299.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Watch HD32`.
    temp13-product_id = `HT-6130`.
    temp13-category = `Flat Screen TVs`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp13-width = `78`.
    temp13-depth = `22.1`.
    temp13-height = `55`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.6`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `16`.
    temp13-price = '1459.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Watch HD37`.
    temp13-product_id = `HT-6131`.
    temp13-category = `Flat Screen TVs`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp13-width = `99.1`.
    temp13-depth = `26`.
    temp13-height = `61`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `2.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `14`.
    temp13-price = '1199.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Watch HD41`.
    temp13-product_id = `HT-6132`.
    temp13-category = `Flat Screen TVs`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Very Best Screens`.
    temp13-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp13-width = `128`.
    temp13-depth = `23`.
    temp13-height = `79.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `1.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `13`.
    temp13-price = '899.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Copperberry`.
    temp13-product_id = `HT-7000`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `Our new multifunctional Handheld with phone function in copper`.
    temp13-width = `8.1`.
    temp13-depth = `13`.
    temp13-height = `12.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `5`.
    temp13-price = '549.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Silverberry`.
    temp13-product_id = `HT-7010`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `Our new multifunctional Handheld with phone function in silver`.
    temp13-width = `8.1`.
    temp13-depth = `13`.
    temp13-height = `12.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `9`.
    temp13-price = '549.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Goldberry`.
    temp13-product_id = `HT-7020`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `Our new multifunctional Handheld with phone function in gold`.
    temp13-width = `8.1`.
    temp13-depth = `13`.
    temp13-height = `12.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `11`.
    temp13-price = '549.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Platinberry`.
    temp13-product_id = `HT-7030`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Components`.
    temp13-supplier_name = `Fasttech`.
    temp13-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp13-width = `8.1`.
    temp13-depth = `13`.
    temp13-height = `12.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `12`.
    temp13-price = '549.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO FlexTop I4000`.
    temp13-product_id = `HT-8000`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp13-width = `31`.
    temp13-depth = `19`.
    temp13-height = `3.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `11`.
    temp13-price = '799.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO FlexTop I6300c`.
    temp13-product_id = `HT-8001`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp13-width = `32`.
    temp13-depth = `20`.
    temp13-height = `3.4`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `4.2`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '799.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO FlexTop I9100`.
    temp13-product_id = `HT-8002`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp13-width = `38`.
    temp13-depth = `21`.
    temp13-height = `4.1`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.5`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '1199.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO FlexTop I9800`.
    temp13-product_id = `HT-8003`.
    temp13-category = `Laptops`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `22`.
    temp13-price = '1388.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smartphone Leather Case`.
    temp13-product_id = `HT-9991`.
    temp13-category = `Accessories`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.02`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `12`.
    temp13-price = '25.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smartphone Alpha`.
    temp13-product_id = `HT-9992`.
    temp13-category = `Smartphones and Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.75`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `13`.
    temp13-price = '599.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Mini Tablet`.
    temp13-product_id = `HT-9993`.
    temp13-category = `Smartphones and Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `10`.
    temp13-price = '833.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Camcorder View`.
    temp13-product_id = `HT-9994`.
    temp13-category = `Accessories`.
    temp13-main_category = `TV, Video & HiFi`.
    temp13-supplier_name = `Ultrasonic United`.
    temp13-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `27`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `50`.
    temp13-price = '1388.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Tablet Pouch`.
    temp13-product_id = `HT-9995`.
    temp13-category = `Accessories`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp13-width = `25`.
    temp13-depth = `40`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.03`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `34`.
    temp13-price = '20.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Tablet Pouch`.
    temp13-product_id = `HT-9996`.
    temp13-category = `Accessories`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp13-width = `25`.
    temp13-depth = `40`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.03`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `34`.
    temp13-price = '20.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `e-Book Reader ReadMe`.
    temp13-product_id = `HT-9997`.
    temp13-category = `Smartphones and Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `23`.
    temp13-price = '33.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smartphone Beta`.
    temp13-product_id = `HT-9998`.
    temp13-category = `Smartphones and Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.75`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `21`.
    temp13-price = '30.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Maxi Tablet`.
    temp13-product_id = `HT-9999`.
    temp13-category = `Tablets`.
    temp13-main_category = `Smartphones & Tablets`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp13-width = `48`.
    temp13-depth = `31`.
    temp13-height = `4.5`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `3.8`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `20`.
    temp13-price = '749.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flyer`.
    temp13-product_id = `PF-1000`.
    temp13-category = `Accessories`.
    temp13-main_category = `Computer Systems`.
    temp13-supplier_name = `Titanium`.
    temp13-description = `Flyer for our product palette`.
    temp13-width = `46`.
    temp13-depth = `30`.
    temp13-height = `3`.
    temp13-dim_unit = `cm`.
    temp13-weight_measure = `0.01`.
    temp13-weight_unit = `KG`.
    temp13-quantity = `33`.
    temp13-price = '0.00'.
    temp13-currency_code = `EUR`.
    INSERT temp13 INTO TABLE temp12.
    t_products = temp12.

    " weightState per the demo Formatter (parseFloat thresholds), computed in ABAP
    " (thin frontend): all product weights are < 1000, so Success throughout
    
    
    LOOP AT t_products REFERENCE INTO lr_product.
      
      temp15 = lr_product->weight_measure.
      
      weight_num = temp15.
      
      IF weight_num < 0.
        temp16 = `None`.
      ELSEIF weight_num < 1000.
        temp16 = `Success`.
      ELSEIF weight_num < 2000.
        temp16 = `Warning`.
      ELSE.
        temp16 = `Error`.
      ENDIF.
      lr_product->weight_state = temp16.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
