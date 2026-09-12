" @keywords input sap.m inputcustomvaluehelpicon verticallayout label selectdialog standardlistitem
" @summary This example shows the usage of a custom value help icon instead of the default one.
" @origin sap.m.sample.InputCustomValueHelpIcon - https://sdk.openui5.org/entity/sap.m.Input/sample/sap.m.sample.InputCustomValueHelpIcon (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_510 DEFINITION PUBLIC.

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
    DATA value      TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS popup_value_help_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_510 IMPLEMENTATION.

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
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->ele( n = `content` ns = `l`
                )->tag( `Label`
                    )->a( n = `text`     v = `Select a product`
                    )->a( n = `labelFor` v = `inputValueHelpCustomIcon`
                " handleValueHelp loads Dialog.fragment.xml and opens it - the same
                " fragment is built here and shown with popup_display
                )->tag( `Input`
                    )->a( n = `id`               v = `inputValueHelpCustomIcon`
                    )->a( n = `class`            v = `sapUiSmallMarginBottom`
                    )->a( n = `type`             v = `Text`
                    )->a( n = `placeholder`      v = `Enter product`
                    )->a( n = `showValueHelp`    v = `true`
                    )->a( n = `valueHelpIconSrc` v = `sap-icon://arrow-left`
                    )->a( n = `value`            v = client->_bind( value )
                    )->a( n = `valueHelpRequest` v = client->_event( `VALUE_HELP` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `VALUE_HELP`.
        popup_value_help_display( ).

      WHEN `VALUE_HELP_CLOSE`.
        " _handleValueHelpClose writes the picked title into the Input
        DATA(title) = client->get_event_arg( ).
        IF title IS NOT INITIAL.
          value = title.
        ENDIF.
        client->popup_destroy( ).

      WHEN `VALUE_HELP_SEARCH`.
        " _handleValueHelpSearch filters the dialog's items by Name
        DATA(term) = client->get_event_arg( ).
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = VALUE #( ( `valueHelpDialog` ) ( `items` ) ( `filter` )
                                                   ( `NAME` ) ( `Contains` ) ( term ) ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD popup_value_help_display.

    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `SelectDialog`
            )->a( n = `id`      v = `valueHelpDialog`
            )->a( n = `title`   v = `Products`
            )->a( n = `items`   v = client->_bind( t_products )
            )->a( n = `search`  v = client->_event( val = `VALUE_HELP_SEARCH` arg = `${$parameters>/value}` )
            )->a( n = `confirm` v = client->_event( val = `VALUE_HELP_CLOSE` arg = `${$parameters>/selectedItem}.getTitle()` )
            )->a( n = `cancel`  v = client->_event( `VALUE_HELP_CLOSE` )

            )->tag( `StandardListItem`
                )->a( n = `icon`             v = `{PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `description`      v = `{PRODUCTID}` ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
