" @keywords semanticpage semantic sap.m.semantic actions messagepopover messageitem button overflowtoolbarbutton
" @summary Semantic Page Full Screen
CLASS z2ui5_cl_smpc_app_105 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES: BEGIN OF ty_s_message,
             message     TYPE string,
             description TYPE string,
             type        TYPE string,
           END OF ty_s_message.
    DATA t_messages TYPE STANDARD TABLE OF ty_s_message WITH DEFAULT KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_105 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `AddAction` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `EditAction` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `DeleteAction` INTO TABLE temp3.
    
    CLEAR temp4.
    INSERT `FlagAction` INTO TABLE temp4.
    
    CLEAR temp5.
    INSERT `FavoriteAction` INTO TABLE temp5.
    
    CLEAR temp6.
    INSERT `SendEmailAction` INTO TABLE temp6.
    
    CLEAR temp7.
    INSERT `SendMessageAction` INTO TABLE temp7.
    
    CLEAR temp8.
    INSERT `DiscussInJamAction` INTO TABLE temp8.
    
    CLEAR temp9.
    INSERT `ShareInJamAction` INTO TABLE temp9.
    
    CLEAR temp10.
    INSERT `PrintAction` INTO TABLE temp10.
    
    CLEAR temp11.
    INSERT `semMessagePopover` INTO TABLE temp11.
    INSERT `toggleBy` INTO TABLE temp11.
    INSERT `$event.oSource.sId` INTO TABLE temp11.
    
    CLEAR temp12.
    INSERT `$event.oSource.sId` INTO TABLE temp12.
    
    CLEAR temp13.
    INSERT `$event.oSource.sId` INTO TABLE temp13.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`         v = `100%`
        )->a( n = `xmlns:core`     v = `sap.ui.core`
        )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
        )->a( n = `xmlns`          v = `sap.m`
        )->a( n = `xmlns:semantic` v = `sap.m.semantic`
        )->a( n = `xmlns:z2ui5`    v = `z2ui5.cc`
        )->a( n = `xmlns:ui`       v = `sap.ca.ui`
        )->a( n = `displayBlock`   v = `true`

        )->ele( n = `FullscreenPage` ns = `semantic`
            )->a( n = `title`          v = `FullScreen Page Title`
            )->a( n = `showNavButton`  v = `true`
            )->a( n = `navButtonPress` v = client->_event( `NAV` )

            )->ele( n = `addAction` ns = `semantic`
                )->tag( n = `AddAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp1 )

            )->end(
            )->ele( n = `editAction` ns = `semantic`
                )->tag( n = `EditAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp2 )

            )->end(
            )->ele( n = `deleteAction` ns = `semantic`
                )->tag( n = `DeleteAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp3 )

            )->end(
            )->ele( n = `flagAction` ns = `semantic`
                )->tag( n = `FlagAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp4 )

            )->end(
            )->ele( n = `favoriteAction` ns = `semantic`
                )->tag( n = `FavoriteAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp5 )

            )->end(
            )->ele( n = `sendEmailAction` ns = `semantic`
                )->tag( n = `SendEmailAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp6 )

            )->end(
            )->ele( n = `sendMessageAction` ns = `semantic`
                )->tag( n = `SendMessageAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp7 )

            )->end(
            )->ele( n = `discussInJamAction` ns = `semantic`
                )->tag( n = `DiscussInJamAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp8 )

            )->end(
            )->ele( n = `shareInJamAction` ns = `semantic`
                )->tag( n = `ShareInJamAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp9 )

            )->end(
            )->ele( n = `printAction` ns = `semantic`
                )->tag( n = `PrintAction` ns = `semantic`
                    )->a( n = `press` v = client->_event( val = `SEM` t_arg = temp10 )

            )->end(
            )->ele( n = `messagesIndicator` ns = `semantic`
                )->ele( n = `MessagesIndicator` ns = `semantic`
                    )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                    t_arg = temp11 )

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
            )->ele( n = `content` ns = `semantic`
                " added container (declared): the z2ui5.cc.MessageManager bridge
                " reproducing onInit's MessageManager.addMessages seed
                )->tag( n = `MessageManager` ns = `z2ui5`
                    )->a( n = `items` v = client->_bind( t_messages )

            )->end(
            )->ele( n = `customFooterContent` ns = `semantic`
                )->tag( `Button`
                    )->a( n = `text`  v = `CustomFooterBtn`
                    )->a( n = `press` v = client->_event( val = `PRESS` t_arg = temp12 )
                )->tag( `OverflowToolbarButton`
                    )->a( n = `icon`  v = `sap-icon://settings`
                    )->a( n = `text`  v = `Settings`
                    )->a( n = `press` v = client->_event( val = `PRESS` t_arg = temp13 ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SEM`.
        client->message_toast_display( |Pressed: { client->get_event_arg( ) }| ).

      WHEN `NAV`.
        client->message_toast_display( `Pressed navigation button` ).

      WHEN `PRESS`.
        client->message_toast_display( |Pressed custom button { client->get_event_arg( ) }| ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    " onInit: MessageManager.addMessages( new Message( { message: 'Something
    " wrong happened', type: Error } ) ) - reconciled by the
    " z2ui5.cc.MessageManager bridge control in the view
    DATA temp3 LIKE t_messages.
    DATA temp4 LIKE LINE OF temp3.
    CLEAR temp3.
    
    temp4-message = `Something wrong happened`.
    temp4-type = `Error`.
    INSERT temp4 INTO TABLE temp3.
    t_messages = temp3.

  ENDMETHOD.

ENDCLASS.
