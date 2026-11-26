" @keywords flexiblecolumnlayout flexible column layout sap.f flexiblecolumnlayoutwithfullscreenpage dynamicpagetitle title table text columnlistitem objectidentifier
" @summary Flexible Column Layout as an app with routing that displays different pages in the initial column. The first page is only displayed in OneColumn layout type
" @origin sap.f.sample.FlexibleColumnLayoutWithFullscreenPage - https://sdk.openui5.org/entity/sap.f.FlexibleColumnLayout/sample/sap.f.sample.FlexibleColumnLayoutWithFullscreenPage (status: checked - verified in a running system)
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
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_supplier,
        text TYPE string,
      END OF ty_s_supplier.
    TYPES ty_t_supplier TYPE STANDARD TABLE OF ty_s_supplier WITH DEFAULT KEY.

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
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      t_rows = t_products.
      total_count = lines( t_products ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " the router also matches a deep link / reload (`#/detailDetail/Laptops/
    " 0/TwoColumnsMidExpanded`): the live hash rides in s_config-hash on
    " every request; applying it is idempotent, so a rebuild whose hash
    " matches the state simply re-derives it
    DATA hash TYPE z2ui5_if_client=>ty_s_get-s_config-hash.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA begin_column TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail_title TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA sections TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp3 TYPE string_table.
      DATA temp5 TYPE string_table.
    DATA temp7 TYPE string_table.
    hash = client->get( )-s_config-hash.
    IF hash IS NOT INITIAL AND hash <> `#`.
      hash_apply( hash ).
    ENDIF.

    
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/isNavigationArrow}` INTO TABLE temp1.
    INSERT `${$parameters>/layout}` INTO TABLE temp1.
    
    fcl = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:f`    v = `sap.f`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:uxap` v = `sap.uxap`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`               v = `fcl`
            )->a( n = `backgroundDesign` v = `Solid`
            " the original wires stateChange to onStateChanged: only a layout
            " change by a NAVIGATION ARROW replace-navTo's the URL - the flag
            " and the new layout travel with the event, the backend guards on it
            )->a( n = `stateChange`      v = client->_event( val = `STATE_CHANGED` t_arg = temp1 )
            )->a( n = `layout`           v = client->_bind( layout ) ).

    " List.view.xml - the categories page the sample starts on, and
    " Detail.view.xml - the products page that replaces it in the begin column
    
    begin_column = fcl->ele( n = `beginColumnPages` ns = `f` ).

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
    
    detail = fcl->ele( n = `midColumnPages` ns = `f`
        )->ele( n = `ObjectPageLayout` ns = `uxap`
            )->a( n = `id`                          v = `ObjectPageLayout`
            )->a( n = `showTitleInHeaderContent`    v = `true`
            )->a( n = `alwaysShowContentHeader`     v = `false`
            )->a( n = `preserveHeaderStateOnScroll` v = `false`
            )->a( n = `headerContentPinnable`       v = `true`
            )->a( n = `isChildPage`                 v = `true`
            )->a( n = `upperCaseAnchorBar`          v = `false` ).

    
    detail_title = detail->ele( n = `headerTitle` ns = `uxap`
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

    
    sections = detail->ele( n = `sections` ns = `uxap` ).

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
    
    CLEAR temp3.
    INSERT `1000` INTO TABLE temp3.
    INSERT client->cs_view-main INTO TABLE temp3.
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = temp3 ).
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
      
      CLEAR temp5.
      INSERT `fcl` INTO TABLE temp5.
      INSERT `to` INTO TABLE temp5.
      INSERT begin_page INTO TABLE temp5.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = temp5 ).
    ENDIF.

    " the original's router, app-owned: the hash carries the route the way
    " the manifest patterns spell it, and a hash change the app did not
    " write (browser Back/Forward, a manual edit) round-trips as
    " HASH_CHANGED. Re-asserted per render - it dies with an app switch
    
    CLEAR temp7.
    INSERT `HASH_CHANGED` INTO TABLE temp7.
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = temp7 ).

  ENDMETHOD.


  METHOD detail_bind.

    " Detail.controller's bindElement( '/ProductCollection/<n>' ) - the relative
    " bindings of the original resolve against the bound element, the port folds
    " them to root-seeded fields (app 229 idiom)
    " IS ASSIGNED, not sy-subrc: a SUCCESSFUL dynamic ASSIGN does not reset
    " sy-subrc on every release (abap2UI5 #1937)
    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_app_578=>ty_s_product.
    READ TABLE t_products WITH KEY productid = productid ASSIGNING <product>.
    IF <product> IS NOT ASSIGNED.
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
          FIELD-SYMBOLS <temp9> LIKE LINE OF t_rows.
          DATA temp10 LIKE sy-tabix.
          DATA temp11 LIKE sy-subrc.
          FIELD-SYMBOLS <temp1> LIKE LINE OF t_rows.
          DATA temp2 LIKE sy-tabix.
            DATA temp12 LIKE sy-subrc.
            FIELD-SYMBOLS <temp3> LIKE LINE OF t_rows.
            DATA temp4 LIKE sy-tabix.
        DATA temp13 LIKE sy-subrc.
          DATA temp14 LIKE sy-subrc.
        DATA temp15 LIKE sy-subrc.
          DATA temp16 LIKE sy-subrc.
        DATA query TYPE string.
          DATA temp17 TYPE z2ui5_cl_smpc_app_578=>ty_t_product.
          DATA product LIKE LINE OF t_products.
        DATA temp1 TYPE xsdboolean.

    CASE client->get_event( ).

      WHEN `CATEGORY_ITEM`.
        " List.controller's onListItemPress: the begin column swaps to the
        " products page, filtered to the pressed category, and the mid column
        " opens on the FIRST product of it - navTo('detailDetail') with the
        " category name and that product's index into the FULL collection
        category_apply( client->get_event_arg( ) ).
        IF t_rows IS NOT INITIAL.
          
          
          temp10 = sy-tabix.
          READ TABLE t_rows INDEX 1 ASSIGNING <temp9>.
          sy-tabix = temp10.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp9>-productid ).
          
          
          
          temp2 = sy-tabix.
          READ TABLE t_rows INDEX 1 ASSIGNING <temp1>.
          sy-tabix = temp2.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE t_products WITH KEY productid = <temp1>-productid TRANSPORTING NO FIELDS.
          temp11 = sy-subrc.
          IF temp11 = 0.
            
            
            
            temp4 = sy-tabix.
            READ TABLE t_rows INDEX 1 ASSIGNING <temp3>.
            sy-tabix = temp4.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            READ TABLE t_products WITH KEY productid = <temp3>-productid TRANSPORTING NO FIELDS.
            temp12 = sy-tabix.
            product_ix = temp12 - 1.
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
        temp13 = sy-subrc.
        IF temp13 = 0.
          
          READ TABLE t_products WITH KEY productid = client->get_event_arg( ) TRANSPORTING NO FIELDS.
          temp14 = sy-tabix.
          product_ix = temp14 - 1.
        ENDIF.
        route  = `detailDetail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `SUPPLIER_ITEM`.
        " handleItemPress: level 2 opens the end column
        dd_text = client->get_event_arg( ).
        
        READ TABLE t_suppliers WITH KEY text = dd_text TRANSPORTING NO FIELDS.
        temp15 = sy-subrc.
        IF temp15 = 0.
          
          READ TABLE t_suppliers WITH KEY text = dd_text TRANSPORTING NO FIELDS.
          temp16 = sy-tabix.
          supplier_ix = temp16 - 1.
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
        
        query = to_upper( client->get_event_arg( ) ).
        IF query IS INITIAL.
          t_rows = t_products.
        ELSE.
          
          CLEAR temp17.
          t_rows = temp17.
          
          LOOP AT t_products INTO product.
            IF to_upper( product-name ) CS query.
              INSERT product INTO TABLE t_rows.
            ENDIF.
          ENDLOOP.
        ENDIF.

      WHEN `SORT`.
        " onSort flips the Name sorter; a thin frontend sorts the data it sends
        
        temp1 = boolc( descending = abap_false ).
        descending = temp1.
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
    DATA sel_category LIKE category.
    DATA temp18 TYPE z2ui5_cl_smpc_app_578=>ty_t_product.
    DATA row LIKE LINE OF t_products.
    DATA temp19 TYPE string_table.

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
    
    sel_category = category.
    
    CLEAR temp18.
    t_rows = temp18.
    
    LOOP AT t_products INTO row WHERE category = sel_category.
      INSERT row INTO TABLE t_rows.
    ENDLOOP.
    " park it too, so a later view_display( ) can put the column back
    begin_page = `dynamicPageId`.
    
    CLEAR temp19.
    INSERT `fcl` INTO TABLE temp19.
    INSERT `to` INTO TABLE temp19.
    INSERT begin_page INTO TABLE temp19.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp19 ).

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
    DATA path LIKE hash.
    DATA t_seg TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA temp21 TYPE string.
    DATA temp22 TYPE string.
    DATA cat TYPE string.
    DATA temp23 TYPE string.
    DATA temp24 TYPE string.
    DATA seg3 LIKE temp23.
    DATA temp25 TYPE string.
    DATA temp26 TYPE string.
    DATA seg4 LIKE temp25.
    DATA temp27 TYPE string.
    DATA temp28 TYPE string.
          DATA temp29 TYPE string.
          DATA temp30 TYPE string.
          DATA temp31 TYPE string_table.
        DATA temp33 TYPE string.
        DATA temp34 TYPE i.
        DATA temp35 TYPE string.
          FIELD-SYMBOLS <temp36> LIKE LINE OF t_products.
          DATA temp37 LIKE sy-tabix.
        DATA temp38 TYPE i.
        DATA temp39 TYPE i.
        DATA temp40 TYPE string.
        DATA temp41 TYPE string.
        DATA temp5 TYPE string.
          FIELD-SYMBOLS <temp1> LIKE LINE OF t_seg.
          DATA temp2 LIKE sy-tabix.
          FIELD-SYMBOLS <temp42> LIKE LINE OF t_products.
          DATA temp43 LIKE sy-tabix.
          FIELD-SYMBOLS <temp44> LIKE LINE OF t_suppliers.
          DATA temp45 LIKE sy-tabix.
        FIELD-SYMBOLS <temp46> LIKE LINE OF t_seg.
        DATA temp47 LIKE sy-tabix.
          DATA temp48 TYPE string.
          DATA temp49 TYPE string.
          DATA temp50 TYPE string_table.
    path = hash.
    IF path CS `#`.
      path = substring_after( val = path sub = `#` ).
    ENDIF.
    path = shift_left( val = path sub = `/` ).
    
    SPLIT path AT `/` INTO TABLE t_seg.
    DELETE t_seg WHERE table_line IS INITIAL.

    
    CLEAR temp21.
    
    READ TABLE t_seg INTO temp22 INDEX 2.
    IF sy-subrc = 0.
      temp21 = temp22.
    ENDIF.
    
    cat  = replace( val = temp21 sub = `%20` with = ` ` occ = 0 ).
    
    CLEAR temp23.
    
    READ TABLE t_seg INTO temp24 INDEX 3.
    IF sy-subrc = 0.
      temp23 = temp24.
    ENDIF.
    
    seg3 = temp23.
    
    CLEAR temp25.
    
    READ TABLE t_seg INTO temp26 INDEX 4.
    IF sy-subrc = 0.
      temp25 = temp26.
    ENDIF.
    
    seg4 = temp25.

    
    CLEAR temp27.
    
    READ TABLE t_seg INTO temp28 INDEX 1.
    IF sy-subrc = 0.
      temp27 = temp28.
    ENDIF.
    CASE temp27.
      WHEN ``.
        route  = `list`.
        layout = `OneColumn`.
        " back on the categories page - the list route targets List.view
        IF begin_page IS NOT INITIAL.
          
          CLEAR temp29.
          begin_page = temp29.
          
          CLEAR temp30.
          route_category = temp30.
          
          CLEAR temp31.
          INSERT `fcl` INTO TABLE temp31.
          INSERT `to` INTO TABLE temp31.
          INSERT `categoriesPage` INTO TABLE temp31.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp31 ).
        ENDIF.

      WHEN `detail`.
        route = `detail`.
        category_apply( cat ).
        
        IF seg3 IS NOT INITIAL.
          temp33 = seg3.
        ELSE.
          temp33 = `OneColumn`.
        ENDIF.
        layout = temp33.

      WHEN `detailDetail`.
        route = `detailDetail`.
        category_apply( cat ).
        
        IF seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4.
          temp34 = seg3.
        ELSE.
          CLEAR temp34.
        ENDIF.
        product_ix = temp34.
        
        IF seg4 IS NOT INITIAL.
          temp35 = seg4.
        ELSE.
          temp35 = `TwoColumnsMidExpanded`.
        ENDIF.
        layout     = temp35.
        IF product_ix < lines( t_products ).
          
          
          temp37 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp36>.
          sy-tabix = temp37.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp36>-productid ).
        ENDIF.

      WHEN `detailDetailDetail`.
        route = `detailDetailDetail`.
        category_apply( cat ).
        
        IF seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4.
          temp38 = seg3.
        ELSE.
          CLEAR temp38.
        ENDIF.
        product_ix  = temp38.
        
        IF seg4 CO `0123456789` AND seg4 IS NOT INITIAL AND strlen( seg4 ) <= 4.
          temp39 = seg4.
        ELSE.
          CLEAR temp39.
        ENDIF.
        supplier_ix = temp39.
        
        CLEAR temp40.
        
        READ TABLE t_seg INTO temp41 INDEX 5.
        IF sy-subrc = 0.
          temp40 = temp41.
        ENDIF.
        
        IF temp40 IS NOT INITIAL.
          
          
          temp2 = sy-tabix.
          READ TABLE t_seg INDEX 5 ASSIGNING <temp1>.
          sy-tabix = temp2.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          temp5 = <temp1>.
        ELSE.
          temp5 = `ThreeColumnsMidExpanded`.
        ENDIF.
        layout      = temp5.
        IF product_ix < lines( t_products ).
          
          
          temp43 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp42>.
          sy-tabix = temp43.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp42>-productid ).
        ENDIF.
        IF supplier_ix < lines( t_suppliers ).
          
          
          temp45 = sy-tabix.
          READ TABLE t_suppliers INDEX supplier_ix + 1 ASSIGNING <temp44>.
          sy-tabix = temp45.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          dd_text = <temp44>-text.
        ENDIF.

      WHEN OTHERS.
        " the single-segment ':layout:' list route, e.g. '#/OneColumn'
        route  = `list`.
        
        
        temp47 = sy-tabix.
        READ TABLE t_seg INDEX 1 ASSIGNING <temp46>.
        sy-tabix = temp47.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        layout = <temp46>.
        IF begin_page IS NOT INITIAL.
          
          CLEAR temp48.
          begin_page = temp48.
          
          CLEAR temp49.
          route_category = temp49.
          
          CLEAR temp50.
          INSERT `fcl` INTO TABLE temp50.
          INSERT `to` INTO TABLE temp50.
          INSERT `categoriesPage` INTO TABLE temp50.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp50 ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD hash_push.

    DATA hash TYPE string.
    " the router's navTo, write side: compose the current route the way the
    " manifest patterns spell it and push it as the app-owned hash. The
    " category name is URL-encoded the way the original's navTo encodes it
    DATA cat TYPE string.
    cat = replace( val = route_category sub = ` ` with = `%20` occ = 0 ).
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
    DATA temp52 TYPE z2ui5_cl_smpc_app_578=>ty_t_product.
    DATA temp53 LIKE LINE OF temp52.
    DATA temp54 TYPE z2ui5_cl_smpc_app_578=>ty_t_supplier.
    DATA temp55 LIKE LINE OF temp54.
    DATA temp56 TYPE z2ui5_cl_smpc_app_578=>ty_t_supplier.
    DATA temp57 LIKE LINE OF temp56.
    CLEAR temp52.
    
    temp53-productid = `HT-1000`.
    temp53-name = `Notebook Basic 15`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp53-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp53-price = `956`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1001`.
    temp53-name = `Notebook Basic 17`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp53-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp53-price = `1249`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1002`.
    temp53-name = `Notebook Basic 18`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp53-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp53-price = `1570`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1003`.
    temp53-name = `Notebook Basic 19`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Smartcards`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp53-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp53-price = `1650`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1007`.
    temp53-name = `ITelO Vault`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp53-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp53-price = `299`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1010`.
    temp53-name = `Notebook Professional 15`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp53-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp53-price = `1999`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1011`.
    temp53-name = `Notebook Professional 17`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp53-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp53-price = `2299`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1020`.
    temp53-name = `ITelO Vault Net`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp53-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp53-price = `459`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1021`.
    temp53-name = `ITelO Vault SAT`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp53-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp53-price = `149`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1022`.
    temp53-name = `Comfort Easy`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp53-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp53-price = `1679`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1023`.
    temp53-name = `Comfort Senior`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp53-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp53-price = `512`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1030`.
    temp53-name = `Ergo Screen E-I`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screen Monitors`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp53-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp53-price = `230`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1031`.
    temp53-name = `Ergo Screen E-II`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screen Monitors`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp53-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp53-price = `285`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1032`.
    temp53-name = `Ergo Screen E-III`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screen Monitors`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp53-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp53-price = `345`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1035`.
    temp53-name = `Flat Basic`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screen Monitors`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp53-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp53-price = `399`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1036`.
    temp53-name = `Flat Future`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screen Monitors`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp53-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp53-price = `430`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1037`.
    temp53-name = `Flat XL`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screen Monitors`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp53-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp53-price = `1230`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1040`.
    temp53-name = `Laser Professional Eco`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Printers`.
    temp53-suppliername = `Alpha Printers`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp53-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp53-price = `830`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1041`.
    temp53-name = `Laser Basic`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Printers`.
    temp53-suppliername = `Alpha Printers`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp53-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp53-price = `490`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1042`.
    temp53-name = `Laser Allround`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Printers`.
    temp53-suppliername = `Alpha Printers`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp53-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp53-price = `349`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1050`.
    temp53-name = `Ultra Jet Super Color`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Printers`.
    temp53-suppliername = `Alpha Printers`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp53-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp53-price = `139`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1051`.
    temp53-name = `Ultra Jet Mobile`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Printers`.
    temp53-suppliername = `Printer for All`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp53-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp53-price = `99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1052`.
    temp53-name = `Ultra Jet Super Highspeed`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Printers`.
    temp53-suppliername = `Printer for All`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp53-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp53-price = `170`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1055`.
    temp53-name = `Multi Print`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Multifunction Printers`.
    temp53-suppliername = `Printer for All`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp53-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp53-price = `99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1056`.
    temp53-name = `Multi Color`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Multifunction Printers`.
    temp53-suppliername = `Printer for All`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp53-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp53-price = `119`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1060`.
    temp53-name = `Cordless Mouse`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Mice`.
    temp53-suppliername = `Oxynum`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp53-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp53-price = `9`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1061`.
    temp53-name = `Speed Mouse`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Mice`.
    temp53-suppliername = `Oxynum`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp53-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp53-price = `7`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1062`.
    temp53-name = `Track Mouse`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Mice`.
    temp53-suppliername = `Oxynum`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp53-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp53-price = `11`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1063`.
    temp53-name = `Ergonomic Keyboard`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Keyboards`.
    temp53-suppliername = `Oxynum`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp53-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp53-price = `14`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1064`.
    temp53-name = `Internet Keyboard`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Keyboards`.
    temp53-suppliername = `Oxynum`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp53-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp53-price = `16`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1065`.
    temp53-name = `Media Keyboard`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Keyboards`.
    temp53-suppliername = `Oxynum`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp53-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp53-price = `26`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1066`.
    temp53-name = `Mousepad`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Mousepads`.
    temp53-suppliername = `Oxynum`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp53-description = `Nice mouse pad with ITelO Logo`.
    temp53-price = `6.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1067`.
    temp53-name = `Ergo Mousepad`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Mousepads`.
    temp53-suppliername = `Oxynum`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp53-description = `Ergonomic mouse pad with ITelO Logo`.
    temp53-price = `8.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1068`.
    temp53-name = `Designer Mousepad`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Mousepads`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp53-description = `ITelO Mousepad Special Edition`.
    temp53-price = `12.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1069`.
    temp53-name = `Universal card reader`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Computer System Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp53-description = `Universal card reader`.
    temp53-price = `14`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1070`.
    temp53-name = `Proctra X`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Graphic Cards`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp53-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp53-price = `70.9`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1071`.
    temp53-name = `Gladiator MX`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Graphic Cards`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp53-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp53-price = `81.7`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1072`.
    temp53-name = `Hurricane GX`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Graphic Cards`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp53-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp53-price = `101.2`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1073`.
    temp53-name = `Hurricane GX/LN`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Graphic Cards`.
    temp53-suppliername = `Smartcards`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp53-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp53-price = `139.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1080`.
    temp53-name = `Photo Scan`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Scanners`.
    temp53-suppliername = `Printer for All`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp53-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp53-price = `129`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1081`.
    temp53-name = `Power Scan`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Scanners`.
    temp53-suppliername = `Printer for All`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp53-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp53-price = `89`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1082`.
    temp53-name = `Jet Scan Professional`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Scanners`.
    temp53-suppliername = `Printer for All`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp53-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp53-price = `169`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1083`.
    temp53-name = `Jet Scan Professional`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Scanners`.
    temp53-suppliername = `Printer for All`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp53-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp53-price = `189`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1085`.
    temp53-name = `Copymaster`.
    temp53-maincategory = `Printers & Scanners`.
    temp53-category = `Multifunction Printers`.
    temp53-suppliername = `Alpha Printers`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp53-description = `Copymaster`.
    temp53-price = `1499`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1090`.
    temp53-name = `Surround Sound`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Speakers`.
    temp53-suppliername = `Speaker Experts`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp53-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp53-price = `39`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1091`.
    temp53-name = `Blaster Extreme`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Speakers`.
    temp53-suppliername = `Speaker Experts`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp53-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp53-price = `26`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1092`.
    temp53-name = `Sound Booster`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Speakers`.
    temp53-suppliername = `Speaker Experts`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp53-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp53-price = `45`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1095`.
    temp53-name = `Lovely Sound 5.1 Wireless`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp53-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp53-price = `49`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1096`.
    temp53-name = `Lovely Sound 5.1`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp53-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp53-price = `39`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1097`.
    temp53-name = `Lovely Sound Stereo`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp53-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp53-price = `29`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1100`.
    temp53-name = `Smart Office`.
    temp53-maincategory = `Software`.
    temp53-category = `Software`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp53-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp53-price = `89.9`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1101`.
    temp53-name = `Smart Design`.
    temp53-maincategory = `Software`.
    temp53-category = `Software`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp53-description = `Complete package, 1 User, Image editing, processing`.
    temp53-price = `79.9`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1102`.
    temp53-name = `Smart Network`.
    temp53-maincategory = `Software`.
    temp53-category = `Software`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp53-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp53-price = `69`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1103`.
    temp53-name = `Smart Multimedia`.
    temp53-maincategory = `Software`.
    temp53-category = `Software`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp53-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp53-price = `77`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1104`.
    temp53-name = `Smart Games`.
    temp53-maincategory = `Software`.
    temp53-category = `Software`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp53-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp53-price = `55`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1105`.
    temp53-name = `Smart Internet Antivirus`.
    temp53-maincategory = `Software`.
    temp53-category = `Software`.
    temp53-suppliername = `Brainsoft`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp53-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp53-price = `29`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1106`.
    temp53-name = `Smart Firewall`.
    temp53-maincategory = `Software`.
    temp53-category = `Software`.
    temp53-suppliername = `Brainsoft`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp53-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp53-price = `34`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1107`.
    temp53-name = `Smart Money`.
    temp53-maincategory = `Software`.
    temp53-category = `Software`.
    temp53-suppliername = `Brainsoft`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp53-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp53-price = `29.9`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1110`.
    temp53-name = `PC Lock`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Computer System Accessories`.
    temp53-suppliername = `Red Point Stores`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp53-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp53-price = `8.9`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1111`.
    temp53-name = `Notebook Lock`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Computer System Accessories`.
    temp53-suppliername = `Red Point Stores`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp53-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp53-price = `6.9`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1112`.
    temp53-name = `Web cam reality`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Computer System Accessories`.
    temp53-suppliername = `Red Point Stores`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp53-description = `Color webcam, color, High-Speed USB`.
    temp53-price = `39`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1113`.
    temp53-name = `Screen clean`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Computer System Accessories`.
    temp53-suppliername = `Red Point Stores`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp53-description = `10 separately packed screen wipes`.
    temp53-price = `2.3`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1114`.
    temp53-name = `Fabric bag professional`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Computer System Accessories`.
    temp53-suppliername = `Red Point Stores`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp53-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp53-price = `31`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1115`.
    temp53-name = `Wireless DSL Router`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Telecommunications`.
    temp53-suppliername = `Red Point Stores`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp53-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp53-price = `49`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1116`.
    temp53-name = `Wireless DSL Router / Repeater`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Telecommunications`.
    temp53-suppliername = `Red Point Stores`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp53-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp53-price = `59`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1117`.
    temp53-name = `Wireless DSL Router / Repeater and Print Server`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Telecommunications`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp53-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp53-price = `69`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1118`.
    temp53-name = `USB Stick`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Computer System Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp53-description = `USB 2.0 High-Speed 64 GB`.
    temp53-price = `35`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1119`.
    temp53-name = `Travel Adapter`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp53-description = `Universal Travel Adapter`.
    temp53-price = `79`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1120`.
    temp53-name = `Cordless Bluetooth Keyboard, english international`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Keyboards`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp53-description = `Cordless Bluetooth Keyboard with English keys`.
    temp53-price = `29`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1137`.
    temp53-name = `Flat XXL`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screen Monitors`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp53-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp53-price = `1430`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1138`.
    temp53-name = `Pocket Mouse`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Mice`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp53-description = `Portable pocket Mouse with retracting cord`.
    temp53-price = `23`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1210`.
    temp53-name = `PC Power Station`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `PCs`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp53-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp53-price = `2399`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1251`.
    temp53-name = `Astro Laptop 1516`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp53-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp53-price = `989`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1252`.
    temp53-name = `Astro Phone 6`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Smartphones and Tablets`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp53-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp53-price = `649`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1253`.
    temp53-name = `Benda Laptop 1408`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp53-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp53-price = `976`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1254`.
    temp53-name = `Bending Screen 21HD`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screens`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp53-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp53-price = `250`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1255`.
    temp53-name = `Broad Screen 22HD`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Flat Screens`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp53-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp53-price = `270`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1256`.
    temp53-name = `Cerdik Phone 7`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Smartphones and Tablets`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp53-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp53-price = `549`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1257`.
    temp53-name = `Cepat Tablet 10.5`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Smartphones and Tablets`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp53-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp53-price = `549`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1258`.
    temp53-name = `Cepat Tablet 8`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Smartphones and Tablets`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp53-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp53-price = `529`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1500`.
    temp53-name = `Server Basic`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Servers`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp53-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp53-price = `5000`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1501`.
    temp53-name = `Server Professional`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Servers`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp53-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp53-price = `15000`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1502`.
    temp53-name = `Server Power Pro`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Servers`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp53-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp53-price = `25000`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1600`.
    temp53-name = `Family PC Basic`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Desktop Computers`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp53-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp53-price = `600`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1601`.
    temp53-name = `Family PC Pro`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Desktop Computers`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp53-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp53-price = `900`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1602`.
    temp53-name = `Gaming Monster`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Desktop Computers`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp53-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp53-price = `1200`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-1603`.
    temp53-name = `Gaming Monster Pro`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Desktop Computers`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp53-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp53-price = `1700`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-2000`.
    temp53-name = `7" Widescreen Portable DVD Player w MP3`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp53-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp53-price = `249.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-2001`.
    temp53-name = `10" Portable DVD player`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp53-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp53-price = `449.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-2002`.
    temp53-name = `Portable DVD Player with 9" LCD Monitor`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp53-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp53-price = `853.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-2025`.
    temp53-name = `CD/DVD case: 264 sleeves`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp53-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp53-price = `44.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-2026`.
    temp53-name = `Audio/Video Cable Kit - 4m`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp53-description = `Quality cables for notebooks and projectors`.
    temp53-price = `29.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-2027`.
    temp53-name = `Removable CD/DVD Laser Labels`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp53-description = `Removable jewel case labels, zero residues (100)`.
    temp53-price = `8.99`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6100`.
    temp53-name = `Beam Breaker B-1`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp53-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp53-price = `469`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6101`.
    temp53-name = `Beam Breaker B-2`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp53-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp53-price = `679`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6102`.
    temp53-name = `Beam Breaker B-3`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Technocom`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp53-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp53-price = `889`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6110`.
    temp53-name = `Play Movie`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp53-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp53-price = `130`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6111`.
    temp53-name = `Record Movie`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp53-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp53-price = `288`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6120`.
    temp53-name = `ITelo MusicStick`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp53-description = `64 GB USB Music-on-Available-Stick`.
    temp53-price = `45`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6121`.
    temp53-name = `ITelo Jog-Mate`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp53-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp53-price = `63`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6122`.
    temp53-name = `Power Pro Player 40`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp53-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp53-price = `167`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6123`.
    temp53-name = `Power Pro Player 80`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp53-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp53-price = `299`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6130`.
    temp53-name = `Flat Watch HD32`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Flat Screen TVs`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp53-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp53-price = `1459`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6131`.
    temp53-name = `Flat Watch HD37`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Flat Screen TVs`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp53-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp53-price = `1199`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-6132`.
    temp53-name = `Flat Watch HD41`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Flat Screen TVs`.
    temp53-suppliername = `Very Best Screens`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp53-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp53-price = `899`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-7000`.
    temp53-name = `Copperberry`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp53-description = `Our new multifunctional Handheld with phone function in copper`.
    temp53-price = `549`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-7010`.
    temp53-name = `Silverberry`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp53-description = `Our new multifunctional Handheld with phone function in silver`.
    temp53-price = `549`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-7020`.
    temp53-name = `Goldberry`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp53-description = `Our new multifunctional Handheld with phone function in gold`.
    temp53-price = `549`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-7030`.
    temp53-name = `Platinberry`.
    temp53-maincategory = `Computer Components`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Fasttech`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp53-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp53-price = `549`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-8000`.
    temp53-name = `ITelO FlexTop I4000`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp53-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp53-price = `799`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-8001`.
    temp53-name = `ITelO FlexTop I6300c`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp53-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp53-price = `799`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-8002`.
    temp53-name = `ITelO FlexTop I9100`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp53-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp53-price = `1199`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-8003`.
    temp53-name = `ITelO FlexTop I9800`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Laptops`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp53-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp53-price = `1388`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9991`.
    temp53-name = `Smartphone Leather Case`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp53-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp53-price = `25`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9992`.
    temp53-name = `Smartphone Alpha`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Smartphones and Tablets`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp53-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp53-price = `599`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9993`.
    temp53-name = `Mini Tablet`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Smartphones and Tablets`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp53-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp53-price = `833`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9994`.
    temp53-name = `Camcorder View`.
    temp53-maincategory = `TV, Video & HiFi`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Ultrasonic United`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp53-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp53-price = `1388`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9995`.
    temp53-name = `Tablet Pouch`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp53-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp53-price = `20`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9996`.
    temp53-name = `Tablet Pouch`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp53-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp53-price = `20`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9997`.
    temp53-name = `e-Book Reader ReadMe`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Smartphones and Tablets`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp53-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp53-price = `33`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9998`.
    temp53-name = `Smartphone Beta`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Smartphones and Tablets`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp53-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp53-price = `30`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `HT-9999`.
    temp53-name = `Maxi Tablet`.
    temp53-maincategory = `Smartphones & Tablets`.
    temp53-category = `Tablets`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp53-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp53-price = `749`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    temp53-productid = `PF-1000`.
    temp53-name = `Flyer`.
    temp53-maincategory = `Computer Systems`.
    temp53-category = `Accessories`.
    temp53-suppliername = `Titanium`.
    temp53-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp53-description = `Flyer for our product palette`.
    temp53-price = `0`.
    temp53-currencycode = `EUR`.
    INSERT temp53 INTO TABLE temp52.
    t_products = temp52.

    " /ProductCollectionStats/Filters/0/values - the sixteen categories
    
    CLEAR temp54.
    
    temp55-text = `Accessories`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Desktop Computers`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Flat Screens`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Keyboards`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Laptops`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Printers`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Smartphones and Tablets`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Mice`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Computer System Accessories`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Graphics Card`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Scanners`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Speakers`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Software`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Telekommunikation`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Servers`.
    INSERT temp55 INTO TABLE temp54.
    temp55-text = `Flat Screen TVs`.
    INSERT temp55 INTO TABLE temp54.
    t_categories = temp54.

    " /ProductCollectionStats/Filters/1/values - the twelve suppliers
    
    CLEAR temp56.
    
    temp57-text = `Titanium`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Technocom`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Red Point Stores`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Very Best Screens`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Smartcards`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Alpha Printers`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Printer for All`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Oxynum`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Fasttech`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Ultrasonic United`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Speaker Experts`.
    INSERT temp57 INTO TABLE temp56.
    temp57-text = `Brainsoft`.
    INSERT temp57 INTO TABLE temp56.
    t_suppliers = temp56.

  ENDMETHOD.

ENDCLASS.
