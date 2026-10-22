" @keywords engine sap.m.p13n p13n.engine table overflowtoolbar title toolbarseparator toolbarspacer button text columnresizer menu
" @summary Responsive Table using the personalization Engine
" @origin sap.m.sample.p13n.Engine - https://sdk.openui5.org/entity/sap.m.p13n.Engine/sample/sap.m.sample.p13n.Engine (status: generated - machine-written, not yet reviewed)
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
    TYPES temp1_cbed504616 TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
DATA t_items         TYPE temp1_cbed504616.
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
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH DEFAULT KEY.
    TYPES ty_t_sorter TYPE STANDARD TABLE OF ty_s_sorter WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    " the Engine state: Columns (order + visibility, ColumnWidth), Sorter, Groups
    DATA t_columns TYPE ty_t_column.
    DATA t_sorters TYPE ty_t_sorter.
    DATA t_groups TYPE string_table.

    METHODS view_display.
    METHODS items_binding
      RETURNING
        VALUE(result) TYPE string.
    METHODS on_event.
    METHODS p13n_popup_display.
    METHODS set_p13n_data.
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

    DATA column_node TYPE REF TO z2ui5_cl_ui5_view_builder.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA temp2 TYPE string_table.
    DATA temp4 TYPE string_table.
    DATA temp3 TYPE string_table.
    DATA columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA column LIKE LINE OF t_columns.
      DATA temp5 TYPE ty_s_sorter.
      DATA temp6 TYPE z2ui5_cl_smpc_app_645=>ty_s_sorter.
      DATA sorter LIKE temp5.
    DATA cells TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    table = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`         v = `sap.m`
        )->a( n = `xmlns:mvc`     v = `sap.ui.core.mvc`
        )->a( n = `xmlns:plugins` v = `sap.m.plugins`
        )->a( n = `xmlns:tcm`     v = `sap.m.table.columnmenu`
        )->a( n = `xmlns:dnd`     v = `sap.ui.core.dnd`
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

    
    CLEAR temp1.
    INSERT `${$parameters>/column}.data('p13nKey')` INTO TABLE temp1.
    INSERT `${$parameters>/width}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$parameters>/item}.getKey()` INTO TABLE temp2.
    INSERT `${$parameters>/item}.getSortOrder()` INTO TABLE temp2.
    
    CLEAR temp4.
    INSERT `${$parameters>/item}.getKey()` INTO TABLE temp4.
    INSERT `${$parameters>/item}.getGrouped()` INTO TABLE temp4.
    table->ele( `dependents`
        )->tag( n = `ColumnResizer` ns = `plugins`
            )->a( n = `columnResize` v = client->_event( val   = `COLUMN_RESIZE`
                                                         t_arg = temp1 )

        )->ele( n = `Menu` ns = `tcm`
            )->a( n = `id`                      v = `menu`
            )->a( n = `beforeOpen`              v = client->_event( val = `BEFORE_OPEN_MENU`
                                                                    arg = `${$parameters>/openBy}.data('p13nKey')` )
            )->a( n = `showTableSettingsButton` v = `true`
            )->a( n = `tableSettingsPressed`    v = client->_event( `OPEN_PERSO` )

            )->ele( n = `QuickSort` ns = `tcm`
                )->a( n = `change` v = client->_event( val   = `QUICK_SORT`
                                                       t_arg = temp2 )

                )->ele( n = `items` ns = `tcm`
                    )->tag( n = `QuickSortItem` ns = `tcm`
                        )->a( n = `key`       v = client->_bind( quick_key )
                        )->a( n = `label`     v = client->_bind( quick_label )
                        )->a( n = `sortOrder` v = client->_bind( quick_sortorder )

                )->end(
            )->end(
            )->ele( n = `QuickGroup` ns = `tcm`
                )->a( n = `change` v = client->_event( val   = `QUICK_GROUP`
                                                       t_arg = temp4 )

                )->ele( n = `items` ns = `tcm`
                    )->tag( n = `QuickGroupItem` ns = `tcm`
                        )->a( n = `key`     v = client->_bind( quick_key )
                        )->a( n = `label`   v = client->_bind( quick_label )
                        )->a( n = `grouped` v = client->_bind( quick_grouped ) ).

    
    CLEAR temp3.
    INSERT `${$parameters>/draggedControl}.data('p13nKey')` INTO TABLE temp3.
    INSERT `${$parameters>/droppedControl}.data('p13nKey')` INTO TABLE temp3.
    INSERT `${$parameters>/dropPosition}` INTO TABLE temp3.
    table->ele( `dragDropConfig`
        )->tag( n = `DragDropInfo` ns = `dnd`
            )->a( n = `sourceAggregation` v = `columns`
            )->a( n = `targetAggregation` v = `columns`
            )->a( n = `dropPosition`      v = `Between`
            )->a( n = `drop`              v = client->_event( val   = `COLUMN_MOVE`
                                                              t_arg = temp3 ) ).

    table->ele( `noData`
        )->tag( `IllustratedMessage` ).

    " updateColumns re-orders, hides and sizes the columns and sets their
    " sort indicator; the port emits them in the order the state holds
    
    columns = table->ele( `columns` ).
    
    LOOP AT t_columns INTO column.
      
      CLEAR temp5.
      
      READ TABLE t_sorters INTO temp6 WITH KEY key = column-key.
      IF sy-subrc = 0.
        temp5 = temp6.
      ENDIF.
      
      sorter = temp5.
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
    
    cells = table->ele( `items`
        )->ele( `ColumnListItem` ).
    LOOP AT t_columns INTO column.
      cells->tag( `Text`
          )->a( n = `text` v = |\{{ column-path }\}| ).
    ENDLOOP.

    client->view_display( view->stringify( ) ).

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
    TYPES temp2 TYPE STANDARD TABLE OF ty_s_binding_sorter WITH DEFAULT KEY.
DATA binding_sorters TYPE temp2.

    DATA group LIKE LINE OF t_groups.
      DATA temp7 TYPE ty_s_binding_sorter.
      FIELD-SYMBOLS <temp5> LIKE LINE OF t_columns.
      DATA temp6 LIKE sy-tabix.
    DATA sorter LIKE LINE OF t_sorters.
      DATA path TYPE z2ui5_cl_smpc_app_645=>ty_s_column-path.
      FIELD-SYMBOLS <temp7> LIKE LINE OF t_columns.
      DATA temp9 LIKE sy-tabix.
      DATA temp8 LIKE sy-subrc.
        FIELD-SYMBOLS <temp9> LIKE LINE OF binding_sorters.
        DATA temp10 LIKE sy-tabix.
        DATA temp11 TYPE ty_s_binding_sorter.
    DATA sorter_list TYPE string.
    DATA binding_sorter LIKE LINE OF binding_sorters.
      DATA temp12 TYPE string.
      DATA temp13 TYPE string.
    LOOP AT t_groups INTO group.
      
      CLEAR temp7.
      
      
      temp6 = sy-tabix.
      READ TABLE t_columns WITH KEY key = group ASSIGNING <temp5>.
      sy-tabix = temp6.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      temp7-path = <temp5>-path.
      temp7-group = abap_true.
      INSERT temp7 INTO TABLE binding_sorters.
    ENDLOOP.
    
    LOOP AT t_sorters INTO sorter.
      
      
      
      temp9 = sy-tabix.
      READ TABLE t_columns WITH KEY key = sorter-key ASSIGNING <temp7>.
      sy-tabix = temp9.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      path = <temp7>-path.
      
      READ TABLE binding_sorters WITH KEY path = path TRANSPORTING NO FIELDS.
      temp8 = sy-subrc.
      IF temp8 = 0.
        
        
        temp10 = sy-tabix.
        READ TABLE binding_sorters WITH KEY path = path ASSIGNING <temp9>.
        sy-tabix = temp10.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp9>-descending = sorter-descending.
      ELSE.
        
        CLEAR temp11.
        temp11-path = path.
        temp11-descending = sorter-descending.
        INSERT temp11 INTO TABLE binding_sorters.
      ENDIF.
    ENDLOOP.

    
    sorter_list = ``.
    
    LOOP AT binding_sorters INTO binding_sorter.
      
      IF binding_sorter-descending = abap_true.
        temp12 = `true`.
      ELSE.
        temp12 = `false`.
      ENDIF.
      
      IF binding_sorter-group = abap_true.
        temp13 = `true`.
      ELSE.
        temp13 = `false`.
      ENDIF.
      sorter_list = |{ sorter_list }, \{ path: '{ binding_sorter-path }', | &&
                    |descending: { temp12 }, | &&
                    |group: { temp13 } \}|.
    ENDLOOP.

    result = |\{ path: '{ client->_bind( val = t_items path = abap_true ) }', | &&
             |sorter: [{ shift_left( val = sorter_list sub = `, ` ) }] \}|.

  ENDMETHOD.


  METHOD on_event.
          DATA temp14 TYPE string_table.
          DATA temp8 TYPE z2ui5_cl_smpc_app_645=>ty_t_sorter.
          DATA temp15 LIKE LINE OF temp8.
          DATA temp17 TYPE string_table.
          DATA temp9 TYPE z2ui5_cl_smpc_app_645=>ty_t_sorter.
          DATA entry LIKE LINE OF temp9.
        DATA temp19 TYPE z2ui5_cl_smpc_app_645=>ty_t_sorter.
          DATA temp20 TYPE z2ui5_cl_smpc_app_645=>ty_t_sorter.
          DATA temp21 LIKE LINE OF temp20.
          DATA temp1 TYPE xsdboolean.
        DATA temp22 TYPE string_table.
          DATA temp23 TYPE string_table.
        DATA temp25 LIKE sy-subrc.
          FIELD-SYMBOLS <temp26> LIKE LINE OF t_columns.
          DATA temp27 LIKE sy-tabix.

    CASE client->get_event( ).

      WHEN `OPEN_PERSO`.
        p13n_popup_display( ).

      WHEN `P13N_CLOSE`.
        " Engine.show( ) creates the popup per call and destroys it once closed;
        " the Engine applies the panel state on Ok only
        client->popup_destroy( ).
        IF client->get_event_arg( ) = `Ok`.
          
          CLEAR temp14.
          
          temp8 = p13n_entries( client->get_event_arg( 2 ) ).
          
          LOOP AT temp8 INTO temp15.
            INSERT temp15-key INTO TABLE temp14.
          ENDLOOP.
          apply_columns( temp14 ).
          t_sorters = p13n_entries( client->get_event_arg( 3 ) ).
          
          CLEAR temp17.
          
          temp9 = p13n_entries( client->get_event_arg( 4 ) ).
          
          LOOP AT temp9 INTO entry.
            INSERT entry-key INTO TABLE temp17.
          ENDLOOP.
          t_groups = temp17.
          view_display( ).
        ENDIF.

      WHEN `BEFORE_OPEN_MENU`.
        before_open_column_menu( ).

      WHEN `QUICK_SORT`.
        " onSort: every sorter cleared, the column's own order pushed unless None
        
        CLEAR temp19.
        t_sorters = temp19.
        IF client->get_event_arg( 2 ) <> `None`.
          
          CLEAR temp20.
          
          temp21-key = client->get_event_arg( ).
          
          temp1 = boolc( client->get_event_arg( 2 ) = `Descending` ).
          temp21-descending = temp1.
          INSERT temp21 INTO TABLE temp20.
          t_sorters = temp20.
        ENDIF.
        view_display( ).

      WHEN `QUICK_GROUP`.
        " onGroup: every grouping cleared, the column grouped if the item says so
        
        CLEAR temp22.
        t_groups = temp22.
        IF client->get_event_arg( 2 ) = abap_true.
          
          CLEAR temp23.
          INSERT client->get_event_arg( ) INTO TABLE temp23.
          t_groups = temp23.
        ENDIF.
        view_display( ).

      WHEN `COLUMN_MOVE`.
        move_column( ).
        view_display( ).

      WHEN `COLUMN_RESIZE`.
        " applyState( { ColumnWidth } ): the resizer has already sized the
        " column, the state keeps the width for the next rebuild
        
        READ TABLE t_columns WITH KEY key = client->get_event_arg( ) TRANSPORTING NO FIELDS.
        temp25 = sy-subrc.
        IF temp25 = 0.
          
          
          temp27 = sy-tabix.
          READ TABLE t_columns WITH KEY key = client->get_event_arg( ) ASSIGNING <temp26>.
          sy-tabix = temp27.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp26>-width = client->get_event_arg( 2 ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD p13n_popup_display.

    " the popup Engine.show( ) creates for the Columns, Sorter and Groups controllers
    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp28 TYPE string_table.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp28.
    INSERT `${$parameters>/reason}` INTO TABLE temp28.
    INSERT `$event.oSource.getPanels()[0].getP13nData(true)` INTO TABLE temp28.
    INSERT `$event.oSource.getPanels()[1].getP13nData(true)` INTO TABLE temp28.
    INSERT `$event.oSource.getPanels()[2].getP13nData(true)` INTO TABLE temp28.
    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`

        )->ele( n = `Popup` ns = `p13n`
            )->a( n = `id`    v = `p13nPopup`
            )->a( n = `close` v = client->_event( val   = `P13N_CLOSE`
                                                  t_arg = temp28 )

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

    client->popup_display( popup->stringify( ) ).

    " the fresh panels get the controllers' adaptation data
    set_p13n_data( ).

  ENDMETHOD.


  METHOD set_p13n_data.

    " the controllers' panel data (mixInfoAndState): the active entries in
    " state order, then the others sorted by label
    DATA by_label LIKE t_columns.
    DATA json TYPE string.
    DATA column LIKE LINE OF t_columns.
    DATA temp30 TYPE string_table.
    DATA temp10 LIKE LINE OF temp30.
    DATA sorter LIKE LINE OF t_sorters.
      DATA temp32 TYPE string.
      FIELD-SYMBOLS <temp11> LIKE LINE OF t_columns.
      DATA temp12 LIKE sy-tabix.
      DATA temp33 LIKE sy-subrc.
    DATA temp34 TYPE string_table.
    DATA temp13 LIKE LINE OF temp34.
    DATA group LIKE LINE OF t_groups.
      FIELD-SYMBOLS <temp36> LIKE LINE OF t_columns.
      DATA temp37 LIKE sy-tabix.
      DATA temp38 LIKE sy-subrc.
    DATA temp39 TYPE string_table.
    DATA temp14 LIKE LINE OF temp39.
    by_label = t_columns.
    SORT by_label BY label.

    
    json = ``.
    
    LOOP AT t_columns INTO column WHERE visible = abap_true.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":true\}|.
    ENDLOOP.
    LOOP AT by_label INTO column WHERE visible = abap_false.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":false\}|.
    ENDLOOP.
    
    CLEAR temp30.
    INSERT `columnsPanel` INTO TABLE temp30.
    INSERT `setP13nData` INTO TABLE temp30.
    
    temp10 = |[{ shift_left( val = json sub = `,` ) }]|.
    INSERT temp10 INTO TABLE temp30.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              view  = client->cs_view-popup
                              t_arg = temp30 ).

    json = ``.
    
    LOOP AT t_sorters INTO sorter.
      
      IF sorter-descending = abap_true.
        temp32 = `true`.
      ELSE.
        temp32 = `false`.
      ENDIF.
      
      
      temp12 = sy-tabix.
      READ TABLE t_columns WITH KEY key = sorter-key ASSIGNING <temp11>.
      sy-tabix = temp12.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      json = |{ json },\{"name":"{ sorter-key }","label":"{ <temp11>-label }","sorted":true,| &&
             |"descending":{ temp32 }\}|.
    ENDLOOP.
    LOOP AT by_label INTO column.
      
      READ TABLE t_sorters WITH KEY key = column-key TRANSPORTING NO FIELDS.
      temp33 = sy-subrc.
      IF NOT temp33 = 0.
        json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","sorted":false,"descending":false\}|.
      ENDIF.
    ENDLOOP.
    
    CLEAR temp34.
    INSERT `sortPanel` INTO TABLE temp34.
    INSERT `setP13nData` INTO TABLE temp34.
    
    temp13 = |[{ shift_left( val = json sub = `,` ) }]|.
    INSERT temp13 INTO TABLE temp34.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              view  = client->cs_view-popup
                              t_arg = temp34 ).

    json = ``.
    
    LOOP AT t_groups INTO group.
      
      
      temp37 = sy-tabix.
      READ TABLE t_columns WITH KEY key = group ASSIGNING <temp36>.
      sy-tabix = temp37.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      json = |{ json },\{"name":"{ group }","label":"{ <temp36>-label }","grouped":true\}|.
    ENDLOOP.
    LOOP AT by_label INTO column.
      
      READ TABLE t_groups WITH KEY table_line = column-key TRANSPORTING NO FIELDS.
      temp38 = sy-subrc.
      IF NOT temp38 = 0.
        json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","grouped":false\}|.
      ENDIF.
    ENDLOOP.
    
    CLEAR temp39.
    INSERT `groupPanel` INTO TABLE temp39.
    INSERT `setP13nData` INTO TABLE temp39.
    
    temp14 = |[{ shift_left( val = json sub = `,` ) }]|.
    INSERT temp14 INTO TABLE temp39.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              view  = client->cs_view-popup
                              t_arg = temp39 ).

  ENDMETHOD.


  METHOD before_open_column_menu.

    DATA temp41 TYPE ty_s_column.
    DATA temp42 TYPE z2ui5_cl_smpc_app_645=>ty_s_column.
    DATA column LIKE temp41.
    DATA temp43 TYPE ty_s_sorter.
    DATA temp44 TYPE z2ui5_cl_smpc_app_645=>ty_s_sorter.
    DATA sorter LIKE temp43.
    DATA temp45 TYPE string.
    DATA temp46 LIKE sy-subrc.
    DATA temp2 TYPE xsdboolean.
    CLEAR temp41.
    
    READ TABLE t_columns INTO temp42 WITH KEY key = client->get_event_arg( ).
    IF sy-subrc = 0.
      temp41 = temp42.
    ENDIF.
    
    column = temp41.
    IF column IS INITIAL.
      RETURN.
    ENDIF.
    
    CLEAR temp43.
    
    READ TABLE t_sorters INTO temp44 WITH KEY key = column-key.
    IF sy-subrc = 0.
      temp43 = temp44.
    ENDIF.
    
    sorter = temp43.

    quick_key       = column-key.
    quick_label     = column-label.
    
    IF sorter IS INITIAL.
      temp45 = `None`.
    ELSEIF sorter-descending = abap_true.
      temp45 = `Descending`.
    ELSE.
      temp45 = `Ascending`.
    ENDIF.
    quick_sortorder = temp45.
    
    READ TABLE t_groups WITH KEY table_line = column-key TRANSPORTING NO FIELDS.
    temp46 = sy-subrc.
    
    temp2 = boolc( temp46 = 0 ).
    quick_grouped   = temp2.

  ENDMETHOD.


  METHOD apply_columns.

    " updateColumns: every column hidden, then the state's columns shown and
    " moved to the front in state order
    DATA previous LIKE t_columns.
    DATA temp47 TYPE z2ui5_cl_smpc_app_645=>ty_t_column.
    DATA key LIKE LINE OF state.
      DATA column LIKE LINE OF previous.
      FIELD-SYMBOLS <temp15> LIKE LINE OF previous.
      DATA temp16 LIKE sy-tabix.
    previous = t_columns.
    
    CLEAR temp47.
    t_columns = temp47.
    
    LOOP AT state INTO key.
      
      
      
      temp16 = sy-tabix.
      READ TABLE previous WITH KEY key = key ASSIGNING <temp15>.
      sy-tabix = temp16.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      column = <temp15>.
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

    DATA dragged TYPE string.
    DATA dropped TYPE string.
    DATA temp48 LIKE sy-subrc.
    DATA temp17 LIKE sy-subrc.
    DATA dragged_index TYPE i.
    DATA temp18 LIKE sy-subrc.
    DATA dropped_index TYPE i.
    DATA temp19 LIKE sy-subrc.
    DATA temp49 TYPE i.
    DATA temp20 TYPE i.
    DATA new_pos TYPE i.
    DATA temp50 TYPE string_table.
    DATA c LIKE LINE OF t_columns.
    DATA state LIKE temp50.
    dragged = client->get_event_arg( ).
    
    dropped = client->get_event_arg( 2 ).
    
    READ TABLE t_columns WITH KEY key = dragged TRANSPORTING NO FIELDS.
    temp48 = sy-subrc.
    
    READ TABLE t_columns WITH KEY key = dropped TRANSPORTING NO FIELDS.
    temp17 = sy-subrc.
    IF dragged = dropped OR NOT temp48 = 0 OR NOT temp17 = 0.
      RETURN.
    ENDIF.

    " onColumnMove's position arithmetic, on 0-based column indices
    
    
    READ TABLE t_columns WITH KEY key = dragged TRANSPORTING NO FIELDS.
    temp18 = sy-tabix.
    dragged_index = temp18 - 1.
    
    
    READ TABLE t_columns WITH KEY key = dropped TRANSPORTING NO FIELDS.
    temp19 = sy-tabix.
    dropped_index = temp19 - 1.
    
    IF client->get_event_arg( 3 ) = `Before`.
      temp49 = 0.
    ELSE.
      temp49 = 1.
    ENDIF.
    
    IF dragged_index < dropped_index.
      temp20 = -1.
    ELSE.
      temp20 = 0.
    ENDIF.
    
    new_pos = dropped_index
                    + temp49
                    + temp20.

    " applyState( { Columns: [ { key, position } ] } ): the column moves to
    " that position of the visible columns and is shown
    
    CLEAR temp50.
    
    LOOP AT t_columns INTO c WHERE visible = abap_true AND key <> dragged.
      INSERT c-key INTO TABLE temp50.
    ENDLOOP.
    
    state = temp50.
    IF new_pos > lines( state ).
      new_pos = lines( state ).
    ENDIF.
    INSERT dragged INTO state INDEX new_pos + 1.
    apply_columns( state ).

  ENDMETHOD.


  METHOD p13n_entries.

    " getP13nData( true ) arrives as a JSON array of the panel's flat item
    " objects; collect their names (and a SortPanel item's direction) in order
    TYPES temp3 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA objects TYPE temp3.
    DATA object LIKE LINE OF objects.
      DATA offset TYPE i.
        DATA temp52 TYPE z2ui5_cl_smpc_app_645=>ty_s_sorter.
        DATA temp4 TYPE xsdboolean.
    SPLIT json AT `}` INTO TABLE objects.
    
    LOOP AT objects INTO object.
      
      offset = find( val = object sub = `"name":"` ).
      IF offset >= 0.
        
        CLEAR temp52.
        temp52-key = substring_before( val = substring( val = object off = offset + 8 ) sub = `"` ).
        
        temp4 = boolc( object CS `"descending":true` ).
        temp52-descending = temp4.
        INSERT temp52 INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    DATA temp53 LIKE t_items.
    DATA temp54 LIKE LINE OF temp53.
    DATA temp55 TYPE z2ui5_cl_smpc_app_645=>ty_t_column.
    DATA temp56 LIKE LINE OF temp55.
    CLEAR temp53.
    
    temp54-key = `P1`.
    temp54-firstname = `Peter`.
    temp54-lastname = `Mueller`.
    temp54-size = `1.75`.
    temp54-city = `Walldorf`.
    INSERT temp54 INTO TABLE temp53.
    temp54-key = `P2`.
    temp54-firstname = `Petra`.
    temp54-lastname = `Maier`.
    temp54-size = `1.85`.
    temp54-city = `Walldorf`.
    INSERT temp54 INTO TABLE temp53.
    temp54-key = `P3`.
    temp54-firstname = `Thomas`.
    temp54-lastname = `Smith`.
    temp54-size = `1.95`.
    temp54-city = `Heidelberg`.
    INSERT temp54 INTO TABLE temp53.
    temp54-key = `P4`.
    temp54-firstname = `John`.
    temp54-lastname = `Williams`.
    temp54-size = `1.65`.
    temp54-city = `Walldorf`.
    INSERT temp54 INTO TABLE temp53.
    temp54-key = `P5`.
    temp54-firstname = `Maria`.
    temp54-lastname = `Jones`.
    temp54-size = `1.55`.
    temp54-city = `Walldorf`.
    INSERT temp54 INTO TABLE temp53.
    t_items = temp53.

    " the columns of the view; label and path are the MetadataHelper's
    
    CLEAR temp55.
    
    temp56-key = `firstName_col`.
    temp56-label = `First Name`.
    temp56-path = `FIRSTNAME`.
    temp56-halign = ``.
    temp56-visible = abap_true.
    INSERT temp56 INTO TABLE temp55.
    temp56-key = `lastName_col`.
    temp56-label = `Last Name`.
    temp56-path = `LASTNAME`.
    temp56-halign = ``.
    temp56-visible = abap_true.
    INSERT temp56 INTO TABLE temp55.
    temp56-key = `city_col`.
    temp56-label = `City`.
    temp56-path = `CITY`.
    temp56-halign = ``.
    temp56-visible = abap_true.
    INSERT temp56 INTO TABLE temp55.
    temp56-key = `size_col`.
    temp56-label = `Size`.
    temp56-path = `SIZE`.
    temp56-halign = `End`.
    temp56-visible = abap_false.
    INSERT temp56 INTO TABLE temp55.
    t_columns = temp55.

    quick_sortorder = `None`.

  ENDMETHOD.

ENDCLASS.
