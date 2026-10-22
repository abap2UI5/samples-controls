" @keywords popup sap.m.p13n p13n.popup vbox button selectionpanel sortpanel grouppanel codeeditor
" @summary Dialog with sap.m.p13n/* Panels
" @origin sap.m.sample.p13n.Popup - https://sdk.openui5.org/entity/sap.m.p13n.Popup/sample/sap.m.sample.p13n.Popup (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_650 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA editor_value TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " the three panels' getP13nData( ), last seen per panel, as JSON arrays
    DATA p13n_columns TYPE string.
    DATA p13n_sort TYPE string.
    DATA p13n_group TYPE string.

    METHODS view_display.
    METHODS on_event.
    METHODS set_initial_data.
    METHODS parse_p13n_state.
    METHODS p13n_json
      IMPORTING
        json          TYPE string
        t_key         TYPE string_table
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_650 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ) IS NOT INITIAL.
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
    DATA temp4 TYPE string_table.
    DATA temp5 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `MESSAGE_TOAST` INTO TABLE temp1.
    INSERT `show` INTO TABLE temp1.
    INSERT `Dialog close reason: {0}` INTO TABLE temp1.
    INSERT `${$parameters>/reason}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `$event.oSource.getPanels()[0].getP13nData()` INTO TABLE temp2.
    INSERT `$event.oSource.getPanels()[1].getP13nData()` INTO TABLE temp2.
    INSERT `$event.oSource.getPanels()[2].getP13nData()` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `${$parameters>/reason}` INTO TABLE temp3.
    INSERT `$event.oSource.getP13nData()` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `${$parameters>/reason}` INTO TABLE temp4.
    INSERT `$event.oSource.getP13nData()` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `${$parameters>/reason}` INTO TABLE temp5.
    INSERT `$event.oSource.getP13nData()` INTO TABLE temp5.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`
        )->a( n = `xmlns:ce`   v = `sap.ui.codeeditor`
        )->a( n = `height`     v = `100%`
        )->a( n = `class`      v = `sapUiContentPadding`

        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->tag( `Button`
                )->a( n = `id`    v = `openBtn`
                )->a( n = `text`  v = `Show p13n.Popup`
                )->a( n = `press` v = client->_event( `OPEN` )

            " reset is a function-typed property (the controller's reset callback)
            " no backend wire can fill, so the Reset button stays away
            )->ele( n = `Popup` ns = `p13n`
                )->a( n = `id`          v = `p13nPopup`
                )->a( n = `title`       v = `My Custom View Settings`
                )->a( n = `close`       v = client->follow_up_action( val   = client->cs_event-control_global
                                                                      t_arg = temp1 )
                )->a( n = `warningText` v = `Are you sure?`
                )->a( n = `open`        v = client->_event( val   = `POPUP_OPEN`
                                                            t_arg = temp2 )

                )->ele( n = `panels` ns = `p13n`
                    )->tag( n = `SelectionPanel` ns = `p13n`
                        )->a( n = `id`          v = `columnsPanel`
                        )->a( n = `title`       v = `Columns`
                        )->a( n = `enableCount` v = `true`
                        )->a( n = `showHeader`  v = `true`
                        )->a( n = `change`      v = client->_event( val   = `COLUMNS_CHANGE`
                                                                    t_arg = temp3 )
                    )->tag( n = `SortPanel` ns = `p13n`
                        )->a( n = `id`     v = `sortPanel`
                        )->a( n = `title`  v = `Sort`
                        )->a( n = `change` v = client->_event( val   = `SORT_CHANGE`
                                                               t_arg = temp4 )
                    )->tag( n = `GroupPanel` ns = `p13n`
                        )->a( n = `id`     v = `groupPanel`
                        )->a( n = `title`  v = `Group`
                        )->a( n = `change` v = client->_event( val   = `GROUP_CHANGE`
                                                               t_arg = temp5 )

                )->end(
            )->end(

            )->tag( n = `CodeEditor` ns = `ce`
                )->a( n = `id`     v = `p13nEditor`
                )->a( n = `class`  v = `sapUiSmallMargin`
                )->a( n = `height` v = `50rem`
                )->a( n = `value`  v = client->_bind( editor_value ) ).

    client->view_display( view->stringify( ) ).

    " the original seeds the panels once, on the first open (_bIsOpen); a
    " rebuilt view carries fresh, empty panels, so they are seeded per render
    set_initial_data( ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string_table.

    CASE client->get_event( ).

      WHEN `OPEN`.
        
        CLEAR temp3.
        INSERT `p13nPopup` INTO TABLE temp3.
        INSERT `open` INTO TABLE temp3.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp3 ).

      WHEN `POPUP_OPEN`.
        " what the three panels hold right now, for the state shown in the editor
        p13n_columns = client->get_event_arg( ).
        p13n_sort    = client->get_event_arg( 2 ).
        p13n_group   = client->get_event_arg( 3 ).

      WHEN `COLUMNS_CHANGE`.
        p13n_columns = client->get_event_arg( 2 ).
        parse_p13n_state( ).

      WHEN `SORT_CHANGE`.
        p13n_sort = client->get_event_arg( 2 ).
        parse_p13n_state( ).

      WHEN `GROUP_CHANGE`.
        p13n_group = client->get_event_arg( 2 ).
        parse_p13n_state( ).

    ENDCASE.

  ENDMETHOD.


  METHOD set_initial_data.

    " _initialData of the original controller, handed to setP13nData( ) as JSON
    DATA temp5 TYPE string_table.
    DATA temp4 LIKE LINE OF temp5.
    DATA temp7 TYPE string_table.
    DATA temp6 LIKE LINE OF temp7.
    DATA temp9 TYPE string_table.
    DATA temp8 LIKE LINE OF temp9.
    CLEAR temp5.
    INSERT `columnsPanel` INTO TABLE temp5.
    INSERT `setP13nData` INTO TABLE temp5.
    
    temp4 = `[{"visible":true,"name":"key1","label":"City"},` && `{"visible":false,"name":"key2","label":"Country"},` && `{"visible":false,"name":"key3","label":"Region"}]`.
    INSERT temp4 INTO TABLE temp5.
    client->follow_up_action(
        val   = client->cs_event-control_by_id
        t_arg = temp5 ).
    
    CLEAR temp7.
    INSERT `sortPanel` INTO TABLE temp7.
    INSERT `setP13nData` INTO TABLE temp7.
    
    temp6 = `[{"sorted":true,"name":"key1","label":"City","descending":true},` && `{"sorted":false,"name":"key2","label":"Country","descending":false},` && `{"sorted":false,"name":"key3","label":"Region","descending":false}]`.
    INSERT temp6 INTO TABLE temp7.
    client->follow_up_action(
        val   = client->cs_event-control_by_id
        t_arg = temp7 ).
    
    CLEAR temp9.
    INSERT `groupPanel` INTO TABLE temp9.
    INSERT `setP13nData` INTO TABLE temp9.
    
    temp8 = `[{"grouped":true,"name":"key1","label":"City"},` && `{"grouped":false,"name":"key2","label":"Country"},` && `{"grouped":false,"name":"key3","label":"Region"}]`.
    INSERT temp8 INTO TABLE temp9.
    client->follow_up_action(
        val   = client->cs_event-control_by_id
        t_arg = temp9 ).

  ENDMETHOD.


  METHOD parse_p13n_state.
    DATA temp11 TYPE string_table.
    DATA columns TYPE string.
    DATA temp13 TYPE string_table.
    DATA sort TYPE string.
    DATA temp15 TYPE string_table.
    DATA group TYPE string.

    client->message_toast_display( |P13n panel change reason:{ client->get_event_arg( ) }| ).

    " JSON.stringify( { columns, sort, group }, null, '  ' ), each panel's
    " items with their keys in the order _initialData gives them
    
    CLEAR temp11.
    INSERT `visible` INTO TABLE temp11.
    INSERT `name` INTO TABLE temp11.
    INSERT `label` INTO TABLE temp11.
    
    columns = p13n_json( json = p13n_columns t_key = temp11 ).
    
    CLEAR temp13.
    INSERT `sorted` INTO TABLE temp13.
    INSERT `name` INTO TABLE temp13.
    INSERT `label` INTO TABLE temp13.
    INSERT `descending` INTO TABLE temp13.
    
    sort    = p13n_json( json = p13n_sort t_key = temp13 ).
    
    CLEAR temp15.
    INSERT `grouped` INTO TABLE temp15.
    INSERT `name` INTO TABLE temp15.
    INSERT `label` INTO TABLE temp15.
    
    group   = p13n_json( json = p13n_group t_key = temp15 ).

    editor_value = |\{\n  "columns": { columns },\n  "sort": { sort },\n  "group": { group }\n\}|.

  ENDMETHOD.


  METHOD p13n_json.

    " getP13nData( ) arrives as a compact JSON array of flat objects whose
    " values hold no comma, brace or quote; print it the way JSON.stringify
    " indents it one level deep
    DATA t_object TYPE string_table.

    DATA t_part TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA part LIKE LINE OF t_part.
      DATA temp17 TYPE string_table.
      DATA t_line LIKE temp17.
      DATA key LIKE LINE OF t_key.
        DATA offset TYPE i.
          DATA value TYPE string.
          DATA temp18 LIKE LINE OF t_line.
        DATA temp19 LIKE LINE OF t_object.
    SPLIT json AT `}` INTO TABLE t_part.
    
    LOOP AT t_part INTO part.
      
      CLEAR temp17.
      
      t_line = temp17.
      
      LOOP AT t_key INTO key.
        
        offset = find( val = part sub = |"{ key }":| ).
        IF offset >= 0.
          
          value = substring( val = part off = offset + strlen( key ) + 3 ).
          
          temp18 = |      "{ key }": { segment( val = value index = 1 sep = `,` ) }|.
          INSERT temp18 INTO TABLE t_line.
        ENDIF.
      ENDLOOP.
      IF t_line IS NOT INITIAL.
        
        temp19 = |    \{\n{ concat_lines_of( table = t_line sep = |,\n| ) }\n    \}|.
        INSERT temp19 INTO TABLE t_object.
      ENDIF.
    ENDLOOP.

    IF t_object IS INITIAL.
      result = `[]`.
    ELSE.
      result = |[\n{ concat_lines_of( table = t_object sep = |,\n| ) }\n  ]|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
