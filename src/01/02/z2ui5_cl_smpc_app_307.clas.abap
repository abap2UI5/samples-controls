" @keywords calendar sap.ui.unified calendarmultipledayselection html verticallayout button list standardlistitem
" @summary Calendar where the user can select multiple days, entire weeks (either by selecting its week number or by using SHIFT + Space) and ranges (using SHIFT + ENTER/Left mouse click).
" @origin sap.ui.unified.sample.CalendarMultipleDaySelection - https://sdk.openui5.org/entity/sap.ui.unified.Calendar/sample/sap.ui.unified.sample.CalendarMultipleDaySelection (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_307 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_date,
        date TYPE string,
      END OF ty_s_date.
    DATA selecteddates TYPE STANDARD TABLE OF ty_s_date WITH DEFAULT KEY.

  PROTECTED SECTION.
    " one entry per DateRange the frontend marshalled out of the LIVE
    " selectedDates aggregation - startDate arrives as an ISO LOCAL timestamp
    " (no Z), so its first ten characters are the day the user picked
    TYPES:
      BEGIN OF ty_s_event_range,
        startdate TYPE string,
      END OF ty_s_event_range.
    TYPES ty_t_event_range TYPE STANDARD TABLE OF ty_s_event_range WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS event_ranges
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_event_range.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_307 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:u`    v = `sap.ui.unified`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `class`      v = `viewPadding`

        )->a( n = `xmlns:core` v = `sap.ui.core`

        " the sample's own ../style.css (shared by the sap.ui.unified samples and
        " listed in this sample's manifest) - the view carries the class and the
        " rule behind it has to come with it. \{ \} escaped: the XMLView parser
        " reads an unescaped brace as a binding
        )->tag( n = `HTML` ns = `core`
            )->a( n = `content` v = `<style>.viewPadding\{padding:1rem\}` &&
                                    `.sap-phone .viewPadding\{padding:0rem\}` &&
                                    `.sap-phone .sapUiCal\{position:relative\}` &&
                                    `.labelMarginLeft\{margin:1rem\}</style>`
        )->ele( n = `VerticalLayout` ns = `l`

            )->tag( n = `Calendar` ns = `u`
                )->a( n = `id`                v = `calendar`
                " the WHOLE selectedDates aggregation travels in one arg: the
                " frontend marshals each DateRange into its public properties
                " (Lib.normalizeEventArgs), which is the loop the client
                " expression grammar does not have
                )->a( n = `select`            v = client->_event( val = `CAL_SELECT` arg = `$event.oSource.getSelectedDates()` )
                )->a( n = `intervalSelection` v = `false`
                )->a( n = `singleSelection`   v = `false`
            )->tag( `Button`
                )->a( n = `press` v = client->_event( `REMOVE_SELECTION` )
                )->a( n = `text`  v = `Remove All Selected Dates`

            )->ele( `List`
                )->a( n = `id`         v = `selectedDatesList`
                )->a( n = `class`      v = `labelMarginLeft`
                )->a( n = `noDataText` v = `No Dates Selected`
                )->a( n = `headerText` v = `Selected Dates (yyyy-mm-dd)`
                )->a( n = `items`      v = |\{path: '{ client->_bind_path( selecteddates ) }'\}|

                )->tag( `StandardListItem`
                    )->a( n = `title` v = `{DATE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp1 LIKE selecteddates.
        DATA ranges TYPE z2ui5_cl_smpc_app_307=>ty_t_event_range.
        DATA temp2 LIKE LINE OF ranges.
        DATA range LIKE REF TO temp2.
          DATA temp3 TYPE z2ui5_cl_smpc_app_307=>ty_s_date.
        DATA temp4 LIKE selecteddates.
        DATA temp5 TYPE string_table.

    CASE client->get_event( ).

      WHEN `CAL_SELECT`.
        " handleCalendarSelect: rebuild the model from EVERY selected date,
        " each formatted yyyy-MM-dd - the day is the first ten characters of
        " the ISO local timestamp the marshalled DateRange carries
        
        CLEAR temp1.
        selecteddates = temp1.
        
        ranges = event_ranges( client->get_event_arg( ) ).
        
        
        LOOP AT ranges REFERENCE INTO range.
          IF strlen( range->startdate ) < 10.
            CONTINUE.
          ENDIF.
          
          CLEAR temp3.
          temp3-date = range->startdate(10).
          INSERT temp3 INTO TABLE selecteddates.
        ENDLOOP.

      WHEN `REMOVE_SELECTION`.
        " handleRemoveSelection: removeAllSelectedDates( ) + clear the model.
        " selectedDates is written by the control itself, so the aggregation
        " has to be emptied on the control - the model half alone would leave
        " the days highlighted
        
        CLEAR temp4.
        selecteddates = temp4.
        
        CLEAR temp5.
        INSERT `calendar` INTO TABLE temp5.
        INSERT `removeAllSelectedDates` INTO TABLE temp5.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp5 ).

    ENDCASE.

  ENDMETHOD.


  METHOD event_ranges.

    DATA json TYPE string.
    DATA marker TYPE string.
    DATA rest LIKE json.
      DATA offset TYPE i.
      DATA temp7 TYPE z2ui5_cl_smpc_app_307=>ty_s_event_range.
    json = condense( val ).
    IF json IS INITIAL.
      RETURN.
    ENDIF.

    " a marshalled DateRange carries ALL its public properties (ID,
    " startDate, endDate); this port models exactly one of them.
    "
    " Read by hand: abap2UI5 releases no JSON parser, and the vendored ajson
    " copy is framework-internal (the linter's non-released-api rule reports
    " it, correctly). For ONE property of a flat projection that is the whole
    " job - walk every `"startdate":"` and take what stands up to the next quote.
    " The same reader as Z2UI5_CL_SMP_APP_197 in abap2UI5/samples, and the
    " same limit: it reads what the FRAMEWORK wrote, which is flat, and it
    " would need to resolve escapes for a payload composed from free text.
    
    marker = |"startdate":"|.
    
    rest = json.

    DO.
      
      offset = find( val = rest sub = marker case = abap_false ).
      IF offset < 0.
        EXIT.
      ENDIF.

      rest = substring( val = rest off = offset + strlen( marker ) ).
      
      CLEAR temp7.
      temp7-startdate = substring_before( val = rest sub = `"` ).
      INSERT temp7 INTO TABLE result.
    ENDDO.

  ENDMETHOD.

ENDCLASS.
