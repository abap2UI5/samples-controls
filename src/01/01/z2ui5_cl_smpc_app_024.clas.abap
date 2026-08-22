" @keywords feedinput feed input sap.m allows user list feedlistitem
" @summary This sample shows you how to build a complete feed user interface by combining a FeedInput with a list of FeedListItems.
CLASS z2ui5_cl_smpc_app_024 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_entry,
        author         TYPE string,
        author_pic_url TYPE string,
        type           TYPE string,
        date           TYPE string,
        text           TYPE string,
      END OF ty_s_entry.
    DATA t_entries TYPE STANDARD TABLE OF ty_s_entry WITH DEFAULT KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_024 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/value}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$source>/sender}` INTO TABLE temp2.
    
    CLEAR temp3.
    INSERT `${$source>/sender}` INTO TABLE temp3.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->tag( `FeedInput`
            )->a( n = `post`  v = client->_event( val   = `POST`
                                                  t_arg = temp1 )
            )->a( n = `icon`  v = `https://sdk.openui5.org/test-resources/sap/m/images/dronning_victoria.jpg`
            )->a( n = `class` v = `sapUiSmallMarginTopBottom`

        )->ele( `List`
            )->a( n = `showSeparators` v = `Inner`
            )->a( n = `items`          v = client->_bind( t_entries )

            )->tag( `FeedListItem`
                )->a( n = `sender`                   v = `{AUTHOR}`
                )->a( n = `icon`                     v = `{AUTHOR_PIC_URL}`
                )->a( n = `senderPress`              v = client->_event( val   = `SENDER_PRESS`
                                                                         t_arg = temp2 )
                )->a( n = `iconPress`                v = client->_event( val   = `ICON_PRESS`
                                                                         t_arg = temp3 )
                )->a( n = `info`                     v = `{TYPE}`
                )->a( n = `timestamp`                v = `{DATE}`
                )->a( n = `text`                     v = `{TEXT}`
                )->a( n = `convertLinksToAnchorTags` v = `All` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string_table.
        DATA month_names LIKE temp3.
        DATA temp5 TYPE i.
        DATA hour LIKE temp5.
        DATA temp6 TYPE string.
        DATA meridiem LIKE temp6.
        DATA temp7 TYPE i.
        DATA temp8 TYPE i.
        DATA date_formatted TYPE string.
        DATA temp10 LIKE LINE OF month_names.
        DATA temp11 LIKE sy-tabix.
        DATA temp9 TYPE z2ui5_cl_smpc_app_024=>ty_s_entry.

    CASE client->get_event( ).

      WHEN `POST`.
        " original: DateFormat.getDateTimeInstance({ style: 'medium' }).format(new Date()) - rebuilt server-side
        
        CLEAR temp3.
        INSERT `Jan` INTO TABLE temp3.
        INSERT `Feb` INTO TABLE temp3.
        INSERT `Mar` INTO TABLE temp3.
        INSERT `Apr` INTO TABLE temp3.
        INSERT `May` INTO TABLE temp3.
        INSERT `Jun` INTO TABLE temp3.
        INSERT `Jul` INTO TABLE temp3.
        INSERT `Aug` INTO TABLE temp3.
        INSERT `Sep` INTO TABLE temp3.
        INSERT `Oct` INTO TABLE temp3.
        INSERT `Nov` INTO TABLE temp3.
        INSERT `Dec` INTO TABLE temp3.
        
        month_names = temp3.
        
        temp5 = sy-uzeit(2).
        
        hour = temp5.
        
        IF hour < 12.
          temp6 = `AM`.
        ELSE.
          temp6 = `PM`.
        ENDIF.
        
        meridiem = temp6.
        
        IF hour MOD 12 = 0.
          temp7 = 12.
        ELSE.
          temp7 = hour MOD 12.
        ENDIF.
        hour = temp7.
        
        temp8 = sy-datum+6(2).
        
        
        
        temp11 = sy-tabix.
        READ TABLE month_names INDEX sy-datum+4(2) INTO temp10.
        sy-tabix = temp11.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        date_formatted = |{ temp10 } { temp8 }, { sy-datum(4) }, { hour }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) } { meridiem }|.
        
        CLEAR temp9.
        temp9-author = `Alexandrina Victoria`.
        temp9-author_pic_url = `http://upload.wikimedia.org/wikipedia/commons/a/aa/Dronning_victoria.jpg`.
        temp9-type = `Reply`.
        temp9-date = date_formatted.
        temp9-text = client->get_event_arg( ).
        INSERT temp9
               INTO t_entries INDEX 1.

      WHEN `SENDER_PRESS`.
        client->message_toast_display( |Clicked on Link: { client->get_event_arg( ) }| ).

      WHEN `ICON_PRESS`.
        client->message_toast_display( |Clicked on Image: { client->get_event_arg( ) }| ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    DATA temp10 LIKE t_entries.
    DATA temp11 LIKE LINE OF temp10.
    CLEAR temp10.
    
    temp11-author = `Alexandrina Victoria`.
    temp11-author_pic_url = `https://sdk.openui5.org/test-resources/sap/m/images/dronning_victoria.jpg`.
    temp11-type = `Request`.
    temp11-date = `March 03 2013`.
    temp11-text = `Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.` &&
`Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. ` &&
`Lorem ipsum dolor sit amet, consetetur sadipscing elitr, seddiamnonumyeirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. ` &&
`Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. ` &&
`Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. ` &&
`Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-author = `George Washington`.
    temp11-author_pic_url = `https://sdk.openui5.org/test-resources/sap/m/images/george_washington.jpg`.
    temp11-type = `Reply`.
    temp11-date = `March 04 2013`.
    temp11-text = `Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore`.
    INSERT temp11 INTO TABLE temp10.
    temp11-author = `Alexandrina Victoria`.
    temp11-author_pic_url = `https://sdk.openui5.org/test-resources/sap/m/images/dronning_victoria.jpg`.
    temp11-type = `Request`.
    temp11-date = `March 05 2013`.
    temp11-text = `Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat`.
    INSERT temp11 INTO TABLE temp10.
    temp11-author = `George Washington`.
    temp11-author_pic_url = `https://sdk.openui5.org/test-resources/sap/m/images/george_washington.jpg`.
    temp11-type = `Rejection`.
    temp11-date = `March 07 2013`.
    temp11-text = `Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.`.
    INSERT temp11 INTO TABLE temp10.
    t_entries = temp10.

  ENDMETHOD.

ENDCLASS.
