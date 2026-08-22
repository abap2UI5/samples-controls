" @keywords toolpage tool sap.tnt button overflowtoolbarlayoutdata toolbarspacer navcontainer scrollcontainer text popover dialog
" @summary A tool page layout with vertical navigation
CLASS z2ui5_cl_smpc_app_167 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_child,
        title   TYPE string,
        key     TYPE string,
        enabled TYPE abap_bool,
      END OF ty_child.
    TYPES ty_child_tt TYPE STANDARD TABLE OF ty_child WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_nav,
        title      TYPE string,
        icon       TYPE string,
        enabled    TYPE abap_bool,
        expanded   TYPE abap_bool,
        key        TYPE string,
        selectable TYPE abap_bool,
        items      TYPE ty_child_tt,
      END OF ty_nav.
    TYPES:
      BEGIN OF ty_fixed,
        title        TYPE string,
        icon         TYPE string,
        ariahaspopup TYPE string,
        design       TYPE string,
        selectable   TYPE abap_bool,
      END OF ty_fixed.
    DATA navigation     TYPE STANDARD TABLE OF ty_nav WITH DEFAULT KEY.
    DATA sideexpanded   TYPE abap_bool.
    DATA toggle_tooltip TYPE string.
    DATA fixednavigation TYPE STANDARD TABLE OF ty_fixed WITH DEFAULT KEY.

    " NavigationListItem.selectable is {= ${items}.length > 3} in the original;
    " per the thin-frontend rule that logic is computed in ABAP into a flat
    " 'selectable' field and bound directly. selectedKey drives the shown page.
    DATA selectedkey TYPE string VALUE `page2`.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_167 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `$event.oSource.sId` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `MESSAGE_TOAST` INTO TABLE temp2.
    INSERT `show` INTO TABLE temp2.
    INSERT `Fired itemPress, item: {0}` INTO TABLE temp2.
    INSERT `${$parameters>/item}.getText()` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `pageContainer` INTO TABLE temp3.
    INSERT `to` INTO TABLE temp3.
    INSERT `${$parameters>/item}.getKey()` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `${$source>/design}` INTO TABLE temp4.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:tnt` v = `sap.tnt`
        )->a( n = `height`    v = `100%`

        )->ele( n = `ToolPage` ns = `tnt`
            )->a( n = `id`           v = `toolPage`
            " added attr (declared): carries onSideNavButtonPress' setSideExpanded
            )->a( n = `sideExpanded` v = client->_bind( sideexpanded )

            )->ele( n = `header` ns = `tnt`
                )->ele( n = `ToolHeader` ns = `tnt`
                    )->ele( `Button`
                        )->a( n = `id`      v = `sideNavigationToggleButton`
                        )->a( n = `icon`    v = `sap-icon://menu2`
                        )->a( n = `type`    v = `Transparent`
                        " added attr (declared): the original sets the tooltip imperatively
                        )->a( n = `tooltip` v = client->_bind( toggle_tooltip )
                        )->a( n = `press`   v = client->_event( `SIDE_TOGGLE` )
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `NeverOverflow`

                        )->end(
                    )->end(
                    )->tag( `ToolbarSpacer`
                        )->a( n = `width` v = `20px`
                    )->ele( `Button`
                        )->a( n = `text` v = `File`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `Edit`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `View`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `Navigate`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `Code`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `Refactor`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `Run`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text` v = `Tools`
                        )->a( n = `type` v = `Transparent`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `Low`

                        )->end(
                    )->end(
                    )->tag( n = `ToolHeaderUtilitySeparator` ns = `tnt`
                    )->ele( `ToolbarSpacer`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `NeverOverflow`
                                )->a( n = `minWidth` v = `20px`

                        )->end(
                    )->end(
                    )->ele( `Button`
                        )->a( n = `text`         v = `Alan Smith`
                        )->a( n = `type`         v = `Transparent`
                        )->a( n = `press`        v = client->_event( val   = `USER_POPOVER`
                                                                     t_arg = temp1 )
                        )->a( n = `ariaHasPopup` v = `Menu`
                        )->ele( `layoutData`
                            )->tag( `OverflowToolbarLayoutData`
                                )->a( n = `priority` v = `NeverOverflow`

                        )->end(
                    )->end(
                )->end(
            )->end(

            )->ele( n = `sideContent` ns = `tnt`
                )->ele( n = `SideNavigation` ns = `tnt`
                    )->a( n = `expanded`    v = `true`
                    )->a( n = `itemPress`   v = client->follow_up_action( val   = client->cs_event-control_global
                                                                          t_arg = temp2 )
                    )->a( n = `selectedKey` v = client->_bind( selectedkey )
                    " onItemSelect: pageContainer.to(createId(item.getKey())) - the key
                    " resolves client-side and the to() runs roundtrip-free
                    )->a( n = `itemSelect`  v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                          t_arg = temp3 )
                    )->ele( n = `NavigationList` ns = `tnt`
                        )->a( n = `items` v = client->_bind( navigation )
                        )->ele( n = `NavigationListItem` ns = `tnt`
                            )->a( n = `text`       v = `{TITLE}`
                            )->a( n = `icon`       v = `{ICON}`
                            )->a( n = `enabled`    v = `{ENABLED}`
                            )->a( n = `expanded`   v = `{EXPANDED}`
                            )->a( n = `items`      v = `{ITEMS}`
                            )->a( n = `selectable` v = `{SELECTABLE}`
                            )->a( n = `key`        v = `{KEY}`
                            )->tag( n = `NavigationListItem` ns = `tnt`
                                )->a( n = `text`    v = `{TITLE}`
                                )->a( n = `key`     v = `{KEY}`
                                )->a( n = `enabled` v = `{ENABLED}`

                        )->end(
                    )->end(
                    )->ele( n = `fixedItem` ns = `tnt`
                        )->ele( n = `NavigationList` ns = `tnt`
                            )->a( n = `items` v = client->_bind( fixednavigation )
                            )->tag( n = `NavigationListItem` ns = `tnt`
                                )->a( n = `text`         v = `{TITLE}`
                                )->a( n = `icon`         v = `{ICON}`
                                )->a( n = `ariaHasPopup` v = `{ARIAHASPOPUP}`
                                )->a( n = `design`       v = `{DESIGN}`
                                )->a( n = `press`        v = client->_event( val   = `QUICK_ACTION`
                                                                             t_arg = temp4 )
                                )->a( n = `selectable`   v = `{SELECTABLE}`

                        )->end(
                    )->end(
                )->end(
            )->end(

            )->ele( n = `mainContents` ns = `tnt`
                )->ele( `NavContainer`
                    )->a( n = `id`          v = `pageContainer`
                    )->a( n = `initialPage` v = `page2`
                    )->ele( `pages`
                        )->ele( `ScrollContainer`
                            )->a( n = `id`         v = `root1`
                            )->a( n = `horizontal` v = `false`
                            )->a( n = `vertical`   v = `true`
                            )->a( n = `height`     v = `100%`
                            )->a( n = `class`      v = `sapUiContentPadding`
                            )->tag( `Text`
                                )->a( n = `text` v = `This is the root page`

                        )->end(
                        )->ele( `ScrollContainer`
                            )->a( n = `id`         v = `page1`
                            )->a( n = `horizontal` v = `false`
                            )->a( n = `vertical`   v = `true`
                            )->a( n = `height`     v = `100%`
                            )->a( n = `class`      v = `sapUiContentPadding`
                            )->tag( `Text`
                                )->a( n = `text` v = `This is the first page`

                        )->end(
                        )->ele( `ScrollContainer`
                            )->a( n = `id`         v = `page2`
                            )->a( n = `horizontal` v = `false`
                            )->a( n = `vertical`   v = `true`
                            )->a( n = `height`     v = `100%`
                            )->a( n = `class`      v = `sapUiContentPadding`
                            )->tag( `Text`
                                )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipisicing elit. (content abbreviated from the original filler text)`

                        )->end(
                        )->ele( `ScrollContainer`
                            )->a( n = `id`         v = `root2`
                            )->a( n = `horizontal` v = `false`
                            )->a( n = `vertical`   v = `true`
                            )->a( n = `height`     v = `100%`
                            )->a( n = `class`      v = `sapUiContentPadding`
                            )->tag( `Text`
                                )->a( n = `text` v = `This is the root page of the second element`

                        )->end(
                    )->end(
                )->end(
            )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string.
        DATA temp1 TYPE xsdboolean.
        DATA popover TYPE REF TO z2ui5_cl_ui5_view_builder.
          DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.

    CASE client->get_event( ).

      WHEN `SIDE_TOGGLE`.
        " onSideNavButtonPress: tooltip from the PRE-toggle expanded state
        " (_setToggleButtonTooltip(bSideExpanded)), then setSideExpanded(!...)
        
        IF sideexpanded = abap_true.
          temp3 = `Large Size Navigation`.
        ELSE.
          temp3 = `Small Size Navigation`.
        ENDIF.
        toggle_tooltip = temp3.
        
        temp1 = boolc( sideexpanded = abap_false ).
        sideexpanded = temp1.

      WHEN `USER_POPOVER`.
        " handleUserNamePress: the controller-built Popover (no header, Bottom,
        " three transparent buttons), opened by the pressed user button
        
        popover = z2ui5_cl_ui5_view_builder=>factory( ).

        popover->ele( n = `FragmentDefinition` ns = `core`
            )->a( n = `xmlns:core` v = `sap.ui.core`
            )->a( n = `xmlns`      v = `sap.m`

            )->ele( `Popover`
                )->a( n = `showHeader` v = `false`
                )->a( n = `placement`  v = `Bottom`
                )->a( n = `class`      v = `sapMOTAPopover sapTntToolHeaderPopover`

                )->ele( `content`
                    )->tag( `Button`
                        )->a( n = `text` v = `Feedback`
                        )->a( n = `type` v = `Transparent`
                    )->tag( `Button`
                        )->a( n = `text` v = `Help`
                        )->a( n = `type` v = `Transparent`
                    )->tag( `Button`
                        )->a( n = `text` v = `Logout`
                        )->a( n = `type` v = `Transparent` ).

        client->popover_display( xml   = popover->stringify( )
                                 by_id = client->get_event_arg( ) ).

      WHEN `QUICK_ACTION`.
        " onQuickActionPress: only a design=Action item opens the dialog
        IF client->get_event_arg( ) = `Action`.
          
          popup = z2ui5_cl_ui5_view_builder=>factory( ).

          popup->ele( n = `FragmentDefinition` ns = `core`
              )->a( n = `xmlns:core` v = `sap.ui.core`
              )->a( n = `xmlns`      v = `sap.m`

              )->ele( `Dialog`
                  )->a( n = `title` v = `Create Item`
                  )->a( n = `type`  v = `Message`

                  )->ele( `content`
                      )->tag( `Text`
                          )->a( n = `text` v = `Create New Navigation List Item`

                  )->end(
                  )->ele( `beginButton`
                      )->tag( `Button`
                          )->a( n = `type`  v = `Emphasized`
                          )->a( n = `text`  v = `Create`
                          )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close )

                  )->end(
                  )->ele( `endButton`
                      )->tag( `Button`
                          )->a( n = `text`  v = `Cancel`
                          )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close ) ).

          client->popup_display( popup->stringify( ) ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.
    DATA temp4 LIKE navigation.
    DATA temp5 LIKE LINE OF temp4.
    DATA temp8 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp9 LIKE LINE OF temp8.
    DATA temp10 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp11 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp12 LIKE LINE OF temp11.
    DATA temp13 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp14 LIKE LINE OF temp13.
    DATA temp15 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp16 LIKE LINE OF temp15.
    DATA temp17 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp18 LIKE LINE OF temp17.
    DATA temp19 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp20 LIKE LINE OF temp19.
    DATA temp21 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp22 LIKE LINE OF temp21.
    DATA temp23 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp24 LIKE LINE OF temp23.
    DATA temp25 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp26 LIKE LINE OF temp25.
    DATA temp27 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp28 LIKE LINE OF temp27.
    DATA temp29 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp30 LIKE LINE OF temp29.
    DATA temp31 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp32 LIKE LINE OF temp31.
    DATA temp33 TYPE z2ui5_cl_smpc_app_167=>ty_child_tt.
    DATA temp34 LIKE LINE OF temp33.
    DATA temp6 LIKE fixednavigation.
    DATA temp7 LIKE LINE OF temp6.

    " onInit: _setToggleButtonTooltip(!Device.system.desktop) - the desktop
    " default; the ToolPage starts with its side content expanded (UI5 default)
    sideexpanded   = abap_true.
    toggle_tooltip = `Small Size Navigation`.

    
    CLEAR temp4.
    
    temp5-title = `Root Item 1`.
    temp5-icon = `sap-icon://employee`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_true.
    temp5-key = `root1`.
    temp5-selectable = abap_false.
    
    CLEAR temp8.
    
    temp9-title = `Child Item 1`.
    temp9-key = `page1`.
    temp9-enabled = abap_true.
    INSERT temp9 INTO TABLE temp8.
    temp9-title = `Child Item 2`.
    temp9-key = `page2`.
    temp9-enabled = abap_true.
    INSERT temp9 INTO TABLE temp8.
    temp5-items = temp8.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 2`.
    temp5-icon = `sap-icon://building`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = `root2`.
    temp5-selectable = abap_false.
    
    CLEAR temp10.
    temp5-items = temp10.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 3`.
    temp5-icon = `sap-icon://card`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_true.
    
    CLEAR temp11.
    
    temp12-title = `Child Item 1`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 2`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 3`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 4`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 5`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 6`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 7`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 8`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 9`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 10`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 11`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 12`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 13`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 14`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 15`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 16`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 17`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 18`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 19`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 20`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 21`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 22`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 23`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 24`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 25`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 26`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 27`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 28`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 29`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 30`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 31`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 32`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 33`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 34`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 35`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 36`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 37`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `Child Item 38`.
    temp12-key = ``.
    temp12-enabled = abap_true.
    INSERT temp12 INTO TABLE temp11.
    temp5-items = temp11.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 4`.
    temp5-icon = `sap-icon://action`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp13.
    
    temp14-title = `Child Item 1`.
    temp14-key = ``.
    temp14-enabled = abap_true.
    INSERT temp14 INTO TABLE temp13.
    temp14-title = `Child Item 2`.
    temp14-key = ``.
    temp14-enabled = abap_true.
    INSERT temp14 INTO TABLE temp13.
    temp14-title = `Child Item 3`.
    temp14-key = ``.
    temp14-enabled = abap_true.
    INSERT temp14 INTO TABLE temp13.
    temp5-items = temp13.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 5`.
    temp5-icon = `sap-icon://action-settings`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp15.
    
    temp16-title = `Child Item 1`.
    temp16-key = ``.
    temp16-enabled = abap_true.
    INSERT temp16 INTO TABLE temp15.
    temp16-title = `Child Item 2`.
    temp16-key = ``.
    temp16-enabled = abap_true.
    INSERT temp16 INTO TABLE temp15.
    temp16-title = `Child Item 3`.
    temp16-key = ``.
    temp16-enabled = abap_true.
    INSERT temp16 INTO TABLE temp15.
    temp5-items = temp15.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 6`.
    temp5-icon = `sap-icon://activate`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp17.
    
    temp18-title = `Child Item 1`.
    temp18-key = ``.
    temp18-enabled = abap_true.
    INSERT temp18 INTO TABLE temp17.
    temp18-title = `Child Item 2`.
    temp18-key = ``.
    temp18-enabled = abap_true.
    INSERT temp18 INTO TABLE temp17.
    temp18-title = `Child Item 3`.
    temp18-key = ``.
    temp18-enabled = abap_true.
    INSERT temp18 INTO TABLE temp17.
    temp5-items = temp17.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 7`.
    temp5-icon = `sap-icon://activities`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp19.
    
    temp20-title = `Child Item 1`.
    temp20-key = ``.
    temp20-enabled = abap_true.
    INSERT temp20 INTO TABLE temp19.
    temp20-title = `Child Item 2`.
    temp20-key = ``.
    temp20-enabled = abap_true.
    INSERT temp20 INTO TABLE temp19.
    temp20-title = `Child Item 3`.
    temp20-key = ``.
    temp20-enabled = abap_true.
    INSERT temp20 INTO TABLE temp19.
    temp5-items = temp19.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 8`.
    temp5-icon = `sap-icon://add`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp21.
    
    temp22-title = `Child Item 1`.
    temp22-key = ``.
    temp22-enabled = abap_true.
    INSERT temp22 INTO TABLE temp21.
    temp22-title = `Child Item 2`.
    temp22-key = ``.
    temp22-enabled = abap_true.
    INSERT temp22 INTO TABLE temp21.
    temp22-title = `Child Item 3`.
    temp22-key = ``.
    temp22-enabled = abap_true.
    INSERT temp22 INTO TABLE temp21.
    temp5-items = temp21.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 9`.
    temp5-icon = `sap-icon://arobase`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp23.
    
    temp24-title = `Child Item 1`.
    temp24-key = ``.
    temp24-enabled = abap_true.
    INSERT temp24 INTO TABLE temp23.
    temp24-title = `Child Item 2`.
    temp24-key = ``.
    temp24-enabled = abap_true.
    INSERT temp24 INTO TABLE temp23.
    temp24-title = `Child Item 3`.
    temp24-key = ``.
    temp24-enabled = abap_true.
    INSERT temp24 INTO TABLE temp23.
    temp5-items = temp23.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 10`.
    temp5-icon = `sap-icon://attachment`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp25.
    
    temp26-title = `Child Item 1`.
    temp26-key = ``.
    temp26-enabled = abap_true.
    INSERT temp26 INTO TABLE temp25.
    temp26-title = `Child Item 2`.
    temp26-key = ``.
    temp26-enabled = abap_true.
    INSERT temp26 INTO TABLE temp25.
    temp26-title = `Child Item 3`.
    temp26-key = ``.
    temp26-enabled = abap_true.
    INSERT temp26 INTO TABLE temp25.
    temp5-items = temp25.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 11`.
    temp5-icon = `sap-icon://badge`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp27.
    
    temp28-title = `Child Item 1`.
    temp28-key = ``.
    temp28-enabled = abap_true.
    INSERT temp28 INTO TABLE temp27.
    temp28-title = `Child Item 2`.
    temp28-key = ``.
    temp28-enabled = abap_true.
    INSERT temp28 INTO TABLE temp27.
    temp28-title = `Child Item 3`.
    temp28-key = ``.
    temp28-enabled = abap_true.
    INSERT temp28 INTO TABLE temp27.
    temp5-items = temp27.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 12`.
    temp5-icon = `sap-icon://basket`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp29.
    
    temp30-title = `Child Item 1`.
    temp30-key = ``.
    temp30-enabled = abap_true.
    INSERT temp30 INTO TABLE temp29.
    temp30-title = `Child Item 2`.
    temp30-key = ``.
    temp30-enabled = abap_true.
    INSERT temp30 INTO TABLE temp29.
    temp30-title = `Child Item 3`.
    temp30-key = ``.
    temp30-enabled = abap_true.
    INSERT temp30 INTO TABLE temp29.
    temp5-items = temp29.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 13`.
    temp5-icon = `sap-icon://bed`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp31.
    
    temp32-title = `Child Item 1`.
    temp32-key = ``.
    temp32-enabled = abap_true.
    INSERT temp32 INTO TABLE temp31.
    temp32-title = `Child Item 2`.
    temp32-key = ``.
    temp32-enabled = abap_true.
    INSERT temp32 INTO TABLE temp31.
    temp32-title = `Child Item 3`.
    temp32-key = ``.
    temp32-enabled = abap_true.
    INSERT temp32 INTO TABLE temp31.
    temp5-items = temp31.
    INSERT temp5 INTO TABLE temp4.
    temp5-title = `Root Item 14`.
    temp5-icon = `sap-icon://bookmark`.
    temp5-enabled = abap_true.
    temp5-expanded = abap_false.
    temp5-key = ``.
    temp5-selectable = abap_false.
    
    CLEAR temp33.
    
    temp34-title = `Child Item 1`.
    temp34-key = ``.
    temp34-enabled = abap_true.
    INSERT temp34 INTO TABLE temp33.
    temp34-title = `Child Item 2`.
    temp34-key = ``.
    temp34-enabled = abap_true.
    INSERT temp34 INTO TABLE temp33.
    temp34-title = `Child Item 3`.
    temp34-key = ``.
    temp34-enabled = abap_true.
    INSERT temp34 INTO TABLE temp33.
    temp5-items = temp33.
    INSERT temp5 INTO TABLE temp4.
    navigation = temp4.

    " data.json omits ariaHasPopup, design AND selectable on Fixed Item 1-3;
    " each is seeded with the control's own default - selectable is TRUE
    " (NavigationListItem.selectable defaultValue: true), corrected 2026-08-21
    " after the review sweep found all three seeded false, which silently took
    " their selection behaviour away. The UI5 enum
    " defaults (None, Default) are seeded explicitly because an empty string
    " would be rejected by the enum validation (AGENTS section 5)
    
    CLEAR temp6.
    
    temp7-title = `Quick Create`.
    temp7-icon = `sap-icon://write-new`.
    temp7-ariahaspopup = `Dialog`.
    temp7-design = `Action`.
    temp7-selectable = abap_false.
    INSERT temp7 INTO TABLE temp6.
    temp7-title = `Fixed Item 1`.
    temp7-icon = `sap-icon://employee`.
    temp7-ariahaspopup = `None`.
    temp7-design = `Default`.
    temp7-selectable = abap_true.
    INSERT temp7 INTO TABLE temp6.
    temp7-title = `Fixed Item 2`.
    temp7-icon = `sap-icon://building`.
    temp7-ariahaspopup = `None`.
    temp7-design = `Default`.
    temp7-selectable = abap_true.
    INSERT temp7 INTO TABLE temp6.
    temp7-title = `Fixed Item 3`.
    temp7-icon = `sap-icon://card`.
    temp7-ariahaspopup = `None`.
    temp7-design = `Default`.
    temp7-selectable = abap_true.
    INSERT temp7 INTO TABLE temp6.
    fixednavigation = temp6.

  ENDMETHOD.

ENDCLASS.
