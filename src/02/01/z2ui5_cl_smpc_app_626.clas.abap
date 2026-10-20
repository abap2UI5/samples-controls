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
    IF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    " original onPress: MessageToast.show( source.getId() + ' Pressed' ) - client-composed, roundtrip-free
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
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
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Accent1 / Error`
                            )->a( n = `class`     v = `sapUiSmallMarginTop` ).


    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
