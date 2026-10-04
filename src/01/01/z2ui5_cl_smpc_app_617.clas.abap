" @keywords icontabbar icon tab bar sap.m icontabbarbackgrounddesign panel label radiobuttongroup radiobutton icontabfilter icontabseparator
" @summary In this example the backgroundDesign and headerBackgroundDesign properties are demonstrated.
" @origin sap.m.sample.IconTabBarBackgroundDesign - https://sdk.openui5.org/entity/sap.m.IconTabBar/sample/sap.m.sample.IconTabBarBackgroundDesign (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_617 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        suppliername  TYPE string,
        width         TYPE string,
        depth         TYPE string,
        height        TYPE string,
        dimunit       TYPE string,
        weightmeasure TYPE string,
        weightunit    TYPE string,
        " Formatter.weightState, computed in the backend (thin frontend)
        weight_state  TYPE string,
        price         TYPE string,
        currencycode  TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    DATA t_products TYPE ty_t_product.

    " ProductCollectionStats/Counts - what the four tab filters show
    DATA count_total       TYPE string.
    DATA count_ok          TYPE string.
    DATA count_heavy       TYPE string.
    DATA count_overweight  TYPE string.

    " the two RadioButtonGroups write these; the IconTabBar binds them
    DATA background_idx        TYPE i.
    DATA header_background_idx TYPE i.
    DATA background_design     TYPE string.
    DATA header_background     TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    " PROTECTED, not PRIVATE: the app's state is serialized into the draft with
    " CALL TRANSFORMATION id, and the transpiled runtime's re-implementation of
    " it walks the attributes with a dynamic ASSIGN obj->(name), which cannot
    " reach a PRIVATE one - it asserts, and every roundtrip 500s with
    " ASSERTION_FAILED (e2e-caught 2026-08-22)
    DATA t_all TYPE ty_t_product.

    METHODS view_display.
    METHODS on_event.
    METHODS filter_apply.
    METHODS designs_apply.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_617 IMPLEMENTATION.

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
    DATA panel TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA bar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    panel = view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`

        )->ele( `Panel`
            )->a( n = `class` v = `sapMShellGlobalOuterBackground` ).

    panel->ele( n = `SimpleForm` ns = `form`
        )->a( n = `labelSpanL` v = `6`
        )->a( n = `labelSpanM` v = `6`
        )->a( n = `editable`   v = `true`
        )->a( n = `layout`     v = `ResponsiveGridLayout`

        )->tag( `Label`
            )->a( n = `text` v = `Background Design`
        " onBackgroundDesignSelect reads the picked button's TEXT and hands it to
        " setBackgroundDesign; the group writes its index and one round trip
        " turns that into the enum the IconTabBar binds (app 604 idiom)
        )->ele( `RadioButtonGroup`
            )->a( n = `columns`       v = `3`
            )->a( n = `selectedIndex` v = client->_bind( background_idx )
            )->a( n = `select`        v = client->_event( `DESIGNS` )
            )->tag( `RadioButton`
                )->a( n = `text` v = `Solid`
            )->tag( `RadioButton`
                )->a( n = `text` v = `Transparent`
            )->tag( `RadioButton`
                )->a( n = `text` v = `Translucent`

        )->end(

        )->tag( `Label`
            )->a( n = `text` v = `Header Background Design`
        )->ele( `RadioButtonGroup`
            )->a( n = `columns`       v = `3`
            )->a( n = `selectedIndex` v = client->_bind( header_background_idx )
            )->a( n = `select`        v = client->_event( `DESIGNS` )
            )->tag( `RadioButton`
                )->a( n = `text` v = `Solid`
            )->tag( `RadioButton`
                )->a( n = `text` v = `Transparent`
            )->tag( `RadioButton`
                )->a( n = `text` v = `Translucent`

        )->end(
    )->end( ).

    
    bar = panel->ele( `IconTabBar`
        )->a( n = `id`                     v = `idIconTabBar`
        )->a( n = `class`                  v = `sapUiResponsiveContentPadding`
        " the null fallback keeps an unset enum out of the property before the
        " first round trip (apps 548/555/604 idiom)
        )->a( n = `backgroundDesign`       v = |\{= ${ client->_bind( background_design ) } \|\| null \}|
        )->a( n = `headerBackgroundDesign` v = |\{= ${ client->_bind( header_background ) } \|\| null \}|
        )->a( n = `select`                 v = client->_event( val = `FILTER` arg = `${$parameters>/key}` ) ).

    bar->ele( `items`
        )->tag( `IconTabFilter`
            )->a( n = `showAll` v = `true`
            )->a( n = `count`   v = client->_bind( count_total )
            )->a( n = `text`    v = `Products`
            )->a( n = `key`     v = `All`
        )->tag( `IconTabSeparator`
        )->tag( `IconTabFilter`
            )->a( n = `icon`      v = `sap-icon://begin`
            )->a( n = `iconColor` v = `Positive`
            )->a( n = `count`     v = client->_bind( count_ok )
            )->a( n = `text`      v = `Ok`
            )->a( n = `key`       v = `Ok`
        )->tag( `IconTabFilter`
            )->a( n = `icon`      v = `sap-icon://compare`
            )->a( n = `iconColor` v = `Critical`
            )->a( n = `count`     v = client->_bind( count_heavy )
            )->a( n = `text`      v = `Heavy`
            )->a( n = `key`       v = `Heavy`
        )->tag( `IconTabFilter`
            )->a( n = `icon`      v = `sap-icon://inventory`
            )->a( n = `iconColor` v = `Negative`
            )->a( n = `count`     v = client->_bind( count_overweight )
            )->a( n = `text`      v = `Overweight`
            )->a( n = `key`       v = `Overweight`

    )->end( ).

    
    table = bar->ele( `content`
        )->ele( `Table`
            )->a( n = `id`             v = `productsTable`
            )->a( n = `inset`          v = `false`
            )->a( n = `showSeparators` v = `Inner`
            )->a( n = `headerText`     v = `Products`
            " the rows binding carries a sorter on Name; a thin frontend sorts
            " the data it sends (app 298 idiom)
            )->a( n = `items`          v = client->_bind( t_products ) ).

    table->ele( `infoToolbar`
        )->ele( `OverflowToolbar`
            )->tag( `Label`
                )->a( n = `text` v = `Wide range of available products`

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
            )->a( n = `minScreenWidth` v = `Desktop`
            )->a( n = `demandPopin`    v = `true`
            )->a( n = `hAlign`         v = `End`
            )->tag( `Text`
                )->a( n = `text` v = `Dimensions`

        )->end(
        )->ele( `Column`
            )->a( n = `minScreenWidth` v = `Desktop`
            )->a( n = `demandPopin`    v = `true`
            )->a( n = `hAlign`         v = `Center`
            )->tag( `Text`
                )->a( n = `text` v = `Weight`

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
                    )->a( n = `number` v = `{WEIGHTMEASURE}`
                    )->a( n = `unit`   v = `{WEIGHTUNIT}`
                    )->a( n = `state`  v = `{WEIGHT_STATE}`
                )->tag( `ObjectNumber`
                    )->a( n = `number` v = |\{ parts:[\{path:'PRICE'\},\{path:'CURRENCYCODE'\}],| &&
                                           | type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: false\} \}|
                    )->a( n = `unit`   v = `{CURRENCYCODE}`

            )->end(
        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
      WHEN `FILTER`.
        filter_apply( ).
      WHEN `DESIGNS`.
        designs_apply( ).
    ENDCASE.

  ENDMETHOD.


  METHOD filter_apply.

    DATA t_keep TYPE ty_t_product.

    " onFilterSelect: a WeightUnit EQ KG filter AND-ed with the measure range of
    " the picked tab; a thin frontend filters the data it sends (app 298 idiom)
    DATA key TYPE string.
    DATA temp1 TYPE z2ui5_cl_smpc_app_617=>ty_t_product.
    DATA row LIKE LINE OF t_products.
      DATA temp2 TYPE decfloat34.
      DATA measure LIKE temp2.
      DATA temp3 TYPE abap_bool.
          DATA temp4 TYPE xsdboolean.
          DATA temp5 TYPE xsdboolean.
          DATA temp6 TYPE xsdboolean.
      DATA keep LIKE temp3.
    key = client->get_event_arg( ).

    t_products = t_all.
    IF key = `All` OR key IS INITIAL.
      RETURN.
    ENDIF.

    " Collected rather than deleted in place: DELETE ... INDEX sy-tabix inside
    " a LOOP over the same table shifts the rows under the loop's own cursor -
    " on a system it silently SKIPS the row after each deletion, on the
    " transpiled backend it raises TABLE_INVALID_INDEX (app 298, 2026-08-17)
    
    CLEAR temp1.
    t_keep = temp1.
    
    LOOP AT t_products INTO row WHERE weightunit = `KG`.
      
      temp2 = row-weightmeasure.
      
      measure = temp2.
      
      CASE key.
        WHEN `Ok`.
          
          temp4 = boolc( measure <= 1 ).
          temp3 = temp4.
        WHEN `Heavy`.
          
          temp5 = boolc( measure >= 1 AND measure <= 5 ).
          temp3 = temp5.
        WHEN `Overweight`.
          
          temp6 = boolc( measure > 5 ).
          temp3 = temp6.
        WHEN OTHERS.
          temp3 = abap_true.
      ENDCASE.
      
      keep = temp3.
      IF keep = abap_true.
        APPEND row TO t_keep.
      ENDIF.
    ENDLOOP.
    t_products = t_keep.

  ENDMETHOD.


  METHOD designs_apply.

    " both handlers read getSelectedButton( ).getText( ) and hand it to a setter;
    " the three texts ARE the sap.m.BackgroundDesign members
    DATA temp4 TYPE string.
    DATA temp5 TYPE string.
    CASE background_idx.
      WHEN 0.
        temp4 = `Solid`.
      WHEN 1.
        temp4 = `Transparent`.
      WHEN OTHERS.
        temp4 = `Translucent`.
    ENDCASE.
    background_design = temp4.

    
    CASE header_background_idx.
      WHEN 0.
        temp5 = `Solid`.
      WHEN 1.
        temp5 = `Transparent`.
      WHEN OTHERS.
        temp5 = `Translucent`.
    ENDCASE.
    header_background = temp5.

  ENDMETHOD.


  METHOD model_init.
    DATA temp6 TYPE z2ui5_cl_smpc_app_617=>ty_t_product.
    DATA temp7 LIKE LINE OF temp6.

    " sap/ui/demo/mock/products.json /ProductCollectionStats/Counts
    count_total      = `123`.
    count_ok         = `53`.
    count_heavy      = `51`.
    count_overweight = `19`.

    " both RadioButtonGroups come up on their first button, which is what
    " getSelectedButton( ) returns before any select
    designs_apply( ).

    " /ProductCollection, seeded verbatim; weight_state is Formatter.weightState
    " over the row's own measure and unit, computed here rather than in the view
    
    CLEAR temp6.
    
    temp7-name = `Notebook Basic 15`.
    temp7-productid = `HT-1000`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `30`.
    temp7-depth = `18`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `956`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 17`.
    temp7-productid = `HT-1001`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `29`.
    temp7-depth = `17`.
    temp7-height = `3.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1249`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 18`.
    temp7-productid = `HT-1002`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `28`.
    temp7-depth = `19`.
    temp7-height = `2.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1570`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Basic 19`.
    temp7-productid = `HT-1003`.
    temp7-suppliername = `Smartcards`.
    temp7-width = `32`.
    temp7-depth = `21`.
    temp7-height = `4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1650`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault`.
    temp7-productid = `HT-1007`.
    temp7-suppliername = `Technocom`.
    temp7-width = `32`.
    temp7-depth = `22`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `299`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Professional 15`.
    temp7-productid = `HT-1010`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `33`.
    temp7-depth = `20`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1999`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Professional 17`.
    temp7-productid = `HT-1011`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `33`.
    temp7-depth = `23`.
    temp7-height = `2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.1`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `2299`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault Net`.
    temp7-productid = `HT-1020`.
    temp7-suppliername = `Technocom`.
    temp7-width = `10`.
    temp7-depth = `1.8`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.16`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `459`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO Vault SAT`.
    temp7-productid = `HT-1021`.
    temp7-suppliername = `Technocom`.
    temp7-width = `11`.
    temp7-depth = `1.7`.
    temp7-height = `18`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.18`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `149`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Comfort Easy`.
    temp7-productid = `HT-1022`.
    temp7-suppliername = `Technocom`.
    temp7-width = `84`.
    temp7-depth = `1.5`.
    temp7-height = `14`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `1679`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Comfort Senior`.
    temp7-productid = `HT-1023`.
    temp7-suppliername = `Technocom`.
    temp7-width = `80`.
    temp7-depth = `1.6`.
    temp7-height = `13`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `512`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-I`.
    temp7-productid = `HT-1030`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `37`.
    temp7-depth = `12`.
    temp7-height = `36`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `21`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `230`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-II`.
    temp7-productid = `HT-1031`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `40.8`.
    temp7-depth = `19`.
    temp7-height = `43`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `21`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `285`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Screen E-III`.
    temp7-productid = `HT-1032`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `40.8`.
    temp7-depth = `19`.
    temp7-height = `43`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `21`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `345`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Basic`.
    temp7-productid = `HT-1035`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `39`.
    temp7-depth = `20`.
    temp7-height = `41`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `14`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `399`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Future`.
    temp7-productid = `HT-1036`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `45`.
    temp7-depth = `26`.
    temp7-height = `46`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `15`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `430`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat XL`.
    temp7-productid = `HT-1037`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `54.5`.
    temp7-depth = `22.1`.
    temp7-height = `39.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `17`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `1230`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Professional Eco`.
    temp7-productid = `HT-1040`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `51`.
    temp7-depth = `46`.
    temp7-height = `30`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `32`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `830`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Basic`.
    temp7-productid = `HT-1041`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `48`.
    temp7-depth = `42`.
    temp7-height = `26`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `23`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `490`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Laser Allround`.
    temp7-productid = `HT-1042`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `53`.
    temp7-depth = `50`.
    temp7-height = `65`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `17`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `349`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Super Color`.
    temp7-productid = `HT-1050`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `41`.
    temp7-depth = `41`.
    temp7-height = `28`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `139`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Mobile`.
    temp7-productid = `HT-1051`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `46`.
    temp7-depth = `32`.
    temp7-height = `25`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.9`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ultra Jet Super Highspeed`.
    temp7-productid = `HT-1052`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `41`.
    temp7-depth = `41`.
    temp7-height = `28`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `18`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `170`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Multi Print`.
    temp7-productid = `HT-1055`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `55`.
    temp7-depth = `45`.
    temp7-height = `29`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `6.3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Multi Color`.
    temp7-productid = `HT-1056`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `51`.
    temp7-depth = `41.3`.
    temp7-height = `22`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `119`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cordless Mouse`.
    temp7-productid = `HT-1060`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `6`.
    temp7-depth = `14.5`.
    temp7-height = `3.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.09`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Speed Mouse`.
    temp7-productid = `HT-1061`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `7`.
    temp7-depth = `15`.
    temp7-height = `3.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.09`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `7`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Track Mouse`.
    temp7-productid = `HT-1062`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `3`.
    temp7-depth = `7`.
    temp7-height = `4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.03`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `11`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergonomic Keyboard`.
    temp7-productid = `HT-1063`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `50`.
    temp7-depth = `21`.
    temp7-height = `3.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.1`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `14`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Internet Keyboard`.
    temp7-productid = `HT-1064`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `52`.
    temp7-depth = `25`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `16`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Media Keyboard`.
    temp7-productid = `HT-1065`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `51.4`.
    temp7-depth = `23`.
    temp7-height = `4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `26`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Mousepad`.
    temp7-productid = `HT-1066`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `15`.
    temp7-depth = `6`.
    temp7-height = `0.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `80`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `6.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Ergo Mousepad`.
    temp7-productid = `HT-1067`.
    temp7-suppliername = `Oxynum`.
    temp7-width = `15`.
    temp7-depth = `6`.
    temp7-height = `0.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `80`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `8.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Designer Mousepad`.
    temp7-productid = `HT-1068`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `24`.
    temp7-depth = `24`.
    temp7-height = `0.6`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `90`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `12.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Universal card reader`.
    temp7-productid = `HT-1069`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `6`.
    temp7-depth = `6`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `45`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `14`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Proctra X`.
    temp7-productid = `HT-1070`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `22`.
    temp7-depth = `35`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.255`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `70.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gladiator MX`.
    temp7-productid = `HT-1071`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `22`.
    temp7-depth = `35`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `81.7`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Hurricane GX`.
    temp7-productid = `HT-1072`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `22`.
    temp7-depth = `35`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.4`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `101.2`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Hurricane GX/LN`.
    temp7-productid = `HT-1073`.
    temp7-suppliername = `Smartcards`.
    temp7-width = `22`.
    temp7-depth = `35`.
    temp7-height = `17`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.4`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `139.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Photo Scan`.
    temp7-productid = `HT-1080`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `34`.
    temp7-depth = `48`.
    temp7-height = `5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `129`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Scan`.
    temp7-productid = `HT-1081`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `31`.
    temp7-depth = `43`.
    temp7-height = `7`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.4`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `89`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Jet Scan Professional`.
    temp7-productid = `HT-1082`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `33`.
    temp7-depth = `41`.
    temp7-height = `12`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `169`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Jet Scan Professional`.
    temp7-productid = `HT-1083`.
    temp7-suppliername = `Printer for All`.
    temp7-width = `35`.
    temp7-depth = `40`.
    temp7-height = `10`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `189`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Copymaster`.
    temp7-productid = `HT-1085`.
    temp7-suppliername = `Alpha Printers`.
    temp7-width = `45`.
    temp7-depth = `42`.
    temp7-height = `22`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `23.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `1499`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Surround Sound`.
    temp7-productid = `HT-1090`.
    temp7-suppliername = `Speaker Experts`.
    temp7-width = `12`.
    temp7-depth = `10`.
    temp7-height = `16`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `39`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Blaster Extreme`.
    temp7-productid = `HT-1091`.
    temp7-suppliername = `Speaker Experts`.
    temp7-width = `13`.
    temp7-depth = `11`.
    temp7-height = `17.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.4`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `26`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Sound Booster`.
    temp7-productid = `HT-1092`.
    temp7-suppliername = `Speaker Experts`.
    temp7-width = `12.4`.
    temp7-depth = `10.4`.
    temp7-height = `18.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.1`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `45`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound 5.1 Wireless`.
    temp7-productid = `HT-1095`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `24`.
    temp7-depth = `19`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `80`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `49`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound 5.1`.
    temp7-productid = `HT-1096`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `25`.
    temp7-depth = `17`.
    temp7-height = `19`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `130`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `39`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Lovely Sound Stereo`.
    temp7-productid = `HT-1097`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `21.3`.
    temp7-depth = `2.4`.
    temp7-height = `19.7`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `60`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `29`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Office`.
    temp7-productid = `HT-1100`.
    temp7-suppliername = `Technocom`.
    temp7-width = `15`.
    temp7-depth = `6.5`.
    temp7-height = `2.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `89.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Design`.
    temp7-productid = `HT-1101`.
    temp7-suppliername = `Technocom`.
    temp7-width = `14`.
    temp7-depth = `6.7`.
    temp7-height = `24`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `79.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Network`.
    temp7-productid = `HT-1102`.
    temp7-suppliername = `Technocom`.
    temp7-width = `16`.
    temp7-depth = `6`.
    temp7-height = `27`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `69`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Multimedia`.
    temp7-productid = `HT-1103`.
    temp7-suppliername = `Technocom`.
    temp7-width = `11`.
    temp7-depth = `3.4`.
    temp7-height = `22`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `77`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Games`.
    temp7-productid = `HT-1104`.
    temp7-suppliername = `Technocom`.
    temp7-width = `10`.
    temp7-depth = `3`.
    temp7-height = `30`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.1`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `55`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Internet Antivirus`.
    temp7-productid = `HT-1105`.
    temp7-suppliername = `Brainsoft`.
    temp7-width = `16`.
    temp7-depth = `4`.
    temp7-height = `21`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.7`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `29`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Firewall`.
    temp7-productid = `HT-1106`.
    temp7-suppliername = `Brainsoft`.
    temp7-width = `17.9`.
    temp7-depth = `4.2`.
    temp7-height = `23.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.9`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `34`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smart Money`.
    temp7-productid = `HT-1107`.
    temp7-suppliername = `Brainsoft`.
    temp7-width = `12`.
    temp7-depth = `1.5`.
    temp7-height = `19`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `29.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `PC Lock`.
    temp7-productid = `HT-1110`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `20`.
    temp7-depth = `8`.
    temp7-height = `4.3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.03`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `8.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Notebook Lock`.
    temp7-productid = `HT-1111`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `31`.
    temp7-depth = `9`.
    temp7-height = `7`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.02`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `6.9`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Web cam reality`.
    temp7-productid = `HT-1112`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `9`.
    temp7-depth = `8.2`.
    temp7-height = `1.3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.075`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `39`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Screen clean`.
    temp7-productid = `HT-1113`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `2`.
    temp7-depth = `2`.
    temp7-height = `0.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.05`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `2.3`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Fabric bag professional`.
    temp7-productid = `HT-1114`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `42`.
    temp7-depth = `32`.
    temp7-height = `7`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `31`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router`.
    temp7-productid = `HT-1115`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `19.3`.
    temp7-depth = `18`.
    temp7-height = `5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.45`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `49`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router / Repeater`.
    temp7-productid = `HT-1116`.
    temp7-suppliername = `Red Point Stores`.
    temp7-width = `19.3`.
    temp7-depth = `18`.
    temp7-height = `5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.45`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `59`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Wireless DSL Router / Repeater and Print Server`.
    temp7-productid = `HT-1117`.
    temp7-suppliername = `Technocom`.
    temp7-width = `19.3`.
    temp7-depth = `18`.
    temp7-height = `5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.45`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `69`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `USB Stick`.
    temp7-productid = `HT-1118`.
    temp7-suppliername = `Technocom`.
    temp7-width = `1.5`.
    temp7-depth = `8.7`.
    temp7-height = `1.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.015`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `35`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Travel Adapter`.
    temp7-productid = `HT-1119`.
    temp7-suppliername = `Titanium`.
    temp7-width = `2`.
    temp7-depth = `3.1`.
    temp7-height = `3.9`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `88`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `79`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cordless Bluetooth Keyboard, english international`.
    temp7-productid = `HT-1120`.
    temp7-suppliername = `Technocom`.
    temp7-width = `51.4`.
    temp7-depth = `23`.
    temp7-height = `4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `29`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat XXL`.
    temp7-productid = `HT-1137`.
    temp7-suppliername = `Technocom`.
    temp7-width = `54`.
    temp7-depth = `22`.
    temp7-height = `38`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `18`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `1430`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Pocket Mouse`.
    temp7-productid = `HT-1138`.
    temp7-suppliername = `Technocom`.
    temp7-width = `0.3`.
    temp7-depth = `0.5`.
    temp7-height = `1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.02`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `23`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `PC Power Station`.
    temp7-productid = `HT-1210`.
    temp7-suppliername = `Technocom`.
    temp7-width = `28`.
    temp7-depth = `31`.
    temp7-height = `43`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `2399`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Astro Laptop 1516`.
    temp7-productid = `HT-1251`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `30`.
    temp7-depth = `18`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `989`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Astro Phone 6`.
    temp7-productid = `HT-1252`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `8`.
    temp7-depth = `6`.
    temp7-height = `1.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.75`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `649`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Benda Laptop 1408`.
    temp7-productid = `HT-1253`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `30`.
    temp7-depth = `18`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `976`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Bending Screen 21HD`.
    temp7-productid = `HT-1254`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `37`.
    temp7-depth = `12`.
    temp7-height = `36`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `15`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `250`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Broad Screen 22HD`.
    temp7-productid = `HT-1255`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `39`.
    temp7-depth = `12`.
    temp7-height = `38`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `16`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `270`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cerdik Phone 7`.
    temp7-productid = `HT-1256`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `9`.
    temp7-depth = `15`.
    temp7-height = `1.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.75`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cepat Tablet 10.5`.
    temp7-productid = `HT-1257`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Cepat Tablet 8`.
    temp7-productid = `HT-1258`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `38`.
    temp7-depth = `21`.
    temp7-height = `3.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `529`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Basic`.
    temp7-productid = `HT-1500`.
    temp7-suppliername = `Technocom`.
    temp7-width = `34`.
    temp7-depth = `35`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `18`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `5000`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Professional`.
    temp7-productid = `HT-1501`.
    temp7-suppliername = `Technocom`.
    temp7-width = `29`.
    temp7-depth = `30`.
    temp7-height = `27`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `25`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `15000`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Server Power Pro`.
    temp7-productid = `HT-1502`.
    temp7-suppliername = `Technocom`.
    temp7-width = `22`.
    temp7-depth = `27.3`.
    temp7-height = `37`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `35`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `25000`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Family PC Basic`.
    temp7-productid = `HT-1600`.
    temp7-suppliername = `Titanium`.
    temp7-width = `21.4`.
    temp7-depth = `29`.
    temp7-height = `38`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `600`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Family PC Pro`.
    temp7-productid = `HT-1601`.
    temp7-suppliername = `Titanium`.
    temp7-width = `25`.
    temp7-depth = `31.7`.
    temp7-height = `40.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `5.3`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `900`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gaming Monster`.
    temp7-productid = `HT-1602`.
    temp7-suppliername = `Titanium`.
    temp7-width = `26.5`.
    temp7-depth = `34`.
    temp7-height = `47`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `5.9`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `1200`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Gaming Monster Pro`.
    temp7-productid = `HT-1603`.
    temp7-suppliername = `Titanium`.
    temp7-width = `27`.
    temp7-depth = `28`.
    temp7-height = `42`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `6.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Error`.
    temp7-price = `1700`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `7" Widescreen Portable DVD Player w MP3`.
    temp7-productid = `HT-2000`.
    temp7-suppliername = `Titanium`.
    temp7-width = `21.4`.
    temp7-depth = `19`.
    temp7-height = `27.6`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.79`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `249.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `10" Portable DVD player`.
    temp7-productid = `HT-2001`.
    temp7-suppliername = `Titanium`.
    temp7-width = `24`.
    temp7-depth = `19.5`.
    temp7-height = `29`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.84`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `449.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Portable DVD Player with 9" LCD Monitor`.
    temp7-productid = `HT-2002`.
    temp7-suppliername = `Technocom`.
    temp7-width = `21`.
    temp7-depth = `16.5`.
    temp7-height = `14`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.72`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `853.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `CD/DVD case: 264 sleeves`.
    temp7-productid = `HT-2025`.
    temp7-suppliername = `Titanium`.
    temp7-width = `13`.
    temp7-depth = `13`.
    temp7-height = `20`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.65`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `44.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Audio/Video Cable Kit - 4m`.
    temp7-productid = `HT-2026`.
    temp7-suppliername = `Titanium`.
    temp7-width = `21`.
    temp7-depth = `10.2`.
    temp7-height = `13`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `29.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Removable CD/DVD Laser Labels`.
    temp7-productid = `HT-2027`.
    temp7-suppliername = `Titanium`.
    temp7-width = `5.5`.
    temp7-depth = `2`.
    temp7-height = `2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.15`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `8.99`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-1`.
    temp7-productid = `HT-6100`.
    temp7-suppliername = `Titanium`.
    temp7-width = `30.4`.
    temp7-depth = `23.1`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.7`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `469`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-2`.
    temp7-productid = `HT-6101`.
    temp7-suppliername = `Technocom`.
    temp7-width = `30.4`.
    temp7-depth = `23.1`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `679`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Beam Breaker B-3`.
    temp7-productid = `HT-6102`.
    temp7-suppliername = `Technocom`.
    temp7-width = `30.4`.
    temp7-depth = `23.1`.
    temp7-height = `23`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `889`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Play Movie`.
    temp7-productid = `HT-6110`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `37`.
    temp7-depth = `24`.
    temp7-height = `6`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.4`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `130`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Record Movie`.
    temp7-productid = `HT-6111`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `38`.
    temp7-depth = `26`.
    temp7-height = `6.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.1`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `288`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelo MusicStick`.
    temp7-productid = `HT-6120`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `1.5`.
    temp7-depth = `6`.
    temp7-height = `1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `134`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `45`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelo Jog-Mate`.
    temp7-productid = `HT-6121`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `5.1`.
    temp7-depth = `8`.
    temp7-height = `9.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `134`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `63`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Pro Player 40`.
    temp7-productid = `HT-6122`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `5.1`.
    temp7-depth = `8`.
    temp7-height = `9.2`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `266`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `167`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Power Pro Player 80`.
    temp7-productid = `HT-6123`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `4`.
    temp7-depth = `6`.
    temp7-height = `0.8`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `267`.
    temp7-weightunit = `G`.
    temp7-weight_state = `Success`.
    temp7-price = `299`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD32`.
    temp7-productid = `HT-6130`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `78`.
    temp7-depth = `22.1`.
    temp7-height = `55`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.6`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1459`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD37`.
    temp7-productid = `HT-6131`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `99.1`.
    temp7-depth = `26`.
    temp7-height = `61`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `2.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1199`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flat Watch HD41`.
    temp7-productid = `HT-6132`.
    temp7-suppliername = `Very Best Screens`.
    temp7-width = `128`.
    temp7-depth = `23`.
    temp7-height = `79.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `1.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `899`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Copperberry`.
    temp7-productid = `HT-7000`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `8.1`.
    temp7-depth = `13`.
    temp7-height = `12.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Silverberry`.
    temp7-productid = `HT-7010`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `8.1`.
    temp7-depth = `13`.
    temp7-height = `12.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Goldberry`.
    temp7-productid = `HT-7020`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `8.1`.
    temp7-depth = `13`.
    temp7-height = `12.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Platinberry`.
    temp7-productid = `HT-7030`.
    temp7-suppliername = `Fasttech`.
    temp7-width = `8.1`.
    temp7-depth = `13`.
    temp7-height = `12.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `549`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I4000`.
    temp7-productid = `HT-8000`.
    temp7-suppliername = `Titanium`.
    temp7-width = `31`.
    temp7-depth = `19`.
    temp7-height = `3.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `799`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I6300c`.
    temp7-productid = `HT-8001`.
    temp7-suppliername = `Titanium`.
    temp7-width = `32`.
    temp7-depth = `20`.
    temp7-height = `3.4`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `4.2`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `799`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I9100`.
    temp7-productid = `HT-8002`.
    temp7-suppliername = `Titanium`.
    temp7-width = `38`.
    temp7-depth = `21`.
    temp7-height = `4.1`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.5`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1199`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `ITelO FlexTop I9800`.
    temp7-productid = `HT-8003`.
    temp7-suppliername = `Titanium`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1388`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Leather Case`.
    temp7-productid = `HT-9991`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.02`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `25`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Alpha`.
    temp7-productid = `HT-9992`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.75`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `599`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Mini Tablet`.
    temp7-productid = `HT-9993`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `833`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Camcorder View`.
    temp7-productid = `HT-9994`.
    temp7-suppliername = `Ultrasonic United`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `27`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `1388`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Tablet Pouch`.
    temp7-productid = `HT-9995`.
    temp7-suppliername = `Titanium`.
    temp7-width = `25`.
    temp7-depth = `40`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.03`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `20`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Tablet Pouch`.
    temp7-productid = `HT-9996`.
    temp7-suppliername = `Titanium`.
    temp7-width = `25`.
    temp7-depth = `40`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.03`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `20`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `e-Book Reader ReadMe`.
    temp7-productid = `HT-9997`.
    temp7-suppliername = `Titanium`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `33`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Smartphone Beta`.
    temp7-productid = `HT-9998`.
    temp7-suppliername = `Titanium`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.75`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `30`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Maxi Tablet`.
    temp7-productid = `HT-9999`.
    temp7-suppliername = `Titanium`.
    temp7-width = `48`.
    temp7-depth = `31`.
    temp7-height = `4.5`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `3.8`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Warning`.
    temp7-price = `749`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    temp7-name = `Flyer`.
    temp7-productid = `PF-1000`.
    temp7-suppliername = `Titanium`.
    temp7-width = `46`.
    temp7-depth = `30`.
    temp7-height = `3`.
    temp7-dimunit = `cm`.
    temp7-weightmeasure = `0.01`.
    temp7-weightunit = `KG`.
    temp7-weight_state = `Success`.
    temp7-price = `0`.
    temp7-currencycode = `EUR`.
    INSERT temp7 INTO TABLE temp6.
    t_all = temp6.

    " the rows binding's sorter, applied to the data the backend sends
    SORT t_all BY name AS TEXT ASCENDING.
    t_products = t_all.

  ENDMETHOD.

ENDCLASS.
