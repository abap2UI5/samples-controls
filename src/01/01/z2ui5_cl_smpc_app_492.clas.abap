" @keywords list sap.m listgrouping overflowtoolbar title toolbarspacer togglebutton menu menuitem
" @summary Grouping your items makes it easier for the user to browse and find the desired content. This example also shows the context menu for the items in the List control.
" @origin sap.m.sample.ListGrouping - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListGrouping (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_492 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        suppliername  TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products TYPE ty_t_product.
    DATA menu_on    TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_492 IMPLEMENTATION.

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

    DATA(list) = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        " the grouping sorter is kept 1:1; groupHeaderFactory returns a control and
        " has no backend equivalent, so the default group header renders instead
        )->ele( `List`
            )->a( n = `id`    v = `idList`
            )->a( n = `items` v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'SUPPLIERNAME', descending: false, group: true \} \}| ).

    list->ele( `headerToolbar`
        )->ele( `OverflowToolbar`

            )->tag( `Title`
                )->a( n = `text` v = `Products`
            )->tag( `ToolbarSpacer`
            " onToggleContextMenu builds a sap.m.Menu on press and destroys it again -
            " the pressed state travels to the backend, which emits the contextMenu
            " subtree below or leaves it out (app 436 precedent)
            )->tag( `ToggleButton`
                )->a( n = `icon`    v = `sap-icon://menu`
                )->a( n = `tooltip` v = `Enable / Disable Custom Context Menu`
                " NOT `b = <field>`: that parameter writes the LITERAL 'true' or
                " 'false' into the attribute at render time (view_builder->a),
                " so a field the event handler changes never reaches the
                " control - none of these apps re-renders after an event
                " (e2e-caught on app 505, 2026-08-22)
                )->a( n = `pressed` v = client->_bind( menu_on )
                )->a( n = `press`   v = client->_event( val = `TOGGLE_CONTEXT_MENU` arg = `${$parameters>/pressed}` ) ).

    IF menu_on = abap_true.
      list->ele( `contextMenu`
          )->ele( `Menu`
              )->tag( `MenuItem`
                  )->a( n = `text` v = `{NAME}`
              )->tag( `MenuItem`
                  )->a( n = `text` v = `{PRODUCTID}` ).
    ENDIF.

    list->tag( `StandardListItem`
        )->a( n = `title`            v = `{NAME}`
        )->a( n = `description`      v = `{PRODUCTID}`
        )->a( n = `icon`             v = `{PRODUCTPICURL}`
        )->a( n = `iconDensityAware` v = `false`
        )->a( n = `iconInset`        v = `false` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `TOGGLE_CONTEXT_MENU`.
      menu_on = client->get_event_arg( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
