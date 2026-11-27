" @keywords planningcalendar planning calendar sap.m planningcalendarviews vbox title label select item datetyperange planningcalendarview
" @summary PlanningCalendar with custom views to set number of hours, days and months and change view description. It illustrates both built-in and custom views. Sub-intervals are shown. Custom non-working days and hours are set.
" @origin sap.m.sample.PlanningCalendarViews - https://sdk.openui5.org/entity/sap.m.PlanningCalendar/sample/sap.m.sample.PlanningCalendarViews (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_537 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES ty_t_int TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_appointment,
        start_at  TYPE string,
        end_at    TYPE string,
        title     TYPE string,
        info      TYPE string,
        type      TYPE string,
        pic       TYPE string,
        tentative TYPE abap_bool,
        aria      TYPE string,
      END OF ty_s_appointment.
    TYPES ty_t_appointment TYPE STANDARD TABLE OF ty_s_appointment WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_header,
        start_at TYPE string,
        end_at   TYPE string,
        title    TYPE string,
        type     TYPE string,
        pic      TYPE string,
      END OF ty_s_header.
    TYPES ty_t_header TYPE STANDARD TABLE OF ty_s_header WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_person,
        pic            TYPE string,
        name           TYPE string,
        role           TYPE string,
        " nonWorkingDays / nonWorkingHours are int[] properties: a table of
        " STRINGS serializes to ['5','6'] and UI5 rejects it ("is of type
        " object, expected int[]"), so both are integer tables
        t_free_days    TYPE ty_t_int,
        t_free_hours   TYPE ty_t_int,
        t_appointments TYPE ty_t_appointment,
        t_headers      TYPE ty_t_header,
        selected       TYPE abap_bool,
      END OF ty_s_person.
    DATA t_people TYPE STANDARD TABLE OF ty_s_person WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_special,
        start_at TYPE string,
        type     TYPE string,
      END OF ty_s_special.
    DATA t_special TYPE STANDARD TABLE OF ty_s_special WITH DEFAULT KEY.

    DATA start_date  TYPE string.
    DATA view_key    TYPE string.
    DATA group_mode  TYPE string.
    DATA t_built_in  TYPE string_table.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_537 IMPLEMENTATION.

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

    " calendar date properties are typed "object" and demand a real JS Date;
    " the model keeps ISO strings and Formatter.DateCreateObject converts them
    
    CLEAR temp1.
    INSERT `${$parameters>/appointment} ? ${$parameters>/appointment}.getTitle() : ''` INTO TABLE temp1.
    INSERT `${$parameters>/appointment} ? ${$parameters>/appointment}.getSelected() : false` INTO TABLE temp1.
    INSERT `$event.getSource().getSelectedAppointments().length` INTO TABLE temp1.
    INSERT `${$parameters>/appointments} ? ${$parameters>/appointments}.length : 0` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$parameters>/startDate}.getFullYear()` INTO TABLE temp2.
    INSERT `${$parameters>/startDate}.getMonth() + 1` INTO TABLE temp2.
    INSERT `${$parameters>/startDate}.getDate()` INTO TABLE temp2.
    INSERT `${$parameters>/startDate}.getHours()` INTO TABLE temp2.
    INSERT `${$parameters>/startDate}.getMinutes()` INTO TABLE temp2.
    INSERT `${$parameters>/endDate}.getFullYear()` INTO TABLE temp2.
    INSERT `${$parameters>/endDate}.getMonth() + 1` INTO TABLE temp2.
    INSERT `${$parameters>/endDate}.getDate()` INTO TABLE temp2.
    INSERT `${$parameters>/endDate}.getHours()` INTO TABLE temp2.
    INSERT `${$parameters>/endDate}.getMinutes()` INTO TABLE temp2.
    INSERT `${$parameters>/row} ? $event.getSource().indexOfRow(${$parameters>/row}) : -1` INTO TABLE temp2.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`      v = `sap.ui.unified`
        )->a( n = `xmlns:core`   v = `sap.ui.core`
        )->a( n = `xmlns`        v = `sap.m`
        )->a( n = `core:require` v = `{Formatter: 'z2ui5/model/formatter'}`

        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`

            )->ele( `PlanningCalendar`
                )->a( n = `id`                        v = `PC1`
                )->a( n = `startDate`                 v = |\{ path: '{ client->_bind_path( start_date ) }', formatter: 'Formatter.DateCreateObject' \}|
                " handleViewChange only recomputes the two visibilities; viewKey is
                " bindable, so the key itself is the shared field and the two
                " expressions below read it - the handler is dropped
                )->a( n = `viewKey`                   v = client->_bind( view_key )
                )->a( n = `rows`                      v = client->_bind( t_people )
                )->a( n = `appointmentsVisualization` v = `Filled`
                )->a( n = `groupAppointmentsMode`     v = client->_bind( group_mode )
                " handleNonWorkingSpecialDates toggles a NonWorking DateTypeRange
                " on the selected interval - the specialDates aggregation is bound
                )->a( n = `specialDates`              v = client->_bind( t_special )
                " handleSelectionFinish hands the MultiComboBox's selected keys to
                " setBuiltInViews - a bindable string[] property, bound here
                )->a( n = `builtInViews`              v = client->_bind( t_built_in )
                )->a( n = `appointmentSelect`         v = client->_event(
                                  val   = `APPT_SELECT`
                                  t_arg = temp1 )
                " handleIntervalSelect: in the nonWorking view it toggles the special
                " date, otherwise it pushes a 'new appointment' into the row it hit
                " (or into every selected row). The interval's start/end travel as
                " their LOCAL parts - a UTC toISOString( ) would shift the day
                )->a( n = `intervalSelect`            v = client->_event(
                                     val   = `INTERVAL_SELECT`
                                     t_arg = temp2 )
                )->a( n = `showEmptyIntervalHeaders`  v = `false`

                )->ele( `toolbarContent`
                    )->tag( `Title`
                        )->a( n = `text`       v = `Title`
                        )->a( n = `titleStyle` v = `H4`
                    " determineControlsVisibility: the Label belongs to the
                    " nonWorking view, the Select to the months view on desktop
                    )->tag( `Label`
                        )->a( n = `id`      v = `label`
                        )->a( n = `text`    v = `Select a date from the interval to mark/unmark it as a non-working day.`
                        )->a( n = `visible` v = |\{= ${ client->_bind( view_key ) } === 'nonWorking' \}|

                    )->ele( `Select`
                        )->a( n = `id`          v = `select`
                        )->a( n = `tooltip`     v = `Group appointments mode`
                        )->a( n = `selectedKey` v = client->_bind( group_mode )
                        )->a( n = `visible`     v = |\{= ${ client->_bind( view_key ) } === 'M' && $\{device>/system/desktop\} \}|

                        )->tag( n = `Item` ns = `core`
                            )->a( n = `key`  v = `Collapsed`
                            )->a( n = `text` v = `Collapsed`
                        )->tag( n = `Item` ns = `core`
                            )->a( n = `key`  v = `Expanded`
                            )->a( n = `text` v = `Expanded`

                    )->end(
                )->end(

                )->ele( `specialDates`
                    )->tag( n = `DateTypeRange` ns = `u`
                        )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
                        )->a( n = `type`      v = `{TYPE}`

                )->end(

                )->ele( `views`
                    )->tag( `PlanningCalendarView`
                        )->a( n = `key`              v = `A`
                        )->a( n = `intervalType`     v = `Hour`
                        )->a( n = `description`      v = `hours view`
                        )->a( n = `intervalsS`       v = `2`
                        )->a( n = `intervalsM`       v = `4`
                        )->a( n = `intervalsL`       v = `6`
                        )->a( n = `showSubIntervals` v = `true`
                    )->tag( `PlanningCalendarView`
                        )->a( n = `key`              v = `D`
                        )->a( n = `intervalType`     v = `Day`
                        )->a( n = `description`      v = `days view`
                        )->a( n = `intervalsS`       v = `1`
                        )->a( n = `intervalsM`       v = `3`
                        )->a( n = `intervalsL`       v = `7`
                        )->a( n = `showSubIntervals` v = `true`
                    )->tag( `PlanningCalendarView`
                        )->a( n = `key`              v = `M`
                        )->a( n = `intervalType`     v = `Month`
                        )->a( n = `description`      v = `months view`
                        )->a( n = `intervalsS`       v = `1`
                        )->a( n = `intervalsM`       v = `2`
                        )->a( n = `intervalsL`       v = `3`
                        )->a( n = `showSubIntervals` v = `true`
                    )->tag( `PlanningCalendarView`
                        )->a( n = `key`          v = `nonWorking`
                        )->a( n = `intervalType` v = `Day`
                        )->a( n = `description`  v = `days with non-working dates`
                        )->a( n = `intervalsS`   v = `1`
                        )->a( n = `intervalsM`   v = `5`
                        )->a( n = `intervalsL`   v = `9`

                )->end(

                )->ele( `rows`
                    )->ele( `PlanningCalendarRow`
                        )->a( n = `icon`            v = `{PIC}`
                        )->a( n = `title`           v = `{NAME}`
                        )->a( n = `text`            v = `{ROLE}`
                        )->a( n = `selected`        v = `{SELECTED}`
                        )->a( n = `nonWorkingDays`  v = `{T_FREE_DAYS}`
                        )->a( n = `nonWorkingHours` v = `{T_FREE_HOURS}`
                        )->a( n = `appointments`    v = `{path: 'T_APPOINTMENTS', templateShareable: false}`
                        )->a( n = `intervalHeaders` v = `{path: 'T_HEADERS', templateShareable: false}`

                        )->ele( `appointments`
                            )->tag( n = `CalendarAppointment` ns = `u`
                                )->a( n = `startDate`    v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
                                )->a( n = `endDate`      v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }`
                                )->a( n = `icon`         v = `{PIC}`
                                )->a( n = `title`        v = `{TITLE}`
                                )->a( n = `text`         v = `{INFO}`
                                )->a( n = `type`         v = `{TYPE}`
                                )->a( n = `tentative`    v = `{TENTATIVE}`
                                )->a( n = `ariaHasPopup` v = `{ARIA}`

                        )->end(
                        )->ele( `intervalHeaders`
                            )->tag( n = `CalendarAppointment` ns = `u`
                                )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
                                )->a( n = `endDate`   v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }`
                                )->a( n = `icon`      v = `{PIC}`
                                )->a( n = `title`     v = `{TITLE}`
                                )->a( n = `type`      v = `{TYPE}`

                        )->end(
                    )->end(
                )->end(
            )->end(

            )->tag( `Label`
                )->a( n = `text` v = `Add available built-in views to the example:`

            )->ele( `MultiComboBox`
                )->a( n = `selectionFinish` v = client->_event( val = `BUILT_IN_VIEWS` arg = `$event.getSource().getSelectedKeys().join(',')` )
                )->a( n = `width`           v = `230px`
                )->a( n = `placeholder`     v = `Choose built-in views`

                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `Hour`
                    )->a( n = `text` v = `Hour`
                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `Day`
                    )->a( n = `text` v = `Day`
                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `Month`
                    )->a( n = `text` v = `Month`
                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `Week`
                    )->a( n = `text` v = `1 week`
                )->tag( n = `Item` ns = `core`
                    )->a( n = `key`  v = `One Month`
                    )->a( n = `text` v = `1 month`

            )->end(

            )->tag( `Label`
                )->a( n = `text` v = `Add or remove custom views:`
            )->tag( `ToggleButton`
                )->a( n = `text` v = `Toggle custom views` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    " declared here, not inline at the ASSIGN below, so it can be UNASSIGNed
    " before each one
    FIELD-SYMBOLS <person> TYPE ty_s_person.
        DATA appt_title TYPE string.
          DATA temp3 TYPE string.
          DATA selected LIKE temp3.
        DATA temp4 TYPE i.
        DATA temp14 TYPE i.
        DATA temp1 TYPE i.
        DATA temp16 TYPE i.
        DATA iso_start TYPE string.
          DATA temp5 LIKE sy-subrc.
          DATA temp6 LIKE sy-tabix.
            DATA temp7 TYPE z2ui5_cl_smpc_app_537=>ty_s_special.
          DATA temp8 TYPE i.
          DATA temp15 TYPE i.
          DATA temp2 TYPE i.
          DATA temp17 TYPE i.
          DATA iso_end TYPE string.
          DATA temp9 TYPE ty_s_appointment.
          DATA appointment LIKE temp9.
          DATA temp10 TYPE i.
          DATA row_index LIKE temp10.
          DATA temp11 TYPE ty_t_int.
          DATA rows LIKE temp11.
            DATA person_sel LIKE LINE OF t_people.
                DATA temp12 LIKE LINE OF rows.
          DATA index LIKE LINE OF rows.
        DATA temp13 TYPE string_table.

    CASE client->get_event( ).

      WHEN `APPT_SELECT`.
        
        appt_title = client->get_event_arg( ).
        IF appt_title IS NOT INITIAL.
          
          IF client->get_event_arg( 2 ) = abap_true.
            temp3 = `selected`.
          ELSE.
            temp3 = `deselected`.
          ENDIF.
          
          selected = temp3.
          client->message_box_display(
              text = |'{ appt_title }' { selected }. \n Selected appointments: { client->get_event_arg( 3 ) }|
              type = `show` ).
        ELSE.
          client->message_box_display( text = |{ client->get_event_arg( 4 ) } Appointments selected|
                                       type = `show` ).
        ENDIF.

      WHEN `INTERVAL_SELECT`.
        
        temp4 = client->get_event_arg( 2 ).
        
        temp14 = client->get_event_arg( 3 ).
        
        temp1 = client->get_event_arg( 4 ).
        
        temp16 = client->get_event_arg( 5 ).
        
        iso_start = |{ client->get_event_arg( ) }-{ temp4 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
                          |-{ temp14 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
                          |T{ temp1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
                          |:{ temp16 WIDTH = 2 ALIGN = RIGHT PAD = '0' }:00|.

        IF view_key = `nonWorking`.
          " the special date toggles: first select marks it, the second clears it
          
          
          temp6 = sy-tabix.
          READ TABLE t_special WITH KEY start_at = iso_start TRANSPORTING NO FIELDS.
          temp5 = sy-subrc.
          sy-tabix = temp6.
          IF temp5 = 0.
            DELETE t_special WHERE start_at = iso_start.
          ELSE.
            
            CLEAR temp7.
            temp7-start_at = iso_start.
            temp7-type = `NonWorking`.
            INSERT temp7 INTO TABLE t_special.
          ENDIF.
        ELSE.
          
          temp8 = client->get_event_arg( 7 ).
          
          temp15 = client->get_event_arg( 8 ).
          
          temp2 = client->get_event_arg( 9 ).
          
          temp17 = client->get_event_arg( 10 ).
          
          iso_end = |{ client->get_event_arg( 6 ) }-{ temp8 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
                          |-{ temp15 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
                          |T{ temp2 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
                          |:{ temp17 WIDTH = 2 ALIGN = RIGHT PAD = '0' }:00|.
          
          CLEAR temp9.
          temp9-start_at = iso_start.
          temp9-end_at = iso_end.
          temp9-title = `new appointment`.
          temp9-type = `Type09`.
          temp9-aria = `None`.
          
          appointment = temp9.
          
          temp10 = client->get_event_arg( 11 ).
          
          row_index = temp10.
          " the selected rows are read from the model, not transported:
          " PlanningCalendarRow has a bindable `selected`, and a JS callback
          " (getSelectedRows().map(function...)) is not in the UI5 expression
          " grammar - it threw and lost the whole handler
          
          CLEAR temp11.
          
          rows = temp11.
          IF row_index >= 0.
            INSERT row_index INTO TABLE rows.
          ELSE.
            
            LOOP AT t_people INTO person_sel.
              IF person_sel-selected = abap_true.
                
                temp12 = sy-tabix - 1.
                INSERT temp12 INTO TABLE rows.
              ENDIF.
            ENDLOOP.
          ENDIF.
          " the row is addressed through a field symbol, not a table expression:
          " abaplint's downport leaves an itab[ ] TARGET of INSERT/DELETE in
          " place, and the 702 parser rejects it
          
          LOOP AT rows INTO index.
            " UNASSIGN first: a failed ASSIGN keeps the previous round's row
            UNASSIGN <person>.
            READ TABLE t_people INDEX index + 1 ASSIGNING <person>.
            IF <person> IS ASSIGNED.
              INSERT appointment INTO TABLE <person>-t_appointments.
            ENDIF.
          ENDLOOP.
        ENDIF.

      WHEN `BUILT_IN_VIEWS`.
        " handleSelectionFinish: the picked keys become the calendar's built-in views
        
        CLEAR temp13.
        t_built_in = temp13.
        IF client->get_event_arg( ) IS NOT INITIAL.
          SPLIT client->get_event_arg( ) AT `,` INTO TABLE t_built_in.
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.
    DATA temp14 LIKE t_people.
    DATA temp15 LIKE LINE OF temp14.
    DATA temp16 TYPE z2ui5_cl_smpc_app_537=>ty_t_int.
    DATA temp18 TYPE z2ui5_cl_smpc_app_537=>ty_t_int.
    DATA temp20 TYPE z2ui5_cl_smpc_app_537=>ty_t_appointment.
    DATA temp21 LIKE LINE OF temp20.
    DATA temp22 TYPE z2ui5_cl_smpc_app_537=>ty_t_header.
    DATA temp23 LIKE LINE OF temp22.
    DATA temp24 TYPE z2ui5_cl_smpc_app_537=>ty_t_int.
    DATA temp26 TYPE z2ui5_cl_smpc_app_537=>ty_t_int.
    DATA temp28 TYPE z2ui5_cl_smpc_app_537=>ty_t_appointment.
    DATA temp29 LIKE LINE OF temp28.
    DATA temp30 TYPE z2ui5_cl_smpc_app_537=>ty_t_header.
    DATA temp31 LIKE LINE OF temp30.

    start_date = `2017-02-08T08:00:00`.
    view_key   = `D`.
    group_mode = `Collapsed`.

    
    CLEAR temp14.
    
    temp15-pic = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/John_Miller.png`.
    temp15-name = `John Miller`.
    temp15-role = `team member`.
    
    CLEAR temp16.
    INSERT 5 INTO TABLE temp16.
    INSERT 6 INTO TABLE temp16.
    temp15-t_free_days = temp16.
    
    CLEAR temp18.
    INSERT 0 INTO TABLE temp18.
    INSERT 1 INTO TABLE temp18.
    INSERT 2 INTO TABLE temp18.
    INSERT 3 INTO TABLE temp18.
    INSERT 4 INTO TABLE temp18.
    INSERT 5 INTO TABLE temp18.
    INSERT 6 INTO TABLE temp18.
    INSERT 17 INTO TABLE temp18.
    INSERT 19 INTO TABLE temp18.
    INSERT 20 INTO TABLE temp18.
    INSERT 21 INTO TABLE temp18.
    INSERT 22 INTO TABLE temp18.
    INSERT 23 INTO TABLE temp18.
    temp15-t_free_hours = temp18.
    
    CLEAR temp20.
    
    CLEAR temp21.
    temp21-start_at = `2016-12-02T11:30:00`.
    temp21-end_at = `2016-12-02T13:30:00`.
    temp21-title = `Online Meeting`.
    temp21-type = `Type03`.
    temp21-tentative = abap_true.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-01-15T13:30:00`.
    temp21-end_at = `2017-01-29T17:30:00`.
    temp21-title = `Discussion with clients`.
    temp21-info = `online meeting`.
    temp21-type = `Type02`.
    temp21-tentative = abap_false.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-02-07T00:01:00`.
    temp21-end_at = `2017-02-07T23:59:00`.
    temp21-title = `Vacation`.
    temp21-type = `Type02`.
    temp21-tentative = abap_false.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-02-08T08:30:00`.
    temp21-end_at = `2017-02-08T15:00:00`.
    temp21-title = `Meeting`.
    temp21-type = `Type05`.
    temp21-tentative = abap_false.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-02-08T08:00:00`.
    temp21-end_at = `2017-02-08T17:00:00`.
    temp21-title = `Team meeting`.
    temp21-info = `room 106`.
    temp21-type = `Type01`.
    temp21-pic = `sap-icon://sap-ui5`.
    temp21-tentative = abap_false.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-02-09T07:30:00`.
    temp21-end_at = `2017-02-09T16:30:00`.
    temp21-title = `Meet Donna Moore`.
    temp21-info = `regular`.
    temp21-type = `Type08`.
    temp21-tentative = abap_false.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-02-10T00:00:00`.
    temp21-end_at = `2017-02-11T23:29:00`.
    temp21-title = `Private appointment`.
    temp21-type = `Type06`.
    temp21-tentative = abap_true.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-04-17T08:30:00`.
    temp21-end_at = `2017-04-17T15:30:00`.
    temp21-title = `Meet Max Mustermann`.
    temp21-type = `Type02`.
    temp21-tentative = abap_true.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-04-03T10:00:00`.
    temp21-end_at = `2017-04-03T12:00:00`.
    temp21-title = `Team meeting`.
    temp21-info = `room 1`.
    temp21-type = `Type01`.
    temp21-pic = `sap-icon://sap-ui5`.
    temp21-tentative = abap_false.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-03-04T11:30:00`.
    temp21-end_at = `0201-03-04T13:30:00`.
    temp21-title = `Online Meeting`.
    temp21-type = `Type03`.
    temp21-tentative = abap_true.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-01-15T13:30:00`.
    temp21-end_at = `2017-01-29T17:30:00`.
    temp21-title = `Discussion with clients`.
    temp21-info = `online meeting`.
    temp21-type = `Type02`.
    temp21-tentative = abap_false.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    CLEAR temp21.
    temp21-start_at = `2017-02-07T00:01:00`.
    temp21-end_at = `2017-02-07T23:59:00`.
    temp21-title = `Vacation`.
    temp21-type = `Type02`.
    temp21-tentative = abap_false.
    temp21-aria = `Dialog`.
    INSERT temp21 INTO TABLE temp20.
    temp15-t_appointments = temp20.
    
    CLEAR temp22.
    
    temp23-start_at = `2017-02-09T11:30:00`.
    temp23-end_at = `2017-02-09T14:00:00`.
    temp23-title = `Lunch`.
    temp23-type = `Type03`.
    INSERT temp23 INTO TABLE temp22.
    temp15-t_headers = temp22.
    INSERT temp15 INTO TABLE temp14.
    temp15-pic = `sap-icon://employee`.
    temp15-name = `Max Mustermann`.
    temp15-role = `team member`.
    
    CLEAR temp24.
    INSERT 0 INTO TABLE temp24.
    INSERT 6 INTO TABLE temp24.
    temp15-t_free_days = temp24.
    
    CLEAR temp26.
    INSERT 0 INTO TABLE temp26.
    INSERT 1 INTO TABLE temp26.
    INSERT 2 INTO TABLE temp26.
    INSERT 3 INTO TABLE temp26.
    INSERT 4 INTO TABLE temp26.
    INSERT 5 INTO TABLE temp26.
    INSERT 6 INTO TABLE temp26.
    INSERT 7 INTO TABLE temp26.
    INSERT 18 INTO TABLE temp26.
    INSERT 19 INTO TABLE temp26.
    INSERT 20 INTO TABLE temp26.
    INSERT 21 INTO TABLE temp26.
    INSERT 22 INTO TABLE temp26.
    INSERT 23 INTO TABLE temp26.
    temp15-t_free_hours = temp26.
    
    CLEAR temp28.
    
    CLEAR temp29.
    temp29-start_at = `2017-01-02T11:30:00`.
    temp29-end_at = `2017-01-02T13:30:00`.
    temp29-title = `Online Meeting`.
    temp29-type = `Type03`.
    temp29-tentative = abap_true.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-01-15T13:30:00`.
    temp29-end_at = `2017-01-29T11:30:00`.
    temp29-title = `Meeting with managers`.
    temp29-info = `online meeting`.
    temp29-type = `Type02`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-02-05T00:01:00`.
    temp29-end_at = `2017-02-05T23:59:00`.
    temp29-title = `Education`.
    temp29-type = `Type03`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-02-08T08:00:00`.
    temp29-end_at = `2017-02-08T17:00:00`.
    temp29-title = `Team meeting`.
    temp29-info = `room 106`.
    temp29-type = `Type01`.
    temp29-pic = `sap-icon://sap-ui5`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-02-09T10:00:00`.
    temp29-end_at = `2017-02-09T16:30:00`.
    temp29-title = `Meeting`.
    temp29-info = `phone`.
    temp29-type = `Type02`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-02-10T00:00:00`.
    temp29-end_at = `2017-01-31T23:59:00`.
    temp29-title = `Blocker`.
    temp29-type = `Type04`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-02-10T07:30:00`.
    temp29-end_at = `2017-02-10T16:30:00`.
    temp29-title = `Meet Donna Moore`.
    temp29-info = `regular`.
    temp29-type = `Type08`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-02-12T00:01:00`.
    temp29-end_at = `2017-02-12T23:59:00`.
    temp29-title = `New Product`.
    temp29-info = `room 105`.
    temp29-type = `Type04`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-03-02T11:30:00`.
    temp29-end_at = `2017-03-02T13:30:00`.
    temp29-title = `Online Meeting`.
    temp29-type = `Type03`.
    temp29-tentative = abap_true.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-03-15T13:30:00`.
    temp29-end_at = `2017-03-29T17:30:00`.
    temp29-title = `Meeting with managers`.
    temp29-info = `online meeting`.
    temp29-type = `Type02`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-05-02T11:30:00`.
    temp29-end_at = `2017-05-02T13:30:00`.
    temp29-title = `Online Meeting`.
    temp29-type = `Type03`.
    temp29-tentative = abap_true.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-03-15T13:30:00`.
    temp29-end_at = `2017-03-29T17:30:00`.
    temp29-title = `Discussion with clients`.
    temp29-info = `online meeting`.
    temp29-type = `Type02`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    CLEAR temp29.
    temp29-start_at = `2017-04-07T00:01:00`.
    temp29-end_at = `2017-04-07T23:59:00`.
    temp29-title = `Vacation`.
    temp29-type = `Type02`.
    temp29-tentative = abap_false.
    temp29-aria = `Dialog`.
    INSERT temp29 INTO TABLE temp28.
    temp15-t_appointments = temp28.
    
    CLEAR temp30.
    
    temp31-start_at = `2017-02-14T00:00:00`.
    temp31-end_at = `2017-02-14T23:59:00`.
    temp31-title = `Valentine's Day`.
    temp31-type = `Type03`.
    INSERT temp31 INTO TABLE temp30.
    temp15-t_headers = temp30.
    INSERT temp15 INTO TABLE temp14.
    t_people = temp14.

  ENDMETHOD.

ENDCLASS.
