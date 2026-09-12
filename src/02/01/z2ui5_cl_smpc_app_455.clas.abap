" @keywords combobox combo box sap.m comboboxclearicon item
" @summary The combo box control can show 'clear' icon, which when pressed will remove the user's input and selected key.
" @origin sap.m.sample.ComboBoxClearIcon - https://sdk.openui5.org/entity/sap.m.ComboBox/sample/sap.m.sample.ComboBoxClearIcon (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_455 DEFINITION PUBLIC.

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


CLASS z2ui5_cl_smpc_app_455 IMPLEMENTATION.

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
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`
            )->a( n = `class`      v = `sapUiContentPadding`

            )->ele( `content`
                )->ele( `ComboBox`
                    )->a( n = `width`         v = `300px`
                    " showClearIcon is @since 1.96 - the subject of the sample
                    )->a( n = `showClearIcon` v = `true`
                    )->a( n = `items`         v = client->_bind( t_products )

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the two bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).


  ENDMETHOD.

ENDCLASS.
