" @keywords table sap.ui.table multiselectionplugin column
" @summary Example showing the behavior of MultiSelectionPlugin
CLASS z2ui5_cl_smpc_app_356 DEFINITION PUBLIC.

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
      BEGIN OF ty_s_key,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_key.
    DATA t_products       TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
    DATA t_selectionmodes TYPE STANDARD TABLE OF ty_s_key WITH DEFAULT KEY.

    " the original's `config>` model, folded onto the one default model. The
    " Input carries the limit as text because sap.m.Input.value is a string
    " property while the plugin's limit is an integer - the original bridges
    " that with a typed binding, the port parses it in onLimitChange's place
    DATA limit                TYPE i.
    DATA limit_text           TYPE string.
    DATA show_header_selector TYPE abap_bool.
    DATA selection_mode       TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_356 IMPLEMENTATION.

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

    " the MultiSelectionPlugin demo. The selection mode Select, the limit Input
    " and the header-selector toggle are two-way bound and the plugin binds the
    " same fields, so the three config controls drive it directly; only the
    " limit's parse and the two selection messages need the backend.
    
    CLEAR temp1.
    INSERT `${$parameters>/limitReached}` INTO TABLE temp1.
    INSERT `${$source>}.getSelectedIndices().length` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`         v = `sap.ui.table`
        )->a( n = `xmlns:plugins` v = `sap.ui.table.plugins`
        )->a( n = `xmlns:mvc`     v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`       v = `sap.ui.unified`
        )->a( n = `xmlns:c`       v = `sap.ui.core`
        )->a( n = `xmlns:m`       v = `sap.m`
        )->a( n = `height`        v = `100%`

        )->ele( n = `Page` ns = `m`
            )->a( n = `showHeader`      v = `false`
            )->a( n = `enableScrolling` v = `false`
            )->a( n = `class`           v = `sapUiContentPadding`

            )->ele( n = `content` ns = `m`
                )->ele( `Table`
                    )->a( n = `id`                  v = `table`
                    )->a( n = `rows`                v = client->_bind( t_products )
                    )->a( n = `threshold`           v = `15`
                    )->a( n = `enableBusyIndicator` v = `true`
                    )->a( n = `ariaLabelledBy`      v = `title`

                    )->ele( `dependents`
                        )->tag( n = `MultiSelectionPlugin` ns = `plugins`
                            )->a( n = `limit`              v = client->_bind( limit )
                            )->a( n = `enableNotification` v = `true`
                            )->a( n = `showHeaderSelector` v = client->_bind( show_header_selector )
                            )->a( n = `selectionMode`      v = client->_bind( selection_mode )
                            )->a( n = `selectionChange`    v = client->_event( val   = `SELECTION_CHANGE`
                                                                               t_arg = temp1 )

                    )->end(
                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `style` v = `Clear`

                            )->tag( n = `Title` ns = `m`
                                )->a( n = `id`   v = `title`
                                )->a( n = `text` v = `Products`

                            )->tag( n = `ToolbarSpacer` ns = `m`

                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text`     v = `Selection Mode`
                                )->a( n = `labelFor` v = `select1`

                            )->ele( n = `Select` ns = `m`
                                )->a( n = `id`          v = `select1`
                                )->a( n = `width`       v = `20%`
                                )->a( n = `items`       v = client->_bind( t_selectionmodes )
                                )->a( n = `selectedKey` v = client->_bind( selection_mode )

                                )->tag( n = `Item` ns = `c`
                                    )->a( n = `key`  v = `{KEY}`
                                    )->a( n = `text` v = `{TEXT}`

                            )->end(
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text`     v = `Limit`
                                )->a( n = `labelFor` v = `input1`

                            )->tag( n = `Input` ns = `m`
                                )->a( n = `id`      v = `input1`
                                )->a( n = `value`   v = client->_bind( limit_text )
                                )->a( n = `change`  v = client->_event( `LIMIT_CHANGE` )
                                )->a( n = `width`   v = `10%`
                                )->a( n = `tooltip` v = `limit`

                            )->tag( n = `ToolbarSeparator` ns = `m`

                            )->tag( n = `ToggleButton` ns = `m`
                                )->a( n = `icon`    v = `sap-icon://complete`
                                )->a( n = `tooltip` v = `Show header selector`
                                )->a( n = `pressed` v = client->_bind( show_header_selector )

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
          DATA temp3 TYPE i.
          DATA temp4 TYPE string.
        DATA lv_limit_reached TYPE string.
        DATA temp5 TYPE i.
        DATA lv_count LIKE temp5.

    CASE client->get_event( ).

      WHEN `LIMIT_CHANGE`.
        " onLimitChange: only a positive integer is accepted, 0 disables the
        " limit, anything else snaps the Input back to the current value
        IF limit_text CO ` 0123456789` AND limit_text IS NOT INITIAL.
          
          temp3 = limit_text.
          limit = temp3.
          
          IF limit = 0.
            temp4 = `Limit disabled`.
          ELSE.
            temp4 = |Limit set to { limit }|.
          ENDIF.
          client->message_toast_display( temp4 ).
        ELSE.
          limit_text = |{ limit }|.
          client->message_toast_display( |The Limit accepts positive integer values. To disable it set its value to 0. \nCurrent limit is { limit }| ).
        ENDIF.

      WHEN `SELECTION_CHANGE`.
        " onSelectionChange: how many rows are selected, and whether the last
        " range had to be cut down to the limit
        
        lv_limit_reached = client->get_event_arg( ).
        
        temp5 = client->get_event_arg( 2 ).
        
        lv_count = temp5.
        IF lv_count = 0.
          client->message_toast_display( `Selection cleared.` ).
        ELSEIF lv_limit_reached = abap_true.
          client->message_toast_display( |{ lv_count } row(s) selected. The recently selected range was limited to { limit } rows!| ).
        ELSE.
          client->message_toast_display( |{ lv_count } row(s) selected.| ).
        ENDIF.

    ENDCASE.


  ENDMETHOD.


  METHOD model_init.
    DATA temp6 LIKE t_selectionmodes.
    DATA temp7 LIKE LINE OF temp6.
    DATA temp8 LIKE t_products.
    DATA temp9 LIKE LINE OF temp8.

    " the `config>` model defaults the controller sets
    limit                = 20.
    limit_text           = `20`.
    show_header_selector = abap_true.
    selection_mode       = `MultiToggle`.

    " the SelectionMode item set the controller builds from the sap.ui.table
    " enum, in Object.keys order, with Multi skipped as there. The enum has
    " exactly MultiToggle / Multi / Single / None - until 2026-08-21 this list
    " carried a fourth entry `All`, which is not a member at all: it is bound
    " straight onto the plugin's selectionMode, typed sap.ui.table.SelectionMode,
    " so picking it reached ManagedObject.validateProperty and threw.
    
    CLEAR temp6.
    
    temp7-key = `MultiToggle`.
    temp7-text = `MultiToggle`.
    INSERT temp7 INTO TABLE temp6.
    temp7-key = `Single`.
    temp7-text = `Single`.
    INSERT temp7 INTO TABLE temp6.
    temp7-key = `None`.
    temp7-text = `None`.
    INSERT temp7 INTO TABLE temp6.
    t_selectionmodes = temp6.

    " the OData ProductSet the sample serves from a MockServer, inlined with
    " the columns the six table columns bind - all 115 rows of ProductSet.json
    
    CLEAR temp8.
    
    temp9-name = `Flyer`.
    temp9-productid = `AD-1000`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Robert Brown Entertainment`.
    temp9-price = `0.0`.
    temp9-currencycode = `CAD`.
    temp9-width = `0.46`.
    temp9-height = `0.03`.
    temp9-depth = `0.3`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Notebook Basic 15`.
    temp9-productid = `HT-1000`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `SAP`.
    temp9-price = `956.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.3`.
    temp9-height = `0.03`.
    temp9-depth = `0.18`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Notebook Basic 17`.
    temp9-productid = `HT-1001`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `Becker Berlin`.
    temp9-price = `1249.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.29`.
    temp9-height = `0.03`.
    temp9-depth = `0.17`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Notebook Basic 18`.
    temp9-productid = `HT-1002`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `DelBont Industries`.
    temp9-price = `1570.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.28`.
    temp9-height = `0.03`.
    temp9-depth = `0.19`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Notebook Basic 19`.
    temp9-productid = `HT-1003`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `Talpa`.
    temp9-price = `1650.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.32`.
    temp9-height = `0.04`.
    temp9-depth = `0.21`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelO Vault`.
    temp9-productid = `HT-1007`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `Panorama Studios`.
    temp9-price = `299.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.32`.
    temp9-height = `0.03`.
    temp9-depth = `0.22`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Notebook Professional 15`.
    temp9-productid = `HT-1010`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `TECUM`.
    temp9-price = `1999.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.33`.
    temp9-height = `0.03`.
    temp9-depth = `0.2`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Notebook Professional 17`.
    temp9-productid = `HT-1011`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `Asia High tech`.
    temp9-price = `2299.0`.
    temp9-currencycode = `JPY`.
    temp9-width = `0.33`.
    temp9-height = `0.02`.
    temp9-depth = `0.23`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelO Vault Net`.
    temp9-productid = `HT-1020`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `Laurent`.
    temp9-price = `459.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.1`.
    temp9-height = `0.17`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelO Vault SAT`.
    temp9-productid = `HT-1021`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `AVANTEL`.
    temp9-price = `149.0`.
    temp9-currencycode = `MXN`.
    temp9-width = `0.11`.
    temp9-height = `0.18`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Comfort Easy`.
    temp9-productid = `HT-1022`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `Telecomunicaciones Star`.
    temp9-price = `1679.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.84`.
    temp9-height = `0.14`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Comfort Senior`.
    temp9-productid = `HT-1023`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `Pear Computing Services`.
    temp9-price = `512.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.8`.
    temp9-height = `0.13`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ergo Screen E-I`.
    temp9-productid = `HT-1030`.
    temp9-category = `Flat screens`.
    temp9-suppliername = `Alpine Systems`.
    temp9-price = `230.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.37`.
    temp9-height = `0.36`.
    temp9-depth = `0.12`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ergo Screen E-II`.
    temp9-productid = `HT-1031`.
    temp9-category = `Flat screens`.
    temp9-suppliername = `New Line Design`.
    temp9-price = `285.0`.
    temp9-currencycode = `GBP`.
    temp9-width = `0.41`.
    temp9-height = `0.43`.
    temp9-depth = `0.19`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ergo Screen E-III`.
    temp9-productid = `HT-1032`.
    temp9-category = `Flat screens`.
    temp9-suppliername = `HEPA Tec`.
    temp9-price = `345.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.41`.
    temp9-height = `0.43`.
    temp9-depth = `0.19`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Flat Basic`.
    temp9-productid = `HT-1035`.
    temp9-category = `Flat screens`.
    temp9-suppliername = `Anav Ideon`.
    temp9-price = `399.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.39`.
    temp9-height = `0.41`.
    temp9-depth = `0.2`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Flat Future`.
    temp9-productid = `HT-1036`.
    temp9-category = `Flat screens`.
    temp9-suppliername = `Robert Brown Entertainment`.
    temp9-price = `430.0`.
    temp9-currencycode = `CAD`.
    temp9-width = `0.45`.
    temp9-height = `0.46`.
    temp9-depth = `0.26`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Flat XL`.
    temp9-productid = `HT-1037`.
    temp9-category = `Flat screens`.
    temp9-suppliername = `Mexican Oil Trading Company`.
    temp9-price = `1230.0`.
    temp9-currencycode = `MXN`.
    temp9-width = `0.55`.
    temp9-height = `0.39`.
    temp9-depth = `0.22`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Laser Professional Eco`.
    temp9-productid = `HT-1040`.
    temp9-category = `Laser printers`.
    temp9-suppliername = `Meliva`.
    temp9-price = `830.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.51`.
    temp9-height = `0.3`.
    temp9-depth = `0.46`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Laser Basic`.
    temp9-productid = `HT-1041`.
    temp9-category = `Laser printers`.
    temp9-suppliername = `Compostela`.
    temp9-price = `490.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.48`.
    temp9-height = `0.26`.
    temp9-depth = `0.42`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Laser Allround`.
    temp9-productid = `HT-1042`.
    temp9-category = `Laser printers`.
    temp9-suppliername = `Pateu`.
    temp9-price = `349.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.53`.
    temp9-height = `0.65`.
    temp9-depth = `0.5`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ultra Jet Super Color`.
    temp9-productid = `HT-1050`.
    temp9-category = `Ink jet printers`.
    temp9-suppliername = `Russian Electronic Trading Company`.
    temp9-price = `139.0`.
    temp9-currencycode = `RUB`.
    temp9-width = `0.41`.
    temp9-height = `0.28`.
    temp9-depth = `0.41`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ultra Jet Mobile`.
    temp9-productid = `HT-1051`.
    temp9-category = `Ink jet printers`.
    temp9-suppliername = `Florida Holiday Company`.
    temp9-price = `99.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.46`.
    temp9-height = `0.25`.
    temp9-depth = `0.32`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ultra Jet Super Highspeed`.
    temp9-productid = `HT-1052`.
    temp9-category = `Ink jet printers`.
    temp9-suppliername = `Quimica Madrilenos`.
    temp9-price = `170.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.41`.
    temp9-height = `0.28`.
    temp9-depth = `0.41`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Multi Print`.
    temp9-productid = `HT-1055`.
    temp9-category = `Multifunction printers`.
    temp9-suppliername = `Getränkegroßhandel Janssen`.
    temp9-price = `99.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.55`.
    temp9-height = `0.29`.
    temp9-depth = `0.45`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Multi Color`.
    temp9-productid = `HT-1056`.
    temp9-category = `Multifunction printers`.
    temp9-suppliername = `JaTeCo`.
    temp9-price = `119.0`.
    temp9-currencycode = `JPY`.
    temp9-width = `0.51`.
    temp9-height = `0.22`.
    temp9-depth = `0.41`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Cordless Mouse`.
    temp9-productid = `HT-1060`.
    temp9-category = `Mice`.
    temp9-suppliername = `Tessile Casa Di Roma`.
    temp9-price = `9.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.06`.
    temp9-height = `0.04`.
    temp9-depth = `0.15`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Speed Mouse`.
    temp9-productid = `HT-1061`.
    temp9-category = `Mice`.
    temp9-suppliername = `Vente Et Réparation de Ordinateur`.
    temp9-price = `7.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.07`.
    temp9-height = `0.03`.
    temp9-depth = `0.15`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Track Mouse`.
    temp9-productid = `HT-1062`.
    temp9-category = `Mice`.
    temp9-suppliername = `Developement Para O Governo`.
    temp9-price = `11.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.0`.
    temp9-height = `0.04`.
    temp9-depth = `0.01`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ergonomic Keyboard`.
    temp9-productid = `HT-1063`.
    temp9-category = `Keyboards`.
    temp9-suppliername = `Brazil Technologies`.
    temp9-price = `14.0`.
    temp9-currencycode = `BRL`.
    temp9-width = `0.5`.
    temp9-height = `0.04`.
    temp9-depth = `0.21`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Internet Keyboard`.
    temp9-productid = `HT-1064`.
    temp9-category = `Keyboards`.
    temp9-suppliername = `C.R.T.U.`.
    temp9-price = `16.0`.
    temp9-currencycode = `CAD`.
    temp9-width = `0.52`.
    temp9-height = `0.03`.
    temp9-depth = `0.25`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Media Keyboard`.
    temp9-productid = `HT-1065`.
    temp9-category = `Keyboards`.
    temp9-suppliername = `Jologa`.
    temp9-price = `26.0`.
    temp9-currencycode = `CHF`.
    temp9-width = `0.51`.
    temp9-height = `0.04`.
    temp9-depth = `0.23`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Mousepad`.
    temp9-productid = `HT-1066`.
    temp9-category = `Mousepads`.
    temp9-suppliername = `Baleda`.
    temp9-price = `6.99`.
    temp9-currencycode = `USD`.
    temp9-width = `0.15`.
    temp9-height = `0.0`.
    temp9-depth = `0.06`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Ergo Mousepad`.
    temp9-productid = `HT-1067`.
    temp9-category = `Mousepads`.
    temp9-suppliername = `Angeré`.
    temp9-price = `8.99`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.15`.
    temp9-height = `0.0`.
    temp9-depth = `0.06`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Designer Mousepad`.
    temp9-productid = `HT-1068`.
    temp9-category = `Mousepads`.
    temp9-suppliername = `PC Gym Tec`.
    temp9-price = `12.99`.
    temp9-currencycode = `USD`.
    temp9-width = `0.24`.
    temp9-height = `0.01`.
    temp9-depth = `0.24`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Universal card reader`.
    temp9-productid = `HT-1069`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Japan Insurance Partner`.
    temp9-price = `14.0`.
    temp9-currencycode = `JPY`.
    temp9-width = `0.01`.
    temp9-height = `0.0`.
    temp9-depth = `0.01`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Proctra X`.
    temp9-productid = `HT-1070`.
    temp9-category = `Graphic cards`.
    temp9-suppliername = `Entertainment Argentinia`.
    temp9-price = `70.9`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.22`.
    temp9-height = `0.17`.
    temp9-depth = `0.35`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Gladiator MX`.
    temp9-productid = `HT-1071`.
    temp9-category = `Graphic cards`.
    temp9-suppliername = `African Gold And Diamond Corporation`.
    temp9-price = `81.7`.
    temp9-currencycode = `ZAR`.
    temp9-width = `0.22`.
    temp9-height = `0.17`.
    temp9-depth = `0.35`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Hurricane GX`.
    temp9-productid = `HT-1072`.
    temp9-category = `Graphic cards`.
    temp9-suppliername = `PicoBit`.
    temp9-price = `101.2`.
    temp9-currencycode = `USD`.
    temp9-width = `0.22`.
    temp9-height = `0.17`.
    temp9-depth = `0.35`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Hurricane GX/LN`.
    temp9-productid = `HT-1073`.
    temp9-category = `Graphic cards`.
    temp9-suppliername = `Bionic Research Lab`.
    temp9-price = `139.99`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.22`.
    temp9-height = `0.17`.
    temp9-depth = `0.35`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Photo Scan`.
    temp9-productid = `HT-1080`.
    temp9-category = `Scanners`.
    temp9-suppliername = `Indian IT Trading Company`.
    temp9-price = `129.0`.
    temp9-currencycode = `INR`.
    temp9-width = `0.34`.
    temp9-height = `0.05`.
    temp9-depth = `0.48`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Power Scan`.
    temp9-productid = `HT-1081`.
    temp9-category = `Scanners`.
    temp9-suppliername = `Chemia A Technicznie Fabryka`.
    temp9-price = `89.0`.
    temp9-currencycode = `PLN`.
    temp9-width = `0.31`.
    temp9-height = `0.07`.
    temp9-depth = `0.43`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Jet Scan Professional`.
    temp9-productid = `HT-1082`.
    temp9-category = `Scanners`.
    temp9-suppliername = `South American IT Company`.
    temp9-price = `169.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.33`.
    temp9-height = `0.12`.
    temp9-depth = `0.41`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Jet Scan Professional`.
    temp9-productid = `HT-1083`.
    temp9-category = `Scanners`.
    temp9-suppliername = `Siwusha`.
    temp9-price = `189.0`.
    temp9-currencycode = `CNY`.
    temp9-width = `0.35`.
    temp9-height = `0.1`.
    temp9-depth = `0.4`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Copymaster`.
    temp9-productid = `HT-1085`.
    temp9-category = `Multifunction printers`.
    temp9-suppliername = `Danish Fish Trading Company`.
    temp9-price = `1499.0`.
    temp9-currencycode = `DKK`.
    temp9-width = `0.45`.
    temp9-height = `0.22`.
    temp9-depth = `0.42`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Surround Sound`.
    temp9-productid = `HT-1090`.
    temp9-category = `Speakers`.
    temp9-suppliername = `Sorali`.
    temp9-price = `39.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.12`.
    temp9-height = `0.16`.
    temp9-depth = `0.1`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Blaster Extreme`.
    temp9-productid = `HT-1091`.
    temp9-category = `Speakers`.
    temp9-suppliername = `SAP`.
    temp9-price = `26.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.13`.
    temp9-height = `0.18`.
    temp9-depth = `0.11`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Sound Booster`.
    temp9-productid = `HT-1092`.
    temp9-category = `Speakers`.
    temp9-suppliername = `Becker Berlin`.
    temp9-price = `45.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.12`.
    temp9-height = `0.18`.
    temp9-depth = `0.1`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Lovely Sound 5.1 Wireless`.
    temp9-productid = `HT-1095`.
    temp9-category = `Headsets`.
    temp9-suppliername = `PC Gym Tec`.
    temp9-price = `49.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.24`.
    temp9-height = `0.23`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Lovely Sound 5.1`.
    temp9-productid = `HT-1096`.
    temp9-category = `Headsets`.
    temp9-suppliername = `Japan Insurance Partner`.
    temp9-price = `39.0`.
    temp9-currencycode = `JPY`.
    temp9-width = `0.25`.
    temp9-height = `0.19`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Lovely Sound Stereo`.
    temp9-productid = `HT-1097`.
    temp9-category = `Headsets`.
    temp9-suppliername = `Entertainment Argentinia`.
    temp9-price = `29.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.21`.
    temp9-height = `0.2`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smart Office`.
    temp9-productid = `HT-1100`.
    temp9-category = `Software`.
    temp9-suppliername = `DelBont Industries`.
    temp9-price = `89.9`.
    temp9-currencycode = `USD`.
    temp9-width = `0.15`.
    temp9-height = `0.21`.
    temp9-depth = `0.07`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smart Design`.
    temp9-productid = `HT-1101`.
    temp9-category = `Software`.
    temp9-suppliername = `Talpa`.
    temp9-price = `79.9`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.14`.
    temp9-height = `0.24`.
    temp9-depth = `0.07`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smart Network`.
    temp9-productid = `HT-1102`.
    temp9-category = `Software`.
    temp9-suppliername = `Panorama Studios`.
    temp9-price = `69.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.16`.
    temp9-height = `0.27`.
    temp9-depth = `0.06`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smart Multimedia`.
    temp9-productid = `HT-1103`.
    temp9-category = `Software`.
    temp9-suppliername = `TECUM`.
    temp9-price = `77.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.11`.
    temp9-height = `0.22`.
    temp9-depth = `0.03`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smart Games`.
    temp9-productid = `HT-1104`.
    temp9-category = `Software`.
    temp9-suppliername = `Asia High tech`.
    temp9-price = `55.0`.
    temp9-currencycode = `JPY`.
    temp9-width = `0.1`.
    temp9-height = `0.3`.
    temp9-depth = `0.03`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smart Internet Antivirus`.
    temp9-productid = `HT-1105`.
    temp9-category = `Software`.
    temp9-suppliername = `Laurent`.
    temp9-price = `29.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.16`.
    temp9-height = `0.21`.
    temp9-depth = `0.04`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smart Firewall`.
    temp9-productid = `HT-1106`.
    temp9-category = `Software`.
    temp9-suppliername = `AVANTEL`.
    temp9-price = `34.0`.
    temp9-currencycode = `MXN`.
    temp9-width = `0.18`.
    temp9-height = `0.23`.
    temp9-depth = `0.04`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smart Money`.
    temp9-productid = `HT-1107`.
    temp9-category = `Software`.
    temp9-suppliername = `Telecomunicaciones Star`.
    temp9-price = `29.9`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.12`.
    temp9-height = `0.19`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `PC Lock`.
    temp9-productid = `HT-1110`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Pear Computing Services`.
    temp9-price = `8.9`.
    temp9-currencycode = `USD`.
    temp9-width = `0.2`.
    temp9-height = `0.04`.
    temp9-depth = `0.08`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Notebook Lock`.
    temp9-productid = `HT-1111`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Alpine Systems`.
    temp9-price = `6.9`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.31`.
    temp9-height = `0.07`.
    temp9-depth = `0.09`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Web cam reality`.
    temp9-productid = `HT-1112`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `New Line Design`.
    temp9-price = `39.0`.
    temp9-currencycode = `GBP`.
    temp9-width = `0.09`.
    temp9-height = `0.01`.
    temp9-depth = `0.08`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Screen clean`.
    temp9-productid = `HT-1113`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `HEPA Tec`.
    temp9-price = `2.3`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.02`.
    temp9-height = `0.0`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Fabric bag professional`.
    temp9-productid = `HT-1114`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Anav Ideon`.
    temp9-price = `31.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.42`.
    temp9-height = `0.07`.
    temp9-depth = `0.32`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Wireless DSL Router`.
    temp9-productid = `HT-1115`.
    temp9-category = `Telecommunication`.
    temp9-suppliername = `Robert Brown Entertainment`.
    temp9-price = `49.0`.
    temp9-currencycode = `CAD`.
    temp9-width = `0.19`.
    temp9-height = `0.05`.
    temp9-depth = `0.18`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Wireless DSL Router / Repeater`.
    temp9-productid = `HT-1116`.
    temp9-category = `Telecommunication`.
    temp9-suppliername = `Mexican Oil Trading Company`.
    temp9-price = `59.0`.
    temp9-currencycode = `MXN`.
    temp9-width = `0.19`.
    temp9-height = `0.05`.
    temp9-depth = `0.18`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Wireless DSL Router / Repeater and Print Server`.
    temp9-productid = `HT-1117`.
    temp9-category = `Telecommunication`.
    temp9-suppliername = `Meliva`.
    temp9-price = `69.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.19`.
    temp9-height = `0.05`.
    temp9-depth = `0.18`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `USB Stick`.
    temp9-productid = `HT-1118`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Compostela`.
    temp9-price = `35.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.02`.
    temp9-height = `0.01`.
    temp9-depth = `0.09`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Travel Adapter`.
    temp9-productid = `HT-1119`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Pear Computing Services`.
    temp9-price = `79.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.02`.
    temp9-height = `0.04`.
    temp9-depth = `0.03`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Cordless Bluetooth Keyboard, english international`.
    temp9-productid = `HT-1120`.
    temp9-category = `Keyboards`.
    temp9-suppliername = `Pateu`.
    temp9-price = `29.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.51`.
    temp9-height = `0.04`.
    temp9-depth = `0.23`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Flat XXL`.
    temp9-productid = `HT-1137`.
    temp9-category = `Flat screens`.
    temp9-suppliername = `Russian Electronic Trading Company`.
    temp9-price = `1430.0`.
    temp9-currencycode = `RUB`.
    temp9-width = `0.54`.
    temp9-height = `0.38`.
    temp9-depth = `0.22`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Pocket Mouse`.
    temp9-productid = `HT-1138`.
    temp9-category = `Mice`.
    temp9-suppliername = `Florida Holiday Company`.
    temp9-price = `23.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.0`.
    temp9-height = `0.01`.
    temp9-depth = `0.01`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `PC Power Station`.
    temp9-productid = `HT-1210`.
    temp9-category = `PCs`.
    temp9-suppliername = `Quimica Madrilenos`.
    temp9-price = `2399.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.28`.
    temp9-height = `0.43`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Server Basic`.
    temp9-productid = `HT-1500`.
    temp9-category = `Servers`.
    temp9-suppliername = `Getränkegroßhandel Janssen`.
    temp9-price = `5000.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.34`.
    temp9-height = `0.23`.
    temp9-depth = `0.35`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Server Professional`.
    temp9-productid = `HT-1501`.
    temp9-category = `Servers`.
    temp9-suppliername = `JaTeCo`.
    temp9-price = `15000.0`.
    temp9-currencycode = `JPY`.
    temp9-width = `0.29`.
    temp9-height = `0.27`.
    temp9-depth = `0.3`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Server Power Pro`.
    temp9-productid = `HT-1502`.
    temp9-category = `Servers`.
    temp9-suppliername = `Tessile Casa Di Roma`.
    temp9-price = `25000.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.22`.
    temp9-height = `0.37`.
    temp9-depth = `0.27`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Family PC Basic`.
    temp9-productid = `HT-1600`.
    temp9-category = `PCs`.
    temp9-suppliername = `Telecomunicaciones Star`.
    temp9-price = `600.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.21`.
    temp9-height = `0.38`.
    temp9-depth = `0.29`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Family PC Pro`.
    temp9-productid = `HT-1601`.
    temp9-category = `PCs`.
    temp9-suppliername = `AVANTEL`.
    temp9-price = `900.0`.
    temp9-currencycode = `MXN`.
    temp9-width = `0.25`.
    temp9-height = `0.4`.
    temp9-depth = `0.32`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Gaming Monster`.
    temp9-productid = `HT-1602`.
    temp9-category = `PCs`.
    temp9-suppliername = `Laurent`.
    temp9-price = `1200.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.27`.
    temp9-height = `0.47`.
    temp9-depth = `0.34`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Gaming Monster Pro`.
    temp9-productid = `HT-1603`.
    temp9-category = `PCs`.
    temp9-suppliername = `Asia High tech`.
    temp9-price = `1700.0`.
    temp9-currencycode = `JPY`.
    temp9-width = `0.27`.
    temp9-height = `0.42`.
    temp9-depth = `0.28`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `7" Widescreen Portable DVD Player w MP3`.
    temp9-productid = `HT-2000`.
    temp9-category = `Portable Players`.
    temp9-suppliername = `TECUM`.
    temp9-price = `249.99`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.21`.
    temp9-height = `0.28`.
    temp9-depth = `0.19`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `10" Portable DVD player`.
    temp9-productid = `HT-2001`.
    temp9-category = `Portable Players`.
    temp9-suppliername = `Panorama Studios`.
    temp9-price = `449.99`.
    temp9-currencycode = `USD`.
    temp9-width = `0.24`.
    temp9-height = `0.29`.
    temp9-depth = `0.2`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Portable DVD Player with 9" LCD Monitor`.
    temp9-productid = `HT-2002`.
    temp9-category = `Portable Players`.
    temp9-suppliername = `Sorali`.
    temp9-price = `853.99`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.21`.
    temp9-height = `0.14`.
    temp9-depth = `0.17`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `CD/DVD case: 264 sleeves`.
    temp9-productid = `HT-2025`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Talpa`.
    temp9-price = `44.99`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.13`.
    temp9-height = `0.2`.
    temp9-depth = `0.13`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Audio/Video Cable Kit - 4m`.
    temp9-productid = `HT-2026`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `DelBont Industries`.
    temp9-price = `29.99`.
    temp9-currencycode = `USD`.
    temp9-width = `0.21`.
    temp9-height = `0.13`.
    temp9-depth = `0.1`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Removable CD/DVD Laser Labels`.
    temp9-productid = `HT-2027`.
    temp9-category = `Computer system accessories`.
    temp9-suppliername = `Becker Berlin`.
    temp9-price = `8.99`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.06`.
    temp9-height = `0.02`.
    temp9-depth = `0.02`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Beam Breaker B-1`.
    temp9-productid = `HT-6100`.
    temp9-category = `Beamers`.
    temp9-suppliername = `SAP`.
    temp9-price = `469.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.3`.
    temp9-height = `0.23`.
    temp9-depth = `0.23`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Beam Breaker B-2`.
    temp9-productid = `HT-6101`.
    temp9-category = `Beamers`.
    temp9-suppliername = `Danish Fish Trading Company`.
    temp9-price = `679.0`.
    temp9-currencycode = `DKK`.
    temp9-width = `0.3`.
    temp9-height = `0.23`.
    temp9-depth = `0.23`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Beam Breaker B-3`.
    temp9-productid = `HT-6102`.
    temp9-category = `Beamers`.
    temp9-suppliername = `Siwusha`.
    temp9-price = `889.0`.
    temp9-currencycode = `CNY`.
    temp9-width = `0.3`.
    temp9-height = `0.23`.
    temp9-depth = `0.23`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Play Movie`.
    temp9-productid = `HT-6110`.
    temp9-category = `Portable Players`.
    temp9-suppliername = `South American IT Company`.
    temp9-price = `130.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.37`.
    temp9-height = `0.06`.
    temp9-depth = `0.24`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Record Movie`.
    temp9-productid = `HT-6111`.
    temp9-category = `Portable Players`.
    temp9-suppliername = `Chemia A Technicznie Fabryka`.
    temp9-price = `288.0`.
    temp9-currencycode = `PLN`.
    temp9-width = `0.38`.
    temp9-height = `0.06`.
    temp9-depth = `0.26`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelo MusickStick`.
    temp9-productid = `HT-6120`.
    temp9-category = `MP3-Players`.
    temp9-suppliername = `Indian IT Trading Company`.
    temp9-price = `45.0`.
    temp9-currencycode = `INR`.
    temp9-width = `0.02`.
    temp9-height = `0.01`.
    temp9-depth = `0.06`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelo Jog-Mate`.
    temp9-productid = `HT-6121`.
    temp9-category = `MP3-Players`.
    temp9-suppliername = `Bionic Research Lab`.
    temp9-price = `63.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.05`.
    temp9-height = `0.09`.
    temp9-depth = `0.08`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Power Pro Player 40`.
    temp9-productid = `HT-6122`.
    temp9-category = `MP3-Players`.
    temp9-suppliername = `PicoBit`.
    temp9-price = `167.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.05`.
    temp9-height = `0.09`.
    temp9-depth = `0.08`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Power Pro Player 80`.
    temp9-productid = `HT-6123`.
    temp9-category = `MP3-Players`.
    temp9-suppliername = `African Gold And Diamond Corporation`.
    temp9-price = `299.0`.
    temp9-currencycode = `ZAR`.
    temp9-width = `0.04`.
    temp9-height = `0.01`.
    temp9-depth = `0.06`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Flat Watch HD32`.
    temp9-productid = `HT-6130`.
    temp9-category = `TV flat screens`.
    temp9-suppliername = `Vente Et Réparation de Ordinateur`.
    temp9-price = `1459.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.78`.
    temp9-height = `0.55`.
    temp9-depth = `0.22`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Flat Watch HD37`.
    temp9-productid = `HT-6131`.
    temp9-category = `TV flat screens`.
    temp9-suppliername = `Developement Para O Governo`.
    temp9-price = `1199.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.99`.
    temp9-height = `0.61`.
    temp9-depth = `0.26`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Flat Watch HD41`.
    temp9-productid = `HT-6132`.
    temp9-category = `TV flat screens`.
    temp9-suppliername = `Brazil Technologies`.
    temp9-price = `899.0`.
    temp9-currencycode = `BRL`.
    temp9-width = `1.28`.
    temp9-height = `0.79`.
    temp9-depth = `0.23`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Copperberry`.
    temp9-productid = `HT-7000`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `Angeré`.
    temp9-price = `549.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.08`.
    temp9-height = `0.12`.
    temp9-depth = `0.13`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Silverberry`.
    temp9-productid = `HT-7010`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `Baleda`.
    temp9-price = `549.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.08`.
    temp9-height = `0.12`.
    temp9-depth = `0.13`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Goldberry`.
    temp9-productid = `HT-7020`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `Jologa`.
    temp9-price = `549.0`.
    temp9-currencycode = `CHF`.
    temp9-width = `0.08`.
    temp9-height = `0.12`.
    temp9-depth = `0.13`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Platinberry`.
    temp9-productid = `HT-7030`.
    temp9-category = `PDAs/Organizers`.
    temp9-suppliername = `C.R.T.U.`.
    temp9-price = `549.0`.
    temp9-currencycode = `CAD`.
    temp9-width = `0.08`.
    temp9-height = `0.12`.
    temp9-depth = `0.13`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelO FlexTop I4000`.
    temp9-productid = `HT-8000`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `Alpine Systems`.
    temp9-price = `799.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.31`.
    temp9-height = `0.03`.
    temp9-depth = `0.19`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelO FlexTop I6300c`.
    temp9-productid = `HT-8001`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `New Line Design`.
    temp9-price = `999.0`.
    temp9-currencycode = `GBP`.
    temp9-width = `0.32`.
    temp9-height = `0.03`.
    temp9-depth = `0.2`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelO FlexTop I9100`.
    temp9-productid = `HT-8002`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `HEPA Tec`.
    temp9-price = `1199.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.38`.
    temp9-height = `0.04`.
    temp9-depth = `0.21`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `ITelO FlexTop I9800`.
    temp9-productid = `HT-8003`.
    temp9-category = `Notebooks`.
    temp9-suppliername = `Anav Ideon`.
    temp9-price = `1388.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.48`.
    temp9-height = `0.05`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smartphone Leather Case`.
    temp9-productid = `HT-9991`.
    temp9-category = `Accessories`.
    temp9-suppliername = `JaTeCo`.
    temp9-price = `25.0`.
    temp9-currencycode = `JPY`.
    temp9-width = `0.48`.
    temp9-height = `0.05`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smartphone Alpha`.
    temp9-productid = `HT-9992`.
    temp9-category = `Smartphones`.
    temp9-suppliername = `Getränkegroßhandel Janssen`.
    temp9-price = `599.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.48`.
    temp9-height = `0.05`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Mini Tablet`.
    temp9-productid = `HT-9993`.
    temp9-category = `Tablets`.
    temp9-suppliername = `Quimica Madrilenos`.
    temp9-price = `833.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.48`.
    temp9-height = `0.05`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Camcorder View`.
    temp9-productid = `HT-9994`.
    temp9-category = `Camcorders`.
    temp9-suppliername = `Florida Holiday Company`.
    temp9-price = `1388.0`.
    temp9-currencycode = `USD`.
    temp9-width = `0.48`.
    temp9-height = `0.27`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smartphone Cover`.
    temp9-productid = `HT-9995`.
    temp9-category = `Accessories`.
    temp9-suppliername = `Russian Electronic Trading Company`.
    temp9-price = `15.0`.
    temp9-currencycode = `RUB`.
    temp9-width = `0.48`.
    temp9-height = `0.05`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Tablet Pouch`.
    temp9-productid = `HT-9996`.
    temp9-category = `Accessories`.
    temp9-suppliername = `Pateu`.
    temp9-price = `20.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.25`.
    temp9-height = `0.05`.
    temp9-depth = `0.4`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `e-Book Reader ReadMe`.
    temp9-productid = `HT-9997`.
    temp9-category = `Tablets`.
    temp9-suppliername = `Compostela`.
    temp9-price = `633.0`.
    temp9-currencycode = `ARS`.
    temp9-width = `0.48`.
    temp9-height = `0.05`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Smartphone Beta`.
    temp9-productid = `HT-9998`.
    temp9-category = `Smartphones`.
    temp9-suppliername = `Meliva`.
    temp9-price = `699.0`.
    temp9-currencycode = `EUR`.
    temp9-width = `0.48`.
    temp9-height = `0.05`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    temp9-name = `Maxi Tablet`.
    temp9-productid = `HT-9999`.
    temp9-category = `Tablets`.
    temp9-suppliername = `Mexican Oil Trading Company`.
    temp9-price = `749.0`.
    temp9-currencycode = `MXN`.
    temp9-width = `0.48`.
    temp9-height = `0.05`.
    temp9-depth = `0.31`.
    temp9-dimunit = `M`.
    INSERT temp9 INTO TABLE temp8.
    t_products = temp8.

  ENDMETHOD.

ENDCLASS.
