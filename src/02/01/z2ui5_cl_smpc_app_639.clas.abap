" @keywords dynamicdaterange dynamic date range sap.m table overflowtoolbar title toolbarspacer label column text
" @summary The dynamic date range is a control that offers a choice of absolute and relative dates, using different offset from the current date. The list of values offered must be defined by the application.
" @origin sap.m.sample.DynamicDateRange - https://sdk.openui5.org/entity/sap.m.DynamicDateRange/sample/sap.m.sample.DynamicDateRange (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_639 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_payment,
        transactiontype TYPE string,
        perfomdatetime  TYPE string,
        amount          TYPE p LENGTH 8 DECIMALS 2,
        currencycode    TYPE string,
      END OF ty_s_payment.
    DATA t_payments TYPE STANDARD TABLE OF ty_s_payment WITH EMPTY KEY.
    DATA filterinputwidth TYPE string.
    DATA value_state TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS shifted_now
      IMPORTING
        days          TYPE i
        months        TYPE i
        years         TYPE i
      RETURNING
        VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_639 IMPLEMENTATION.

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
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `Table`
            )->a( n = `id`    v = `payments-table`
            )->a( n = `inset` v = `false`
            )->a( n = `items` v = client->_bind( t_payments )

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->ele( `content`
                        )->tag( `Title`
                            )->a( n = `text`  v = `Payments`
                            )->a( n = `level` v = `H2`
                        )->tag( `ToolbarSpacer`
                        )->tag( `Label`
                            )->a( n = `visible`  v = `false`
                            )->a( n = `text`     v = `Transaction date`
                            )->a( n = `labelFor` v = `dynamic-range`
                        " the controller's setValueState is the bound valueState; toDates runs on the source control
                        )->tag( `DynamicDateRange`
                            )->a( n = `placeholder` v = `Choose date range`
                            )->a( n = `id`          v = `dynamic-range`
                            )->a( n = `valueState`  v = client->_bind( value_state )
                            )->a( n = `change`      v = client->_event(
                                                            val   = `CHANGE`
                                                            t_arg = VALUE #( ( `${$parameters>/valid}` )
                                                                             ( `${$parameters>/value/operator}` )
                                                                             ( `${$parameters>/value} ? ${$source>}.toDates(${$parameters>/value})[0].getJSDate() : ''` )
                                                                             ( `${$parameters>/value} ? (${$source>}.toDates(${$parameters>/value})[1] ? ${$source>}.toDates(${$parameters>/value})[1].getJSDate() : '') : ''` ) ) )
                            )->a( n = `width`       v = client->_bind( filterinputwidth )

                    )->end(
                )->end(
            )->end(
            )->ele( `infoToolbar`
                )->ele( `OverflowToolbar`
                    )->tag( `Label`
                        )->a( n = `text` v = `List of payments`

                )->end(
            )->end(
            )->ele( `columns`
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Transaction date`

                )->end(
                )->ele( `Column`
                    )->a( n = `hAlign` v = `Center`

                    )->tag( `Text`
                        )->a( n = `text` v = `Transaction type`

                )->end(
                )->ele( `Column`
                    )->a( n = `hAlign` v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Amount`

                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->ele( `cells`
                        " the controller's _dateFormatter pattern as a DateTime type over the ISO string
                        )->tag( `Text`
                            )->a( n = `text` v = `{ path: 'PERFOMDATETIME', type: 'sap.ui.model.type.DateTime', formatOptions: { pattern: 'MMMM dd YY, hh:mm:ss', source: { pattern: 'yyyy-MM-dd\'T\'HH:mm:ss' } } }`
                        )->tag( `Text`
                            )->a( n = `text` v = `{TRANSACTIONTYPE}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{ parts: [{path: 'AMOUNT'}, {path: 'CURRENCYCODE'}], type: 'sap.ui.model.type.Currency', formatOptions: {showMeasure: false} }`
                            )->a( n = `unit`   v = `{CURRENCYCODE}`

                    )->end(
                )->end(
            )->end(
        )->end(
        )->tag( n = `VerticalLayout` ns = `l`
            )->a( n = `id` v = `tableLayout` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `CHANGE`.
      IF client->get_event_arg( ) = abap_false.
        value_state = `Error`.
        RETURN.
      ENDIF.
      value_state = `None`.
      " the controller's _createFilter - an empty value clears the filter
      DATA(operator) = SWITCH string( client->get_event_arg( 2 )
          WHEN `FROM` OR `FROMDATETIME` THEN `GT`
          WHEN `TO` OR `TODATETIME` THEN `LT`
          ELSE `BT` ).
      client->follow_up_action( val   = client->cs_event-binding_call
                                t_arg = VALUE #( ( `payments-table` )
                                                 ( `items` )
                                                 ( `filter` )
                                                 ( `PERFOMDATETIME` )
                                                 ( operator )
                                                 ( client->get_event_arg( 3 ) )
                                                 ( client->get_event_arg( 4 ) ) ) ).
    ENDIF.

  ENDMETHOD.


  METHOD shifted_now.

    " getIcrementedDateFromToday: years and months first, the day offset overflows like JS setDate
    DATA(month) = CONV i( sy-datum+4(2) ) - 1 + months.
    DATA(year) = CONV i( sy-datum(4) ) + years + month DIV 12.
    month = month MOD 12 + 1.
    DATA(first) = CONV d( |{ year WIDTH = 4 ALIGN = RIGHT PAD = `0` }{ month WIDTH = 2 ALIGN = RIGHT PAD = `0` }01| ).
    DATA(day) = CONV d( first + CONV i( sy-datum+6(2) ) - 1 + days ).
    result = |{ day DATE = ISO }T{ sy-uzeit TIME = ISO }|.

  ENDMETHOD.


  METHOD model_init.

    filterinputwidth = COND #( WHEN client->get( )-s_device-system = z2ui5_if_client=>cs_device-system-phone
                               THEN `auto`
                               ELSE `300px` ).
    value_state = `None`.

    t_payments = VALUE #(
        ( transactiontype = `ATM withdrawal`          perfomdatetime = shifted_now( days = -1 months = 0 years = 0 )  amount = `100.00` currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -2 months = 0 years = 0 )  amount = `18.00`  currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -3 months = 0 years = 0 )  amount = `54.05`  currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -4 months = 0 years = 0 )  amount = `30.00`  currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -5 months = 0 years = 0 )  amount = `105.50` currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -3 months = 0 years = 0 )  amount = `74.35`  currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -3 months = -1 years = 0 ) amount = `9.50`   currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -1 months = -1 years = 0 ) amount = `3.90`   currencycode = `EUR` )
        ( transactiontype = `ATM withdrawal`          perfomdatetime = shifted_now( days = -5 months = -2 years = 0 ) amount = `200.00` currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -4 months = -2 years = 0 ) amount = `153.80` currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -9 months = 0 years = 0 )  amount = `5.30`   currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = -8 months = 0 years = 0 )  amount = `1.60`   currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = shifted_now( days = 0 months = -1 years = -1 ) amount = `95.60`  currencycode = `EUR` )
        ( transactiontype = `ATM withdrawal`          perfomdatetime = shifted_now( days = 0 months = 0 years = 0 )   amount = `400.00` currencycode = `EUR` )
        ( transactiontype = `ATM withdrawal`          perfomdatetime = `2021-06-09T15:15:00`                          amount = `50.00`  currencycode = `EUR` )
        ( transactiontype = `payment on POS terminal` perfomdatetime = `2021-06-08T10:15:00`                          amount = `22.34`  currencycode = `EUR` ) ).

  ENDMETHOD.

ENDCLASS.
