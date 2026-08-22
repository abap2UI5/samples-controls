" @keywords semanticpage semantic sap.m.semantic master-detail actions splitcontainer pageaccessiblelandmarkinfo messagepopover messageitem pagingbutton overflowtoolbarbutton button
" @summary Semantic Page Master/Detail
CLASS z2ui5_cl_smpc_app_107 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES: BEGIN OF ty_s_filter,
             type TYPE string,
           END OF ty_s_filter.
    TYPES: BEGIN OF ty_s_message,
             message     TYPE string,
             description TYPE string,
             type        TYPE string,
           END OF ty_s_message.
    DATA t_filters  TYPE STANDARD TABLE OF ty_s_filter WITH DEFAULT KEY.
    DATA t_messages TYPE STANDARD TABLE OF ty_s_message WITH DEFAULT KEY.
    DATA sort_key   TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_107 IMPLEMENTATION.

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
    DATA temp6 TYPE string_table.
    DATA temp7 TYPE string_table.
    DATA temp8 TYPE string_table.
    DATA temp9 TYPE string_table.
    DATA temp10 TYPE string_table.
    DATA temp11 TYPE string_table.
    DATA temp12 TYPE string_table.
    DATA temp13 TYPE string_table.
    DATA temp14 TYPE string_table.
    DATA temp15 TYPE string_table.
    DATA temp16 TYPE string_table.
    DATA temp17 TYPE string_table.
    DATA temp18 TYPE string_table.
    DATA temp19 TYPE string_table.
    DATA temp20 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `FilterAction` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `GroupAction` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `AddAction` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `${$source>/pressed}` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `PositiveAction` INTO TABLE temp5.
    
    CLEAR temp6.
    INSERT `NegativeAction` INTO TABLE temp6.
    
    CLEAR temp7.
    INSERT `ForwardAction` INTO TABLE temp7.
    
    CLEAR temp8.
    INSERT `FlagAction` INTO TABLE temp8.
    
    CLEAR temp9.
    INSERT `FavoriteAction` INTO TABLE temp9.
    
    CLEAR temp10.
    INSERT `SendEmailAction` INTO TABLE temp10.
    
    CLEAR temp11.
    INSERT `SendMessageAction` INTO TABLE temp11.
    
    CLEAR temp12.
    INSERT `DiscussInJamAction` INTO TABLE temp12.
    
    CLEAR temp13.
    INSERT `ShareInJamAction` INTO TABLE temp13.
    
    CLEAR temp14.
    INSERT `PrintAction` INTO TABLE temp14.
    
    CLEAR temp15.
    INSERT `semMessagePopover` INTO TABLE temp15.
    INSERT `toggleBy` INTO TABLE temp15.
    INSERT `$event.oSource.sId` INTO TABLE temp15.
    
    CLEAR temp16.
    INSERT `${$parameters>/newPosition}` INTO TABLE temp16.
    
    CLEAR temp17.
    INSERT `$event.oSource.sId` INTO TABLE temp17.
    
    CLEAR temp18.
    INSERT `$event.oSource.sId` INTO TABLE temp18.
    
    CLEAR temp19.
    INSERT `$event.oSource.sId` INTO TABLE temp19.
    
    CLEAR temp20.
    INSERT `$event.oSource.sId` INTO TABLE temp20.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`         v = `100%`
        )->a( n = `xmlns:core`     v = `sap.ui.core`
        )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
        )->a( n = `xmlns`          v = `sap.m`
        )->a( n = `xmlns:semantic` v = `sap.m.semantic`
        )->a( n = `xmlns:z2ui5`    v = `z2ui5.cc`
        )->a( n = `displayBlock`   v = `true`

        )->ele( `SplitContainer`
            )->ele( `masterPages`
                )->ele( n = `MasterPage` ns = `semantic`
                    )->a( n = `title` v = `Master Page Title`

                    )->ele( n = `landmarkInfo` ns = `semantic`
                        )->tag( `PageAccessibleLandmarkInfo`
                            )->a( n = `rootLabel`   v = `Root label`
                            )->a( n = `headerLabel` v = `Header label`
                            )->a( n = `footerLabel` v = `Footer label`

                    )->end(
                    )->ele( n = `sort` ns = `semantic`
                        )->ele( n = `SortSelect` ns = `semantic`
                            )->a( n = `change`      v = client->_event( `SELECT_CHANGE` )
                            )->a( n = `selectedKey` v = client->_bind( sort_key )
                            )->a( n = `items` v = |\{ path: '{ client->_bind( val = t_filters path = abap_true ) }', sorter: \{ path: 'Name' \} \}|

                            )->tag( n = `Item` ns = `core`
                                )->a( n = `key`  v = `{TYPE}`
                                )->a( n = `text` v = `{TYPE}`

                        )->end(
                    )->end(
                    )->ele( n = `filter` ns = `semantic`
                        )->tag( n = `FilterAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp1 )

                    )->end(
                    )->ele( n = `group` ns = `semantic`
                        )->tag( n = `GroupAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp2 )

                    )->end(
                    )->ele( n = `addAction` ns = `semantic`
                        )->tag( n = `AddAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp3 )

                    )->end(
                    )->ele( n = `multiSelectAction` ns = `semantic`
                        )->tag( n = `MultiSelectAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val   = `MULTI`
                                                                  t_arg = temp4 )

                    )->end(
                )->end(
            )->end(
            )->ele( `detailPages`
                )->ele( n = `DetailPage` ns = `semantic`
                    )->a( n = `title` v = `Detail Page Title`

                    )->ele( n = `positiveAction` ns = `semantic`
                        )->tag( n = `PositiveAction` ns = `semantic`
                            )->a( n = `text`  v = `Positive`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp5 )

                    )->end(
                    )->ele( n = `negativeAction` ns = `semantic`
                        )->tag( n = `NegativeAction` ns = `semantic`
                            )->a( n = `text`  v = `Negative`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp6 )

                    )->end(
                    )->ele( n = `forwardAction` ns = `semantic`
                        )->tag( n = `ForwardAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp7 )

                    )->end(
                    )->ele( n = `flagAction` ns = `semantic`
                        )->tag( n = `FlagAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp8 )

                    )->end(
                    )->ele( n = `favoriteAction` ns = `semantic`
                        )->tag( n = `FavoriteAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp9 )

                    )->end(
                    )->ele( n = `sendEmailAction` ns = `semantic`
                        )->tag( n = `SendEmailAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp10 )

                    )->end(
                    )->ele( n = `sendMessageAction` ns = `semantic`
                        )->tag( n = `SendMessageAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp11 )

                    )->end(
                    )->ele( n = `discussInJamAction` ns = `semantic`
                        )->tag( n = `DiscussInJamAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp12 )

                    )->end(
                    )->ele( n = `shareInJamAction` ns = `semantic`
                        )->tag( n = `ShareInJamAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp13 )

                    )->end(
                    )->ele( n = `printAction` ns = `semantic`
                        )->tag( n = `PrintAction` ns = `semantic`
                            )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp14 )

                    )->end(
                    )->ele( n = `messagesIndicator` ns = `semantic`
                        )->ele( n = `MessagesIndicator` ns = `semantic`
                            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                            t_arg = temp15 )

                            " the original's controller-built MessagePopover over the
                            " message model, declared as a dependent of its anchor
                            )->ele( n = `dependents` ns = `semantic`
                                )->ele( `MessagePopover`
                                    )->a( n = `id`    v = `semMessagePopover`
                                    )->a( n = `items` v = `{message>/}`

                                    )->tag( `MessageItem`
                                        )->a( n = `description` v = `{message>description}`
                                        )->a( n = `type`        v = `{message>type}`
                                        )->a( n = `title`       v = `{message>message}`

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                    )->ele( n = `pagingAction` ns = `semantic`
                        )->tag( `PagingButton`
                            )->a( n = `count`          v = `5`
                            )->a( n = `positionChange` v = client->_event( val = `POSITION` t_arg = temp16 )

                    )->end(
                    )->ele( n = `customFooterContent` ns = `semantic`
                        )->tag( `OverflowToolbarButton`
                            )->a( n = `icon`  v = `sap-icon://settings`
                            )->a( n = `text`  v = `Settings`
                            )->a( n = `press` v = client->_event( val = `PRESS` t_arg = temp17 )
                        )->tag( `OverflowToolbarButton`
                            )->a( n = `icon`  v = `sap-icon://video`
                            )->a( n = `text`  v = `Video`
                            )->a( n = `press` v = client->_event( val = `PRESS` t_arg = temp18 )

                    )->end(
                    )->ele( n = `content` ns = `semantic`
                        " added container (declared): the z2ui5.cc.MessageManager bridge
                        " reproducing onInit's MessageManager.addMessages seed
                        )->tag( n = `MessageManager` ns = `z2ui5`
                            )->a( n = `items` v = client->_bind( t_messages )

                    )->end(
                    )->ele( n = `customShareMenuContent` ns = `semantic`
                        )->tag( `Button`
                            )->a( n = `text`  v = `CustomShareBtn1`
                            )->a( n = `icon`  v = `sap-icon://color-fill`
                            )->a( n = `press` v = client->_event( val = `PRESS` t_arg = temp19 )
                        )->tag( `Button`
                            )->a( n = `text`  v = `CustomShareBtn2`
                            )->a( n = `icon`  v = `sap-icon://crop`
                            )->a( n = `press` v = client->_event( val = `PRESS` t_arg = temp20 ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE abap_bool.
        DATA lv_pressed LIKE temp3.
        DATA temp4 TYPE string.

    CASE client->get_event( ).

      WHEN `SEM`.
        client->message_toast_display( |Pressed: { client->get_event_arg( ) }| ).

      WHEN `SELECT_CHANGE`.
        client->message_toast_display( |Selected: { sort_key }| ).

      WHEN `MULTI`.
        " onMultiSelectPress: getPressed() ? 'MultiSelect Pressed' : 'MultiSelect Unpressed'
        
        temp3 = client->get_event_arg( ).
        
        lv_pressed = temp3.
        
        IF lv_pressed = abap_true.
          temp4 = `MultiSelect Pressed`.
        ELSE.
          temp4 = `MultiSelect Unpressed`.
        ENDIF.
        client->message_toast_display( temp4 ).

      WHEN `POSITION`.
        client->message_toast_display( |Positioned changed to { client->get_event_arg( ) }| ).

      WHEN `PRESS`.
        client->message_toast_display( |Pressed custom button { client->get_event_arg( ) }| ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    DATA temp5 LIKE t_filters.
    DATA temp6 LIKE LINE OF temp5.
    DATA temp7 LIKE t_messages.
    DATA temp8 LIKE LINE OF temp7.
    CLEAR temp5.
    
    temp6-type = `Category`.
    INSERT temp6 INTO TABLE temp5.
    temp6-type = `SupplierName`.
    INSERT temp6 INTO TABLE temp5.
    t_filters = temp5.

    " onInit: MessageManager.addMessages(new Message({ message: 'Something wrong
    " happened', type: Error })) - reconciled by the z2ui5.cc.MessageManager
    
    CLEAR temp7.
    
    temp8-message = `Something wrong happened`.
    temp8-type = `Error`.
    INSERT temp8 INTO TABLE temp7.
    t_messages = temp7.

  ENDMETHOD.

ENDCLASS.
