" @keywords planningcalendar planning calendar sap.m planningcalendarmodifyappointments vbox title button planningcalendarrow calendarappointment responsivepopover simpleform
" @summary PlanningCalendar containing sap.m.Popover with information for the appointments and sap.m.Dialog for creating a new appointment. Note: Illustrates how the PlanningCalendar can be used in combination with the sap.m.Popover and sap.m.
" @origin sap.m.sample.PlanningCalendarModifyAppointments - https://sdk.openui5.org/entity/sap.m.PlanningCalendar/sample/sap.m.sample.PlanningCalendarModifyAppointments (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_547 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

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
        selected  TYPE abap_bool,
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
        t_appointments TYPE ty_t_appointment,
        t_headers      TYPE ty_t_header,
      END OF ty_s_person.
    DATA t_people TYPE STANDARD TABLE OF ty_s_person WITH DEFAULT KEY.

    DATA start_date TYPE string.

    " the details popover and the create/edit dialog, folded to fields
    DATA sel_title     TYPE string.
    DATA sel_info      TYPE string.
    DATA sel_start     TYPE string.
    DATA sel_end       TYPE string.
    DATA d_person      TYPE string.
    DATA d_interval    TYPE abap_bool.
    DATA d_title       TYPE string.
    DATA d_info        TYPE string.
    DATA d_start       TYPE string.
    DATA d_end         TYPE string.
    DATA d_start_state TYPE string.

  PROTECTED SECTION.
    DATA client    TYPE REF TO z2ui5_if_client.
    DATA sel_row   TYPE i.
    DATA sel_index TYPE i.
    DATA d_mode    TYPE string.

    METHODS view_display.
    METHODS popup_details_display.
    METHODS popup_create_display.
    METHODS on_event.
    METHODS appointment_edit
      IMPORTING target_row TYPE i.
    METHODS iso_of
      IMPORTING first         TYPE i
      RETURNING VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_547 IMPLEMENTATION.

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

    " the calendar date properties are typed "object" and demand a real JS Date;
    " the model keeps ISO strings and Formatter.DateCreateObject converts them
    
    CLEAR temp1.
    INSERT `${$parameters>/appointment} ? ${$parameters>/appointment}.getBindingContext().getPath() : ''` INTO TABLE temp1.
    INSERT `${$parameters>/appointment} ? ${$parameters>/appointment}.getSelected() : false` INTO TABLE temp1.
    INSERT `${$parameters>/appointments} ? ${$parameters>/appointments}.length : 0` INTO TABLE temp1.
    INSERT `${$parameters>/appointments} ? ${$parameters>/appointments}[0].getType() : ''` INTO TABLE temp1.
    
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
    INSERT `${$parameters>/row} ? $event.oSource.indexOfRow(${$parameters>/row}) : -1` INTO TABLE temp2.
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
                )->a( n = `rows`                      v = client->_bind( t_people )
                )->a( n = `appointmentsVisualization` v = `Filled`
                " handleAppointmentSelect opens the details popover on a single
                " appointment, or the group popover on a collapsed group
                )->a( n = `appointmentSelect`         v = client->_event(
                                  val   = `APPT_SELECT`
                                  t_arg = temp1 )
                )->a( n = `showEmptyIntervalHeaders`  v = `false`
                " handleAppointmentAddWithContext opens the same dialog pre-set to
                " the selected interval
                )->a( n = `intervalSelect`            v = client->_event(
                                     val   = `INTERVAL_SELECT`
                                     t_arg = temp2 )

                )->ele( `toolbarContent`
                    )->tag( `Title`
                        )->a( n = `text`       v = `Title`
                        )->a( n = `titleStyle` v = `H4`
                    )->tag( `Button`
                        )->a( n = `id`      v = `addButton`
                        )->a( n = `icon`    v = `sap-icon://add`
                        )->a( n = `press`   v = client->_event( `APPT_CREATE` )
                        )->a( n = `tooltip` v = `Add`

                )->end(

                )->ele( `rows`
                    )->ele( `PlanningCalendarRow`
                        )->a( n = `icon`            v = `{PIC}`
                        )->a( n = `title`           v = `{NAME}`
                        )->a( n = `text`            v = `{ROLE}`
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
                                )->a( n = `selected`     v = `{SELECTED}`
                                )->a( n = `ariaHasPopup` v = `{ARIA}`

                        )->end(
                        )->ele( `intervalHeaders`
                            )->tag( n = `CalendarAppointment` ns = `u`
                                )->a( n = `startDate` v = `{ path: 'START_AT', formatter: 'Formatter.DateCreateObject' }`
                                )->a( n = `endDate`   v = `{ path: 'END_AT', formatter: 'Formatter.DateCreateObject' }`
                                )->a( n = `icon`      v = `{PIC}`
                                )->a( n = `title`     v = `{TITLE}`
                                )->a( n = `type`      v = `{TYPE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD popup_details_display.

    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `ResponsivePopover`
            )->a( n = `id`        v = `detailsPopover`
            )->a( n = `title`     v = client->_bind( sel_title )
            )->a( n = `class`     v = `sapUiContentPadding`
            )->a( n = `placement` v = `Auto`

            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Edit`
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->_event( `EDIT` )

            )->end(
            )->ele( `endButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Delete`
                    )->a( n = `press` v = client->_event( `DELETE` )

            )->end(

            )->ele( n = `SimpleForm` ns = `form`
                )->a( n = `editable`                v = `false`
                )->a( n = `layout`                  v = `ResponsiveGridLayout`
                )->a( n = `singleContainerFullSize` v = `false`

                )->tag( `Label`
                    )->a( n = `text`     v = `Additional information`
                    )->a( n = `labelFor` v = `moreInfoText`
                )->tag( `Text`
                    )->a( n = `id`   v = `moreInfoText`
                    )->a( n = `text` v = client->_bind( sel_info )
                )->tag( `Label`
                    )->a( n = `text`     v = `From`
                    )->a( n = `labelFor` v = `startDateText`
                )->tag( `Text`
                    )->a( n = `id`   v = `startDateText`
                    )->a( n = `text` v = client->_bind( sel_start )
                )->tag( `Label`
                    )->a( n = `text`     v = `To`
                    )->a( n = `labelFor` v = `endDateText`
                )->tag( `Text`
                    )->a( n = `id`   v = `endDateText`
                    )->a( n = `text` v = client->_bind( sel_end ) ).

    client->popover_display( xml = popup->stringify( ) by_id = `PC1` ).

  ENDMETHOD.


  METHOD popup_create_display.

    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    popup = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `Dialog`
            )->a( n = `id` v = `createDialog`

            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Save`
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->_event( `DIALOG_SAVE` )

            )->end(
            )->ele( `endButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Cancel`
                    )->a( n = `press` v = client->_event( `DIALOG_CANCEL` )

            )->end(

            )->ele( n = `VerticalLayout` ns = `l`
                )->a( n = `class` v = `sapUiContentPadding`
                )->a( n = `width` v = `100%`

                " handleAppointmentTypeChange only re-reads the checkbox; the flag
                " is bound two-way here, so the select wire is dropped
                )->tag( `CheckBox`
                    )->a( n = `id`       v = `isIntervalAppointment`
                    )->a( n = `text`     v = `Interval appointment`
                    )->a( n = `selected` v = client->_bind( d_interval )
                )->tag( `Label`
                    )->a( n = `text`     v = `Select person: `
                    )->a( n = `labelFor` v = `selectPerson`

                )->ele( `Select`
                    )->a( n = `id`             v = `selectPerson`
                    )->a( n = `forceSelection` v = `false`
                    )->a( n = `width`          v = `100%`
                    )->a( n = `items`          v = client->_bind( t_people )
                    )->a( n = `selectedKey`    v = client->_bind( d_person )

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{NAME}`
                        )->a( n = `text` v = `{NAME}`

                )->end(

                )->tag( `Label`
                    )->a( n = `text`     v = `Title: `
                    )->a( n = `labelFor` v = `inputTitle`
                )->tag( `Input`
                    )->a( n = `id`    v = `inputTitle`
                    )->a( n = `value` v = client->_bind( d_title )
                )->tag( `Label`
                    )->a( n = `text`     v = `Start date: `
                    )->a( n = `labelFor` v = `startDate`
                " handleCreateChange rejects an end date at or before the start
                )->tag( `DateTimePicker`
                    )->a( n = `id`             v = `startDate`
                    )->a( n = `displayFormat`  v = `short`
                    " the ORIGINAL binds no value at all - it works in Date objects
                    " through setDateValue/getDateValue - so the string binding is the
                    " port's own and the port owes the format. Without it the picker
                    " writes a LOCALE string back (measured: "Jan 10, 2017, 8:00:00 AM"),
                    " which breaks CREATE_CHANGE's `d_end <= d_start` string compare and
                    " lands a non-ISO value in t_appointments beside ISO neighbours
                    )->a( n = `valueFormat`    v = `yyyy-MM-dd'T'HH:mm:ss`
                    )->a( n = `required`       v = `true`
                    )->a( n = `value`          v = client->_bind( d_start )
                    )->a( n = `valueState`     v = client->_bind( d_start_state )
                    )->a( n = `valueStateText` v = `Start date should be before End date`
                    )->a( n = `change`         v = client->_event( `CREATE_CHANGE` )
                )->tag( `Label`
                    )->a( n = `text`     v = `End date: `
                    )->a( n = `labelFor` v = `endDate`
                )->tag( `DateTimePicker`
                    )->a( n = `id`            v = `endDate`
                    )->a( n = `displayFormat` v = `short`
                    " see startDate above - the compare is only meaningful while both
                    " sides stay lexicographically sortable ISO
                    )->a( n = `valueFormat`   v = `yyyy-MM-dd'T'HH:mm:ss`
                    )->a( n = `required`      v = `true`
                    )->a( n = `value`         v = client->_bind( d_end )
                    )->a( n = `change`        v = client->_event( `CREATE_CHANGE` )
                )->tag( `Label`
                    )->a( n = `text`     v = `More information: `
                    )->a( n = `labelFor` v = `moreInfo`
                )->tag( `Input`
                    )->a( n = `id`    v = `moreInfo`
                    )->a( n = `value` v = client->_bind( d_info ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA path TYPE string.
          DATA count TYPE string.
          DATA first_type TYPE string.
          DATA differ LIKE abap_false.
          DATA person_sel LIKE LINE OF t_people.
            DATA appt_sel LIKE LINE OF person_sel-t_appointments.
          DATA temp3 TYPE string.
          DATA parts TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
          FIELD-SYMBOLS <temp4> LIKE LINE OF parts.
          DATA temp5 LIKE sy-tabix.
          FIELD-SYMBOLS <temp6> LIKE LINE OF parts.
          DATA temp7 LIKE sy-tabix.
          DATA person TYPE z2ui5_cl_smpc_app_547=>ty_s_person.
            DATA appointment TYPE z2ui5_cl_smpc_app_547=>ty_s_appointment.
            FIELD-SYMBOLS <temp5> LIKE LINE OF person-t_appointments.
            DATA temp6 LIKE sy-tabix.
        DATA temp8 TYPE i.
        DATA row_index LIKE temp8.
        DATA temp9 TYPE string.
          FIELD-SYMBOLS <temp7> LIKE LINE OF t_people.
          DATA temp15 LIKE sy-tabix.
        DATA temp10 TYPE string.
          FIELD-SYMBOLS <temp16> LIKE LINE OF t_people.
          DATA temp17 LIKE sy-tabix.
        FIELD-SYMBOLS <person> TYPE z2ui5_cl_smpc_app_547=>ty_s_person.
        DATA temp11 TYPE string.
          DATA temp12 TYPE i.
          DATA temp18 LIKE sy-subrc.
          DATA temp19 LIKE sy-subrc.
            DATA temp20 LIKE sy-subrc.
            DATA temp21 LIKE sy-subrc.
          DATA target_row LIKE temp12.
            FIELD-SYMBOLS <target> TYPE z2ui5_cl_smpc_app_547=>ty_s_person.
                DATA temp13 TYPE z2ui5_cl_smpc_app_547=>ty_s_header.
                DATA temp14 TYPE z2ui5_cl_smpc_app_547=>ty_s_appointment.

    CASE client->get_event( ).

      WHEN `APPT_SELECT`.
        
        path = client->get_event_arg( ).
        IF path IS INITIAL.
          " _handleGroupAppointments: a collapsed GROUP was clicked
          
          count  = client->get_event_arg( 3 ).
          " whether the selected appointments differ in type is computed here, from
          " the bound `selected` flags - the client-side .some(function(a){...}) it
          " replaced is not in the UI5 expression grammar and threw
          
          first_type = ``.
          
          differ = abap_false.
          
          LOOP AT t_people INTO person_sel.
            
            LOOP AT person_sel-t_appointments INTO appt_sel WHERE selected = abap_true.
              IF first_type IS INITIAL.
                first_type = appt_sel-type.
              ELSEIF appt_sel-type <> first_type.
                differ = abap_true.
              ENDIF.
            ENDLOOP.
          ENDLOOP.
          
          IF differ = abap_true.
            temp3 = |{ count } Appointments of different types selected|.
          ELSE.
            temp3 = |{ count } Appointments of the same { client->get_event_arg( 4 ) } selected|.
          ENDIF.
          client->message_toast_display(
              temp3 ).
        ELSEIF client->get_event_arg( 2 ) <> abap_true.
          client->popover_destroy( ).
        ELSE.
          
          SPLIT path AT `/` INTO TABLE parts.
          DELETE parts WHERE table_line IS INITIAL.
          
          
          temp5 = sy-tabix.
          READ TABLE parts INDEX 2 ASSIGNING <temp4>.
          sy-tabix = temp5.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          sel_row   = <temp4>.
          
          
          temp7 = sy-tabix.
          READ TABLE parts INDEX lines( parts ) ASSIGNING <temp6>.
          sy-tabix = temp7.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          sel_index = <temp6>.
          
          READ TABLE t_people INDEX sel_row + 1 INTO person.
          IF sy-subrc = 0 AND sel_index >= 0 AND sel_index < lines( person-t_appointments ).
            
            
            
            temp6 = sy-tabix.
            READ TABLE person-t_appointments INDEX sel_index + 1 ASSIGNING <temp5>.
            sy-tabix = temp6.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            appointment = <temp5>.
            sel_title = appointment-title.
            sel_info  = appointment-info.
            sel_start = appointment-start_at.
            sel_end   = appointment-end_at.
            popup_details_display( ).
          ENDIF.
        ENDIF.

      WHEN `APPT_CREATE`.
        " handleAppointmentCreate opens the dialog on the calendar's start date
        d_mode        = `create`.
        d_person      = ``.
        d_interval    = abap_false.
        d_title       = ``.
        d_info        = ``.
        d_start       = start_date.
        d_end         = start_date.
        d_start_state = `None`.
        popup_create_display( ).

      WHEN `INTERVAL_SELECT`.
        " handleAppointmentAddWithContext keeps the clicked interval and row
        d_mode        = `create_with_context`.
        
        temp8 = client->get_event_arg( 11 ).
        
        row_index = temp8.
        
        IF row_index >= 0 AND row_index < lines( t_people ).
          
          
          temp15 = sy-tabix.
          READ TABLE t_people INDEX row_index + 1 ASSIGNING <temp7>.
          sy-tabix = temp15.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          temp9 = <temp7>-name.
        ELSE.
          temp9 = ``.
        ENDIF.
        d_person      = temp9.
        d_interval    = abap_false.
        d_title       = ``.
        d_info        = ``.
        d_start       = iso_of( 1 ).
        d_end         = iso_of( 6 ).
        d_start_state = `None`.
        popup_create_display( ).

      WHEN `EDIT`.
        " handleEditButton closes the popover and opens the dialog on the row
        client->popover_destroy( ).
        d_mode        = `edit_appointment`.
        
        IF sel_row >= 0 AND sel_row < lines( t_people ).
          
          
          temp17 = sy-tabix.
          READ TABLE t_people INDEX sel_row + 1 ASSIGNING <temp16>.
          sy-tabix = temp17.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          temp10 = <temp16>-name.
        ELSE.
          temp10 = ``.
        ENDIF.
        d_person      = temp10.
        d_interval    = abap_false.
        d_title       = sel_title.
        d_info        = sel_info.
        d_start       = sel_start.
        d_end         = sel_end.
        d_start_state = `None`.
        popup_create_display( ).

      WHEN `DELETE`.
        " handleDeleteAppointment removes the appointment behind the popover
        
        READ TABLE t_people INDEX sel_row + 1 ASSIGNING <person>.
        IF sy-subrc = 0 AND sel_index >= 0 AND sel_index < lines( <person>-t_appointments ).
          DELETE <person>-t_appointments INDEX sel_index + 1.
        ENDIF.
        client->popover_destroy( ).

      WHEN `CREATE_CHANGE`.
        " _validateDateTimePicker: the end date has to be after the start date
        
        IF d_start IS NOT INITIAL AND d_end IS NOT INITIAL AND d_end <= d_start.
          temp11 = `Error`.
        ELSE.
          temp11 = `None`.
        ENDIF.
        d_start_state = temp11.

      WHEN `DIALOG_SAVE`.
        IF d_start_state <> `Error`.
          
          
          
          temp19 = sy-subrc.
          READ TABLE t_people WITH KEY name = d_person TRANSPORTING NO FIELDS.
          temp18 = sy-subrc.
          sy-subrc = temp19.
          IF temp18 = 0.
            
            
            temp21 = sy-subrc.
            READ TABLE t_people WITH KEY name = d_person TRANSPORTING NO FIELDS.
            temp20 = sy-tabix.
            sy-subrc = temp21.
            temp12 = temp20 - 1.
          ELSE.
            temp12 = 0.
          ENDIF.
          
          target_row = temp12.
          IF d_mode = `edit_appointment`.
            appointment_edit( target_row ).
          ELSE.
            " _addNewAppointment appends to the picked person's appointments, or
            " to their interval HEADERS when the checkbox is set
            
            READ TABLE t_people INDEX target_row + 1 ASSIGNING <target>.
            IF sy-subrc = 0.
              IF d_interval = abap_true.
                
                CLEAR temp13.
                temp13-title = d_title.
                temp13-start_at = d_start.
                temp13-end_at = d_end.
                temp13-type = `Type01`.
                INSERT temp13 INTO TABLE <target>-t_headers.
              ELSE.
                
                CLEAR temp14.
                temp14-title = d_title.
                temp14-info = d_info.
                temp14-start_at = d_start.
                temp14-end_at = d_end.
                temp14-type = `Type01`.
                temp14-aria = `Dialog`.
                INSERT temp14 INTO TABLE <target>-t_appointments.
              ENDIF.
            ENDIF.
          ENDIF.
          client->popup_destroy( ).
        ENDIF.

      WHEN `DIALOG_CANCEL`.
        client->popup_destroy( ).

    ENDCASE.

  ENDMETHOD.


  METHOD appointment_edit.

    " _editAppointment rewrites the row in place, moving it to the picked owner
    " when the Select changed
    FIELD-SYMBOLS <source> TYPE z2ui5_cl_smpc_app_547=>ty_s_person.
    DATA edited TYPE z2ui5_cl_smpc_app_547=>ty_s_appointment.
    FIELD-SYMBOLS <temp22> LIKE LINE OF <source>-t_appointments.
    DATA temp23 LIKE sy-tabix.
      FIELD-SYMBOLS <temp15> LIKE LINE OF <source>-t_appointments.
      DATA temp16 LIKE sy-tabix.
    FIELD-SYMBOLS <owner> TYPE z2ui5_cl_smpc_app_547=>ty_s_person.
    READ TABLE t_people INDEX sel_row + 1 ASSIGNING <source>.
    IF sy-subrc <> 0 OR sel_index < 0 OR sel_index >= lines( <source>-t_appointments ).
      RETURN.
    ENDIF.

    
    
    
    temp23 = sy-tabix.
    READ TABLE <source>-t_appointments INDEX sel_index + 1 ASSIGNING <temp22>.
    sy-tabix = temp23.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    edited = <temp22>.
    edited-title    = d_title.
    edited-info     = d_info.
    edited-start_at = d_start.
    edited-end_at   = d_end.

    IF target_row = sel_row.
      
      
      temp16 = sy-tabix.
      READ TABLE <source>-t_appointments INDEX sel_index + 1 ASSIGNING <temp15>.
      sy-tabix = temp16.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      <temp15> = edited.
      RETURN.
    ENDIF.

    DELETE <source>-t_appointments INDEX sel_index + 1.
    
    READ TABLE t_people INDEX target_row + 1 ASSIGNING <owner>.
    IF sy-subrc = 0.
      INSERT edited INTO TABLE <owner>-t_appointments.
    ENDIF.

  ENDMETHOD.


  METHOD iso_of.

    " five consecutive event arguments (year, month, day, hour, minute) as one
    " ISO string - the parts travel LOCAL, so no timezone shifts the day
    DATA temp17 TYPE i.
    DATA temp24 TYPE i.
    DATA temp1 TYPE i.
    DATA temp2 TYPE i.
    temp17 = client->get_event_arg( first + 1 ).
    
    temp24 = client->get_event_arg( first + 2 ).
    
    temp1 = client->get_event_arg( first + 3 ).
    
    temp2 = client->get_event_arg( first + 4 ).
    result = |{ client->get_event_arg( first ) }| &&
             |-{ temp17 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
             |-{ temp24 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
             |T{ temp1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
             |:{ temp2 WIDTH = 2 ALIGN = RIGHT PAD = '0' }:00|.

  ENDMETHOD.


  METHOD model_init.
    DATA temp18 LIKE t_people.
    DATA temp19 LIKE LINE OF temp18.
    DATA temp25 TYPE z2ui5_cl_smpc_app_547=>ty_t_appointment.
    DATA temp26 LIKE LINE OF temp25.
    DATA temp27 TYPE z2ui5_cl_smpc_app_547=>ty_t_header.
    DATA temp28 LIKE LINE OF temp27.
    DATA temp29 TYPE z2ui5_cl_smpc_app_547=>ty_t_appointment.
    DATA temp30 LIKE LINE OF temp29.
    DATA temp31 TYPE z2ui5_cl_smpc_app_547=>ty_t_header.
    DATA temp32 LIKE LINE OF temp31.
    DATA temp33 TYPE z2ui5_cl_smpc_app_547=>ty_t_appointment.
    DATA temp34 LIKE LINE OF temp33.
    DATA temp35 TYPE z2ui5_cl_smpc_app_547=>ty_t_header.
    DATA temp36 LIKE LINE OF temp35.

    start_date    = `2017-01-15T08:00:00`.
    sel_row       = -1.
    sel_index     = -1.
    d_mode        = `create`.
    d_start_state = `None`.

    
    CLEAR temp18.
    
    temp19-pic = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/John_Miller.png`.
    temp19-name = `John Miller`.
    temp19-role = `team member`.
    
    CLEAR temp25.
    
    CLEAR temp26.
    temp26-start_at = `2017-01-08T08:30:00`.
    temp26-end_at = `2017-01-08T09:30:00`.
    temp26-title = `Meet Max Mustermann`.
    temp26-type = `Type02`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-11T10:00:00`.
    temp26-end_at = `2017-01-11T12:00:00`.
    temp26-title = `Team meeting`.
    temp26-info = `room 1`.
    temp26-type = `Type01`.
    temp26-pic = `sap-icon://sap-ui5`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-12T11:30:00`.
    temp26-end_at = `2017-01-12T13:30:00`.
    temp26-title = `Lunch`.
    temp26-info = `canteen`.
    temp26-type = `Type03`.
    temp26-tentative = abap_true.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-15T08:30:00`.
    temp26-end_at = `2017-01-15T09:30:00`.
    temp26-title = `Meet Max Mustermann`.
    temp26-type = `Type02`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-15T10:00:00`.
    temp26-end_at = `2017-01-15T12:00:00`.
    temp26-title = `Team meeting`.
    temp26-info = `room 1`.
    temp26-type = `Type01`.
    temp26-pic = `sap-icon://sap-ui5`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-15T11:30:00`.
    temp26-end_at = `2017-01-15T13:30:00`.
    temp26-title = `Lunch`.
    temp26-info = `canteen`.
    temp26-type = `Type03`.
    temp26-tentative = abap_true.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-15T13:30:00`.
    temp26-end_at = `2017-01-15T17:30:00`.
    temp26-title = `Discussion with clients`.
    temp26-info = `online meeting`.
    temp26-type = `Type02`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-16T04:00:00`.
    temp26-end_at = `2017-01-16T22:30:00`.
    temp26-title = `Discussion of the plan`.
    temp26-info = `Online meeting`.
    temp26-type = `Type04`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-18T08:30:00`.
    temp26-end_at = `2017-01-18T09:30:00`.
    temp26-title = `Meeting with the manager`.
    temp26-type = `Type02`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-18T11:30:00`.
    temp26-end_at = `2017-01-18T13:30:00`.
    temp26-title = `Lunch`.
    temp26-info = `canteen`.
    temp26-type = `Type03`.
    temp26-tentative = abap_true.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-18T01:00:00`.
    temp26-end_at = `2017-01-18T22:00:00`.
    temp26-title = `Team meeting`.
    temp26-info = `regular`.
    temp26-type = `Type01`.
    temp26-pic = `sap-icon://sap-ui5`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-21T00:30:00`.
    temp26-end_at = `2017-01-21T23:30:00`.
    temp26-title = `New Product`.
    temp26-info = `room 105`.
    temp26-type = `Type03`.
    temp26-tentative = abap_true.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-25T11:30:00`.
    temp26-end_at = `2017-01-25T13:30:00`.
    temp26-title = `Lunch`.
    temp26-type = `Type01`.
    temp26-tentative = abap_true.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-29T10:00:00`.
    temp26-end_at = `2017-01-29T12:00:00`.
    temp26-title = `Team meeting`.
    temp26-info = `room 1`.
    temp26-type = `Type01`.
    temp26-pic = `sap-icon://sap-ui5`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-30T08:30:00`.
    temp26-end_at = `2017-01-30T09:30:00`.
    temp26-title = `Meet Max Mustermann`.
    temp26-type = `Type02`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-30T10:00:00`.
    temp26-end_at = `2017-01-30T12:00:00`.
    temp26-title = `Team meeting`.
    temp26-info = `room 1`.
    temp26-type = `Type01`.
    temp26-pic = `sap-icon://sap-ui5`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-30T11:30:00`.
    temp26-end_at = `2017-01-30T13:30:00`.
    temp26-title = `Lunch`.
    temp26-type = `Type03`.
    temp26-tentative = abap_true.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-30T13:30:00`.
    temp26-end_at = `2017-01-30T17:30:00`.
    temp26-title = `Discussion with clients`.
    temp26-type = `Type02`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-01-31T10:00:00`.
    temp26-end_at = `2017-01-31T11:30:00`.
    temp26-title = `Discussion of the plan`.
    temp26-info = `Online meeting`.
    temp26-type = `Type04`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-02-03T08:30:00`.
    temp26-end_at = `2017-02-13T09:30:00`.
    temp26-title = `Meeting with the manager`.
    temp26-type = `Type02`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-02-04T10:00:00`.
    temp26-end_at = `2017-02-04T12:00:00`.
    temp26-title = `Team meeting`.
    temp26-info = `room 1`.
    temp26-type = `Type01`.
    temp26-pic = `sap-icon://sap-ui5`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    CLEAR temp26.
    temp26-start_at = `2017-03-30T10:00:00`.
    temp26-end_at = `2017-06-02T12:00:00`.
    temp26-title = `Working out of the building`.
    temp26-type = `Type07`.
    temp26-pic = `sap-icon://sap-ui5`.
    temp26-tentative = abap_false.
    temp26-aria = `Dialog`.
    INSERT temp26 INTO TABLE temp25.
    temp19-t_appointments = temp25.
    
    CLEAR temp27.
    
    temp28-start_at = `2017-01-15T08:00:00`.
    temp28-end_at = `2017-01-15T10:00:00`.
    temp28-title = `Reminder`.
    temp28-type = `Type06`.
    INSERT temp28 INTO TABLE temp27.
    temp28-start_at = `2017-01-15T17:00:00`.
    temp28-end_at = `2017-01-15T19:00:00`.
    temp28-title = `Reminder`.
    temp28-type = `Type06`.
    INSERT temp28 INTO TABLE temp27.
    temp28-start_at = `2017-09-01T00:00:00`.
    temp28-end_at = `2017-11-30T23:59:00`.
    temp28-title = `New quarter`.
    temp28-type = `Type10`.
    INSERT temp28 INTO TABLE temp27.
    temp28-start_at = `2018-02-01T00:00:00`.
    temp28-end_at = `2018-04-30T23:59:00`.
    temp28-title = `New quarter`.
    temp28-type = `Type10`.
    INSERT temp28 INTO TABLE temp27.
    temp19-t_headers = temp27.
    INSERT temp19 INTO TABLE temp18.
    temp19-pic = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/Donna_Moore.jpg`.
    temp19-name = `Donna Moore`.
    temp19-role = `team member`.
    
    CLEAR temp29.
    
    CLEAR temp30.
    temp30-start_at = `2017-01-10T18:00:00`.
    temp30-end_at = `2017-01-10T19:10:00`.
    temp30-title = `Discussion of the plan`.
    temp30-info = `Online meeting`.
    temp30-type = `Type04`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-01-09T10:00:00`.
    temp30-end_at = `2017-01-13T12:00:00`.
    temp30-title = `Workshop out of the country`.
    temp30-type = `Type07`.
    temp30-pic = `sap-icon://sap-ui5`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-01-15T08:00:00`.
    temp30-end_at = `2017-01-15T09:30:00`.
    temp30-title = `Discussion of the plan`.
    temp30-info = `Online meeting`.
    temp30-type = `Type04`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-01-15T10:00:00`.
    temp30-end_at = `2017-01-15T12:00:00`.
    temp30-title = `Team meeting`.
    temp30-info = `room 1`.
    temp30-type = `Type01`.
    temp30-pic = `sap-icon://sap-ui5`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-01-15T18:00:00`.
    temp30-end_at = `2017-01-15T19:10:00`.
    temp30-title = `Discussion of the plan`.
    temp30-info = `Online meeting`.
    temp30-type = `Type04`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-01-16T10:00:00`.
    temp30-end_at = `2017-01-31T12:00:00`.
    temp30-title = `Workshop out of the country`.
    temp30-type = `Type07`.
    temp30-pic = `sap-icon://sap-ui5`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2018-01-01T00:00:00`.
    temp30-end_at = `2018-03-31T23:59:00`.
    temp30-title = `New quarter`.
    temp30-type = `Type10`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-02-11T10:00:00`.
    temp30-end_at = `2017-03-20T12:00:00`.
    temp30-title = `Team collaboration`.
    temp30-info = `room 1`.
    temp30-type = `Type01`.
    temp30-pic = `sap-icon://sap-ui5`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-04-01T10:00:00`.
    temp30-end_at = `2017-05-01T12:00:00`.
    temp30-title = `Workshop out of the country`.
    temp30-type = `Type07`.
    temp30-pic = `sap-icon://sap-ui5`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-05-01T10:00:00`.
    temp30-end_at = `2017-05-31T12:00:00`.
    temp30-title = `Out of the office`.
    temp30-type = `Type08`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    CLEAR temp30.
    temp30-start_at = `2017-08-01T00:00:00`.
    temp30-end_at = `2017-08-31T23:59:00`.
    temp30-title = `Vacation`.
    temp30-info = `out of office`.
    temp30-type = `Type04`.
    temp30-tentative = abap_false.
    temp30-aria = `Dialog`.
    INSERT temp30 INTO TABLE temp29.
    temp19-t_appointments = temp29.
    
    CLEAR temp31.
    
    temp32-start_at = `2017-01-15T09:00:00`.
    temp32-end_at = `2017-01-15T10:00:00`.
    temp32-title = `Payment reminder`.
    temp32-type = `Type06`.
    INSERT temp32 INTO TABLE temp31.
    temp32-start_at = `2017-01-15T16:30:00`.
    temp32-end_at = `2017-01-15T18:00:00`.
    temp32-title = `Private appointment`.
    temp32-type = `Type06`.
    INSERT temp32 INTO TABLE temp31.
    temp19-t_headers = temp31.
    INSERT temp19 INTO TABLE temp18.
    temp19-pic = `sap-icon://employee`.
    temp19-name = `Max Mustermann`.
    temp19-role = `team member`.
    
    CLEAR temp33.
    
    CLEAR temp34.
    temp34-start_at = `2017-01-15T08:30:00`.
    temp34-end_at = `2017-01-15T09:30:00`.
    temp34-title = `Meet John Miller`.
    temp34-type = `Type02`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-15T10:00:00`.
    temp34-end_at = `2017-01-15T12:00:00`.
    temp34-title = `Team meeting`.
    temp34-info = `room 1`.
    temp34-type = `Type01`.
    temp34-pic = `sap-icon://sap-ui5`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-15T13:00:00`.
    temp34-end_at = `2017-01-15T16:00:00`.
    temp34-title = `Discussion with clients`.
    temp34-info = `online`.
    temp34-type = `Type02`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-16T00:00:00`.
    temp34-end_at = `2017-01-16T23:59:00`.
    temp34-title = `Vacation`.
    temp34-info = `out of office`.
    temp34-type = `Type08`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-17T01:00:00`.
    temp34-end_at = `2017-01-18T22:00:00`.
    temp34-title = `Workshop`.
    temp34-info = `regular`.
    temp34-type = `Type08`.
    temp34-pic = `sap-icon://sap-ui5`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-19T08:30:00`.
    temp34-end_at = `2017-01-19T18:30:00`.
    temp34-title = `Meet John Doe`.
    temp34-type = `Type08`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-19T10:00:00`.
    temp34-end_at = `2017-01-19T16:00:00`.
    temp34-title = `Team meeting`.
    temp34-info = `room 1`.
    temp34-type = `Type08`.
    temp34-pic = `sap-icon://sap-ui5`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-19T07:00:00`.
    temp34-end_at = `2017-01-19T17:30:00`.
    temp34-title = `Discussion with clients`.
    temp34-type = `Type08`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-20T00:00:00`.
    temp34-end_at = `2017-01-20T23:59:00`.
    temp34-title = `Vacation`.
    temp34-info = `out of office`.
    temp34-type = `Type08`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-01-22T07:00:00`.
    temp34-end_at = `2017-01-27T17:30:00`.
    temp34-title = `Discussion with clients`.
    temp34-info = `out of office`.
    temp34-type = `Type08`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-03-13T09:00:00`.
    temp34-end_at = `2017-03-17T10:00:00`.
    temp34-title = `Payment week`.
    temp34-type = `Type08`.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-04-10T00:00:00`.
    temp34-end_at = `2017-06-16T23:59:00`.
    temp34-title = `Vacation`.
    temp34-info = `out of office`.
    temp34-type = `Type04`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    CLEAR temp34.
    temp34-start_at = `2017-08-01T00:00:00`.
    temp34-end_at = `2017-10-31T23:59:00`.
    temp34-title = `New quarter`.
    temp34-type = `Type10`.
    temp34-tentative = abap_false.
    temp34-aria = `Dialog`.
    INSERT temp34 INTO TABLE temp33.
    temp19-t_appointments = temp33.
    
    CLEAR temp35.
    
    temp36-start_at = `2017-01-16T00:00:00`.
    temp36-end_at = `2017-01-16T23:59:00`.
    temp36-title = `Private`.
    temp36-type = `Type05`.
    INSERT temp36 INTO TABLE temp35.
    temp19-t_headers = temp35.
    INSERT temp19 INTO TABLE temp18.
    t_people = temp18.

  ENDMETHOD.

ENDCLASS.
