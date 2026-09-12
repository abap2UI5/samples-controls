" @keywords pulltorefresh pull refresh sap.m refreshresponsive bar searchfield list standardlistitem
" @summary An 'Responsive Refresh' can be achieved by the combination of a Search Field's refresh button and a Pull To Refresh, both of which appear depending on whether the device is touch-enabled. A growing stream of backend data is simulated here.
" @origin sap.m.sample.RefreshResponsive - https://sdk.openui5.org/entity/sap.m.PullToRefresh/sample/sap.m.sample.RefreshResponsive (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_438 DEFINITION PUBLIC.

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
    DATA search     TYPE string.

  PROTECTED SECTION.
    DATA client        TYPE REF TO z2ui5_if_client.
    DATA product_count TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS list_refresh.
    METHODS products_all RETURNING VALUE(result) TYPE ty_t_product.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_438 IMPLEMENTATION.

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
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `Page`
            )->a( n = `id`         v = `page`
            )->a( n = `showHeader` v = `false`

            )->ele( `subHeader`
                )->ele( `Bar`
                    )->a( n = `id` v = `searchBar`

                    )->ele( `contentMiddle`
                        " the original's own device model (isNoTouch / isTouch) folds onto
                        " the framework's raw device> model
                        )->tag( `SearchField`
                            )->a( n = `id`                v = `searchField`
                            )->a( n = `showRefreshButton` v = `{= !${device>/support/touch} }`
                            )->a( n = `value`             v = client->_bind( search )
                            )->a( n = `search`            v = client->_event( `REFRESH` )
                            )->a( n = `width`             v = `100%`

                    )->end(
                )->end(
            )->end(

            )->ele( `content`
                )->tag( `PullToRefresh`
                    )->a( n = `id`      v = `pullToRefresh`
                    )->a( n = `visible` v = `{= ${device>/support/touch} }`
                    )->a( n = `refresh` v = client->_event( `REFRESH` )

                )->ele( `List`
                    )->a( n = `id`    v = `list`
                    )->a( n = `items` v = client->_bind( t_products )

                    )->tag( `StandardListItem`
                        )->a( n = `title`            v = `{NAME}`
                        )->a( n = `description`      v = `{PRODUCTID}`
                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                        )->a( n = `iconDensityAware` v = `false`
                        )->a( n = `iconInset`        v = `false` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `REFRESH`.

      list_refresh( ).

      " the original hides the PullToRefresh spinner when the refresh is through
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `pullToRefresh` ) ( `hide` ) ) ).

    ENDIF.

  ENDMETHOD.


  METHOD list_refresh.

    " _pushNewProduct adds one more record of the mock per refresh, and
    " handleRefresh then filters the list binding by the search field's value -
    " both are done in the backend here, on the one table the List binds
    DATA(all) = products_all( ).
    IF product_count < lines( all ).
      product_count = product_count + 1.
    ENDIF.

    t_products = VALUE #( ).
    LOOP AT all INTO DATA(product) TO product_count.
      IF search IS INITIAL OR to_upper( product-name ) CS to_upper( search ).
        INSERT product INTO TABLE t_products.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD products_all.

    " /ProductCollection of ui5/mock/products.json, verbatim - the "backend" the
    " sample loads with jQuery.getJSON and hands out one record at a time
    result = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.


  METHOD model_init.

    " the sample starts with an empty collection and pushes the first record
    " as soon as the mock is loaded
    list_refresh( ).

  ENDMETHOD.

ENDCLASS.
