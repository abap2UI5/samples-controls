" @keywords avatargroup avatar group sap.f slider verticallayout label avatargroupitem popover card hbox vbox
" @summary This sample demonstrates the different group types and item sizes of the AvatarGroup control.
" @origin sap.f.sample.AvatarGroup - https://sdk.openui5.org/entity/sap.f.AvatarGroup/sample/sap.f.sample.AvatarGroup (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_662 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        initials     TYPE string,
        name         TYPE string,
        jobposition  TYPE string,
        mobile       TYPE string,
        phone        TYPE string,
        email        TYPE string,
        src          TYPE string,
        fallbackicon TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_person,
        src             TYPE string,
        initials        TYPE string,
        fallbackicon    TYPE string,
        backgroundcolor TYPE string,
        name            TYPE string,
        jobposition     TYPE string,
        mobile          TYPE string,
        phone           TYPE string,
        email           TYPE string,
      END OF ty_s_person.
    TYPES ty_t_person TYPE STANDARD TABLE OF ty_s_person WITH DEFAULT KEY.

    DATA viewportpercentwidth TYPE i.
    DATA vl_width             TYPE string.
    DATA t_content            TYPE ty_t_item.
    DATA popovertitle         TYPE string.
    DATA popover_height       TYPE string.
    DATA s_person             TYPE ty_s_person.
    DATA t_grouped            TYPE ty_t_person.

  PROTECTED SECTION.
    DATA client       TYPE REF TO z2ui5_if_client.
    DATA totalcount   TYPE i.
    DATA group_height TYPE string.

    METHODS view_display.
    METHODS on_event.
    METHODS individual_popover_display
      IMPORTING
        anchor TYPE string.
    METHODS group_popover_display
      IMPORTING
        anchor    TYPE string
        displayed TYPE i OPTIONAL.
    METHODS person_of
      IMPORTING
        idx           TYPE i
      RETURNING
        VALUE(result) TYPE ty_s_person.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_662 IMPLEMENTATION.

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
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp2 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    temp1-check_queue_last = abap_true.
    temp1-check_no_busy = abap_true.
    
    CLEAR temp2.
    INSERT `${$parameters>/overflowButtonPressed}` INTO TABLE temp2.
    INSERT `${$parameters>/avatarsDisplayed}` INTO TABLE temp2.
    INSERT `${$parameters>/eventSource}.getId()` INTO TABLE temp2.
    INSERT `${$parameters>/overflowButtonPressed} ? '' : ${$parameters>/eventSource}.getBindingContext().getPath().split('/').pop()` INTO TABLE temp2.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.f`
        )->a( n = `xmlns:m`   v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `height`    v = `100%`

        )->tag( n = `Slider` ns = `m`
            )->a( n = `id`         v = `slider`
            )->a( n = `value`      v = client->_bind( viewportpercentwidth )
            )->a( n = `liveChange` v = client->_event( val    = `SLIDER_MOVED`
                                                       s_ctrl = temp1 )

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `id`    v = `vl1`
            )->a( n = `width` v = client->_bind( vl_width )
            )->a( n = `class` v = `sapUiContentPadding`

            )->tag( n = `Label` ns = `m`
                )->a( n = `text`  v = `AvatarGroup control in Individual mode`
                )->a( n = `class` v = `sapUiSmallMarginBottom sapUiMediumMarginTop`

            )->ele( `AvatarGroup`
                )->a( n = `id`                v = `avatarGroup`
                )->a( n = `groupType`         v = `Individual`
                )->a( n = `avatarDisplaySize` v = `S`
                )->a( n = `press`             v = client->_event( val   = `INDIVIDUAL_PRESS`
                                                                  t_arg = temp2 )
                )->a( n = `items`             v = client->_bind( t_content )

                )->tag( `AvatarGroupItem`
                    )->a( n = `initials`     v = `{INITIALS}`
                    )->a( n = `fallbackIcon` v = `{FALLBACKICON}`
                    )->a( n = `src`          v = `{SRC}`
                    )->a( n = `tooltip`      v = `{NAME}`

            )->end(

            )->tag( n = `Label` ns = `m`
                )->a( n = `text`  v = `AvatarGroup control in Group mode`
                )->a( n = `class` v = `sapUiSmallMarginBottom sapUiMediumMarginTop`

            )->ele( `AvatarGroup`
                )->a( n = `groupType`         v = `Group`
                )->a( n = `tooltip`           v = `Avatar Group`
                )->a( n = `avatarDisplaySize` v = `M`
                )->a( n = `press`             v = client->_event( val = `GROUP_PRESS`
                                                                  arg = `$event.oSource.sId` )
                )->a( n = `items`             v = client->_bind( t_content )

                )->tag( `AvatarGroupItem`
                    )->a( n = `initials`     v = `{INITIALS}`
                    )->a( n = `fallbackIcon` v = `{FALLBACKICON}`
                    )->a( n = `src`          v = `{SRC}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
          DATA temp2 TYPE i.
          DATA temp3 TYPE i.
          DATA index LIKE temp3.
        DATA temp4 TYPE i.
        DATA idx TYPE i.
        FIELD-SYMBOLS <temp5> LIKE LINE OF t_grouped.
        DATA temp6 LIKE sy-tabix.
        DATA temp7 TYPE string_table.
        DATA temp9 TYPE string_table.

    CASE client->get_event( ).

      WHEN `SLIDER_MOVED`.
        " onSliderMoved: setWidth( value + '%' ) on the VerticalLayout, as a bound width
        vl_width = |{ viewportpercentwidth }%|.

      WHEN `INDIVIDUAL_PRESS`.
        IF client->get_event_arg( ) = abap_true.
          " the overflow button: onGroupPress for the avatars that did not fit
          
          temp2 = client->get_event_arg( 2 ).
          group_popover_display( anchor    = client->get_event_arg( 3 )
                                 displayed = temp2 ).
        ELSE.
          
          temp3 = client->get_event_arg( 4 ).
          
          index = temp3.
          IF index < 0 OR index >= lines( t_content ).
            RETURN.
          ENDIF.
          s_person = person_of( index ).
          individual_popover_display( client->get_event_arg( 3 ) ).
        ENDIF.

      WHEN `GROUP_PRESS`.
        group_popover_display( client->get_event_arg( ) ).

      WHEN `AVATAR_PRESS`.
        " onAvatarPress: show the pressed team member's card on the detail page
        
        temp4 = client->get_event_arg( ).
        
        idx = temp4 + 1.
        IF idx < 1 OR idx > lines( t_grouped ).
          RETURN.
        ENDIF.
        
        
        temp6 = sy-tabix.
        READ TABLE t_grouped INDEX idx ASSIGNING <temp5>.
        sy-tabix = temp6.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        s_person       = <temp5>.
        popover_height = `375px`.
        
        CLEAR temp7.
        INSERT `navCon` INTO TABLE temp7.
        INSERT `to` INTO TABLE temp7.
        INSERT `detail` INTO TABLE temp7.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  view  = client->cs_view-popover
                                  t_arg = temp7 ).

      WHEN `NAV_BACK`.
        popover_height = group_height.
        
        CLEAR temp9.
        INSERT `navCon` INTO TABLE temp9.
        INSERT `back` INTO TABLE temp9.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  view  = client->cs_view-popover
                                  t_arg = temp9 ).

    ENDCASE.

  ENDMETHOD.


  METHOD individual_popover_display.

    DATA popover TYPE REF TO z2ui5_cl_ui5_view_builder.
    popover = z2ui5_cl_ui5_view_builder=>factory( ).

    " IndividualPopover.fragment.xml with Card.fragment.xml inlined; openBy( ) adds
    " the sapFAvatarGroupPopover style class, declared on the Popover here
    popover->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:f`    v = `sap.f`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`

        )->ele( `Popover`
            )->a( n = `id`             v = `individualPopover`
            )->a( n = `title`          v = `Business card`
            )->a( n = `titleAlignment` v = `Center`
            )->a( n = `placement`      v = `Bottom`
            )->a( n = `contentWidth`   v = `250px`
            )->a( n = `contentHeight`  v = `332px`
            )->a( n = `class`          v = `sapFAvatarGroupPopover`

            )->ele( n = `Card` ns = `f`
                )->ele( n = `content` ns = `f`
                    )->ele( n = `VerticalLayout` ns = `l`
                        )->a( n = `class` v = `sapUiContentPadding`

                        )->ele( `HBox`
                            )->a( n = `alignItems` v = `Center`

                            )->tag( `Avatar`
                                )->a( n = `src`             v = client->_bind( s_person-src )
                                )->a( n = `initials`        v = client->_bind( s_person-initials )
                                )->a( n = `tooltip`         v = client->_bind( s_person-initials )
                                )->a( n = `fallbackIcon`    v = client->_bind( s_person-fallbackicon )
                                )->a( n = `backgroundColor` v = client->_bind( s_person-backgroundcolor )

                            )->ele( `VBox`
                                )->a( n = `class` v = `sapUiTinyMarginBegin`

                                )->tag( `Title`
                                    )->a( n = `text` v = client->_bind( s_person-name )
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( s_person-jobposition )

                            )->end(
                        )->end(

                        )->tag( `Title`
                            )->a( n = `text` v = `Contact Details`
                        )->tag( `Label`
                            )->a( n = `text` v = `Mobile`
                        )->tag( `Text`
                            )->a( n = `text` v = client->_bind( s_person-mobile )
                        )->tag( `Label`
                            )->a( n = `text` v = `Phone`
                        )->tag( `Text`
                            )->a( n = `text` v = client->_bind( s_person-phone )
                        )->tag( `Label`
                            )->a( n = `text` v = `Email`
                        )->tag( `Text`
                            )->a( n = `text` v = client->_bind( s_person-email ) ).

    client->popover_display( xml = popover->stringify( ) by_id = anchor ).

  ENDMETHOD.


  METHOD group_popover_display.

    " onGroupPress / _getContent: the avatars past the ones displayed (all of
    " them for the Group type), each with the color its AvatarGroupItem got
    DATA temp11 TYPE z2ui5_cl_smpc_app_662=>ty_t_person.
    DATA index LIKE displayed.
    DATA count TYPE i.
    DATA popover TYPE REF TO z2ui5_cl_ui5_view_builder.
    CLEAR temp11.
    t_grouped = temp11.
    
    index = displayed.
    WHILE index < lines( t_content ).
      INSERT person_of( index ) INTO TABLE t_grouped.
      index = index + 1.
    ENDWHILE.

    popovertitle = |Team Members ({ totalcount - displayed })|.

    " every cell is 68px high, plus 40px header and 8px top margin
    
    count = lines( t_grouped ).
    group_height   = |{ ( count DIV 2 + count MOD 2 ) * 68 + 48 }px|.
    popover_height = group_height.

    
    popover = z2ui5_cl_ui5_view_builder=>factory( ).

    " GroupPopover.fragment.xml with Card.fragment.xml inlined on the detail page
    popover->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:f`    v = `sap.f`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`

        )->ele( `Popover`
            )->a( n = `id`            v = `groupPopover`
            )->a( n = `showHeader`    v = `false`
            )->a( n = `contentWidth`  v = `450px`
            )->a( n = `contentHeight` v = client->_bind( popover_height )
            )->a( n = `placement`     v = `Bottom`
            )->a( n = `class`         v = `sapFAvatarGroupPopover`

            )->ele( `NavContainer`
                )->a( n = `id` v = `navCon`

                )->ele( `Page`
                    )->a( n = `id`             v = `main`
                    )->a( n = `titleAlignment` v = `Center`
                    )->a( n = `title`          v = client->_bind( popovertitle )

                    )->ele( n = `VerticalLayout` ns = `l`
                        )->a( n = `class` v = `sapUiTinyMarginTop`
                        )->a( n = `width` v = `100%`

                        )->ele( n = `Grid` ns = `l`
                            )->a( n = `defaultSpan` v = `XL6 L6 M6 S12`
                            )->a( n = `content`     v = client->_bind( t_grouped )

                            )->ele( `HBox`
                                )->a( n = `alignItems` v = `Center`

                                )->ele( `VBox`
                                    )->tag( `Avatar`
                                        )->a( n = `class`           v = `sapUiTinyMarginEnd`
                                        )->a( n = `src`             v = `{SRC}`
                                        )->a( n = `initials`        v = `{INITIALS}`
                                        )->a( n = `tooltip`         v = `{INITIALS}`
                                        )->a( n = `fallbackIcon`    v = client->_bind( s_person-fallbackicon )
                                        )->a( n = `backgroundColor` v = `{BACKGROUNDCOLOR}`
                                        )->a( n = `press`           v = client->_event( val = `AVATAR_PRESS`
                                                                                        arg = `$event.oSource.getBindingContext().getPath().split('/').pop()` )

                                )->end(

                                )->ele( `VBox`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{NAME}`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{JOBPOSITION}`

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                )->end(

                )->ele( `Page`
                    )->a( n = `id`             v = `detail`
                    )->a( n = `showNavButton`  v = `true`
                    )->a( n = `navButtonPress` v = client->_event( `NAV_BACK` )
                    )->a( n = `titleAlignment` v = `Center`
                    )->a( n = `title`          v = client->_bind( popovertitle )

                    )->ele( n = `Card` ns = `f`
                        )->ele( n = `content` ns = `f`
                            )->ele( n = `VerticalLayout` ns = `l`
                                )->a( n = `class` v = `sapUiContentPadding`

                                )->ele( `HBox`
                                    )->a( n = `alignItems` v = `Center`

                                    )->tag( `Avatar`
                                        )->a( n = `src`             v = client->_bind( s_person-src )
                                        )->a( n = `initials`        v = client->_bind( s_person-initials )
                                        )->a( n = `tooltip`         v = client->_bind( s_person-initials )
                                        )->a( n = `fallbackIcon`    v = client->_bind( s_person-fallbackicon )
                                        )->a( n = `backgroundColor` v = client->_bind( s_person-backgroundcolor )

                                    )->ele( `VBox`
                                        )->a( n = `class` v = `sapUiTinyMarginBegin`

                                        )->tag( `Title`
                                            )->a( n = `text` v = client->_bind( s_person-name )
                                        )->tag( `Text`
                                            )->a( n = `text` v = client->_bind( s_person-jobposition )

                                    )->end(
                                )->end(

                                )->tag( `Title`
                                    )->a( n = `text` v = `Contact Details`
                                )->tag( `Label`
                                    )->a( n = `text` v = `Mobile`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( s_person-mobile )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Phone`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( s_person-phone )
                                )->tag( `Label`
                                    )->a( n = `text` v = `Email`
                                )->tag( `Text`
                                    )->a( n = `text` v = client->_bind( s_person-email ) ).

    client->popover_display( xml = popover->stringify( ) by_id = anchor ).

  ENDMETHOD.


  METHOD person_of.

    " _getAvatarModel: the row's data plus the AvatarGroupItem's own color -
    " AvatarGroup.addItem hands out Accent1..Accent10 in item order, round robin
    FIELD-SYMBOLS <temp4> LIKE LINE OF t_content.
    DATA temp5 LIKE sy-tabix.
    temp5 = sy-tabix.
    READ TABLE t_content INDEX idx + 1 ASSIGNING <temp4>.
    sy-tabix = temp5.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    MOVE-CORRESPONDING <temp4> TO result.
    result-backgroundcolor = |Accent{ idx MOD 10 + 1 }|.

  ENDMETHOD.


  METHOD model_init.
    DATA temp12 TYPE z2ui5_cl_smpc_app_662=>ty_t_item.
    DATA temp13 LIKE LINE OF temp12.

    viewportpercentwidth = 100.
    vl_width             = `100%`.

    " model/avatargroup.json
    totalcount = 15.
    
    CLEAR temp12.
    
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `JD`.
    temp13-name = `John Doe`.
    temp13-jobposition = `Marketing Manager`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `SP`.
    temp13-name = `Sarah Parker`.
    temp13-jobposition = `Visual Designer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `JG`.
    temp13-name = `Jason Goldwell`.
    temp13-jobposition = `Software Developer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-name = `Christian Bow`.
    temp13-jobposition = `Marketing Manager`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-src = `https://sdk.openui5.org/test-resources/sap/f/images/Woman_avatar_01.png`.
    temp13-name = `Jessica Parker`.
    temp13-jobposition = `Visual Designer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `JB`.
    temp13-name = `Jonathan Bale`.
    temp13-jobposition = `Software Developer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `GS`.
    temp13-name = `Gordon Smith`.
    temp13-jobposition = `Marketing Manager`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-fallbackicon = `sap-icon://person-placeholder`.
    temp13-name = `Simon Jason`.
    temp13-jobposition = `Visual Designer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `JS`.
    temp13-name = `Jason Swan`.
    temp13-jobposition = `Software Developer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `JC`.
    temp13-name = `John Carter`.
    temp13-jobposition = `Marketing Manager`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-src = `https://sdk.openui5.org/test-resources/sap/f/images/Woman_avatar_02.png`.
    temp13-name = `Whitney Parker`.
    temp13-jobposition = `Visual Designer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-fallbackicon = `sap-icon://person-placeholder`.
    temp13-name = `Jason Goldwell`.
    temp13-jobposition = `Software Developer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `CD`.
    temp13-name = `Chris Doe`.
    temp13-jobposition = `Marketing Manager`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `SS`.
    temp13-name = `Sarah Smith`.
    temp13-jobposition = `Visual Designer`.
    INSERT temp13 INTO TABLE temp12.
    CLEAR temp13.
    temp13-mobile = `+89181818181`.
    temp13-phone = `+2828282828`.
    temp13-email = `blabla@blabla`.
    temp13-initials = `DC`.
    temp13-name = `David Copper`.
    temp13-jobposition = `Software Developer`.
    INSERT temp13 INTO TABLE temp12.
    t_content = temp12.

    " the personData model starts empty; its Avatar.backgroundColor falls back
    " to the control default, which an empty enum string would not
    s_person-backgroundcolor = `Accent6`.

  ENDMETHOD.

ENDCLASS.
