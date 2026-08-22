" @keywords colorpickerpopover color picker popover sap.ui.unified table column text columnlistitem label input
" @summary Example of ColorPicker in a popover using the thin wrapper control sap.ui.unified.ColorPickerPopover.
CLASS z2ui5_cl_smpc_app_268 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA color_d          TYPE string.
    DATA color_l          TYPE string.
    DATA color_s          TYPE string.
    DATA color_lc         TYPE string.
    DATA live_change_text TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_268 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
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
    DATA temp6 TYPE string_table.
    DATA temp7 TYPE string_table.
    DATA temp8 TYPE string_table.
    DATA temp9 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    " The controller creates one ColorPickerPopover per display mode lazily and
    " opens it with openBy(input). abap2UI5 declares all four up front in the
    " view's dependents and opens them roundtrip-free via control_by_id/openBy
    " anchored to the pressed Input ($event.oSource.sId) - the anchored-open
    " idiom of apps 016/060. Each popover's change/liveChange round-trips so
    " the backend can write the value into the Input (handleChange) and the
    " liveChange Text, exactly like the controller does.
    
    CLEAR temp1.
    INSERT `${$parameters>/colorString}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$parameters>/colorString}` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `${$parameters>/colorString}` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `${$parameters>/colorString}` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `${$parameters>/colorString}` INTO TABLE temp5.
    
    CLEAR temp6.
    INSERT `oColorPickerPopover` INTO TABLE temp6.
    INSERT `openBy` INTO TABLE temp6.
    INSERT `$event.oSource.sId` INTO TABLE temp6.
    
    CLEAR temp7.
    INSERT `oColorPickerLargePopover` INTO TABLE temp7.
    INSERT `openBy` INTO TABLE temp7.
    INSERT `$event.oSource.sId` INTO TABLE temp7.
    
    CLEAR temp8.
    INSERT `oColorPickerSimpplifiedPopover` INTO TABLE temp8.
    INSERT `openBy` INTO TABLE temp8.
    INSERT `$event.oSource.sId` INTO TABLE temp8.
    
    CLEAR temp9.
    INSERT `oColorPickerLiveChangePopover` INTO TABLE temp9.
    INSERT `openBy` INTO TABLE temp9.
    INSERT `$event.oSource.sId` INTO TABLE temp9.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`   v = `sap.ui.unified`

        )->ele( `Table`
            )->a( n = `id`         v = `samplesTable`
            )->a( n = `headerText` v = `Color Picker in a Popover`
            )->a( n = `class`      v = `sapUiLargeMarginBottom`

            )->ele( `dependents`
                )->tag( n = `ColorPickerPopover` ns = `u`
                    )->a( n = `id`          v = `oColorPickerPopover`
                    )->a( n = `colorString` v = `blue`
                    )->a( n = `mode`        v = `HSL`
                    )->a( n = `change`      v = client->_event( val   = `CHANGE_D`
                                                                t_arg = temp1 )
                )->tag( n = `ColorPickerPopover` ns = `u`
                    )->a( n = `id`          v = `oColorPickerLargePopover`
                    )->a( n = `colorString` v = `green`
                    )->a( n = `displayMode` v = `Large`
                    )->a( n = `mode`        v = `HSL`
                    )->a( n = `change`      v = client->_event( val   = `CHANGE_L`
                                                                t_arg = temp2 )
                )->tag( n = `ColorPickerPopover` ns = `u`
                    )->a( n = `id`          v = `oColorPickerSimpplifiedPopover`
                    )->a( n = `colorString` v = `pink`
                    )->a( n = `displayMode` v = `Simplified`
                    )->a( n = `mode`        v = `HSL`
                    )->a( n = `change`      v = client->_event( val   = `CHANGE_S`
                                                                t_arg = temp3 )
                )->tag( n = `ColorPickerPopover` ns = `u`
                    )->a( n = `id`          v = `oColorPickerLiveChangePopover`
                    )->a( n = `colorString` v = `orange`
                    )->a( n = `displayMode` v = `Large`
                    )->a( n = `mode`        v = `HSL`
                    )->a( n = `change`      v = client->_event( val   = `CHANGE_LC`
                                                                t_arg = temp4 )
                    )->a( n = `liveChange`  v = client->_event( val   = `LIVE_CHANGE`
                                                                t_arg = temp5 )

            )->end(

            )->ele( `columns`
                )->ele( `Column`
                    )->a( n = `width` v = `30%`

                    )->tag( `Text`
                        )->a( n = `text` v = `Description`

                )->end(

                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Click 'Value help' icon to select color`

                )->end(

                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Value from liveChange event`

                )->end(
            )->end(

            )->ele( `ColumnListItem`
                )->ele( `cells`
                    )->tag( `Label`
                        )->a( n = `text` v = `Default displayMode`
                    )->tag( `Input`
                        )->a( n = `id`               v = `colorD`
                        )->a( n = `type`             v = `Text`
                        )->a( n = `width`            v = `200px`
                        )->a( n = `placeholder`      v = `Enter Color ...`
                        )->a( n = `showValueHelp`    v = `true`
                        )->a( n = `value`            v = client->_bind( color_d )
                        )->a( n = `valueHelpRequest` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                   t_arg = temp6 )

                )->end(
            )->end(

            )->ele( `ColumnListItem`
                )->ele( `cells`
                    )->tag( `Label`
                        )->a( n = `text` v = `Large displayMode`
                    )->tag( `Input`
                        )->a( n = `id`               v = `colorL`
                        )->a( n = `type`             v = `Text`
                        )->a( n = `width`            v = `200px`
                        )->a( n = `placeholder`      v = `Enter Color ...`
                        )->a( n = `showValueHelp`    v = `true`
                        )->a( n = `value`            v = client->_bind( color_l )
                        )->a( n = `valueHelpRequest` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                   t_arg = temp7 )

                )->end(
            )->end(

            )->ele( `ColumnListItem`
                )->ele( `cells`
                    )->tag( `Label`
                        )->a( n = `text` v = `Simplified displayMode`
                    )->tag( `Input`
                        )->a( n = `id`               v = `colorS`
                        )->a( n = `type`             v = `Text`
                        )->a( n = `width`            v = `200px`
                        )->a( n = `placeholder`      v = `Enter Color ...`
                        )->a( n = `showValueHelp`    v = `true`
                        )->a( n = `value`            v = client->_bind( color_s )
                        )->a( n = `valueHelpRequest` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                   t_arg = temp8 )

                )->end(
            )->end(

            )->ele( `ColumnListItem`
                )->ele( `cells`
                    )->tag( `Label`
                        )->a( n = `text` v = `With liveChange`
                    )->tag( `Input`
                        )->a( n = `id`               v = `colorLC`
                        )->a( n = `type`             v = `Text`
                        )->a( n = `width`            v = `200px`
                        )->a( n = `placeholder`      v = `Enter Color ...`
                        )->a( n = `showValueHelp`    v = `true`
                        )->a( n = `value`            v = client->_bind( color_lc )
                        )->a( n = `valueHelpRequest` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                   t_arg = temp9 )
                    )->tag( `Text`
                        )->a( n = `id`   v = `liveChangeText`
                        )->a( n = `text` v = client->_bind( live_change_text )

                        ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
        " handleChange: write the chosen color string into the Input the popover
        " was opened from and toast it. The original tracks that Input in
        " this.inputId; here each popover has its own event, so the target is
        " known statically.
      WHEN `CHANGE_D`.
        color_d = client->get_event_arg( ).
        client->message_toast_display( |Chosen color string: { color_d }| ).

      WHEN `CHANGE_L`.
        color_l = client->get_event_arg( ).
        client->message_toast_display( |Chosen color string: { color_l }| ).

      WHEN `CHANGE_S`.
        color_s = client->get_event_arg( ).
        client->message_toast_display( |Chosen color string: { color_s }| ).

      WHEN `CHANGE_LC`.
        color_lc = client->get_event_arg( ).
        client->message_toast_display( |Chosen color string: { color_lc }| ).

      WHEN `LIVE_CHANGE`.
        " handleLiveChange: the Text under the last Input follows the picker
        live_change_text = client->get_event_arg( ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
