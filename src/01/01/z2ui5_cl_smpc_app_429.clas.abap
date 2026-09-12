" @keywords list sap.m listnavtype standardlistitem
" @summary If only a subset of the list items are navigable you should indicate those by setting their 'type' to 'Navigation'. This displays an navigation arrow. Do not show arrows if all items are navigable.
" @origin sap.m.sample.ListNavType - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListNavType (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_429 DEFINITION PUBLIC.

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

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_429 IMPLEMENTATION.

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

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`

        " the List carries the element binding of the whole collection, the three
        " items address the first three records relative to it - 1:1 with the original
        )->ele( `List`
            )->a( n = `headerText` v = `Products`
            )->a( n = `binding`    v = |\{{ client->_bind_path( t_products ) }\}|

            )->tag( `StandardListItem`
                )->a( n = `title`            v = `{0/NAME}`
                )->a( n = `description`      v = `{0/PRODUCTID}`
                )->a( n = `icon`             v = `{0/PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false`
                )->a( n = `type`             v = `Navigation`
            )->tag( `StandardListItem`
                )->a( n = `title`            v = `{1/NAME}`
                )->a( n = `description`      v = `{1/PRODUCTID}`
                )->a( n = `icon`             v = `{1/PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false`
                )->a( n = `type`             v = `Navigation`
            )->tag( `StandardListItem`
                )->a( n = `title`            v = `{2/NAME}`
                )->a( n = `description`      v = `{2/PRODUCTID}`
                )->a( n = `icon`             v = `{2/PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
