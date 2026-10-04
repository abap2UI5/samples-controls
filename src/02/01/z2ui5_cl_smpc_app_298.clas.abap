" @keywords table sap.m tableviewsettingsdialog menu quicksort quicksortitem quickresize actionitem viewsettingsdialog viewsettingsitem viewsettingsfilteritem overflowtoolbar
" @summary The View Settings Dialog is standard UI pattern for specifying sorting, grouping and filtering. For a table it should be triggered by a button in the table header with the 'drop-down-list' icon.
" @origin sap.m.sample.TableViewSettingsDialog - https://sdk.openui5.org/entity/sap.m.Table/sample/sap.m.sample.TableViewSettingsDialog (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_298 DEFINITION PUBLIC.

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
        width         TYPE string,
        depth         TYPE string,
        height        TYPE string,
        dimunit       TYPE string,
      END OF ty_s_product.
    TYPES temp1_6fa4fe2962 TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_products TYPE temp1_6fa4fe2962.

    DATA filter_bar_visible TYPE abap_bool.
    DATA filter_label TYPE string.

    " onResize writes the Product column's width. A bound CSSSize carries it:
    " an empty value is valid there (the type's 0* branch matches it), so the
    " column keeps its automatic width until the user drags once.
    DATA product_width TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    TYPES temp2_6fa4fe2962 TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_all TYPE temp2_6fa4fe2962.
    " the filtered set in MODEL ORDER, i.e. before any sort. Restoring it is
    " what oBinding.sort( ) with no argument does in the original, and both the
    " QuickSort None entry and the group dialog's Reset need exactly that.
    TYPES temp3_6fa4fe2962 TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_filtered TYPE temp3_6fa4fe2962.
    DATA group_key TYPE string.
    DATA context_menu_on TYPE abap_bool.

    TYPES:
      BEGIN OF ty_s_event_item,
        id       TYPE string,
        key      TYPE string,
        text     TYPE string,
        selected TYPE abap_bool,
      END OF ty_s_event_item.
    TYPES ty_t_event_item TYPE STANDARD TABLE OF ty_s_event_item WITH DEFAULT KEY.

    METHODS view_display.
    METHODS on_event.
    METHODS on_event_filter_confirm.
    METHODS weight_state_set.
    METHODS table_sort
      IMPORTING
        field      TYPE string
        descending TYPE abap_bool.
    METHODS abap_field
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS event_items
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_event_item.
    METHODS json_objects
      IMPORTING
        json          TYPE string
      RETURNING
        VALUE(result) TYPE string_table.
    METHODS json_get_value
      IMPORTING
        json          TYPE string
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS json_get_bool
      IMPORTING
        json          TYPE string
        name          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_298 IMPLEMENTATION.

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
    INSERT `${$parameters>/item}.getKey()` INTO TABLE temp1.
    INSERT `${$parameters>/item}.getSortOrder()` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$parameters>/sortItem}` INTO TABLE temp2.
    INSERT `${$parameters>/sortDescending}` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `${$parameters>/filterItems}` INTO TABLE temp3.
    INSERT `${$parameters>/filterString}` INTO TABLE temp3.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:tcm`  v = `sap.m.table.columnmenu`
        )->a( n = `height`     v = `100%`

        " the four controller-loaded fragments (ColumnMenu, Sort, Group,
        " Filter), declared in the view's dependents aggregation
        )->ele( n = `dependents` ns = `mvc`

            )->ele( n = `Menu` ns = `tcm`
                )->a( n = `id` v = `columnHeaderMenu`

                )->ele( n = `QuickSort` ns = `tcm`
                    " QuickSort.change DECLARES key and sortOrder in its event
                    " metadata and fires neither: onChange does
                    " fireChange({ item: oItem }) and nothing else. Reading the
                    " declared names therefore delivered two empty strings on
                    " every firing, and the handler's fallback sorted Name
                    " ascending whatever was clicked. The original reads the
                    " same `item` the control really passes, so the port asks
                    " the item for its key and order - an event arg is a full
                    " UI5 expression, so the two getters resolve in the client.
                    )->a( n = `change` v = client->_event( val   = `MENU_SORT`
                                                           t_arg = temp1 )

                    )->ele( n = `items` ns = `tcm`
                        )->tag( n = `QuickSortItem` ns = `tcm`
                            )->a( n = `key`   v = `Name`
                            )->a( n = `label` v = `Product`

                    )->end(
                )->end(
                )->ele( n = `QuickResize` ns = `tcm`
                    )->a( n = `id`     v = `quickResize`
                    )->a( n = `change` v = client->_event( val = `MENU_RESIZE` arg = `${$parameters>/width}` )

                )->end(
                )->ele( n = `items` ns = `tcm`
                    )->tag( n = `ActionItem` ns = `tcm`
                        )->a( n = `label` v = `Action Item`
                        )->a( n = `press` v = client->_event( `MENU_ACTION` )

                )->end(
            )->end(

            )->ele( `ViewSettingsDialog`
                )->a( n = `id`      v = `sortDialog`
                )->a( n = `confirm` v = client->_event( val   = `SORT_CONFIRM`
                                                        t_arg = temp2 )

                )->ele( `sortItems`
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text`     v = `Product`
                        )->a( n = `key`      v = `Name`
                        )->a( n = `selected` v = `true`
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text` v = `Supplier`
                        )->a( n = `key`  v = `SupplierName`
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text` v = `Weight`
                        )->a( n = `key`  v = `WeightMeasure`
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text` v = `Price`
                        )->a( n = `key`  v = `Price`

                )->end(
            )->end(

            )->ele( `ViewSettingsDialog`
                )->a( n = `id`      v = `groupDialog`
                )->a( n = `confirm` v = client->_event( val = `GROUP_CONFIRM` arg = `${$parameters>/groupItem}` )
                )->a( n = `reset`   v = client->_event( `GROUP_RESET` )

                )->ele( `groupItems`
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text` v = `Supplier`
                        )->a( n = `key`  v = `SupplierName`
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text` v = `Price`
                        )->a( n = `key`  v = `Price`

                )->end(
            )->end(

            )->ele( `ViewSettingsDialog`
                )->a( n = `id`      v = `filterDialog`
                )->a( n = `confirm` v = client->_event( val   = `FILTER_CONFIRM`
                                                        t_arg = temp3 )

                )->ele( `filterItems`
                    )->ele( `ViewSettingsFilterItem`
                        )->a( n = `text`        v = `Weight`
                        )->a( n = `key`         v = `WeightMeasure`
                        )->a( n = `multiSelect` v = `false`

                        )->ele( `items`
                            )->tag( `ViewSettingsItem`
                                )->a( n = `text` v = `Less than 1000`
                                )->a( n = `key`  v = `WeightMeasure___LE___1000___X`
                            )->tag( `ViewSettingsItem`
                                )->a( n = `text` v = `Between 1000 and 2000`
                                )->a( n = `key`  v = `WeightMeasure___BT___1000___2000`
                            )->tag( `ViewSettingsItem`
                                )->a( n = `text` v = `More Than 2000`
                                )->a( n = `key`  v = `WeightMeasure___GT___2000___X`

                        )->end(
                    )->end(
                    )->ele( `ViewSettingsFilterItem`
                        )->a( n = `text`        v = `Price`
                        )->a( n = `key`         v = `Price`
                        )->a( n = `multiSelect` v = `false`

                        )->ele( `items`
                            )->tag( `ViewSettingsItem`
                                )->a( n = `text` v = `Less Than 100`
                                )->a( n = `key`  v = `Price___LE___100___X`
                            )->tag( `ViewSettingsItem`
                                )->a( n = `text` v = `Between 100 and 1000`
                                )->a( n = `key`  v = `Price___BT___100___1000`
                            )->tag( `ViewSettingsItem`
                                )->a( n = `text` v = `More Than 1000`
                                )->a( n = `key`  v = `Price___GT___1000___X`

                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( `Table`
                )->a( n = `id`    v = `idProductsTable`
                )->a( n = `items` v = client->_bind( t_products )

                )->ele( `headerToolbar`
                    )->ele( `OverflowToolbar`
                        )->tag( `Title`
                            )->a( n = `text`  v = `Products`
                            )->a( n = `level` v = `H2`
                        )->tag( `ToolbarSpacer`
                        )->tag( `Button`
                            )->a( n = `tooltip` v = `Sort`
                            )->a( n = `icon`    v = `sap-icon://sort`
                            )->a( n = `press`   v = client->_event( `OPEN_SORT` )
                        )->tag( `Button`
                            )->a( n = `tooltip` v = `Filter`
                            )->a( n = `icon`    v = `sap-icon://filter`
                            )->a( n = `press`   v = client->_event( `OPEN_FILTER` )
                        )->tag( `Button`
                            )->a( n = `tooltip` v = `Group`
                            )->a( n = `icon`    v = `sap-icon://group-2`
                            )->a( n = `press`   v = client->_event( `OPEN_GROUP` )
                        )->tag( `ToggleButton`
                            )->a( n = `icon`    v = `sap-icon://menu`
                            )->a( n = `tooltip` v = `Enable Custom Context Menu`
                            )->a( n = `press`   v = client->_event( `TOGGLE_CONTEXT_MENU` )

                    )->end(
                )->end(
                )->ele( `infoToolbar`
                    )->ele( `OverflowToolbar`
                        )->a( n = `id`      v = `vsdFilterBar`
                        )->a( n = `visible` v = client->_bind( filter_bar_visible )

                        )->tag( `Text`
                            )->a( n = `id`   v = `vsdFilterLabel`
                            )->a( n = `text` v = client->_bind( filter_label )

                    )->end(
                )->end(
                )->ele( `columns`
                    )->ele( `Column`
                        )->a( n = `id`         v = `product`
                        )->a( n = `headerMenu` v = `columnHeaderMenu`
                        " onResize's oColumn.setWidth( iWidth + 'px' ) - a
                        " bindable property, so the width travels back through
                        " the model instead of a setter
                        )->a( n = `width`      v = client->_bind( product_width )

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
                    )->ele( `Column`
                        )->a( n = `minScreenWidth` v = `Tablet`
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
                                )->a( n = `number` v = |\{ parts:[\{path:'PRICE'\},\{path:'CURRENCYCODE'\}], type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: false\} \}|
                                )->a( n = `unit`   v = `{CURRENCYCODE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string_table.
        DATA temp5 TYPE string_table.
        DATA temp7 TYPE string_table.
        DATA t_item TYPE z2ui5_cl_smpc_app_298=>ty_t_event_item.
          FIELD-SYMBOLS <temp9> LIKE LINE OF t_item.
          DATA temp10 LIKE sy-tabix.
          DATA temp1 TYPE xsdboolean.
          DATA temp2 TYPE xsdboolean.
        DATA temp11 TYPE string.
          FIELD-SYMBOLS <temp4> LIKE LINE OF t_item.
          DATA temp6 LIKE sy-tabix.
        DATA temp4 TYPE xsdboolean.
        DATA temp12 TYPE string.

    CASE client->get_event( ).

      WHEN `OPEN_SORT`.
        
        CLEAR temp3.
        INSERT `sortDialog` INTO TABLE temp3.
        INSERT `open` INTO TABLE temp3.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp3 ).

      WHEN `OPEN_FILTER`.
        
        CLEAR temp5.
        INSERT `filterDialog` INTO TABLE temp5.
        INSERT `open` INTO TABLE temp5.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp5 ).

      WHEN `OPEN_GROUP`.
        
        CLEAR temp7.
        INSERT `groupDialog` INTO TABLE temp7.
        INSERT `open` INTO TABLE temp7.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp7 ).

      WHEN `SORT_CONFIRM`.
        
        t_item = event_items( client->get_event_arg( ) ).
        IF t_item IS NOT INITIAL.
          
          
          temp10 = sy-tabix.
          READ TABLE t_item INDEX 1 ASSIGNING <temp9>.
          sy-tabix = temp10.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          temp1 = boolc( client->get_event_arg( 2 ) = abap_true ).
          table_sort( field      = abap_field( <temp9>-key )
                      descending = temp1 ).
        ENDIF.

      WHEN `MENU_SORT`.
        " onSortChange: sortOrder None clears the sorter (oBinding.sort( ) with
        " no argument), which restores MODEL order rather than sorting by
        " anything - the branch the port used to fall through
        IF client->get_event_arg( 2 ) = `None`.
          t_products = t_filtered.
        ELSE.
          
          temp2 = boolc( client->get_event_arg( 2 ) = `Descending` ).
          table_sort( field      = abap_field( client->get_event_arg( ) )
                      descending = temp2 ).
        ENDIF.

      WHEN `GROUP_CONFIRM`.
        t_item = event_items( client->get_event_arg( ) ).
        
        IF t_item IS INITIAL.
          temp11 = ``.
        ELSE.
          
          
          temp6 = sy-tabix.
          READ TABLE t_item INDEX 1 ASSIGNING <temp4>.
          sy-tabix = temp6.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          temp11 = <temp4>-key.
        ENDIF.
        group_key = temp11.
        CASE group_key.

          WHEN `SupplierName`.
            SORT t_products BY suppliername ASCENDING.

          WHEN `Price`.
            SORT t_products BY price ASCENDING.

        ENDCASE.

      WHEN `GROUP_RESET`.
        " resetGroupDialog sets this.groupReset, and the confirm handler then
        " calls oBinding.sort( ) - so Reset really puts the rows back in model
        " order. Clearing group_key alone changed nothing observable: it is
        " read only inside GROUP_CONFIRM, which reassigns it first.
        group_key  = ``.
        t_products = t_filtered.

      WHEN `FILTER_CONFIRM`.
        on_event_filter_confirm( ).

      WHEN `TOGGLE_CONTEXT_MENU`.
        
        temp4 = boolc( context_menu_on = abap_false ).
        context_menu_on = temp4.
        
        IF context_menu_on = abap_true.
          temp12 = `Custom context menu enabled`.
        ELSE.
          temp12 = `Custom context menu disabled`.
        ENDIF.
        client->message_toast_display( temp12 ).

      WHEN `MENU_ACTION`.
        client->message_toast_display( `Action Item Pressed` ).

      WHEN `MENU_RESIZE`.
        " onResize: oColumn.setWidth( oEvent.getParameter('width') + 'px' ).
        " The width now travels as an event arg and lands on the bound
        " property; the toast this used to show instead was not in the original
        " at all, and the comment beside it claimed onResize only logs.
        product_width = |{ client->get_event_arg( ) }px|.

    ENDCASE.

  ENDMETHOD.


  METHOD on_event_filter_confirm.

    DATA t_keep LIKE t_products.

    " the item key encodes the whole condition: <field>___<operator>___<v1>___<v2>
    DATA t_item TYPE z2ui5_cl_smpc_app_298=>ty_t_event_item.
    DATA temp5 TYPE xsdboolean.
    DATA s_item LIKE LINE OF t_item.
      DATA field TYPE string.
      DATA operator TYPE string.
      DATA value1 TYPE string.
      DATA value2 TYPE string.
      DATA temp13 TYPE decfloat34.
      DATA low LIKE temp13.
      DATA temp14 TYPE decfloat34.
      DATA temp7 TYPE string.
      DATA high LIKE temp14.
      DATA temp15 LIKE t_keep.
      DATA s_row LIKE LINE OF t_products.
        DATA temp16 TYPE decfloat34.
        DATA compare LIKE temp16.
        DATA temp17 TYPE abap_bool.
            DATA temp6 TYPE xsdboolean.
            DATA temp8 TYPE xsdboolean.
            DATA temp9 TYPE xsdboolean.
        DATA keep LIKE temp17.
    t_item = event_items( client->get_event_arg( ) ).

    t_products = t_all.
    filter_label       = client->get_event_arg( 2 ).
    
    temp5 = boolc( filter_label IS NOT INITIAL ).
    filter_bar_visible = temp5.

    
    LOOP AT t_item INTO s_item.
      
      
      
      
      SPLIT s_item-key AT `___` INTO field operator value1 value2.

      
      temp13 = value1.
      
      low = temp13.
      
      
      IF value2 = `X`.
        temp7 = `0`.
      ELSE.
        temp7 = value2.
      ENDIF.
      temp14 = temp7.
      
      high = temp14.

      " Collected rather than deleted in place: DELETE ... INDEX sy-tabix inside
      " a LOOP over the same table shifts the rows under the loop's own cursor -
      " on a system it silently SKIPS the row after each deletion, on the
      " transpiled backend it raises TABLE_INVALID_INDEX (2026-08-17).
      
      CLEAR temp15.
      t_keep = temp15.
      
      LOOP AT t_products INTO s_row.
        
        IF field = `WeightMeasure`.
          temp16 = s_row-weightmeasure.
        ELSE.
          temp16 = s_row-price.
        ENDIF.
        
        compare = temp16.
        
        CASE operator.
          WHEN `LE`.
            
            temp6 = boolc( compare <= low ).
            temp17 = temp6.
          WHEN `GT`.
            
            temp8 = boolc( compare > low ).
            temp17 = temp8.
          WHEN `BT`.
            
            temp9 = boolc( compare >= low AND compare <= high ).
            temp17 = temp9.
          WHEN OTHERS.
            temp17 = abap_true.
        ENDCASE.
        
        keep = temp17.
        IF keep = abap_true.
          APPEND s_row TO t_keep.
        ENDIF.
      ENDLOOP.
      t_products = t_keep.
    ENDLOOP.

    " the filter result in model order - what a cleared sorter goes back to
    t_filtered = t_products.


  ENDMETHOD.


  METHOD weight_state_set.

    " weightState is business logic, not presentation - abap2UI5 is a thin
    " frontend, so it is computed here rather than in a frontend formatter.
    " THIS SAMPLE'S OWN Formatter.js takes ONE argument and compares the RAW
    " measure: < 0 None, < 1000 Success, < 2000 Warning, else Error - and the
    " view binds a single part (WeightMeasure), so the unit never reaches it.
    " The KG rule with the 1/5 boundaries belongs to a DIFFERENT sample
    " (sap.m.Table, app 009, whose formatter takes measure AND unit); it was
    " imported here on 2026-08-21 and made 66 of the 123 rows disagree with the
    " original, every one of which renders Success.
    DATA temp18 LIKE LINE OF t_products.
    DATA row LIKE REF TO temp18.
      DATA temp19 TYPE z2ui5_cl_smpc_app_298=>ty_s_product-weight_state.
    LOOP AT t_products REFERENCE INTO row.
      
      IF row->weightmeasure < 0.
        temp19 = `None`.
      ELSEIF row->weightmeasure < 1000.
        temp19 = `Success`.
      ELSEIF row->weightmeasure < 2000.
        temp19 = `Warning`.
      ELSE.
        temp19 = `Error`.
      ENDIF.
      row->weight_state = temp19.
    ENDLOOP.

  ENDMETHOD.


  METHOD table_sort.

    " the component is named STATICALLY per field rather than through
    " SORT BY (field): the transpiled backend drops the dynamic BY clause
    " altogether (abap.statements.sort(t, {}) - **e2e-caught 2026-08-22** on
    " app 571), so the table came back in its original order
    CASE field.
      WHEN `SUPPLIERNAME`.
        IF descending = abap_true.
          SORT t_products BY suppliername AS TEXT DESCENDING.
        ELSE.
          SORT t_products BY suppliername AS TEXT ASCENDING.
        ENDIF.
      WHEN `WEIGHTMEASURE`.
        IF descending = abap_true.
          SORT t_products BY weightmeasure DESCENDING.
        ELSE.
          SORT t_products BY weightmeasure ASCENDING.
        ENDIF.
      WHEN `PRICE`.
        IF descending = abap_true.
          SORT t_products BY price DESCENDING.
        ELSE.
          SORT t_products BY price ASCENDING.
        ENDIF.
      WHEN OTHERS.
        IF descending = abap_true.
          SORT t_products BY name AS TEXT DESCENDING.
        ELSE.
          SORT t_products BY name AS TEXT ASCENDING.
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD abap_field.

    " the dialog keys are the mock's UI5 field names; the model carries the
    " ABAP component names
    DATA temp20 TYPE string.
    CASE val.
      WHEN `Name`.
        temp20 = `NAME`.
      WHEN `SupplierName`.
        temp20 = `SUPPLIERNAME`.
      WHEN `WeightMeasure`.
        temp20 = `WEIGHTMEASURE`.
      WHEN `Price`.
        temp20 = `PRICE`.
      WHEN OTHERS.
        temp20 = `NAME`.
    ENDCASE.
    result = temp20.

  ENDMETHOD.


  METHOD event_items.

    DATA json TYPE string.
    DATA temp21 TYPE string_table.
    DATA object LIKE LINE OF temp21.
      DATA temp22 TYPE z2ui5_cl_smpc_app_298=>ty_s_event_item.
    json = condense( val ).
    IF json IS INITIAL.
      RETURN.
    ENDIF.

    " The frontend marshals each control into an object of its ID plus ALL
    " its public properties, so this reads the fields the port models and
    " ignores the rest - which is what the corresponding-only mapping used
    " to do. Written by hand: there is no released JSON parser, and the
    " vendored ajson copy is framework-internal.
    
    temp21 = json_objects( json ).
    
    LOOP AT temp21 INTO object.
      
      CLEAR temp22.
      temp22-id = json_get_value( json = object name = `id` ).
      temp22-key = json_get_value( json = object name = `key` ).
      temp22-text = json_get_value( json = object name = `text` ).
      temp22-selected = json_get_bool( json = object name = `selected` ).
      INSERT temp22 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


  METHOD json_objects.

    " Cut the array into its objects. abap2UI5 releases no JSON parser and
    " the vendored ajson copy is framework-internal (the linter's
    " non-released-api rule reports it, correctly), so the split is one
    " character walk - and it is a walk rather than a SPLIT on `},{` because
    " a brace inside a STRING is text, not structure.
    DATA depth TYPE i.
    DATA in_string LIKE abap_false.
    DATA escaped LIKE abap_false.
    DATA start TYPE i.
    DATA pos TYPE i.
    DATA length TYPE i.
      DATA char TYPE string.
        DATA temp10 TYPE xsdboolean.
    depth     = 0.
    
    in_string = abap_false.
    
    escaped = abap_false.
    
    start     = 0.
    
    pos       = 0.
    
    length    = strlen( json ).

    WHILE pos < length.
      
      char = substring( val = json off = pos len = 1 ).

      IF escaped = abap_true.
        escaped = abap_false.
      ELSEIF in_string = abap_true AND char = `\`.
        escaped = abap_true.
      ELSEIF char = `"`.
        
        temp10 = boolc( in_string = abap_false ).
        in_string = temp10.
      ELSEIF in_string = abap_false AND char = `{`.
        IF depth = 0.
          start = pos.
        ENDIF.
        depth = depth + 1.
      ELSEIF in_string = abap_false AND char = `}`.
        depth = depth - 1.
        IF depth = 0.
          INSERT substring( val = json off = start len = pos - start + 1 ) INTO TABLE result.
        ENDIF.
      ENDIF.

      pos = pos + 1.
    ENDWHILE.

  ENDMETHOD.


  METHOD json_get_value.

    " One string field of ONE object: find `"<name>":"` and take what stands
    " up to the next quote. The search is case-insensitive because the key is
    " the UI5 property name (camelCase) and this reads it in lower case.
    " Same reader as Z2UI5_CL_SMP_APP_327 in abap2UI5/samples, and the same
    " limit: it reads what the FRAMEWORK wrote and does not resolve escapes,
    " which a payload composed from free user input would need.
    DATA marker TYPE string.
    DATA offset TYPE i.
    marker = |"{ name }":"|.

    
    offset = find( val = json sub = marker case = abap_false ).
    IF offset < 0.
      RETURN.
    ENDIF.

    result = substring_before( val = substring( val = json
                                                off = offset + strlen( marker ) )
                               sub = `"` ).

  ENDMETHOD.


  METHOD json_get_bool.

    " A JSON boolean carries no quotes, so the marker stops at the colon and
    " what follows is `true` or `false` - the mapping ajson made onto
    " abap_bool, written out.
    DATA marker TYPE string.
    DATA offset TYPE i.
    DATA temp11 TYPE xsdboolean.
    marker = |"{ name }":|.

    
    offset = find( val = json sub = marker case = abap_false ).
    IF offset < 0.
      RETURN.
    ENDIF.

    
    temp11 = boolc( substring( val = json off = offset + strlen( marker ) ) CP `true*` ).
    result = temp11.

  ENDMETHOD.


  METHOD model_init.

    " the shared mock /ProductCollection flattened to the bound columns, all 123 rows kept verbatim
    DATA temp23 LIKE t_products.
    DATA temp24 LIKE LINE OF temp23.
    CLEAR temp23.
    
    temp24-productid = `HT-1000`.
    temp24-name = `Notebook Basic 15`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '4.2'.
    temp24-weightunit = `KG`.
    temp24-price = '956'.
    temp24-currencycode = `EUR`.
    temp24-width = '30'.
    temp24-depth = '18'.
    temp24-height = '3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1001`.
    temp24-name = `Notebook Basic 17`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '4.5'.
    temp24-weightunit = `KG`.
    temp24-price = '1249'.
    temp24-currencycode = `EUR`.
    temp24-width = '29'.
    temp24-depth = '17'.
    temp24-height = '3.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1002`.
    temp24-name = `Notebook Basic 18`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '4.2'.
    temp24-weightunit = `KG`.
    temp24-price = '1570'.
    temp24-currencycode = `EUR`.
    temp24-width = '28'.
    temp24-depth = '19'.
    temp24-height = '2.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1003`.
    temp24-name = `Notebook Basic 19`.
    temp24-suppliername = `Smartcards`.
    temp24-weightmeasure = '4.2'.
    temp24-weightunit = `KG`.
    temp24-price = '1650'.
    temp24-currencycode = `EUR`.
    temp24-width = '32'.
    temp24-depth = '21'.
    temp24-height = '4'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1007`.
    temp24-name = `ITelO Vault`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.2'.
    temp24-weightunit = `KG`.
    temp24-price = '299'.
    temp24-currencycode = `EUR`.
    temp24-width = '32'.
    temp24-depth = '22'.
    temp24-height = '3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1010`.
    temp24-name = `Notebook Professional 15`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '4.3'.
    temp24-weightunit = `KG`.
    temp24-price = '1999'.
    temp24-currencycode = `EUR`.
    temp24-width = '33'.
    temp24-depth = '20'.
    temp24-height = '3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1011`.
    temp24-name = `Notebook Professional 17`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '4.1'.
    temp24-weightunit = `KG`.
    temp24-price = '2299'.
    temp24-currencycode = `EUR`.
    temp24-width = '33'.
    temp24-depth = '23'.
    temp24-height = '2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1020`.
    temp24-name = `ITelO Vault Net`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.16'.
    temp24-weightunit = `KG`.
    temp24-price = '459'.
    temp24-currencycode = `EUR`.
    temp24-width = '10'.
    temp24-depth = '1.8'.
    temp24-height = '17'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1021`.
    temp24-name = `ITelO Vault SAT`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.18'.
    temp24-weightunit = `KG`.
    temp24-price = '149'.
    temp24-currencycode = `EUR`.
    temp24-width = '11'.
    temp24-depth = '1.7'.
    temp24-height = '18'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1022`.
    temp24-name = `Comfort Easy`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.2'.
    temp24-weightunit = `KG`.
    temp24-price = '1679'.
    temp24-currencycode = `EUR`.
    temp24-width = '84'.
    temp24-depth = '1.5'.
    temp24-height = '14'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1023`.
    temp24-name = `Comfort Senior`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.8'.
    temp24-weightunit = `KG`.
    temp24-price = '512'.
    temp24-currencycode = `EUR`.
    temp24-width = '80'.
    temp24-depth = '1.6'.
    temp24-height = '13'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1030`.
    temp24-name = `Ergo Screen E-I`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '21'.
    temp24-weightunit = `KG`.
    temp24-price = '230'.
    temp24-currencycode = `EUR`.
    temp24-width = '37'.
    temp24-depth = '12'.
    temp24-height = '36'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1031`.
    temp24-name = `Ergo Screen E-II`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '21'.
    temp24-weightunit = `KG`.
    temp24-price = '285'.
    temp24-currencycode = `EUR`.
    temp24-width = '40.8'.
    temp24-depth = '19'.
    temp24-height = '43'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1032`.
    temp24-name = `Ergo Screen E-III`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '21'.
    temp24-weightunit = `KG`.
    temp24-price = '345'.
    temp24-currencycode = `EUR`.
    temp24-width = '40.8'.
    temp24-depth = '19'.
    temp24-height = '43'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1035`.
    temp24-name = `Flat Basic`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '14'.
    temp24-weightunit = `KG`.
    temp24-price = '399'.
    temp24-currencycode = `EUR`.
    temp24-width = '39'.
    temp24-depth = '20'.
    temp24-height = '41'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1036`.
    temp24-name = `Flat Future`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '15'.
    temp24-weightunit = `KG`.
    temp24-price = '430'.
    temp24-currencycode = `EUR`.
    temp24-width = '45'.
    temp24-depth = '26'.
    temp24-height = '46'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1037`.
    temp24-name = `Flat XL`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '17'.
    temp24-weightunit = `KG`.
    temp24-price = '1230'.
    temp24-currencycode = `EUR`.
    temp24-width = '54.5'.
    temp24-depth = '22.1'.
    temp24-height = '39.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1040`.
    temp24-name = `Laser Professional Eco`.
    temp24-suppliername = `Alpha Printers`.
    temp24-weightmeasure = '32'.
    temp24-weightunit = `KG`.
    temp24-price = '830'.
    temp24-currencycode = `EUR`.
    temp24-width = '51'.
    temp24-depth = '46'.
    temp24-height = '30'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1041`.
    temp24-name = `Laser Basic`.
    temp24-suppliername = `Alpha Printers`.
    temp24-weightmeasure = '23'.
    temp24-weightunit = `KG`.
    temp24-price = '490'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '42'.
    temp24-height = '26'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1042`.
    temp24-name = `Laser Allround`.
    temp24-suppliername = `Alpha Printers`.
    temp24-weightmeasure = '17'.
    temp24-weightunit = `KG`.
    temp24-price = '349'.
    temp24-currencycode = `EUR`.
    temp24-width = '53'.
    temp24-depth = '50'.
    temp24-height = '65'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1050`.
    temp24-name = `Ultra Jet Super Color`.
    temp24-suppliername = `Alpha Printers`.
    temp24-weightmeasure = '3'.
    temp24-weightunit = `KG`.
    temp24-price = '139'.
    temp24-currencycode = `EUR`.
    temp24-width = '41'.
    temp24-depth = '41'.
    temp24-height = '28'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1051`.
    temp24-name = `Ultra Jet Mobile`.
    temp24-suppliername = `Printer for All`.
    temp24-weightmeasure = '1.9'.
    temp24-weightunit = `KG`.
    temp24-price = '99'.
    temp24-currencycode = `EUR`.
    temp24-width = '46'.
    temp24-depth = '32'.
    temp24-height = '25'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1052`.
    temp24-name = `Ultra Jet Super Highspeed`.
    temp24-suppliername = `Printer for All`.
    temp24-weightmeasure = '18'.
    temp24-weightunit = `KG`.
    temp24-price = '170'.
    temp24-currencycode = `EUR`.
    temp24-width = '41'.
    temp24-depth = '41'.
    temp24-height = '28'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1055`.
    temp24-name = `Multi Print`.
    temp24-suppliername = `Printer for All`.
    temp24-weightmeasure = '6.3'.
    temp24-weightunit = `KG`.
    temp24-price = '99'.
    temp24-currencycode = `EUR`.
    temp24-width = '55'.
    temp24-depth = '45'.
    temp24-height = '29'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1056`.
    temp24-name = `Multi Color`.
    temp24-suppliername = `Printer for All`.
    temp24-weightmeasure = '4.3'.
    temp24-weightunit = `KG`.
    temp24-price = '119'.
    temp24-currencycode = `EUR`.
    temp24-width = '51'.
    temp24-depth = '41.3'.
    temp24-height = '22'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1060`.
    temp24-name = `Cordless Mouse`.
    temp24-suppliername = `Oxynum`.
    temp24-weightmeasure = '0.09'.
    temp24-weightunit = `KG`.
    temp24-price = '9'.
    temp24-currencycode = `EUR`.
    temp24-width = '6'.
    temp24-depth = '14.5'.
    temp24-height = '3.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1061`.
    temp24-name = `Speed Mouse`.
    temp24-suppliername = `Oxynum`.
    temp24-weightmeasure = '0.09'.
    temp24-weightunit = `KG`.
    temp24-price = '7'.
    temp24-currencycode = `EUR`.
    temp24-width = '7'.
    temp24-depth = '15'.
    temp24-height = '3.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1062`.
    temp24-name = `Track Mouse`.
    temp24-suppliername = `Oxynum`.
    temp24-weightmeasure = '0.03'.
    temp24-weightunit = `KG`.
    temp24-price = '11'.
    temp24-currencycode = `EUR`.
    temp24-width = '3'.
    temp24-depth = '7'.
    temp24-height = '4'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1063`.
    temp24-name = `Ergonomic Keyboard`.
    temp24-suppliername = `Oxynum`.
    temp24-weightmeasure = '2.1'.
    temp24-weightunit = `KG`.
    temp24-price = '14'.
    temp24-currencycode = `EUR`.
    temp24-width = '50'.
    temp24-depth = '21'.
    temp24-height = '3.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1064`.
    temp24-name = `Internet Keyboard`.
    temp24-suppliername = `Oxynum`.
    temp24-weightmeasure = '1.8'.
    temp24-weightunit = `KG`.
    temp24-price = '16'.
    temp24-currencycode = `EUR`.
    temp24-width = '52'.
    temp24-depth = '25'.
    temp24-height = '3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1065`.
    temp24-name = `Media Keyboard`.
    temp24-suppliername = `Oxynum`.
    temp24-weightmeasure = '2.3'.
    temp24-weightunit = `KG`.
    temp24-price = '26'.
    temp24-currencycode = `EUR`.
    temp24-width = '51.4'.
    temp24-depth = '23'.
    temp24-height = '4'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1066`.
    temp24-name = `Mousepad`.
    temp24-suppliername = `Oxynum`.
    temp24-weightmeasure = '80'.
    temp24-weightunit = `G`.
    temp24-price = '6.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '15'.
    temp24-depth = '6'.
    temp24-height = '0.2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1067`.
    temp24-name = `Ergo Mousepad`.
    temp24-suppliername = `Oxynum`.
    temp24-weightmeasure = '80'.
    temp24-weightunit = `G`.
    temp24-price = '8.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '15'.
    temp24-depth = '6'.
    temp24-height = '0.2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1068`.
    temp24-name = `Designer Mousepad`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '90'.
    temp24-weightunit = `G`.
    temp24-price = '12.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '24'.
    temp24-depth = '24'.
    temp24-height = '0.6'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1069`.
    temp24-name = `Universal card reader`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '45'.
    temp24-weightunit = `G`.
    temp24-price = '14'.
    temp24-currencycode = `EUR`.
    temp24-width = '6'.
    temp24-depth = '6'.
    temp24-height = '3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1070`.
    temp24-name = `Proctra X`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '0.255'.
    temp24-weightunit = `KG`.
    temp24-price = '70.9'.
    temp24-currencycode = `EUR`.
    temp24-width = '22'.
    temp24-depth = '35'.
    temp24-height = '17'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1071`.
    temp24-name = `Gladiator MX`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '0.3'.
    temp24-weightunit = `KG`.
    temp24-price = '81.7'.
    temp24-currencycode = `EUR`.
    temp24-width = '22'.
    temp24-depth = '35'.
    temp24-height = '17'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1072`.
    temp24-name = `Hurricane GX`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '0.4'.
    temp24-weightunit = `KG`.
    temp24-price = '101.2'.
    temp24-currencycode = `EUR`.
    temp24-width = '22'.
    temp24-depth = '35'.
    temp24-height = '17'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1073`.
    temp24-name = `Hurricane GX/LN`.
    temp24-suppliername = `Smartcards`.
    temp24-weightmeasure = '0.4'.
    temp24-weightunit = `KG`.
    temp24-price = '139.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '22'.
    temp24-depth = '35'.
    temp24-height = '17'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1080`.
    temp24-name = `Photo Scan`.
    temp24-suppliername = `Printer for All`.
    temp24-weightmeasure = '2.3'.
    temp24-weightunit = `KG`.
    temp24-price = '129'.
    temp24-currencycode = `EUR`.
    temp24-width = '34'.
    temp24-depth = '48'.
    temp24-height = '5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1081`.
    temp24-name = `Power Scan`.
    temp24-suppliername = `Printer for All`.
    temp24-weightmeasure = '2.4'.
    temp24-weightunit = `KG`.
    temp24-price = '89'.
    temp24-currencycode = `EUR`.
    temp24-width = '31'.
    temp24-depth = '43'.
    temp24-height = '7'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1082`.
    temp24-name = `Jet Scan Professional`.
    temp24-suppliername = `Printer for All`.
    temp24-weightmeasure = '3.2'.
    temp24-weightunit = `KG`.
    temp24-price = '169'.
    temp24-currencycode = `EUR`.
    temp24-width = '33'.
    temp24-depth = '41'.
    temp24-height = '12'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1083`.
    temp24-name = `Jet Scan Professional`.
    temp24-suppliername = `Printer for All`.
    temp24-weightmeasure = '3.2'.
    temp24-weightunit = `KG`.
    temp24-price = '189'.
    temp24-currencycode = `EUR`.
    temp24-width = '35'.
    temp24-depth = '40'.
    temp24-height = '10'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1085`.
    temp24-name = `Copymaster`.
    temp24-suppliername = `Alpha Printers`.
    temp24-weightmeasure = '23.2'.
    temp24-weightunit = `KG`.
    temp24-price = '1499'.
    temp24-currencycode = `EUR`.
    temp24-width = '45'.
    temp24-depth = '42'.
    temp24-height = '22'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1090`.
    temp24-name = `Surround Sound`.
    temp24-suppliername = `Speaker Experts`.
    temp24-weightmeasure = '3'.
    temp24-weightunit = `KG`.
    temp24-price = '39'.
    temp24-currencycode = `EUR`.
    temp24-width = '12'.
    temp24-depth = '10'.
    temp24-height = '16'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1091`.
    temp24-name = `Blaster Extreme`.
    temp24-suppliername = `Speaker Experts`.
    temp24-weightmeasure = '1.4'.
    temp24-weightunit = `KG`.
    temp24-price = '26'.
    temp24-currencycode = `EUR`.
    temp24-width = '13'.
    temp24-depth = '11'.
    temp24-height = '17.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1092`.
    temp24-name = `Sound Booster`.
    temp24-suppliername = `Speaker Experts`.
    temp24-weightmeasure = '2.1'.
    temp24-weightunit = `KG`.
    temp24-price = '45'.
    temp24-currencycode = `EUR`.
    temp24-width = '12.4'.
    temp24-depth = '10.4'.
    temp24-height = '18.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1095`.
    temp24-name = `Lovely Sound 5.1 Wireless`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '80'.
    temp24-weightunit = `G`.
    temp24-price = '49'.
    temp24-currencycode = `EUR`.
    temp24-width = '24'.
    temp24-depth = '19'.
    temp24-height = '23'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1096`.
    temp24-name = `Lovely Sound 5.1`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '130'.
    temp24-weightunit = `G`.
    temp24-price = '39'.
    temp24-currencycode = `EUR`.
    temp24-width = '25'.
    temp24-depth = '17'.
    temp24-height = '19'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1097`.
    temp24-name = `Lovely Sound Stereo`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '60'.
    temp24-weightunit = `G`.
    temp24-price = '29'.
    temp24-currencycode = `EUR`.
    temp24-width = '21.3'.
    temp24-depth = '2.4'.
    temp24-height = '19.7'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1100`.
    temp24-name = `Smart Office`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '1.2'.
    temp24-weightunit = `KG`.
    temp24-price = '89.9'.
    temp24-currencycode = `EUR`.
    temp24-width = '15'.
    temp24-depth = '6.5'.
    temp24-height = '2.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1101`.
    temp24-name = `Smart Design`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.8'.
    temp24-weightunit = `KG`.
    temp24-price = '79.9'.
    temp24-currencycode = `EUR`.
    temp24-width = '14'.
    temp24-depth = '6.7'.
    temp24-height = '24'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1102`.
    temp24-name = `Smart Network`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.8'.
    temp24-weightunit = `KG`.
    temp24-price = '69'.
    temp24-currencycode = `EUR`.
    temp24-width = '16'.
    temp24-depth = '6'.
    temp24-height = '27'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1103`.
    temp24-name = `Smart Multimedia`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.8'.
    temp24-weightunit = `KG`.
    temp24-price = '77'.
    temp24-currencycode = `EUR`.
    temp24-width = '11'.
    temp24-depth = '3.4'.
    temp24-height = '22'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1104`.
    temp24-name = `Smart Games`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '1.1'.
    temp24-weightunit = `KG`.
    temp24-price = '55'.
    temp24-currencycode = `EUR`.
    temp24-width = '10'.
    temp24-depth = '3'.
    temp24-height = '30'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1105`.
    temp24-name = `Smart Internet Antivirus`.
    temp24-suppliername = `Brainsoft`.
    temp24-weightmeasure = '0.7'.
    temp24-weightunit = `KG`.
    temp24-price = '29'.
    temp24-currencycode = `EUR`.
    temp24-width = '16'.
    temp24-depth = '4'.
    temp24-height = '21'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1106`.
    temp24-name = `Smart Firewall`.
    temp24-suppliername = `Brainsoft`.
    temp24-weightmeasure = '0.9'.
    temp24-weightunit = `KG`.
    temp24-price = '34'.
    temp24-currencycode = `EUR`.
    temp24-width = '17.9'.
    temp24-depth = '4.2'.
    temp24-height = '23.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1107`.
    temp24-name = `Smart Money`.
    temp24-suppliername = `Brainsoft`.
    temp24-weightmeasure = '0.5'.
    temp24-weightunit = `KG`.
    temp24-price = '29.9'.
    temp24-currencycode = `EUR`.
    temp24-width = '12'.
    temp24-depth = '1.5'.
    temp24-height = '19'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1110`.
    temp24-name = `PC Lock`.
    temp24-suppliername = `Red Point Stores`.
    temp24-weightmeasure = '0.03'.
    temp24-weightunit = `KG`.
    temp24-price = '8.9'.
    temp24-currencycode = `EUR`.
    temp24-width = '20'.
    temp24-depth = '8'.
    temp24-height = '4.3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1111`.
    temp24-name = `Notebook Lock`.
    temp24-suppliername = `Red Point Stores`.
    temp24-weightmeasure = '0.02'.
    temp24-weightunit = `KG`.
    temp24-price = '6.9'.
    temp24-currencycode = `EUR`.
    temp24-width = '31'.
    temp24-depth = '9'.
    temp24-height = '7'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1112`.
    temp24-name = `Web cam reality`.
    temp24-suppliername = `Red Point Stores`.
    temp24-weightmeasure = '0.075'.
    temp24-weightunit = `KG`.
    temp24-price = '39'.
    temp24-currencycode = `EUR`.
    temp24-width = '9'.
    temp24-depth = '8.2'.
    temp24-height = '1.3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1113`.
    temp24-name = `Screen clean`.
    temp24-suppliername = `Red Point Stores`.
    temp24-weightmeasure = '0.05'.
    temp24-weightunit = `KG`.
    temp24-price = '2.3'.
    temp24-currencycode = `EUR`.
    temp24-width = '2'.
    temp24-depth = '2'.
    temp24-height = '0.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1114`.
    temp24-name = `Fabric bag professional`.
    temp24-suppliername = `Red Point Stores`.
    temp24-weightmeasure = '1.8'.
    temp24-weightunit = `KG`.
    temp24-price = '31'.
    temp24-currencycode = `EUR`.
    temp24-width = '42'.
    temp24-depth = '32'.
    temp24-height = '7'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1115`.
    temp24-name = `Wireless DSL Router`.
    temp24-suppliername = `Red Point Stores`.
    temp24-weightmeasure = '0.45'.
    temp24-weightunit = `KG`.
    temp24-price = '49'.
    temp24-currencycode = `EUR`.
    temp24-width = '19.3'.
    temp24-depth = '18'.
    temp24-height = '5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1116`.
    temp24-name = `Wireless DSL Router / Repeater`.
    temp24-suppliername = `Red Point Stores`.
    temp24-weightmeasure = '0.45'.
    temp24-weightunit = `KG`.
    temp24-price = '59'.
    temp24-currencycode = `EUR`.
    temp24-width = '19.3'.
    temp24-depth = '18'.
    temp24-height = '5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1117`.
    temp24-name = `Wireless DSL Router / Repeater and Print Server`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.45'.
    temp24-weightunit = `KG`.
    temp24-price = '69'.
    temp24-currencycode = `EUR`.
    temp24-width = '19.3'.
    temp24-depth = '18'.
    temp24-height = '5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1118`.
    temp24-name = `USB Stick`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.015'.
    temp24-weightunit = `KG`.
    temp24-price = '35'.
    temp24-currencycode = `EUR`.
    temp24-width = '1.5'.
    temp24-depth = '8.7'.
    temp24-height = '1.2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1119`.
    temp24-name = `Travel Adapter`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '88'.
    temp24-weightunit = `G`.
    temp24-price = '79'.
    temp24-currencycode = `EUR`.
    temp24-width = '2'.
    temp24-depth = '3.1'.
    temp24-height = '3.9'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1120`.
    temp24-name = `Cordless Bluetooth Keyboard, english international`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '1'.
    temp24-weightunit = `KG`.
    temp24-price = '29'.
    temp24-currencycode = `EUR`.
    temp24-width = '51.4'.
    temp24-depth = '23'.
    temp24-height = '4'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1137`.
    temp24-name = `Flat XXL`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '18'.
    temp24-weightunit = `KG`.
    temp24-price = '1430'.
    temp24-currencycode = `EUR`.
    temp24-width = '54'.
    temp24-depth = '22'.
    temp24-height = '38'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1138`.
    temp24-name = `Pocket Mouse`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.02'.
    temp24-weightunit = `KG`.
    temp24-price = '23'.
    temp24-currencycode = `EUR`.
    temp24-width = '0.3'.
    temp24-depth = '0.5'.
    temp24-height = '1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1210`.
    temp24-name = `PC Power Station`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '2.3'.
    temp24-weightunit = `KG`.
    temp24-price = '2399'.
    temp24-currencycode = `EUR`.
    temp24-width = '28'.
    temp24-depth = '31'.
    temp24-height = '43'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1251`.
    temp24-name = `Astro Laptop 1516`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '4.2'.
    temp24-weightunit = `KG`.
    temp24-price = '989'.
    temp24-currencycode = `EUR`.
    temp24-width = '30'.
    temp24-depth = '18'.
    temp24-height = '3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1252`.
    temp24-name = `Astro Phone 6`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '0.75'.
    temp24-weightunit = `KG`.
    temp24-price = '649'.
    temp24-currencycode = `EUR`.
    temp24-width = '8'.
    temp24-depth = '6'.
    temp24-height = '1.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1253`.
    temp24-name = `Benda Laptop 1408`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '4.2'.
    temp24-weightunit = `KG`.
    temp24-price = '976'.
    temp24-currencycode = `EUR`.
    temp24-width = '30'.
    temp24-depth = '18'.
    temp24-height = '3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1254`.
    temp24-name = `Bending Screen 21HD`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '15'.
    temp24-weightunit = `KG`.
    temp24-price = '250'.
    temp24-currencycode = `EUR`.
    temp24-width = '37'.
    temp24-depth = '12'.
    temp24-height = '36'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1255`.
    temp24-name = `Broad Screen 22HD`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '16'.
    temp24-weightunit = `KG`.
    temp24-price = '270'.
    temp24-currencycode = `EUR`.
    temp24-width = '39'.
    temp24-depth = '12'.
    temp24-height = '38'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1256`.
    temp24-name = `Cerdik Phone 7`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '0.75'.
    temp24-weightunit = `KG`.
    temp24-price = '549'.
    temp24-currencycode = `EUR`.
    temp24-width = '9'.
    temp24-depth = '15'.
    temp24-height = '1.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1257`.
    temp24-name = `Cepat Tablet 10.5`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '2.8'.
    temp24-weightunit = `KG`.
    temp24-price = '549'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1258`.
    temp24-name = `Cepat Tablet 8`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '2.5'.
    temp24-weightunit = `KG`.
    temp24-price = '529'.
    temp24-currencycode = `EUR`.
    temp24-width = '38'.
    temp24-depth = '21'.
    temp24-height = '3.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1500`.
    temp24-name = `Server Basic`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '18'.
    temp24-weightunit = `KG`.
    temp24-price = '5000'.
    temp24-currencycode = `EUR`.
    temp24-width = '34'.
    temp24-depth = '35'.
    temp24-height = '23'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1501`.
    temp24-name = `Server Professional`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '25'.
    temp24-weightunit = `KG`.
    temp24-price = '15000'.
    temp24-currencycode = `EUR`.
    temp24-width = '29'.
    temp24-depth = '30'.
    temp24-height = '27'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1502`.
    temp24-name = `Server Power Pro`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '35'.
    temp24-weightunit = `KG`.
    temp24-price = '25000'.
    temp24-currencycode = `EUR`.
    temp24-width = '22'.
    temp24-depth = '27.3'.
    temp24-height = '37'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1600`.
    temp24-name = `Family PC Basic`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '4.8'.
    temp24-weightunit = `KG`.
    temp24-price = '600'.
    temp24-currencycode = `EUR`.
    temp24-width = '21.4'.
    temp24-depth = '29'.
    temp24-height = '38'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1601`.
    temp24-name = `Family PC Pro`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '5.3'.
    temp24-weightunit = `KG`.
    temp24-price = '900'.
    temp24-currencycode = `EUR`.
    temp24-width = '25'.
    temp24-depth = '31.7'.
    temp24-height = '40.2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1602`.
    temp24-name = `Gaming Monster`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '5.9'.
    temp24-weightunit = `KG`.
    temp24-price = '1200'.
    temp24-currencycode = `EUR`.
    temp24-width = '26.5'.
    temp24-depth = '34'.
    temp24-height = '47'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-1603`.
    temp24-name = `Gaming Monster Pro`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '6.8'.
    temp24-weightunit = `KG`.
    temp24-price = '1700'.
    temp24-currencycode = `EUR`.
    temp24-width = '27'.
    temp24-depth = '28'.
    temp24-height = '42'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-2000`.
    temp24-name = `7" Widescreen Portable DVD Player w MP3`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.79'.
    temp24-weightunit = `KG`.
    temp24-price = '249.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '21.4'.
    temp24-depth = '19'.
    temp24-height = '27.6'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-2001`.
    temp24-name = `10" Portable DVD player`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.84'.
    temp24-weightunit = `KG`.
    temp24-price = '449.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '24'.
    temp24-depth = '19.5'.
    temp24-height = '29'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-2002`.
    temp24-name = `Portable DVD Player with 9" LCD Monitor`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '0.72'.
    temp24-weightunit = `KG`.
    temp24-price = '853.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '21'.
    temp24-depth = '16.5'.
    temp24-height = '14'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-2025`.
    temp24-name = `CD/DVD case: 264 sleeves`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.65'.
    temp24-weightunit = `KG`.
    temp24-price = '44.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '13'.
    temp24-depth = '13'.
    temp24-height = '20'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-2026`.
    temp24-name = `Audio/Video Cable Kit - 4m`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.2'.
    temp24-weightunit = `KG`.
    temp24-price = '29.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '21'.
    temp24-depth = '10.2'.
    temp24-height = '13'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-2027`.
    temp24-name = `Removable CD/DVD Laser Labels`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.15'.
    temp24-weightunit = `KG`.
    temp24-price = '8.99'.
    temp24-currencycode = `EUR`.
    temp24-width = '5.5'.
    temp24-depth = '2'.
    temp24-height = '2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6100`.
    temp24-name = `Beam Breaker B-1`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '1.7'.
    temp24-weightunit = `KG`.
    temp24-price = '469'.
    temp24-currencycode = `EUR`.
    temp24-width = '30.4'.
    temp24-depth = '23.1'.
    temp24-height = '23'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6101`.
    temp24-name = `Beam Breaker B-2`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '2'.
    temp24-weightunit = `KG`.
    temp24-price = '679'.
    temp24-currencycode = `EUR`.
    temp24-width = '30.4'.
    temp24-depth = '23.1'.
    temp24-height = '23'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6102`.
    temp24-name = `Beam Breaker B-3`.
    temp24-suppliername = `Technocom`.
    temp24-weightmeasure = '2.5'.
    temp24-weightunit = `KG`.
    temp24-price = '889'.
    temp24-currencycode = `EUR`.
    temp24-width = '30.4'.
    temp24-depth = '23.1'.
    temp24-height = '23'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6110`.
    temp24-name = `Play Movie`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '2.4'.
    temp24-weightunit = `KG`.
    temp24-price = '130'.
    temp24-currencycode = `EUR`.
    temp24-width = '37'.
    temp24-depth = '24'.
    temp24-height = '6'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6111`.
    temp24-name = `Record Movie`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '3.1'.
    temp24-weightunit = `KG`.
    temp24-price = '288'.
    temp24-currencycode = `EUR`.
    temp24-width = '38'.
    temp24-depth = '26'.
    temp24-height = '6.2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6120`.
    temp24-name = `ITelo MusicStick`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '134'.
    temp24-weightunit = `G`.
    temp24-price = '45'.
    temp24-currencycode = `EUR`.
    temp24-width = '1.5'.
    temp24-depth = '6'.
    temp24-height = '1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6121`.
    temp24-name = `ITelo Jog-Mate`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '134'.
    temp24-weightunit = `G`.
    temp24-price = '63'.
    temp24-currencycode = `EUR`.
    temp24-width = '5.1'.
    temp24-depth = '8'.
    temp24-height = '9.2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6122`.
    temp24-name = `Power Pro Player 40`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '266'.
    temp24-weightunit = `G`.
    temp24-price = '167'.
    temp24-currencycode = `EUR`.
    temp24-width = '5.1'.
    temp24-depth = '8'.
    temp24-height = '9.2'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6123`.
    temp24-name = `Power Pro Player 80`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '267'.
    temp24-weightunit = `G`.
    temp24-price = '299'.
    temp24-currencycode = `EUR`.
    temp24-width = '4'.
    temp24-depth = '6'.
    temp24-height = '0.8'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6130`.
    temp24-name = `Flat Watch HD32`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '2.6'.
    temp24-weightunit = `KG`.
    temp24-price = '1459'.
    temp24-currencycode = `EUR`.
    temp24-width = '78'.
    temp24-depth = '22.1'.
    temp24-height = '55'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6131`.
    temp24-name = `Flat Watch HD37`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '2.2'.
    temp24-weightunit = `KG`.
    temp24-price = '1199'.
    temp24-currencycode = `EUR`.
    temp24-width = '99.1'.
    temp24-depth = '26'.
    temp24-height = '61'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-6132`.
    temp24-name = `Flat Watch HD41`.
    temp24-suppliername = `Very Best Screens`.
    temp24-weightmeasure = '1.8'.
    temp24-weightunit = `KG`.
    temp24-price = '899'.
    temp24-currencycode = `EUR`.
    temp24-width = '128'.
    temp24-depth = '23'.
    temp24-height = '79.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-7000`.
    temp24-name = `Copperberry`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '0.5'.
    temp24-weightunit = `KG`.
    temp24-price = '549'.
    temp24-currencycode = `EUR`.
    temp24-width = '8.1'.
    temp24-depth = '13'.
    temp24-height = '12.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-7010`.
    temp24-name = `Silverberry`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '0.5'.
    temp24-weightunit = `KG`.
    temp24-price = '549'.
    temp24-currencycode = `EUR`.
    temp24-width = '8.1'.
    temp24-depth = '13'.
    temp24-height = '12.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-7020`.
    temp24-name = `Goldberry`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '0.5'.
    temp24-weightunit = `KG`.
    temp24-price = '549'.
    temp24-currencycode = `EUR`.
    temp24-width = '8.1'.
    temp24-depth = '13'.
    temp24-height = '12.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-7030`.
    temp24-name = `Platinberry`.
    temp24-suppliername = `Fasttech`.
    temp24-weightmeasure = '0.5'.
    temp24-weightunit = `KG`.
    temp24-price = '549'.
    temp24-currencycode = `EUR`.
    temp24-width = '8.1'.
    temp24-depth = '13'.
    temp24-height = '12.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-8000`.
    temp24-name = `ITelO FlexTop I4000`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '4'.
    temp24-weightunit = `KG`.
    temp24-price = '799'.
    temp24-currencycode = `EUR`.
    temp24-width = '31'.
    temp24-depth = '19'.
    temp24-height = '3.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-8001`.
    temp24-name = `ITelO FlexTop I6300c`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '4.2'.
    temp24-weightunit = `KG`.
    temp24-price = '799'.
    temp24-currencycode = `EUR`.
    temp24-width = '32'.
    temp24-depth = '20'.
    temp24-height = '3.4'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-8002`.
    temp24-name = `ITelO FlexTop I9100`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '3.5'.
    temp24-weightunit = `KG`.
    temp24-price = '1199'.
    temp24-currencycode = `EUR`.
    temp24-width = '38'.
    temp24-depth = '21'.
    temp24-height = '4.1'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-8003`.
    temp24-name = `ITelO FlexTop I9800`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '3.8'.
    temp24-weightunit = `KG`.
    temp24-price = '1388'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9991`.
    temp24-name = `Smartphone Leather Case`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '0.02'.
    temp24-weightunit = `KG`.
    temp24-price = '25'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9992`.
    temp24-name = `Smartphone Alpha`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '0.75'.
    temp24-weightunit = `KG`.
    temp24-price = '599'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9993`.
    temp24-name = `Mini Tablet`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '3.8'.
    temp24-weightunit = `KG`.
    temp24-price = '833'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9994`.
    temp24-name = `Camcorder View`.
    temp24-suppliername = `Ultrasonic United`.
    temp24-weightmeasure = '3.8'.
    temp24-weightunit = `KG`.
    temp24-price = '1388'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '27'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9995`.
    temp24-name = `Tablet Pouch`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.03'.
    temp24-weightunit = `KG`.
    temp24-price = '20'.
    temp24-currencycode = `EUR`.
    temp24-width = '25'.
    temp24-depth = '40'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9996`.
    temp24-name = `Tablet Pouch`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.03'.
    temp24-weightunit = `KG`.
    temp24-price = '20'.
    temp24-currencycode = `EUR`.
    temp24-width = '25'.
    temp24-depth = '40'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9997`.
    temp24-name = `e-Book Reader ReadMe`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '3.8'.
    temp24-weightunit = `KG`.
    temp24-price = '33'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9998`.
    temp24-name = `Smartphone Beta`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.75'.
    temp24-weightunit = `KG`.
    temp24-price = '30'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `HT-9999`.
    temp24-name = `Maxi Tablet`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '3.8'.
    temp24-weightunit = `KG`.
    temp24-price = '749'.
    temp24-currencycode = `EUR`.
    temp24-width = '48'.
    temp24-depth = '31'.
    temp24-height = '4.5'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    temp24-productid = `PF-1000`.
    temp24-name = `Flyer`.
    temp24-suppliername = `Titanium`.
    temp24-weightmeasure = '0.01'.
    temp24-weightunit = `KG`.
    temp24-price = '0'.
    temp24-currencycode = `EUR`.
    temp24-width = '46'.
    temp24-depth = '30'.
    temp24-height = '3'.
    temp24-dimunit = `cm`.
    INSERT temp24 INTO TABLE temp23.
    t_products = temp23.


    weight_state_set( ).
    t_all      = t_products.
    t_filtered = t_products.

  ENDMETHOD.


ENDCLASS.
