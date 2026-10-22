" @keywords avatar sap.m scrollcontainer text grid vbox
" @summary This sample demonstrates different combinations of types, shapes, and sizes of the Avatar.
" @origin sap.m.sample.Avatar - https://sdk.openui5.org/entity/sap.m.Avatar/sample/sap.m.sample.Avatar (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_624 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA speakers TYPE string.
    DATA woman01  TYPE string.
    DATA woman02  TYPE string.
    DATA screw    TYPE string.
    DATA lamp     TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_624 IMPLEMENTATION.

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
    DATA temp6 TYPE string_table.
    DATA temp7 TYPE string_table.
    DATA temp8 TYPE string_table.
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
                )->a( n = `text`  v = `The Avatar Control allows usage of different shapes, sizes and content. Border can also be applied:`
                )->a( n = `width` v = `100%`
                )->a( n = `class` v = `sapUiSmallMarginTop sapUiSmallMarginBegin sapUiMediumMarginBottom`
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL2 L3 M6 S6`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`          v = client->_bind( speakers )
                            )->a( n = `displaySize`  v = `XL`
                            )->a( n = `displayShape` v = `Square`
                            )->a( n = `showBorder`   v = `true`
                            )->a( n = `press`        v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                   t_arg = temp1 )
                        )->tag( `Text`
                            )->a( n = `text`  v = `Avatar of a product with border`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`         v = client->_bind( woman01 )
                            )->a( n = `displaySize` v = `XL`
                            )->a( n = `showBorder`  v = `true`
                            )->a( n = `press`       v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                  t_arg = temp2 )
                        )->tag( `Text`
                            )->a( n = `text`  v = `Avatar of a person with border`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `initials`     v = `IS`
                            )->a( n = `displaySize`  v = `XL`
                            )->a( n = `displayShape` v = `Square`
                            )->a( n = `press`        v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                   t_arg = temp3 )
                        )->tag( `Text`
                            )->a( n = `text`  v = `Square with initials`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `enabled`     v = `false`
                            )->a( n = `initials`    v = `PI`
                            )->a( n = `displaySize` v = `XL`
                            )->a( n = `press`       v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                  t_arg = temp4 )
                        )->tag( `Text`
                            )->a( n = `text`  v = `Disabled`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `XL`
                            )->a( n = `backgroundColor` v = `Transparent`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp5 )
                        )->tag( `Text`
                            )->a( n = `text`  v = `Transparent background`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `initials`        v = `IS`
                            )->a( n = `displaySize`     v = `XL`
                            )->a( n = `backgroundColor` v = `TileIcon`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp6 )
                        )->tag( `Text`
                            )->a( n = `text`  v = `TileIcon background`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `XL`
                            )->a( n = `backgroundColor` v = `Placeholder`
                            )->a( n = `displayShape`    v = `Square`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = temp7 )
                        )->tag( `Text`
                            )->a( n = `text`  v = `Placeholder background`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize` v = `XL`
                            )->a( n = `press`       v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                  t_arg = temp8 )
                            )->a( n = `initials`    v = `ABC`
                        )->tag( `Text`
                            )->a( n = `text`  v = `Circular avatar with 3 letter initials`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                )->end(
            )->end(

            )->tag( `Text`
                )->a( n = `text`  v = `The Avatar can be set to a square or circular shape with a predefined size:`
                )->a( n = `width` v = `100%`
                )->a( n = `class` v = `sapUiSmallMarginBegin sapUiMediumMarginTop sapUiMediumMarginBottom`
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL2 L2 M3 S12`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems`   v = `Center`
                        )->a( n = `alignContent` v = `End`

                        )->tag( `Avatar`
                            )->a( n = `src`          v = client->_bind( screw )
                            )->a( n = `displaySize`  v = `XL`
                            )->a( n = `displayShape` v = `Square`
                        )->tag( `Text`
                            )->a( n = `text`  v = `XL`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems`   v = `Center`
                        )->a( n = `alignContent` v = `End`

                        )->tag( `Avatar`
                            )->a( n = `src`          v = client->_bind( screw )
                            )->a( n = `displaySize`  v = `L`
                            )->a( n = `displayShape` v = `Square`
                        )->tag( `Text`
                            )->a( n = `text`  v = `L`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`          v = client->_bind( screw )
                            )->a( n = `displaySize`  v = `M`
                            )->a( n = `displayShape` v = `Square`
                        )->tag( `Text`
                            )->a( n = `text`  v = `M`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`          v = client->_bind( screw )
                            )->a( n = `displaySize`  v = `S`
                            )->a( n = `displayShape` v = `Square`
                        )->tag( `Text`
                            )->a( n = `text`  v = `S`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`          v = client->_bind( screw )
                            )->a( n = `displaySize`  v = `XS`
                            )->a( n = `displayShape` v = `Square`
                        )->tag( `Text`
                            )->a( n = `text`  v = `XS`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                )->end(
            )->end(
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL2 L2 M3 S12`
                )->a( n = `class`       v = `sapUiMediumMarginTop`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`         v = client->_bind( woman02 )
                            )->a( n = `displaySize` v = `XL`
                        )->tag( `Text`
                            )->a( n = `text`  v = `XL`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`         v = client->_bind( woman02 )
                            )->a( n = `displaySize` v = `L`
                        )->tag( `Text`
                            )->a( n = `text`  v = `L`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`         v = client->_bind( woman02 )
                            )->a( n = `displaySize` v = `M`
                        )->tag( `Text`
                            )->a( n = `text`  v = `M`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`         v = client->_bind( woman02 )
                            )->a( n = `displaySize` v = `S`
                        )->tag( `Text`
                            )->a( n = `text`  v = `S`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`         v = client->_bind( woman02 )
                            )->a( n = `displaySize` v = `XS`
                        )->tag( `Text`
                            )->a( n = `text`  v = `XS`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                )->end(
            )->end(
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL2 L2 M3 S12`
                )->a( n = `class`       v = `sapUiMediumMarginTop`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `initials`        v = `IS`
                            )->a( n = `displaySize`     v = `XL`
                            )->a( n = `backgroundColor` v = `Accent1`
                        )->tag( `Text`
                            )->a( n = `text`  v = `XL`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent1`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `initials`        v = `IS`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent2`
                        )->tag( `Text`
                            )->a( n = `text`  v = `L`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent2`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `initials`        v = `IS`
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `backgroundColor` v = `Accent3`
                        )->tag( `Text`
                            )->a( n = `text`  v = `M`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent3`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `initials`        v = `IS`
                            )->a( n = `displaySize`     v = `S`
                            )->a( n = `backgroundColor` v = `Accent4`
                        )->tag( `Text`
                            )->a( n = `text`  v = `S`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent4`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `initials`        v = `IS`
                            )->a( n = `displaySize`     v = `XS`
                            )->a( n = `backgroundColor` v = `Accent5`
                        )->tag( `Text`
                            )->a( n = `text`  v = `XS`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent5`

                    )->end(
                )->end(
            )->end(
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL2 L2 M3 S12`
                )->a( n = `class`       v = `sapUiMediumMarginTop`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`             v = `sap-icon://lab`
                            )->a( n = `displaySize`     v = `XL`
                            )->a( n = `backgroundColor` v = `Accent6`
                        )->tag( `Text`
                            )->a( n = `text`  v = `XL`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent6`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`             v = `sap-icon://lab`
                            )->a( n = `displaySize`     v = `L`
                            )->a( n = `backgroundColor` v = `Accent7`
                        )->tag( `Text`
                            )->a( n = `text`  v = `L`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent7`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`             v = `sap-icon://lab`
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `backgroundColor` v = `Accent8`
                        )->tag( `Text`
                            )->a( n = `text`  v = `M`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent8`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`             v = `sap-icon://lab`
                            )->a( n = `displaySize`     v = `S`
                            )->a( n = `backgroundColor` v = `Accent9`
                        )->tag( `Text`
                            )->a( n = `text`  v = `S`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent9`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`             v = `sap-icon://lab`
                            )->a( n = `displaySize`     v = `XS`
                            )->a( n = `backgroundColor` v = `Accent10`
                        )->tag( `Text`
                            )->a( n = `text`  v = `XS`
                            )->a( n = `class` v = `sapUiSmallMarginTop`
                        )->tag( `Text`
                            )->a( n = `text` v = `Accent10`

                    )->end(
                )->end(
            )->end(
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL4 L5 M6 S12`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Text`
                            )->a( n = `text`  v = `The Avatar can be set to a custom size:`
                            )->a( n = `width` v = `100%`
                            )->a( n = `class` v = `sapUiMediumMarginTop sapUiMediumMarginBottom`
                        )->tag( `Avatar`
                            )->a( n = `src`               v = client->_bind( lamp )
                            )->a( n = `displaySize`       v = `Custom`
                            )->a( n = `customDisplaySize` v = `250px`
                            )->a( n = `displayShape`      v = `Square`
                        )->tag( `Text`
                            )->a( n = `text`  v = `Avatar with custom Size`
                            )->a( n = `class` v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Text`
                            )->a( n = `text`  v = `If there is no image, icon or initials set, the Avatar displays a Placeholder. If there is invalid image src, ` &&
                                                  `the control displays either initials (if provided) or icon Placeholder (if no initials are proivided):`
                            )->a( n = `width` v = `100%`
                            )->a( n = `class` v = `sapUiMediumMarginBottom sapUiMediumMarginTop`
                        )->ele( n = `Grid` ns = `l`
                            )->a( n = `defaultSpan` v = `XL4 L4 M6 S6`

                            )->ele( n = `content` ns = `l`
                                )->ele( `VBox`
                                    )->a( n = `alignItems` v = `Center`

                                    )->tag( `Avatar`
                                        )->a( n = `displaySize`     v = `L`
                                        )->a( n = `displayShape`    v = `Square`
                                        )->a( n = `backgroundColor` v = `Random`
                                    )->tag( `Text`
                                        )->a( n = `text`  v = `With product icon`
                                        )->a( n = `class` v = `sapUiSmallMarginTop`

                                )->end(
                                )->ele( `VBox`
                                    )->a( n = `alignItems` v = `Center`

                                    )->tag( `Avatar`
                                        )->a( n = `displaySize`     v = `L`
                                        )->a( n = `backgroundColor` v = `Random`
                                    )->tag( `Text`
                                        )->a( n = `text`  v = `With person icon`
                                        )->a( n = `class` v = `sapUiSmallMarginTop`

                                )->end(
                                )->ele( `VBox`
                                    )->a( n = `alignItems` v = `Center`

                                    )->tag( `Avatar`
                                        )->a( n = `displaySize`     v = `L`
                                        )->a( n = `displayShape`    v = `Square`
                                        )->a( n = `fallbackIcon`    v = `sap-icon://accelerated`
                                        )->a( n = `backgroundColor` v = `Random`
                                    )->tag( `Text`
                                        )->a( n = `text`  v = `With custom fallback icon`
                                        )->a( n = `class` v = `sapUiSmallMarginTop`

                                )->end(
                                )->ele( `VBox`
                                    )->a( n = `alignItems` v = `Center`

                                    )->tag( `Avatar`
                                        )->a( n = `displaySize`     v = `L`
                                        )->a( n = `initials`        v = `PB`
                                        )->a( n = `src`             v = client->_bind( woman01 )
                                        )->a( n = `backgroundColor` v = `Random`
                                    )->tag( `Text`
                                        )->a( n = `text`      v = `With invalid image source, but initials provided`
                                        )->a( n = `class`     v = `sapUiSmallMarginTop`
                                        )->a( n = `textAlign` v = `Center` ).


    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " onInit's JSONModel - sap.ui.require.toUrl( 'sap/m/images/...' ), absolutized to the OpenUI5 host
    speakers = `https://sdk.openui5.org/test-resources/sap/m/images/Speakers_avatar_01.jpg`.
    woman01  = `https://sdk.openui5.org/test-resources/sap/m/images/Woman_avatar_01.png`.
    woman02  = `https://sdk.openui5.org/test-resources/sap/m/images/Woman_avatar_02.png`.
    screw    = `https://sdk.openui5.org/test-resources/sap/m/images/Screw_avatar_01.jpg`.
    lamp     = `https://sdk.openui5.org/test-resources/sap/m/images/Lamp_avatar_01.jpg`.

  ENDMETHOD.

ENDCLASS.
