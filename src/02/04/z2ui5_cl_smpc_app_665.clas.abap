" @keywords sidepanel side panel sap.f sidepanelresizable button vbox label switch text sidepanelitem input
" @summary Demonstrates the usage of resizable Side Panel.
" @origin sap.f.sample.SidePanelResizable - https://sdk.openui5.org/entity/sap.f.SidePanel/sample/sap.f.sample.SidePanelResizable (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_665 DEFINITION PUBLIC.

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


CLASS z2ui5_cl_smpc_app_665 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " onToggle vetoes the firing (preventDefault) when the Switch for its
    " direction is on - decided per firing on the client, reading the two
    " two-way bound Switch states: (!expanded && collapse) || (expanded && expand)
    DATA veto_expr TYPE string.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    veto_expr = `(!${$parameters>/expanded} && $` && client->_bind( prevent_collapse ) &&
                      `) || (${$parameters>/expanded} && $` && client->_bind( prevent_expand ) && `)`.

    
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    temp1-prevent_default_expr = veto_expr.
    temp1-check_queue_last = abap_true.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:f`   v = `sap.f`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `height`    v = `100%`

        )->ele( `Page`
            )->ele( `content`
                )->ele( n = `SidePanel` ns = `f`
                    )->a( n = `id`                 v = `mySidePanel`
                    )->a( n = `sidePanelResizable` v = `true`
                    )->a( n = `toggle`             v = client->_event( val    = `TOGGLE`
                                                                       arg    = `${$parameters>/expanded}`
                                                                       s_ctrl = temp1 )

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
                            )->tag( `Text`
                                )->a( n = `text`  v = `On desktop or tablet devices Side Panel can be resized while the side content is expanded. There are several different resize methods:`
                                )->a( n = `class` v = `sapUiSmallMarginBottom`
                            )->tag( `Text`
                                )->a( n = `text`  v = `By mouse: drag resize splitter to set the desired width.`
                                )->a( n = `class` v = `sapUiSmallMarginBottom`
                            )->tag( `Text`
                                )->a( n = `text`  v = `By Keyboard: focus the resize splitter, then resize with Arrow Keys (small step), Shift + Arrow Keys (large step), Home (minimum width), ` &&
                                                      `End (maximum width) or Enter (default width).`
                                )->a( n = `class` v = `sapUiSmallMarginBottom`
                            )->tag( `Text`
                                )->a( n = `text`  v = `By context menu: press Context Menu key or Shift + F10 and select one of the predefined widths (minimum, maximum or default).`
                                )->a( n = `class` v = `sapUiSmallMarginBottom`

                        )->end(
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
                                    )->a( n = `text` v = `Do some physical activity as it will greatly improve your health.`
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

                        )->ele( n = `SidePanelItem` ns = `f`
                            )->a( n = `icon` v = `sap-icon://building`
                            )->a( n = `text` v = `Go to office`

                            " onToggle builds this VBox into the third item when it expands (destroyContent +
                            " addContent) - declared here up front, it is only ever seen expanded
                            )->ele( `VBox`
                                )->tag( `Text`
                                    )->a( n = `text`  v = `Dynamically added content`
                                    )->a( n = `class` v = `sapUiSmallMarginBottom`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Label 1`
                                )->tag( `Input`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Label 2`
                                )->tag( `Input`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Label 3`
                                )->tag( `Input` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
      DATA expanded TYPE abap_bool.
      DATA temp1 TYPE xsdboolean.

    IF client->get_event( ) = `TOGGLE`.
      " the event reaches the backend whether or not the veto fired; on a
      " vetoed direction the original toasts and resets that Switch, otherwise
      " the control has already toggled itself. No view_display( ): the
      " expanded item lives in the control, a re-render would collapse it
      
      
      temp1 = boolc( client->get_event_arg( ) = abap_true ).
      expanded = temp1.
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
