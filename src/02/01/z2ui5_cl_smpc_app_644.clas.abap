" @keywords container sap.m.p13n p13n.container vbox radiobuttongroup radiobutton label button text
" @summary Dialog & Popover with a sap.m.P13nContainer as content.
" @origin sap.m.sample.p13n.Container - https://sdk.openui5.org/entity/sap.m.p13n.Container/sample/sap.m.sample.p13n.Container (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_644 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA dialog_index TYPE i.
    DATA layout_index TYPE i.
    DATA listlayout   TYPE abap_bool.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_view,
        key     TYPE string,
        text    TYPE string,
        content TYPE string,
      END OF ty_s_view.
    TYPES ty_t_view TYPE STANDARD TABLE OF ty_s_view WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    DATA t_dialog_views TYPE ty_t_view.
    DATA t_popover_views TYPE ty_t_view.

    METHODS view_display.
    METHODS on_event.
    METHODS open_dialog.
    METHODS open_popover.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_644 IMPLEMENTATION.

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
    DATA vbox TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA dialog TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA dialog_container TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA popover TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA popover_container TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA dialog_view LIKE LINE OF t_dialog_views.
      DATA dialog_item TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA popover_view LIKE LINE OF t_popover_views.
      DATA popover_item TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    vbox = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`
        )->a( n = `height`     v = `100%`
        )->a( n = `class`      v = `sapUiContentPadding`

        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin` ).

    vbox->tag( `Label`
        )->a( n = `labelFor` v = `dialogChose`
        )->a( n = `text`     v = `Chose Popup type`

        )->ele( `RadioButtonGroup`
            )->a( n = `id`            v = `dialogChose`
            )->a( n = `columns`       v = `2`
            )->a( n = `class`         v = `sapUiMediumMarginBottom`
            )->a( n = `selectedIndex` v = client->_bind( dialog_index )

            )->tag( `RadioButton`
                )->a( n = `id`   v = `dlg`
                )->a( n = `text` v = `Dialog`
            )->tag( `RadioButton`
                )->a( n = `id`   v = `ppr`
                )->a( n = `text` v = `Popover`

        )->end(

        )->tag( `Label`
            )->a( n = `labelFor` v = `layoutType`
            )->a( n = `text`     v = `Chose P13nContainer layout type`

        )->ele( `RadioButtonGroup`
            )->a( n = `select`        v = client->_event( val = `SELECT_LAYOUT`
                                                          arg = `${$parameters>/selectedIndex}` )
            )->a( n = `id`            v = `layoutType`
            )->a( n = `columns`       v = `2`
            )->a( n = `class`         v = `sapUiMediumMarginBottom`
            )->a( n = `selectedIndex` v = client->_bind( layout_index )

            )->tag( `RadioButton`
                )->a( n = `id`   v = `list`
                )->a( n = `text` v = `List`
            )->tag( `RadioButton`
                )->a( n = `id`   v = `tabs`
                )->a( n = `text` v = `IconTabBar`

        )->end(

        )->tag( `Button`
            )->a( n = `id`    v = `openBtn`
            )->a( n = `text`  v = `Show P13nContainer used in Popup`
            )->a( n = `press` v = client->_event( `OPEN` ) ).

    
    dialog = vbox->ele( `Dialog`
        )->a( n = `id`                v = `d1`
        )->a( n = `title`             v = `My custom p13n Dialog`
        )->a( n = `verticalScrolling` v = `false`
        )->a( n = `contentWidth`      v = `25rem`
        )->a( n = `contentHeight`     v = `35rem` ).

    
    dialog_container = dialog->ele( n = `Container` ns = `p13n`
        )->a( n = `id`          v = `P13nContainer`
        )->a( n = `listLayout`  v = client->_bind( listlayout )
        )->a( n = `defaultView` v = `view2` ).

    
    CLEAR temp1.
    INSERT `d1` INTO TABLE temp1.
    INSERT `close` INTO TABLE temp1.
    dialog->ele( `buttons`
        )->tag( `Button`
            )->a( n = `text`  v = `Add custom view`
            )->a( n = `press` v = client->_event( `ADD_VIEW_DIALOG` )
        )->tag( `Button`
            )->a( n = `text`  v = `Close Dialog`
            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                            t_arg = temp1 ) ).

    
    popover = vbox->ele( `ResponsivePopover`
        )->a( n = `id`                v = `p1`
        )->a( n = `title`             v = `My custom p13n Popover`
        )->a( n = `verticalScrolling` v = `false`
        )->a( n = `contentWidth`      v = `25rem`
        )->a( n = `contentHeight`     v = `15rem` ).

    
    popover_container = popover->ele( n = `Container` ns = `p13n`
        )->a( n = `id`          v = `P13nContainerPopover`
        )->a( n = `listLayout`  v = client->_bind( listlayout )
        )->a( n = `defaultView` v = `view2` ).

    popover->ele( `beginButton`
        )->tag( `Button`
            )->a( n = `text`  v = `Add custom view`
            )->a( n = `press` v = client->_event( `ADD_VIEW_POPOVER` ) ).

    " the three static views of each container, plus the ones addCustomView
    " appended - the controller's addView( ) is a backend row and a rebuild
    
    LOOP AT t_dialog_views INTO dialog_view.
      
      dialog_item = dialog_container->ele( n = `AbstractContainerItem` ns = `p13n`
          )->a( n = `key`  t = dialog_view-key
          )->a( n = `text` t = dialog_view-text ).
      IF dialog_view-content IS NOT INITIAL.
        dialog_item->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`
            )->tag( `Text`
                )->a( n = `text` t = dialog_view-content ).
      ENDIF.
    ENDLOOP.

    
    LOOP AT t_popover_views INTO popover_view.
      
      popover_item = popover_container->ele( n = `AbstractContainerItem` ns = `p13n`
          )->a( n = `key`  t = popover_view-key
          )->a( n = `text` t = popover_view-text ).
      IF popover_view-content IS NOT INITIAL.
        popover_item->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`
            )->tag( `Text`
                )->a( n = `text` t = popover_view-content ).
      ENDIF.
    ENDLOOP.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp1 TYPE xsdboolean.
        DATA count TYPE i.
        DATA temp3 TYPE z2ui5_cl_smpc_app_644=>ty_s_view.
        DATA temp4 TYPE z2ui5_cl_smpc_app_644=>ty_s_view.

    CASE client->get_event( ).

      WHEN `SELECT_LAYOUT`.
        
        temp1 = boolc( client->get_event_arg( ) = `0` ).
        listlayout = temp1.

      WHEN `OPEN`.
        IF dialog_index = 0.
          open_dialog( ).
        ELSE.
          open_popover( ).
        ENDIF.

      WHEN `ADD_VIEW_DIALOG`.
        " "View " + getViews( ).length: the views BEFORE adding, the Container's
        " own $default navigation view counted too
        
        count = lines( t_dialog_views ) + 1.
        
        CLEAR temp3.
        temp3-key = |view{ count }|.
        temp3-text = |View { count }|.
        INSERT temp3 INTO TABLE t_dialog_views.
        view_display( ).
        open_dialog( ).

      WHEN `ADD_VIEW_POPOVER`.
        count = lines( t_popover_views ) + 1.
        
        CLEAR temp4.
        temp4-key = |view{ count }|.
        temp4-text = |View { count }|.
        INSERT temp4 INTO TABLE t_popover_views.
        view_display( ).
        open_popover( ).

    ENDCASE.

  ENDMETHOD.


  METHOD open_dialog.

    DATA temp5 TYPE string_table.
    CLEAR temp5.
    INSERT `d1` INTO TABLE temp5.
    INSERT `open` INTO TABLE temp5.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp5 ).

  ENDMETHOD.


  METHOD open_popover.

    DATA temp7 TYPE string_table.
    CLEAR temp7.
    INSERT `p1` INTO TABLE temp7.
    INSERT `openBy` INTO TABLE temp7.
    INSERT `openBtn` INTO TABLE temp7.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp7 ).

  ENDMETHOD.


  METHOD model_init.
    DATA temp9 TYPE z2ui5_cl_smpc_app_644=>ty_t_view.
    DATA temp10 LIKE LINE OF temp9.

    listlayout = abap_true.

    
    CLEAR temp9.
    
    temp10-key = `view1`.
    temp10-text = `View 1`.
    temp10-content = `My Test View 1`.
    INSERT temp10 INTO TABLE temp9.
    temp10-key = `view2`.
    temp10-text = `View 2`.
    temp10-content = `My Test View 2`.
    INSERT temp10 INTO TABLE temp9.
    temp10-key = `view3`.
    temp10-text = `View 3`.
    temp10-content = `My Test View 3`.
    INSERT temp10 INTO TABLE temp9.
    t_dialog_views = temp9.
    t_popover_views = t_dialog_views.

  ENDMETHOD.

ENDCLASS.
