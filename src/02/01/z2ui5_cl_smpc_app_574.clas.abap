" @keywords table sap.m tablemultiselectmode overflowtoolbar title toolbarspacer searchfield label switch combobox item button
" @summary This example demonstrates the different multi-selection modes if the table is configured with MultiToggle mode and the sap.m.table.Title control.
" @origin sap.m.sample.TableMultiSelectMode - https://sdk.openui5.org/entity/sap.m.Table/sample/sap.m.sample.TableMultiSelectMode (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_574 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid    TYPE string,
        name         TYPE string,
        suppliername TYPE string,
        width        TYPE string,
        depth        TYPE string,
        height       TYPE string,
        dimunit      TYPE string,
        selected     TYPE abap_bool,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    " the rows the search leaves visible; T_PRODUCTS stays the full set
    DATA t_rows TYPE ty_t_product.

    " the ui> view model of the sample
    DATA totalcount    TYPE i.
    DATA selectedcount TYPE i.
    DATA show_total    TYPE abap_bool VALUE abap_true.
    DATA extended_view TYPE abap_bool.
    DATA select_mode   TYPE string VALUE `Default`.

  PROTECTED SECTION.
    DATA client      TYPE REF TO z2ui5_if_client.
    DATA t_products  TYPE ty_t_product.
    DATA new_counter TYPE i.

    METHODS view_display.
    METHODS counts_refresh.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_574 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      t_rows = t_products.
      counts_refresh( ).
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
        )->a( n = `xmlns`       v = `sap.m`
        )->a( n = `xmlns:mvc`   v = `sap.ui.core.mvc`
        )->a( n = `xmlns:table` v = `sap.m.table`
        )->a( n = `xmlns:core`  v = `sap.ui.core`

        )->ele( `Table`
            )->a( n = `id`                 v = `idProductsTable`
            )->a( n = `mode`               v = `MultiSelect`
            )->a( n = `items`              v = |\{ path: '{ client->_bind_path( t_rows ) }', sorter: \{ path: 'NAME' \} \}|
            )->a( n = `itemActionCount`    v = `1`
            )->a( n = `rememberSelections` v = `false`
            )->a( n = `selectionChange`    v = client->_event( `ROW_SELECTION` )
            " onItemActionPress deletes the row the action was fired on; the event
            " ships the list item, so its ProductId travels with it
            )->a( n = `itemActionPress`    v = client->_event( val = `ITEM_ACTION` arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )
            " onSelectionChange of the ComboBox calls setMultiSelectionMode - see
            " the sidecar; the real property is multiSelectMode and it is bindable
            )->a( n = `multiSelectMode`    v = client->_bind( select_mode )

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`

                    )->ele( n = `Title` ns = `table`
                        )->a( n = `id`               v = `idTableTitle`
                        )->a( n = `totalCount`       v = client->_bind( totalcount )
                        )->a( n = `selectedCount`    v = client->_bind( selectedcount )
                        )->a( n = `showExtendedView` v = client->_bind( extended_view )

                        )->tag( `Title`
                            )->a( n = `text`  v = `Products`
                            )->a( n = `level` v = `H2`

                    )->end(
                    )->tag( `ToolbarSpacer`
                    )->tag( `SearchField`
                        )->a( n = `id`          v = `idSearchField`
                        )->a( n = `width`       v = `15rem`
                        )->a( n = `placeholder` v = `Search products...`
                        )->a( n = `search`      v = client->_event( val = `SEARCH` arg = `${$parameters>/query}` )
                    )->tag( `Label`
                        )->a( n = `text`     v = `Extended view`
                        )->a( n = `labelFor` v = `extViewSwitch`
                    )->tag( `Switch`
                        )->a( n = `id`    v = `extViewSwitch`
                        )->a( n = `state` v = client->_bind( extended_view )
                    )->tag( `Label`
                        )->a( n = `text`     v = `Show totalCount`
                        )->a( n = `labelFor` v = `disableTotalCountSwitch`
                    )->tag( `Switch`
                        )->a( n = `id`     v = `disableTotalCountSwitch`
                        )->a( n = `state`  v = client->_bind( show_total )
                        )->a( n = `change` v = client->_event( `TOGGLE_TOTAL` )
                    )->tag( `Label`
                        )->a( n = `text`     v = `Multi selection modes`
                        )->a( n = `labelFor` v = `idComboBoxSuccess`
                    )->ele( `ComboBox`
                        )->a( n = `id`          v = `idComboBoxSuccess`
                        )->a( n = `selectedKey` v = client->_bind( select_mode )

                        )->tag( n = `Item` ns = `core`
                            )->a( n = `text` v = `Default`
                            )->a( n = `key`  v = `Default`
                        )->tag( n = `Item` ns = `core`
                            )->a( n = `text` v = `ClearAll`
                            )->a( n = `key`  v = `ClearAll`

                    )->end(
                    )->tag( `Button`
                        )->a( n = `icon`  v = `sap-icon://add`
                        )->a( n = `text`  v = `Add randomized product`
                        )->a( n = `press` v = client->_event( `ADD_ROW` )

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
                    )->a( n = `minScreenWidth` v = `Tablet`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Dimensions`

                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->a( n = `vAlign`   v = `Middle`
                    )->a( n = `selected` v = `{SELECTED}`

                    )->ele( `actions`
                        )->tag( `ListItemAction`
                            )->a( n = `type` v = `Delete`

                    )->end(
                    )->ele( `cells`
                        )->tag( `ObjectIdentifier`
                            )->a( n = `title` v = `{NAME}`
                            )->a( n = `text`  v = `{PRODUCTID}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{SUPPLIERNAME}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{WIDTH} x {DEPTH} x {HEIGHT} {DIMUNIT}`

                    )->end(
                )->end(
            )->end(
        )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD counts_refresh.

    " _updateTotalCount / _updateSelectedCount read the binding and the selection;
    " the backend holds both, so it counts them here
    DATA temp1 TYPE i.
    DATA temp2 TYPE i.
    DATA n TYPE i.
    DATA row LIKE LINE OF t_rows.
      DATA temp3 TYPE i.
    IF show_total = abap_true.
      temp1 = lines( t_rows ).
    ELSE.
      temp1 = -1.
    ENDIF.
    totalcount = temp1.
    
    
    n = 0.
    
    LOOP AT t_rows INTO row.
      
      IF row-selected = abap_true.
        temp3 = n + 1.
      ELSE.
        temp3 = n.
      ENDIF.
      n = temp3.
    ENDLOOP.
    temp2 = n.
    selectedcount = temp2.

  ENDMETHOD.


  METHOD on_event.
        DATA query TYPE string.
          DATA temp3 TYPE z2ui5_cl_smpc_app_574=>ty_t_product.
          DATA product LIKE LINE OF t_products.
        DATA del_id TYPE string.
        DATA temp4 LIKE LINE OF t_rows.
        DATA row LIKE REF TO temp4.
        DATA temp5 TYPE string_table.
        DATA suppliers LIKE temp5.
        DATA temp7 TYPE ty_s_product.
        FIELD-SYMBOLS <temp4> LIKE LINE OF suppliers.
        DATA temp6 LIKE sy-tabix.
        DATA new_row LIKE temp7.

    CASE client->get_event( ).

      WHEN `ROW_SELECTION`.
        counts_refresh( ).

      WHEN `TOGGLE_TOTAL`.
        counts_refresh( ).

      WHEN `SEARCH`.
        " onSearch filters Name, SupplierName and ProductId with an OR filter
        
        query = to_upper( client->get_event_arg( ) ).
        IF query IS INITIAL.
          t_rows = t_products.
        ELSE.
          
          CLEAR temp3.
          t_rows = temp3.
          
          LOOP AT t_products INTO product.
            IF to_upper( product-name ) CS query
                OR to_upper( product-suppliername ) CS query OR to_upper( product-productid ) CS query.
              APPEND product TO t_rows.
            ENDIF.
          ENDLOOP.
        ENDIF.
        counts_refresh( ).

      WHEN `ITEM_ACTION`.
        " onItemActionPress deletes the row, clears the selection and toasts
        
        del_id = client->get_event_arg( ).
        DELETE t_products WHERE productid = del_id.
        DELETE t_rows WHERE productid = del_id.
        
        
        LOOP AT t_rows REFERENCE INTO row.
          row->selected = abap_false.
        ENDLOOP.
        counts_refresh( ).
        client->message_toast_display( `Product deleted and selection cleared.` ).

      WHEN `ADD_ROW`.
        " onAddRow appends a product with randomised values; a backend cannot
        " repeat a client-side random draw, so it counts up instead
        new_counter = new_counter + 1.
        
        CLEAR temp5.
        INSERT `SupplierA` INTO TABLE temp5.
        INSERT `SupplierB` INTO TABLE temp5.
        INSERT `SupplierC` INTO TABLE temp5.
        
        suppliers = temp5.
        
        CLEAR temp7.
        temp7-productid = |PRD-{ new_counter }|.
        temp7-name = |Product { new_counter }|.
        
        
        temp6 = sy-tabix.
        READ TABLE suppliers INDEX ( new_counter - 1 ) MOD 3 + 1 ASSIGNING <temp4>.
        sy-tabix = temp6.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        temp7-suppliername = <temp4>.
        temp7-width = |{ 10 + new_counter MOD 50 }|.
        temp7-depth = |{ 10 + new_counter MOD 50 }|.
        temp7-height = |{ 10 + new_counter MOD 50 }|.
        temp7-dimunit = `cm`.
        
        new_row = temp7.
        APPEND new_row TO t_products.
        APPEND new_row TO t_rows.
        counts_refresh( ).
        client->message_toast_display( |New product added: { new_row-name }| ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " the full mock /ProductCollection, in the mock order - the items binding
    " keeps its own sorter on NAME
    DATA temp8 TYPE z2ui5_cl_smpc_app_574=>ty_t_product.
    DATA temp9 LIKE LINE OF temp8.
    CLEAR temp8.
    
    temp9-productid = `HT-1000`.
    temp9-name = `Notebook Basic 15`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `30`.
    temp9-depth = `18`.
    temp9-height = `3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1001`.
    temp9-name = `Notebook Basic 17`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `29`.
    temp9-depth = `17`.
    temp9-height = `3.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1002`.
    temp9-name = `Notebook Basic 18`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `28`.
    temp9-depth = `19`.
    temp9-height = `2.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1003`.
    temp9-name = `Notebook Basic 19`.
    temp9-suppliername = `Smartcards`.
    temp9-width = `32`.
    temp9-depth = `21`.
    temp9-height = `4`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1007`.
    temp9-name = `ITelO Vault`.
    temp9-suppliername = `Technocom`.
    temp9-width = `32`.
    temp9-depth = `22`.
    temp9-height = `3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1010`.
    temp9-name = `Notebook Professional 15`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `33`.
    temp9-depth = `20`.
    temp9-height = `3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1011`.
    temp9-name = `Notebook Professional 17`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `33`.
    temp9-depth = `23`.
    temp9-height = `2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1020`.
    temp9-name = `ITelO Vault Net`.
    temp9-suppliername = `Technocom`.
    temp9-width = `10`.
    temp9-depth = `1.8`.
    temp9-height = `17`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1021`.
    temp9-name = `ITelO Vault SAT`.
    temp9-suppliername = `Technocom`.
    temp9-width = `11`.
    temp9-depth = `1.7`.
    temp9-height = `18`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1022`.
    temp9-name = `Comfort Easy`.
    temp9-suppliername = `Technocom`.
    temp9-width = `84`.
    temp9-depth = `1.5`.
    temp9-height = `14`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1023`.
    temp9-name = `Comfort Senior`.
    temp9-suppliername = `Technocom`.
    temp9-width = `80`.
    temp9-depth = `1.6`.
    temp9-height = `13`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1030`.
    temp9-name = `Ergo Screen E-I`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `37`.
    temp9-depth = `12`.
    temp9-height = `36`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1031`.
    temp9-name = `Ergo Screen E-II`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `40.8`.
    temp9-depth = `19`.
    temp9-height = `43`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1032`.
    temp9-name = `Ergo Screen E-III`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `40.8`.
    temp9-depth = `19`.
    temp9-height = `43`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1035`.
    temp9-name = `Flat Basic`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `39`.
    temp9-depth = `20`.
    temp9-height = `41`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1036`.
    temp9-name = `Flat Future`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `45`.
    temp9-depth = `26`.
    temp9-height = `46`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1037`.
    temp9-name = `Flat XL`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `54.5`.
    temp9-depth = `22.1`.
    temp9-height = `39.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1040`.
    temp9-name = `Laser Professional Eco`.
    temp9-suppliername = `Alpha Printers`.
    temp9-width = `51`.
    temp9-depth = `46`.
    temp9-height = `30`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1041`.
    temp9-name = `Laser Basic`.
    temp9-suppliername = `Alpha Printers`.
    temp9-width = `48`.
    temp9-depth = `42`.
    temp9-height = `26`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1042`.
    temp9-name = `Laser Allround`.
    temp9-suppliername = `Alpha Printers`.
    temp9-width = `53`.
    temp9-depth = `50`.
    temp9-height = `65`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1050`.
    temp9-name = `Ultra Jet Super Color`.
    temp9-suppliername = `Alpha Printers`.
    temp9-width = `41`.
    temp9-depth = `41`.
    temp9-height = `28`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1051`.
    temp9-name = `Ultra Jet Mobile`.
    temp9-suppliername = `Printer for All`.
    temp9-width = `46`.
    temp9-depth = `32`.
    temp9-height = `25`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1052`.
    temp9-name = `Ultra Jet Super Highspeed`.
    temp9-suppliername = `Printer for All`.
    temp9-width = `41`.
    temp9-depth = `41`.
    temp9-height = `28`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1055`.
    temp9-name = `Multi Print`.
    temp9-suppliername = `Printer for All`.
    temp9-width = `55`.
    temp9-depth = `45`.
    temp9-height = `29`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1056`.
    temp9-name = `Multi Color`.
    temp9-suppliername = `Printer for All`.
    temp9-width = `51`.
    temp9-depth = `41.3`.
    temp9-height = `22`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1060`.
    temp9-name = `Cordless Mouse`.
    temp9-suppliername = `Oxynum`.
    temp9-width = `6`.
    temp9-depth = `14.5`.
    temp9-height = `3.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1061`.
    temp9-name = `Speed Mouse`.
    temp9-suppliername = `Oxynum`.
    temp9-width = `7`.
    temp9-depth = `15`.
    temp9-height = `3.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1062`.
    temp9-name = `Track Mouse`.
    temp9-suppliername = `Oxynum`.
    temp9-width = `3`.
    temp9-depth = `7`.
    temp9-height = `4`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1063`.
    temp9-name = `Ergonomic Keyboard`.
    temp9-suppliername = `Oxynum`.
    temp9-width = `50`.
    temp9-depth = `21`.
    temp9-height = `3.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1064`.
    temp9-name = `Internet Keyboard`.
    temp9-suppliername = `Oxynum`.
    temp9-width = `52`.
    temp9-depth = `25`.
    temp9-height = `3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1065`.
    temp9-name = `Media Keyboard`.
    temp9-suppliername = `Oxynum`.
    temp9-width = `51.4`.
    temp9-depth = `23`.
    temp9-height = `4`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1066`.
    temp9-name = `Mousepad`.
    temp9-suppliername = `Oxynum`.
    temp9-width = `15`.
    temp9-depth = `6`.
    temp9-height = `0.2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1067`.
    temp9-name = `Ergo Mousepad`.
    temp9-suppliername = `Oxynum`.
    temp9-width = `15`.
    temp9-depth = `6`.
    temp9-height = `0.2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1068`.
    temp9-name = `Designer Mousepad`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `24`.
    temp9-depth = `24`.
    temp9-height = `0.6`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1069`.
    temp9-name = `Universal card reader`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `6`.
    temp9-depth = `6`.
    temp9-height = `3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1070`.
    temp9-name = `Proctra X`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `22`.
    temp9-depth = `35`.
    temp9-height = `17`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1071`.
    temp9-name = `Gladiator MX`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `22`.
    temp9-depth = `35`.
    temp9-height = `17`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1072`.
    temp9-name = `Hurricane GX`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `22`.
    temp9-depth = `35`.
    temp9-height = `17`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1073`.
    temp9-name = `Hurricane GX/LN`.
    temp9-suppliername = `Smartcards`.
    temp9-width = `22`.
    temp9-depth = `35`.
    temp9-height = `17`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1080`.
    temp9-name = `Photo Scan`.
    temp9-suppliername = `Printer for All`.
    temp9-width = `34`.
    temp9-depth = `48`.
    temp9-height = `5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1081`.
    temp9-name = `Power Scan`.
    temp9-suppliername = `Printer for All`.
    temp9-width = `31`.
    temp9-depth = `43`.
    temp9-height = `7`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1082`.
    temp9-name = `Jet Scan Professional`.
    temp9-suppliername = `Printer for All`.
    temp9-width = `33`.
    temp9-depth = `41`.
    temp9-height = `12`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1083`.
    temp9-name = `Jet Scan Professional`.
    temp9-suppliername = `Printer for All`.
    temp9-width = `35`.
    temp9-depth = `40`.
    temp9-height = `10`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1085`.
    temp9-name = `Copymaster`.
    temp9-suppliername = `Alpha Printers`.
    temp9-width = `45`.
    temp9-depth = `42`.
    temp9-height = `22`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1090`.
    temp9-name = `Surround Sound`.
    temp9-suppliername = `Speaker Experts`.
    temp9-width = `12`.
    temp9-depth = `10`.
    temp9-height = `16`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1091`.
    temp9-name = `Blaster Extreme`.
    temp9-suppliername = `Speaker Experts`.
    temp9-width = `13`.
    temp9-depth = `11`.
    temp9-height = `17.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1092`.
    temp9-name = `Sound Booster`.
    temp9-suppliername = `Speaker Experts`.
    temp9-width = `12.4`.
    temp9-depth = `10.4`.
    temp9-height = `18.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1095`.
    temp9-name = `Lovely Sound 5.1 Wireless`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `24`.
    temp9-depth = `19`.
    temp9-height = `23`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1096`.
    temp9-name = `Lovely Sound 5.1`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `25`.
    temp9-depth = `17`.
    temp9-height = `19`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1097`.
    temp9-name = `Lovely Sound Stereo`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `21.3`.
    temp9-depth = `2.4`.
    temp9-height = `19.7`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1100`.
    temp9-name = `Smart Office`.
    temp9-suppliername = `Technocom`.
    temp9-width = `15`.
    temp9-depth = `6.5`.
    temp9-height = `2.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1101`.
    temp9-name = `Smart Design`.
    temp9-suppliername = `Technocom`.
    temp9-width = `14`.
    temp9-depth = `6.7`.
    temp9-height = `24`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1102`.
    temp9-name = `Smart Network`.
    temp9-suppliername = `Technocom`.
    temp9-width = `16`.
    temp9-depth = `6`.
    temp9-height = `27`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1103`.
    temp9-name = `Smart Multimedia`.
    temp9-suppliername = `Technocom`.
    temp9-width = `11`.
    temp9-depth = `3.4`.
    temp9-height = `22`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1104`.
    temp9-name = `Smart Games`.
    temp9-suppliername = `Technocom`.
    temp9-width = `10`.
    temp9-depth = `3`.
    temp9-height = `30`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1105`.
    temp9-name = `Smart Internet Antivirus`.
    temp9-suppliername = `Brainsoft`.
    temp9-width = `16`.
    temp9-depth = `4`.
    temp9-height = `21`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1106`.
    temp9-name = `Smart Firewall`.
    temp9-suppliername = `Brainsoft`.
    temp9-width = `17.9`.
    temp9-depth = `4.2`.
    temp9-height = `23.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1107`.
    temp9-name = `Smart Money`.
    temp9-suppliername = `Brainsoft`.
    temp9-width = `12`.
    temp9-depth = `1.5`.
    temp9-height = `19`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1110`.
    temp9-name = `PC Lock`.
    temp9-suppliername = `Red Point Stores`.
    temp9-width = `20`.
    temp9-depth = `8`.
    temp9-height = `4.3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1111`.
    temp9-name = `Notebook Lock`.
    temp9-suppliername = `Red Point Stores`.
    temp9-width = `31`.
    temp9-depth = `9`.
    temp9-height = `7`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1112`.
    temp9-name = `Web cam reality`.
    temp9-suppliername = `Red Point Stores`.
    temp9-width = `9`.
    temp9-depth = `8.2`.
    temp9-height = `1.3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1113`.
    temp9-name = `Screen clean`.
    temp9-suppliername = `Red Point Stores`.
    temp9-width = `2`.
    temp9-depth = `2`.
    temp9-height = `0.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1114`.
    temp9-name = `Fabric bag professional`.
    temp9-suppliername = `Red Point Stores`.
    temp9-width = `42`.
    temp9-depth = `32`.
    temp9-height = `7`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1115`.
    temp9-name = `Wireless DSL Router`.
    temp9-suppliername = `Red Point Stores`.
    temp9-width = `19.3`.
    temp9-depth = `18`.
    temp9-height = `5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1116`.
    temp9-name = `Wireless DSL Router / Repeater`.
    temp9-suppliername = `Red Point Stores`.
    temp9-width = `19.3`.
    temp9-depth = `18`.
    temp9-height = `5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1117`.
    temp9-name = `Wireless DSL Router / Repeater and Print Server`.
    temp9-suppliername = `Technocom`.
    temp9-width = `19.3`.
    temp9-depth = `18`.
    temp9-height = `5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1118`.
    temp9-name = `USB Stick`.
    temp9-suppliername = `Technocom`.
    temp9-width = `1.5`.
    temp9-depth = `8.7`.
    temp9-height = `1.2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1119`.
    temp9-name = `Travel Adapter`.
    temp9-suppliername = `Titanium`.
    temp9-width = `2`.
    temp9-depth = `3.1`.
    temp9-height = `3.9`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1120`.
    temp9-name = `Cordless Bluetooth Keyboard, english international`.
    temp9-suppliername = `Technocom`.
    temp9-width = `51.4`.
    temp9-depth = `23`.
    temp9-height = `4`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1137`.
    temp9-name = `Flat XXL`.
    temp9-suppliername = `Technocom`.
    temp9-width = `54`.
    temp9-depth = `22`.
    temp9-height = `38`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1138`.
    temp9-name = `Pocket Mouse`.
    temp9-suppliername = `Technocom`.
    temp9-width = `0.3`.
    temp9-depth = `0.5`.
    temp9-height = `1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1210`.
    temp9-name = `PC Power Station`.
    temp9-suppliername = `Technocom`.
    temp9-width = `28`.
    temp9-depth = `31`.
    temp9-height = `43`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1251`.
    temp9-name = `Astro Laptop 1516`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `30`.
    temp9-depth = `18`.
    temp9-height = `3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1252`.
    temp9-name = `Astro Phone 6`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `8`.
    temp9-depth = `6`.
    temp9-height = `1.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1253`.
    temp9-name = `Benda Laptop 1408`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `30`.
    temp9-depth = `18`.
    temp9-height = `3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1254`.
    temp9-name = `Bending Screen 21HD`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `37`.
    temp9-depth = `12`.
    temp9-height = `36`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1255`.
    temp9-name = `Broad Screen 22HD`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `39`.
    temp9-depth = `12`.
    temp9-height = `38`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1256`.
    temp9-name = `Cerdik Phone 7`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `9`.
    temp9-depth = `15`.
    temp9-height = `1.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1257`.
    temp9-name = `Cepat Tablet 10.5`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1258`.
    temp9-name = `Cepat Tablet 8`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `38`.
    temp9-depth = `21`.
    temp9-height = `3.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1500`.
    temp9-name = `Server Basic`.
    temp9-suppliername = `Technocom`.
    temp9-width = `34`.
    temp9-depth = `35`.
    temp9-height = `23`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1501`.
    temp9-name = `Server Professional`.
    temp9-suppliername = `Technocom`.
    temp9-width = `29`.
    temp9-depth = `30`.
    temp9-height = `27`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1502`.
    temp9-name = `Server Power Pro`.
    temp9-suppliername = `Technocom`.
    temp9-width = `22`.
    temp9-depth = `27.3`.
    temp9-height = `37`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1600`.
    temp9-name = `Family PC Basic`.
    temp9-suppliername = `Titanium`.
    temp9-width = `21.4`.
    temp9-depth = `29`.
    temp9-height = `38`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1601`.
    temp9-name = `Family PC Pro`.
    temp9-suppliername = `Titanium`.
    temp9-width = `25`.
    temp9-depth = `31.7`.
    temp9-height = `40.2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1602`.
    temp9-name = `Gaming Monster`.
    temp9-suppliername = `Titanium`.
    temp9-width = `26.5`.
    temp9-depth = `34`.
    temp9-height = `47`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-1603`.
    temp9-name = `Gaming Monster Pro`.
    temp9-suppliername = `Titanium`.
    temp9-width = `27`.
    temp9-depth = `28`.
    temp9-height = `42`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-2000`.
    temp9-name = `7" Widescreen Portable DVD Player w MP3`.
    temp9-suppliername = `Titanium`.
    temp9-width = `21.4`.
    temp9-depth = `19`.
    temp9-height = `27.6`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-2001`.
    temp9-name = `10" Portable DVD player`.
    temp9-suppliername = `Titanium`.
    temp9-width = `24`.
    temp9-depth = `19.5`.
    temp9-height = `29`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-2002`.
    temp9-name = `Portable DVD Player with 9" LCD Monitor`.
    temp9-suppliername = `Technocom`.
    temp9-width = `21`.
    temp9-depth = `16.5`.
    temp9-height = `14`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-2025`.
    temp9-name = `CD/DVD case: 264 sleeves`.
    temp9-suppliername = `Titanium`.
    temp9-width = `13`.
    temp9-depth = `13`.
    temp9-height = `20`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-2026`.
    temp9-name = `Audio/Video Cable Kit - 4m`.
    temp9-suppliername = `Titanium`.
    temp9-width = `21`.
    temp9-depth = `10.2`.
    temp9-height = `13`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-2027`.
    temp9-name = `Removable CD/DVD Laser Labels`.
    temp9-suppliername = `Titanium`.
    temp9-width = `5.5`.
    temp9-depth = `2`.
    temp9-height = `2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6100`.
    temp9-name = `Beam Breaker B-1`.
    temp9-suppliername = `Titanium`.
    temp9-width = `30.4`.
    temp9-depth = `23.1`.
    temp9-height = `23`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6101`.
    temp9-name = `Beam Breaker B-2`.
    temp9-suppliername = `Technocom`.
    temp9-width = `30.4`.
    temp9-depth = `23.1`.
    temp9-height = `23`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6102`.
    temp9-name = `Beam Breaker B-3`.
    temp9-suppliername = `Technocom`.
    temp9-width = `30.4`.
    temp9-depth = `23.1`.
    temp9-height = `23`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6110`.
    temp9-name = `Play Movie`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `37`.
    temp9-depth = `24`.
    temp9-height = `6`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6111`.
    temp9-name = `Record Movie`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `38`.
    temp9-depth = `26`.
    temp9-height = `6.2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6120`.
    temp9-name = `ITelo MusicStick`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `1.5`.
    temp9-depth = `6`.
    temp9-height = `1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6121`.
    temp9-name = `ITelo Jog-Mate`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `5.1`.
    temp9-depth = `8`.
    temp9-height = `9.2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6122`.
    temp9-name = `Power Pro Player 40`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `5.1`.
    temp9-depth = `8`.
    temp9-height = `9.2`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6123`.
    temp9-name = `Power Pro Player 80`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `4`.
    temp9-depth = `6`.
    temp9-height = `0.8`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6130`.
    temp9-name = `Flat Watch HD32`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `78`.
    temp9-depth = `22.1`.
    temp9-height = `55`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6131`.
    temp9-name = `Flat Watch HD37`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `99.1`.
    temp9-depth = `26`.
    temp9-height = `61`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-6132`.
    temp9-name = `Flat Watch HD41`.
    temp9-suppliername = `Very Best Screens`.
    temp9-width = `128`.
    temp9-depth = `23`.
    temp9-height = `79.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-7000`.
    temp9-name = `Copperberry`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `8.1`.
    temp9-depth = `13`.
    temp9-height = `12.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-7010`.
    temp9-name = `Silverberry`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `8.1`.
    temp9-depth = `13`.
    temp9-height = `12.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-7020`.
    temp9-name = `Goldberry`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `8.1`.
    temp9-depth = `13`.
    temp9-height = `12.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-7030`.
    temp9-name = `Platinberry`.
    temp9-suppliername = `Fasttech`.
    temp9-width = `8.1`.
    temp9-depth = `13`.
    temp9-height = `12.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-8000`.
    temp9-name = `ITelO FlexTop I4000`.
    temp9-suppliername = `Titanium`.
    temp9-width = `31`.
    temp9-depth = `19`.
    temp9-height = `3.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-8001`.
    temp9-name = `ITelO FlexTop I6300c`.
    temp9-suppliername = `Titanium`.
    temp9-width = `32`.
    temp9-depth = `20`.
    temp9-height = `3.4`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-8002`.
    temp9-name = `ITelO FlexTop I9100`.
    temp9-suppliername = `Titanium`.
    temp9-width = `38`.
    temp9-depth = `21`.
    temp9-height = `4.1`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-8003`.
    temp9-name = `ITelO FlexTop I9800`.
    temp9-suppliername = `Titanium`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9991`.
    temp9-name = `Smartphone Leather Case`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9992`.
    temp9-name = `Smartphone Alpha`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9993`.
    temp9-name = `Mini Tablet`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9994`.
    temp9-name = `Camcorder View`.
    temp9-suppliername = `Ultrasonic United`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `27`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9995`.
    temp9-name = `Tablet Pouch`.
    temp9-suppliername = `Titanium`.
    temp9-width = `25`.
    temp9-depth = `40`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9996`.
    temp9-name = `Tablet Pouch`.
    temp9-suppliername = `Titanium`.
    temp9-width = `25`.
    temp9-depth = `40`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9997`.
    temp9-name = `e-Book Reader ReadMe`.
    temp9-suppliername = `Titanium`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9998`.
    temp9-name = `Smartphone Beta`.
    temp9-suppliername = `Titanium`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `HT-9999`.
    temp9-name = `Maxi Tablet`.
    temp9-suppliername = `Titanium`.
    temp9-width = `48`.
    temp9-depth = `31`.
    temp9-height = `4.5`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    temp9-productid = `PF-1000`.
    temp9-name = `Flyer`.
    temp9-suppliername = `Titanium`.
    temp9-width = `46`.
    temp9-depth = `30`.
    temp9-height = `3`.
    temp9-dimunit = `cm`.
    INSERT temp9 INTO TABLE temp8.
    t_products = temp8.

  ENDMETHOD.

ENDCLASS.
