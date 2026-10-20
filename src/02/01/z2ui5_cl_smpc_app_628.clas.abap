CLASS z2ui5_cl_smpc_app_628 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA gettyimages     TYPE string.
    DATA shutterstock    TYPE string.
    DATA lowshutterstock TYPE string.
    DATA lightbox        TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_628 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
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
                )->a( n = `text`  v = `The Avatar Control allows usage of different shapes, sizes and content, configured with various types of visual affordance`
                )->a( n = `width` v = `100%`
                )->a( n = `class` v = `sapUiSmallMarginTop sapUiSmallMarginBegin sapUiMediumMarginBottom`
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL3 L3 M6 S6`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->ele( `Avatar`
                            )->a( n = `src`          v = client->_bind( lightbox )
                            )->a( n = `displaySize`  v = `L`
                            )->a( n = `displayShape` v = `Circle`

                            )->ele( `detailBox`
                                )->ele( `LightBox`
                                    )->tag( `LightBoxItem`
                                        )->a( n = `imageSrc` v = client->_bind( lightbox )
                                        )->a( n = `alt`      v = `Michael Adams`
                                        )->a( n = `title`    v = `This is Michael Adams`
                                        )->a( n = `subtitle` v = `Michael Adams Human Relations`

                                )->end(
                            )->end(
                        )->end(

                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Avatar with Lightbox attached`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `src`          v = client->_bind( gettyimages )
                            )->a( n = `displaySize`  v = `XL`
                            )->a( n = `imageFitType` v = `Cover`
                            )->a( n = `press`        v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                   t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
                            )->a( n = `badgeIcon`    v = `sap-icon://camera`
                            )->a( n = `badgeTooltip` v = `Sabine Mayer`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Avatar with predefined visual affordance suggesting an image change with a custom tooltip`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`  v = `M`
                            )->a( n = `displayShape` v = `Circle`
                            )->a( n = `press`        v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                   t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
                            )->a( n = `src`          v = client->_bind( lowshutterstock )
                            )->a( n = `badgeIcon`    v = `sap-icon://edit`
                            )->a( n = `badgeTooltip` v = `Julie Armstrong`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Avatar with predefined visual affordance suggesting an editing action with a custom tooltip`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `backgroundColor` v = `Accent7`
                            )->a( n = `initials`        v = `JD`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
                            )->a( n = `badgeIcon`       v = `sap-icon://camera`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Avatar with predefined visual affordance suggesting an image change with default tooltip`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                )->end(
            )->end(
            )->ele( n = `Grid` ns = `l`
                )->a( n = `defaultSpan` v = `XL3 L3 M6 S6`

                )->ele( n = `content` ns = `l`
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `M`
                            )->a( n = `backgroundColor` v = `Accent3`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Avatar with predefined badge affordance and badge tooltip`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`  v = `XL`
                            )->a( n = `displayShape` v = `Square`
                            )->a( n = `press`        v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                   t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
                            )->a( n = `src`          v = client->_bind( shutterstock )
                            )->a( n = `badgeIcon`    v = `sap-icon://edit`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Avatar with predefined visual affordance suggesting an editing action with default tooltip`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `XL`
                            )->a( n = `backgroundColor` v = `Accent5`
                            )->a( n = `src`             v = `sap-icon://soccer`
                            )->a( n = `displayShape`    v = `Square`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
                            )->a( n = `badgeIcon`       v = `sap-icon://edit`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Avatar with custom visual affordance and a custom tooltip`
                            )->a( n = `class`     v = `sapUiSmallMarginTop`

                    )->end(
                    )->ele( `VBox`
                        )->a( n = `alignItems` v = `Center`

                        )->tag( `Avatar`
                            )->a( n = `displaySize`     v = `XL`
                            )->a( n = `backgroundColor` v = `Accent3`
                            )->a( n = `src`             v = `sap-icon://customer`
                            )->a( n = `press`           v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `{0} Pressed` ) ( `$event.oSource.sId` ) ) )
                            )->a( n = `badgeIcon`       v = `sap-icon://add`
                            )->a( n = `badgeTooltip`    v = `People`
                        )->tag( `Text`
                            )->a( n = `textAlign` v = `Center`
                            )->a( n = `text`      v = `Avatar with custom badge affordance icon and custom badge tooltip`
                            )->a( n = `class`     v = `sapUiSmallMarginTop` ).


    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " onInit's JSONModel - sap.ui.require.toUrl( 'sap/m/images/...' ), absolutized to the OpenUI5 host
    gettyimages     = `https://sdk.openui5.org/test-resources/sap/m/images/284133_GettyImages-145058106_2600.jpg`.
    shutterstock    = `https://sdk.openui5.org/test-resources/sap/m/images/283930_shutterstock_56287057.jpg`.
    lowshutterstock = `https://sdk.openui5.org/test-resources/sap/m/images/282627_low_shutterstock_402830878.jpg`.
    lightbox        = `https://sdk.openui5.org/test-resources/sap/m/images/274827_274827_l_srgb_s_gl.jpg`.

  ENDMETHOD.

ENDCLASS.
