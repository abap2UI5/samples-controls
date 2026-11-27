" @keywords flexiblecolumnlayout flexible column layout sap.f flexiblecolumnlayoutwithtwocolumnstart dynamicpage dynamicpagetitle title table overflowtoolbar toolbarspacer
" @summary Flexible Column Layout as an app with routing that starts with two initial columns.
" @origin sap.f.sample.FlexibleColumnLayoutWithTwoColumnStart - https://sdk.openui5.org/entity/sap.f.FlexibleColumnLayout/sample/sap.f.sample.FlexibleColumnLayoutWithTwoColumnStart (status: checked - verified in a running system)
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
        DATA temp9 LIKE sy-subrc.
          DATA temp10 LIKE sy-subrc.
        DATA temp11 LIKE sy-subrc.
          DATA temp12 LIKE sy-subrc.
        DATA query TYPE string.
          DATA temp13 TYPE z2ui5_cl_smpc_app_580=>ty_t_product.
          DATA product LIKE LINE OF t_products.
        DATA temp1 TYPE xsdboolean.

    CASE client->get_event( ).

      WHEN `LIST_ITEM`.
        " onListItemPress: navTo('detail') - the helper's next state for
        " level 1 opens the mid column, the route carries the product INDEX
        detail_bind( client->get_event_arg( ) ).
        
        READ TABLE t_products WITH KEY productid = client->get_event_arg( ) TRANSPORTING NO FIELDS.
        temp9 = sy-subrc.
        IF temp9 = 0.
          
          READ TABLE t_products WITH KEY productid = client->get_event_arg( ) TRANSPORTING NO FIELDS.
          temp10 = sy-tabix.
          product_ix = temp10 - 1.
        ENDIF.
        route  = `detail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `SUPPLIER_ITEM`.
        " handleItemPress: navTo('detailDetail') - level 2 opens the end column
        dd_text = client->get_event_arg( ).
        
        READ TABLE t_suppliers WITH KEY text = dd_text TRANSPORTING NO FIELDS.
        temp11 = sy-subrc.
        IF temp11 = 0.
          
          READ TABLE t_suppliers WITH KEY text = dd_text TRANSPORTING NO FIELDS.
          temp12 = sy-tabix.
          supplier_ix = temp12 - 1.
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
          
          CLEAR temp13.
          t_rows = temp13.
          
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
    DATA temp14 TYPE string.
    DATA temp15 TYPE string.
    DATA seg2 LIKE temp14.
    DATA temp16 TYPE string.
    DATA temp17 TYPE string.
    DATA seg3 LIKE temp16.
    DATA temp18 TYPE string.
    DATA temp19 TYPE string.
        DATA temp20 TYPE i.
        DATA temp21 TYPE string.
          FIELD-SYMBOLS <temp22> LIKE LINE OF t_products.
          DATA temp23 LIKE sy-tabix.
        DATA temp24 TYPE i.
        DATA temp25 TYPE i.
        DATA temp26 TYPE string.
        DATA temp27 TYPE string.
        DATA temp1 TYPE string.
          FIELD-SYMBOLS <temp1> LIKE LINE OF t_seg.
          DATA temp2 LIKE sy-tabix.
          FIELD-SYMBOLS <temp28> LIKE LINE OF t_products.
          DATA temp29 LIKE sy-tabix.
          FIELD-SYMBOLS <temp30> LIKE LINE OF t_suppliers.
          DATA temp31 LIKE sy-tabix.
        FIELD-SYMBOLS <temp32> LIKE LINE OF t_seg.
        DATA temp33 LIKE sy-tabix.
    path = hash.
    IF path CS `#`.
      path = substring_after( val = path sub = `#` ).
    ENDIF.
    path = shift_left( val = path sub = `/` ).
    
    SPLIT path AT `/` INTO TABLE t_seg.
    DELETE t_seg WHERE table_line IS INITIAL.

    
    CLEAR temp14.
    
    READ TABLE t_seg INTO temp15 INDEX 2.
    IF sy-subrc = 0.
      temp14 = temp15.
    ENDIF.
    
    seg2 = temp14.
    
    CLEAR temp16.
    
    READ TABLE t_seg INTO temp17 INDEX 3.
    IF sy-subrc = 0.
      temp16 = temp17.
    ENDIF.
    
    seg3 = temp16.

    
    CLEAR temp18.
    
    READ TABLE t_seg INTO temp19 INDEX 1.
    IF sy-subrc = 0.
      temp18 = temp19.
    ENDIF.
    CASE temp18.
      WHEN ``.
        route  = `list`.
        layout = `TwoColumnsMidExpanded`.

      WHEN `page2`.
        route  = `page2`.
        layout = `EndColumnFullScreen`.

      WHEN `detail`.
        route      = `detail`.
        
        IF seg2 CO `0123456789` AND seg2 IS NOT INITIAL AND strlen( seg2 ) <= 4.
          temp20 = seg2.
        ELSE.
          CLEAR temp20.
        ENDIF.
        product_ix = temp20.
        
        IF seg3 IS NOT INITIAL.
          temp21 = seg3.
        ELSE.
          temp21 = `TwoColumnsMidExpanded`.
        ENDIF.
        layout     = temp21.
        IF product_ix < lines( t_products ).
          
          
          temp23 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp22>.
          sy-tabix = temp23.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp22>-productid ).
        ENDIF.

      WHEN `detailDetail`.
        route       = `detailDetail`.
        
        IF seg2 CO `0123456789` AND seg2 IS NOT INITIAL AND strlen( seg2 ) <= 4.
          temp24 = seg2.
        ELSE.
          CLEAR temp24.
        ENDIF.
        product_ix  = temp24.
        
        IF seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4.
          temp25 = seg3.
        ELSE.
          CLEAR temp25.
        ENDIF.
        supplier_ix = temp25.
        
        CLEAR temp26.
        
        READ TABLE t_seg INTO temp27 INDEX 4.
        IF sy-subrc = 0.
          temp26 = temp27.
        ENDIF.
        
        IF temp26 IS NOT INITIAL.
          
          
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
          
          
          temp29 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp28>.
          sy-tabix = temp29.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp28>-productid ).
        ENDIF.
        IF supplier_ix < lines( t_suppliers ).
          
          
          temp31 = sy-tabix.
          READ TABLE t_suppliers INDEX supplier_ix + 1 ASSIGNING <temp30>.
          sy-tabix = temp31.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          dd_text = <temp30>-text.
        ENDIF.

      WHEN OTHERS.
        " the single-segment ':layout:' list route, e.g. '#/OneColumn'
        route  = `list`.
        
        
        temp33 = sy-tabix.
        READ TABLE t_seg INDEX 1 ASSIGNING <temp32>.
        sy-tabix = temp33.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        layout = <temp32>.
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
    DATA temp34 TYPE z2ui5_cl_smpc_app_580=>ty_t_product.
    DATA temp35 LIKE LINE OF temp34.
    DATA temp36 TYPE z2ui5_cl_smpc_app_580=>ty_t_supplier.
    DATA temp37 LIKE LINE OF temp36.
    CLEAR temp34.
    
    temp35-productid = `HT-1000`.
    temp35-name = `Notebook Basic 15`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp35-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp35-price = `956`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1001`.
    temp35-name = `Notebook Basic 17`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp35-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp35-price = `1249`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1002`.
    temp35-name = `Notebook Basic 18`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp35-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp35-price = `1570`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1003`.
    temp35-name = `Notebook Basic 19`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Smartcards`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp35-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp35-price = `1650`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1007`.
    temp35-name = `ITelO Vault`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp35-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp35-price = `299`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1010`.
    temp35-name = `Notebook Professional 15`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp35-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp35-price = `1999`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1011`.
    temp35-name = `Notebook Professional 17`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp35-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp35-price = `2299`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1020`.
    temp35-name = `ITelO Vault Net`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp35-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp35-price = `459`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1021`.
    temp35-name = `ITelO Vault SAT`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp35-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp35-price = `149`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1022`.
    temp35-name = `Comfort Easy`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp35-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp35-price = `1679`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1023`.
    temp35-name = `Comfort Senior`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp35-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp35-price = `512`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1030`.
    temp35-name = `Ergo Screen E-I`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screen Monitors`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp35-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp35-price = `230`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1031`.
    temp35-name = `Ergo Screen E-II`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screen Monitors`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp35-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp35-price = `285`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1032`.
    temp35-name = `Ergo Screen E-III`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screen Monitors`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp35-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp35-price = `345`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1035`.
    temp35-name = `Flat Basic`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screen Monitors`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp35-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp35-price = `399`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1036`.
    temp35-name = `Flat Future`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screen Monitors`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp35-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp35-price = `430`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1037`.
    temp35-name = `Flat XL`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screen Monitors`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp35-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp35-price = `1230`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1040`.
    temp35-name = `Laser Professional Eco`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Printers`.
    temp35-suppliername = `Alpha Printers`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp35-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp35-price = `830`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1041`.
    temp35-name = `Laser Basic`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Printers`.
    temp35-suppliername = `Alpha Printers`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp35-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp35-price = `490`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1042`.
    temp35-name = `Laser Allround`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Printers`.
    temp35-suppliername = `Alpha Printers`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp35-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp35-price = `349`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1050`.
    temp35-name = `Ultra Jet Super Color`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Printers`.
    temp35-suppliername = `Alpha Printers`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp35-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp35-price = `139`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1051`.
    temp35-name = `Ultra Jet Mobile`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Printers`.
    temp35-suppliername = `Printer for All`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp35-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp35-price = `99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1052`.
    temp35-name = `Ultra Jet Super Highspeed`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Printers`.
    temp35-suppliername = `Printer for All`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp35-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp35-price = `170`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1055`.
    temp35-name = `Multi Print`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Multifunction Printers`.
    temp35-suppliername = `Printer for All`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp35-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp35-price = `99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1056`.
    temp35-name = `Multi Color`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Multifunction Printers`.
    temp35-suppliername = `Printer for All`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp35-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp35-price = `119`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1060`.
    temp35-name = `Cordless Mouse`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Mice`.
    temp35-suppliername = `Oxynum`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp35-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp35-price = `9`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1061`.
    temp35-name = `Speed Mouse`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Mice`.
    temp35-suppliername = `Oxynum`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp35-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp35-price = `7`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1062`.
    temp35-name = `Track Mouse`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Mice`.
    temp35-suppliername = `Oxynum`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp35-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp35-price = `11`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1063`.
    temp35-name = `Ergonomic Keyboard`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Keyboards`.
    temp35-suppliername = `Oxynum`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp35-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp35-price = `14`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1064`.
    temp35-name = `Internet Keyboard`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Keyboards`.
    temp35-suppliername = `Oxynum`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp35-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp35-price = `16`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1065`.
    temp35-name = `Media Keyboard`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Keyboards`.
    temp35-suppliername = `Oxynum`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp35-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp35-price = `26`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1066`.
    temp35-name = `Mousepad`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Mousepads`.
    temp35-suppliername = `Oxynum`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp35-description = `Nice mouse pad with ITelO Logo`.
    temp35-price = `6.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1067`.
    temp35-name = `Ergo Mousepad`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Mousepads`.
    temp35-suppliername = `Oxynum`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp35-description = `Ergonomic mouse pad with ITelO Logo`.
    temp35-price = `8.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1068`.
    temp35-name = `Designer Mousepad`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Mousepads`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp35-description = `ITelO Mousepad Special Edition`.
    temp35-price = `12.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1069`.
    temp35-name = `Universal card reader`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Computer System Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp35-description = `Universal card reader`.
    temp35-price = `14`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1070`.
    temp35-name = `Proctra X`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Graphic Cards`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp35-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp35-price = `70.9`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1071`.
    temp35-name = `Gladiator MX`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Graphic Cards`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp35-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp35-price = `81.7`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1072`.
    temp35-name = `Hurricane GX`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Graphic Cards`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp35-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp35-price = `101.2`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1073`.
    temp35-name = `Hurricane GX/LN`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Graphic Cards`.
    temp35-suppliername = `Smartcards`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp35-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp35-price = `139.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1080`.
    temp35-name = `Photo Scan`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Scanners`.
    temp35-suppliername = `Printer for All`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp35-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp35-price = `129`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1081`.
    temp35-name = `Power Scan`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Scanners`.
    temp35-suppliername = `Printer for All`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp35-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp35-price = `89`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1082`.
    temp35-name = `Jet Scan Professional`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Scanners`.
    temp35-suppliername = `Printer for All`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp35-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp35-price = `169`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1083`.
    temp35-name = `Jet Scan Professional`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Scanners`.
    temp35-suppliername = `Printer for All`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp35-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp35-price = `189`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1085`.
    temp35-name = `Copymaster`.
    temp35-maincategory = `Printers & Scanners`.
    temp35-category = `Multifunction Printers`.
    temp35-suppliername = `Alpha Printers`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp35-description = `Copymaster`.
    temp35-price = `1499`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1090`.
    temp35-name = `Surround Sound`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Speakers`.
    temp35-suppliername = `Speaker Experts`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp35-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp35-price = `39`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1091`.
    temp35-name = `Blaster Extreme`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Speakers`.
    temp35-suppliername = `Speaker Experts`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp35-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp35-price = `26`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1092`.
    temp35-name = `Sound Booster`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Speakers`.
    temp35-suppliername = `Speaker Experts`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp35-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp35-price = `45`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1095`.
    temp35-name = `Lovely Sound 5.1 Wireless`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp35-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp35-price = `49`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1096`.
    temp35-name = `Lovely Sound 5.1`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp35-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp35-price = `39`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1097`.
    temp35-name = `Lovely Sound Stereo`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp35-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp35-price = `29`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1100`.
    temp35-name = `Smart Office`.
    temp35-maincategory = `Software`.
    temp35-category = `Software`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp35-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp35-price = `89.9`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1101`.
    temp35-name = `Smart Design`.
    temp35-maincategory = `Software`.
    temp35-category = `Software`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp35-description = `Complete package, 1 User, Image editing, processing`.
    temp35-price = `79.9`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1102`.
    temp35-name = `Smart Network`.
    temp35-maincategory = `Software`.
    temp35-category = `Software`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp35-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp35-price = `69`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1103`.
    temp35-name = `Smart Multimedia`.
    temp35-maincategory = `Software`.
    temp35-category = `Software`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp35-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp35-price = `77`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1104`.
    temp35-name = `Smart Games`.
    temp35-maincategory = `Software`.
    temp35-category = `Software`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp35-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp35-price = `55`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1105`.
    temp35-name = `Smart Internet Antivirus`.
    temp35-maincategory = `Software`.
    temp35-category = `Software`.
    temp35-suppliername = `Brainsoft`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp35-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp35-price = `29`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1106`.
    temp35-name = `Smart Firewall`.
    temp35-maincategory = `Software`.
    temp35-category = `Software`.
    temp35-suppliername = `Brainsoft`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp35-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp35-price = `34`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1107`.
    temp35-name = `Smart Money`.
    temp35-maincategory = `Software`.
    temp35-category = `Software`.
    temp35-suppliername = `Brainsoft`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp35-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp35-price = `29.9`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1110`.
    temp35-name = `PC Lock`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Computer System Accessories`.
    temp35-suppliername = `Red Point Stores`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp35-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp35-price = `8.9`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1111`.
    temp35-name = `Notebook Lock`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Computer System Accessories`.
    temp35-suppliername = `Red Point Stores`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp35-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp35-price = `6.9`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1112`.
    temp35-name = `Web cam reality`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Computer System Accessories`.
    temp35-suppliername = `Red Point Stores`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp35-description = `Color webcam, color, High-Speed USB`.
    temp35-price = `39`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1113`.
    temp35-name = `Screen clean`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Computer System Accessories`.
    temp35-suppliername = `Red Point Stores`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp35-description = `10 separately packed screen wipes`.
    temp35-price = `2.3`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1114`.
    temp35-name = `Fabric bag professional`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Computer System Accessories`.
    temp35-suppliername = `Red Point Stores`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp35-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp35-price = `31`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1115`.
    temp35-name = `Wireless DSL Router`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Telecommunications`.
    temp35-suppliername = `Red Point Stores`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp35-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp35-price = `49`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1116`.
    temp35-name = `Wireless DSL Router / Repeater`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Telecommunications`.
    temp35-suppliername = `Red Point Stores`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp35-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp35-price = `59`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1117`.
    temp35-name = `Wireless DSL Router / Repeater and Print Server`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Telecommunications`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp35-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp35-price = `69`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1118`.
    temp35-name = `USB Stick`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Computer System Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp35-description = `USB 2.0 High-Speed 64 GB`.
    temp35-price = `35`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1119`.
    temp35-name = `Travel Adapter`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp35-description = `Universal Travel Adapter`.
    temp35-price = `79`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1120`.
    temp35-name = `Cordless Bluetooth Keyboard, english international`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Keyboards`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp35-description = `Cordless Bluetooth Keyboard with English keys`.
    temp35-price = `29`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1137`.
    temp35-name = `Flat XXL`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screen Monitors`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp35-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp35-price = `1430`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1138`.
    temp35-name = `Pocket Mouse`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Mice`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp35-description = `Portable pocket Mouse with retracting cord`.
    temp35-price = `23`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1210`.
    temp35-name = `PC Power Station`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `PCs`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp35-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp35-price = `2399`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1251`.
    temp35-name = `Astro Laptop 1516`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp35-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp35-price = `989`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1252`.
    temp35-name = `Astro Phone 6`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Smartphones and Tablets`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp35-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp35-price = `649`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1253`.
    temp35-name = `Benda Laptop 1408`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp35-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp35-price = `976`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1254`.
    temp35-name = `Bending Screen 21HD`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screens`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp35-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp35-price = `250`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1255`.
    temp35-name = `Broad Screen 22HD`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Flat Screens`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp35-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp35-price = `270`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1256`.
    temp35-name = `Cerdik Phone 7`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Smartphones and Tablets`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp35-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1257`.
    temp35-name = `Cepat Tablet 10.5`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Smartphones and Tablets`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp35-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1258`.
    temp35-name = `Cepat Tablet 8`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Smartphones and Tablets`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp35-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp35-price = `529`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1500`.
    temp35-name = `Server Basic`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Servers`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp35-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp35-price = `5000`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1501`.
    temp35-name = `Server Professional`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Servers`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp35-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp35-price = `15000`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1502`.
    temp35-name = `Server Power Pro`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Servers`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp35-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp35-price = `25000`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1600`.
    temp35-name = `Family PC Basic`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Desktop Computers`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp35-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp35-price = `600`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1601`.
    temp35-name = `Family PC Pro`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Desktop Computers`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp35-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp35-price = `900`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1602`.
    temp35-name = `Gaming Monster`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Desktop Computers`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp35-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp35-price = `1200`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1603`.
    temp35-name = `Gaming Monster Pro`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Desktop Computers`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp35-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp35-price = `1700`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2000`.
    temp35-name = `7" Widescreen Portable DVD Player w MP3`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp35-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp35-price = `249.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2001`.
    temp35-name = `10" Portable DVD player`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp35-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp35-price = `449.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2002`.
    temp35-name = `Portable DVD Player with 9" LCD Monitor`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp35-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp35-price = `853.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2025`.
    temp35-name = `CD/DVD case: 264 sleeves`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp35-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp35-price = `44.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2026`.
    temp35-name = `Audio/Video Cable Kit - 4m`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp35-description = `Quality cables for notebooks and projectors`.
    temp35-price = `29.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2027`.
    temp35-name = `Removable CD/DVD Laser Labels`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp35-description = `Removable jewel case labels, zero residues (100)`.
    temp35-price = `8.99`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6100`.
    temp35-name = `Beam Breaker B-1`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp35-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp35-price = `469`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6101`.
    temp35-name = `Beam Breaker B-2`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp35-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp35-price = `679`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6102`.
    temp35-name = `Beam Breaker B-3`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Technocom`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp35-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp35-price = `889`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6110`.
    temp35-name = `Play Movie`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp35-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp35-price = `130`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6111`.
    temp35-name = `Record Movie`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp35-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp35-price = `288`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6120`.
    temp35-name = `ITelo MusicStick`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp35-description = `64 GB USB Music-on-Available-Stick`.
    temp35-price = `45`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6121`.
    temp35-name = `ITelo Jog-Mate`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp35-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp35-price = `63`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6122`.
    temp35-name = `Power Pro Player 40`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp35-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp35-price = `167`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6123`.
    temp35-name = `Power Pro Player 80`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp35-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp35-price = `299`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6130`.
    temp35-name = `Flat Watch HD32`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Flat Screen TVs`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp35-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp35-price = `1459`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6131`.
    temp35-name = `Flat Watch HD37`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Flat Screen TVs`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp35-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp35-price = `1199`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6132`.
    temp35-name = `Flat Watch HD41`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Flat Screen TVs`.
    temp35-suppliername = `Very Best Screens`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp35-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp35-price = `899`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-7000`.
    temp35-name = `Copperberry`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp35-description = `Our new multifunctional Handheld with phone function in copper`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-7010`.
    temp35-name = `Silverberry`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp35-description = `Our new multifunctional Handheld with phone function in silver`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-7020`.
    temp35-name = `Goldberry`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp35-description = `Our new multifunctional Handheld with phone function in gold`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-7030`.
    temp35-name = `Platinberry`.
    temp35-maincategory = `Computer Components`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Fasttech`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp35-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-8000`.
    temp35-name = `ITelO FlexTop I4000`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp35-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp35-price = `799`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-8001`.
    temp35-name = `ITelO FlexTop I6300c`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp35-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp35-price = `799`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-8002`.
    temp35-name = `ITelO FlexTop I9100`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp35-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp35-price = `1199`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-8003`.
    temp35-name = `ITelO FlexTop I9800`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Laptops`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp35-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp35-price = `1388`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9991`.
    temp35-name = `Smartphone Leather Case`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp35-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp35-price = `25`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9992`.
    temp35-name = `Smartphone Alpha`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Smartphones and Tablets`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp35-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp35-price = `599`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9993`.
    temp35-name = `Mini Tablet`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Smartphones and Tablets`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp35-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp35-price = `833`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9994`.
    temp35-name = `Camcorder View`.
    temp35-maincategory = `TV, Video & HiFi`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp35-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp35-price = `1388`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9995`.
    temp35-name = `Tablet Pouch`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp35-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp35-price = `20`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9996`.
    temp35-name = `Tablet Pouch`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp35-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp35-price = `20`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9997`.
    temp35-name = `e-Book Reader ReadMe`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Smartphones and Tablets`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp35-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp35-price = `33`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9998`.
    temp35-name = `Smartphone Beta`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Smartphones and Tablets`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp35-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp35-price = `30`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9999`.
    temp35-name = `Maxi Tablet`.
    temp35-maincategory = `Smartphones & Tablets`.
    temp35-category = `Tablets`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp35-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp35-price = `749`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `PF-1000`.
    temp35-name = `Flyer`.
    temp35-maincategory = `Computer Systems`.
    temp35-category = `Accessories`.
    temp35-suppliername = `Titanium`.
    temp35-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp35-description = `Flyer for our product palette`.
    temp35-price = `0`.
    temp35-currencycode = `EUR`.
    INSERT temp35 INTO TABLE temp34.
    t_products = temp34.

    " /ProductCollectionStats/Filters/1/values - the twelve suppliers
    
    CLEAR temp36.
    
    temp37-text = `Titanium`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Technocom`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Red Point Stores`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Very Best Screens`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Smartcards`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Alpha Printers`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Printer for All`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Oxynum`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Fasttech`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Ultrasonic United`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Speaker Experts`.
    INSERT temp37 INTO TABLE temp36.
    temp37-text = `Brainsoft`.
    INSERT temp37 INTO TABLE temp36.
    t_suppliers = temp36.

  ENDMETHOD.

ENDCLASS.
