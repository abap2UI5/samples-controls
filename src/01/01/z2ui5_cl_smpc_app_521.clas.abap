" @keywords input sap.m inputkeyvalue verticallayout label listitem text selectdialog standardlistitem
" @summary This sample illustrates how the Input works with key and value values, when the data is available via list of suggestions.
" @origin sap.m.sample.InputKeyValue - https://sdk.openui5.org/entity/sap.m.Input/sample/sap.m.sample.InputKeyValue (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_521 DEFINITION PUBLIC.

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
    DATA value        TYPE string.
    DATA selected_key TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS popup_value_help_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_521 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Product`
                )->a( n = `labelFor` v = `productInput`
            " onValueHelpRequest loads ValueHelpDialog.fragment.xml, pre-filters it by
            " the input's value and opens it - the same fragment via popup_display
            )->ele( `Input`
                )->a( n = `id`                     v = `productInput`
                )->a( n = `textFormatMode`         v = `KeyValue`
                " selectedKey is bindable, and a property-binding update calls the
                " control's own setSelectedKey (ManagedObjectBindingSupport), so the
                " KeyValue rendering `(HT-1000) Notebook Basic 15` comes out of the
                " model - and survives a view rebuild, which a control call would not
                )->a( n = `selectedKey`            v = client->_bind( selected_key )
                )->a( n = `placeholder`            v = `Enter product`
                )->a( n = `showSuggestion`         v = `true`
                )->a( n = `showValueHelp`          v = `true`
                )->a( n = `value`                  v = client->_bind( value )
                )->a( n = `valueHelpRequest`       v = client->_event( `VALUE_HELP` )
                )->a( n = `suggestionItems`        v = client->_bind( t_products )
                " onSuggestionItemSelected shows the picked item's key
                )->a( n = `suggestionItemSelected` v = client->_event( val = `ITEM_SELECTED` arg = `${$parameters>/selectedItem}.getKey()` )

                )->ele( `suggestionItems`
                    )->tag( n = `ListItem` ns = `core`
                        )->a( n = `key`            v = `{PRODUCTID}`
                        )->a( n = `text`           v = `{NAME}`
                        )->a( n = `additionalText` v = `{PRODUCTID}`

                )->end(
            )->end(

            )->tag( `Label`
                )->a( n = `text`     v = `Selected Key`
                )->a( n = `labelFor` v = `selectedKey`
            )->tag( `Text`
                )->a( n = `id`   v = `selectedKeyIndicator`
                )->a( n = `text` v = client->_bind( selected_key ) ).

    client->view_display( view->stringify( ) ).

    " onInit: oModel.setSizeLimit(100000) - without it the JSONModel caps a bound
    " aggregation at 100 and the last 23 of the 123 products never reach the
    " suggestion list (the app-252 / app-444 idiom)
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

      WHEN `ITEM_SELECTED`.
        selected_key = client->get_event_arg( ).

      WHEN `VALUE_HELP_CLOSE`.
        " onValueHelpDialogClose reads the item's DESCRIPTION - the ProductId - and
        " writes it to BOTH setSelectedKey on the Input and setText on the indicator
        DATA(picked_key) = client->get_event_arg( ).
        IF picked_key IS NOT INITIAL.
          " one field drives both: the Input's selectedKey (which renders the
          " `(key) text` form) and the indicator Text - the original sets both to
          " the same description, and a suggestion pick lands on the same value
          selected_key = picked_key.
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
            )->a( n = `confirm` v = client->_event( val = `VALUE_HELP_CLOSE` arg = `${$parameters>/selectedItem}.getDescription()` )
            )->a( n = `cancel`  v = client->_event( `VALUE_HELP_CLOSE` )

            )->tag( `StandardListItem`
                )->a( n = `icon`             v = `{PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `description`      v = `{PRODUCTID}` ).

    client->popup_display( popup->stringify( ) ).

    " the popup slot keeps its own model, so the raised limit has to be repeated
    " for it or the dialog itself stops at 100 rows
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = VALUE #( ( `100000` ) ( client->cs_view-popup ) ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields);
    " the original raises the model's size limit so every row is offered
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
