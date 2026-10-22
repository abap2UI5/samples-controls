" @keywords engine sap.m.p13n p13n.enginegridtable table overflowtoolbar title toolbarseparator toolbarspacer button menu illustratedmessage label
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
    TYPES temp1_82363bad2e TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
DATA t_items TYPE temp1_82363bad2e.

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
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH DEFAULT KEY.
    TYPES ty_t_sorter TYPE STANDARD TABLE OF ty_s_sorter WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    " the Engine state: Columns (order + visibility), ColumnWidth, Sorter
    DATA t_columns TYPE ty_t_column.
    DATA t_sorters TYPE ty_t_sorter.

    METHODS view_display.
    METHODS rows_binding
      RETURNING
        VALUE(result) TYPE string.
    METHODS on_event.
    METHODS p13n_popup_display.
    METHODS set_p13n_data.
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
    DATA temp1 TYPE string_table.
    DATA temp2 TYPE string_table.
    DATA temp5 TYPE string_table.
    DATA temp6 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA column LIKE LINE OF t_columns.
      DATA temp3 TYPE ty_s_sorter.
      DATA temp4 TYPE z2ui5_cl_smpc_app_648=>ty_s_sorter.
      DATA sorter LIKE temp3.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/column}.data('p13nKey')` INTO TABLE temp1.
    INSERT `${$parameters>/sortOrder}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$parameters>/column}.data('p13nKey')` INTO TABLE temp2.
    INSERT `${$parameters>/width}` INTO TABLE temp2.
    
    CLEAR temp5.
    INSERT `${$parameters>/column}.data('p13nKey')` INTO TABLE temp5.
    INSERT `${$parameters>/newPos}` INTO TABLE temp5.
    
    CLEAR temp6.
    temp6-check_prevent_default = abap_true.
    
    table = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.ui.table`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:m`   v = `sap.m`
        )->a( n = `xmlns:tcm` v = `sap.m.table.columnmenu`
        )->a( n = `xmlns:app` v = `http://schemas.sap.com/sapui5/extension/sap.ui.core.CustomData/1`
        )->a( n = `height`    v = `100%`

        )->ele( n = `Page` ns = `m`
            )->a( n = `showHeader` v = `false`

            " handleStateChange's getBinding( 'rows' ).sort( ), composed by the backend
            )->ele( `Table`
                )->a( n = `id`             v = `persoTable`
                )->a( n = `sort`           v = client->_event( val   = `SORT`
                                                               t_arg = temp1 )
                )->a( n = `columnResize`   v = client->_event( val   = `COLUMN_RESIZE`
                                                               t_arg = temp2 )
                " onColumnMove calls oEvt.preventDefault( ) and moves the column through the state
                )->a( n = `columnMove`     v = client->_event( val    = `COLUMN_MOVE`
                                                               t_arg  = temp5
                                                               s_ctrl = temp6 )
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
            )->a( n = `tableSettingsPressed`    v = client->_event( `OPEN_PERSO` ) ).

    table->ele( `noData`
        )->tag( n = `IllustratedMessage` ns = `m`
            )->a( n = `enableVerticalResponsiveness` v = `true` ).

    " handleStateChange re-orders, hides and sizes the columns and sets their
    " sort order; the port emits them in the order the state holds
    
    columns = table->ele( `columns` ).
    
    LOOP AT t_columns INTO column.
      
      CLEAR temp3.
      
      READ TABLE t_sorters INTO temp4 WITH KEY key = column-key.
      IF sy-subrc = 0.
        temp3 = temp4.
      ENDIF.
      
      sorter = temp3.
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

  ENDMETHOD.


  METHOD rows_binding.

    DATA sorter_list TYPE string.
    DATA sorter LIKE LINE OF t_sorters.
      DATA temp5 TYPE string.
      FIELD-SYMBOLS <temp6> LIKE LINE OF t_columns.
      DATA temp7 LIKE sy-tabix.
    sorter_list = ``.
    
    LOOP AT t_sorters INTO sorter.
      
      IF sorter-descending = abap_true.
        temp5 = `true`.
      ELSE.
        temp5 = `false`.
      ENDIF.
      
      
      temp7 = sy-tabix.
      READ TABLE t_columns WITH KEY key = sorter-key ASSIGNING <temp6>.
      sy-tabix = temp7.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      sorter_list = |{ sorter_list }, \{ path: '{ <temp6>-path }', | &&
                    |descending: { temp5 } \}|.
    ENDLOOP.

    result = |\{ path: '{ client->_bind( val = t_items path = abap_true ) }', | &&
             |sorter: [{ shift_left( val = sorter_list sub = `, ` ) }] \}|.

  ENDMETHOD.


  METHOD on_event.
          DATA temp6 TYPE string_table.
          DATA temp12 TYPE z2ui5_cl_smpc_app_648=>ty_t_sorter.
          DATA entry LIKE LINE OF temp12.
        DATA temp8 LIKE sy-subrc.
          DATA temp9 TYPE z2ui5_cl_smpc_app_648=>ty_t_sorter.
          DATA temp10 LIKE LINE OF temp9.
          DATA temp1 TYPE xsdboolean.
        DATA temp11 LIKE sy-subrc.
          FIELD-SYMBOLS <temp12> LIKE LINE OF t_columns.
          DATA temp13 LIKE sy-tabix.

    CASE client->get_event( ).

      WHEN `OPEN_PERSO`.
        p13n_popup_display( ).

      WHEN `P13N_CLOSE`.
        " Engine.show( ) creates the popup per call and destroys it once closed;
        " the Engine applies the panel state on Ok only
        client->popup_destroy( ).
        IF client->get_event_arg( ) = `Ok`.
          
          CLEAR temp6.
          
          temp12 = p13n_entries( client->get_event_arg( 2 ) ).
          
          LOOP AT temp12 INTO entry.
            INSERT entry-key INTO TABLE temp6.
          ENDLOOP.
          apply_columns( temp6 ).
          t_sorters = p13n_entries( client->get_event_arg( 3 ) ).
          view_display( ).
        ENDIF.

      WHEN `SORT`.
        " onSort: every sorter cleared, the column's own order pushed
        
        READ TABLE t_columns WITH KEY key = client->get_event_arg( ) TRANSPORTING NO FIELDS.
        temp8 = sy-subrc.
        IF temp8 = 0.
          
          CLEAR temp9.
          
          temp10-key = client->get_event_arg( ).
          
          temp1 = boolc( client->get_event_arg( 2 ) = `Descending` ).
          temp10-descending = temp1.
          INSERT temp10 INTO TABLE temp9.
          t_sorters = temp9.
          view_display( ).
        ENDIF.

      WHEN `COLUMN_MOVE`.
        move_column( ).
        view_display( ).

      WHEN `COLUMN_RESIZE`.
        " applyState( { ColumnWidth } ): the table has already sized the
        " column, the state keeps the width for the next rebuild
        
        READ TABLE t_columns WITH KEY key = client->get_event_arg( ) TRANSPORTING NO FIELDS.
        temp11 = sy-subrc.
        IF temp11 = 0.
          
          
          temp13 = sy-tabix.
          READ TABLE t_columns WITH KEY key = client->get_event_arg( ) ASSIGNING <temp12>.
          sy-tabix = temp13.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp12>-width = client->get_event_arg( 2 ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD p13n_popup_display.

    " the popup Engine.show( ) creates for the Columns and Sorter controllers
    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp14 TYPE string_table.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp14.
    INSERT `${$parameters>/reason}` INTO TABLE temp14.
    INSERT `$event.oSource.getPanels()[0].getP13nData(true)` INTO TABLE temp14.
    INSERT `$event.oSource.getPanels()[1].getP13nData(true)` INTO TABLE temp14.
    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`

        )->ele( n = `Popup` ns = `p13n`
            )->a( n = `id`    v = `p13nPopup`
            )->a( n = `close` v = client->_event( val   = `P13N_CLOSE`
                                                  t_arg = temp14 )

            )->ele( n = `panels` ns = `p13n`
                )->tag( n = `SelectionPanel` ns = `p13n`
                    )->a( n = `id`          v = `gridColumnsPanel`
                    )->a( n = `showHeader`  v = `true`
                    )->a( n = `enableCount` v = `true`
                )->tag( n = `SortPanel` ns = `p13n`
                    )->a( n = `id` v = `gridSortPanel` ).

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
    DATA temp16 TYPE string_table.
    DATA temp13 LIKE LINE OF temp16.
    DATA sorter LIKE LINE OF t_sorters.
      DATA temp18 TYPE string.
      FIELD-SYMBOLS <temp14> LIKE LINE OF t_columns.
      DATA temp15 LIKE sy-tabix.
      DATA temp19 LIKE sy-subrc.
    DATA temp20 TYPE string_table.
    DATA temp17 LIKE LINE OF temp20.
    by_label = t_columns.
    SORT by_label BY label.

    
    json = ``.
    
    LOOP AT t_columns INTO column WHERE visible = abap_true.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":true\}|.
    ENDLOOP.
    LOOP AT by_label INTO column WHERE visible = abap_false.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":false\}|.
    ENDLOOP.
    
    CLEAR temp16.
    INSERT `gridColumnsPanel` INTO TABLE temp16.
    INSERT `setP13nData` INTO TABLE temp16.
    
    temp13 = |[{ shift_left( val = json sub = `,` ) }]|.
    INSERT temp13 INTO TABLE temp16.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              view  = client->cs_view-popup
                              t_arg = temp16 ).

    json = ``.
    
    LOOP AT t_sorters INTO sorter.
      
      IF sorter-descending = abap_true.
        temp18 = `true`.
      ELSE.
        temp18 = `false`.
      ENDIF.
      
      
      temp15 = sy-tabix.
      READ TABLE t_columns WITH KEY key = sorter-key ASSIGNING <temp14>.
      sy-tabix = temp15.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      json = |{ json },\{"name":"{ sorter-key }","label":"{ <temp14>-label }","sorted":true,| &&
             |"descending":{ temp18 }\}|.
    ENDLOOP.
    LOOP AT by_label INTO column.
      
      READ TABLE t_sorters WITH KEY key = column-key TRANSPORTING NO FIELDS.
      temp19 = sy-subrc.
      IF NOT temp19 = 0.
        json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","sorted":false,"descending":false\}|.
      ENDIF.
    ENDLOOP.
    
    CLEAR temp20.
    INSERT `gridSortPanel` INTO TABLE temp20.
    INSERT `setP13nData` INTO TABLE temp20.
    
    temp17 = |[{ shift_left( val = json sub = `,` ) }]|.
    INSERT temp17 INTO TABLE temp20.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              view  = client->cs_view-popup
                              t_arg = temp20 ).

  ENDMETHOD.


  METHOD apply_columns.

    " handleStateChange: every column hidden, then the state's columns shown
    " and moved to the front in state order
    DATA previous LIKE t_columns.
    DATA temp22 TYPE z2ui5_cl_smpc_app_648=>ty_t_column.
    DATA key LIKE LINE OF state.
      DATA column LIKE LINE OF previous.
      FIELD-SYMBOLS <temp18> LIKE LINE OF previous.
      DATA temp19 LIKE sy-tabix.
    previous = t_columns.
    
    CLEAR temp22.
    t_columns = temp22.
    
    LOOP AT state INTO key.
      
      
      
      temp19 = sy-tabix.
      READ TABLE previous WITH KEY key = key ASSIGNING <temp18>.
      sy-tabix = temp19.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      column = <temp18>.
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

    DATA moved TYPE string.
    DATA temp23 LIKE sy-subrc.
    DATA temp24 TYPE i.
    DATA new_pos LIKE temp24.
    DATA temp25 TYPE string_table.
    DATA c LIKE LINE OF t_columns.
    DATA state LIKE temp25.
    moved = client->get_event_arg( ).
    
    READ TABLE t_columns WITH KEY key = moved TRANSPORTING NO FIELDS.
    temp23 = sy-subrc.
    IF NOT temp23 = 0.
      RETURN.
    ENDIF.

    " applyState( { Columns: [ { key, position: newPos } ] } ): the column
    " moves to that position of the visible columns and is shown
    
    temp24 = client->get_event_arg( 2 ).
    
    new_pos = temp24.
    
    CLEAR temp25.
    
    LOOP AT t_columns INTO c WHERE visible = abap_true AND key <> moved.
      INSERT c-key INTO TABLE temp25.
    ENDLOOP.
    
    state = temp25.
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
    TYPES temp2 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA objects TYPE temp2.
    DATA object LIKE LINE OF objects.
      DATA offset TYPE i.
        DATA temp27 TYPE z2ui5_cl_smpc_app_648=>ty_s_sorter.
        DATA temp3 TYPE xsdboolean.
    SPLIT json AT `}` INTO TABLE objects.
    
    LOOP AT objects INTO object.
      
      offset = find( val = object sub = `"name":"` ).
      IF offset >= 0.
        
        CLEAR temp27.
        temp27-key = substring_before( val = substring( val = object off = offset + 8 ) sub = `"` ).
        
        temp3 = boolc( object CS `"descending":true` ).
        temp27-descending = temp3.
        INSERT temp27 INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    DATA temp28 LIKE t_items.
    DATA temp29 LIKE LINE OF temp28.
    DATA temp30 TYPE z2ui5_cl_smpc_app_648=>ty_t_column.
    DATA temp31 LIKE LINE OF temp30.
    CLEAR temp28.
    
    temp29-firstname = `Peter`.
    temp29-lastname = `Mueller`.
    temp29-size = `1.75`.
    temp29-city = `Walldorf`.
    INSERT temp29 INTO TABLE temp28.
    temp29-firstname = `Petra`.
    temp29-lastname = `Maier`.
    temp29-size = `1.85`.
    temp29-city = `Walldorf`.
    INSERT temp29 INTO TABLE temp28.
    temp29-firstname = `Thomas`.
    temp29-lastname = `Smith`.
    temp29-size = `1.95`.
    temp29-city = `Heidelberg`.
    INSERT temp29 INTO TABLE temp28.
    temp29-firstname = `John`.
    temp29-lastname = `Williams`.
    temp29-size = `1.65`.
    temp29-city = `Walldorf`.
    INSERT temp29 INTO TABLE temp28.
    temp29-firstname = `Maria`.
    temp29-lastname = `Jones`.
    temp29-size = `1.55`.
    temp29-city = `Walldorf`.
    INSERT temp29 INTO TABLE temp28.
    t_items = temp28.

    " the columns of the view; label and path are the MetadataHelper's, the
    " width the controller's _mIntialWidth
    
    CLEAR temp30.
    
    temp31-key = `firstName_col`.
    temp31-label = `First Name`.
    temp31-path = `FIRSTNAME`.
    temp31-visible = abap_true.
    temp31-width = `11rem`.
    INSERT temp31 INTO TABLE temp30.
    temp31-key = `lastName_col`.
    temp31-label = `Last Name`.
    temp31-path = `LASTNAME`.
    temp31-visible = abap_true.
    temp31-width = `11rem`.
    INSERT temp31 INTO TABLE temp30.
    temp31-key = `city_col`.
    temp31-label = `City`.
    temp31-path = `CITY`.
    temp31-visible = abap_true.
    temp31-width = `11rem`.
    INSERT temp31 INTO TABLE temp30.
    temp31-key = `size_col`.
    temp31-label = `Size`.
    temp31-path = `SIZE`.
    temp31-visible = abap_false.
    temp31-width = `11rem`.
    INSERT temp31 INTO TABLE temp30.
    t_columns = temp30.

  ENDMETHOD.

ENDCLASS.
