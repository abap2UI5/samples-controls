" @keywords singleplanningcalendar single planning calendar sap.m day selection vbox overflowtoolbar toolbarseparator label togglebutton
" @summary SinglePlanningCalendar with multiple date selection functionality.
CLASS z2ui5_cl_smpc_app_109 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " onPress flips the calendar's dateSelectionMode and swaps the button's
    " tooltip - both are bindable properties, so they are held here and bound
    " two-way rather than driven through a frontend action
    DATA date_selection_mode TYPE string.
    DATA multiselect_tooltip TYPE string.

    TYPES: BEGIN OF ty_s_appointment,
             title      TYPE string,
             text       TYPE string,
             type       TYPE string,
             icon       TYPE string,
             start_date TYPE string,
             end_date   TYPE string,
           END OF ty_s_appointment.
    DATA t_appointments TYPE STANDARD TABLE OF ty_s_appointment WITH DEFAULT KEY.
    DATA start_date TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_109 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    " startDate + CalendarAppointment startDate/endDate are object-typed: the model
    " keeps ISO strings and Formatter.DateCreateObject converts them at the binding
    
    CLEAR temp1.
    INSERT `${$parameters>/weekNumber}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$parameters>/date}` INTO TABLE temp2.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc`     v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core`    v = `sap.ui.core`
        )->a( n = `xmlns:unified` v = `sap.ui.unified`
        )->a( n = `xmlns`         v = `sap.m`
        )->a( n = `core:require`  v = `{Formatter: 'z2ui5/model/formatter'}`

        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->ele( `OverflowToolbar`
                )->a( n = `height` v = `100%`
                )->a( n = `width`  v = `100%`

                )->tag( `ToolbarSeparator`
                )->tag( `Label`
                    )->a( n = `text` v = `Day selection mode : `
                )->ele( `ToggleButton`
                    )->a( n = `id`      v = `MultiSelect`
                    )->a( n = `icon`    v = `sap-icon://select-appointments`
                    )->a( n = `tooltip` v = client->_bind( multiselect_tooltip )
                    )->a( n = `press`   v = client->_event( `PRESS` )

                    )->ele( `layoutData`
                        )->tag( `OverflowToolbarLayoutData`
                            )->a( n = `priority` v = `NeverOverflow`

                    )->end(
                )->end(
            )->end(

            )->ele( `SinglePlanningCalendar`
                )->a( n = `id`                  v = `SPC1`
                )->a( n = `class`               v = `sapUiSmallMarginTop`
                )->a( n = `title`               v = `My Calendar`
                )->a( n = `dateSelectionMode`   v = client->_bind( date_selection_mode )
                )->a( n = `viewChange`          v = client->_event( `VIEW_CHANGE` )
                )->a( n = `selectedDatesChange` v = client->_event( `SELECTED_DATE` )
                )->a( n = `weekNumberPress`     v = client->_event( val   = `WEEK`
                                                                    t_arg = temp1 )
                )->a( n = `startDateChange`     v = client->_event( val   = `START_DATE`
                                                                    t_arg = temp2 )
                )->a( n = `startDate`           v = |\{ path: '{ client->_bind( val = start_date path = abap_true ) }', formatter: 'Formatter.DateCreateObject' \}|
                )->a( n = `appointments`        v = client->_bind( t_appointments )

                )->ele( `views`
                    )->tag( `SinglePlanningCalendarDayView`
                        )->a( n = `key`   v = `DayView`
                        )->a( n = `title` v = `Day`
                    )->tag( `SinglePlanningCalendarWorkWeekView`
                        )->a( n = `key`   v = `WorkWeekView`
                        )->a( n = `title` v = `Work Week`
                    )->tag( `SinglePlanningCalendarWeekView`
                        )->a( n = `key`   v = `WeekView`
                        )->a( n = `title` v = `Week`
                    )->tag( `SinglePlanningCalendarMonthView`
                        )->a( n = `key`   v = `MonthView`
                        )->a( n = `title` v = `Month`

                )->end(
                )->ele( `appointments`
                    )->tag( n = `CalendarAppointment` ns = `unified`
                        )->a( n = `title`     v = `{TITLE}`
                        )->a( n = `text`      v = `{TEXT}`
                        )->a( n = `type`      v = `{TYPE}`
                        )->a( n = `icon`      v = `{ICON}`
                        )->a( n = `startDate` v = `{ path: 'START_DATE', formatter: 'Formatter.DateCreateObject' }`
                        )->a( n = `endDate`   v = `{ path: 'END_DATE', formatter: 'Formatter.DateCreateObject' }` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `PRESS`.
        " onPress: SingleSelect <-> MultiSelect, and the tooltip follows the
        " pressed state exactly as the original's setTooltip does
        IF date_selection_mode = `SingleSelect`.
          date_selection_mode = `MultiSelect`.
          multiselect_tooltip = `Disable multi-day selection`.
        ELSE.
          date_selection_mode = `SingleSelect`.
          multiselect_tooltip = `Enable multi-day selection`.
        ENDIF.

      WHEN `VIEW_CHANGE`.
        client->message_toast_display( |'viewChange' event fired.| ).

      WHEN `SELECTED_DATE`.
        client->message_toast_display( |'selectedDatesChange' event fired.| ).

      WHEN `WEEK`.
        " the original appends the pressed week number, which the event carries
        client->message_toast_display( |'weekNumberPress' event fired.\n\nweek number is { client->get_event_arg( ) }| ).

      WHEN `START_DATE`.
        " same for the new start date (the event parameter, not a control ref)
        client->message_toast_display( |'startDateChange' event fired.\n\nNew start date is { client->get_event_arg( ) }| ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.
    DATA temp3 LIKE t_appointments.
    DATA temp4 LIKE LINE OF temp3.

    " the calendar opens in single-day selection, and the button offers to
    " enable the multi-day one - the original's view defaults
    date_selection_mode = `SingleSelect`.
    multiselect_tooltip = `Enable multi-day selection`.

    start_date = `2018-07-09T00:00:00`.
    
    CLEAR temp3.
    
    temp4-title = `Discussion of the plan`.
    temp4-text = ``.
    temp4-type = `Type01`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-09T00:00:00`.
    temp4-end_date = `2018-07-09T00:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Meet John Miller`.
    temp4-text = ``.
    temp4-type = `Type05`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-08T05:00:00`.
    temp4-end_date = `2018-07-08T06:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Lunch`.
    temp4-text = `canteen`.
    temp4-type = `Type05`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-08T07:00:00`.
    temp4-end_date = `2018-07-08T08:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `New Product`.
    temp4-text = `room 105`.
    temp4-type = `Type01`.
    temp4-icon = `sap-icon://meeting-room`.
    temp4-start_date = `2018-07-08T08:00:00`.
    temp4-end_date = `2018-07-08T09:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Discussion with clients for the new release dates`.
    temp4-text = `Online meeting`.
    temp4-type = `Type08`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-09T09:00:00`.
    temp4-end_date = `2018-07-09T10:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Meeting with the manager`.
    temp4-text = ``.
    temp4-type = `Type03`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-06T09:00:00`.
    temp4-end_date = `2018-07-06T10:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Daily standup meeting`.
    temp4-text = ``.
    temp4-type = `Type01`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-07T10:00:00`.
    temp4-end_date = `2018-07-07T10:30:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Private meeting`.
    temp4-text = ``.
    temp4-type = `Type03`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-06T11:30:00`.
    temp4-end_date = `2018-07-06T12:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Lunch`.
    temp4-text = ``.
    temp4-type = `Type05`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-06T12:00:00`.
    temp4-end_date = `2018-07-06T13:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Discussion of the plan`.
    temp4-text = ``.
    temp4-type = `Type01`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-16T11:00:00`.
    temp4-end_date = `2018-07-16T12:00:00`.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `Lunch`.
    temp4-text = `canteen`.
    temp4-type = `Type05`.
    temp4-icon = ``.
    temp4-start_date = `2018-07-16T12:00:00`.
    temp4-end_date = `2018-07-16T13:00:00`.
    INSERT temp4 INTO TABLE temp3.
    t_appointments = temp3.

  ENDMETHOD.

ENDCLASS.
