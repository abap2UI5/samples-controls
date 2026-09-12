" @keywords flexiblecolumnlayout flexible column layout sap.f flexiblecolumnlayoutwithfullscreenpage dynamicpagetitle title table text columnlistitem objectidentifier
" @summary Flexible Column Layout as an app with routing that displays different pages in the initial column. The first page is only displayed in OneColumn layout type
" @origin sap.f.sample.FlexibleColumnLayoutWithFullscreenPage - https://sdk.openui5.org/entity/sap.f.FlexibleColumnLayout/sample/sap.f.sample.FlexibleColumnLayoutWithFullscreenPage (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_578 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid     TYPE string,
        name          TYPE string,
        maincategory  TYPE string,
        category      TYPE string,
        suppliername  TYPE string,
        productpicurl TYPE string,
        description   TYPE string,
        price         TYPE p LENGTH 9 DECIMALS 2,
        currencycode  TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_supplier,
        text TYPE string,
      END OF ty_s_supplier.
    TYPES ty_t_supplier TYPE STANDARD TABLE OF ty_s_supplier WITH EMPTY KEY.

    DATA t_products  TYPE ty_t_product.
    DATA t_rows      TYPE ty_t_product.
    DATA t_suppliers TYPE ty_t_supplier.
    " /ProductCollectionStats/Filters/0/values - the categories page of the
    " begin column, which this sample starts on
    DATA t_categories TYPE ty_t_supplier.

    " the FlexibleColumnLayout state the router drives in the original
    DATA layout TYPE string VALUE `OneColumn`.

    " the product the mid column shows and the supplier the end column shows
    DATA d_name          TYPE string.
    DATA d_productid     TYPE string.
    DATA d_maincategory  TYPE string.
    DATA d_category      TYPE string.
    DATA d_suppliername  TYPE string.
    DATA d_productpicurl TYPE string.
    DATA d_description   TYPE string.
    DATA d_price         TYPE string.
    DATA dd_text         TYPE string.

  PROTECTED SECTION.
    DATA client      TYPE REF TO z2ui5_if_client.
    DATA total_count TYPE i.
    DATA descending  TYPE abap_bool.
    " the beginColumnPages page the LIVE FlexibleColumnLayout was last sent to.
    " A column position is control state, not model state, so view_display( )
    " loses it (app 585 idiom); this field is what lets it be re-issued
    DATA begin_page  TYPE string.

    " the router state the original keeps (currentRouteName + the route's
    " arguments): the category travels as its NAME (URL-encoded, spaces as
    " %20), product and supplier as INDICES into the mock collections
    DATA route          TYPE string VALUE `list`.
    DATA route_category TYPE string.
    DATA product_ix     TYPE i.
    DATA supplier_ix    TYPE i.

    METHODS view_display.
    METHODS detail_bind IMPORTING productid TYPE string.
    METHODS on_event.
    METHODS category_apply IMPORTING category TYPE string.
    METHODS hash_apply IMPORTING hash TYPE string.
    METHODS hash_push IMPORTING check_replace TYPE abap_bool OPTIONAL.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_578 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      t_rows = t_products.
      total_count = lines( t_products ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " the router also matches a deep link / reload (`#/detailDetail/Laptops/
    " 0/TwoColumnsMidExpanded`): the live hash rides in s_config-hash on
    " every request; applying it is idempotent, so a rebuild whose hash
    " matches the state simply re-derives it
    DATA(hash) = client->get( )-s_config-hash.
    IF hash IS NOT INITIAL AND hash <> `#`.
      hash_apply( hash ).
    ENDIF.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(fcl) = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:f`    v = `sap.f`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:uxap` v = `sap.uxap`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`               v = `fcl`
            )->a( n = `backgroundDesign` v = `Translucent`
            " the original wires stateChange to onStateChanged: only a layout
            " change by a NAVIGATION ARROW replace-navTo's the URL - the flag
            " and the new layout travel with the event, the backend guards on it
            )->a( n = `stateChange`      v = client->_event( val = `STATE_CHANGED` t_arg = VALUE #( ( `${$parameters>/isNavigationArrow}` ) ( `${$parameters>/layout}` ) ) )
            )->a( n = `layout`           v = client->_bind( layout ) ).

    " List.view.xml - the categories page the sample starts on, and
    " Detail.view.xml - the products page that replaces it in the begin column
    DATA(begin_column) = fcl->ele( n = `beginColumnPages` ns = `f` ).

    begin_column->ele( n = `DynamicPage` ns = `f`
        )->a( n = `id`                       v = `categoriesPage`
        )->a( n = `toggleHeaderOnTitleClick` v = `false`

        )->ele( n = `title` ns = `f`
            )->ele( n = `DynamicPageTitle` ns = `f`
                )->ele( n = `heading` ns = `f`
                    )->tag( `Title`
                        )->a( n = `text` v = `Categories`

                )->end(
            )->end(
        )->end(
        )->ele( n = `content` ns = `f`
            )->ele( `Table`
                )->a( n = `id`        v = `categoriesTable`
                )->a( n = `mode`      v = `SingleSelectMaster`
                )->a( n = `inset`     v = `false`
                )->a( n = `class`     v = `sapFDynamicPageAlignContent`
                )->a( n = `width`     v = `auto`
                )->a( n = `items`     v = client->_bind( t_categories )
                )->a( n = `itemPress` v = client->_event( val = `CATEGORY_ITEM` arg = `${$parameters>/listItem}.getBindingContext().getProperty('TEXT')` )

                )->ele( `columns`
                    )->ele( `Column`
                        )->a( n = `width` v = `12em`

                        )->tag( `Text`
                            )->a( n = `text` v = `Category`

                    )->end(
                )->end(
                )->ele( `items`
                    )->ele( `ColumnListItem`
                        )->a( n = `type` v = `Navigation`

                        )->ele( `cells`
                            )->tag( `ObjectIdentifier`
                                )->a( n = `title` v = `{TEXT}`

                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    begin_column->ele( n = `DynamicPage` ns = `f`
        )->a( n = `id`                       v = `dynamicPageId`
        )->a( n = `toggleHeaderOnTitleClick` v = `false`

        )->ele( n = `title` ns = `f`
            )->ele( n = `DynamicPageTitle` ns = `f`
                )->ele( n = `heading` ns = `f`
                    )->tag( `Title`
                        )->a( n = `text` v = `Products`

                )->end(
            )->end(
        )->end(
        )->ele( n = `content` ns = `f`
            )->ele( `Table`
                )->a( n = `id`        v = `productsTable`
                )->a( n = `mode`      v = `SingleSelectMaster`
                )->a( n = `inset`     v = `false`
                )->a( n = `class`     v = `sapFDynamicPageAlignContent`
                )->a( n = `width`     v = `auto`
                )->a( n = `items`     v = client->_bind( t_rows )
                )->a( n = `itemPress` v = client->_event( val = `LIST_ITEM` arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )

                )->ele( `headerToolbar`
                    )->ele( `OverflowToolbar`
                        )->tag( `ToolbarSpacer`
                        )->tag( `SearchField`
                            )->a( n = `width`  v = `17.5rem`
                            )->a( n = `search` v = client->_event( val = `SEARCH` arg = `${$parameters>/query}` )
                        )->tag( `OverflowToolbarButton`
                            )->a( n = `icon`    v = `sap-icon://add`
                            )->a( n = `type`    v = `Transparent`
                            )->a( n = `tooltip` v = `Add`
                            )->a( n = `press`   v = client->_event( `ADD` )
                        )->tag( `OverflowToolbarButton`
                            )->a( n = `icon`    v = `sap-icon://sort`
                            )->a( n = `type`    v = `Transparent`
                            )->a( n = `tooltip` v = `Sort`
                            )->a( n = `press`   v = client->_event( `SORT` )

                    )->end(
                )->end(
                )->ele( `columns`
                    )->ele( `Column`
                        )->a( n = `width` v = `12em`

                        )->tag( `Text`
                            )->a( n = `text` v = `Product`

                    )->end(
                    )->ele( `Column`
                        )->a( n = `hAlign` v = `End`

                        )->tag( `Text`
                            )->a( n = `text` v = `Price`

                    )->end(
                )->end(
                )->ele( `items`
                    )->ele( `ColumnListItem`
                        )->a( n = `type` v = `Navigation`

                        )->ele( `cells`
                            )->tag( `ObjectIdentifier`
                                )->a( n = `title` v = `{NAME}`
                                )->a( n = `text`  v = `{PRODUCTID}`
                            )->tag( `ObjectNumber`
                                )->a( n = `number` v = |\{ parts:[\{path:'PRICE'\},\{path:'CURRENCYCODE'\}], type:'sap.ui.model.type.Currency', formatOptions:\{showMeasure:false\} \}|
                                )->a( n = `unit`   v = `{CURRENCYCODE}`

                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(
        )->ele( n = `footer` ns = `f`
            )->ele( `OverflowToolbar`
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `type` v = `Accept`
                    )->a( n = `text` v = `Accept`
                )->tag( `Button`
                    )->a( n = `type` v = `Reject`
                    )->a( n = `text` v = `Reject`

            )->end(
        )->end(
    )->end( ).

    " Detail.view.xml - the ObjectPage of the mid column
    DATA(detail) = fcl->ele( n = `midColumnPages` ns = `f`
        )->ele( n = `ObjectPageLayout` ns = `uxap`
            )->a( n = `id`                          v = `ObjectPageLayout`
            )->a( n = `showTitleInHeaderContent`    v = `true`
            )->a( n = `alwaysShowContentHeader`     v = `false`
            )->a( n = `preserveHeaderStateOnScroll` v = `false`
            )->a( n = `headerContentPinnable`       v = `true`
            )->a( n = `isChildPage`                 v = `true`
            )->a( n = `upperCaseAnchorBar`          v = `false` ).

    DATA(detail_title) = detail->ele( n = `headerTitle` ns = `uxap`
        )->ele( n = `ObjectPageDynamicHeaderTitle` ns = `uxap` ).

    detail_title->ele( n = `expandedHeading` ns = `uxap`
        )->tag( `Title`
            )->a( n = `text`     v = client->_bind( d_name )
            )->a( n = `wrapping` v = `true`
            )->a( n = `class`    v = `sapUiSmallMarginEnd`

    )->end(
        )->ele( n = `snappedHeading` ns = `uxap`
            )->ele( `FlexBox`
                )->a( n = `wrap`         v = `Wrap`
                )->a( n = `fitContainer` v = `true`
                )->a( n = `alignItems`   v = `Center`

                )->ele( `FlexBox`
                    )->a( n = `wrap`         v = `NoWrap`
                    )->a( n = `fitContainer` v = `true`
                    )->a( n = `alignItems`   v = `Center`
                    )->a( n = `class`        v = `sapUiTinyMarginEnd`

                    )->tag( `Avatar`
                        )->a( n = `src`          v = client->_bind( d_productpicurl )
                        )->a( n = `displaySize`  v = `S`
                        )->a( n = `displayShape` v = `Square`
                    )->tag( `Title`
                        )->a( n = `text`     v = client->_bind( d_name )
                        )->a( n = `wrapping` v = `true`
                        )->a( n = `class`    v = `sapUiTinyMarginEnd`

                )->end(
            )->end(
        )->end(
        )->ele( n = `navigationActions` ns = `uxap`
            )->tag( `OverflowToolbarButton`
                )->a( n = `id`      v = `enterFullScreenBtn`
                )->a( n = `type`    v = `Transparent`
                )->a( n = `icon`    v = `sap-icon://full-screen`
                )->a( n = `tooltip` v = `Enter Full Screen Mode`
                )->a( n = `visible` v = |\{= ${ client->_bind( layout ) } !== 'MidColumnFullScreen' \}|
                )->a( n = `press`   v = client->_event( `MID_FULL_SCREEN` )
            )->tag( `OverflowToolbarButton`
                )->a( n = `id`      v = `exitFullScreenBtn`
                )->a( n = `type`    v = `Transparent`
                )->a( n = `icon`    v = `sap-icon://exit-full-screen`
                )->a( n = `tooltip` v = `Exit Full Screen Mode`
                )->a( n = `visible` v = |\{= ${ client->_bind( layout ) } === 'MidColumnFullScreen' \}|
                )->a( n = `press`   v = client->_event( `MID_EXIT_FULL_SCREEN` )
            )->tag( `OverflowToolbarButton`
                )->a( n = `type`    v = `Transparent`
                )->a( n = `icon`    v = `sap-icon://decline`
                )->a( n = `tooltip` v = `Close middle column`
                )->a( n = `visible` v = |\{= ${ client->_bind( layout ) } !== 'OneColumn' \}|
                )->a( n = `press`   v = client->_event( `MID_CLOSE` )

        )->end(
        )->ele( n = `actions` ns = `uxap`
            )->tag( `Button`
                )->a( n = `text` v = `Edit`
                )->a( n = `type` v = `Emphasized`
            )->tag( `Button`
                )->a( n = `text` v = `Delete`
                )->a( n = `type` v = `Transparent`
            )->tag( `Button`
                )->a( n = `text` v = `Copy`
                )->a( n = `type` v = `Transparent`
            )->tag( `Button`
                )->a( n = `text` v = `Toggle Footer`
                )->a( n = `type` v = `Transparent`
            )->tag( `Button`
                )->a( n = `icon`    v = `sap-icon://action`
                )->a( n = `tooltip` v = `Share`
                )->a( n = `type`    v = `Transparent`

        )->end(
    )->end( ).

    detail->ele( n = `headerContent` ns = `uxap`
        )->ele( `FlexBox`
            )->a( n = `wrap`         v = `Wrap`
            )->a( n = `fitContainer` v = `true`
            )->a( n = `alignItems`   v = `Stretch`

            )->tag( `Avatar`
                )->a( n = `src`          v = client->_bind( d_productpicurl )
                )->a( n = `displaySize`  v = `L`
                )->a( n = `displayShape` v = `Square`
                )->a( n = `class`        v = `sapUiTinyMarginEnd`
            )->ele( `VBox`
                )->a( n = `justifyContent` v = `Center`
                )->a( n = `class`          v = `sapUiSmallMarginEnd`

                )->tag( `Label`
                    )->a( n = `text` v = `Main Category`
                )->tag( `Text`
                    )->a( n = `text` v = client->_bind( d_maincategory )

            )->end(
            )->ele( `VBox`
                )->a( n = `justifyContent` v = `Center`
                )->a( n = `class`          v = `sapUiSmallMarginEnd`

                )->tag( `Label`
                    )->a( n = `text` v = `Subcategory`
                )->tag( `Text`
                    )->a( n = `text` v = client->_bind( d_category )

            )->end(
            )->ele( `VBox`
                )->a( n = `justifyContent` v = `Center`
                )->a( n = `class`          v = `sapUiSmallMarginEnd`

                )->tag( `Label`
                    )->a( n = `text` v = `Price`
                )->tag( `ObjectNumber`
                    )->a( n = `number`     v = client->_bind( d_price )
                    )->a( n = `emphasized` v = `false`

            )->end(
        )->end(
    )->end( ).

    DATA(sections) = detail->ele( n = `sections` ns = `uxap` ).

    sections->ele( n = `ObjectPageSection` ns = `uxap`
        )->a( n = `title` v = `General Information`

        )->ele( n = `subSections` ns = `uxap`
            )->ele( n = `ObjectPageSubSection` ns = `uxap`

                )->ele( n = `blocks` ns = `uxap`
                    )->ele( n = `SimpleForm` ns = `form`
                        )->a( n = `maxContainerCols` v = `2`
                        )->a( n = `editable`         v = `false`
                        )->a( n = `layout`           v = `ResponsiveGridLayout`
                        )->a( n = `labelSpanL`       v = `12`
                        )->a( n = `labelSpanM`       v = `12`
                        )->a( n = `emptySpanL`       v = `0`
                        )->a( n = `emptySpanM`       v = `0`
                        )->a( n = `columnsL`         v = `1`
                        )->a( n = `columnsM`         v = `1`

                        )->ele( n = `content` ns = `form`
                            )->tag( `Label`
                                )->a( n = `text` v = `Product ID`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( d_productid )
                            )->tag( `Label`
                                )->a( n = `text` v = `Description`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( d_description )
                            )->tag( `Label`
                                )->a( n = `text` v = `Supplier`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( d_suppliername )

                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    sections->ele( n = `ObjectPageSection` ns = `uxap`
        )->a( n = `title` v = `Suppliers`

        )->ele( n = `subSections` ns = `uxap`
            )->ele( n = `ObjectPageSubSection` ns = `uxap`

                )->ele( n = `blocks` ns = `uxap`
                    )->ele( `Table`
                        )->a( n = `id`        v = `suppliersTable`
                        )->a( n = `mode`      v = `SingleSelectMaster`
                        )->a( n = `items`     v = client->_bind( t_suppliers )
                        )->a( n = `itemPress` v = client->_event( val = `SUPPLIER_ITEM` arg = `${$parameters>/listItem}.getBindingContext().getProperty('TEXT')` )

                        )->ele( `columns`
                            )->tag( `Column`

                        )->end(
                        )->ele( `items`
                            )->ele( `ColumnListItem`
                                )->a( n = `type` v = `Navigation`

                                )->ele( `cells`
                                    )->tag( `ObjectIdentifier`
                                        )->a( n = `text` v = `{TEXT}`

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    " DetailDetailDetail.view.xml - the end column
    fcl->ele( n = `endColumnPages` ns = `f`
        )->ele( n = `DynamicPage` ns = `f`
            )->a( n = `toggleHeaderOnTitleClick` v = `false`

            )->ele( n = `title` ns = `f`
                )->ele( n = `DynamicPageTitle` ns = `f`

                    )->ele( n = `heading` ns = `f`
                        )->ele( `FlexBox`
                            )->a( n = `wrap`         v = `Wrap`
                            )->a( n = `fitContainer` v = `true`
                            )->a( n = `alignItems`   v = `Center`

                            )->tag( `Title`
                                )->a( n = `text`     v = client->_bind( dd_text )
                                )->a( n = `wrapping` v = `true`
                                )->a( n = `class`    v = `sapUiTinyMarginEnd`

                        )->end(
                    )->end(
                    )->ele( n = `navigationActions` ns = `f`
                        )->tag( `OverflowToolbarButton`
                            )->a( n = `type`    v = `Transparent`
                            )->a( n = `icon`    v = `sap-icon://full-screen`
                            )->a( n = `tooltip` v = `Enter Full Screen Mode`
                            )->a( n = `visible` v = |\{= ${ client->_bind( layout ) } !== 'EndColumnFullScreen' \}|
                            )->a( n = `press`   v = client->_event( `END_FULL_SCREEN` )
                        )->tag( `OverflowToolbarButton`
                            )->a( n = `type`    v = `Transparent`
                            )->a( n = `icon`    v = `sap-icon://exit-full-screen`
                            )->a( n = `tooltip` v = `Exit Full Screen Mode`
                            )->a( n = `visible` v = |\{= ${ client->_bind( layout ) } === 'EndColumnFullScreen' \}|
                            )->a( n = `press`   v = client->_event( `END_EXIT_FULL_SCREEN` )
                        )->tag( `OverflowToolbarButton`
                            )->a( n = `type`    v = `Transparent`
                            )->a( n = `icon`    v = `sap-icon://decline`
                            )->a( n = `tooltip` v = `Close end column`
                            )->a( n = `press`   v = client->_event( `END_CLOSE` )

                    )->end(
                )->end(
            )->end(
            )->ele( n = `content` ns = `f`
                )->tag( `Text`
                    )->a( n = `text` v = `Information about Supplier`

            )->end(
        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).
    " Component.js: oProductsModel.setSizeLimit(1000) - the collection is 123 rows
    " and the JSONModel caps a bound aggregation at 100, so the table would stop 23
    " rows short of the count its own title reports
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = VALUE #( ( `1000` ) ( client->cs_view-main ) ) ).
    " The column position of a FlexibleColumnLayout is LIVE control state:
    " view_display( ) destroys the MAIN slot and XMLView.create builds a fresh
    " tree, so the begin column comes back on the first beginColumnPages entry
    " (categoriesPage) - while layout and t_rows are class state that survive.
    " Measured 2026-08-27: after a SEARCH the user was back on the categories
    " while the layout still claimed three columns and the filtered products
    " table was bound but off screen. Re-issuing the SAME page the CATEGORY_ITEM
    " branch last sent is the app 585 idiom; a view that has never navigated
    " parks nothing and issues nothing
    IF begin_page IS NOT INITIAL.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `fcl` ) ( `to` ) ( begin_page ) ) ).
    ENDIF.

    " the original's router, app-owned: the hash carries the route the way
    " the manifest patterns spell it, and a hash change the app did not
    " write (browser Back/Forward, a manual edit) round-trips as
    " HASH_CHANGED. Re-asserted per render - it dies with an app switch
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = VALUE #( ( `HASH_CHANGED` ) ) ).

  ENDMETHOD.


  METHOD detail_bind.

    " Detail.controller's bindElement( '/ProductCollection/<n>' ) - the relative
    " bindings of the original resolve against the bound element, the port folds
    " them to root-seeded fields (app 229 idiom)
    ASSIGN t_products[ productid = productid ] TO FIELD-SYMBOL(<product>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    d_name          = <product>-name.
    d_productid     = <product>-productid.
    d_maincategory  = <product>-maincategory.
    d_category      = <product>-category.
    d_suppliername  = <product>-suppliername.
    d_productpicurl = <product>-productpicurl.
    d_description   = <product>-description.
    d_price         = |{ <product>-currencycode } { <product>-price }|.

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `CATEGORY_ITEM`.
        " List.controller's onListItemPress: the begin column swaps to the
        " products page, filtered to the pressed category, and the mid column
        " opens on the FIRST product of it - navTo('detailDetail') with the
        " category name and that product's index into the FULL collection
        category_apply( client->get_event_arg( ) ).
        IF t_rows IS NOT INITIAL.
          detail_bind( t_rows[ 1 ]-productid ).
          READ TABLE t_products WITH KEY productid = t_rows[ 1 ]-productid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            product_ix = sy-tabix - 1.
          ENDIF.
        ENDIF.
        route  = `detailDetail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `LIST_ITEM`.
        " Detail.controller's onListItemPress opens the mid column on that
        " product - the route carries its index into the FULL collection
        " (the bindingContext path index of the original)
        detail_bind( client->get_event_arg( ) ).
        READ TABLE t_products WITH KEY productid = client->get_event_arg( ) TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          product_ix = sy-tabix - 1.
        ENDIF.
        route  = `detailDetail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `SUPPLIER_ITEM`.
        " handleItemPress: level 2 opens the end column
        dd_text = client->get_event_arg( ).
        READ TABLE t_suppliers WITH KEY text = dd_text TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          supplier_ix = sy-tabix - 1.
        ENDIF.
        route  = `detailDetailDetail`.
        layout = `ThreeColumnsMidExpanded`.
        hash_push( ).

      WHEN `MID_FULL_SCREEN`.
        route  = `detailDetail`.
        layout = `MidColumnFullScreen`.
        hash_push( ).

      WHEN `MID_EXIT_FULL_SCREEN`.
        route  = `detailDetail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `MID_CLOSE`.
        " DetailDetail's handleClose leaves the products page alone in the
        " begin column - navigateToView('detail')
        route  = `detail`.
        layout = `OneColumn`.
        hash_push( ).

      WHEN `END_FULL_SCREEN`.
        route  = `detailDetailDetail`.
        layout = `EndColumnFullScreen`.
        hash_push( ).

      WHEN `END_EXIT_FULL_SCREEN`.
        route  = `detailDetailDetail`.
        layout = `ThreeColumnsMidExpanded`.
        hash_push( ).

      WHEN `END_CLOSE`.
        route  = `detailDetail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `STATE_CHANGED`.
        " onStateChanged: the layout is a two-way binding, so the model
        " already carries the value this event reports - but when a
        " NAVIGATION ARROW changed it, the original replace-navTo's the
        " URL: same route, new layout, no new history entry
        IF client->get_event_arg( ) = abap_true.
          layout = client->get_event_arg( 2 ).
          hash_push( abap_true ).
        ENDIF.

      WHEN `HASH_CHANGED`.
        " browser Back/Forward (or a manual edit) moved the app-owned hash -
        " the router's routeMatched: derive route, category, indices and
        " layout from the hash this request carries. The instance itself is
        " untouched, so search text and sort order survive like in the
        " original
        hash_apply( client->get( )-s_config-hash ).

      WHEN `SEARCH`.
        " onSearch filters the table's items on Name
        DATA(query) = to_upper( client->get_event_arg( ) ).
        IF query IS INITIAL.
          t_rows = t_products.
        ELSE.
          t_rows = VALUE #( ).
          LOOP AT t_products INTO DATA(product).
            IF to_upper( product-name ) CS query.
              APPEND product TO t_rows.
            ENDIF.
          ENDLOOP.
        ENDIF.

      WHEN `SORT`.
        " onSort flips the Name sorter; a thin frontend sorts the data it sends
        descending = xsdbool( descending = abap_false ).
        IF descending = abap_true.
          SORT t_rows BY name DESCENDING.
        ELSE.
          SORT t_rows BY name ASCENDING.
        ENDIF.

      WHEN `ADD`.
        " onAdd: MessageBox.show( 'This functionality is not ready yet.' )
        client->message_box_display( text  = `This functionality is not ready yet.`
                                     type  = `information`
                                     title = `Aw, Snap!` ).

    ENDCASE.

  ENDMETHOD.


  METHOD category_apply.

    " the category the URL (or the pressed row) names: filter the products
    " page to it and swap the begin column onto that page. Idempotent - the
    " same category leaves T_ROWS alone, so a search filtered further is not
    " reset by the next render's hash_apply
    IF category = route_category AND begin_page IS NOT INITIAL.
      RETURN.
    ENDIF.
    route_category = category.
    " the right-hand name of a WHERE resolves to the COLUMN, so the local
    " one must not share it (apps 520/524)
    DATA(sel_category) = category.
    t_rows = VALUE #( ).
    LOOP AT t_products INTO DATA(row) WHERE category = sel_category.
      APPEND row TO t_rows.
    ENDLOOP.
    " park it too, so a later view_display( ) can put the column back
    begin_page = `dynamicPageId`.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `fcl` ) ( `to` ) ( begin_page ) ) ).

  ENDMETHOD.


  METHOD hash_apply.

    " the router's routeMatched, read side: parse the app hash back into
    " route, category, indices and layout. The original's patterns: ''
    " (list start), '{layout}' (the ':layout:' list route),
    " 'detail/{category}/{layout}',
    " 'detailDetail/{category}/{product}/{layout}',
    " 'detailDetailDetail/{category}/{product}/{supplier}/{layout}' -
    " the category is its NAME (spaces ride URL-encoded), product/supplier
    " are INDICES into the mock collections, defaulting to 0 like the
    " original's `arguments.product || this._product || "0"`
    DATA(path) = hash.
    IF path CS `#`.
      path = substring_after( val = path sub = `#` ).
    ENDIF.
    SHIFT path LEFT DELETING LEADING `/`.
    SPLIT path AT `/` INTO TABLE DATA(t_seg).
    DELETE t_seg WHERE table_line IS INITIAL.

    DATA(cat)  = replace( val = VALUE string( t_seg[ 2 ] OPTIONAL ) sub = `%20` with = ` ` occ = 0 ).
    DATA(seg3) = VALUE string( t_seg[ 3 ] OPTIONAL ).
    DATA(seg4) = VALUE string( t_seg[ 4 ] OPTIONAL ).

    CASE VALUE string( t_seg[ 1 ] OPTIONAL ).
      WHEN ``.
        route  = `list`.
        layout = `OneColumn`.
        " back on the categories page - the list route targets List.view
        IF begin_page IS NOT INITIAL.
          begin_page = VALUE #( ).
          route_category = VALUE #( ).
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = VALUE #( ( `fcl` ) ( `to` ) ( `categoriesPage` ) ) ).
        ENDIF.

      WHEN `detail`.
        route = `detail`.
        category_apply( cat ).
        layout = COND #( WHEN seg3 IS NOT INITIAL THEN seg3 ELSE `OneColumn` ).

      WHEN `detailDetail`.
        route = `detailDetail`.
        category_apply( cat ).
        product_ix = COND #( WHEN seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4 THEN seg3 ).
        layout     = COND #( WHEN seg4 IS NOT INITIAL THEN seg4 ELSE `TwoColumnsMidExpanded` ).
        IF product_ix < lines( t_products ).
          detail_bind( t_products[ product_ix + 1 ]-productid ).
        ENDIF.

      WHEN `detailDetailDetail`.
        route = `detailDetailDetail`.
        category_apply( cat ).
        product_ix  = COND #( WHEN seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4 THEN seg3 ).
        supplier_ix = COND #( WHEN seg4 CO `0123456789` AND seg4 IS NOT INITIAL AND strlen( seg4 ) <= 4 THEN seg4 ).
        layout      = COND #( WHEN VALUE string( t_seg[ 5 ] OPTIONAL ) IS NOT INITIAL
                              THEN t_seg[ 5 ]
                              ELSE `ThreeColumnsMidExpanded` ).
        IF product_ix < lines( t_products ).
          detail_bind( t_products[ product_ix + 1 ]-productid ).
        ENDIF.
        IF supplier_ix < lines( t_suppliers ).
          dd_text = t_suppliers[ supplier_ix + 1 ]-text.
        ENDIF.

      WHEN OTHERS.
        " the single-segment ':layout:' list route, e.g. '#/OneColumn'
        route  = `list`.
        layout = t_seg[ 1 ].
        IF begin_page IS NOT INITIAL.
          begin_page = VALUE #( ).
          route_category = VALUE #( ).
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = VALUE #( ( `fcl` ) ( `to` ) ( `categoriesPage` ) ) ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD hash_push.

    DATA hash TYPE string.
    " the router's navTo, write side: compose the current route the way the
    " manifest patterns spell it and push it as the app-owned hash. The
    " category name is URL-encoded the way the original's navTo encodes it
    DATA(cat) = replace( val = route_category sub = ` ` with = `%20` occ = 0 ).
    CASE route.
      WHEN `detail`.
        hash = |/detail/{ cat }/{ layout }|.
      WHEN `detailDetail`.
        hash = |/detailDetail/{ cat }/{ product_ix }/{ layout }|.
      WHEN `detailDetailDetail`.
        hash = |/detailDetailDetail/{ cat }/{ product_ix }/{ supplier_ix }/{ layout }|.
      WHEN OTHERS.
        hash = |/{ layout }|.
    ENDCASE.

    " a NAVIGATION ARROW rewrites the URL in place (the original's
    " replace-navTo) - everything else is a real, pushed history entry
    IF check_replace = abap_true.
      client->hash_replace( hash ).
    ELSE.
      client->hash_set( hash ).
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " the full mock /ProductCollection, in the mock order - the items binding
    " carries NO sorter, so the backend owns the order. Do not add one: a
    " declared sorter is re-applied by JSONListBinding.update on every model
    " change (ClientListBinding.applySort), so it becomes the primary key and
    " the ABAP order survives only as a tiebreak - which is exactly what made
    " the Sort button unable to sort here
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

    " /ProductCollectionStats/Filters/0/values - the sixteen categories
    t_categories = VALUE #(
      ( text = `Accessories` )
      ( text = `Desktop Computers` )
      ( text = `Flat Screens` )
      ( text = `Keyboards` )
      ( text = `Laptops` )
      ( text = `Printers` )
      ( text = `Smartphones and Tablets` )
      ( text = `Mice` )
      ( text = `Computer System Accessories` )
      ( text = `Graphics Card` )
      ( text = `Scanners` )
      ( text = `Speakers` )
      ( text = `Software` )
      ( text = `Telekommunikation` )
      ( text = `Servers` )
      ( text = `Flat Screen TVs` ) ).

    " /ProductCollectionStats/Filters/1/values - the twelve suppliers
    t_suppliers = VALUE #(
      ( text = `Titanium` )
      ( text = `Technocom` )
      ( text = `Red Point Stores` )
      ( text = `Very Best Screens` )
      ( text = `Smartcards` )
      ( text = `Alpha Printers` )
      ( text = `Printer for All` )
      ( text = `Oxynum` )
      ( text = `Fasttech` )
      ( text = `Ultrasonic United` )
      ( text = `Speaker Experts` )
      ( text = `Brainsoft` ) ).

  ENDMETHOD.

ENDCLASS.
