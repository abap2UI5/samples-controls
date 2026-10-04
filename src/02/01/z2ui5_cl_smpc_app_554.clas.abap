" @keywords singleplanningcalendar single planning calendar sap.m singleplanningcalendarwithzoominzoomout dynamicsidecontent vbox togglebutton button singleplanningcalendardayview singleplanningcalendarworkweekview
" @summary SinglePlanningCalendar with enabled Zoom In and Zoom Out functionality.
" @origin sap.m.sample.SinglePlanningCalendarWithZoomInZoomOut - https://sdk.openui5.org/entity/sap.m.SinglePlanningCalendar/sample/sap.m.sample.SinglePlanningCalendarWithZoomInZoomOut (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_554 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_appointment,
        title     TYPE string,
        text      TYPE string,
        type      TYPE string,
        icon      TYPE string,
        start_at  TYPE string,
        end_at    TYPE string,
        tentative TYPE abap_bool,
      END OF ty_s_appointment.
    TYPES ty_t_appointment TYPE STANDARD TABLE OF ty_s_appointment WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_special,
        start_at TYPE string,
        end_at   TYPE string,
        type     TYPE string,
        color    TYPE string,
      END OF ty_s_special.
    TYPES ty_t_special TYPE STANDARD TABLE OF ty_s_special WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_legend,
        text  TYPE string,
        type  TYPE string,
        color TYPE string,
      END OF ty_s_legend.
    TYPES ty_t_legend TYPE STANDARD TABLE OF ty_s_legend WITH DEFAULT KEY.

    DATA t_appointments      TYPE ty_t_appointment.
    DATA t_special_dates     TYPE ty_t_special.
    DATA t_legend_items      TYPE ty_t_legend.
    DATA t_legend_appt_items TYPE ty_t_legend.

    DATA startdate    TYPE string.
    DATA legend_shown TYPE abap_bool.
    DATA full_day     TYPE abap_bool.
    DATA scale_factor TYPE i.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_554 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    " the calendar date properties are typed "object" and demand a real JS Date;
    " the model keeps ISO strings and Formatter.DateCreateObject converts them
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`      v = `sap.ui.unified`
        )->a( n = `xmlns:l`      v = `sap.ui.layout`
        )->a( n = `xmlns:core`   v = `sap.ui.core`
        )->a( n = `xmlns`        v = `sap.m`
        )->a( n = `core:require` v = `{Formatter: 'z2ui5/model/formatter'}`

        )->ele( n = `DynamicSideContent` ns = `l`
            )->a( n = `id`                    v = `DynamicSideContent`
            )->a( n = `class`                 v = `sapUiDSCExplored sapUiContentPadding`
            )->a( n = `sideContentVisibility` v = `AlwaysShow`
            " the original keeps the legend flag in a second named model; abap2UI5
            " keeps one default model, so the flag is a field here
            )->a( n = `showSideContent`       v = client->_bind( legend_shown )
            )->a( n = `containerQuery`        v = `true`

            )->ele( `VBox`

                )->ele( `SinglePlanningCalendar`
                    )->a( n = `id`           v = `SPC1`
                    )->a( n = `class`        v = `sapUiSmallMarginTop`
                    )->a( n = `title`        v = `My Calendar`
                    )->a( n = `startHour`    v = `8`
                    )->a( n = `endHour`      v = `20`
                    " toggleFullDay flips setFullDay; the property is bindable, so
                    " the ToggleButton and the calendar share the flag
                    )->a( n = `fullDay`      v = client->_bind( full_day )
                    " zoomIn / zoomOut step setScaleFactor; the property is bindable
                    " and the two presses do the same increment in ABAP
                    )->a( n = `scaleFactor`  v = client->_bind( scale_factor )
                    )->a( n = `startDate`    v = |\{ path: '{ client->_bind_path( startdate ) }', formatter: 'Formatter.DateCreateObject' \}|
                    )->a( n = `appointments` v = client->_bind( t_appointments )
                    )->a( n = `specialDates` v = client->_bind( t_special_dates )
                    )->a( n = `legend`       v = `SinglePlanningCalendarLegend`

                    )->ele( `actions`
                        )->tag( `ToggleButton`
                            )->a( n = `text`    v = `Full Day`
                            )->a( n = `pressed` v = client->_bind( full_day )
                        )->tag( `ToggleButton`
                            )->a( n = `pressed` v = client->_bind( legend_shown )
                            )->a( n = `icon`    v = `sap-icon://legend`
                        )->tag( `Button`
                            )->a( n = `icon`  v = `sap-icon://zoom-in`
                            )->a( n = `press` v = client->_event( `ZOOM_IN` )
                        )->tag( `Button`
                            )->a( n = `icon`  v = `sap-icon://zoom-out`
                            )->a( n = `press` v = client->_event( `ZOOM_OUT` )

                    )->end(

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

                    )->end(

                    )->ele( `specialDates`
                        )->tag( n = `DateTypeRange` ns = `u`
                            )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
                            )->a( n = `endDate`   v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }`
                            )->a( n = `type`      v = `{TYPE}`
                            )->a( n = `color`     v = `{COLOR}`

                    )->end(

                    )->ele( `appointments`
                        )->tag( n = `CalendarAppointment` ns = `u`
                            )->a( n = `title`     v = `{TITLE}`
                            )->a( n = `text`      v = `{TEXT}`
                            )->a( n = `type`      v = `{TYPE}`
                            )->a( n = `icon`      v = `{ICON}`
                            )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
                            )->a( n = `endDate`   v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }`

                    )->end(
                )->end(
            )->end(

            )->ele( n = `sideContent` ns = `l`
                )->a( n = `width` v = `200px`

                )->ele( `PlanningCalendarLegend`
                    )->a( n = `id`               v = `SinglePlanningCalendarLegend`
                    " ROOT-level aggregations - a bare 'T_' path is RELATIVE and resolves
                    " against nothing outside a row context, and an unbound table is not
                    " serialized at all (app 553 has the same two fixes)
                    )->a( n = `items`            v = |\{ path: '{ client->_bind_path( t_legend_items ) }', templateShareable: true \}|
                    )->a( n = `appointmentItems` v = |\{ path: '{ client->_bind_path( t_legend_appt_items ) }', templateShareable: true \}|
                    )->a( n = `class`            v = `sapUiSmallMarginTop`

                    )->ele( `items`
                        )->tag( n = `CalendarLegendItem` ns = `u`
                            )->a( n = `text`    v = `{TEXT}`
                            )->a( n = `type`    v = `{TYPE}`
                            )->a( n = `color`   v = `{COLOR}`
                            )->a( n = `tooltip` v = `{TEXT}`

                    )->end(
                    )->ele( `appointmentItems`
                        )->tag( n = `CalendarLegendItem` ns = `u`
                            )->a( n = `text`    v = `{TEXT}`
                            )->a( n = `type`    v = `{TYPE}`
                            )->a( n = `tooltip` v = `{TEXT}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `ZOOM_IN`.
        scale_factor = scale_factor + 1.

      WHEN `ZOOM_OUT`.
        scale_factor = scale_factor - 1.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.
    DATA temp1 TYPE z2ui5_cl_smpc_app_554=>ty_t_special.
    DATA temp2 TYPE z2ui5_cl_smpc_app_554=>ty_t_appointment.
    DATA temp3 LIKE LINE OF temp2.
    DATA temp4 TYPE z2ui5_cl_smpc_app_554=>ty_t_legend.
    DATA temp5 LIKE LINE OF temp4.
    DATA temp6 TYPE z2ui5_cl_smpc_app_554=>ty_t_legend.
    DATA temp7 LIKE LINE OF temp6.

    startdate   = `2018-07-24T00:00:00`.
    legend_shown = abap_false.
    full_day     = abap_false.
    " the SinglePlanningCalendar scaleFactor default
    scale_factor = 1.

    " the view binds /specialDates, which the sample's own model never fills
    
    CLEAR temp1.
    t_special_dates = temp1.
    
    CLEAR temp2.
    
    temp3-title = `Meet John Miller`.
    temp3-type = `Type05`.
    temp3-start_at = `2018-07-24T08:00:00`.
    temp3-end_at = `2018-07-24T08:05:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Discussion of the plan`.
    temp3-type = `Type08`.
    temp3-start_at = `2018-07-24T08:05:00`.
    temp3-end_at = `2018-07-24T08:10:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Lunch`.
    temp3-text = `canteen`.
    temp3-type = `Type05`.
    temp3-start_at = `2018-07-24T08:10:00`.
    temp3-end_at = `2018-07-24T08:15:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `New Product`.
    temp3-text = `room 105`.
    temp3-type = `Type01`.
    temp3-icon = `sap-icon://meeting-room`.
    temp3-start_at = `2018-07-24T08:15:00`.
    temp3-end_at = `2018-07-24T08:20:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Team meeting`.
    temp3-text = `Regular`.
    temp3-type = `Type01`.
    temp3-icon = `sap-icon://home`.
    temp3-start_at = `2018-07-24T08:20:00`.
    temp3-end_at = `2018-07-24T08:25:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Discussion with clients`.
    temp3-text = `Online meeting`.
    temp3-type = `Type08`.
    temp3-icon = `sap-icon://home`.
    temp3-start_at = `2018-07-24T08:25:00`.
    temp3-end_at = `2018-07-24T08:30:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Discussion of the plan`.
    temp3-text = `Online meeting`.
    temp3-type = `Type08`.
    temp3-icon = `sap-icon://home`.
    temp3-start_at = `2018-07-24T08:30:00`.
    temp3-end_at = `2018-07-24T08:35:00`.
    temp3-tentative = abap_true.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Discussion with clients`.
    temp3-type = `Type08`.
    temp3-icon = `sap-icon://home`.
    temp3-start_at = `2018-07-24T08:35:00`.
    temp3-end_at = `2018-07-24T08:40:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Meeting with the manager`.
    temp3-type = `Type03`.
    temp3-start_at = `2018-07-24T08:40:00`.
    temp3-end_at = `2018-07-24T08:45:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Meeting with the manager`.
    temp3-type = `Type03`.
    temp3-start_at = `2018-07-24T08:45:00`.
    temp3-end_at = `2018-07-24T08:50:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Lunch`.
    temp3-type = `Type05`.
    temp3-start_at = `2018-07-24T08:50:00`.
    temp3-end_at = `2018-07-24T08:55:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Team meeting`.
    temp3-text = `online`.
    temp3-type = `Type01`.
    temp3-start_at = `2018-07-24T08:55:00`.
    temp3-end_at = `2018-07-24T09:00:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Discussion with clients`.
    temp3-type = `Type08`.
    temp3-start_at = `2018-07-25T08:00:00`.
    temp3-end_at = `2018-07-25T09:00:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Team meeting`.
    temp3-text = `room 5`.
    temp3-type = `Type01`.
    temp3-start_at = `2018-07-26T08:00:00`.
    temp3-end_at = `2018-07-26T08:30:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Daily standup meeting`.
    temp3-type = `Type01`.
    temp3-start_at = `2018-07-26T08:30:00`.
    temp3-end_at = `2018-07-26T09:00:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Private meeting`.
    temp3-type = `Type03`.
    temp3-start_at = `2018-07-27T08:00:00`.
    temp3-end_at = `2018-07-27T08:20:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Team meeting`.
    temp3-text = `room 5`.
    temp3-type = `Type01`.
    temp3-start_at = `2018-07-27T08:20:00`.
    temp3-end_at = `2018-07-27T08:40:00`.
    INSERT temp3 INTO TABLE temp2.
    temp3-title = `Meeting with the manager`.
    temp3-type = `Type03`.
    temp3-start_at = `2018-07-27T08:40:00`.
    temp3-end_at = `2018-07-27T09:00:00`.
    INSERT temp3 INTO TABLE temp2.
    t_appointments = temp2.

    
    CLEAR temp4.
    
    temp5-text = `Public holiday`.
    temp5-type = `Type07`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Team building`.
    temp5-type = `Type08`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Work from office 1`.
    temp5-type = `Type09`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Work from office 2`.
    temp5-type = `Type14`.
    INSERT temp5 INTO TABLE temp4.
    temp5-text = `Home office`.
    temp5-type = `Type03`.
    temp5-color = `#add8e6`.
    INSERT temp5 INTO TABLE temp4.
    t_legend_items = temp4.

    
    CLEAR temp6.
    
    temp7-text = `Team Meeting`.
    temp7-type = `Type01`.
    INSERT temp7 INTO TABLE temp6.
    temp7-text = `Personal`.
    temp7-type = `Type05`.
    INSERT temp7 INTO TABLE temp6.
    temp7-text = `Discussions`.
    temp7-type = `Type08`.
    INSERT temp7 INTO TABLE temp6.
    temp7-text = `Out of office`.
    temp7-type = `Type09`.
    INSERT temp7 INTO TABLE temp6.
    temp7-text = `Private meeting`.
    temp7-type = `Type03`.
    INSERT temp7 INTO TABLE temp6.
    t_legend_appt_items = temp6.

  ENDMETHOD.

ENDCLASS.
