" @keywords table sap.ui.table sorting overflowtoolbar title toolbarspacer button column label text link
" @summary Example showing the different kinds of sorting capabilities
" @origin sap.ui.table.sample.Sorting - https://sdk.openui5.org/entity/sap.ui.table.Table/sample/sap.ui.table.sample.Sorting (status: reviewed - read against the original, not run)
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
      DATA temp1 TYPE z2ui5_cl_smpc_app_362=>ty_s_sortkey.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      " Every sortOrder starts at the enum's own None. Leaving the other three
      " initial made them serialize as "" - which sap.ui.core.SortOrder rejects
      " outright, so the app terminated on its first render with
      " `"" is of type string, expected sap.ui.core.SortOrder`. The original
      " calls _resetSortingState for the same reason; sort_clear( ) is it.
      sort_clear( ).
      " the original sorts by Product Name ascending in onInit - and
      " oTable.sort( ) pushes that column onto the sorted-column list, so the
      " list starts with NAME in it rather than empty
      SORT t_products BY name ASCENDING.
      sort_name = `Ascending`.
      
      CLEAR temp1.
      temp1-field = `NAME`.
      temp1-descending = abap_false.
      APPEND temp1 TO t_sortkeys.
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp2 TYPE string_table.
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    " every sort of this sample happens in ABAP: the three toolbar buttons and
    " the column header menu all fire a backend event, the model comes back
    " sorted and each Column's sortOrder is bound so the indicator follows.
    " The sort event vetoes the control's own client-side sort, which is what
    " the original does for the delivery-date column (its date strings cannot
    " be compared as text - here the underlying timestamp is sorted instead).
    
    CLEAR temp2.
    INSERT `${$parameters>/column}.getSortProperty()` INTO TABLE temp2.
    INSERT `${$parameters>/sortOrder}` INTO TABLE temp2.
    
    CLEAR temp1.
    temp1-check_prevent_default = abap_true.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.ui.table`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`    v = `sap.ui.unified`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:m`    v = `sap.m`
        )->a( n = `height`     v = `100%`

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
                              val   = `SORT`
                              t_arg = temp2
                              s_ctrl = temp1 )

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
                            )->a( n = `sortOrder`    v = |\{= ${ client->_bind( sort_name ) } === 'Descending' ? 'Descending' : 'Ascending' \}|
                            )->a( n = `sorted`       v = |\{= ${ client->_bind( sort_name ) } !== 'None' \}|

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
                            )->a( n = `sortOrder`         v = |\{= ${ client->_bind( sort_category ) } === 'Descending' ? 'Descending' : 'Ascending' \}|
                            )->a( n = `sorted`            v = |\{= ${ client->_bind( sort_category ) } !== 'None' \}|

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
                            )->a( n = `sortOrder`    v = |\{= ${ client->_bind( sort_quantity ) } === 'Descending' ? 'Descending' : 'Ascending' \}|
                            )->a( n = `sorted`       v = |\{= ${ client->_bind( sort_quantity ) } !== 'None' \}|

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
                            )->a( n = `sortOrder`    v = |\{= ${ client->_bind( sort_deliverydate ) } === 'Descending' ? 'Descending' : 'Ascending' \}|
                            )->a( n = `sorted`       v = |\{= ${ client->_bind( sort_deliverydate ) } !== 'None' \}|

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
        DATA property TYPE string.
        DATA sort_order TYPE string.
        DATA ascending TYPE abap_bool.
        DATA temp1 TYPE xsdboolean.
        DATA temp4 TYPE z2ui5_cl_smpc_app_362=>ty_s_sortkey.
        DATA temp2 TYPE xsdboolean.
        DATA temp5 LIKE t_sortkeys.
        DATA temp6 LIKE LINE OF temp5.
        DATA temp7 TYPE ty_s_sortkey.
        DATA s_cat LIKE temp7.
          FIELD-SYMBOLS <temp8> LIKE LINE OF t_sortkeys.
          DATA temp9 LIKE sy-tabix.
        DATA temp10 TYPE string.
        DATA temp3 TYPE xsdboolean.

    CASE client->get_event( ).

      WHEN `SORT`.
        " sortDeliveryDate: no multi-column sorting - every other column's
        " indicator is reset first, then the pressed one is sorted. The
        " delivery-date column is the reason the sort runs server-side at all:
        " its cells hold dd/MM/yyyy STRINGS, which no text compare can order,
        " so the underlying timestamp is sorted instead (the ABAP equivalent of
        " the original's custom Sorter.fnCompare)
        
        property   = client->get_event_arg( ).
        
        sort_order = client->get_event_arg( 2 ).
        
        
        temp1 = boolc( sort_order <> `Descending` ).
        ascending  = temp1.
        sort_clear( ).

        CASE property.
          WHEN `NAME`.
            sort_name = sort_order.
            IF ascending = abap_true.
              SORT t_products BY name ASCENDING.
            ELSE.
              SORT t_products BY name DESCENDING.
            ENDIF.

          WHEN `CATEGORY`.
            sort_category = sort_order.
            IF ascending = abap_true.
              SORT t_products BY category ASCENDING.
            ELSE.
              SORT t_products BY category DESCENDING.
            ENDIF.

          WHEN `QUANTITY`.
            sort_quantity = sort_order.
            IF ascending = abap_true.
              SORT t_products BY quantity ASCENDING.
            ELSE.
              SORT t_products BY quantity DESCENDING.
            ENDIF.

          WHEN `DELIVERYDATESTR`.
            sort_deliverydate = sort_order.
            IF ascending = abap_true.
              SORT t_products BY deliverydate ASCENDING.
            ELSE.
              SORT t_products BY deliverydate DESCENDING.
            ENDIF.
        ENDCASE.

        " Column._sort ends in oTable.pushSortedColumn( this ), so the column
        " just sorted becomes the active sort key. sort_clear( ) above emptied
        " the list and nothing put the pressed column back until 2026-08-24,
        " which left t_sortkeys empty on this path - so a following
        " "Sort Categories in addition to current sorting" had nothing to add
        " to and ordered by Category ALONE, while sort_name still showed
        " Ascending. Exactly the header-lies-about-the-rows defect the
        " SORT_CATEGORIES branch below was fixed for on 2026-08-21, still live
        " on the menu path.
        
        CLEAR temp4.
        temp4-field = property.
        
        temp2 = boolc( ascending = abap_false ).
        temp4-descending = temp2.
        APPEND temp4 TO t_sortkeys.

      WHEN `SORT_CATEGORIES_AND_NAME`.
        " sortCategoriesAndName: Category ascending, then Name ascending
        sort_clear( ).
        
        CLEAR temp5.
        
        temp6-field = `CATEGORY`.
        INSERT temp6 INTO TABLE temp5.
        temp6-field = `NAME`.
        INSERT temp6 INTO TABLE temp5.
        t_sortkeys    = temp5.
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
        
        CLEAR temp7.
        temp7-field = `CATEGORY`.
        temp7-descending = category_descending.
        
        s_cat = temp7.
        READ TABLE t_sortkeys TRANSPORTING NO FIELDS WITH KEY field = `CATEGORY`.
        IF sy-subrc = 0.
          
          
          temp9 = sy-tabix.
          READ TABLE t_sortkeys INDEX sy-tabix ASSIGNING <temp8>.
          sy-tabix = temp9.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp8> = s_cat.
        ELSE.
          APPEND s_cat TO t_sortkeys.
        ENDIF.
        
        IF category_descending = abap_true.
          temp10 = `Descending`.
        ELSE.
          temp10 = `Ascending`.
        ENDIF.
        sort_category       = temp10.
        
        temp3 = boolc( category_descending = abap_false ).
        category_descending = temp3.
        sort_apply( ).

      WHEN `CLEAR_SORTINGS`.
        " clearAllSortings: drop the sorter and every column indicator - the
        " model goes back to the mock's own row order
        model_init( ).
        sort_clear( ).

    ENDCASE.


  ENDMETHOD.


  METHOD sort_clear.
    DATA temp11 LIKE t_sortkeys.

    " _resetSortingState: every column back to SortOrder.None
    sort_name         = `None`.
    sort_category     = `None`.
    sort_quantity     = `None`.
    sort_deliverydate = `None`.
    
    CLEAR temp11.
    t_sortkeys = temp11.
  ENDMETHOD.


  METHOD sort_apply.

    " Sort by the whole key list, primary first. ABAP has one sort key per
    " SORT, so the list is applied from the LAST key to the first with STABLE -
    " each pass preserves the order the previous one established, which leaves
    " the rows ordered by the list exactly as a multi-key sorter would.
    DATA index TYPE i.
      DATA s_key LIKE LINE OF t_sortkeys.
      FIELD-SYMBOLS <temp2> LIKE LINE OF t_sortkeys.
      DATA temp3 LIKE sy-tabix.
    index = lines( t_sortkeys ).
    WHILE index >= 1.
      
      
      
      temp3 = sy-tabix.
      READ TABLE t_sortkeys INDEX index ASSIGNING <temp2>.
      sy-tabix = temp3.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      s_key = <temp2>.
      " the component is named STATICALLY per key rather than through
      " SORT BY (s_key-field): the transpiled backend drops the dynamic BY
      " clause altogether (abap.statements.sort(t, {}) - **e2e-caught
      " 2026-08-22** on app 571), so the table came back in its original order
      CASE s_key-field.
        WHEN `CATEGORY`.
          IF s_key-descending = abap_true.
            SORT t_products STABLE BY category AS TEXT DESCENDING.
          ELSE.
            SORT t_products STABLE BY category AS TEXT ASCENDING.
          ENDIF.
        WHEN OTHERS.
          IF s_key-descending = abap_true.
            SORT t_products STABLE BY name AS TEXT DESCENDING.
          ELSE.
            SORT t_products STABLE BY name AS TEXT ASCENDING.
          ENDIF.
      ENDCASE.
      index = index - 1.
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
    DATA temp12 LIKE t_products.
    DATA temp13 LIKE LINE OF temp12.
    CLEAR temp12.
    
    temp13-name = `Notebook Basic 15`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp13-quantity = 10.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Basic 17`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Basic 18`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp13-quantity = 10.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Basic 19`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp13-quantity = 15.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO Vault`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp13-quantity = 15.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Professional 15`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp13-quantity = 16.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Professional 17`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp13-quantity = 17.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO Vault Net`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp13-quantity = 14.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO Vault SAT`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp13-quantity = 50.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Comfort Easy`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp13-quantity = 30.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Comfort Senior`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp13-quantity = 24.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergo Screen E-I`.
    temp13-category = `Flat Screen Monitors`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp13-quantity = 14.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergo Screen E-II`.
    temp13-category = `Flat Screen Monitors`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp13-quantity = 24.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergo Screen E-III`.
    temp13-category = `Flat Screen Monitors`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp13-quantity = 50.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Basic`.
    temp13-category = `Flat Screen Monitors`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp13-quantity = 23.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Future`.
    temp13-category = `Flat Screen Monitors`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp13-quantity = 22.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat XL`.
    temp13-category = `Flat Screen Monitors`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp13-quantity = 23.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Laser Professional Eco`.
    temp13-category = `Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp13-quantity = 21.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Laser Basic`.
    temp13-category = `Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp13-quantity = 8.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Laser Allround`.
    temp13-category = `Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp13-quantity = 9.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ultra Jet Super Color`.
    temp13-category = `Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp13-quantity = 17.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ultra Jet Mobile`.
    temp13-category = `Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp13-quantity = 18.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ultra Jet Super Highspeed`.
    temp13-category = `Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp13-quantity = 25.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Multi Print`.
    temp13-category = `Multifunction Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp13-quantity = 16.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Multi Color`.
    temp13-category = `Multifunction Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp13-quantity = 5.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cordless Mouse`.
    temp13-category = `Mice`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp13-quantity = 25.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Speed Mouse`.
    temp13-category = `Mice`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp13-quantity = 12.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Track Mouse`.
    temp13-category = `Mice`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp13-quantity = 12.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergonomic Keyboard`.
    temp13-category = `Keyboards`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp13-quantity = 50.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Internet Keyboard`.
    temp13-category = `Keyboards`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp13-quantity = 35.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Media Keyboard`.
    temp13-category = `Keyboards`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp13-quantity = 26.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Mousepad`.
    temp13-category = `Mousepads`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp13-quantity = 12.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Ergo Mousepad`.
    temp13-category = `Mousepads`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp13-quantity = 16.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Designer Mousepad`.
    temp13-category = `Mousepads`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp13-quantity = 26.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Universal card reader`.
    temp13-category = `Computer System Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp13-quantity = 22.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Proctra X`.
    temp13-category = `Graphic Cards`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp13-quantity = 15.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Gladiator MX`.
    temp13-category = `Graphic Cards`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp13-quantity = 16.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Hurricane GX`.
    temp13-category = `Graphic Cards`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp13-quantity = 13.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Hurricane GX/LN`.
    temp13-category = `Graphic Cards`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp13-quantity = 5.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Photo Scan`.
    temp13-category = `Scanners`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp13-quantity = 8.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Power Scan`.
    temp13-category = `Scanners`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp13-quantity = 11.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Jet Scan Professional`.
    temp13-category = `Scanners`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp13-quantity = 13.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Jet Scan Professional`.
    temp13-category = `Scanners`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp13-quantity = 10.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Copymaster`.
    temp13-category = `Multifunction Printers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp13-quantity = 10.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Surround Sound`.
    temp13-category = `Speakers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Blaster Extreme`.
    temp13-category = `Speakers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp13-quantity = 15.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Sound Booster`.
    temp13-category = `Speakers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp13-quantity = 50.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Lovely Sound 5.1 Wireless`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp13-quantity = 12.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Lovely Sound 5.1`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp13-quantity = 18.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Lovely Sound Stereo`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp13-quantity = 21.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Office`.
    temp13-category = `Software`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp13-quantity = 25.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Design`.
    temp13-category = `Software`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp13-quantity = 26.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Network`.
    temp13-category = `Software`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp13-quantity = 28.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Multimedia`.
    temp13-category = `Software`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp13-quantity = 9.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Games`.
    temp13-category = `Software`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp13-quantity = 13.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Internet Antivirus`.
    temp13-category = `Software`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp13-quantity = 17.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Firewall`.
    temp13-category = `Software`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp13-quantity = 19.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smart Money`.
    temp13-category = `Software`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp13-quantity = 18.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `PC Lock`.
    temp13-category = `Computer System Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp13-quantity = 14.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Notebook Lock`.
    temp13-category = `Computer System Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Web cam reality`.
    temp13-category = `Computer System Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp13-quantity = 27.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Screen clean`.
    temp13-category = `Computer System Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp13-quantity = 17.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Fabric bag professional`.
    temp13-category = `Computer System Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp13-quantity = 14.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Wireless DSL Router`.
    temp13-category = `Telecommunications`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp13-quantity = 16.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Wireless DSL Router / Repeater`.
    temp13-category = `Telecommunications`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp13-quantity = 12.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Wireless DSL Router / Repeater and Print Server`.
    temp13-category = `Telecommunications`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp13-quantity = 12.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `USB Stick`.
    temp13-category = `Computer System Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp13-quantity = 14.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Travel Adapter`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp13-quantity = 10.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cordless Bluetooth Keyboard, english international`.
    temp13-category = `Keyboards`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp13-quantity = 13.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat XXL`.
    temp13-category = `Flat Screen Monitors`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp13-quantity = 10.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Pocket Mouse`.
    temp13-category = `Mice`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `PC Power Station`.
    temp13-category = `PCs`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp13-quantity = 22.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Astro Laptop 1516`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp13-quantity = 23.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Astro Phone 6`.
    temp13-category = `Smartphones and Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp13-quantity = 28.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Benda Laptop 1408`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp13-quantity = 27.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Bending Screen 21HD`.
    temp13-category = `Flat Screens`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp13-quantity = 23.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Broad Screen 22HD`.
    temp13-category = `Flat Screens`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp13-quantity = 5.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cerdik Phone 7`.
    temp13-category = `Smartphones and Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp13-quantity = 19.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cepat Tablet 10.5`.
    temp13-category = `Smartphones and Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp13-quantity = 17.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Cepat Tablet 8`.
    temp13-category = `Smartphones and Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp13-quantity = 24.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Server Basic`.
    temp13-category = `Servers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp13-quantity = 24.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Server Professional`.
    temp13-category = `Servers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp13-quantity = 26.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Server Power Pro`.
    temp13-category = `Servers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp13-quantity = 34.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Family PC Basic`.
    temp13-category = `Desktop Computers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp13-quantity = 10.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Family PC Pro`.
    temp13-category = `Desktop Computers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Gaming Monster`.
    temp13-category = `Desktop Computers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp13-quantity = 24.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Gaming Monster Pro`.
    temp13-category = `Desktop Computers`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp13-quantity = 25.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `7" Widescreen Portable DVD Player w MP3`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `10" Portable DVD player`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp13-quantity = 21.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Portable DVD Player with 9" LCD Monitor`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp13-quantity = 50.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `CD/DVD case: 264 sleeves`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp13-quantity = 26.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Audio/Video Cable Kit - 4m`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp13-quantity = 16.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Removable CD/DVD Laser Labels`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp13-quantity = 25.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Beam Breaker B-1`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp13-quantity = 32.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Beam Breaker B-2`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp13-quantity = 18.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Beam Breaker B-3`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp13-quantity = 16.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Play Movie`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp13-quantity = 15.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Record Movie`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp13-quantity = 24.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelo MusicStick`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp13-quantity = 15.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelo Jog-Mate`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp13-quantity = 24.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Power Pro Player 40`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp13-quantity = 23.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Power Pro Player 80`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp13-quantity = 13.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Watch HD32`.
    temp13-category = `Flat Screen TVs`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp13-quantity = 16.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Watch HD37`.
    temp13-category = `Flat Screen TVs`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp13-quantity = 14.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flat Watch HD41`.
    temp13-category = `Flat Screen TVs`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp13-quantity = 13.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Copperberry`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp13-quantity = 5.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Silverberry`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp13-quantity = 9.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Goldberry`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp13-quantity = 11.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Platinberry`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp13-quantity = 12.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO FlexTop I4000`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp13-quantity = 11.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO FlexTop I6300c`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO FlexTop I9100`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `ITelO FlexTop I9800`.
    temp13-category = `Laptops`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp13-quantity = 22.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smartphone Leather Case`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp13-quantity = 12.
    temp13-deliverydatestr = `11/07/2026`.
    temp13-deliverydate = 1783728000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smartphone Alpha`.
    temp13-category = `Smartphones and Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp13-quantity = 13.
    temp13-deliverydatestr = `07/07/2026`.
    temp13-deliverydate = 1783382400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Mini Tablet`.
    temp13-category = `Smartphones and Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp13-quantity = 10.
    temp13-deliverydatestr = `03/07/2026`.
    temp13-deliverydate = 1783036800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Camcorder View`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp13-quantity = 50.
    temp13-deliverydatestr = `29/06/2026`.
    temp13-deliverydate = 1782691200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Tablet Pouch`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp13-quantity = 34.
    temp13-deliverydatestr = `25/06/2026`.
    temp13-deliverydate = 1782345600000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Tablet Pouch`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp13-quantity = 34.
    temp13-deliverydatestr = `21/06/2026`.
    temp13-deliverydate = 1782000000000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `e-Book Reader ReadMe`.
    temp13-category = `Smartphones and Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp13-quantity = 23.
    temp13-deliverydatestr = `17/06/2026`.
    temp13-deliverydate = 1781654400000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Smartphone Beta`.
    temp13-category = `Smartphones and Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp13-quantity = 21.
    temp13-deliverydatestr = `23/07/2026`.
    temp13-deliverydate = 1784764800000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Maxi Tablet`.
    temp13-category = `Tablets`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp13-quantity = 20.
    temp13-deliverydatestr = `19/07/2026`.
    temp13-deliverydate = 1784419200000.
    INSERT temp13 INTO TABLE temp12.
    temp13-name = `Flyer`.
    temp13-category = `Accessories`.
    temp13-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp13-quantity = 33.
    temp13-deliverydatestr = `15/07/2026`.
    temp13-deliverydate = 1784073600000.
    INSERT temp13 INTO TABLE temp12.
    t_products = temp12.

  ENDMETHOD.

ENDCLASS.
