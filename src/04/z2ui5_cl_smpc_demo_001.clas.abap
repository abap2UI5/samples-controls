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

    DATA t_rows            TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
    DATA t_comments        TYPE STANDARD TABLE OF ty_s_comment WITH DEFAULT KEY.
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
    DATA t_products    TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
    DATA t_suppliers   TYPE STANDARD TABLE OF ty_s_supplier WITH DEFAULT KEY.
    " the productFeedback model: every comment, of every product
    DATA t_feedback    TYPE STANDARD TABLE OF ty_s_comment WITH DEFAULT KEY.
    " the table's remembered selection (rememberSelections), rows a quick
    " filter or the search hides included
    DATA t_selected    TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
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
      DATA temp1 TYPE string_table.

    me->client = client.

    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      list_refresh( ).
      view_display( ).
      " index.html's <title>
      
      CLEAR temp1.
      INSERT `Manage Products` INTO TABLE temp1.
      client->follow_up_action( val   = client->cs_event-set_title
                                t_arg = temp1 ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA app TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp3 TYPE string_table.

    " the router's initialize( ): the live hash rides in s_config-hash on
    " every request, so a reload or a shared link starts on the page its hash
    " names - the App opens on it (initialPage)
    page = route_match( ).

    
    view = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock`   v = `true`
            )->a( n = `xmlns`          v = `sap.m`
            )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
            )->a( n = `xmlns:core`     v = `sap.ui.core`
            )->a( n = `xmlns:semantic` v = `sap.f.semantic`
            )->a( n = `xmlns:form`     v = `sap.ui.layout.form`
            )->a( n = `xmlns:l`        v = `sap.ui.layout` ).

    " App.view.xml - the router's controlId "app", aggregation "pages"
    
    app = view->ele( `Shell`
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
    
    CLEAR temp3.
    INSERT `HASH_CHANGED` INTO TABLE temp3.
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = temp3 ).

  ENDMETHOD.


  METHOD page_worklist.

    " Worklist.view.xml
    DATA worklist TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    worklist = parent->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`                       v = `worklist`
        )->a( n = `headerPinnable`           b = abap_false
        )->a( n = `toggleHeaderOnTitleClick` b = abap_false
        )->a( n = `showFooter`               b = abap_true ).

    worklist->ele( n = `titleHeading` ns = `semantic`
        )->tag( `Title`
            )->a( n = `text` v = `Manage Products` ).

    " onQuickFilter: the tab's key is the Control filter of the list binding
    
    table = worklist->ele( n = `headerContent` ns = `semantic`
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
    DATA object TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA header TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA body TYPE REF TO z2ui5_cl_ui5_view_builder.
    object = parent->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`                       v = `object`
        )->a( n = `headerPinnable`           b = abap_false
        )->a( n = `toggleHeaderOnTitleClick` b = abap_false ).

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
            )->a( n = `displayValue` v = client->_bind( obj_units_display )
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
        DATA temp5 TYPE i.
        DATA temp1 TYPE string.
        DATA temp6 TYPE z2ui5_cl_smpc_demo_001=>ty_s_comment.

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
        
        temp5 = client->get_event_arg( ).
        
        IF object_bind( temp5 ) = abap_true.
          temp1 = `object`.
        ELSE.
          temp1 = `objectNotFound`.
        ENDIF.
        page_to( temp1 ).

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
        
        CLEAR temp6.
        temp6-productid = product_shown.
        temp6-type = `Comment`.
        temp6-date = date_medium( ).
        temp6-comment = client->get_event_arg( ).
        INSERT temp6 INTO TABLE t_feedback.
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
    DATA done TYPE i.
    DATA row LIKE LINE OF t_rows.
        FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_demo_001=>ty_s_product.
    DATA temp7 TYPE string.
    done = 0.
    
    LOOP AT t_rows INTO row WHERE selected = abap_true.
      IF client->get_event( ) = `REORDER`.
        
        READ TABLE t_products WITH KEY productid = row-productid ASSIGNING <product>.
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
    
    IF client->get_event( ) = `REORDER`.
      temp7 = `Product stock level updated`.
    ELSE.
      temp7 = `Product removed`.
    ENDIF.
    client->message_toast_display( temp7 ).

  ENDMETHOD.


  METHOD route_match.

    " the manifest's routes: "" is the worklist, "Products/{objectId}" the
    " object - crossroads matches the pattern case-insensitively - and
    " anything else the bypassed target notFound
    DATA hash TYPE string.
    DATA segments TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    FIELD-SYMBOLS <temp8> LIKE LINE OF segments.
    DATA temp9 LIKE sy-tabix.
    DATA id LIKE LINE OF segments.
    FIELD-SYMBOLS <temp2> LIKE LINE OF segments.
    DATA temp3 LIKE sy-tabix.
    DATA temp10 TYPE i.
    hash = app_hash( ).
    IF hash IS INITIAL.
      result = `worklist`.
      RETURN.
    ENDIF.

    
    SPLIT hash AT `/` INTO TABLE segments.
    
    
    temp9 = sy-tabix.
    READ TABLE segments INDEX 1 ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF lines( segments ) <> 2 OR to_upper( <temp8> ) <> `PRODUCTS`.
      result = `notFound`.
      RETURN.
    ENDIF.

    " _onObjectMatched binds /Products(<id>); _onBindingChange displays the
    " target objectNotFound when that entity does not exist (the conditions
    " short-circuit, so only a number that fits reaches CONV i)
    
    
    
    temp3 = sy-tabix.
    READ TABLE segments INDEX 2 ASSIGNING <temp2>.
    sy-tabix = temp3.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    id = <temp2>.
    result = `objectNotFound`.
    
    temp10 = id.
    IF id CO `0123456789` AND strlen( id ) <= 9 AND object_bind( temp10 ) = abap_true.
      result = `object`.
    ENDIF.

  ENDMETHOD.


  METHOD app_hash.

    " the part of the URL hash the app's own routes live in: behind a
    " launchpad's shell hash (`<intent>&/`) and behind abap2UI5's own
    " segments (`/z2ui5-xapp-state=<id>`, `/app/<class>/<draft>`), without
    " the slashes around it - `#/Products/1` reads `Products/1`
    DATA get TYPE z2ui5_if_client=>ty_s_get.
    DATA hash LIKE get-s_config-hash.
    DATA shell TYPE i.
    DATA segments TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    FIELD-SYMBOLS <temp11> LIKE LINE OF segments.
    DATA temp12 LIKE sy-tabix.
    FIELD-SYMBOLS <temp13> LIKE LINE OF segments.
    DATA temp14 LIKE sy-tabix.
      FIELD-SYMBOLS <temp15> LIKE LINE OF segments.
      DATA temp16 LIKE sy-tabix.
    get = client->get( ).
    
    hash = get-s_config-hash.
    SHIFT hash LEFT DELETING LEADING `#`.
    
    shell = find( val = hash sub = `&/` ).
    IF shell >= 0.
      hash = substring( val = hash off = shell + 2 ).
    ELSEIF get-check_launchpad_active = abap_true.
      hash = ``.
    ENDIF.
    IF hash IS INITIAL.
      RETURN.
    ENDIF.

    
    SPLIT hash AT `/` INTO TABLE segments.
    DELETE segments WHERE table_line IS INITIAL.
    
    
    temp12 = sy-tabix.
    READ TABLE segments INDEX 1 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF segments IS NOT INITIAL AND <temp11> CP `z2ui5-xapp-state=*`.
      DELETE segments INDEX 1.
    ENDIF.
    
    
    temp14 = sy-tabix.
    READ TABLE segments INDEX 1 ASSIGNING <temp13>.
    sy-tabix = temp14.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    IF lines( segments ) >= 2 AND <temp13> = `app`.
      DELETE segments FROM 1 TO 2.
      
      
      temp16 = sy-tabix.
      READ TABLE segments INDEX 1 ASSIGNING <temp15>.
      sy-tabix = temp16.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      IF segments IS NOT INITIAL AND strlen( <temp15> ) = 32.
        DELETE segments INDEX 1.
      ENDIF.
    ENDIF.

    result = concat_lines_of( table = segments sep = `/` ).

  ENDMETHOD.


  METHOD page_to.
    DATA temp17 TYPE string_table.

    " the target's display( ): the App navigates to the target's page
    IF target = page.
      RETURN.
    ENDIF.
    page = target.
    
    CLEAR temp17.
    INSERT `app` INTO TABLE temp17.
    INSERT `to` INTO TABLE temp17.
    INSERT target INTO TABLE temp17.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp17 ).

  ENDMETHOD.


  METHOD object_bind.

    " the object view's bindElement( /Products(<id>) ) with the expanded
    " supplier, through the formatters
    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_demo_001=>ty_s_product.
    FIELD-SYMBOLS <supplier> TYPE z2ui5_cl_smpc_demo_001=>ty_s_supplier.
    READ TABLE t_products WITH KEY productid = productid ASSIGNING <product>.
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
    
    READ TABLE t_suppliers WITH KEY supplierid = <product>-supplierid ASSIGNING <supplier>.
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
    DATA temp19 LIKE t_comments.
    DATA comment LIKE LINE OF t_feedback.
    CLEAR temp19.
    
    LOOP AT t_feedback INTO comment WHERE productid = product_shown.
      INSERT comment INTO TABLE temp19.
    ENDLOOP.
    t_comments = temp19.
    SORT t_comments STABLE BY date DESCENDING AS TEXT.

  ENDMETHOD.


  METHOD list_refresh.

    " declared here, not inline at the ASSIGN below, so it can be UNASSIGNed
    " before each one - see there
    FIELD-SYMBOLS <supplier> LIKE LINE OF t_suppliers.

    " rememberSelections: the rows on show carry the live selection, the
    " rows a filter hid keep theirs
    DATA row LIKE LINE OF t_rows.
    DATA temp21 LIKE t_rows.
    DATA product LIKE LINE OF t_products.
      DATA temp22 TYPE z2ui5_cl_smpc_demo_001=>ty_s_row.
      DATA temp4 TYPE z2ui5_cl_smpc_demo_001=>ty_s_row-suppliername.
      DATA temp5 LIKE sy-subrc.
      DATA temp1 TYPE xsdboolean.
    DATA temp23 TYPE string.
    DATA temp24 TYPE i.
    DATA n TYPE i.
    DATA p LIKE LINE OF t_products.
      DATA temp6 TYPE i.
    DATA temp25 TYPE i.
    DATA s TYPE i.
    DATA q LIKE LINE OF t_products.
      DATA temp7 TYPE i.
    DATA temp26 TYPE i.
    DATA o TYPE i.
    DATA r LIKE LINE OF t_products.
      DATA temp8 TYPE i.
    LOOP AT t_rows INTO row.
      DELETE t_selected WHERE table_line = row-productid.
      IF row-selected = abap_true.
        INSERT row-productid INTO TABLE t_selected.
      ENDIF.
    ENDLOOP.

    
    CLEAR temp21.
    t_rows = temp21.
    
    LOOP AT t_products INTO product.
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
      READ TABLE t_suppliers WITH KEY supplierid = product-supplierid ASSIGNING <supplier>.
      
      CLEAR temp22.
      temp22-productid = product-productid.
      temp22-productname = product-productname.
      
      IF <supplier> IS ASSIGNED.
        temp4 = <supplier>-companyname.
      ELSE.
        CLEAR temp4.
      ENDIF.
      temp22-suppliername = temp4.
      temp22-unitprice_text = number_unit( product-unitprice ).
      temp22-unitsonorder_text = number_unit( product-unitsonorder ).
      temp22-unitsinstock_text = number_unit( product-unitsinstock ).
      temp22-unitsinstock_state = quantity_state( product-unitsinstock ).
      
      READ TABLE t_selected WITH KEY table_line = product-productid TRANSPORTING NO FIELDS.
      temp5 = sy-subrc.
      
      temp1 = boolc( temp5 = 0 ).
      temp22-selected = temp1.
      INSERT temp22 INTO TABLE t_rows.
    ENDLOOP.

    " the sorter on ProductName ascending - the mock server's $orderby, which
    " compares code points
    SORT t_rows BY productname.

    " onUpdateFinished: the title counts the rows on show, the four $count
    " reads count the whole stock
    
    IF t_rows IS INITIAL.
      temp23 = `ProductsPlural`.
    ELSE.
      temp23 = |Products ({ lines( t_rows ) })|.
    ENDIF.
    table_title      = temp23.
    count_all        = |{ lines( t_products ) }|.
    
    
    n = 0.
    
    LOOP AT t_products INTO p.
      
      IF p-unitsinstock > 10.
        temp6 = n + 1.
      ELSE.
        temp6 = n.
      ENDIF.
      n = temp6.
    ENDLOOP.
    temp24 = n.
    count_instock    = |{ temp24 }|.
    
    
    s = 0.
    
    LOOP AT t_products INTO q.
      
      IF q-unitsinstock BETWEEN 1 AND 10.
        temp7 = s + 1.
      ELSE.
        temp7 = s.
      ENDIF.
      s = temp7.
    ENDLOOP.
    temp25 = s.
    count_shortage   = |{ temp25 }|.
    
    
    o = 0.
    
    LOOP AT t_products INTO r.
      
      IF r-unitsinstock <= 0.
        temp8 = o + 1.
      ELSE.
        temp8 = o.
      ENDIF.
      o = temp8.
    ENDLOOP.
    temp26 = o.
    count_outofstock = |{ temp26 }|.

  ENDMETHOD.


  METHOD share_email.

    " BaseController.onShareEmailPress: URLHelper.triggerEmail( null, subject,
    " body ) - the body ends in location.href after a "\r\n", which the
    " URLHELPER action refuses, so a space stands in for it
    DATA config TYPE z2ui5_if_client=>ty_s_get-s_config.
    DATA href TYPE string.
    DATA temp27 TYPE string_table.
    DATA temp9 LIKE LINE OF temp27.
    config = client->get( )-s_config.
    
    href = config-origin && config-pathname && config-search && config-hash.
    
    CLEAR temp27.
    INSERT `TRIGGER_EMAIL` INTO TABLE temp27.
    
    temp9 = |\{"SUBJECT":"{ json_text( subject ) }","BODY":"{ json_text( |{ body } { href }| ) }"\}|.
    INSERT temp9 INTO TABLE temp27.
    client->follow_up_action( val   = client->cs_event-urlhelper
                              t_arg = temp27 ).

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
    DATA date LIKE sy-datlo.
    DATA time LIKE sy-timlo.
    DATA temp29 TYPE i.
    DATA hour LIKE temp29.
    DATA hour12 TYPE i.
    DATA temp30 TYPE i.
    DATA month TYPE string.
    DATA temp31 TYPE i.
    DATA temp10 TYPE string.
    date = sy-datlo.
    
    time = sy-timlo.
    
    temp29 = time(2).
    
    hour = temp29.
    
    hour12 = hour MOD 12.
    IF hour12 = 0.
      hour12 = 12.
    ENDIF.
    
    temp30 = date+4(2).
    
    month = substring( val = `JanFebMarAprMayJunJulAugSepOctNovDec` off = ( temp30 - 1 ) * 3 len = 3 ).
    
    temp31 = date+6(2).
    
    IF hour < 12.
      temp10 = `AM`.
    ELSE.
      temp10 = `PM`.
    ENDIF.
    result = |{ month } { temp31 }, { date(4) }, { hour12 }:{ time+2(2) }:{ time+4(2) } { temp10 }|.

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
    DATA temp32 TYPE string.
    IF val = 0.
      temp32 = `Error`.
    ELSEIF val <= 10.
      temp32 = `Warning`.
    ELSE.
      temp32 = `Success`.
    ENDIF.
    result = temp32.

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Products.json - the full row set, verbatim
    DATA temp33 LIKE t_products.
    DATA temp34 LIKE LINE OF temp33.
    DATA temp35 LIKE t_suppliers.
    DATA temp36 LIKE LINE OF temp35.
    CLEAR temp33.
    
    temp34-productid = 1.
    temp34-productname = `Chai`.
    temp34-supplierid = 1.
    temp34-unitsinstock = 39.
    temp34-unitsonorder = 10.
    temp34-unitprice = 8.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 2.
    temp34-productname = `Chang`.
    temp34-supplierid = 1.
    temp34-unitsinstock = 81.
    temp34-unitsonorder = 7.
    temp34-unitprice = 6.
    temp34-discontinued = abap_true.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 3.
    temp34-productname = `Aniseed Syrup`.
    temp34-supplierid = 3.
    temp34-unitsinstock = 100.
    temp34-unitsonorder = 6.
    temp34-unitprice = 3.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 4.
    temp34-productname = `Schwarzwälder Kirschtorte`.
    temp34-supplierid = 3.
    temp34-unitsinstock = 2.
    temp34-unitsonorder = 3.
    temp34-unitprice = 19.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 5.
    temp34-productname = `Chef Anton's Cajun Seasoning`.
    temp34-supplierid = 3.
    temp34-unitsinstock = 11.
    temp34-unitsonorder = 9.
    temp34-unitprice = 108.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 6.
    temp34-productname = `Chef Anton's Gumbo Mix`.
    temp34-supplierid = 4.
    temp34-unitsinstock = 21.
    temp34-unitsonorder = 12.
    temp34-unitprice = 18.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 7.
    temp34-productname = `Grandma's Boysenberry Spread`.
    temp34-supplierid = 5.
    temp34-unitsinstock = 25.
    temp34-unitsonorder = 25.
    temp34-unitprice = 18.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 8.
    temp34-productname = `Uncle Bob's Organic Dried Pears`.
    temp34-supplierid = 6.
    temp34-unitsinstock = 29.
    temp34-unitsonorder = 7.
    temp34-unitprice = 35.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 9.
    temp34-productname = `Northwoods Cranberry Sauce`.
    temp34-supplierid = 6.
    temp34-unitsinstock = 4.
    temp34-unitsonorder = 32.
    temp34-unitprice = 35.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 10.
    temp34-productname = `Mishi Kobe Niku`.
    temp34-supplierid = 5.
    temp34-unitsinstock = 40.
    temp34-unitsonorder = 5.
    temp34-unitprice = 130.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 11.
    temp34-productname = `Ikura`.
    temp34-supplierid = 4.
    temp34-unitsinstock = 4.
    temp34-unitsonorder = 10.
    temp34-unitprice = 13.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 13.
    temp34-productname = `Carnarvon Tigers`.
    temp34-supplierid = 3.
    temp34-unitsinstock = 36.
    temp34-unitsonorder = 40.
    temp34-unitprice = 56.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 14.
    temp34-productname = `Teatime Chocolate Biscuits`.
    temp34-supplierid = 2.
    temp34-unitsinstock = 21.
    temp34-unitsonorder = 40.
    temp34-unitprice = 7.
    temp34-discontinued = abap_false.
    INSERT temp34 INTO TABLE temp33.
    temp34-productid = 15.
    temp34-productname = `Alice Mutton`.
    temp34-supplierid = 2.
    temp34-unitsinstock = 90.
    temp34-unitsonorder = 20.
    temp34-unitprice = 75.
    temp34-discontinued = abap_true.
    INSERT temp34 INTO TABLE temp33.
    t_products = temp33.

    " localService/mockdata/Suppliers.json - the rows the expand joins in
    
    CLEAR temp35.
    
    temp36-supplierid = 1.
    temp36-companyname = `New Orleans Cajun Delights`.
    temp36-address = `P.O. Box 78934`.
    temp36-postalcode = `70117`.
    temp36-city = `New Orleans`.
    temp36-country = `USA`.
    INSERT temp36 INTO TABLE temp35.
    temp36-supplierid = 2.
    temp36-companyname = `Exotic Liquids`.
    temp36-address = `49 Gilbert St.`.
    temp36-postalcode = `EC1 4SD`.
    temp36-city = `London`.
    temp36-country = `UK`.
    INSERT temp36 INTO TABLE temp35.
    temp36-supplierid = 3.
    temp36-companyname = `Grandma Kelly's Homestead`.
    temp36-address = `707 Oxford Rd.`.
    temp36-postalcode = `48104`.
    temp36-city = `Ann Arbor`.
    temp36-country = `USA`.
    INSERT temp36 INTO TABLE temp35.
    temp36-supplierid = 4.
    temp36-companyname = `Forêts d'érables`.
    temp36-address = `148 rue Chasseur`.
    temp36-postalcode = `J2S 7S8`.
    temp36-city = `Ste-Hyacinthe`.
    temp36-country = `Canada`.
    INSERT temp36 INTO TABLE temp35.
    temp36-supplierid = 5.
    temp36-companyname = `Plutzer Lebensmittelgroßmärkte AG`.
    temp36-address = `Bogenallee 51`.
    temp36-postalcode = `60439`.
    temp36-city = `Frankfurt`.
    temp36-country = `Germany`.
    INSERT temp36 INTO TABLE temp35.
    temp36-supplierid = 6.
    temp36-companyname = `Lyngbysild`.
    temp36-address = `Lyngbysild Fiskebakken 10`.
    temp36-postalcode = `2800`.
    temp36-city = `Lyngby`.
    temp36-country = `Denmark`.
    INSERT temp36 INTO TABLE temp35.
    temp36-supplierid = 7.
    temp36-companyname = `Formaggi Fortini s.r.l.`.
    temp36-address = `Viale Dante, 75`.
    temp36-postalcode = `48100`.
    temp36-city = `Ravenna`.
    temp36-country = `Italy`.
    INSERT temp36 INTO TABLE temp35.
    t_suppliers = temp35.

  ENDMETHOD.

ENDCLASS.
