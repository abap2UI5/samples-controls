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
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA filter_bar_visible TYPE abap_bool.
    DATA filter_label TYPE string.

    " onResize writes the Product column's width. A bound CSSSize carries it:
    " an empty value is valid there (the type's 0* branch matches it), so the
    " column keeps its automatic width until the user drags once.
    DATA product_width TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    DATA t_all TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    " the filtered set in MODEL ORDER, i.e. before any sort. Restoring it is
    " what oBinding.sort( ) with no argument does in the original, and both the
    " QuickSort None entry and the group dialog's Reset need exactly that.
    DATA t_filtered TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA group_key TYPE string.
    DATA context_menu_on TYPE abap_bool.

    TYPES:
      BEGIN OF ty_s_event_item,
        id       TYPE string,
        key      TYPE string,
        text     TYPE string,
        selected TYPE abap_bool,
      END OF ty_s_event_item.
    TYPES ty_t_event_item TYPE STANDARD TABLE OF ty_s_event_item WITH EMPTY KEY.

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
                                                           t_arg = VALUE #( ( `${$parameters>/item}.getKey()` )
                                                                            ( `${$parameters>/item}.getSortOrder()` ) ) )

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
                                                        t_arg = VALUE #( ( `${$parameters>/sortItem}` )
                                                                         ( `${$parameters>/sortDescending}` ) ) )

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
                                                        t_arg = VALUE #( ( `${$parameters>/filterItems}` )
                                                                         ( `${$parameters>/filterString}` ) ) )

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

    CASE client->get_event( ).

      WHEN `OPEN_SORT`.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `sortDialog` ) ( `open` ) ) ).

      WHEN `OPEN_FILTER`.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `filterDialog` ) ( `open` ) ) ).

      WHEN `OPEN_GROUP`.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `groupDialog` ) ( `open` ) ) ).

      WHEN `SORT_CONFIRM`.
        DATA(t_item) = event_items( client->get_event_arg( ) ).
        IF t_item IS NOT INITIAL.
          table_sort( field      = abap_field( t_item[ 1 ]-key )
                      descending = xsdbool( client->get_event_arg( 2 ) = abap_true ) ).
        ENDIF.

      WHEN `MENU_SORT`.
        " onSortChange: sortOrder None clears the sorter (oBinding.sort( ) with
        " no argument), which restores MODEL order rather than sorting by
        " anything - the branch the port used to fall through
        IF client->get_event_arg( 2 ) = `None`.
          t_products = t_filtered.
        ELSE.
          table_sort( field      = abap_field( client->get_event_arg( ) )
                      descending = xsdbool( client->get_event_arg( 2 ) = `Descending` ) ).
        ENDIF.

      WHEN `GROUP_CONFIRM`.
        t_item = event_items( client->get_event_arg( ) ).
        group_key = COND #( WHEN t_item IS INITIAL THEN `` ELSE t_item[ 1 ]-key ).
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
        context_menu_on = xsdbool( context_menu_on = abap_false ).
        client->message_toast_display( COND #( WHEN context_menu_on = abap_true
                                               THEN `Custom context menu enabled`
                                               ELSE `Custom context menu disabled` ) ).

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
    DATA(t_item) = event_items( client->get_event_arg( ) ).

    t_products = t_all.
    filter_label       = client->get_event_arg( 2 ).
    filter_bar_visible = xsdbool( filter_label IS NOT INITIAL ).

    LOOP AT t_item INTO DATA(s_item).
      SPLIT s_item-key AT `___` INTO DATA(field) DATA(operator) DATA(value1) DATA(value2).

      DATA(low)  = CONV decfloat34( value1 ).
      DATA(high) = CONV decfloat34( COND string( WHEN value2 = `X` THEN `0` ELSE value2 ) ).

      " Collected rather than deleted in place: DELETE ... INDEX sy-tabix inside
      " a LOOP over the same table shifts the rows under the loop's own cursor -
      " on a system it silently SKIPS the row after each deletion, on the
      " transpiled backend it raises TABLE_INVALID_INDEX (2026-08-17).
      t_keep = VALUE #( ).
      LOOP AT t_products INTO DATA(s_row).
        DATA(compare) = COND decfloat34( WHEN field = `WeightMeasure` THEN s_row-weightmeasure ELSE s_row-price ).
        DATA(keep) = SWITCH abap_bool( operator
                                       WHEN `LE` THEN xsdbool( compare <= low )
                                       WHEN `GT` THEN xsdbool( compare > low )
                                       WHEN `BT` THEN xsdbool( compare >= low AND compare <= high )
                                       ELSE abap_true ).
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
    LOOP AT t_products REFERENCE INTO DATA(row).
      row->weight_state = COND #( WHEN row->weightmeasure < 0    THEN `None`
                                     WHEN row->weightmeasure < 1000 THEN `Success`
                                     WHEN row->weightmeasure < 2000 THEN `Warning`
                                     ELSE `Error` ).
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
    result = SWITCH #( val
                       WHEN `Name`          THEN `NAME`
                       WHEN `SupplierName`  THEN `SUPPLIERNAME`
                       WHEN `WeightMeasure` THEN `WEIGHTMEASURE`
                       WHEN `Price`         THEN `PRICE`
                       ELSE `NAME` ).

  ENDMETHOD.


  METHOD event_items.

    DATA(json) = condense( val ).
    IF json IS INITIAL.
      RETURN.
    ENDIF.

    " The frontend marshals each control into an object of its ID plus ALL
    " its public properties, so this reads the fields the port models and
    " ignores the rest - which is what the corresponding-only mapping used
    " to do. Written by hand: there is no released JSON parser, and the
    " vendored ajson copy is framework-internal.
    LOOP AT json_objects( json ) INTO DATA(object).
      INSERT VALUE #( id       = json_get_value( json = object
                                                 name = `id` )
                      key      = json_get_value( json = object
                                                 name = `key` )
                      text     = json_get_value( json = object
                                                 name = `text` )
                      selected = json_get_bool( json = object
                                                name = `selected` ) ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


  METHOD json_objects.

    " Cut the array into its objects. abap2UI5 releases no JSON parser and
    " the vendored ajson copy is framework-internal (the linter's
    " non-released-api rule reports it, correctly), so the split is one
    " character walk - and it is a walk rather than a SPLIT on `},{` because
    " a brace inside a STRING is text, not structure.
    DATA(depth)     = 0.
    DATA(in_string) = abap_false.
    DATA(escaped)   = abap_false.
    DATA(start)     = 0.
    DATA(pos)       = 0.
    DATA(length)    = strlen( json ).

    WHILE pos < length.
      DATA(char) = substring( val = json off = pos len = 1 ).

      IF escaped = abap_true.
        escaped = abap_false.
      ELSEIF in_string = abap_true AND char = `\`.
        escaped = abap_true.
      ELSEIF char = `"`.
        in_string = xsdbool( in_string = abap_false ).
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
    DATA(marker) = |"{ name }":"|.

    DATA(offset) = find( val = json sub = marker case = abap_false ).
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
    DATA(marker) = |"{ name }":|.

    DATA(offset) = find( val = json sub = marker case = abap_false ).
    IF offset < 0.
      RETURN.
    ENDIF.

    result = xsdbool( substring( val = json off = offset + strlen( marker ) ) CP `true*` ).

  ENDMETHOD.


  METHOD model_init.

    " the shared mock /ProductCollection flattened to the bound columns, all 123 rows kept verbatim
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


    weight_state_set( ).
    t_all      = t_products.
    t_filtered = t_products.

  ENDMETHOD.


ENDCLASS.
