" @keywords multicombobox multi combo box sap.m multicomboboxsuggestionsandvaluestate verticallayout label item formattedtext link
" @summary MultiComboBox with suggestions and Value State Message containing a link.
" @origin sap.m.sample.MultiComboBoxSuggestionsAndValueState - https://sdk.openui5.org/entity/sap.m.MultiComboBox/sample/sap.m.sample.MultiComboBoxSuggestionsAndValueState (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_519 DEFINITION PUBLIC.

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


CLASS z2ui5_cl_smpc_app_519 IMPLEMENTATION.

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
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( n = `VerticalLayout` ns = `l`
                )->a( n = `class` v = `sapUiContentPadding`
                )->a( n = `width` v = `100%`

                )->tag( `Label`
                    )->a( n = `text`     v = `MultiComboBox with suggestions and success value state with a a long message:`
                    )->a( n = `labelFor` v = `MCBSuccess`
                )->ele( `MultiComboBox`
                    )->a( n = `id`             v = `MCBSuccess`
                    )->a( n = `class`          v = `sapUiSmallMarginBottom`
                    )->a( n = `maxWidth`       v = `500px`
                    )->a( n = `valueState`     v = `Success`
                    )->a( n = `valueStateText` v = `Success message. Extra long text used as a success message. Extra long text used as a success message - 2. Extra long text used as a success message.`
                    )->a( n = `items`          v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}`

                )->end(

                )->tag( `Label`
                    )->a( n = `text`     v = `MultiComboBox with suggestions and information value state with a a long message:`
                    )->a( n = `labelFor` v = `MCBInformation`
                )->ele( `MultiComboBox`
                    )->a( n = `id`             v = `MCBInformation`
                    )->a( n = `class`          v = `sapUiSmallMarginBottom`
                    )->a( n = `maxWidth`       v = `500px`
                    )->a( n = `valueState`     v = `Information`
                    )->a( n = `valueStateText` v = `Information message. Extra long text used as a information message. Extra long text used as a information message - 2. Extra long text used as a information message.`
                    )->a( n = `items`          v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}`

                )->end(

                )->tag( `Label`
                    )->a( n = `text`     v = `MultiComboBox with suggestions and an information value state with multiple links:`
                    )->a( n = `labelFor` v = `MCBInformationLinks`
                )->ele( `MultiComboBox`
                    )->a( n = `id`         v = `MCBInformationLinks`
                    )->a( n = `class`      v = `sapUiSmallMarginBottom`
                    )->a( n = `maxWidth`   v = `500px`
                    )->a( n = `valueState` v = `Information`
                    )->a( n = `items`      v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}`

                    )->ele( `formattedValueStateText`
                        )->ele( `FormattedText`
                            )->a( n = `htmlText` v = `Value state with FormattedText used as an information message containing %%0 %%1.`

                            )->ele( `controls`
                                )->tag( `Link`
                                    )->a( n = `text`  v = `multiple`
                                    )->a( n = `href`  v = ``
                                    )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                    t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `Link pressed` ) ) )
                                )->tag( `Link`
                                    )->a( n = `text`  v = `links`
                                    )->a( n = `href`  v = ``
                                    )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                    t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `Link pressed` ) ) )

                            )->end(
                        )->end(
                    )->end(
                )->end(

                )->tag( `Label`
                    )->a( n = `text`     v = `MultiComboBox with suggestions and warning value state with a a long message:`
                    )->a( n = `labelFor` v = `MCBWarning`
                )->ele( `MultiComboBox`
                    )->a( n = `id`             v = `MCBWarning`
                    )->a( n = `class`          v = `sapUiSmallMarginBottom`
                    )->a( n = `maxWidth`       v = `500px`
                    )->a( n = `valueState`     v = `Warning`
                    )->a( n = `valueStateText` v = `Warning message. Extra long text used as a warning message. Extra long text used as a information message - 2. Extra long text used as a warning message.`
                    )->a( n = `items`          v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}`

                )->end(

                )->tag( `Label`
                    )->a( n = `text`     v = `MultiComboBox with suggestions and a warning value state with a link:`
                    )->a( n = `labelFor` v = `MCBWarningLink`
                )->ele( `MultiComboBox`
                    )->a( n = `id`             v = `MCBWarningLink`
                    )->a( n = `class`          v = `sapUiSmallMarginBottom`
                    )->a( n = `maxWidth`       v = `500px`
                    )->a( n = `valueState`     v = `Warning`
                    )->a( n = `valueStateText` v = `Warning message. Extra long text used as a warning message.`
                    )->a( n = `items`          v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}`

                    )->ele( `formattedValueStateText`
                        )->ele( `FormattedText`
                            )->a( n = `htmlText` v = `Value state with FormattedText used as a warning message containing a %%0.`

                            )->ele( `controls`
                                )->tag( `Link`
                                    )->a( n = `text`  v = `link`
                                    )->a( n = `href`  v = ``
                                    )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                                    t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `Link pressed` ) ) )

                            )->end(
                        )->end(
                    )->end(
                )->end(

                )->tag( `Label`
                    )->a( n = `text`     v = `MultiComboBox with suggestions and an error value state with a a long message:`
                    )->a( n = `labelFor` v = `MCBError`
                )->ele( `MultiComboBox`
                    )->a( n = `id`             v = `MCBError`
                    )->a( n = `class`          v = `sapUiSmallMarginBottom`
                    )->a( n = `maxWidth`       v = `500px`
                    )->a( n = `valueState`     v = `Error`
                    )->a( n = `valueStateText` v = `Error message. Extra long text used as a warning message. Extra long text used as an error message - 2. Extra long text used as an error message.`
                    )->a( n = `items`          v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{PRODUCTID}`
                        )->a( n = `text` v = `{NAME}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
