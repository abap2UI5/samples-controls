" @keywords manage products app title icontabbar icontabfilter icontabseparator table toolbar toolbarspacer searchfield column
" @summary Created with the 'Worklist App' tutorial. - the UI5 demo app "Manage Products", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Manage Products (sap.m/tutorial/worklist) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Manage Products</p>
"!
"! The UI5 demo app Manage Products (the "Worklist App" tutorial, step 07) -
"! a whole application rather than a control sample, rebuilt as ONE abap2UI5
"! class, page for page and control for control: the worklist with its quick
"! filters and their counts, the case-sensitive search, the multi-selection
"! and the two mass actions with their MessageBox and MessageToasts, the
"! object page with the supplier form and the comments feed, the share
"! menu's e-mail on both pages, and the two not-found pages. The original's
"! App and its router are kept: the four targets of its manifest.json are
"! the four pages of one App here, and the URL hash decides which one shows
"! - "" is the worklist, "Products/{objectId}" the object page (or the
"! object-not-found page for an id the stock does not hold), anything else
"! the router's bypassed not-found page. Opening a product and the "Show
"! Manage Products" button push a hash as navTo( ) does, so the browser Back
"! button, a reload and a deep link work the way the original's router makes
"! them work.
"!
"! Texts are the original's i18n.properties, resolved in English. Two of its
"! keys are missing from its own bundle (the view binds
"! i18n>TableNameColumnTitle, the bundle carries tableNameColumnTitle; the
"! controller asks for TableSelectProduct, the bundle carries
"! TableNoProductsSelected), so the demo kit shows the raw key in the name
"! column header and in the no-selection MessageBox - and so does this class.
"!
"! Where it differs from the original, and why - only what an app without a
"! browser-side model layer cannot do the same way:
"!
"!  - the OData V2 service and its mock server become ABAP data: the 14
"!    products and 7 suppliers of the mock, verbatim, with the supplier joined
"!    into the row as the original's expand does. Filtering, searching,
"!    sorting and the four $count reads run in ABAP with the mock server's
"!    semantics: a case-sensitive substringof on ProductName, the
"!    code-point order of $orderby. The table remembers the selection of rows
"!    a filter hides, as its rememberSelections does, while the mass actions
"!    act on the rows on show, as getSelectedItems( ) does.
"!  - the formatter module (numberUnit, quantityState) is business logic and
"!    moves to the backend with it - the view binds the finished text and the
"!    finished ValueState.
"!  - a posted comment is stamped by the server clock in the user's time zone
"!    (sy-datlo/sy-timlo) in the en medium DateTimeFormat ("Sep 24, 2026,
"!    9:05:30 AM") where the original formats the browser clock; the CLDR
"!    pattern puts a narrow no-break space before AM/PM, this a plain one.
"!  - the not-found pages show an IllustratedMessage, @since 1.98, and a Page
"!    titleAlignment, @since 1.72, where this package holds the 1.71 floor.
"!    The 1.71 equivalent is built instead: the same Page, HBox and button,
"!    with an icon, the illustration type's default title ("Sorry, we can't
"!    find this page") and the description in a centered VBox; the page
"!    title is centered on the 1.71 themes and follows the theme on newer
"!    ones.
"!  - the share menu's e-mail goes through abap2UI5's URLHELPER action,
"!    which is sap.m.URLHelper.triggerEmail itself, with the original's
"!    subject and body and the page's location.href. That action refuses a
"!    CR/LF in a parameter, so the "\r\n" of the body text is a space here;
"!    the worklist's href is read when the e-mail is sent, not when the
"!    worklist was first created.
"!  - the busy handling (busyIndicatorDelay, the app and object view models'
"!    busy flags) and the ErrorHandler's service-error MessageBox have
"!    nothing to wait for or to fail: the data is already on the server.
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

    DATA t_rows            TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA t_comments        TYPE STANDARD TABLE OF ty_s_comment WITH EMPTY KEY.
    " the worklistView model of the original
    DATA filter_key        TYPE string VALUE `all`.
    DATA table_title       TYPE string VALUE `ProductsPlural`.
    DATA table_no_data     TYPE string VALUE `No ProductsPlural are currently available`.
    DATA count_all         TYPE string VALUE `0`.
    DATA count_instock     TYPE string VALUE `0`.
    DATA count_shortage    TYPE string VALUE `0`.
    DATA count_outofstock  TYPE string VALUE `0`.
    " the bound product of the object page
    DATA obj_productname   TYPE string.
    DATA obj_productid     TYPE string.
    DATA obj_unitprice     TYPE string.
    DATA obj_unitsinstock  TYPE string.
    DATA obj_units_display TYPE string.
    DATA obj_units_percent TYPE i.
    " ObjectNumber.state is enum-typed: an empty value is rejected outright
    " (validateProperty), so the worklist start carries the UI5 default until
    " a product is opened
    DATA obj_units_state   TYPE string VALUE `None`.
    DATA obj_discontinued  TYPE abap_bool.
    DATA obj_suppliername  TYPE string.
    DATA obj_address       TYPE string.
    DATA obj_postal_city   TYPE string.
    DATA obj_country       TYPE string.

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
    " the productFeedback model: every comment, of every product
    DATA t_feedback    TYPE STANDARD TABLE OF ty_s_comment WITH EMPTY KEY.
    " the table's remembered selection (rememberSelections), rows a quick
    " filter or the search hides included
    DATA t_selected    TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    " the query of the last search event - the Application filter
    DATA search_query  TYPE string.
    DATA product_shown TYPE i.
    " the router target on show - the id of its page in the App
    DATA page          TYPE string VALUE `worklist`.

    METHODS view_display.
    METHODS page_worklist
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_object
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_not_found
      IMPORTING
        parent       TYPE REF TO z2ui5_cl_ui5_view_builder
        id           TYPE string
        illustration TYPE string
        title        TYPE string
        description  TYPE string
        link         TYPE string.
    METHODS on_event.
    METHODS on_mass_action.
    METHODS route_match
      RETURNING
        VALUE(result) TYPE string.
    METHODS app_hash
      RETURNING
        VALUE(result) TYPE string.
    METHODS page_to
      IMPORTING
        target TYPE string.
    METHODS object_bind
      IMPORTING
        productid     TYPE i
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS comments_refresh.
    METHODS list_refresh.
    METHODS share_email
      IMPORTING
        subject TYPE string
        body    TYPE string.
    METHODS json_text
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS date_medium
      RETURNING
        VALUE(result) TYPE string.
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
      " index.html's <title>
      client->follow_up_action( val   = client->cs_event-set_title
                                t_arg = VALUE #( ( `Manage Products` ) ) ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " the router's initialize( ): the live hash rides in s_config-hash on
    " every request, so a reload or a shared link starts on the page its hash
    " names - the App opens on it (initialPage)
    page = route_match( ).

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock`   v = `true`
            )->a( n = `xmlns`          v = `sap.m`
            )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
            )->a( n = `xmlns:core`     v = `sap.ui.core`
            )->a( n = `xmlns:semantic` v = `sap.f.semantic`
            )->a( n = `xmlns:form`     v = `sap.ui.layout.form`
            )->a( n = `xmlns:l`        v = `sap.ui.layout` ).

    " App.view.xml - the router's controlId "app", aggregation "pages"
    DATA(app) = view->ele( `Shell`
        )->ele( `App`
            )->a( n = `id`          v = `app`
            )->a( n = `initialPage` v = page ).

    page_worklist( app ).
    page_object( app ).
    page_not_found( parent       = app
                    id           = `objectNotFound`
                    illustration = `objectNotFoundIllustration`
                    title        = `Products`
                    description  = `This Product is not available`
                    link         = `linkObject` ).
    page_not_found( parent       = app
                    id           = `notFound`
                    illustration = `notFoundIllustration`
                    title        = `Not Found`
                    description  = `The requested resource was not found`
                    link         = `link` ).

    client->view_display( view->stringify( ) ).

    " hash changes the app did not write itself - the browser Back/Forward
    " buttons, a hand-edited URL - round-trip as HASH_CHANGED. Registered per
    " render, since the registration dies with an app switch
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = VALUE #( ( `HASH_CHANGED` ) ) ).

  ENDMETHOD.


  METHOD page_worklist.

    " Worklist.view.xml
    DATA(worklist) = parent->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`                       v = `worklist`
        )->a( n = `headerPinnable`           b = abap_false
        )->a( n = `toggleHeaderOnTitleClick` b = abap_false
        )->a( n = `showFooter`               b = abap_true ).

    worklist->ele( n = `titleHeading` ns = `semantic`
        )->tag( `Title`
            )->a( n = `text` v = `Manage Products` ).

    " onQuickFilter: the tab's key is the Control filter of the list binding
    DATA(table) = worklist->ele( n = `headerContent` ns = `semantic`
        )->ele( `IconTabBar`
            )->a( n = `id`          v = `iconTabBar`
            )->a( n = `select`      v = client->_event( `FILTER` )
            )->a( n = `expandable`  b = abap_false
            )->a( n = `selectedKey` v = client->_bind( filter_key )

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

    " onSearch: the query travels as the event's argument - the field is not
    " bound, as in the original, where nothing binds its value
    table->ele( `headerToolbar`
        )->ele( `Toolbar`
            )->tag( `Title`
                )->a( n = `id`   v = `tableHeader`
                )->a( n = `text` v = client->_bind( table_title )
            )->tag( `ToolbarSpacer`
            )->tag( `SearchField`
                )->a( n = `id`      v = `searchField`
                )->a( n = `tooltip` v = `Enter a Product name or a part of it.`
                )->a( n = `search`  v = client->_event( val = `SEARCH` arg = `${$parameters>/query}` )
                )->a( n = `width`   v = `auto` ).

    " the name column binds i18n>TableNameColumnTitle, a key the bundle does
    " not carry - the demo kit shows the key itself
    table->ele( `columns`
        )->ele( `Column`
            )->a( n = `id` v = `nameColumn`

            )->tag( `Text`
                )->a( n = `id`   v = `nameColumnTitle`
                )->a( n = `text` v = `TableNameColumnTitle`

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

    " onPress: navTo( "object", { objectId: ProductID } )
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
                    )->a( n = `number` v = `{UNITSONORDER_TEXT}`
                    )->a( n = `unit`   v = `PC`
                )->tag( `ObjectNumber`
                    )->a( n = `number` v = `{UNITSINSTOCK_TEXT}`
                    )->a( n = `unit`   v = `PC`
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

  ENDMETHOD.


  METHOD page_object.

    " Object.view.xml - no footer and no back button, as there: the way back
    " is the browser's Back button
    DATA(object) = parent->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`                       v = `object`
        )->a( n = `headerPinnable`           b = abap_false
        )->a( n = `toggleHeaderOnTitleClick` b = abap_false ).

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
            )->a( n = `displayValue` v = client->_bind( obj_units_display )
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

    " onPost: the FeedInput empties itself and hands over its value
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
            )->a( n = `press` v = client->_event( `SHARE_EMAIL_OBJECT` ) ).

  ENDMETHOD.


  METHOD page_not_found.

    " NotFound.view.xml and ObjectNotFound.view.xml. The IllustratedMessage
    " (@since 1.98) becomes its 1.71 equivalent: an icon for the
    " illustration, the PageNotFound type's default title, the description
    " and the additional content, centered in a VBox that takes the
    " IllustratedMessage's place and its FlexItemData
    parent->ele( `Page`
        )->a( n = `id`    v = id
        )->a( n = `title` v = title

        )->ele( `HBox`
            )->a( n = `height`     v = `100%`
            )->a( n = `alignItems` v = `Center`

            )->ele( `VBox`
                )->a( n = `id`             v = illustration
                )->a( n = `alignItems`     v = `Center`
                )->a( n = `justifyContent` v = `Center`

                )->ele( `layoutData`
                    )->tag( `FlexItemData`
                        )->a( n = `growFactor` v = `1`

                )->end(
                )->tag( n = `Icon` ns = `core`
                    )->a( n = `src`   v = `sap-icon://document`
                    )->a( n = `size`  v = `6rem`
                    )->a( n = `class` v = `sapUiMediumMarginBottom`
                )->tag( `Title`
                    )->a( n = `text`       v = `Sorry, we can’t find this page`
                    )->a( n = `titleStyle` v = `H2`
                    )->a( n = `textAlign`  v = `Center`
                    )->a( n = `wrapping`   b = abap_true
                )->tag( `Text`
                    )->a( n = `text`      v = description
                    )->a( n = `textAlign` v = `Center`
                    )->a( n = `class`     v = `sapUiSmallMarginTop`
                )->tag( `Button`
                    )->a( n = `id`    v = link
                    )->a( n = `text`  v = `Show Manage Products`
                    )->a( n = `press` v = client->_event( `SHOW_WORKLIST` )
                    )->a( n = `class` v = `sapUiSmallMarginTop` ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `FILTER`.
        " onQuickFilter: the list binding's filter( ), done where the data is
        list_refresh( ).

      WHEN `SEARCH`.
        " onSearch/_applySearch: a Contains filter on ProductName, or none for
        " an empty query; a real search swaps the no-data text for good
        search_query = client->get_event_arg( ).
        IF search_query IS NOT INITIAL.
          table_no_data = `No matching ProductsPlural found`.
        ENDIF.
        list_refresh( ).

      WHEN `SHOW`.
        " onPress: navTo( "object", { objectId } ) pushes the hash; the
        " route's patternMatched binds the page
        client->hash_set( |/Products/{ client->get_event_arg( ) }| ).
        page_to( COND #( WHEN object_bind( CONV i( client->get_event_arg( ) ) ) = abap_true
                         THEN `object`
                         ELSE `objectNotFound` ) ).

      WHEN `SHOW_WORKLIST`.
        " NotFound's onLinkPressed: navTo( "worklist" ) - a new history entry
        client->hash_set( `/` ).
        page_to( `worklist` ).

      WHEN `HASH_CHANGED`.
        " the router's hashChanged: show the target the hash now names
        page_to( route_match( ) ).

      WHEN `REORDER` OR `UNLIST`.
        on_mass_action( ).

      WHEN `POST`.
        " onPost: the entry lands in the productFeedback model
        INSERT VALUE #( productid = product_shown
                        type      = `Comment`
                        date      = date_medium( )
                        comment   = client->get_event_arg( ) ) INTO TABLE t_feedback.
        comments_refresh( ).

      WHEN `SHARE_EMAIL`.
        " onShareEmailPress with the worklistView model's two texts
        share_email( subject = `Email subject PLEASE REPLACE ACCORDING TO YOUR USE CASE`
                     body    = `Email body PLEASE REPLACE ACCORDING TO YOUR USE CASE` ).

      WHEN `SHARE_EMAIL_OBJECT`.
        " onShareEmailPress with the objectView model's two texts
        share_email( subject = |Email subject including object identifier PLEASE REPLACE ACCORDING TO YOUR USE CASE { product_shown }|
                     body    = |Email body PLEASE REPLACE ACCORDING TO YOUR USE CASE { obj_productname } (id: { product_shown })| ).

    ENDCASE.

  ENDMETHOD.


  METHOD on_mass_action.

    " onUpdateStockObjects / onUnlistObjects over getSelectedItems( ) - the
    " selected rows ON SHOW, so a selection a filter hides is not acted on
    DATA(done) = 0.
    LOOP AT t_rows INTO DATA(row) WHERE selected = abap_true.
      IF client->get_event( ) = `REORDER`.
        ASSIGN t_products[ productid = row-productid ] TO FIELD-SYMBOL(<product>).
        IF <product> IS ASSIGNED.
          <product>-unitsinstock = <product>-unitsinstock + 10.
          UNASSIGN <product>.
        ENDIF.
      ELSE.
        DELETE t_products WHERE productid = row-productid.
      ENDIF.
      done = done + 1.
    ENDLOOP.

    IF done = 0.
      " _showErrorMessage( getText( "TableSelectProduct" ) ) - a key the
      " bundle does not carry, so MessageBox.error shows the key
      client->message_box_display( text = `TableSelectProduct` type = `error` ).
      RETURN.
    ENDIF.

    " the table's refresh and its updateFinished: rows, title and counts;
    " the last request's handler toasts once
    list_refresh( ).
    client->message_toast_display( COND #( WHEN client->get_event( ) = `REORDER`
                                            THEN `Product stock level updated`
                                            ELSE `Product removed` ) ).

  ENDMETHOD.


  METHOD route_match.

    " the manifest's routes: "" is the worklist, "Products/{objectId}" the
    " object - crossroads matches the pattern case-insensitively - and
    " anything else the bypassed target notFound
    DATA(hash) = app_hash( ).
    IF hash IS INITIAL.
      result = `worklist`.
      RETURN.
    ENDIF.

    SPLIT hash AT `/` INTO TABLE DATA(segments).
    IF lines( segments ) <> 2 OR to_upper( segments[ 1 ] ) <> `PRODUCTS`.
      result = `notFound`.
      RETURN.
    ENDIF.

    " _onObjectMatched binds /Products(<id>); _onBindingChange displays the
    " target objectNotFound when that entity does not exist (the conditions
    " short-circuit, so only a number that fits reaches CONV i)
    DATA(id) = segments[ 2 ].
    result = `objectNotFound`.
    IF id CO `0123456789` AND strlen( id ) <= 9 AND object_bind( CONV i( id ) ) = abap_true.
      result = `object`.
    ENDIF.

  ENDMETHOD.


  METHOD app_hash.

    " the part of the URL hash the app's own routes live in: behind a
    " launchpad's shell hash (`<intent>&/`) and behind abap2UI5's own
    " segments (`/z2ui5-xapp-state=<id>`, `/app/<class>/<draft>`), without
    " the slashes around it - `#/Products/1` reads `Products/1`
    DATA(get) = client->get( ).
    DATA(hash) = get-s_config-hash.
    SHIFT hash LEFT DELETING LEADING `#`.
    DATA(shell) = find( val = hash sub = `&/` ).
    IF shell >= 0.
      hash = substring( val = hash off = shell + 2 ).
    ELSEIF get-check_launchpad_active = abap_true.
      hash = ``.
    ENDIF.
    IF hash IS INITIAL.
      RETURN.
    ENDIF.

    SPLIT hash AT `/` INTO TABLE DATA(segments).
    DELETE segments WHERE table_line IS INITIAL.
    IF segments IS NOT INITIAL AND segments[ 1 ] CP `z2ui5-xapp-state=*`.
      DELETE segments INDEX 1.
    ENDIF.
    IF lines( segments ) >= 2 AND segments[ 1 ] = `app`.
      DELETE segments FROM 1 TO 2.
      IF segments IS NOT INITIAL AND strlen( segments[ 1 ] ) = 32.
        DELETE segments INDEX 1.
      ENDIF.
    ENDIF.

    result = concat_lines_of( table = segments sep = `/` ).

  ENDMETHOD.


  METHOD page_to.

    " the target's display( ): the App navigates to the target's page
    IF target = page.
      RETURN.
    ENDIF.
    page = target.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `app` ) ( `to` ) ( target ) ) ).

  ENDMETHOD.


  METHOD object_bind.

    " the object view's bindElement( /Products(<id>) ) with the expanded
    " supplier, through the formatters
    ASSIGN t_products[ productid = productid ] TO FIELD-SYMBOL(<product>).
    IF <product> IS NOT ASSIGNED.
      RETURN.
    ENDIF.
    result = abap_true.

    product_shown     = productid.
    obj_productname   = <product>-productname.
    obj_productid     = number_unit( <product>-productid ).
    obj_unitprice     = |{ number_unit( <product>-unitprice ) } EUR|.
    obj_unitsinstock  = number_unit( <product>-unitsinstock ).
    obj_units_display = |{ <product>-unitsinstock }|.
    obj_units_percent = <product>-unitsinstock.
    obj_units_state   = quantity_state( <product>-unitsinstock ).
    obj_discontinued  = <product>-discontinued.

    CLEAR: obj_suppliername, obj_address, obj_postal_city, obj_country.
    ASSIGN t_suppliers[ supplierid = <product>-supplierid ] TO FIELD-SYMBOL(<supplier>).
    IF <supplier> IS ASSIGNED.
      obj_suppliername = <supplier>-companyname.
      obj_address      = <supplier>-address.
      obj_postal_city  = |{ <supplier>-postalcode } / { <supplier>-city }|.
      obj_country      = <supplier>-country.
    ENDIF.

    comments_refresh( ).

  ENDMETHOD.


  METHOD comments_refresh.

    " _onBindingChange filters the feed list on productID; its sorter orders
    " the date TEXT descending (localeCompare, equal texts in the order they
    " were posted)
    t_comments = VALUE #( FOR comment IN t_feedback WHERE ( productid = product_shown ) ( comment ) ).
    SORT t_comments STABLE BY date DESCENDING AS TEXT.

  ENDMETHOD.


  METHOD list_refresh.

    " declared here, not inline at the ASSIGN below, so it can be UNASSIGNed
    " before each one - see there
    FIELD-SYMBOLS <supplier> LIKE LINE OF t_suppliers.

    " rememberSelections: the rows on show carry the live selection, the
    " rows a filter hid keep theirs
    LOOP AT t_rows INTO DATA(row).
      DELETE t_selected WHERE table_line = row-productid.
      IF row-selected = abap_true.
        INSERT row-productid INTO TABLE t_selected.
      ENDIF.
    ENDLOOP.

    t_rows = VALUE #( ).
    LOOP AT t_products INTO DATA(product).
      " the Control filter of the quick filter tab
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

      " the Application filter of the search: the mock server's substringof,
      " case-sensitive
      IF search_query IS NOT INITIAL AND find( val = product-productname sub = search_query ) < 0.
        CONTINUE.
      ENDIF.

      " IS ASSIGNED, not sy-subrc (#1937: a SUCCESSFUL dynamic ASSIGN does not
      " reset sy-subrc on every release, so a product whose supplier IS in the
      " table lost its supplier name). UNASSIGN first because this sits in a
      " LOOP: a failed ASSIGN leaves the previous iteration's binding in place,
      " and IS ASSIGNED would then read TRUE - and print the WRONG supplier
      UNASSIGN <supplier>.
      ASSIGN t_suppliers[ supplierid = product-supplierid ] TO <supplier>.
      INSERT VALUE #( productid          = product-productid
                      productname        = product-productname
                      suppliername       = COND #( WHEN <supplier> IS ASSIGNED THEN <supplier>-companyname )
                      unitprice_text     = number_unit( product-unitprice )
                      unitsonorder_text  = number_unit( product-unitsonorder )
                      unitsinstock_text  = number_unit( product-unitsinstock )
                      unitsinstock_state = quantity_state( product-unitsinstock )
                      selected           = xsdbool( line_exists( t_selected[ table_line = product-productid ] ) ) ) INTO TABLE t_rows.
    ENDLOOP.

    " the sorter on ProductName ascending - the mock server's $orderby, which
    " compares code points
    SORT t_rows BY productname.

    " onUpdateFinished: the title counts the rows on show, the four $count
    " reads count the whole stock
    table_title      = COND #( WHEN t_rows IS INITIAL THEN `ProductsPlural` ELSE |Products ({ lines( t_rows ) })| ).
    count_all        = |{ lines( t_products ) }|.
    count_instock    = |{ REDUCE i( INIT n = 0 FOR p IN t_products NEXT n = COND #( WHEN p-unitsinstock > 10 THEN n + 1 ELSE n ) ) }|.
    count_shortage   = |{ REDUCE i( INIT s = 0 FOR q IN t_products NEXT s = COND #( WHEN q-unitsinstock BETWEEN 1 AND 10 THEN s + 1 ELSE s ) ) }|.
    count_outofstock = |{ REDUCE i( INIT o = 0 FOR r IN t_products NEXT o = COND #( WHEN r-unitsinstock <= 0 THEN o + 1 ELSE o ) ) }|.

  ENDMETHOD.


  METHOD share_email.

    " BaseController.onShareEmailPress: URLHelper.triggerEmail( null, subject,
    " body ) - the body ends in location.href after a "\r\n", which the
    " URLHELPER action refuses, so a space stands in for it
    DATA(config) = client->get( )-s_config.
    DATA(href) = config-origin && config-pathname && config-search && config-hash.
    client->follow_up_action( val   = client->cs_event-urlhelper
                              t_arg = VALUE #( ( `TRIGGER_EMAIL` )
                                               ( |\{"SUBJECT":"{ json_text( subject ) }","BODY":"{ json_text( |{ body } { href }| ) }"\}| ) ) ).

  ENDMETHOD.


  METHOD json_text.

    " a string as the inside of a JSON string literal
    result = val.
    REPLACE ALL OCCURRENCES OF `\` IN result WITH `\\`.
    REPLACE ALL OCCURRENCES OF `"` IN result WITH `\"`.

  ENDMETHOD.


  METHOD date_medium.

    " DateFormat.getDateTimeInstance( { style: "medium" } ) in English:
    " "MMM d, y, h:mm:ss a"
    DATA(date) = sy-datlo.
    DATA(time) = sy-timlo.
    DATA(hour) = CONV i( time(2) ).
    DATA(hour12) = hour MOD 12.
    IF hour12 = 0.
      hour12 = 12.
    ENDIF.
    DATA(month) = substring( val = `JanFebMarAprMayJunJulAugSepOctNovDec` off = ( CONV i( date+4(2) ) - 1 ) * 3 len = 3 ).
    result = |{ month } { CONV i( date+6(2) ) }, { date(4) }, { hour12 }:{ time+2(2) }:{ time+4(2) } { COND #( WHEN hour < 12 THEN `AM` ELSE `PM` ) }|.

  ENDMETHOD.


  METHOD number_unit.

    " the original's numberUnit formatter - "" for a falsy value, otherwise
    " parseFloat(value).toFixed(2). The mock carries whole numbers only, so
    " the two decimals are always the two zeros
    IF val = 0.
      result = ``.
      RETURN.
    ENDIF.
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
