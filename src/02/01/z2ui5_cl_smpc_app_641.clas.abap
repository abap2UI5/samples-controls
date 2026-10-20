CLASS z2ui5_cl_smpc_app_641 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_641 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->tag( `Title`
            )->a( n = `class` v = `sapUiSmallMargin`
            )->a( n = `text`  v = `Open Dynamic Date Range by Another Control`

        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->tag( `Label`
                )->a( n = `text` v = `By Button with text`
            )->tag( `Button`
                )->a( n = `ariaHasPopup` v = `Dialog`
                )->a( n = `text`         v = `Open Dynamic Date Range`
                )->a( n = `press`        v = client->follow_up_action( val = client->cs_event-control_by_id t_arg = VALUE #( ( `HiddenDDR` ) ( `openBy` ) ( `$event.oSource.sId` ) ) )

        )->end(
        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->tag( `Label`
                )->a( n = `text` v = `By Button with icon`
            )->tag( `Button`
                )->a( n = `ariaHasPopup` v = `Dialog`
                )->a( n = `tooltip`      v = `Open Dynamic Date Range`
                )->a( n = `icon`         v = `sap-icon://check-availability`
                )->a( n = `press`        v = client->follow_up_action( val = client->cs_event-control_by_id t_arg = VALUE #( ( `HiddenDDR` ) ( `openBy` ) ( `$event.oSource.sId` ) ) )

        )->end(
        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->tag( `Label`
                )->a( n = `text` v = `By Link`
            )->tag( `Link`
                )->a( n = `ariaHasPopup` v = `Dialog`
                )->a( n = `text`         v = `Open Dynamic Date Range`
                )->a( n = `press`        v = client->follow_up_action( val = client->cs_event-control_by_id t_arg = VALUE #( ( `HiddenDDR` ) ( `openBy` ) ( `$event.oSource.sId` ) ) )

        )->end(
        " the values travel as the original's string concatenation renders them (a Date as its toString)
        )->tag( `DynamicDateRange`
            )->a( n = `id`        v = `HiddenDDR`
            )->a( n = `hideInput` v = `true`
            )->a( n = `change`    v = client->_event( val   = `CHANGE`
                                                      t_arg = VALUE #( ( `${$parameters>/value/operator}` )
                                                                       ( `${$parameters>/value/values}.length` )
                                                                       ( `${$parameters>/value/values/0} + ''` )
                                                                       ( `${$parameters>/value/values/1} + ''` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `CHANGE`.
      " changeDateHandler - the toast text is composed here, one line per value
      DATA(output) = |\nOperator: { client->get_event_arg( ) }|.
      DATA(count) = CONV i( client->get_event_arg( 2 ) ).
      IF count >= 1.
        output = |{ output }\nValue 1: { client->get_event_arg( 3 ) }|.
      ENDIF.
      IF count >= 2.
        output = |{ output }\nValue 2: { client->get_event_arg( 4 ) }|.
      ENDIF.
      client->message_toast_display( |Selected: \n{ output }| ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
