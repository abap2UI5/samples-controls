" @keywords productswitch product switch sap.f productswitchitemwithimagesrc verticallayout button text responsivepopover productswitchitem
" @summary This sample demonstrates the usage of Product Switch Item with imageSrc, configurable by the app developer.
" @origin sap.f.sample.ProductSwitchItemWithImageSrc - https://sdk.openui5.org/entity/sap.f.ProductSwitch/sample/sap.f.sample.ProductSwitchItemWithImageSrc (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_666 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_666 IMPLEMENTATION.

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
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `height`    v = `100%`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`

            )->tag( `Button`
                )->a( n = `id`    v = `pSwitchBtn`
                )->a( n = `icon`  v = `sap-icon://menu`
                )->a( n = `text`  v = `Open Product Switch`
                " fnOpen opens the fragment's ResponsivePopover at this button - rebuilt in
                " on_event and shown through popover_display( by_id = ... )
                )->a( n = `press` v = client->_event( `OPEN_SWITCH` )
            )->tag( `Text`
                )->a( n = `text` v = `Note: Redirection logic should be handled by the app developer.`
            )->tag( `Text`
                )->a( n = `text` v = `You can use sap.m.URLHelper, as shown in the fnChange method of the ProductSwitchItemWithImageSrc controller.` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
      DATA popover TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp1 TYPE string_table.
      DATA temp2 TYPE string_table.
      DATA temp3 LIKE LINE OF temp2.

    IF client->get_event( ) = `OPEN_SWITCH`.
      
      popover = z2ui5_cl_ui5_view_builder=>factory( ).

      
      CLEAR temp1.
      INSERT `MESSAGE_TOAST` INTO TABLE temp1.
      INSERT `show` INTO TABLE temp1.
      INSERT `Redirecting to {0}` INTO TABLE temp1.
      INSERT `${$parameters>/itemPressed}.getTargetSrc()` INTO TABLE temp1.
      
      CLEAR temp2.
      INSERT `REDIRECT` INTO TABLE temp2.
      
      temp3 = |\{ URL: $\{$parameters>/itemPressed\}.getTargetSrc(), NEW_WINDOW: true \}|.
      INSERT temp3 INTO TABLE temp2.
      popover->ele( n = `FragmentDefinition` ns = `core`
          )->a( n = `xmlns`      v = `sap.m`
          )->a( n = `xmlns:f`    v = `sap.f`
          )->a( n = `xmlns:core` v = `sap.ui.core`

          )->ele( `ResponsivePopover`
              )->a( n = `placement`  v = `Bottom`
              )->a( n = `showHeader` v = `false`

              " onInit gives the popover an Emphasized Close endButton on a phone
              " only - declared once, its visibility bound to the device model
              )->ele( `endButton`
                  )->tag( `Button`
                      )->a( n = `text`    v = `Close`
                      )->a( n = `type`    v = `Emphasized`
                      )->a( n = `visible` v = |\{= $\{device>/system/phone\} \}|
                      )->a( n = `press`   v = client->follow_up_action( client->cs_event-popover_close )

              )->end(

              )->ele( n = `ProductSwitch` ns = `f`
                  " fnChange toasts 'Redirecting to <targetSrc>' and calls
                  " URLHelper.redirect( targetSrc, true ) - two client actions on one event
                  )->a( n = `change` v = client->follow_up_action(
                            val   = client->cs_event-control_global
                            t_arg = temp1 ) && `; ` &&
                                        client->follow_up_action(
                            val   = client->cs_event-urlhelper
                            t_arg = temp2 )

                  )->ele( n = `items` ns = `f`
                      )->tag( n = `ProductSwitchItem` ns = `f`
                          )->a( n = `src`       v = `sap-icon://newspaper`
                          )->a( n = `imageSrc`  v = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`
                          )->a( n = `title`     v = `JPG`
                          )->a( n = `subTitle`  v = `JPG image`
                          )->a( n = `targetSrc` v = `https://listserv.sap.com/mailman/listinfo/ui5.announce`
                          )->a( n = `target`    v = `_blank`
                      )->tag( n = `ProductSwitchItem` ns = `f`
                          )->a( n = `src`       v = `sap-icon://group`
                          )->a( n = `imageSrc`  v = `https://www.sap.com/dam/application/shared/logos/sap-logo-svg.svg.adapt.svg/1493030643828.svg`
                          )->a( n = `title`     v = `SVG`
                          )->a( n = `subTitle`  v = `SVG image`
                          )->a( n = `targetSrc` v = `https://community.sap.com/topics/ui5`
                          )->a( n = `target`    v = `_blank`
                      )->tag( n = `ProductSwitchItem` ns = `f`
                          )->a( n = `src`       v = `sap-icon://group`
                          )->a( n = `imageSrc`  v = `https://sdk.openui5.org/test-resources/sap/m/images/Woman_avatar_01.png`
                          )->a( n = `title`     v = `PNG`
                          )->a( n = `subTitle`  v = `PNG image`
                          )->a( n = `targetSrc` v = `https://community.sap.com/topics/ui5`
                          )->a( n = `target`    v = `_blank` ).

      client->popover_display( xml = popover->stringify( ) by_id = `pSwitchBtn` ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
