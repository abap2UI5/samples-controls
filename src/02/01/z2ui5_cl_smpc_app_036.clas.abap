" @keywords messagebox message box sap.m shows set initial focus verticallayout text button
" @summary Shows how to set initial focus to MessageBox button.
" @origin sap.m.sample.MessageBoxInitialFocus - https://sdk.openui5.org/entity/sap.m.MessageBox/sample/sap.m.sample.MessageBoxInitialFocus (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_036 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_036 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `id`    v = `messageBoxHost`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Text`
                )->a( n = `text` v = `Different approaches to set Initial focus`

            )->tag( `Button`
                )->a( n = `text`         v = `Action`
                )->a( n = `class`        v = `sapUiSmallMarginBottom`
                )->a( n = `press`        v = client->_event( `INITIAL_FOCUS_ON_ACTION` )
                )->a( n = `width`        v = `250px`
                )->a( n = `ariaHasPopup` v = `Dialog`

            )->tag( `Button`
                )->a( n = `text`         v = `Custom action`
                )->a( n = `class`        v = `sapUiSmallMarginBottom`
                )->a( n = `press`        v = client->_event( `INITIAL_FOCUS_ON_CUSTOM_ACTION` )
                )->a( n = `width`        v = `250px`
                )->a( n = `ariaHasPopup` v = `Dialog` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp1 TYPE string_table.
        DATA temp2 LIKE LINE OF temp1.
        DATA temp4 LIKE LINE OF temp1.
        DATA temp3 TYPE string_table.
        DATA temp5 LIKE LINE OF temp3.
        DATA temp6 LIKE LINE OF temp3.

    CASE client->get_event( ).

      WHEN `INITIAL_FOCUS_ON_ACTION`.

        " icon and dependentOn are sap.m.MessageBox options, so the whole box
        " is opened as the control it is: the global call takes the box type as
        " its method and the UI5 option object as its last argument.
        " dependentOn ties the box to the view's layout lifecycle (original:
        " this.getView())
        
        CLEAR temp1.
        INSERT `MESSAGE_BOX` INTO TABLE temp1.
        INSERT `warning` INTO TABLE temp1.
        
        temp2 = |Initial button focus is set by attribute \n initialFocus: sap.m.MessageBox.Action.CANCEL|.
        INSERT temp2 INTO TABLE temp1.
        
        temp4 = `{"icon":"WARNING","title":"Focus on a Button","actions":["OK","CANCEL"],` && `"emphasizedAction":"OK","initialFocus":"CANCEL","dependentOn":"messageBoxHost",` && `"styleClass":"sapUiResponsivePadding--header sapUiResponsivePadding--content sapUiResponsivePadding--footer"}`.
        INSERT temp4 INTO TABLE temp1.
        client->follow_up_action(
            val   = client->cs_event-control_global
            t_arg = temp1 ).

      WHEN `INITIAL_FOCUS_ON_CUSTOM_ACTION`.

        " icon and dependentOn as above
        
        CLEAR temp3.
        INSERT `MESSAGE_BOX` INTO TABLE temp3.
        INSERT `show` INTO TABLE temp3.
        
        temp5 = |Initial button focus is set by attribute \n initialFocus: "Custom button" \n Note: The name is not case sensitive|.
        INSERT temp5 INTO TABLE temp3.
        
        temp6 = `{"icon":"WARNING","title":"Focus on a Custom Action","actions":["YES","NO","Custom Action"],` && `"emphasizedAction":"Custom Action","initialFocus":"Custom Action","dependentOn":"messageBoxHost",` && `"styleClass":"sapUiResponsivePadding--header sapUiResponsivePadding--content sapUiResponsivePadding--footer"}`.
        INSERT temp6 INTO TABLE temp3.
        client->follow_up_action(
            val   = client->cs_event-control_global
            t_arg = temp3 ).

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
