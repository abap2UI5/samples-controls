" @keywords table sap.ui.table sorting column
" @summary Example showing the different kinds of sorting capabilities
CLASS z2ui5_cl_smpc_app_362 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name            TYPE string,
        category        TYPE string,
        productpicurl   TYPE string,
        quantity        TYPE i,
        deliverydatestr TYPE string,
        deliverydate    TYPE string,
      END OF ty_s_product.
    TYPES temp1_3359add38e TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_products TYPE temp1_3359add38e.

    " one field per sortable Column's sortOrder - the original drives them
    " imperatively (oTable.sort( column, order ) / setSortOrder), here the
    " sorting happens on the model and the indicator follows it
    DATA sort_name         TYPE string.
    DATA sort_category     TYPE string.
    DATA sort_quantity     TYPE string.
    DATA sort_deliverydate TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    " sortCategories alternates ascending / descending on every press
    DATA category_descending TYPE abap_bool.

    " The ACTIVE sorters, in precedence order - the model equivalent of the
    " table's own _aSortedColumns. sortCategories passes bAdd = true, which
    " pushes its column onto that list rather than replacing it, so the port
    " needs the list too: a single dynamic SORT can only ever express one key.
    TYPES:
      BEGIN OF ty_s_sortkey,
        field      TYPE string,
        descending TYPE abap_bool,
      END OF ty_s_sortkey.
    TYPES temp2_3359add38e TYPE STANDARD TABLE OF ty_s_sortkey WITH DEFAULT KEY.
