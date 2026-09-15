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
            )->a( n = `backgroundDesign` v = `Translucent`
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
    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_app_578=>ty_s_product.
    READ TABLE t_products WITH KEY productid = productid ASSIGNING <product>.
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
          FIELD-SYMBOLS <temp9> LIKE LINE OF t_rows.
          DATA temp10 LIKE sy-tabix.
          FIELD-SYMBOLS <temp11> LIKE LINE OF t_rows.
          DATA temp12 LIKE sy-tabix.
        DATA query TYPE string.
          DATA temp13 TYPE z2ui5_cl_smpc_app_578=>ty_t_product.
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
          
          
          temp12 = sy-tabix.
          READ TABLE t_rows INDEX 1 ASSIGNING <temp11>.
          sy-tabix = temp12.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE t_products WITH KEY productid = <temp11>-productid TRANSPORTING NO FIELDS.
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
        
        query = to_upper( client->get_event_arg( ) ).
        IF query IS INITIAL.
          t_rows = t_products.
        ELSE.
          
          CLEAR temp13.
          t_rows = temp13.
          
          LOOP AT t_products INTO product.
            IF to_upper( product-name ) CS query.
              APPEND product TO t_rows.
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
    DATA temp14 TYPE z2ui5_cl_smpc_app_578=>ty_t_product.
    DATA row LIKE LINE OF t_products.
    DATA temp15 TYPE string_table.

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
    
    CLEAR temp14.
    t_rows = temp14.
    
    LOOP AT t_products INTO row WHERE category = sel_category.
      APPEND row TO t_rows.
    ENDLOOP.
    " park it too, so a later view_display( ) can put the column back
    begin_page = `dynamicPageId`.
    
    CLEAR temp15.
    INSERT `fcl` INTO TABLE temp15.
    INSERT `to` INTO TABLE temp15.
    INSERT begin_page INTO TABLE temp15.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp15 ).

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
    DATA temp17 TYPE string.
    DATA temp18 TYPE string.
    DATA cat TYPE string.
    DATA temp19 TYPE string.
    DATA temp20 TYPE string.
    DATA seg3 LIKE temp19.
    DATA temp21 TYPE string.
    DATA temp22 TYPE string.
    DATA seg4 LIKE temp21.
    DATA temp23 TYPE string.
    DATA temp24 TYPE string.
          DATA temp25 TYPE string.
          DATA temp26 TYPE string.
          DATA temp27 TYPE string_table.
        DATA temp29 TYPE string.
        DATA temp30 TYPE i.
        DATA temp31 TYPE string.
          FIELD-SYMBOLS <temp32> LIKE LINE OF t_products.
          DATA temp33 LIKE sy-tabix.
        DATA temp34 TYPE i.
        DATA temp35 TYPE i.
        DATA temp36 TYPE string.
        DATA temp37 TYPE string.
        DATA temp1 TYPE string.
          FIELD-SYMBOLS <temp1> LIKE LINE OF t_seg.
          DATA temp2 LIKE sy-tabix.
          FIELD-SYMBOLS <temp38> LIKE LINE OF t_products.
          DATA temp39 LIKE sy-tabix.
          FIELD-SYMBOLS <temp40> LIKE LINE OF t_suppliers.
          DATA temp41 LIKE sy-tabix.
        FIELD-SYMBOLS <temp42> LIKE LINE OF t_seg.
        DATA temp43 LIKE sy-tabix.
          DATA temp44 TYPE string.
          DATA temp45 TYPE string.
          DATA temp46 TYPE string_table.
    path = hash.
    IF path CS `#`.
      path = substring_after( val = path sub = `#` ).
    ENDIF.
    SHIFT path LEFT DELETING LEADING `/`.
    
    SPLIT path AT `/` INTO TABLE t_seg.
    DELETE t_seg WHERE table_line IS INITIAL.

    
    CLEAR temp17.
    
    READ TABLE t_seg INTO temp18 INDEX 2.
    IF sy-subrc = 0.
      temp17 = temp18.
    ENDIF.
    
    cat  = replace( val = temp17 sub = `%20` with = ` ` occ = 0 ).
    
    CLEAR temp19.
    
    READ TABLE t_seg INTO temp20 INDEX 3.
    IF sy-subrc = 0.
      temp19 = temp20.
    ENDIF.
    
    seg3 = temp19.
    
    CLEAR temp21.
    
    READ TABLE t_seg INTO temp22 INDEX 4.
    IF sy-subrc = 0.
      temp21 = temp22.
    ENDIF.
    
    seg4 = temp21.

    
    CLEAR temp23.
    
    READ TABLE t_seg INTO temp24 INDEX 1.
    IF sy-subrc = 0.
      temp23 = temp24.
    ENDIF.
    CASE temp23.
      WHEN ``.
        route  = `list`.
        layout = `OneColumn`.
        " back on the categories page - the list route targets List.view
        IF begin_page IS NOT INITIAL.
          
          CLEAR temp25.
          begin_page = temp25.
          
          CLEAR temp26.
          route_category = temp26.
          
          CLEAR temp27.
          INSERT `fcl` INTO TABLE temp27.
          INSERT `to` INTO TABLE temp27.
          INSERT `categoriesPage` INTO TABLE temp27.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp27 ).
        ENDIF.

      WHEN `detail`.
        route = `detail`.
        category_apply( cat ).
        
        IF seg3 IS NOT INITIAL.
          temp29 = seg3.
        ELSE.
          temp29 = `OneColumn`.
        ENDIF.
        layout = temp29.

      WHEN `detailDetail`.
        route = `detailDetail`.
        category_apply( cat ).
        
        IF seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4.
          temp30 = seg3.
        ELSE.
          CLEAR temp30.
        ENDIF.
        product_ix = temp30.
        
        IF seg4 IS NOT INITIAL.
          temp31 = seg4.
        ELSE.
          temp31 = `TwoColumnsMidExpanded`.
        ENDIF.
        layout     = temp31.
        IF product_ix < lines( t_products ).
          
          
          temp33 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp32>.
          sy-tabix = temp33.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp32>-productid ).
        ENDIF.

      WHEN `detailDetailDetail`.
        route = `detailDetailDetail`.
        category_apply( cat ).
        
        IF seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4.
          temp34 = seg3.
        ELSE.
          CLEAR temp34.
        ENDIF.
        product_ix  = temp34.
        
        IF seg4 CO `0123456789` AND seg4 IS NOT INITIAL AND strlen( seg4 ) <= 4.
          temp35 = seg4.
        ELSE.
          CLEAR temp35.
        ENDIF.
        supplier_ix = temp35.
        
        CLEAR temp36.
        
        READ TABLE t_seg INTO temp37 INDEX 5.
        IF sy-subrc = 0.
          temp36 = temp37.
        ENDIF.
        
        IF temp36 IS NOT INITIAL.
          
          
          temp2 = sy-tabix.
          READ TABLE t_seg INDEX 5 ASSIGNING <temp1>.
          sy-tabix = temp2.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          temp1 = <temp1>.
        ELSE.
          temp1 = `ThreeColumnsMidExpanded`.
        ENDIF.
        layout      = temp1.
        IF product_ix < lines( t_products ).
          
          
          temp39 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp38>.
          sy-tabix = temp39.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp38>-productid ).
        ENDIF.
        IF supplier_ix < lines( t_suppliers ).
          
          
          temp41 = sy-tabix.
          READ TABLE t_suppliers INDEX supplier_ix + 1 ASSIGNING <temp40>.
          sy-tabix = temp41.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          dd_text = <temp40>-text.
        ENDIF.

      WHEN OTHERS.
        " the single-segment ':layout:' list route, e.g. '#/OneColumn'
        route  = `list`.
        
        
        temp43 = sy-tabix.
        READ TABLE t_seg INDEX 1 ASSIGNING <temp42>.
        sy-tabix = temp43.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        layout = <temp42>.
        IF begin_page IS NOT INITIAL.
          
          CLEAR temp44.
          begin_page = temp44.
          
          CLEAR temp45.
          route_category = temp45.
          
          CLEAR temp46.
          INSERT `fcl` INTO TABLE temp46.
          INSERT `to` INTO TABLE temp46.
          INSERT `categoriesPage` INTO TABLE temp46.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp46 ).
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
    DATA temp48 TYPE z2ui5_cl_smpc_app_578=>ty_t_product.
    DATA temp49 LIKE LINE OF temp48.
    DATA temp50 TYPE z2ui5_cl_smpc_app_578=>ty_t_supplier.
    DATA temp51 LIKE LINE OF temp50.
    DATA temp52 TYPE z2ui5_cl_smpc_app_578=>ty_t_supplier.
    DATA temp53 LIKE LINE OF temp52.
    CLEAR temp48.
    
    temp49-productid = `HT-1000`.
    temp49-name = `Notebook Basic 15`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp49-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp49-price = `956`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1001`.
    temp49-name = `Notebook Basic 17`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp49-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp49-price = `1249`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1002`.
    temp49-name = `Notebook Basic 18`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp49-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp49-price = `1570`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1003`.
    temp49-name = `Notebook Basic 19`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Smartcards`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp49-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp49-price = `1650`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1007`.
    temp49-name = `ITelO Vault`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp49-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp49-price = `299`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1010`.
    temp49-name = `Notebook Professional 15`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp49-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp49-price = `1999`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1011`.
    temp49-name = `Notebook Professional 17`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp49-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp49-price = `2299`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1020`.
    temp49-name = `ITelO Vault Net`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp49-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp49-price = `459`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1021`.
    temp49-name = `ITelO Vault SAT`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp49-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp49-price = `149`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1022`.
    temp49-name = `Comfort Easy`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp49-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp49-price = `1679`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1023`.
    temp49-name = `Comfort Senior`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp49-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp49-price = `512`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1030`.
    temp49-name = `Ergo Screen E-I`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screen Monitors`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp49-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp49-price = `230`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1031`.
    temp49-name = `Ergo Screen E-II`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screen Monitors`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp49-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp49-price = `285`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1032`.
    temp49-name = `Ergo Screen E-III`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screen Monitors`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp49-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp49-price = `345`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1035`.
    temp49-name = `Flat Basic`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screen Monitors`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp49-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp49-price = `399`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1036`.
    temp49-name = `Flat Future`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screen Monitors`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp49-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp49-price = `430`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1037`.
    temp49-name = `Flat XL`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screen Monitors`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp49-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp49-price = `1230`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1040`.
    temp49-name = `Laser Professional Eco`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Printers`.
    temp49-suppliername = `Alpha Printers`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp49-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp49-price = `830`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1041`.
    temp49-name = `Laser Basic`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Printers`.
    temp49-suppliername = `Alpha Printers`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp49-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp49-price = `490`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1042`.
    temp49-name = `Laser Allround`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Printers`.
    temp49-suppliername = `Alpha Printers`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp49-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp49-price = `349`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1050`.
    temp49-name = `Ultra Jet Super Color`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Printers`.
    temp49-suppliername = `Alpha Printers`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp49-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp49-price = `139`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1051`.
    temp49-name = `Ultra Jet Mobile`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Printers`.
    temp49-suppliername = `Printer for All`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp49-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp49-price = `99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1052`.
    temp49-name = `Ultra Jet Super Highspeed`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Printers`.
    temp49-suppliername = `Printer for All`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp49-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp49-price = `170`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1055`.
    temp49-name = `Multi Print`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Multifunction Printers`.
    temp49-suppliername = `Printer for All`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp49-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp49-price = `99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1056`.
    temp49-name = `Multi Color`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Multifunction Printers`.
    temp49-suppliername = `Printer for All`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp49-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp49-price = `119`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1060`.
    temp49-name = `Cordless Mouse`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Mice`.
    temp49-suppliername = `Oxynum`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp49-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp49-price = `9`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1061`.
    temp49-name = `Speed Mouse`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Mice`.
    temp49-suppliername = `Oxynum`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp49-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp49-price = `7`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1062`.
    temp49-name = `Track Mouse`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Mice`.
    temp49-suppliername = `Oxynum`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp49-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp49-price = `11`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1063`.
    temp49-name = `Ergonomic Keyboard`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Keyboards`.
    temp49-suppliername = `Oxynum`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp49-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp49-price = `14`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1064`.
    temp49-name = `Internet Keyboard`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Keyboards`.
    temp49-suppliername = `Oxynum`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp49-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp49-price = `16`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1065`.
    temp49-name = `Media Keyboard`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Keyboards`.
    temp49-suppliername = `Oxynum`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp49-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp49-price = `26`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1066`.
    temp49-name = `Mousepad`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Mousepads`.
    temp49-suppliername = `Oxynum`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp49-description = `Nice mouse pad with ITelO Logo`.
    temp49-price = `6.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1067`.
    temp49-name = `Ergo Mousepad`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Mousepads`.
    temp49-suppliername = `Oxynum`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp49-description = `Ergonomic mouse pad with ITelO Logo`.
    temp49-price = `8.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1068`.
    temp49-name = `Designer Mousepad`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Mousepads`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp49-description = `ITelO Mousepad Special Edition`.
    temp49-price = `12.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1069`.
    temp49-name = `Universal card reader`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Computer System Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp49-description = `Universal card reader`.
    temp49-price = `14`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1070`.
    temp49-name = `Proctra X`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Graphic Cards`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp49-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp49-price = `70.9`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1071`.
    temp49-name = `Gladiator MX`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Graphic Cards`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp49-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp49-price = `81.7`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1072`.
    temp49-name = `Hurricane GX`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Graphic Cards`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp49-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp49-price = `101.2`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1073`.
    temp49-name = `Hurricane GX/LN`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Graphic Cards`.
    temp49-suppliername = `Smartcards`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp49-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp49-price = `139.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1080`.
    temp49-name = `Photo Scan`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Scanners`.
    temp49-suppliername = `Printer for All`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp49-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp49-price = `129`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1081`.
    temp49-name = `Power Scan`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Scanners`.
    temp49-suppliername = `Printer for All`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp49-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp49-price = `89`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1082`.
    temp49-name = `Jet Scan Professional`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Scanners`.
    temp49-suppliername = `Printer for All`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp49-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp49-price = `169`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1083`.
    temp49-name = `Jet Scan Professional`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Scanners`.
    temp49-suppliername = `Printer for All`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp49-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp49-price = `189`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1085`.
    temp49-name = `Copymaster`.
    temp49-maincategory = `Printers & Scanners`.
    temp49-category = `Multifunction Printers`.
    temp49-suppliername = `Alpha Printers`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp49-description = `Copymaster`.
    temp49-price = `1499`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1090`.
    temp49-name = `Surround Sound`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Speakers`.
    temp49-suppliername = `Speaker Experts`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp49-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp49-price = `39`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1091`.
    temp49-name = `Blaster Extreme`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Speakers`.
    temp49-suppliername = `Speaker Experts`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp49-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp49-price = `26`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1092`.
    temp49-name = `Sound Booster`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Speakers`.
    temp49-suppliername = `Speaker Experts`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp49-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp49-price = `45`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1095`.
    temp49-name = `Lovely Sound 5.1 Wireless`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp49-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp49-price = `49`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1096`.
    temp49-name = `Lovely Sound 5.1`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp49-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp49-price = `39`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1097`.
    temp49-name = `Lovely Sound Stereo`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp49-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp49-price = `29`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1100`.
    temp49-name = `Smart Office`.
    temp49-maincategory = `Software`.
    temp49-category = `Software`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp49-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp49-price = `89.9`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1101`.
    temp49-name = `Smart Design`.
    temp49-maincategory = `Software`.
    temp49-category = `Software`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp49-description = `Complete package, 1 User, Image editing, processing`.
    temp49-price = `79.9`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1102`.
    temp49-name = `Smart Network`.
    temp49-maincategory = `Software`.
    temp49-category = `Software`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp49-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp49-price = `69`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1103`.
    temp49-name = `Smart Multimedia`.
    temp49-maincategory = `Software`.
    temp49-category = `Software`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp49-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp49-price = `77`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1104`.
    temp49-name = `Smart Games`.
    temp49-maincategory = `Software`.
    temp49-category = `Software`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp49-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp49-price = `55`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1105`.
    temp49-name = `Smart Internet Antivirus`.
    temp49-maincategory = `Software`.
    temp49-category = `Software`.
    temp49-suppliername = `Brainsoft`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp49-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp49-price = `29`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1106`.
    temp49-name = `Smart Firewall`.
    temp49-maincategory = `Software`.
    temp49-category = `Software`.
    temp49-suppliername = `Brainsoft`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp49-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp49-price = `34`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1107`.
    temp49-name = `Smart Money`.
    temp49-maincategory = `Software`.
    temp49-category = `Software`.
    temp49-suppliername = `Brainsoft`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp49-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp49-price = `29.9`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1110`.
    temp49-name = `PC Lock`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Computer System Accessories`.
    temp49-suppliername = `Red Point Stores`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp49-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp49-price = `8.9`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1111`.
    temp49-name = `Notebook Lock`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Computer System Accessories`.
    temp49-suppliername = `Red Point Stores`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp49-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp49-price = `6.9`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1112`.
    temp49-name = `Web cam reality`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Computer System Accessories`.
    temp49-suppliername = `Red Point Stores`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp49-description = `Color webcam, color, High-Speed USB`.
    temp49-price = `39`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1113`.
    temp49-name = `Screen clean`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Computer System Accessories`.
    temp49-suppliername = `Red Point Stores`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp49-description = `10 separately packed screen wipes`.
    temp49-price = `2.3`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1114`.
    temp49-name = `Fabric bag professional`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Computer System Accessories`.
    temp49-suppliername = `Red Point Stores`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp49-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp49-price = `31`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1115`.
    temp49-name = `Wireless DSL Router`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Telecommunications`.
    temp49-suppliername = `Red Point Stores`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp49-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp49-price = `49`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1116`.
    temp49-name = `Wireless DSL Router / Repeater`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Telecommunications`.
    temp49-suppliername = `Red Point Stores`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp49-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp49-price = `59`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1117`.
    temp49-name = `Wireless DSL Router / Repeater and Print Server`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Telecommunications`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp49-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp49-price = `69`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1118`.
    temp49-name = `USB Stick`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Computer System Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp49-description = `USB 2.0 High-Speed 64 GB`.
    temp49-price = `35`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1119`.
    temp49-name = `Travel Adapter`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp49-description = `Universal Travel Adapter`.
    temp49-price = `79`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1120`.
    temp49-name = `Cordless Bluetooth Keyboard, english international`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Keyboards`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp49-description = `Cordless Bluetooth Keyboard with English keys`.
    temp49-price = `29`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1137`.
    temp49-name = `Flat XXL`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screen Monitors`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp49-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp49-price = `1430`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1138`.
    temp49-name = `Pocket Mouse`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Mice`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp49-description = `Portable pocket Mouse with retracting cord`.
    temp49-price = `23`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1210`.
    temp49-name = `PC Power Station`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `PCs`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp49-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp49-price = `2399`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1251`.
    temp49-name = `Astro Laptop 1516`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp49-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp49-price = `989`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1252`.
    temp49-name = `Astro Phone 6`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Smartphones and Tablets`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp49-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp49-price = `649`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1253`.
    temp49-name = `Benda Laptop 1408`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp49-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp49-price = `976`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1254`.
    temp49-name = `Bending Screen 21HD`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screens`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp49-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp49-price = `250`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1255`.
    temp49-name = `Broad Screen 22HD`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Flat Screens`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp49-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp49-price = `270`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1256`.
    temp49-name = `Cerdik Phone 7`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Smartphones and Tablets`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp49-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp49-price = `549`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1257`.
    temp49-name = `Cepat Tablet 10.5`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Smartphones and Tablets`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp49-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp49-price = `549`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1258`.
    temp49-name = `Cepat Tablet 8`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Smartphones and Tablets`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp49-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp49-price = `529`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1500`.
    temp49-name = `Server Basic`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Servers`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp49-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp49-price = `5000`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1501`.
    temp49-name = `Server Professional`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Servers`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp49-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp49-price = `15000`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1502`.
    temp49-name = `Server Power Pro`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Servers`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp49-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp49-price = `25000`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1600`.
    temp49-name = `Family PC Basic`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Desktop Computers`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp49-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp49-price = `600`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1601`.
    temp49-name = `Family PC Pro`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Desktop Computers`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp49-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp49-price = `900`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1602`.
    temp49-name = `Gaming Monster`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Desktop Computers`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp49-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp49-price = `1200`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-1603`.
    temp49-name = `Gaming Monster Pro`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Desktop Computers`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp49-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp49-price = `1700`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-2000`.
    temp49-name = `7" Widescreen Portable DVD Player w MP3`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp49-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp49-price = `249.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-2001`.
    temp49-name = `10" Portable DVD player`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp49-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp49-price = `449.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-2002`.
    temp49-name = `Portable DVD Player with 9" LCD Monitor`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp49-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp49-price = `853.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-2025`.
    temp49-name = `CD/DVD case: 264 sleeves`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp49-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp49-price = `44.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-2026`.
    temp49-name = `Audio/Video Cable Kit - 4m`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp49-description = `Quality cables for notebooks and projectors`.
    temp49-price = `29.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-2027`.
    temp49-name = `Removable CD/DVD Laser Labels`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp49-description = `Removable jewel case labels, zero residues (100)`.
    temp49-price = `8.99`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6100`.
    temp49-name = `Beam Breaker B-1`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp49-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp49-price = `469`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6101`.
    temp49-name = `Beam Breaker B-2`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp49-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp49-price = `679`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6102`.
    temp49-name = `Beam Breaker B-3`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Technocom`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp49-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp49-price = `889`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6110`.
    temp49-name = `Play Movie`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp49-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp49-price = `130`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6111`.
    temp49-name = `Record Movie`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp49-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp49-price = `288`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6120`.
    temp49-name = `ITelo MusicStick`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp49-description = `64 GB USB Music-on-Available-Stick`.
    temp49-price = `45`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6121`.
    temp49-name = `ITelo Jog-Mate`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp49-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp49-price = `63`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6122`.
    temp49-name = `Power Pro Player 40`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp49-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp49-price = `167`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6123`.
    temp49-name = `Power Pro Player 80`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp49-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp49-price = `299`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6130`.
    temp49-name = `Flat Watch HD32`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Flat Screen TVs`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp49-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp49-price = `1459`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6131`.
    temp49-name = `Flat Watch HD37`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Flat Screen TVs`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp49-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp49-price = `1199`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-6132`.
    temp49-name = `Flat Watch HD41`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Flat Screen TVs`.
    temp49-suppliername = `Very Best Screens`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp49-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp49-price = `899`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-7000`.
    temp49-name = `Copperberry`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp49-description = `Our new multifunctional Handheld with phone function in copper`.
    temp49-price = `549`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-7010`.
    temp49-name = `Silverberry`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp49-description = `Our new multifunctional Handheld with phone function in silver`.
    temp49-price = `549`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-7020`.
    temp49-name = `Goldberry`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp49-description = `Our new multifunctional Handheld with phone function in gold`.
    temp49-price = `549`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-7030`.
    temp49-name = `Platinberry`.
    temp49-maincategory = `Computer Components`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Fasttech`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp49-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp49-price = `549`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-8000`.
    temp49-name = `ITelO FlexTop I4000`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp49-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp49-price = `799`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-8001`.
    temp49-name = `ITelO FlexTop I6300c`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp49-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp49-price = `799`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-8002`.
    temp49-name = `ITelO FlexTop I9100`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp49-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp49-price = `1199`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-8003`.
    temp49-name = `ITelO FlexTop I9800`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Laptops`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp49-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp49-price = `1388`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9991`.
    temp49-name = `Smartphone Leather Case`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp49-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp49-price = `25`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9992`.
    temp49-name = `Smartphone Alpha`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Smartphones and Tablets`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp49-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp49-price = `599`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9993`.
    temp49-name = `Mini Tablet`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Smartphones and Tablets`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp49-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp49-price = `833`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9994`.
    temp49-name = `Camcorder View`.
    temp49-maincategory = `TV, Video & HiFi`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Ultrasonic United`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp49-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp49-price = `1388`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9995`.
    temp49-name = `Tablet Pouch`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp49-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp49-price = `20`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9996`.
    temp49-name = `Tablet Pouch`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp49-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp49-price = `20`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9997`.
    temp49-name = `e-Book Reader ReadMe`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Smartphones and Tablets`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp49-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp49-price = `33`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9998`.
    temp49-name = `Smartphone Beta`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Smartphones and Tablets`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp49-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp49-price = `30`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `HT-9999`.
    temp49-name = `Maxi Tablet`.
    temp49-maincategory = `Smartphones & Tablets`.
    temp49-category = `Tablets`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp49-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp49-price = `749`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    temp49-productid = `PF-1000`.
    temp49-name = `Flyer`.
    temp49-maincategory = `Computer Systems`.
    temp49-category = `Accessories`.
    temp49-suppliername = `Titanium`.
    temp49-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp49-description = `Flyer for our product palette`.
    temp49-price = `0`.
    temp49-currencycode = `EUR`.
    INSERT temp49 INTO TABLE temp48.
    t_products = temp48.

    " /ProductCollectionStats/Filters/0/values - the sixteen categories
    
    CLEAR temp50.
    
    temp51-text = `Accessories`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Desktop Computers`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Flat Screens`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Keyboards`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Laptops`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Printers`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Smartphones and Tablets`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Mice`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Computer System Accessories`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Graphics Card`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Scanners`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Speakers`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Software`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Telekommunikation`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Servers`.
    INSERT temp51 INTO TABLE temp50.
    temp51-text = `Flat Screen TVs`.
    INSERT temp51 INTO TABLE temp50.
    t_categories = temp50.

    " /ProductCollectionStats/Filters/1/values - the twelve suppliers
    
    CLEAR temp52.
    
    temp53-text = `Titanium`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Technocom`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Red Point Stores`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Very Best Screens`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Smartcards`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Alpha Printers`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Printer for All`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Oxynum`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Fasttech`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Ultrasonic United`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Speaker Experts`.
    INSERT temp53 INTO TABLE temp52.
    temp53-text = `Brainsoft`.
    INSERT temp53 INTO TABLE temp52.
    t_suppliers = temp52.

  ENDMETHOD.

ENDCLASS.
