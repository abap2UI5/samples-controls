" @keywords sidepanel side panel sap.f sidepaneloverflow button vbox label switch text sidepanelitem
" @summary Demonstrates the usage of Side Panel with overflow menu on desktop and tablet devices.
" @origin sap.f.sample.SidePanelOverflow - https://sdk.openui5.org/entity/sap.f.SidePanel/sample/sap.f.sample.SidePanelOverflow (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_664 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA prevent_expand   TYPE abap_bool.
    DATA prevent_collapse TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_664 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " onToggle vetoes the firing (preventDefault) when the Switch for its
    " direction is on - decided per firing on the client, reading the two
    " two-way bound Switch states: (!expanded && collapse) || (expanded && expand)
    DATA(veto_expr) = `(!${$parameters>/expanded} && $` && client->_bind( prevent_collapse ) &&
                      `) || (${$parameters>/expanded} && $` && client->_bind( prevent_expand ) && `)`.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:f`   v = `sap.f`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `height`    v = `100%`

        )->ele( `Page`
            )->ele( `content`
                )->ele( n = `SidePanel` ns = `f`
                    )->a( n = `id`     v = `mySidePanel`
                    )->a( n = `toggle` v = client->_event( val    = `TOGGLE`
                                                           arg    = `${$parameters>/expanded}`
                                                           s_ctrl = VALUE #( prevent_default_expr = veto_expr check_queue_last = abap_true ) )

                    )->ele( n = `mainContent` ns = `f`
                        )->tag( `Button`
                            )->a( n = `text` v = `Button 1`
                        )->tag( `Button`
                            )->a( n = `text` v = `Button 2`

                        )->ele( `VBox`
                            )->a( n = `class` v = `sapUiSmallMarginTopBottom`

                            )->tag( `Label`
                                )->a( n = `text` v = `Prevent next toggle (expand) event`
                            )->tag( `Switch`
                                )->a( n = `id`    v = `preventExpand`
                                )->a( n = `state` v = client->_bind( prevent_expand )
                                )->a( n = `type`  v = `AcceptReject`
                                )->a( n = `class` v = `sapUiSmallMarginBottom`
                            )->tag( `Label`
                                )->a( n = `text` v = `Prevent next toggle (collapse) event`
                            )->tag( `Switch`
                                )->a( n = `id`    v = `preventCollapse`
                                )->a( n = `state` v = client->_bind( prevent_collapse )
                                )->a( n = `type`  v = `AcceptReject`
                                )->a( n = `class` v = `sapUiSmallMarginBottom`

                        )->end(

                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`
                        )->tag( `Text`
                            )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ` &&
                                                 `ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ` &&
                                                 `occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum`

                    )->end(

                    )->ele( n = `items` ns = `f`
                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://physical-activity`
                            )->a( n = `text` v = `Run`

                            )->ele( `VBox`
                                )->tag( `Text`
                                    )->a( n = `text`  v = `Static Content`
                                    )->a( n = `class` v = `sapUiSmallMarginBottom`
                                )->tag( `Text`
                                    )->a( n = `text` v = `Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.`
                                )->tag( `Switch`
                                )->tag( `Button`
                                    )->a( n = `text` v = `Press me`

                            )->end(
                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://addresses`
                            )->a( n = `text` v = `Go home`

                            )->ele( `VBox`
                                )->tag( `Text`
                                    )->a( n = `text`  v = `Static Content`
                                    )->a( n = `class` v = `sapUiSmallMarginBottom`
                                )->tag( `Button`
                                    )->a( n = `text` v = `Press me`
                                )->tag( `Button`
                                    )->a( n = `text` v = `Hit me`
                                )->tag( `Button`
                                    )->a( n = `text` v = `Touch me`

                            )->end(
                        )->end(

                        )->tag( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon`    v = `sap-icon://building`
                            )->a( n = `text`    v = `Go to office`
                            )->a( n = `enabled` v = `false`

                        " onToggle replaces the content of every item past the second with this Text
                        " when it expands - declared up front per enabled item, only ever seen expanded
                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://bed`
                            )->a( n = `text` v = `Go to sleep`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Go to sleep'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://flight`
                            )->a( n = `text` v = `Fly abroad`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Fly abroad'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://cargo-train`
                            )->a( n = `text` v = `Travel`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Travel'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://cart`
                            )->a( n = `text` v = `Go to the mall`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Go to the mall'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://car-rental`
                            )->a( n = `text` v = `Drive your car`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Drive your car'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://create-leave-request`
                            )->a( n = `text` v = `Go on vacation`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Go on vacation'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://family-protection`
                            )->a( n = `text` v = `Meet your family`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Meet your family'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://lab`
                            )->a( n = `text` v = `Do a research`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Do a research'`

                        )->end(

                        )->tag( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon`    v = `sap-icon://theater`
                            )->a( n = `text`    v = `Go to the theater`
                            )->a( n = `enabled` v = `false`

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://taxi`
                            )->a( n = `text` v = `Take a taxi`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Take a taxi'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://vehicle-repair`
                            )->a( n = `text` v = `Repair your car`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Repair your car'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://wounds-doc`
                            )->a( n = `text` v = `Visit a doctor`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Visit a doctor'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://umbrella`
                            )->a( n = `text` v = `Take an umbrella`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Take an umbrella'`

                        )->end(

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://puzzle`
                            )->a( n = `text` v = `Solve a puzzle`

                            )->tag( `Text`
                                )->a( n = `text` v = `Dynamically created content for item 'Solve a puzzle'`

                        )->end(

                        )->tag( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon`    v = `sap-icon://picture`
                            )->a( n = `text`    v = `Draw a picture`
                            )->a( n = `enabled` v = `false` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `TOGGLE`.
      " the event reaches the backend whether or not the veto fired; on a
      " vetoed direction the original toasts and resets that Switch, otherwise
      " the control has already toggled itself. No view_display( ): the
      " expanded item lives in the control, a re-render would collapse it
      DATA(expanded) = xsdbool( client->get_event_arg( ) = abap_true ).
      IF expanded = abap_false AND prevent_collapse = abap_true.
        prevent_collapse = abap_false.
        client->message_toast_display( `I am prevented COLLAPSE event` ).
      ELSEIF expanded = abap_true AND prevent_expand = abap_true.
        prevent_expand = abap_false.
        client->message_toast_display( `I am prevented EXPAND event` ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
