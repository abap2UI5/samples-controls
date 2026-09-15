" @keywords table sap.m tablebreadcrumb overflowtoolbar toolbarspacer button breadcrumbs link label column text columnlistitem
" @summary With an InfoToolbar and some crumb logic you can navigate simple hierarchies with a breadcrumb table approach.
" @origin sap.m.sample.TableBreadcrumb - https://sdk.openui5.org/entity/sap.m.Table/sample/sap.m.sample.TableBreadcrumb (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_566 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " the three levels of the hierarchy in one flat table: 1 Suppliers,
    " 2 Categories, 3 Products
    TYPES:
      BEGIN OF ty_s_node,
        level         TYPE i,
        supplier      TYPE string,
        category      TYPE string,
        name          TYPE string,
        productid     TYPE string,
        dimensions    TYPE string,
        weightmeasure TYPE string,
        weightunit    TYPE string,
        weight_state  TYPE string,
        price         TYPE string,
        currencycode  TYPE string,
        row_type      TYPE string,
        selected      TYPE abap_bool,
      END OF ty_s_node.
    TYPES ty_t_node TYPE STANDARD TABLE OF ty_s_node WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_crumb,
        text  TYPE string,
        level TYPE i,
      END OF ty_s_crumb.
    TYPES ty_t_crumb TYPE STANDARD TABLE OF ty_s_crumb WITH DEFAULT KEY.

    DATA t_rows   TYPE ty_t_node.
    DATA t_crumbs TYPE ty_t_crumb.

    " where the drill-down currently is
    DATA cur_level TYPE i VALUE 1.
    " the Order model: count + hasCounts
    DATA order_count TYPE i.
    DATA hascounts   TYPE abap_bool.

  PROTECTED SECTION.
    DATA client       TYPE REF TO z2ui5_if_client.
    DATA t_nodes      TYPE ty_t_node.
    DATA cur_supplier TYPE string.
    DATA cur_category TYPE string.

    METHODS view_display.
    METHODS rows_refresh.
    METHODS order_refresh.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_566 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      rows_refresh( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    page = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`

        )->ele( `Page`
            )->a( n = `showHeader` v = `false` ).

    " the Order button is enabled while at least one product is selected
    page->ele( `footer`
        )->ele( `OverflowToolbar`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `text`    v = `Order`
                )->a( n = `enabled` v = client->_bind( hascounts )
                )->a( n = `press`   v = client->_event( `ORDER` )

        )->end(
    )->end( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/listItem}.getBindingContext().getProperty('NAME')` INTO TABLE temp1.
    INSERT `${$parameters>/selected}` INTO TABLE temp1.
    page->ele( `content`
        )->ele( `Table`
            )->a( n = `id`              v = `idProductsTable`
            )->a( n = `inset`           v = `false`
            " _setAggregation switches the mode with the level; the property is
            " bindable, so the expression follows the level instead
            )->a( n = `mode`            v = |\{= ${ client->_bind( cur_level ) } === 3 ? 'MultiSelect' : 'SingleSelectMaster' \}|
            )->a( n = `items`           v = client->_bind( t_rows )
            )->a( n = `selectionChange` v = client->_event( val   = `SELECTION_CHANGE`
                                                            t_arg = temp1 )

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->a( n = `id` v = `idCrumbToolbar`

                    )->ele( `Breadcrumbs`
                        )->a( n = `id`    v = `breadcrumb`
                        )->a( n = `links` v = client->_bind( t_crumbs )

                        )->tag( `Link`
                            )->a( n = `text`  v = `{TEXT}`
                            )->a( n = `press` v = client->_event( val = `CRUMB` arg = `${LEVEL}` )

                    )->end(
                )->end(
            )->end(
            )->ele( `infoToolbar`
                )->ele( `OverflowToolbar`
                    )->a( n = `visible` v = client->_bind( hascounts )

                    )->tag( `Label`
                        )->a( n = `text` v = |\{{ client->_bind_path( order_count ) }\} Products Selected|

                )->end(
            )->end(
            )->ele( `columns`
                )->ele( `Column`
                    )->a( n = `width` v = `12em`

                    )->tag( `Text`
                        )->a( n = `text` v = `Name`

                )->end(
                )->ele( `Column`
                    )->a( n = `id`             v = `dimensionsColumn`
                    )->a( n = `minScreenWidth` v = `Tablet`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `End`
                    )->a( n = `visible`        v = |\{= ${ client->_bind( cur_level ) } === 3 \}|

                    )->tag( `Text`
                        )->a( n = `text` v = `Dimensions`

                )->end(
                )->ele( `Column`
                    )->a( n = `id`             v = `weightColumn`
                    )->a( n = `minScreenWidth` v = `Tablet`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `Center`
                    )->a( n = `visible`        v = |\{= ${ client->_bind( cur_level ) } === 3 \}|

                    )->tag( `Text`
                        )->a( n = `text` v = `Weight`

                )->end(
                )->ele( `Column`
                    )->a( n = `hAlign` v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Price`

                )->end(
            )->end(

            " Row.fragment.xml - the row template the controller binds
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->a( n = `vAlign`   v = `Middle`
                    )->a( n = `type`     v = `{ROW_TYPE}`
                    )->a( n = `selected` v = `{SELECTED}`

                    )->ele( `cells`
                        )->tag( `ObjectIdentifier`
                            )->a( n = `title` v = `{NAME}`
                            )->a( n = `text`  v = `{PRODUCTID}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{DIMENSIONS}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{WEIGHTMEASURE}`
                            )->a( n = `unit`   v = `{WEIGHTUNIT}`
                            )->a( n = `state`  v = `{WEIGHT_STATE}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{PRICE}`
                            )->a( n = `unit`   v = `{CURRENCYCODE}`

                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD rows_refresh.

    " _setAggregation rebinds the table to the branch the user drilled into
    DATA temp3 TYPE z2ui5_cl_smpc_app_566=>ty_t_node.
    DATA node LIKE LINE OF t_nodes.
    DATA temp4 TYPE z2ui5_cl_smpc_app_566=>ty_t_crumb.
    DATA temp5 LIKE LINE OF temp4.
      DATA temp6 TYPE z2ui5_cl_smpc_app_566=>ty_s_crumb.
      DATA temp7 TYPE z2ui5_cl_smpc_app_566=>ty_s_crumb.
    CLEAR temp3.
    t_rows = temp3.
    
    LOOP AT t_nodes INTO node.
      CASE cur_level.
        WHEN 1.
          IF node-level = 1.
            APPEND node TO t_rows.
          ENDIF.
        WHEN 2.
          IF node-level = 2 AND node-supplier = cur_supplier.
            APPEND node TO t_rows.
          ENDIF.
        WHEN OTHERS.
          IF node-level = 3 AND node-supplier = cur_supplier AND node-category = cur_category.
            APPEND node TO t_rows.
          ENDIF.
      ENDCASE.
    ENDLOOP.

    " the breadcrumb carries one link per level already visited
    
    CLEAR temp4.
    
    temp5-text = `Suppliers`.
    temp5-level = 1.
    INSERT temp5 INTO TABLE temp4.
    t_crumbs = temp4.
    IF cur_level >= 2.
      
      CLEAR temp6.
      temp6-text = cur_supplier.
      temp6-level = 2.
      APPEND temp6 TO t_crumbs.
    ENDIF.
    IF cur_level >= 3.
      
      CLEAR temp7.
      temp7-text = cur_category.
      temp7-level = 3.
      APPEND temp7 TO t_crumbs.
    ENDIF.

  ENDMETHOD.


  METHOD order_refresh.

    " the Order model's count / hasCounts (Formatter.listProductsSelected)
    DATA temp8 TYPE i.
    DATA n TYPE i.
    DATA node LIKE LINE OF t_nodes.
      DATA temp1 TYPE i.
    DATA temp2 TYPE xsdboolean.
    n = 0.
    
    LOOP AT t_nodes INTO node.
      
      IF node-selected = abap_true.
        temp1 = n + 1.
      ELSE.
        temp1 = n.
      ENDIF.
      n = temp1.
    ENDLOOP.
    temp8 = n.
    order_count = temp8.
    
    temp2 = boolc( order_count > 0 ).
    hascounts = temp2.

  ENDMETHOD.


  METHOD on_event.
        DATA row_name TYPE string.
        DATA temp9 TYPE abap_bool.
        DATA is_selected LIKE temp9.
            FIELD-SYMBOLS <node> TYPE z2ui5_cl_smpc_app_566=>ty_s_node.
        DATA names TYPE string.
        DATA sel LIKE LINE OF t_nodes.

    CASE client->get_event( ).

      WHEN `SELECTION_CHANGE`.
        " handleSelectionChange: on a branch the selection navigates one level
        " deeper, on a leaf it only records the order selection
        
        row_name = client->get_event_arg( ).
        
        temp9 = client->get_event_arg( 2 ).
        
        is_selected = temp9.
        CASE cur_level.
          WHEN 1.
            cur_supplier = row_name.
            cur_level = 2.
          WHEN 2.
            cur_category = row_name.
            cur_level = 3.
          WHEN OTHERS.
            
            READ TABLE t_nodes WITH KEY level = 3 supplier = cur_supplier category = cur_category name = row_name ASSIGNING <node>.
            IF sy-subrc = 0.
              <node>-selected = is_selected.
            ENDIF.
            order_refresh( ).
        ENDCASE.
        rows_refresh( ).
        view_display( ).

      WHEN `CRUMB`.
        " onBreadcrumbPress: the links after the pressed one are dropped and the
        " table goes back to that level
        cur_level = client->get_event_arg( ).
        rows_refresh( ).
        view_display( ).

      WHEN `ORDER`.
        " handleOrderPress toasts the names of the selected products
        
        names = ``.
        
        LOOP AT t_nodes INTO sel WHERE selected = abap_true.
          IF names IS NOT INITIAL.
            names = names && `,`.
          ENDIF.
          names = names && sel-name.
        ENDLOOP.
        client->message_toast_display( |Ordering: { names }| ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " productHierarchy.json, flattened into one node table: 4 suppliers, their
    " 9 categories and the 14 products under them. Price is already rounded to
    " two decimals (Formatter.round2DP) and the dimensions string is already
    " joined (Formatter.dimensions skips the missing ones)
    DATA temp10 TYPE z2ui5_cl_smpc_app_566=>ty_t_node.
    DATA temp11 LIKE LINE OF temp10.
    FIELD-SYMBOLS <node> LIKE LINE OF t_nodes.
    CLEAR temp10.
    
    temp11-level = 1.
    temp11-name = `Titanium`.
    temp11-price = `1884.49`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Titanium`.
    temp11-name = `Projector`.
    temp11-price = `856.49`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Titanium`.
    temp11-category = `Projector`.
    temp11-name = `Power Projector 4713`.
    temp11-productid = `1239102`.
    temp11-dimensions = `51 x 42 x 18 cm`.
    temp11-weightmeasure = `1467`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Warning`.
    temp11-price = `856.49`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Titanium`.
    temp11-name = `Laptop`.
    temp11-price = `939.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Titanium`.
    temp11-category = `Laptop`.
    temp11-name = `High End Laptop 2b`.
    temp11-productid = `OP-38800002`.
    temp11-dimensions = `64 x 34 x 4 cm`.
    temp11-weightmeasure = `1190`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Warning`.
    temp11-price = `939.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Titanium`.
    temp11-name = `Keyboard`.
    temp11-price = `89.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Titanium`.
    temp11-category = `Keyboard`.
    temp11-name = `Hardcore Hacker`.
    temp11-productid = `977700-11`.
    temp11-dimensions = `53 x 24 x 6 cm`.
    temp11-weightmeasure = `651`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Success`.
    temp11-price = `89.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 1.
    temp11-name = `Technocom`.
    temp11-price = `154.19`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Technocom`.
    temp11-name = `Graphics Card`.
    temp11-price = `81.70`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Technocom`.
    temp11-category = `Graphics Card`.
    temp11-name = `Gladiator MX`.
    temp11-productid = `2212-121-828`.
    temp11-dimensions = `34 x 14 x 2 cm`.
    temp11-weightmeasure = `321`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Success`.
    temp11-price = `81.70`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Technocom`.
    temp11-name = `Accessory`.
    temp11-price = `72.49`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Technocom`.
    temp11-category = `Accessory`.
    temp11-name = `Webcam`.
    temp11-productid = `22134T`.
    temp11-dimensions = `18 x 19 x 21 cm`.
    temp11-weightmeasure = `700`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Success`.
    temp11-price = `59.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Technocom`.
    temp11-category = `Accessory`.
    temp11-name = `Monitor Locking Cable`.
    temp11-productid = `P1239823`.
    temp11-dimensions = `11 x 11 x 3 cm`.
    temp11-weightmeasure = `40`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Success`.
    temp11-price = `13.49`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 1.
    temp11-name = `Red Point Stores`.
    temp11-price = `472.36`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Red Point Stores`.
    temp11-name = `Graphics Card`.
    temp11-price = `219.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Red Point Stores`.
    temp11-category = `Graphics Card`.
    temp11-name = `Hurricane GX`.
    temp11-productid = `K47322.1`.
    temp11-dimensions = `34 x 14 x 2 cm`.
    temp11-weightmeasure = `588`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Success`.
    temp11-price = `219.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Red Point Stores`.
    temp11-name = `Accessory`.
    temp11-price = `96.18`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Red Point Stores`.
    temp11-category = `Accessory`.
    temp11-name = `Laptop Case`.
    temp11-productid = `214-121-828`.
    temp11-dimensions = `53 x 34 x 7 cm`.
    temp11-weightmeasure = `1289`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Warning`.
    temp11-price = `78.99`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Red Point Stores`.
    temp11-category = `Accessory`.
    temp11-name = `USB Stick 16 GByte`.
    temp11-productid = `XKP-312548`.
    temp11-dimensions = `6 x 2 x 0.5 cm`.
    temp11-weightmeasure = `11`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Success`.
    temp11-price = `17.19`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Red Point Stores`.
    temp11-name = `Printer`.
    temp11-price = `157.18`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Red Point Stores`.
    temp11-category = `Printer`.
    temp11-name = `Deskjet Super Highspeed`.
    temp11-productid = `KTZ-12012.V2`.
    temp11-dimensions = `87 x 45 x 39 cm`.
    temp11-weightmeasure = `100`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Success`.
    temp11-price = `117.19`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Red Point Stores`.
    temp11-category = `Printer`.
    temp11-name = `Laser Allround Pro`.
    temp11-productid = `89932-922`.
    temp11-dimensions = `42 x 29 x 31 cm`.
    temp11-weightmeasure = `2134`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Error`.
    temp11-price = `39.99`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 1.
    temp11-name = `Very Best Screens`.
    temp11-price = `2217.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 2.
    temp11-supplier = `Very Best Screens`.
    temp11-name = `Monitor`.
    temp11-price = `2217.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Navigation`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Very Best Screens`.
    temp11-category = `Monitor`.
    temp11-name = `Flat S`.
    temp11-productid = `38094020.1`.
    temp11-dimensions = `88 x 13 x 49 cm`.
    temp11-weightmeasure = `1401`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Warning`.
    temp11-price = `339.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Very Best Screens`.
    temp11-category = `Monitor`.
    temp11-name = `Flat Medium`.
    temp11-productid = `870394932`.
    temp11-dimensions = `102 x 13 x 54 cm`.
    temp11-weightmeasure = `1800`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Warning`.
    temp11-price = `639.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    temp11-level = 3.
    temp11-supplier = `Very Best Screens`.
    temp11-category = `Monitor`.
    temp11-name = `Flat X-large II`.
    temp11-productid = `282948303-02`.
    temp11-dimensions = `112 x 13 x 60 cm`.
    temp11-weightmeasure = `2100`.
    temp11-weightunit = `g`.
    temp11-weight_state = `Error`.
    temp11-price = `1239.00`.
    temp11-currencycode = `EUR`.
    temp11-row_type = `Inactive`.
    INSERT temp11 INTO TABLE temp10.
    t_nodes = temp10.

    " a flat ABAP row serializes EVERY field, so the supplier and category rows -
    " which carry no weight at all - would send an empty string into the
    " ObjectNumber's ValueState and take the whole view down. None is the
    " control's own default and is what the sample's formatter returns for a
    " missing measure (**e2e-caught 2026-08-22**)
    
    LOOP AT t_nodes ASSIGNING <node> WHERE weight_state IS INITIAL.
      <node>-weight_state = `None`.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
