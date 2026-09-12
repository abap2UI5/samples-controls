" @keywords standardlistitem standard list item sap.m standardlistitemtitle
" @summary By default the title size adapts to the available space and gets bigger if the description is empty. List items with and without descriptions results in titles with different sizes. In this cases it is better to switch the size adaption off.
" @origin sap.m.sample.StandardListItemTitle - https://sdk.openui5.org/entity/sap.m.StandardListItem/sample/sap.m.sample.StandardListItemTitle (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_483 DEFINITION PUBLIC.

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


CLASS z2ui5_cl_smpc_app_483 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        " onInit calls list.bindElement('/ProductCollection'), so the four items
        " address the first four records relative to that context
        )->ele( `List`
            )->a( n = `id`         v = `ShortProductList`
            )->a( n = `headerText` v = `Products`
            )->a( n = `binding`    v = |\{{ client->_bind_path( t_products ) }\}|

            )->ele( `items`
                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{0/NAME}`
                    )->a( n = `description`      v = `{0/PRODUCTID}`
                    )->a( n = `icon`             v = `{0/PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `adaptTitleSize`   v = `false`
                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{1/NAME}`
                    " the sample sets this item's description explicitly empty
                    )->a( n = `description`      v = ``
                    )->a( n = `icon`             v = `{1/PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `adaptTitleSize`   v = `false`
                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{2/NAME}`
                    )->a( n = `description`      v = `{2/PRODUCTID}`
                    )->a( n = `icon`             v = `{2/PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `adaptTitleSize`   v = `false`
                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{3/NAME}`
                    )->a( n = `icon`             v = `{3/PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `adaptTitleSize`   v = `false` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
