" @keywords multicombobox multi combo box sap.m multicomboboxselectall verticallayout item
" @summary MultiComboBox with enabled Select All feature inside suggestions.
" @origin sap.m.sample.MultiComboBoxSelectAll - https://sdk.openui5.org/entity/sap.m.MultiComboBox/sample/sap.m.sample.MultiComboBoxSelectAll (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_281 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid TYPE string,
        name      TYPE string,
      END OF ty_s_product.
    DATA t_products      TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_selected_keys TYPE string_table.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_281 IMPLEMENTATION.

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
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `height`     v = `100%`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->ele( `MultiComboBox`
                )->a( n = `selectionChange` v = client->_event( val = `SELECTION_CHANGE` t_arg = VALUE #( ( `${$parameters>/changedItem}.getText()` ) ( `${$parameters>/selected}` ) ) )
                )->a( n = `selectionFinish` v = client->_event( `SELECTION_FINISH` )
                )->a( n = `showSelectAll`   v = `true`
                )->a( n = `width`           v = `350px`
                )->a( n = `items`           v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|
                " added binding: the selected keys must reach the backend for the
                " selectionFinish text (the original reads getSelectedItems in the controller)
                )->a( n = `selectedKeys`    v = client->_bind( t_selected_keys )

                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{PRODUCTID}`
                    )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SELECTION_CHANGE`.

        client->message_toast_display(
          text  = |Event 'selectionChange': { COND string( WHEN client->get_event_arg( 2 ) = abap_true THEN `Selected` ELSE `Deselected` ) } '{ client->get_event_arg( ) }'|
          width = `auto` ).

      WHEN `SELECTION_FINISH`.

        DATA(names) = ``.
        LOOP AT t_selected_keys INTO DATA(key).
          names = |{ names }{ COND string( WHEN sy-tabix > 1 THEN `,` ) }'{ VALUE #( t_products[ productid = key ]-name OPTIONAL ) }'|.
        ENDLOOP.

        client->message_toast_display( text = |Event 'selectionFinished': [{ names }]| width = `auto` ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " /ProductCollection of sap/ui/demo/mock/products.json - the two bound keys of every row
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
