" @keywords list sap.m listtoolbar standardlistitem overflowtoolbar title toolbarspacer multicombobox item togglebutton button label
" @summary The 'headerText' property is an easy but limited way of setting the list header. If you need more flexibility you should assemble your own header or info toolbar that can also contain buttons.
" @origin sap.m.sample.ListToolbar - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListToolbar (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_508 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products   TYPE ty_t_product.
    DATA t_sticky     TYPE string_table.
    " the ToggleButton's own pressed state. The original view declares no
    " pressed attribute, so the button starts UNpressed and the info toolbar
    " starts visible - onToggleInfoToolbar sets visible = NOT pressed. The
    " seed was abap_true, which came up with the toolbar already hidden
    " (e2e-caught 2026-08-22), and the name said the opposite of what it held.
    DATA toggle_pressed TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_508 IMPLEMENTATION.

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
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `List`
            )->a( n = `id`     v = `productList`
            )->a( n = `items`  v = client->_bind( t_products )
            " onSelectionFinish maps the picked keys onto list.setSticky( ) - the
            " MultiComboBox selection and the sticky property share one bound table
            )->a( n = `sticky` v = client->_bind( t_sticky )

            )->ele( `items`
                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `description`      v = `{PRODUCTID}`
                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`

            )->end(

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`

                    )->tag( `Title`
                        )->a( n = `text`  v = `Products`
                        )->a( n = `level` v = `H2`
                    )->tag( `ToolbarSpacer`

                    )->ele( `MultiComboBox`
                        )->a( n = `id`           v = `idSticky`
                        )->a( n = `placeholder`  v = `Sticky options`
                        )->a( n = `selectedKeys` v = client->_bind( t_sticky )
                        )->a( n = `width`        v = `15%`

                        )->ele( `items`
                            )->tag( n = `Item` ns = `core`
                                )->a( n = `text` v = `Header Toolbar`
                                )->a( n = `key`  v = `HeaderToolbar`
                            )->tag( n = `Item` ns = `core`
                                )->a( n = `text` v = `Info Toolbar`
                                )->a( n = `key`  v = `InfoToolbar`

                        )->end(
                    )->end(

                    " onToggleInfoToolbar hides the info toolbar while the button is
                    " pressed - one expression binding over the bound pressed state
                    )->tag( `ToggleButton`
                        )->a( n = `id`      v = `toggleInfoToolbar`
                        )->a( n = `text`    v = `Hide/Show InfoToolbar`
                        )->a( n = `pressed` v = client->_bind( toggle_pressed )
                    )->tag( `Button`
                        )->a( n = `icon`  v = `sap-icon://settings`
                        )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                        t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `header toolbar button pressed` ) ) )
                    )->tag( `Button`
                        )->a( n = `icon`  v = `sap-icon://person-placeholder`
                        )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                        t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `header toolbar button pressed` ) ) )
                    )->tag( `Button`
                        )->a( n = `icon`  v = `sap-icon://drop-down-list`
                        )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                        t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `header toolbar button pressed` ) ) )

                )->end(
            )->end(

            )->ele( `infoToolbar`
                )->ele( `OverflowToolbar`
                    )->a( n = `active`  v = `true`
                    )->a( n = `visible` v = |\{= !${ client->_bind( toggle_pressed ) } \}|
                    )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_global
                                                                      t_arg = VALUE #( ( `MESSAGE_TOAST` ) ( `show` ) ( `info toolbar pressed` ) ) )

                    )->tag( `Label`
                        )->a( n = `text` v = `This is the info bar` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
