" @keywords pulltorefresh pull refresh sap.m list standardlistitem
" @summary With the Pull to Refresh you can trigger an update operation by swiping the current page down on touch devices. On other devices the Pull To Refresh is visible all the time and the user clicks it like a button.
" @origin sap.m.sample.PullToRefresh - https://sdk.openui5.org/entity/sap.m.PullToRefresh/sample/sap.m.sample.PullToRefresh (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_081 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA shown  TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS fill_all RETURNING VALUE(result) LIKE t_products.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_081 IMPLEMENTATION.

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
            )->a( n = `showHeader` v = `false`

            )->ele( `content`
                )->tag( `PullToRefresh`
                    )->a( n = `id`      v = `pullToRefresh`
                    )->a( n = `refresh` v = client->_event( `REFRESH` )
                )->ele( `List`
                    )->a( n = `id`    v = `list`
                    )->a( n = `items` v = client->_bind( t_products )

                    )->tag( `StandardListItem`
                        )->a( n = `title`            v = `{NAME}`
                        )->a( n = `description`      v = `{PRODUCTID}`
                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                        )->a( n = `iconDensityAware` v = `false`
                        )->a( n = `iconInset`        v = `false`

                )->end(
            )->end(
        )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `REFRESH`.
      " handleRefresh calls pullToRefresh.hide( ) before appending: onclick puts
      " the control in its busy state and only hide( ) resets it, so without
      " this the spinner never goes away after the first pull
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `pullToRefresh` ) ( `hide` ) ) ).

      " _pushNewProduct: each pull-to-refresh appends the next product until the full collection is shown
      DATA(all) = fill_all( ).
      IF shown < lines( all ).
        shown = shown + 1.
      ENDIF.
      t_products = VALUE #( FOR i = 1 WHILE i <= shown ( all[ i ] ) ).
    ENDIF.

  ENDMETHOD.


  METHOD fill_all.

    " full mock /ProductCollection (sap/ui/demo/mock/products.json); ProductPicUrl resolved to absolute OpenUI5 URLs
    result = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.


  METHOD model_init.

    " the original starts with an empty model and pushes the first product on init
    shown = 1.
    DATA(all) = fill_all( ).
    t_products = VALUE #( ( all[ 1 ] ) ).

  ENDMETHOD.
ENDCLASS.
