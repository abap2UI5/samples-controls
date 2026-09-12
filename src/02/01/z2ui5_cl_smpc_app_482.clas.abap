" @keywords standardlistitem standard list item sap.m standardlistitemnavigated
" @summary This example demonstrates the navigated property of the list item.
" @origin sap.m.sample.StandardListItemNavigated - https://sdk.openui5.org/entity/sap.m.StandardListItem/sample/sap.m.sample.StandardListItemNavigated (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_482 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name      TYPE string,
        productid TYPE string,
        navigated TYPE abap_bool,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products TYPE ty_t_product.
  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_482 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `List`
            )->a( n = `id`         v = `ShortProductList`
            )->a( n = `headerText` v = `Products (Click on an item to set as navigated)`
            )->a( n = `items`      v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

            )->ele( `items`
                " isNavigated compares the pressed ProductId with the one the settings
                " model holds - the comparison is business logic, so the flag is a
                " model field the press wire sets in ABAP
                )->tag( `StandardListItem`
                    )->a( n = `type`      v = `Active`
                    )->a( n = `title`     v = `{NAME}`
                    )->a( n = `navigated` v = `{NAVIGATED}`
                    )->a( n = `press`     v = client->_event( val = `PRESS` arg = `${PRODUCTID}` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `PRESS`.

      " onPress writes the pressed row's ProductId into the settings model, which
      " the navigated formatter compares against every row
      DATA(pressed_id) = client->get_event_arg( ).
      LOOP AT t_products ASSIGNING FIELD-SYMBOL(<product>).
        <product>-navigated = xsdbool( <product>-productid = pressed_id ).
      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
