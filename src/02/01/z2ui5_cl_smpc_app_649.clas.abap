" @keywords engine sap.m.p13n p13n.enginemultiplecontroller table overflowtoolbar title toolbarseparator toolbarspacer button menu actionitem dragdropinfo
" @summary Personalization for Reponsive Table using multiple SelectionControllers
" @origin sap.m.sample.p13n.EngineMultipleController - https://sdk.openui5.org/entity/sap.m.p13n.Engine/sample/sap.m.sample.p13n.EngineMultipleController (status: generated - machine-written, not yet reviewed)
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
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH DEFAULT KEY.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    " the table's columns and items in their current order, each with its visibility
    DATA t_columns TYPE ty_t_column.
    DATA t_rows TYPE ty_t_row.

    METHODS view_display.
    METHODS on_event.
    METHODS columns_popup_display.
    METHODS set_columns_p13n_data.
    METHODS rows_popup_display.
    METHODS set_rows_p13n_data.
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
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA column LIKE LINE OF t_columns.
      DATA column_node TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA row LIKE LINE OF t_rows.
      DATA item TYPE REF TO z2ui5_cl_ui5_view_builder.
        DATA temp3 TYPE string.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    table = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:tcm` v = `sap.m.table.columnmenu`
        )->a( n = `xmlns:dnd` v = `sap.ui.core.dnd`
        )->a( n = `xmlns:app` v = `http://schemas.sap.com/sapui5/extension/sap.ui.core.CustomData/1`
        )->a( n = `height`    v = `100%`

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
                    )->a( n = `press` v = client->_event( `OPEN_COLUMNS` ) ).

    
    CLEAR temp1.
    INSERT `${$parameters>/draggedControl}.data('p13nKey')` INTO TABLE temp1.
    INSERT `${$parameters>/droppedControl}.data('p13nKey')` INTO TABLE temp1.
    INSERT `${$parameters>/dropPosition}` INTO TABLE temp1.
    table->ele( `dragDropConfig`
        )->tag( n = `DragDropInfo` ns = `dnd`
            )->a( n = `sourceAggregation` v = `columns`
            )->a( n = `targetAggregation` v = `columns`
            )->a( n = `dropPosition`      v = `Between`
            )->a( n = `drop`              v = client->_event( val   = `COLUMN_MOVE`
                                                              t_arg = temp1 ) ).

    table->ele( `noData`
        )->tag( `IllustratedMessage` ).

    " handleStateChange re-orders and hides columns and items; the port emits
    " them in the order the state holds, the cells following their columns
    
    columns = table->ele( `columns` ).
    
    LOOP AT t_columns INTO column.
      
      column_node = columns->ele( `Column`
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

    
    items = table->ele( `items` ).
    
    LOOP AT t_rows INTO row.
      
      item = items->ele( `ColumnListItem`
          )->a( n = `app:p13nKey` t = row-key
          )->a( n = `visible`     b = row-visible ).
      LOOP AT t_columns INTO column.
        
        CASE column-key.
          WHEN `id_col`.
            temp3 = row-id.
          WHEN `firstName_col`.
            temp3 = row-firstname.
          WHEN `lastName_col`.
            temp3 = row-lastname.
          WHEN `city_col`.
            temp3 = row-city.
          WHEN OTHERS.
            temp3 = row-size.
        ENDCASE.
        item->tag( `Text`
            )->a( n = `text` t = temp3 ).
      ENDLOOP.
    ENDLOOP.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `OPEN_COLUMNS`.
        columns_popup_display( ).

      WHEN `OPEN_ROWS`.
        rows_popup_display( ).

      WHEN `COLUMNS_CLOSE`.
        " Engine.show( ) creates the popup per call and destroys it once closed;
        " the Engine applies the panel state on Ok only
        client->popup_destroy( ).
        IF client->get_event_arg( ) = `Ok`.
          apply_columns( p13n_names( client->get_event_arg( 2 ) ) ).
          view_display( ).
        ENDIF.

      WHEN `ROWS_CLOSE`.
        client->popup_destroy( ).
        IF client->get_event_arg( ) = `Ok`.
          apply_rows( p13n_names( client->get_event_arg( 2 ) ) ).
          view_display( ).
        ENDIF.

      WHEN `COLUMN_MOVE`.
        move_column( ).
        view_display( ).

    ENDCASE.

  ENDMETHOD.


  METHOD columns_popup_display.

    " the popup Engine.show( ) creates for the Columns controller
    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp4 TYPE string_table.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp4.
    INSERT `${$parameters>/reason}` INTO TABLE temp4.
    INSERT `$event.oSource.getPanels()[0].getP13nData(true)` INTO TABLE temp4.
    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`

        )->ele( n = `Popup` ns = `p13n`
            )->a( n = `id`    v = `columnsPopup`
            )->a( n = `close` v = client->_event( val   = `COLUMNS_CLOSE`
                                                  t_arg = temp4 )

            )->ele( n = `panels` ns = `p13n`
                )->tag( n = `SelectionPanel` ns = `p13n`
                    )->a( n = `id`          v = `tableColumnsPanel`
                    )->a( n = `showHeader`  v = `true`
                    )->a( n = `enableCount` v = `true` ).

    client->popup_display( popup->stringify( ) ).

    " the fresh panels get the controllers' adaptation data
    set_columns_p13n_data( ).

  ENDMETHOD.


  METHOD set_columns_p13n_data.

    " the SelectionController's panel data: the visible entries in state
    " order, then the hidden ones sorted by label
    DATA json TYPE string.
    DATA column LIKE LINE OF t_columns.
    DATA temp6 TYPE ty_t_column.
    DATA c LIKE LINE OF t_columns.
    DATA hidden_columns LIKE temp6.
    DATA temp8 TYPE string_table.
    DATA temp1 LIKE LINE OF temp8.
    json = ``.
    
    LOOP AT t_columns INTO column WHERE visible = abap_true.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":true\}|.
    ENDLOOP.
    
    CLEAR temp6.
    
    LOOP AT t_columns INTO c WHERE visible = abap_false.
      INSERT c INTO TABLE temp6.
    ENDLOOP.
    
    hidden_columns = temp6.
    SORT hidden_columns BY label.
    LOOP AT hidden_columns INTO column.
      json = |{ json },\{"name":"{ column-key }","label":"{ column-label }","visible":false\}|.
    ENDLOOP.
    
    CLEAR temp8.
    INSERT `tableColumnsPanel` INTO TABLE temp8.
    INSERT `setP13nData` INTO TABLE temp8.
    
    temp1 = |[{ shift_left( val = json sub = `,` ) }]|.
    INSERT temp1 INTO TABLE temp8.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              view  = client->cs_view-popup
                              t_arg = temp8 ).

  ENDMETHOD.


  METHOD rows_popup_display.

    " the popup Engine.show( ) creates for the Rows controller
    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp10 TYPE string_table.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp10.
    INSERT `${$parameters>/reason}` INTO TABLE temp10.
    INSERT `$event.oSource.getPanels()[0].getP13nData(true)` INTO TABLE temp10.
    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`

        )->ele( n = `Popup` ns = `p13n`
            )->a( n = `id`    v = `rowsPopup`
            )->a( n = `close` v = client->_event( val   = `ROWS_CLOSE`
                                                  t_arg = temp10 )

            )->ele( n = `panels` ns = `p13n`
                )->tag( n = `SelectionPanel` ns = `p13n`
                    )->a( n = `id`            v = `rowsPanel`
                    )->a( n = `showHeader`    v = `true`
                    )->a( n = `enableCount`   v = `true`
                    )->a( n = `enableReorder` v = `false` ).

    client->popup_display( popup->stringify( ) ).

    " the fresh panels get the controllers' adaptation data
    set_rows_p13n_data( ).

  ENDMETHOD.


  METHOD set_rows_p13n_data.

    " the Rows controller's panel data: the visible entries in state order,
    " then the hidden ones sorted by label
    DATA json TYPE string.
    DATA row LIKE LINE OF t_rows.
    DATA temp12 TYPE ty_t_row.
    DATA r LIKE LINE OF t_rows.
    DATA hidden_rows LIKE temp12.
    DATA temp14 TYPE string_table.
    DATA temp2 LIKE LINE OF temp14.
    json = ``.
    
    LOOP AT t_rows INTO row WHERE visible = abap_true.
      json = |{ json },\{"name":"{ row-key }","label":"{ row-label }","visible":true\}|.
    ENDLOOP.
    
    CLEAR temp12.
    
    LOOP AT t_rows INTO r WHERE visible = abap_false.
      INSERT r INTO TABLE temp12.
    ENDLOOP.
    
    hidden_rows = temp12.
    SORT hidden_rows BY label.
    LOOP AT hidden_rows INTO row.
      json = |{ json },\{"name":"{ row-key }","label":"{ row-label }","visible":false\}|.
    ENDLOOP.
    
    CLEAR temp14.
    INSERT `rowsPanel` INTO TABLE temp14.
    INSERT `setP13nData` INTO TABLE temp14.
    
    temp2 = |[{ shift_left( val = json sub = `,` ) }]|.
    INSERT temp2 INTO TABLE temp14.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              view  = client->cs_view-popup
                              t_arg = temp14 ).

  ENDMETHOD.


  METHOD apply_columns.

    " like handleStateChange: every column hidden, then the state's columns
    " shown and moved to the front in state order
    DATA previous LIKE t_columns.
    DATA temp16 TYPE z2ui5_cl_smpc_app_649=>ty_t_column.
    DATA key LIKE LINE OF state.
      DATA column LIKE LINE OF previous.
      FIELD-SYMBOLS <temp3> LIKE LINE OF previous.
      DATA temp4 LIKE sy-tabix.
    previous = t_columns.
    
    CLEAR temp16.
    t_columns = temp16.
    
    LOOP AT state INTO key.
      
      
      
      temp4 = sy-tabix.
      READ TABLE previous WITH KEY key = key ASSIGNING <temp3>.
      sy-tabix = temp4.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      column = <temp3>.
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

    DATA previous LIKE t_rows.
    DATA temp17 TYPE z2ui5_cl_smpc_app_649=>ty_t_row.
    DATA key LIKE LINE OF state.
      DATA row LIKE LINE OF previous.
      FIELD-SYMBOLS <temp5> LIKE LINE OF previous.
      DATA temp6 LIKE sy-tabix.
    previous = t_rows.
    
    CLEAR temp17.
    t_rows = temp17.
    
    LOOP AT state INTO key.
      
      
      
      temp6 = sy-tabix.
      READ TABLE previous WITH KEY key = key ASSIGNING <temp5>.
      sy-tabix = temp6.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      row = <temp5>.
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

    DATA dragged TYPE string.
    DATA dropped TYPE string.
    DATA temp18 LIKE sy-subrc.
    DATA temp7 LIKE sy-subrc.
    DATA dragged_index TYPE i.
    DATA temp8 LIKE sy-subrc.
    DATA dropped_index TYPE i.
    DATA temp9 LIKE sy-subrc.
    DATA temp19 TYPE i.
    DATA temp10 TYPE i.
    DATA new_pos TYPE i.
    DATA temp20 TYPE string_table.
    DATA c LIKE LINE OF t_columns.
    DATA state LIKE temp20.
    dragged = client->get_event_arg( ).
    
    dropped = client->get_event_arg( 2 ).
    
    READ TABLE t_columns WITH KEY key = dragged TRANSPORTING NO FIELDS.
    temp18 = sy-subrc.
    
    READ TABLE t_columns WITH KEY key = dropped TRANSPORTING NO FIELDS.
    temp7 = sy-subrc.
    IF dragged = dropped OR NOT temp18 = 0 OR NOT temp7 = 0.
      RETURN.
    ENDIF.

    " onColumnMove's position arithmetic, on 0-based column indices
    
    
    READ TABLE t_columns WITH KEY key = dragged TRANSPORTING NO FIELDS.
    temp8 = sy-tabix.
    dragged_index = temp8 - 1.
    
    
    READ TABLE t_columns WITH KEY key = dropped TRANSPORTING NO FIELDS.
    temp9 = sy-tabix.
    dropped_index = temp9 - 1.
    
    IF client->get_event_arg( 3 ) = `Before`.
      temp19 = 0.
    ELSE.
      temp19 = 1.
    ENDIF.
    
    IF dragged_index < dropped_index.
      temp10 = -1.
    ELSE.
      temp10 = 0.
    ENDIF.
    
    new_pos = dropped_index
                    + temp19
                    + temp10.

    " applyState( { Columns: [ { key, position } ] } ): the column moves to
    " that position of the visible columns and is shown
    
    CLEAR temp20.
    
    LOOP AT t_columns INTO c WHERE visible = abap_true AND key <> dragged.
      INSERT c-key INTO TABLE temp20.
    ENDLOOP.
    
    state = temp20.
    IF new_pos > lines( state ).
      new_pos = lines( state ).
    ENDIF.
    INSERT dragged INTO state INDEX new_pos + 1.
    apply_columns( state ).

  ENDMETHOD.


  METHOD p13n_names.

    " getP13nData( true ) arrives as a JSON array of the panel's flat item
    " objects; collect their names in order
    DATA objects TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA object LIKE LINE OF objects.
      DATA offset TYPE i.
    SPLIT json AT `}` INTO TABLE objects.
    
    LOOP AT objects INTO object.
      
      offset = find( val = object sub = `"name":"` ).
      IF offset >= 0.
        INSERT substring_before( val = substring( val = object off = offset + 8 ) sub = `"` ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    " the columns of the view; the labels are the MetadataHelper's
    DATA temp22 TYPE z2ui5_cl_smpc_app_649=>ty_t_column.
    DATA temp23 LIKE LINE OF temp22.
    DATA temp24 TYPE z2ui5_cl_smpc_app_649=>ty_t_row.
    DATA temp25 LIKE LINE OF temp24.
    CLEAR temp22.
    
    temp23-key = `id_col`.
    temp23-label = `ID`.
    temp23-halign = ``.
    temp23-visible = abap_true.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `firstName_col`.
    temp23-label = `First Name`.
    temp23-halign = ``.
    temp23-visible = abap_true.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `lastName_col`.
    temp23-label = `Last Name`.
    temp23-halign = ``.
    temp23-visible = abap_true.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `city_col`.
    temp23-label = `City`.
    temp23-halign = ``.
    temp23-visible = abap_true.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `size_col`.
    temp23-label = `Size`.
    temp23-halign = `End`.
    temp23-visible = abap_false.
    INSERT temp23 INTO TABLE temp22.
    t_columns = temp22.

    " the static items of the view; the labels are the rows' MetadataHelper's
    
    CLEAR temp24.
    
    temp25-key = `P1`.
    temp25-label = `Peter Müller`.
    temp25-id = `P1`.
    temp25-firstname = `Peter`.
    temp25-lastname = `Mueller`.
    temp25-city = `Walldorf`.
    temp25-size = `1.75`.
    temp25-visible = abap_true.
    INSERT temp25 INTO TABLE temp24.
    temp25-key = `P2`.
    temp25-label = `Petra Maier`.
    temp25-id = `P2`.
    temp25-firstname = `Petra`.
    temp25-lastname = `Maier`.
    temp25-city = `Walldorf`.
    temp25-size = `1.85`.
    temp25-visible = abap_true.
    INSERT temp25 INTO TABLE temp24.
    temp25-key = `P3`.
    temp25-label = `Thomas Smith`.
    temp25-id = `P3`.
    temp25-firstname = `Thomas`.
    temp25-lastname = `Smith`.
    temp25-city = `Walldorf`.
    temp25-size = `1.95`.
    temp25-visible = abap_true.
    INSERT temp25 INTO TABLE temp24.
    temp25-key = `P4`.
    temp25-label = `John Williams`.
    temp25-id = `P4`.
    temp25-firstname = `John`.
    temp25-lastname = `Williams`.
    temp25-city = `Walldorf`.
    temp25-size = `1.65`.
    temp25-visible = abap_true.
    INSERT temp25 INTO TABLE temp24.
    temp25-key = `P5`.
    temp25-label = `Maria Jones`.
    temp25-id = `P5`.
    temp25-firstname = `Maria`.
    temp25-lastname = `Jones`.
    temp25-city = `Walldorf`.
    temp25-size = `1.55`.
    temp25-visible = abap_true.
    INSERT temp25 INTO TABLE temp24.
    t_rows = temp24.

  ENDMETHOD.

ENDCLASS.
