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
        t_appointments TYPE STANDARD TABLE OF ty_s_appointment WITH DEFAULT KEY,
        t_headers      TYPE STANDARD TABLE OF ty_s_header WITH DEFAULT KEY,
      END OF ty_s_person.
    TYPES:
      BEGIN OF ty_s_legend,
        text TYPE string,
        type TYPE string,
      END OF ty_s_legend.

    TYPES temp1_090b636631 TYPE STANDARD TABLE OF ty_s_person WITH DEFAULT KEY.
DATA t_team     TYPE temp1_090b636631.
    " the appointments of the member the SinglePlanningCalendar shows - the
    " original binds the calendar to /team/<index> (bindElement)
    TYPES temp2_090b636631 TYPE STANDARD TABLE OF ty_s_appointment WITH DEFAULT KEY.
DATA t_selected TYPE temp2_090b636631.
    TYPES temp3_090b636631 TYPE STANDARD TABLE OF ty_s_legend WITH DEFAULT KEY.
DATA t_legend   TYPE temp3_090b636631.
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

    " Main.view.xml. The chain hangs off the factory( ) rather than starting
    " from a standalone one: with the split shape the variable has to hold
    " the mvc:View, or the next statement adds a SECOND ROOT beside it
    " (view-chain-layout, "the one combination that is broken")
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory(
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

    " the VerticalLayout the controller adds the displayed calendar to
    
    content = page->ele( n = `content` ns = `f`
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
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp3 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA pc TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA toolbar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA toolbar_select TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp2 TYPE string_table.
    CLEAR temp1.
    temp1-check_queue_last = abap_true.
    temp1-check_no_busy = abap_true.
    
    CLEAR temp3.
    temp3-check_queue_last = abap_true.
    
    pc = parent->ele( `VBox`
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
                                                                      s_ctrl = temp1 )
            )->a( n = `viewChange`                v = client->_event( val    = `VIEW_CHANGE`
                                                                      arg    = `${$source>/viewKey}`
                                                                      s_ctrl = temp3 ) ).

    
    toolbar = pc->ele( `toolbarContent` ).

    
    toolbar_select = toolbar->tag( `Label`
        )->a( n = `labelFor` v = `PlanningCalendarTeamSelector`
        )->a( n = `text`     v = `Calendar for: `

        )->ele( `Select`
            )->a( n = `id`          v = `PlanningCalendarTeamSelector`
            )->a( n = `selectedKey` v = client->_bind( member )
            )->a( n = `change`      v = client->_event( val = `SELECT_MEMBER`
                                                        arg = `${$parameters>/selectedItem}.getKey()` ) ).
    view_select_items( toolbar_select ).

    
    CLEAR temp2.
    INSERT `legendPopover` INTO TABLE temp2.
    INSERT `toggleBy` INTO TABLE temp2.
    INSERT `PlanningCalendarLegendButton` INTO TABLE temp2.
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
                                                              t_arg = temp2 )
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
    DATA temp4 TYPE string.
    DATA view_index LIKE temp4.
    DATA temp5 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp7 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA temp1 TYPE string_table.
    DATA temp2 LIKE LINE OF temp1.
    DATA spc TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA actions TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA actions_select TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp6 TYPE string_table.
    CASE view_key.
      WHEN `Week`.
        temp4 = `1`.
      WHEN `OneMonth`.
        temp4 = `2`.
      WHEN OTHERS.
        temp4 = `0`.
    ENDCASE.
    
    view_index = temp4.

    
    CLEAR temp5.
    temp5-check_queue_last = abap_true.
    temp5-check_no_busy = abap_true.
    
    CLEAR temp7.
    temp7-check_queue_last = abap_true.
    
    CLEAR temp1.
    INSERT `$event.getSource().getId()` INTO TABLE temp1.
    INSERT `setSelectedView` INTO TABLE temp1.
    
    temp2 = |$event.getSource().getViews()[{ view_index }].getId()|.
    INSERT temp2 INTO TABLE temp1.
    
    spc = parent->ele( `VBox`
        )->ele( `SinglePlanningCalendar`
            )->a( n = `id`              v = `SinglePlanningCalendar`
            )->a( n = `startDate`       v = |\{ path: '{ client->_bind_path( start_date ) }', formatter: 'Formatter.DateCreateObject' \}|
            )->a( n = `startDateChange` v = client->_event( val    = `START_DATE`
                                                            arg    = `$event.getSource().getStartDate().toISOString()`
                                                            s_ctrl = temp5 )
            )->a( n = `viewChange`      v = client->_event( val    = `VIEW_CHANGE`
                                                            arg    = `$event.getSource().getSelectedView().split('spcView').pop()`
                                                            s_ctrl = temp7 )
            )->a( n = `appointments`    v = client->_bind( t_selected )
            )->a( n = `modelContextChange`
                  v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                t_arg = temp1 ) ).

    
    actions = spc->ele( `actions` ).

    
    actions_select = actions->tag( `Label`
        )->a( n = `labelFor` v = `SinglePlanningCalendarTeamSelector`
        )->a( n = `text`     v = `Calendar for: `

        )->ele( `Select`
            )->a( n = `id`          v = `SinglePlanningCalendarTeamSelector`
            )->a( n = `selectedKey` v = client->_bind( member )
            )->a( n = `change`      v = client->_event( val = `SELECT_MEMBER`
                                                        arg = `${$parameters>/selectedItem}.getKey()` ) ).
    view_select_items( actions_select ).

    
    CLEAR temp6.
    INSERT `legendPopover` INTO TABLE temp6.
    INSERT `toggleBy` INTO TABLE temp6.
    INSERT `SinglePlanningCalendarLegendButton` INTO TABLE temp6.
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
                                                              t_arg = temp6 )
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
    DATA person LIKE LINE OF t_team.
      DATA index TYPE i.

    " the Select of both fragments: "Team", plus what _populateSelect( ) adds
    " once the fragment has loaded - one item per person, its index the key
    selector->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = `Team`
        )->a( n = `text` v = `Team` ).
    
    LOOP AT t_team INTO person.
      " read before the chain runs - the builder's own table work moves sy-tabix
      
      index = sy-tabix - 1.
      selector->tag( n = `Item` ns = `core`
          )->a( n = `key`  v = |{ index }|
          )->a( n = `text` v = person-name ).
    ENDLOOP.

  ENDMETHOD.


  METHOD on_event.
        DATA date TYPE string.
        DATA key TYPE string.

    CASE client->get_event( ).

      WHEN `SELECT_MEMBER` OR `ROW_SELECT`.
        " selectChangeHandler (the item's key) and rowSelectionHandler (the
        " index out of the row's id) - both then _loadCalendar( )
        calendar_load( client->get_event_arg( ) ).

      WHEN `START_DATE`.
        " startDateChangeHandler: only kept, nothing is redrawn
        
        date = client->get_event_arg( ).
        IF date IS NOT INITIAL.
          start_date = date.
        ENDIF.

      WHEN `VIEW_CHANGE`.
        " viewChangeHandler: keep the view, then put the calendar back on the
        " saved date - the rebuilt calendar opens on both
        
        key = client->get_event_arg( ).
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
    DATA temp8 LIKE t_selected.
      DATA temp9 TYPE i.
      DATA index TYPE i.
      FIELD-SYMBOLS <person> TYPE z2ui5_cl_smpc_demo_003=>ty_s_person.

    " _loadCalendar / _displayCalendar: "Team" (anything not a number) is the
    " PlanningCalendar of everybody, an index the SinglePlanningCalendar of
    " that person
    member = key.
    
    CLEAR temp8.
    t_selected = temp8.
    IF is_single( ) = abap_true.
      
      temp9 = member.
      
      index = temp9 + 1.
      
      READ TABLE t_team INDEX index ASSIGNING <person>.
      IF sy-subrc = 0.
        t_selected = <person>-t_appointments.
      ENDIF.
    ENDIF.
    view_display( ).

  ENDMETHOD.


  METHOD is_single.

    " the controller's isNaN( this._sSelectedMember ), negated
    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( member IS NOT INITIAL AND member CO `0123456789` ).
    result = temp1.

  ENDMETHOD.


  METHOD model_init.
    DATA temp10 LIKE t_team.
    DATA temp11 LIKE LINE OF temp10.
    DATA temp8 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_appointments.
    DATA temp9 LIKE LINE OF temp8.
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
    DATA temp26 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_appointments.
    DATA temp27 LIKE LINE OF temp26.
    DATA temp28 TYPE z2ui5_cl_smpc_demo_003=>ty_s_person-t_headers.
    DATA temp29 LIKE LINE OF temp28.
    DATA temp12 LIKE t_legend.
    DATA temp13 LIKE LINE OF temp12.
    DATA temp14 LIKE LINE OF t_team.
    DATA person LIKE REF TO temp14.
      DATA temp15 LIKE LINE OF person->t_appointments.
      DATA appointment LIKE REF TO temp15.

    " model/Calendar.json: its title, its start date and view, and onInit's
    " "Team" as the member shown first
    page_title = `Team Calendar`.
    start_date = `2019-10-01T08:00:00`.
    view_key   = `OneMonth`.
    member     = `Team`.

    " model/Calendar.json - the team, their appointments and the interval
    " headers, verbatim
    
    CLEAR temp10.
    
    temp11-personid = `PersonID_1`.
    temp11-name = `John Miller`.
    temp11-role = `Scrum master`.
    temp11-pic = `images/John_Miller.png`.
    
    CLEAR temp8.
    
    temp9-start_at = `2019-10-01T09:00`.
    temp9-end_at = `2019-10-01T11:30`.
    temp9-title = `Team meeting`.
    temp9-info = `Conf. room 1`.
    temp9-pic = ``.
    temp9-type = `Type01`.
    temp9-tentative = abap_true.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-04T09:00`.
    temp9-end_at = `2019-10-04T17:30`.
    temp9-title = `Face to face`.
    temp9-info = `Room 13`.
    temp9-pic = `images/Donna_Moore.jpg`.
    temp9-type = `Type05`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-07T09:00`.
    temp9-end_at = `2019-10-07T11:30`.
    temp9-title = `Team meeting`.
    temp9-info = `Conf. room 1`.
    temp9-pic = ``.
    temp9-type = `Type01`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-11T09:00`.
    temp9-end_at = `2019-10-11T17:30`.
    temp9-title = `Face to face`.
    temp9-info = `Room 13`.
    temp9-pic = `images/Donna_Moore.jpg`.
    temp9-type = `Type05`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-10T09:00`.
    temp9-end_at = `2019-10-10T17:00`.
    temp9-title = `Show and tell`.
    temp9-info = ``.
    temp9-pic = ``.
    temp9-type = `Type08`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-16T09:00`.
    temp9-end_at = `2019-10-16T11:30`.
    temp9-title = `Team meeting`.
    temp9-info = `Conf. room 1`.
    temp9-pic = ``.
    temp9-type = `Type01`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-17T14:00`.
    temp9-end_at = `2019-10-17T16:00`.
    temp9-title = `Release plan presentation`.
    temp9-info = `Conf. room 1`.
    temp9-pic = `sap-icon://legend`.
    temp9-type = `Type08`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-18T09:30`.
    temp9-end_at = `2019-10-18T12:00`.
    temp9-title = `Training`.
    temp9-info = `Training hall`.
    temp9-pic = `sap-icon://education`.
    temp9-type = `Type05`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-21T09:00`.
    temp9-end_at = `2019-10-21T11:30`.
    temp9-title = `Team meeting`.
    temp9-info = `Conf. room 1`.
    temp9-pic = ``.
    temp9-type = `Type01`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-23T10:00`.
    temp9-end_at = `2019-10-23T13:00`.
    temp9-title = `Company security`.
    temp9-info = `Conf. room 3`.
    temp9-pic = `sap-icon://legend`.
    temp9-type = `Type08`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-24T09:30`.
    temp9-end_at = `2019-10-24T13:00`.
    temp9-title = `Dentist`.
    temp9-info = ``.
    temp9-pic = `sap-icon://offsite-work`.
    temp9-type = `Type09`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp9-start_at = `2019-10-29T14:00`.
    temp9-end_at = `2019-10-29T15:00`.
    temp9-title = `Face to face`.
    temp9-info = `Room 13`.
    temp9-pic = `images/Donna_Moore.jpg`.
    temp9-type = `Type05`.
    temp9-tentative = abap_false.
    INSERT temp9 INTO TABLE temp8.
    temp11-t_appointments = temp8.
    
    CLEAR temp16.
    
    temp17-start_at = `2019-10-08T00:00:00`.
    temp17-end_at = `2019-10-10T00:00:00`.
    temp17-title = `Team building`.
    temp17-type = `Type09`.
    INSERT temp17 INTO TABLE temp16.
    temp17-start_at = `2019-10-24T00:00:00`.
    temp17-end_at = `2019-10-26T00:00:00`.
    temp17-title = `Business trip`.
    temp17-type = `Type05`.
    INSERT temp17 INTO TABLE temp16.
    temp11-t_headers = temp16.
    INSERT temp11 INTO TABLE temp10.
    temp11-personid = `PersonID_2`.
    temp11-name = `Donna Moore`.
    temp11-role = `Team manager`.
    temp11-pic = `images/Donna_Moore.jpg`.
    
    CLEAR temp18.
    
    temp19-start_at = `2019-10-01T09:00`.
    temp19-end_at = `2019-10-01T11:30`.
    temp19-title = `Team meeting`.
    temp19-info = `Conf. room 1`.
    temp19-pic = ``.
    temp19-type = `Type01`.
    temp19-tentative = abap_true.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-04T09:00`.
    temp19-end_at = `2019-10-04T17:30`.
    temp19-title = `Face to face`.
    temp19-info = `Room 13`.
    temp19-pic = `images/John_Miller.png`.
    temp19-type = `Type05`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-07T09:00`.
    temp19-end_at = `2019-10-07T11:30`.
    temp19-title = `Team meeting`.
    temp19-info = `Conf. room 1`.
    temp19-pic = ``.
    temp19-type = `Type01`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-11T09:00`.
    temp19-end_at = `2019-10-11T17:30`.
    temp19-title = `Face to face`.
    temp19-info = `Room 13`.
    temp19-pic = `images/John_Miller.png`.
    temp19-type = `Type05`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-14T09:00`.
    temp19-end_at = `2019-10-14T17:00`.
    temp19-title = `Conference in Berlin`.
    temp19-info = ``.
    temp19-pic = ``.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-16T09:00`.
    temp19-end_at = `2019-10-16T11:30`.
    temp19-title = `Team meeting`.
    temp19-info = `Conf. room 1`.
    temp19-pic = ``.
    temp19-type = `Type01`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-17T14:00`.
    temp19-end_at = `2019-10-17T16:00`.
    temp19-title = `Release plan presentation`.
    temp19-info = `Conf. room 1`.
    temp19-pic = `sap-icon://legend`.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-21T09:30`.
    temp19-end_at = `2019-10-21T12:00`.
    temp19-title = `Doctor`.
    temp19-info = `City clinic`.
    temp19-pic = `sap-icon://offsite-work`.
    temp19-type = `Type09`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-21T14:00`.
    temp19-end_at = `2019-10-21T17:00`.
    temp19-title = `Company results`.
    temp19-info = `Conf. room 2`.
    temp19-pic = ``.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-23T10:00`.
    temp19-end_at = `2019-10-23T13:00`.
    temp19-title = `Company security`.
    temp19-info = `Conf. room 3`.
    temp19-pic = `sap-icon://legend`.
    temp19-type = `Type08`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp19-start_at = `2019-10-29T14:00`.
    temp19-end_at = `2019-10-29T15:00`.
    temp19-title = `Face to face`.
    temp19-info = `Room 13`.
    temp19-pic = `images/John_Miller.png`.
    temp19-type = `Type05`.
    temp19-tentative = abap_false.
    INSERT temp19 INTO TABLE temp18.
    temp11-t_appointments = temp18.
    
    CLEAR temp20.
    
    temp21-start_at = `2019-10-08T00:00:00`.
    temp21-end_at = `2019-10-10T00:00:00`.
    temp21-title = `Team building`.
    temp21-type = `Type09`.
    INSERT temp21 INTO TABLE temp20.
    temp21-start_at = `2019-10-14T00:00:00`.
    temp21-end_at = `2019-10-16T00:00:00`.
    temp21-title = `Business trip`.
    temp21-type = `Type05`.
    INSERT temp21 INTO TABLE temp20.
    temp11-t_headers = temp20.
    INSERT temp11 INTO TABLE temp10.
    temp11-personid = `PersonID_3`.
    temp11-name = `Elena Petrova`.
    temp11-role = `Designer`.
    temp11-pic = `images/Elena_Petrova.jpg`.
    
    CLEAR temp22.
    
    temp23-start_at = `2019-10-03T09:00`.
    temp23-end_at = `2019-10-03T17:00`.
    temp23-title = `The new design guide`.
    temp23-info = `Conf. room 3`.
    temp23-pic = ``.
    temp23-type = `Type08`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-07T13:00`.
    temp23-end_at = `2019-10-07T14:30`.
    temp23-title = `Team meeting`.
    temp23-info = `Conf. Room 2`.
    temp23-pic = ``.
    temp23-type = `Type01`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-10T11:00`.
    temp23-end_at = `2019-10-10T12:30`.
    temp23-title = `Meet the developers`.
    temp23-info = `Room 6`.
    temp23-pic = `images/John_Li.jpg`.
    temp23-type = `Type05`.
    temp23-tentative = abap_true.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-11T09:00`.
    temp23-end_at = `2019-10-11T17:00`.
    temp23-title = `The new design guide`.
    temp23-info = `Conf. room 3`.
    temp23-pic = ``.
    temp23-type = `Type08`.
    temp23-tentative = abap_false.
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
    temp23-title = `Photoshop training`.
    temp23-info = `Training hall`.
    temp23-pic = `sap-icon://education`.
    temp23-type = `Type08`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-18T09:30`.
    temp23-end_at = `2019-10-18T12:00`.
    temp23-title = `Security training`.
    temp23-info = `Training hall`.
    temp23-pic = `sap-icon://education`.
    temp23-type = `Type05`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-22T11:00`.
    temp23-end_at = `2019-10-22T12:30`.
    temp23-title = `Team meeting`.
    temp23-info = `Conf. Room 2`.
    temp23-pic = ``.
    temp23-type = `Type01`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-23T10:00`.
    temp23-end_at = `2019-10-23T13:00`.
    temp23-title = `Styling and typography`.
    temp23-info = `Training hall`.
    temp23-pic = `sap-icon://education`.
    temp23-type = `Type08`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-24T19:00`.
    temp23-end_at = `2019-10-24T22:00`.
    temp23-title = `Family dinner`.
    temp23-info = `Nice restaurant`.
    temp23-pic = ``.
    temp23-type = `Type03`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-28T09:00`.
    temp23-end_at = `2019-10-28T11:00`.
    temp23-title = `Talk to Mishelle`.
    temp23-info = ``.
    temp23-pic = ``.
    temp23-type = `Type05`.
    temp23-tentative = abap_true.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-29T09:00`.
    temp23-end_at = `2019-10-29T14:00`.
    temp23-title = `Team meeting`.
    temp23-info = `Conf. room 2`.
    temp23-pic = ``.
    temp23-type = `Type01`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp23-start_at = `2019-10-31T09:00`.
    temp23-end_at = `2019-10-31T17:00`.
    temp23-title = `Styling and typography`.
    temp23-info = `Training hall`.
    temp23-pic = `sap-icon://education`.
    temp23-type = `Type08`.
    temp23-tentative = abap_false.
    INSERT temp23 INTO TABLE temp22.
    temp11-t_appointments = temp22.
    
    CLEAR temp24.
    
    temp25-start_at = `2019-10-08T00:00:00`.
    temp25-end_at = `2019-10-10T00:00:00`.
    temp25-title = `Team building`.
    temp25-type = `Type09`.
    INSERT temp25 INTO TABLE temp24.
    temp25-start_at = `2019-10-10T00:00:00`.
    temp25-end_at = `2019-10-12T00:00:00`.
    temp25-title = `Business trip`.
    temp25-type = `Type05`.
    INSERT temp25 INTO TABLE temp24.
    temp11-t_headers = temp24.
    INSERT temp11 INTO TABLE temp10.
    temp11-personid = `PersonID_4`.
    temp11-name = `John Li`.
    temp11-role = `Developer`.
    temp11-pic = `images/John_Li.jpg`.
    
    CLEAR temp26.
    
    temp27-start_at = `2019-10-02T14:00`.
    temp27-end_at = `2019-10-02T16:00`.
    temp27-title = `Doctor`.
    temp27-info = `Town hospital`.
    temp27-pic = `sap-icon://offsite-work`.
    temp27-type = `Type09`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-07T13:00`.
    temp27-end_at = `2019-10-07T14:30`.
    temp27-title = `Team meeting`.
    temp27-info = `Conf. room 2`.
    temp27-pic = ``.
    temp27-type = `Type01`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-10T11:00`.
    temp27-end_at = `2019-10-10T12:30`.
    temp27-title = `Meet the designers`.
    temp27-info = `Room 6`.
    temp27-pic = `images/Elena_Petrova.jpg`.
    temp27-type = `Type05`.
    temp27-tentative = abap_true.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-14T09:00`.
    temp27-end_at = `2019-10-14T11:30`.
    temp27-title = `Team meeting`.
    temp27-info = `Conf. room 1`.
    temp27-pic = ``.
    temp27-type = `Type01`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-15T09:00`.
    temp27-end_at = `2019-10-15T17:00`.
    temp27-title = `Mastering JavaScript`.
    temp27-info = `Conf. room 3`.
    temp27-pic = ``.
    temp27-type = `Type08`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-16T09:00`.
    temp27-end_at = `2019-10-16T17:00`.
    temp27-title = `Introduction to app development`.
    temp27-info = `Training hall`.
    temp27-pic = `sap-icon://education`.
    temp27-type = `Type08`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-17T15:30`.
    temp27-end_at = `2019-10-17T17:00`.
    temp27-title = `Security training`.
    temp27-info = `Training hall`.
    temp27-pic = `sap-icon://education`.
    temp27-type = `Type05`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-22T11:00`.
    temp27-end_at = `2019-10-22T12:30`.
    temp27-title = `Team meeting`.
    temp27-info = `Conf. room 2`.
    temp27-pic = ``.
    temp27-type = `Type01`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-23T14:00`.
    temp27-end_at = `2019-10-23T16:00`.
    temp27-title = `Doctor`.
    temp27-info = `Town hospital`.
    temp27-pic = `sap-icon://offsite-work`.
    temp27-type = `Type09`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-25T18:00`.
    temp27-end_at = `2019-10-25T20:00`.
    temp27-title = `Play tennis`.
    temp27-info = `With Jessie`.
    temp27-pic = ``.
    temp27-type = `Type05`.
    temp27-tentative = abap_true.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-29T09:00`.
    temp27-end_at = `2019-10-29T11:00`.
    temp27-title = `Developers meeting`.
    temp27-info = ``.
    temp27-pic = ``.
    temp27-type = `Type01`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-29T11:00`.
    temp27-end_at = `2019-10-29T13:00`.
    temp27-title = `Candidate interview`.
    temp27-info = `Room 7`.
    temp27-pic = ``.
    temp27-type = `Type05`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp27-start_at = `2019-10-30T09:00`.
    temp27-end_at = `2019-10-30T17:00`.
    temp27-title = `Mastering JavaScript`.
    temp27-info = `Training hall`.
    temp27-pic = `sap-icon://education`.
    temp27-type = `Type08`.
    temp27-tentative = abap_false.
    INSERT temp27 INTO TABLE temp26.
    temp11-t_appointments = temp26.
    
    CLEAR temp28.
    
    temp29-start_at = `2019-10-08T00:00:00`.
    temp29-end_at = `2019-10-10T00:00:00`.
    temp29-title = `Team building`.
    temp29-type = `Type09`.
    INSERT temp29 INTO TABLE temp28.
    temp29-start_at = `2019-10-11T00:00:00`.
    temp29-end_at = `2019-10-12T00:00:00`.
    temp29-title = `Business trip`.
    temp29-type = `Type05`.
    INSERT temp29 INTO TABLE temp28.
    temp29-start_at = `2019-10-18T00:00:00`.
    temp29-end_at = `2019-10-19T00:00:00`.
    temp29-title = `Business trip`.
    temp29-type = `Type05`.
    INSERT temp29 INTO TABLE temp28.
    temp29-start_at = `2019-10-31T00:00:00`.
    temp29-end_at = `2019-11-02T00:00:00`.
    temp29-title = `Business trip`.
    temp29-type = `Type05`.
    INSERT temp29 INTO TABLE temp28.
    temp11-t_headers = temp28.
    INSERT temp11 INTO TABLE temp10.
    t_team = temp10.

    
    CLEAR temp12.
    
    temp13-text = `Team meeting`.
    temp13-type = `Type01`.
    INSERT temp13 INTO TABLE temp12.
    temp13-text = `Personal`.
    temp13-type = `Type05`.
    INSERT temp13 INTO TABLE temp12.
    temp13-text = `Discussions`.
    temp13-type = `Type08`.
    INSERT temp13 INTO TABLE temp12.
    temp13-text = `Out of office`.
    temp13-type = `Type09`.
    INSERT temp13 INTO TABLE temp12.
    temp13-text = `Private meeting`.
    temp13-type = `Type03`.
    INSERT temp13 INTO TABLE temp12.
    t_legend = temp12.

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
