" @keywords team calendar app dynamicpagetitle title verticallayout planningcalendar select item button planningcalendarview planningcalendarrow
" @summary Calendar demo app for team and team members. - the UI5 demo app "Team Calendar", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Team Calendar (sap.m/teamCalendar) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Team Calendar</p>
"!
"! The UI5 demo app Team Calendar, rebuilt as ONE abap2UI5 class: a
"! DynamicPage carrying the team's PlanningCalendar - four people, their
"! appointments and their interval headers - and the SinglePlanningCalendar of
"! one team member, with the calendar legend in a popover and the Select that
"! switches between them.
"!
"! Where it differs from the original, and why:
"!
"!  - the two calendars are two controls in ONE view, shown and hidden by a
"!    bound `visible`, where the original loads a fragment per calendar and
"!    swaps it into a VerticalLayout. That is also why this class has no
"!    startDateChange / viewChange handler: the original needs them to carry
"!    the date and the view across a swap that destroys nothing but re-adds
"!    everything, and here both calendars stay alive and keep their own.
"!  - the fixImagePath formatter moves to the backend: model_init holds the
"!    picture paths as the mock writes them and prefixes them once with the
"!    demo kit's own URL, which is what the original computes at runtime from
"!    sap.ui.require.toUrl( ).
"!  - the utcToLocalDateTime formatter stays on the FRONTEND, and it is the
"!    one formatter that has to: startDate, endDate and the calendar's own
"!    startDate are object-typed properties that demand a real JS Date, which
"!    no wire can carry. abap2UI5 ships exactly that converter as
"!    Formatter.DateCreateObject in its curated module.
"!  - the Select is filled in the view rather than by the controller's
"!    _populateSelect( ), and it carries the person's NAME as its key, because
"!    that is what the rowSelectionChange event hands back about the row that
"!    was clicked.
"!  - the single calendar opens on its DAY view, where the original's
"!    _displayCalendar( ) selects the month the model names. selectedView is an
"!    association: it cannot be bound, has no whitelisted setter, and a
"!    declared id is resolved before the views exist. Same limit as app 549.
"!  - an appointment of the SINGLE calendar shows its info line and its
"!    picture. The original's SinglePlanningCalendar fragment binds `text` and
"!    `icon` there, two paths its model does not have (the rows carry `info`
"!    and `pic`, which its PlanningCalendar fragment binds correctly), so the
"!    demo kit shows neither - the same row data as the team calendar, drawn.
"!  - the i18n bundle becomes literals (the original ships de and en plus two
"!    terminologies; an abap2UI5 app translates with ABAP text elements).
"!
"! Original: src/sap.m/test/sap/m/demokit/teamCalendar in OpenUI5, archived
"! under ui5/demoapps/sap.m/teamCalendar.
"! Demo apps: https://sdk.openui5.org/demoapps
CLASS z2ui5_cl_smpc_demo_003 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_appointment,
        start_at  TYPE string,
        end_at    TYPE string,
        title     TYPE string,
        info      TYPE string,
        pic       TYPE string,
        type      TYPE string,
        tentative TYPE abap_bool,
      END OF ty_s_appointment.
    TYPES:
      BEGIN OF ty_s_header,
        start_at TYPE string,
        end_at   TYPE string,
        title    TYPE string,
        type     TYPE string,
      END OF ty_s_header.
    TYPES:
      BEGIN OF ty_s_person,
        personid       TYPE string,
        name           TYPE string,
        role           TYPE string,
        pic            TYPE string,
        t_appointments TYPE STANDARD TABLE OF ty_s_appointment WITH DEFAULT KEY,
        t_headers      TYPE STANDARD TABLE OF ty_s_header WITH DEFAULT KEY,
      END OF ty_s_person.
    TYPES:
      BEGIN OF ty_s_member,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_member.
    TYPES:
      BEGIN OF ty_s_legend,
        text TYPE string,
        type TYPE string,
      END OF ty_s_legend.

    DATA t_team       TYPE STANDARD TABLE OF ty_s_person WITH DEFAULT KEY.
    DATA t_selected   TYPE STANDARD TABLE OF ty_s_appointment WITH DEFAULT KEY.
    DATA t_members    TYPE STANDARD TABLE OF ty_s_member WITH DEFAULT KEY.
    DATA t_legend     TYPE STANDARD TABLE OF ty_s_legend WITH DEFAULT KEY.
    DATA page_title   TYPE string VALUE `Team Calendar`.
    DATA start_date   TYPE string.
    DATA view_key     TYPE string VALUE `OneMonth`.
    DATA member       TYPE string VALUE `Team`.
    DATA check_team   TYPE abap_bool VALUE abap_true.

  PROTECTED SECTION.
    " what the original's fixImagePath prefixes a relative picture with:
    " sap.ui.require.toUrl( ) resolved against the demo kit's own host
    CONSTANTS c_base TYPE string VALUE `https://sdk.openui5.org/test-resources/sap/m/demokit/teamCalendar/webapp/`.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS legend_display.
    METHODS member_select
      IMPORTING
        name TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_demo_003 IMPLEMENTATION.

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

    " calendar date properties are typed "object" and demand a real JS Date;
    " the model keeps the mock's ISO strings and Formatter.DateCreateObject
    " converts them - the curated module's whole reason to exist.
    " The chain hangs off the factory( ) rather than starting from a
    " standalone one: with the split shape the variable has to hold the
    " mvc:View, or the next statement adds a SECOND ROOT beside it and the
    " document does not parse (view-chain-layout, "the one combination that
    " is broken")
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA pc TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA pc_toolbar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA spc TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA spc_actions TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `xmlns:f`      v = `sap.f`
            )->a( n = `xmlns:l`      v = `sap.ui.layout`
            )->a( n = `xmlns:u`      v = `sap.ui.unified`
            )->a( n = `xmlns:core`   v = `sap.ui.core`
            )->a( n = `height`       v = `100%`
            )->a( n = `core:require` v = `{Formatter: 'z2ui5/model/formatter'}` ).

    
    page = view->ele( n = `DynamicPage` ns = `f`
        )->a( n = `id`                          v = `dynamicPage`
        )->a( n = `class`                       v = `sapUiContentPadding`
        )->a( n = `preserveHeaderStateOnScroll` b = abap_true ).

    page->ele( n = `title` ns = `f`
        )->ele( n = `DynamicPageTitle` ns = `f`

            )->ele( n = `heading` ns = `f`
                )->tag( `Title`
                    )->a( n = `text` v = client->_bind( page_title )

            )->end(
            )->ele( n = `snappedTitleOnMobile` ns = `f`
                )->tag( `Title`
                    )->a( n = `text` v = client->_bind( page_title ) ).

    
    content = page->ele( n = `content` ns = `f`
        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `id`    v = `mainContent`
            )->a( n = `width` v = `100%` ).

    " ------------------------------------------------- the team calendar
    
    pc = content->ele( `VBox`
        )->a( n = `visible` v = client->_bind( check_team )

        )->ele( `PlanningCalendar`
            )->a( n = `id`                        v = `PlanningCalendar`
            )->a( n = `viewKey`                   v = client->_bind( view_key )
            )->a( n = `rows`                      v = client->_bind( t_team )
            )->a( n = `appointmentsVisualization` v = `Filled`
            )->a( n = `showEmptyIntervalHeaders`  b = abap_false
            )->a( n = `showWeekNumbers`           b = abap_true
            )->a( n = `rowSelectionChange`        v = client->_event( val = `ROW_SELECT`
                                                                     arg = `${$parameters>/rows}[0].getTitle()` ) ).

    " the calendar's own startDate is object-typed too
    pc->a( n = `startDate` v = |\{ path: '{ client->_bind_path( start_date ) }', formatter: 'Formatter.DateCreateObject' \}| ).

    
    pc_toolbar = pc->ele( `toolbarContent` ).

    pc_toolbar->tag( `Label`
        )->a( n = `labelFor` v = `PlanningCalendarTeamSelector`
        )->a( n = `text`     v = `Calendar for: `

        )->ele( `Select`
            )->a( n = `id`          v = `PlanningCalendarTeamSelector`
            )->a( n = `selectedKey` v = client->_bind( member )
            )->a( n = `items`       v = client->_bind( t_members )
            )->a( n = `change`      v = client->_event( val = `SELECT_MEMBER`
                                                        arg = `${$parameters>/selectedItem}.getKey()` )

            )->ele( `items`
                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{KEY}`
                    )->a( n = `text` v = `{TEXT}` ).

    pc_toolbar->tag( `Button`
        )->a( n = `id`      v = `PlanningCalendarCreateAppointmentButton`
        )->a( n = `text`    v = `Create`
        )->a( n = `tooltip` v = `Create new appointment`
        )->a( n = `press`   v = client->_event( `CREATE` )
        )->tag( `Button`
            )->a( n = `id`      v = `PlanningCalendarLegendButton`
            )->a( n = `icon`    v = `sap-icon://legend`
            )->a( n = `tooltip` v = `Open Planning Calendar legend`
            " the button's OWN id, not `$event.oSource.sId`: that resolves to
            " the view-PREFIXED `mainView--PlanningCalendarLegendButton`, and
            " popover_display( by_id = ) looks the anchor up inside the view,
            " where the prefixed spelling matches nothing - so the event
            " arrived, the handler ran, and no popover ever appeared
            )->a( n = `press`   v = client->_event( val = `LEGEND` arg = `PlanningCalendarLegendButton` ) ).

    pc->ele( `views`
        )->ele( `PlanningCalendarView`
            )->a( n = `key`               v = `Day`
            )->a( n = `intervalType`      v = `Hour`
            )->a( n = `description`       v = `Day`
            )->a( n = `intervalsS`        v = `3`
            )->a( n = `intervalsM`        v = `6`
            )->a( n = `intervalsL`        v = `12`
            )->a( n = `showSubIntervals`  b = abap_true

        )->end(
        )->ele( `PlanningCalendarView`
            )->a( n = `key`               v = `Week`
            )->a( n = `intervalType`      v = `Week`
            )->a( n = `description`       v = `Week`
            )->a( n = `intervalsS`        v = `1`
            )->a( n = `intervalsM`        v = `2`
            )->a( n = `intervalsL`        v = `7`
            )->a( n = `showSubIntervals`  b = abap_true

        )->end(
        )->ele( `PlanningCalendarView`
            )->a( n = `key`          v = `OneMonth`
            " the enum KEY, which is what the original writes and what an XML
            " view needs: DataType.createEnumType's parseValue( ) maps the key
            " to the value ("One Month") and only then validates. The pinned
            " linter (0.6.1) lists the VALUES as allowed, so it reads the
            " correct spelling as wrong - and would have accepted "One Month",
            " which parses to undefined and leaves the property at its default.
            " Fixed upstream in abap2UI5/linter#104; this line comes out
            " with the pin bump, together with the other two waivers the same
            " pin costs (STATUS.md carries all three)
            " abap2ui5lint-disable-next-line invalid-property-value
            )->a( n = `intervalType` v = `OneMonth`
            )->a( n = `description`  v = `Month` ).

    pc->ele( `rows`
        )->ele( `PlanningCalendarRow`
            )->a( n = `icon`            v = `{PIC}`
            )->a( n = `title`           v = `{NAME}`
            )->a( n = `text`            v = `{ROLE}`
            )->a( n = `appointments`    v = `{path: 'T_APPOINTMENTS', templateShareable: true}`
            )->a( n = `intervalHeaders` v = `{path: 'T_HEADERS', templateShareable: true}`

            )->ele( `appointments`
                )->tag( n = `CalendarAppointment` ns = `u`
                    )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
                    )->a( n = `endDate`   v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }`
                    )->a( n = `icon`      v = `{PIC}`
                    )->a( n = `title`     v = `{TITLE}`
                    )->a( n = `text`      v = `{INFO}`
                    )->a( n = `type`      v = `{TYPE}`
                    )->a( n = `tentative` v = `{TENTATIVE}`

            )->end(
            )->ele( `intervalHeaders`
                )->tag( n = `CalendarAppointment` ns = `u`
                    )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
                    )->a( n = `endDate`   v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }`
                    )->a( n = `title`     v = `{TITLE}`
                    )->a( n = `type`      v = `{TYPE}` ).

    " ------------------------------------ the calendar of one team member
    
    spc = content->ele( `VBox`
        )->a( n = `visible` v = |\{= !${ client->_bind( check_team ) } \}|

        )->ele( `SinglePlanningCalendar`
            )->a( n = `id`           v = `SinglePlanningCalendar`
            " the month view the original selects from its controller cannot be
            " preselected here: selectedView is an ASSOCIATION, which neither
            " binds nor has a whitelisted setter (app 549 carries the same
            " sentence), and setting the id declaratively logs "There is no such
            " view" - UI5 resolves it while the views aggregation is still empty.
            " So this calendar opens on the first view of its list, the Day view
            )->a( n = `startDate`    v = |\{ path: '{ client->_bind_path( start_date ) }', formatter: 'Formatter.DateCreateObject' \}|
            )->a( n = `appointments` v = client->_bind( t_selected ) ).

    
    spc_actions = spc->ele( `actions` ).

    spc_actions->tag( `Label`
        )->a( n = `labelFor` v = `SinglePlanningCalendarTeamSelector`
        )->a( n = `text`     v = `Calendar for: `

        )->ele( `Select`
            )->a( n = `id`          v = `SinglePlanningCalendarTeamSelector`
            )->a( n = `selectedKey` v = client->_bind( member )
            )->a( n = `items`       v = client->_bind( t_members )
            )->a( n = `change`      v = client->_event( val = `SELECT_MEMBER`
                                                        arg = `${$parameters>/selectedItem}.getKey()` )

            )->ele( `items`
                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `{KEY}`
                    )->a( n = `text` v = `{TEXT}` ).

    spc_actions->tag( `Button`
        )->a( n = `id`      v = `SinglePlanningCalendarCreateAppointmentButton`
        )->a( n = `text`    v = `Create`
        )->a( n = `tooltip` v = `Create new appointment`
        )->a( n = `press`   v = client->_event( `CREATE` )
        )->tag( `Button`
            )->a( n = `id`      v = `SinglePlanningCalendarLegendButton`
            )->a( n = `icon`    v = `sap-icon://legend`
            )->a( n = `tooltip` v = `Open Single Planning Calendar legend`
            " the button's own id - see the team calendar's legend button
            )->a( n = `press`   v = client->_event( val = `LEGEND` arg = `SinglePlanningCalendarLegendButton` ) ).

    spc->ele( `views`
        )->tag( `SinglePlanningCalendarDayView`
            )->a( n = `key`   v = `Day`
            )->a( n = `title` v = `Day`
        )->tag( `SinglePlanningCalendarWeekView`
            )->a( n = `key`   v = `Week`
            )->a( n = `title` v = `Week`
        )->tag( `SinglePlanningCalendarMonthView`
            )->a( n = `key`   v = `OneMonth`
            )->a( n = `title` v = `Month` ).

    spc->ele( `appointments`
        )->tag( n = `CalendarAppointment` ns = `u`
            )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
            )->a( n = `endDate`   v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }`
            )->a( n = `icon`      v = `{PIC}`
            )->a( n = `title`     v = `{TITLE}`
            )->a( n = `text`      v = `{INFO}`
            )->a( n = `type`      v = `{TYPE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SELECT_MEMBER`.
        member_select( client->get_event_arg( ) ).

      WHEN `ROW_SELECT`.
        " the original reads the clicked row's id and cuts the person out of
        " it; the row's title IS the person, so the wire carries that
        member_select( client->get_event_arg( ) ).

      WHEN `CREATE`.
        client->message_toast_display( `Creating new appointment...` ).

      WHEN `LEGEND`.
        legend_display( ).

    ENDCASE.

  ENDMETHOD.


  METHOD legend_display.

    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:u`    v = `sap.ui.unified`

        )->ele( `ResponsivePopover`
            )->a( n = `title`      v = `Calendar Legend`
            )->a( n = `placement`  v = `Bottom`
            )->a( n = `showHeader` b = abap_false

            )->ele( `PlanningCalendarLegend`
                )->a( n = `appointmentItems` v = client->_bind( t_legend )

                )->ele( `appointmentItems`
                    )->tag( n = `CalendarLegendItem` ns = `u`
                        )->a( n = `text`    v = `{TEXT}`
                        )->a( n = `type`    v = `{TYPE}`
                        )->a( n = `tooltip` v = `{TEXT}` ).

    client->popover_display( xml = popup->stringify( ) by_id = client->get_event_arg( ) ).

  ENDMETHOD.


  METHOD member_select.
    DATA temp3 TYPE xsdboolean.
      DATA temp1 LIKE t_selected.
    DATA temp2 LIKE t_selected.
    FIELD-SYMBOLS <member> TYPE z2ui5_cl_smpc_demo_003=>ty_s_person.

    member = name.
    
    temp3 = boolc( name = `Team` ).
    check_team = temp3.
    IF check_team = abap_true.
      
      CLEAR temp1.
      t_selected = temp1.
      RETURN.
    ENDIF.

    " the SinglePlanningCalendar shows one person, so the appointments of the
    " selected row become the bound table.
    "
    " Written as a READ rather than as the one-liner it was - a nested
    " `VALUE #( ( LINES OF VALUE #( t[ key ]-inner OPTIONAL ) ) )` is what the
    " 702 downport cannot resolve: it emitted `READ TABLE ... WITH KEY
    " undefined` and the transpiled backend refused the class outright
    " (check_syntax, "undefined" not found). A row this port cannot run on a
    " 702 system is a port that does not keep this package's promise.
    
    CLEAR temp2.
    t_selected = temp2.
    
    READ TABLE t_team WITH KEY name = name ASSIGNING <member>.
    IF <member> IS ASSIGNED.
      t_selected = <member>-t_appointments.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.
    DATA temp3 LIKE t_team.
    DATA temp4 LIKE LINE OF temp3.
    DATA temp1 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_appointments.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp12 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_headers.
    DATA temp13 LIKE LINE OF temp12.
    DATA temp14 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_appointments.
    DATA temp15 LIKE LINE OF temp14.
    DATA temp16 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_headers.
    DATA temp17 LIKE LINE OF temp16.
    DATA temp18 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_appointments.
    DATA temp19 LIKE LINE OF temp18.
    DATA temp20 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_headers.
    DATA temp21 LIKE LINE OF temp20.
    DATA temp22 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_appointments.
    DATA temp23 LIKE LINE OF temp22.
    DATA temp24 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_headers.
    DATA temp25 LIKE LINE OF temp24.
    DATA temp5 LIKE t_legend.
    DATA temp6 LIKE LINE OF temp5.
    DATA temp7 LIKE t_members.
    DATA temp8 LIKE LINE OF temp7.
    DATA member_row LIKE LINE OF t_team.
      DATA temp9 TYPE z2ui5_cl_smpc_demo_003=>ty_s_member.
    DATA temp10 LIKE LINE OF t_team.
    DATA person LIKE REF TO temp10.
      DATA temp11 LIKE LINE OF person->t_appointments.
      DATA appointment LIKE REF TO temp11.

    " model/Calendar.json's own start date
    start_date = `2019-10-01T08:00:00`.

    " model/Calendar.json - the team, their appointments and the interval
    " headers, verbatim
    
    CLEAR temp3.
    
    temp4-personid = `PersonID_1`.
    temp4-name = `John Miller`.
    temp4-role = `Scrum master`.
    temp4-pic = `images/John_Miller.png`.
    
    CLEAR temp1.
    
    temp2-start_at = `2019-10-01T09:00`.
    temp2-end_at = `2019-10-01T11:30`.
    temp2-title = `Team meeting`.
    temp2-info = `Conf. room 1`.
    temp2-pic = ``.
    temp2-type = `Type01`.
    temp2-tentative = abap_true.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-04T09:00`.
    temp2-end_at = `2019-10-04T17:30`.
    temp2-title = `Face to face`.
    temp2-info = `Room 13`.
    temp2-pic = `images/Donna_Moore.jpg`.
    temp2-type = `Type05`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-07T09:00`.
    temp2-end_at = `2019-10-07T11:30`.
    temp2-title = `Team meeting`.
    temp2-info = `Conf. room 1`.
    temp2-pic = ``.
    temp2-type = `Type01`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-11T09:00`.
    temp2-end_at = `2019-10-11T17:30`.
    temp2-title = `Face to face`.
    temp2-info = `Room 13`.
    temp2-pic = `images/Donna_Moore.jpg`.
    temp2-type = `Type05`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-10T09:00`.
    temp2-end_at = `2019-10-10T17:00`.
    temp2-title = `Show and tell`.
    temp2-info = ``.
    temp2-pic = ``.
    temp2-type = `Type08`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-16T09:00`.
    temp2-end_at = `2019-10-16T11:30`.
    temp2-title = `Team meeting`.
    temp2-info = `Conf. room 1`.
    temp2-pic = ``.
    temp2-type = `Type01`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-17T14:00`.
    temp2-end_at = `2019-10-17T16:00`.
    temp2-title = `Release plan presentation`.
    temp2-info = `Conf. room 1`.
    temp2-pic = `sap-icon://legend`.
    temp2-type = `Type08`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-18T09:30`.
    temp2-end_at = `2019-10-18T12:00`.
    temp2-title = `Training`.
    temp2-info = `Training hall`.
    temp2-pic = `sap-icon://education`.
    temp2-type = `Type05`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-21T09:00`.
    temp2-end_at = `2019-10-21T11:30`.
    temp2-title = `Team meeting`.
    temp2-info = `Conf. room 1`.
    temp2-pic = ``.
    temp2-type = `Type01`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-23T10:00`.
    temp2-end_at = `2019-10-23T13:00`.
    temp2-title = `Company security`.
    temp2-info = `Conf. room 3`.
    temp2-pic = `sap-icon://legend`.
    temp2-type = `Type08`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-24T09:30`.
    temp2-end_at = `2019-10-24T13:00`.
    temp2-title = `Dentist`.
    temp2-info = ``.
    temp2-pic = `sap-icon://offsite-work`.
    temp2-type = `Type09`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp2-start_at = `2019-10-29T14:00`.
    temp2-end_at = `2019-10-29T15:00`.
    temp2-title = `Face to face`.
    temp2-info = `Room 13`.
    temp2-pic = `images/Donna_Moore.jpg`.
    temp2-type = `Type05`.
    temp2-tentative = abap_false.
    INSERT temp2 INTO TABLE temp1.
    temp4-t_appointments = temp1.
    
    CLEAR temp12.
    
    temp13-start_at = `2019-10-08T00:00:00`.
    temp13-end_at = `2019-10-10T00:00:00`.
    temp13-title = `Team building`.
    temp13-type = `Type09`.
    INSERT temp13 INTO TABLE temp12.
    temp13-start_at = `2019-10-24T00:00:00`.
    temp13-end_at = `2019-10-26T00:00:00`.
    temp13-title = `Business trip`.
    temp13-type = `Type05`.
    INSERT temp13 INTO TABLE temp12.
    temp4-t_headers = temp12.
    INSERT temp4 INTO TABLE temp3.
    temp4-personid = `PersonID_2`.
    temp4-name = `Donna Moore`.
    temp4-role = `Team manager`.
    temp4-pic = `images/Donna_Moore.jpg`.
    
    CLEAR temp14.
    
    temp15-start_at = `2019-10-01T09:00`.
    temp15-end_at = `2019-10-01T11:30`.
    temp15-title = `Team meeting`.
    temp15-info = `Conf. room 1`.
    temp15-pic = ``.
    temp15-type = `Type01`.
    temp15-tentative = abap_true.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-04T09:00`.
    temp15-end_at = `2019-10-04T17:30`.
    temp15-title = `Face to face`.
    temp15-info = `Room 13`.
    temp15-pic = `images/John_Miller.png`.
    temp15-type = `Type05`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-07T09:00`.
    temp15-end_at = `2019-10-07T11:30`.
    temp15-title = `Team meeting`.
    temp15-info = `Conf. room 1`.
    temp15-pic = ``.
    temp15-type = `Type01`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-11T09:00`.
    temp15-end_at = `2019-10-11T17:30`.
    temp15-title = `Face to face`.
    temp15-info = `Room 13`.
    temp15-pic = `images/John_Miller.png`.
    temp15-type = `Type05`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-14T09:00`.
    temp15-end_at = `2019-10-14T17:00`.
    temp15-title = `Conference in Berlin`.
    temp15-info = ``.
    temp15-pic = ``.
    temp15-type = `Type08`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-16T09:00`.
    temp15-end_at = `2019-10-16T11:30`.
    temp15-title = `Team meeting`.
    temp15-info = `Conf. room 1`.
    temp15-pic = ``.
    temp15-type = `Type01`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-17T14:00`.
    temp15-end_at = `2019-10-17T16:00`.
    temp15-title = `Release plan presentation`.
    temp15-info = `Conf. room 1`.
    temp15-pic = `sap-icon://legend`.
    temp15-type = `Type08`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-21T09:30`.
    temp15-end_at = `2019-10-21T12:00`.
    temp15-title = `Doctor`.
    temp15-info = `City clinic`.
    temp15-pic = `sap-icon://offsite-work`.
    temp15-type = `Type09`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-21T14:00`.
    temp15-end_at = `2019-10-21T17:00`.
    temp15-title = `Company results`.
    temp15-info = `Conf. room 2`.
    temp15-pic = ``.
    temp15-type = `Type08`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-23T10:00`.
    temp15-end_at = `2019-10-23T13:00`.
    temp15-title = `Company security`.
    temp15-info = `Conf. room 3`.
    temp15-pic = `sap-icon://legend`.
    temp15-type = `Type08`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp15-start_at = `2019-10-29T14:00`.
    temp15-end_at = `2019-10-29T15:00`.
    temp15-title = `Face to face`.
    temp15-info = `Room 13`.
    temp15-pic = `images/John_Miller.png`.
    temp15-type = `Type05`.
    temp15-tentative = abap_false.
    INSERT temp15 INTO TABLE temp14.
    temp4-t_appointments = temp14.
    
    CLEAR temp16.
    
    temp17-start_at = `2019-10-08T00:00:00`.
    temp17-end_at = `2019-10-10T00:00:00`.
    temp17-title = `Team building`.
    temp17-type = `Type09`.
    INSERT temp17 INTO TABLE temp16.
    temp17-start_at = `2019-10-14T00:00:00`.
    temp17-end_at = `2019-10-16T00:00:00`.
    temp17-title = `Business trip`.
    temp17-type = `Type05`.
    INSERT temp17 INTO TABLE temp16.
    temp4-t_headers = temp16.
    INSERT temp4 INTO TABLE temp3.
    temp4-personid = `PersonID_3`.
    temp4-name = `Elena Petrova`.
    temp4-role = `Designer`.
    temp4-pic = `images/Elena_Petrova.jpg`.
    
    CLEAR temp18.
    
    temp19-start_at = `2019-10-03T09:00`.
    temp19-end_at = `2019-10-03T17:00`.
    temp19-title = `The new design guide`.
    temp19-info = `Conf. room 3`.
    temp19-pic = ``.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-07T13:00`.
    temp19-end_at = `2019-10-07T14:30`.
    temp19-title = `Team meeting`.
    temp19-info = `Conf. Room 2`.
    temp19-pic = ``.
    temp19-type = `Type01`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-10T11:00`.
    temp19-end_at = `2019-10-10T12:30`.
    temp19-title = `Meet the developers`.
    temp19-info = `Room 6`.
    temp19-pic = `images/John_Li.jpg`.
    temp19-type = `Type05`.
    temp19-tentative = abap_true.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-11T09:00`.
    temp19-end_at = `2019-10-11T17:00`.
    temp19-title = `The new design guide`.
    temp19-info = `Conf. room 3`.
    temp19-pic = ``.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-14T09:00`.
    temp19-end_at = `2019-10-14T11:30`.
    temp19-title = `Team meeting`.
    temp19-info = `Conf. room 1`.
    temp19-pic = ``.
    temp19-type = `Type01`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-15T09:00`.
    temp19-end_at = `2019-10-15T17:00`.
    temp19-title = `Photoshop training`.
    temp19-info = `Training hall`.
    temp19-pic = `sap-icon://education`.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-18T09:30`.
    temp19-end_at = `2019-10-18T12:00`.
    temp19-title = `Security training`.
    temp19-info = `Training hall`.
    temp19-pic = `sap-icon://education`.
    temp19-type = `Type05`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-22T11:00`.
    temp19-end_at = `2019-10-22T12:30`.
    temp19-title = `Team meeting`.
    temp19-info = `Conf. Room 2`.
    temp19-pic = ``.
    temp19-type = `Type01`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-23T10:00`.
    temp19-end_at = `2019-10-23T13:00`.
    temp19-title = `Styling and typography`.
    temp19-info = `Training hall`.
    temp19-pic = `sap-icon://education`.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-24T19:00`.
    temp19-end_at = `2019-10-24T22:00`.
    temp19-title = `Family dinner`.
    temp19-info = `Nice restaurant`.
    temp19-pic = ``.
    temp19-type = `Type03`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-28T09:00`.
    temp19-end_at = `2019-10-28T11:00`.
    temp19-title = `Talk to Mishelle`.
    temp19-info = ``.
    temp19-pic = ``.
    temp19-type = `Type05`.
    temp19-tentative = abap_true.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-29T09:00`.
    temp19-end_at = `2019-10-29T14:00`.
    temp19-title = `Team meeting`.
    temp19-info = `Conf. room 2`.
    temp19-pic = ``.
    temp19-type = `Type01`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-31T09:00`.
    temp19-end_at = `2019-10-31T17:00`.
    temp19-title = `Styling and typography`.
    temp19-info = `Training hall`.
    temp19-pic = `sap-icon://education`.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp4-t_appointments = temp18.
    
    CLEAR temp20.
    
    temp21-start_at = `2019-10-08T00:00:00`.
    temp21-end_at = `2019-10-10T00:00:00`.
    temp21-title = `Team building`.
    temp21-type = `Type09`.
    INSERT temp21 INTO TABLE temp20.
    temp21-start_at = `2019-10-10T00:00:00`.
    temp21-end_at = `2019-10-12T00:00:00`.
    temp21-title = `Business trip`.
    temp21-type = `Type05`.
    INSERT temp21 INTO TABLE temp20.
    temp4-t_headers = temp20.
    INSERT temp4 INTO TABLE temp3.
    temp4-personid = `PersonID_4`.
    temp4-name = `John Li`.
    temp4-role = `Developer`.
    temp4-pic = `images/John_Li.jpg`.
    
    CLEAR temp22.
    
    temp23-start_at = `2019-10-02T14:00`.
    temp23-end_at = `2019-10-02T16:00`.
    temp23-title = `Doctor`.
    temp23-info = `Town hospital`.
    temp23-pic = `sap-icon://offsite-work`.
    temp23-type = `Type09`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-07T13:00`.
    temp23-end_at = `2019-10-07T14:30`.
    temp23-title = `Team meeting`.
    temp23-info = `Conf. room 2`.
    temp23-pic = ``.
    temp23-type = `Type01`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-10T11:00`.
    temp23-end_at = `2019-10-10T12:30`.
    temp23-title = `Meet the designers`.
    temp23-info = `Room 6`.
    temp23-pic = `images/Elena_Petrova.jpg`.
    temp23-type = `Type05`.
    temp23-tentative = abap_true.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-14T09:00`.
    temp23-end_at = `2019-10-14T11:30`.
    temp23-title = `Team meeting`.
    temp23-info = `Conf. room 1`.
    temp23-pic = ``.
    temp23-type = `Type01`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-15T09:00`.
    temp23-end_at = `2019-10-15T17:00`.
    temp23-title = `Mastering JavaScript`.
    temp23-info = `Conf. room 3`.
    temp23-pic = ``.
    temp23-type = `Type08`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-16T09:00`.
    temp23-end_at = `2019-10-16T17:00`.
    temp23-title = `Introduction to app development`.
    temp23-info = `Training hall`.
    temp23-pic = `sap-icon://education`.
    temp23-type = `Type08`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-17T15:30`.
    temp23-end_at = `2019-10-17T17:00`.
    temp23-title = `Security training`.
    temp23-info = `Training hall`.
    temp23-pic = `sap-icon://education`.
    temp23-type = `Type05`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-22T11:00`.
    temp23-end_at = `2019-10-22T12:30`.
    temp23-title = `Team meeting`.
    temp23-info = `Conf. room 2`.
    temp23-pic = ``.
    temp23-type = `Type01`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-23T14:00`.
    temp23-end_at = `2019-10-23T16:00`.
    temp23-title = `Doctor`.
    temp23-info = `Town hospital`.
    temp23-pic = `sap-icon://offsite-work`.
    temp23-type = `Type09`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-25T18:00`.
    temp23-end_at = `2019-10-25T20:00`.
    temp23-title = `Play tennis`.
    temp23-info = `With Jessie`.
    temp23-pic = ``.
    temp23-type = `Type05`.
    temp23-tentative = abap_true.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-29T09:00`.
    temp23-end_at = `2019-10-29T11:00`.
    temp23-title = `Developers meeting`.
    temp23-info = ``.
    temp23-pic = ``.
    temp23-type = `Type01`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-29T11:00`.
    temp23-end_at = `2019-10-29T13:00`.
    temp23-title = `Candidate interview`.
    temp23-info = `Room 7`.
    temp23-pic = ``.
    temp23-type = `Type05`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-30T09:00`.
    temp23-end_at = `2019-10-30T17:00`.
    temp23-title = `Mastering JavaScript`.
    temp23-info = `Training hall`.
    temp23-pic = `sap-icon://education`.
    temp23-type = `Type08`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp4-t_appointments = temp22.
    
    CLEAR temp24.
    
    temp25-start_at = `2019-10-08T00:00:00`.
    temp25-end_at = `2019-10-10T00:00:00`.
    temp25-title = `Team building`.
    temp25-type = `Type09`.
    INSERT temp25 INTO TABLE temp24.
    temp25-start_at = `2019-10-11T00:00:00`.
    temp25-end_at = `2019-10-12T00:00:00`.
    temp25-title = `Business trip`.
    temp25-type = `Type05`.
    INSERT temp25 INTO TABLE temp24.
    temp25-start_at = `2019-10-18T00:00:00`.
    temp25-end_at = `2019-10-19T00:00:00`.
    temp25-title = `Business trip`.
    temp25-type = `Type05`.
    INSERT temp25 INTO TABLE temp24.
    temp25-start_at = `2019-10-31T00:00:00`.
    temp25-end_at = `2019-11-02T00:00:00`.
    temp25-title = `Business trip`.
    temp25-type = `Type05`.
    INSERT temp25 INTO TABLE temp24.
    temp4-t_headers = temp24.
    INSERT temp4 INTO TABLE temp3.
    t_team = temp3.

    
    CLEAR temp5.
    
    temp6-text = `Team meeting`.
    temp6-type = `Type01`.
    INSERT temp6 INTO TABLE temp5.
    temp6-text = `Personal`.
    temp6-type = `Type05`.
    INSERT temp6 INTO TABLE temp5.
    temp6-text = `Discussions`.
    temp6-type = `Type08`.
    INSERT temp6 INTO TABLE temp5.
    temp6-text = `Out of office`.
    temp6-type = `Type09`.
    INSERT temp6 INTO TABLE temp5.
    temp6-text = `Private meeting`.
    temp6-type = `Type03`.
    INSERT temp6 INTO TABLE temp5.
    t_legend = temp5.

    " the Select of the original is filled by _populateSelect( ) after the
    " fragment loads; here it is a bound table, "Team" plus one row per person
    
    CLEAR temp7.
    
    temp8-key = `Team`.
    temp8-text = `Team`.
    INSERT temp8 INTO TABLE temp7.
    t_members = temp7.
    
    LOOP AT t_team INTO member_row.
      
      CLEAR temp9.
      temp9-key = member_row-name.
      temp9-text = member_row-name.
      INSERT temp9 INTO TABLE t_members.
    ENDLOOP.

    " the picture paths are the mock's relative ones; the original's
    " fixImagePath prefixes everything that is not an icon, once
    
    
    LOOP AT t_team REFERENCE INTO person.
      IF person->pic IS NOT INITIAL AND person->pic NP `sap-icon://*`.
        person->pic = |{ c_base }{ person->pic }|.
      ENDIF.
      
      
      LOOP AT person->t_appointments REFERENCE INTO appointment.
        IF appointment->pic IS NOT INITIAL AND appointment->pic NP `sap-icon://*`.
          appointment->pic = |{ c_base }{ appointment->pic }|.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
