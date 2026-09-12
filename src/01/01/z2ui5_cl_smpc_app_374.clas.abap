" @keywords select sap.m selectwithwrappeditemtext item
" @summary Illustrates how the text in items wrap.
" @origin sap.m.sample.SelectWithWrappedItemText - https://sdk.openui5.org/entity/sap.m.Select/sample/sap.m.sample.SelectWithWrappedItemText (status: reviewed)
CLASS z2ui5_cl_smpc_app_374 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid TYPE string,
        name      TYPE string,
      END OF ty_s_product.
    DATA t_products  TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_products2 TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_374 IMPLEMENTATION.

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

        )->ele( `Select`
            )->a( n = `width`         v = `300px`
            )->a( n = `wrapItemsText` v = `true`
            )->a( n = `class`         v = `sapUiLargeMargin`
            )->a( n = `items`         v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

            )->tag( n = `Item` ns = `core`
                )->a( n = `key`  v = `{PRODUCTID}`
                )->a( n = `text` v = `{NAME}`

        )->end(

        )->ele( `Select`
            )->a( n = `width`         v = `300px`
            )->a( n = `wrapItemsText` v = `true`
            )->a( n = `class`         v = `sapUiLargeMargin`
            )->a( n = `items`         v = |\{ path: '{ client->_bind_path( t_products2 ) }', sorter: \{ path: 'NAME' \} \}|

            )->tag( n = `Item` ns = `core`
                )->a( n = `key`  v = `{PRODUCTID}`
                )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " Data of the inline JSON model defined in the original sample controller
    t_products = VALUE #(
      ( productid = `HT-1001` name = `Select option 1` )
      ( productid = `HT-1002` name = `Lorem Ipsum is simply dummy text of the printing and typesetting industry.` )
      ( productid = `HT-1003` name = `Select option 3` )
      ( productid = `HT-1007` name = `Select option 4` )
      ( productid = `HT-1010` name = `Select option 5` ) ).

    t_products2 = VALUE #(
      ( productid = `key1` name = `Select option 1` )
      ( productid = `key2` name = `Lorem Ipsum is simply dummy text of the printing and typesetting industry. ` &&
                                   `Lorem Ipsum is simply dummy text of the printing and typesetting industry.` )
      ( productid = `key3` name = `Select option 3` )
      ( productid = `key4` name = `Select option 4` )
      ( productid = `key5` name = `Select option 5` ) ).

  ENDMETHOD.

ENDCLASS.
