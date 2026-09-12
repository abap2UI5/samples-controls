" @keywords list sap.m listgrowing standardlistitem
" @summary The Growing feature helps if your content is too big to be loaded/shown at once. It paginates the content into smaller chunks - aka pages - which are loaded/shown one after another. Random access to pages (e.
" @origin sap.m.sample.ListGrowing - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListGrowing (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_276 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_product.
    DATA t_products TYPE STANDARD TABLE OF ty_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_276 IMPLEMENTATION.

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

    " growing is a pure client-side feature of sap.m.List: the whole
    " collection is in the model and the control pages through it, so the
    " port has no growing wire at all - the app stays init-only
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`

        )->ele( `List`
            )->a( n = `items`               v = client->_bind( t_products )
            )->a( n = `headerText`          v = `Products`
            )->a( n = `growing`             v = `true`
            )->a( n = `growingThreshold`    v = `4`
            )->a( n = `growingScrollToLoad` v = `false`

            )->tag( `StandardListItem`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `description`      v = `{PRODUCTID}`
                )->a( n = `icon`             v = `{PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false`

                ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " the shared demo products.json /ProductCollection, all 123 rows; the
    " StandardListItem binds Name, ProductId and ProductPicUrl (host-
    " absolutized per the runtime asset-URL rule)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
