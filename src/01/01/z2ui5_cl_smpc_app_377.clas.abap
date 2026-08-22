" @keywords icontabbar icon tab bar sap.m icontabfilter icontabseparator table overflowtoolbar label column text
" @summary In this example, the Icon Tab Bar is used to apply filters on a table and display the count of the items for each view.
CLASS z2ui5_cl_smpc_app_377 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        product_id     TYPE string,
        name           TYPE string,
        supplier_name  TYPE string,
        weight_measure TYPE p LENGTH 8 DECIMALS 3,
        weight_unit    TYPE string,
        weight_state   TYPE string,
        price          TYPE p LENGTH 8 DECIMALS 2,
        currency_code  TYPE string,
        width          TYPE string,
        depth          TYPE string,
        height         TYPE string,
        dim_unit       TYPE string,
      END OF ty_s_product.
    TYPES temp1_3a5bcee211 TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_products TYPE temp1_3a5bcee211.

    " /ProductCollectionStats/Counts of the shared mock, bound to the tab counts
    DATA count_total      TYPE i.
    DATA count_ok         TYPE i.
    DATA count_heavy      TYPE i.
    DATA count_overweight TYPE i.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    TYPES temp2_3a5bcee211 TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_all TYPE temp2_3a5bcee211.

    METHODS view_display.
    METHODS on_event.
    METHODS table_filter
      IMPORTING
        key TYPE string.
    METHODS weight_state_set.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_377 IMPLEMENTATION.

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
    INSERT `${$parameters>/key}` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `IconTabBar`
            )->a( n = `id`     v = `idIconTabBar`
            )->a( n = `select` v = client->_event( val   = `FILTER_SELECT`
                                                   t_arg = temp1 )
            )->a( n = `class`  v = `sapUiResponsiveContentPadding`

            )->ele( `items`
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

            )->end(

            )->ele( `content`
                )->ele( `Table`
                    )->a( n = `id`             v = `productsTable`
                    )->a( n = `inset`          v = `false`
                    )->a( n = `showSeparators` v = `Inner`
                    )->a( n = `headerText`     v = `Products`
                    )->a( n = `items`          v = |\{ path: '{ client->_bind( val = t_products path = abap_true ) }', sorter: \{ path: 'NAME' \} \}|

                    )->ele( `infoToolbar`
                        )->ele( `OverflowToolbar`
                            )->tag( `Label`
                                )->a( n = `text` v = `Wide range of available products`

                        )->end(
                    )->end(

                    )->ele( `columns`
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
                    )->end(

                    )->ele( `items`
                        )->ele( `ColumnListItem`
                            )->ele( `cells`
                                )->tag( `ObjectIdentifier`
                                    )->a( n = `title` v = `{NAME}`
                                    )->a( n = `text`  v = `{PRODUCT_ID}`
                                )->tag( `Text`
                                    )->a( n = `text` v = `{SUPPLIER_NAME}`
                                )->tag( `Text`
                                    )->a( n = `text` v = `{WIDTH} x {DEPTH} x {HEIGHT} {DIM_UNIT}`
                                )->tag( `ObjectNumber`
                                    )->a( n = `number` v = `{WEIGHT_MEASURE}`
                                    )->a( n = `unit`   v = `{WEIGHT_UNIT}`
                                    " Formatter.weightState computed in ABAP, bound as a finished value
                                    )->a( n = `state`  v = `{WEIGHT_STATE}`
                                )->tag( `ObjectNumber`
                                    )->a( n = `number` v = |\{ parts: [\{ path: 'PRICE' \}, \{ path: 'CURRENCY_CODE' \}], type: 'sap.ui.model.type.Currency', formatOptions: \{ showMeasure: false \} \}|
                                    )->a( n = `unit`   v = `{CURRENCY_CODE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `FILTER_SELECT`.
      table_filter( client->get_event_arg( ) ).
    ENDIF.

  ENDMETHOD.


  METHOD table_filter.
    DATA row LIKE LINE OF t_all.
      DATA keep LIKE abap_false.
      DATA temp3 TYPE z2ui5_cl_smpc_app_377=>ty_s_product-weight_measure.
      DATA grams LIKE temp3.
          DATA temp1 TYPE xsdboolean.
          DATA temp2 TYPE xsdboolean.
          DATA temp4 TYPE xsdboolean.

    " the original's onFilterSelect builds sap.ui.model.Filters on the items
    " binding; the thin frontend filters the model table in ABAP instead.
    " The thresholds are the controller's: 1 KG / 1000 G is "Ok", up to
    " 5 KG / 5000 G is "Heavy", anything above is "Overweight".
    " Collected rather than deleted in place: DELETE ... INDEX sy-tabix inside
    " a LOOP over the same table shifts the rows under the loop's own cursor -
    " on a system it silently SKIPS the row after each deletion, on the
    " transpiled backend it raises TABLE_INVALID_INDEX (2026-08-17).
    CLEAR t_products.

    
    LOOP AT t_all INTO row.
      
      keep = abap_false.
      
      IF row-weight_unit = `G`.
        temp3 = row-weight_measure.
      ELSE.
        temp3 = row-weight_measure * 1000.
      ENDIF.
      
      grams = temp3.

      CASE key.
        WHEN `Ok`.
          
          temp1 = boolc( grams < 1000 ).
          keep = temp1.
        WHEN `Heavy`.
          
          temp2 = boolc( grams >= 1000 AND grams <= 5000 ).
          keep = temp2.
        WHEN `Overweight`.
          
          temp4 = boolc( grams > 5000 ).
          keep = temp4.
        WHEN OTHERS.
          keep = abap_true.
      ENDCASE.

      IF keep = abap_true.
        APPEND row TO t_products.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD weight_state_set.

    " the original's Formatter.weightState, computed in ABAP and bound as a
    " finished value (thin frontend). Its two boundaries are KILOGRAMS
    " (fMaxWeightSuccess = 1, fMaxWeightWarning = 5) and it normalises a G row
    " by 1000 first - both of which this method dropped until 2026-08-21, when
    " it compared the RAW measure against 1000 and 2000 instead. Every KG row
    " is below 1000, so 66 of the 123 rows came out Success: HT-1000 at 4.2 KG
    " should be Warning and HT-1030 at 21 KG should be Error. Same body as the
    " live-checked app 009, and the same normalisation table_filter above
    " already does for its own thresholds.
    FIELD-SYMBOLS <row> LIKE LINE OF t_all.
      DATA weight_kg LIKE <row>-weight_measure.
      DATA temp4 TYPE z2ui5_cl_smpc_app_377=>ty_s_product-weight_state.
    LOOP AT t_all ASSIGNING <row>.
      
      weight_kg = <row>-weight_measure.
      IF <row>-weight_unit = `G`.
        weight_kg = weight_kg / 1000.
      ENDIF.
      
      IF weight_kg < 0.
        temp4 = `None`.
      ELSEIF weight_kg < 1.
        temp4 = `Success`.
      ELSEIF weight_kg < 5.
        temp4 = `Warning`.
      ELSE.
        temp4 = `Error`.
      ENDIF.
      <row>-weight_state = temp4.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.
    DATA temp5 LIKE t_all.
    DATA temp6 LIKE LINE OF temp5.

    " /ProductCollectionStats/Counts of the shared mock
    count_total      = 123.
    count_ok         = 53.
    count_heavy      = 51.
    count_overweight = 19.

    " the shared mock /ProductCollection flattened to the bound columns, all 123 rows kept verbatim
    
    CLEAR temp5.
    
    temp6-product_id = `HT-1000`.
    temp6-name = `Notebook Basic 15`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '4.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '956'.
    temp6-currency_code = `EUR`.
    temp6-width = '30'.
    temp6-depth = '18'.
    temp6-height = '3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1001`.
    temp6-name = `Notebook Basic 17`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '4.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '1249'.
    temp6-currency_code = `EUR`.
    temp6-width = '29'.
    temp6-depth = '17'.
    temp6-height = '3.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1002`.
    temp6-name = `Notebook Basic 18`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '4.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '1570'.
    temp6-currency_code = `EUR`.
    temp6-width = '28'.
    temp6-depth = '19'.
    temp6-height = '2.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1003`.
    temp6-name = `Notebook Basic 19`.
    temp6-supplier_name = `Smartcards`.
    temp6-weight_measure = '4.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '1650'.
    temp6-currency_code = `EUR`.
    temp6-width = '32'.
    temp6-depth = '21'.
    temp6-height = '4'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1007`.
    temp6-name = `ITelO Vault`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '299'.
    temp6-currency_code = `EUR`.
    temp6-width = '32'.
    temp6-depth = '22'.
    temp6-height = '3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1010`.
    temp6-name = `Notebook Professional 15`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '4.3'.
    temp6-weight_unit = `KG`.
    temp6-price = '1999'.
    temp6-currency_code = `EUR`.
    temp6-width = '33'.
    temp6-depth = '20'.
    temp6-height = '3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1011`.
    temp6-name = `Notebook Professional 17`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '4.1'.
    temp6-weight_unit = `KG`.
    temp6-price = '2299'.
    temp6-currency_code = `EUR`.
    temp6-width = '33'.
    temp6-depth = '23'.
    temp6-height = '2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1020`.
    temp6-name = `ITelO Vault Net`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.16'.
    temp6-weight_unit = `KG`.
    temp6-price = '459'.
    temp6-currency_code = `EUR`.
    temp6-width = '10'.
    temp6-depth = '1.8'.
    temp6-height = '17'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1021`.
    temp6-name = `ITelO Vault SAT`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.18'.
    temp6-weight_unit = `KG`.
    temp6-price = '149'.
    temp6-currency_code = `EUR`.
    temp6-width = '11'.
    temp6-depth = '1.7'.
    temp6-height = '18'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1022`.
    temp6-name = `Comfort Easy`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '1679'.
    temp6-currency_code = `EUR`.
    temp6-width = '84'.
    temp6-depth = '1.5'.
    temp6-height = '14'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1023`.
    temp6-name = `Comfort Senior`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '512'.
    temp6-currency_code = `EUR`.
    temp6-width = '80'.
    temp6-depth = '1.6'.
    temp6-height = '13'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1030`.
    temp6-name = `Ergo Screen E-I`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '21'.
    temp6-weight_unit = `KG`.
    temp6-price = '230'.
    temp6-currency_code = `EUR`.
    temp6-width = '37'.
    temp6-depth = '12'.
    temp6-height = '36'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1031`.
    temp6-name = `Ergo Screen E-II`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '21'.
    temp6-weight_unit = `KG`.
    temp6-price = '285'.
    temp6-currency_code = `EUR`.
    temp6-width = '40.8'.
    temp6-depth = '19'.
    temp6-height = '43'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1032`.
    temp6-name = `Ergo Screen E-III`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '21'.
    temp6-weight_unit = `KG`.
    temp6-price = '345'.
    temp6-currency_code = `EUR`.
    temp6-width = '40.8'.
    temp6-depth = '19'.
    temp6-height = '43'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1035`.
    temp6-name = `Flat Basic`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '14'.
    temp6-weight_unit = `KG`.
    temp6-price = '399'.
    temp6-currency_code = `EUR`.
    temp6-width = '39'.
    temp6-depth = '20'.
    temp6-height = '41'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1036`.
    temp6-name = `Flat Future`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '15'.
    temp6-weight_unit = `KG`.
    temp6-price = '430'.
    temp6-currency_code = `EUR`.
    temp6-width = '45'.
    temp6-depth = '26'.
    temp6-height = '46'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1037`.
    temp6-name = `Flat XL`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '17'.
    temp6-weight_unit = `KG`.
    temp6-price = '1230'.
    temp6-currency_code = `EUR`.
    temp6-width = '54.5'.
    temp6-depth = '22.1'.
    temp6-height = '39.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1040`.
    temp6-name = `Laser Professional Eco`.
    temp6-supplier_name = `Alpha Printers`.
    temp6-weight_measure = '32'.
    temp6-weight_unit = `KG`.
    temp6-price = '830'.
    temp6-currency_code = `EUR`.
    temp6-width = '51'.
    temp6-depth = '46'.
    temp6-height = '30'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1041`.
    temp6-name = `Laser Basic`.
    temp6-supplier_name = `Alpha Printers`.
    temp6-weight_measure = '23'.
    temp6-weight_unit = `KG`.
    temp6-price = '490'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '42'.
    temp6-height = '26'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1042`.
    temp6-name = `Laser Allround`.
    temp6-supplier_name = `Alpha Printers`.
    temp6-weight_measure = '17'.
    temp6-weight_unit = `KG`.
    temp6-price = '349'.
    temp6-currency_code = `EUR`.
    temp6-width = '53'.
    temp6-depth = '50'.
    temp6-height = '65'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1050`.
    temp6-name = `Ultra Jet Super Color`.
    temp6-supplier_name = `Alpha Printers`.
    temp6-weight_measure = '3'.
    temp6-weight_unit = `KG`.
    temp6-price = '139'.
    temp6-currency_code = `EUR`.
    temp6-width = '41'.
    temp6-depth = '41'.
    temp6-height = '28'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1051`.
    temp6-name = `Ultra Jet Mobile`.
    temp6-supplier_name = `Printer for All`.
    temp6-weight_measure = '1.9'.
    temp6-weight_unit = `KG`.
    temp6-price = '99'.
    temp6-currency_code = `EUR`.
    temp6-width = '46'.
    temp6-depth = '32'.
    temp6-height = '25'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1052`.
    temp6-name = `Ultra Jet Super Highspeed`.
    temp6-supplier_name = `Printer for All`.
    temp6-weight_measure = '18'.
    temp6-weight_unit = `KG`.
    temp6-price = '170'.
    temp6-currency_code = `EUR`.
    temp6-width = '41'.
    temp6-depth = '41'.
    temp6-height = '28'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1055`.
    temp6-name = `Multi Print`.
    temp6-supplier_name = `Printer for All`.
    temp6-weight_measure = '6.3'.
    temp6-weight_unit = `KG`.
    temp6-price = '99'.
    temp6-currency_code = `EUR`.
    temp6-width = '55'.
    temp6-depth = '45'.
    temp6-height = '29'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1056`.
    temp6-name = `Multi Color`.
    temp6-supplier_name = `Printer for All`.
    temp6-weight_measure = '4.3'.
    temp6-weight_unit = `KG`.
    temp6-price = '119'.
    temp6-currency_code = `EUR`.
    temp6-width = '51'.
    temp6-depth = '41.3'.
    temp6-height = '22'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1060`.
    temp6-name = `Cordless Mouse`.
    temp6-supplier_name = `Oxynum`.
    temp6-weight_measure = '0.09'.
    temp6-weight_unit = `KG`.
    temp6-price = '9'.
    temp6-currency_code = `EUR`.
    temp6-width = '6'.
    temp6-depth = '14.5'.
    temp6-height = '3.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1061`.
    temp6-name = `Speed Mouse`.
    temp6-supplier_name = `Oxynum`.
    temp6-weight_measure = '0.09'.
    temp6-weight_unit = `KG`.
    temp6-price = '7'.
    temp6-currency_code = `EUR`.
    temp6-width = '7'.
    temp6-depth = '15'.
    temp6-height = '3.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1062`.
    temp6-name = `Track Mouse`.
    temp6-supplier_name = `Oxynum`.
    temp6-weight_measure = '0.03'.
    temp6-weight_unit = `KG`.
    temp6-price = '11'.
    temp6-currency_code = `EUR`.
    temp6-width = '3'.
    temp6-depth = '7'.
    temp6-height = '4'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1063`.
    temp6-name = `Ergonomic Keyboard`.
    temp6-supplier_name = `Oxynum`.
    temp6-weight_measure = '2.1'.
    temp6-weight_unit = `KG`.
    temp6-price = '14'.
    temp6-currency_code = `EUR`.
    temp6-width = '50'.
    temp6-depth = '21'.
    temp6-height = '3.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1064`.
    temp6-name = `Internet Keyboard`.
    temp6-supplier_name = `Oxynum`.
    temp6-weight_measure = '1.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '16'.
    temp6-currency_code = `EUR`.
    temp6-width = '52'.
    temp6-depth = '25'.
    temp6-height = '3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1065`.
    temp6-name = `Media Keyboard`.
    temp6-supplier_name = `Oxynum`.
    temp6-weight_measure = '2.3'.
    temp6-weight_unit = `KG`.
    temp6-price = '26'.
    temp6-currency_code = `EUR`.
    temp6-width = '51.4'.
    temp6-depth = '23'.
    temp6-height = '4'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1066`.
    temp6-name = `Mousepad`.
    temp6-supplier_name = `Oxynum`.
    temp6-weight_measure = '80'.
    temp6-weight_unit = `G`.
    temp6-price = '6.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '15'.
    temp6-depth = '6'.
    temp6-height = '0.2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1067`.
    temp6-name = `Ergo Mousepad`.
    temp6-supplier_name = `Oxynum`.
    temp6-weight_measure = '80'.
    temp6-weight_unit = `G`.
    temp6-price = '8.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '15'.
    temp6-depth = '6'.
    temp6-height = '0.2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1068`.
    temp6-name = `Designer Mousepad`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '90'.
    temp6-weight_unit = `G`.
    temp6-price = '12.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '24'.
    temp6-depth = '24'.
    temp6-height = '0.6'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1069`.
    temp6-name = `Universal card reader`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '45'.
    temp6-weight_unit = `G`.
    temp6-price = '14'.
    temp6-currency_code = `EUR`.
    temp6-width = '6'.
    temp6-depth = '6'.
    temp6-height = '3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1070`.
    temp6-name = `Proctra X`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '0.255'.
    temp6-weight_unit = `KG`.
    temp6-price = '70.9'.
    temp6-currency_code = `EUR`.
    temp6-width = '22'.
    temp6-depth = '35'.
    temp6-height = '17'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1071`.
    temp6-name = `Gladiator MX`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '0.3'.
    temp6-weight_unit = `KG`.
    temp6-price = '81.7'.
    temp6-currency_code = `EUR`.
    temp6-width = '22'.
    temp6-depth = '35'.
    temp6-height = '17'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1072`.
    temp6-name = `Hurricane GX`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '0.4'.
    temp6-weight_unit = `KG`.
    temp6-price = '101.2'.
    temp6-currency_code = `EUR`.
    temp6-width = '22'.
    temp6-depth = '35'.
    temp6-height = '17'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1073`.
    temp6-name = `Hurricane GX/LN`.
    temp6-supplier_name = `Smartcards`.
    temp6-weight_measure = '0.4'.
    temp6-weight_unit = `KG`.
    temp6-price = '139.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '22'.
    temp6-depth = '35'.
    temp6-height = '17'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1080`.
    temp6-name = `Photo Scan`.
    temp6-supplier_name = `Printer for All`.
    temp6-weight_measure = '2.3'.
    temp6-weight_unit = `KG`.
    temp6-price = '129'.
    temp6-currency_code = `EUR`.
    temp6-width = '34'.
    temp6-depth = '48'.
    temp6-height = '5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1081`.
    temp6-name = `Power Scan`.
    temp6-supplier_name = `Printer for All`.
    temp6-weight_measure = '2.4'.
    temp6-weight_unit = `KG`.
    temp6-price = '89'.
    temp6-currency_code = `EUR`.
    temp6-width = '31'.
    temp6-depth = '43'.
    temp6-height = '7'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1082`.
    temp6-name = `Jet Scan Professional`.
    temp6-supplier_name = `Printer for All`.
    temp6-weight_measure = '3.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '169'.
    temp6-currency_code = `EUR`.
    temp6-width = '33'.
    temp6-depth = '41'.
    temp6-height = '12'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1083`.
    temp6-name = `Jet Scan Professional`.
    temp6-supplier_name = `Printer for All`.
    temp6-weight_measure = '3.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '189'.
    temp6-currency_code = `EUR`.
    temp6-width = '35'.
    temp6-depth = '40'.
    temp6-height = '10'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1085`.
    temp6-name = `Copymaster`.
    temp6-supplier_name = `Alpha Printers`.
    temp6-weight_measure = '23.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '1499'.
    temp6-currency_code = `EUR`.
    temp6-width = '45'.
    temp6-depth = '42'.
    temp6-height = '22'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1090`.
    temp6-name = `Surround Sound`.
    temp6-supplier_name = `Speaker Experts`.
    temp6-weight_measure = '3'.
    temp6-weight_unit = `KG`.
    temp6-price = '39'.
    temp6-currency_code = `EUR`.
    temp6-width = '12'.
    temp6-depth = '10'.
    temp6-height = '16'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1091`.
    temp6-name = `Blaster Extreme`.
    temp6-supplier_name = `Speaker Experts`.
    temp6-weight_measure = '1.4'.
    temp6-weight_unit = `KG`.
    temp6-price = '26'.
    temp6-currency_code = `EUR`.
    temp6-width = '13'.
    temp6-depth = '11'.
    temp6-height = '17.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1092`.
    temp6-name = `Sound Booster`.
    temp6-supplier_name = `Speaker Experts`.
    temp6-weight_measure = '2.1'.
    temp6-weight_unit = `KG`.
    temp6-price = '45'.
    temp6-currency_code = `EUR`.
    temp6-width = '12.4'.
    temp6-depth = '10.4'.
    temp6-height = '18.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1095`.
    temp6-name = `Lovely Sound 5.1 Wireless`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '80'.
    temp6-weight_unit = `G`.
    temp6-price = '49'.
    temp6-currency_code = `EUR`.
    temp6-width = '24'.
    temp6-depth = '19'.
    temp6-height = '23'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1096`.
    temp6-name = `Lovely Sound 5.1`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '130'.
    temp6-weight_unit = `G`.
    temp6-price = '39'.
    temp6-currency_code = `EUR`.
    temp6-width = '25'.
    temp6-depth = '17'.
    temp6-height = '19'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1097`.
    temp6-name = `Lovely Sound Stereo`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '60'.
    temp6-weight_unit = `G`.
    temp6-price = '29'.
    temp6-currency_code = `EUR`.
    temp6-width = '21.3'.
    temp6-depth = '2.4'.
    temp6-height = '19.7'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1100`.
    temp6-name = `Smart Office`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '1.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '89.9'.
    temp6-currency_code = `EUR`.
    temp6-width = '15'.
    temp6-depth = '6.5'.
    temp6-height = '2.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1101`.
    temp6-name = `Smart Design`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '79.9'.
    temp6-currency_code = `EUR`.
    temp6-width = '14'.
    temp6-depth = '6.7'.
    temp6-height = '24'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1102`.
    temp6-name = `Smart Network`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '69'.
    temp6-currency_code = `EUR`.
    temp6-width = '16'.
    temp6-depth = '6'.
    temp6-height = '27'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1103`.
    temp6-name = `Smart Multimedia`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '77'.
    temp6-currency_code = `EUR`.
    temp6-width = '11'.
    temp6-depth = '3.4'.
    temp6-height = '22'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1104`.
    temp6-name = `Smart Games`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '1.1'.
    temp6-weight_unit = `KG`.
    temp6-price = '55'.
    temp6-currency_code = `EUR`.
    temp6-width = '10'.
    temp6-depth = '3'.
    temp6-height = '30'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1105`.
    temp6-name = `Smart Internet Antivirus`.
    temp6-supplier_name = `Brainsoft`.
    temp6-weight_measure = '0.7'.
    temp6-weight_unit = `KG`.
    temp6-price = '29'.
    temp6-currency_code = `EUR`.
    temp6-width = '16'.
    temp6-depth = '4'.
    temp6-height = '21'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1106`.
    temp6-name = `Smart Firewall`.
    temp6-supplier_name = `Brainsoft`.
    temp6-weight_measure = '0.9'.
    temp6-weight_unit = `KG`.
    temp6-price = '34'.
    temp6-currency_code = `EUR`.
    temp6-width = '17.9'.
    temp6-depth = '4.2'.
    temp6-height = '23.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1107`.
    temp6-name = `Smart Money`.
    temp6-supplier_name = `Brainsoft`.
    temp6-weight_measure = '0.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '29.9'.
    temp6-currency_code = `EUR`.
    temp6-width = '12'.
    temp6-depth = '1.5'.
    temp6-height = '19'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1110`.
    temp6-name = `PC Lock`.
    temp6-supplier_name = `Red Point Stores`.
    temp6-weight_measure = '0.03'.
    temp6-weight_unit = `KG`.
    temp6-price = '8.9'.
    temp6-currency_code = `EUR`.
    temp6-width = '20'.
    temp6-depth = '8'.
    temp6-height = '4.3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1111`.
    temp6-name = `Notebook Lock`.
    temp6-supplier_name = `Red Point Stores`.
    temp6-weight_measure = '0.02'.
    temp6-weight_unit = `KG`.
    temp6-price = '6.9'.
    temp6-currency_code = `EUR`.
    temp6-width = '31'.
    temp6-depth = '9'.
    temp6-height = '7'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1112`.
    temp6-name = `Web cam reality`.
    temp6-supplier_name = `Red Point Stores`.
    temp6-weight_measure = '0.075'.
    temp6-weight_unit = `KG`.
    temp6-price = '39'.
    temp6-currency_code = `EUR`.
    temp6-width = '9'.
    temp6-depth = '8.2'.
    temp6-height = '1.3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1113`.
    temp6-name = `Screen clean`.
    temp6-supplier_name = `Red Point Stores`.
    temp6-weight_measure = '0.05'.
    temp6-weight_unit = `KG`.
    temp6-price = '2.3'.
    temp6-currency_code = `EUR`.
    temp6-width = '2'.
    temp6-depth = '2'.
    temp6-height = '0.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1114`.
    temp6-name = `Fabric bag professional`.
    temp6-supplier_name = `Red Point Stores`.
    temp6-weight_measure = '1.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '31'.
    temp6-currency_code = `EUR`.
    temp6-width = '42'.
    temp6-depth = '32'.
    temp6-height = '7'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1115`.
    temp6-name = `Wireless DSL Router`.
    temp6-supplier_name = `Red Point Stores`.
    temp6-weight_measure = '0.45'.
    temp6-weight_unit = `KG`.
    temp6-price = '49'.
    temp6-currency_code = `EUR`.
    temp6-width = '19.3'.
    temp6-depth = '18'.
    temp6-height = '5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1116`.
    temp6-name = `Wireless DSL Router / Repeater`.
    temp6-supplier_name = `Red Point Stores`.
    temp6-weight_measure = '0.45'.
    temp6-weight_unit = `KG`.
    temp6-price = '59'.
    temp6-currency_code = `EUR`.
    temp6-width = '19.3'.
    temp6-depth = '18'.
    temp6-height = '5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1117`.
    temp6-name = `Wireless DSL Router / Repeater and Print Server`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.45'.
    temp6-weight_unit = `KG`.
    temp6-price = '69'.
    temp6-currency_code = `EUR`.
    temp6-width = '19.3'.
    temp6-depth = '18'.
    temp6-height = '5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1118`.
    temp6-name = `USB Stick`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.015'.
    temp6-weight_unit = `KG`.
    temp6-price = '35'.
    temp6-currency_code = `EUR`.
    temp6-width = '1.5'.
    temp6-depth = '8.7'.
    temp6-height = '1.2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1119`.
    temp6-name = `Travel Adapter`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '88'.
    temp6-weight_unit = `G`.
    temp6-price = '79'.
    temp6-currency_code = `EUR`.
    temp6-width = '2'.
    temp6-depth = '3.1'.
    temp6-height = '3.9'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1120`.
    temp6-name = `Cordless Bluetooth Keyboard, english international`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '1'.
    temp6-weight_unit = `KG`.
    temp6-price = '29'.
    temp6-currency_code = `EUR`.
    temp6-width = '51.4'.
    temp6-depth = '23'.
    temp6-height = '4'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1137`.
    temp6-name = `Flat XXL`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '18'.
    temp6-weight_unit = `KG`.
    temp6-price = '1430'.
    temp6-currency_code = `EUR`.
    temp6-width = '54'.
    temp6-depth = '22'.
    temp6-height = '38'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1138`.
    temp6-name = `Pocket Mouse`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.02'.
    temp6-weight_unit = `KG`.
    temp6-price = '23'.
    temp6-currency_code = `EUR`.
    temp6-width = '0.3'.
    temp6-depth = '0.5'.
    temp6-height = '1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1210`.
    temp6-name = `PC Power Station`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '2.3'.
    temp6-weight_unit = `KG`.
    temp6-price = '2399'.
    temp6-currency_code = `EUR`.
    temp6-width = '28'.
    temp6-depth = '31'.
    temp6-height = '43'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1251`.
    temp6-name = `Astro Laptop 1516`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '4.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '989'.
    temp6-currency_code = `EUR`.
    temp6-width = '30'.
    temp6-depth = '18'.
    temp6-height = '3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1252`.
    temp6-name = `Astro Phone 6`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '0.75'.
    temp6-weight_unit = `KG`.
    temp6-price = '649'.
    temp6-currency_code = `EUR`.
    temp6-width = '8'.
    temp6-depth = '6'.
    temp6-height = '1.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1253`.
    temp6-name = `Benda Laptop 1408`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '4.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '976'.
    temp6-currency_code = `EUR`.
    temp6-width = '30'.
    temp6-depth = '18'.
    temp6-height = '3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1254`.
    temp6-name = `Bending Screen 21HD`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '15'.
    temp6-weight_unit = `KG`.
    temp6-price = '250'.
    temp6-currency_code = `EUR`.
    temp6-width = '37'.
    temp6-depth = '12'.
    temp6-height = '36'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1255`.
    temp6-name = `Broad Screen 22HD`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '16'.
    temp6-weight_unit = `KG`.
    temp6-price = '270'.
    temp6-currency_code = `EUR`.
    temp6-width = '39'.
    temp6-depth = '12'.
    temp6-height = '38'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1256`.
    temp6-name = `Cerdik Phone 7`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '0.75'.
    temp6-weight_unit = `KG`.
    temp6-price = '549'.
    temp6-currency_code = `EUR`.
    temp6-width = '9'.
    temp6-depth = '15'.
    temp6-height = '1.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1257`.
    temp6-name = `Cepat Tablet 10.5`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '2.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '549'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1258`.
    temp6-name = `Cepat Tablet 8`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '2.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '529'.
    temp6-currency_code = `EUR`.
    temp6-width = '38'.
    temp6-depth = '21'.
    temp6-height = '3.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1500`.
    temp6-name = `Server Basic`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '18'.
    temp6-weight_unit = `KG`.
    temp6-price = '5000'.
    temp6-currency_code = `EUR`.
    temp6-width = '34'.
    temp6-depth = '35'.
    temp6-height = '23'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1501`.
    temp6-name = `Server Professional`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '25'.
    temp6-weight_unit = `KG`.
    temp6-price = '15000'.
    temp6-currency_code = `EUR`.
    temp6-width = '29'.
    temp6-depth = '30'.
    temp6-height = '27'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1502`.
    temp6-name = `Server Power Pro`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '35'.
    temp6-weight_unit = `KG`.
    temp6-price = '25000'.
    temp6-currency_code = `EUR`.
    temp6-width = '22'.
    temp6-depth = '27.3'.
    temp6-height = '37'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1600`.
    temp6-name = `Family PC Basic`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '4.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '600'.
    temp6-currency_code = `EUR`.
    temp6-width = '21.4'.
    temp6-depth = '29'.
    temp6-height = '38'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1601`.
    temp6-name = `Family PC Pro`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '5.3'.
    temp6-weight_unit = `KG`.
    temp6-price = '900'.
    temp6-currency_code = `EUR`.
    temp6-width = '25'.
    temp6-depth = '31.7'.
    temp6-height = '40.2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1602`.
    temp6-name = `Gaming Monster`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '5.9'.
    temp6-weight_unit = `KG`.
    temp6-price = '1200'.
    temp6-currency_code = `EUR`.
    temp6-width = '26.5'.
    temp6-depth = '34'.
    temp6-height = '47'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-1603`.
    temp6-name = `Gaming Monster Pro`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '6.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '1700'.
    temp6-currency_code = `EUR`.
    temp6-width = '27'.
    temp6-depth = '28'.
    temp6-height = '42'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-2000`.
    temp6-name = `7" Widescreen Portable DVD Player w MP3`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.79'.
    temp6-weight_unit = `KG`.
    temp6-price = '249.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '21.4'.
    temp6-depth = '19'.
    temp6-height = '27.6'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-2001`.
    temp6-name = `10" Portable DVD player`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.84'.
    temp6-weight_unit = `KG`.
    temp6-price = '449.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '24'.
    temp6-depth = '19.5'.
    temp6-height = '29'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-2002`.
    temp6-name = `Portable DVD Player with 9" LCD Monitor`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '0.72'.
    temp6-weight_unit = `KG`.
    temp6-price = '853.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '21'.
    temp6-depth = '16.5'.
    temp6-height = '14'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-2025`.
    temp6-name = `CD/DVD case: 264 sleeves`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.65'.
    temp6-weight_unit = `KG`.
    temp6-price = '44.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '13'.
    temp6-depth = '13'.
    temp6-height = '20'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-2026`.
    temp6-name = `Audio/Video Cable Kit - 4m`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '29.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '21'.
    temp6-depth = '10.2'.
    temp6-height = '13'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-2027`.
    temp6-name = `Removable CD/DVD Laser Labels`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.15'.
    temp6-weight_unit = `KG`.
    temp6-price = '8.99'.
    temp6-currency_code = `EUR`.
    temp6-width = '5.5'.
    temp6-depth = '2'.
    temp6-height = '2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6100`.
    temp6-name = `Beam Breaker B-1`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '1.7'.
    temp6-weight_unit = `KG`.
    temp6-price = '469'.
    temp6-currency_code = `EUR`.
    temp6-width = '30.4'.
    temp6-depth = '23.1'.
    temp6-height = '23'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6101`.
    temp6-name = `Beam Breaker B-2`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '2'.
    temp6-weight_unit = `KG`.
    temp6-price = '679'.
    temp6-currency_code = `EUR`.
    temp6-width = '30.4'.
    temp6-depth = '23.1'.
    temp6-height = '23'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6102`.
    temp6-name = `Beam Breaker B-3`.
    temp6-supplier_name = `Technocom`.
    temp6-weight_measure = '2.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '889'.
    temp6-currency_code = `EUR`.
    temp6-width = '30.4'.
    temp6-depth = '23.1'.
    temp6-height = '23'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6110`.
    temp6-name = `Play Movie`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '2.4'.
    temp6-weight_unit = `KG`.
    temp6-price = '130'.
    temp6-currency_code = `EUR`.
    temp6-width = '37'.
    temp6-depth = '24'.
    temp6-height = '6'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6111`.
    temp6-name = `Record Movie`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '3.1'.
    temp6-weight_unit = `KG`.
    temp6-price = '288'.
    temp6-currency_code = `EUR`.
    temp6-width = '38'.
    temp6-depth = '26'.
    temp6-height = '6.2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6120`.
    temp6-name = `ITelo MusicStick`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '134'.
    temp6-weight_unit = `G`.
    temp6-price = '45'.
    temp6-currency_code = `EUR`.
    temp6-width = '1.5'.
    temp6-depth = '6'.
    temp6-height = '1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6121`.
    temp6-name = `ITelo Jog-Mate`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '134'.
    temp6-weight_unit = `G`.
    temp6-price = '63'.
    temp6-currency_code = `EUR`.
    temp6-width = '5.1'.
    temp6-depth = '8'.
    temp6-height = '9.2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6122`.
    temp6-name = `Power Pro Player 40`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '266'.
    temp6-weight_unit = `G`.
    temp6-price = '167'.
    temp6-currency_code = `EUR`.
    temp6-width = '5.1'.
    temp6-depth = '8'.
    temp6-height = '9.2'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6123`.
    temp6-name = `Power Pro Player 80`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '267'.
    temp6-weight_unit = `G`.
    temp6-price = '299'.
    temp6-currency_code = `EUR`.
    temp6-width = '4'.
    temp6-depth = '6'.
    temp6-height = '0.8'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6130`.
    temp6-name = `Flat Watch HD32`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '2.6'.
    temp6-weight_unit = `KG`.
    temp6-price = '1459'.
    temp6-currency_code = `EUR`.
    temp6-width = '78'.
    temp6-depth = '22.1'.
    temp6-height = '55'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6131`.
    temp6-name = `Flat Watch HD37`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '2.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '1199'.
    temp6-currency_code = `EUR`.
    temp6-width = '99.1'.
    temp6-depth = '26'.
    temp6-height = '61'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-6132`.
    temp6-name = `Flat Watch HD41`.
    temp6-supplier_name = `Very Best Screens`.
    temp6-weight_measure = '1.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '899'.
    temp6-currency_code = `EUR`.
    temp6-width = '128'.
    temp6-depth = '23'.
    temp6-height = '79.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-7000`.
    temp6-name = `Copperberry`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '0.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '549'.
    temp6-currency_code = `EUR`.
    temp6-width = '8.1'.
    temp6-depth = '13'.
    temp6-height = '12.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-7010`.
    temp6-name = `Silverberry`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '0.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '549'.
    temp6-currency_code = `EUR`.
    temp6-width = '8.1'.
    temp6-depth = '13'.
    temp6-height = '12.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-7020`.
    temp6-name = `Goldberry`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '0.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '549'.
    temp6-currency_code = `EUR`.
    temp6-width = '8.1'.
    temp6-depth = '13'.
    temp6-height = '12.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-7030`.
    temp6-name = `Platinberry`.
    temp6-supplier_name = `Fasttech`.
    temp6-weight_measure = '0.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '549'.
    temp6-currency_code = `EUR`.
    temp6-width = '8.1'.
    temp6-depth = '13'.
    temp6-height = '12.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-8000`.
    temp6-name = `ITelO FlexTop I4000`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '4'.
    temp6-weight_unit = `KG`.
    temp6-price = '799'.
    temp6-currency_code = `EUR`.
    temp6-width = '31'.
    temp6-depth = '19'.
    temp6-height = '3.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-8001`.
    temp6-name = `ITelO FlexTop I6300c`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '4.2'.
    temp6-weight_unit = `KG`.
    temp6-price = '799'.
    temp6-currency_code = `EUR`.
    temp6-width = '32'.
    temp6-depth = '20'.
    temp6-height = '3.4'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-8002`.
    temp6-name = `ITelO FlexTop I9100`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '3.5'.
    temp6-weight_unit = `KG`.
    temp6-price = '1199'.
    temp6-currency_code = `EUR`.
    temp6-width = '38'.
    temp6-depth = '21'.
    temp6-height = '4.1'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-8003`.
    temp6-name = `ITelO FlexTop I9800`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '3.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '1388'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9991`.
    temp6-name = `Smartphone Leather Case`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '0.02'.
    temp6-weight_unit = `KG`.
    temp6-price = '25'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9992`.
    temp6-name = `Smartphone Alpha`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '0.75'.
    temp6-weight_unit = `KG`.
    temp6-price = '599'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9993`.
    temp6-name = `Mini Tablet`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '3.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '833'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9994`.
    temp6-name = `Camcorder View`.
    temp6-supplier_name = `Ultrasonic United`.
    temp6-weight_measure = '3.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '1388'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '27'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9995`.
    temp6-name = `Tablet Pouch`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.03'.
    temp6-weight_unit = `KG`.
    temp6-price = '20'.
    temp6-currency_code = `EUR`.
    temp6-width = '25'.
    temp6-depth = '40'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9996`.
    temp6-name = `Tablet Pouch`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.03'.
    temp6-weight_unit = `KG`.
    temp6-price = '20'.
    temp6-currency_code = `EUR`.
    temp6-width = '25'.
    temp6-depth = '40'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9997`.
    temp6-name = `e-Book Reader ReadMe`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '3.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '33'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9998`.
    temp6-name = `Smartphone Beta`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.75'.
    temp6-weight_unit = `KG`.
    temp6-price = '30'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `HT-9999`.
    temp6-name = `Maxi Tablet`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '3.8'.
    temp6-weight_unit = `KG`.
    temp6-price = '749'.
    temp6-currency_code = `EUR`.
    temp6-width = '48'.
    temp6-depth = '31'.
    temp6-height = '4.5'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    temp6-product_id = `PF-1000`.
    temp6-name = `Flyer`.
    temp6-supplier_name = `Titanium`.
    temp6-weight_measure = '0.01'.
    temp6-weight_unit = `KG`.
    temp6-price = '0'.
    temp6-currency_code = `EUR`.
    temp6-width = '46'.
    temp6-depth = '30'.
    temp6-height = '3'.
    temp6-dim_unit = `cm`.
    INSERT temp6 INTO TABLE temp5.
    t_all = temp5.

    weight_state_set( ).
    t_products = t_all.

  ENDMETHOD.

ENDCLASS.
