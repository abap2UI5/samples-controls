" @keywords overflowtoolbar overflow toolbar sap.m overflowtoolbarfooter messagestrip slider toolbarspacer searchfield overflowtoolbarlayoutdata button overflowtoolbarbutton
" @summary Overflow Toolbar Button is useful for showing lists of action buttons that can display an icon in the toolbar, and icon+text when in the overflow.
" @origin sap.m.sample.OverflowToolbarFooter - https://sdk.openui5.org/entity/sap.m.OverflowToolbar/sample/sap.m.sample.OverflowToolbarFooter (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_607 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name         TYPE string,
        productid    TYPE string,
        suppliername TYPE string,
        width        TYPE string,
        depth        TYPE string,
        height       TYPE string,
        dimunit      TYPE string,
        price        TYPE string,
        currencycode TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    DATA t_products   TYPE ty_t_product.
    DATA slider_value TYPE i VALUE 100.
    DATA search_query TYPE string.
    DATA toggle_state TYPE abap_bool.

  PROTECTED SECTION.
    DATA client           TYPE REF TO z2ui5_if_client.
    DATA grouped          TYPE abap_bool.
    " the sort direction the binding_call sorter is rebuilt with - class
    " state no view binds, so it stays out of the model
    DATA descending       TYPE abap_bool.
    " set by filters_apply, so a rebuilt view knows an ordering is in force.
    " It cannot be derived from grouped/descending: RESET clears both and still
    " applies a Name-ascending sorter, exactly as fnApplyFiltersAndOrdering does
    DATA ordering_applied TYPE abap_bool.

    " PROTECTED, not PRIVATE: the app's state is serialized into the draft with
    " CALL TRANSFORMATION id, and the transpiled runtime's re-implementation of
    " it walks the attributes with a dynamic ASSIGN obj->(name), which cannot
    " reach a PRIVATE one - it asserts, and every roundtrip 500s with
    " ASSERTION_FAILED (e2e-caught 2026-08-22)
    DATA t_all TYPE ty_t_product.

    METHODS view_display.
    METHODS on_event.
    METHODS filters_apply.
    METHODS ordering_issue.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_607 IMPLEMENTATION.

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
    DATA root TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA temp2 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    root = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc` ).

    root->tag( n = `InvisibleText` ns = `core`
        )->a( n = `id`   v = `text1`
        )->a( n = `text` v = `Label text` ).

    
    page = root->ele( `Page`
        )->a( n = `showHeader`      v = `false`
        )->a( n = `enableScrolling` v = `true`
        )->a( n = `class`           v = `sapUiContentPadding`
        )->a( n = `showNavButton`   v = `false` ).

    
    content = page->ele( `content` ).

    content->ele( `VBox`
        )->tag( `MessageStrip`
            )->a( n = `text`     v = `Use this slider to shrink the toolbars and observe their behavior. Note: the icon buttons display text only when in the overflow area.`
            )->a( n = `type`     v = `Information`
            )->a( n = `showIcon` v = `true`
        " onSliderMoved sets both toolbars' width to <value>%; width is bindable,
        " so the two are expressions over the two-way bound slider value
        )->tag( `Slider`
            )->a( n = `value` v = client->_bind( slider_value )

    )->end( ).

    content->tag( `Label` ).

    
    table = content->ele( `Table`
        )->a( n = `id`    v = `idProductsTable`
        )->a( n = `items` v = client->_bind( t_products ) ).

    
    CLEAR temp1.
    INSERT `MESSAGE_TOAST` INTO TABLE temp1.
    INSERT `show` INTO TABLE temp1.
    INSERT `Default action triggered` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `MESSAGE_TOAST` INTO TABLE temp2.
    INSERT `show` INTO TABLE temp2.
    INSERT `beforeMenuOpen is fired` INTO TABLE temp2.
    table->ele( `headerToolbar`
        )->ele( `OverflowToolbar`
            )->a( n = `id`    v = `otbSubheader`
            )->a( n = `width` v = |\{= ${ client->_bind( slider_value ) } + '%' \}|

            )->tag( `ToolbarSpacer`

            )->ele( `SearchField`
                )->a( n = `ariaLabelledBy` v = `text1`
                )->a( n = `id`             v = `maxPrice`
                )->a( n = `value`          v = client->_bind( search_query )
                " onFilter runs on liveChange; the final value is the bindable
                " equivalent, so the port filters on search / change instead
                )->a( n = `search`         v = client->_event( `FILTER` )
                )->ele( `layoutData`
                    )->tag( `OverflowToolbarLayoutData`
                        )->a( n = `maxWidth`   v = `300px`
                        )->a( n = `shrinkable` v = `true`
                        )->a( n = `priority`   v = `NeverOverflow`

                )->end(
            )->end(

            )->tag( `Button`
                )->a( n = `text`  v = `Reset`
                )->a( n = `type`  v = `Transparent`
                )->a( n = `press` v = client->_event( `RESET` )
            )->tag( `OverflowToolbarButton`
                )->a( n = `tooltip` v = `Sort`
                )->a( n = `type`    v = `Transparent`
                )->a( n = `text`    v = `Sort`
                )->a( n = `icon`    v = `sap-icon://sort`
                )->a( n = `press`   v = client->_event( `SORT` )
            )->tag( `OverflowToolbarButton`
                )->a( n = `tooltip` v = `Group`
                )->a( n = `type`    v = `Transparent`
                )->a( n = `text`    v = `Group`
                )->a( n = `icon`    v = `sap-icon://group-2`
                )->a( n = `press`   v = client->_event( `GROUP` )

            )->ele( `OverflowToolbarMenuButton`
                )->a( n = `tooltip`              v = `Export`
                )->a( n = `type`                 v = `Transparent`
                )->a( n = `text`                 v = `Export`
                )->a( n = `buttonMode`           v = `Split`
                )->a( n = `icon`                 v = `sap-icon://share`
                )->a( n = `useDefaultActionOnly` v = `true`
                )->a( n = `defaultAction`        v = client->follow_up_action( val   = client->cs_event-control_global
                                                                               t_arg = temp1 )
                )->a( n = `beforeMenuOpen`       v = client->follow_up_action( val   = client->cs_event-control_global
                                                                               t_arg = temp2 )
                )->ele( `menu`
                    )->ele( `Menu`
                        )->a( n = `itemSelected` v = client->_event( val = `MENU_ACTION` arg = `${$parameters>/item}.getText()` )
                        )->tag( `MenuItem`
                            )->a( n = `text` v = `Export as PDF`
                            )->a( n = `icon` v = `sap-icon://pdf-attachment`
                        )->tag( `MenuItem`
                            )->a( n = `text` v = `Export to Excel`
                            )->a( n = `icon` v = `sap-icon://excel-attachment`

                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    table->ele( `columns`
        )->ele( `Column`
            )->a( n = `width` v = `12em`
            )->tag( `Text`
                )->a( n = `text` v = `Product`

        )->end(
        )->ele( `Column`
            )->a( n = `minScreenWidth` v = `Tablet`
            )->a( n = `demandPopin`    v = `true`
            )->tag( `Text`
                )->a( n = `text` v = `Supplier`

        )->end(
        )->ele( `Column`
            )->a( n = `minScreenWidth` v = `Tablet`
            )->a( n = `demandPopin`    v = `true`
            )->a( n = `hAlign`         v = `End`
            )->tag( `Text`
                )->a( n = `text` v = `Dimensions`

        )->end(
        )->ele( `Column`
            )->a( n = `hAlign` v = `End`
            )->tag( `Text`
                )->a( n = `text` v = `Price`

        )->end(
    )->end( ).

    table->ele( `items`
        )->ele( `ColumnListItem`
            )->ele( `cells`
                )->tag( `ObjectIdentifier`
                    )->a( n = `title` v = `{NAME}`
                    )->a( n = `text`  v = `{PRODUCTID}`
                )->tag( `Text`
                    )->a( n = `text` v = `{SUPPLIERNAME}`
                )->tag( `Text`
                    )->a( n = `text` v = `{WIDTH} x {DEPTH} x {HEIGHT} {DIMUNIT}`
                )->tag( `ObjectNumber`
                    )->a( n = `number` v = |\{ parts:[\{path:'PRICE'\},\{path:'CURRENCYCODE'\}],| &&
                                           | type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: false\} \}|
                    )->a( n = `unit`   v = `{CURRENCYCODE}`

            )->end(
        )->end(
    )->end( ).

    page->ele( `footer`
        )->ele( `OverflowToolbar`
            )->a( n = `id`    v = `otbFooter`
            )->a( n = `width` v = |\{= ${ client->_bind( slider_value ) } + '%' \}|

            )->tag( `ToolbarSpacer`
            )->ele( `Button`
                )->a( n = `type` v = `Accept`
                )->a( n = `text` v = `Accept`
                )->ele( `layoutData`
                    )->tag( `OverflowToolbarLayoutData`
                        )->a( n = `priority` v = `NeverOverflow`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `type` v = `Reject`
                )->a( n = `text` v = `Reject`
                )->ele( `layoutData`
                    )->tag( `OverflowToolbarLayoutData`
                        )->a( n = `priority` v = `NeverOverflow`

                )->end(
            )->end(

            )->tag( `OverflowToolbarButton`
                )->a( n = `tooltip` v = `Delete`
                )->a( n = `text`    v = `Delete`
                )->a( n = `icon`    v = `sap-icon://delete`
            )->tag( `OverflowToolbarButton`
                )->a( n = `tooltip` v = `Edit`
                )->a( n = `text`    v = `Edit`
                )->a( n = `icon`    v = `sap-icon://edit`
            )->tag( `OverflowToolbarButton`
                )->a( n = `tooltip` v = `Add`
                )->a( n = `text`    v = `Add`
                )->a( n = `icon`    v = `sap-icon://add`
            )->tag( `OverflowToolbarButton`
                )->a( n = `tooltip` v = `Favorite`
                )->a( n = `text`    v = `Favorite`
                )->a( n = `icon`    v = `sap-icon://favorite`
            )->tag( `OverflowToolbarButton`
                )->a( n = `tooltip` v = `Flag`
                )->a( n = `text`    v = `Flag`
                )->a( n = `icon`    v = `sap-icon://flag`
            )->tag( `OverflowToolbarToggleButton`
                )->a( n = `id`      v = `toggleButton`
                )->a( n = `tooltip` v = `Toggle`
                )->a( n = `text`    v = `Toggle`
                )->a( n = `icon`    v = `sap-icon://touch`
                )->a( n = `pressed` v = client->_bind( toggle_state )
                )->a( n = `press`   v = client->_event( `TOGGLE` )

        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).

    " A rebuilt view creates a FRESH items binding with an empty aSorters, so the
    " client-side ordering is gone - while grouped/descending/search_query are
    " class state that survives. Without this the Sort and Group buttons report a
    " state the rows do not show, and the ABAP filter (which lives in t_products)
    " survives while the sorter does not: asymmetric, and invisible in a run that
    " never leaves the app. check_on_navigated takes exactly this path
    IF ordering_applied = abap_true.
      ordering_issue( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string.
        DATA temp1 TYPE xsdboolean.
        DATA temp2 TYPE xsdboolean.
        DATA temp4 TYPE string.

    CASE client->get_event( ).

      WHEN `FILTER`.
        " onFilter: the search field's value becomes the Name Contains filter
        filters_apply( ).

      WHEN `RESET`.
        " onReset: clears the search field and both flags, then re-applies
        
        CLEAR temp3.
        search_query = temp3.
        grouped    = abap_false.
        descending = abap_false.
        filters_apply( ).

      WHEN `SORT`.
        " onSort flips the sorter's descending flag
        
        temp1 = boolc( descending = abap_false ).
        descending = temp1.
        filters_apply( ).

      WHEN `GROUP`.
        " onGroup flips between the SupplierName grouper and the Name sorter
        
        temp2 = boolc( grouped = abap_false ).
        grouped = temp2.
        filters_apply( ).

      WHEN `MENU_ACTION`.
        client->message_toast_display( |Action triggered on item: { client->get_event_arg( ) }| ).

      WHEN `TOGGLE`.
        
        IF toggle_state = abap_true.
          temp4 = `Pressed`.
        ELSE.
          temp4 = `Unpressed`.
        ENDIF.
        client->message_toast_display( |toggleButton { temp4 }| ).

    ENDCASE.

  ENDMETHOD.


  METHOD filters_apply.

    " fnApplyFiltersAndOrdering: a Name Contains filter plus one Sorter - on
    " SupplierName when grouped, on Name otherwise, descending when flipped.
    " The filter is applied here, over the data this thin frontend sends
    " (app 298 idiom); the SORTER is handed to the live binding instead, so
    " UI5 builds it itself and can draw the grey SupplierName group headers
    " the sample's _fnGroup produces. binding_call's sort takes
    " [path, descending, group], and UI5's DEFAULT group function returns
    " \{ key, text \} of the sorted property - which is exactly what _fnGroup
    " returns, so the third parameter reproduces the sample's headers rather
    " than approximating them.
    t_products = t_all.

    IF search_query IS NOT INITIAL.
      DELETE t_products WHERE name NS search_query.
    ENDIF.

    ordering_applied = abap_true.
    ordering_issue( ).

  ENDMETHOD.


  METHOD ordering_issue.

    " the sorter lives on the LIVE binding, so it does not survive a rebuild -
    " issued from filters_apply and again from view_display (the app-000 idiom)
    DATA temp5 TYPE string_table.
    DATA temp4 TYPE string.
    DATA temp6 TYPE string.
    DATA temp7 TYPE string.
    CLEAR temp5.
    INSERT `idProductsTable` INTO TABLE temp5.
    INSERT `items` INTO TABLE temp5.
    INSERT `sort` INTO TABLE temp5.
    
    IF grouped = abap_true.
      temp4 = `SUPPLIERNAME`.
    ELSE.
      temp4 = `NAME`.
    ENDIF.
    INSERT temp4 INTO TABLE temp5.
    
    IF descending = abap_true.
      temp6 = `X`.
    ELSE.
      temp6 = ``.
    ENDIF.
    INSERT temp6 INTO TABLE temp5.
    
    IF grouped = abap_true.
      temp7 = `X`.
    ELSE.
      temp7 = ``.
    ENDIF.
    INSERT temp7 INTO TABLE temp5.
    client->follow_up_action(
        val   = client->cs_event-binding_call
        t_arg = temp5 ).

  ENDMETHOD.


  METHOD model_init.

    " sap/ui/demo/mock/products.json /ProductCollection, seeded verbatim
    DATA temp7 TYPE z2ui5_cl_smpc_app_607=>ty_t_product.
    DATA temp8 LIKE LINE OF temp7.
    CLEAR temp7.
    
    temp8-name = `Notebook Basic 15`.
    temp8-productid = `HT-1000`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `30`.
    temp8-depth = `18`.
    temp8-height = `3`.
    temp8-dimunit = `cm`.
    temp8-price = `956`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Basic 17`.
    temp8-productid = `HT-1001`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `29`.
    temp8-depth = `17`.
    temp8-height = `3.1`.
    temp8-dimunit = `cm`.
    temp8-price = `1249`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Basic 18`.
    temp8-productid = `HT-1002`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `28`.
    temp8-depth = `19`.
    temp8-height = `2.5`.
    temp8-dimunit = `cm`.
    temp8-price = `1570`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Basic 19`.
    temp8-productid = `HT-1003`.
    temp8-suppliername = `Smartcards`.
    temp8-width = `32`.
    temp8-depth = `21`.
    temp8-height = `4`.
    temp8-dimunit = `cm`.
    temp8-price = `1650`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO Vault`.
    temp8-productid = `HT-1007`.
    temp8-suppliername = `Technocom`.
    temp8-width = `32`.
    temp8-depth = `22`.
    temp8-height = `3`.
    temp8-dimunit = `cm`.
    temp8-price = `299`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Professional 15`.
    temp8-productid = `HT-1010`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `33`.
    temp8-depth = `20`.
    temp8-height = `3`.
    temp8-dimunit = `cm`.
    temp8-price = `1999`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Professional 17`.
    temp8-productid = `HT-1011`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `33`.
    temp8-depth = `23`.
    temp8-height = `2`.
    temp8-dimunit = `cm`.
    temp8-price = `2299`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO Vault Net`.
    temp8-productid = `HT-1020`.
    temp8-suppliername = `Technocom`.
    temp8-width = `10`.
    temp8-depth = `1.8`.
    temp8-height = `17`.
    temp8-dimunit = `cm`.
    temp8-price = `459`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO Vault SAT`.
    temp8-productid = `HT-1021`.
    temp8-suppliername = `Technocom`.
    temp8-width = `11`.
    temp8-depth = `1.7`.
    temp8-height = `18`.
    temp8-dimunit = `cm`.
    temp8-price = `149`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Comfort Easy`.
    temp8-productid = `HT-1022`.
    temp8-suppliername = `Technocom`.
    temp8-width = `84`.
    temp8-depth = `1.5`.
    temp8-height = `14`.
    temp8-dimunit = `cm`.
    temp8-price = `1679`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Comfort Senior`.
    temp8-productid = `HT-1023`.
    temp8-suppliername = `Technocom`.
    temp8-width = `80`.
    temp8-depth = `1.6`.
    temp8-height = `13`.
    temp8-dimunit = `cm`.
    temp8-price = `512`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergo Screen E-I`.
    temp8-productid = `HT-1030`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `37`.
    temp8-depth = `12`.
    temp8-height = `36`.
    temp8-dimunit = `cm`.
    temp8-price = `230`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergo Screen E-II`.
    temp8-productid = `HT-1031`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `40.8`.
    temp8-depth = `19`.
    temp8-height = `43`.
    temp8-dimunit = `cm`.
    temp8-price = `285`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergo Screen E-III`.
    temp8-productid = `HT-1032`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `40.8`.
    temp8-depth = `19`.
    temp8-height = `43`.
    temp8-dimunit = `cm`.
    temp8-price = `345`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Basic`.
    temp8-productid = `HT-1035`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `39`.
    temp8-depth = `20`.
    temp8-height = `41`.
    temp8-dimunit = `cm`.
    temp8-price = `399`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Future`.
    temp8-productid = `HT-1036`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `45`.
    temp8-depth = `26`.
    temp8-height = `46`.
    temp8-dimunit = `cm`.
    temp8-price = `430`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat XL`.
    temp8-productid = `HT-1037`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `54.5`.
    temp8-depth = `22.1`.
    temp8-height = `39.1`.
    temp8-dimunit = `cm`.
    temp8-price = `1230`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Laser Professional Eco`.
    temp8-productid = `HT-1040`.
    temp8-suppliername = `Alpha Printers`.
    temp8-width = `51`.
    temp8-depth = `46`.
    temp8-height = `30`.
    temp8-dimunit = `cm`.
    temp8-price = `830`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Laser Basic`.
    temp8-productid = `HT-1041`.
    temp8-suppliername = `Alpha Printers`.
    temp8-width = `48`.
    temp8-depth = `42`.
    temp8-height = `26`.
    temp8-dimunit = `cm`.
    temp8-price = `490`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Laser Allround`.
    temp8-productid = `HT-1042`.
    temp8-suppliername = `Alpha Printers`.
    temp8-width = `53`.
    temp8-depth = `50`.
    temp8-height = `65`.
    temp8-dimunit = `cm`.
    temp8-price = `349`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ultra Jet Super Color`.
    temp8-productid = `HT-1050`.
    temp8-suppliername = `Alpha Printers`.
    temp8-width = `41`.
    temp8-depth = `41`.
    temp8-height = `28`.
    temp8-dimunit = `cm`.
    temp8-price = `139`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ultra Jet Mobile`.
    temp8-productid = `HT-1051`.
    temp8-suppliername = `Printer for All`.
    temp8-width = `46`.
    temp8-depth = `32`.
    temp8-height = `25`.
    temp8-dimunit = `cm`.
    temp8-price = `99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ultra Jet Super Highspeed`.
    temp8-productid = `HT-1052`.
    temp8-suppliername = `Printer for All`.
    temp8-width = `41`.
    temp8-depth = `41`.
    temp8-height = `28`.
    temp8-dimunit = `cm`.
    temp8-price = `170`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Multi Print`.
    temp8-productid = `HT-1055`.
    temp8-suppliername = `Printer for All`.
    temp8-width = `55`.
    temp8-depth = `45`.
    temp8-height = `29`.
    temp8-dimunit = `cm`.
    temp8-price = `99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Multi Color`.
    temp8-productid = `HT-1056`.
    temp8-suppliername = `Printer for All`.
    temp8-width = `51`.
    temp8-depth = `41.3`.
    temp8-height = `22`.
    temp8-dimunit = `cm`.
    temp8-price = `119`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cordless Mouse`.
    temp8-productid = `HT-1060`.
    temp8-suppliername = `Oxynum`.
    temp8-width = `6`.
    temp8-depth = `14.5`.
    temp8-height = `3.5`.
    temp8-dimunit = `cm`.
    temp8-price = `9`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Speed Mouse`.
    temp8-productid = `HT-1061`.
    temp8-suppliername = `Oxynum`.
    temp8-width = `7`.
    temp8-depth = `15`.
    temp8-height = `3.1`.
    temp8-dimunit = `cm`.
    temp8-price = `7`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Track Mouse`.
    temp8-productid = `HT-1062`.
    temp8-suppliername = `Oxynum`.
    temp8-width = `3`.
    temp8-depth = `7`.
    temp8-height = `4`.
    temp8-dimunit = `cm`.
    temp8-price = `11`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergonomic Keyboard`.
    temp8-productid = `HT-1063`.
    temp8-suppliername = `Oxynum`.
    temp8-width = `50`.
    temp8-depth = `21`.
    temp8-height = `3.5`.
    temp8-dimunit = `cm`.
    temp8-price = `14`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Internet Keyboard`.
    temp8-productid = `HT-1064`.
    temp8-suppliername = `Oxynum`.
    temp8-width = `52`.
    temp8-depth = `25`.
    temp8-height = `3`.
    temp8-dimunit = `cm`.
    temp8-price = `16`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Media Keyboard`.
    temp8-productid = `HT-1065`.
    temp8-suppliername = `Oxynum`.
    temp8-width = `51.4`.
    temp8-depth = `23`.
    temp8-height = `4`.
    temp8-dimunit = `cm`.
    temp8-price = `26`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Mousepad`.
    temp8-productid = `HT-1066`.
    temp8-suppliername = `Oxynum`.
    temp8-width = `15`.
    temp8-depth = `6`.
    temp8-height = `0.2`.
    temp8-dimunit = `cm`.
    temp8-price = `6.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Ergo Mousepad`.
    temp8-productid = `HT-1067`.
    temp8-suppliername = `Oxynum`.
    temp8-width = `15`.
    temp8-depth = `6`.
    temp8-height = `0.2`.
    temp8-dimunit = `cm`.
    temp8-price = `8.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Designer Mousepad`.
    temp8-productid = `HT-1068`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `24`.
    temp8-depth = `24`.
    temp8-height = `0.6`.
    temp8-dimunit = `cm`.
    temp8-price = `12.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Universal card reader`.
    temp8-productid = `HT-1069`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `6`.
    temp8-depth = `6`.
    temp8-height = `3`.
    temp8-dimunit = `cm`.
    temp8-price = `14`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Proctra X`.
    temp8-productid = `HT-1070`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `22`.
    temp8-depth = `35`.
    temp8-height = `17`.
    temp8-dimunit = `cm`.
    temp8-price = `70.9`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Gladiator MX`.
    temp8-productid = `HT-1071`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `22`.
    temp8-depth = `35`.
    temp8-height = `17`.
    temp8-dimunit = `cm`.
    temp8-price = `81.7`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Hurricane GX`.
    temp8-productid = `HT-1072`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `22`.
    temp8-depth = `35`.
    temp8-height = `17`.
    temp8-dimunit = `cm`.
    temp8-price = `101.2`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Hurricane GX/LN`.
    temp8-productid = `HT-1073`.
    temp8-suppliername = `Smartcards`.
    temp8-width = `22`.
    temp8-depth = `35`.
    temp8-height = `17`.
    temp8-dimunit = `cm`.
    temp8-price = `139.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Photo Scan`.
    temp8-productid = `HT-1080`.
    temp8-suppliername = `Printer for All`.
    temp8-width = `34`.
    temp8-depth = `48`.
    temp8-height = `5`.
    temp8-dimunit = `cm`.
    temp8-price = `129`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Power Scan`.
    temp8-productid = `HT-1081`.
    temp8-suppliername = `Printer for All`.
    temp8-width = `31`.
    temp8-depth = `43`.
    temp8-height = `7`.
    temp8-dimunit = `cm`.
    temp8-price = `89`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Jet Scan Professional`.
    temp8-productid = `HT-1082`.
    temp8-suppliername = `Printer for All`.
    temp8-width = `33`.
    temp8-depth = `41`.
    temp8-height = `12`.
    temp8-dimunit = `cm`.
    temp8-price = `169`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Jet Scan Professional`.
    temp8-productid = `HT-1083`.
    temp8-suppliername = `Printer for All`.
    temp8-width = `35`.
    temp8-depth = `40`.
    temp8-height = `10`.
    temp8-dimunit = `cm`.
    temp8-price = `189`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Copymaster`.
    temp8-productid = `HT-1085`.
    temp8-suppliername = `Alpha Printers`.
    temp8-width = `45`.
    temp8-depth = `42`.
    temp8-height = `22`.
    temp8-dimunit = `cm`.
    temp8-price = `1499`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Surround Sound`.
    temp8-productid = `HT-1090`.
    temp8-suppliername = `Speaker Experts`.
    temp8-width = `12`.
    temp8-depth = `10`.
    temp8-height = `16`.
    temp8-dimunit = `cm`.
    temp8-price = `39`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Blaster Extreme`.
    temp8-productid = `HT-1091`.
    temp8-suppliername = `Speaker Experts`.
    temp8-width = `13`.
    temp8-depth = `11`.
    temp8-height = `17.5`.
    temp8-dimunit = `cm`.
    temp8-price = `26`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Sound Booster`.
    temp8-productid = `HT-1092`.
    temp8-suppliername = `Speaker Experts`.
    temp8-width = `12.4`.
    temp8-depth = `10.4`.
    temp8-height = `18.1`.
    temp8-dimunit = `cm`.
    temp8-price = `45`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Lovely Sound 5.1 Wireless`.
    temp8-productid = `HT-1095`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `24`.
    temp8-depth = `19`.
    temp8-height = `23`.
    temp8-dimunit = `cm`.
    temp8-price = `49`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Lovely Sound 5.1`.
    temp8-productid = `HT-1096`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `25`.
    temp8-depth = `17`.
    temp8-height = `19`.
    temp8-dimunit = `cm`.
    temp8-price = `39`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Lovely Sound Stereo`.
    temp8-productid = `HT-1097`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `21.3`.
    temp8-depth = `2.4`.
    temp8-height = `19.7`.
    temp8-dimunit = `cm`.
    temp8-price = `29`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Office`.
    temp8-productid = `HT-1100`.
    temp8-suppliername = `Technocom`.
    temp8-width = `15`.
    temp8-depth = `6.5`.
    temp8-height = `2.1`.
    temp8-dimunit = `cm`.
    temp8-price = `89.9`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Design`.
    temp8-productid = `HT-1101`.
    temp8-suppliername = `Technocom`.
    temp8-width = `14`.
    temp8-depth = `6.7`.
    temp8-height = `24`.
    temp8-dimunit = `cm`.
    temp8-price = `79.9`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Network`.
    temp8-productid = `HT-1102`.
    temp8-suppliername = `Technocom`.
    temp8-width = `16`.
    temp8-depth = `6`.
    temp8-height = `27`.
    temp8-dimunit = `cm`.
    temp8-price = `69`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Multimedia`.
    temp8-productid = `HT-1103`.
    temp8-suppliername = `Technocom`.
    temp8-width = `11`.
    temp8-depth = `3.4`.
    temp8-height = `22`.
    temp8-dimunit = `cm`.
    temp8-price = `77`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Games`.
    temp8-productid = `HT-1104`.
    temp8-suppliername = `Technocom`.
    temp8-width = `10`.
    temp8-depth = `3`.
    temp8-height = `30`.
    temp8-dimunit = `cm`.
    temp8-price = `55`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Internet Antivirus`.
    temp8-productid = `HT-1105`.
    temp8-suppliername = `Brainsoft`.
    temp8-width = `16`.
    temp8-depth = `4`.
    temp8-height = `21`.
    temp8-dimunit = `cm`.
    temp8-price = `29`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Firewall`.
    temp8-productid = `HT-1106`.
    temp8-suppliername = `Brainsoft`.
    temp8-width = `17.9`.
    temp8-depth = `4.2`.
    temp8-height = `23.1`.
    temp8-dimunit = `cm`.
    temp8-price = `34`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smart Money`.
    temp8-productid = `HT-1107`.
    temp8-suppliername = `Brainsoft`.
    temp8-width = `12`.
    temp8-depth = `1.5`.
    temp8-height = `19`.
    temp8-dimunit = `cm`.
    temp8-price = `29.9`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `PC Lock`.
    temp8-productid = `HT-1110`.
    temp8-suppliername = `Red Point Stores`.
    temp8-width = `20`.
    temp8-depth = `8`.
    temp8-height = `4.3`.
    temp8-dimunit = `cm`.
    temp8-price = `8.9`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Notebook Lock`.
    temp8-productid = `HT-1111`.
    temp8-suppliername = `Red Point Stores`.
    temp8-width = `31`.
    temp8-depth = `9`.
    temp8-height = `7`.
    temp8-dimunit = `cm`.
    temp8-price = `6.9`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Web cam reality`.
    temp8-productid = `HT-1112`.
    temp8-suppliername = `Red Point Stores`.
    temp8-width = `9`.
    temp8-depth = `8.2`.
    temp8-height = `1.3`.
    temp8-dimunit = `cm`.
    temp8-price = `39`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Screen clean`.
    temp8-productid = `HT-1113`.
    temp8-suppliername = `Red Point Stores`.
    temp8-width = `2`.
    temp8-depth = `2`.
    temp8-height = `0.1`.
    temp8-dimunit = `cm`.
    temp8-price = `2.3`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Fabric bag professional`.
    temp8-productid = `HT-1114`.
    temp8-suppliername = `Red Point Stores`.
    temp8-width = `42`.
    temp8-depth = `32`.
    temp8-height = `7`.
    temp8-dimunit = `cm`.
    temp8-price = `31`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Wireless DSL Router`.
    temp8-productid = `HT-1115`.
    temp8-suppliername = `Red Point Stores`.
    temp8-width = `19.3`.
    temp8-depth = `18`.
    temp8-height = `5`.
    temp8-dimunit = `cm`.
    temp8-price = `49`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Wireless DSL Router / Repeater`.
    temp8-productid = `HT-1116`.
    temp8-suppliername = `Red Point Stores`.
    temp8-width = `19.3`.
    temp8-depth = `18`.
    temp8-height = `5`.
    temp8-dimunit = `cm`.
    temp8-price = `59`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Wireless DSL Router / Repeater and Print Server`.
    temp8-productid = `HT-1117`.
    temp8-suppliername = `Technocom`.
    temp8-width = `19.3`.
    temp8-depth = `18`.
    temp8-height = `5`.
    temp8-dimunit = `cm`.
    temp8-price = `69`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `USB Stick`.
    temp8-productid = `HT-1118`.
    temp8-suppliername = `Technocom`.
    temp8-width = `1.5`.
    temp8-depth = `8.7`.
    temp8-height = `1.2`.
    temp8-dimunit = `cm`.
    temp8-price = `35`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Travel Adapter`.
    temp8-productid = `HT-1119`.
    temp8-suppliername = `Titanium`.
    temp8-width = `2`.
    temp8-depth = `3.1`.
    temp8-height = `3.9`.
    temp8-dimunit = `cm`.
    temp8-price = `79`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cordless Bluetooth Keyboard, english international`.
    temp8-productid = `HT-1120`.
    temp8-suppliername = `Technocom`.
    temp8-width = `51.4`.
    temp8-depth = `23`.
    temp8-height = `4`.
    temp8-dimunit = `cm`.
    temp8-price = `29`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat XXL`.
    temp8-productid = `HT-1137`.
    temp8-suppliername = `Technocom`.
    temp8-width = `54`.
    temp8-depth = `22`.
    temp8-height = `38`.
    temp8-dimunit = `cm`.
    temp8-price = `1430`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Pocket Mouse`.
    temp8-productid = `HT-1138`.
    temp8-suppliername = `Technocom`.
    temp8-width = `0.3`.
    temp8-depth = `0.5`.
    temp8-height = `1`.
    temp8-dimunit = `cm`.
    temp8-price = `23`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `PC Power Station`.
    temp8-productid = `HT-1210`.
    temp8-suppliername = `Technocom`.
    temp8-width = `28`.
    temp8-depth = `31`.
    temp8-height = `43`.
    temp8-dimunit = `cm`.
    temp8-price = `2399`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Astro Laptop 1516`.
    temp8-productid = `HT-1251`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `30`.
    temp8-depth = `18`.
    temp8-height = `3`.
    temp8-dimunit = `cm`.
    temp8-price = `989`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Astro Phone 6`.
    temp8-productid = `HT-1252`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `8`.
    temp8-depth = `6`.
    temp8-height = `1.5`.
    temp8-dimunit = `cm`.
    temp8-price = `649`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Benda Laptop 1408`.
    temp8-productid = `HT-1253`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `30`.
    temp8-depth = `18`.
    temp8-height = `3`.
    temp8-dimunit = `cm`.
    temp8-price = `976`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Bending Screen 21HD`.
    temp8-productid = `HT-1254`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `37`.
    temp8-depth = `12`.
    temp8-height = `36`.
    temp8-dimunit = `cm`.
    temp8-price = `250`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Broad Screen 22HD`.
    temp8-productid = `HT-1255`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `39`.
    temp8-depth = `12`.
    temp8-height = `38`.
    temp8-dimunit = `cm`.
    temp8-price = `270`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cerdik Phone 7`.
    temp8-productid = `HT-1256`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `9`.
    temp8-depth = `15`.
    temp8-height = `1.5`.
    temp8-dimunit = `cm`.
    temp8-price = `549`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cepat Tablet 10.5`.
    temp8-productid = `HT-1257`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `549`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Cepat Tablet 8`.
    temp8-productid = `HT-1258`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `38`.
    temp8-depth = `21`.
    temp8-height = `3.5`.
    temp8-dimunit = `cm`.
    temp8-price = `529`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Server Basic`.
    temp8-productid = `HT-1500`.
    temp8-suppliername = `Technocom`.
    temp8-width = `34`.
    temp8-depth = `35`.
    temp8-height = `23`.
    temp8-dimunit = `cm`.
    temp8-price = `5000`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Server Professional`.
    temp8-productid = `HT-1501`.
    temp8-suppliername = `Technocom`.
    temp8-width = `29`.
    temp8-depth = `30`.
    temp8-height = `27`.
    temp8-dimunit = `cm`.
    temp8-price = `15000`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Server Power Pro`.
    temp8-productid = `HT-1502`.
    temp8-suppliername = `Technocom`.
    temp8-width = `22`.
    temp8-depth = `27.3`.
    temp8-height = `37`.
    temp8-dimunit = `cm`.
    temp8-price = `25000`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Family PC Basic`.
    temp8-productid = `HT-1600`.
    temp8-suppliername = `Titanium`.
    temp8-width = `21.4`.
    temp8-depth = `29`.
    temp8-height = `38`.
    temp8-dimunit = `cm`.
    temp8-price = `600`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Family PC Pro`.
    temp8-productid = `HT-1601`.
    temp8-suppliername = `Titanium`.
    temp8-width = `25`.
    temp8-depth = `31.7`.
    temp8-height = `40.2`.
    temp8-dimunit = `cm`.
    temp8-price = `900`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Gaming Monster`.
    temp8-productid = `HT-1602`.
    temp8-suppliername = `Titanium`.
    temp8-width = `26.5`.
    temp8-depth = `34`.
    temp8-height = `47`.
    temp8-dimunit = `cm`.
    temp8-price = `1200`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Gaming Monster Pro`.
    temp8-productid = `HT-1603`.
    temp8-suppliername = `Titanium`.
    temp8-width = `27`.
    temp8-depth = `28`.
    temp8-height = `42`.
    temp8-dimunit = `cm`.
    temp8-price = `1700`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `7" Widescreen Portable DVD Player w MP3`.
    temp8-productid = `HT-2000`.
    temp8-suppliername = `Titanium`.
    temp8-width = `21.4`.
    temp8-depth = `19`.
    temp8-height = `27.6`.
    temp8-dimunit = `cm`.
    temp8-price = `249.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `10" Portable DVD player`.
    temp8-productid = `HT-2001`.
    temp8-suppliername = `Titanium`.
    temp8-width = `24`.
    temp8-depth = `19.5`.
    temp8-height = `29`.
    temp8-dimunit = `cm`.
    temp8-price = `449.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Portable DVD Player with 9" LCD Monitor`.
    temp8-productid = `HT-2002`.
    temp8-suppliername = `Technocom`.
    temp8-width = `21`.
    temp8-depth = `16.5`.
    temp8-height = `14`.
    temp8-dimunit = `cm`.
    temp8-price = `853.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `CD/DVD case: 264 sleeves`.
    temp8-productid = `HT-2025`.
    temp8-suppliername = `Titanium`.
    temp8-width = `13`.
    temp8-depth = `13`.
    temp8-height = `20`.
    temp8-dimunit = `cm`.
    temp8-price = `44.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Audio/Video Cable Kit - 4m`.
    temp8-productid = `HT-2026`.
    temp8-suppliername = `Titanium`.
    temp8-width = `21`.
    temp8-depth = `10.2`.
    temp8-height = `13`.
    temp8-dimunit = `cm`.
    temp8-price = `29.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Removable CD/DVD Laser Labels`.
    temp8-productid = `HT-2027`.
    temp8-suppliername = `Titanium`.
    temp8-width = `5.5`.
    temp8-depth = `2`.
    temp8-height = `2`.
    temp8-dimunit = `cm`.
    temp8-price = `8.99`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Beam Breaker B-1`.
    temp8-productid = `HT-6100`.
    temp8-suppliername = `Titanium`.
    temp8-width = `30.4`.
    temp8-depth = `23.1`.
    temp8-height = `23`.
    temp8-dimunit = `cm`.
    temp8-price = `469`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Beam Breaker B-2`.
    temp8-productid = `HT-6101`.
    temp8-suppliername = `Technocom`.
    temp8-width = `30.4`.
    temp8-depth = `23.1`.
    temp8-height = `23`.
    temp8-dimunit = `cm`.
    temp8-price = `679`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Beam Breaker B-3`.
    temp8-productid = `HT-6102`.
    temp8-suppliername = `Technocom`.
    temp8-width = `30.4`.
    temp8-depth = `23.1`.
    temp8-height = `23`.
    temp8-dimunit = `cm`.
    temp8-price = `889`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Play Movie`.
    temp8-productid = `HT-6110`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `37`.
    temp8-depth = `24`.
    temp8-height = `6`.
    temp8-dimunit = `cm`.
    temp8-price = `130`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Record Movie`.
    temp8-productid = `HT-6111`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `38`.
    temp8-depth = `26`.
    temp8-height = `6.2`.
    temp8-dimunit = `cm`.
    temp8-price = `288`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelo MusicStick`.
    temp8-productid = `HT-6120`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `1.5`.
    temp8-depth = `6`.
    temp8-height = `1`.
    temp8-dimunit = `cm`.
    temp8-price = `45`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelo Jog-Mate`.
    temp8-productid = `HT-6121`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `5.1`.
    temp8-depth = `8`.
    temp8-height = `9.2`.
    temp8-dimunit = `cm`.
    temp8-price = `63`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Power Pro Player 40`.
    temp8-productid = `HT-6122`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `5.1`.
    temp8-depth = `8`.
    temp8-height = `9.2`.
    temp8-dimunit = `cm`.
    temp8-price = `167`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Power Pro Player 80`.
    temp8-productid = `HT-6123`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `4`.
    temp8-depth = `6`.
    temp8-height = `0.8`.
    temp8-dimunit = `cm`.
    temp8-price = `299`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Watch HD32`.
    temp8-productid = `HT-6130`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `78`.
    temp8-depth = `22.1`.
    temp8-height = `55`.
    temp8-dimunit = `cm`.
    temp8-price = `1459`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Watch HD37`.
    temp8-productid = `HT-6131`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `99.1`.
    temp8-depth = `26`.
    temp8-height = `61`.
    temp8-dimunit = `cm`.
    temp8-price = `1199`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flat Watch HD41`.
    temp8-productid = `HT-6132`.
    temp8-suppliername = `Very Best Screens`.
    temp8-width = `128`.
    temp8-depth = `23`.
    temp8-height = `79.1`.
    temp8-dimunit = `cm`.
    temp8-price = `899`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Copperberry`.
    temp8-productid = `HT-7000`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `8.1`.
    temp8-depth = `13`.
    temp8-height = `12.1`.
    temp8-dimunit = `cm`.
    temp8-price = `549`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Silverberry`.
    temp8-productid = `HT-7010`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `8.1`.
    temp8-depth = `13`.
    temp8-height = `12.1`.
    temp8-dimunit = `cm`.
    temp8-price = `549`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Goldberry`.
    temp8-productid = `HT-7020`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `8.1`.
    temp8-depth = `13`.
    temp8-height = `12.1`.
    temp8-dimunit = `cm`.
    temp8-price = `549`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Platinberry`.
    temp8-productid = `HT-7030`.
    temp8-suppliername = `Fasttech`.
    temp8-width = `8.1`.
    temp8-depth = `13`.
    temp8-height = `12.1`.
    temp8-dimunit = `cm`.
    temp8-price = `549`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO FlexTop I4000`.
    temp8-productid = `HT-8000`.
    temp8-suppliername = `Titanium`.
    temp8-width = `31`.
    temp8-depth = `19`.
    temp8-height = `3.1`.
    temp8-dimunit = `cm`.
    temp8-price = `799`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO FlexTop I6300c`.
    temp8-productid = `HT-8001`.
    temp8-suppliername = `Titanium`.
    temp8-width = `32`.
    temp8-depth = `20`.
    temp8-height = `3.4`.
    temp8-dimunit = `cm`.
    temp8-price = `799`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO FlexTop I9100`.
    temp8-productid = `HT-8002`.
    temp8-suppliername = `Titanium`.
    temp8-width = `38`.
    temp8-depth = `21`.
    temp8-height = `4.1`.
    temp8-dimunit = `cm`.
    temp8-price = `1199`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `ITelO FlexTop I9800`.
    temp8-productid = `HT-8003`.
    temp8-suppliername = `Titanium`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `1388`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smartphone Leather Case`.
    temp8-productid = `HT-9991`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `25`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smartphone Alpha`.
    temp8-productid = `HT-9992`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `599`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Mini Tablet`.
    temp8-productid = `HT-9993`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `833`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Camcorder View`.
    temp8-productid = `HT-9994`.
    temp8-suppliername = `Ultrasonic United`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `27`.
    temp8-dimunit = `cm`.
    temp8-price = `1388`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Tablet Pouch`.
    temp8-productid = `HT-9995`.
    temp8-suppliername = `Titanium`.
    temp8-width = `25`.
    temp8-depth = `40`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `20`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Tablet Pouch`.
    temp8-productid = `HT-9996`.
    temp8-suppliername = `Titanium`.
    temp8-width = `25`.
    temp8-depth = `40`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `20`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `e-Book Reader ReadMe`.
    temp8-productid = `HT-9997`.
    temp8-suppliername = `Titanium`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `33`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Smartphone Beta`.
    temp8-productid = `HT-9998`.
    temp8-suppliername = `Titanium`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `30`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Maxi Tablet`.
    temp8-productid = `HT-9999`.
    temp8-suppliername = `Titanium`.
    temp8-width = `48`.
    temp8-depth = `31`.
    temp8-height = `4.5`.
    temp8-dimunit = `cm`.
    temp8-price = `749`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    temp8-name = `Flyer`.
    temp8-productid = `PF-1000`.
    temp8-suppliername = `Titanium`.
    temp8-width = `46`.
    temp8-depth = `30`.
    temp8-height = `3`.
    temp8-dimunit = `cm`.
    temp8-price = `0`.
    temp8-currencycode = `EUR`.
    INSERT temp8 INTO TABLE temp7.
    t_all = temp7.

    t_products = t_all.

  ENDMETHOD.

ENDCLASS.
