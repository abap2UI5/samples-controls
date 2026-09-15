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

    TYPES temp1_0d301326e8 TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA t_rows             TYPE temp1_0d301326e8.
    TYPES temp2_0d301326e8 TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
DATA t_items            TYPE temp2_0d301326e8.
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
    TYPES temp3_0d301326e8 TYPE STANDARD TABLE OF ty_s_order WITH DEFAULT KEY.
DATA t_orders     TYPE temp3_0d301326e8.
    TYPES temp4_0d301326e8 TYPE STANDARD TABLE OF ty_s_customer WITH DEFAULT KEY.
DATA t_customers  TYPE temp4_0d301326e8.
    TYPES temp5_0d301326e8 TYPE STANDARD TABLE OF ty_s_employee WITH DEFAULT KEY.
DATA t_employees  TYPE temp5_0d301326e8.
    TYPES temp6_0d301326e8 TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_products   TYPE temp6_0d301326e8.
    TYPES temp7_0d301326e8 TYPE STANDARD TABLE OF ty_s_detail WITH DEFAULT KEY.
DATA t_details    TYPE temp7_0d301326e8.
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
    DATA temp1 TYPE string_table.
    DATA fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA list TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA header TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA column TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA tabs TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp3 TYPE string_table.

    " a reload or a shared link: the live hash names the order to show, the
    " routeMatched of a cold start
    hash_apply( ).

    
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

    " the dialog the controller loads as a fragment in the original, declared
    " in the view's dependents aggregation and opened by id
    
    CLEAR temp1.
    INSERT `${$parameters>/filterItems}.length ? ${$parameters>/filterItems}[0].getText() : ''` INTO TABLE temp1.
    INSERT `${$parameters>/filterItems}.length ? ${$parameters>/filterItems}[0].getKey() : ''` INTO TABLE temp1.
    INSERT `${$parameters>/groupItem} ? ${$parameters>/groupItem}.getKey() : ''` INTO TABLE temp1.
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
                                                    t_arg = temp1 )

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

    
    fcl = view->ele( `App`
        )->a( n = `id` v = `app`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`               v = `layout`
            )->a( n = `layout`           v = client->_bind( layout )
            )->a( n = `backgroundDesign` v = `Translucent` ).

    " ------------------------------------------------------------ master
    
    list = fcl->ele( n = `beginColumnPages` ns = `f`
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
    
    detail = fcl->ele( n = `midColumnPages` ns = `f`
        )->ele( n = `SemanticPage` ns = `semantic`
            )->a( n = `id` v = `detailPage` ).

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

    
    column = detail->ele( n = `content` ns = `semantic`
        )->ele( n = `VerticalLayout` ns = `l` ).

    
    tabs = column->ele( `IconTabBar`
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

    
    items = column->ele( `Table`
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
    
    CLEAR temp3.
    INSERT `HASH_CHANGED` INTO TABLE temp3.
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = temp3 ).

    " a grouping is a sorter on the LIST BINDING, not on the model: a rebuilt
    " view starts ungrouped, so an active grouping is re-applied here
    group_apply( ).

  ENDMETHOD.


  METHOD group_apply.
    DATA temp5 TYPE string_table.
    DATA temp1 TYPE string.

    IF group_key IS INITIAL.
      RETURN.
    ENDIF.

    " the client-side equivalent of the original's new Sorter(path, false,
    " groupFunction): group = X makes UI5 draw a GroupHeaderListItem per value
    
    CLEAR temp5.
    INSERT `list` INTO TABLE temp5.
    INSERT `items` INTO TABLE temp5.
    INSERT `sort` INTO TABLE temp5.
    
    IF group_key = `CompanyName`.
      temp1 = `COMPANYNAME`.
    ELSEIF group_key = `OrderDate`.
      temp1 = `ORDER_PERIOD`.
    ELSE.
      temp1 = `SHIPPED_PERIOD`.
    ENDIF.
    INSERT temp1 INTO TABLE temp5.
    INSERT `` INTO TABLE temp5.
    INSERT `X` INTO TABLE temp5.
    client->follow_up_action( val   = client->cs_event-binding_call
                              t_arg = temp5 ).

  ENDMETHOD.


  METHOD on_event.
        DATA row TYPE z2ui5_cl_smpc_demo_002=>ty_s_row.
        DATA dialog_tab TYPE string.
        DATA temp7 TYPE string_table.
        DATA temp1 TYPE xsdboolean.
        DATA temp9 TYPE ty_s_row.
        DATA clear_row LIKE temp9.
        DATA temp4 TYPE xsdboolean.
        DATA temp10 TYPE string.
        DATA temp11 TYPE string_table.
        DATA temp2 LIKE LINE OF temp11.
        DATA temp13 TYPE string_table.
        DATA temp3 LIKE LINE OF temp13.

    CASE client->get_event( ).

      WHEN `SEARCH`.
        list_refresh( ).

      WHEN `SELECT`.
        " the list carries the selection back in the bound row field, so the
        " backend reads it rather than asking the control
        
        READ TABLE t_rows INTO row WITH KEY selected = abap_true.
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
        
        dialog_tab = client->get_event_arg( ).
        IF dialog_tab IS INITIAL.
          dialog_tab = `filter`.
        ENDIF.
        
        CLEAR temp7.
        INSERT `viewSettingsDialog` INTO TABLE temp7.
        INSERT `open` INTO TABLE temp7.
        INSERT dialog_tab INTO TABLE temp7.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp7 ).

      WHEN `VIEW_SETTINGS`.
        " the selected filter item's TEXT for the info bar, and the chosen
        " filter and group KEYS for the work - the three the original reads
        " off the event. Not `filterString`, which UI5 composes as "Filtered
        " By: Orders (Only Shipped Orders)" and which the original does not
        " use: it joins the item texts itself, so its bar reads "Filtered by
        " Only Shipped Orders"
        filter_bar_label   = |Filtered by { client->get_event_arg( ) }|.
        
        temp1 = boolc( client->get_event_arg( ) IS NOT INITIAL ).
        filter_bar_visible = temp1.
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
        
        CLEAR temp9.
        
        clear_row = temp9.
        MODIFY t_rows FROM clear_row TRANSPORTING selected WHERE selected = abap_true.
        client->hash_set( `/` ).

      WHEN `TOGGLE_FULLSCREEN`.
        
        temp4 = boolc( check_fullscreen = abap_false ).
        check_fullscreen = temp4.
        
        IF check_fullscreen = abap_true.
          temp10 = `MidColumnFullScreen`.
        ELSE.
          temp10 = `TwoColumnsMidExpanded`.
        ENDIF.
        layout           = temp10.

      WHEN `PHONE`.
        
        CLEAR temp11.
        
        temp2 = |tel:{ det_phone }|.
        INSERT temp2 INTO TABLE temp11.
        client->follow_up_action( val   = client->cs_event-open_new_tab
                                  t_arg = temp11 ).

      WHEN `SHARE_EMAIL`.
        
        CLEAR temp13.
        
        temp3 = |mailto:?subject=Order%20{ order_shown }|.
        INSERT temp3 INTO TABLE temp13.
        client->follow_up_action( val   = client->cs_event-open_new_tab
                                  t_arg = temp13 ).

    ENDCASE.

  ENDMETHOD.


  METHOD hash_apply.

    " '/Orders/<id>' is the detail column, everything else the list alone
    DATA hash TYPE z2ui5_if_client=>ty_s_get-s_config-hash.
      DATA id TYPE string.
        DATA temp15 TYPE i.
    hash = client->get( )-s_config-hash.
    IF hash CS `/Orders/`.
      
      id = substring_after( val = hash sub = `/Orders/` ).
      IF id CO `0123456789` AND id IS NOT INITIAL.
        
        temp15 = id.
        detail_show( temp15 ).
        RETURN.
      ENDIF.
    ENDIF.

    order_shown = 0.
    layout      = `OneColumn`.

  ENDMETHOD.


  METHOD detail_show.

    DATA total      TYPE ty_amount.
    DATA line_total TYPE ty_amount.

    FIELD-SYMBOLS <order> TYPE z2ui5_cl_smpc_demo_002=>ty_s_order.
    DATA temp16 TYPE string.
    DATA temp17 TYPE z2ui5_cl_smpc_demo_002=>ty_s_customer.
    DATA temp18 TYPE string.
    FIELD-SYMBOLS <employee> TYPE z2ui5_cl_smpc_demo_002=>ty_s_employee.
    DATA temp19 LIKE t_items.
    DATA item LIKE LINE OF t_details.
      DATA temp20 TYPE z2ui5_cl_smpc_demo_002=>ty_s_item.
      DATA temp4 TYPE z2ui5_cl_smpc_demo_002=>ty_s_item-productname.
      DATA temp5 TYPE z2ui5_cl_smpc_demo_002=>ty_s_product.
    DATA temp21 TYPE string.
    DATA temp22 TYPE string.
    DATA temp23 TYPE ty_s_row.
    DATA clear_row LIKE temp23.
    FIELD-SYMBOLS <row> TYPE z2ui5_cl_smpc_demo_002=>ty_s_row.
    READ TABLE t_orders WITH KEY orderid = orderid ASSIGNING <order>.
    IF <order> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    order_shown  = orderid.
    det_title    = |Order { orderid }|.
    
    CLEAR temp16.
    
    READ TABLE t_customers INTO temp17 WITH KEY customerid = <order>-customerid.
    IF sy-subrc = 0.
      temp16 = temp17-companyname.
    ENDIF.
    det_customer = temp16.
    det_orderdate = |{ <order>-orderdate DATE = ISO }|.
    
    IF <order>-shippeddate IS INITIAL.
      temp18 = `Not shipped yet`.
    ELSE.
      temp18 = |{ <order>-shippeddate DATE = ISO }|.
    ENDIF.
    det_shipped  = temp18.

    det_shipname    = <order>-shipname.
    det_shipaddress = <order>-shipaddress.
    det_shipzipcity = |{ <order>-shippostal } { <order>-shipcity }|.
    det_shipregion  = <order>-shipregion.
    det_shipcountry = <order>-shipcountry.

    
    READ TABLE t_employees WITH KEY employeeid = <order>-employeeid ASSIGNING <employee>.
    IF <employee> IS ASSIGNED.
      det_employee   = |{ <employee>-firstname } { <employee>-lastname }|.
      det_employeeid = |{ <employee>-employeeid }|.
      det_jobtitle   = <employee>-title.
      det_phone      = <employee>-homephone.
    ENDIF.

    " the line items, and the order total the original reduces on the client
    
    CLEAR temp19.
    t_items = temp19.
    
    LOOP AT t_details INTO item WHERE orderid = orderid.
      line_total = item-unitprice * item-quantity.
      total = total + line_total.
      
      CLEAR temp20.
      
      CLEAR temp4.
      
      READ TABLE t_products INTO temp5 WITH KEY productid = item-productid.
      IF sy-subrc = 0.
        temp4 = temp5-productname.
      ENDIF.
      temp20-productname = temp4.
      temp20-productid = |{ item-productid }|.
      temp20-unitprice = amount( item-unitprice ).
      temp20-quantity = |{ item-quantity }|.
      temp20-item_total = amount( line_total ).
      INSERT temp20 INTO TABLE t_items.
    ENDLOOP.
    det_total       = amount( total ).
    
    IF t_items IS INITIAL.
      temp21 = `Line Items`.
    ELSE.
      temp21 = |Line Items ({ lines( t_items ) })|.
    ENDIF.
    det_items_title = temp21.

    
    IF check_fullscreen = abap_true.
      temp22 = `MidColumnFullScreen`.
    ELSE.
      temp22 = `TwoColumnsMidExpanded`.
    ENDIF.
    layout = temp22.

    " what the original's ListSelector does after the route matched: the order
    " on show is the selected row of the master list. A click already carries
    " the flag back, a COLD DEEP LINK does not - list_refresh( ) ran before
    " hash_apply( ) knew which order it is - and the list came up with nothing
    " marked. An explicit work area rather than `FROM VALUE #( )`: see
    " CLOSE_DETAIL on what the 702 downport makes of the inline form
    
    CLEAR temp23.
    
    clear_row = temp23.
    MODIFY t_rows FROM clear_row TRANSPORTING selected WHERE selected = abap_true.
    
    READ TABLE t_rows WITH KEY orderid = orderid ASSIGNING <row>.
    IF <row> IS ASSIGNED.
      <row>-selected = abap_true.
    ENDIF.

    " the router's navTo: a pushed history entry, and the deep link of the
    " original
    client->hash_set( |/Orders/{ orderid }| ).

  ENDMETHOD.


  METHOD list_refresh.

    DATA temp24 LIKE t_rows.
    DATA order LIKE LINE OF t_orders.
      DATA temp25 TYPE string.
      DATA temp26 TYPE z2ui5_cl_smpc_demo_002=>ty_s_customer.
      DATA company LIKE temp25.
      DATA state TYPE string.
      DATA text TYPE string.
        DATA days TYPE z2ui5_cl_smpc_demo_002=>ty_s_order-shippeddate.
      DATA temp27 TYPE z2ui5_cl_smpc_demo_002=>ty_s_row.
      DATA temp6 TYPE z2ui5_cl_smpc_demo_002=>ty_s_row-shipped.
      DATA temp7 TYPE z2ui5_cl_smpc_demo_002=>ty_s_row-shipped_period.
      DATA temp5 TYPE xsdboolean.
    DATA temp28 TYPE string.
    CLEAR temp24.
    t_rows = temp24.

    
    LOOP AT t_orders INTO order.
      
      CLEAR temp25.
      
      READ TABLE t_customers INTO temp26 WITH KEY customerid = order-customerid.
      IF sy-subrc = 0.
        temp25 = temp26-companyname.
      ENDIF.
      
      company = temp25.

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
      
      state = `None`.
      
      text = `None`.
      IF order-shippeddate IS NOT INITIAL.
        
        days = order-requireddate - order-shippeddate.
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

      
      CLEAR temp27.
      temp27-orderid = order-orderid.
      temp27-title = |Order { order-orderid }|.
      temp27-orderdate = |{ order-orderdate DATE = ISO }|.
      temp27-companyname = company.
      
      IF order-shippeddate IS INITIAL.
        temp6 = `Not shipped yet`.
      ELSE.
        temp6 = |{ order-shippeddate DATE = ISO }|.
      ENDIF.
      temp27-shipped = temp6.
      temp27-delivery_state = state.
      temp27-delivery_text = text.
      temp27-order_period = |Ordered in { month_name( order-orderdate ) } { order-orderdate(4) }|.
      
      IF order-shippeddate IS INITIAL.
        temp7 = `Not Shipped Yet`.
      ELSE.
        temp7 = |Shipped in { month_name( order-shippeddate ) } { order-shippeddate(4) }|.
      ENDIF.
      temp27-shipped_period = temp7.
      
      temp5 = boolc( order-orderid = order_shown ).
      temp27-selected = temp5.
      INSERT temp27 INTO TABLE t_rows.
    ENDLOOP.

    " the original sorts by OrderID descending
    SORT t_rows BY orderid DESCENDING.

    title_count  = |Orders ({ lines( t_rows ) })|.
    
    IF search_term IS INITIAL AND filter_key IS INITIAL.
      temp28 = `No orders are currently available`.
    ELSE.
      temp28 = `No matching order found`.
    ENDIF.
    no_data_text = temp28.

  ENDMETHOD.


  METHOD month_name.

    " the month name the original's DateFormat writes into a group header
    DATA temp29 TYPE string_table.
    DATA months LIKE temp29.
    DATA temp31 TYPE i.
    FIELD-SYMBOLS <temp8> LIKE LINE OF months.
    DATA temp9 LIKE sy-tabix.
    CLEAR temp29.
    INSERT `January` INTO TABLE temp29.
    INSERT `February` INTO TABLE temp29.
    INSERT `March` INTO TABLE temp29.
    INSERT `April` INTO TABLE temp29.
    INSERT `May` INTO TABLE temp29.
    INSERT `June` INTO TABLE temp29.
    INSERT `July` INTO TABLE temp29.
    INSERT `August` INTO TABLE temp29.
    INSERT `September` INTO TABLE temp29.
    INSERT `October` INTO TABLE temp29.
    INSERT `November` INTO TABLE temp29.
    INSERT `December` INTO TABLE temp29.
    
    months = temp29.
    
    temp31 = val+4(2).
    
    
    temp9 = sy-tabix.
    READ TABLE months INDEX temp31 ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    result = <temp8>.

  ENDMETHOD.


  METHOD amount.

    " the currencyValue / calculateItemTotal formatters: two digits, no
    " measure - computed here, because a formatter is business logic
    result = |{ val DECIMALS = 2 NUMBER = RAW }|.

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Orders.json - dates converted from the OData
    " /Date(ms)/ epoch form the mock server writes
    DATA temp32 LIKE t_orders.
    DATA temp33 LIKE LINE OF temp32.
    DATA temp34 LIKE t_customers.
    DATA temp35 LIKE LINE OF temp34.
    DATA temp36 LIKE t_employees.
    DATA temp37 LIKE LINE OF temp36.
    DATA temp38 LIKE t_products.
    DATA temp39 LIKE LINE OF temp38.
    DATA temp40 LIKE t_details.
    DATA temp41 LIKE LINE OF temp40.
    CLEAR temp32.
    
    temp33-orderid = 7918.
    temp33-customerid = `TORTU`.
    temp33-employeeid = 7424.
    temp33-orderdate = `20160917`.
    temp33-requireddate = `20160929`.
    temp33-shippeddate = `20160925`.
    temp33-shipname = `ExcellentParcel`.
    temp33-shipaddress = `Tottenham Court Road`.
    temp33-shipcity = `London`.
    temp33-shipregion = `Greater London`.
    temp33-shippostal = `N170AA`.
    temp33-shipcountry = `United Kingdom`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 7311.
    temp33-customerid = `ALFKI`.
    temp33-employeeid = 7827.
    temp33-orderdate = `20161120`.
    temp33-requireddate = `20161207`.
    temp33-shippeddate = `20161124`.
    temp33-shipname = `ExcellentParcel`.
    temp33-shipaddress = `Tottenham Court Road`.
    temp33-shipcity = `London`.
    temp33-shipregion = `Greater London`.
    temp33-shippostal = `N170AA`.
    temp33-shipcountry = `United Kingdom`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 7375.
    temp33-customerid = `AROUT`.
    temp33-employeeid = 7424.
    temp33-orderdate = `20161005`.
    temp33-requireddate = `20161116`.
    temp33-shippeddate = `20161013`.
    temp33-shipname = `ExcellentParcel`.
    temp33-shipaddress = `Tottenham Court Road`.
    temp33-shipcity = `London`.
    temp33-shipregion = `Greater London`.
    temp33-shippostal = `N170AA`.
    temp33-shipcountry = `United Kingdom`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 6189.
    temp33-customerid = `BERGS`.
    temp33-employeeid = 7829.
    temp33-orderdate = `20161127`.
    temp33-requireddate = `20161220`.
    temp33-shippeddate = `20161129`.
    temp33-shipname = `1A Paket- und Lieferservice`.
    temp33-shipaddress = `Bismarckstraße 5`.
    temp33-shipcity = `Berlin`.
    temp33-shipregion = `Berlin`.
    temp33-shippostal = `10179`.
    temp33-shipcountry = `Deutschland`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 3115.
    temp33-customerid = `BERGS`.
    temp33-employeeid = 7830.
    temp33-orderdate = `20161203`.
    temp33-requireddate = `20161205`.
    temp33-shippeddate = `20161222`.
    temp33-shipname = `1A Paket- und Lieferservice`.
    temp33-shipaddress = `Bismarckstraße 5`.
    temp33-shipcity = `Berlin`.
    temp33-shipregion = `Berlin`.
    temp33-shippostal = `10179`.
    temp33-shipcountry = `Deutschland`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 2686.
    temp33-customerid = `BOTTM`.
    temp33-employeeid = 7840.
    temp33-orderdate = `20161026`.
    temp33-requireddate = `20161108`.
    temp33-shippeddate = `20161031`.
    temp33-shipname = `1A Paket- und Lieferservice`.
    temp33-shipaddress = `Bismarckstraße 5`.
    temp33-shipcity = `Berlin`.
    temp33-shipregion = `Berlin`.
    temp33-shippostal = `10179`.
    temp33-shipcountry = `Deutschland`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 6858.
    temp33-customerid = `TORTU`.
    temp33-employeeid = 7840.
    temp33-orderdate = `20161112`.
    temp33-requireddate = `20161129`.
    temp33-shippeddate = `20161113`.
    temp33-shipname = `ExcellentParcel`.
    temp33-shipaddress = `Tottenham Court Road`.
    temp33-shipcity = `London`.
    temp33-shipregion = `Greater London`.
    temp33-shippostal = `N170AA`.
    temp33-shipcountry = `United Kingdom`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 6368.
    temp33-customerid = `ALFKI`.
    temp33-employeeid = 7424.
    temp33-orderdate = `20161112`.
    temp33-requireddate = `20161129`.
    temp33-shippeddate = `20161118`.
    temp33-shipname = `ExcellentParcel`.
    temp33-shipaddress = `Tottenham Court Road`.
    temp33-shipcity = `London`.
    temp33-shipregion = `Greater London`.
    temp33-shippostal = `N170AA`.
    temp33-shipcountry = `United Kingdom`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 828.
    temp33-customerid = `AROUT`.
    temp33-employeeid = 7829.
    temp33-orderdate = `20161120`.
    temp33-requireddate = `20161207`.
    temp33-shippeddate = `20161124`.
    temp33-shipname = `ShipEx`.
    temp33-shipaddress = `5th Avenue 610`.
    temp33-shipcity = `New York`.
    temp33-shipregion = `New Jersey`.
    temp33-shippostal = `10020`.
    temp33-shipcountry = `United Stated of America`.
    INSERT temp33 INTO TABLE temp32.
    temp33-orderid = 7991.
    temp33-customerid = `BERGS`.
    temp33-employeeid = 7830.
    temp33-orderdate = `20161120`.
    temp33-requireddate = `20161207`.
    temp33-shippeddate = `20161124`.
    temp33-shipname = `ShipEx`.
    temp33-shipaddress = `5th Avenue 610`.
    temp33-shipcity = `New York`.
    temp33-shipregion = `New Jersey`.
    temp33-shippostal = `10020`.
    temp33-shipcountry = `United Stated of America`.
    INSERT temp33 INTO TABLE temp32.
    t_orders = temp32.

    " localService/mockdata/Customer.json
    
    CLEAR temp34.
    
    temp35-customerid = `TORTU`.
    temp35-companyname = `Tortuga Restaurante`.
    INSERT temp35 INTO TABLE temp34.
    temp35-customerid = `ALFKI`.
    temp35-companyname = `Alfreds Futterkiste`.
    INSERT temp35 INTO TABLE temp34.
    temp35-customerid = `AROUT`.
    temp35-companyname = `Around the Horn`.
    INSERT temp35 INTO TABLE temp34.
    temp35-customerid = `BERGS`.
    temp35-companyname = `Berglunds snabbköp`.
    INSERT temp35 INTO TABLE temp34.
    temp35-customerid = `BOTTM`.
    temp35-companyname = `Bottom-Dollar Markets`.
    INSERT temp35 INTO TABLE temp34.
    t_customers = temp34.

    " localService/mockdata/Employee.json - the Photo column is empty in the
    " mock for every row, so the original renders its fallback image
    
    CLEAR temp36.
    
    temp37-employeeid = 7424.
    temp37-firstname = `Jack`.
    temp37-lastname = `Smith`.
    temp37-title = `Developer`.
    temp37-homephone = `01781163487`.
    INSERT temp37 INTO TABLE temp36.
    temp37-employeeid = 7827.
    temp37-firstname = `Loura`.
    temp37-lastname = `Hajjar`.
    temp37-title = `Developer`.
    temp37-homephone = `01781237845`.
    INSERT temp37 INTO TABLE temp36.
    temp37-employeeid = 7829.
    temp37-firstname = `Steven`.
    temp37-lastname = `Buchanan`.
    temp37-title = `Manager`.
    temp37-homephone = `01787650439`.
    INSERT temp37 INTO TABLE temp36.
    temp37-employeeid = 7830.
    temp37-firstname = `Andrew`.
    temp37-lastname = `Fuller`.
    temp37-title = `Designer`.
    temp37-homephone = `01781234598`.
    INSERT temp37 INTO TABLE temp36.
    temp37-employeeid = 7840.
    temp37-firstname = `Anne`.
    temp37-lastname = `Dodsworth`.
    temp37-title = `Developer`.
    temp37-homephone = `01796577660`.
    INSERT temp37 INTO TABLE temp36.
    t_employees = temp36.

    " localService/mockdata/Product.json
    
    CLEAR temp38.
    
    temp39-productid = 1412.
    temp39-productname = `Aniseed Syrup`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 5267.
    temp39-productname = `Uncle Bob's Organic Dried Pears`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 5046.
    temp39-productname = `Northwoods Cranberry Sauce`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 1114.
    temp39-productname = `Grandma's Boysenberry Spread`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 5079.
    temp39-productname = `Chef Anton's Cajun Seasoning`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 4008.
    temp39-productname = `Sir Rodney's Marmalade`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 5672.
    temp39-productname = `Tunnbröd`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 8486.
    temp39-productname = `Mascarpone Fabioli`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 9505.
    temp39-productname = `Camembert Pierrot`.
    INSERT temp39 INTO TABLE temp38.
    temp39-productid = 4663.
    temp39-productname = `Louisiana Hot Spiced Okra`.
    INSERT temp39 INTO TABLE temp38.
    t_products = temp38.

    " localService/mockdata/Order_Details.json - the Discount column is in
    " the mock and in no view of the app
    
    CLEAR temp40.
    
    temp41-orderid = 7918.
    temp41-productid = 1412.
    temp41-unitprice = `65.89`.
    temp41-quantity = 899.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7918.
    temp41-productid = 5672.
    temp41-unitprice = `14.77`.
    temp41-quantity = 2367.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7918.
    temp41-productid = 5046.
    temp41-unitprice = `61.69`.
    temp41-quantity = 867.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7918.
    temp41-productid = 9505.
    temp41-unitprice = `3.07`.
    temp41-quantity = 1060.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 2686.
    temp41-productid = 5267.
    temp41-unitprice = `24.34`.
    temp41-quantity = 7783.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 2686.
    temp41-productid = 1114.
    temp41-unitprice = `20.50`.
    temp41-quantity = 523.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 2686.
    temp41-productid = 5046.
    temp41-unitprice = `61.69`.
    temp41-quantity = 336.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6858.
    temp41-productid = 1114.
    temp41-unitprice = `20.50`.
    temp41-quantity = 2960.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6858.
    temp41-productid = 4663.
    temp41-unitprice = `9.31`.
    temp41-quantity = 9491.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6858.
    temp41-productid = 5672.
    temp41-unitprice = `14.77`.
    temp41-quantity = 547.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6858.
    temp41-productid = 4008.
    temp41-unitprice = `47.10`.
    temp41-quantity = 5780.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7311.
    temp41-productid = 5046.
    temp41-unitprice = `61.69`.
    temp41-quantity = 6636.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7311.
    temp41-productid = 1412.
    temp41-unitprice = `65.89`.
    temp41-quantity = 3436.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7311.
    temp41-productid = 5672.
    temp41-unitprice = `14.77`.
    temp41-quantity = 8076.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7991.
    temp41-productid = 4663.
    temp41-unitprice = `9.31`.
    temp41-quantity = 9491.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7991.
    temp41-productid = 5672.
    temp41-unitprice = `14.77`.
    temp41-quantity = 547.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7991.
    temp41-productid = 4008.
    temp41-unitprice = `47.10`.
    temp41-quantity = 5780.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7991.
    temp41-productid = 9505.
    temp41-unitprice = `3.07`.
    temp41-quantity = 3239.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7991.
    temp41-productid = 8486.
    temp41-unitprice = `6.31`.
    temp41-quantity = 5039.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6189.
    temp41-productid = 5672.
    temp41-unitprice = `14.77`.
    temp41-quantity = 552.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6189.
    temp41-productid = 4663.
    temp41-unitprice = `9.31`.
    temp41-quantity = 1052.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6189.
    temp41-productid = 5267.
    temp41-unitprice = `24.34`.
    temp41-quantity = 852.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6189.
    temp41-productid = 1412.
    temp41-unitprice = `65.89`.
    temp41-quantity = 6752.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 828.
    temp41-productid = 8486.
    temp41-unitprice = `6.31`.
    temp41-quantity = 1204.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 828.
    temp41-productid = 1114.
    temp41-unitprice = `20.50`.
    temp41-quantity = 2960.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 828.
    temp41-productid = 4663.
    temp41-unitprice = `9.31`.
    temp41-quantity = 9491.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 828.
    temp41-productid = 5672.
    temp41-unitprice = `14.77`.
    temp41-quantity = 547.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 828.
    temp41-productid = 4008.
    temp41-unitprice = `47.10`.
    temp41-quantity = 5780.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 3115.
    temp41-productid = 1114.
    temp41-unitprice = `20.50`.
    temp41-quantity = 1530.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 3115.
    temp41-productid = 5079.
    temp41-unitprice = `62.40`.
    temp41-quantity = 2370.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 3115.
    temp41-productid = 8486.
    temp41-unitprice = `6.31`.
    temp41-quantity = 2567.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 3115.
    temp41-productid = 4663.
    temp41-unitprice = `9.31`.
    temp41-quantity = 1809.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 3115.
    temp41-productid = 4008.
    temp41-unitprice = `47.10`.
    temp41-quantity = 1310.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7375.
    temp41-productid = 4008.
    temp41-unitprice = `47.10`.
    temp41-quantity = 5780.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7375.
    temp41-productid = 9505.
    temp41-unitprice = `3.07`.
    temp41-quantity = 3239.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 7375.
    temp41-productid = 8486.
    temp41-unitprice = `6.31`.
    temp41-quantity = 5039.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6368.
    temp41-productid = 9505.
    temp41-unitprice = `3.07`.
    temp41-quantity = 3239.
    INSERT temp41 INTO TABLE temp40.
    temp41-orderid = 6368.
    temp41-productid = 8486.
    temp41-unitprice = `6.31`.
    temp41-quantity = 5039.
    INSERT temp41 INTO TABLE temp40.
    t_details = temp40.

  ENDMETHOD.

ENDCLASS.
