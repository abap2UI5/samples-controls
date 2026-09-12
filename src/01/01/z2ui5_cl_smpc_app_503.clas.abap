" @keywords input sap.m inputkeyvaluetabularsuggestions verticallayout label column columnlistitem text
" @summary This sample illustrates how the Input works with key and value values, when the data is provided with table-like suggestions.
" @origin sap.m.sample.InputKeyValueTabularSuggestions - https://sdk.openui5.org/entity/sap.m.Input/sample/sap.m.sample.InputKeyValueTabularSuggestions (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_503 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name         TYPE string,
        productid    TYPE string,
        suppliername TYPE string,
        price        TYPE p LENGTH 8 DECIMALS 2,
        currencycode TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products   TYPE ty_t_product.
    DATA selected_key TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_503 IMPLEMENTATION.

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
        )->a( n = `xmlns:l`   v = `sap.ui.layout`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Product`
                )->a( n = `labelFor` v = `productInput`

            )->ele( `Input`
                )->a( n = `id`                           v = `productInput`
                )->a( n = `textFormatMode`               v = `ValueKey`
                )->a( n = `placeholder`                  v = `Enter Product ...`
                )->a( n = `showSuggestion`               v = `true`
                )->a( n = `showTableSuggestionValueHelp` v = `false`
                )->a( n = `suggestionRows`               v = client->_bind( t_products )
                " onSuggestionItemSelected reads the Input's selectedKey, which the JS
                " suggestionRowValidator fills from the row's second cell - the same
                " cell travels straight from the selected row instead
                )->a( n = `suggestionItemSelected`       v = client->_event( val = `ITEM_SELECTED` arg = `${$parameters>/selectedRow}.getCells()[1].getText()` )

                )->ele( `suggestionColumns`
                    )->ele( `Column`
                        )->a( n = `popinDisplay` v = `Inline`
                        )->a( n = `demandPopin`  v = `true`

                        )->tag( `Label`
                            )->a( n = `text` v = `Name`

                    )->end(

                    )->ele( `Column`
                        )->a( n = `hAlign`         v = `Center`
                        )->a( n = `popinDisplay`   v = `Inline`
                        )->a( n = `demandPopin`    v = `true`
                        )->a( n = `minScreenWidth` v = `Tablet`

                        )->tag( `Label`
                            )->a( n = `text` v = `Product ID`

                    )->end(

                    )->ele( `Column`
                        )->a( n = `hAlign`         v = `Center`
                        )->a( n = `popinDisplay`   v = `Inline`
                        )->a( n = `minScreenWidth` v = `Tablet`

                        )->tag( `Label`
                            )->a( n = `text` v = `Supplier Name`

                    )->end(

                    )->ele( `Column`
                        )->a( n = `hAlign`       v = `End`
                        )->a( n = `popinDisplay` v = `Inline`
                        )->a( n = `demandPopin`  v = `true`

                        )->tag( `Label`
                            )->a( n = `text` v = `Price`

                    )->end(
                )->end(

                )->ele( `suggestionRows`
                    )->ele( `ColumnListItem`
                        )->tag( `Label`
                            )->a( n = `text` v = `{NAME}`
                        )->tag( `Label`
                            )->a( n = `text` v = `{PRODUCTID}`
                        )->tag( `Label`
                            )->a( n = `text` v = `{SUPPLIERNAME}`
                        )->tag( `Label`
                            )->a( n = `text` v = |\{ parts:[\{path:'PRICE'\}, \{path:'CURRENCYCODE'\}], type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: true\} \}|

                    )->end(
                )->end(
            )->end(

            )->tag( `Label`
                )->a( n = `text`     v = `Selected Key`
                )->a( n = `labelFor` v = `selectedKeyIndicator`
            )->tag( `Text`
                )->a( n = `id`   v = `selectedKeyIndicator`
                )->a( n = `text` v = client->_bind( selected_key ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `ITEM_SELECTED`.
      selected_key = client->get_event_arg( ).
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
