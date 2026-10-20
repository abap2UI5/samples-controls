" @keywords expandabletext expandable text sap.m table column columnlistitem
" @summary The ExpandableText control can be used to display a larger texts inside a table, list or form.
" @origin sap.m.sample.ExpandableText - https://sdk.openui5.org/entity/sap.m.ExpandableText/sample/sap.m.sample.ExpandableText (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_643 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name         TYPE string,
        attribute1   TYPE string,
        attribute2   TYPE string,
        status       TYPE string,
        overflowmode TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_643 IMPLEMENTATION.

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
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`

        )->ele( `Table`
            )->a( n = `mode`          v = `MultiSelect`
            )->a( n = `items`         v = client->_bind( t_products )
            )->a( n = `autoPopinMode` v = `true`

            )->ele( `columns`
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Product`

                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Attribute 1`

                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Attribute 2`

                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Status`

                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->ele( `cells`
                        )->tag( `Text`
                            )->a( n = `text` v = `{NAME}`
                        )->tag( `ExpandableText`
                            )->a( n = `class`        v = `sapUiTinyMarginBottom sapUiTinyMarginTop`
                            )->a( n = `text`         v = `{ATTRIBUTE1}`
                            )->a( n = `overflowMode` v = `{OVERFLOWMODE}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{ATTRIBUTE2}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{STATUS}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    DATA(lorem) = `Lorem ipsum dolor sit amet, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. `
               && `At vero eos et accusam et justo duo dolores et ea rebum.Lorem ipsum dolor sit amet, consetetur sadipscing elitr, `
               && `sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. `
               && `At vero eos et accusam et justo duo dolores et ea rebum. Lorem ipsum dolor sit amet, consetetur sadipscing elitr`.

    t_products = VALUE #(
        ( name = `Product 1` attribute1 = |The full text is displayed in place. { lorem }|     attribute2 = `Attribute related to label` status = `Some status` overflowmode = `InPlace` )
        ( name = `Product 2` attribute1 = |The full text is displayed in a popover. { lorem }| attribute2 = `Attribute related to label` status = `Some status` overflowmode = `Popover` )
        ( name = `Product 3` attribute1 = |The full text is displayed in place. { lorem }|     attribute2 = `Attribute related to label` status = `Some status` overflowmode = `InPlace` )
        ( name = `Product 4` attribute1 = |The full text is displayed in a popover. { lorem }| attribute2 = `Attribute related to label` status = `Some status` overflowmode = `Popover` ) ).

  ENDMETHOD.

ENDCLASS.
