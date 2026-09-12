" @keywords list sap.m listselection overflowtoolbar title toolbarspacer select item standardlistitem
" @summary 'Single selection' forces the user to choose exactly one out of many items. With the 'multi' selection the user can pick multiple items at the same time. This is helpful for e.g. batch processing.
" @origin sap.m.sample.ListSelection - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListSelection (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_224 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA mode       TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_224 IMPLEMENTATION.

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
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`

        )->ele( `List`
            )->a( n = `id`                     v = `ProductList`
            )->a( n = `items`                  v = client->_bind( t_products )
            )->a( n = `mode`                   v = client->_bind( mode )
            )->a( n = `includeItemInSelection` v = `true`

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->ele( `content`
                        )->tag( `Title`
                            )->a( n = `text`  v = `Products`
                            )->a( n = `level` v = `H2`
                        )->tag( `ToolbarSpacer`

                        )->ele( `Select`
                            )->a( n = `selectedKey` v = client->_bind( mode )

                            )->ele( `items`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `None`
                                    )->a( n = `text` v = `No Selection`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `SingleSelect`
                                    )->a( n = `text` v = `Single Selection`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `SingleSelectLeft`
                                    )->a( n = `text` v = `Single Selection Left`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `SingleSelectMaster`
                                    )->a( n = `text` v = `Single Selection (Master)`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `MultiSelect`
                                    )->a( n = `text` v = `Multi Selection`

                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(

            )->ele( `items`
                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `description`      v = `{PRODUCTID}`
                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`

            )->end(
        )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    mode = `MultiSelect`.

    " full mock /ProductCollection (sap/ui/demo/mock/products.json) of the original sample
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
