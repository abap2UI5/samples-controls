" @keywords table sap.m tableselectcopy cellselector overflowtoolbar title toolbarspacer checkbox column text columnlistitem objectidentifier
" @summary This example demonstrates how the Table data can be copied to the clipboard via CopyProvider plugin.
" @origin sap.m.sample.TableSelectCopy - https://sdk.openui5.org/entity/sap.m.Table/sample/sap.m.sample.TableSelectCopy (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_523 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name         TYPE string,
        productid    TYPE string,
        suppliername TYPE string,
        quantity     TYPE string,
        uom          TYPE string,
        price        TYPE p LENGTH 8 DECIMALS 2,
        currencycode TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products  TYPE ty_t_product.
    DATA copy_visible TYPE abap_bool VALUE abap_true.
    DATA copy_enabled TYPE abap_bool VALUE abap_true.
    DATA copy_sparse  TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_523 IMPLEMENTATION.

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
        )->a( n = `xmlns`         v = `sap.m`
        )->a( n = `xmlns:core`    v = `sap.ui.core`
        )->a( n = `xmlns:mvc`     v = `sap.ui.core.mvc`
        )->a( n = `xmlns:plugins` v = `sap.m.plugins`
        )->a( n = `xmlns:app`     v = `http://schemas.sap.com/sapui5/extension/sap.ui.core.CustomData/1`

        )->ele( `Table`
            )->a( n = `id`      v = `idProductsTable`
            )->a( n = `growing` v = `true`
            )->a( n = `mode`    v = `MultiSelect`
            )->a( n = `items`   v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

            " only the CellSelector - the CopyProvider is dropped, it refuses to be
            " created without the extractData JS callback (see sidecar)
            )->ele( `dependents`
                )->tag( n = `CellSelector` ns = `plugins`
                    )->a( n = `id` v = `cellSelector`

            )->end(

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->a( n = `id` v = `toolbar`

                    )->tag( `Title`
                        )->a( n = `text`  v = `Products`
                        )->a( n = `level` v = `H2`
                    )->tag( `ToolbarSpacer`
                    )->tag( `CheckBox`
                        )->a( n = `text`     v = `Visible`
                        )->a( n = `selected` v = client->_bind( copy_visible )
                    )->tag( `CheckBox`
                        )->a( n = `text`     v = `Enabled`
                        )->a( n = `selected` v = client->_bind( copy_enabled )
                    )->tag( `CheckBox`
                        )->a( n = `text`     v = `Sparse`
                        )->a( n = `selected` v = client->_bind( copy_sparse )

                )->end(
            )->end(

            )->ele( `columns`
                )->ele( `Column`
                    )->a( n = `width`        v = `16em`
                    )->a( n = `app:bindings` v = `ProductId,Name`
                    )->a( n = `app:template` v = `\{1\}\n\{0\}`

                    )->tag( `Text`
                        )->a( n = `text` v = `Product`

                )->end(

                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Desktop`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `app:bindings`   v = `SupplierName`

                    )->tag( `Text`
                        )->a( n = `text` v = `Supplier`

                )->end(

                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Desktop`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `End`
                    )->a( n = `app:bindings`   v = `Quantity,UoM`
                    )->a( n = `app:template`   v = `\{0\} \{1\}`

                    )->tag( `Text`
                        )->a( n = `text` v = `Quantity`

                )->end(

                )->ele( `Column`
                    )->a( n = `width`        v = `10em`
                    )->a( n = `hAlign`       v = `End`
                    )->a( n = `app:bindings` v = `Price,CurrencyCode`
                    )->a( n = `app:template` v = `\{0\} \{1\}`

                    )->tag( `Text`
                        )->a( n = `text` v = `Price`

                )->end(
            )->end(

            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->a( n = `vAlign` v = `Middle`

                    )->ele( `cells`
                        )->tag( `ObjectIdentifier`
                            )->a( n = `title` v = `{NAME}`
                            )->a( n = `text`  v = `{PRODUCTID}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{SUPPLIERNAME}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{QUANTITY} {UOM}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = |\{ parts: [\{path: 'PRICE'\}, \{path: 'CURRENCYCODE'\}], type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: false\} \}|
                            )->a( n = `unit`   v = `{CURRENCYCODE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
