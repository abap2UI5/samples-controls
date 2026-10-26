" @keywords engine sap.m.p13n p13n.enginecustomfilters table overflowtoolbar title toolbarseparator toolbarspacer button columnresizer menu quicksort
" @summary Filtering using the personalization Engine
" @origin sap.m.sample.p13n.EngineCustomFilters - https://sdk.openui5.org/entity/sap.m.p13n.Engine/sample/sap.m.sample.p13n.EngineCustomFilters (status: generated - machine-written, not yet reviewed)
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
    TYPES ty_t_token TYPE STANDARD TABLE OF ty_s_token WITH DEFAULT KEY.
    DATA t_items TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
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
    TYPES ty_t_condition TYPE STANDARD TABLE OF ty_s_condition WITH DEFAULT KEY.

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
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA temp2 TYPE string_table.
    DATA temp3 TYPE string_table.
    DATA temp4 TYPE string_table.
    DATA temp5 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/addedTokens}` INTO TABLE temp1.
    INSERT `${$parameters>/removedTokens}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$parameters>/addedTokens}` INTO TABLE temp2.
    INSERT `${$parameters>/removedTokens}` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `${$parameters>/addedTokens}` INTO TABLE temp3.
    INSERT `${$parameters>/removedTokens}` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `${$parameters>/addedTokens}` INTO TABLE temp4.
    INSERT `${$parameters>/removedTokens}` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `filterDialog` INTO TABLE temp5.
    INSERT `close` INTO TABLE temp5.
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
                                                                                t_arg = temp1 )

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
                                                                                t_arg = temp2 )

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
                                                                                t_arg = temp3 )

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
                                                                                t_arg = temp4 )

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
                                                                                t_arg = temp5 )

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
    DATA filters TYPE string.
    DATA condition LIKE LINE OF t_conditions.
    filters = ``.
    
    LOOP AT t_conditions INTO condition.
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
    DATA temp4 TYPE z2ui5_cl_smpc_app_646=>ty_t_token.
    DATA temp5 LIKE LINE OF t_conditions.
      DATA temp6 LIKE LINE OF temp4.
    DATA temp7 TYPE z2ui5_cl_smpc_app_646=>ty_t_token.
    DATA temp9 LIKE LINE OF t_conditions.
      DATA temp8 LIKE LINE OF temp7.
    DATA temp10 TYPE z2ui5_cl_smpc_app_646=>ty_t_token.
    DATA temp12 LIKE LINE OF t_conditions.
      DATA temp11 LIKE LINE OF temp10.
    DATA temp13 TYPE z2ui5_cl_smpc_app_646=>ty_t_token.
    DATA c LIKE LINE OF t_conditions.
      DATA temp14 LIKE LINE OF temp13.
    DATA temp15 TYPE string_table.
    CLEAR temp4.
    
    LOOP AT t_conditions INTO temp5 WHERE path = `FIRSTNAME`.
      
      temp6-text = temp5-value.
      INSERT temp6 INTO TABLE temp4.
    ENDLOOP.
    t_firstname_tokens = temp4.
    
    CLEAR temp7.
    
    LOOP AT t_conditions INTO temp9 WHERE path = `LASTNAME`.
      
      temp8-text = temp9-value.
      INSERT temp8 INTO TABLE temp7.
    ENDLOOP.
    t_lastname_tokens  = temp7.
    
    CLEAR temp10.
    
    LOOP AT t_conditions INTO temp12 WHERE path = `CITY`.
      
      temp11-text = temp12-value.
      INSERT temp11 INTO TABLE temp10.
    ENDLOOP.
    t_city_tokens      = temp10.
    
    CLEAR temp13.
    
    LOOP AT t_conditions INTO c WHERE path = `SIZE`.
      
      temp14-text = c-value.
      INSERT temp14 INTO TABLE temp13.
    ENDLOOP.
    t_size_tokens      = temp13.

    
    CLEAR temp15.
    INSERT `filterDialog` INTO TABLE temp15.
    INSERT `open` INTO TABLE temp15.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp15 ).

  ENDMETHOD.


  METHOD update_tokens.

    " tokenUpdate: an EQ condition per added token, the removed ones dropped
    DATA temp17 TYPE string_table.
    DATA added LIKE LINE OF temp17.
      DATA temp18 TYPE z2ui5_cl_smpc_app_646=>ty_s_token.
    DATA temp19 TYPE string_table.
    DATA removed LIKE LINE OF temp19.
    temp17 = token_texts( client->get_event_arg( ) ).
    
    LOOP AT temp17 INTO added.
      
      CLEAR temp18.
      temp18-text = added.
      INSERT temp18 INTO TABLE tokens.
    ENDLOOP.
    
    temp19 = token_texts( client->get_event_arg( 2 ) ).
    
    LOOP AT temp19 INTO removed.
      DELETE tokens WHERE text = removed.
    ENDLOOP.

  ENDMETHOD.


  METHOD apply_filters.

    DATA temp20 TYPE z2ui5_cl_smpc_app_646=>ty_t_condition.
    DATA temp1 TYPE ty_t_condition.
    DATA temp9 LIKE LINE OF t_firstname_tokens.
      DATA temp2 LIKE LINE OF temp1.
    DATA temp3 TYPE ty_t_condition.
    DATA temp5 LIKE LINE OF t_lastname_tokens.
      DATA temp4 LIKE LINE OF temp3.
    DATA temp6 TYPE ty_t_condition.
    DATA temp8 LIKE LINE OF t_city_tokens.
      DATA temp7 LIKE LINE OF temp6.
    DATA temp10 TYPE ty_t_condition.
    DATA t LIKE LINE OF t_size_tokens.
      DATA temp11 LIKE LINE OF temp10.
    CLEAR temp20.
    
    CLEAR temp1.
    
    LOOP AT t_firstname_tokens INTO temp9.
      
      temp2-path = `FIRSTNAME`.
      temp2-value = temp9-text.
      INSERT temp2 INTO TABLE temp1.
    ENDLOOP.
    INSERT LINES OF temp1 INTO TABLE temp20.
    
    CLEAR temp3.
    
    LOOP AT t_lastname_tokens INTO temp5.
      
      temp4-path = `LASTNAME`.
      temp4-value = temp5-text.
      INSERT temp4 INTO TABLE temp3.
    ENDLOOP.
    INSERT LINES OF temp3 INTO TABLE temp20.
    
    CLEAR temp6.
    
    LOOP AT t_city_tokens INTO temp8.
      
      temp7-path = `CITY`.
      temp7-value = temp8-text.
      INSERT temp7 INTO TABLE temp6.
    ENDLOOP.
    INSERT LINES OF temp6 INTO TABLE temp20.
    
    CLEAR temp10.
    
    LOOP AT t_size_tokens INTO t.
      
      temp11-path = `SIZE`.
      temp11-value = t-text.
      INSERT temp11 INTO TABLE temp10.
    ENDLOOP.
    INSERT LINES OF temp10 INTO TABLE temp20.
    t_conditions = temp20.

  ENDMETHOD.


  METHOD token_texts.

    " addedTokens / removedTokens arrive as a JSON array of the tokens'
    " properties; collect their texts
    DATA objects TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA object LIKE LINE OF objects.
      DATA offset TYPE i.
    SPLIT json AT `}` INTO TABLE objects.
    
    LOOP AT objects INTO object.
      
      offset = find( val = object sub = `"text":"` ).
      IF offset >= 0.
        INSERT substring_before( val = substring( val = object off = offset + 8 ) sub = `"` ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    DATA temp22 LIKE t_items.
    DATA temp23 LIKE LINE OF temp22.
    CLEAR temp22.
    
    temp23-key = `P1`.
    temp23-firstname = `Peter`.
    temp23-lastname = `Mueller`.
    temp23-size = `1.75`.
    temp23-city = `Walldorf`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P2`.
    temp23-firstname = `Petra`.
    temp23-lastname = `Maier`.
    temp23-size = `1.85`.
    temp23-city = `Berlin`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P3`.
    temp23-firstname = `Thomas`.
    temp23-lastname = `Smith`.
    temp23-size = `1.95`.
    temp23-city = `Berlin`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P4`.
    temp23-firstname = `John`.
    temp23-lastname = `Mueller`.
    temp23-size = `1.65`.
    temp23-city = `Walldorf`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P5`.
    temp23-firstname = `Maria`.
    temp23-lastname = `Jones`.
    temp23-size = `1.55`.
    temp23-city = `Walldorf`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P6`.
    temp23-firstname = `Christine`.
    temp23-lastname = `Smith`.
    temp23-size = `1.95`.
    temp23-city = `Manchester`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P7`.
    temp23-firstname = `Hobin`.
    temp23-lastname = `Rood`.
    temp23-size = `1.85`.
    temp23-city = `Manchester`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P8`.
    temp23-firstname = `Nils`.
    temp23-lastname = `Mueller`.
    temp23-size = `1.75`.
    temp23-city = `Walldorf`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P9`.
    temp23-firstname = `Helga`.
    temp23-lastname = `Maier`.
    temp23-size = `1.85`.
    temp23-city = `Berlin`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P10`.
    temp23-firstname = `Torsten`.
    temp23-lastname = `Smith`.
    temp23-size = `1.95`.
    temp23-city = `Berlin`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P11`.
    temp23-firstname = `Yannick`.
    temp23-lastname = `Mueller`.
    temp23-size = `1.65`.
    temp23-city = `London`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P12`.
    temp23-firstname = `Peter`.
    temp23-lastname = `Jones`.
    temp23-size = `1.75`.
    temp23-city = `Walldorf`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P13`.
    temp23-firstname = `Christine`.
    temp23-lastname = `Jones`.
    temp23-size = `1.65`.
    temp23-city = `Dresden`.
    INSERT temp23 INTO TABLE temp22.
    temp23-key = `P14`.
    temp23-firstname = `Nils`.
    temp23-lastname = `Maier`.
    temp23-size = `1.65`.
    temp23-city = `Manchester`.
    INSERT temp23 INTO TABLE temp22.
    t_items = temp22.

  ENDMETHOD.

ENDCLASS.
