" @keywords input sap.m inputassisted verticallayout label item selectdialog standardlistitem
" @summary Assisted input is available via suggestions - shown as you type - and a value help dialog.
" @origin sap.m.sample.InputAssisted - https://sdk.openui5.org/entity/sap.m.Input/sample/sap.m.sample.InputAssisted (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_515 DEFINITION PUBLIC.

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


CLASS z2ui5_cl_smpc_app_515 IMPLEMENTATION.

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
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Product`
                )->a( n = `labelFor` v = `productInput`
            " onValueHelpRequest loads ValueHelpDialog.fragment.xml, pre-filters it by
            " the input's value and opens it - the same fragment, shown with
            " popup_display and pre-filtered on the same round-trip
            )->ele( `Input`
                )->a( n = `id`               v = `productInput`
                )->a( n = `placeholder`      v = `Enter product`
                )->a( n = `showSuggestion`   v = `true`
                )->a( n = `showValueHelp`    v = `true`
                )->a( n = `value`            v = client->_bind( value )
                )->a( n = `valueHelpRequest` v = client->_event( `VALUE_HELP` )
                )->a( n = `suggestionItems`  v = client->_bind( t_products )

                )->ele( `suggestionItems`
                    )->tag( n = `Item` ns = `core`
                        )->a( n = `text` v = `{NAME}`

                )->end(
            )->end(
        )->end(

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `No typeahead`
                )->a( n = `labelFor` v = `productInputTypeAhead`
            )->ele( `Input`
                )->a( n = `id`               v = `productInputTypeAhead`
                )->a( n = `placeholder`      v = `Enter product`
                )->a( n = `autocomplete`     v = `false`
                )->a( n = `showSuggestion`   v = `true`
                )->a( n = `showValueHelp`    v = `true`
                )->a( n = `valueHelpRequest` v = client->_event( `VALUE_HELP` )
                )->a( n = `suggestionItems`  v = client->_bind( t_products )

                )->ele( `suggestionItems`
                    )->tag( n = `Item` ns = `core`
                        )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

    " onInit: oModel.setSizeLimit(100000) - "The default limit of the model is set
    " to 100. We want to show all the entries." Without it both Inputs' bound
    " suggestionItems stop at 100 of the 123 products (the app-252 / app-444 idiom)
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = VALUE #( ( `100000` ) ( client->cs_view-main ) ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `VALUE_HELP`.
        popup_value_help_display( ).
        " the original pre-filters the dialog by the input's current value
        IF value IS NOT INITIAL.
          client->follow_up_action( val   = client->cs_event-binding_call
                                    t_arg = VALUE #( ( `selectDialog` ) ( `items` ) ( `filter` )
                                                     ( `NAME` ) ( `Contains` ) ( value ) ) ).
        ENDIF.

      WHEN `VALUE_HELP_SEARCH`.
        DATA(term) = client->get_event_arg( ).
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = VALUE #( ( `selectDialog` ) ( `items` ) ( `filter` )
                                                   ( `NAME` ) ( `Contains` ) ( term ) ) ).

      WHEN `VALUE_HELP_CLOSE`.
        " onValueHelpClose writes the picked title into the first Input
        DATA(title) = client->get_event_arg( ).
        IF title IS NOT INITIAL.
          value = title.
        ENDIF.
        client->popup_destroy( ).

    ENDCASE.

  ENDMETHOD.


  METHOD popup_value_help_display.

    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `SelectDialog`
            )->a( n = `id`      v = `selectDialog`
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

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields);
    " the original raises the model's size limit so every row is offered
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
