" @keywords notificationlistgroup notification list group sap.m notificationlistgrouplazyloading vbox notificationlist flexitemdata button notificationlistitem
" @summary Notification List Group with lazy loading of the notifications.
" @origin sap.m.sample.NotificationListGroupLazyLoading - https://sdk.openui5.org/entity/sap.m.NotificationListGroup/sample/sap.m.sample.NotificationListGroupLazyLoading (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_520 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_notification,
        group    TYPE i,
        id       TYPE i,
        title    TYPE string,
        datetime TYPE string,
        priority TYPE string,
      END OF ty_s_notification.
    TYPES ty_t_notification TYPE STANDARD TABLE OF ty_s_notification WITH DEFAULT KEY.

    DATA t_group1 TYPE ty_t_notification.
    DATA t_group2 TYPE ty_t_notification.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS group_fill IMPORTING group TYPE i.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_520 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA list TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA group LIKE sy-index.
      DATA temp1 TYPE string.
      DATA items LIKE temp1.
      DATA temp2 TYPE string_table.
      DATA temp3 LIKE LINE OF temp2.
      DATA temp4 TYPE string_table.
      DATA temp5 TYPE string_table.
      DATA temp6 TYPE string_table.
      DATA temp7 LIKE LINE OF temp6.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    list = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `class`     v = `sapUiBodyBackground sapContrastPlus`

        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->ele( `NotificationList`
                )->a( n = `class` v = `sapContrast sapContrastPlus` ).

    list->ele( `layoutData`
        )->tag( `FlexItemData`
            )->a( n = `maxWidth` v = `600px` ).

    " the two groups are identical in the original and differ only in the table
    " their lazily loaded items land in
    DO 2 TIMES.
      
      group = sy-index.
      
      IF group = 1.
        temp1 = client->_bind( t_group1 ).
      ELSE.
        temp1 = client->_bind( t_group2 ).
      ENDIF.
      
      items = temp1.

      
      CLEAR temp2.
      
      temp3 = |{ group }|.
      INSERT temp3 INTO TABLE temp2.
      INSERT `${$parameters>/collapsed} ? 'collapsed' : 'expanded'` INTO TABLE temp2.
      
      CLEAR temp4.
      INSERT `MESSAGE_TOAST` INTO TABLE temp4.
      INSERT `show` INTO TABLE temp4.
      INSERT `Accept Button Pressed` INTO TABLE temp4.
      
      CLEAR temp5.
      INSERT `MESSAGE_TOAST` INTO TABLE temp5.
      INSERT `show` INTO TABLE temp5.
      INSERT `Reject Button Pressed` INTO TABLE temp5.
      
      CLEAR temp6.
      
      temp7 = |{ group }|.
      INSERT temp7 INTO TABLE temp6.
      INSERT `${ID}` INTO TABLE temp6.
      list->ele( `NotificationListGroup`
          )->a( n = `title`                         v = `3 messages. They will be lazy loaded when 'Expand' button is pressed.`
          )->a( n = `showCloseButton`               v = `true`
          )->a( n = `showItemsCounter`              v = `false`
          )->a( n = `collapsed`                     v = `true`
          " onToggleCollapse fills the group the first time it is expanded
          " The collapsed flag travels as a STRING TOKEN, not as the raw boolean:
          " a JSON boolean t_arg is normalised to X/space by ajson on a real
          " system, but reaches the transpiled backend verbatim as 'true'/'false'
          " - and 'false' is not INITIAL, so the group was never filled there
          " (e2e-caught 2026-08-22, the app 421 idiom).
          )->a( n = `onCollapse`                    v = client->_event( val   = `TOGGLE_COLLAPSE`
                                                                        t_arg = temp2 )
          )->a( n = `close`                         v = client->_event( val = `GROUP_CLOSE` arg = |{ group }| )
          )->a( n = `showEmptyGroup`                v = `true`
          )->a( n = `enableCollapseButtonWhenEmpty` v = `true`
          )->a( n = `items`                         v = items

          )->ele( `buttons`
              )->tag( `Button`
                  )->a( n = `text`  v = `Accept All`
                  )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                  t_arg = temp4 )
              )->tag( `Button`
                  )->a( n = `text`  v = `Reject All`
                  )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_global
                                                                  t_arg = temp5 )
              )->tag( `Button`
                  )->a( n = `text`  v = `Get items count`
                  )->a( n = `press` v = client->_event( val = `ITEMS_COUNT` arg = |{ group }| )

          )->end(

          )->tag( `NotificationListItem`
              )->a( n = `title`           v = `{TITLE}`
              " _addItemsToGroup creates each item with unread: true; ListItemBase
              " defaults it to false, so without this every notification renders read
              )->a( n = `unread`          v = `true`
              )->a( n = `showCloseButton` v = `true`
              )->a( n = `datetime`        v = `{DATETIME}`
              )->a( n = `priority`        v = `{PRIORITY}`
              )->a( n = `close`           v = client->_event( val   = `ITEM_CLOSE`
                                                              t_arg = temp6 )

      )->end( ).
    ENDDO.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    DATA temp4 TYPE i.
    DATA group LIKE temp4.
        DATA temp5 TYPE i.
        DATA count LIKE temp5.
        DATA temp6 TYPE i.
        DATA del_id LIKE temp6.
          DATA temp7 TYPE z2ui5_cl_smpc_app_520=>ty_t_notification.
          DATA temp8 TYPE z2ui5_cl_smpc_app_520=>ty_t_notification.
    temp4 = client->get_event_arg( ).
    
    group = temp4.

    CASE client->get_event( ).

      WHEN `TOGGLE_COLLAPSE`.
        " the group is filled the first time it is EXPANDED
        IF client->get_event_arg( 2 ) = `expanded`.
          group_fill( group ).
        ENDIF.

      WHEN `ITEMS_COUNT`.
        
        IF group = 1.
          temp5 = lines( t_group1 ).
        ELSE.
          temp5 = lines( t_group2 ).
        ENDIF.
        
        count = temp5.
        client->message_toast_display( |Number of items in group: { count }| ).

      WHEN `ITEM_CLOSE`.
        
        temp6 = client->get_event_arg( 2 ).
        
        del_id = temp6.
        IF group = 1.
          DELETE t_group1 WHERE id = del_id.
        ELSE.
          DELETE t_group2 WHERE id = del_id.
        ENDIF.
        client->message_toast_display( `Item Closed` ).

      WHEN `GROUP_CLOSE`.
        IF group = 1.
          
          CLEAR temp7.
          t_group1 = temp7.
        ELSE.
          
          CLEAR temp8.
          t_group2 = temp8.
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD group_fill.

    " _addItemsToGroup adds three notifications with RANDOM title, time and
    " priority; a backend cannot repeat a client-side random draw, so the port
    " walks the same three lists in order
    DATA temp9 TYPE string_table.
    DATA titles LIKE temp9.
    DATA temp11 TYPE string_table.
    DATA times LIKE temp11.
    DATA temp13 TYPE string_table.
    DATA priorities LIKE temp13.
      DATA index LIKE sy-index.
      DATA temp15 TYPE ty_s_notification.
      FIELD-SYMBOLS <temp6> LIKE LINE OF titles.
      DATA temp7 LIKE sy-tabix.
      FIELD-SYMBOLS <temp8> LIKE LINE OF times.
      DATA temp10 LIKE sy-tabix.
      FIELD-SYMBOLS <temp11> LIKE LINE OF priorities.
      DATA temp12 LIKE sy-tabix.
      DATA item LIKE temp15.
    CLEAR temp9.
    INSERT `New order request` INTO TABLE temp9.
    INSERT `Your vacation has been approved` INTO TABLE temp9.
    INSERT `New transaction in queue` INTO TABLE temp9.
    INSERT `A new request awaits your action` INTO TABLE temp9.
    
    titles = temp9.
    
    CLEAR temp11.
    INSERT `3 days` INTO TABLE temp11.
    INSERT `5 minutes` INTO TABLE temp11.
    INSERT `1 hour` INTO TABLE temp11.
    
    times = temp11.
    
    CLEAR temp13.
    INSERT `None` INTO TABLE temp13.
    INSERT `Low` INTO TABLE temp13.
    INSERT `Medium` INTO TABLE temp13.
    INSERT `High` INTO TABLE temp13.
    
    priorities = temp13.

    IF group = 1 AND t_group1 IS NOT INITIAL.
      RETURN.
    ENDIF.
    IF group = 2 AND t_group2 IS NOT INITIAL.
      RETURN.
    ENDIF.

    DO 3 TIMES.
      
      index = sy-index.
      
      CLEAR temp15.
      temp15-group = group.
      temp15-id = index.
      
      
      temp7 = sy-tabix.
      READ TABLE titles INDEX index MOD 4 + 1 ASSIGNING <temp6>.
      sy-tabix = temp7.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      temp15-title = <temp6>.
      
      
      temp10 = sy-tabix.
      READ TABLE times INDEX index MOD 3 + 1 ASSIGNING <temp8>.
      sy-tabix = temp10.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      temp15-datetime = <temp8>.
      
      
      temp12 = sy-tabix.
      READ TABLE priorities INDEX index MOD 4 + 1 ASSIGNING <temp11>.
      sy-tabix = temp12.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      temp15-priority = <temp11>.
      
      item = temp15.
      IF group = 1.
        APPEND item TO t_group1.
      ELSE.
        APPEND item TO t_group2.
      ENDIF.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
