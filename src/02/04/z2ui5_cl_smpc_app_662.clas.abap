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
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
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
    TYPES ty_t_person TYPE STANDARD TABLE OF ty_s_person WITH EMPTY KEY.

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
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

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
                                                       s_ctrl = VALUE #( check_queue_last = abap_true check_no_busy = abap_true ) )

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
                                                                  t_arg = VALUE #( ( `${$parameters>/overflowButtonPressed}` )
                                                                                   ( `${$parameters>/avatarsDisplayed}` )
                                                                                   ( `${$parameters>/eventSource}.getId()` )
                                                                                   ( `${$parameters>/overflowButtonPressed} ? '' : ${$parameters>/eventSource}.getBindingContext().getPath().split('/').pop()` ) ) )
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

    CASE client->get_event( ).

      WHEN `SLIDER_MOVED`.
        " onSliderMoved: setWidth( value + '%' ) on the VerticalLayout, as a bound width
        vl_width = |{ viewportpercentwidth }%|.

      WHEN `INDIVIDUAL_PRESS`.
        IF client->get_event_arg( ) = abap_true.
          " the overflow button: onGroupPress for the avatars that did not fit
          group_popover_display( anchor    = client->get_event_arg( 3 )
                                 displayed = CONV #( client->get_event_arg( 2 ) ) ).
        ELSE.
          DATA(index) = CONV i( client->get_event_arg( 4 ) ).
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
        DATA(idx) = CONV i( client->get_event_arg( ) ) + 1.
        IF idx < 1 OR idx > lines( t_grouped ).
          RETURN.
        ENDIF.
        s_person       = t_grouped[ idx ].
        popover_height = `375px`.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  view  = client->cs_view-popover
                                  t_arg = VALUE #( ( `navCon` ) ( `to` ) ( `detail` ) ) ).

      WHEN `NAV_BACK`.
        popover_height = group_height.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  view  = client->cs_view-popover
                                  t_arg = VALUE #( ( `navCon` ) ( `back` ) ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD individual_popover_display.

    DATA(popover) = z2ui5_cl_ui5_view_builder=>factory( ).

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
    t_grouped = VALUE #( ).
    DATA(index) = displayed.
    WHILE index < lines( t_content ).
      INSERT person_of( index ) INTO TABLE t_grouped.
      index = index + 1.
    ENDWHILE.

    popovertitle = |Team Members ({ totalcount - displayed })|.

    " every cell is 68px high, plus 40px header and 8px top margin
    DATA(count) = lines( t_grouped ).
    group_height   = |{ ( count DIV 2 + count MOD 2 ) * 68 + 48 }px|.
    popover_height = group_height.

    DATA(popover) = z2ui5_cl_ui5_view_builder=>factory( ).

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
    result = CORRESPONDING #( t_content[ idx + 1 ] ).
    result-backgroundcolor = |Accent{ idx MOD 10 + 1 }|.

  ENDMETHOD.


  METHOD model_init.

    viewportpercentwidth = 100.
    vl_width             = `100%`.

    " model/avatargroup.json
    totalcount = 15.
    t_content = VALUE #(
      mobile = `+89181818181`
      phone  = `+2828282828`
      email  = `blabla@blabla`
      ( initials = `JD` name = `John Doe` jobposition = `Marketing Manager` )
      ( initials = `SP` name = `Sarah Parker` jobposition = `Visual Designer` )
      ( initials = `JG` name = `Jason Goldwell` jobposition = `Software Developer` )
      ( name = `Christian Bow` jobposition = `Marketing Manager` )
      ( src = `https://sdk.openui5.org/test-resources/sap/f/images/Woman_avatar_01.png` name = `Jessica Parker` jobposition = `Visual Designer` )
      ( initials = `JB` name = `Jonathan Bale` jobposition = `Software Developer` )
      ( initials = `GS` name = `Gordon Smith` jobposition = `Marketing Manager` )
      ( fallbackicon = `sap-icon://person-placeholder` name = `Simon Jason` jobposition = `Visual Designer` )
      ( initials = `JS` name = `Jason Swan` jobposition = `Software Developer` )
      ( initials = `JC` name = `John Carter` jobposition = `Marketing Manager` )
      ( src = `https://sdk.openui5.org/test-resources/sap/f/images/Woman_avatar_02.png` name = `Whitney Parker` jobposition = `Visual Designer` )
      ( fallbackicon = `sap-icon://person-placeholder` name = `Jason Goldwell` jobposition = `Software Developer` )
      ( initials = `CD` name = `Chris Doe` jobposition = `Marketing Manager` )
      ( initials = `SS` name = `Sarah Smith` jobposition = `Visual Designer` )
      ( initials = `DC` name = `David Copper` jobposition = `Software Developer` ) ).

    " the personData model starts empty; its Avatar.backgroundColor falls back
    " to the control default, which an empty enum string would not
    s_person-backgroundcolor = `Accent6`.

  ENDMETHOD.

ENDCLASS.
