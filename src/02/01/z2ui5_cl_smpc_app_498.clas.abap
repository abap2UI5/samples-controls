" @keywords list sap.m listactions overflowtoolbar title toolbarspacer text slider standardlistitem listitemaction
" @summary This example demonstrates how to add custom actions to list items. Dedicated 'Delete' and 'Edit' types can be used to add predefined actions to the list items. The 'Custom' type can be used to add custom actions to the list items.
" @origin sap.m.sample.ListActions - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListActions (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_498 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
        quantity      TYPE i,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products   TYPE ty_t_product.
    DATA action_count TYPE i VALUE 2.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_498 IMPLEMENTATION.

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

        )->ele( `List`
            )->a( n = `id`              v = `list`
            )->a( n = `items`           v = client->_bind( t_products )
            )->a( n = `mode`            v = `MultiSelect`
            " onSliderChange calls list.setItemActionCount( value ) - the Slider value
            " and the count are the same two-way bound field here
            )->a( n = `itemActionCount` v = client->_bind( action_count )
            " onItemActionPress toasts the action's text (or its type) and the product
            " of the row - both travel with the event
            )->a( n = `itemActionPress` v = client->_event( val   = `ITEM_ACTION`
                                                            t_arg = VALUE #( ( `${$parameters>/action}.getText() || ${$parameters>/action}.getType()` )
                                                                             ( `${$parameters>/listItem}.getTitle()` ) ) )

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`

                    )->tag( `Title`
                        )->a( n = `text`  v = `Products`
                        )->a( n = `level` v = `H2`
                    )->tag( `ToolbarSpacer`
                    )->tag( `Text`
                        )->a( n = `text` v = `Item Action Count: `
                    )->tag( `Slider`
                        )->a( n = `min`             v = `0`
                        )->a( n = `max`             v = `2`
                        )->a( n = `value`           v = client->_bind( action_count )
                        )->a( n = `width`           v = `150px`
                        )->a( n = `enableTickmarks` v = `true`

                )->end(
            )->end(

            )->ele( `StandardListItem`
                )->a( n = `title`       v = `{NAME}`
                )->a( n = `description` v = `{PRODUCTID}`
                )->a( n = `icon`        v = `{PRODUCTPICURL}`
                )->a( n = `counter`     v = `{QUANTITY}`
                )->a( n = `type`        v = `Navigation`

                )->tag( `ListItemAction`
                    )->a( n = `text` v = `Add to Cart`
                    )->a( n = `icon` v = `sap-icon://cart`
                )->tag( `ListItemAction`
                    )->a( n = `text` v = `Bookmark`
                    )->a( n = `icon` v = `sap-icon://bookmark`
                )->tag( `ListItemAction`
                    )->a( n = `type` v = `Edit`
                )->tag( `ListItemAction`
                    )->a( n = `type` v = `Delete` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `ITEM_ACTION`.
      client->message_toast_display( |{ client->get_event_arg( ) } action is pressed for the Product { client->get_event_arg( 2 ) }| ).
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
