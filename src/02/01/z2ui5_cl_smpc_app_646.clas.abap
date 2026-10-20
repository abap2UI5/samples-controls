CLASS z2ui5_cl_smpc_app_646 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        key       TYPE string,
        firstname TYPE string,
        lastname  TYPE string,
        size      TYPE string,
        city      TYPE string,
      END OF ty_s_item.
    TYPES:
      BEGIN OF ty_s_token,
        text TYPE string,
      END OF ty_s_token.
    TYPES ty_t_token TYPE STANDARD TABLE OF ty_s_token WITH EMPTY KEY.
    DATA t_items TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
    " the EQ conditions per filter field while the filter dialog is open
    DATA t_firstname_tokens TYPE ty_t_token.
    DATA t_lastname_tokens  TYPE ty_t_token.
    DATA t_city_tokens      TYPE ty_t_token.
    DATA t_size_tokens      TYPE ty_t_token.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_condition,
        path  TYPE string,
        value TYPE string,
      END OF ty_s_condition.
    TYPES ty_t_condition TYPE STANDARD TABLE OF ty_s_condition WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    " the Filter state the table is bound with
    DATA t_conditions TYPE ty_t_condition.

    METHODS view_display.
    METHODS items_binding
      RETURNING
        VALUE(result) TYPE string.
    METHODS on_event.
    METHODS open_perso_dialog.
    METHODS update_tokens
      CHANGING
        tokens TYPE ty_t_token.
    METHODS apply_filters.
    METHODS token_texts
      IMPORTING
        json          TYPE string
      RETURNING
        VALUE(result) TYPE string_table.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_646 IMPLEMENTATION.

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
        )->a( n = `xmlns`         v = `sap.m`
        )->a( n = `xmlns:mvc`     v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core`    v = `sap.ui.core`
        )->a( n = `xmlns:plugins` v = `sap.m.plugins`
        )->a( n = `xmlns:tcm`     v = `sap.m.table.columnmenu`
        )->a( n = `xmlns:dnd`     v = `sap.ui.core.dnd`
        )->a( n = `xmlns:app`     v = `http://schemas.sap.com/sapui5/extension/sap.ui.core.CustomData/1`
        )->a( n = `height`        v = `100%`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false`

            " handleStateChange's getBinding( 'items' ).filter( ), composed by the backend
            )->ele( `Table`
                )->a( n = `id`             v = `persoTable`
                )->a( n = `items`          v = items_binding( )
                )->a( n = `ariaLabelledBy` v = `title`
                )->a( n = `fixedLayout`    v = `Strict`
                )->a( n = `autoPopinMode`  v = `true`
                )->a( n = `growing`        v = `true`
                )->a( n = `sticky`         v = `ColumnHeaders,HeaderToolbar`
                )->a( n = `popinLayout`    v = `GridSmall`

                )->ele( `headerToolbar`
                    )->ele( `OverflowToolbar`
                        )->tag( `Title`
                            )->a( n = `id`   v = `title`
                            )->a( n = `text` v = `Persons`
                        )->tag( `ToolbarSeparator`
                        " the sap.ui.fl VariantManagement (p13nVm) is dropped - see the sidecar
                        )->tag( `ToolbarSpacer`
                        )->tag( `Button`
                            )->a( n = `icon`    v = `sap-icon://action-settings`
                            )->a( n = `press`   v = client->_event( `OPEN_PERSO` )
                            )->a( n = `tooltip` v = `Settings`

                    )->end(
                )->end(

                )->ele( `dependents`
                    )->tag( n = `ColumnResizer` ns = `plugins`
                    )->ele( n = `Menu` ns = `tcm`
                        )->a( n = `id` v = `menu`

                        )->ele( n = `QuickSort` ns = `tcm`
                            )->ele( n = `items` ns = `tcm`
                                )->tag( n = `QuickSortItem` ns = `tcm`

                            )->end(
                        )->end(
                        )->ele( n = `QuickGroup` ns = `tcm`
                            )->ele( n = `items` ns = `tcm`
                                )->tag( n = `QuickGroupItem` ns = `tcm`

                            )->end(
                        )->end(
                        )->ele( n = `items` ns = `tcm`
                            )->tag( n = `ActionItem` ns = `tcm`
                                )->a( n = `icon`  v = `sap-icon://sort`
                                )->a( n = `label` v = `Sort`
                            )->tag( n = `ActionItem` ns = `tcm`
                                )->a( n = `icon`  v = `sap-icon://group-2`
                                )->a( n = `label` v = `Group`
                            )->tag( n = `ActionItem` ns = `tcm`
                                )->a( n = `icon`  v = `sap-icon://table-column`
                                )->a( n = `label` v = `Columns`

                        )->end(
                    )->end(

                    " the Filter popup Engine.show( ) creates - its FilterPanel cannot be
                    " built (see the sidecar), so the itemFactory's MultiInput controls sit
                    " in a Dialog, one per filterable field
                    )->ele( `Dialog`
                        )->a( n = `id`            v = `filterDialog`
                        )->a( n = `title`         v = `Custom Filter Settings`
                        )->a( n = `contentHeight` v = `50rem`
                        )->a( n = `contentWidth`  v = `45rem`

                        )->ele( `VBox`
                            )->a( n = `class` v = `sapUiSmallMargin`

                            )->tag( `Label`
                                )->a( n = `text`     v = `First Name`
                                )->a( n = `labelFor` v = `firstNameFilter`
                            )->ele( `MultiInput`
                                )->a( n = `id`              v = `firstNameFilter`
                                )->a( n = `showValueHelp`   v = `false`
                                )->a( n = `showClearIcon`   v = `true`
                                )->a( n = `tokens`          v = client->_bind( t_firstname_tokens )
                                )->a( n = `suggestionItems` v = client->_bind( t_items )
                                )->a( n = `tokenUpdate`     v = client->_event( val   = `TOKEN_UPDATE_FIRSTNAME`
                                                                                t_arg = VALUE #( ( `${$parameters>/addedTokens}` )
                                                                                                 ( `${$parameters>/removedTokens}` ) ) )

                                )->ele( `tokens`
                                    )->tag( `Token`
                                        )->a( n = `text` v = `{TEXT}`

                                )->end(
                                )->ele( `suggestionItems`
                                    )->tag( n = `Item` ns = `core`
                                        )->a( n = `key`  v = `{KEY}`
                                        )->a( n = `text` v = `{FIRSTNAME}`

                                )->end(
                            )->end(

                            )->tag( `Label`
                                )->a( n = `text`     v = `Last Name`
                                )->a( n = `labelFor` v = `lastNameFilter`
                            )->ele( `MultiInput`
                                )->a( n = `id`              v = `lastNameFilter`
                                )->a( n = `showValueHelp`   v = `false`
                                )->a( n = `showClearIcon`   v = `true`
                                )->a( n = `tokens`          v = client->_bind( t_lastname_tokens )
                                )->a( n = `suggestionItems` v = client->_bind( t_items )
                                )->a( n = `tokenUpdate`     v = client->_event( val   = `TOKEN_UPDATE_LASTNAME`
                                                                                t_arg = VALUE #( ( `${$parameters>/addedTokens}` )
                                                                                                 ( `${$parameters>/removedTokens}` ) ) )

                                )->ele( `tokens`
                                    )->tag( `Token`
                                        )->a( n = `text` v = `{TEXT}`

                                )->end(
                                )->ele( `suggestionItems`
                                    )->tag( n = `Item` ns = `core`
                                        )->a( n = `key`  v = `{KEY}`
                                        )->a( n = `text` v = `{LASTNAME}`

                                )->end(
                            )->end(

                            )->tag( `Label`
                                )->a( n = `text`     v = `City`
                                )->a( n = `labelFor` v = `cityFilter`
                            )->ele( `MultiInput`
                                )->a( n = `id`              v = `cityFilter`
                                )->a( n = `showValueHelp`   v = `false`
                                )->a( n = `showClearIcon`   v = `true`
                                )->a( n = `tokens`          v = client->_bind( t_city_tokens )
                                )->a( n = `suggestionItems` v = client->_bind( t_items )
                                )->a( n = `tokenUpdate`     v = client->_event( val   = `TOKEN_UPDATE_CITY`
                                                                                t_arg = VALUE #( ( `${$parameters>/addedTokens}` )
                                                                                                 ( `${$parameters>/removedTokens}` ) ) )

                                )->ele( `tokens`
                                    )->tag( `Token`
                                        )->a( n = `text` v = `{TEXT}`

                                )->end(
                                )->ele( `suggestionItems`
                                    )->tag( n = `Item` ns = `core`
                                        )->a( n = `key`  v = `{KEY}`
                                        )->a( n = `text` v = `{CITY}`

                                )->end(
                            )->end(

                            )->tag( `Label`
                                )->a( n = `text`     v = `Size`
                                )->a( n = `labelFor` v = `sizeFilter`
                            )->ele( `MultiInput`
                                )->a( n = `id`              v = `sizeFilter`
                                )->a( n = `showValueHelp`   v = `false`
                                )->a( n = `showClearIcon`   v = `true`
                                )->a( n = `tokens`          v = client->_bind( t_size_tokens )
                                )->a( n = `suggestionItems` v = client->_bind( t_items )
                                )->a( n = `tokenUpdate`     v = client->_event( val   = `TOKEN_UPDATE_SIZE`
                                                                                t_arg = VALUE #( ( `${$parameters>/addedTokens}` )
                                                                                                 ( `${$parameters>/removedTokens}` ) ) )

                                )->ele( `tokens`
                                    )->tag( `Token`
                                        )->a( n = `text` v = `{TEXT}`

                                )->end(
                                )->ele( `suggestionItems`
                                    )->tag( n = `Item` ns = `core`
                                        )->a( n = `key`  v = `{KEY}`
                                        )->a( n = `text` v = `{SIZE}`

                                )->end(
                            )->end(
                        )->end(

                        )->ele( `beginButton`
                            )->tag( `Button`
                                )->a( n = `text`  v = `OK`
                                )->a( n = `type`  v = `Emphasized`
                                )->a( n = `press` v = client->_event( `APPLY_FILTERS` )

                        )->end(
                        )->ele( `endButton`
                            )->tag( `Button`
                                )->a( n = `text`  v = `Cancel`
                                )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                t_arg = VALUE #( ( `filterDialog` ) ( `close` ) ) )

                        )->end(
                    )->end(
                )->end(

                )->ele( `dragDropConfig`
                    )->tag( n = `DragDropInfo` ns = `dnd`
                        )->a( n = `sourceAggregation` v = `columns`
                        )->a( n = `targetAggregation` v = `columns`
                        )->a( n = `dropPosition`      v = `Between`

                )->end(

                )->ele( `noData`
                    )->tag( `IllustratedMessage`

                )->end(

                )->ele( `columns`
                    )->ele( `Column`
                        )->a( n = `app:p13nKey` v = `firstName_col`
                        )->a( n = `headerMenu`  v = `menu`

                        )->ele( `header`
                            )->tag( `Text`
                                )->a( n = `text` v = `First Name`

                        )->end(
                    )->end(
                    )->ele( `Column`
                        )->a( n = `app:p13nKey` v = `lastName_col`
                        )->a( n = `headerMenu`  v = `menu`

                        )->tag( `Text`
                            )->a( n = `text` v = `Last Name`

                    )->end(
                    )->ele( `Column`
                        )->a( n = `app:p13nKey` v = `city_col`
                        )->a( n = `headerMenu`  v = `menu`

                        )->tag( `Text`
                            )->a( n = `text` v = `City`

                    )->end(
                    )->ele( `Column`
                        )->a( n = `app:p13nKey` v = `size_col`
                        )->a( n = `hAlign`      v = `End`
                        )->a( n = `headerMenu`  v = `menu`

                        )->tag( `Text`
                            )->a( n = `text` v = `Size`

                    )->end(
                )->end(

                )->ele( `items`
                    )->ele( `ColumnListItem`
                        )->tag( `Text`
                            )->a( n = `text` v = `{FIRSTNAME}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{LASTNAME}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{CITY}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{SIZE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD items_binding.

    " createFilters: one EQ filter per condition, all in one flat array -
    " UI5 ORs the filters of one path and ANDs the paths
    DATA(filters) = ``.
    LOOP AT t_conditions INTO DATA(condition).
      filters = |{ filters }, \{ path: '{ condition-path }', operator: 'EQ', value1: '{ condition-value }' \}|.
    ENDLOOP.

    result = |\{ path: '{ client->_bind( val = t_items path = abap_true ) }', | &&
             |filters: [{ shift_left( val = filters sub = `, ` ) }] \}|.

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `OPEN_PERSO`.
        open_perso_dialog( ).

      WHEN `TOKEN_UPDATE_FIRSTNAME`.
        update_tokens( CHANGING tokens = t_firstname_tokens ).

      WHEN `TOKEN_UPDATE_LASTNAME`.
        update_tokens( CHANGING tokens = t_lastname_tokens ).

      WHEN `TOKEN_UPDATE_CITY`.
        update_tokens( CHANGING tokens = t_city_tokens ).

      WHEN `TOKEN_UPDATE_SIZE`.
        update_tokens( CHANGING tokens = t_size_tokens ).

      WHEN `APPLY_FILTERS`.
        apply_filters( ).
        view_display( ).

    ENDCASE.

  ENDMETHOD.


  METHOD open_perso_dialog.

    " the itemFactory seeds each MultiInput with the existing conditions
    t_firstname_tokens = VALUE #( FOR c IN t_conditions WHERE ( path = `FIRSTNAME` ) ( text = c-value ) ).
    t_lastname_tokens  = VALUE #( FOR c IN t_conditions WHERE ( path = `LASTNAME` ) ( text = c-value ) ).
    t_city_tokens      = VALUE #( FOR c IN t_conditions WHERE ( path = `CITY` ) ( text = c-value ) ).
    t_size_tokens      = VALUE #( FOR c IN t_conditions WHERE ( path = `SIZE` ) ( text = c-value ) ).

    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `filterDialog` ) ( `open` ) ) ).

  ENDMETHOD.


  METHOD update_tokens.

    " tokenUpdate: an EQ condition per added token, the removed ones dropped
    LOOP AT token_texts( client->get_event_arg( ) ) INTO DATA(added).
      INSERT VALUE #( text = added ) INTO TABLE tokens.
    ENDLOOP.
    LOOP AT token_texts( client->get_event_arg( 2 ) ) INTO DATA(removed).
      DELETE tokens WHERE text = removed.
    ENDLOOP.

  ENDMETHOD.


  METHOD apply_filters.

    t_conditions = VALUE #( ( LINES OF VALUE ty_t_condition( FOR t IN t_firstname_tokens ( path = `FIRSTNAME` value = t-text ) ) )
                            ( LINES OF VALUE ty_t_condition( FOR t IN t_lastname_tokens ( path = `LASTNAME` value = t-text ) ) )
                            ( LINES OF VALUE ty_t_condition( FOR t IN t_city_tokens ( path = `CITY` value = t-text ) ) )
                            ( LINES OF VALUE ty_t_condition( FOR t IN t_size_tokens ( path = `SIZE` value = t-text ) ) ) ).

  ENDMETHOD.


  METHOD token_texts.

    " addedTokens / removedTokens arrive as a JSON array of the tokens'
    " properties; collect their texts
    SPLIT json AT `}` INTO TABLE DATA(objects).
    LOOP AT objects INTO DATA(object).
      DATA(offset) = find( val = object sub = `"text":"` ).
      IF offset >= 0.
        INSERT substring_before( val = substring( val = object off = offset + 8 ) sub = `"` ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    t_items = VALUE #(
        ( key = `P1`  firstname = `Peter`     lastname = `Mueller` size = `1.75` city = `Walldorf` )
        ( key = `P2`  firstname = `Petra`     lastname = `Maier`   size = `1.85` city = `Berlin` )
        ( key = `P3`  firstname = `Thomas`    lastname = `Smith`   size = `1.95` city = `Berlin` )
        ( key = `P4`  firstname = `John`      lastname = `Mueller` size = `1.65` city = `Walldorf` )
        ( key = `P5`  firstname = `Maria`     lastname = `Jones`   size = `1.55` city = `Walldorf` )
        ( key = `P6`  firstname = `Christine` lastname = `Smith`   size = `1.95` city = `Manchester` )
        ( key = `P7`  firstname = `Hobin`     lastname = `Rood`    size = `1.85` city = `Manchester` )
        ( key = `P8`  firstname = `Nils`      lastname = `Mueller` size = `1.75` city = `Walldorf` )
        ( key = `P9`  firstname = `Helga`     lastname = `Maier`   size = `1.85` city = `Berlin` )
        ( key = `P10` firstname = `Torsten`   lastname = `Smith`   size = `1.95` city = `Berlin` )
        ( key = `P11` firstname = `Yannick`   lastname = `Mueller` size = `1.65` city = `London` )
        ( key = `P12` firstname = `Peter`     lastname = `Jones`   size = `1.75` city = `Walldorf` )
        ( key = `P13` firstname = `Christine` lastname = `Jones`   size = `1.65` city = `Dresden` )
        ( key = `P14` firstname = `Nils`      lastname = `Maier`   size = `1.65` city = `Manchester` ) ).

  ENDMETHOD.

ENDCLASS.
