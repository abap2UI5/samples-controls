" @keywords list sap.m listswipe standardlistitem button
" @summary With a swipe gesture you can show additional content for an item without having to navigate to a detail page. This feature is only available for touch devices.
" @origin sap.m.sample.ListSwipe - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListSwipe (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_497 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products  TYPE ty_t_product.
    DATA swipe_text  TYPE string VALUE `Approve`.
    DATA swipe_type  TYPE string VALUE `Accept`.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_497 IMPLEMENTATION.

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
            )->a( n = `headerText` v = `Products`
            )->a( n = `items`      v = client->_bind( t_products )
            " handleSwipe rewrites the swipe button and toasts the direction - the
            " direction travels to the backend, which writes the two bound properties
            )->a( n = `swipe`      v = client->_event( val = `SWIPE` arg = `${$parameters>/swipeDirection}` )

            )->tag( `StandardListItem`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `description`      v = `{PRODUCTID}`
                )->a( n = `icon`             v = `{PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false`

            )->ele( `swipeContent`
                " handleReject removes the swiped item and swipes out; the row index
                " travels with the press
                )->tag( `Button`
                    )->a( n = `text`  v = client->_bind( swipe_text )
                    )->a( n = `type`  v = client->_bind( swipe_type )
                    )->a( n = `press` v = client->_event( val = `REJECT` arg = `$event.oSource.getParent().indexOfItem($event.oSource.getParent().getSwipedItem())` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SWIPE`.
        " BeginToEnd -> Approve/Accept, otherwise Disapprove/Reject
        IF client->get_event_arg( ) = `BeginToEnd`.
          swipe_text = `Approve`.
          swipe_type = `Accept`.
          client->message_toast_display( `Swipe direction is from the beginning to the end (left ro right in LTR languages)` ).
        ELSE.
          swipe_text = `Disapprove`.
          swipe_type = `Reject`.
          client->message_toast_display( `Swipe direction is from the end to the beginning (right to left in LTR languages)` ).
        ENDIF.

      WHEN `REJECT`.
        DATA(index) = CONV i( client->get_event_arg( ) ).
        IF index >= 0 AND index < lines( t_products ).
          DELETE t_products INDEX index + 1.
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
