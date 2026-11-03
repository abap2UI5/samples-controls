" @keywords dynamicdaterange dynamic date range sap.m dynamicdaterangewithcustomoptions table overflowtoolbar title toolbarspacer label column
" @summary This example shows the Dynamic Date Range control with custom options for interval or date selection.
" @origin sap.m.sample.DynamicDateRangeWithCustomOptions - https://sdk.openui5.org/entity/sap.m.DynamicDateRange/sample/sap.m.sample.DynamicDateRangeWithCustomOptions (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_642 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_order,
        producttype     TYPE string,
        ordertime       TYPE string,
        productprice    TYPE p LENGTH 8 DECIMALS 2,
        productquantity TYPE i,
        currency        TYPE string,
        totalprice      TYPE p LENGTH 8 DECIMALS 2,
      END OF ty_s_order.
    DATA t_orders TYPE STANDARD TABLE OF ty_s_order WITH DEFAULT KEY.
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


CLASS z2ui5_cl_smpc_app_642 IMPLEMENTATION.

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
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/valid}` INTO TABLE temp1.
    INSERT `${$parameters>/value/operator}` INTO TABLE temp1.
    INSERT `${$parameters>/value} ? ${$source>}.toDates(${$parameters>/value})[0].getJSDate() : ''` INTO TABLE temp1.
    INSERT `${$parameters>/value} ? (${$source>}.toDates(${$parameters>/value})[1] ? ${$source>}.toDates(${$parameters>/value})[1].getJSDate() : '') : ''` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `Table`
            )->a( n = `id`    v = `orders-table`
            )->a( n = `items` v = client->_bind( t_orders )

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->tag( `Title`
                        )->a( n = `text`  v = `Orders`
                        )->a( n = `level` v = `H2`
                    )->tag( `ToolbarSpacer`
                    )->tag( `Label`
                        )->a( n = `visible`  v = `false`
                        )->a( n = `text`     v = `Order date`
                        )->a( n = `labelFor` v = `dynamic-range`
                    " the controller's four custom DynamicDateOption classes are JS code - only the standard options remain
                    )->tag( `DynamicDateRange`
                        )->a( n = `placeholder` v = `Choose date range`
                        )->a( n = `id`          v = `dynamic-range`
                        )->a( n = `valueState`  v = client->_bind( value_state )
                        )->a( n = `change`      v = client->_event(
                                                        val   = `CHANGE`
                                                        t_arg = temp1 )
                        )->a( n = `width`       v = client->_bind( filterinputwidth )

                )->end(
            )->end(
            )->ele( `infoToolbar`
                )->ele( `OverflowToolbar`
                    )->tag( `Label`
                        )->a( n = `text` v = `List of orders`

                )->end(
            )->end(
            )->ele( `columns`
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Order date`

                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Product name`

                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Product Quantity`

                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Price`

                )->end(
                )->ele( `Column`
                    )->tag( `Text`
                        )->a( n = `text` v = `Total Price`

                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->ele( `cells`
                        " the controller's _dateFormatter pattern as a DateTime type over the ISO string
                        )->tag( `Text`
                            )->a( n = `text` v = `{ path: 'ORDERTIME', type: 'sap.ui.model.type.DateTime', formatOptions: { pattern: 'MMMM dd YY, hh:mm:ss', source: { pattern: 'yyyy-MM-dd\'T\'HH:mm:ss' } } }`
                        )->tag( `Text`
                            )->a( n = `text` v = `{PRODUCTTYPE}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{PRODUCTQUANTITY}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{ parts: [{path: 'PRODUCTPRICE'}, {path: 'CURRENCY'}], type: 'sap.ui.model.type.Currency', formatOptions: {showMeasure: false} }`
                            )->a( n = `unit`   v = `{CURRENCY}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{ parts: [{path: 'TOTALPRICE'}, {path: 'CURRENCY'}], type: 'sap.ui.model.type.Currency', formatOptions: {showMeasure: false} }`
                            )->a( n = `unit`   v = `{CURRENCY}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
      DATA operator TYPE string.
      DATA temp3 TYPE string.
      DATA path LIKE temp3.
      DATA temp4 TYPE string.
      DATA filter LIKE temp4.
      DATA temp5 TYPE string_table.

    IF client->get_event( ) = `CHANGE`.
      IF client->get_event_arg( ) = abap_false.
        value_state = `Error`.
        RETURN.
      ENDIF.
      value_state = `None`.
      " the controller's _createFilter - its FROM/TO branches filter the path PerfomDateTime, which no order row has
      
      operator = client->get_event_arg( 2 ).
      
      CASE operator.
        WHEN `FROM` OR `FROMDATETIME` OR `TO` OR `TODATETIME`.
          temp3 = `PERFOMDATETIME`.
        WHEN OTHERS.
          temp3 = `ORDERTIME`.
      ENDCASE.
      
      path = temp3.
      
      CASE operator.
        WHEN `FROM` OR `FROMDATETIME`.
          temp4 = `GT`.
        WHEN `TO` OR `TODATETIME`.
          temp4 = `LT`.
        WHEN OTHERS.
          temp4 = `BT`.
      ENDCASE.
      
      filter = temp4.
      
      CLEAR temp5.
      INSERT `orders-table` INTO TABLE temp5.
      INSERT `items` INTO TABLE temp5.
      INSERT `filter` INTO TABLE temp5.
      INSERT path INTO TABLE temp5.
      INSERT filter INTO TABLE temp5.
      INSERT client->get_event_arg( 3 ) INTO TABLE temp5.
      INSERT client->get_event_arg( 4 ) INTO TABLE temp5.
      client->follow_up_action( val   = client->cs_event-binding_call
                                t_arg = temp5 ).
    ENDIF.

  ENDMETHOD.


  METHOD shifted_now.

    " getIcrementedDateFromToday: years and months first, the day offset overflows like JS setUTCDate
    DATA temp7 TYPE i.
    DATA month TYPE i.
    DATA temp8 TYPE i.
    DATA year TYPE i.
    DATA temp9 TYPE d.
    DATA first LIKE temp9.
    DATA temp10 TYPE d.
    DATA temp1 TYPE i.
    DATA day LIKE temp10.
    temp7 = sy-datum+4(2).
    
    month = temp7 - 1 + months.
    
    temp8 = sy-datum(4).
    
    year = temp8 + years + month DIV 12.
    month = month MOD 12 + 1.
    
    temp9 = |{ year WIDTH = 4 ALIGN = RIGHT PAD = `0` }{ month WIDTH = 2 ALIGN = RIGHT PAD = `0` }01|.
    
    first = temp9.
    
    
    temp1 = sy-datum+6(2).
    temp10 = first + temp1 - 1 + days.
    
    day = temp10.
    result = |{ day DATE = ISO }T{ sy-uzeit TIME = ISO }|.

  ENDMETHOD.


  METHOD model_init.

    DATA temp11 TYPE string.
    DATA temp12 TYPE i.
    DATA last_christmas TYPE string.
    DATA temp13 LIKE t_orders.
    DATA temp14 LIKE LINE OF temp13.
    DATA temp15 LIKE LINE OF t_orders.
    DATA order LIKE REF TO temp15.
    IF client->get( )-s_device-system = z2ui5_if_client=>cs_device-system-phone.
      temp11 = `auto`.
    ELSE.
      temp11 = `300px`.
    ENDIF.
    filterinputwidth = temp11.
    value_state = `None`.

    " getChristmasDay( iCurrentYear - 1 ) keeps the current time of day
    
    temp12 = sy-datum(4).
    
    last_christmas = |{ temp12 - 1 }-12-25T{ sy-uzeit TIME = ISO }|.

    
    CLEAR temp13.
    
    temp14-producttype = `Water`.
    temp14-ordertime = shifted_now( days = -1 months = 0 years = 0 ).
    temp14-productprice = `1.00`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Cake`.
    temp14-ordertime = shifted_now( days = -2 months = 0 years = 0 ).
    temp14-productprice = `18.00`.
    temp14-productquantity = 1.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Orange Juice`.
    temp14-ordertime = shifted_now( days = -3 months = 0 years = 0 ).
    temp14-productprice = `5.05`.
    temp14-productquantity = 4.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Apple Juice`.
    temp14-ordertime = shifted_now( days = -4 months = 0 years = 0 ).
    temp14-productprice = `3.00`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Beer`.
    temp14-ordertime = shifted_now( days = -5 months = 0 years = 0 ).
    temp14-productprice = `5.50`.
    temp14-productquantity = 3.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Wine`.
    temp14-ordertime = shifted_now( days = -3 months = 0 years = 0 ).
    temp14-productprice = `7.30`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Sandwich`.
    temp14-ordertime = shifted_now( days = -3 months = -1 years = 0 ).
    temp14-productprice = `9.50`.
    temp14-productquantity = 1.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Toast`.
    temp14-ordertime = shifted_now( days = -1 months = -1 years = 0 ).
    temp14-productprice = `3.90`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Coffee`.
    temp14-ordertime = shifted_now( days = -5 months = -2 years = 0 ).
    temp14-productprice = `2.00`.
    temp14-productquantity = 5.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Strawberry Smoothie`.
    temp14-ordertime = shifted_now( days = -4 months = -2 years = 0 ).
    temp14-productprice = `5.80`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Water`.
    temp14-ordertime = shifted_now( days = -9 months = 0 years = 0 ).
    temp14-productprice = `1.30`.
    temp14-productquantity = 1.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Beer`.
    temp14-ordertime = shifted_now( days = -8 months = 0 years = 0 ).
    temp14-productprice = `4.60`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Soda`.
    temp14-ordertime = shifted_now( days = 0 months = -1 years = -1 ).
    temp14-productprice = `1.60`.
    temp14-productquantity = 4.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Soda`.
    temp14-ordertime = shifted_now( days = 0 months = 0 years = 0 ).
    temp14-productprice = `4.00`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Orange Juice`.
    temp14-ordertime = `2021-06-09T15:15:00`.
    temp14-productprice = `5.00`.
    temp14-productquantity = 1.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Burger`.
    temp14-ordertime = `2021-06-08T10:15:00`.
    temp14-productprice = `12.40`.
    temp14-productquantity = 3.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Pizza`.
    temp14-ordertime = `2021-06-08T10:15:00`.
    temp14-productprice = `5.30`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Toast`.
    temp14-ordertime = shifted_now( days = -1 months = -1 years = 0 ).
    temp14-productprice = `3.90`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Coffee`.
    temp14-ordertime = shifted_now( days = -4 months = -2 years = 0 ).
    temp14-productprice = `2.00`.
    temp14-productquantity = 5.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Strawberry Smoothie`.
    temp14-ordertime = shifted_now( days = -1 months = -2 years = 0 ).
    temp14-productprice = `5.80`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Water`.
    temp14-ordertime = shifted_now( days = -3 months = 0 years = 0 ).
    temp14-productprice = `1.30`.
    temp14-productquantity = 1.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Beer`.
    temp14-ordertime = shifted_now( days = -3 months = 0 years = 0 ).
    temp14-productprice = `5.60`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Toast`.
    temp14-ordertime = shifted_now( days = -4 months = -1 years = 0 ).
    temp14-productprice = `5.90`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Coffee`.
    temp14-ordertime = shifted_now( days = -12 months = -2 years = 0 ).
    temp14-productprice = `2.00`.
    temp14-productquantity = 5.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Strawberry Smoothie`.
    temp14-ordertime = shifted_now( days = -12 months = -2 years = 0 ).
    temp14-productprice = `7.80`.
    temp14-productquantity = 2.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Water`.
    temp14-ordertime = shifted_now( days = -3 months = 0 years = 0 ).
    temp14-productprice = `1.30`.
    temp14-productquantity = 1.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Wine`.
    temp14-ordertime = `2021-06-08T10:15:00`.
    temp14-productprice = `5.34`.
    temp14-productquantity = 1.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    temp14-producttype = `Turkey`.
    temp14-ordertime = last_christmas.
    temp14-productprice = `20.00`.
    temp14-productquantity = 1.
    temp14-currency = `EUR`.
    INSERT temp14 INTO TABLE temp13.
    t_orders = temp13.

    " onInit: totalPrice = productQuantity * productPrice
    
    
    LOOP AT t_orders REFERENCE INTO order.
      order->totalprice = order->productquantity * order->productprice.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
