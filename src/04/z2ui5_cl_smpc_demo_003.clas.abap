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
        t_appointments TYPE STANDARD TABLE OF ty_s_appointment WITH EMPTY KEY,
        t_headers      TYPE STANDARD TABLE OF ty_s_header WITH EMPTY KEY,
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

    DATA t_team       TYPE STANDARD TABLE OF ty_s_person WITH EMPTY KEY.
    DATA t_selected   TYPE STANDARD TABLE OF ty_s_appointment WITH EMPTY KEY.
    DATA t_members    TYPE STANDARD TABLE OF ty_s_member WITH EMPTY KEY.
    DATA t_legend     TYPE STANDARD TABLE OF ty_s_legend WITH EMPTY KEY.
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

    " calendar date properties are typed "object" and demand a real JS Date;
    " the model keeps the mock's ISO strings and Formatter.DateCreateObject
    " converts them - the curated module's whole reason to exist.
    " The chain hangs off the factory( ) rather than starting from a
    " standalone one: with the split shape the variable has to hold the
    " mvc:View, or the next statement adds a SECOND ROOT beside it and the
    " document does not parse (view-chain-layout, "the one combination that
    " is broken")
    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `xmlns:f`      v = `sap.f`
            )->a( n = `xmlns:l`      v = `sap.ui.layout`
            )->a( n = `xmlns:u`      v = `sap.ui.unified`
            )->a( n = `xmlns:core`   v = `sap.ui.core`
            )->a( n = `height`       v = `100%`
            )->a( n = `core:require` v = `{Formatter: 'z2ui5/model/formatter'}` ).

    DATA(page) = view->ele( n = `DynamicPage` ns = `f`
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

    DATA(content) = page->ele( n = `content` ns = `f`
        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `id`    v = `mainContent`
            )->a( n = `width` v = `100%` ).

    " ------------------------------------------------- the team calendar
    DATA(pc) = content->ele( `VBox`
        )->a( n = `visible` b = check_team

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

    DATA(pc_toolbar) = pc->ele( `toolbarContent` ).

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
            )->a( n = `press`   v = client->_event( val = `LEGEND` arg = `$event.oSource.sId` ) ).

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
    DATA(spc) = content->ele( `VBox`
        )->a( n = `visible` v = |\{= !${ client->_bind( check_team ) } \}|

        )->ele( `SinglePlanningCalendar`
            )->a( n = `id`           v = `SinglePlanningCalendar`
            )->a( n = `startDate`    v = |\{ path: '{ client->_bind_path( start_date ) }', formatter: 'Formatter.DateCreateObject' \}|
            )->a( n = `appointments` v = client->_bind( t_selected ) ).

    DATA(spc_actions) = spc->ele( `actions` ).

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
            )->a( n = `press`   v = client->_event( val = `LEGEND` arg = `$event.oSource.sId` ) ).

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

    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

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

    member = name.
    check_team = xsdbool( name = `Team` ).
    IF check_team = abap_true.
      t_selected = VALUE #( ).
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
    CLEAR t_selected.
    ASSIGN t_team[ name = name ] TO FIELD-SYMBOL(<member>).
    IF <member> IS ASSIGNED.
      t_selected = <member>-t_appointments.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " model/Calendar.json's own start date
    start_date = `2019-10-01T08:00:00`.

    " model/Calendar.json - the team, their appointments and the interval
    " headers, verbatim
    t_team = VALUE #(
        ( personid = `PersonID_1` name = `John Miller` role = `Scrum master` pic = `images/John_Miller.png`
          t_appointments = VALUE #(
              ( start_at = `2019-10-01T09:00` end_at = `2019-10-01T11:30` title = `Team meeting`              info = `Conf. room 1`  pic = ``                        type = `Type01` tentative = abap_true )
              ( start_at = `2019-10-04T09:00` end_at = `2019-10-04T17:30` title = `Face to face`              info = `Room 13`       pic = `images/Donna_Moore.jpg`  type = `Type05` tentative = abap_false )
              ( start_at = `2019-10-07T09:00` end_at = `2019-10-07T11:30` title = `Team meeting`              info = `Conf. room 1`  pic = ``                        type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-11T09:00` end_at = `2019-10-11T17:30` title = `Face to face`              info = `Room 13`       pic = `images/Donna_Moore.jpg`  type = `Type05` tentative = abap_false )
              ( start_at = `2019-10-10T09:00` end_at = `2019-10-10T17:00` title = `Show and tell`             info = ``              pic = ``                        type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-16T09:00` end_at = `2019-10-16T11:30` title = `Team meeting`              info = `Conf. room 1`  pic = ``                        type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-17T14:00` end_at = `2019-10-17T16:00` title = `Release plan presentation` info = `Conf. room 1`  pic = `sap-icon://legend`       type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-18T09:30` end_at = `2019-10-18T12:00` title = `Training`                  info = `Training hall` pic = `sap-icon://education`    type = `Type05` tentative = abap_false )
              ( start_at = `2019-10-21T09:00` end_at = `2019-10-21T11:30` title = `Team meeting`              info = `Conf. room 1`  pic = ``                        type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-23T10:00` end_at = `2019-10-23T13:00` title = `Company security`          info = `Conf. room 3`  pic = `sap-icon://legend`       type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-24T09:30` end_at = `2019-10-24T13:00` title = `Dentist`                   info = ``              pic = `sap-icon://offsite-work` type = `Type09` tentative = abap_false )
              ( start_at = `2019-10-29T14:00` end_at = `2019-10-29T15:00` title = `Face to face`              info = `Room 13`       pic = `images/Donna_Moore.jpg`  type = `Type05` tentative = abap_false )
          )
          t_headers = VALUE #(
              ( start_at = `2019-10-08T00:00:00` end_at = `2019-10-10T00:00:00` title = `Team building` type = `Type09` )
              ( start_at = `2019-10-24T00:00:00` end_at = `2019-10-26T00:00:00` title = `Business trip` type = `Type05` )
          )
        )
        ( personid = `PersonID_2` name = `Donna Moore` role = `Team manager` pic = `images/Donna_Moore.jpg`
          t_appointments = VALUE #(
              ( start_at = `2019-10-01T09:00` end_at = `2019-10-01T11:30` title = `Team meeting`              info = `Conf. room 1` pic = ``                        type = `Type01` tentative = abap_true )
              ( start_at = `2019-10-04T09:00` end_at = `2019-10-04T17:30` title = `Face to face`              info = `Room 13`      pic = `images/John_Miller.png`  type = `Type05` tentative = abap_false )
              ( start_at = `2019-10-07T09:00` end_at = `2019-10-07T11:30` title = `Team meeting`              info = `Conf. room 1` pic = ``                        type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-11T09:00` end_at = `2019-10-11T17:30` title = `Face to face`              info = `Room 13`      pic = `images/John_Miller.png`  type = `Type05` tentative = abap_false )
              ( start_at = `2019-10-14T09:00` end_at = `2019-10-14T17:00` title = `Conference in Berlin`      info = ``             pic = ``                        type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-16T09:00` end_at = `2019-10-16T11:30` title = `Team meeting`              info = `Conf. room 1` pic = ``                        type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-17T14:00` end_at = `2019-10-17T16:00` title = `Release plan presentation` info = `Conf. room 1` pic = `sap-icon://legend`       type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-21T09:30` end_at = `2019-10-21T12:00` title = `Doctor`                    info = `City clinic`  pic = `sap-icon://offsite-work` type = `Type09` tentative = abap_false )
              ( start_at = `2019-10-21T14:00` end_at = `2019-10-21T17:00` title = `Company results`           info = `Conf. room 2` pic = ``                        type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-23T10:00` end_at = `2019-10-23T13:00` title = `Company security`          info = `Conf. room 3` pic = `sap-icon://legend`       type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-29T14:00` end_at = `2019-10-29T15:00` title = `Face to face`              info = `Room 13`      pic = `images/John_Miller.png`  type = `Type05` tentative = abap_false )
          )
          t_headers = VALUE #(
              ( start_at = `2019-10-08T00:00:00` end_at = `2019-10-10T00:00:00` title = `Team building` type = `Type09` )
              ( start_at = `2019-10-14T00:00:00` end_at = `2019-10-16T00:00:00` title = `Business trip` type = `Type05` )
          )
        )
        ( personid = `PersonID_3` name = `Elena Petrova` role = `Designer` pic = `images/Elena_Petrova.jpg`
          t_appointments = VALUE #(
              ( start_at = `2019-10-03T09:00` end_at = `2019-10-03T17:00` title = `The new design guide`   info = `Conf. room 3`    pic = ``                     type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-07T13:00` end_at = `2019-10-07T14:30` title = `Team meeting`           info = `Conf. Room 2`    pic = ``                     type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-10T11:00` end_at = `2019-10-10T12:30` title = `Meet the developers`    info = `Room 6`          pic = `images/John_Li.jpg`   type = `Type05` tentative = abap_true )
              ( start_at = `2019-10-11T09:00` end_at = `2019-10-11T17:00` title = `The new design guide`   info = `Conf. room 3`    pic = ``                     type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-14T09:00` end_at = `2019-10-14T11:30` title = `Team meeting`           info = `Conf. room 1`    pic = ``                     type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-15T09:00` end_at = `2019-10-15T17:00` title = `Photoshop training`     info = `Training hall`   pic = `sap-icon://education` type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-18T09:30` end_at = `2019-10-18T12:00` title = `Security training`      info = `Training hall`   pic = `sap-icon://education` type = `Type05` tentative = abap_false )
              ( start_at = `2019-10-22T11:00` end_at = `2019-10-22T12:30` title = `Team meeting`           info = `Conf. Room 2`    pic = ``                     type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-23T10:00` end_at = `2019-10-23T13:00` title = `Styling and typography` info = `Training hall`   pic = `sap-icon://education` type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-24T19:00` end_at = `2019-10-24T22:00` title = `Family dinner`          info = `Nice restaurant` pic = ``                     type = `Type03` tentative = abap_false )
              ( start_at = `2019-10-28T09:00` end_at = `2019-10-28T11:00` title = `Talk to Mishelle`       info = ``                pic = ``                     type = `Type05` tentative = abap_true )
              ( start_at = `2019-10-29T09:00` end_at = `2019-10-29T14:00` title = `Team meeting`           info = `Conf. room 2`    pic = ``                     type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-31T09:00` end_at = `2019-10-31T17:00` title = `Styling and typography` info = `Training hall`   pic = `sap-icon://education` type = `Type08` tentative = abap_false )
          )
          t_headers = VALUE #(
              ( start_at = `2019-10-08T00:00:00` end_at = `2019-10-10T00:00:00` title = `Team building` type = `Type09` )
              ( start_at = `2019-10-10T00:00:00` end_at = `2019-10-12T00:00:00` title = `Business trip` type = `Type05` )
          )
        )
        ( personid = `PersonID_4` name = `John Li` role = `Developer` pic = `images/John_Li.jpg`
          t_appointments = VALUE #(
              ( start_at = `2019-10-02T14:00` end_at = `2019-10-02T16:00` title = `Doctor`                          info = `Town hospital` pic = `sap-icon://offsite-work`  type = `Type09` tentative = abap_false )
              ( start_at = `2019-10-07T13:00` end_at = `2019-10-07T14:30` title = `Team meeting`                    info = `Conf. room 2`  pic = ``                         type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-10T11:00` end_at = `2019-10-10T12:30` title = `Meet the designers`              info = `Room 6`        pic = `images/Elena_Petrova.jpg` type = `Type05` tentative = abap_true )
              ( start_at = `2019-10-14T09:00` end_at = `2019-10-14T11:30` title = `Team meeting`                    info = `Conf. room 1`  pic = ``                         type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-15T09:00` end_at = `2019-10-15T17:00` title = `Mastering JavaScript`            info = `Conf. room 3`  pic = ``                         type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-16T09:00` end_at = `2019-10-16T17:00` title = `Introduction to app development` info = `Training hall` pic = `sap-icon://education`     type = `Type08` tentative = abap_false )
              ( start_at = `2019-10-17T15:30` end_at = `2019-10-17T17:00` title = `Security training`               info = `Training hall` pic = `sap-icon://education`     type = `Type05` tentative = abap_false )
              ( start_at = `2019-10-22T11:00` end_at = `2019-10-22T12:30` title = `Team meeting`                    info = `Conf. room 2`  pic = ``                         type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-23T14:00` end_at = `2019-10-23T16:00` title = `Doctor`                          info = `Town hospital` pic = `sap-icon://offsite-work`  type = `Type09` tentative = abap_false )
              ( start_at = `2019-10-25T18:00` end_at = `2019-10-25T20:00` title = `Play tennis`                     info = `With Jessie`   pic = ``                         type = `Type05` tentative = abap_true )
              ( start_at = `2019-10-29T09:00` end_at = `2019-10-29T11:00` title = `Developers meeting`              info = ``              pic = ``                         type = `Type01` tentative = abap_false )
              ( start_at = `2019-10-29T11:00` end_at = `2019-10-29T13:00` title = `Candidate interview`             info = `Room 7`        pic = ``                         type = `Type05` tentative = abap_false )
              ( start_at = `2019-10-30T09:00` end_at = `2019-10-30T17:00` title = `Mastering JavaScript`            info = `Training hall` pic = `sap-icon://education`     type = `Type08` tentative = abap_false )
          )
          t_headers = VALUE #(
              ( start_at = `2019-10-08T00:00:00` end_at = `2019-10-10T00:00:00` title = `Team building` type = `Type09` )
              ( start_at = `2019-10-11T00:00:00` end_at = `2019-10-12T00:00:00` title = `Business trip` type = `Type05` )
              ( start_at = `2019-10-18T00:00:00` end_at = `2019-10-19T00:00:00` title = `Business trip` type = `Type05` )
              ( start_at = `2019-10-31T00:00:00` end_at = `2019-11-02T00:00:00` title = `Business trip` type = `Type05` )
          )
        )
    ).

    t_legend = VALUE #(
        ( text = `Team meeting`    type = `Type01` )
        ( text = `Personal`        type = `Type05` )
        ( text = `Discussions`     type = `Type08` )
        ( text = `Out of office`   type = `Type09` )
        ( text = `Private meeting` type = `Type03` ) ).

    " the Select of the original is filled by _populateSelect( ) after the
    " fragment loads; here it is a bound table, "Team" plus one row per person
    t_members = VALUE #( ( key = `Team` text = `Team` ) ).
    LOOP AT t_team INTO DATA(member_row).
      INSERT VALUE #( key = member_row-name text = member_row-name ) INTO TABLE t_members.
    ENDLOOP.

    " the picture paths are the mock's relative ones; the original's
    " fixImagePath prefixes everything that is not an icon, once
    LOOP AT t_team REFERENCE INTO DATA(person).
      IF person->pic IS NOT INITIAL AND person->pic NP `sap-icon://*`.
        person->pic = |{ c_base }{ person->pic }|.
      ENDIF.
      LOOP AT person->t_appointments REFERENCE INTO DATA(appointment).
        IF appointment->pic IS NOT INITIAL AND appointment->pic NP `sap-icon://*`.
          appointment->pic = |{ c_base }{ appointment->pic }|.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
