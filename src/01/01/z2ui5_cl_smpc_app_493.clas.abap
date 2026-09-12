" @keywords combobox combo box sap.m comboboxlazyloading listitem
" @summary Use this feature to defer initialization of items until the point at which the items are needed. It can improve performance, reduce memory usage and unnecessary client/server round-trips.
" @origin sap.m.sample.ComboBoxLazyLoading - https://sdk.openui5.org/entity/sap.m.ComboBox/sample/sap.m.sample.ComboBoxLazyLoading (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_493 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid TYPE string,
        name      TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products TYPE ty_t_product.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS products_load.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_493 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`
            )->a( n = `class`      v = `sapUiContentPadding`

            )->ele( `content`
                " the original suspends the OData binding and resumes it in
                " handleLoadItems - here the items are fetched from the backend on the
                " same event, so the list is still empty until the picker is opened
                )->ele( `ComboBox`
                    )->a( n = `items`     v = client->_bind( t_products )
                    )->a( n = `loadItems` v = client->_event( `LOAD_ITEMS` )

                    )->tag( n = `ListItem` ns = `core`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `LOAD_ITEMS`.
      products_load( ).
    ENDIF.

  ENDMETHOD.


  METHOD products_load.

    " the mock server's ProductCollection, delivered on the first loadItems
    IF t_products IS NOT INITIAL.
      RETURN.
    ENDIF.

    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