DATA t_sortkeys TYPE temp2_3359add38e.

    METHODS view_display.
    METHODS on_event.
    METHODS sort_clear.
    METHODS sort_apply.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_362 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      " Every sortOrder starts at the enum's own None. Leaving the other three
      " initial made them serialize as "" - which sap.ui.core.SortOrder rejects
      " outright, so the app terminated on its first render with
      " `"" is of type string, expected sap.ui.core.SortOrder`. The original
      " calls _resetSortingState for the same reason; sort_clear( ) is it.
      sort_clear( ).
      " the original sorts by Product Name ascending in onInit
      SORT t_products BY name ASCENDING.
      sort_name = `Ascending`.
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

    " every sort of this sample happens in ABAP: the three toolbar buttons and
    " the column header menu all fire a backend event, the model comes back
    " sorted and each Column's sortOrder is bound so the indicator follows.
    " The sort event vetoes the control's own client-side sort, which is what
    " the original does for the delivery-date column (its date strings cannot
    " be compared as text - here the underlying timestamp is sorted instead).
    
    CLEAR temp1.
    INSERT `${$parameters>/column}.getSortProperty()` INTO TABLE temp1.
    INSERT `${$parameters>/sortOrder}` INTO TABLE temp1.
    
    CLEAR temp2.
    temp2-check_prevent_default = abap_true.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.ui.table`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`   v = `sap.ui.unified`
        )->a( n = `xmlns:c`   v = `sap.ui.core`
        )->a( n = `xmlns:m`   v = `sap.m`
        )->a( n = `height`    v = `100%`

        )->ele( n = `Page` ns = `m`
            )->a( n = `showHeader`      v = `false`
            )->a( n = `enableScrolling` v = `false`
            )->a( n = `class`           v = `sapUiContentPadding`

            )->ele( n = `content` ns = `m`
                )->ele( `Table`
                    )->a( n = `id`             v = `table`
                    )->a( n = `selectionMode`  v = `MultiToggle`
                    )->a( n = `rows`           v = client->_bind( t_products )
                    )->a( n = `ariaLabelledBy` v = `title`
                    )->a( n = `sort`           v = client->_event(
                              val    = `SORT`
                              t_arg  = temp1
                              s_ctrl = temp2 )

                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `style` v = `Clear`

                            )->tag( n = `Title` ns = `m`
                                )->a( n = `id`   v = `title`
                                )->a( n = `text` v = `Products`

                            )->tag( n = `ToolbarSpacer` ns = `m`

                            )->tag( n = `Button` ns = `m`
                                )->a( n = `icon`    v = `sap-icon://sorting-ranking`
                                )->a( n = `tooltip` v = `Sort ascending across Categories and Name`
                                )->a( n = `press`   v = client->_event( `SORT_CATEGORIES_AND_NAME` )

                            )->tag( n = `Button` ns = `m`
                                )->a( n = `icon`    v = `sap-icon://sort`
                                )->a( n = `tooltip` v = `Sort Categories in addition to current sorting`
                                )->a( n = `press`   v = client->_event( `SORT_CATEGORIES` )

                            )->tag( n = `Button` ns = `m`
                                )->a( n = `icon`    v = `sap-icon://decline`
                                )->a( n = `tooltip` v = `Clear all sortings`
                                )->a( n = `press`   v = client->_event( `CLEAR_SORTINGS` )

                        )->end(
                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`
                            )->a( n = `id`           v = `name`
                            )->a( n = `width`        v = `11rem`
                            )->a( n = `sortProperty` v = `NAME`
                            )->a( n = `sortOrder`    v = client->_bind( sort_name )

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Name`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{NAME}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id`                v = `categories`
                            )->a( n = `width`             v = `11rem`
                            )->a( n = `showSortMenuEntry` v = `false`
                            )->a( n = `sortProperty`      v = `CATEGORY`
                            )->a( n = `sortOrder`         v = client->_bind( sort_category )

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
                            )->a( n = `id`           v = `quantity`
                            )->a( n = `width`        v = `6rem`
                            )->a( n = `hAlign`       v = `End`
                            )->a( n = `sortProperty` v = `QUANTITY`
                            )->a( n = `sortOrder`    v = client->_bind( sort_quantity )

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Quantity`

                            )->ele( `template`
                                )->tag( n = `Label` ns = `m`
                                    )->a( n = `text` v = |\{ path: 'QUANTITY', type: 'sap.ui.model.type.Integer' \}|

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `id`           v = `deliverydate`
                            )->a( n = `width`        v = `9rem`
                            )->a( n = `sortProperty` v = `DELIVERYDATESTR`
                            )->a( n = `sortOrder`    v = client->_bind( sort_deliverydate )

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Delivery Date`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = |\{ path: 'DELIVERYDATESTR', type: 'sap.ui.model.type.Date', formatOptions: \{ source: \{ pattern: 'dd/MM/yyyy' \}, style: 'long' \} \}|
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                    )->end(
                    )->ele( `footer`
                        )->tag( n = `OverflowToolbar` ns = `m`
                            )->a( n = `id` v = `infobar` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA lv_property TYPE string.
        DATA lv_order TYPE string.
        DATA lv_ascending TYPE abap_bool.
        DATA temp1 TYPE xsdboolean.
        DATA temp3 LIKE t_sortkeys.
        DATA temp4 LIKE LINE OF temp3.
        DATA temp5 TYPE ty_s_sortkey.
        DATA ls_cat LIKE temp5.
          FIELD-SYMBOLS <temp6> LIKE LINE OF t_sortkeys.
          DATA temp7 LIKE sy-tabix.
        DATA temp8 TYPE string.
        DATA temp2 TYPE xsdboolean.

    CASE client->get_event( ).

      WHEN `SORT`.
        " sortDeliveryDate: no multi-column sorting - every other column's
        " indicator is reset first, then the pressed one is sorted. The
        " delivery-date column is the reason the sort runs server-side at all:
        " its cells hold dd/MM/yyyy STRINGS, which no text compare can order,
        " so the underlying timestamp is sorted instead (the ABAP equivalent of
        " the original's custom Sorter.fnCompare)
        
        lv_property  = client->get_event_arg( ).
        
        lv_order     = client->get_event_arg( 2 ).
        
        
        temp1 = boolc( lv_order <> `Descending` ).
        lv_ascending = temp1.
        sort_clear( ).

        CASE lv_property.
          WHEN `NAME`.
            sort_name = lv_order.
            IF lv_ascending = abap_true.
              SORT t_products BY name ASCENDING.
            ELSE.
              SORT t_products BY name DESCENDING.
            ENDIF.

          WHEN `CATEGORY`.
            sort_category = lv_order.
            IF lv_ascending = abap_true.
              SORT t_products BY category ASCENDING.
            ELSE.
              SORT t_products BY category DESCENDING.
            ENDIF.

          WHEN `QUANTITY`.
            sort_quantity = lv_order.
            IF lv_ascending = abap_true.
              SORT t_products BY quantity ASCENDING.
            ELSE.
              SORT t_products BY quantity DESCENDING.
            ENDIF.

          WHEN `DELIVERYDATESTR`.
            sort_deliverydate = lv_order.
            IF lv_ascending = abap_true.
              SORT t_products BY deliverydate ASCENDING.
            ELSE.
              SORT t_products BY deliverydate DESCENDING.
            ENDIF.
        ENDCASE.

      WHEN `SORT_CATEGORIES_AND_NAME`.
        " sortCategoriesAndName: Category ascending, then Name ascending
        sort_clear( ).
        
        CLEAR temp3.
        
        temp4-field = `CATEGORY`.
        INSERT temp4 INTO TABLE temp3.
        temp4-field = `NAME`.
        INSERT temp4 INTO TABLE temp3.
        t_sortkeys    = temp3.
        sort_category = `Ascending`.
        sort_name     = `Ascending`.
        sort_apply( ).

      WHEN `SORT_CATEGORIES`.
        " sortCategories passes bAdd = TRUE - Table.pushSortedColumn appends
        " the column to the active sorter list, so whatever was sorting keeps
        " precedence and Category is added behind it. Until 2026-08-21 this
        " issued a fresh single-key SORT instead, which reordered the whole
        " table while leaving the other columns' indicators standing: the
        " header claimed Name-ascending while the rows were Category-ascending.
        " The button's own tooltip says "in addition to current sorting".
        
        CLEAR temp5.
        temp5-field = `CATEGORY`.
        temp5-descending = category_descending.
        
        ls_cat = temp5.
        READ TABLE t_sortkeys TRANSPORTING NO FIELDS WITH KEY field = `CATEGORY`.
        IF sy-subrc = 0.
          
          
          temp7 = sy-tabix.
          READ TABLE t_sortkeys INDEX sy-tabix ASSIGNING <temp6>.
          sy-tabix = temp7.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp6> = ls_cat.
        ELSE.
          APPEND ls_cat TO t_sortkeys.
        ENDIF.
        
        IF category_descending = abap_true.
          temp8 = `Descending`.
        ELSE.
          temp8 = `Ascending`.
        ENDIF.
        sort_category       = temp8.
        
        temp2 = boolc( category_descending = abap_false ).
        category_descending = temp2.
        sort_apply( ).

      WHEN `CLEAR_SORTINGS`.
        " clearAllSortings: drop the sorter and every column indicator - the
        " model goes back to the mock's own row order
        model_init( ).
        sort_clear( ).

    ENDCASE.


  ENDMETHOD.


  METHOD sort_clear.

    " _resetSortingState: every column back to SortOrder.None
    sort_name         = `None`.
    sort_category     = `None`.
    sort_quantity     = `None`.
    sort_deliverydate = `None`.
    CLEAR t_sortkeys.

  ENDMETHOD.


  METHOD sort_apply.

    " Sort by the whole key list, primary first. ABAP has one sort key per
    " SORT, so the list is applied from the LAST key to the first with STABLE -
    " each pass preserves the order the previous one established, which leaves
    " the rows ordered by the list exactly as a multi-key sorter would.
    DATA lv_index TYPE i.
      DATA ls_key LIKE LINE OF t_sortkeys.
      DATA temp3 LIKE LINE OF t_sortkeys.
      DATA temp4 LIKE sy-tabix.
    lv_index = lines( t_sortkeys ).
    WHILE lv_index >= 1.
      
      
      
      temp4 = sy-tabix.
      READ TABLE t_sortkeys INDEX lv_index INTO temp3.
      sy-tabix = temp4.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      ls_key = temp3.
      IF ls_key-descending = abap_true.
        SORT t_products STABLE BY (ls_key-field) DESCENDING.
      ELSE.
        SORT t_products STABLE BY (ls_key-field) ASCENDING.
      ENDIF.
      lv_index = lv_index - 1.
    ENDWHILE.

  ENDMETHOD.


  METHOD model_init.

    " the shared 123-row demo ProductCollection (sap/ui/demo/mock/products.json)
    " with the five columns the sample binds. DeliveryDate is Date.now()-derived
    " in the original (i mod 10 offset in 4-day steps); a fixed base (2026-07-23)
    " is used here so the port is deterministic - the corpus convention of app
    " 164. DeliveryDateStr is that timestamp formatted dd/MM/yyyy, exactly what
    " the controller's DateFormat produces; the raw timestamp is kept alongside
    " it as the sort key the original needs its custom compare function for.
    DATA temp9 LIKE t_products.
    DATA temp10 LIKE LINE OF temp9.
    CLEAR temp9.
    
    temp10-name = `Notebook Basic 15`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp10-quantity = 10.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Notebook Basic 17`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Notebook Basic 18`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp10-quantity = 10.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Notebook Basic 19`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp10-quantity = 15.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelO Vault`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp10-quantity = 15.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Notebook Professional 15`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp10-quantity = 16.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Notebook Professional 17`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp10-quantity = 17.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelO Vault Net`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp10-quantity = 14.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelO Vault SAT`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp10-quantity = 50.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Comfort Easy`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp10-quantity = 30.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Comfort Senior`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp10-quantity = 24.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Ergo Screen E-I`.
    temp10-category = `Flat Screen Monitors`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp10-quantity = 14.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Ergo Screen E-II`.
    temp10-category = `Flat Screen Monitors`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp10-quantity = 24.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Ergo Screen E-III`.
    temp10-category = `Flat Screen Monitors`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp10-quantity = 50.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Flat Basic`.
    temp10-category = `Flat Screen Monitors`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp10-quantity = 23.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Flat Future`.
    temp10-category = `Flat Screen Monitors`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp10-quantity = 22.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Flat XL`.
    temp10-category = `Flat Screen Monitors`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp10-quantity = 23.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Laser Professional Eco`.
    temp10-category = `Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp10-quantity = 21.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Laser Basic`.
    temp10-category = `Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp10-quantity = 8.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Laser Allround`.
    temp10-category = `Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp10-quantity = 9.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Ultra Jet Super Color`.
    temp10-category = `Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp10-quantity = 17.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Ultra Jet Mobile`.
    temp10-category = `Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp10-quantity = 18.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Ultra Jet Super Highspeed`.
    temp10-category = `Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp10-quantity = 25.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Multi Print`.
    temp10-category = `Multifunction Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp10-quantity = 16.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Multi Color`.
    temp10-category = `Multifunction Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp10-quantity = 5.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Cordless Mouse`.
    temp10-category = `Mice`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp10-quantity = 25.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Speed Mouse`.
    temp10-category = `Mice`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp10-quantity = 12.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Track Mouse`.
    temp10-category = `Mice`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp10-quantity = 12.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Ergonomic Keyboard`.
    temp10-category = `Keyboards`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp10-quantity = 50.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Internet Keyboard`.
    temp10-category = `Keyboards`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp10-quantity = 35.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Media Keyboard`.
    temp10-category = `Keyboards`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp10-quantity = 26.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Mousepad`.
    temp10-category = `Mousepads`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp10-quantity = 12.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Ergo Mousepad`.
    temp10-category = `Mousepads`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp10-quantity = 16.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Designer Mousepad`.
    temp10-category = `Mousepads`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp10-quantity = 26.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Universal card reader`.
    temp10-category = `Computer System Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp10-quantity = 22.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Proctra X`.
    temp10-category = `Graphic Cards`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp10-quantity = 15.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Gladiator MX`.
    temp10-category = `Graphic Cards`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp10-quantity = 16.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Hurricane GX`.
    temp10-category = `Graphic Cards`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp10-quantity = 13.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Hurricane GX/LN`.
    temp10-category = `Graphic Cards`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp10-quantity = 5.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Photo Scan`.
    temp10-category = `Scanners`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp10-quantity = 8.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Power Scan`.
    temp10-category = `Scanners`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp10-quantity = 11.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Jet Scan Professional`.
    temp10-category = `Scanners`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp10-quantity = 13.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Jet Scan Professional`.
    temp10-category = `Scanners`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp10-quantity = 10.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Copymaster`.
    temp10-category = `Multifunction Printers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp10-quantity = 10.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Surround Sound`.
    temp10-category = `Speakers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Blaster Extreme`.
    temp10-category = `Speakers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp10-quantity = 15.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Sound Booster`.
    temp10-category = `Speakers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp10-quantity = 50.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Lovely Sound 5.1 Wireless`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp10-quantity = 12.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Lovely Sound 5.1`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp10-quantity = 18.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Lovely Sound Stereo`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp10-quantity = 21.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smart Office`.
    temp10-category = `Software`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp10-quantity = 25.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smart Design`.
    temp10-category = `Software`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp10-quantity = 26.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smart Network`.
    temp10-category = `Software`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp10-quantity = 28.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smart Multimedia`.
    temp10-category = `Software`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp10-quantity = 9.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smart Games`.
    temp10-category = `Software`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp10-quantity = 13.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smart Internet Antivirus`.
    temp10-category = `Software`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp10-quantity = 17.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smart Firewall`.
    temp10-category = `Software`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp10-quantity = 19.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smart Money`.
    temp10-category = `Software`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp10-quantity = 18.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `PC Lock`.
    temp10-category = `Computer System Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp10-quantity = 14.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Notebook Lock`.
    temp10-category = `Computer System Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Web cam reality`.
    temp10-category = `Computer System Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp10-quantity = 27.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Screen clean`.
    temp10-category = `Computer System Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp10-quantity = 17.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Fabric bag professional`.
    temp10-category = `Computer System Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp10-quantity = 14.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Wireless DSL Router`.
    temp10-category = `Telecommunications`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp10-quantity = 16.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Wireless DSL Router / Repeater`.
    temp10-category = `Telecommunications`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp10-quantity = 12.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Wireless DSL Router / Repeater and Print Server`.
    temp10-category = `Telecommunications`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp10-quantity = 12.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `USB Stick`.
    temp10-category = `Computer System Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp10-quantity = 14.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Travel Adapter`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp10-quantity = 10.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Cordless Bluetooth Keyboard, english international`.
    temp10-category = `Keyboards`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp10-quantity = 13.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Flat XXL`.
    temp10-category = `Flat Screen Monitors`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp10-quantity = 10.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Pocket Mouse`.
    temp10-category = `Mice`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `PC Power Station`.
    temp10-category = `PCs`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp10-quantity = 22.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Astro Laptop 1516`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp10-quantity = 23.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Astro Phone 6`.
    temp10-category = `Smartphones and Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp10-quantity = 28.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Benda Laptop 1408`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp10-quantity = 27.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Bending Screen 21HD`.
    temp10-category = `Flat Screens`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp10-quantity = 23.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Broad Screen 22HD`.
    temp10-category = `Flat Screens`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp10-quantity = 5.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Cerdik Phone 7`.
    temp10-category = `Smartphones and Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp10-quantity = 19.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Cepat Tablet 10.5`.
    temp10-category = `Smartphones and Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp10-quantity = 17.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Cepat Tablet 8`.
    temp10-category = `Smartphones and Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp10-quantity = 24.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Server Basic`.
    temp10-category = `Servers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp10-quantity = 24.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Server Professional`.
    temp10-category = `Servers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp10-quantity = 26.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Server Power Pro`.
    temp10-category = `Servers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp10-quantity = 34.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Family PC Basic`.
    temp10-category = `Desktop Computers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp10-quantity = 10.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Family PC Pro`.
    temp10-category = `Desktop Computers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Gaming Monster`.
    temp10-category = `Desktop Computers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp10-quantity = 24.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Gaming Monster Pro`.
    temp10-category = `Desktop Computers`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp10-quantity = 25.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `7" Widescreen Portable DVD Player w MP3`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `10" Portable DVD player`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp10-quantity = 21.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Portable DVD Player with 9" LCD Monitor`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp10-quantity = 50.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `CD/DVD case: 264 sleeves`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp10-quantity = 26.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Audio/Video Cable Kit - 4m`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp10-quantity = 16.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Removable CD/DVD Laser Labels`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp10-quantity = 25.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Beam Breaker B-1`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp10-quantity = 32.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Beam Breaker B-2`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp10-quantity = 18.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Beam Breaker B-3`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp10-quantity = 16.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Play Movie`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp10-quantity = 15.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Record Movie`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp10-quantity = 24.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelo MusicStick`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp10-quantity = 15.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelo Jog-Mate`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp10-quantity = 24.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Power Pro Player 40`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp10-quantity = 23.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Power Pro Player 80`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp10-quantity = 13.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Flat Watch HD32`.
    temp10-category = `Flat Screen TVs`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp10-quantity = 16.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Flat Watch HD37`.
    temp10-category = `Flat Screen TVs`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp10-quantity = 14.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Flat Watch HD41`.
    temp10-category = `Flat Screen TVs`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp10-quantity = 13.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Copperberry`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp10-quantity = 5.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Silverberry`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp10-quantity = 9.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Goldberry`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp10-quantity = 11.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Platinberry`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp10-quantity = 12.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelO FlexTop I4000`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp10-quantity = 11.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelO FlexTop I6300c`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelO FlexTop I9100`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `ITelO FlexTop I9800`.
    temp10-category = `Laptops`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp10-quantity = 22.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smartphone Leather Case`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp10-quantity = 12.
    temp10-deliverydatestr = `11/07/2026`.
    temp10-deliverydate = 1783728000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smartphone Alpha`.
    temp10-category = `Smartphones and Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp10-quantity = 13.
    temp10-deliverydatestr = `07/07/2026`.
    temp10-deliverydate = 1783382400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Mini Tablet`.
    temp10-category = `Smartphones and Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp10-quantity = 10.
    temp10-deliverydatestr = `03/07/2026`.
    temp10-deliverydate = 1783036800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Camcorder View`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp10-quantity = 50.
    temp10-deliverydatestr = `29/06/2026`.
    temp10-deliverydate = 1782691200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Tablet Pouch`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp10-quantity = 34.
    temp10-deliverydatestr = `25/06/2026`.
    temp10-deliverydate = 1782345600000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Tablet Pouch`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp10-quantity = 34.
    temp10-deliverydatestr = `21/06/2026`.
    temp10-deliverydate = 1782000000000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `e-Book Reader ReadMe`.
    temp10-category = `Smartphones and Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp10-quantity = 23.
    temp10-deliverydatestr = `17/06/2026`.
    temp10-deliverydate = 1781654400000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Smartphone Beta`.
    temp10-category = `Smartphones and Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp10-quantity = 21.
    temp10-deliverydatestr = `23/07/2026`.
    temp10-deliverydate = 1784764800000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Maxi Tablet`.
    temp10-category = `Tablets`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp10-quantity = 20.
    temp10-deliverydatestr = `19/07/2026`.
    temp10-deliverydate = 1784419200000.
    INSERT temp10 INTO TABLE temp9.
    temp10-name = `Flyer`.
    temp10-category = `Accessories`.
    temp10-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp10-quantity = 33.
    temp10-deliverydatestr = `15/07/2026`.
    temp10-deliverydate = 1784073600000.
    INSERT temp10 INTO TABLE temp9.
    t_products = temp9.

  ENDMETHOD.

ENDCLASS.
