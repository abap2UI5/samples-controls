CLASS z2ui5_cl_smpc_app_649 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_column,
        key     TYPE string,
        label   TYPE string,
        halign  TYPE string,
        visible TYPE abap_bool,
      END OF ty_s_column.
    TYPES:
      BEGIN OF ty_s_row,
        key       TYPE string,
        label     TYPE string,
        id        TYPE string,
        firstname TYPE string,
        lastname  TYPE string,
        city      TYPE string,
        size      TYPE string,
        visible   TYPE abap_bool,
      END OF ty_s_row.
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH EMPTY KEY.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    " the table's columns and items in their current order, each with its visibility
    DATA t_columns TYPE ty_t_column.
    DATA t_rows TYPE ty_t_row.

    METHODS view_display.
    METHODS set_p13n_data.
    METHODS on_event.
    METHODS apply_columns
      IMPORTING
        state TYPE string_table.
    METHODS apply_rows
      IMPORTING
        state TYPE string_table.
    METHODS move_column.
    METHODS p13n_names
      IMPORTING
        json          TYPE string
      RETURNING
        VALUE(result) TYPE string_table.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_649 IMPLEMENTATION.

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

    DATA(table) = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:tcm`  v = `sap.m.table.columnmenu`
        )->a( n = `xmlns:dnd`  v = `sap.ui.core.dnd`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`
        )->a( n = `xmlns:app`  v = `http://schemas.sap.com/sapui5/extension/sap.ui.core.CustomData/1`
        )->a( n = `height`     v = `100%`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( `Table`
                )->a( n = `id`             v = `persoTable`
                )->a( n = `ariaLabelledBy` v = `title`
                )->a( n = `fixedLayout`    v = `Strict`
                )->a( n = `autoPopinMode`  v = `true`
                )->a( n = `growing`        v = `true`
                )->a( n = `sticky`         v = `ColumnHeaders,HeaderToolbar`
                )->a( n = `popinLayout`    v = `GridSmall` ).

    table->ele( `headerToolbar`
        )->ele( `OverflowToolbar`
            )->tag( `Title`
                )->a( n = `id`   v = `title`
                )->a( n = `text` v = `Persons`
            )->tag( `ToolbarSeparator`
            " the sap.ui.fl VariantManagement (p13nVm) is dropped - see the sidecar
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `icon`    v = `sap-icon://action-settings`
                )->a( n = `press`   v = client->_event( `OPEN_COLUMNS` )
                )->a( n = `tooltip` v = `Settings`
            )->tag( `Button`
                )->a( n = `icon`    v = `sap-icon://add-employee`
                )->a( n = `press`   v = client->_event( `OPEN_ROWS` )
                )->a( n = `tooltip` v = `Settings` ).

    table->ele( `dependents`
        )->ele( n = `Menu` ns = `tcm`
            )->a( n = `id` v = `menu`

            )->ele( n = `items` ns = `tcm`
                )->tag( n = `ActionItem` ns = `tcm`
                    )->a( n = `icon`  v = `sap-icon://table-column`
                    )->a( n = `label` v = `Columns`
                    )->a( n = `press` v = client->_event( `OPEN_COLUMNS` )

            )->end(
        )->end(

        " the two popups Engine.show( ) creates for the Columns and the Rows controller
        )->ele( n = `Popup` ns = `p13n`
            )->a( n = `id`    v = `columnsPopup`
            )->a( n = `close` v = client->_event( val   = `COLUMNS_CLOSE`
                                                  t_arg = VALUE #( ( `${$parameters>/reason}` )
                                                                   ( `$event.oSource.getPanels()[0].getP13nData(true)` ) ) )

            )->ele( n = `panels` ns = `p13n`
                )->tag( n = `SelectionPanel` ns = `p13n`
                    )->a( n = `id`          v = `columnsPanel`
                    )->a( n = `showHeader`  v = `true`
                    )->a( n = `enableCount` v = `true`

            )->end(
        )->end(

        )->ele( n = `Popup` ns = `p13n`
            )->a( n = `id`    v = `rowsPopup`
            )->a( n = `close` v = client->_event( val   = `ROWS_CLOSE`
                                                  t_arg = VALUE #( ( `${$parameters>/reason}` )
                                                                   ( `$event.oSource.getPanels()[0].getP13nData(true)` ) ) )

            )->ele( n = `panels` ns = `p13n`
                )->tag( n = `SelectionPanel` ns = `p13n`
                    )->a( n = `id`            v = `rowsPanel`
                    )->a( n = `showHeader`    v = `true`
                    )->a( n = `enableCount`   v = `true`
                    )->a( n = `enableReorder` v = `false` ).

    table->ele( `dragDropConfig`
        )->tag( n = `DragDropInfo` ns = `dnd`
            )->a( n = `sourceAggregation` v = `columns`
            )->a( n = `targetAggregation` v = `columns`
            )->a( n = `dropPosition`      v = `Between`
            )->a( n = `drop`              v = client->_event( val   = `COLUMN_MOVE`
                                                              t_arg = VALUE #( ( `${$parameters>/draggedControl}.data('p13nKey')` )
                                                                               ( `${$parameters>/droppedControl}.data('p13nKey')` )
                                                                               ( `${$parameters>/dropPosition}` ) ) ) ).

    table->ele( `noData`
        )->tag( `IllustratedMessage` ).

    " handleStateChange re-orders and hides columns and items; the port emits
    " them in the order the state holds, the cells following their columns
    DATA(columns) = table->ele( `columns` ).
    LOOP AT t_columns INTO DATA(column).
      DATA(column_node) = columns->ele( `Column`
          )->a( n = `app:p13nKey` t = column-key
          )->a( n = `headerMenu`  v = `menu`
          )->a( n = `visible`     b = column-visible ).
      IF column-halign = `End`.
        column_node->a( n = `hAlign` v = `End` ).
      ENDIF.
      IF column-key = `id_col`.
        column_node->ele( `header`
            )->tag( `Text`
                )->a( n = `text` t = column-label ).
      ELSE.
        column_node->tag( `Text`
            )->a( n = `text` t = column-label ).
      ENDIF.
    ENDLOOP.

    DATA(items) = table->ele( `items` ).
    LOOP AT t_rows INTO DATA(row).
      DATA(item) = items->ele( `ColumnListItem`
          )->a( n = `app:p13nKey` t = row-key
          )->a( n = `visible`     b = row-visible ).
      LOOP AT t_columns INTO column.
        item->tag( `Text`
            )->a( n = `text` t = SWITCH #( column-key
                                           WHEN `id_col`        THEN row-id
                                           WHEN `firstName_col` THEN row-firstname
                                           WHEN `lastName_col`  THEN row-lastname
                                           WHEN `city_col`      THEN row-city
                                           ELSE row-size ) ).
      ENDLOOP.
    ENDLOOP.

    client->view_display( view->stringify( ) ).

    " a rebuilt view carries fresh, empty panels
    set_p13n_data( ).

  ENDMETHOD.


  METHOD set_p13n_data.

    " the SelectionControllers' panel data: the visible entries in state
    " order, then the hidden ones sorted by label
    DATA(json) = ``.
    LOOP AT t_columns INTO DATA(column) WHERE visible = abap_true.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":true\}|.
    ENDLOOP.
    DATA(hidden_columns) = VALUE ty_t_column( FOR c IN t_columns WHERE ( visible = abap_false ) ( c ) ).
    SORT hidden_columns BY label.
    LOOP AT hidden_columns INTO column.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":false\}|.
    ENDLOOP.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `columnsPanel` )
                                               ( `setP13nData` )
                                               ( |[{ shift_left( val = json sub = `,` ) }]| ) ) ).

    json = ``.
    LOOP AT t_rows INTO DATA(row) WHERE visible = abap_true.
      json = |{ json },\{"name":"{ row-key }","label":"{ row-label }","visible":true\}|.
    ENDLOOP.
    DATA(hidden_rows) = VALUE ty_t_row( FOR r IN t_rows WHERE ( visible = abap_false ) ( r ) ).
    SORT hidden_rows BY label.
    LOOP AT hidden_rows INTO row.
      json = |{ json },\{"name":"{ row-key }","label":"{ row-label }","visible":false\}|.
    ENDLOOP.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `rowsPanel` )
                                               ( `setP13nData` )
                                               ( |[{ shift_left( val = json sub = `,` ) }]| ) ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `OPEN_COLUMNS`.
        set_p13n_data( ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `columnsPopup` ) ( `open` ) ) ).

      WHEN `OPEN_ROWS`.
        set_p13n_data( ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `rowsPopup` ) ( `open` ) ) ).

      WHEN `COLUMNS_CLOSE`.
        " the Engine applies the panel state on Ok only
        IF client->get_event_arg( ) = `Ok`.
          apply_columns( p13n_names( client->get_event_arg( 2 ) ) ).
          view_display( ).
        ENDIF.

      WHEN `ROWS_CLOSE`.
        IF client->get_event_arg( ) = `Ok`.
          apply_rows( p13n_names( client->get_event_arg( 2 ) ) ).
          view_display( ).
        ENDIF.

      WHEN `COLUMN_MOVE`.
        move_column( ).
        view_display( ).

    ENDCASE.

  ENDMETHOD.


  METHOD apply_columns.

    " like handleStateChange: every column hidden, then the state's columns
    " shown and moved to the front in state order
    DATA(previous) = t_columns.
    t_columns = VALUE #( ).
    LOOP AT state INTO DATA(key).
      DATA(column) = previous[ key = key ].
      column-visible = abap_true.
      INSERT column INTO TABLE t_columns.
      DELETE previous WHERE key = key.
    ENDLOOP.
    LOOP AT previous INTO column.
      column-visible = abap_false.
      INSERT column INTO TABLE t_columns.
    ENDLOOP.

  ENDMETHOD.


  METHOD apply_rows.

    DATA(previous) = t_rows.
    t_rows = VALUE #( ).
    LOOP AT state INTO DATA(key).
      DATA(row) = previous[ key = key ].
      row-visible = abap_true.
      INSERT row INTO TABLE t_rows.
      DELETE previous WHERE key = key.
    ENDLOOP.
    LOOP AT previous INTO row.
      row-visible = abap_false.
      INSERT row INTO TABLE t_rows.
    ENDLOOP.

  ENDMETHOD.


  METHOD move_column.

    DATA(dragged) = client->get_event_arg( ).
    DATA(dropped) = client->get_event_arg( 2 ).
    IF dragged = dropped OR NOT line_exists( t_columns[ key = dragged ] ) OR NOT line_exists( t_columns[ key = dropped ] ).
      RETURN.
    ENDIF.

    " onColumnMove's position arithmetic, on 0-based column indices
    DATA(dragged_index) = line_index( t_columns[ key = dragged ] ) - 1.
    DATA(dropped_index) = line_index( t_columns[ key = dropped ] ) - 1.
    DATA(new_pos) = dropped_index
                    + COND i( WHEN client->get_event_arg( 3 ) = `Before` THEN 0 ELSE 1 )
                    + COND i( WHEN dragged_index < dropped_index THEN -1 ELSE 0 ).

    " applyState( { Columns: [ { key, position } ] } ): the column moves to
    " that position of the visible columns and is shown
    DATA(state) = VALUE string_table( FOR c IN t_columns WHERE ( visible = abap_true AND key <> dragged ) ( c-key ) ).
    IF new_pos > lines( state ).
      new_pos = lines( state ).
    ENDIF.
    INSERT dragged INTO state INDEX new_pos + 1.
    apply_columns( state ).

  ENDMETHOD.


  METHOD p13n_names.

    " getP13nData( true ) arrives as a JSON array of the panel's flat item
    " objects; collect their names in order
    SPLIT json AT `}` INTO TABLE DATA(objects).
    LOOP AT objects INTO DATA(object).
      DATA(offset) = find( val = object sub = `"name":"` ).
      IF offset >= 0.
        INSERT substring_before( val = substring( val = object off = offset + 8 ) sub = `"` ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    " the columns of the view; the labels are the MetadataHelper's
    t_columns = VALUE #(
        ( key = `id_col`        label = `ID`         halign = ``    visible = abap_true )
        ( key = `firstName_col` label = `First Name` halign = ``    visible = abap_true )
        ( key = `lastName_col`  label = `Last Name`  halign = ``    visible = abap_true )
        ( key = `city_col`      label = `City`       halign = ``    visible = abap_true )
        ( key = `size_col`      label = `Size`       halign = `End` visible = abap_false ) ).

    " the static items of the view; the labels are the rows' MetadataHelper's
    t_rows = VALUE #(
        ( key = `P1` label = `Peter Mueller` id = `P1` firstname = `Peter`  lastname = `Mueller`  city = `Walldorf` size = `1.75` visible = abap_true )
        ( key = `P2` label = `Petra Maier`   id = `P2` firstname = `Petra`  lastname = `Maier`    city = `Walldorf` size = `1.85` visible = abap_true )
        ( key = `P3` label = `Thomas Smith`  id = `P3` firstname = `Thomas` lastname = `Smith`    city = `Walldorf` size = `1.95` visible = abap_true )
        ( key = `P4` label = `John Williams` id = `P4` firstname = `John`   lastname = `Williams` city = `Walldorf` size = `1.65` visible = abap_true )
        ( key = `P5` label = `Maria Jones`   id = `P5` firstname = `Maria`  lastname = `Jones`    city = `Walldorf` size = `1.55` visible = abap_true ) ).

  ENDMETHOD.

ENDCLASS.
