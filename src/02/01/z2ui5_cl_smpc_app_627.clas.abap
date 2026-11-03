" @keywords avatar sap.m avatarvaluestate scrollcontainer grid vbox text
" @summary This sample demonstrates different badge value states of the Avatar.
" @origin sap.m.sample.AvatarValueState - https://sdk.openui5.org/entity/sap.m.Avatar/sample/sap.m.sample.AvatarValueState (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_627 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA gettyimages     TYPE string.
    DATA lowshutterstock TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_627 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
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

    " original onPress: MessageToast.show( source.getId() + ' Pressed' ) - client-composed, roundtrip-free
    
    CLEAR temp1.
    INSERT `MESSAGE_TOAST` INTO TABLE temp1.
    INSERT `show` INTO TABLE temp1.
    INSERT `{0} Pressed` INTO TABLE temp1.
    INSERT `$event.oSource.sId` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `MESSAGE_TOAST` INTO TABLE temp2.
    INSERT `show` INTO TABLE temp2.
    INSERT `{0} Pressed` INTO TABLE temp2.
    INSERT `$event.oSource.sId` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `MESSAGE_TOAST` INTO TABLE temp3.
    INSERT `show` INTO TABLE temp3.
    INSERT `{0} Pressed` INTO TABLE temp3.
    INSERT `$event.oSource.sId` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `MESSAGE_TOAST` INTO TABLE temp4.
    INSERT `show` INTO TABLE temp4.
    INSERT `{0} Pressed` INTO TABLE temp4.
    INSERT `$event.oSource.sId` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `MESSAGE_TOAST` INTO TABLE temp5.
    INSERT `show` INTO TABLE temp5.
    INSERT `{0} Pressed` INTO TABLE temp5.
    INSERT `$event.oSource.sId` INTO TABLE temp5.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `height`    v = `100%`

        )->ele( `ScrollContainer`
            )->a( n = `height`     v = `100%`
            )->a( n = `width`      v = `100%`
            )->a( n = `horizontal` v = `false`
            )->a( n = `vertical`   v = `true`

            )->ele( n = `Grid` ns = `l`
                )->a( n = `class`       v = `sapUiSmallMarginTop`
                )->a( n = `defaultSpan` v = `XL3 L3 M6 S12`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`             v = client->_bind( gettyimages )
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `imageFitType`    v = `Cover`
                            )->a( n = `badgeValueState` v = `Warning`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp1 )
                            )->a( n = `badgeIcon`       v = `sap-icon://alert`
                            )->a( n = `badgeTooltip`    v = `Sabine Mayer`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `badgeValueState property set to 'Warning'`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `displayShape`    v = `Circle`
                            )->a( n = `badgeValueState` v = `Information`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp2 )
                            )->a( n = `src`             v = client->_bind( lowshutterstock )
                            )->a( n = `badgeIcon`       v = `sap-icon://information`
                            )->a( n = `badgeTooltip`    v = `Julie Armstrong`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `badgeValueState property set to 'Information'`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `backgroundColor` v = `Accent7`
                            )->a( n = `initials`        v = `JD`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp3 )
                            )->a( n = `badgeValueState` v = `None`
                            )->a( n = `badgeIcon`       v = `sap-icon://camera`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `badgeValueState property set to 'None'`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `backgroundColor` v = `Accent3`
                            )->a( n = `badgeValueState` v = `Success`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp4 )
                            )->a( n = `badgeIcon`       v = `sap-icon://message-success`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `badgeValueState property set to 'Success'`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `badgeValueState` v = `Error`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp5 )
                            )->a( n = `badgeIcon`       v = `sap-icon://message-error`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `badgeValueState property set to 'Error'`
                            )->a( n = `class`     v = `sapUiSmallMarginTop` ).


    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " onInit's JSONModel - sap.ui.require.toUrl( 'sap/m/images/...' ), absolutized to the OpenUI5 host
    gettyimages     = `https://sdk.openui5.org/test-resources/sap/m/images/284133_GettyImages-145058106_2600.jpg`.
    lowshutterstock = `https://sdk.openui5.org/test-resources/sap/m/images/282627_low_shutterstock_402830878.jpg`.

  ENDMETHOD.

ENDCLASS.
