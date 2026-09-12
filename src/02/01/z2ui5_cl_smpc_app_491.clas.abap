" @keywords multicombobox multi combo box sap.m multicomboboxclearicon verticallayout item
" @summary The multi combo box control can show 'clear' icon, which when pressed will remove the user's input.
" @origin sap.m.sample.MultiComboBoxClearIcon - https://sdk.openui5.org/entity/sap.m.MultiComboBox/sample/sap.m.sample.MultiComboBoxClearIcon (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_491 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid TYPE string,
        name      TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products     TYPE ty_t_product.
    DATA t_selected_key TYPE string_table.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_491 IMPLEMENTATION.

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
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->ele( `MultiComboBox`
                " handleSelectionChange toasts the changed item and its new state -
                " composed on the client from the two event parameters
                )->a( n = `selectionChange` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                          t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` )
                                                                                           ( `Event 'selectionChange': {0?Selected:Deselected} '{1}'` )
                                                                                           ( `${$parameters>/selected}` )
                                                                                           ( `${$parameters>/changedItem}.getText()` ) ) )
                " handleSelectionFinish lists every selected item; a UI5 expression has
                " no loop, so the selection travels as the bound selectedKeys and ABAP
                " builds the same line
                )->a( n = `selectionFinish` v = client->_event( `SELECTION_FINISH` )
                )->a( n = `selectedKeys`    v = client->_bind( t_selected_key )
                )->a( n = `showClearIcon`   v = `true`
                )->a( n = `width`           v = `350px`
                )->a( n = `items`           v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{PRODUCTID}`
                    )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `SELECTION_FINISH`.

      " "Event 'selectionFinished': ['A','B']" - the texts of the selected keys in
      " SELECTION order: the original reads the selectedItems event parameter, which
      " MultiComboBox fills by addAssociation per pick, so looping the bound keys
      " (not the product table) is what reproduces it - the app-281 form
      DATA(list) = ``.
      LOOP AT t_selected_key INTO DATA(key).
        IF list IS NOT INITIAL.
          list = list && `,`.
        ENDIF.
        list = list && |'{ VALUE #( t_products[ productid = key ]-name OPTIONAL ) }'|.
      ENDLOOP.

      client->message_toast_display( text = |Event 'selectionFinished': [{ list }]| width = `auto` ).

    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
