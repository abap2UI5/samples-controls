" @keywords browse orders app viewsettingsdialog viewsettingsfilteritem viewsettingsitem flexiblecolumnlayout semanticpage title list toolbar overflowtoolbar
" @summary Master-detail app for browsing orders. - the UI5 demo app "Browse Orders", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Browse Orders (sap.m/orderbrowser) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Browse Orders</p>
"!
"! The UI5 demo app Browse Orders - the master-detail showcase of the demo kit
"! - rebuilt as ONE abap2UI5 class: a FlexibleColumnLayout with the order list
"! on the left and the order on the right, search, a ViewSettingsDialog that
"! filters and groups, the delivery-state formatter, the line-item table with
"! its running total, and the two detail tabs (shipping address, processor).
"! Selecting an order opens the second column, the column actions switch
"! between one column, two columns and full screen, and the URL follows over
"! hash_set - the deep link of the original's router.
"!
"! Where it differs from the original, and why:
"!
"!  - the OData V2 service and its mock server become ABAP data. The original
"!    expands Customer into the list and reads Order_Details, Product and
"!    Employee through navigation properties; here model_init holds the five
"!    mock files and the joins happen where the data is.
"!  - search and filter run in ABAP; GROUPING stays on the client, because a
"!    UI5 group header is made by the list binding and not by the model:
"!    cs_event-binding_call sorts the bound aggregation with group = X, on a
"!    column this class precomputes so the header text reads exactly as the
"!    original's group functions write it ("Ordered in September 2016").
"!    A view rebuild loses that client-side sorter, so view_display re-issues
"!    it whenever a grouping is active.
"!  - the formatter module is business logic and moves to the backend: the
"!    delivery state and text, the line-item totals and the order total are
"!    computed in ABAP and bound as finished values.
"!  - dates are formatted in ABAP as ISO strings rather than by the UI5 Date
"!    type in the browser, so they read the same in every locale - and, unlike
"!    the original's short/medium styles, they do not follow the browser.
"!  - the two detail tabs are the content of their IconTabFilters instead of
"!    two routing targets displayed into the tab: one view, no round-trip on
"!    a tab switch, same result on screen.
"!  - the processor's photo is dropped. The formatter builds a data: URL from
"!    a base64 column the mock does not fill (every Photo is empty), so the
"!    original renders its fallback image - a file this archive does not carry.
"!  - the IllustratedMessage of the empty list is @since 1.98 and this package
"!    holds the 1.71 floor, so the list carries a plain noDataText.
"!  - the share menu and the phone link open a mailto: / tel: URL from the
"!    client, which is what sap.m.URLHelper does one layer down. Not verified
"!    in a running system.
"!  - the search matches the order NUMBER as well as the customer, and takes
"!    the customer from the joined Customer/CompanyName. The original filters
"!    Orders/CustomerName, the order's own copy of that name - which one mock
"!    row leaves empty (order 3115), so a search for its customer finds it
"!    here and not there. The tooltip of both says "order name".
"!  - amounts carry two decimals and no thousands separator, where the
"!    original's Currency type groups them for the browser's locale - the same
"!    reason the dates are ISO.
"!  - the i18n resource bundle becomes literals, and the busy handling has
"!    nothing to do here - the server holds the data the view renders.
"!
"! Original: src/sap.m/test/sap/m/demokit/orderbrowser in OpenUI5, archived
"! under ui5/demoapps/sap.m/orderbrowser.
"! Demo apps: https://sdk.openui5.org/demoapps
CLASS z2ui5_cl_smpc_demo_002 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_row,
        orderid        TYPE i,
        title          TYPE string,
        orderdate      TYPE string,
        companyname    TYPE string,
        shipped        TYPE string,
        delivery_state TYPE string,
        delivery_text  TYPE string,
        order_period   TYPE string,
        shipped_period TYPE string,
        selected       TYPE abap_bool,
      END OF ty_s_row.
    TYPES:
      BEGIN OF ty_s_item,
        productname TYPE string,
        productid   TYPE string,
        unitprice   TYPE string,
        quantity    TYPE string,
        item_total  TYPE string,
      END OF ty_s_item.

    DATA t_rows             TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA t_items            TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
    DATA layout             TYPE string VALUE `OneColumn`.
    DATA title_count        TYPE string.
    DATA no_data_text       TYPE string.
    DATA search_term        TYPE string.
    DATA filter_bar_visible TYPE abap_bool.
    DATA filter_bar_label   TYPE string.
    DATA selected_tab       TYPE string VALUE `shipping`.
    DATA det_title          TYPE string.
    DATA det_customer       TYPE string.
    DATA det_orderdate      TYPE string.
    DATA det_shipped        TYPE string.
    DATA det_total          TYPE string.
    DATA det_currency       TYPE string VALUE `EUR`.
    DATA det_items_title    TYPE string.
    DATA det_shipname       TYPE string.
    DATA det_shipaddress    TYPE string.
    DATA det_shipzipcity    TYPE string.
    DATA det_shipregion     TYPE string.
    DATA det_shipcountry    TYPE string.
    DATA det_employee       TYPE string.
    DATA det_employeeid     TYPE string.
    DATA det_jobtitle       TYPE string.
    DATA det_phone          TYPE string.
    DATA check_fullscreen   TYPE abap_bool.

  PROTECTED SECTION.
    " the grouping the LIST BINDING carries right now - bookkeeping the view
    " never binds, so it is no model field; PROTECTED rather than PRIVATE
    " because the draft serializer reaches every section but the private one
    DATA group_live TYPE string.

    TYPES:
      BEGIN OF ty_s_order,
        orderid      TYPE i,
        customerid   TYPE string,
        employeeid   TYPE i,
        orderdate    TYPE d,
        requireddate TYPE d,
        shippeddate  TYPE d,
        shipname     TYPE string,
        shipaddress  TYPE string,
        shipcity     TYPE string,
        shipregion   TYPE string,
        shippostal   TYPE string,
        shipcountry  TYPE string,
      END OF ty_s_order.
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
    TYPES ty_amount TYPE p LENGTH 12 DECIMALS 2.
    TYPES:
      BEGIN OF ty_s_detail,
        orderid   TYPE i,
        productid TYPE i,
        unitprice TYPE ty_amount,
        quantity  TYPE i,
      END OF ty_s_detail.

    DATA client       TYPE REF TO z2ui5_if_client.
    DATA t_orders     TYPE STANDARD TABLE OF ty_s_order WITH EMPTY KEY.
    DATA t_customers  TYPE STANDARD TABLE OF ty_s_customer WITH EMPTY KEY.
    DATA t_employees  TYPE STANDARD TABLE OF ty_s_employee WITH EMPTY KEY.
    DATA t_products   TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_details    TYPE STANDARD TABLE OF ty_s_detail WITH EMPTY KEY.
    DATA filter_key   TYPE string.
    DATA group_key    TYPE string.
    DATA order_shown  TYPE i.

    METHODS view_display.
    METHODS group_apply.
    METHODS on_event.
    METHODS hash_apply.
    METHODS detail_show
      IMPORTING
        orderid TYPE i.
    METHODS list_refresh.
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
      list_refresh( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " a reload or a shared link: the live hash names the order to show, the
    " routeMatched of a cold start
    hash_apply( ).

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

    " the dialog the controller loads as a fragment in the original, declared
    " in the view's dependents aggregation and opened by id
    view->ele( n = `dependents` ns = `mvc`
        )->ele( `ViewSettingsDialog`
            )->a( n = `id`      v = `viewSettingsDialog`
            " `${ }` wraps the BINDING, not the expression around it: the
            " corpus idiom is `${$parameters>/selectedItem}.getKey()` (apps
            " 521, 534, 546, 558). Wrapped once more, as these three were, the
            " whole attribute is a nested binding UI5 cannot parse - pressing
            " OK then fires nothing at all, and the dialog looked broken while
            " the filter, group and info-bar logic behind it was correct
            )->a( n = `confirm` v = client->_event( val   = `VIEW_SETTINGS`
                                                    t_arg = VALUE #( ( `${$parameters>/filterItems}.length ? ${$parameters>/filterItems}[0].getText() : ''` )
                                                                     ( `${$parameters>/filterItems}.length ? ${$parameters>/filterItems}[0].getKey() : ''` )
                                                                     ( `${$parameters>/groupItem} ? ${$parameters>/groupItem}.getKey() : ''` ) ) )

            )->ele( `filterItems`
                )->ele( `ViewSettingsFilterItem`
                    )->a( n = `id`          v = `filterItems`
                    )->a( n = `text`        v = `Orders`
                    )->a( n = `key`         v = `Orders`
                    )->a( n = `multiSelect` b = abap_false

                    )->ele( `items`
                        )->tag( `ViewSettingsItem`
                            )->a( n = `id`   v = `viewFilter1`
                            )->a( n = `text` v = `Only Shipped Orders`
                            )->a( n = `key`  v = `Shipped`
                        )->tag( `ViewSettingsItem`
                            )->a( n = `id`   v = `viewFilter2`
                            )->a( n = `text` v = `Only Orders without Shipment`
                            )->a( n = `key`  v = `NotShipped`

                    )->end(
                )->end(
            )->end(
            )->ele( `groupItems`
                )->tag( `ViewSettingsItem`
                    )->a( n = `text` v = `Group by Customer`
                    )->a( n = `key`  v = `CompanyName`
                )->tag( `ViewSettingsItem`
                    )->a( n = `text` v = `Group by Order Period`
                    )->a( n = `key`  v = `OrderDate`
                )->tag( `ViewSettingsItem`
                    )->a( n = `text` v = `Group by Shipped Period`
                    )->a( n = `key`  v = `ShippedDate` ).

    DATA(fcl) = view->ele( `App`
        )->a( n = `id` v = `app`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`               v = `layout`
            )->a( n = `layout`           v = client->_bind( layout )
            )->a( n = `backgroundDesign` v = `Translucent` ).

    " ------------------------------------------------------------ master
    DATA(list) = fcl->ele( n = `beginColumnPages` ns = `f`
        )->ele( n = `SemanticPage` ns = `semantic`
            )->a( n = `id` v = `page`

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
                    )->a( n = `noDataText`          v = client->_bind( no_data_text )
                    )->a( n = `mode`                v = `SingleSelectMaster`
                    )->a( n = `growing`             b = abap_true
                    )->a( n = `growingScrollToLoad` b = abap_true
                    )->a( n = `selectionChange`     v = client->_event( `SELECT` )
                    )->a( n = `items`               v = client->_bind( t_rows ) ).

    list->ele( `infoToolbar`
        )->ele( `Toolbar`
            )->a( n = `id`      v = `filterBar`
            )->a( n = `active`  b = abap_true
            )->a( n = `visible` v = client->_bind( filter_bar_visible )
            )->a( n = `press`   v = client->_event( val = `OPEN_VIEW_SETTINGS` arg = `filter` )

            )->tag( `Title`
                )->a( n = `id`   v = `filterBarLabel`
                )->a( n = `text` v = client->_bind( filter_bar_label ) ).

    list->ele( `headerToolbar`
        )->ele( `OverflowToolbar`

            )->ele( `SearchField`
                )->a( n = `id`      v = `searchField`
                )->a( n = `tooltip` v = `Enter an order name or a part of it.`
                )->a( n = `width`   v = `100%`
                )->a( n = `value`   v = client->_bind( search_term )
                )->a( n = `search`  v = client->_event( `SEARCH` )

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
                )->a( n = `icon`  v = `sap-icon://filter`
                )->a( n = `type`  v = `Transparent`
                )->a( n = `press` v = client->_event( val = `OPEN_VIEW_SETTINGS` arg = `filter` )
            )->tag( `Button`
                )->a( n = `id`    v = `groupButton`
                )->a( n = `icon`  v = `sap-icon://group-2`
                )->a( n = `type`  v = `Transparent`
                )->a( n = `press` v = client->_event( val = `OPEN_VIEW_SETTINGS` arg = `group` ) ).

    list->ele( `items`
        )->ele( `ObjectListItem`
            )->a( n = `type`     v = `Inactive`
            )->a( n = `selected` v = `{SELECTED}`
            )->a( n = `title`    v = `{TITLE}`
            )->a( n = `number`   v = `{ORDERDATE}`

            )->ele( `firstStatus`
                )->tag( `ObjectStatus`
                    )->a( n = `state` v = `{DELIVERY_STATE}`
                    )->a( n = `text`  v = `{DELIVERY_TEXT}`

            )->end(
            )->ele( `attributes`
                )->tag( `ObjectAttribute`
                    )->a( n = `id`   v = `companyName`
                    )->a( n = `text` v = `{COMPANYNAME}`
                )->tag( `ObjectAttribute`
                    )->a( n = `title` v = `Shipped`
                    )->a( n = `text`  v = `{SHIPPED}` ).

    " ------------------------------------------------------------ detail
    DATA(detail) = fcl->ele( n = `midColumnPages` ns = `f`
        )->ele( n = `SemanticPage` ns = `semantic`
            )->a( n = `id` v = `detailPage` ).

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
            )->a( n = `text`  v = client->_bind( det_orderdate )
        )->tag( `ObjectAttribute`
            )->a( n = `title` v = `Shipped`
            )->a( n = `text`  v = client->_bind( det_shipped ) ).

    header->ele( n = `VerticalLayout` ns = `l`
        )->tag( `Label`
            )->a( n = `text` v = `Price`
        )->tag( `ObjectNumber`
            )->a( n = `number` v = client->_bind( det_total )
            )->a( n = `unit`   v = client->_bind( det_currency ) ).

    DATA(column) = detail->ele( n = `content` ns = `semantic`
        )->ele( n = `VerticalLayout` ns = `l` ).

    DATA(tabs) = column->ele( `IconTabBar`
        )->a( n = `id`                     v = `iconTabBar`
        )->a( n = `headerBackgroundDesign` v = `Transparent`
        )->a( n = `selectedKey`            v = client->_bind( selected_tab )

        )->ele( `items` ).

    " the original displays the two tab pages as routing targets; here they
    " are the content of their tab, so a switch costs no round-trip
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
                        )->a( n = `text`  v = client->_bind( det_phone )
                        )->a( n = `press` v = client->_event( `PHONE` ) ).

    DATA(items) = column->ele( `Table`
        )->a( n = `id`         v = `lineItemsList`
        )->a( n = `class`      v = `sapUiSmallMarginTop`
        )->a( n = `width`      v = `auto`
        )->a( n = `noDataText` v = `No line items`
        )->a( n = `items`      v = client->_bind( t_items ) ).

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
                    )->a( n = `number` v = `{ITEM_TOTAL}`
                    )->a( n = `unit`   v = client->_bind( det_currency ) ).

    detail->ele( n = `sendEmailAction` ns = `semantic`
        )->tag( n = `SendEmailAction` ns = `semantic`
            )->a( n = `id`    v = `shareEmail`
            )->a( n = `press` v = client->_event( `SHARE_EMAIL` ) ).

    detail->ele( n = `closeAction` ns = `semantic`
        )->tag( n = `CloseAction` ns = `semantic`
            )->a( n = `id`    v = `closeColumn`
            )->a( n = `press` v = client->_event( `CLOSE_DETAIL` ) ).

    detail->ele( n = `fullScreenAction` ns = `semantic`
        )->tag( n = `FullScreenAction` ns = `semantic`
            )->a( n = `id`      v = `enterFullScreen`
            )->a( n = `visible` v = |\{= !${ client->_bind( check_fullscreen ) } \}|
            )->a( n = `press`   v = client->_event( `TOGGLE_FULLSCREEN` ) ).

    detail->ele( n = `exitFullScreenAction` ns = `semantic`
        )->tag( n = `ExitFullScreenAction` ns = `semantic`
            )->a( n = `id`      v = `exitFullScreen`
            )->a( n = `visible` v = client->_bind( check_fullscreen )
            )->a( n = `press`   v = client->_event( `TOGGLE_FULLSCREEN` ) ).

    client->view_display( view->stringify( ) ).

    " the browser Back/Forward buttons and a hand-edited URL round-trip as
    " HASH_CHANGED; the registration dies with an app switch, so it is
    " re-issued per render
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = VALUE #( ( `HASH_CHANGED` ) ) ).

    " a grouping is a sorter on the LIST BINDING, not on the model: a rebuilt
    " view starts ungrouped, so an active grouping is re-applied here
    group_live = ``.
    group_apply( ).

  ENDMETHOD.


  METHOD group_apply.

    IF group_key IS INITIAL.
      " the sorter lives on the list binding and binding_call has no form
      " that takes it off again (the original calls oBinding.sort( [] )): a
      " grouping the user just cleared in the dialog stays on the list until
      " the view is rebuilt - so rebuild it, once, when there is one to clear
      IF group_live IS NOT INITIAL.
        view_display( ).
      ENDIF.
      RETURN.
    ENDIF.
    group_live = group_key.

    " the client-side equivalent of the original's new Sorter(path, false,
    " groupFunction): group = X makes UI5 draw a GroupHeaderListItem per value
    client->follow_up_action( val   = client->cs_event-binding_call
                              t_arg = VALUE #( ( `list` )
                                               ( `items` )
                                               ( `sort` )
                                               ( COND #( WHEN group_key = `CompanyName`  THEN `COMPANYNAME`
                                                         WHEN group_key = `OrderDate`    THEN `ORDER_PERIOD`
                                                         ELSE `SHIPPED_PERIOD` ) )
                                               ( `` )
                                               ( `X` ) ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SEARCH`.
        list_refresh( ).

      WHEN `SELECT`.
        " the list carries the selection back in the bound row field, so the
        " backend reads it rather than asking the control
        READ TABLE t_rows INTO DATA(row) WITH KEY selected = abap_true.
        IF sy-subrc = 0.
          detail_show( row-orderid ).
        ENDIF.

      WHEN `OPEN_VIEW_SETTINGS`.
        " onOpenViewSettings picks the dialog PAGE from the button that fired
        " it - a button id matching "sort"/"group" opens that tab, everything
        " else (the info bar included, which is a Toolbar rather than a
        " Button) opens "filter". The port carries the same decision as the
        " event argument, so the group button lands on the group page instead
        " of on the dialog's first one
        DATA(dialog_tab) = client->get_event_arg( ).
        IF dialog_tab IS INITIAL.
          dialog_tab = `filter`.
        ENDIF.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `viewSettingsDialog` ) ( `open` ) ( dialog_tab ) ) ).

      WHEN `VIEW_SETTINGS`.
        " the selected filter item's TEXT for the info bar, and the chosen
        " filter and group KEYS for the work - the three the original reads
        " off the event. Not `filterString`, which UI5 composes as "Filtered
        " By: Orders (Only Shipped Orders)" and which the original does not
        " use: it joins the item texts itself, so its bar reads "Filtered by
        " Only Shipped Orders"
        filter_bar_label   = |Filtered by { client->get_event_arg( ) }|.
        filter_bar_visible = xsdbool( client->get_event_arg( ) IS NOT INITIAL ).
        filter_key         = client->get_event_arg( 2 ).
        group_key          = client->get_event_arg( 3 ).
        list_refresh( ).
        group_apply( ).

      WHEN `HASH_CHANGED`.
        hash_apply( ).

      WHEN `CLOSE_DETAIL`.
        order_shown      = 0.
        check_fullscreen = abap_false.
        layout           = `OneColumn`.
        " an explicit work area rather than `FROM VALUE #( ... )`: the 702
        " downport cannot infer the `#` of a VALUE constructor in a MODIFY
        " source and emitted `type not found: #`, so the transpiled backend
        " refused the class
        DATA(clear_row) = VALUE ty_s_row( ).
        MODIFY t_rows FROM clear_row TRANSPORTING selected WHERE selected = abap_true.
        client->hash_set( `/` ).

      WHEN `TOGGLE_FULLSCREEN`.
        check_fullscreen = xsdbool( check_fullscreen = abap_false ).
        layout           = COND #( WHEN check_fullscreen = abap_true THEN `MidColumnFullScreen` ELSE `TwoColumnsMidExpanded` ).

      WHEN `PHONE`.
        client->follow_up_action( val   = client->cs_event-open_new_tab
                                  t_arg = VALUE #( ( |tel:{ det_phone }| ) ) ).

      WHEN `SHARE_EMAIL`.
        client->follow_up_action( val   = client->cs_event-open_new_tab
                                  t_arg = VALUE #( ( |mailto:?subject=Order%20{ order_shown }| ) ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD hash_apply.

    " '/Orders/<id>' is the detail column, everything else the list alone
    DATA(hash) = client->get( )-s_config-hash.
    IF hash CS `/Orders/`.
      DATA(id) = substring_after( val = hash sub = `/Orders/` ).
      IF id CO `0123456789` AND id IS NOT INITIAL.
        detail_show( CONV i( id ) ).
        RETURN.
      ENDIF.
    ENDIF.

    order_shown = 0.
    layout      = `OneColumn`.

  ENDMETHOD.


  METHOD detail_show.

    DATA total      TYPE ty_amount.
    DATA line_total TYPE ty_amount.

    ASSIGN t_orders[ orderid = orderid ] TO FIELD-SYMBOL(<order>).
    IF <order> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    order_shown  = orderid.
    det_title    = |Order { orderid }|.
    det_customer = VALUE #( t_customers[ customerid = <order>-customerid ]-companyname OPTIONAL ).
    det_orderdate = |{ <order>-orderdate DATE = ISO }|.
    det_shipped  = COND #( WHEN <order>-shippeddate IS INITIAL
                           THEN `Not shipped yet`
                           ELSE |{ <order>-shippeddate DATE = ISO }| ).

    det_shipname    = <order>-shipname.
    det_shipaddress = <order>-shipaddress.
    det_shipzipcity = |{ <order>-shippostal } { <order>-shipcity }|.
    det_shipregion  = <order>-shipregion.
    det_shipcountry = <order>-shipcountry.

    ASSIGN t_employees[ employeeid = <order>-employeeid ] TO FIELD-SYMBOL(<employee>).
    IF <employee> IS ASSIGNED.
      det_employee   = |{ <employee>-firstname } { <employee>-lastname }|.
      det_employeeid = |{ <employee>-employeeid }|.
      det_jobtitle   = <employee>-title.
      det_phone      = <employee>-homephone.
    ENDIF.

    " the line items, and the order total the original reduces on the client
    t_items = VALUE #( ).
    LOOP AT t_details INTO DATA(item) WHERE orderid = orderid.
      line_total = item-unitprice * item-quantity.
      total = total + line_total.
      INSERT VALUE #( productname = VALUE #( t_products[ productid = item-productid ]-productname OPTIONAL )
                      productid   = |{ item-productid }|
                      unitprice   = amount( item-unitprice )
                      quantity    = |{ item-quantity }|
                      item_total  = amount( line_total ) ) INTO TABLE t_items.
    ENDLOOP.
    det_total       = amount( total ).
    det_items_title = COND #( WHEN t_items IS INITIAL THEN `Line Items` ELSE |Line Items ({ lines( t_items ) })| ).

    layout = COND #( WHEN check_fullscreen = abap_true THEN `MidColumnFullScreen` ELSE `TwoColumnsMidExpanded` ).

    " what the original's ListSelector does after the route matched: the order
    " on show is the selected row of the master list. A click already carries
    " the flag back, a COLD DEEP LINK does not - list_refresh( ) ran before
    " hash_apply( ) knew which order it is - and the list came up with nothing
    " marked. An explicit work area rather than `FROM VALUE #( )`: see
    " CLOSE_DETAIL on what the 702 downport makes of the inline form
    DATA(clear_row) = VALUE ty_s_row( ).
    MODIFY t_rows FROM clear_row TRANSPORTING selected WHERE selected = abap_true.
    ASSIGN t_rows[ orderid = orderid ] TO FIELD-SYMBOL(<row>).
    IF <row> IS ASSIGNED.
      <row>-selected = abap_true.
    ENDIF.

    " the router's navTo: a pushed history entry, and the deep link of the
    " original
    client->hash_set( |/Orders/{ orderid }| ).

  ENDMETHOD.


  METHOD list_refresh.

    t_rows = VALUE #( ).

    LOOP AT t_orders INTO DATA(order).
      DATA(company) = VALUE string( t_customers[ customerid = order-customerid ]-companyname OPTIONAL ).

      CASE filter_key.
        WHEN `Shipped`.
          IF order-shippeddate IS INITIAL.
            CONTINUE.
          ENDIF.
        WHEN `NotShipped`.
          IF order-shippeddate IS NOT INITIAL.
            CONTINUE.
          ENDIF.
      ENDCASE.

      IF search_term IS NOT INITIAL AND to_upper( |{ order-orderid }| ) NS to_upper( search_term )
                                    AND to_upper( company ) NS to_upper( search_term ).
        CONTINUE.
      ENDIF.

      " the deliveryState / deliveryText formatters of the original: an
      " unshipped order has no state, a delivery inside five days of the
      " required date is urgent, one after it is too late
      DATA(state) = `None`.
      DATA(text) = `None`.
      IF order-shippeddate IS NOT INITIAL.
        DATA(days) = order-requireddate - order-shippeddate.
        IF days > 0 AND days <= 5.
          state = `Warning`.
          text = `Urgent`.
        ELSEIF order-requireddate < order-shippeddate.
          state = `Error`.
          text = `Too late`.
        ELSE.
          state = `Success`.
          text = `In time`.
        ENDIF.
      ENDIF.

      INSERT VALUE #( orderid        = order-orderid
                      title          = |Order { order-orderid }|
                      orderdate      = |{ order-orderdate DATE = ISO }|
                      companyname    = company
                      shipped        = COND #( WHEN order-shippeddate IS INITIAL
                                               THEN `Not shipped yet`
                                               ELSE |{ order-shippeddate DATE = ISO }| )
                      delivery_state = state
                      delivery_text  = text
                      order_period   = |Ordered in { month_name( order-orderdate ) } { order-orderdate(4) }|
                      shipped_period = COND #( WHEN order-shippeddate IS INITIAL
                                               THEN `Not Shipped Yet`
                                               ELSE |Shipped in { month_name( order-shippeddate ) } { order-shippeddate(4) }| )
                      selected       = xsdbool( order-orderid = order_shown ) ) INTO TABLE t_rows.
    ENDLOOP.

    " the original sorts by OrderID descending
    SORT t_rows BY orderid DESCENDING.

    title_count  = |Orders ({ lines( t_rows ) })|.
    no_data_text = COND #( WHEN search_term IS INITIAL AND filter_key IS INITIAL
                           THEN `No orders are currently available`
                           ELSE `No matching order found` ).

  ENDMETHOD.


  METHOD month_name.

    " the month name the original's DateFormat writes into a group header
    DATA(months) = VALUE string_table( ( `January` ) ( `February` ) ( `March` ) ( `April` )
                                       ( `May` ) ( `June` ) ( `July` ) ( `August` )
                                       ( `September` ) ( `October` ) ( `November` ) ( `December` ) ).
    result = months[ CONV i( val+4(2) ) ].

  ENDMETHOD.


  METHOD amount.

    " the currencyValue / calculateItemTotal formatters: two digits, no
    " measure - computed here, because a formatter is business logic
    result = |{ val DECIMALS = 2 NUMBER = RAW }|.

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Orders.json - dates converted from the OData
    " /Date(ms)/ epoch form the mock server writes
    t_orders = VALUE #(
        ( orderid = 7918 customerid = `TORTU` employeeid = 7424
          orderdate = `20160917` requireddate = `20160929` shippeddate = `20160925`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 7311 customerid = `ALFKI` employeeid = 7827
          orderdate = `20161120` requireddate = `20161207` shippeddate = `20161124`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 7375 customerid = `AROUT` employeeid = 7424
          orderdate = `20161005` requireddate = `20161116` shippeddate = `20161013`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 6189 customerid = `BERGS` employeeid = 7829
          orderdate = `20161127` requireddate = `20161220` shippeddate = `20161129`
          shipname = `1A Paket- und Lieferservice` shipaddress = `Bismarckstraße 5`
          shipcity = `Berlin` shipregion = `Berlin` shippostal = `10179` shipcountry = `Deutschland` )
        ( orderid = 3115 customerid = `BERGS` employeeid = 7830
          orderdate = `20161203` requireddate = `20161205` shippeddate = `20161222`
          shipname = `1A Paket- und Lieferservice` shipaddress = `Bismarckstraße 5`
          shipcity = `Berlin` shipregion = `Berlin` shippostal = `10179` shipcountry = `Deutschland` )
        ( orderid = 2686 customerid = `BOTTM` employeeid = 7840
          orderdate = `20161026` requireddate = `20161108` shippeddate = `20161031`
          shipname = `1A Paket- und Lieferservice` shipaddress = `Bismarckstraße 5`
          shipcity = `Berlin` shipregion = `Berlin` shippostal = `10179` shipcountry = `Deutschland` )
        ( orderid = 6858 customerid = `TORTU` employeeid = 7840
          orderdate = `20161112` requireddate = `20161129` shippeddate = `20161113`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 6368 customerid = `ALFKI` employeeid = 7424
          orderdate = `20161112` requireddate = `20161129` shippeddate = `20161118`
          shipname = `ExcellentParcel` shipaddress = `Tottenham Court Road`
          shipcity = `London` shipregion = `Greater London` shippostal = `N170AA` shipcountry = `United Kingdom` )
        ( orderid = 828  customerid = `AROUT` employeeid = 7829
          orderdate = `20161120` requireddate = `20161207` shippeddate = `20161124`
          shipname = `ShipEx` shipaddress = `5th Avenue 610`
          shipcity = `New York` shipregion = `New Jersey` shippostal = `10020` shipcountry = `United Stated of America` )
        ( orderid = 7991 customerid = `BERGS` employeeid = 7830
          orderdate = `20161120` requireddate = `20161207` shippeddate = `20161124`
          shipname = `ShipEx` shipaddress = `5th Avenue 610`
          shipcity = `New York` shipregion = `New Jersey` shippostal = `10020` shipcountry = `United Stated of America` ) ).

    " localService/mockdata/Customer.json
    t_customers = VALUE #(
        ( customerid = `TORTU` companyname = `Tortuga Restaurante` )
        ( customerid = `ALFKI` companyname = `Alfreds Futterkiste` )
        ( customerid = `AROUT` companyname = `Around the Horn` )
        ( customerid = `BERGS` companyname = `Berglunds snabbköp` )
        ( customerid = `BOTTM` companyname = `Bottom-Dollar Markets` ) ).

    " localService/mockdata/Employee.json - the Photo column is empty in the
    " mock for every row, so the original renders its fallback image
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
