" @keywords popover sap.m popoverwithinarea horizontallayout button vbox flexitemdata flexbox image list standardlistitem
" @summary Within area of sap.ui.core.Popup determines where all popups (including popovers) are positioned.
" @origin sap.m.sample.PopoverWithinArea - https://sdk.openui5.org/entity/sap.m.Popover/sample/sap.m.sample.PopoverWithinArea (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_285 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products TYPE ty_t_product.

    " the record the original reaches with bindElement( '/ProductCollection/0' )
    " on every popover, seeded at the model root
    DATA name          TYPE string.
    DATA productpicurl TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS popover_image_display.
    METHODS popover_list_display.
    METHODS popover_inner_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_285 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( n = `HorizontalLayout` ns = `l`
            )->a( n = `class` v = `sapUiMediumMargin`

            )->tag( `Button`
                )->a( n = `text`         v = `Show Popover With Image`
                )->a( n = `press`        v = client->_event( val = `POPOVER_IMAGE` arg = `$event.oSource.sId` )
                )->a( n = `class`        v = `sapUiLargeMargin`
                )->a( n = `ariaHasPopup` v = `Dialog`

            )->ele( `VBox`
                )->a( n = `id`               v = `withinArea`
                )->a( n = `backgroundDesign` v = `Solid`
                )->a( n = `height`           v = `30rem`
                )->a( n = `width`            v = `60rem`
                )->a( n = `alignItems`       v = `Center`
                )->a( n = `justifyContent`   v = `Center`

                )->tag( `Button`
                    )->a( n = `text`         v = `Show Inside Popover`
                    )->a( n = `press`        v = client->_event( val = `POPOVER_INNER` arg = `$event.oSource.sId` )
                    )->a( n = `ariaHasPopup` v = `Dialog`

                )->ele( `layoutData`
                    )->tag( `FlexItemData`
                        )->a( n = `backgroundDesign` v = `Solid`

                )->end(
            )->end(

            )->ele( `FlexBox`
                )->a( n = `direction`      v = `Column`
                )->a( n = `alignItems`     v = `End`
                )->a( n = `justifyContent` v = `End`
                )->a( n = `height`         v = `30rem`

                )->tag( `Button`
                    )->a( n = `text`         v = `Show Popover with List`
                    )->a( n = `press`        v = client->_event( val = `POPOVER_LIST` arg = `$event.oSource.sId` )
                    )->a( n = `ariaHasPopup` v = `Dialog`
                    )->a( n = `class`        v = `sapUiLargeMargin` ).

    client->view_display( view->stringify( ) ).

    " Popup.setWithinArea confines every popup to the grey VBox instead of the
    " viewport - the sample's point. The original re-sets it in each press
    " handler and releases it in afterClose; here it is set once with the view,
    " because a follow-up action runs AFTER the popover of the same round-trip
    " has opened. This app opens no other popup, so the effect is the same.
    client->follow_up_action( val   = client->cs_event-control_global
                              t_arg = VALUE #( ( `POPUP` ) ( `setWithinArea` ) ( `withinArea` ) ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `POPOVER_IMAGE`.
        popover_image_display( ).

      WHEN `POPOVER_INNER`.
        popover_inner_display( ).

      WHEN `POPOVER_LIST`.
        popover_list_display( ).

    ENDCASE.

  ENDMETHOD.


  METHOD popover_image_display.

    DATA(popover) = z2ui5_cl_ui5_view_builder=>factory( ).

    " the fragment's relative {Name}/{ProductPicUrl} come from the popover's
    " bindElement( '/ProductCollection/0' ); that record is seeded at the model
    " root here, so both bind absolutely
    popover->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Popover`
            )->a( n = `id`            v = `myPopover`
            )->a( n = `title`         v = client->_bind( name )
            )->a( n = `contentHeight` v = `20em`
            )->a( n = `placement`     v = `Right`

            )->tag( `Image`
                )->a( n = `src`          v = client->_bind( productpicurl )
                )->a( n = `width`        v = `18em`
                )->a( n = `densityAware` v = `false` ).

    client->popover_display( xml   = popover->stringify( )
                             by_id = client->get_event_arg( ) ).

  ENDMETHOD.


  METHOD popover_list_display.

    DATA(popover) = z2ui5_cl_ui5_view_builder=>factory( ).

    popover->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Popover`
            )->a( n = `id`        v = `myListPopover`
            )->a( n = `title`     v = `Products`
            )->a( n = `placement` v = `Left`

            )->ele( `List`
                )->a( n = `id`    v = `list`
                )->a( n = `items` v = client->_bind( t_products )

                )->ele( `items`
                    )->tag( `StandardListItem`
                        )->a( n = `title`            v = `{NAME}`
                        )->a( n = `description`      v = `{PRODUCTID}`
                        )->a( n = `type`             v = `Active`
                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                        )->a( n = `iconDensityAware` v = `false`
                        )->a( n = `iconInset`        v = `false` ).

    client->popover_display( xml   = popover->stringify( )
                             by_id = client->get_event_arg( ) ).

  ENDMETHOD.


  METHOD popover_inner_display.

    DATA(popover) = z2ui5_cl_ui5_view_builder=>factory( ).

    popover->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Popover`
            )->a( n = `id`        v = `myInnerPopover`
            )->a( n = `placement` v = `Left`

            )->ele( `List`
                )->a( n = `id`    v = `inner-List`
                )->a( n = `items` v = client->_bind( t_products )

                )->ele( `items`
                    )->tag( `StandardListItem`
                        )->a( n = `title`            v = `{NAME}`
                        )->a( n = `description`      v = `{PRODUCTID}`
                        )->a( n = `type`             v = `Active`
                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                        )->a( n = `iconDensityAware` v = `false`
                        )->a( n = `iconInset`        v = `false` ).

    client->popover_display( xml   = popover->stringify( )
                             by_id = client->get_event_arg( ) ).

  ENDMETHOD.


  METHOD model_init.

    " the popovers' bindElement( '/ProductCollection/0' ) record, seeded at the
    " model root (sap/ui/demo/mock/products.json, first row)
    name          = `Notebook Basic 15`.
    productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.

    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
