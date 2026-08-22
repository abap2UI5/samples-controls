" @keywords table sap.ui.table filtering column
" @summary Example showing the different facets of filtering within a table
CLASS z2ui5_cl_smpc_app_354 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name           TYPE string,
        category       TYPE string,
        productpicurl  TYPE string,
        available      TYPE abap_bool,
        availablestate TYPE string,
        status         TYPE string,
        price          TYPE p LENGTH 13 DECIMALS 2,
        currencycode   TYPE string,
        quantity       TYPE i,
      END OF ty_s_product,
      ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    " the ROWS the table shows - the filtered result. The full catalog stays in
    " a method (see catalog): it is never bound, so it does not belong in the
    " model that travels on every round-trip
    DATA t_products TYPE ty_t_product.

    " the original's `ui>` model, folded onto the one default model
    DATA global_filter           TYPE string.
    DATA availability_filter_on  TYPE abap_bool.
    DATA cell_filter_on          TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    " the price column's own filter (the original's _oPriceFilter): the value
    " the user typed, and the +/- 20 band around it
    DATA price_filter TYPE string.

    METHODS view_display.
    METHODS on_event.
    METHODS filter_apply.
    METHODS catalog
      RETURNING
        VALUE(result) TYPE ty_t_product.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_354 IMPLEMENTATION.

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
    DATA temp2 TYPE z2ui5_if_client=>ty_s_event_control.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    " the filtering demo. Every filter is applied in ABAP and the table binds
    " the filtered rows, so the controller's Filter objects and its
    " binding.filter( ) calls become one server-side selection.
    
    CLEAR temp1.
    INSERT `${$parameters>/column}.getFilterProperty()` INTO TABLE temp1.
    INSERT `${$parameters>/value}` INTO TABLE temp1.
    
    CLEAR temp2.
    temp2-prevent_default_expr = `${$parameters>/column}.getId().indexOf('price') >= 0`.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.ui.table`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`   v = `sap.ui.unified`
        )->a( n = `xmlns:m`   v = `sap.m`
        )->a( n = `height`    v = `100%`

        )->ele( n = `Page` ns = `m`
            )->a( n = `showHeader`      v = `false`
            )->a( n = `enableScrolling` v = `false`
            )->a( n = `class`           v = `sapUiContentPadding`

            )->ele( n = `content` ns = `m`
                )->ele( `Table`
                    )->a( n = `id`               v = `table`
                    )->a( n = `selectionMode`    v = `MultiToggle`
                    )->a( n = `rows`             v = client->_bind( t_products )
                    )->a( n = `enableCellFilter` v = client->_bind( cell_filter_on )
                    )->a( n = `filter`           v = client->_event(
                                        val    = `COLUMN_FILTER`
                                        t_arg  = temp1
                                        " filterPrice returns BEFORE preventDefault for
                                        " every column but price, so the other four keep
                                        " the table's own client-side filtering. A boolean
                                        " check_prevent_default is baked per WIRE and would
                                        " veto all five - the conditional form is what this
                                        " needs (worked precedent: app 247's columnResize)
                                        s_ctrl = temp2 )
                    )->a( n = `ariaLabelledBy`   v = `title`

                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `style` v = `Clear`

                            )->tag( n = `Title` ns = `m`
                                )->a( n = `id`   v = `title`
                                )->a( n = `text` v = `Products`

                            )->tag( n = `ToolbarSpacer` ns = `m`

                            )->tag( n = `ToggleButton` ns = `m`
                                )->a( n = `icon`    v = `sap-icon://complete`
                                )->a( n = `tooltip` v = `Show available products only`
                                )->a( n = `pressed` v = client->_bind( availability_filter_on )
                                )->a( n = `press`   v = client->_event( `TOGGLE_AVAILABILITY` )

                            )->tag( n = `ToggleButton` ns = `m`
                                )->a( n = `icon`    v = `sap-icon://grid`
                                )->a( n = `tooltip` v = `Enable / Disable Cell Filter Functionality`
                                )->a( n = `pressed` v = client->_bind( cell_filter_on )

                            )->tag( n = `Button` ns = `m`
                                )->a( n = `icon`    v = `sap-icon://decline`
                                )->a( n = `tooltip` v = `Clear all filters`
                                )->a( n = `press`   v = client->_event( `CLEAR_FILTERS` )

                            )->tag( n = `ToolbarSeparator` ns = `m`

                            )->tag( n = `SearchField` ns = `m`
                                )->a( n = `placeholder` v = `Filter`
                                )->a( n = `value`       v = client->_bind( global_filter )
                                )->a( n = `search`      v = client->_event( `SEARCH` )
                                )->a( n = `width`       v = `15rem`

                        )->end(
                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`
                            )->a( n = `width`          v = `11rem`
                            )->a( n = `filterProperty` v = `NAME`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Name`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{NAME}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width`                 v = `11rem`
                            )->a( n = `filterProperty`        v = `CATEGORY`
                            )->a( n = `defaultFilterOperator` v = `StartsWith`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Category`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{CATEGORY}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `9rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Image`

                            )->ele( `template`
                                )->tag( n = `Link` ns = `m`
                                    )->a( n = `text`   v = `Show Image`
                                    )->a( n = `href`   v = `{PRODUCTPICURL}`
                                    )->a( n = `target` v = `_blank`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id`                    v = `availability`
                            )->a( n = `width`                 v = `9rem`
                            )->a( n = `filterProperty`        v = `AVAILABLE`
                            )->a( n = `showFilterMenuEntry`   v = `false`
                            )->a( n = `defaultFilterOperator` v = `EQ`
                            )->a( n = `filterType`            v = `sap.ui.model.type.Boolean`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Status`

                            )->ele( `template`
                                )->tag( n = `ObjectStatus` ns = `m`
                                    )->a( n = `text`  v = `{STATUS}`
                                    )->a( n = `state` v = `{AVAILABLESTATE}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id`             v = `price`
                            )->a( n = `width`          v = `9rem`
                            )->a( n = `filterProperty` v = `PRICE`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Price`

                            )->ele( `template`
                                )->tag( n = `Currency` ns = `u`
                                    )->a( n = `value`    v = `{PRICE}`
                                    )->a( n = `currency` v = `{CURRENCYCODE}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width`          v = `6rem`
                            )->a( n = `hAlign`         v = `End`
                            )->a( n = `filterProperty` v = `QUANTITY`
                            )->a( n = `filterType`     v = `sap.ui.model.type.Integer`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Quantity`

                            )->ele( `template`
                                )->tag( n = `Label` ns = `m`
                                    )->a( n = `text` v = |\{ path: 'QUANTITY', type: 'sap.ui.model.type.Integer' \}|

                            )->end(
                        )->end(
                    )->end(
                    )->ele( `footer`
                        )->tag( n = `OverflowToolbar` ns = `m`
                            )->a( n = `id` v = `infobar`

                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SEARCH`.
        " filterGlobally: Name OR Category contains the query
        filter_apply( ).

      WHEN `TOGGLE_AVAILABILITY`.
        " toggleAvailabilityFilter: filter the availability column on/off
        filter_apply( ).

      WHEN `COLUMN_FILTER`.
        " filterPrice: the price column filters a +/- 20 BAND around the entered
        " value instead of an exact match, so its client-side default is vetoed
        " and the band is computed server-side. Every other column keeps the
        " default and filters on its own filterProperty in the client, which is
        " what the original does by returning before preventDefault - the veto
        " is therefore conditional on the column, not baked into the wire
        IF client->get_event_arg( ) = `PRICE`.
          price_filter = client->get_event_arg( 2 ).
        ENDIF.
        filter_apply( ).

      WHEN `CLEAR_FILTERS`.
        " clearAllFilters
        global_filter          = ``.
        availability_filter_on = abap_false.
        price_filter           = ``.
        filter_apply( ).

    ENDCASE.


  ENDMETHOD.


  METHOD filter_apply.
      DATA lv_query TYPE string.
      DATA temp3 TYPE ty_t_product.
      DATA lt_keep LIKE temp3.
      DATA ls_row LIKE LINE OF t_products.
      DATA temp4 TYPE decfloat34.
      DATA lv_price LIKE temp4.

    " the controller's _filter( ): the global filter and the price filter are
    " ANDed, each one on its own an OR over its columns
    t_products = catalog( ).

    IF global_filter IS NOT INITIAL.
      
      lv_query = to_upper( global_filter ).
      " Collected rather than deleted in place: DELETE ... INDEX sy-tabix inside
      " a LOOP over the same table shifts the rows under the loop's own cursor -
      " on a system it silently SKIPS the row after each deletion, on the
      " transpiled backend it raises TABLE_INVALID_INDEX (2026-08-17).
      
      CLEAR temp3.
      
      lt_keep = temp3.
      
      LOOP AT t_products INTO ls_row.
        IF to_upper( ls_row-name ) CS lv_query OR to_upper( ls_row-category ) CS lv_query.
          APPEND ls_row TO lt_keep.
        ENDIF.
      ENDLOOP.
      t_products = lt_keep.
    ENDIF.

    IF availability_filter_on = abap_true.
      DELETE t_products WHERE available = abap_false.
    ENDIF.

    IF price_filter CO ` 0123456789.` AND price_filter IS NOT INITIAL.
      
      temp4 = price_filter.
      
      lv_price = temp4.
      DELETE t_products WHERE price < lv_price - 20 OR price > lv_price + 20.
    ENDIF.

  ENDMETHOD.


  METHOD catalog.

    " the shared 123-row demo ProductCollection (sap/ui/demo/mock/products.json)
    " with the columns the six table columns bind. The controller's
    " formatAvailableToObjectState is precomputed into AVAILABLESTATE, since
    " business logic belongs in the backend. ProductPicUrl values point at the
    " OpenUI5 host per the asset-URL rule; the mock carries them host-relative
    DATA temp5 TYPE z2ui5_cl_smpc_app_354=>ty_t_product.
    DATA temp6 LIKE LINE OF temp5.
    CLEAR temp5.
    
    temp6-name = `Notebook Basic 15`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 956.
    temp6-currencycode = `EUR`.
    temp6-quantity = 10.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 17`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1249.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 18`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1570.
    temp6-currencycode = `EUR`.
    temp6-quantity = 10.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 19`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 1650.
    temp6-currencycode = `EUR`.
    temp6-quantity = 15.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 299.
    temp6-currencycode = `EUR`.
    temp6-quantity = 15.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Professional 15`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 1999.
    temp6-currencycode = `EUR`.
    temp6-quantity = 16.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Professional 17`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 2299.
    temp6-currencycode = `EUR`.
    temp6-quantity = 17.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault Net`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 459.
    temp6-currencycode = `EUR`.
    temp6-quantity = 14.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault SAT`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 149.
    temp6-currencycode = `EUR`.
    temp6-quantity = 50.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Comfort Easy`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 1679.
    temp6-currencycode = `EUR`.
    temp6-quantity = 30.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Comfort Senior`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 512.
    temp6-currencycode = `EUR`.
    temp6-quantity = 24.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-I`.
    temp6-category = `Flat Screen Monitors`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 230.
    temp6-currencycode = `EUR`.
    temp6-quantity = 14.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-II`.
    temp6-category = `Flat Screen Monitors`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 285.
    temp6-currencycode = `EUR`.
    temp6-quantity = 24.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-III`.
    temp6-category = `Flat Screen Monitors`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 345.
    temp6-currencycode = `EUR`.
    temp6-quantity = 50.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Basic`.
    temp6-category = `Flat Screen Monitors`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 399.
    temp6-currencycode = `EUR`.
    temp6-quantity = 23.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Future`.
    temp6-category = `Flat Screen Monitors`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 430.
    temp6-currencycode = `EUR`.
    temp6-quantity = 22.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat XL`.
    temp6-category = `Flat Screen Monitors`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1230.
    temp6-currencycode = `EUR`.
    temp6-quantity = 23.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Professional Eco`.
    temp6-category = `Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 830.
    temp6-currencycode = `EUR`.
    temp6-quantity = 21.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Basic`.
    temp6-category = `Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 490.
    temp6-currencycode = `EUR`.
    temp6-quantity = 8.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Allround`.
    temp6-category = `Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 349.
    temp6-currencycode = `EUR`.
    temp6-quantity = 9.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Super Color`.
    temp6-category = `Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 139.
    temp6-currencycode = `EUR`.
    temp6-quantity = 17.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Mobile`.
    temp6-category = `Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 99.
    temp6-currencycode = `EUR`.
    temp6-quantity = 18.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Super Highspeed`.
    temp6-category = `Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 170.
    temp6-currencycode = `EUR`.
    temp6-quantity = 25.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Multi Print`.
    temp6-category = `Multifunction Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 99.
    temp6-currencycode = `EUR`.
    temp6-quantity = 16.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Multi Color`.
    temp6-category = `Multifunction Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 119.
    temp6-currencycode = `EUR`.
    temp6-quantity = 5.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cordless Mouse`.
    temp6-category = `Mice`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 9.
    temp6-currencycode = `EUR`.
    temp6-quantity = 25.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Speed Mouse`.
    temp6-category = `Mice`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 7.
    temp6-currencycode = `EUR`.
    temp6-quantity = 12.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Track Mouse`.
    temp6-category = `Mice`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 11.
    temp6-currencycode = `EUR`.
    temp6-quantity = 12.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergonomic Keyboard`.
    temp6-category = `Keyboards`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 14.
    temp6-currencycode = `EUR`.
    temp6-quantity = 50.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Internet Keyboard`.
    temp6-category = `Keyboards`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 16.
    temp6-currencycode = `EUR`.
    temp6-quantity = 35.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Media Keyboard`.
    temp6-category = `Keyboards`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 26.
    temp6-currencycode = `EUR`.
    temp6-quantity = 26.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Mousepad`.
    temp6-category = `Mousepads`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `6.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 12.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Mousepad`.
    temp6-category = `Mousepads`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = `8.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 16.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Designer Mousepad`.
    temp6-category = `Mousepads`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `12.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 26.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Universal card reader`.
    temp6-category = `Computer System Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 14.
    temp6-currencycode = `EUR`.
    temp6-quantity = 22.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Proctra X`.
    temp6-category = `Graphic Cards`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = `70.9`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 15.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gladiator MX`.
    temp6-category = `Graphic Cards`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = `81.7`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 16.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Hurricane GX`.
    temp6-category = `Graphic Cards`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `101.2`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 13.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Hurricane GX/LN`.
    temp6-category = `Graphic Cards`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = `139.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 5.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Photo Scan`.
    temp6-category = `Scanners`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 129.
    temp6-currencycode = `EUR`.
    temp6-quantity = 8.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Scan`.
    temp6-category = `Scanners`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 89.
    temp6-currencycode = `EUR`.
    temp6-quantity = 11.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Jet Scan Professional`.
    temp6-category = `Scanners`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 169.
    temp6-currencycode = `EUR`.
    temp6-quantity = 13.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Jet Scan Professional`.
    temp6-category = `Scanners`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 189.
    temp6-currencycode = `EUR`.
    temp6-quantity = 10.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Copymaster`.
    temp6-category = `Multifunction Printers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1499.
    temp6-currencycode = `EUR`.
    temp6-quantity = 10.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Surround Sound`.
    temp6-category = `Speakers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 39.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Blaster Extreme`.
    temp6-category = `Speakers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 26.
    temp6-currencycode = `EUR`.
    temp6-quantity = 15.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Sound Booster`.
    temp6-category = `Speakers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 45.
    temp6-currencycode = `EUR`.
    temp6-quantity = 50.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound 5.1 Wireless`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 49.
    temp6-currencycode = `EUR`.
    temp6-quantity = 12.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound 5.1`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 39.
    temp6-currencycode = `EUR`.
    temp6-quantity = 18.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound Stereo`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 29.
    temp6-currencycode = `EUR`.
    temp6-quantity = 21.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Office`.
    temp6-category = `Software`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = `89.9`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 25.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Design`.
    temp6-category = `Software`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `79.9`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 26.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Network`.
    temp6-category = `Software`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 69.
    temp6-currencycode = `EUR`.
    temp6-quantity = 28.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Multimedia`.
    temp6-category = `Software`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 77.
    temp6-currencycode = `EUR`.
    temp6-quantity = 9.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Games`.
    temp6-category = `Software`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 55.
    temp6-currencycode = `EUR`.
    temp6-quantity = 13.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Internet Antivirus`.
    temp6-category = `Software`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 29.
    temp6-currencycode = `EUR`.
    temp6-quantity = 17.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Firewall`.
    temp6-category = `Software`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 34.
    temp6-currencycode = `EUR`.
    temp6-quantity = 19.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Money`.
    temp6-category = `Software`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = `29.9`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 18.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `PC Lock`.
    temp6-category = `Computer System Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `8.9`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 14.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Lock`.
    temp6-category = `Computer System Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `6.9`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Web cam reality`.
    temp6-category = `Computer System Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 39.
    temp6-currencycode = `EUR`.
    temp6-quantity = 27.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Screen clean`.
    temp6-category = `Computer System Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `2.3`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 17.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Fabric bag professional`.
    temp6-category = `Computer System Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 31.
    temp6-currencycode = `EUR`.
    temp6-quantity = 14.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router`.
    temp6-category = `Telecommunications`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 49.
    temp6-currencycode = `EUR`.
    temp6-quantity = 16.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router / Repeater`.
    temp6-category = `Telecommunications`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 59.
    temp6-currencycode = `EUR`.
    temp6-quantity = 12.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router / Repeater and Print Server`.
    temp6-category = `Telecommunications`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 69.
    temp6-currencycode = `EUR`.
    temp6-quantity = 12.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `USB Stick`.
    temp6-category = `Computer System Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 35.
    temp6-currencycode = `EUR`.
    temp6-quantity = 14.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Travel Adapter`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 79.
    temp6-currencycode = `EUR`.
    temp6-quantity = 10.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cordless Bluetooth Keyboard, english international`.
    temp6-category = `Keyboards`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 29.
    temp6-currencycode = `EUR`.
    temp6-quantity = 13.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat XXL`.
    temp6-category = `Flat Screen Monitors`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 1430.
    temp6-currencycode = `EUR`.
    temp6-quantity = 10.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Pocket Mouse`.
    temp6-category = `Mice`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 23.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `PC Power Station`.
    temp6-category = `PCs`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 2399.
    temp6-currencycode = `EUR`.
    temp6-quantity = 22.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Astro Laptop 1516`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 989.
    temp6-currencycode = `EUR`.
    temp6-quantity = 23.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Astro Phone 6`.
    temp6-category = `Smartphones and Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 649.
    temp6-currencycode = `EUR`.
    temp6-quantity = 28.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Benda Laptop 1408`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 976.
    temp6-currencycode = `EUR`.
    temp6-quantity = 27.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Bending Screen 21HD`.
    temp6-category = `Flat Screens`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 250.
    temp6-currencycode = `EUR`.
    temp6-quantity = 23.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Broad Screen 22HD`.
    temp6-category = `Flat Screens`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 270.
    temp6-currencycode = `EUR`.
    temp6-quantity = 5.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cerdik Phone 7`.
    temp6-category = `Smartphones and Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 549.
    temp6-currencycode = `EUR`.
    temp6-quantity = 19.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cepat Tablet 10.5`.
    temp6-category = `Smartphones and Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 549.
    temp6-currencycode = `EUR`.
    temp6-quantity = 17.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cepat Tablet 8`.
    temp6-category = `Smartphones and Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 529.
    temp6-currencycode = `EUR`.
    temp6-quantity = 24.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Basic`.
    temp6-category = `Servers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 5000.
    temp6-currencycode = `EUR`.
    temp6-quantity = 24.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Professional`.
    temp6-category = `Servers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 15000.
    temp6-currencycode = `EUR`.
    temp6-quantity = 26.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Power Pro`.
    temp6-category = `Servers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 25000.
    temp6-currencycode = `EUR`.
    temp6-quantity = 34.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Family PC Basic`.
    temp6-category = `Desktop Computers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 600.
    temp6-currencycode = `EUR`.
    temp6-quantity = 10.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Family PC Pro`.
    temp6-category = `Desktop Computers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 900.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gaming Monster`.
    temp6-category = `Desktop Computers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1200.
    temp6-currencycode = `EUR`.
    temp6-quantity = 24.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gaming Monster Pro`.
    temp6-category = `Desktop Computers`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 1700.
    temp6-currencycode = `EUR`.
    temp6-quantity = 25.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `7" Widescreen Portable DVD Player w MP3`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `249.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `10" Portable DVD player`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `449.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 21.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Portable DVD Player with 9" LCD Monitor`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `853.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 50.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `CD/DVD case: 264 sleeves`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = `44.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 26.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Audio/Video Cable Kit - 4m`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = `29.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 16.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Removable CD/DVD Laser Labels`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = `8.99`.
    temp6-currencycode = `EUR`.
    temp6-quantity = 25.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-1`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 469.
    temp6-currencycode = `EUR`.
    temp6-quantity = 32.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-2`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 679.
    temp6-currencycode = `EUR`.
    temp6-quantity = 18.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-3`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 889.
    temp6-currencycode = `EUR`.
    temp6-quantity = 16.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Play Movie`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 130.
    temp6-currencycode = `EUR`.
    temp6-quantity = 15.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Record Movie`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 288.
    temp6-currencycode = `EUR`.
    temp6-quantity = 24.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelo MusicStick`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 45.
    temp6-currencycode = `EUR`.
    temp6-quantity = 15.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelo Jog-Mate`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 63.
    temp6-currencycode = `EUR`.
    temp6-quantity = 24.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Pro Player 40`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 167.
    temp6-currencycode = `EUR`.
    temp6-quantity = 23.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Pro Player 80`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 299.
    temp6-currencycode = `EUR`.
    temp6-quantity = 13.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD32`.
    temp6-category = `Flat Screen TVs`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1459.
    temp6-currencycode = `EUR`.
    temp6-quantity = 16.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD37`.
    temp6-category = `Flat Screen TVs`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1199.
    temp6-currencycode = `EUR`.
    temp6-quantity = 14.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD41`.
    temp6-category = `Flat Screen TVs`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 899.
    temp6-currencycode = `EUR`.
    temp6-quantity = 13.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Copperberry`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 549.
    temp6-currencycode = `EUR`.
    temp6-quantity = 5.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Silverberry`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 549.
    temp6-currencycode = `EUR`.
    temp6-quantity = 9.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Goldberry`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 549.
    temp6-currencycode = `EUR`.
    temp6-quantity = 11.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Platinberry`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 549.
    temp6-currencycode = `EUR`.
    temp6-quantity = 12.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I4000`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 799.
    temp6-currencycode = `EUR`.
    temp6-quantity = 11.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I6300c`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Discontinued`.
    temp6-price = 799.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I9100`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1199.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I9800`.
    temp6-category = `Laptops`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 1388.
    temp6-currencycode = `EUR`.
    temp6-quantity = 22.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Leather Case`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 25.
    temp6-currencycode = `EUR`.
    temp6-quantity = 12.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Alpha`.
    temp6-category = `Smartphones and Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 599.
    temp6-currencycode = `EUR`.
    temp6-quantity = 13.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Mini Tablet`.
    temp6-category = `Smartphones and Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 833.
    temp6-currencycode = `EUR`.
    temp6-quantity = 10.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Camcorder View`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 1388.
    temp6-currencycode = `EUR`.
    temp6-quantity = 50.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Tablet Pouch`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 20.
    temp6-currencycode = `EUR`.
    temp6-quantity = 34.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Tablet Pouch`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 20.
    temp6-currencycode = `EUR`.
    temp6-quantity = 34.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `e-Book Reader ReadMe`.
    temp6-category = `Smartphones and Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 33.
    temp6-currencycode = `EUR`.
    temp6-quantity = 23.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Beta`.
    temp6-category = `Smartphones and Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 30.
    temp6-currencycode = `EUR`.
    temp6-quantity = 21.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Maxi Tablet`.
    temp6-category = `Tablets`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp6-available = abap_true.
    temp6-availablestate = `Success`.
    temp6-status = `Available`.
    temp6-price = 749.
    temp6-currencycode = `EUR`.
    temp6-quantity = 20.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flyer`.
    temp6-category = `Accessories`.
    temp6-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp6-available = abap_false.
    temp6-availablestate = `Error`.
    temp6-status = `Out of Stock`.
    temp6-price = 0.
    temp6-currencycode = `EUR`.
    temp6-quantity = 33.
    INSERT temp6 INTO TABLE temp5.
    result = temp5.

  ENDMETHOD.


  METHOD model_init.

    " the original's `ui>` model defaults: no global filter, both toggles off
    t_products = catalog( ).

  ENDMETHOD.

ENDCLASS.
