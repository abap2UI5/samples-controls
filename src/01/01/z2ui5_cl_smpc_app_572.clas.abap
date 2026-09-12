" @keywords table sap.m tablelayout overflowtoolbar title toolbarspacer checkbox button column text columnlistitem dialog
" @summary You can use fixedLayout property to define the layout algorithm to be used for the table cells, rows, and columns. When fixedLayout property is set to false, the width of the table and its cells depends on the content thereof.
" @origin sap.m.sample.TableLayout - https://sdk.openui5.org/entity/sap.m.Table/sample/sap.m.sample.TableLayout (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_572 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid    TYPE string,
        name         TYPE string,
        suppliername TYPE string,
        description  TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products     TYPE ty_t_product.
    " onCheckBoxSelect calls setFixedLayout on the table the CheckBox sits in;
    " the property is bindable, so each table has its own flag
    DATA fixed_layout   TYPE abap_bool VALUE abap_true.
    DATA dialog_fixed   TYPE abap_bool VALUE abap_true.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS popup_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_572 IMPLEMENTATION.

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
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`

        )->ele( `Table`
            )->a( n = `fixedLayout` v = client->_bind( fixed_layout )
            )->a( n = `items`       v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->tag( `Title`
                        )->a( n = `text`  v = `Products`
                        )->a( n = `level` v = `H2`
                    )->tag( `ToolbarSpacer`
                    )->tag( `CheckBox`
                        )->a( n = `text`     v = `Fixed Layout`
                        )->a( n = `selected` v = client->_bind( fixed_layout )
                    )->tag( `Button`
                        )->a( n = `text`  v = `Open Dialog`
                        )->a( n = `press` v = client->_event( `OPEN_DIALOG` )

                )->end(
            )->end(
            )->ele( `columns`
                )->ele( `Column`

                    )->tag( `Text`
                        )->a( n = `text` v = `Product Name`

                )->end(
                )->ele( `Column`

                    )->tag( `Text`
                        )->a( n = `text` v = `Supplier Name`

                )->end(
                )->ele( `Column`

                    )->tag( `Text`
                        )->a( n = `text` v = `Description`

                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->a( n = `vAlign` v = `Middle`
                    )->a( n = `type`   v = `Navigation`

                    )->ele( `cells`
                        )->tag( `Text`
                            )->a( n = `text`     v = `{NAME}`
                            )->a( n = `wrapping` v = `false`
                        )->tag( `Text`
                            )->a( n = `text`     v = `{SUPPLIERNAME}`
                            )->a( n = `wrapping` v = `false`
                        )->tag( `Text`
                            )->a( n = `text` v = `{DESCRIPTION}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD popup_display.

    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Dialog`
            )->a( n = `title` v = `Table Dialog`
            )->a( n = `class` v = `sapUiContentPadding`

            )->ele( `content`
                )->ele( `Table`
                    )->a( n = `mode`        v = `MultiSelect`
                    )->a( n = `fixedLayout` v = client->_bind( dialog_fixed )
                    )->a( n = `items`       v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

                    )->ele( `headerToolbar`
                        )->ele( `Toolbar`
                            )->tag( `Title`
                                )->a( n = `text`  v = `Products`
                                )->a( n = `level` v = `H2`
                            )->tag( `ToolbarSpacer`
                            )->tag( `CheckBox`
                                )->a( n = `text`     v = `Fixed Layout`
                                )->a( n = `selected` v = client->_bind( dialog_fixed )

                        )->end(
                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`

                            )->tag( `Text`
                                )->a( n = `text` v = `Supplier Name`

                        )->end(
                        )->ele( `Column`
                            )->a( n = `hAlign` v = `End`

                            )->tag( `Text`
                                )->a( n = `text` v = `Product ID`

                        )->end(
                    )->end(
                    )->ele( `items`
                        )->ele( `ColumnListItem`
                            )->a( n = `vAlign` v = `Middle`
                            )->a( n = `type`   v = `Navigation`

                            )->ele( `cells`
                                )->tag( `Text`
                                    )->a( n = `text`     v = `{NAME}`
                                    )->a( n = `wrapping` v = `false`
                                )->tag( `Text`
                                    )->a( n = `text`     v = `{PRODUCTID}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(

            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Close`
                    )->a( n = `press` v = client->_event( `CLOSE_DIALOG` ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `OPEN_DIALOG`.
        popup_display( ).

      WHEN `CLOSE_DIALOG`.
        client->popup_destroy( ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " the full mock /ProductCollection, in the mock order - the items binding
    " keeps its own sorter on NAME
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
