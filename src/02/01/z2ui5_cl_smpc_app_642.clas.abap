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
    DATA t_orders TYPE STANDARD TABLE OF ty_s_order WITH EMPTY KEY.
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
                                                        t_arg = VALUE #( ( `${$parameters>/valid}` )
                                                                         ( `${$parameters>/value/operator}` )
                                                                         ( `${$parameters>/value} ? ${$source>}.toDates(${$parameters>/value})[0].getJSDate() : ''` )
                                                                         ( `${$parameters>/value} ? (${$source>}.toDates(${$parameters>/value})[1] ? ${$source>}.toDates(${$parameters>/value})[1].getJSDate() : '') : ''` ) ) )
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

    IF client->get_event( ) = `CHANGE`.
      IF client->get_event_arg( ) = abap_false.
        value_state = `Error`.
        RETURN.
      ENDIF.
      value_state = `None`.
      " the controller's _createFilter - its FROM/TO branches filter the path PerfomDateTime, which no order row has
      DATA(operator) = client->get_event_arg( 2 ).
      DATA(path) = SWITCH string( operator
          WHEN `FROM` OR `FROMDATETIME` OR `TO` OR `TODATETIME` THEN `PERFOMDATETIME`
          ELSE `ORDERTIME` ).
      DATA(filter) = SWITCH string( operator
          WHEN `FROM` OR `FROMDATETIME` THEN `GT`
          WHEN `TO` OR `TODATETIME` THEN `LT`
          ELSE `BT` ).
      client->follow_up_action( val   = client->cs_event-binding_call
                                t_arg = VALUE #( ( `orders-table` )
                                                 ( `items` )
                                                 ( `filter` )
                                                 ( path )
                                                 ( filter )
                                                 ( client->get_event_arg( 3 ) )
                                                 ( client->get_event_arg( 4 ) ) ) ).
    ENDIF.

  ENDMETHOD.


  METHOD shifted_now.

    " getIcrementedDateFromToday: years and months first, the day offset overflows like JS setUTCDate
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

    " getChristmasDay( iCurrentYear - 1 ) keeps the current time of day
    DATA(last_christmas) = |{ CONV i( sy-datum(4) ) - 1 }-12-25T{ sy-uzeit TIME = ISO }|.

    t_orders = VALUE #(
        ( producttype = `Water`               ordertime = shifted_now( days = -1 months = 0 years = 0 )   productprice = `1.00`  productquantity = 2 currency = `EUR` )
        ( producttype = `Cake`                ordertime = shifted_now( days = -2 months = 0 years = 0 )   productprice = `18.00` productquantity = 1 currency = `EUR` )
        ( producttype = `Orange Juice`        ordertime = shifted_now( days = -3 months = 0 years = 0 )   productprice = `5.05`  productquantity = 4 currency = `EUR` )
        ( producttype = `Apple Juice`         ordertime = shifted_now( days = -4 months = 0 years = 0 )   productprice = `3.00`  productquantity = 2 currency = `EUR` )
        ( producttype = `Beer`                ordertime = shifted_now( days = -5 months = 0 years = 0 )   productprice = `5.50`  productquantity = 3 currency = `EUR` )
        ( producttype = `Wine`                ordertime = shifted_now( days = -3 months = 0 years = 0 )   productprice = `7.30`  productquantity = 2 currency = `EUR` )
        ( producttype = `Sandwich`            ordertime = shifted_now( days = -3 months = -1 years = 0 )  productprice = `9.50`  productquantity = 1 currency = `EUR` )
        ( producttype = `Toast`               ordertime = shifted_now( days = -1 months = -1 years = 0 )  productprice = `3.90`  productquantity = 2 currency = `EUR` )
        ( producttype = `Coffee`              ordertime = shifted_now( days = -5 months = -2 years = 0 )  productprice = `2.00`  productquantity = 5 currency = `EUR` )
        ( producttype = `Strawberry Smoothie` ordertime = shifted_now( days = -4 months = -2 years = 0 )  productprice = `5.80`  productquantity = 2 currency = `EUR` )
        ( producttype = `Water`               ordertime = shifted_now( days = -9 months = 0 years = 0 )   productprice = `1.30`  productquantity = 1 currency = `EUR` )
        ( producttype = `Beer`                ordertime = shifted_now( days = -8 months = 0 years = 0 )   productprice = `4.60`  productquantity = 2 currency = `EUR` )
        ( producttype = `Soda`                ordertime = shifted_now( days = 0 months = -1 years = -1 )  productprice = `1.60`  productquantity = 4 currency = `EUR` )
        ( producttype = `Soda`                ordertime = shifted_now( days = 0 months = 0 years = 0 )    productprice = `4.00`  productquantity = 2 currency = `EUR` )
        ( producttype = `Orange Juice`        ordertime = `2021-06-09T15:15:00`                           productprice = `5.00`  productquantity = 1 currency = `EUR` )
        ( producttype = `Burger`              ordertime = `2021-06-08T10:15:00`                           productprice = `12.40` productquantity = 3 currency = `EUR` )
        ( producttype = `Pizza`               ordertime = `2021-06-08T10:15:00`                           productprice = `5.30`  productquantity = 2 currency = `EUR` )
        ( producttype = `Toast`               ordertime = shifted_now( days = -1 months = -1 years = 0 )  productprice = `3.90`  productquantity = 2 currency = `EUR` )
        ( producttype = `Coffee`              ordertime = shifted_now( days = -4 months = -2 years = 0 )  productprice = `2.00`  productquantity = 5 currency = `EUR` )
        ( producttype = `Strawberry Smoothie` ordertime = shifted_now( days = -1 months = -2 years = 0 )  productprice = `5.80`  productquantity = 2 currency = `EUR` )
        ( producttype = `Water`               ordertime = shifted_now( days = -3 months = 0 years = 0 )   productprice = `1.30`  productquantity = 1 currency = `EUR` )
        ( producttype = `Beer`                ordertime = shifted_now( days = -3 months = 0 years = 0 )   productprice = `5.60`  productquantity = 2 currency = `EUR` )
        ( producttype = `Toast`               ordertime = shifted_now( days = -4 months = -1 years = 0 )  productprice = `5.90`  productquantity = 2 currency = `EUR` )
        ( producttype = `Coffee`              ordertime = shifted_now( days = -12 months = -2 years = 0 ) productprice = `2.00`  productquantity = 5 currency = `EUR` )
        ( producttype = `Strawberry Smoothie` ordertime = shifted_now( days = -12 months = -2 years = 0 ) productprice = `7.80`  productquantity = 2 currency = `EUR` )
        ( producttype = `Water`               ordertime = shifted_now( days = -3 months = 0 years = 0 )   productprice = `1.30`  productquantity = 1 currency = `EUR` )
        ( producttype = `Wine`                ordertime = `2021-06-08T10:15:00`                           productprice = `5.34`  productquantity = 1 currency = `EUR` )
        ( producttype = `Turkey`              ordertime = last_christmas                                  productprice = `20.00` productquantity = 1 currency = `EUR` ) ).

    " onInit: totalPrice = productQuantity * productPrice
    LOOP AT t_orders REFERENCE INTO DATA(order).
      order->totalprice = order->productquantity * order->productprice.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
