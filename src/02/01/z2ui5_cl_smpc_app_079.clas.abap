" @keywords title sap.m embedded link list toolbar toolbarspacer button standardlistitem
" @summary This sample shows how to add a link to a title.
" @origin sap.m.sample.TitleLink - https://sdk.openui5.org/entity/sap.m.Title/sample/sap.m.sample.TitleLink (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_079 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name      TYPE string,
        productid TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_079 IMPLEMENTATION.

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
        )->a( n = `height`    v = `100%`

        )->ele( `Page`
            )->a( n = `enableScrolling` v = `true`
            )->a( n = `title`           v = `Page Header Title`
            )->a( n = `titleLevel`      v = `H2`
            )->a( n = `showFooter`      v = `false`

            )->ele( `List`
                )->a( n = `items` v = client->_bind( t_products )

                )->ele( `headerToolbar`
                    )->ele( `Toolbar`
                        " the Link sits in the Title content aggregation (since UI5 1.87) - kept 1:1, needs UI5 >= 1.87
                        )->ele( `Title`
                            )->a( n = `level` v = `H3`
                            )->tag( `Link`
                                )->a( n = `text`   v = `Products Link`
                                )->a( n = `href`   v = `https://sap.com`
                                )->a( n = `target` v = `_blank`

                        )->end(
                        )->tag( `ToolbarSpacer`
                        )->tag( `Button`
                            )->a( n = `icon`  v = `sap-icon://settings`
                            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                            t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `Header toolbar button pressed.` ) ) )

                    )->end(
                )->end(

                )->tag( `StandardListItem`
                    )->a( n = `title`       v = `{NAME}`
                    )->a( n = `description` v = `{PRODUCTID}`

            )->end(
        )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection (sap/ui/demo/mock/products.json)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
