CLASS z2ui5_cl_smpc_app_645 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        key       TYPE string,
        firstname TYPE string,
        lastname  TYPE string,
        size      TYPE string,
        city      TYPE string,
      END OF ty_s_item.
    DATA t_items         TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
    " the column menu's QuickSortItem and QuickGroupItem, set per opened column
    DATA quick_key       TYPE string.
    DATA quick_label     TYPE string.
    DATA quick_sortorder TYPE string.
    DATA quick_grouped   TYPE abap_bool.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_column,
        key     TYPE string,
        label   TYPE string,
        path    TYPE string,
        halign  TYPE string,
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
    " the Engine state: Columns (order + visibility, ColumnWidth), Sorter, Groups
    DATA t_columns TYPE ty_t_column.
    DATA t_sorters TYPE ty_t_sorter.
    DATA t_groups TYPE string_table.

    METHODS view_display.
    METHODS items_binding
      RETURNING
        VALUE(result) TYPE string.
    METHODS set_p13n_data.
    METHODS on_event.
    METHODS before_open_column_menu.
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


CLASS z2ui5_cl_smpc_app_645 IMPLEMENTATION.

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
        )->a( n = `xmlns`         v = `sap.m`
        )->a( n = `xmlns:mvc`     v = `sap.ui.core.mvc`
        )->a( n = `xmlns:plugins` v = `sap.m.plugins`
        )->a( n = `xmlns:tcm`     v = `sap.m.table.columnmenu`
        )->a( n = `xmlns:dnd`     v = `sap.ui.core.dnd`
        )->a( n = `xmlns:p13n`    v = `sap.m.p13n`
        )->a( n = `xmlns:app`     v = `http://schemas.sap.com/sapui5/extension/sap.ui.core.CustomData/1`
        )->a( n = `height`        v = `100%`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            " handleStateChange's bindItems( { sorter, filters } ), composed by the backend
            )->ele( `Table`
                )->a( n = `id`             v = `persoTable`
                )->a( n = `items`          v = items_binding( )
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
                )->a( n = `press`   v = client->_event( `OPEN_PERSO` )
                )->a( n = `tooltip` v = `Settings` ).

    " no filter can be set without the FilterPanel (see the sidecar), so the
    " filter info bar stays hidden and its two press handlers are not wired
    table->ele( `infoToolbar`
        )->ele( `OverflowToolbar`
            )->a( n = `id`      v = `filterInfo`
            )->a( n = `visible` v = `false`
            )->a( n = `design`  v = `Info`
            )->a( n = `active`  v = `true`

            )->tag( `Text`
                )->a( n = `id`       v = `filterInfoText`
                )->a( n = `wrapping` v = `false`
                )->a( n = `text`     v = `Table filter active`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `tooltip` v = `Remove All Filters`
                )->a( n = `icon`    v = `sap-icon://decline`
                )->a( n = `type`    v = `Transparent` ).

    table->ele( `dependents`
        )->tag( n = `ColumnResizer` ns = `plugins`
            )->a( n = `columnResize` v = client->_event( val   = `COLUMN_RESIZE`
                                                         t_arg = VALUE #( ( `${$parameters>/column}.data('p13nKey')` )
                                                                          ( `${$parameters>/width}` ) ) )

        )->ele( n = `Menu` ns = `tcm`
            )->a( n = `id`                      v = `menu`
            )->a( n = `beforeOpen`              v = client->_event( val = `BEFORE_OPEN_MENU`
                                                                    arg = `${$parameters>/openBy}.data('p13nKey')` )
            )->a( n = `showTableSettingsButton` v = `true`
            )->a( n = `tableSettingsPressed`    v = client->_event( `OPEN_PERSO` )

            )->ele( n = `QuickSort` ns = `tcm`
                )->a( n = `change` v = client->_event( val   = `QUICK_SORT`
                                                       t_arg = VALUE #( ( `${$parameters>/item}.getKey()` )
                                                                        ( `${$parameters>/item}.getSortOrder()` ) ) )

                )->ele( n = `items` ns = `tcm`
                    )->tag( n = `QuickSortItem` ns = `tcm`
                        )->a( n = `key`       v = client->_bind( quick_key )
                        )->a( n = `label`     v = client->_bind( quick_label )
                        )->a( n = `sortOrder` v = client->_bind( quick_sortorder )

                )->end(
            )->end(
            )->ele( n = `QuickGroup` ns = `tcm`
                )->a( n = `change` v = client->_event( val   = `QUICK_GROUP`
                                                       t_arg = VALUE #( ( `${$parameters>/item}.getKey()` )
                                                                        ( `${$parameters>/item}.getGrouped()` ) ) )

                )->ele( n = `items` ns = `tcm`
                    )->tag( n = `QuickGroupItem` ns = `tcm`
                        )->a( n = `key`     v = client->_bind( quick_key )
                        )->a( n = `label`   v = client->_bind( quick_label )
                        )->a( n = `grouped` v = client->_bind( quick_grouped )

                )->end(
            )->end(
        )->end(

        " the popup Engine.show( ) creates for the Columns, Sorter and Groups controllers
        )->ele( n = `Popup` ns = `p13n`
            )->a( n = `id`    v = `p13nPopup`
            )->a( n = `close` v = client->_event( val   = `P13N_CLOSE`
                                                  t_arg = VALUE #( ( `${$parameters>/reason}` )
                                                                   ( `$event.oSource.getPanels()[0].getP13nData(true)` )
                                                                   ( `$event.oSource.getPanels()[1].getP13nData(true)` )
                                                                   ( `$event.oSource.getPanels()[2].getP13nData(true)` ) ) )

            )->ele( n = `panels` ns = `p13n`
                )->tag( n = `SelectionPanel` ns = `p13n`
                    )->a( n = `id`          v = `columnsPanel`
                    )->a( n = `showHeader`  v = `true`
                    )->a( n = `enableCount` v = `true`
                )->tag( n = `SortPanel` ns = `p13n`
                    )->a( n = `id` v = `sortPanel`
                )->tag( n = `GroupPanel` ns = `p13n`
                    )->a( n = `id`         v = `groupPanel`
                    )->a( n = `queryLimit` v = `1` ).

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

    " updateColumns re-orders, hides and sizes the columns and sets their
    " sort indicator; the port emits them in the order the state holds
    DATA(columns) = table->ele( `columns` ).
    LOOP AT t_columns INTO DATA(column).
      DATA(sorter) = VALUE ty_s_sorter( t_sorters[ key = column-key ] OPTIONAL ).
      IF sorter IS INITIAL.
        column_node = columns->ele( `Column` ).
      ELSEIF sorter-descending = abap_true.
        column_node = columns->ele( `Column`
            )->a( n = `sortIndicator` v = `Descending` ).
      ELSE.
        column_node = columns->ele( `Column`
            )->a( n = `sortIndicator` v = `Ascending` ).
      ENDIF.
      column_node->a( n = `app:p13nKey` t = column-key
          )->a( n = `headerMenu` v = `menu`
          )->a( n = `visible`    b = column-visible ).
      IF column-halign = `End`.
        column_node->a( n = `hAlign` v = `End` ).
      ENDIF.
      IF column-width IS NOT INITIAL.
        column_node->a( n = `width` t = column-width ).
      ENDIF.
      IF column-key = `firstName_col`.
        column_node->ele( `header`
            )->tag( `Text`
                )->a( n = `text` t = column-label ).
      ELSE.
        column_node->tag( `Text`
            )->a( n = `text` t = column-label ).
      ENDIF.
    ENDLOOP.

    " the cell template follows the column order: one Text per column
    DATA(cells) = table->ele( `items`
        )->ele( `ColumnListItem` ).
    LOOP AT t_columns INTO column.
      cells->tag( `Text`
          )->a( n = `text` v = |\{{ column-path }\}| ).
    ENDLOOP.

    client->view_display( view->stringify( ) ).

    " a rebuilt view carries fresh, empty panels
    set_p13n_data( ).

  ENDMETHOD.


  METHOD items_binding.

    " createGroups + createSorters: one grouping sorter per group, then the
    " sorters - a sorter on an already grouped path only sets its direction
    TYPES:
      BEGIN OF ty_s_binding_sorter,
        path       TYPE string,
        descending TYPE abap_bool,
        group      TYPE abap_bool,
      END OF ty_s_binding_sorter.
    DATA binding_sorters TYPE STANDARD TABLE OF ty_s_binding_sorter WITH EMPTY KEY.

    LOOP AT t_groups INTO DATA(group).
      INSERT VALUE #( path = t_columns[ key = group ]-path group = abap_true ) INTO TABLE binding_sorters.
    ENDLOOP.
    LOOP AT t_sorters INTO DATA(sorter).
      DATA(path) = t_columns[ key = sorter-key ]-path.
      IF line_exists( binding_sorters[ path = path ] ).
        binding_sorters[ path = path ]-descending = sorter-descending.
      ELSE.
        INSERT VALUE #( path = path descending = sorter-descending ) INTO TABLE binding_sorters.
      ENDIF.
    ENDLOOP.

    DATA(sorter_list) = ``.
    LOOP AT binding_sorters INTO DATA(binding_sorter).
      sorter_list = |{ sorter_list }, \{ path: '{ binding_sorter-path }', | &&
                    |descending: { COND #( WHEN binding_sorter-descending = abap_true THEN `true` ELSE `false` ) }, | &&
                    |group: { COND #( WHEN binding_sorter-group = abap_true THEN `true` ELSE `false` ) } \}|.
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

    json = ``.
    LOOP AT t_groups INTO DATA(group).
      json = |{ json },\{"name":"{ group }","label":"{ t_columns[ key = group ]-label }","grouped":true\}|.
    ENDLOOP.
    LOOP AT by_label INTO column.
      IF NOT line_exists( t_groups[ table_line = column-key ] ).
        json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","grouped":false\}|.
      ENDIF.
    ENDLOOP.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `groupPanel` )
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
          t_groups = VALUE #( FOR entry IN p13n_entries( client->get_event_arg( 4 ) ) ( entry-key ) ).
          view_display( ).
        ENDIF.

      WHEN `BEFORE_OPEN_MENU`.
        before_open_column_menu( ).

      WHEN `QUICK_SORT`.
        " onSort: every sorter cleared, the column's own order pushed unless None
        t_sorters = VALUE #( ).
        IF client->get_event_arg( 2 ) <> `None`.
          t_sorters = VALUE #( ( key        = client->get_event_arg( )
                                 descending = xsdbool( client->get_event_arg( 2 ) = `Descending` ) ) ).
        ENDIF.
        view_display( ).

      WHEN `QUICK_GROUP`.
        " onGroup: every grouping cleared, the column grouped if the item says so
        t_groups = VALUE #( ).
        IF client->get_event_arg( 2 ) = abap_true.
          t_groups = VALUE #( ( client->get_event_arg( ) ) ).
        ENDIF.
        view_display( ).

      WHEN `COLUMN_MOVE`.
        move_column( ).
        view_display( ).

      WHEN `COLUMN_RESIZE`.
        " applyState( { ColumnWidth } ): the resizer has already sized the
        " column, the state keeps the width for the next rebuild
        IF line_exists( t_columns[ key = client->get_event_arg( ) ] ).
          t_columns[ key = client->get_event_arg( ) ]-width = client->get_event_arg( 2 ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD before_open_column_menu.

    DATA(column) = VALUE ty_s_column( t_columns[ key = client->get_event_arg( ) ] OPTIONAL ).
    IF column IS INITIAL.
      RETURN.
    ENDIF.
    DATA(sorter) = VALUE ty_s_sorter( t_sorters[ key = column-key ] OPTIONAL ).

    quick_key       = column-key.
    quick_label     = column-label.
    quick_sortorder = COND #( WHEN sorter IS INITIAL               THEN `None`
                              WHEN sorter-descending = abap_true THEN `Descending`
                              ELSE `Ascending` ).
    quick_grouped   = xsdbool( line_exists( t_groups[ table_line = column-key ] ) ).

  ENDMETHOD.


  METHOD apply_columns.

    " updateColumns: every column hidden, then the state's columns shown and
    " moved to the front in state order
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
        ( key = `P1` firstname = `Peter`  lastname = `Mueller`  size = `1.75` city = `Walldorf` )
        ( key = `P2` firstname = `Petra`  lastname = `Maier`    size = `1.85` city = `Walldorf` )
        ( key = `P3` firstname = `Thomas` lastname = `Smith`    size = `1.95` city = `Heidelberg` )
        ( key = `P4` firstname = `John`   lastname = `Williams` size = `1.65` city = `Walldorf` )
        ( key = `P5` firstname = `Maria`  lastname = `Jones`    size = `1.55` city = `Walldorf` ) ).

    " the columns of the view; label and path are the MetadataHelper's
    t_columns = VALUE #(
        ( key = `firstName_col` label = `First Name` path = `FIRSTNAME` halign = ``    visible = abap_true )
        ( key = `lastName_col`  label = `Last Name`  path = `LASTNAME`  halign = ``    visible = abap_true )
        ( key = `city_col`      label = `City`       path = `CITY`      halign = ``    visible = abap_true )
        ( key = `size_col`      label = `Size`       path = `SIZE`      halign = `End` visible = abap_false ) ).

    quick_sortorder = `None`.

  ENDMETHOD.

ENDCLASS.
