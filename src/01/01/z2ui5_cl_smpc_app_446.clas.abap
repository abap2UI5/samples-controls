" @keywords link sap.m linksubtle table toolbar title column text columnlistitem objectidentifier
" @summary Subtle links should be used to indicate less important links in tables with a large number of links. In this example all columns contain links, only the first column is non-subtle.
" @origin sap.m.sample.LinkSubtle - https://sdk.openui5.org/entity/sap.m.Link/sample/sap.m.sample.LinkSubtle (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_446 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        suppliername  TYPE string,
        category      TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products TYPE ty_t_product.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_446 IMPLEMENTATION.

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

        )->ele( `Table`
            )->a( n = `id`    v = `idProductsTable`
            )->a( n = `inset` v = `false`
            )->a( n = `items` v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|

            )->ele( `headerToolbar`
                )->ele( `Toolbar`
                    )->tag( `Title`
                        )->a( n = `text`  v = `Products`
                        )->a( n = `level` v = `H2`

                )->end(
            )->end(

            )->ele( `columns`
                )->ele( `Column`
                    )->a( n = `width` v = `12em`

                    )->tag( `Text`
                        )->a( n = `text` v = `Name`

                )->end(

                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Id`

                )->end(

                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Tablet`
                    )->a( n = `demandPopin`    v = `true`

                    )->tag( `Text`
                        )->a( n = `text` v = `Supplier`

                )->end(

                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Tablet`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Category`

                )->end(

                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Tablet`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Picture`

                )->end(
            )->end(

            )->ele( `ColumnListItem`
                )->tag( `Link`
                    )->a( n = `text` v = `{NAME}`
                    )->a( n = `href` v = `{PRODUCTPICURL}`
                )->tag( `ObjectIdentifier`
                    )->a( n = `title`       v = `{PRODUCTID}`
                    )->a( n = `titleActive` v = `true`
                    )->a( n = `titlePress`  v = client->_event( `IDENTIFIER_PRESS` )
                )->tag( `Link`
                    )->a( n = `text`   v = `{SUPPLIERNAME}`
                    )->a( n = `subtle` v = `true`
                    )->a( n = `press`  v = client->_event( `LINK_PRESS` )
                )->tag( `Link`
                    )->a( n = `text`   v = `{CATEGORY}`
                    )->a( n = `subtle` v = `true`
                    )->a( n = `press`  v = client->_event( `LINK_PRESS` )
                )->tag( `Link`
                    )->a( n = `text`   v = `picture`
                    )->a( n = `subtle` v = `true`
                    )->a( n = `href`   v = `{PRODUCTPICURL}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `LINK_PRESS`.
        " handleLinkPress - MessageBox.alert("Link was clicked!")
        client->message_box_display( text = `Link was clicked!` type = `alert` ).

      WHEN `IDENTIFIER_PRESS`.
        " handleObjectIdentifierPress - MessageBox.alert("Object Identifier was clicked!")
        client->message_box_display( text = `Object Identifier was clicked!` type = `alert` ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the fields the view binds)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
