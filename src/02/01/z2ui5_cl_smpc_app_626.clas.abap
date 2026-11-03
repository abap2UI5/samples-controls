" @keywords avatar sap.m avatarbadgeiconcolor scrollcontainer text grid vbox
" @summary This sample demonstrates different badge icon colors of the Avatar.
" @origin sap.m.sample.AvatarBadgeIconColor - https://sdk.openui5.org/entity/sap.m.Avatar/sample/sap.m.sample.AvatarBadgeIconColor (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_626 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_626 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ) IS NOT INITIAL.
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
    DATA temp6 TYPE string_table.
    DATA temp7 TYPE string_table.
    DATA temp8 TYPE string_table.
    DATA temp9 TYPE string_table.
    DATA temp10 TYPE string_table.
    DATA temp11 TYPE string_table.
    DATA temp12 TYPE string_table.
    DATA temp13 TYPE string_table.
    DATA temp14 TYPE string_table.
    DATA temp15 TYPE string_table.
    DATA temp16 TYPE string_table.
    DATA temp17 TYPE string_table.
    DATA temp18 TYPE string_table.
    DATA temp19 TYPE string_table.
    DATA temp20 TYPE string_table.
    DATA temp21 TYPE string_table.
    DATA temp22 TYPE string_table.
    DATA temp23 TYPE string_table.
    DATA temp24 TYPE string_table.
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
    
    CLEAR temp6.
    INSERT `MESSAGE_TOAST` INTO TABLE temp6.
    INSERT `show` INTO TABLE temp6.
    INSERT `{0} Pressed` INTO TABLE temp6.
    INSERT `$event.oSource.sId` INTO TABLE temp6.
    
    CLEAR temp7.
    INSERT `MESSAGE_TOAST` INTO TABLE temp7.
    INSERT `show` INTO TABLE temp7.
    INSERT `{0} Pressed` INTO TABLE temp7.
    INSERT `$event.oSource.sId` INTO TABLE temp7.
    
    CLEAR temp8.
    INSERT `MESSAGE_TOAST` INTO TABLE temp8.
    INSERT `show` INTO TABLE temp8.
    INSERT `{0} Pressed` INTO TABLE temp8.
    INSERT `$event.oSource.sId` INTO TABLE temp8.
    
    CLEAR temp9.
    INSERT `MESSAGE_TOAST` INTO TABLE temp9.
    INSERT `show` INTO TABLE temp9.
    INSERT `{0} Pressed` INTO TABLE temp9.
    INSERT `$event.oSource.sId` INTO TABLE temp9.
    
    CLEAR temp10.
    INSERT `MESSAGE_TOAST` INTO TABLE temp10.
    INSERT `show` INTO TABLE temp10.
    INSERT `{0} Pressed` INTO TABLE temp10.
    INSERT `$event.oSource.sId` INTO TABLE temp10.
    
    CLEAR temp11.
    INSERT `MESSAGE_TOAST` INTO TABLE temp11.
    INSERT `show` INTO TABLE temp11.
    INSERT `{0} Pressed` INTO TABLE temp11.
    INSERT `$event.oSource.sId` INTO TABLE temp11.
    
    CLEAR temp12.
    INSERT `MESSAGE_TOAST` INTO TABLE temp12.
    INSERT `show` INTO TABLE temp12.
    INSERT `{0} Pressed` INTO TABLE temp12.
    INSERT `$event.oSource.sId` INTO TABLE temp12.
    
    CLEAR temp13.
    INSERT `MESSAGE_TOAST` INTO TABLE temp13.
    INSERT `show` INTO TABLE temp13.
    INSERT `{0} Pressed` INTO TABLE temp13.
    INSERT `$event.oSource.sId` INTO TABLE temp13.
    
    CLEAR temp14.
    INSERT `MESSAGE_TOAST` INTO TABLE temp14.
    INSERT `show` INTO TABLE temp14.
    INSERT `{0} Pressed` INTO TABLE temp14.
    INSERT `$event.oSource.sId` INTO TABLE temp14.
    
    CLEAR temp15.
    INSERT `MESSAGE_TOAST` INTO TABLE temp15.
    INSERT `show` INTO TABLE temp15.
    INSERT `{0} Pressed` INTO TABLE temp15.
    INSERT `$event.oSource.sId` INTO TABLE temp15.
    
    CLEAR temp16.
    INSERT `MESSAGE_TOAST` INTO TABLE temp16.
    INSERT `show` INTO TABLE temp16.
    INSERT `{0} Pressed` INTO TABLE temp16.
    INSERT `$event.oSource.sId` INTO TABLE temp16.
    
    CLEAR temp17.
    INSERT `MESSAGE_TOAST` INTO TABLE temp17.
    INSERT `show` INTO TABLE temp17.
    INSERT `{0} Pressed` INTO TABLE temp17.
    INSERT `$event.oSource.sId` INTO TABLE temp17.
    
    CLEAR temp18.
    INSERT `MESSAGE_TOAST` INTO TABLE temp18.
    INSERT `show` INTO TABLE temp18.
    INSERT `{0} Pressed` INTO TABLE temp18.
    INSERT `$event.oSource.sId` INTO TABLE temp18.
    
    CLEAR temp19.
    INSERT `MESSAGE_TOAST` INTO TABLE temp19.
    INSERT `show` INTO TABLE temp19.
    INSERT `{0} Pressed` INTO TABLE temp19.
    INSERT `$event.oSource.sId` INTO TABLE temp19.
    
    CLEAR temp20.
    INSERT `MESSAGE_TOAST` INTO TABLE temp20.
    INSERT `show` INTO TABLE temp20.
    INSERT `{0} Pressed` INTO TABLE temp20.
    INSERT `$event.oSource.sId` INTO TABLE temp20.
    
    CLEAR temp21.
    INSERT `MESSAGE_TOAST` INTO TABLE temp21.
    INSERT `show` INTO TABLE temp21.
    INSERT `{0} Pressed` INTO TABLE temp21.
    INSERT `$event.oSource.sId` INTO TABLE temp21.
    
    CLEAR temp22.
    INSERT `MESSAGE_TOAST` INTO TABLE temp22.
    INSERT `show` INTO TABLE temp22.
    INSERT `{0} Pressed` INTO TABLE temp22.
    INSERT `$event.oSource.sId` INTO TABLE temp22.
    
    CLEAR temp23.
    INSERT `MESSAGE_TOAST` INTO TABLE temp23.
    INSERT `show` INTO TABLE temp23.
    INSERT `{0} Pressed` INTO TABLE temp23.
    INSERT `$event.oSource.sId` INTO TABLE temp23.
    
    CLEAR temp24.
    INSERT `MESSAGE_TOAST` INTO TABLE temp24.
    INSERT `show` INTO TABLE temp24.
    INSERT `{0} Pressed` INTO TABLE temp24.
    INSERT `$event.oSource.sId` INTO TABLE temp24.
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

            )->tag( `Text`
                )->a( n = `text`  v = `Avatar with different Accent background colors and Accent badge icon colors:`
                )->a( n = `width` v = `100%`
                )->a( n = `class` v = `sapUiSmallMarginTop sapUiSmallMarginBegin sapUiMediumMarginBottom`
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL2 L2 M4 S6`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent1`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent1`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp1 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent1 / Accent1`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent2`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent2`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp2 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent2 / Accent2`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent3`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent3`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp3 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent3 / Accent3`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent4`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent4`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp4 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent4 / Accent4`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent5`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent5`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp5 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent5 / Accent5`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent6`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent6`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp6 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent6 / Accent6`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent7`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent7`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp7 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent7 / Accent7`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent8`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent8`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp8 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent8 / Accent8`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent9`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent9`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp9 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent9 / Accent9`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent10`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Accent10`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp10 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent10 / Accent10`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                )->end(
            )->end(

            )->tag( `Text`
                )->a( n = `text`  v = `Avatar with different Accent background colors and Indication badge icon colors:`
                )->a( n = `width` v = `100%`
                )->a( n = `class` v = `sapUiSmallMarginTop sapUiSmallMarginBegin sapUiMediumMarginBottom`
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL2 L2 M4 S6`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent1`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication1`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp11 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent1 / Indication1`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent2`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication2`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp12 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent2 / Indication2`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent3`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication3`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp13 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent3 / Indication3`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent4`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication4`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp14 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent4 / Indication4`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent5`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication5`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp15 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent5 / Indication5`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent6`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication6`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp16 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent6 / Indication6`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent7`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication7`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp17 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent7 / Indication7`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent8`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication8`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp18 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent8 / Indication8`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent9`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication9`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp19 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent9 / Indication9`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent10`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeIconColor`  v = `Indication10`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp20 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent10 / Indication10`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                )->end(
            )->end(

            )->tag( `Text`
                )->a( n = `text`  v = `Avatar with Accent1 background color and different badge icon value state colors:`
                )->a( n = `width` v = `100%`
                )->a( n = `class` v = `sapUiSmallMarginTop sapUiSmallMarginBegin sapUiMediumMarginBottom`
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL2 L2 M4 S6`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent1`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeValueState` v = `Success`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp21 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent1 / Success`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent1`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeValueState` v = `Information`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp22 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent1 / Information`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent1`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeValueState` v = `Warning`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp23 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent1 / Warning`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent1`
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                            )->a( n = `badgeValueState` v = `Error`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp24 )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent1 / Error`
                            )->a( n = `class`     v = `sapUiSmallMarginTop` ).


    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
