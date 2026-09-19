" @keywords inputmodelupdate input model update sap.m late binding app vbox text button
" @summary The sample demonstrates how to rebind a control to a different data source after a certain delay.
" @origin sap.m.sample.InputModelUpdate - https://sdk.openui5.org/entity/sap.m.InputModelUpdate/sample/sap.m.sample.InputModelUpdate (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_102 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA currentvalue TYPE string VALUE `Martin`.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA initial_value TYPE string VALUE `Martin`.

    METHODS view_display.
    METHODS on_event.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_102 IMPLEMENTATION.

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
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    temp1-check_queue_last = abap_true.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`

        )->ele( `App`
            )->ele( `Page`
                )->a( n = `title` v = `Late binding of Input (oData v2)`

                )->ele( `VBox`
                    )->tag( `Text`
                        )->a( n = `class` v = `sapUiSmallMarginBottom`
                        )->a( n = `text`  v = `For more details about this sample code and its intended use case, please refer to the description and comments provided within the code.`
                    )->tag( `Input`
                        )->a( n = `id`         v = `inputArtistName`
                        )->a( n = `value`      v = client->_bind( currentvalue )
                        )->a( n = `liveChange` v = client->_event( val = `LIVE_CHANGE` s_ctrl = temp1 )
                    )->tag( `Button`
                        )->a( n = `press` v = client->_event( `REBIND` )
                        )->a( n = `text`  v = `Bind Input in 3 seconds` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp2 TYPE string_table.

    CASE client->get_event( ).

      WHEN `REBIND`.
        " original fnRebind: after ~3s (the OData dataReceived) late-bind the input
        
        CLEAR temp2.
        INSERT `REBIND_DONE` INTO TABLE temp2.
        INSERT `3000` INTO TABLE temp2.
        client->follow_up_action( val   = client->cs_event-start_timer
                                  t_arg = temp2 ).

      WHEN `REBIND_DONE`.
        " original dataReceived: if the input is still untouched, bind it to Employees(1)/FirstName
        IF currentvalue = initial_value.
          currentvalue = `Nancy`.
        ENDIF.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
