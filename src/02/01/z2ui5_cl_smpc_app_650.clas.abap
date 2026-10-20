" @keywords popup sap.m.p13n p13n.popup vbox button selectionpanel sortpanel grouppanel codeeditor
" @summary Dialog with sap.m.p13n/* Panels
" @origin sap.m.sample.p13n.Popup - https://sdk.openui5.org/entity/sap.m.p13n.Popup/sample/sap.m.sample.p13n.Popup (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_650 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA editor_value TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA p13n_columns TYPE string.
    DATA p13n_sort TYPE string.
    DATA p13n_group TYPE string.

    METHODS view_display.
    METHODS on_event.
    METHODS set_initial_data.
    METHODS parse_p13n_state.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_650 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

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
                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` )
                                                                                       ( `show` )
                                                                                       ( `Dialog close reason: {0}` )
                                                                                       ( `${$parameters>/reason}` ) ) )
                )->a( n = `warningText` v = `Are you sure?`
                )->a( n = `open`        v = client->_event(
                    val   = `POPUP_OPEN`
                    t_arg = VALUE #(
                        ( `$event.oSource ? JSON.stringify($event.oSource.getPanels()[0].getP13nData(), null, '  ') : ''` )
                        ( `$event.oSource ? JSON.stringify($event.oSource.getPanels()[1].getP13nData(), null, '  ') : ''` )
                        ( `$event.oSource ? JSON.stringify($event.oSource.getPanels()[2].getP13nData(), null, '  ') : ''` ) ) )

                )->ele( n = `panels` ns = `p13n`
                    )->tag( n = `SelectionPanel` ns = `p13n`
                        )->a( n = `id`          v = `columnsPanel`
                        )->a( n = `title`       v = `Columns`
                        )->a( n = `enableCount` v = `true`
                        )->a( n = `showHeader`  v = `true`
                        )->a( n = `change`      v = client->_event(
                            val   = `COLUMNS_CHANGE`
                            t_arg = VALUE #(
                                ( `${$parameters>/reason}` )
                                ( `$event.oSource ? JSON.stringify($event.oSource.getP13nData(), null, '  ') : ''` ) ) )
                    )->tag( n = `SortPanel` ns = `p13n`
                        )->a( n = `id`     v = `sortPanel`
                        )->a( n = `title`  v = `Sort`
                        )->a( n = `change` v = client->_event(
                            val   = `SORT_CHANGE`
                            t_arg = VALUE #(
                                ( `${$parameters>/reason}` )
                                ( `$event.oSource ? JSON.stringify($event.oSource.getP13nData(), null, '  ') : ''` ) ) )
                    )->tag( n = `GroupPanel` ns = `p13n`
                        )->a( n = `id`     v = `groupPanel`
                        )->a( n = `title`  v = `Group`
                        )->a( n = `change` v = client->_event(
                            val   = `GROUP_CHANGE`
                            t_arg = VALUE #(
                                ( `${$parameters>/reason}` )
                                ( `$event.oSource ? JSON.stringify($event.oSource.getP13nData(), null, '  ') : ''` ) ) )

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

    CASE client->get_event( ).

      WHEN `OPEN`.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `p13nPopup` ) ( `open` ) ) ).

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
    client->follow_up_action(
        val   = client->cs_event-control_by_id
        t_arg = VALUE #( ( `columnsPanel` )
                         ( `setP13nData` )
                         ( `[{"visible":true,"name":"key1","label":"City"},` &&
                           `{"visible":false,"name":"key2","label":"Country"},` &&
                           `{"visible":false,"name":"key3","label":"Region"}]` ) ) ).
    client->follow_up_action(
        val   = client->cs_event-control_by_id
        t_arg = VALUE #( ( `sortPanel` )
                         ( `setP13nData` )
                         ( `[{"sorted":true,"name":"key1","label":"City","descending":true},` &&
                           `{"sorted":false,"name":"key2","label":"Country","descending":false},` &&
                           `{"sorted":false,"name":"key3","label":"Region","descending":false}]` ) ) ).
    client->follow_up_action(
        val   = client->cs_event-control_by_id
        t_arg = VALUE #( ( `groupPanel` )
                         ( `setP13nData` )
                         ( `[{"grouped":true,"name":"key1","label":"City"},` &&
                           `{"grouped":false,"name":"key2","label":"Country"},` &&
                           `{"grouped":false,"name":"key3","label":"Region"}]` ) ) ).

  ENDMETHOD.


  METHOD parse_p13n_state.

    client->message_toast_display( |P13n panel change reason:{ client->get_event_arg( ) }| ).

    " JSON.stringify( { columns, sort, group }, null, '  ' ): each panel array
    " arrives stringified with the same indent and is nested one level deeper
    DATA(columns) = replace( val = p13n_columns sub = |\n| with = |\n  | occ = 0 ).
    DATA(sort)    = replace( val = p13n_sort    sub = |\n| with = |\n  | occ = 0 ).
    DATA(group)   = replace( val = p13n_group   sub = |\n| with = |\n  | occ = 0 ).

    editor_value = |\{\n  "columns": { columns },\n  "sort": { sort },\n  "group": { group }\n\}|.

  ENDMETHOD.

ENDCLASS.
