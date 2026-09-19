" @keywords manage products app navcontainer title icontabbar icontabfilter icontabseparator table toolbar toolbarspacer searchfield
" @summary Created with the 'Worklist App' tutorial. - the UI5 demo app "Manage Products", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Manage Products (sap.m/tutorial/worklist) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Manage Products</p>
"!
"! The UI5 demo app Manage Products (the "Worklist App" tutorial, step 07) -
"! a whole application rather than a control sample, rebuilt as ONE abap2UI5
"! class: the worklist page with its quick filters, search, multi-selection
"! and the two mass actions, and the object page with supplier form and
"! comments. Both pages live in one NavContainer and are switched on the
"! client; the URL follows over hash_set, so the browser Back button and a
"! deep link work the way the original's router makes them work.
"!
"! Where it differs from the original, and why:
"!
"!  - the OData V2 service and its mock server become ABAP data. The
"!    original expands Supplier into every product row; here the supplier
"!    name is joined into the row in model_init, which is what the expand
"!    produces.
"!  - filtering, searching and counting run in ABAP rather than on the list
"!    binding. abap2UI5 is a thin frontend: the backend holds the full stock
"!    and sends the rows the tab and the search leave.
"!  - the formatter module (numberUnit, quantityState) is business logic and
"!    moves to the backend with it - the view binds the finished text and the
"!    finished ValueState.
"!  - selection is a bound row field instead of getSelectedItems( ), so the
"!    two mass actions read what the user picked without asking the browser.
"!  - the i18n resource bundle becomes literals. An abap2UI5 app translates
"!    with ABAP text elements or a message class, not with a properties file
"!    that never reaches the system.
"!  - the busy handling (busyIndicatorDelay, the view model's busy flags) has
"!    nothing to do here: the view is rendered from data the server already
"!    holds.
"!  - the IllustratedMessage of the not-found pages is @since 1.98 and this
"!    package holds the 1.71 floor; no route can reach a missing product
"!    here, so the pages are gone rather than downgraded.
"!  - the share menu opens a mailto: URL from the client. The original
"!    composes it with sap.m.URLHelper, which is the same thing one layer
"!    down. Not verified in a running system.
"!  - a posted comment is stamped with the server date and time in ISO form,
"!    where the original formats the browser clock with a medium DateFormat.
"!  - the object page gets an in-app back button in its footer. The original
"!    has none - its Object view offers no way back and relies on the browser
"!    Back button alone, while its onNavBack handler sits unused in the
"!    controller. The button is that handler, wired.
"!  - the name column header reads ProductName. The original binds
"!    i18n>TableNameColumnTitle, a key its bundle does not have (it carries
"!    tableNameColumnTitle), so the demo kit renders the raw key there.
"!
"! Original: src/sap.m/test/sap/m/demokit/tutorial/worklist/07 in OpenUI5,
"! archived under ui5/demoapps/sap.m/tutorial/worklist.
"! Demo apps: https://sdk.openui5.org/demoapps
CLASS z2ui5_cl_smpc_demo_001 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_row,
        productid          TYPE i,
        productname        TYPE string,
        suppliername       TYPE string,
        unitprice_text     TYPE string,
        unitsonorder_text  TYPE string,
        unitsinstock_text  TYPE string,
        unitsinstock_state TYPE string,
        selected           TYPE abap_bool,
      END OF ty_s_row.
    TYPES:
      BEGIN OF ty_s_comment,
        productid TYPE i,
        type      TYPE string,
        date      TYPE string,
        comment   TYPE string,
      END OF ty_s_comment.

    DATA t_rows             TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
    DATA t_comments         TYPE STANDARD TABLE OF ty_s_comment WITH DEFAULT KEY.
    DATA filter_key         TYPE string VALUE `all`.
    DATA search_term        TYPE string.
    DATA table_title        TYPE string.
    DATA table_no_data      TYPE string.
    DATA count_all          TYPE string.
    DATA count_instock      TYPE string.
    DATA count_shortage     TYPE string.
    DATA count_outofstock   TYPE string.
    DATA obj_productname    TYPE string.
    DATA obj_productid      TYPE string.
    DATA obj_unitprice      TYPE string.
    DATA obj_unitsinstock   TYPE string.
    DATA obj_units_percent  TYPE i.
    " ObjectNumber.state is enum-typed: an empty value is rejected outright
    " (validateProperty), so the worklist start carries the UI5 default until
    " a product is opened
    DATA obj_units_state    TYPE string VALUE `None`.
    DATA obj_discontinued   TYPE abap_bool.
    DATA obj_suppliername   TYPE string.
    DATA obj_address        TYPE string.
    DATA obj_postal_city    TYPE string.
    DATA obj_country        TYPE string.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_product,
        productid    TYPE i,
        productname  TYPE string,
        supplierid   TYPE i,
        unitsinstock TYPE i,
        unitsonorder TYPE i,
        unitprice    TYPE i,
        discontinued TYPE abap_bool,
      END OF ty_s_product.
    TYPES:
      BEGIN OF ty_s_supplier,
        supplierid  TYPE i,
        companyname TYPE string,
        address     TYPE string,
        postalcode  TYPE string,
        city        TYPE string,
        country     TYPE string,
      END OF ty_s_supplier.

    DATA client        TYPE REF TO z2ui5_if_client.
    DATA t_products    TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
    DATA t_suppliers   TYPE STANDARD TABLE OF ty_s_supplier WITH DEFAULT KEY.
    DATA t_feedback    TYPE STANDARD TABLE OF ty_s_comment WITH DEFAULT KEY.
    DATA product_shown TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS hash_apply.
    METHODS object_show
      IMPORTING
        productid TYPE i.
    METHODS comments_refresh.
    METHODS list_refresh.
    METHODS number_unit
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE string.
    METHODS quantity_state
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_demo_001 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      list_refresh( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA nav TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA worklist TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA object TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA header TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA body TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA temp3 TYPE string_table.
      DATA temp5 TYPE string_table.

    " a reload or a shared link: the live hash rides in s_config-hash on
    " every request, so a render whose hash already names a product starts on
    " the object page - the routeMatched of a cold start
    hash_apply( ).

    
    view = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock`   v = `true`
            )->a( n = `xmlns`          v = `sap.m`
            )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
            )->a( n = `xmlns:semantic` v = `sap.f.semantic`
            )->a( n = `xmlns:form`     v = `sap.ui.layout.form`
            )->a( n = `xmlns:l`        v = `sap.ui.layout` ).

    
    nav = view->ele( `Shell`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav` ).

    " ---------------------------------------------------------- worklist
    
    worklist = nav->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`                       v = `page-worklist`
        )->a( n = `headerPinnable`           b = abap_false
        )->a( n = `toggleHeaderOnTitleClick` b = abap_false
        )->a( n = `showFooter`               b = abap_true ).

    worklist->ele( n = `titleHeading` ns = `semantic`
        )->tag( `Title`
            )->a( n = `text` v = `Manage Products` ).

    
    table = worklist->ele( n = `headerContent` ns = `semantic`
        )->ele( `IconTabBar`
            )->a( n = `id`          v = `iconTabBar`
            )->a( n = `expandable`  b = abap_false
            )->a( n = `selectedKey` v = client->_bind( filter_key )
            )->a( n = `select`      v = client->_event( `FILTER` )

            )->ele( `items`
                )->tag( `IconTabFilter`
                    )->a( n = `key`     v = `all`
                    )->a( n = `showAll` b = abap_true
                    )->a( n = `count`   v = client->_bind( count_all )
                    )->a( n = `text`    v = `Products`
                )->tag( `IconTabSeparator`
                )->tag( `IconTabFilter`
                    )->a( n = `key`       v = `inStock`
                    )->a( n = `icon`      v = `sap-icon://message-success`
                    )->a( n = `iconColor` v = `Positive`
                    )->a( n = `count`     v = client->_bind( count_instock )
                    )->a( n = `text`      v = `Plenty in Stock`
                )->tag( `IconTabFilter`
                    )->a( n = `key`       v = `shortage`
                    )->a( n = `icon`      v = `sap-icon://message-warning`
                    )->a( n = `iconColor` v = `Critical`
                    )->a( n = `count`     v = client->_bind( count_shortage )
                    )->a( n = `text`      v = `Shortage`
                )->tag( `IconTabFilter`
                    )->a( n = `key`       v = `outOfStock`
                    )->a( n = `icon`      v = `sap-icon://message-error`
                    )->a( n = `iconColor` v = `Negative`
                    )->a( n = `count`     v = client->_bind( count_outofstock )
                    )->a( n = `text`      v = `Out of Stock`

            )->end(
            )->ele( `content`
                )->ele( `Table`
                    )->a( n = `id`                  v = `table`
                    )->a( n = `growing`             b = abap_true
                    )->a( n = `growingScrollToLoad` b = abap_true
                    )->a( n = `noDataText`          v = client->_bind( table_no_data )
                    )->a( n = `width`               v = `auto`
                    )->a( n = `mode`                v = `MultiSelect`
                    )->a( n = `items`               v = client->_bind( t_rows ) ).

    table->ele( `headerToolbar`
        )->ele( `Toolbar`
            )->tag( `Title`
                )->a( n = `id`   v = `tableHeader`
                )->a( n = `text` v = client->_bind( table_title )
            )->tag( `ToolbarSpacer`
            )->tag( `SearchField`
                )->a( n = `id`      v = `searchField`
                )->a( n = `tooltip` v = `Enter a Product name or a part of it.`
                )->a( n = `value`   v = client->_bind( search_term )
                )->a( n = `search`  v = client->_event( `SEARCH` )
                )->a( n = `width`   v = `auto` ).

    table->ele( `columns`
        )->ele( `Column`
            )->a( n = `id` v = `nameColumn`

            )->tag( `Text`
                )->a( n = `id`   v = `nameColumnTitle`
                )->a( n = `text` v = `ProductName`

        )->end(
        )->ele( `Column`
            )->a( n = `id`             v = `supplierNameColumn`
            )->a( n = `demandPopin`    b = abap_false
            )->a( n = `minScreenWidth` v = `Tablet`

            )->tag( `Text`
                )->a( n = `text` v = `Supplier`

        )->end(
        )->ele( `Column`
            )->a( n = `id`             v = `unitPriceColumn`
            )->a( n = `hAlign`         v = `End`
            )->a( n = `demandPopin`    b = abap_true
            )->a( n = `minScreenWidth` v = `Tablet`

            )->tag( `Text`
                )->a( n = `text` v = `Price`

        )->end(
        )->ele( `Column`
            )->a( n = `id`             v = `unitsOnOrderColumn`
            )->a( n = `demandPopin`    b = abap_true
            )->a( n = `minScreenWidth` v = `Tablet`
            )->a( n = `hAlign`         v = `End`

            )->tag( `Text`
                )->a( n = `text` v = `Units Ordered`

        )->end(
        )->ele( `Column`
            )->a( n = `id`     v = `unitsInStockColumn`
            )->a( n = `hAlign` v = `End`

            )->tag( `Text`
                )->a( n = `text` v = `Units in Stock` ).

    table->ele( `items`
        )->ele( `ColumnListItem`
            )->a( n = `type`     v = `Navigation`
            )->a( n = `selected` v = `{SELECTED}`
            )->a( n = `press`    v = client->_event( val = `SHOW` arg = `${PRODUCTID}` )

            )->ele( `cells`
                )->tag( `ObjectIdentifier`
                    )->a( n = `title` v = `{PRODUCTNAME}`
                )->tag( `Text`
                    )->a( n = `text` v = `{SUPPLIERNAME}`
                )->tag( `ObjectNumber`
                    )->a( n = `unit`   v = `EUR`
                    )->a( n = `number` v = `{UNITPRICE_TEXT}`
                )->tag( `ObjectNumber`
                    )->a( n = `unit`   v = `PC`
                    )->a( n = `number` v = `{UNITSONORDER_TEXT}`
                )->tag( `ObjectNumber`
                    )->a( n = `unit`   v = `PC`
                    )->a( n = `number` v = `{UNITSINSTOCK_TEXT}`
                    )->a( n = `state`  v = `{UNITSINSTOCK_STATE}` ).

    worklist->ele( n = `sendEmailAction` ns = `semantic`
        )->tag( n = `SendEmailAction` ns = `semantic`
            )->a( n = `id`    v = `shareEmail`
            )->a( n = `press` v = client->_event( `SHARE_EMAIL` ) ).

    worklist->ele( n = `positiveAction` ns = `semantic`
        )->tag( n = `PositiveAction` ns = `semantic`
            )->a( n = `text`  v = `Order`
            )->a( n = `press` v = client->_event( `REORDER` ) ).

    worklist->ele( n = `negativeAction` ns = `semantic`
        )->tag( n = `NegativeAction` ns = `semantic`
            )->a( n = `text`  v = `Remove`
            )->a( n = `press` v = client->_event( `UNLIST` ) ).

    " ------------------------------------------------------------ object
    
    object = nav->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`                       v = `page-object`
        )->a( n = `headerPinnable`           b = abap_false
        )->a( n = `toggleHeaderOnTitleClick` b = abap_false
        )->a( n = `showFooter`               b = abap_true ).

    object->ele( n = `titleHeading` ns = `semantic`
        )->tag( `Title`
            )->a( n = `text` v = client->_bind( obj_productname ) ).

    
    header = object->ele( n = `headerContent` ns = `semantic`
        )->ele( `FlexBox`
            )->a( n = `alignItems`     v = `Start`
            )->a( n = `justifyContent` v = `SpaceBetween` ).

    header->ele( `Panel`
        )->a( n = `backgroundDesign` v = `Transparent`

        )->tag( `ObjectAttribute`
            )->a( n = `title` v = `Product ID`
            )->a( n = `text`  v = client->_bind( obj_productid )
        )->tag( `ObjectAttribute`
            )->a( n = `title` v = `Price`
            )->a( n = `text`  v = client->_bind( obj_unitprice ) ).

    header->ele( `Panel`
        )->a( n = `backgroundDesign` v = `Transparent`

        )->tag( `ObjectNumber`
            )->a( n = `id`        v = `objectHeader`
            )->a( n = `unit`      v = `PC`
            )->a( n = `textAlign` v = `End`
            )->a( n = `state`     v = client->_bind( obj_units_state )
            )->a( n = `number`    v = client->_bind( obj_unitsinstock )
        )->tag( `ObjectStatus`
            )->a( n = `text`    v = `Discontinued`
            )->a( n = `state`   v = `Error`
            )->a( n = `visible` v = client->_bind( obj_discontinued )
        )->tag( `ProgressIndicator`
            )->a( n = `width`        v = `300px`
            )->a( n = `percentValue` v = client->_bind( obj_units_percent )
            )->a( n = `displayValue` v = client->_bind( obj_unitsinstock )
            )->a( n = `showValue`    b = abap_true
            )->a( n = `state`        v = client->_bind( obj_units_state ) ).

    
    body = object->ele( n = `content` ns = `semantic`
        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `width` v = `100%` ).

    body->ele( `Panel`
        )->a( n = `backgroundDesign` v = `Transparent`
        )->a( n = `headerText`       v = `Supplier Info`

        )->ele( `content`
            )->ele( n = `SimpleForm` ns = `form`
                )->a( n = `maxContainerCols` v = `2`
                )->a( n = `editable`         b = abap_false
                )->a( n = `layout`           v = `ResponsiveGridLayout`
                )->a( n = `labelSpanL`       v = `3`
                )->a( n = `labelSpanM`       v = `3`
                )->a( n = `emptySpanL`       v = `4`
                )->a( n = `emptySpanM`       v = `4`
                )->a( n = `columnsL`         v = `1`
                )->a( n = `columnsM`         v = `1`

                )->ele( n = `content` ns = `form`
                    )->tag( `Label`
                        )->a( n = `text` v = `Name`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( obj_suppliername )
                    )->tag( `Label`
                        )->a( n = `text` v = `Address`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( obj_address )
                    )->tag( `Label`
                        )->a( n = `text` v = `ZIP Code / City`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( obj_postal_city )
                    )->tag( `Label`
                        )->a( n = `text` v = `Country`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( obj_country ) ).

    body->ele( `Panel`
        )->a( n = `backgroundDesign` v = `Transparent`
        )->a( n = `headerText`       v = `Comments`

        )->ele( `content`
            )->tag( `FeedInput`
                )->a( n = `post` v = client->_event( val = `POST` arg = `${$parameters>/value}` )

            )->ele( `List`
                )->a( n = `id`             v = `idCommentsList`
                )->a( n = `noDataText`     v = `No Comments`
                )->a( n = `showSeparators` v = `Inner`
                )->a( n = `items`          v = client->_bind( t_comments )

                )->ele( `items`
                    )->tag( `FeedListItem`
                        )->a( n = `info`      v = `{TYPE}`
                        )->a( n = `text`      v = `{COMMENT}`
                        )->a( n = `timestamp` v = `{DATE}` ).

    object->ele( n = `sendEmailAction` ns = `semantic`
        )->tag( n = `SendEmailAction` ns = `semantic`
            )->a( n = `id`    v = `shareEmailObject`
            )->a( n = `press` v = client->_event( `SHARE_EMAIL` ) ).

    " the in-app back button of the object page: the UI5 onNavBack pattern -
    " one consumed step back in the browser history, and on a cold deep link,
    " where no step exists, a replace to the worklist
    
    CLEAR temp1.
    INSERT `/` INTO TABLE temp1.
    object->ele( n = `footerCustomActions` ns = `semantic`
        )->tag( `Button`
            )->a( n = `text`  v = `Show Manage Products`
            )->a( n = `icon`  v = `sap-icon://nav-back`
            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-hash_back
                                                            t_arg = temp1 ) ).

    client->view_display( view->stringify( ) ).

    " hash changes the app did not write itself - the browser Back/Forward
    " buttons, a hand-edited URL - round-trip as HASH_CHANGED. Registered per
    " render, since the registration dies with an app switch
    
    CLEAR temp3.
    INSERT `HASH_CHANGED` INTO TABLE temp3.
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = temp3 ).

    " a rebuilt NavContainer is back on its first page while the product on
    " show survives as class state - re-issue the page it should carry
    IF product_shown IS NOT INITIAL.
      
      CLEAR temp5.
      INSERT `nav` INTO TABLE temp5.
      INSERT `to` INTO TABLE temp5.
      INSERT `page-object` INTO TABLE temp5.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = temp5 ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.
        DATA temp7 TYPE i.
        DATA temp8 TYPE string_table.
        DATA temp1 TYPE string.
        DATA reordered TYPE i.
        DATA temp10 LIKE LINE OF t_products.
        DATA product LIKE REF TO temp10.
          DATA temp11 LIKE sy-subrc.
        DATA unlisted TYPE i.
        DATA row LIKE LINE OF t_rows.
        DATA temp12 TYPE z2ui5_cl_smpc_demo_001=>ty_s_comment.
        DATA temp13 TYPE string_table.

    CASE client->get_event( ).

      WHEN `FILTER` OR `SEARCH`.
        " the list binding's filter( ), done where the data is
        list_refresh( ).

      WHEN `SHOW`.
        " the router's navTo( "object", { objectId: ... } )
        
        temp7 = client->get_event_arg( ).
        object_show( temp7 ).

      WHEN `HASH_CHANGED`.
        " the router's routeMatched: show the page the hash now names
        hash_apply( ).
        
        CLEAR temp8.
        INSERT `nav` INTO TABLE temp8.
        INSERT `to` INTO TABLE temp8.
        
        IF product_shown IS NOT INITIAL.
          temp1 = `page-object`.
        ELSE.
          temp1 = `page-worklist`.
        ENDIF.
        INSERT temp1 INTO TABLE temp8.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp8 ).

      WHEN `REORDER`.
        
        reordered = 0.
        
        
        LOOP AT t_products REFERENCE INTO product.
          
          READ TABLE t_rows WITH KEY productid = product->productid selected = abap_true TRANSPORTING NO FIELDS.
          temp11 = sy-subrc.
          IF NOT temp11 = 0.
            CONTINUE.
          ENDIF.
          product->unitsinstock = product->unitsinstock + 10.
          reordered = reordered + 1.
        ENDLOOP.
        IF reordered = 0.
          client->message_box_display( text = `No product selected` type = `error` ).
        ELSE.
          list_refresh( ).
          client->message_toast_display( `Product stock level updated` ).
        ENDIF.

      WHEN `UNLIST`.
        
        unlisted = 0.
        
        LOOP AT t_rows INTO row WHERE selected = abap_true.
          DELETE t_products WHERE productid = row-productid.
          unlisted = unlisted + 1.
        ENDLOOP.
        IF unlisted = 0.
          client->message_box_display( text = `No product selected` type = `error` ).
        ELSE.
          list_refresh( ).
          client->message_toast_display( `Product removed` ).
        ENDIF.

      WHEN `POST`.
        
        CLEAR temp12.
        temp12-productid = product_shown.
        temp12-type = `Comment`.
        temp12-date = |{ sy-datum DATE = ISO } { sy-uzeit TIME = ISO }|.
        temp12-comment = client->get_event_arg( ).
        INSERT temp12 INTO TABLE t_feedback.
        comments_refresh( ).

      WHEN `SHARE_EMAIL`.
        " what sap.m.URLHelper.triggerEmail does one layer down
        
        CLEAR temp13.
        INSERT `mailto:?subject=Manage%20Products` INTO TABLE temp13.
        client->follow_up_action( val   = client->cs_event-open_new_tab
                                  t_arg = temp13 ).

    ENDCASE.

  ENDMETHOD.


  METHOD hash_apply.

    " '/Products/<id>' is the object page, everything else the worklist -
    " the two routes of the original's manifest
    DATA hash TYPE z2ui5_if_client=>ty_s_get-s_config-hash.
      DATA id TYPE string.
        DATA temp15 TYPE i.
    hash = client->get( )-s_config-hash.
    IF hash CS `/Products/`.
      
      id = substring_after( val = hash sub = `/Products/` ).
      IF id CO `0123456789` AND id IS NOT INITIAL.
        
        temp15 = id.
        object_show( temp15 ).
        RETURN.
      ENDIF.
    ENDIF.

    product_shown = 0.

  ENDMETHOD.


  METHOD object_show.

    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_demo_001=>ty_s_product.
    FIELD-SYMBOLS <supplier> TYPE z2ui5_cl_smpc_demo_001=>ty_s_supplier.
    DATA temp16 TYPE string_table.
    READ TABLE t_products WITH KEY productid = productid ASSIGNING <product>.
    IF <product> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    product_shown     = productid.
    obj_productname   = <product>-productname.
    obj_productid     = number_unit( <product>-productid ).
    obj_unitprice     = |{ number_unit( <product>-unitprice ) } EUR|.
    obj_unitsinstock  = number_unit( <product>-unitsinstock ).
    obj_units_percent = <product>-unitsinstock.
    obj_units_state   = quantity_state( <product>-unitsinstock ).
    obj_discontinued  = <product>-discontinued.

    
    READ TABLE t_suppliers WITH KEY supplierid = <product>-supplierid ASSIGNING <supplier>.
    IF <supplier> IS ASSIGNED.
      obj_suppliername = <supplier>-companyname.
      obj_address      = <supplier>-address.
      obj_postal_city  = |{ <supplier>-postalcode } / { <supplier>-city }|.
      obj_country      = <supplier>-country.
    ENDIF.

    comments_refresh( ).

    " the router's navTo pushes a history entry, so the browser Back button
    " has a step to take - and the URL is the deep link of the original
    client->hash_set( |/Products/{ productid }| ).
    
    CLEAR temp16.
    INSERT `nav` INTO TABLE temp16.
    INSERT `to` INTO TABLE temp16.
    INSERT `page-object` INTO TABLE temp16.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp16 ).

  ENDMETHOD.


  METHOD comments_refresh.

    " the original filters the feed list on productID and sorts it by date,
    " newest first
    DATA temp18 LIKE t_comments.
    DATA comment LIKE LINE OF t_feedback.
    CLEAR temp18.
    t_comments = temp18.
    
    LOOP AT t_feedback INTO comment WHERE productid = product_shown.
      INSERT comment INTO t_comments INDEX 1.
    ENDLOOP.

  ENDMETHOD.


  METHOD list_refresh.

    " declared here, not inline at the ASSIGN below, so it can be UNASSIGNed
    " before each one - see there
    FIELD-SYMBOLS <supplier> LIKE LINE OF t_suppliers.

    DATA shown TYPE i.
    DATA selection LIKE t_rows.
    DATA temp19 LIKE t_rows.
    DATA product LIKE LINE OF t_products.
      DATA temp20 TYPE z2ui5_cl_smpc_demo_001=>ty_s_row.
      DATA temp2 TYPE z2ui5_cl_smpc_demo_001=>ty_s_row-suppliername.
      DATA temp3 LIKE sy-subrc.
      DATA temp1 TYPE xsdboolean.
    DATA temp21 TYPE i.
    DATA n TYPE i.
    DATA p LIKE LINE OF t_products.
      DATA temp4 TYPE i.
    DATA temp22 TYPE i.
    DATA s TYPE i.
    DATA q LIKE LINE OF t_products.
      DATA temp5 TYPE i.
    DATA temp23 TYPE i.
    DATA o TYPE i.
    DATA r LIKE LINE OF t_products.
      DATA temp6 TYPE i.
    DATA temp24 TYPE string.
    DATA temp25 TYPE string.
    shown = 0.
    
    selection = t_rows.
    
    CLEAR temp19.
    t_rows = temp19.

    
    LOOP AT t_products INTO product.
      CASE filter_key.
        WHEN `inStock`.
          IF product-unitsinstock <= 10.
            CONTINUE.
          ENDIF.
        WHEN `shortage`.
          IF product-unitsinstock < 1 OR product-unitsinstock > 10.
            CONTINUE.
          ENDIF.
        WHEN `outOfStock`.
          IF product-unitsinstock > 0.
            CONTINUE.
          ENDIF.
      ENDCASE.

      IF search_term IS NOT INITIAL AND to_upper( product-productname ) NS to_upper( search_term ).
        CONTINUE.
      ENDIF.

      " IS ASSIGNED, not sy-subrc (#1937: a SUCCESSFUL dynamic ASSIGN does not
      " reset sy-subrc on every release, so a product whose supplier IS in the
      " table lost its supplier name). UNASSIGN first because this sits in a
      " LOOP: a failed ASSIGN leaves the previous iteration's binding in place,
      " and IS ASSIGNED would then read TRUE - and print the WRONG supplier
      UNASSIGN <supplier>.
      READ TABLE t_suppliers WITH KEY supplierid = product-supplierid ASSIGNING <supplier>.
      
      CLEAR temp20.
      temp20-productid = product-productid.
      temp20-productname = product-productname.
      
      IF <supplier> IS ASSIGNED.
        temp2 = <supplier>-companyname.
      ELSE.
        CLEAR temp2.
      ENDIF.
      temp20-suppliername = temp2.
      temp20-unitprice_text = number_unit( product-unitprice ).
      temp20-unitsonorder_text = number_unit( product-unitsonorder ).
      temp20-unitsinstock_text = number_unit( product-unitsinstock ).
      temp20-unitsinstock_state = quantity_state( product-unitsinstock ).
      
      READ TABLE selection WITH KEY productid = product-productid selected = abap_true TRANSPORTING NO FIELDS.
      temp3 = sy-subrc.
      
      temp1 = boolc( temp3 = 0 ).
      temp20-selected = temp1.
      INSERT temp20 INTO TABLE t_rows.
      shown = shown + 1.
    ENDLOOP.

    " the original's list binding sorts by ProductName ascending
    SORT t_rows BY productname AS TEXT.

    " the four $count reads of the original, over the full stock
    count_all        = |{ lines( t_products ) }|.
    
    
    n = 0.
    
    LOOP AT t_products INTO p.
      
      IF p-unitsinstock > 10.
        temp4 = n + 1.
      ELSE.
        temp4 = n.
      ENDIF.
      n = temp4.
    ENDLOOP.
    temp21 = n.
    count_instock    = |{ temp21 }|.
    
    
    s = 0.
    
    LOOP AT t_products INTO q.
      
      IF q-unitsinstock BETWEEN 1 AND 10.
        temp5 = s + 1.
      ELSE.
        temp5 = s.
      ENDIF.
      s = temp5.
    ENDLOOP.
    temp22 = s.
    count_shortage   = |{ temp22 }|.
    
    
    o = 0.
    
    LOOP AT t_products INTO r.
      
      IF r-unitsinstock <= 0.
        temp6 = o + 1.
      ELSE.
        temp6 = o.
      ENDIF.
      o = temp6.
    ENDLOOP.
    temp23 = o.
    count_outofstock = |{ temp23 }|.

    
    IF shown = 0.
      temp24 = `ProductsPlural`.
    ELSE.
      temp24 = |Products ({ shown })|.
    ENDIF.
    table_title   = temp24.
    
    IF search_term IS INITIAL.
      temp25 = `No ProductsPlural are currently available`.
    ELSE.
      temp25 = `No matching ProductsPlural found`.
    ENDIF.
    table_no_data = temp25.

  ENDMETHOD.


  METHOD number_unit.

    " the original's numberUnit formatter - parseFloat(value).toFixed(2).
    " The mock carries whole numbers only, so the two decimals are always
    " the two zeros; it runs in ABAP because a formatter is business logic
    result = |{ val }.00|.

  ENDMETHOD.


  METHOD quantity_state.

    " the original's quantityState formatter: out of stock is an error,
    " ten or fewer a warning, anything above that success
    DATA temp26 TYPE string.
    IF val = 0.
      temp26 = `Error`.
    ELSEIF val <= 10.
      temp26 = `Warning`.
    ELSE.
      temp26 = `Success`.
    ENDIF.
    result = temp26.

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Products.json - the full row set, verbatim
    DATA temp27 LIKE t_products.
    DATA temp28 LIKE LINE OF temp27.
    DATA temp29 LIKE t_suppliers.
    DATA temp30 LIKE LINE OF temp29.
    CLEAR temp27.
    
    temp28-productid = 1.
    temp28-productname = `Chai`.
    temp28-supplierid = 1.
    temp28-unitsinstock = 39.
    temp28-unitsonorder = 10.
    temp28-unitprice = 8.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 2.
    temp28-productname = `Chang`.
    temp28-supplierid = 1.
    temp28-unitsinstock = 81.
    temp28-unitsonorder = 7.
    temp28-unitprice = 6.
    temp28-discontinued = abap_true.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 3.
    temp28-productname = `Aniseed Syrup`.
    temp28-supplierid = 3.
    temp28-unitsinstock = 100.
    temp28-unitsonorder = 6.
    temp28-unitprice = 3.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 4.
    temp28-productname = `Schwarzwälder Kirschtorte`.
    temp28-supplierid = 3.
    temp28-unitsinstock = 2.
    temp28-unitsonorder = 3.
    temp28-unitprice = 19.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 5.
    temp28-productname = `Chef Anton's Cajun Seasoning`.
    temp28-supplierid = 3.
    temp28-unitsinstock = 11.
    temp28-unitsonorder = 9.
    temp28-unitprice = 108.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 6.
    temp28-productname = `Chef Anton's Gumbo Mix`.
    temp28-supplierid = 4.
    temp28-unitsinstock = 21.
    temp28-unitsonorder = 12.
    temp28-unitprice = 18.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 7.
    temp28-productname = `Grandma's Boysenberry Spread`.
    temp28-supplierid = 5.
    temp28-unitsinstock = 25.
    temp28-unitsonorder = 25.
    temp28-unitprice = 18.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 8.
    temp28-productname = `Uncle Bob's Organic Dried Pears`.
    temp28-supplierid = 6.
    temp28-unitsinstock = 29.
    temp28-unitsonorder = 7.
    temp28-unitprice = 35.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 9.
    temp28-productname = `Northwoods Cranberry Sauce`.
    temp28-supplierid = 6.
    temp28-unitsinstock = 4.
    temp28-unitsonorder = 32.
    temp28-unitprice = 35.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 10.
    temp28-productname = `Mishi Kobe Niku`.
    temp28-supplierid = 5.
    temp28-unitsinstock = 40.
    temp28-unitsonorder = 5.
    temp28-unitprice = 130.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 11.
    temp28-productname = `Ikura`.
    temp28-supplierid = 4.
    temp28-unitsinstock = 4.
    temp28-unitsonorder = 10.
    temp28-unitprice = 13.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 13.
    temp28-productname = `Carnarvon Tigers`.
    temp28-supplierid = 3.
    temp28-unitsinstock = 36.
    temp28-unitsonorder = 40.
    temp28-unitprice = 56.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 14.
    temp28-productname = `Teatime Chocolate Biscuits`.
    temp28-supplierid = 2.
    temp28-unitsinstock = 21.
    temp28-unitsonorder = 40.
    temp28-unitprice = 7.
    temp28-discontinued = abap_false.
    INSERT temp28 INTO TABLE temp27.
    temp28-productid = 15.
    temp28-productname = `Alice Mutton`.
    temp28-supplierid = 2.
    temp28-unitsinstock = 90.
    temp28-unitsonorder = 20.
    temp28-unitprice = 75.
    temp28-discontinued = abap_true.
    INSERT temp28 INTO TABLE temp27.
    t_products = temp27.

    " localService/mockdata/Suppliers.json - the rows the expand joins in
    
    CLEAR temp29.
    
    temp30-supplierid = 1.
    temp30-companyname = `New Orleans Cajun Delights`.
    temp30-address = `P.O. Box 78934`.
    temp30-postalcode = `70117`.
    temp30-city = `New Orleans`.
    temp30-country = `USA`.
    INSERT temp30 INTO TABLE temp29.
    temp30-supplierid = 2.
    temp30-companyname = `Exotic Liquids`.
    temp30-address = `49 Gilbert St.`.
    temp30-postalcode = `EC1 4SD`.
    temp30-city = `London`.
    temp30-country = `UK`.
    INSERT temp30 INTO TABLE temp29.
    temp30-supplierid = 3.
    temp30-companyname = `Grandma Kelly's Homestead`.
    temp30-address = `707 Oxford Rd.`.
    temp30-postalcode = `48104`.
    temp30-city = `Ann Arbor`.
    temp30-country = `USA`.
    INSERT temp30 INTO TABLE temp29.
    temp30-supplierid = 4.
    temp30-companyname = `Forêts d'érables`.
    temp30-address = `148 rue Chasseur`.
    temp30-postalcode = `J2S 7S8`.
    temp30-city = `Ste-Hyacinthe`.
    temp30-country = `Canada`.
    INSERT temp30 INTO TABLE temp29.
    temp30-supplierid = 5.
    temp30-companyname = `Plutzer Lebensmittelgroßmärkte AG`.
    temp30-address = `Bogenallee 51`.
    temp30-postalcode = `60439`.
    temp30-city = `Frankfurt`.
    temp30-country = `Germany`.
    INSERT temp30 INTO TABLE temp29.
    temp30-supplierid = 6.
    temp30-companyname = `Lyngbysild`.
    temp30-address = `Lyngbysild Fiskebakken 10`.
    temp30-postalcode = `2800`.
    temp30-city = `Lyngby`.
    temp30-country = `Denmark`.
    INSERT temp30 INTO TABLE temp29.
    temp30-supplierid = 7.
    temp30-companyname = `Formaggi Fortini s.r.l.`.
    temp30-address = `Viale Dante, 75`.
    temp30-postalcode = `48100`.
    temp30-city = `Ravenna`.
    temp30-country = `Italy`.
    INSERT temp30 INTO TABLE temp29.
    t_suppliers = temp29.

  ENDMETHOD.

ENDCLASS.
