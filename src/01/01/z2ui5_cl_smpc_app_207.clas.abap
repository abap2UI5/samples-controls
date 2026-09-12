" @keywords list sap.m listitemtypes overflowtoolbar title toolbarspacer label select item standardlistitem
" @summary You can use the 'type' property of any list item, which inherits from ListItemBase control, to demonstrate all possible types (see sap.m.ListType).
" @origin sap.m.sample.ListItemTypes - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListItemTypes (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_207 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA listtype TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_207 IMPLEMENTATION.

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
            )->a( n = `includeItemInSelection` v = `true`

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->ele( `content`
                        )->tag( `Title`
                            )->a( n = `text`  v = `Products`
                            )->a( n = `level` v = `H2`
                        )->tag( `ToolbarSpacer`
                        )->tag( `Label`
                            )->a( n = `text`     v = `List Item type:`
                            )->a( n = `labelFor` v = `state`

                        " the Select's change handler is replaced by a two-way binding:
                        " selectedKey and every item's type share the LISTTYPE field, so a
                        " selection re-types all items client-side (original: handleSelectChange)
                        )->ele( `Select`
                            )->a( n = `id`          v = `state`
                            )->a( n = `selectedKey` v = client->_bind( listtype )

                            )->ele( `items`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `Inactive`
                                    )->a( n = `text` v = `Inactive`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `Active`
                                    )->a( n = `text` v = `Active`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `Navigation`
                                    )->a( n = `text` v = `Navigation`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `Detail`
                                    )->a( n = `text` v = `Detail`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `key`  v = `DetailAndActive`
                                    )->a( n = `text` v = `Detail And Active`

                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
            )->tag( `StandardListItem`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `description`      v = `{PRODUCTID}`
                )->a( n = `icon`             v = `{PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false`
                " absolute binding (client->_bind), NOT the relative {LISTTYPE}:
                " the shared field lives at the model ROOT, while the template
                " resolves relative paths against the row - a row has no
                " LISTTYPE, so the relative form never followed the Select
                " (found by the e2e interaction 2026-07-31)
                )->a( n = `type`             v = client->_bind( listtype )
                )->a( n = `press`            v = client->follow_up_action( val = client->cs_event-control_global t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `'press' event fired!` ) ) )
                )->a( n = `detailPress`      v = client->follow_up_action( val = client->cs_event-control_global t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `'detailPress' event fired!` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " the shared mock /ProductCollection (ui5/mock/products.json), the three bound
    " columns Name/ProductId/ProductPicUrl, all 123 rows kept verbatim
    " (ProductPicUrl rewritten to the OpenUI5 host per the asset-URL rule)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

    " the Select and every item's type share this two-way bound field; the
    " original seeds the Select with selectedKey="Inactive"
    listtype = `Inactive`.

  ENDMETHOD.

ENDCLASS.
