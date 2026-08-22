" @keywords table sap.ui.table selectcopypaste column
" @summary Shows cell selection, copy and paste interaction in the table.
CLASS z2ui5_cl_smpc_app_360 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name         TYPE string,
        productid    TYPE string,
        category     TYPE string,
        suppliername TYPE string,
        price        TYPE string,
        currencycode TYPE string,
        width        TYPE string,
        height       TYPE string,
        depth        TYPE string,
        dimunit      TYPE string,
      END OF ty_s_product,
      BEGIN OF ty_s_mode,
        mode TYPE string,
      END OF ty_s_mode.
    DATA t_products       TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    " the original's `ui>` model: the three selection modes and the picked one
    DATA t_selectionmodes TYPE STANDARD TABLE OF ty_s_mode WITH DEFAULT KEY.
    DATA selection_mode   TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_360 IMPLEMENTATION.

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

    " the select / copy / paste demo. The selection-mode Select and the
    " MultiSelectionPlugin bind the same field, so onSelectChange disappears;
    " the paste event carries the pasted data to the backend, which reports it.
    
    CLEAR temp1.
    INSERT `${$parameters>/data}` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`     v = `sap.ui.table`
        )->a( n = `xmlns:trm` v = `sap.ui.table.rowmodes`
        )->a( n = `xmlns:tp`  v = `sap.ui.table.plugins`
        )->a( n = `xmlns:mp`  v = `sap.m.plugins`
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
                    )->a( n = `id`                  v = `table`
                    )->a( n = `enableSelectAll`     v = `false`
                    )->a( n = `rows`                v = client->_bind( t_products )
                    )->a( n = `threshold`           v = `15`
                    )->a( n = `enableBusyIndicator` v = `true`
                    )->a( n = `ariaLabelledBy`      v = `title`
                    )->a( n = `paste`               v = client->_event( val   = `PASTE`
                                                                        t_arg = temp1 )

                    )->ele( `dependents`
                        )->tag( n = `MultiSelectionPlugin` ns = `tp`
                            )->a( n = `limit`              v = `100`
                            )->a( n = `enableNotification` v = `true`
                            )->a( n = `selectionMode`      v = client->_bind( selection_mode )

                    )->end(
                    )->ele( `rowMode`
                        )->tag( n = `Fixed` ns = `trm`
                            )->a( n = `rowCount` v = `7`

                    )->end(
                    )->ele( `noData`
                        )->tag( n = `BusyIndicator` ns = `m`
                            )->a( n = `class` v = `sapUiMediumMargin`

                    )->end(
                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `id`    v = `toolbar`
                            )->a( n = `style` v = `Clear`

                            )->tag( n = `Title` ns = `m`
                                )->a( n = `id`   v = `title`
                                )->a( n = `text` v = `Products`

                            )->tag( n = `ToolbarSpacer` ns = `m`

                            )->ele( n = `Select` ns = `m`
                                )->a( n = `items`       v = client->_bind( t_selectionmodes )
                                )->a( n = `selectedKey` v = client->_bind( selection_mode )

                                )->tag( n = `Item` ns = `c`
                                    )->a( n = `key`  v = `{MODE}`
                                    )->a( n = `text` v = `{MODE}`

                            )->end(
                            )->ele( n = `Button` ns = `m`
                                )->ele( n = `dependents` ns = `m`
                                    )->tag( n = `PasteProvider` ns = `mp`
                                        )->a( n = `pasteFor` v = `table`

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`
                            )->a( n = `sortProperty`   v = `NAME`
                            )->a( n = `filterProperty` v = `NAME`
                            )->a( n = `autoResizable`  v = `true`
                            )->a( n = `width`          v = `11rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Name`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{NAME}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `sortProperty`   v = `PRODUCTID`
                            )->a( n = `filterProperty` v = `PRODUCTID`
                            )->a( n = `autoResizable`  v = `true`
                            )->a( n = `width`          v = `6rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product ID`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{PRODUCTID}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `sortProperty`   v = `CATEGORY`
                            )->a( n = `filterProperty` v = `CATEGORY`
                            )->a( n = `autoResizable`  v = `true`
                            )->a( n = `width`          v = `11rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Prod. Cat.`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{CATEGORY}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `sortProperty`   v = `SUPPLIERNAME`
                            )->a( n = `filterProperty` v = `SUPPLIERNAME`
                            )->a( n = `autoResizable`  v = `true`
                            )->a( n = `width`          v = `12rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Company Name`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{SUPPLIERNAME}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `filterProperty` v = `PRICE`
                            )->a( n = `width`          v = `9rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Unit Price`

                            )->ele( `template`
                                )->tag( n = `Currency` ns = `u`
                                    )->a( n = `value`    v = |\{ path: 'PRICE', type: 'sap.ui.model.type.String' \}|
                                    )->a( n = `currency` v = `{CURRENCYCODE}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `hAlign`        v = `End`
                            )->a( n = `autoResizable` v = `true`
                            )->a( n = `width`         v = `9rem`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Dimensions`

                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{WIDTH}x{HEIGHT}x{DEPTH} {DIMUNIT}`
                                    )->a( n = `wrapping` v = `false`

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

    IF client->get_event( ) = `PASTE`.
      " onPaste: report what arrived. The original first asks whether to
      " paste at the selected cell range; the CellSelector that provides that
      " range is added in the controller and has no counterpart here, so the
      " table-level branch of the same handler is what remains
      client->message_toast_display( |Pasted Data (on Table Level):\n\n{ client->get_event_arg( ) }| ).
    ENDIF.


  ENDMETHOD.


  METHOD model_init.

    " the `ui>` model the controller sets: three selection modes, MultiToggle
    " preselected
    DATA temp3 LIKE t_selectionmodes.
    DATA temp4 LIKE LINE OF temp3.
    DATA temp5 LIKE t_products.
    DATA temp6 LIKE LINE OF temp5.
    CLEAR temp3.
    
    temp4-mode = `MultiToggle`.
    INSERT temp4 INTO TABLE temp3.
    temp4-mode = `Single`.
    INSERT temp4 INTO TABLE temp3.
    temp4-mode = `None`.
    INSERT temp4 INTO TABLE temp3.
    t_selectionmodes = temp3.
    selection_mode   = `MultiToggle`.

    " the OData ProductSet the sample serves from a MockServer, inlined with
    " the columns the six table columns bind - all 115 rows of ProductSet.json
    
    CLEAR temp5.
    
    temp6-name = `Flyer`.
    temp6-productid = `AD-1000`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Robert Brown Entertainment`.
    temp6-price = `0.0`.
    temp6-currencycode = `CAD`.
    temp6-width = `0.46`.
    temp6-height = `0.03`.
    temp6-depth = `0.3`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 15`.
    temp6-productid = `HT-1000`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `SAP`.
    temp6-price = `956.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.3`.
    temp6-height = `0.03`.
    temp6-depth = `0.18`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 17`.
    temp6-productid = `HT-1001`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `Becker Berlin`.
    temp6-price = `1249.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.29`.
    temp6-height = `0.03`.
    temp6-depth = `0.17`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 18`.
    temp6-productid = `HT-1002`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `DelBont Industries`.
    temp6-price = `1570.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.28`.
    temp6-height = `0.03`.
    temp6-depth = `0.19`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Basic 19`.
    temp6-productid = `HT-1003`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `Talpa`.
    temp6-price = `1650.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.32`.
    temp6-height = `0.04`.
    temp6-depth = `0.21`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault`.
    temp6-productid = `HT-1007`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `Panorama Studios`.
    temp6-price = `299.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.32`.
    temp6-height = `0.03`.
    temp6-depth = `0.22`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Professional 15`.
    temp6-productid = `HT-1010`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `TECUM`.
    temp6-price = `1999.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.33`.
    temp6-height = `0.03`.
    temp6-depth = `0.2`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Professional 17`.
    temp6-productid = `HT-1011`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `Asia High tech`.
    temp6-price = `2299.0`.
    temp6-currencycode = `JPY`.
    temp6-width = `0.33`.
    temp6-height = `0.02`.
    temp6-depth = `0.23`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault Net`.
    temp6-productid = `HT-1020`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `Laurent`.
    temp6-price = `459.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.1`.
    temp6-height = `0.17`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO Vault SAT`.
    temp6-productid = `HT-1021`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `AVANTEL`.
    temp6-price = `149.0`.
    temp6-currencycode = `MXN`.
    temp6-width = `0.11`.
    temp6-height = `0.18`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Comfort Easy`.
    temp6-productid = `HT-1022`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `Telecomunicaciones Star`.
    temp6-price = `1679.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.84`.
    temp6-height = `0.14`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Comfort Senior`.
    temp6-productid = `HT-1023`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `Pear Computing Services`.
    temp6-price = `512.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.8`.
    temp6-height = `0.13`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-I`.
    temp6-productid = `HT-1030`.
    temp6-category = `Flat screens`.
    temp6-suppliername = `Alpine Systems`.
    temp6-price = `230.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.37`.
    temp6-height = `0.36`.
    temp6-depth = `0.12`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-II`.
    temp6-productid = `HT-1031`.
    temp6-category = `Flat screens`.
    temp6-suppliername = `New Line Design`.
    temp6-price = `285.0`.
    temp6-currencycode = `GBP`.
    temp6-width = `0.41`.
    temp6-height = `0.43`.
    temp6-depth = `0.19`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Screen E-III`.
    temp6-productid = `HT-1032`.
    temp6-category = `Flat screens`.
    temp6-suppliername = `HEPA Tec`.
    temp6-price = `345.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.41`.
    temp6-height = `0.43`.
    temp6-depth = `0.19`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Basic`.
    temp6-productid = `HT-1035`.
    temp6-category = `Flat screens`.
    temp6-suppliername = `Anav Ideon`.
    temp6-price = `399.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.39`.
    temp6-height = `0.41`.
    temp6-depth = `0.2`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Future`.
    temp6-productid = `HT-1036`.
    temp6-category = `Flat screens`.
    temp6-suppliername = `Robert Brown Entertainment`.
    temp6-price = `430.0`.
    temp6-currencycode = `CAD`.
    temp6-width = `0.45`.
    temp6-height = `0.46`.
    temp6-depth = `0.26`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat XL`.
    temp6-productid = `HT-1037`.
    temp6-category = `Flat screens`.
    temp6-suppliername = `Mexican Oil Trading Company`.
    temp6-price = `1230.0`.
    temp6-currencycode = `MXN`.
    temp6-width = `0.55`.
    temp6-height = `0.39`.
    temp6-depth = `0.22`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Professional Eco`.
    temp6-productid = `HT-1040`.
    temp6-category = `Laser printers`.
    temp6-suppliername = `Meliva`.
    temp6-price = `830.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.51`.
    temp6-height = `0.3`.
    temp6-depth = `0.46`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Basic`.
    temp6-productid = `HT-1041`.
    temp6-category = `Laser printers`.
    temp6-suppliername = `Compostela`.
    temp6-price = `490.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.48`.
    temp6-height = `0.26`.
    temp6-depth = `0.42`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Laser Allround`.
    temp6-productid = `HT-1042`.
    temp6-category = `Laser printers`.
    temp6-suppliername = `Pateu`.
    temp6-price = `349.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.53`.
    temp6-height = `0.65`.
    temp6-depth = `0.5`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Super Color`.
    temp6-productid = `HT-1050`.
    temp6-category = `Ink jet printers`.
    temp6-suppliername = `Russian Electronic Trading Company`.
    temp6-price = `139.0`.
    temp6-currencycode = `RUB`.
    temp6-width = `0.41`.
    temp6-height = `0.28`.
    temp6-depth = `0.41`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Mobile`.
    temp6-productid = `HT-1051`.
    temp6-category = `Ink jet printers`.
    temp6-suppliername = `Florida Holiday Company`.
    temp6-price = `99.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.46`.
    temp6-height = `0.25`.
    temp6-depth = `0.32`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ultra Jet Super Highspeed`.
    temp6-productid = `HT-1052`.
    temp6-category = `Ink jet printers`.
    temp6-suppliername = `Quimica Madrilenos`.
    temp6-price = `170.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.41`.
    temp6-height = `0.28`.
    temp6-depth = `0.41`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Multi Print`.
    temp6-productid = `HT-1055`.
    temp6-category = `Multifunction printers`.
    temp6-suppliername = `Getränkegroßhandel Janssen`.
    temp6-price = `99.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.55`.
    temp6-height = `0.29`.
    temp6-depth = `0.45`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Multi Color`.
    temp6-productid = `HT-1056`.
    temp6-category = `Multifunction printers`.
    temp6-suppliername = `JaTeCo`.
    temp6-price = `119.0`.
    temp6-currencycode = `JPY`.
    temp6-width = `0.51`.
    temp6-height = `0.22`.
    temp6-depth = `0.41`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cordless Mouse`.
    temp6-productid = `HT-1060`.
    temp6-category = `Mice`.
    temp6-suppliername = `Tessile Casa Di Roma`.
    temp6-price = `9.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.06`.
    temp6-height = `0.04`.
    temp6-depth = `0.15`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Speed Mouse`.
    temp6-productid = `HT-1061`.
    temp6-category = `Mice`.
    temp6-suppliername = `Vente Et Réparation de Ordinateur`.
    temp6-price = `7.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.07`.
    temp6-height = `0.03`.
    temp6-depth = `0.15`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Track Mouse`.
    temp6-productid = `HT-1062`.
    temp6-category = `Mice`.
    temp6-suppliername = `Developement Para O Governo`.
    temp6-price = `11.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.0`.
    temp6-height = `0.04`.
    temp6-depth = `0.01`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergonomic Keyboard`.
    temp6-productid = `HT-1063`.
    temp6-category = `Keyboards`.
    temp6-suppliername = `Brazil Technologies`.
    temp6-price = `14.0`.
    temp6-currencycode = `BRL`.
    temp6-width = `0.5`.
    temp6-height = `0.04`.
    temp6-depth = `0.21`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Internet Keyboard`.
    temp6-productid = `HT-1064`.
    temp6-category = `Keyboards`.
    temp6-suppliername = `C.R.T.U.`.
    temp6-price = `16.0`.
    temp6-currencycode = `CAD`.
    temp6-width = `0.52`.
    temp6-height = `0.03`.
    temp6-depth = `0.25`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Media Keyboard`.
    temp6-productid = `HT-1065`.
    temp6-category = `Keyboards`.
    temp6-suppliername = `Jologa`.
    temp6-price = `26.0`.
    temp6-currencycode = `CHF`.
    temp6-width = `0.51`.
    temp6-height = `0.04`.
    temp6-depth = `0.23`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Mousepad`.
    temp6-productid = `HT-1066`.
    temp6-category = `Mousepads`.
    temp6-suppliername = `Baleda`.
    temp6-price = `6.99`.
    temp6-currencycode = `USD`.
    temp6-width = `0.15`.
    temp6-height = `0.0`.
    temp6-depth = `0.06`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Ergo Mousepad`.
    temp6-productid = `HT-1067`.
    temp6-category = `Mousepads`.
    temp6-suppliername = `Angeré`.
    temp6-price = `8.99`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.15`.
    temp6-height = `0.0`.
    temp6-depth = `0.06`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Designer Mousepad`.
    temp6-productid = `HT-1068`.
    temp6-category = `Mousepads`.
    temp6-suppliername = `PC Gym Tec`.
    temp6-price = `12.99`.
    temp6-currencycode = `USD`.
    temp6-width = `0.24`.
    temp6-height = `0.01`.
    temp6-depth = `0.24`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Universal card reader`.
    temp6-productid = `HT-1069`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Japan Insurance Partner`.
    temp6-price = `14.0`.
    temp6-currencycode = `JPY`.
    temp6-width = `0.01`.
    temp6-height = `0.0`.
    temp6-depth = `0.01`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Proctra X`.
    temp6-productid = `HT-1070`.
    temp6-category = `Graphic cards`.
    temp6-suppliername = `Entertainment Argentinia`.
    temp6-price = `70.9`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.22`.
    temp6-height = `0.17`.
    temp6-depth = `0.35`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gladiator MX`.
    temp6-productid = `HT-1071`.
    temp6-category = `Graphic cards`.
    temp6-suppliername = `African Gold And Diamond Corporation`.
    temp6-price = `81.7`.
    temp6-currencycode = `ZAR`.
    temp6-width = `0.22`.
    temp6-height = `0.17`.
    temp6-depth = `0.35`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Hurricane GX`.
    temp6-productid = `HT-1072`.
    temp6-category = `Graphic cards`.
    temp6-suppliername = `PicoBit`.
    temp6-price = `101.2`.
    temp6-currencycode = `USD`.
    temp6-width = `0.22`.
    temp6-height = `0.17`.
    temp6-depth = `0.35`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Hurricane GX/LN`.
    temp6-productid = `HT-1073`.
    temp6-category = `Graphic cards`.
    temp6-suppliername = `Bionic Research Lab`.
    temp6-price = `139.99`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.22`.
    temp6-height = `0.17`.
    temp6-depth = `0.35`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Photo Scan`.
    temp6-productid = `HT-1080`.
    temp6-category = `Scanners`.
    temp6-suppliername = `Indian IT Trading Company`.
    temp6-price = `129.0`.
    temp6-currencycode = `INR`.
    temp6-width = `0.34`.
    temp6-height = `0.05`.
    temp6-depth = `0.48`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Scan`.
    temp6-productid = `HT-1081`.
    temp6-category = `Scanners`.
    temp6-suppliername = `Chemia A Technicznie Fabryka`.
    temp6-price = `89.0`.
    temp6-currencycode = `PLN`.
    temp6-width = `0.31`.
    temp6-height = `0.07`.
    temp6-depth = `0.43`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Jet Scan Professional`.
    temp6-productid = `HT-1082`.
    temp6-category = `Scanners`.
    temp6-suppliername = `South American IT Company`.
    temp6-price = `169.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.33`.
    temp6-height = `0.12`.
    temp6-depth = `0.41`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Jet Scan Professional`.
    temp6-productid = `HT-1083`.
    temp6-category = `Scanners`.
    temp6-suppliername = `Siwusha`.
    temp6-price = `189.0`.
    temp6-currencycode = `CNY`.
    temp6-width = `0.35`.
    temp6-height = `0.1`.
    temp6-depth = `0.4`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Copymaster`.
    temp6-productid = `HT-1085`.
    temp6-category = `Multifunction printers`.
    temp6-suppliername = `Danish Fish Trading Company`.
    temp6-price = `1499.0`.
    temp6-currencycode = `DKK`.
    temp6-width = `0.45`.
    temp6-height = `0.22`.
    temp6-depth = `0.42`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Surround Sound`.
    temp6-productid = `HT-1090`.
    temp6-category = `Speakers`.
    temp6-suppliername = `Sorali`.
    temp6-price = `39.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.12`.
    temp6-height = `0.16`.
    temp6-depth = `0.1`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Blaster Extreme`.
    temp6-productid = `HT-1091`.
    temp6-category = `Speakers`.
    temp6-suppliername = `SAP`.
    temp6-price = `26.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.13`.
    temp6-height = `0.18`.
    temp6-depth = `0.11`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Sound Booster`.
    temp6-productid = `HT-1092`.
    temp6-category = `Speakers`.
    temp6-suppliername = `Becker Berlin`.
    temp6-price = `45.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.12`.
    temp6-height = `0.18`.
    temp6-depth = `0.1`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound 5.1 Wireless`.
    temp6-productid = `HT-1095`.
    temp6-category = `Headsets`.
    temp6-suppliername = `PC Gym Tec`.
    temp6-price = `49.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.24`.
    temp6-height = `0.23`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound 5.1`.
    temp6-productid = `HT-1096`.
    temp6-category = `Headsets`.
    temp6-suppliername = `Japan Insurance Partner`.
    temp6-price = `39.0`.
    temp6-currencycode = `JPY`.
    temp6-width = `0.25`.
    temp6-height = `0.19`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Lovely Sound Stereo`.
    temp6-productid = `HT-1097`.
    temp6-category = `Headsets`.
    temp6-suppliername = `Entertainment Argentinia`.
    temp6-price = `29.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.21`.
    temp6-height = `0.2`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Office`.
    temp6-productid = `HT-1100`.
    temp6-category = `Software`.
    temp6-suppliername = `DelBont Industries`.
    temp6-price = `89.9`.
    temp6-currencycode = `USD`.
    temp6-width = `0.15`.
    temp6-height = `0.21`.
    temp6-depth = `0.07`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Design`.
    temp6-productid = `HT-1101`.
    temp6-category = `Software`.
    temp6-suppliername = `Talpa`.
    temp6-price = `79.9`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.14`.
    temp6-height = `0.24`.
    temp6-depth = `0.07`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Network`.
    temp6-productid = `HT-1102`.
    temp6-category = `Software`.
    temp6-suppliername = `Panorama Studios`.
    temp6-price = `69.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.16`.
    temp6-height = `0.27`.
    temp6-depth = `0.06`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Multimedia`.
    temp6-productid = `HT-1103`.
    temp6-category = `Software`.
    temp6-suppliername = `TECUM`.
    temp6-price = `77.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.11`.
    temp6-height = `0.22`.
    temp6-depth = `0.03`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Games`.
    temp6-productid = `HT-1104`.
    temp6-category = `Software`.
    temp6-suppliername = `Asia High tech`.
    temp6-price = `55.0`.
    temp6-currencycode = `JPY`.
    temp6-width = `0.1`.
    temp6-height = `0.3`.
    temp6-depth = `0.03`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Internet Antivirus`.
    temp6-productid = `HT-1105`.
    temp6-category = `Software`.
    temp6-suppliername = `Laurent`.
    temp6-price = `29.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.16`.
    temp6-height = `0.21`.
    temp6-depth = `0.04`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Firewall`.
    temp6-productid = `HT-1106`.
    temp6-category = `Software`.
    temp6-suppliername = `AVANTEL`.
    temp6-price = `34.0`.
    temp6-currencycode = `MXN`.
    temp6-width = `0.18`.
    temp6-height = `0.23`.
    temp6-depth = `0.04`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smart Money`.
    temp6-productid = `HT-1107`.
    temp6-category = `Software`.
    temp6-suppliername = `Telecomunicaciones Star`.
    temp6-price = `29.9`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.12`.
    temp6-height = `0.19`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `PC Lock`.
    temp6-productid = `HT-1110`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Pear Computing Services`.
    temp6-price = `8.9`.
    temp6-currencycode = `USD`.
    temp6-width = `0.2`.
    temp6-height = `0.04`.
    temp6-depth = `0.08`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Notebook Lock`.
    temp6-productid = `HT-1111`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Alpine Systems`.
    temp6-price = `6.9`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.31`.
    temp6-height = `0.07`.
    temp6-depth = `0.09`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Web cam reality`.
    temp6-productid = `HT-1112`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `New Line Design`.
    temp6-price = `39.0`.
    temp6-currencycode = `GBP`.
    temp6-width = `0.09`.
    temp6-height = `0.01`.
    temp6-depth = `0.08`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Screen clean`.
    temp6-productid = `HT-1113`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `HEPA Tec`.
    temp6-price = `2.3`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.02`.
    temp6-height = `0.0`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Fabric bag professional`.
    temp6-productid = `HT-1114`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Anav Ideon`.
    temp6-price = `31.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.42`.
    temp6-height = `0.07`.
    temp6-depth = `0.32`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router`.
    temp6-productid = `HT-1115`.
    temp6-category = `Telecommunication`.
    temp6-suppliername = `Robert Brown Entertainment`.
    temp6-price = `49.0`.
    temp6-currencycode = `CAD`.
    temp6-width = `0.19`.
    temp6-height = `0.05`.
    temp6-depth = `0.18`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router / Repeater`.
    temp6-productid = `HT-1116`.
    temp6-category = `Telecommunication`.
    temp6-suppliername = `Mexican Oil Trading Company`.
    temp6-price = `59.0`.
    temp6-currencycode = `MXN`.
    temp6-width = `0.19`.
    temp6-height = `0.05`.
    temp6-depth = `0.18`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Wireless DSL Router / Repeater and Print Server`.
    temp6-productid = `HT-1117`.
    temp6-category = `Telecommunication`.
    temp6-suppliername = `Meliva`.
    temp6-price = `69.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.19`.
    temp6-height = `0.05`.
    temp6-depth = `0.18`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `USB Stick`.
    temp6-productid = `HT-1118`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Compostela`.
    temp6-price = `35.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.02`.
    temp6-height = `0.01`.
    temp6-depth = `0.09`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Travel Adapter`.
    temp6-productid = `HT-1119`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Pear Computing Services`.
    temp6-price = `79.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.02`.
    temp6-height = `0.04`.
    temp6-depth = `0.03`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Cordless Bluetooth Keyboard, english international`.
    temp6-productid = `HT-1120`.
    temp6-category = `Keyboards`.
    temp6-suppliername = `Pateu`.
    temp6-price = `29.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.51`.
    temp6-height = `0.04`.
    temp6-depth = `0.23`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat XXL`.
    temp6-productid = `HT-1137`.
    temp6-category = `Flat screens`.
    temp6-suppliername = `Russian Electronic Trading Company`.
    temp6-price = `1430.0`.
    temp6-currencycode = `RUB`.
    temp6-width = `0.54`.
    temp6-height = `0.38`.
    temp6-depth = `0.22`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Pocket Mouse`.
    temp6-productid = `HT-1138`.
    temp6-category = `Mice`.
    temp6-suppliername = `Florida Holiday Company`.
    temp6-price = `23.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.0`.
    temp6-height = `0.01`.
    temp6-depth = `0.01`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `PC Power Station`.
    temp6-productid = `HT-1210`.
    temp6-category = `PCs`.
    temp6-suppliername = `Quimica Madrilenos`.
    temp6-price = `2399.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.28`.
    temp6-height = `0.43`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Basic`.
    temp6-productid = `HT-1500`.
    temp6-category = `Servers`.
    temp6-suppliername = `Getränkegroßhandel Janssen`.
    temp6-price = `5000.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.34`.
    temp6-height = `0.23`.
    temp6-depth = `0.35`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Professional`.
    temp6-productid = `HT-1501`.
    temp6-category = `Servers`.
    temp6-suppliername = `JaTeCo`.
    temp6-price = `15000.0`.
    temp6-currencycode = `JPY`.
    temp6-width = `0.29`.
    temp6-height = `0.27`.
    temp6-depth = `0.3`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Server Power Pro`.
    temp6-productid = `HT-1502`.
    temp6-category = `Servers`.
    temp6-suppliername = `Tessile Casa Di Roma`.
    temp6-price = `25000.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.22`.
    temp6-height = `0.37`.
    temp6-depth = `0.27`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Family PC Basic`.
    temp6-productid = `HT-1600`.
    temp6-category = `PCs`.
    temp6-suppliername = `Telecomunicaciones Star`.
    temp6-price = `600.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.21`.
    temp6-height = `0.38`.
    temp6-depth = `0.29`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Family PC Pro`.
    temp6-productid = `HT-1601`.
    temp6-category = `PCs`.
    temp6-suppliername = `AVANTEL`.
    temp6-price = `900.0`.
    temp6-currencycode = `MXN`.
    temp6-width = `0.25`.
    temp6-height = `0.4`.
    temp6-depth = `0.32`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gaming Monster`.
    temp6-productid = `HT-1602`.
    temp6-category = `PCs`.
    temp6-suppliername = `Laurent`.
    temp6-price = `1200.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.27`.
    temp6-height = `0.47`.
    temp6-depth = `0.34`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Gaming Monster Pro`.
    temp6-productid = `HT-1603`.
    temp6-category = `PCs`.
    temp6-suppliername = `Asia High tech`.
    temp6-price = `1700.0`.
    temp6-currencycode = `JPY`.
    temp6-width = `0.27`.
    temp6-height = `0.42`.
    temp6-depth = `0.28`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `7" Widescreen Portable DVD Player w MP3`.
    temp6-productid = `HT-2000`.
    temp6-category = `Portable Players`.
    temp6-suppliername = `TECUM`.
    temp6-price = `249.99`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.21`.
    temp6-height = `0.28`.
    temp6-depth = `0.19`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `10" Portable DVD player`.
    temp6-productid = `HT-2001`.
    temp6-category = `Portable Players`.
    temp6-suppliername = `Panorama Studios`.
    temp6-price = `449.99`.
    temp6-currencycode = `USD`.
    temp6-width = `0.24`.
    temp6-height = `0.29`.
    temp6-depth = `0.2`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Portable DVD Player with 9" LCD Monitor`.
    temp6-productid = `HT-2002`.
    temp6-category = `Portable Players`.
    temp6-suppliername = `Sorali`.
    temp6-price = `853.99`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.21`.
    temp6-height = `0.14`.
    temp6-depth = `0.17`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `CD/DVD case: 264 sleeves`.
    temp6-productid = `HT-2025`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Talpa`.
    temp6-price = `44.99`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.13`.
    temp6-height = `0.2`.
    temp6-depth = `0.13`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Audio/Video Cable Kit - 4m`.
    temp6-productid = `HT-2026`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `DelBont Industries`.
    temp6-price = `29.99`.
    temp6-currencycode = `USD`.
    temp6-width = `0.21`.
    temp6-height = `0.13`.
    temp6-depth = `0.1`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Removable CD/DVD Laser Labels`.
    temp6-productid = `HT-2027`.
    temp6-category = `Computer system accessories`.
    temp6-suppliername = `Becker Berlin`.
    temp6-price = `8.99`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.06`.
    temp6-height = `0.02`.
    temp6-depth = `0.02`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-1`.
    temp6-productid = `HT-6100`.
    temp6-category = `Beamers`.
    temp6-suppliername = `SAP`.
    temp6-price = `469.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.3`.
    temp6-height = `0.23`.
    temp6-depth = `0.23`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-2`.
    temp6-productid = `HT-6101`.
    temp6-category = `Beamers`.
    temp6-suppliername = `Danish Fish Trading Company`.
    temp6-price = `679.0`.
    temp6-currencycode = `DKK`.
    temp6-width = `0.3`.
    temp6-height = `0.23`.
    temp6-depth = `0.23`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Beam Breaker B-3`.
    temp6-productid = `HT-6102`.
    temp6-category = `Beamers`.
    temp6-suppliername = `Siwusha`.
    temp6-price = `889.0`.
    temp6-currencycode = `CNY`.
    temp6-width = `0.3`.
    temp6-height = `0.23`.
    temp6-depth = `0.23`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Play Movie`.
    temp6-productid = `HT-6110`.
    temp6-category = `Portable Players`.
    temp6-suppliername = `South American IT Company`.
    temp6-price = `130.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.37`.
    temp6-height = `0.06`.
    temp6-depth = `0.24`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Record Movie`.
    temp6-productid = `HT-6111`.
    temp6-category = `Portable Players`.
    temp6-suppliername = `Chemia A Technicznie Fabryka`.
    temp6-price = `288.0`.
    temp6-currencycode = `PLN`.
    temp6-width = `0.38`.
    temp6-height = `0.06`.
    temp6-depth = `0.26`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelo MusickStick`.
    temp6-productid = `HT-6120`.
    temp6-category = `MP3-Players`.
    temp6-suppliername = `Indian IT Trading Company`.
    temp6-price = `45.0`.
    temp6-currencycode = `INR`.
    temp6-width = `0.02`.
    temp6-height = `0.01`.
    temp6-depth = `0.06`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelo Jog-Mate`.
    temp6-productid = `HT-6121`.
    temp6-category = `MP3-Players`.
    temp6-suppliername = `Bionic Research Lab`.
    temp6-price = `63.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.05`.
    temp6-height = `0.09`.
    temp6-depth = `0.08`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Pro Player 40`.
    temp6-productid = `HT-6122`.
    temp6-category = `MP3-Players`.
    temp6-suppliername = `PicoBit`.
    temp6-price = `167.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.05`.
    temp6-height = `0.09`.
    temp6-depth = `0.08`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Power Pro Player 80`.
    temp6-productid = `HT-6123`.
    temp6-category = `MP3-Players`.
    temp6-suppliername = `African Gold And Diamond Corporation`.
    temp6-price = `299.0`.
    temp6-currencycode = `ZAR`.
    temp6-width = `0.04`.
    temp6-height = `0.01`.
    temp6-depth = `0.06`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD32`.
    temp6-productid = `HT-6130`.
    temp6-category = `TV flat screens`.
    temp6-suppliername = `Vente Et Réparation de Ordinateur`.
    temp6-price = `1459.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.78`.
    temp6-height = `0.55`.
    temp6-depth = `0.22`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD37`.
    temp6-productid = `HT-6131`.
    temp6-category = `TV flat screens`.
    temp6-suppliername = `Developement Para O Governo`.
    temp6-price = `1199.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.99`.
    temp6-height = `0.61`.
    temp6-depth = `0.26`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Flat Watch HD41`.
    temp6-productid = `HT-6132`.
    temp6-category = `TV flat screens`.
    temp6-suppliername = `Brazil Technologies`.
    temp6-price = `899.0`.
    temp6-currencycode = `BRL`.
    temp6-width = `1.28`.
    temp6-height = `0.79`.
    temp6-depth = `0.23`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Copperberry`.
    temp6-productid = `HT-7000`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `Angeré`.
    temp6-price = `549.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.08`.
    temp6-height = `0.12`.
    temp6-depth = `0.13`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Silverberry`.
    temp6-productid = `HT-7010`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `Baleda`.
    temp6-price = `549.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.08`.
    temp6-height = `0.12`.
    temp6-depth = `0.13`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Goldberry`.
    temp6-productid = `HT-7020`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `Jologa`.
    temp6-price = `549.0`.
    temp6-currencycode = `CHF`.
    temp6-width = `0.08`.
    temp6-height = `0.12`.
    temp6-depth = `0.13`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Platinberry`.
    temp6-productid = `HT-7030`.
    temp6-category = `PDAs/Organizers`.
    temp6-suppliername = `C.R.T.U.`.
    temp6-price = `549.0`.
    temp6-currencycode = `CAD`.
    temp6-width = `0.08`.
    temp6-height = `0.12`.
    temp6-depth = `0.13`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I4000`.
    temp6-productid = `HT-8000`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `Alpine Systems`.
    temp6-price = `799.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.31`.
    temp6-height = `0.03`.
    temp6-depth = `0.19`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I6300c`.
    temp6-productid = `HT-8001`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `New Line Design`.
    temp6-price = `999.0`.
    temp6-currencycode = `GBP`.
    temp6-width = `0.32`.
    temp6-height = `0.03`.
    temp6-depth = `0.2`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I9100`.
    temp6-productid = `HT-8002`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `HEPA Tec`.
    temp6-price = `1199.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.38`.
    temp6-height = `0.04`.
    temp6-depth = `0.21`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `ITelO FlexTop I9800`.
    temp6-productid = `HT-8003`.
    temp6-category = `Notebooks`.
    temp6-suppliername = `Anav Ideon`.
    temp6-price = `1388.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.48`.
    temp6-height = `0.05`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Leather Case`.
    temp6-productid = `HT-9991`.
    temp6-category = `Accessories`.
    temp6-suppliername = `JaTeCo`.
    temp6-price = `25.0`.
    temp6-currencycode = `JPY`.
    temp6-width = `0.48`.
    temp6-height = `0.05`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Alpha`.
    temp6-productid = `HT-9992`.
    temp6-category = `Smartphones`.
    temp6-suppliername = `Getränkegroßhandel Janssen`.
    temp6-price = `599.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.48`.
    temp6-height = `0.05`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Mini Tablet`.
    temp6-productid = `HT-9993`.
    temp6-category = `Tablets`.
    temp6-suppliername = `Quimica Madrilenos`.
    temp6-price = `833.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.48`.
    temp6-height = `0.05`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Camcorder View`.
    temp6-productid = `HT-9994`.
    temp6-category = `Camcorders`.
    temp6-suppliername = `Florida Holiday Company`.
    temp6-price = `1388.0`.
    temp6-currencycode = `USD`.
    temp6-width = `0.48`.
    temp6-height = `0.27`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Cover`.
    temp6-productid = `HT-9995`.
    temp6-category = `Accessories`.
    temp6-suppliername = `Russian Electronic Trading Company`.
    temp6-price = `15.0`.
    temp6-currencycode = `RUB`.
    temp6-width = `0.48`.
    temp6-height = `0.05`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Tablet Pouch`.
    temp6-productid = `HT-9996`.
    temp6-category = `Accessories`.
    temp6-suppliername = `Pateu`.
    temp6-price = `20.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.25`.
    temp6-height = `0.05`.
    temp6-depth = `0.4`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `e-Book Reader ReadMe`.
    temp6-productid = `HT-9997`.
    temp6-category = `Tablets`.
    temp6-suppliername = `Compostela`.
    temp6-price = `633.0`.
    temp6-currencycode = `ARS`.
    temp6-width = `0.48`.
    temp6-height = `0.05`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Smartphone Beta`.
    temp6-productid = `HT-9998`.
    temp6-category = `Smartphones`.
    temp6-suppliername = `Meliva`.
    temp6-price = `699.0`.
    temp6-currencycode = `EUR`.
    temp6-width = `0.48`.
    temp6-height = `0.05`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    temp6-name = `Maxi Tablet`.
    temp6-productid = `HT-9999`.
    temp6-category = `Tablets`.
    temp6-suppliername = `Mexican Oil Trading Company`.
    temp6-price = `749.0`.
    temp6-currencycode = `MXN`.
    temp6-width = `0.48`.
    temp6-height = `0.05`.
    temp6-depth = `0.31`.
    temp6-dimunit = `M`.
    INSERT temp6 INTO TABLE temp5.
    t_products = temp5.

  ENDMETHOD.

ENDCLASS.
