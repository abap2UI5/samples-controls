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

    DATA t_rows             TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA t_comments         TYPE STANDARD TABLE OF ty_s_comment WITH EMPTY KEY.
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
    DATA t_products    TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_suppliers   TYPE STANDARD TABLE OF ty_s_supplier WITH EMPTY KEY.
    DATA t_feedback    TYPE STANDARD TABLE OF ty_s_comment WITH EMPTY KEY.
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

    IF client->check_on_init( ).
      model_init( ).
      list_refresh( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " a reload or a shared link: the live hash rides in s_config-hash on
    " every request, so a render whose hash already names a product starts on
    " the object page - the routeMatched of a cold start
    hash_apply( ).

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock`   v = `true`
            )->a( n = `xmlns`          v = `sap.m`
            )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
            )->a( n = `xmlns:semantic` v = `sap.f.semantic`
            )->a( n = `xmlns:form`     v = `sap.ui.layout.form`
            )->a( n = `xmlns:l`        v = `sap.ui.layout` ).

    DATA(nav) = view->ele( `Shell`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav` ).

    " ---------------------------------------------------------- worklist
    DATA(worklist) = nav->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`                       v = `page-worklist`
        )->a( n = `headerPinnable`           b = abap_false
        )->a( n = `toggleHeaderOnTitleClick` b = abap_false
        )->a( n = `showFooter`               b = abap_true ).

    worklist->ele( n = `titleHeading` ns = `semantic`
        )->tag( `Title`
            )->a( n = `text` v = `Manage Products` ).

    DATA(table) = worklist->ele( n = `headerContent` ns = `semantic`
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
    DATA(object) = nav->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`                       v = `page-object`
        )->a( n = `headerPinnable`           b = abap_false
        )->a( n = `toggleHeaderOnTitleClick` b = abap_false
        )->a( n = `showFooter`               b = abap_true ).

    object->ele( n = `titleHeading` ns = `semantic`
        )->tag( `Title`
            )->a( n = `text` v = client->_bind( obj_productname ) ).

    DATA(header) = object->ele( n = `headerContent` ns = `semantic`
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

    DATA(body) = object->ele( n = `content` ns = `semantic`
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
    object->ele( n = `footerCustomActions` ns = `semantic`
        )->tag( `Button`
            )->a( n = `text`  v = `Show Manage Products`
            )->a( n = `icon`  v = `sap-icon://nav-back`
            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-hash_back
                                                            t_arg = VALUE #( ( `/` ) ) ) ).

    client->view_display( view->stringify( ) ).

    " hash changes the app did not write itself - the browser Back/Forward
    " buttons, a hand-edited URL - round-trip as HASH_CHANGED. Registered per
    " render, since the registration dies with an app switch
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = VALUE #( ( `HASH_CHANGED` ) ) ).

    " a rebuilt NavContainer is back on its first page while the product on
    " show survives as class state - re-issue the page it should carry
    IF product_shown IS NOT INITIAL.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `nav` ) ( `to` ) ( `page-object` ) ) ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `FILTER` OR `SEARCH`.
        " the list binding's filter( ), done where the data is
        list_refresh( ).

      WHEN `SHOW`.
        " the router's navTo( "object", { objectId: ... } )
        object_show( CONV i( client->get_event_arg( ) ) ).

      WHEN `HASH_CHANGED`.
        " the router's routeMatched: show the page the hash now names
        hash_apply( ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `nav` )
                                                   ( `to` )
                                                   ( COND #( WHEN product_shown IS NOT INITIAL
                                                             THEN `page-object`
                                                             ELSE `page-worklist` ) ) ) ).

      WHEN `REORDER`.
        DATA(reordered) = 0.
        LOOP AT t_products REFERENCE INTO DATA(product).
          IF NOT line_exists( t_rows[ productid = product->productid selected = abap_true ] ).
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
        DATA(unlisted) = 0.
        LOOP AT t_rows INTO DATA(row) WHERE selected = abap_true.
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
        INSERT VALUE #( productid = product_shown
                        type      = `Comment`
                        date      = |{ sy-datum DATE = ISO } { sy-uzeit TIME = ISO }|
                        comment   = client->get_event_arg( ) ) INTO TABLE t_feedback.
        comments_refresh( ).

      WHEN `SHARE_EMAIL`.
        " what sap.m.URLHelper.triggerEmail does one layer down
        client->follow_up_action( val   = client->cs_event-open_new_tab
                                  t_arg = VALUE #( ( `mailto:?subject=Manage%20Products` ) ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD hash_apply.

    " '/Products/<id>' is the object page, everything else the worklist -
    " the two routes of the original's manifest
    DATA(hash) = client->get( )-s_config-hash.
    IF hash CS `/Products/`.
      DATA(id) = substring_after( val = hash sub = `/Products/` ).
      IF id CO `0123456789` AND id IS NOT INITIAL.
        object_show( CONV i( id ) ).
        RETURN.
      ENDIF.
    ENDIF.

    product_shown = 0.

  ENDMETHOD.


  METHOD object_show.

    ASSIGN t_products[ productid = productid ] TO FIELD-SYMBOL(<product>).
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

    ASSIGN t_suppliers[ supplierid = <product>-supplierid ] TO FIELD-SYMBOL(<supplier>).
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
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `nav` ) ( `to` ) ( `page-object` ) ) ).

  ENDMETHOD.


  METHOD comments_refresh.

    " the original filters the feed list on productID and sorts it by date,
    " newest first
    t_comments = VALUE #( ).
    LOOP AT t_feedback INTO DATA(comment) WHERE productid = product_shown.
      INSERT comment INTO t_comments INDEX 1.
    ENDLOOP.

  ENDMETHOD.


  METHOD list_refresh.

    DATA(shown) = 0.
    DATA(selection) = t_rows.
    t_rows = VALUE #( ).

    LOOP AT t_products INTO DATA(product).
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

      ASSIGN t_suppliers[ supplierid = product-supplierid ] TO FIELD-SYMBOL(<supplier>).
      INSERT VALUE #( productid          = product-productid
                      productname        = product-productname
                      suppliername       = COND #( WHEN sy-subrc = 0 THEN <supplier>-companyname )
                      unitprice_text     = number_unit( product-unitprice )
                      unitsonorder_text  = number_unit( product-unitsonorder )
                      unitsinstock_text  = number_unit( product-unitsinstock )
                      unitsinstock_state = quantity_state( product-unitsinstock )
                      selected           = xsdbool( line_exists( selection[ productid = product-productid selected = abap_true ] ) ) ) INTO TABLE t_rows.
      shown = shown + 1.
    ENDLOOP.

    " the original's list binding sorts by ProductName ascending
    SORT t_rows BY productname AS TEXT.

    " the four $count reads of the original, over the full stock
    count_all        = |{ lines( t_products ) }|.
    count_instock    = |{ REDUCE i( INIT n = 0 FOR p IN t_products NEXT n = COND #( WHEN p-unitsinstock > 10 THEN n + 1 ELSE n ) ) }|.
    count_shortage   = |{ REDUCE i( INIT s = 0 FOR q IN t_products NEXT s = COND #( WHEN q-unitsinstock BETWEEN 1 AND 10 THEN s + 1 ELSE s ) ) }|.
    count_outofstock = |{ REDUCE i( INIT o = 0 FOR r IN t_products NEXT o = COND #( WHEN r-unitsinstock <= 0 THEN o + 1 ELSE o ) ) }|.

    table_title   = COND #( WHEN shown = 0 THEN `ProductsPlural` ELSE |Products ({ shown })| ).
    table_no_data = COND #( WHEN search_term IS INITIAL
                            THEN `No ProductsPlural are currently available`
                            ELSE `No matching ProductsPlural found` ).

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
    result = COND #( WHEN val = 0 THEN `Error` WHEN val <= 10 THEN `Warning` ELSE `Success` ).

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Products.json - the full row set, verbatim
    t_products = VALUE #(
        ( productid = 1  productname = `Chai`                           supplierid = 1 unitsinstock = 39  unitsonorder = 10 unitprice = 8   discontinued = abap_false )
        ( productid = 2  productname = `Chang`                          supplierid = 1 unitsinstock = 81  unitsonorder = 7  unitprice = 6   discontinued = abap_true )
        ( productid = 3  productname = `Aniseed Syrup`                  supplierid = 3 unitsinstock = 100 unitsonorder = 6  unitprice = 3   discontinued = abap_false )
        ( productid = 4  productname = `Schwarzwälder Kirschtorte`      supplierid = 3 unitsinstock = 2   unitsonorder = 3  unitprice = 19  discontinued = abap_false )
        ( productid = 5  productname = `Chef Anton's Cajun Seasoning`   supplierid = 3 unitsinstock = 11  unitsonorder = 9  unitprice = 108 discontinued = abap_false )
        ( productid = 6  productname = `Chef Anton's Gumbo Mix`         supplierid = 4 unitsinstock = 21  unitsonorder = 12 unitprice = 18  discontinued = abap_false )
        ( productid = 7  productname = `Grandma's Boysenberry Spread`   supplierid = 5 unitsinstock = 25  unitsonorder = 25 unitprice = 18  discontinued = abap_false )
        ( productid = 8  productname = `Uncle Bob's Organic Dried Pears` supplierid = 6 unitsinstock = 29 unitsonorder = 7  unitprice = 35  discontinued = abap_false )
        ( productid = 9  productname = `Northwoods Cranberry Sauce`     supplierid = 6 unitsinstock = 4   unitsonorder = 32 unitprice = 35  discontinued = abap_false )
        ( productid = 10 productname = `Mishi Kobe Niku`                supplierid = 5 unitsinstock = 40  unitsonorder = 5  unitprice = 130 discontinued = abap_false )
        ( productid = 11 productname = `Ikura`                          supplierid = 4 unitsinstock = 4   unitsonorder = 10 unitprice = 13  discontinued = abap_false )
        ( productid = 13 productname = `Carnarvon Tigers`               supplierid = 3 unitsinstock = 36  unitsonorder = 40 unitprice = 56  discontinued = abap_false )
        ( productid = 14 productname = `Teatime Chocolate Biscuits`     supplierid = 2 unitsinstock = 21  unitsonorder = 40 unitprice = 7   discontinued = abap_false )
        ( productid = 15 productname = `Alice Mutton`                   supplierid = 2 unitsinstock = 90  unitsonorder = 20 unitprice = 75  discontinued = abap_true ) ).

    " localService/mockdata/Suppliers.json - the rows the expand joins in
    t_suppliers = VALUE #(
        ( supplierid = 1 companyname = `New Orleans Cajun Delights`        address = `P.O. Box 78934`            postalcode = `70117`   city = `New Orleans`   country = `USA` )
        ( supplierid = 2 companyname = `Exotic Liquids`                    address = `49 Gilbert St.`             postalcode = `EC1 4SD` city = `London`        country = `UK` )
        ( supplierid = 3 companyname = `Grandma Kelly's Homestead`         address = `707 Oxford Rd.`             postalcode = `48104`   city = `Ann Arbor`     country = `USA` )
        ( supplierid = 4 companyname = `Forêts d'érables`                  address = `148 rue Chasseur`           postalcode = `J2S 7S8` city = `Ste-Hyacinthe` country = `Canada` )
        ( supplierid = 5 companyname = `Plutzer Lebensmittelgroßmärkte AG` address = `Bogenallee 51`            postalcode = `60439`   city = `Frankfurt`     country = `Germany` )
        ( supplierid = 6 companyname = `Lyngbysild`                        address = `Lyngbysild Fiskebakken 10`  postalcode = `2800`    city = `Lyngby`        country = `Denmark` )
        ( supplierid = 7 companyname = `Formaggi Fortini s.r.l.`           address = `Viale Dante, 75`            postalcode = `48100`   city = `Ravenna`       country = `Italy` ) ).

  ENDMETHOD.

ENDCLASS.
