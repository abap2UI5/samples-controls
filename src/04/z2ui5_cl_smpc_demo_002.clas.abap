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
    TYPES temp1_0d301326e8 TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
DATA t_items            TYPE temp1_0d301326e8.
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
    TYPES ty_t_order TYPE STANDARD TABLE OF ty_s_order WITH DEFAULT KEY.
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
    TYPES temp2_0d301326e8 TYPE STANDARD TABLE OF ty_s_customer WITH DEFAULT KEY.
DATA t_customers     TYPE temp2_0d301326e8.
    TYPES temp3_0d301326e8 TYPE STANDARD TABLE OF ty_s_employee WITH DEFAULT KEY.
DATA t_employees     TYPE temp3_0d301326e8.
    TYPES temp4_0d301326e8 TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_products      TYPE temp4_0d301326e8.
    TYPES temp5_0d301326e8 TYPE STANDARD TABLE OF ty_s_detail WITH DEFAULT KEY.
DATA t_details       TYPE temp5_0d301326e8.
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

    " the app owns the hash: the browser Back/Forward buttons and a
    " hand-edited URL round-trip as HASH_CHANGED. Queued FIRST - a route
    " below may already rewrite the hash, and without the listener in place
    " the frontend would append that value instead of writing it. The
    " registration dies with an app switch, so it is re-issued per render
    DATA temp1 TYPE string_table.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    CLEAR temp1.
    INSERT `HASH_CHANGED` INTO TABLE temp1.
    client->follow_up_action( val = client->cs_event-hash_attach_changed t_arg = temp1 ).

    " a start, a reload or a shared link: the live hash is matched like the
    " router's initialize( ) matches it
    route_hash( ).
    rows_build( ).

    
    view = z2ui5_cl_ui5_view_builder=>factory(
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
    
    fcl = view->ele( `App`
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
    DATA temp3 TYPE string_table.
    CLEAR temp3.
    INSERT `${$parameters>/filterItems}.length ? ${$parameters>/filterItems}[0].getText() : ''` INTO TABLE temp3.
    INSERT `${$parameters>/filterItems}.length ? ${$parameters>/filterItems}[0].getKey() : ''` INTO TABLE temp3.
    INSERT `${$parameters>/groupItem} ? ${$parameters>/groupItem}.getKey() : ''` INTO TABLE temp3.
    INSERT `${$parameters>/groupDescending} ? 'X' : ''` INTO TABLE temp3.
    view->ele( n = `dependents` ns = `mvc`
        )->ele( `ViewSettingsDialog`
            )->a( n = `id`              v = `viewSettingsDialog`
            )->a( n = `groupDescending` v = client->_bind( group_descending )
            )->a( n = `confirm`         v = client->_event( val   = `VIEW_SETTINGS`
                                                            t_arg = temp3 )

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

    DATA temp5 TYPE string_table.
    DATA open_filter TYPE string.
    DATA column TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA list TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp7 TYPE string_table.
    DATA temp1 TYPE string_table.
    CLEAR temp5.
    INSERT `viewSettingsDialog` INTO TABLE temp5.
    INSERT `open` INTO TABLE temp5.
    INSERT `filter` INTO TABLE temp5.
    
    open_filter = client->follow_up_action( val   = client->cs_event-control_by_id
                                                  t_arg = temp5 ).

    " the begin column: Master.view.xml and the NotFound target
    
    column = fcl->ele( n = `beginColumnPages` ns = `f` ).

    
    list = column->ele( n = `SemanticPage` ns = `semantic`
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

    
    CLEAR temp7.
    INSERT `${$parameters>/query}` INTO TABLE temp7.
    INSERT `${$parameters>/refreshButtonPressed} ? 'X' : ''` INTO TABLE temp7.
    
    CLEAR temp1.
    INSERT `viewSettingsDialog` INTO TABLE temp1.
    INSERT `open` INTO TABLE temp1.
    INSERT `group` INTO TABLE temp1.
    list->ele( `headerToolbar`
        )->ele( `OverflowToolbar`

            )->ele( `SearchField`
                )->a( n = `id`                 v = `searchField`
                )->a( n = `showRefreshButton`  b = abap_true
                )->a( n = `tooltip`            v = `Enter an order name or a part of it.`
                )->a( n = `width`              v = `100%`
                )->a( n = `value`              v = client->_bind( search_value )
                )->a( n = `search`             v = client->_event( val   = `SEARCH`
                                                                   t_arg = temp7 )

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
                                                                t_arg = temp1 )
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
    DATA column TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA header TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp9 TYPE string_table.
    DATA temp3 LIKE LINE OF temp9.
    column = fcl->ele( n = `midColumnPages` ns = `f` ).

    
    detail = column->ele( n = `SemanticPage` ns = `semantic`
        )->a( n = `id`           v = `detailPage`
        )->a( n = `core:require` v = `{DateType: 'sap/ui/model/type/Date', CurrencyType: 'sap/ui/model/type/Currency'}` ).

    detail->ele( n = `titleHeading` ns = `semantic`
        )->tag( `Title`
            )->a( n = `text` v = client->_bind( det_title ) ).

    
    header = detail->ele( n = `headerContent` ns = `semantic`
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

    
    content = detail->ele( n = `content` ns = `semantic`
        )->ele( n = `VerticalLayout` ns = `l` ).
    view_detail_tabs( content ).
    view_detail_items( content ).

    " the share action is URLHelper.triggerEmail - a frontend action that
    " reads the bound mail structure when it is pressed, no round-trip
    
    CLEAR temp9.
    INSERT `TRIGGER_EMAIL` INTO TABLE temp9.
    
    temp3 = |${ client->_bind( s_mail ) }|.
    INSERT temp3 INTO TABLE temp9.
    detail->ele( n = `sendEmailAction` ns = `semantic`
        )->tag( n = `SendEmailAction` ns = `semantic`
            )->a( n = `id`    v = `shareEmail`
            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-urlhelper
                                                            t_arg = temp9 ) ).

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
    DATA tabs TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp11 TYPE string_table.
    DATA temp4 LIKE LINE OF temp11.
    tabs = column->ele( `IconTabBar`
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
    
    CLEAR temp11.
    INSERT `TRIGGER_TEL` INTO TABLE temp11.
    
    temp4 = |${ client->_bind( s_tel ) }|.
    INSERT temp4 INTO TABLE temp11.
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
                                                                        t_arg = temp11 )
                    )->tag( n = `Title` ns = `core`
                        )->a( n = `text` v = `Picture`
                    )->tag( `Image`
                        )->a( n = `src`    v = client->_bind( det_photo )
                        )->a( n = `width`  v = `50%`
                        )->a( n = `height` v = `50%` ).

  ENDMETHOD.


  METHOD view_detail_items.

    DATA items TYPE REF TO z2ui5_cl_ui5_view_builder.
    items = column->ele( `Table`
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
        DATA temp13 TYPE string_table.

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
        
        CLEAR temp13.
        INSERT `/` INTO TABLE temp13.
        client->follow_up_action( val = client->cs_event-hash_back t_arg = temp13 ).

    ENDCASE.

    rows_build( ).
    pages_sync( ).

  ENDMETHOD.


  METHOD on_select.
    DATA hash TYPE string.

    " Master._showDetail: two columns, and navTo( "object" ) - replacing the
    " hash on a desktop, pushing it on a phone. The object route has no ?tab=
    " then, so _onObjectMatched rewrites it to tab=shipping in place: the net
    " effect is one write of the final hash
    layout = `TwoColumnsMidExpanded`.
    
    hash = |/Orders/{ orderid }/?tab=shipping|.
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
    DATA temp1 TYPE xsdboolean.
    DATA temp2 TYPE xsdboolean.
    DATA temp3 TYPE xsdboolean.
    DATA temp4 TYPE xsdboolean.
    DATA temp5 TYPE xsdboolean.
    DATA temp6 TYPE xsdboolean.
    DATA temp7 TYPE xsdboolean.

    " onConfirmViewSettingsDialog: the filter and the info bar - which shows
    " only while a filter is set, but is labelled either way
    filter_bar_label   = |Filtered by { client->get_event_arg( ) }|.
    filter_key         = client->get_event_arg( 2 ).
    
    temp1 = boolc( filter_key IS NOT INITIAL ).
    filter_bar_visible = temp1.
    
    temp2 = boolc( filter_key = `Shipped` ).
    flt_shipped        = temp2.
    
    temp3 = boolc( filter_key = `NotShipped` ).
    flt_not_shipped    = temp3.

    " _applyGrouper: the grouper's sorter REPLACES the binding's sorters -
    " the OrderID sorter of the view is gone after the first confirm
    group_key        = client->get_event_arg( 3 ).
    
    temp4 = boolc( client->get_event_arg( 4 ) = `X` ).
    group_descending = temp4.
    
    temp5 = boolc( group_key = `CompanyName` ).
    grp_customer     = temp5.
    
    temp6 = boolc( group_key = `OrderDate` ).
    grp_order        = temp6.
    
    temp7 = boolc( group_key = `ShippedDate` ).
    grp_shipped      = temp7.
    check_sorted     = abap_true.
    group_sync( abap_true ).

  ENDMETHOD.


  METHOD on_toggle_fullscreen.

    " toggleFullScreen: remember the layout on the way in, restore it on the
    " way out
    DATA temp8 TYPE xsdboolean.
    temp8 = boolc( check_fullscreen = abap_false ).
    check_fullscreen = temp8.
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
    DATA hash TYPE z2ui5_if_client=>ty_s_get-s_config-hash.
    DATA objectid TYPE string.
    DATA query TYPE string.
    DATA tab TYPE string.
    TYPES temp6 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA t_param TYPE temp6.
    DATA param LIKE LINE OF t_param.
    hash = client->get( )-s_config-hash.
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

    
    objectid = substring_after( val = hash sub = `/` ).
    
    query = ``.
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

    
    tab = ``.
    

    SPLIT query AT `&` INTO TABLE t_param.
    
    LOOP AT t_param INTO param.
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
    DATA temp15 TYPE ty_s_order.
    DATA order LIKE temp15.
      DATA temp16 TYPE z2ui5_cl_smpc_demo_002=>ty_s_order.
      DATA temp5 TYPE i.
      DATA temp17 TYPE z2ui5_cl_smpc_demo_002=>ty_s_order.

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
    
    CLEAR temp15.
    
    order = temp15.
    IF objectid CO `0123456789` AND strlen( objectid ) <= 9.
      
      CLEAR temp16.
      
      temp5 = objectid.
      
      READ TABLE t_orders INTO temp17 WITH KEY orderid = temp5.
      IF sy-subrc = 0.
        temp16 = temp17.
      ENDIF.
      order = temp16.
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
    DATA temp18 TYPE ty_s_employee.
    DATA temp19 TYPE z2ui5_cl_smpc_demo_002=>ty_s_employee.
    DATA employee LIKE temp18.
    DATA temp20 LIKE t_items.
    DATA item LIKE LINE OF t_details.
      DATA temp21 TYPE z2ui5_cl_smpc_demo_002=>ty_s_item.
      DATA temp6 TYPE z2ui5_cl_smpc_demo_002=>ty_s_item-productname.
      DATA temp7 TYPE z2ui5_cl_smpc_demo_002=>ty_s_product.
    DATA temp22 TYPE string.
    DATA config TYPE z2ui5_if_client=>ty_s_get-s_config.

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

    
    CLEAR temp18.
    
    READ TABLE t_employees INTO temp19 WITH KEY employeeid = order-employeeid.
    IF sy-subrc = 0.
      temp18 = temp19.
    ENDIF.
    
    employee = temp18.
    det_employee   = |{ employee-firstname } { employee-lastname }|.
    det_employeeid = |{ employee-employeeid }|.
    det_jobtitle   = employee-title.
    s_tel-tel      = employee-homephone.
    " formatter.handleBinaryContent: every Photo of the mock is empty, so the
    " original shows its fallback, webapp/images/Employee.png
    det_photo = `https://sdk.openui5.org/test-resources/sap/m/demokit/orderbrowser/webapp/images/Employee.png`.

    " the line items, and onListUpdateFinished's title and order total
    
    CLEAR temp20.
    t_items = temp20.
    
    LOOP AT t_details INTO item WHERE orderid = order-orderid.
      line_total = item-unitprice * item-quantity.
      total = total + line_total.
      
      CLEAR temp21.
      
      CLEAR temp6.
      
      READ TABLE t_products INTO temp7 WITH KEY productid = item-productid.
      IF sy-subrc = 0.
        temp6 = temp7-productname.
      ENDIF.
      temp21-productname = temp6.
      temp21-productid = |{ item-productid }|.
      temp21-unitprice = amount( item-unitprice ).
      temp21-quantity = |{ item-quantity }|.
      temp21-item_total = line_total.
      INSERT temp21 INTO TABLE t_items.
    ENDLOOP.
    det_total       = total.
    
    IF t_items IS INITIAL.
      temp22 = `Line Items`.
    ELSE.
      temp22 = |Line Items ({ lines( t_items ) })|.
    ENDIF.
    det_items_title = temp22.

    " _onBindingChange: the share texts, with the link to this order
    
    config = client->get( )-s_config.
    s_mail-subject = |Order { order-orderid }|.
    s_mail-body    = |Please take a look at order { order-orderid } (id: { order-orderid }) | &&
                     |{ config-origin }{ config-pathname }{ config-search }#/Orders/{ order-orderid }/?tab={ selected_tab } | &&
                     |More Information on this order: - Customer Name: { order-shipname } | &&
                     |- Customer ID: { order-customerid } - Processor ID: { order-employeeid }|.

  ENDMETHOD.


  METHOD pages_sync.
      DATA temp23 TYPE string_table.
      DATA temp25 TYPE string_table.

    " the router's target display: FlexibleColumnLayout.to( ) moves the
    " column that owns the page - issued only where the page changes
    IF page_begin <> page_begin_live.
      
      CLEAR temp23.
      INSERT `layout` INTO TABLE temp23.
      INSERT `to` INTO TABLE temp23.
      INSERT page_begin INTO TABLE temp23.
      client->follow_up_action( val = client->cs_event-control_by_id t_arg = temp23 ).
      page_begin_live = page_begin.
    ENDIF.
    IF page_mid <> page_mid_live.
      
      CLEAR temp25.
      INSERT `layout` INTO TABLE temp25.
      INSERT `to` INTO TABLE temp25.
      INSERT page_mid INTO TABLE temp25.
      client->follow_up_action( val = client->cs_event-control_by_id t_arg = temp25 ).
      page_mid_live = page_mid.
    ENDIF.

  ENDMETHOD.


  METHOD group_sync.
        DATA temp27 TYPE string_table.
      DATA temp29 TYPE string_table.

    " the grouper's sorter on the LIST BINDING: sorting on each row's group
    " object with group = X draws the original's group headers, and keeps the
    " order rows_build( ) chose. Without a grouping, a sorter on the row
    " position takes the headers away again - the original's sort( [] )
    IF group_key IS INITIAL.
      IF group_live IS NOT INITIAL.
        
        CLEAR temp27.
        INSERT `list` INTO TABLE temp27.
        INSERT `items` INTO TABLE temp27.
        INSERT `sort` INTO TABLE temp27.
        INSERT `pos` INTO TABLE temp27.
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = temp27 ).
      ENDIF.
    ELSEIF group_key <> group_live OR check_force = abap_true.
      
      CLEAR temp29.
      INSERT `list` INTO TABLE temp29.
      INSERT `items` INTO TABLE temp29.
      INSERT `sort` INTO TABLE temp29.
      INSERT `grp` INTO TABLE temp29.
      INSERT `` INTO TABLE temp29.
      INSERT `X` INTO TABLE temp29.
      client->follow_up_action( val   = client->cs_event-binding_call
                                t_arg = temp29 ).
    ENDIF.
    group_live = group_key.

  ENDMETHOD.


  METHOD rows_build.

    DATA t_order TYPE ty_t_order.

    " _applyFilterSearch: the search and the filter, ANDed as the binding
    " ANDs filters on different paths
    DATA order LIKE LINE OF t_orders.
    DATA json TYPE string.
      DATA pos LIKE sy-tabix.
    LOOP AT t_orders INTO order.
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

    
    json = ``.
    LOOP AT t_order INTO order.
      
      pos = sy-tabix.
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
    DATA state TYPE string.
    DATA text TYPE string.
      DATA margin TYPE p LENGTH 8 DECIMALS 0.
    DATA key TYPE string.
    DATA group TYPE string.
        DATA ordered TYPE d.
        DATA temp31 TYPE i.
          DATA shipped TYPE d.
          DATA temp32 TYPE i.
    DATA temp33 TYPE string.
    DATA temp8 TYPE string.
    state = `None`.
    
    text = `None`.
    IF order-shippeddate IS NOT INITIAL.
      
      margin = order-requireddate - order-shippeddate.
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
    
    key = ``.
    
    group = ``.
    CASE group_key.
      WHEN `CompanyName`.
        key   = order-companyname.
        group = order-companyname.
      WHEN `OrderDate`.
        
        ordered = utc_date( order-orderdate ).
        
        temp31 = ordered+4(2).
        key   = |{ ordered(4) }-{ temp31 }|.
        group = |Ordered in { month_name( ordered ) } { ordered(4) }|.
      WHEN `ShippedDate`.
        IF order-shippeddate IS INITIAL.
          key   = `0`.
          group = `Not Shipped Yet`.
        ELSE.
          
          shipped = utc_date( order-shippeddate ).
          
          temp32 = shipped+4(2).
          key   = |{ shipped(4) }-{ temp32 }|.
          group = |Shipped in { month_name( shipped ) } { shipped(4) }|.
        ENDIF.
    ENDCASE.

    
    IF order-shippeddate IS INITIAL.
      temp33 = `null`.
    ELSE.
      temp33 = |{ order-shippeddate }|.
    ENDIF.
    
    IF order-orderid = order_selected.
      temp8 = `true`.
    ELSE.
      temp8 = `false`.
    ENDIF.
    result = |\{"pos":{ pos },"orderid":{ order-orderid },"title":{ json_text( |Order { order-orderid }| ) },| &&
             |"orderdate":{ order-orderdate },| &&
             |"shippeddate":{ temp33 },| &&
             |"companyname":{ json_text( order-companyname ) },"state":"{ state }","text":"{ text }",| &&
             |"selected":{ temp8 },| &&
             |"grp":\{"key":{ json_text( key ) },"text":{ json_text( group ) }\}\}|.

  ENDMETHOD.


  METHOD json_text.

    " a JSON string literal: the backslash and the quote escaped
    DATA escaped TYPE string.
    escaped = replace( val = val sub = `\` with = `\\` occ = 0 ).
    result = |"{ replace( val = escaped sub = `"` with = `\"` occ = 0 ) }"|.

  ENDMETHOD.


  METHOD utc_date.

    " the calendar day of an epoch millisecond value, in UTC
    DATA temp34 TYPE d.
    temp34 = `19700101`.
    result = temp34.
    result = result + val DIV 86400000.

  ENDMETHOD.


  METHOD month_name.

    " the month name the original's DateFormat "MMMM" writes into a group
    " header
    DATA temp35 TYPE string_table.
    DATA months LIKE temp35.
    DATA temp37 TYPE i.
    FIELD-SYMBOLS <temp9> LIKE LINE OF months.
    DATA temp10 LIKE sy-tabix.
    CLEAR temp35.
    INSERT `January` INTO TABLE temp35.
    INSERT `February` INTO TABLE temp35.
    INSERT `March` INTO TABLE temp35.
    INSERT `April` INTO TABLE temp35.
    INSERT `May` INTO TABLE temp35.
    INSERT `June` INTO TABLE temp35.
    INSERT `July` INTO TABLE temp35.
    INSERT `August` INTO TABLE temp35.
    INSERT `September` INTO TABLE temp35.
    INSERT `October` INTO TABLE temp35.
    INSERT `November` INTO TABLE temp35.
    INSERT `December` INTO TABLE temp35.
    
    months = temp35.
    
    temp37 = val+4(2).
    
    
    temp10 = sy-tabix.
    READ TABLE months INDEX temp37 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    result = <temp9>.

  ENDMETHOD.


  METHOD amount.

    " formatter.currencyValue: two digits, no grouping
    result = |{ val DECIMALS = 2 NUMBER = RAW }|.

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Orders.json - the Edm.DateTime values are the
    " mock's /Date(ms)/ milliseconds, CustomerName the order's own column
    DATA temp38 TYPE z2ui5_cl_smpc_demo_002=>ty_t_order.
    DATA temp39 LIKE LINE OF temp38.
    DATA temp40 LIKE t_customers.
    DATA temp41 LIKE LINE OF temp40.
    DATA temp42 LIKE LINE OF t_orders.
    DATA order LIKE REF TO temp42.
      DATA temp43 TYPE z2ui5_cl_smpc_demo_002=>ty_s_order-companyname.
      DATA temp44 TYPE z2ui5_cl_smpc_demo_002=>ty_s_customer.
    DATA temp45 LIKE t_employees.
    DATA temp46 LIKE LINE OF temp45.
    DATA temp47 LIKE t_products.
    DATA temp48 LIKE LINE OF temp47.
    DATA temp49 LIKE t_details.
    DATA temp50 LIKE LINE OF temp49.
    CLEAR temp38.
    
    temp39-orderid = 7918.
    temp39-customerid = `TORTU`.
    temp39-customername = `Tortuga Restaurante`.
    temp39-employeeid = 7424.
    temp39-orderdate = `1474149600000`.
    temp39-requireddate = `1475186400000`.
    temp39-shippeddate = `1474840800000`.
    temp39-shipname = `ExcellentParcel`.
    temp39-shipaddress = `Tottenham Court Road`.
    temp39-shipcity = `London`.
    temp39-shipregion = `Greater London`.
    temp39-shippostal = `N170AA`.
    temp39-shipcountry = `United Kingdom`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 7311.
    temp39-customerid = `ALFKI`.
    temp39-customername = `Alfreds Futterkiste`.
    temp39-employeeid = 7827.
    temp39-orderdate = `1479682800000`.
    temp39-requireddate = `1481151600000`.
    temp39-shippeddate = `1480028400000`.
    temp39-shipname = `ExcellentParcel`.
    temp39-shipaddress = `Tottenham Court Road`.
    temp39-shipcity = `London`.
    temp39-shipregion = `Greater London`.
    temp39-shippostal = `N170AA`.
    temp39-shipcountry = `United Kingdom`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 7375.
    temp39-customerid = `AROUT`.
    temp39-customername = `Around the Horn`.
    temp39-employeeid = 7424.
    temp39-orderdate = `1475704800000`.
    temp39-requireddate = `1479337200000`.
    temp39-shippeddate = `1476396000000`.
    temp39-shipname = `ExcellentParcel`.
    temp39-shipaddress = `Tottenham Court Road`.
    temp39-shipcity = `London`.
    temp39-shipregion = `Greater London`.
    temp39-shippostal = `N170AA`.
    temp39-shipcountry = `United Kingdom`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 6189.
    temp39-customerid = `BERGS`.
    temp39-customername = `Berglunds snabbköp`.
    temp39-employeeid = 7829.
    temp39-orderdate = `1480287600000`.
    temp39-requireddate = `1482274800000`.
    temp39-shippeddate = `1480460400000`.
    temp39-shipname = `1A Paket- und Lieferservice`.
    temp39-shipaddress = `Bismarckstraße 5`.
    temp39-shipcity = `Berlin`.
    temp39-shipregion = `Berlin`.
    temp39-shippostal = `10179`.
    temp39-shipcountry = `Deutschland`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 3115.
    temp39-customerid = `BERGS`.
    temp39-customername = ``.
    temp39-employeeid = 7830.
    temp39-orderdate = `1480806000000`.
    temp39-requireddate = `1480978800000`.
    temp39-shippeddate = `1482447600000`.
    temp39-shipname = `1A Paket- und Lieferservice`.
    temp39-shipaddress = `Bismarckstraße 5`.
    temp39-shipcity = `Berlin`.
    temp39-shipregion = `Berlin`.
    temp39-shippostal = `10179`.
    temp39-shipcountry = `Deutschland`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 2686.
    temp39-customerid = `BOTTM`.
    temp39-customername = `Bottom-Dollar Markets`.
    temp39-employeeid = 7840.
    temp39-orderdate = `1477519200000`.
    temp39-requireddate = `1478646000000`.
    temp39-shippeddate = `1477954800000`.
    temp39-shipname = `1A Paket- und Lieferservice`.
    temp39-shipaddress = `Bismarckstraße 5`.
    temp39-shipcity = `Berlin`.
    temp39-shipregion = `Berlin`.
    temp39-shippostal = `10179`.
    temp39-shipcountry = `Deutschland`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 6858.
    temp39-customerid = `TORTU`.
    temp39-customername = `Tortuga Restaurante`.
    temp39-employeeid = 7840.
    temp39-orderdate = `1478991600000`.
    temp39-requireddate = `1480460400000`.
    temp39-shippeddate = `1479078000000`.
    temp39-shipname = `ExcellentParcel`.
    temp39-shipaddress = `Tottenham Court Road`.
    temp39-shipcity = `London`.
    temp39-shipregion = `Greater London`.
    temp39-shippostal = `N170AA`.
    temp39-shipcountry = `United Kingdom`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 6368.
    temp39-customerid = `ALFKI`.
    temp39-customername = `Alfreds Futterkiste`.
    temp39-employeeid = 7424.
    temp39-orderdate = `1478991600000`.
    temp39-requireddate = `1480460400000`.
    temp39-shippeddate = `1479510000000`.
    temp39-shipname = `ExcellentParcel`.
    temp39-shipaddress = `Tottenham Court Road`.
    temp39-shipcity = `London`.
    temp39-shipregion = `Greater London`.
    temp39-shippostal = `N170AA`.
    temp39-shipcountry = `United Kingdom`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 828.
    temp39-customerid = `AROUT`.
    temp39-customername = `Around the Horn`.
    temp39-employeeid = 7829.
    temp39-orderdate = `1479682800000`.
    temp39-requireddate = `1481151600000`.
    temp39-shippeddate = `1480028400000`.
    temp39-shipname = `ShipEx`.
    temp39-shipaddress = `5th Avenue 610`.
    temp39-shipcity = `New York`.
    temp39-shipregion = `New Jersey`.
    temp39-shippostal = `10020`.
    temp39-shipcountry = `United Stated of America`.
    INSERT temp39 INTO TABLE temp38.
    temp39-orderid = 7991.
    temp39-customerid = `BERGS`.
    temp39-customername = `Berglunds snabbköp`.
    temp39-employeeid = 7830.
    temp39-orderdate = `1479682800000`.
    temp39-requireddate = `1481151600000`.
    temp39-shippeddate = `1480028400000`.
    temp39-shipname = `ShipEx`.
    temp39-shipaddress = `5th Avenue 610`.
    temp39-shipcity = `New York`.
    temp39-shipregion = `New Jersey`.
    temp39-shippostal = `10020`.
    temp39-shipcountry = `United Stated of America`.
    INSERT temp39 INTO TABLE temp38.
    t_orders = temp38.

    " localService/mockdata/Customer.json - the list's expand of Customer
    
    CLEAR temp40.
    
    temp41-customerid = `TORTU`.
    temp41-companyname = `Tortuga Restaurante`.
    INSERT temp41 INTO TABLE temp40.
    temp41-customerid = `ALFKI`.
    temp41-companyname = `Alfreds Futterkiste`.
    INSERT temp41 INTO TABLE temp40.
    temp41-customerid = `AROUT`.
    temp41-companyname = `Around the Horn`.
    INSERT temp41 INTO TABLE temp40.
    temp41-customerid = `BERGS`.
    temp41-companyname = `Berglunds snabbköp`.
    INSERT temp41 INTO TABLE temp40.
    temp41-customerid = `BOTTM`.
    temp41-companyname = `Bottom-Dollar Markets`.
    INSERT temp41 INTO TABLE temp40.
    t_customers = temp40.
    
    
    LOOP AT t_orders REFERENCE INTO order.
      
      CLEAR temp43.
      
      READ TABLE t_customers INTO temp44 WITH KEY customerid = order->customerid.
      IF sy-subrc = 0.
        temp43 = temp44-companyname.
      ENDIF.
      order->companyname = temp43.
    ENDLOOP.

    " localService/mockdata/Employee.json - the Photo column is empty in the
    " mock for every row
    
    CLEAR temp45.
    
    temp46-employeeid = 7424.
    temp46-firstname = `Jack`.
    temp46-lastname = `Smith`.
    temp46-title = `Developer`.
    temp46-homephone = `01781163487`.
    INSERT temp46 INTO TABLE temp45.
    temp46-employeeid = 7827.
    temp46-firstname = `Loura`.
    temp46-lastname = `Hajjar`.
    temp46-title = `Developer`.
    temp46-homephone = `01781237845`.
    INSERT temp46 INTO TABLE temp45.
    temp46-employeeid = 7829.
    temp46-firstname = `Steven`.
    temp46-lastname = `Buchanan`.
    temp46-title = `Manager`.
    temp46-homephone = `01787650439`.
    INSERT temp46 INTO TABLE temp45.
    temp46-employeeid = 7830.
    temp46-firstname = `Andrew`.
    temp46-lastname = `Fuller`.
    temp46-title = `Designer`.
    temp46-homephone = `01781234598`.
    INSERT temp46 INTO TABLE temp45.
    temp46-employeeid = 7840.
    temp46-firstname = `Anne`.
    temp46-lastname = `Dodsworth`.
    temp46-title = `Developer`.
    temp46-homephone = `01796577660`.
    INSERT temp46 INTO TABLE temp45.
    t_employees = temp45.

    " localService/mockdata/Product.json
    
    CLEAR temp47.
    
    temp48-productid = 1412.
    temp48-productname = `Aniseed Syrup`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 5267.
    temp48-productname = `Uncle Bob's Organic Dried Pears`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 5046.
    temp48-productname = `Northwoods Cranberry Sauce`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 1114.
    temp48-productname = `Grandma's Boysenberry Spread`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 5079.
    temp48-productname = `Chef Anton's Cajun Seasoning`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 4008.
    temp48-productname = `Sir Rodney's Marmalade`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 5672.
    temp48-productname = `Tunnbröd`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 8486.
    temp48-productname = `Mascarpone Fabioli`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 9505.
    temp48-productname = `Camembert Pierrot`.
    INSERT temp48 INTO TABLE temp47.
    temp48-productid = 4663.
    temp48-productname = `Louisiana Hot Spiced Okra`.
    INSERT temp48 INTO TABLE temp47.
    t_products = temp47.

    " localService/mockdata/Order_Details.json - the Discount column is in
    " the mock and in no view of the app
    
    CLEAR temp49.
    
    temp50-orderid = 7918.
    temp50-productid = 1412.
    temp50-unitprice = `65.89`.
    temp50-quantity = 899.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7918.
    temp50-productid = 5672.
    temp50-unitprice = `14.77`.
    temp50-quantity = 2367.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7918.
    temp50-productid = 5046.
    temp50-unitprice = `61.69`.
    temp50-quantity = 867.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7918.
    temp50-productid = 9505.
    temp50-unitprice = `3.07`.
    temp50-quantity = 1060.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 2686.
    temp50-productid = 5267.
    temp50-unitprice = `24.34`.
    temp50-quantity = 7783.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 2686.
    temp50-productid = 1114.
    temp50-unitprice = `20.50`.
    temp50-quantity = 523.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 2686.
    temp50-productid = 5046.
    temp50-unitprice = `61.69`.
    temp50-quantity = 336.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6858.
    temp50-productid = 1114.
    temp50-unitprice = `20.50`.
    temp50-quantity = 2960.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6858.
    temp50-productid = 4663.
    temp50-unitprice = `9.31`.
    temp50-quantity = 9491.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6858.
    temp50-productid = 5672.
    temp50-unitprice = `14.77`.
    temp50-quantity = 547.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6858.
    temp50-productid = 4008.
    temp50-unitprice = `47.10`.
    temp50-quantity = 5780.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7311.
    temp50-productid = 5046.
    temp50-unitprice = `61.69`.
    temp50-quantity = 6636.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7311.
    temp50-productid = 1412.
    temp50-unitprice = `65.89`.
    temp50-quantity = 3436.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7311.
    temp50-productid = 5672.
    temp50-unitprice = `14.77`.
    temp50-quantity = 8076.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7991.
    temp50-productid = 4663.
    temp50-unitprice = `9.31`.
    temp50-quantity = 9491.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7991.
    temp50-productid = 5672.
    temp50-unitprice = `14.77`.
    temp50-quantity = 547.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7991.
    temp50-productid = 4008.
    temp50-unitprice = `47.10`.
    temp50-quantity = 5780.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7991.
    temp50-productid = 9505.
    temp50-unitprice = `3.07`.
    temp50-quantity = 3239.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7991.
    temp50-productid = 8486.
    temp50-unitprice = `6.31`.
    temp50-quantity = 5039.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6189.
    temp50-productid = 5672.
    temp50-unitprice = `14.77`.
    temp50-quantity = 552.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6189.
    temp50-productid = 4663.
    temp50-unitprice = `9.31`.
    temp50-quantity = 1052.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6189.
    temp50-productid = 5267.
    temp50-unitprice = `24.34`.
    temp50-quantity = 852.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6189.
    temp50-productid = 1412.
    temp50-unitprice = `65.89`.
    temp50-quantity = 6752.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 828.
    temp50-productid = 8486.
    temp50-unitprice = `6.31`.
    temp50-quantity = 1204.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 828.
    temp50-productid = 1114.
    temp50-unitprice = `20.50`.
    temp50-quantity = 2960.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 828.
    temp50-productid = 4663.
    temp50-unitprice = `9.31`.
    temp50-quantity = 9491.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 828.
    temp50-productid = 5672.
    temp50-unitprice = `14.77`.
    temp50-quantity = 547.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 828.
    temp50-productid = 4008.
    temp50-unitprice = `47.10`.
    temp50-quantity = 5780.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 3115.
    temp50-productid = 1114.
    temp50-unitprice = `20.50`.
    temp50-quantity = 1530.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 3115.
    temp50-productid = 5079.
    temp50-unitprice = `62.40`.
    temp50-quantity = 2370.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 3115.
    temp50-productid = 8486.
    temp50-unitprice = `6.31`.
    temp50-quantity = 2567.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 3115.
    temp50-productid = 4663.
    temp50-unitprice = `9.31`.
    temp50-quantity = 1809.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 3115.
    temp50-productid = 4008.
    temp50-unitprice = `47.10`.
    temp50-quantity = 1310.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7375.
    temp50-productid = 4008.
    temp50-unitprice = `47.10`.
    temp50-quantity = 5780.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7375.
    temp50-productid = 9505.
    temp50-unitprice = `3.07`.
    temp50-quantity = 3239.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 7375.
    temp50-productid = 8486.
    temp50-unitprice = `6.31`.
    temp50-quantity = 5039.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6368.
    temp50-productid = 9505.
    temp50-unitprice = `3.07`.
    temp50-quantity = 3239.
    INSERT temp50 INTO TABLE temp49.
    temp50-orderid = 6368.
    temp50-productid = 8486.
    temp50-unitprice = `6.31`.
    temp50-quantity = 5039.
    INSERT temp50 INTO TABLE temp49.
    t_details = temp49.

  ENDMETHOD.

ENDCLASS.
