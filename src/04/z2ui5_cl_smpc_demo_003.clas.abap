" @keywords team calendar app dynamicpagetitle title verticallayout responsivepopover planningcalendarlegend calendarlegenditem planningcalendar select button
" @summary Calendar demo app for team and team members. - the UI5 demo app "Team Calendar", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Team Calendar (sap.m/teamCalendar) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Team Calendar</p>
"!
"! The UI5 demo app Team Calendar, rebuilt as ONE abap2UI5 class and 1:1 with
"! its one view, its three fragments and its controller: a DynamicPage whose
"! VerticalLayout shows either the team's PlanningCalendar - four people,
"! their appointments and their interval headers - or the
"! SinglePlanningCalendar of one team member, switched by the "Calendar for:"
"! Select of either calendar or by a click on a row of the team calendar.
"! The date and the view the user has reached travel across every switch
"! (startDateChangeHandler / viewChangeHandler), "Create" shows the
"! original's toast and the legend button toggles the calendar legend in its
"! ResponsivePopover.
"!
"! Where it differs from the original, and why - only what a backend-driven
"! app cannot do the same way:
"!
"!  - a switch between the two calendars REBUILDS the view with the calendar
"!    the controller's _displayCalendar( ) would add to the VerticalLayout,
"!    where the original keeps both fragments loaded and swaps them. What the
"!    swap carries is state of this class instead (start_date, view_key,
"!    member), so the rebuilt calendar opens where the swapped one would.
"!    For the same reason viewChangeHandler's setStartDate( ) of the saved
"!    date is a rebuild too: a Date object cannot travel as a control-call
"!    argument, and the rebuilt calendar starts on the saved date.
"!  - the dates stay ISO strings in ABAP and become JS Dates at the binding
"!    (Formatter.DateCreateObject, the original's utcToLocalDateTime): an
"!    object-typed property cannot be filled from JSON. The date a calendar
"!    reports on startDateChange comes back as its toISOString( ) - the same
"!    instant, spelled in UTC.
"!  - the SinglePlanningCalendar's selectedView is an ASSOCIATION: it cannot
"!    be bound, and set in the XML it is resolved before the views exist
"!    ("There is no such view"). _displayCalendar's setSelectedView( ) is
"!    therefore wired to the calendar's own modelContextChange, which fires
"!    once the calendar - views included - is built and has its model, and
"!    hands over the view's runtime id: the one spelling setSelectedView( )
"!    accepts, and one only the browser knows.
"!  - the fixImagePath formatter moves to the backend: model_init prefixes
"!    every picture that is not an icon once with the demo kit's own URL,
"!    which is what the original computes from sap.ui.require.toUrl( ).
"!  - the legend's ResponsivePopover carries an id (legendPopover): it lives
"!    in the view's dependents, as the original adds it there, and the
"!    buttons toggle it by that id without a round-trip (isOpen ? close :
"!    openBy, as openLegend does).
"!  - the legend buttons do not set ariaHasPopup="Dialog": Button has it from
"!    UI5 1.84 on, above the 1.71 floor of src/04.
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
      BEGIN OF ty_s_legend,
        text TYPE string,
        type TYPE string,
      END OF ty_s_legend.

    DATA t_team     TYPE STANDARD TABLE OF ty_s_person WITH EMPTY KEY.
    " the appointments of the member the SinglePlanningCalendar shows - the
    " original binds the calendar to /team/<index> (bindElement)
    DATA t_selected TYPE STANDARD TABLE OF ty_s_appointment WITH EMPTY KEY.
    DATA t_legend   TYPE STANDARD TABLE OF ty_s_legend WITH EMPTY KEY.
    DATA page_title TYPE string.
    " the controller's _oStartDate, _sSelectedView and _sSelectedMember
    DATA start_date TYPE string.
    DATA view_key   TYPE string.
    DATA member     TYPE string.

  PROTECTED SECTION.
    " what the original's fixImagePath prefixes a relative picture with:
    " sap.ui.require.toUrl( ) resolved against the demo kit's own host
    CONSTANTS c_base TYPE string VALUE `https://sdk.openui5.org/test-resources/sap/m/demokit/teamCalendar/webapp/`.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_legend
      IMPORTING
        view TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS view_team
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS view_single
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS view_select_items
      IMPORTING
        selector TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS on_event.
    METHODS calendar_load
      IMPORTING
        key TYPE string.
    METHODS is_single
      RETURNING
        VALUE(result) TYPE abap_bool.
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

    " Main.view.xml. The chain hangs off the factory( ) rather than starting
    " from a standalone one: with the split shape the variable has to hold
    " the mvc:View, or the next statement adds a SECOND ROOT beside it
    " (view-chain-layout, "the one combination that is broken")
    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `xmlns:f`      v = `sap.f`
            )->a( n = `xmlns:layout` v = `sap.ui.layout`
            )->a( n = `xmlns:u`      v = `sap.ui.unified`
            )->a( n = `xmlns:core`   v = `sap.ui.core`
            )->a( n = `height`       v = `100%`
            " the calendar dates are object-typed and demand a real JS Date -
            " Formatter.DateCreateObject is the original's utcToLocalDateTime
            )->a( n = `core:require` v = `{Formatter: 'z2ui5/model/formatter'}` ).

    view_legend( view ).

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

    " the VerticalLayout the controller adds the displayed calendar to
    DATA(content) = page->ele( n = `content` ns = `f`
        )->ele( n = `VerticalLayout` ns = `layout`
            )->a( n = `id`    v = `mainContent`
            )->a( n = `width` v = `100%` ).

    IF is_single( ) = abap_true.
      view_single( content ).
    ELSE.
      view_team( content ).
    ENDIF.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_legend.

    " Legend.fragment.xml - openLegend( ) loads it once and adds it to the
    " view's dependents; the two legend buttons toggle it by id
    view->ele( n = `dependents` ns = `mvc`
        )->ele( `ResponsivePopover`
            )->a( n = `id`         v = `legendPopover`
            )->a( n = `title`      v = `Calendar Legend`
            )->a( n = `placement`  v = `Bottom`
            )->a( n = `showHeader` b = abap_false

            )->ele( `PlanningCalendarLegend`
                )->a( n = `appointmentItems` v = |\{ path: '{ client->_bind_path( t_legend ) }', templateShareable: true \}|

                )->ele( `appointmentItems`
                    )->tag( n = `CalendarLegendItem` ns = `u`
                        )->a( n = `text`    v = `{TEXT}`
                        )->a( n = `type`    v = `{TYPE}`
                        )->a( n = `tooltip` v = `{TEXT}` ).

  ENDMETHOD.


  METHOD view_team.

    " PlanningCalendar.fragment.xml. viewKey is the saved view (the fragment's
    " "Day" is what _displayCalendar overwrites at once), startDate the saved
    " date. The three events are the controller's handlers: a row opens that
    " member's calendar, the date and the view are kept for the next switch.
    " The two keeping wires queue (check_queue_last): the calendar reports its
    " aligned start date while it is still being built, and a view switch
    " fires startDateChange and viewChange back to back
    DATA(pc) = parent->ele( `VBox`
        )->ele( `PlanningCalendar`
            )->a( n = `id`                        v = `PlanningCalendar`
            )->a( n = `startDate`                 v = |\{ path: '{ client->_bind_path( start_date ) }', formatter: 'Formatter.DateCreateObject' \}|
            )->a( n = `viewKey`                   v = client->_bind( view_key )
            )->a( n = `rows`                      v = client->_bind( t_team )
            )->a( n = `appointmentsVisualization` v = `Filled`
            )->a( n = `showEmptyIntervalHeaders`  b = abap_false
            )->a( n = `showWeekNumbers`           b = abap_true
            " rowSelectionHandler cuts the row index out of the row's id
            )->a( n = `rowSelectionChange`        v = client->_event( val = `ROW_SELECT`
                                                                      arg = `${$parameters>/rows}[0].getId().split('-').pop()` )
            )->a( n = `startDateChange`           v = client->_event( val    = `START_DATE`
                                                                      arg    = `$event.getSource().getStartDate().toISOString()`
                                                                      s_ctrl = VALUE #( check_queue_last = abap_true
                                                                                        check_no_busy    = abap_true ) )
            )->a( n = `viewChange`                v = client->_event( val    = `VIEW_CHANGE`
                                                                      arg    = `${$source>/viewKey}`
                                                                      s_ctrl = VALUE #( check_queue_last = abap_true ) ) ).

    DATA(toolbar) = pc->ele( `toolbarContent` ).

    DATA(toolbar_select) = toolbar->tag( `Label`
        )->a( n = `labelFor` v = `PlanningCalendarTeamSelector`
        )->a( n = `text`     v = `Calendar for: `

        )->ele( `Select`
            )->a( n = `id`          v = `PlanningCalendarTeamSelector`
            )->a( n = `selectedKey` v = client->_bind( member )
            )->a( n = `change`      v = client->_event( val = `SELECT_MEMBER`
                                                        arg = `${$parameters>/selectedItem}.getKey()` ) ).
    view_select_items( toolbar_select ).

    toolbar->tag( `Button`
        )->a( n = `id`      v = `PlanningCalendarCreateAppointmentButton`
        )->a( n = `text`    v = `Create`
        )->a( n = `press`   v = client->_event( `CREATE` )
        )->a( n = `tooltip` v = `Create new appointment`
        )->tag( `Button`
            )->a( n = `id`      v = `PlanningCalendarLegendButton`
            )->a( n = `icon`    v = `sap-icon://legend`
            " openLegend: isOpen( ) ? close( ) : openBy( the button ) - in the
            " browser, no round-trip
            )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                              t_arg = VALUE #( ( `legendPopover` )
                                                                               ( `toggleBy` )
                                                                               ( `PlanningCalendarLegendButton` ) ) )
            )->a( n = `tooltip` v = `Open Planning Calendar legend` ).

    pc->ele( `views`
        )->ele( `PlanningCalendarView`
            )->a( n = `key`              v = `Day`
            )->a( n = `intervalType`     v = `Hour`
            )->a( n = `description`      v = `Day`
            )->a( n = `intervalsS`       v = `3`
            )->a( n = `intervalsM`       v = `6`
            )->a( n = `intervalsL`       v = `12`
            )->a( n = `showSubIntervals` b = abap_true

        )->end(
        )->ele( `PlanningCalendarView`
            )->a( n = `key`              v = `Week`
            )->a( n = `intervalType`     v = `Week`
            )->a( n = `description`      v = `Week`
            )->a( n = `intervalsS`       v = `1`
            )->a( n = `intervalsM`       v = `2`
            )->a( n = `intervalsL`       v = `7`
            )->a( n = `showSubIntervals` b = abap_true

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

    " the headers carry no `pic`, so the fragment's icon binding of the
    " interval headers resolves to nothing and is left out
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

  ENDMETHOD.


  METHOD view_single.

    " SinglePlanningCalendar.fragment.xml. startDate is the saved date (the
    " controller's setStartDate). viewChangeHandler reads the key of the
    " selected view; the views carry ids that end in their key, so the key is
    " what the wire cuts out of getSelectedView( ).
    "
    " _displayCalendar's setSelectedView( getViewByKey( saved view ) ):
    " selectedView is an association that takes the view's RUNTIME id, and
    " the XML cannot preset it (UI5 resolves it before the views aggregation
    " is filled). modelContextChange fires once the calendar is complete and
    " has its model - so that is where the calendar is handed the id of the
    " view it should open on. Both ids are read off the event's source, which
    " is the fully qualified calendar: it resolves before the view is
    " registered anywhere
    DATA(view_index) = SWITCH string( view_key WHEN `Week` THEN `1` WHEN `OneMonth` THEN `2` ELSE `0` ).

    DATA(spc) = parent->ele( `VBox`
        )->ele( `SinglePlanningCalendar`
            )->a( n = `id`              v = `SinglePlanningCalendar`
            )->a( n = `startDate`       v = |\{ path: '{ client->_bind_path( start_date ) }', formatter: 'Formatter.DateCreateObject' \}|
            )->a( n = `startDateChange` v = client->_event( val    = `START_DATE`
                                                            arg    = `$event.getSource().getStartDate().toISOString()`
                                                            s_ctrl = VALUE #( check_queue_last = abap_true
                                                                              check_no_busy    = abap_true ) )
            )->a( n = `viewChange`      v = client->_event( val    = `VIEW_CHANGE`
                                                            arg    = `$event.getSource().getSelectedView().split('spcView').pop()`
                                                            s_ctrl = VALUE #( check_queue_last = abap_true ) )
            )->a( n = `appointments`    v = client->_bind( t_selected )
            )->a( n = `modelContextChange`
                  v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                t_arg = VALUE #( ( `$event.getSource().getId()` )
                                                                 ( `setSelectedView` )
                                                                 ( |$event.getSource().getViews()[{ view_index }].getId()| ) ) ) ).

    DATA(actions) = spc->ele( `actions` ).

    DATA(actions_select) = actions->tag( `Label`
        )->a( n = `labelFor` v = `SinglePlanningCalendarTeamSelector`
        )->a( n = `text`     v = `Calendar for: `

        )->ele( `Select`
            )->a( n = `id`          v = `SinglePlanningCalendarTeamSelector`
            )->a( n = `selectedKey` v = client->_bind( member )
            )->a( n = `change`      v = client->_event( val = `SELECT_MEMBER`
                                                        arg = `${$parameters>/selectedItem}.getKey()` ) ).
    view_select_items( actions_select ).

    actions->tag( `Button`
        )->a( n = `id`      v = `SinglePlanningCalendarCreateAppointmentButton`
        )->a( n = `text`    v = `Create`
        )->a( n = `press`   v = client->_event( `CREATE` )
        )->a( n = `tooltip` v = `Create new appointment`
        )->tag( `Button`
            )->a( n = `id`      v = `SinglePlanningCalendarLegendButton`
            )->a( n = `icon`    v = `sap-icon://legend`
            " openLegend: isOpen( ) ? close( ) : openBy( the button ) - in the
            " browser, no round-trip
            )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                              t_arg = VALUE #( ( `legendPopover` )
                                                                               ( `toggleBy` )
                                                                               ( `SinglePlanningCalendarLegendButton` ) ) )
            )->a( n = `tooltip` v = `Open Single Planning Calendar legend` ).

    spc->ele( `views`
        )->tag( `SinglePlanningCalendarDayView`
            )->a( n = `id`    v = `spcViewDay`
            )->a( n = `key`   v = `Day`
            )->a( n = `title` v = `Day`
        )->tag( `SinglePlanningCalendarWeekView`
            )->a( n = `id`    v = `spcViewWeek`
            )->a( n = `key`   v = `Week`
            )->a( n = `title` v = `Week`
        )->tag( `SinglePlanningCalendarMonthView`
            )->a( n = `id`    v = `spcViewOneMonth`
            )->a( n = `key`   v = `OneMonth`
            )->a( n = `title` v = `Month` ).

    " the fragment binds `text` and `icon` of these appointments to
    " calendar>text and calendar>icon - two paths the rows of the model do
    " not have (they carry `info` and `pic`), so the demo kit shows neither
    " here, and neither does this rebuild. No `tentative` either, as there
    spc->ele( `appointments`
        )->tag( n = `CalendarAppointment` ns = `u`
            )->a( n = `title`     v = `{TITLE}`
            )->a( n = `type`      v = `{TYPE}`
            )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
            )->a( n = `endDate`   v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }` ).

  ENDMETHOD.


  METHOD view_select_items.

    " the Select of both fragments: "Team", plus what _populateSelect( ) adds
    " once the fragment has loaded - one item per person, its index the key
    selector->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = `Team`
        )->a( n = `text` v = `Team` ).
    LOOP AT t_team INTO DATA(person).
      " read before the chain runs - the builder's own table work moves sy-tabix
      DATA(index) = sy-tabix - 1.
      selector->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = |{ index }|
          )->a( n = `text` v = person-name ).
    ENDLOOP.

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SELECT_MEMBER` OR `ROW_SELECT`.
        " selectChangeHandler (the item's key) and rowSelectionHandler (the
        " index out of the row's id) - both then _loadCalendar( )
        calendar_load( client->get_event_arg( ) ).

      WHEN `START_DATE`.
        " startDateChangeHandler: only kept, nothing is redrawn
        DATA(date) = client->get_event_arg( ).
        IF date IS NOT INITIAL.
          start_date = date.
        ENDIF.

      WHEN `VIEW_CHANGE`.
        " viewChangeHandler: keep the view, then put the calendar back on the
        " saved date - the rebuilt calendar opens on both
        DATA(key) = client->get_event_arg( ).
        IF key IS NOT INITIAL.
          view_key = key.
        ENDIF.
        view_display( ).

      WHEN `CREATE`.
        " appointmentCreate
        client->message_toast_display( `Creating new appointment...` ).

    ENDCASE.

  ENDMETHOD.


  METHOD calendar_load.

    " _loadCalendar / _displayCalendar: "Team" (anything not a number) is the
    " PlanningCalendar of everybody, an index the SinglePlanningCalendar of
    " that person
    member = key.
    t_selected = VALUE #( ).
    IF is_single( ) = abap_true.
      DATA(index) = CONV i( member ) + 1.
      READ TABLE t_team INDEX index ASSIGNING FIELD-SYMBOL(<person>).
      IF sy-subrc = 0.
        t_selected = <person>-t_appointments.
      ENDIF.
    ENDIF.
    view_display( ).

  ENDMETHOD.


  METHOD is_single.

    " the controller's isNaN( this._sSelectedMember ), negated
    result = xsdbool( member IS NOT INITIAL AND member CO `0123456789` ).

  ENDMETHOD.


  METHOD model_init.

    " model/Calendar.json: its title, its start date and view, and onInit's
    " "Team" as the member shown first
    page_title = `Team Calendar`.
    start_date = `2019-10-01T08:00:00`.
    view_key   = `OneMonth`.
    member     = `Team`.

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
