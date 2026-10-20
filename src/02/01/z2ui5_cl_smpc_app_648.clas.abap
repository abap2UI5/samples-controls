" @keywords engine sap.m.p13n p13n.enginegridtable table overflowtoolbar title toolbarseparator toolbarspacer button menu popup selectionpanel
" @summary Grid Table using the personalization Engine
" @origin sap.m.sample.p13n.EngineGridTable - https://sdk.openui5.org/entity/sap.m.p13n.Engine/sample/sap.m.sample.p13n.EngineGridTable (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_648 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        firstname TYPE string,
        lastname  TYPE string,
        size      TYPE string,
        city      TYPE string,
      END OF ty_s_item.
    DATA t_items TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_column,
        key     TYPE string,
        label   TYPE string,
        path    TYPE string,
        visible TYPE abap_bool,
        width   TYPE string,
      END OF ty_s_column.
    TYPES:
      BEGIN OF ty_s_sorter,
        key        TYPE string,
        descending TYPE abap_bool,
      END OF ty_s_sorter.
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH EMPTY KEY.
    TYPES ty_t_sorter TYPE STANDARD TABLE OF ty_s_sorter WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    " the Engine state: Columns (order + visibility), ColumnWidth, Sorter
    DATA t_columns TYPE ty_t_column.
    DATA t_sorters TYPE ty_t_sorter.

    METHODS view_display.
    METHODS rows_binding
      RETURNING
        VALUE(result) TYPE string.
    METHODS set_p13n_data.
    METHODS on_event.
    METHODS apply_columns
      IMPORTING
        state TYPE string_table.
    METHODS move_column.
    METHODS p13n_entries
      IMPORTING
        json          TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_sorter.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_648 IMPLEMENTATION.

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

    DATA column_node TYPE REF TO z2ui5_cl_ui5_view_builder.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(table) = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.ui.table`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:m`    v = `sap.m`
        )->a( n = `xmlns:tcm`  v = `sap.m.table.columnmenu`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`
        )->a( n = `xmlns:app`  v = `http://schemas.sap.com/sapui5/extension/sap.ui.core.CustomData/1`
        )->a( n = `height`     v = `100%`

        )->ele( n = `Page` ns = `m`
            )->a( n = `showHeader` v = `false`

            " handleStateChange's getBinding( 'rows' ).sort( ), composed by the backend
            )->ele( `Table`
                )->a( n = `id`             v = `persoTable`
                )->a( n = `sort`           v = client->_event( val   = `SORT`
                                                               t_arg = VALUE #( ( `${$parameters>/column}.data('p13nKey')` )
                                                                                ( `${$parameters>/sortOrder}` ) ) )
                )->a( n = `columnResize`   v = client->_event( val   = `COLUMN_RESIZE`
                                                               t_arg = VALUE #( ( `${$parameters>/column}.data('p13nKey')` )
                                                                                ( `${$parameters>/width}` ) ) )
                " onColumnMove calls oEvt.preventDefault( ) and moves the column through the state
                )->a( n = `columnMove`     v = client->_event( val    = `COLUMN_MOVE`
                                                               t_arg  = VALUE #( ( `${$parameters>/column}.data('p13nKey')` )
                                                                                 ( `${$parameters>/newPos}` ) )
                                                               s_ctrl = VALUE #( check_prevent_default = abap_true ) )
                )->a( n = `rowMode`        v = `Auto`
                )->a( n = `ariaLabelledBy` v = `title`
                )->a( n = `rows`           v = rows_binding( ) ).

    table->ele( `extension`
        )->ele( n = `OverflowToolbar` ns = `m`
            )->tag( n = `Title` ns = `m`
                )->a( n = `id`   v = `title`
                )->a( n = `text` v = `Persons`
            )->tag( n = `ToolbarSeparator` ns = `m`
            " the sap.ui.fl VariantManagement (p13nVm) is dropped - see the sidecar
            )->tag( n = `ToolbarSpacer` ns = `m`
            )->tag( n = `Button` ns = `m`
                )->a( n = `icon`  v = `sap-icon://action-settings`
                )->a( n = `press` v = client->_event( `OPEN_PERSO` ) ).

    table->ele( `dependents`
        )->tag( n = `Menu` ns = `tcm`
            )->a( n = `id`                      v = `menu`
            )->a( n = `showTableSettingsButton` v = `true`
            )->a( n = `tableSettingsPressed`    v = client->_event( `OPEN_PERSO` )

        " the popup Engine.show( ) creates for the Columns and Sorter controllers
        )->ele( n = `Popup` ns = `p13n`
            )->a( n = `id`    v = `p13nPopup`
            )->a( n = `close` v = client->_event( val   = `P13N_CLOSE`
                                                  t_arg = VALUE #( ( `${$parameters>/reason}` )
                                                                   ( `$event.oSource.getPanels()[0].getP13nData(true)` )
                                                                   ( `$event.oSource.getPanels()[1].getP13nData(true)` ) ) )

            )->ele( n = `panels` ns = `p13n`
                )->tag( n = `SelectionPanel` ns = `p13n`
                    )->a( n = `id`          v = `columnsPanel`
                    )->a( n = `showHeader`  v = `true`
                    )->a( n = `enableCount` v = `true`
                )->tag( n = `SortPanel` ns = `p13n`
                    )->a( n = `id` v = `sortPanel` ).

    table->ele( `noData`
        )->tag( n = `IllustratedMessage` ns = `m`
            )->a( n = `enableVerticalResponsiveness` v = `true` ).

    " handleStateChange re-orders, hides and sizes the columns and sets their
    " sort order; the port emits them in the order the state holds
    DATA(columns) = table->ele( `columns` ).
    LOOP AT t_columns INTO DATA(column).
      DATA(sorter) = VALUE ty_s_sorter( t_sorters[ key = column-key ] OPTIONAL ).
      IF sorter IS INITIAL.
        column_node = columns->ele( `Column` ).
      ELSEIF sorter-descending = abap_true.
        column_node = columns->ele( `Column`
            )->a( n = `sortOrder` v = `Descending` ).
      ELSE.
        column_node = columns->ele( `Column`
            )->a( n = `sortOrder` v = `Ascending` ).
      ENDIF.
      column_node->a( n = `app:p13nKey`   t = column-key
          )->a( n = `sortProperty`  t = column-path
          )->a( n = `visible`       b = column-visible
          )->a( n = `headerMenu`    v = `menu`
          )->a( n = `resizable`     v = `true`
          )->a( n = `width`         t = column-width
          )->a( n = `autoResizable` v = `true`
          )->tag( n = `Label` ns = `m`
              )->a( n = `text` t = column-label
          )->ele( `template`
              )->tag( n = `Text` ns = `m`
                  )->a( n = `text` v = |\{{ column-path }\}| ).
    ENDLOOP.

    client->view_display( view->stringify( ) ).

    " a rebuilt view carries fresh, empty panels
    set_p13n_data( ).

  ENDMETHOD.


  METHOD rows_binding.

    DATA(sorter_list) = ``.
    LOOP AT t_sorters INTO DATA(sorter).
      sorter_list = |{ sorter_list }, \{ path: '{ t_columns[ key = sorter-key ]-path }', | &&
                    |descending: { COND #( WHEN sorter-descending = abap_true THEN `true` ELSE `false` ) } \}|.
    ENDLOOP.

    result = |\{ path: '{ client->_bind( val = t_items path = abap_true ) }', | &&
             |sorter: [{ shift_left( val = sorter_list sub = `, ` ) }] \}|.

  ENDMETHOD.


  METHOD set_p13n_data.

    " the controllers' panel data (mixInfoAndState): the active entries in
    " state order, then the others sorted by label
    DATA(by_label) = t_columns.
    SORT by_label BY label.

    DATA(json) = ``.
    LOOP AT t_columns INTO DATA(column) WHERE visible = abap_true.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":true\}|.
    ENDLOOP.
    LOOP AT by_label INTO column WHERE visible = abap_false.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":false\}|.
    ENDLOOP.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `columnsPanel` )
                                               ( `setP13nData` )
                                               ( |[{ shift_left( val = json sub = `,` ) }]| ) ) ).

    json = ``.
    LOOP AT t_sorters INTO DATA(sorter).
      json = |{ json },\{"name":"{ sorter-key }","label":"{ t_columns[ key = sorter-key ]-label }","sorted":true,| &&
             |"descending":{ COND #( WHEN sorter-descending = abap_true THEN `true` ELSE `false` ) }\}|.
    ENDLOOP.
    LOOP AT by_label INTO column.
      IF NOT line_exists( t_sorters[ key = column-key ] ).
        json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","sorted":false,"descending":false\}|.
      ENDIF.
    ENDLOOP.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `sortPanel` )
                                               ( `setP13nData` )
                                               ( |[{ shift_left( val = json sub = `,` ) }]| ) ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `OPEN_PERSO`.
        set_p13n_data( ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `p13nPopup` ) ( `open` ) ) ).

      WHEN `P13N_CLOSE`.
        " the Engine applies the panel state on Ok only
        IF client->get_event_arg( ) = `Ok`.
          apply_columns( VALUE #( FOR entry IN p13n_entries( client->get_event_arg( 2 ) ) ( entry-key ) ) ).
          t_sorters = p13n_entries( client->get_event_arg( 3 ) ).
          view_display( ).
        ENDIF.

      WHEN `SORT`.
        " onSort: every sorter cleared, the column's own order pushed
        IF line_exists( t_columns[ key = client->get_event_arg( ) ] ).
          t_sorters = VALUE #( ( key        = client->get_event_arg( )
                                 descending = xsdbool( client->get_event_arg( 2 ) = `Descending` ) ) ).
          view_display( ).
        ENDIF.

      WHEN `COLUMN_MOVE`.
        move_column( ).
        view_display( ).

      WHEN `COLUMN_RESIZE`.
        " applyState( { ColumnWidth } ): the table has already sized the
        " column, the state keeps the width for the next rebuild
        IF line_exists( t_columns[ key = client->get_event_arg( ) ] ).
          t_columns[ key = client->get_event_arg( ) ]-width = client->get_event_arg( 2 ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD apply_columns.

    " handleStateChange: every column hidden, then the state's columns shown
    " and moved to the front in state order
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


  METHOD move_column.

    DATA(moved) = client->get_event_arg( ).
    IF NOT line_exists( t_columns[ key = moved ] ).
      RETURN.
    ENDIF.

    " applyState( { Columns: [ { key, position: newPos } ] } ): the column
    " moves to that position of the visible columns and is shown
    DATA(new_pos) = CONV i( client->get_event_arg( 2 ) ).
    DATA(state) = VALUE string_table( FOR c IN t_columns WHERE ( visible = abap_true AND key <> moved ) ( c-key ) ).
    IF new_pos > lines( state ).
      new_pos = lines( state ).
    ELSEIF new_pos < 0.
      new_pos = 0.
    ENDIF.
    INSERT moved INTO state INDEX new_pos + 1.
    apply_columns( state ).

  ENDMETHOD.


  METHOD p13n_entries.

    " getP13nData( true ) arrives as a JSON array of the panel's flat item
    " objects; collect their names (and a SortPanel item's direction) in order
    SPLIT json AT `}` INTO TABLE DATA(objects).
    LOOP AT objects INTO DATA(object).
      DATA(offset) = find( val = object sub = `"name":"` ).
      IF offset >= 0.
        INSERT VALUE #( key        = substring_before( val = substring( val = object off = offset + 8 ) sub = `"` )
                        descending = xsdbool( object CS `"descending":true` ) ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    t_items = VALUE #(
        ( firstname = `Peter`  lastname = `Mueller`  size = `1.75` city = `Walldorf` )
        ( firstname = `Petra`  lastname = `Maier`    size = `1.85` city = `Walldorf` )
        ( firstname = `Thomas` lastname = `Smith`    size = `1.95` city = `Heidelberg` )
        ( firstname = `John`   lastname = `Williams` size = `1.65` city = `Walldorf` )
        ( firstname = `Maria`  lastname = `Jones`    size = `1.55` city = `Walldorf` ) ).

    " the columns of the view; label and path are the MetadataHelper's, the
    " width the controller's _mIntialWidth
    t_columns = VALUE #(
        ( key = `firstName_col` label = `First Name` path = `FIRSTNAME` visible = abap_true  width = `11rem` )
        ( key = `lastName_col`  label = `Last Name`  path = `LASTNAME`  visible = abap_true  width = `11rem` )
        ( key = `city_col`      label = `City`       path = `CITY`      visible = abap_true  width = `11rem` )
        ( key = `size_col`      label = `Size`       path = `SIZE`      visible = abap_false width = `11rem` ) ).

  ENDMETHOD.

ENDCLASS.
