" @keywords multiinput multi input sap.m provides functionality add verticallayout label item token multiinputext
" @summary MultiInput provides functionality to add / remove / enter tokens.
" @origin sap.m.sample.MultiInput - https://sdk.openui5.org/entity/sap.m.MultiInput/sample/sap.m.sample.MultiInput (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_040 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid TYPE string,
        name      TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_040 IMPLEMENTATION.

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
        )->a( n = `height`      v = `100%`
        )->a( n = `xmlns`       v = `sap.m`
        )->a( n = `xmlns:mvc`   v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`     v = `sap.ui.layout`
        )->a( n = `xmlns:core`  v = `sap.ui.core`
        )->a( n = `xmlns:z2ui5` v = `z2ui5.cc`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Enter a search term, e.g. “Notebook”, and add matching products as tokens`
                )->a( n = `width`    v = `100%`
                )->a( n = `labelFor` v = `multiInput`

            )->ele( `MultiInput`
                )->a( n = `width`           v = `70%`
                )->a( n = `showClearIcon`   v = `true`
                )->a( n = `id`              v = `multiInput`
                )->a( n = `suggestionItems` v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|
                )->a( n = `placeholder`     v = `Products...`
                )->a( n = `showValueHelp`   v = `false`

                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{PRODUCTID}`
                    )->a( n = `text` v = `{NAME}`

            )->end(
            )->tag( `Label`
                )->a( n = `text`     v = `MultiInput with pre-selected tokens`
                )->a( n = `labelFor` v = `multiInput1`

            " the tokens the original controller pre-sets in onInit
            )->ele( `MultiInput`
                )->a( n = `id`             v = `multiInput1`
                )->a( n = `showSuggestion` v = `false`
                )->a( n = `width`          v = `70%`
                )->a( n = `showValueHelp`  v = `false`

                )->ele( `tokens`
                    )->tag( `Token`
                        )->a( n = `key`  v = `0001`
                        )->a( n = `text` v = `Token 1`
                    )->tag( `Token`
                        )->a( n = `key`  v = `0002`
                        )->a( n = `text` v = `Token 2`
                    )->tag( `Token`
                        )->a( n = `key`  v = `0003`
                        )->a( n = `text` v = `Token 3`
                    )->tag( `Token`
                        )->a( n = `key`  v = `0004`
                        )->a( n = `text` v = `Token 4`
                    )->tag( `Token`
                        )->a( n = `key`  v = `0005`
                        )->a( n = `text` v = `Token 5`
                    )->tag( `Token`
                        )->a( n = `key`  v = `0006`
                        )->a( n = `text` v = `Token 6`

                )->end(
            )->end(
            " original onInit addValidator on multiInput1, installed by the invisible z2ui5.cc.MultiInputExt companion
            )->tag( n = `MultiInputExt` ns = `z2ui5`
                )->a( n = `MultiInputId` v = `multiInput1`
            )->tag( `Label`
                )->a( n = `text`     v = `MultiInput with single long token`
                )->a( n = `labelFor` v = `multiInput2`

            )->ele( `MultiInput`
                )->a( n = `id`             v = `multiInput2`
                )->a( n = `showSuggestion` v = `false`
                )->a( n = `width`          v = `300px`
                )->a( n = `showValueHelp`  v = `false`

                )->ele( `tokens`
                    )->tag( `Token`
                        )->a( n = `key`  v = `longText`
                        )->a( n = `text` v = `Very long long long long long long long text`

                )->end(
            )->end(
            " same validator on multiInput2, as in the original onInit
            )->tag( n = `MultiInputExt` ns = `z2ui5`
                )->a( n = `MultiInputId` v = `multiInput2` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection (sap/ui/demo/mock/products.json) of the original sample
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
