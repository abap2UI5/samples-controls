" @keywords table sap.ui.table tablefreeze column
" @summary Example which shows table freeze with fixed columns
CLASS z2ui5_cl_smpc_app_363 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name           TYPE string,
        productid      TYPE string,
        quantity       TYPE i,
        status         TYPE string,
        availablestate TYPE string,
        availableicon  TYPE string,
        price          TYPE p LENGTH 13 DECIMALS 2,
        currencycode   TYPE string,
        suppliername   TYPE string,
        productpicurl  TYPE string,
        heavy          TYPE string,
        category       TYPE string,
        deliverydate   TYPE string,
      END OF ty_s_product,
      BEGIN OF ty_s_name,
        name TYPE string,
      END OF ty_s_name.
    DATA t_products   TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
    DATA t_suppliers  TYPE STANDARD TABLE OF ty_s_name WITH DEFAULT KEY.
    DATA t_categories TYPE STANDARD TABLE OF ty_s_name WITH DEFAULT KEY.

    " the Inputs and the Table are bound to DIFFERENT fields on purpose: an
    " Input writes its value back as a STRING, and feeding that into the
    " int-typed fixedColumnCount / fixedTopRowCount / fixedBottomRowCount kills
    " the view outright ("20" is of type string, expected int). The original
    " keeps them apart the same way - it parseInts the Input and only then
    " calls setFixedColumnCount - so Apply converts, clamps, and writes the
    " corrected number back into the Input, which is the original's setValue.
    DATA column_count_text      TYPE string.
    DATA top_row_count_text     TYPE string.
    DATA bottom_row_count_text  TYPE string.
    DATA fixed_column_count     TYPE i.
    DATA fixed_top_row_count    TYPE i.
    DATA fixed_bottom_row_count TYPE i.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    CONSTANTS cv_total_columns TYPE i VALUE 12.
    CONSTANTS cv_total_rows    TYPE i VALUE 10.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_363 IMPLEMENTATION.

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

    " the freeze demo: the three count Inputs are two-way bound and the Table's
    " fixedColumnCount and the rowMode's fixedTopRowCount / fixedBottomRowCount
    " bind the same fields, so the Apply press only clamps them in ABAP - the
    " validation the original does in buttonPress before calling the setters.
    
    CLEAR temp1.
    INSERT `MESSAGE_TOAST` INTO TABLE temp1.
    INSERT `show` INTO TABLE temp1.
    INSERT `Details for product with id {0}` INTO TABLE temp1.
    INSERT `${PRODUCTID}` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`          v = `sap.ui.table`
        )->a( n = `xmlns:rowmodes` v = `sap.ui.table.rowmodes`
        )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`        v = `sap.ui.unified`
        )->a( n = `xmlns:c`        v = `sap.ui.core`
        )->a( n = `xmlns:m`        v = `sap.m`
        )->a( n = `height`         v = `100%`

        )->ele( n = `Page` ns = `m`
            )->a( n = `showHeader`      v = `false`
            )->a( n = `enableScrolling` v = `false`
            )->a( n = `class`           v = `sapUiContentPadding`

            )->ele( n = `content` ns = `m`
                )->ele( `Table`
                    )->a( n = `id`               v = `table1`
                    )->a( n = `rows`             v = client->_bind( t_products )
                    )->a( n = `selectionMode`    v = `MultiToggle`
                    )->a( n = `fixedColumnCount` v = client->_bind( fixed_column_count )
                    )->a( n = `ariaLabelledBy`   v = `title`

                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `style` v = `Clear`

                            )->tag( n = `Title` ns = `m`
                                )->a( n = `id`   v = `title`
                                )->a( n = `text` v = `Products`

                            )->tag( n = `ToolbarSpacer` ns = `m`

                            )->tag( n = `Input` ns = `m`
                                )->a( n = `id`          v = `inputColumn`
                                )->a( n = `width`       v = `20%`
                                )->a( n = `placeholder` v = `fixed column count`
                                )->a( n = `tooltip`     v = `fixed column count`
                                )->a( n = `value`       v = client->_bind( column_count_text )

                            )->tag( n = `Input` ns = `m`
                                )->a( n = `id`          v = `inputRow`
                                )->a( n = `width`       v = `20%`
                                )->a( n = `placeholder` v = `fixed row count`
                                )->a( n = `tooltip`     v = `fixed row count`
                                )->a( n = `value`       v = client->_bind( top_row_count_text )

                            )->tag( n = `Input` ns = `m`
                                )->a( n = `id`          v = `inputBottomRow`
                                )->a( n = `width`       v = `20%`
                                )->a( n = `placeholder` v = `fixed bottom row count`
                                )->a( n = `tooltip`     v = `fixed bottom row count`
                                )->a( n = `value`       v = client->_bind( bottom_row_count_text )

                            )->tag( n = `Button` ns = `m`
                                )->a( n = `id`    v = `button`
                                )->a( n = `text`  v = `Apply`
                                )->a( n = `press` v = client->_event( `APPLY` )

                        )->end(
                    )->end(
                    )->ele( `rowMode`
                        )->tag( n = `Fixed` ns = `rowmodes`
                            )->a( n = `fixedTopRowCount`    v = client->_bind( fixed_top_row_count )
                            )->a( n = `fixedBottomRowCount` v = client->_bind( fixed_bottom_row_count )

                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`
                            )->a( n = `width` v = `11rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Name`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{NAME}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `11rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Id`

                            )->ele( `template`
                                )->tag( n = `Input` ns = `m`
                                    )->a( n = `value` v = `{PRODUCTID}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width`  v = `6rem`
                            )->a( n = `hAlign` v = `End`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Quantity`

                            )->ele( `template`
                                )->tag( n = `Label` ns = `m`
                                    )->a( n = `text` v = `{QUANTITY}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `9rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Status`

                            )->ele( `template`
                                )->tag( n = `ObjectStatus` ns = `m`
                                    )->a( n = `text`  v = `{STATUS}`
                                    )->a( n = `state` v = `{AVAILABLESTATE}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `9rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Price`

                            )->ele( `template`
                                )->tag( n = `Currency` ns = `u`
                                    )->a( n = `value`    v = `{PRICE}`
                                    )->a( n = `currency` v = `{CURRENCYCODE}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `12rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Supplier`

                            )->ele( `template`
                                )->ele( n = `ComboBox` ns = `m`
                                    )->a( n = `value` v = `{SUPPLIERNAME}`
                                    )->a( n = `items` v = |\{ path: '{ client->_bind( val = t_suppliers path = abap_true ) }', templateShareable: false \}|

                                    )->tag( n = `Item` ns = `c`
                                        )->a( n = `text` v = `{NAME}`

                                )->end(
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
                            )->a( n = `width` v = `9rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Details`

                            )->ele( `template`
                                )->tag( n = `Button` ns = `m`
                                    )->a( n = `text`  v = `Show Details`
                                    )->a( n = `press` v = client->follow_up_action(
                                              val   = client->cs_event-control_global
                                              t_arg = temp1 )

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `7rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Heavy Weight`

                            )->ele( `template`
                                )->tag( n = `CheckBox` ns = `m`
                                    )->a( n = `selected` v = |\{ path: 'HEAVY', type: 'sap.ui.model.type.String' \}|

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `12rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Category`

                            )->ele( `template`
                                )->ele( n = `Select` ns = `m`
                                    )->a( n = `selectedKey` v = `{CATEGORY}`
                                    )->a( n = `items`       v = |\{ path: '{ client->_bind( val = t_categories path = abap_true ) }', templateShareable: false \}|

                                    )->tag( n = `Item` ns = `c`
                                        )->a( n = `text` v = `{NAME}`
                                        )->a( n = `key`  v = `{NAME}`

                                )->end(
                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width`  v = `6rem`
                            )->a( n = `hAlign` v = `Center`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Status`

                            )->ele( `template`
                                )->tag( n = `Icon` ns = `c`
                                    )->a( n = `src` v = `{AVAILABLEICON}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width`  v = `11rem`
                            )->a( n = `hAlign` v = `Center`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Delivery Date`

                            )->ele( `template`
                                )->tag( n = `DatePicker` ns = `m`
                                    )->a( n = `value` v = |\{ path: 'DELIVERYDATE', type: 'sap.ui.model.type.Date', formatOptions: \{ source: \{ pattern: 'timestamp' \} \} \}|

                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE i.
        DATA temp4 TYPE i.
        DATA temp5 TYPE i.

    IF client->get_event( ) = `APPLY`.
      " buttonPress: read the Inputs the way the original parseInts them, then
      " clamp against the table's own totals and tell the user when a value
      " had to be corrected. A non-numeric entry keeps the last value - the
      " original's parseInt would hand setFixedColumnCount a NaN there.
      IF column_count_text CO ` 0123456789` AND column_count_text IS NOT INITIAL.
        
        temp3 = column_count_text.
        fixed_column_count = temp3.
      ENDIF.
      IF top_row_count_text CO ` 0123456789` AND top_row_count_text IS NOT INITIAL.
        
        temp4 = top_row_count_text.
        fixed_top_row_count = temp4.
      ENDIF.
      IF bottom_row_count_text CO ` 0123456789` AND bottom_row_count_text IS NOT INITIAL.
        
        temp5 = bottom_row_count_text.
        fixed_bottom_row_count = temp5.
      ENDIF.

      IF fixed_column_count > cv_total_columns.
        fixed_column_count = cv_total_columns.
        client->message_toast_display( `Fixed column count exceeds the total column count. Value in column count input got updated.` ).
      ENDIF.

      IF fixed_top_row_count + fixed_bottom_row_count > cv_total_rows.
        IF fixed_top_row_count < cv_total_rows AND fixed_bottom_row_count < cv_total_rows.
          fixed_bottom_row_count = 1.
        ELSEIF fixed_top_row_count > cv_total_rows AND fixed_bottom_row_count < cv_total_rows.
          fixed_top_row_count = cv_total_rows - fixed_bottom_row_count - 1.
        ELSEIF fixed_top_row_count < cv_total_rows AND fixed_bottom_row_count > cv_total_rows.
          fixed_bottom_row_count = cv_total_rows - fixed_top_row_count - 1.
        ELSE.
          fixed_top_row_count    = 1.
          fixed_bottom_row_count = 1.
        ENDIF.
        client->message_toast_display( `Sum of fixed row count and bottom row count exceeds the total row count. Input values got updated.` ).
      ENDIF.

      " the original's oView.byId( ... ).setValue( ) - the corrected numbers
      " travel back into the Inputs
      column_count_text     = |{ fixed_column_count }|.
      top_row_count_text    = |{ fixed_top_row_count }|.
      bottom_row_count_text = |{ fixed_bottom_row_count }|.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " The three Inputs start EMPTY, as in the original, which gives them no
    " value at all - so their placeholders ("fixed column count" and friends)
    " are what the user sees, and buttonPress reads them as getValue( ) || 0.
    " Until 2026-08-21 they were seeded from the freeze counts, i.e. with "0",
    " and sap.m.Input hides the placeholder as soon as a value is set: the port
    " opened with three zeroes where the sample opens with three hints. The
    " counts themselves stay 0; only the text fields are unset.

    " the shared 123-row demo ProductCollection (sap/ui/demo/mock/products.json)
    " with the columns the twelve table columns bind. DeliveryDate is
    " Date.now()-derived in the original (i mod 10 offset in 4-day steps); a
    " fixed base (2026-07-23) is used here so the port is deterministic - the
    " corpus convention of app 164. Heavy is WeightMeasure > 1000 as the string
    " the typed CheckBox binding expects, and the two Available formatters of
    " the controller are precomputed into AVAILABLESTATE / AVAILABLEICON, since
    " business logic belongs in the backend.
    DATA temp6 LIKE t_products.
    DATA temp7 LIKE LINE OF temp6.
    DATA temp8 LIKE t_suppliers.
    DATA temp9 LIKE LINE OF temp8.
    DATA temp10 LIKE t_categories.
    DATA temp11 LIKE LINE OF temp10.
    CLEAR temp6.
    
    temp7-name = `Notebook Basic 15`.
    temp7-productid = `HT-1000`.
    temp7-quantity = 10.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 956.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 17`.
    temp7-productid = `HT-1001`.
    temp7-quantity = 20.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1249.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 18`.
    temp7-productid = `HT-1002`.
    temp7-quantity = 10.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1570.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 19`.
    temp7-productid = `HT-1003`.
    temp7-quantity = 15.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 1650.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Smartcards`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault`.
    temp7-productid = `HT-1007`.
    temp7-quantity = 15.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 299.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Professional 15`.
    temp7-productid = `HT-1010`.
    temp7-quantity = 16.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 1999.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Professional 17`.
    temp7-productid = `HT-1011`.
    temp7-quantity = 17.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 2299.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault Net`.
    temp7-productid = `HT-1020`.
    temp7-quantity = 14.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 459.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault SAT`.
    temp7-productid = `HT-1021`.
    temp7-quantity = 50.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 149.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Comfort Easy`.
    temp7-productid = `HT-1022`.
    temp7-quantity = 30.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 1679.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Comfort Senior`.
    temp7-productid = `HT-1023`.
    temp7-quantity = 24.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 512.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-I`.
    temp7-productid = `HT-1030`.
    temp7-quantity = 14.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 230.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen Monitors`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-II`.
    temp7-productid = `HT-1031`.
    temp7-quantity = 24.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 285.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen Monitors`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-III`.
    temp7-productid = `HT-1032`.
    temp7-quantity = 50.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 345.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen Monitors`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Basic`.
    temp7-productid = `HT-1035`.
    temp7-quantity = 23.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 399.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen Monitors`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Future`.
    temp7-productid = `HT-1036`.
    temp7-quantity = 22.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 430.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen Monitors`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat XL`.
    temp7-productid = `HT-1037`.
    temp7-quantity = 23.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1230.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen Monitors`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Professional Eco`.
    temp7-productid = `HT-1040`.
    temp7-quantity = 21.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 830.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Alpha Printers`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Printers`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Basic`.
    temp7-productid = `HT-1041`.
    temp7-quantity = 8.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 490.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Alpha Printers`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Printers`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Allround`.
    temp7-productid = `HT-1042`.
    temp7-quantity = 9.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 349.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Alpha Printers`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Printers`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Super Color`.
    temp7-productid = `HT-1050`.
    temp7-quantity = 17.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 139.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Alpha Printers`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Printers`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Mobile`.
    temp7-productid = `HT-1051`.
    temp7-quantity = 18.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 99.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Printer for All`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Printers`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Super Highspeed`.
    temp7-productid = `HT-1052`.
    temp7-quantity = 25.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 170.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Printer for All`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Printers`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Multi Print`.
    temp7-productid = `HT-1055`.
    temp7-quantity = 16.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 99.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Printer for All`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Multifunction Printers`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Multi Color`.
    temp7-productid = `HT-1056`.
    temp7-quantity = 5.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 119.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Printer for All`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Multifunction Printers`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cordless Mouse`.
    temp7-productid = `HT-1060`.
    temp7-quantity = 25.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 9.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Oxynum`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Mice`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Speed Mouse`.
    temp7-productid = `HT-1061`.
    temp7-quantity = 12.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 7.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Oxynum`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Mice`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Track Mouse`.
    temp7-productid = `HT-1062`.
    temp7-quantity = 12.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 11.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Oxynum`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Mice`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergonomic Keyboard`.
    temp7-productid = `HT-1063`.
    temp7-quantity = 50.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 14.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Oxynum`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Keyboards`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Internet Keyboard`.
    temp7-productid = `HT-1064`.
    temp7-quantity = 35.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 16.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Oxynum`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Keyboards`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Media Keyboard`.
    temp7-productid = `HT-1065`.
    temp7-quantity = 26.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 26.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Oxynum`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Keyboards`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Mousepad`.
    temp7-productid = `HT-1066`.
    temp7-quantity = 12.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `6.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Oxynum`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Mousepads`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Mousepad`.
    temp7-productid = `HT-1067`.
    temp7-quantity = 16.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = `8.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Oxynum`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Mousepads`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Designer Mousepad`.
    temp7-productid = `HT-1068`.
    temp7-quantity = 26.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `12.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Mousepads`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Universal card reader`.
    temp7-productid = `HT-1069`.
    temp7-quantity = 22.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 14.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Computer System Accessories`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Proctra X`.
    temp7-productid = `HT-1070`.
    temp7-quantity = 15.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = `70.9`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Graphic Cards`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gladiator MX`.
    temp7-productid = `HT-1071`.
    temp7-quantity = 16.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = `81.7`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Graphic Cards`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Hurricane GX`.
    temp7-productid = `HT-1072`.
    temp7-quantity = 13.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `101.2`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Graphic Cards`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Hurricane GX/LN`.
    temp7-productid = `HT-1073`.
    temp7-quantity = 5.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = `139.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Smartcards`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Graphic Cards`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Photo Scan`.
    temp7-productid = `HT-1080`.
    temp7-quantity = 8.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 129.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Printer for All`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Scanners`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Scan`.
    temp7-productid = `HT-1081`.
    temp7-quantity = 11.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 89.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Printer for All`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Scanners`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Jet Scan Professional`.
    temp7-productid = `HT-1082`.
    temp7-quantity = 13.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 169.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Printer for All`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Scanners`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Jet Scan Professional`.
    temp7-productid = `HT-1083`.
    temp7-quantity = 10.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 189.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Printer for All`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Scanners`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Copymaster`.
    temp7-productid = `HT-1085`.
    temp7-quantity = 10.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1499.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Alpha Printers`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Multifunction Printers`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Surround Sound`.
    temp7-productid = `HT-1090`.
    temp7-quantity = 20.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 39.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Speaker Experts`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Speakers`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Blaster Extreme`.
    temp7-productid = `HT-1091`.
    temp7-quantity = 15.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 26.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Speaker Experts`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Speakers`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Sound Booster`.
    temp7-productid = `HT-1092`.
    temp7-quantity = 50.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 45.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Speaker Experts`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Speakers`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound 5.1 Wireless`.
    temp7-productid = `HT-1095`.
    temp7-quantity = 12.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 49.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound 5.1`.
    temp7-productid = `HT-1096`.
    temp7-quantity = 18.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 39.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound Stereo`.
    temp7-productid = `HT-1097`.
    temp7-quantity = 21.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 29.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Office`.
    temp7-productid = `HT-1100`.
    temp7-quantity = 25.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = `89.9`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Software`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Design`.
    temp7-productid = `HT-1101`.
    temp7-quantity = 26.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `79.9`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Software`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Network`.
    temp7-productid = `HT-1102`.
    temp7-quantity = 28.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 69.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Software`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Multimedia`.
    temp7-productid = `HT-1103`.
    temp7-quantity = 9.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 77.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Software`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Games`.
    temp7-productid = `HT-1104`.
    temp7-quantity = 13.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 55.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Software`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Internet Antivirus`.
    temp7-productid = `HT-1105`.
    temp7-quantity = 17.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 29.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Brainsoft`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Software`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Firewall`.
    temp7-productid = `HT-1106`.
    temp7-quantity = 19.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 34.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Brainsoft`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Software`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Money`.
    temp7-productid = `HT-1107`.
    temp7-quantity = 18.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = `29.9`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Brainsoft`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Software`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `PC Lock`.
    temp7-productid = `HT-1110`.
    temp7-quantity = 14.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `8.9`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Red Point Stores`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Computer System Accessories`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Lock`.
    temp7-productid = `HT-1111`.
    temp7-quantity = 20.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `6.9`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Red Point Stores`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Computer System Accessories`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Web cam reality`.
    temp7-productid = `HT-1112`.
    temp7-quantity = 27.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 39.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Red Point Stores`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Computer System Accessories`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Screen clean`.
    temp7-productid = `HT-1113`.
    temp7-quantity = 17.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `2.3`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Red Point Stores`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Computer System Accessories`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Fabric bag professional`.
    temp7-productid = `HT-1114`.
    temp7-quantity = 14.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 31.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Red Point Stores`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Computer System Accessories`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router`.
    temp7-productid = `HT-1115`.
    temp7-quantity = 16.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 49.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Red Point Stores`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Telecommunications`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router / Repeater`.
    temp7-productid = `HT-1116`.
    temp7-quantity = 12.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 59.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Red Point Stores`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Telecommunications`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router / Repeater and Print Server`.
    temp7-productid = `HT-1117`.
    temp7-quantity = 12.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 69.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Telecommunications`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `USB Stick`.
    temp7-productid = `HT-1118`.
    temp7-quantity = 14.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 35.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Computer System Accessories`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Travel Adapter`.
    temp7-productid = `HT-1119`.
    temp7-quantity = 10.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 79.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cordless Bluetooth Keyboard, english international`.
    temp7-productid = `HT-1120`.
    temp7-quantity = 13.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 29.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Keyboards`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat XXL`.
    temp7-productid = `HT-1137`.
    temp7-quantity = 10.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 1430.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen Monitors`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Pocket Mouse`.
    temp7-productid = `HT-1138`.
    temp7-quantity = 20.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 23.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Mice`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `PC Power Station`.
    temp7-productid = `HT-1210`.
    temp7-quantity = 22.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 2399.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp7-heavy = `false`.
    temp7-category = `PCs`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Astro Laptop 1516`.
    temp7-productid = `HT-1251`.
    temp7-quantity = 23.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 989.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Astro Phone 6`.
    temp7-productid = `HT-1252`.
    temp7-quantity = 28.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 649.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Smartphones and Tablets`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Benda Laptop 1408`.
    temp7-productid = `HT-1253`.
    temp7-quantity = 27.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 976.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Bending Screen 21HD`.
    temp7-productid = `HT-1254`.
    temp7-quantity = 23.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 250.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screens`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Broad Screen 22HD`.
    temp7-productid = `HT-1255`.
    temp7-quantity = 5.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 270.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screens`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cerdik Phone 7`.
    temp7-productid = `HT-1256`.
    temp7-quantity = 19.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 549.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Smartphones and Tablets`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cepat Tablet 10.5`.
    temp7-productid = `HT-1257`.
    temp7-quantity = 17.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 549.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Smartphones and Tablets`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cepat Tablet 8`.
    temp7-productid = `HT-1258`.
    temp7-quantity = 24.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 529.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Smartphones and Tablets`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Basic`.
    temp7-productid = `HT-1500`.
    temp7-quantity = 24.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 5000.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Servers`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Professional`.
    temp7-productid = `HT-1501`.
    temp7-quantity = 26.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 15000.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Servers`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Power Pro`.
    temp7-productid = `HT-1502`.
    temp7-quantity = 34.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 25000.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Servers`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Family PC Basic`.
    temp7-productid = `HT-1600`.
    temp7-quantity = 10.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 600.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Desktop Computers`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Family PC Pro`.
    temp7-productid = `HT-1601`.
    temp7-quantity = 20.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 900.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Desktop Computers`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gaming Monster`.
    temp7-productid = `HT-1602`.
    temp7-quantity = 24.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1200.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Desktop Computers`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gaming Monster Pro`.
    temp7-productid = `HT-1603`.
    temp7-quantity = 25.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 1700.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Desktop Computers`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `7" Widescreen Portable DVD Player w MP3`.
    temp7-productid = `HT-2000`.
    temp7-quantity = 20.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `249.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `10" Portable DVD player`.
    temp7-productid = `HT-2001`.
    temp7-quantity = 21.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `449.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Portable DVD Player with 9" LCD Monitor`.
    temp7-productid = `HT-2002`.
    temp7-quantity = 50.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `853.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `CD/DVD case: 264 sleeves`.
    temp7-productid = `HT-2025`.
    temp7-quantity = 26.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = `44.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Audio/Video Cable Kit - 4m`.
    temp7-productid = `HT-2026`.
    temp7-quantity = 16.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = `29.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Removable CD/DVD Laser Labels`.
    temp7-productid = `HT-2027`.
    temp7-quantity = 25.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = `8.99`.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-1`.
    temp7-productid = `HT-6100`.
    temp7-quantity = 32.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 469.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-2`.
    temp7-productid = `HT-6101`.
    temp7-quantity = 18.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 679.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-3`.
    temp7-productid = `HT-6102`.
    temp7-quantity = 16.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 889.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Technocom`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Play Movie`.
    temp7-productid = `HT-6110`.
    temp7-quantity = 15.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 130.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Record Movie`.
    temp7-productid = `HT-6111`.
    temp7-quantity = 24.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 288.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelo MusicStick`.
    temp7-productid = `HT-6120`.
    temp7-quantity = 15.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 45.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelo Jog-Mate`.
    temp7-productid = `HT-6121`.
    temp7-quantity = 24.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 63.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Pro Player 40`.
    temp7-productid = `HT-6122`.
    temp7-quantity = 23.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 167.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Pro Player 80`.
    temp7-productid = `HT-6123`.
    temp7-quantity = 13.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 299.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD32`.
    temp7-productid = `HT-6130`.
    temp7-quantity = 16.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1459.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen TVs`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD37`.
    temp7-productid = `HT-6131`.
    temp7-quantity = 14.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1199.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen TVs`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD41`.
    temp7-productid = `HT-6132`.
    temp7-quantity = 13.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 899.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Very Best Screens`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Flat Screen TVs`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Copperberry`.
    temp7-productid = `HT-7000`.
    temp7-quantity = 5.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 549.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Silverberry`.
    temp7-productid = `HT-7010`.
    temp7-quantity = 9.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 549.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Goldberry`.
    temp7-productid = `HT-7020`.
    temp7-quantity = 11.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 549.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Platinberry`.
    temp7-productid = `HT-7030`.
    temp7-quantity = 12.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 549.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Fasttech`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I4000`.
    temp7-productid = `HT-8000`.
    temp7-quantity = 11.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 799.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I6300c`.
    temp7-productid = `HT-8001`.
    temp7-quantity = 20.
    temp7-status = `Discontinued`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 799.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I9100`.
    temp7-productid = `HT-8002`.
    temp7-quantity = 20.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1199.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I9800`.
    temp7-productid = `HT-8003`.
    temp7-quantity = 22.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 1388.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Laptops`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Leather Case`.
    temp7-productid = `HT-9991`.
    temp7-quantity = 12.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 25.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1783728000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Alpha`.
    temp7-productid = `HT-9992`.
    temp7-quantity = 13.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 599.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Smartphones and Tablets`.
    temp7-deliverydate = 1783382400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Mini Tablet`.
    temp7-productid = `HT-9993`.
    temp7-quantity = 10.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 833.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Smartphones and Tablets`.
    temp7-deliverydate = 1783036800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Camcorder View`.
    temp7-productid = `HT-9994`.
    temp7-quantity = 50.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 1388.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782691200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Tablet Pouch`.
    temp7-productid = `HT-9995`.
    temp7-quantity = 34.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 20.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782345600000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Tablet Pouch`.
    temp7-productid = `HT-9996`.
    temp7-quantity = 34.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 20.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1782000000000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `e-Book Reader ReadMe`.
    temp7-productid = `HT-9997`.
    temp7-quantity = 23.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 33.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Smartphones and Tablets`.
    temp7-deliverydate = 1781654400000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Beta`.
    temp7-productid = `HT-9998`.
    temp7-quantity = 21.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 30.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Smartphones and Tablets`.
    temp7-deliverydate = 1784764800000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Maxi Tablet`.
    temp7-productid = `HT-9999`.
    temp7-quantity = 20.
    temp7-status = `Available`.
    temp7-availablestate = `Success`.
    temp7-availableicon = `sap-icon://accept`.
    temp7-price = 749.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Tablets`.
    temp7-deliverydate = 1784419200000.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flyer`.
    temp7-productid = `PF-1000`.
    temp7-quantity = 33.
    temp7-status = `Out of Stock`.
    temp7-availablestate = `Error`.
    temp7-availableicon = `sap-icon://decline`.
    temp7-price = 0.
    temp7-currencycode = `EUR`.
    temp7-suppliername = `Titanium`.
    temp7-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp7-heavy = `false`.
    temp7-category = `Accessories`.
    temp7-deliverydate = 1784073600000.
    INSERT temp7 INTO TABLE temp6.
    t_products = temp6.

    " the Suppliers / Categories collections the controller derives from the
    " products for the two in-cell dropdowns - the distinct values, in first
    " appearance order, exactly as the JS loop collects them
    
    CLEAR temp8.
    
    temp9-name = `Very Best Screens`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smartcards`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Technocom`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Alpha Printers`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Printer for All`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Oxynum`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Fasttech`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ultrasonic United`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Speaker Experts`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Brainsoft`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Red Point Stores`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Titanium`.
    INSERT temp9 INTO TABLE temp8.
    t_suppliers = temp8.

    
    CLEAR temp10.
    
    temp11-name = `Laptops`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Accessories`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat Screen Monitors`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Printers`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Multifunction Printers`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Mice`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Keyboards`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Mousepads`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Computer System Accessories`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Graphic Cards`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Scanners`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Speakers`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Software`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Telecommunications`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `PCs`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Smartphones and Tablets`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat Screens`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Servers`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Desktop Computers`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Flat Screen TVs`.
    INSERT temp11 INTO TABLE temp10.
    temp11-name = `Tablets`.
    INSERT temp11 INTO TABLE temp10.
    t_categories = temp10.

  ENDMETHOD.

ENDCLASS.
