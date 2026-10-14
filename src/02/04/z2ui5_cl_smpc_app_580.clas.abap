" @keywords flexiblecolumnlayout flexible column layout sap.f flexiblecolumnlayoutwithtwocolumnstart dynamicpage dynamicpagetitle title table overflowtoolbar toolbarspacer
" @summary Flexible Column Layout as an app with routing that starts with two initial columns.
" @origin sap.f.sample.FlexibleColumnLayoutWithTwoColumnStart - https://sdk.openui5.org/entity/sap.f.FlexibleColumnLayout/sample/sap.f.sample.FlexibleColumnLayoutWithTwoColumnStart (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_580 DEFINITION PUBLIC.

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

    " the FlexibleColumnLayout state the router drives in the original; this
    " sample's list route targets list AND detail, so it starts on two columns
    " with the first product shown
    DATA layout      TYPE string VALUE `TwoColumnsMidExpanded`.
    DATA total_count TYPE i.

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
    DATA client     TYPE REF TO z2ui5_if_client.
    DATA descending TYPE abap_bool.

    " the router state the original keeps (currentRouteName + the route's
    " arguments): the original routes by INDEX into the mock collections
    DATA route       TYPE string VALUE `list`.
    DATA product_ix  TYPE i.
    DATA supplier_ix TYPE i.

    METHODS view_display.
    METHODS detail_bind IMPORTING productid TYPE string.
    METHODS on_event.
    METHODS hash_apply IMPORTING hash TYPE string.
    METHODS hash_push IMPORTING check_replace TYPE abap_bool OPTIONAL.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_580 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.
      FIELD-SYMBOLS <temp1> LIKE LINE OF t_products.
      DATA temp2 LIKE sy-tabix.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      t_rows = t_products.
      total_count = lines( t_products ).
      " _onProductMatched defaults to product 0, so the detail column is bound
      " before the user presses anything
      
      
      temp2 = sy-tabix.
      READ TABLE t_products INDEX 1 ASSIGNING <temp1>.
      sy-tabix = temp2.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      detail_bind( <temp1>-productid ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " the router also matches a deep link / reload (`#/detail/1/
    " TwoColumnsMidExpanded`): the live hash rides in s_config-hash on every
    " request; applying it is idempotent, so a rebuild whose hash matches the
    " state simply re-derives it
    DATA hash TYPE z2ui5_if_client=>ty_s_get-s_config-hash.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp3 TYPE string_table.
    DATA fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail_title TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA sections TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA end_column TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp5 TYPE string_table.
    DATA temp7 TYPE string_table.
    hash = client->get( )-s_config-hash.
    IF hash IS NOT INITIAL AND hash <> `#`.
      hash_apply( hash ).
    ENDIF.

    
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp3.
    INSERT `${$parameters>/isNavigationArrow}` INTO TABLE temp3.
    INSERT `${$parameters>/layout}` INTO TABLE temp3.
    
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
            )->a( n = `stateChange`      v = client->_event( val = `STATE_CHANGED` t_arg = temp3 )
            )->a( n = `layout`           v = client->_bind( layout ) ).

    " List.view.xml
    fcl->ele( n = `beginColumnPages` ns = `f`
        )->ele( n = `DynamicPage` ns = `f`
            )->a( n = `id`                       v = `dynamicPageId`
            )->a( n = `toggleHeaderOnTitleClick` v = `false`

            )->ele( n = `title` ns = `f`
                )->ele( n = `DynamicPageTitle` ns = `f`
                    )->ele( n = `heading` ns = `f`
                        )->tag( `Title`
                            )->a( n = `text` v = |Products (\{{ client->_bind_path( total_count ) }\})|

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

    " DetailDetail.view.xml and AboutPage.view.xml - the end column
    
    end_column = fcl->ele( n = `endColumnPages` ns = `f` ).

    end_column->ele( n = `DynamicPage` ns = `f`
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
            )->tag( `Link`
                )->a( n = `text`  v = `Navigate to next page…`
                )->a( n = `press` v = client->_event( `ABOUT` )

        )->end(
    )->end( ).

    end_column->ele( n = `DynamicPage` ns = `f`
        )->a( n = `toggleHeaderOnTitleClick` v = `false`

        )->ele( n = `title` ns = `f`
            )->ele( n = `DynamicPageTitle` ns = `f`
                )->ele( n = `heading` ns = `f`
                    )->tag( `Title`
                        )->a( n = `text` v = `About supplier`

                )->end(
                )->ele( n = `navigationActions` ns = `f`
                    )->tag( `OverflowToolbarButton`
                        )->a( n = `type`    v = `Transparent`
                        )->a( n = `icon`    v = `sap-icon://decline`
                        )->a( n = `tooltip` v = `Close about page`
                        " AboutPage.controller's handleClose is
                        " window.history.go(-1): one real step back - the
                        " hash change then round-trips as HASH_CHANGED
                        )->a( n = `press`   v = client->follow_up_action( client->cs_event-hash_back )

                )->end(
            )->end(
        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).
    " Component.js: oProductsModel.setSizeLimit(1000) - the collection is 123 rows
    " and the JSONModel caps a bound aggregation at 100, so the table would stop 23
    " rows short of the count its own title reports
    
    CLEAR temp5.
    INSERT `1000` INTO TABLE temp5.
    INSERT client->cs_view-main INTO TABLE temp5.
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = temp5 ).

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
    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_app_580=>ty_s_product.
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
        DATA query TYPE string.
          DATA temp9 TYPE z2ui5_cl_smpc_app_580=>ty_t_product.
          DATA product LIKE LINE OF t_products.
        DATA temp1 TYPE xsdboolean.

    CASE client->get_event( ).

      WHEN `LIST_ITEM`.
        " onListItemPress: navTo('detail') - the helper's next state for
        " level 1 opens the mid column, the route carries the product INDEX
        detail_bind( client->get_event_arg( ) ).
        READ TABLE t_products WITH KEY productid = client->get_event_arg( ) TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          product_ix = sy-tabix - 1.
        ENDIF.
        route  = `detail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `SUPPLIER_ITEM`.
        " handleItemPress: navTo('detailDetail') - level 2 opens the end column
        dd_text = client->get_event_arg( ).
        READ TABLE t_suppliers WITH KEY text = dd_text TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          supplier_ix = sy-tabix - 1.
        ENDIF.
        route  = `detailDetail`.
        layout = `ThreeColumnsMidExpanded`.
        hash_push( ).

      WHEN `ABOUT`.
        " handleAboutPress: navTo('page2') - the about page, full screen in
        " the end column
        route  = `page2`.
        layout = `EndColumnFullScreen`.
        hash_push( ).

      WHEN `MID_FULL_SCREEN`.
        route  = `detail`.
        layout = `MidColumnFullScreen`.
        hash_push( ).

      WHEN `MID_EXIT_FULL_SCREEN`.
        route  = `detail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `MID_CLOSE`.
        " handleClose: navTo('list') - the ':layout:' route
        route  = `list`.
        layout = `OneColumn`.
        hash_push( ).

      WHEN `END_FULL_SCREEN`.
        route  = `detailDetail`.
        layout = `EndColumnFullScreen`.
        hash_push( ).

      WHEN `END_EXIT_FULL_SCREEN`.
        route  = `detailDetail`.
        layout = `ThreeColumnsMidExpanded`.
        hash_push( ).

      WHEN `END_CLOSE`.
        route  = `detail`.
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
        " the router's routeMatched: derive route, indices and layout from
        " the hash this request carries. The instance itself is untouched,
        " so search text and sort order survive like in the original
        hash_apply( client->get( )-s_config-hash ).

      WHEN `SEARCH`.
        " onSearch filters the table's items on Name
        
        query = to_upper( client->get_event_arg( ) ).
        IF query IS INITIAL.
          t_rows = t_products.
        ELSE.
          
          CLEAR temp9.
          t_rows = temp9.
          
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


  METHOD hash_apply.

    " the router's routeMatched, read side: parse the app hash back into
    " route, indices and layout. The original's patterns: '' (the TWO-column
    " start - initialColumnsCount 2 makes the helper's level-0 state
    " TwoColumnsMidExpanded), '{layout}' (the ':layout:' list route),
    " 'page2', 'detail/{product}/{layout}',
    " 'detailDetail/{product}/{supplier}/{layout}' - product/supplier are
    " INDICES into the mock collections, defaulting to 0 like the original's
    " `arguments.product || this._product || "0"`
    DATA path LIKE hash.
    DATA t_seg TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA temp10 TYPE string.
    DATA temp11 TYPE string.
    DATA seg2 LIKE temp10.
    DATA temp12 TYPE string.
    DATA temp13 TYPE string.
    DATA seg3 LIKE temp12.
    DATA temp14 TYPE string.
    DATA temp15 TYPE string.
        DATA temp16 TYPE i.
        DATA temp17 TYPE string.
          FIELD-SYMBOLS <temp18> LIKE LINE OF t_products.
          DATA temp19 LIKE sy-tabix.
        DATA temp20 TYPE i.
        DATA temp21 TYPE i.
        DATA temp22 TYPE string.
        DATA temp23 TYPE string.
        DATA temp1 TYPE string.
          FIELD-SYMBOLS <temp1> LIKE LINE OF t_seg.
          DATA temp2 LIKE sy-tabix.
          FIELD-SYMBOLS <temp24> LIKE LINE OF t_products.
          DATA temp25 LIKE sy-tabix.
          FIELD-SYMBOLS <temp26> LIKE LINE OF t_suppliers.
          DATA temp27 LIKE sy-tabix.
        FIELD-SYMBOLS <temp28> LIKE LINE OF t_seg.
        DATA temp29 LIKE sy-tabix.
    path = hash.
    IF path CS `#`.
      path = substring_after( val = path sub = `#` ).
    ENDIF.
    SHIFT path LEFT DELETING LEADING `/`.
    
    SPLIT path AT `/` INTO TABLE t_seg.
    DELETE t_seg WHERE table_line IS INITIAL.

    
    CLEAR temp10.
    
    READ TABLE t_seg INTO temp11 INDEX 2.
    IF sy-subrc = 0.
      temp10 = temp11.
    ENDIF.
    
    seg2 = temp10.
    
    CLEAR temp12.
    
    READ TABLE t_seg INTO temp13 INDEX 3.
    IF sy-subrc = 0.
      temp12 = temp13.
    ENDIF.
    
    seg3 = temp12.

    
    CLEAR temp14.
    
    READ TABLE t_seg INTO temp15 INDEX 1.
    IF sy-subrc = 0.
      temp14 = temp15.
    ENDIF.
    CASE temp14.
      WHEN ``.
        route  = `list`.
        layout = `TwoColumnsMidExpanded`.

      WHEN `page2`.
        route  = `page2`.
        layout = `EndColumnFullScreen`.

      WHEN `detail`.
        route      = `detail`.
        
        IF seg2 CO `0123456789` AND seg2 IS NOT INITIAL AND strlen( seg2 ) <= 4.
          temp16 = seg2.
        ELSE.
          CLEAR temp16.
        ENDIF.
        product_ix = temp16.
        
        IF seg3 IS NOT INITIAL.
          temp17 = seg3.
        ELSE.
          temp17 = `TwoColumnsMidExpanded`.
        ENDIF.
        layout     = temp17.
        IF product_ix < lines( t_products ).
          
          
          temp19 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp18>.
          sy-tabix = temp19.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp18>-productid ).
        ENDIF.

      WHEN `detailDetail`.
        route       = `detailDetail`.
        
        IF seg2 CO `0123456789` AND seg2 IS NOT INITIAL AND strlen( seg2 ) <= 4.
          temp20 = seg2.
        ELSE.
          CLEAR temp20.
        ENDIF.
        product_ix  = temp20.
        
        IF seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4.
          temp21 = seg3.
        ELSE.
          CLEAR temp21.
        ENDIF.
        supplier_ix = temp21.
        
        CLEAR temp22.
        
        READ TABLE t_seg INTO temp23 INDEX 4.
        IF sy-subrc = 0.
          temp22 = temp23.
        ENDIF.
        
        IF temp22 IS NOT INITIAL.
          
          
          temp2 = sy-tabix.
          READ TABLE t_seg INDEX 4 ASSIGNING <temp1>.
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
          
          
          temp25 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp24>.
          sy-tabix = temp25.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp24>-productid ).
        ENDIF.
        IF supplier_ix < lines( t_suppliers ).
          
          
          temp27 = sy-tabix.
          READ TABLE t_suppliers INDEX supplier_ix + 1 ASSIGNING <temp26>.
          sy-tabix = temp27.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          dd_text = <temp26>-text.
        ENDIF.

      WHEN OTHERS.
        " the single-segment ':layout:' list route, e.g. '#/OneColumn'
        route  = `list`.
        
        
        temp29 = sy-tabix.
        READ TABLE t_seg INDEX 1 ASSIGNING <temp28>.
        sy-tabix = temp29.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        layout = <temp28>.
    ENDCASE.

  ENDMETHOD.


  METHOD hash_push.

    DATA hash TYPE string.
    " the router's navTo, write side: compose the current route the way the
    " manifest patterns spell it and push it as the app-owned hash
    CASE route.
      WHEN `detail`.
        hash = |/detail/{ product_ix }/{ layout }|.
      WHEN `detailDetail`.
        hash = |/detailDetail/{ product_ix }/{ supplier_ix }/{ layout }|.
      WHEN `page2`.
        hash = `/page2`.
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
    DATA temp30 TYPE z2ui5_cl_smpc_app_580=>ty_t_product.
    DATA temp31 LIKE LINE OF temp30.
    DATA temp32 TYPE z2ui5_cl_smpc_app_580=>ty_t_supplier.
    DATA temp33 LIKE LINE OF temp32.
    CLEAR temp30.
    
    temp31-productid = `HT-1000`.
    temp31-name = `Notebook Basic 15`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp31-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp31-price = `956`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1001`.
    temp31-name = `Notebook Basic 17`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp31-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp31-price = `1249`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1002`.
    temp31-name = `Notebook Basic 18`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp31-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp31-price = `1570`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1003`.
    temp31-name = `Notebook Basic 19`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Smartcards`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp31-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp31-price = `1650`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1007`.
    temp31-name = `ITelO Vault`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp31-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp31-price = `299`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1010`.
    temp31-name = `Notebook Professional 15`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp31-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp31-price = `1999`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1011`.
    temp31-name = `Notebook Professional 17`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp31-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp31-price = `2299`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1020`.
    temp31-name = `ITelO Vault Net`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp31-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp31-price = `459`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1021`.
    temp31-name = `ITelO Vault SAT`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp31-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp31-price = `149`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1022`.
    temp31-name = `Comfort Easy`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp31-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp31-price = `1679`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1023`.
    temp31-name = `Comfort Senior`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp31-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp31-price = `512`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1030`.
    temp31-name = `Ergo Screen E-I`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screen Monitors`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp31-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp31-price = `230`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1031`.
    temp31-name = `Ergo Screen E-II`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screen Monitors`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp31-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp31-price = `285`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1032`.
    temp31-name = `Ergo Screen E-III`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screen Monitors`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp31-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp31-price = `345`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1035`.
    temp31-name = `Flat Basic`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screen Monitors`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp31-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp31-price = `399`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1036`.
    temp31-name = `Flat Future`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screen Monitors`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp31-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp31-price = `430`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1037`.
    temp31-name = `Flat XL`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screen Monitors`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp31-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp31-price = `1230`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1040`.
    temp31-name = `Laser Professional Eco`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Printers`.
    temp31-suppliername = `Alpha Printers`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp31-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp31-price = `830`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1041`.
    temp31-name = `Laser Basic`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Printers`.
    temp31-suppliername = `Alpha Printers`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp31-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp31-price = `490`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1042`.
    temp31-name = `Laser Allround`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Printers`.
    temp31-suppliername = `Alpha Printers`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp31-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp31-price = `349`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1050`.
    temp31-name = `Ultra Jet Super Color`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Printers`.
    temp31-suppliername = `Alpha Printers`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp31-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp31-price = `139`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1051`.
    temp31-name = `Ultra Jet Mobile`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Printers`.
    temp31-suppliername = `Printer for All`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp31-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp31-price = `99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1052`.
    temp31-name = `Ultra Jet Super Highspeed`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Printers`.
    temp31-suppliername = `Printer for All`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp31-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp31-price = `170`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1055`.
    temp31-name = `Multi Print`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Multifunction Printers`.
    temp31-suppliername = `Printer for All`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp31-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp31-price = `99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1056`.
    temp31-name = `Multi Color`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Multifunction Printers`.
    temp31-suppliername = `Printer for All`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp31-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp31-price = `119`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1060`.
    temp31-name = `Cordless Mouse`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Mice`.
    temp31-suppliername = `Oxynum`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp31-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp31-price = `9`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1061`.
    temp31-name = `Speed Mouse`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Mice`.
    temp31-suppliername = `Oxynum`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp31-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp31-price = `7`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1062`.
    temp31-name = `Track Mouse`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Mice`.
    temp31-suppliername = `Oxynum`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp31-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp31-price = `11`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1063`.
    temp31-name = `Ergonomic Keyboard`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Keyboards`.
    temp31-suppliername = `Oxynum`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp31-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp31-price = `14`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1064`.
    temp31-name = `Internet Keyboard`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Keyboards`.
    temp31-suppliername = `Oxynum`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp31-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp31-price = `16`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1065`.
    temp31-name = `Media Keyboard`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Keyboards`.
    temp31-suppliername = `Oxynum`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp31-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp31-price = `26`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1066`.
    temp31-name = `Mousepad`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Mousepads`.
    temp31-suppliername = `Oxynum`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp31-description = `Nice mouse pad with ITelO Logo`.
    temp31-price = `6.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1067`.
    temp31-name = `Ergo Mousepad`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Mousepads`.
    temp31-suppliername = `Oxynum`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp31-description = `Ergonomic mouse pad with ITelO Logo`.
    temp31-price = `8.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1068`.
    temp31-name = `Designer Mousepad`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Mousepads`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp31-description = `ITelO Mousepad Special Edition`.
    temp31-price = `12.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1069`.
    temp31-name = `Universal card reader`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Computer System Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp31-description = `Universal card reader`.
    temp31-price = `14`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1070`.
    temp31-name = `Proctra X`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Graphic Cards`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp31-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp31-price = `70.9`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1071`.
    temp31-name = `Gladiator MX`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Graphic Cards`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp31-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp31-price = `81.7`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1072`.
    temp31-name = `Hurricane GX`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Graphic Cards`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp31-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp31-price = `101.2`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1073`.
    temp31-name = `Hurricane GX/LN`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Graphic Cards`.
    temp31-suppliername = `Smartcards`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp31-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp31-price = `139.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1080`.
    temp31-name = `Photo Scan`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Scanners`.
    temp31-suppliername = `Printer for All`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp31-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp31-price = `129`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1081`.
    temp31-name = `Power Scan`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Scanners`.
    temp31-suppliername = `Printer for All`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp31-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp31-price = `89`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1082`.
    temp31-name = `Jet Scan Professional`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Scanners`.
    temp31-suppliername = `Printer for All`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp31-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp31-price = `169`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1083`.
    temp31-name = `Jet Scan Professional`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Scanners`.
    temp31-suppliername = `Printer for All`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp31-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp31-price = `189`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1085`.
    temp31-name = `Copymaster`.
    temp31-maincategory = `Printers & Scanners`.
    temp31-category = `Multifunction Printers`.
    temp31-suppliername = `Alpha Printers`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp31-description = `Copymaster`.
    temp31-price = `1499`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1090`.
    temp31-name = `Surround Sound`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Speakers`.
    temp31-suppliername = `Speaker Experts`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp31-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp31-price = `39`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1091`.
    temp31-name = `Blaster Extreme`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Speakers`.
    temp31-suppliername = `Speaker Experts`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp31-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp31-price = `26`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1092`.
    temp31-name = `Sound Booster`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Speakers`.
    temp31-suppliername = `Speaker Experts`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp31-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp31-price = `45`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1095`.
    temp31-name = `Lovely Sound 5.1 Wireless`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp31-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp31-price = `49`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1096`.
    temp31-name = `Lovely Sound 5.1`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp31-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp31-price = `39`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1097`.
    temp31-name = `Lovely Sound Stereo`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp31-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp31-price = `29`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1100`.
    temp31-name = `Smart Office`.
    temp31-maincategory = `Software`.
    temp31-category = `Software`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp31-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp31-price = `89.9`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1101`.
    temp31-name = `Smart Design`.
    temp31-maincategory = `Software`.
    temp31-category = `Software`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp31-description = `Complete package, 1 User, Image editing, processing`.
    temp31-price = `79.9`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1102`.
    temp31-name = `Smart Network`.
    temp31-maincategory = `Software`.
    temp31-category = `Software`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp31-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp31-price = `69`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1103`.
    temp31-name = `Smart Multimedia`.
    temp31-maincategory = `Software`.
    temp31-category = `Software`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp31-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp31-price = `77`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1104`.
    temp31-name = `Smart Games`.
    temp31-maincategory = `Software`.
    temp31-category = `Software`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp31-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp31-price = `55`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1105`.
    temp31-name = `Smart Internet Antivirus`.
    temp31-maincategory = `Software`.
    temp31-category = `Software`.
    temp31-suppliername = `Brainsoft`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp31-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp31-price = `29`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1106`.
    temp31-name = `Smart Firewall`.
    temp31-maincategory = `Software`.
    temp31-category = `Software`.
    temp31-suppliername = `Brainsoft`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp31-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp31-price = `34`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1107`.
    temp31-name = `Smart Money`.
    temp31-maincategory = `Software`.
    temp31-category = `Software`.
    temp31-suppliername = `Brainsoft`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp31-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp31-price = `29.9`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1110`.
    temp31-name = `PC Lock`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Computer System Accessories`.
    temp31-suppliername = `Red Point Stores`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp31-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp31-price = `8.9`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1111`.
    temp31-name = `Notebook Lock`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Computer System Accessories`.
    temp31-suppliername = `Red Point Stores`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp31-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp31-price = `6.9`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1112`.
    temp31-name = `Web cam reality`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Computer System Accessories`.
    temp31-suppliername = `Red Point Stores`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp31-description = `Color webcam, color, High-Speed USB`.
    temp31-price = `39`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1113`.
    temp31-name = `Screen clean`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Computer System Accessories`.
    temp31-suppliername = `Red Point Stores`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp31-description = `10 separately packed screen wipes`.
    temp31-price = `2.3`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1114`.
    temp31-name = `Fabric bag professional`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Computer System Accessories`.
    temp31-suppliername = `Red Point Stores`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp31-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp31-price = `31`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1115`.
    temp31-name = `Wireless DSL Router`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Telecommunications`.
    temp31-suppliername = `Red Point Stores`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp31-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp31-price = `49`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1116`.
    temp31-name = `Wireless DSL Router / Repeater`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Telecommunications`.
    temp31-suppliername = `Red Point Stores`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp31-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp31-price = `59`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1117`.
    temp31-name = `Wireless DSL Router / Repeater and Print Server`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Telecommunications`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp31-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp31-price = `69`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1118`.
    temp31-name = `USB Stick`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Computer System Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp31-description = `USB 2.0 High-Speed 64 GB`.
    temp31-price = `35`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1119`.
    temp31-name = `Travel Adapter`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp31-description = `Universal Travel Adapter`.
    temp31-price = `79`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1120`.
    temp31-name = `Cordless Bluetooth Keyboard, english international`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Keyboards`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp31-description = `Cordless Bluetooth Keyboard with English keys`.
    temp31-price = `29`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1137`.
    temp31-name = `Flat XXL`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screen Monitors`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp31-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp31-price = `1430`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1138`.
    temp31-name = `Pocket Mouse`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Mice`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp31-description = `Portable pocket Mouse with retracting cord`.
    temp31-price = `23`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1210`.
    temp31-name = `PC Power Station`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `PCs`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp31-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp31-price = `2399`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1251`.
    temp31-name = `Astro Laptop 1516`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp31-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp31-price = `989`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1252`.
    temp31-name = `Astro Phone 6`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Smartphones and Tablets`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp31-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp31-price = `649`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1253`.
    temp31-name = `Benda Laptop 1408`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp31-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp31-price = `976`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1254`.
    temp31-name = `Bending Screen 21HD`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screens`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp31-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp31-price = `250`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1255`.
    temp31-name = `Broad Screen 22HD`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Flat Screens`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp31-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp31-price = `270`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1256`.
    temp31-name = `Cerdik Phone 7`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Smartphones and Tablets`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp31-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp31-price = `549`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1257`.
    temp31-name = `Cepat Tablet 10.5`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Smartphones and Tablets`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp31-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp31-price = `549`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1258`.
    temp31-name = `Cepat Tablet 8`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Smartphones and Tablets`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp31-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp31-price = `529`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1500`.
    temp31-name = `Server Basic`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Servers`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp31-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp31-price = `5000`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1501`.
    temp31-name = `Server Professional`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Servers`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp31-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp31-price = `15000`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1502`.
    temp31-name = `Server Power Pro`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Servers`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp31-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp31-price = `25000`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1600`.
    temp31-name = `Family PC Basic`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Desktop Computers`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp31-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp31-price = `600`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1601`.
    temp31-name = `Family PC Pro`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Desktop Computers`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp31-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp31-price = `900`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1602`.
    temp31-name = `Gaming Monster`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Desktop Computers`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp31-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp31-price = `1200`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-1603`.
    temp31-name = `Gaming Monster Pro`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Desktop Computers`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp31-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp31-price = `1700`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-2000`.
    temp31-name = `7" Widescreen Portable DVD Player w MP3`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp31-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp31-price = `249.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-2001`.
    temp31-name = `10" Portable DVD player`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp31-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp31-price = `449.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-2002`.
    temp31-name = `Portable DVD Player with 9" LCD Monitor`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp31-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp31-price = `853.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-2025`.
    temp31-name = `CD/DVD case: 264 sleeves`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp31-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp31-price = `44.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-2026`.
    temp31-name = `Audio/Video Cable Kit - 4m`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp31-description = `Quality cables for notebooks and projectors`.
    temp31-price = `29.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-2027`.
    temp31-name = `Removable CD/DVD Laser Labels`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp31-description = `Removable jewel case labels, zero residues (100)`.
    temp31-price = `8.99`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6100`.
    temp31-name = `Beam Breaker B-1`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp31-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp31-price = `469`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6101`.
    temp31-name = `Beam Breaker B-2`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp31-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp31-price = `679`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6102`.
    temp31-name = `Beam Breaker B-3`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Technocom`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp31-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp31-price = `889`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6110`.
    temp31-name = `Play Movie`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp31-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp31-price = `130`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6111`.
    temp31-name = `Record Movie`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp31-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp31-price = `288`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6120`.
    temp31-name = `ITelo MusicStick`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp31-description = `64 GB USB Music-on-Available-Stick`.
    temp31-price = `45`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6121`.
    temp31-name = `ITelo Jog-Mate`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp31-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp31-price = `63`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6122`.
    temp31-name = `Power Pro Player 40`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp31-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp31-price = `167`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6123`.
    temp31-name = `Power Pro Player 80`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp31-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp31-price = `299`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6130`.
    temp31-name = `Flat Watch HD32`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Flat Screen TVs`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp31-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp31-price = `1459`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6131`.
    temp31-name = `Flat Watch HD37`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Flat Screen TVs`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp31-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp31-price = `1199`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-6132`.
    temp31-name = `Flat Watch HD41`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Flat Screen TVs`.
    temp31-suppliername = `Very Best Screens`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp31-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp31-price = `899`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-7000`.
    temp31-name = `Copperberry`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp31-description = `Our new multifunctional Handheld with phone function in copper`.
    temp31-price = `549`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-7010`.
    temp31-name = `Silverberry`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp31-description = `Our new multifunctional Handheld with phone function in silver`.
    temp31-price = `549`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-7020`.
    temp31-name = `Goldberry`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp31-description = `Our new multifunctional Handheld with phone function in gold`.
    temp31-price = `549`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-7030`.
    temp31-name = `Platinberry`.
    temp31-maincategory = `Computer Components`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Fasttech`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp31-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp31-price = `549`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-8000`.
    temp31-name = `ITelO FlexTop I4000`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp31-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp31-price = `799`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-8001`.
    temp31-name = `ITelO FlexTop I6300c`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp31-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp31-price = `799`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-8002`.
    temp31-name = `ITelO FlexTop I9100`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp31-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp31-price = `1199`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-8003`.
    temp31-name = `ITelO FlexTop I9800`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Laptops`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp31-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp31-price = `1388`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9991`.
    temp31-name = `Smartphone Leather Case`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp31-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp31-price = `25`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9992`.
    temp31-name = `Smartphone Alpha`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Smartphones and Tablets`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp31-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp31-price = `599`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9993`.
    temp31-name = `Mini Tablet`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Smartphones and Tablets`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp31-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp31-price = `833`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9994`.
    temp31-name = `Camcorder View`.
    temp31-maincategory = `TV, Video & HiFi`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Ultrasonic United`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp31-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp31-price = `1388`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9995`.
    temp31-name = `Tablet Pouch`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp31-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp31-price = `20`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9996`.
    temp31-name = `Tablet Pouch`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp31-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp31-price = `20`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9997`.
    temp31-name = `e-Book Reader ReadMe`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Smartphones and Tablets`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp31-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp31-price = `33`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9998`.
    temp31-name = `Smartphone Beta`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Smartphones and Tablets`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp31-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp31-price = `30`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `HT-9999`.
    temp31-name = `Maxi Tablet`.
    temp31-maincategory = `Smartphones & Tablets`.
    temp31-category = `Tablets`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp31-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp31-price = `749`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    temp31-productid = `PF-1000`.
    temp31-name = `Flyer`.
    temp31-maincategory = `Computer Systems`.
    temp31-category = `Accessories`.
    temp31-suppliername = `Titanium`.
    temp31-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp31-description = `Flyer for our product palette`.
    temp31-price = `0`.
    temp31-currencycode = `EUR`.
    INSERT temp31 INTO TABLE temp30.
    t_products = temp30.

    " /ProductCollectionStats/Filters/1/values - the twelve suppliers
    
    CLEAR temp32.
    
    temp33-text = `Titanium`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Technocom`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Red Point Stores`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Very Best Screens`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Smartcards`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Alpha Printers`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Printer for All`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Oxynum`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Fasttech`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Ultrasonic United`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Speaker Experts`.
    INSERT temp33 INTO TABLE temp32.
    temp33-text = `Brainsoft`.
    INSERT temp33 INTO TABLE temp32.
    t_suppliers = temp32.

  ENDMETHOD.

ENDCLASS.
