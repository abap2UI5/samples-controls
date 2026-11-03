" @keywords dynamicdaterange dynamic date range sap.m dynamicdaterangehidden title vbox label button link
" @summary This example shows Dynamic Date Range which is opened by another control.
" @origin sap.m.sample.DynamicDateRangeHidden - https://sdk.openui5.org/entity/sap.m.DynamicDateRange/sample/sap.m.sample.DynamicDateRangeHidden (status: generated - machine-written, not yet reviewed)
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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `HiddenDDR` INTO TABLE temp1.
    INSERT `openBy` INTO TABLE temp1.
    INSERT `$event.oSource.sId` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `HiddenDDR` INTO TABLE temp2.
    INSERT `openBy` INTO TABLE temp2.
    INSERT `$event.oSource.sId` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `HiddenDDR` INTO TABLE temp3.
    INSERT `openBy` INTO TABLE temp3.
    INSERT `$event.oSource.sId` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `${$parameters>/value/operator}` INTO TABLE temp4.
    INSERT `${$parameters>/value/values}.length` INTO TABLE temp4.
    INSERT `${$parameters>/value/values/0} + ''` INTO TABLE temp4.
    INSERT `${$parameters>/value/values/1} + ''` INTO TABLE temp4.
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
                )->a( n = `press`        v = client->follow_up_action( val = client->cs_event-control_by_id t_arg = temp1 )

        )->end(
        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->tag( `Label`
                )->a( n = `text` v = `By Button with icon`
            )->tag( `Button`
                )->a( n = `ariaHasPopup` v = `Dialog`
                )->a( n = `tooltip`      v = `Open Dynamic Date Range`
                )->a( n = `icon`         v = `sap-icon://check-availability`
                )->a( n = `press`        v = client->follow_up_action( val = client->cs_event-control_by_id t_arg = temp2 )

        )->end(
        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->tag( `Label`
                )->a( n = `text` v = `By Link`
            )->tag( `Link`
                )->a( n = `ariaHasPopup` v = `Dialog`
                )->a( n = `text`         v = `Open Dynamic Date Range`
                )->a( n = `press`        v = client->follow_up_action( val = client->cs_event-control_by_id t_arg = temp3 )

        )->end(
        " the values travel as the original's string concatenation renders them (a Date as its toString)
        )->tag( `DynamicDateRange`
            )->a( n = `id`        v = `HiddenDDR`
            )->a( n = `hideInput` v = `true`
            )->a( n = `change`    v = client->_event( val   = `CHANGE`
                                                      t_arg = temp4 ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
      DATA output TYPE string.
      DATA temp3 TYPE i.
      DATA count LIKE temp3.

    IF client->get_event( ) = `CHANGE`.
      " changeDateHandler - the toast text is composed here, one line per value
      
      output = |\nOperator: { client->get_event_arg( ) }|.
      
      temp3 = client->get_event_arg( 2 ).
      
      count = temp3.
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
