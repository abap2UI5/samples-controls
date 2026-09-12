" @keywords multiinput multi input sap.m multiinputdatabinding verticallayout label token
" @summary MultiInput data binding allows data to be bound to tokens in MultiInput.
" @origin sap.m.sample.MultiInputDatabinding - https://sdk.openui5.org/entity/sap.m.MultiInput/sample/sap.m.sample.MultiInputDatabinding (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_457 DEFINITION PUBLIC.

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
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_457 IMPLEMENTATION.

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
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Token data binding`
                )->a( n = `labelFor` v = `multiinput1`
            )->ele( `MultiInput`
                )->a( n = `id`             v = `multiinput1`
                )->a( n = `showValueHelp`  v = `false`
                )->a( n = `showSuggestion` v = `false`
                )->a( n = `tokens`         v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                )->ele( `tokens`
                    )->tag( `Token`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
