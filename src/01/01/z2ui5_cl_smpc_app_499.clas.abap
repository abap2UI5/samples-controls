" @keywords list sap.m listselectionsearch overflowtoolbar searchfield label standardlistitem
" @summary When searching a list with multi selection the previously selected items will stay selected. This is managed by the list control for you.
" @origin sap.m.sample.ListSelectionSearch - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListSelectionSearch (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_499 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
        selected      TYPE abap_bool,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products    TYPE ty_t_product.
    DATA info_visible  TYPE abap_bool.
    DATA filter_label  TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_499 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `height`    v = `100%`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            )->ele( `subHeader`
                )->ele( `OverflowToolbar`
                    " onSearch filters the items binding by Name - the same declarative
                    " filter on the aggregation binding, the model untouched
                    )->tag( `SearchField`
                        )->a( n = `liveChange` v = client->_event( val = `SEARCH` arg = `${$parameters>/newValue}` )
                        )->a( n = `width`      v = `80%`

                )->end(
            )->end(

            )->ele( `List`
                )->a( n = `id`                     v = `idList`
                )->a( n = `items`                  v = client->_bind( t_products )
                " onSelectionChange counts the selected contexts and drives the info
                " toolbar - the selection is a bound row field, counted in ABAP
                )->a( n = `selectionChange`        v = client->_event( `SELECTION_CHANGE` )
                )->a( n = `mode`                   v = `MultiSelect`
                )->a( n = `growing`                v = `true`
                )->a( n = `growingThreshold`       v = `50`
                )->a( n = `includeItemInSelection` v = `true`

                )->ele( `infoToolbar`
                    )->ele( `OverflowToolbar`
                        )->a( n = `visible` v = client->_bind( info_visible )
                        )->a( n = `id`      v = `idInfoToolbar`

                        )->tag( `Label`
                            )->a( n = `id`   v = `idFilterLabel`
                            )->a( n = `text` v = client->_bind( filter_label )

                    )->end(
                )->end(

                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `description`      v = `{PRODUCTID}`
                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `selected`         v = `{SELECTED}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SEARCH`.
        DATA(term) = client->get_event_arg( ).
        " free text spliced into a JSON string literal - backslash first, then the quote (app 218/420)
        REPLACE ALL OCCURRENCES OF `\` IN term WITH `\\`.
        REPLACE ALL OCCURRENCES OF `"` IN term WITH `\"`.
        " The compound payload is an array of GROUPS, each group an array of
        " [path, operator, value1] ROWS (app 022's shape). It was written as an
        " array of objects, which buildFilterGroups drops as not-an-array - and
        " an empty group list CLEARS the filter, so every search showed the full
        " list (e2e-caught 2026-08-22).
        DATA(filter) = COND string( WHEN term IS INITIAL
                                    THEN `[]`
                                    ELSE |[[["NAME","Contains","{ term }"]]]| ).
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = VALUE #( ( `idList` ) ( `items` ) ( `filter` ) ( filter ) ) ).

      WHEN `SELECTION_CHANGE`.
        " getSelectedContexts(true) counts across the current filter - the bound
        " selected flag does the same, because it lives on the row
        DATA(count) = REDUCE i( INIT n = 0 FOR row IN t_products NEXT n = COND #( WHEN row-selected = abap_true THEN n + 1 ELSE n ) ).
        info_visible = xsdbool( count > 0 ).
        filter_label = COND string( WHEN count > 0 THEN |{ count } selected| ELSE `` ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
