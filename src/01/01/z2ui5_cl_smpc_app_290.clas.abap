" @keywords multiinput multi input sap.m multiinputvaluehelp selectdialog standardlistitem verticallayout label token item
" @summary MultiInput that includes a SelectDialog as a value help dialog
" @origin sap.m.sample.MultiInputValueHelp - https://sdk.openui5.org/entity/sap.m.MultiInput/sample/sap.m.sample.MultiInputValueHelp (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_290 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
        selected      TYPE abap_bool,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_token,
        text TYPE string,
      END OF ty_s_token.
    TYPES ty_t_token TYPE STANDARD TABLE OF ty_s_token WITH EMPTY KEY.

    DATA t_products TYPE ty_t_product.
    DATA t_tokens   TYPE ty_t_token.
    DATA value      TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_290 IMPLEMENTATION.

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

        " the value help of Dialog.fragment.xml, declared as a dependent and
        " opened by id - the fragment root itself has no counterpart
        )->ele( n = `dependents` ns = `mvc`

            )->ele( `SelectDialog`
                )->a( n = `id`          v = `valueHelpDialog`
                )->a( n = `title`       v = `Products`
                )->a( n = `items`       v = client->_bind( t_products )
                )->a( n = `search`      v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                      t_arg = VALUE #( ( `valueHelpDialog` ) ( `items` ) ( `filter` ) ( `NAME` ) ( `Contains` ) ( `${$parameters>/value}` ) ) )
                )->a( n = `confirm`     v = client->_event( `VALUE_HELP_CLOSE` )
                )->a( n = `cancel`      v = client->_event( `VALUE_HELP_CLOSE` )
                )->a( n = `multiSelect` v = `true`

                )->tag( `StandardListItem`
                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `description`      v = `{PRODUCTID}`
                    " added: the confirmed selection is read server-side from the
                    " rows instead of from the event's selectedItems controls
                    )->a( n = `selected`         v = `{SELECTED}`

            )->end(
        )->end(

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Enter a search term, e.g. “Notebook”, and add matching products as tokens`
                )->a( n = `width`    v = `100%`
                )->a( n = `labelFor` v = `multiInput`

            )->ele( `MultiInput`
                )->a( n = `width`            v = `40%`
                )->a( n = `id`               v = `multiInput`
                )->a( n = `value`            v = client->_bind( value )
                )->a( n = `tokens`           v = client->_bind( t_tokens )
                )->a( n = `suggestionItems`  v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|
                )->a( n = `valueHelpRequest` v = client->_event( `VALUE_HELP` )

                )->ele( `tokens`
                    )->tag( `Token`
                        )->a( n = `text` v = `{TEXT}`

                )->end(

                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{PRODUCTID}`
                    )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

    " onInit: oModel.setSizeLimit(1000000) - the ABAP table travels in full, but
    " the CLIENT-side JSONModel still caps a bound aggregation at 100, and
    " Input.updateSuggestionItems goes through updateAggregation with no explicit
    " length, so the last 23 of the 123 products never reach suggestionItems.
    " The SelectDialog beside it needs nothing: SelectDialog.growing defaults
    " true and growing always passes a length, which skips the cap
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = VALUE #( ( `1000000` ) ( client->cs_view-main ) ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `VALUE_HELP`.
        " handleValueHelp: filter the dialog binding by what was typed, then
        " open it with that same value in its search field
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = VALUE #( ( `valueHelpDialog` ) ( `items` ) ( `filter` ) ( `NAME` ) ( `Contains` ) ( value ) ) ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `valueHelpDialog` ) ( `open` ) ( value ) ) ).

      WHEN `VALUE_HELP_CLOSE`.
        " _handleValueHelpClose adds one Token per selected item; the selection
        " arrives in the rows themselves, so the tokens are built from them
        LOOP AT t_products REFERENCE INTO DATA(product) WHERE selected = abap_true.
          t_tokens = VALUE #( BASE t_tokens ( text = product->name ) ).
          product->selected = abap_false.
        ENDLOOP.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " the shared demo ProductCollection (sap/ui/demo/mock/products.json) the
    " Component loads; the columns the view binds
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
