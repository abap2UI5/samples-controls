" @keywords browse orders app flexiblecolumnlayout viewsettingsdialog viewsettingsfilteritem viewsettingsitem title list toolbar overflowtoolbar searchfield
" @summary Master-detail app for browsing orders. - the UI5 demo app "Browse Orders", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Browse Orders (sap.m/orderbrowser) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Browse Orders</p>
"!
"! The UI5 demo app Browse Orders - the master-detail showcase of the demo kit
"! - rebuilt as ONE abap2UI5 class, view for view and control for control:
"! the FlexibleColumnLayout with the order list in the begin column and the
"! order in the mid column, the search, the ViewSettingsDialog that filters
"! and groups (with its group order), the info bar, the line-item table with
"! its totals, the shipping and processor tabs, the share, close and full
"! screen actions, and the NotFound and DetailObjectNotFound pages.
"!
"! The original's router is kept, and so is its URL: the app owns the hash
"! (cs_event-hash_attach_changed) and route_hash( ) matches it against the
"! patterns of manifest.json - "" is the master route,
"! "Orders/{objectId}/:?query:" the object route, anything else is bypassed
"! to NotFound. Each route shows the same pages in the same columns and sets
"! the layouts the route-matched handlers set. navTo is hash_set( ) or - where
"! the original passes bReplace - hash_replace( ): a selection replaces the
"! hash on a desktop and pushes it on a phone, a tab switch replaces it, an
"! object route without a valid ?tab= is rewritten to tab=shipping, and the
"! Back buttons of the not-found pages are onNavBack (cs_event-hash_back,
"! falling back to the master route when the app has no history of its own).
"!
"! Where it differs from the original, and why - only what an app without a
"! browser-side model layer cannot do the same way:
"!
"!  - the OData V2 service and its mock server become ABAP data - the five
"!    mock files verbatim, the Edm.DateTime values as the epoch milliseconds
"!    the mock carries. What the service does is done where the data is,
"!    with the mock server's semantics: the search is its case-sensitive
"!    substringof on the order's own CustomerName (so order 3115, whose
"!    CustomerName the mock leaves empty, is never found), the two filters
"!    are ShippedDate ne/eq null, and the list's sort order is the one the
"!    binding asks for - OrderID descending until the dialog is first
"!    confirmed, then the grouper's sorter (a stable sort on Customer/
"!    CompanyName, OrderDate or ShippedDate, ascending or descending), and no
"!    sorter at all - the mock's own row order - once a confirm carries no
"!    grouping, because _applyGrouper replaces the binding's sorters on every
"!    confirm.
"!  - a GROUP HEADER is made by the list binding, from a Sorter with a group
"!    function the original passes per grouping. A backend cannot hand over a
"!    function, so the rows are bound as JSON the class composes
"!    (_bind( json = abap_true )): each row carries its group as an object
"!    { key, text } - exactly what the original's group functions return - and
"!    cs_event-binding_call sorts on it with group = X. The default group
"!    function then yields that object as the group, and the default
"!    comparator ranks two objects as equal, so the sort leaves the order the
"!    backend chose. A view rebuild loses the sorter; view_display re-issues it.
"!  - the formatter module is business logic and moves to the backend: the
"!    delivery state and text, the unit price's two digits, the order total and
"!    the employee picture's fallback. The dates and amounts keep the
"!    original's DateType and CurrencyType bindings, so they format in the
"!    browser's locale and time zone exactly as there. The group header texts
"!    ("Ordered in November 2016") are composed in ABAP from the UTC date,
"!    where the original's group function reads the month in the browser's
"!    time zone - so east of UTC one order (2686, shipped 2016-10-31 23:00
"!    UTC) is listed under the other month of its shipping date.
"!  - the share action's mail body loses its line breaks: abap2UI5's URLHELPER
"!    action refuses CR/LF in its parameters (a header-injection guard), and
"!    the i18n text carries three of them, so they become spaces. Subject,
"!    recipient-less mailto: and the link to the order are the original's.
"!  - the processor's picture is the original's fallback image
"!    (images/Employee.png, as every Photo of the mock is empty), served from
"!    the demo kit host, because this archive carries no binaries.
"!  - the IllustratedMessage is @since 1.98 and this package holds the 1.71
"!    floor: the empty list shows the same text as a noDataText (the List's
"!    noData aggregation is @since 1.101), and the two not-found pages show
"!    theirs in a MessagePage, the 1.71 empty-page control.
"!  - the i18n resource bundle becomes literals. The busy indicators the
"!    original shows until its OData metadata and data have arrived, and the
"!    ErrorHandler's MessageBox for a failed request, have no service to wait
"!    for or to fail here. The content density needs nothing: abap2UI5's page
"!    already carries sapUiSizeCompact on its body, which is the case in which
"!    the original's getContentDensityClass adds no class either.
"!
"! Original: src/sap.m/test/sap/m/demokit/orderbrowser in OpenUI5, archived
"! under ui5/demoapps/sap.m/orderbrowser.
"! Demo apps: https://sdk.openui5.org/demoapps
CLASS z2ui5_cl_smpc_demo_002 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " Edm.DateTime as the epoch milliseconds of the mock - what the
    " DateType bindings read with source pattern 'timestamp'
    TYPES ty_ms TYPE p LENGTH 8 DECIMALS 0.
    TYPES ty_amount TYPE p LENGTH 12 DECIMALS 2.
    TYPES:
      BEGIN OF ty_s_item,
        productname TYPE string,
        productid   TYPE string,
        unitprice   TYPE string,
        quantity    TYPE string,
        item_total  TYPE ty_amount,
      END OF ty_s_item.
    TYPES:
      BEGIN OF ty_s_mail,
        email   TYPE string,
        subject TYPE string,
        body    TYPE string,
      END OF ty_s_mail.
    TYPES:
      BEGIN OF ty_s_tel,
        tel TYPE string,
      END OF ty_s_tel.

    " the master list - JSON composed in rows_build( ), see the header
    DATA rows_json          TYPE string VALUE `[]`.
    DATA t_items            TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
    " appView>/layout and appView>/actionButtonsInfo/midColumn/fullScreen
    DATA layout             TYPE string VALUE `OneColumn`.
    DATA check_fullscreen   TYPE abap_bool.
    " masterView
    DATA title_count        TYPE string.
    DATA no_data_text       TYPE string VALUE `No orders are currently available`.
    DATA filter_bar_visible TYPE abap_bool.
    DATA filter_bar_label   TYPE string.
    DATA search_value       TYPE string.
    " the dialog's selections, bound so a rebuilt view shows them again
    DATA flt_shipped        TYPE abap_bool.
    DATA flt_not_shipped    TYPE abap_bool.
    DATA grp_customer       TYPE abap_bool.
    DATA grp_order          TYPE abap_bool.
    DATA grp_shipped        TYPE abap_bool.
    DATA group_descending   TYPE abap_bool.
    " detailView and the bound order
    DATA selected_tab       TYPE string VALUE `shipping`.
    DATA det_title          TYPE string.
    DATA det_customer       TYPE string.
    DATA det_orderdate      TYPE p LENGTH 8 DECIMALS 0.
    DATA det_shippeddate    TYPE p LENGTH 8 DECIMALS 0.
    DATA det_total          TYPE ty_amount.
    DATA det_currency       TYPE string VALUE `EUR`.
    DATA det_items_title    TYPE string VALUE `Line Items`.
    DATA det_shipname       TYPE string.
    DATA det_shipaddress    TYPE string.
    DATA det_shipzipcity    TYPE string.
    DATA det_shipregion     TYPE string.
    DATA det_shipcountry    TYPE string.
    DATA det_employee       TYPE string.
    DATA det_employeeid     TYPE string.
    DATA det_jobtitle       TYPE string.
    DATA det_photo          TYPE string.
    DATA s_tel              TYPE ty_s_tel.
    DATA s_mail             TYPE ty_s_mail.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_order,
        orderid      TYPE i,
        customerid   TYPE string,
        customername TYPE string,
        companyname  TYPE string,
        employeeid   TYPE i,
        orderdate    TYPE ty_ms,
        requireddate TYPE ty_ms,
        shippeddate  TYPE ty_ms,
        shipname     TYPE string,
        shipaddress  TYPE string,
        shipcity     TYPE string,
        shipregion   TYPE string,
        shippostal   TYPE string,
        shipcountry  TYPE string,
      END OF ty_s_order.
    TYPES ty_t_order TYPE STANDARD TABLE OF ty_s_order WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_customer,
        customerid  TYPE string,
        companyname TYPE string,
      END OF ty_s_customer.
    TYPES:
      BEGIN OF ty_s_employee,
        employeeid TYPE i,
        firstname  TYPE string,
        lastname   TYPE string,
        title      TYPE string,
        homephone  TYPE string,
      END OF ty_s_employee.
    TYPES:
      BEGIN OF ty_s_product,
        productid   TYPE i,
        productname TYPE string,
      END OF ty_s_product.
    TYPES:
      BEGIN OF ty_s_detail,
        orderid   TYPE i,
        productid TYPE i,
        unitprice TYPE ty_amount,
        quantity  TYPE i,
      END OF ty_s_detail.

    DATA client          TYPE REF TO z2ui5_if_client.
    DATA t_orders        TYPE ty_t_order.
    DATA t_customers     TYPE STANDARD TABLE OF ty_s_customer WITH EMPTY KEY.
    DATA t_employees     TYPE STANDARD TABLE OF ty_s_employee WITH EMPTY KEY.
    DATA t_products      TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_details       TYPE STANDARD TABLE OF ty_s_detail WITH EMPTY KEY.
    " Master.controller's _oListFilterState and the binding's sorters
    DATA search_term     TYPE string.
    DATA filter_key      TYPE string.
    DATA group_key       TYPE string.
    DATA check_sorted    TYPE abap_bool.
    " the route's objectId, the order bound to the detail page and the one
    " the ListSelector marks in the master list
    DATA route_objectid  TYPE string.
    DATA order_shown     TYPE i.
    DATA order_selected  TYPE i.
    DATA previous_layout TYPE string.
    " the page each column shows, and what the client shows right now -
    " bookkeeping the view never binds
    DATA page_begin      TYPE string VALUE `page`.
    DATA page_mid        TYPE string VALUE `detailPage`.
    DATA page_begin_live TYPE string.
    DATA page_mid_live   TYPE string.
    DATA group_live      TYPE string.

    METHODS view_display.
    METHODS view_dialog
      IMPORTING
        view TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS view_master
      IMPORTING
        fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS view_detail
      IMPORTING
        fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS view_detail_tabs
      IMPORTING
        column TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS view_detail_items
      IMPORTING
        column TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS on_event.
    METHODS on_select
      IMPORTING
        orderid TYPE string.
    METHODS on_search.
    METHODS on_view_settings.
    METHODS on_toggle_fullscreen.
    METHODS route_hash.
    METHODS route_master.
    METHODS route_object
      IMPORTING
        objectid TYPE string
        tab      TYPE string.
    METHODS route_bypassed.
    METHODS detail_bind
      IMPORTING
        order TYPE ty_s_order.
    METHODS pages_sync.
    METHODS group_sync
      IMPORTING
        check_force TYPE abap_bool DEFAULT abap_false.
    METHODS rows_build.
    METHODS rows_sort
      CHANGING
        t_order TYPE ty_t_order.
    METHODS row_json
      IMPORTING
        order         TYPE ty_s_order
        pos           TYPE i
      RETURNING
        VALUE(result) TYPE string.
    METHODS json_text
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS utc_date
      IMPORTING
        val           TYPE ty_ms
      RETURNING
        VALUE(result) TYPE d.
    METHODS month_name
      IMPORTING
        val           TYPE d
      RETURNING
        VALUE(result) TYPE string.
    METHODS amount
      IMPORTING
        val           TYPE ty_amount
      RETURNING
        VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_demo_002 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " the app owns the hash: the browser Back/Forward buttons and a
    " hand-edited URL round-trip as HASH_CHANGED. Queued FIRST - a route
    " below may already rewrite the hash, and without the listener in place
    " the frontend would append that value instead of writing it. The
    " registration dies with an app switch, so it is re-issued per render
    client->follow_up_action( val = client->cs_event-hash_attach_changed t_arg = VALUE #( ( `HASH_CHANGED` ) ) ).

    " a start, a reload or a shared link: the live hash is matched like the
    " router's initialize( ) matches it
    route_hash( ).
    rows_build( ).

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock`   v = `true`
            )->a( n = `height`         v = `100%`
            )->a( n = `xmlns`          v = `sap.m`
            )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
            )->a( n = `xmlns:f`        v = `sap.f`
            )->a( n = `xmlns:semantic` v = `sap.f.semantic`
            )->a( n = `xmlns:core`     v = `sap.ui.core`
            )->a( n = `xmlns:form`     v = `sap.ui.layout.form`
            )->a( n = `xmlns:l`        v = `sap.ui.layout` ).

    view_dialog( view ).

    " App.view.xml. The layout is bound two-way, as appView>/layout is: the
    " FCL's own arrows change it, and toggleFullScreen stores what they left
    DATA(fcl) = view->ele( `App`
        )->a( n = `id` v = `app`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`               v = `layout`
            )->a( n = `layout`           v = client->_bind( layout )
            )->a( n = `backgroundDesign` v = `Translucent` ).

    view_master( fcl ).
    view_detail( fcl ).

    client->view_display( view->stringify( ) ).

    " a rebuilt FlexibleColumnLayout starts on the first page of each column
    " and a rebuilt list binding without a sorter - both re-issued from the
    " state that survived
    page_begin_live = `page`.
    page_mid_live   = `detailPage`.
    pages_sync( ).
    group_live = ``.
    group_sync( ).

  ENDMETHOD.


  METHOD view_dialog.

    " ViewSettingsDialog.fragment.xml, which Master.onOpenViewSettings loads
    " into the view's dependents - declared there and opened by id without a
    " round-trip. The confirm hands over what _onConfirm reads: the text and
    " key of the filter item, the group item's key and the group order. The
    " selections are bound as well, so a rebuilt view restores them
    view->ele( n = `dependents` ns = `mvc`
        )->ele( `ViewSettingsDialog`
            )->a( n = `id`              v = `viewSettingsDialog`
            )->a( n = `groupDescending` v = client->_bind( group_descending )
            )->a( n = `confirm`         v = client->_event( val   = `VIEW_SETTINGS`
                                                            t_arg = VALUE #( ( `${$parameters>/filterItems}.length ? ${$parameters>/filterItems}[0].getText() : ''` )
                                                                             ( `${$parameters>/filterItems}.length ? ${$parameters>/filterItems}[0].getKey() : ''` )
                                                                             ( `${$parameters>/groupItem} ? ${$parameters>/groupItem}.getKey() : ''` )
                                                                             ( `${$parameters>/groupDescending} ? 'X' : ''` ) ) )

            )->ele( `filterItems`
                )->ele( `ViewSettingsFilterItem`
                    )->a( n = `id`          v = `filterItems`
                    )->a( n = `text`        v = `Orders`
                    )->a( n = `key`         v = `Orders`
                    )->a( n = `multiSelect` b = abap_false

                    )->ele( `items`
                        )->tag( `ViewSettingsItem`
                            )->a( n = `id`       v = `viewFilter1`
                            )->a( n = `text`     v = `Only Shipped Orders`
                            )->a( n = `key`      v = `Shipped`
                            )->a( n = `selected` v = client->_bind( flt_shipped )
                        )->tag( `ViewSettingsItem`
                            )->a( n = `id`       v = `viewFilter2`
                            )->a( n = `text`     v = `Only Orders without Shipment`
                            )->a( n = `key`      v = `NotShipped`
                            )->a( n = `selected` v = client->_bind( flt_not_shipped )

                    )->end(
                )->end(
            )->end(
            )->ele( `groupItems`
                )->tag( `ViewSettingsItem`
                    )->a( n = `text`     v = `Group by Customer`
                    )->a( n = `key`      v = `CompanyName`
                    )->a( n = `selected` v = client->_bind( grp_customer )
                )->tag( `ViewSettingsItem`
                    )->a( n = `text`     v = `Group by Order Period`
                    )->a( n = `key`      v = `OrderDate`
                    )->a( n = `selected` v = client->_bind( grp_order )
                )->tag( `ViewSettingsItem`
                    )->a( n = `text`     v = `Group by Shipped Period`
                    )->a( n = `key`      v = `ShippedDate`
                    )->a( n = `selected` v = client->_bind( grp_shipped ) ).

  ENDMETHOD.


  METHOD view_master.

    DATA(open_filter) = client->follow_up_action( val   = client->cs_event-control_by_id
                                                  t_arg = VALUE #( ( `viewSettingsDialog` ) ( `open` ) ( `filter` ) ) ).

    " the begin column: Master.view.xml and the NotFound target
    DATA(column) = fcl->ele( n = `beginColumnPages` ns = `f` ).

    DATA(list) = column->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`           v = `page`
        )->a( n = `core:require` v = `{DateType: 'sap/ui/model/type/Date'}`

        )->ele( n = `titleHeading` ns = `semantic`
            )->tag( `Title`
                )->a( n = `id`   v = `masterHeaderTitle`
                )->a( n = `text` v = client->_bind( title_count )

        )->end(
        )->ele( n = `content` ns = `semantic`
            )->ele( `List`
                )->a( n = `id`                  v = `list`
                )->a( n = `width`               v = `auto`
                )->a( n = `class`               v = `sapFDynamicPageAlignContent`
                )->a( n = `items`               v = client->_bind( val = rows_json json = abap_true )
                )->a( n = `noDataText`          v = client->_bind( no_data_text )
                )->a( n = `mode`                v = `{= ${device>/system/phone} ? 'None' : 'SingleSelectMaster'}`
                )->a( n = `growing`             b = abap_true
                )->a( n = `growingScrollToLoad` b = abap_true
                " a click in SingleSelectMaster mode fires the list's
                " selectionChange and never the item's press
                )->a( n = `selectionChange`     v = client->_event( val = `SELECT`
                                                                    arg = `${$parameters>/listItem}.getBindingContext().getProperty('orderid')` ) ).

    " the info bar and the three header controls open the dialog on the page
    " onOpenViewSettings picks: "group" for the group button, "filter" for
    " everything else
    list->ele( `infoToolbar`
        )->ele( `Toolbar`
            )->a( n = `active`  b = abap_true
            )->a( n = `id`      v = `filterBar`
            )->a( n = `visible` v = client->_bind( filter_bar_visible )
            )->a( n = `press`   v = open_filter

            )->tag( `Title`
                )->a( n = `id`   v = `filterBarLabel`
                )->a( n = `text` v = client->_bind( filter_bar_label ) ).

    list->ele( `headerToolbar`
        )->ele( `OverflowToolbar`

            )->ele( `SearchField`
                )->a( n = `id`                 v = `searchField`
                )->a( n = `showRefreshButton`  b = abap_true
                )->a( n = `tooltip`            v = `Enter an order name or a part of it.`
                )->a( n = `width`              v = `100%`
                )->a( n = `value`              v = client->_bind( search_value )
                )->a( n = `search`             v = client->_event( val   = `SEARCH`
                                                                   t_arg = VALUE #( ( `${$parameters>/query}` )
                                                                                    ( `${$parameters>/refreshButtonPressed} ? 'X' : ''` ) ) )

                )->ele( `layoutData`
                    )->tag( `OverflowToolbarLayoutData`
                        )->a( n = `minWidth`   v = `150px`
                        )->a( n = `maxWidth`   v = `240px`
                        )->a( n = `shrinkable` b = abap_true
                        )->a( n = `priority`   v = `NeverOverflow`

                )->end(
            )->end(
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `id`    v = `filterButton`
                )->a( n = `press` v = open_filter
                )->a( n = `icon`  v = `sap-icon://filter`
                )->a( n = `type`  v = `Transparent`
            )->tag( `Button`
                )->a( n = `id`    v = `groupButton`
                )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                t_arg = VALUE #( ( `viewSettingsDialog` ) ( `open` ) ( `group` ) ) )
                )->a( n = `icon`  v = `sap-icon://group-2`
                )->a( n = `type`  v = `Transparent` ).

    " the rows are the JSON of rows_build( ), so their fields are the lower
    " case keys composed there
    list->ele( `items`
        )->ele( `ObjectListItem`
            )->a( n = `type`     v = `{= ${device>/system/phone} ? 'Active' : 'Inactive'}`
            )->a( n = `press`    v = client->_event( val = `SELECT` arg = `${orderid}` )
            )->a( n = `selected` v = `{selected}`
            )->a( n = `title`    v = `{title}`
            )->a( n = `number`   v = `{ path: 'orderdate', type: 'DateType', formatOptions: { style: 'short', source: { pattern: 'timestamp' } } }`

            )->ele( `firstStatus`
                )->tag( `ObjectStatus`
                    )->a( n = `state` v = `{state}`
                    )->a( n = `text`  v = `{text}`

            )->end(
            )->ele( `attributes`
                )->tag( `ObjectAttribute`
                    )->a( n = `id`   v = `companyName`
                    )->a( n = `text` v = `{companyname}`
                )->tag( `ObjectAttribute`
                    )->a( n = `title` v = `Shipped`
                    )->a( n = `text`  v = `{= ${shippeddate} ? ${ path: 'shippeddate', type: 'DateType', ` &&
                                          `formatOptions: { style: 'medium', source: { pattern: 'timestamp' } } } : 'Not shipped yet' }` ).

    " NotFound.view.xml - the bypassed target
    column->ele( `Page`
        )->a( n = `id`             v = `notFoundPage`
        )->a( n = `title`          v = `Not Found`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `NAV_BACK` )

        )->tag( `MessagePage`
            )->a( n = `showHeader`  b = abap_false
            )->a( n = `text`        v = `The requested resource was not found`
            )->a( n = `description` v = ``
            )->a( n = `icon`        v = `sap-icon://documents` ).

  ENDMETHOD.


  METHOD view_detail.


    " the mid column: Detail.view.xml and the DetailObjectNotFound target
    DATA(column) = fcl->ele( n = `midColumnPages` ns = `f` ).

    DATA(detail) = column->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`           v = `detailPage`
        )->a( n = `core:require` v = `{DateType: 'sap/ui/model/type/Date', CurrencyType: 'sap/ui/model/type/Currency'}` ).

    detail->ele( n = `titleHeading` ns = `semantic`
        )->tag( `Title`
            )->a( n = `text` v = client->_bind( det_title ) ).

    DATA(header) = detail->ele( n = `headerContent` ns = `semantic`
        )->ele( n = `HorizontalLayout` ns = `l` ).

    header->ele( n = `VerticalLayout` ns = `l`
        )->a( n = `class` v = `sapUiMediumMarginEnd`

        )->tag( `ObjectAttribute`
            )->a( n = `title` v = `Customer`
            )->a( n = `text`  v = client->_bind( det_customer )
        )->tag( `ObjectAttribute`
            )->a( n = `title` v = `Ordered`
            )->a( n = `text`  v = |\{ path: '{ client->_bind( val = det_orderdate path = abap_true ) }', type: 'DateType', | &&
                                  |formatOptions: \{ style: 'medium', source: \{ pattern: 'timestamp' \} \} \}|
        )->tag( `ObjectAttribute`
            )->a( n = `title` v = `Shipped`
            )->a( n = `text`  v = |\{= ${ client->_bind( det_shippeddate ) } ? $\{ path: '{ client->_bind( val = det_shippeddate path = abap_true ) }', | &&
                                  |type: 'DateType', formatOptions: \{ style: 'medium', source: \{ pattern: 'timestamp' \} \} \} : 'Not shipped yet' \}| ).

    header->ele( n = `VerticalLayout` ns = `l`
        )->tag( `Label`
            )->a( n = `text` v = `Price`
        )->tag( `ObjectNumber`
            )->a( n = `number` v = |\{ parts: [ \{ path: '{ client->_bind( val = det_total path = abap_true ) }' \}, | &&
                                   |\{ path: '{ client->_bind( val = det_currency path = abap_true ) }' \} ], | &&
                                   |type: 'CurrencyType', formatOptions: \{ showMeasure: false \} \}|
            )->a( n = `unit`   v = client->_bind( det_currency ) ).

    DATA(content) = detail->ele( n = `content` ns = `semantic`
        )->ele( n = `VerticalLayout` ns = `l` ).
    view_detail_tabs( content ).
    view_detail_items( content ).

    " the share action is URLHelper.triggerEmail - a frontend action that
    " reads the bound mail structure when it is pressed, no round-trip
    detail->ele( n = `sendEmailAction` ns = `semantic`
        )->tag( n = `SendEmailAction` ns = `semantic`
            )->a( n = `id`    v = `shareEmail`
            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-urlhelper
                                                            t_arg = VALUE #( ( `TRIGGER_EMAIL` ) ( |${ client->_bind( s_mail ) }| ) ) ) ).

    detail->ele( n = `closeAction` ns = `semantic`
        )->tag( n = `CloseAction` ns = `semantic`
            )->a( n = `id`    v = `closeColumn`
            )->a( n = `press` v = client->_event( `CLOSE_DETAIL` ) ).

    detail->ele( n = `fullScreenAction` ns = `semantic`
        )->tag( n = `FullScreenAction` ns = `semantic`
            )->a( n = `id`      v = `enterFullScreen`
            )->a( n = `visible` v = |\{= !$\{device>/system/phone\} && !${ client->_bind( check_fullscreen ) } \}|
            )->a( n = `press`   v = client->_event( `TOGGLE_FULLSCREEN` ) ).

    detail->ele( n = `exitFullScreenAction` ns = `semantic`
        )->tag( n = `ExitFullScreenAction` ns = `semantic`
            )->a( n = `id`      v = `exitFullScreen`
            )->a( n = `visible` v = |\{= !$\{device>/system/phone\} && ${ client->_bind( check_fullscreen ) } \}|
            )->a( n = `press`   v = client->_event( `TOGGLE_FULLSCREEN` ) ).

    " DetailObjectNotFound.view.xml - the target _onBindingChange displays
    " when the route names an order the service does not have
    column->ele( `Page`
        )->a( n = `id`             v = `detailObjectNotFoundPage`
        )->a( n = `title`          v = `Order Details`
        )->a( n = `showNavButton`  v = `{= ${device>/system/phone} || ${device>/system/tablet} && ${device>/orientation/portrait} }`
        )->a( n = `navButtonPress` v = client->_event( `NAV_BACK` )

        )->tag( `MessagePage`
            )->a( n = `showHeader`  b = abap_false
            )->a( n = `text`        v = `This order is not available`
            )->a( n = `description` v = ``
            )->a( n = `icon`        v = `sap-icon://search` ).

  ENDMETHOD.


  METHOD view_detail_tabs.

    " the shipping and processor targets are displayed INTO these two tabs;
    " a tab switch is onTabSelect, which rewrites the route's ?tab= query
    DATA(tabs) = column->ele( `IconTabBar`
        )->a( n = `id`                     v = `iconTabBar`
        )->a( n = `headerBackgroundDesign` v = `Transparent`
        )->a( n = `select`                 v = client->_event( val = `TAB_SELECT` arg = `${$parameters>/selectedKey}` )
        )->a( n = `selectedKey`            v = client->_bind( selected_tab )

        )->ele( `items` ).

    " Shipping.view.xml
    tabs->ele( `IconTabFilter`
        )->a( n = `id`      v = `iconTabFilterShipping`
        )->a( n = `icon`    v = `sap-icon://shipping-status`
        )->a( n = `tooltip` v = `Shipping Info`
        )->a( n = `key`     v = `shipping`

        )->ele( `VBox`
            )->ele( n = `SimpleForm` ns = `form`
                )->a( n = `id`         v = `SimpleFormShipAddress`
                )->a( n = `editable`   b = abap_false
                )->a( n = `layout`     v = `ResponsiveGridLayout`
                )->a( n = `title`      v = `Shipping Address`
                )->a( n = `labelSpanL` v = `3`
                )->a( n = `labelSpanM` v = `3`
                )->a( n = `emptySpanL` v = `4`
                )->a( n = `emptySpanM` v = `4`
                )->a( n = `columnsL`   v = `1`
                )->a( n = `columnsM`   v = `1`

                )->ele( n = `content` ns = `form`
                    )->tag( `Label`
                        )->a( n = `text` v = `Name`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( det_shipname )
                    )->tag( `Label`
                        )->a( n = `text` v = `Street`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( det_shipaddress )
                    )->tag( `Label`
                        )->a( n = `text` v = `ZIP Code / City`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( det_shipzipcity )
                    )->tag( `Label`
                        )->a( n = `text` v = `Region`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( det_shipregion )
                    )->tag( `Label`
                        )->a( n = `text` v = `Country`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( det_shipcountry ) ).

    " Processor.view.xml. The phone link is URLHelper.triggerTel - a frontend
    " action reading the bound number, no round-trip
    tabs->ele( `IconTabFilter`
        )->a( n = `id`      v = `iconTabFilterProcessor`
        )->a( n = `icon`    v = `sap-icon://employee`
        )->a( n = `tooltip` v = `Processor`
        )->a( n = `key`     v = `processor`

        )->ele( `VBox`
            )->ele( n = `SimpleForm` ns = `form`
                )->a( n = `id`         v = `SimpleFormProcessorInfo`
                )->a( n = `editable`   b = abap_false
                )->a( n = `layout`     v = `ResponsiveGridLayout`
                )->a( n = `title`      v = `Processor Information`
                )->a( n = `labelSpanL` v = `3`
                )->a( n = `labelSpanM` v = `3`
                )->a( n = `emptySpanL` v = `4`
                )->a( n = `emptySpanM` v = `4`
                )->a( n = `columnsL`   v = `2`
                )->a( n = `columnsM`   v = `2`

                )->ele( n = `content` ns = `form`
                    )->tag( n = `Title` ns = `core`
                        )->a( n = `text` v = `Details`
                    )->tag( `Label`
                        )->a( n = `text` v = `Name`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( det_employee )
                    )->tag( `Label`
                        )->a( n = `text` v = `Employee ID`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( det_employeeid )
                    )->tag( `Label`
                        )->a( n = `text` v = `Job Title`
                    )->tag( `Text`
                        )->a( n = `text` v = client->_bind( det_jobtitle )
                    )->tag( `Label`
                        )->a( n = `text` v = `Phone`
                    )->tag( `Link`
                        )->a( n = `text`  v = client->_bind( s_tel-tel )
                        )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-urlhelper
                                                                        t_arg = VALUE #( ( `TRIGGER_TEL` ) ( |${ client->_bind( s_tel ) }| ) ) )
                    )->tag( n = `Title` ns = `core`
                        )->a( n = `text` v = `Picture`
                    )->tag( `Image`
                        )->a( n = `src`    v = client->_bind( det_photo )
                        )->a( n = `width`  v = `50%`
                        )->a( n = `height` v = `50%` ).

  ENDMETHOD.


  METHOD view_detail_items.

    DATA(items) = column->ele( `Table`
        )->a( n = `id`         v = `lineItemsList`
        )->a( n = `class`      v = `sapUiSmallMarginTop`
        )->a( n = `width`      v = `auto`
        )->a( n = `items`      v = client->_bind( t_items )
        )->a( n = `noDataText` v = `No line items` ).

    items->ele( `headerToolbar`
        )->ele( `Toolbar`
            )->a( n = `id` v = `lineItemsToolbar`

            )->tag( `Title`
                )->a( n = `id`   v = `lineItemsHeader`
                )->a( n = `text` v = client->_bind( det_items_title ) ).

    items->ele( `columns`
        )->ele( `Column`

            )->tag( `Text`
                )->a( n = `text` v = `Product`

        )->end(
        )->ele( `Column`
            )->a( n = `minScreenWidth` v = `Tablet`
            )->a( n = `demandPopin`    b = abap_true
            )->a( n = `hAlign`         v = `End`

            )->tag( `Text`
                )->a( n = `text` v = `Unit Price`

        )->end(
        )->ele( `Column`
            )->a( n = `minScreenWidth` v = `Tablet`
            )->a( n = `demandPopin`    b = abap_true
            )->a( n = `hAlign`         v = `End`

            )->tag( `Text`
                )->a( n = `text` v = `Quantity`

        )->end(
        )->ele( `Column`
            )->a( n = `minScreenWidth` v = `Tablet`
            )->a( n = `demandPopin`    b = abap_true
            )->a( n = `hAlign`         v = `End`

            )->tag( `Text`
                )->a( n = `text` v = `Total` ).

    items->ele( `items`
        )->ele( `ColumnListItem`

            )->ele( `cells`
                )->tag( `ObjectIdentifier`
                    )->a( n = `title` v = `{PRODUCTNAME}`
                    )->a( n = `text`  v = `{PRODUCTID}`
                )->tag( `ObjectNumber`
                    )->a( n = `number` v = `{UNITPRICE}`
                    )->a( n = `unit`   v = client->_bind( det_currency )
                )->tag( `ObjectAttribute`
                    )->a( n = `text` v = `{QUANTITY}`
                )->tag( `ObjectNumber`
                    )->a( n = `number` v = |\{ parts: [ \{ path: 'ITEM_TOTAL' \}, \{ path: '{ client->_bind( val = det_currency path = abap_true ) }' \} ], | &&
                                           |type: 'CurrencyType', formatOptions: \{ showMeasure: false \} \}|
                    )->a( n = `unit`   v = client->_bind( det_currency ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SELECT`.
        on_select( client->get_event_arg( ) ).

      WHEN `SEARCH`.
        on_search( ).

      WHEN `VIEW_SETTINGS`.
        on_view_settings( ).

      WHEN `HASH_CHANGED`.
        route_hash( ).

      WHEN `TAB_SELECT`.
        " onTabSelect: navTo( "object", { objectId, query: { tab } }, true )
        selected_tab = client->get_event_arg( ).
        client->hash_replace( |/Orders/{ route_objectid }/?tab={ selected_tab }| ).

      WHEN `CLOSE_DETAIL`.
        " onCloseDetailPress: out of full screen, no selection left in the
        " master list, and navTo( "master" ) - a pushed history entry
        check_fullscreen = abap_false.
        order_selected   = 0.
        client->hash_set( `/` ).
        route_master( ).

      WHEN `TOGGLE_FULLSCREEN`.
        on_toggle_fullscreen( ).

      WHEN `NAV_BACK`.
        " BaseController.onNavBack: one step back in the history, or - when
        " the app has none of its own - navTo( "master", {}, true )
        client->follow_up_action( val = client->cs_event-hash_back t_arg = VALUE #( ( `/` ) ) ).

    ENDCASE.

    rows_build( ).
    pages_sync( ).

  ENDMETHOD.


  METHOD on_select.

    " Master._showDetail: two columns, and navTo( "object" ) - replacing the
    " hash on a desktop, pushing it on a phone. The object route has no ?tab=
    " then, so _onObjectMatched rewrites it to tab=shipping in place: the net
    " effect is one write of the final hash
    layout = `TwoColumnsMidExpanded`.
    DATA(hash) = |/Orders/{ orderid }/?tab=shipping|.
    IF client->get( )-s_device-system = z2ui5_if_client=>cs_device-system-phone.
      client->hash_set( hash ).
    ELSE.
      client->hash_replace( hash ).
    ENDIF.
    route_object( objectid = orderid tab = `shipping` ).

  ENDMETHOD.


  METHOD on_search.

    " onSearch: the refresh button only refreshes the binding - the query in
    " the field is NOT applied then
    IF client->get_event_arg( 2 ) = `X`.
      RETURN.
    ENDIF.
    search_term = client->get_event_arg( ).
    group_sync( abap_true ).

  ENDMETHOD.


  METHOD on_view_settings.

    " onConfirmViewSettingsDialog: the filter and the info bar - which shows
    " only while a filter is set, but is labelled either way
    filter_bar_label   = |Filtered by { client->get_event_arg( ) }|.
    filter_key         = client->get_event_arg( 2 ).
    filter_bar_visible = xsdbool( filter_key IS NOT INITIAL ).
    flt_shipped        = xsdbool( filter_key = `Shipped` ).
    flt_not_shipped    = xsdbool( filter_key = `NotShipped` ).

    " _applyGrouper: the grouper's sorter REPLACES the binding's sorters -
    " the OrderID sorter of the view is gone after the first confirm
    group_key        = client->get_event_arg( 3 ).
    group_descending = xsdbool( client->get_event_arg( 4 ) = `X` ).
    grp_customer     = xsdbool( group_key = `CompanyName` ).
    grp_order        = xsdbool( group_key = `OrderDate` ).
    grp_shipped      = xsdbool( group_key = `ShippedDate` ).
    check_sorted     = abap_true.
    group_sync( abap_true ).

  ENDMETHOD.


  METHOD on_toggle_fullscreen.

    " toggleFullScreen: remember the layout on the way in, restore it on the
    " way out
    check_fullscreen = xsdbool( check_fullscreen = abap_false ).
    IF check_fullscreen = abap_true.
      previous_layout = layout.
      layout = `MidColumnFullScreen`.
    ELSE.
      layout = previous_layout.
    ENDIF.

  ENDMETHOD.


  METHOD route_hash.

    " the router's parse of the hash, against the patterns of manifest.json:
    " "" -> master, "Orders/{objectId}/:?query:" -> object, else bypassed.
    " crossroads ignores the case of the pattern's literals, as CP does
    DATA(hash) = client->get( )-s_config-hash.
    IF hash CS `#`.
      hash = substring_after( val = hash sub = `#` ).
    ENDIF.
    SHIFT hash LEFT DELETING LEADING `/`.
    " the framework's own app-state hash is none of the app's routes
    IF hash CP `z2ui5-*`.
      RETURN.
    ENDIF.

    IF hash IS INITIAL.
      route_master( ).
      RETURN.
    ENDIF.
    IF hash NP `Orders/*`.
      route_bypassed( ).
      RETURN.
    ENDIF.

    DATA(objectid) = substring_after( val = hash sub = `/` ).
    DATA(query) = ``.
    IF objectid CS `?`.
      query    = substring_after( val = objectid sub = `?` ).
      objectid = substring_before( val = objectid sub = `?` ).
    ENDIF.
    IF objectid CP `*/`.
      objectid = substring( val = objectid len = strlen( objectid ) - 1 ).
    ENDIF.
    IF objectid IS INITIAL OR objectid CS `/`.
      route_bypassed( ).
      RETURN.
    ENDIF.

    DATA(tab) = ``.
    SPLIT query AT `&` INTO TABLE DATA(t_param).
    LOOP AT t_param INTO DATA(param).
      IF substring_before( val = param sub = `=` ) = `tab`.
        tab = substring_after( val = param sub = `=` ).
      ENDIF.
    ENDLOOP.
    route_object( objectid = objectid tab = tab ).

  ENDMETHOD.


  METHOD route_master.

    " the master target, and Master._onMasterMatched
    page_begin = `page`.
    layout     = `OneColumn`.

  ENDMETHOD.


  METHOD route_object.

    " the targets master and object, and Detail._onObjectMatched: two columns
    " unless the detail is in full screen
    route_objectid = objectid.
    page_begin     = `page`.
    IF layout <> `MidColumnFullScreen`.
      layout = `TwoColumnsMidExpanded`.
    ENDIF.

    " a missing or unknown ?tab= becomes tab=shipping, in place
    IF tab = `shipping` OR tab = `processor`.
      selected_tab = tab.
    ELSE.
      selected_tab = `shipping`.
      client->hash_replace( |/Orders/{ objectid }/?tab=shipping| ).
    ENDIF.

    " _bindView and _onBindingChange: the order, or - for an id the service
    " does not have - the DetailObjectNotFound target and no selection
    DATA(order) = VALUE ty_s_order( ).
    IF objectid CO `0123456789` AND strlen( objectid ) <= 9.
      order = VALUE #( t_orders[ orderid = CONV i( objectid ) ] OPTIONAL ).
    ENDIF.
    IF order IS INITIAL.
      page_mid       = `detailObjectNotFoundPage`.
      order_selected = 0.
      RETURN.
    ENDIF.
    page_mid       = `detailPage`.
    order_selected = order-orderid.
    detail_bind( order ).

  ENDMETHOD.


  METHOD route_bypassed.

    " the notFound target, NotFound._onNotFoundDisplayed and
    " Master.onBypassed
    page_begin     = `notFoundPage`.
    layout         = `OneColumn`.
    order_selected = 0.

  ENDMETHOD.


  METHOD detail_bind.

    DATA total      TYPE ty_amount.
    DATA line_total TYPE ty_amount.

    order_shown     = order-orderid.
    det_title       = |Order { order-orderid }|.
    det_customer    = order-companyname.
    det_orderdate   = order-orderdate.
    det_shippeddate = order-shippeddate.
    det_shipname    = order-shipname.
    det_shipaddress = order-shipaddress.
    det_shipzipcity = |{ order-shippostal } { order-shipcity }|.
    det_shipregion  = order-shipregion.
    det_shipcountry = order-shipcountry.

    DATA(employee) = VALUE ty_s_employee( t_employees[ employeeid = order-employeeid ] OPTIONAL ).
    det_employee   = |{ employee-firstname } { employee-lastname }|.
    det_employeeid = |{ employee-employeeid }|.
    det_jobtitle   = employee-title.
    s_tel-tel      = employee-homephone.
    " formatter.handleBinaryContent: every Photo of the mock is empty, so the
    " original shows its fallback, webapp/images/Employee.png
    det_photo = `https://sdk.openui5.org/test-resources/sap/m/demokit/orderbrowser/webapp/images/Employee.png`.

    " the line items, and onListUpdateFinished's title and order total
    t_items = VALUE #( ).
    LOOP AT t_details INTO DATA(item) WHERE orderid = order-orderid.
      line_total = item-unitprice * item-quantity.
      total = total + line_total.
      INSERT VALUE #( productname = VALUE #( t_products[ productid = item-productid ]-productname OPTIONAL )
                      productid   = |{ item-productid }|
                      unitprice   = amount( item-unitprice )
                      quantity    = |{ item-quantity }|
                      item_total  = line_total ) INTO TABLE t_items.
    ENDLOOP.
    det_total       = total.
    det_items_title = COND #( WHEN t_items IS INITIAL THEN `Line Items` ELSE |Line Items ({ lines( t_items ) })| ).

    " _onBindingChange: the share texts, with the link to this order
    DATA(config) = client->get( )-s_config.
    s_mail-subject = |Order { order-orderid }|.
    s_mail-body    = |Please take a look at order { order-orderid } (id: { order-orderid }) | &&
                     |{ config-origin }{ config-pathname }{ config-search }#/Orders/{ order-orderid }/?tab={ selected_tab } | &&
                     |More Information on this order: - Customer Name: { order-shipname } | &&
                     |- Customer ID: { order-customerid } - Processor ID: { order-employeeid }|.

  ENDMETHOD.


  METHOD pages_sync.

    " the router's target display: FlexibleColumnLayout.to( ) moves the
    " column that owns the page - issued only where the page changes
    IF page_begin <> page_begin_live.
      client->follow_up_action( val = client->cs_event-control_by_id t_arg = VALUE #( ( `layout` ) ( `to` ) ( page_begin ) ) ).
      page_begin_live = page_begin.
    ENDIF.
    IF page_mid <> page_mid_live.
      client->follow_up_action( val = client->cs_event-control_by_id t_arg = VALUE #( ( `layout` ) ( `to` ) ( page_mid ) ) ).
      page_mid_live = page_mid.
    ENDIF.

  ENDMETHOD.


  METHOD group_sync.

    " the grouper's sorter on the LIST BINDING: sorting on each row's group
    " object with group = X draws the original's group headers, and keeps the
    " order rows_build( ) chose. Without a grouping, a sorter on the row
    " position takes the headers away again - the original's sort( [] )
    IF group_key IS INITIAL.
      IF group_live IS NOT INITIAL.
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = VALUE #( ( `list` ) ( `items` ) ( `sort` ) ( `pos` ) ) ).
      ENDIF.
    ELSEIF group_key <> group_live OR check_force = abap_true.
      client->follow_up_action( val   = client->cs_event-binding_call
                                t_arg = VALUE #( ( `list` ) ( `items` ) ( `sort` ) ( `grp` ) ( `` ) ( `X` ) ) ).
    ENDIF.
    group_live = group_key.

  ENDMETHOD.


  METHOD rows_build.

    DATA t_order TYPE ty_t_order.

    " _applyFilterSearch: the search and the filter, ANDed as the binding
    " ANDs filters on different paths
    LOOP AT t_orders INTO DATA(order).
      IF    ( filter_key = `Shipped` AND order-shippeddate IS INITIAL )
         OR ( filter_key = `NotShipped` AND order-shippeddate IS NOT INITIAL ).
        CONTINUE.
      ENDIF.
      IF search_term IS NOT INITIAL AND find( val = order-customername sub = search_term ) < 0.
        CONTINUE.
      ENDIF.
      INSERT order INTO TABLE t_order.
    ENDLOOP.
    rows_sort( CHANGING t_order = t_order ).

    DATA(json) = ``.
    LOOP AT t_order INTO order.
      DATA(pos) = sy-tabix.
      IF pos > 1.
        json = json && `,`.
      ENDIF.
      json = json && row_json( order = order pos = pos ).
    ENDLOOP.
    rows_json = |[{ json }]|.

    " _updateListItemCount, and the noDataText _applyFilterSearch sets once a
    " filter or search is applied - and, as there, never sets back
    title_count = |Orders ({ lines( t_order ) })|.
    IF filter_key IS NOT INITIAL OR search_term IS NOT INITIAL.
      no_data_text = `No matching order found`.
    ENDIF.

  ENDMETHOD.


  METHOD rows_sort.

    " the binding's sorter: the view's OrderID descending until a confirm
    " replaced it, then the grouper's sorter - or none, the mock's row order.
    " The mock server sorts stably, so equal values keep the mock's order
    IF check_sorted = abap_false.
      SORT t_order BY orderid DESCENDING.
      RETURN.
    ENDIF.
    CASE group_key.
      WHEN `CompanyName`.
        IF group_descending = abap_true.
          SORT t_order STABLE BY companyname DESCENDING.
        ELSE.
          SORT t_order STABLE BY companyname.
        ENDIF.
      WHEN `OrderDate`.
        IF group_descending = abap_true.
          SORT t_order STABLE BY orderdate DESCENDING.
        ELSE.
          SORT t_order STABLE BY orderdate.
        ENDIF.
      WHEN `ShippedDate`.
        IF group_descending = abap_true.
          SORT t_order STABLE BY shippeddate DESCENDING.
        ELSE.
          SORT t_order STABLE BY shippeddate.
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD row_json.

    " the deliveryState / deliveryText formatters: an unshipped order has
    " none, a delivery up to five days before the required date is urgent,
    " one after it too late
    DATA(state) = `None`.
    DATA(text) = `None`.
    IF order-shippeddate IS NOT INITIAL.
      DATA(margin) = order-requireddate - order-shippeddate.
      IF margin > 0 AND margin <= 432000000.
        state = `Warning`.
        text  = `Urgent`.
      ELSEIF order-requireddate < order-shippeddate.
        state = `Error`.
        text  = `Too late`.
      ELSE.
        state = `Success`.
        text  = `In time`.
      ENDIF.
    ENDIF.

    " the group the original's group function returns for the row
    DATA(key) = ``.
    DATA(group) = ``.
    CASE group_key.
      WHEN `CompanyName`.
        key   = order-companyname.
        group = order-companyname.
      WHEN `OrderDate`.
        DATA(ordered) = utc_date( order-orderdate ).
        key   = |{ ordered(4) }-{ CONV i( ordered+4(2) ) }|.
        group = |Ordered in { month_name( ordered ) } { ordered(4) }|.
      WHEN `ShippedDate`.
        IF order-shippeddate IS INITIAL.
          key   = `0`.
          group = `Not Shipped Yet`.
        ELSE.
          DATA(shipped) = utc_date( order-shippeddate ).
          key   = |{ shipped(4) }-{ CONV i( shipped+4(2) ) }|.
          group = |Shipped in { month_name( shipped ) } { shipped(4) }|.
        ENDIF.
    ENDCASE.

    result = |\{"pos":{ pos },"orderid":{ order-orderid },"title":{ json_text( |Order { order-orderid }| ) },| &&
             |"orderdate":{ order-orderdate },| &&
             |"shippeddate":{ COND string( WHEN order-shippeddate IS INITIAL THEN `null` ELSE |{ order-shippeddate }| ) },| &&
             |"companyname":{ json_text( order-companyname ) },"state":"{ state }","text":"{ text }",| &&
             |"selected":{ COND string( WHEN order-orderid = order_selected THEN `true` ELSE `false` ) },| &&
             |"grp":\{"key":{ json_text( key ) },"text":{ json_text( group ) }\}\}|.

  ENDMETHOD.


  METHOD json_text.

    " a JSON string literal: the backslash and the quote escaped
    DATA(escaped) = replace( val = val sub = `\` with = `\\` occ = 0 ).
    result = |"{ replace( val = escaped sub = `"` with = `\"` occ = 0 ) }"|.

  ENDMETHOD.


  METHOD utc_date.

    " the calendar day of an epoch millisecond value, in UTC
    result = CONV d( `19700101` ).
    result = result + val DIV 86400000.

  ENDMETHOD.


  METHOD month_name.

    " the month name the original's DateFormat "MMMM" writes into a group
    " header
    DATA(months) = VALUE string_table( ( `January` ) ( `February` ) ( `March` ) ( `April` )
                                       ( `May` ) ( `June` ) ( `July` ) ( `August` )
                                       ( `September` ) ( `October` ) ( `November` ) ( `December` ) ).
    result = months[ CONV i( val+4(2) ) ].

  ENDMETHOD.


  METHOD amount.

    " formatter.currencyValue: two digits, no grouping
    result = |{ val DECIMALS = 2 NUMBER = RAW }|.

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Orders.json - the Edm.DateTime values are the
    " mock's /Date(ms)/ milliseconds, CustomerName the order's own column
    t_orders = VALUE #(
        ( orderid = 7918 customerid = `TORTU` customername = `Tortuga Restaurante` employeeid = 7424
          orderdate = `1474149600000` requireddate = `1475186400000` shippeddate = `1474840800000`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 7311 customerid = `ALFKI` customername = `Alfreds Futterkiste` employeeid = 7827
          orderdate = `1479682800000` requireddate = `1481151600000` shippeddate = `1480028400000`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 7375 customerid = `AROUT` customername = `Around the Horn` employeeid = 7424
          orderdate = `1475704800000` requireddate = `1479337200000` shippeddate = `1476396000000`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 6189 customerid = `BERGS` customername = `Berglunds snabbköp` employeeid = 7829
          orderdate = `1480287600000` requireddate = `1482274800000` shippeddate = `1480460400000`
          shipname = `1A Paket- und Lieferservice` shipaddress = `Bismarckstraße 5`
          shipcity = `Berlin` shipregion = `Berlin` shippostal = `10179` shipcountry = `Deutschland` )
        ( orderid = 3115 customerid = `BERGS` customername = `` employeeid = 7830
          orderdate = `1480806000000` requireddate = `1480978800000` shippeddate = `1482447600000`
          shipname = `1A Paket- und Lieferservice` shipaddress = `Bismarckstraße 5`
          shipcity = `Berlin` shipregion = `Berlin` shippostal = `10179` shipcountry = `Deutschland` )
        ( orderid = 2686 customerid = `BOTTM` customername = `Bottom-Dollar Markets` employeeid = 7840
          orderdate = `1477519200000` requireddate = `1478646000000` shippeddate = `1477954800000`
          shipname = `1A Paket- und Lieferservice` shipaddress = `Bismarckstraße 5`
          shipcity = `Berlin` shipregion = `Berlin` shippostal = `10179` shipcountry = `Deutschland` )
        ( orderid = 6858 customerid = `TORTU` customername = `Tortuga Restaurante` employeeid = 7840
          orderdate = `1478991600000` requireddate = `1480460400000` shippeddate = `1479078000000`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 6368 customerid = `ALFKI` customername = `Alfreds Futterkiste` employeeid = 7424
          orderdate = `1478991600000` requireddate = `1480460400000` shippeddate = `1479510000000`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 828  customerid = `AROUT` customername = `Around the Horn` employeeid = 7829
          orderdate = `1479682800000` requireddate = `1481151600000` shippeddate = `1480028400000`
          shipname = `ShipEx` shipaddress = `5th Avenue 610`
          shipcity = `New York` shipregion = `New Jersey` shippostal = `10020` shipcountry = `United Stated of America` )
        ( orderid = 7991 customerid = `BERGS` customername = `Berglunds snabbköp` employeeid = 7830
          orderdate = `1479682800000` requireddate = `1481151600000` shippeddate = `1480028400000`
          shipname = `ShipEx` shipaddress = `5th Avenue 610`
          shipcity = `New York` shipregion = `New Jersey` shippostal = `10020` shipcountry = `United Stated of America` ) ).

    " localService/mockdata/Customer.json - the list's expand of Customer
    t_customers = VALUE #(
        ( customerid = `TORTU` companyname = `Tortuga Restaurante` )
        ( customerid = `ALFKI` companyname = `Alfreds Futterkiste` )
        ( customerid = `AROUT` companyname = `Around the Horn` )
        ( customerid = `BERGS` companyname = `Berglunds snabbköp` )
        ( customerid = `BOTTM` companyname = `Bottom-Dollar Markets` ) ).
    LOOP AT t_orders REFERENCE INTO DATA(order).
      order->companyname = VALUE #( t_customers[ customerid = order->customerid ]-companyname OPTIONAL ).
    ENDLOOP.

    " localService/mockdata/Employee.json - the Photo column is empty in the
    " mock for every row
    t_employees = VALUE #(
        ( employeeid = 7424 firstname = `Jack`   lastname = `Smith`     title = `Developer` homephone = `01781163487` )
        ( employeeid = 7827 firstname = `Loura`  lastname = `Hajjar`    title = `Developer` homephone = `01781237845` )
        ( employeeid = 7829 firstname = `Steven` lastname = `Buchanan`  title = `Manager`   homephone = `01787650439` )
        ( employeeid = 7830 firstname = `Andrew` lastname = `Fuller`    title = `Designer`  homephone = `01781234598` )
        ( employeeid = 7840 firstname = `Anne`   lastname = `Dodsworth` title = `Developer` homephone = `01796577660` ) ).

    " localService/mockdata/Product.json
    t_products = VALUE #(
        ( productid = 1412 productname = `Aniseed Syrup` )
        ( productid = 5267 productname = `Uncle Bob's Organic Dried Pears` )
        ( productid = 5046 productname = `Northwoods Cranberry Sauce` )
        ( productid = 1114 productname = `Grandma's Boysenberry Spread` )
        ( productid = 5079 productname = `Chef Anton's Cajun Seasoning` )
        ( productid = 4008 productname = `Sir Rodney's Marmalade` )
        ( productid = 5672 productname = `Tunnbröd` )
        ( productid = 8486 productname = `Mascarpone Fabioli` )
        ( productid = 9505 productname = `Camembert Pierrot` )
        ( productid = 4663 productname = `Louisiana Hot Spiced Okra` ) ).

    " localService/mockdata/Order_Details.json - the Discount column is in
    " the mock and in no view of the app
    t_details = VALUE #(
        ( orderid = 7918 productid = 1412 unitprice = `65.89` quantity = 899 )
        ( orderid = 7918 productid = 5672 unitprice = `14.77` quantity = 2367 )
        ( orderid = 7918 productid = 5046 unitprice = `61.69` quantity = 867 )
        ( orderid = 7918 productid = 9505 unitprice = `3.07`  quantity = 1060 )
        ( orderid = 2686 productid = 5267 unitprice = `24.34` quantity = 7783 )
        ( orderid = 2686 productid = 1114 unitprice = `20.50` quantity = 523 )
        ( orderid = 2686 productid = 5046 unitprice = `61.69` quantity = 336 )
        ( orderid = 6858 productid = 1114 unitprice = `20.50` quantity = 2960 )
        ( orderid = 6858 productid = 4663 unitprice = `9.31`  quantity = 9491 )
        ( orderid = 6858 productid = 5672 unitprice = `14.77` quantity = 547 )
        ( orderid = 6858 productid = 4008 unitprice = `47.10` quantity = 5780 )
        ( orderid = 7311 productid = 5046 unitprice = `61.69` quantity = 6636 )
        ( orderid = 7311 productid = 1412 unitprice = `65.89` quantity = 3436 )
        ( orderid = 7311 productid = 5672 unitprice = `14.77` quantity = 8076 )
        ( orderid = 7991 productid = 4663 unitprice = `9.31`  quantity = 9491 )
        ( orderid = 7991 productid = 5672 unitprice = `14.77` quantity = 547 )
        ( orderid = 7991 productid = 4008 unitprice = `47.10` quantity = 5780 )
        ( orderid = 7991 productid = 9505 unitprice = `3.07`  quantity = 3239 )
        ( orderid = 7991 productid = 8486 unitprice = `6.31`  quantity = 5039 )
        ( orderid = 6189 productid = 5672 unitprice = `14.77` quantity = 552 )
        ( orderid = 6189 productid = 4663 unitprice = `9.31`  quantity = 1052 )
        ( orderid = 6189 productid = 5267 unitprice = `24.34` quantity = 852 )
        ( orderid = 6189 productid = 1412 unitprice = `65.89` quantity = 6752 )
        ( orderid = 828  productid = 8486 unitprice = `6.31`  quantity = 1204 )
        ( orderid = 828  productid = 1114 unitprice = `20.50` quantity = 2960 )
        ( orderid = 828  productid = 4663 unitprice = `9.31`  quantity = 9491 )
        ( orderid = 828  productid = 5672 unitprice = `14.77` quantity = 547 )
        ( orderid = 828  productid = 4008 unitprice = `47.10` quantity = 5780 )
        ( orderid = 3115 productid = 1114 unitprice = `20.50` quantity = 1530 )
        ( orderid = 3115 productid = 5079 unitprice = `62.40` quantity = 2370 )
        ( orderid = 3115 productid = 8486 unitprice = `6.31`  quantity = 2567 )
        ( orderid = 3115 productid = 4663 unitprice = `9.31`  quantity = 1809 )
        ( orderid = 3115 productid = 4008 unitprice = `47.10` quantity = 1310 )
        ( orderid = 7375 productid = 4008 unitprice = `47.10` quantity = 5780 )
        ( orderid = 7375 productid = 9505 unitprice = `3.07`  quantity = 3239 )
        ( orderid = 7375 productid = 8486 unitprice = `6.31`  quantity = 5039 )
        ( orderid = 6368 productid = 9505 unitprice = `3.07`  quantity = 3239 )
        ( orderid = 6368 productid = 8486 unitprice = `6.31`  quantity = 5039 ) ).

  ENDMETHOD.

ENDCLASS.
