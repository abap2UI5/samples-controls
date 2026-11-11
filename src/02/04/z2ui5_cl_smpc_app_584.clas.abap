" @keywords flexiblecolumnlayout flexible column layout sap.f shellbarwithflexiblecolumnlayout shellbar menu menuitem avatar dynamicpage dynamicpagetitle
" @summary Example of Shell Bar in combination with Flexible Column Layout.
" @origin sap.f.sample.ShellBarWithFlexibleColumnLayout - https://sdk.openui5.org/entity/sap.f.FlexibleColumnLayout/sample/sap.f.sample.ShellBarWithFlexibleColumnLayout (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_584 DEFINITION PUBLIC.

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

    " the FlexibleColumnLayout state the router drives in the original
    DATA layout      TYPE string VALUE `OneColumn`.
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


CLASS z2ui5_cl_smpc_app_584 IMPLEMENTATION.

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

    " the router also matches a deep link / reload (`#/detail/1/
    " TwoColumnsMidExpanded`): the live hash rides in s_config-hash on every
    " request; applying it is idempotent, so a rebuild whose hash matches the
    " state simply re-derives it
    DATA hash TYPE z2ui5_if_client=>ty_s_get-s_config-hash.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail_title TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA sections TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA end_column TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp3 TYPE string_table.
    DATA temp5 TYPE string_table.
    hash = client->get( )-s_config-hash.
    IF hash IS NOT INITIAL AND hash <> `#`.
      hash_apply( hash ).
    ENDIF.

    
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    page = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:f`    v = `sap.f`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:uxap` v = `sap.uxap`

        )->ele( `Page` ).

    " the ShellBar is the page's custom header; its back button only shows while
    " the end column is full screen, which is a pure expression over the layout
    page->ele( `customHeader`
        )->ele( n = `ShellBar` ns = `f`
            )->a( n = `title`               v = `Application Title`
            )->a( n = `secondTitle`         v = `Short description`
            )->a( n = `homeIcon`            v = `https://sdk.openui5.org/resources/sap/ui/documentation/sdk/images/logo_sap.png`
            )->a( n = `showCopilot`         v = `true`
            )->a( n = `showSearch`          v = `true`
            )->a( n = `showNotifications`   v = `true`
            )->a( n = `notificationsNumber` v = `2`
            )->a( n = `showNavButton`       v = |\{= ${ client->_bind( layout ) } === 'EndColumnFullScreen' \}|
            " handleBackButtonPressed is window.history.go(-1): one real step
            " back that CONSUMES the history entry - the hash change then
            " round-trips as HASH_CHANGED and restores that route
            )->a( n = `navButtonPressed`    v = client->follow_up_action( client->cs_event-hash_back )

            )->ele( n = `menu` ns = `f`
                )->ele( `Menu`
                    )->tag( `MenuItem`
                        )->a( n = `text` v = `Flight booking`
                        )->a( n = `icon` v = `sap-icon://flight`
                    )->tag( `MenuItem`
                        )->a( n = `text` v = `Car rental`
                        )->a( n = `icon` v = `sap-icon://car-rental`

                )->end(
            )->end(
            )->ele( n = `profile` ns = `f`
                )->tag( `Avatar`
                    )->a( n = `initials` v = `UI`

            )->end(
        )->end(
    )->end( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/isNavigationArrow}` INTO TABLE temp1.
    INSERT `${$parameters>/layout}` INTO TABLE temp1.
    
    fcl = page->ele( n = `FlexibleColumnLayout` ns = `f`
        )->a( n = `id`               v = `fcl`
        )->a( n = `backgroundDesign` v = `Solid`
        " the original wires stateChange to onStateChanged: only a layout
        " change by a NAVIGATION ARROW replace-navTo's the URL - the flag
        " and the new layout travel with the event, the backend guards on it
        )->a( n = `stateChange`      v = client->_event( val = `STATE_CHANGED` t_arg = temp1 )
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
            )->ele( `HBox`
                )->a( n = `wrap`       v = `NoWrap`
                )->a( n = `alignItems` v = `Center`
                )->a( n = `class`      v = `sapUiTinyMarginEnd`

                )->tag( `Avatar`
                    )->a( n = `src`          v = client->_bind( d_productpicurl )
                    )->a( n = `displaySize`  v = `S`
                    )->a( n = `displayShape` v = `Square`
                    )->a( n = `class`        v = `sapUiTinyMarginEnd`
                )->ele( `VBox`
                    )->a( n = `wrap` v = `Wrap`

                    )->tag( `Title`
                        )->a( n = `text`     v = client->_bind( d_name )
                        )->a( n = `wrapping` v = `true`
                    )->tag( `Label`
                        )->a( n = `text`     v = client->_bind( d_productid )
                        )->a( n = `wrapping` v = `true`

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

    " the original's router, app-owned: the hash carries the route the way
    " the manifest patterns spell it, and a hash change the app did not
    " write (browser Back/Forward, a manual edit) round-trips as
    " HASH_CHANGED. Re-asserted per render - it dies with an app switch
    
    CLEAR temp5.
    INSERT `HASH_CHANGED` INTO TABLE temp5.
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = temp5 ).

  ENDMETHOD.


  METHOD detail_bind.

    " Detail.controller's bindElement( '/ProductCollection/<n>' ) - the relative
    " bindings of the original resolve against the bound element, the port folds
    " them to root-seeded fields (app 229 idiom)
    " IS ASSIGNED, not sy-subrc: a SUCCESSFUL dynamic ASSIGN does not reset
    " sy-subrc on every release (abap2UI5 #1937)
    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_app_584=>ty_s_product.
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
          DATA temp7 TYPE z2ui5_cl_smpc_app_584=>ty_t_product.
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
        " handleFullScreen: navTo('detail') with the helper's fullScreen layout
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
          
          CLEAR temp7.
          t_rows = temp7.
          
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
    " route, indices and layout. The original's patterns: '' (list start),
    " '{layout}' (the ':layout:' list route), 'page2',
    " 'detail/{product}/{layout}',
    " 'detailDetail/{product}/{supplier}/{layout}' - product/supplier are
    " INDICES into the mock collections, defaulting to 0 like the original's
    " `arguments.product || this._product || "0"`
    DATA path LIKE hash.
    DATA t_seg TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA temp8 TYPE string.
    DATA temp9 TYPE string.
    DATA seg2 LIKE temp8.
    DATA temp10 TYPE string.
    DATA temp11 TYPE string.
    DATA seg3 LIKE temp10.
    DATA temp12 TYPE string.
    DATA temp13 TYPE string.
        DATA temp14 TYPE i.
        DATA temp15 TYPE string.
          FIELD-SYMBOLS <temp16> LIKE LINE OF t_products.
          DATA temp17 LIKE sy-tabix.
        DATA temp18 TYPE i.
        DATA temp19 TYPE i.
        DATA temp20 TYPE string.
        DATA temp21 TYPE string.
        DATA temp1 TYPE string.
          FIELD-SYMBOLS <temp1> LIKE LINE OF t_seg.
          DATA temp2 LIKE sy-tabix.
          FIELD-SYMBOLS <temp22> LIKE LINE OF t_products.
          DATA temp23 LIKE sy-tabix.
          FIELD-SYMBOLS <temp24> LIKE LINE OF t_suppliers.
          DATA temp25 LIKE sy-tabix.
        FIELD-SYMBOLS <temp26> LIKE LINE OF t_seg.
        DATA temp27 LIKE sy-tabix.
    path = hash.
    IF path CS `#`.
      path = substring_after( val = path sub = `#` ).
    ENDIF.
    SHIFT path LEFT DELETING LEADING `/`.
    
    SPLIT path AT `/` INTO TABLE t_seg.
    DELETE t_seg WHERE table_line IS INITIAL.

    
    CLEAR temp8.
    
    READ TABLE t_seg INTO temp9 INDEX 2.
    IF sy-subrc = 0.
      temp8 = temp9.
    ENDIF.
    
    seg2 = temp8.
    
    CLEAR temp10.
    
    READ TABLE t_seg INTO temp11 INDEX 3.
    IF sy-subrc = 0.
      temp10 = temp11.
    ENDIF.
    
    seg3 = temp10.

    
    CLEAR temp12.
    
    READ TABLE t_seg INTO temp13 INDEX 1.
    IF sy-subrc = 0.
      temp12 = temp13.
    ENDIF.
    CASE temp12.
      WHEN ``.
        route  = `list`.
        layout = `OneColumn`.

      WHEN `page2`.
        route  = `page2`.
        layout = `EndColumnFullScreen`.

      WHEN `detail`.
        route      = `detail`.
        
        IF seg2 CO `0123456789` AND seg2 IS NOT INITIAL AND strlen( seg2 ) <= 4.
          temp14 = seg2.
        ELSE.
          CLEAR temp14.
        ENDIF.
        product_ix = temp14.
        
        IF seg3 IS NOT INITIAL.
          temp15 = seg3.
        ELSE.
          temp15 = `TwoColumnsMidExpanded`.
        ENDIF.
        layout     = temp15.
        IF product_ix < lines( t_products ).
          
          
          temp17 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp16>.
          sy-tabix = temp17.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp16>-productid ).
        ENDIF.

      WHEN `detailDetail`.
        route       = `detailDetail`.
        
        IF seg2 CO `0123456789` AND seg2 IS NOT INITIAL AND strlen( seg2 ) <= 4.
          temp18 = seg2.
        ELSE.
          CLEAR temp18.
        ENDIF.
        product_ix  = temp18.
        
        IF seg3 CO `0123456789` AND seg3 IS NOT INITIAL AND strlen( seg3 ) <= 4.
          temp19 = seg3.
        ELSE.
          CLEAR temp19.
        ENDIF.
        supplier_ix = temp19.
        
        CLEAR temp20.
        
        READ TABLE t_seg INTO temp21 INDEX 4.
        IF sy-subrc = 0.
          temp20 = temp21.
        ENDIF.
        
        IF temp20 IS NOT INITIAL.
          
          
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
          
          
          temp23 = sy-tabix.
          READ TABLE t_products INDEX product_ix + 1 ASSIGNING <temp22>.
          sy-tabix = temp23.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_bind( <temp22>-productid ).
        ENDIF.
        IF supplier_ix < lines( t_suppliers ).
          
          
          temp25 = sy-tabix.
          READ TABLE t_suppliers INDEX supplier_ix + 1 ASSIGNING <temp24>.
          sy-tabix = temp25.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          dd_text = <temp24>-text.
        ENDIF.

      WHEN OTHERS.
        " the single-segment ':layout:' list route, e.g. '#/OneColumn'
        route  = `list`.
        
        
        temp27 = sy-tabix.
        READ TABLE t_seg INDEX 1 ASSIGNING <temp26>.
        sy-tabix = temp27.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        layout = <temp26>.
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
    DATA temp28 TYPE z2ui5_cl_smpc_app_584=>ty_t_product.
    DATA temp29 LIKE LINE OF temp28.
    DATA temp30 TYPE z2ui5_cl_smpc_app_584=>ty_t_supplier.
    DATA temp31 LIKE LINE OF temp30.
    CLEAR temp28.
    
    temp29-productid = `HT-1000`.
    temp29-name = `Notebook Basic 15`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp29-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp29-price = `956`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1001`.
    temp29-name = `Notebook Basic 17`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp29-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp29-price = `1249`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1002`.
    temp29-name = `Notebook Basic 18`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp29-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp29-price = `1570`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1003`.
    temp29-name = `Notebook Basic 19`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Smartcards`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp29-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp29-price = `1650`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1007`.
    temp29-name = `ITelO Vault`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp29-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp29-price = `299`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1010`.
    temp29-name = `Notebook Professional 15`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp29-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp29-price = `1999`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1011`.
    temp29-name = `Notebook Professional 17`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp29-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp29-price = `2299`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1020`.
    temp29-name = `ITelO Vault Net`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp29-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp29-price = `459`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1021`.
    temp29-name = `ITelO Vault SAT`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp29-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp29-price = `149`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1022`.
    temp29-name = `Comfort Easy`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp29-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp29-price = `1679`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1023`.
    temp29-name = `Comfort Senior`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp29-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp29-price = `512`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1030`.
    temp29-name = `Ergo Screen E-I`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screen Monitors`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp29-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp29-price = `230`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1031`.
    temp29-name = `Ergo Screen E-II`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screen Monitors`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp29-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp29-price = `285`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1032`.
    temp29-name = `Ergo Screen E-III`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screen Monitors`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp29-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp29-price = `345`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1035`.
    temp29-name = `Flat Basic`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screen Monitors`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp29-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp29-price = `399`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1036`.
    temp29-name = `Flat Future`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screen Monitors`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp29-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp29-price = `430`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1037`.
    temp29-name = `Flat XL`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screen Monitors`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp29-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp29-price = `1230`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1040`.
    temp29-name = `Laser Professional Eco`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Printers`.
    temp29-suppliername = `Alpha Printers`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp29-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp29-price = `830`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1041`.
    temp29-name = `Laser Basic`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Printers`.
    temp29-suppliername = `Alpha Printers`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp29-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp29-price = `490`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1042`.
    temp29-name = `Laser Allround`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Printers`.
    temp29-suppliername = `Alpha Printers`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp29-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp29-price = `349`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1050`.
    temp29-name = `Ultra Jet Super Color`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Printers`.
    temp29-suppliername = `Alpha Printers`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp29-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp29-price = `139`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1051`.
    temp29-name = `Ultra Jet Mobile`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Printers`.
    temp29-suppliername = `Printer for All`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp29-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp29-price = `99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1052`.
    temp29-name = `Ultra Jet Super Highspeed`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Printers`.
    temp29-suppliername = `Printer for All`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp29-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp29-price = `170`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1055`.
    temp29-name = `Multi Print`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Multifunction Printers`.
    temp29-suppliername = `Printer for All`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp29-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp29-price = `99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1056`.
    temp29-name = `Multi Color`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Multifunction Printers`.
    temp29-suppliername = `Printer for All`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp29-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp29-price = `119`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1060`.
    temp29-name = `Cordless Mouse`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Mice`.
    temp29-suppliername = `Oxynum`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp29-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp29-price = `9`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1061`.
    temp29-name = `Speed Mouse`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Mice`.
    temp29-suppliername = `Oxynum`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp29-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp29-price = `7`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1062`.
    temp29-name = `Track Mouse`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Mice`.
    temp29-suppliername = `Oxynum`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp29-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp29-price = `11`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1063`.
    temp29-name = `Ergonomic Keyboard`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Keyboards`.
    temp29-suppliername = `Oxynum`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp29-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp29-price = `14`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1064`.
    temp29-name = `Internet Keyboard`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Keyboards`.
    temp29-suppliername = `Oxynum`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp29-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp29-price = `16`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1065`.
    temp29-name = `Media Keyboard`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Keyboards`.
    temp29-suppliername = `Oxynum`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp29-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp29-price = `26`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1066`.
    temp29-name = `Mousepad`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Mousepads`.
    temp29-suppliername = `Oxynum`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp29-description = `Nice mouse pad with ITelO Logo`.
    temp29-price = `6.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1067`.
    temp29-name = `Ergo Mousepad`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Mousepads`.
    temp29-suppliername = `Oxynum`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp29-description = `Ergonomic mouse pad with ITelO Logo`.
    temp29-price = `8.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1068`.
    temp29-name = `Designer Mousepad`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Mousepads`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp29-description = `ITelO Mousepad Special Edition`.
    temp29-price = `12.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1069`.
    temp29-name = `Universal card reader`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Computer System Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp29-description = `Universal card reader`.
    temp29-price = `14`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1070`.
    temp29-name = `Proctra X`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Graphic Cards`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp29-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp29-price = `70.9`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1071`.
    temp29-name = `Gladiator MX`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Graphic Cards`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp29-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp29-price = `81.7`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1072`.
    temp29-name = `Hurricane GX`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Graphic Cards`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp29-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp29-price = `101.2`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1073`.
    temp29-name = `Hurricane GX/LN`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Graphic Cards`.
    temp29-suppliername = `Smartcards`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp29-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp29-price = `139.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1080`.
    temp29-name = `Photo Scan`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Scanners`.
    temp29-suppliername = `Printer for All`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp29-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp29-price = `129`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1081`.
    temp29-name = `Power Scan`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Scanners`.
    temp29-suppliername = `Printer for All`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp29-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp29-price = `89`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1082`.
    temp29-name = `Jet Scan Professional`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Scanners`.
    temp29-suppliername = `Printer for All`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp29-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp29-price = `169`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1083`.
    temp29-name = `Jet Scan Professional`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Scanners`.
    temp29-suppliername = `Printer for All`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp29-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp29-price = `189`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1085`.
    temp29-name = `Copymaster`.
    temp29-maincategory = `Printers & Scanners`.
    temp29-category = `Multifunction Printers`.
    temp29-suppliername = `Alpha Printers`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp29-description = `Copymaster`.
    temp29-price = `1499`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1090`.
    temp29-name = `Surround Sound`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Speakers`.
    temp29-suppliername = `Speaker Experts`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp29-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp29-price = `39`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1091`.
    temp29-name = `Blaster Extreme`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Speakers`.
    temp29-suppliername = `Speaker Experts`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp29-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp29-price = `26`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1092`.
    temp29-name = `Sound Booster`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Speakers`.
    temp29-suppliername = `Speaker Experts`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp29-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp29-price = `45`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1095`.
    temp29-name = `Lovely Sound 5.1 Wireless`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp29-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp29-price = `49`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1096`.
    temp29-name = `Lovely Sound 5.1`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp29-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp29-price = `39`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1097`.
    temp29-name = `Lovely Sound Stereo`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp29-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp29-price = `29`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1100`.
    temp29-name = `Smart Office`.
    temp29-maincategory = `Software`.
    temp29-category = `Software`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp29-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp29-price = `89.9`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1101`.
    temp29-name = `Smart Design`.
    temp29-maincategory = `Software`.
    temp29-category = `Software`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp29-description = `Complete package, 1 User, Image editing, processing`.
    temp29-price = `79.9`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1102`.
    temp29-name = `Smart Network`.
    temp29-maincategory = `Software`.
    temp29-category = `Software`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp29-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp29-price = `69`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1103`.
    temp29-name = `Smart Multimedia`.
    temp29-maincategory = `Software`.
    temp29-category = `Software`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp29-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp29-price = `77`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1104`.
    temp29-name = `Smart Games`.
    temp29-maincategory = `Software`.
    temp29-category = `Software`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp29-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp29-price = `55`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1105`.
    temp29-name = `Smart Internet Antivirus`.
    temp29-maincategory = `Software`.
    temp29-category = `Software`.
    temp29-suppliername = `Brainsoft`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp29-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp29-price = `29`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1106`.
    temp29-name = `Smart Firewall`.
    temp29-maincategory = `Software`.
    temp29-category = `Software`.
    temp29-suppliername = `Brainsoft`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp29-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp29-price = `34`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1107`.
    temp29-name = `Smart Money`.
    temp29-maincategory = `Software`.
    temp29-category = `Software`.
    temp29-suppliername = `Brainsoft`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp29-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp29-price = `29.9`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1110`.
    temp29-name = `PC Lock`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Computer System Accessories`.
    temp29-suppliername = `Red Point Stores`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp29-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp29-price = `8.9`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1111`.
    temp29-name = `Notebook Lock`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Computer System Accessories`.
    temp29-suppliername = `Red Point Stores`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp29-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp29-price = `6.9`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1112`.
    temp29-name = `Web cam reality`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Computer System Accessories`.
    temp29-suppliername = `Red Point Stores`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp29-description = `Color webcam, color, High-Speed USB`.
    temp29-price = `39`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1113`.
    temp29-name = `Screen clean`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Computer System Accessories`.
    temp29-suppliername = `Red Point Stores`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp29-description = `10 separately packed screen wipes`.
    temp29-price = `2.3`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1114`.
    temp29-name = `Fabric bag professional`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Computer System Accessories`.
    temp29-suppliername = `Red Point Stores`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp29-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp29-price = `31`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1115`.
    temp29-name = `Wireless DSL Router`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Telecommunications`.
    temp29-suppliername = `Red Point Stores`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp29-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp29-price = `49`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1116`.
    temp29-name = `Wireless DSL Router / Repeater`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Telecommunications`.
    temp29-suppliername = `Red Point Stores`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp29-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp29-price = `59`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1117`.
    temp29-name = `Wireless DSL Router / Repeater and Print Server`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Telecommunications`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp29-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp29-price = `69`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1118`.
    temp29-name = `USB Stick`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Computer System Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp29-description = `USB 2.0 High-Speed 64 GB`.
    temp29-price = `35`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1119`.
    temp29-name = `Travel Adapter`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp29-description = `Universal Travel Adapter`.
    temp29-price = `79`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1120`.
    temp29-name = `Cordless Bluetooth Keyboard, english international`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Keyboards`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp29-description = `Cordless Bluetooth Keyboard with English keys`.
    temp29-price = `29`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1137`.
    temp29-name = `Flat XXL`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screen Monitors`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp29-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp29-price = `1430`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1138`.
    temp29-name = `Pocket Mouse`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Mice`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp29-description = `Portable pocket Mouse with retracting cord`.
    temp29-price = `23`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1210`.
    temp29-name = `PC Power Station`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `PCs`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp29-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp29-price = `2399`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1251`.
    temp29-name = `Astro Laptop 1516`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp29-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp29-price = `989`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1252`.
    temp29-name = `Astro Phone 6`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Smartphones and Tablets`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp29-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp29-price = `649`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1253`.
    temp29-name = `Benda Laptop 1408`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp29-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp29-price = `976`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1254`.
    temp29-name = `Bending Screen 21HD`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screens`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp29-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp29-price = `250`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1255`.
    temp29-name = `Broad Screen 22HD`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Flat Screens`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp29-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp29-price = `270`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1256`.
    temp29-name = `Cerdik Phone 7`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Smartphones and Tablets`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp29-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp29-price = `549`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1257`.
    temp29-name = `Cepat Tablet 10.5`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Smartphones and Tablets`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp29-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp29-price = `549`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1258`.
    temp29-name = `Cepat Tablet 8`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Smartphones and Tablets`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp29-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp29-price = `529`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1500`.
    temp29-name = `Server Basic`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Servers`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp29-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp29-price = `5000`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1501`.
    temp29-name = `Server Professional`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Servers`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp29-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp29-price = `15000`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1502`.
    temp29-name = `Server Power Pro`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Servers`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp29-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp29-price = `25000`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1600`.
    temp29-name = `Family PC Basic`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Desktop Computers`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp29-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp29-price = `600`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1601`.
    temp29-name = `Family PC Pro`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Desktop Computers`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp29-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp29-price = `900`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1602`.
    temp29-name = `Gaming Monster`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Desktop Computers`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp29-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp29-price = `1200`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-1603`.
    temp29-name = `Gaming Monster Pro`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Desktop Computers`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp29-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp29-price = `1700`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-2000`.
    temp29-name = `7" Widescreen Portable DVD Player w MP3`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp29-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp29-price = `249.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-2001`.
    temp29-name = `10" Portable DVD player`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp29-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp29-price = `449.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-2002`.
    temp29-name = `Portable DVD Player with 9" LCD Monitor`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp29-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp29-price = `853.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-2025`.
    temp29-name = `CD/DVD case: 264 sleeves`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp29-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp29-price = `44.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-2026`.
    temp29-name = `Audio/Video Cable Kit - 4m`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp29-description = `Quality cables for notebooks and projectors`.
    temp29-price = `29.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-2027`.
    temp29-name = `Removable CD/DVD Laser Labels`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp29-description = `Removable jewel case labels, zero residues (100)`.
    temp29-price = `8.99`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6100`.
    temp29-name = `Beam Breaker B-1`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp29-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp29-price = `469`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6101`.
    temp29-name = `Beam Breaker B-2`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp29-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp29-price = `679`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6102`.
    temp29-name = `Beam Breaker B-3`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Technocom`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp29-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp29-price = `889`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6110`.
    temp29-name = `Play Movie`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp29-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp29-price = `130`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6111`.
    temp29-name = `Record Movie`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp29-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp29-price = `288`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6120`.
    temp29-name = `ITelo MusicStick`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp29-description = `64 GB USB Music-on-Available-Stick`.
    temp29-price = `45`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6121`.
    temp29-name = `ITelo Jog-Mate`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp29-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp29-price = `63`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6122`.
    temp29-name = `Power Pro Player 40`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp29-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp29-price = `167`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6123`.
    temp29-name = `Power Pro Player 80`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp29-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp29-price = `299`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6130`.
    temp29-name = `Flat Watch HD32`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Flat Screen TVs`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp29-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp29-price = `1459`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6131`.
    temp29-name = `Flat Watch HD37`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Flat Screen TVs`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp29-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp29-price = `1199`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-6132`.
    temp29-name = `Flat Watch HD41`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Flat Screen TVs`.
    temp29-suppliername = `Very Best Screens`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp29-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp29-price = `899`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-7000`.
    temp29-name = `Copperberry`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp29-description = `Our new multifunctional Handheld with phone function in copper`.
    temp29-price = `549`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-7010`.
    temp29-name = `Silverberry`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp29-description = `Our new multifunctional Handheld with phone function in silver`.
    temp29-price = `549`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-7020`.
    temp29-name = `Goldberry`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp29-description = `Our new multifunctional Handheld with phone function in gold`.
    temp29-price = `549`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-7030`.
    temp29-name = `Platinberry`.
    temp29-maincategory = `Computer Components`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Fasttech`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp29-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp29-price = `549`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-8000`.
    temp29-name = `ITelO FlexTop I4000`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp29-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp29-price = `799`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-8001`.
    temp29-name = `ITelO FlexTop I6300c`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp29-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp29-price = `799`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-8002`.
    temp29-name = `ITelO FlexTop I9100`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp29-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp29-price = `1199`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-8003`.
    temp29-name = `ITelO FlexTop I9800`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Laptops`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp29-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp29-price = `1388`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9991`.
    temp29-name = `Smartphone Leather Case`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp29-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp29-price = `25`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9992`.
    temp29-name = `Smartphone Alpha`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Smartphones and Tablets`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp29-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp29-price = `599`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9993`.
    temp29-name = `Mini Tablet`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Smartphones and Tablets`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp29-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp29-price = `833`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9994`.
    temp29-name = `Camcorder View`.
    temp29-maincategory = `TV, Video & HiFi`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Ultrasonic United`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp29-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp29-price = `1388`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9995`.
    temp29-name = `Tablet Pouch`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp29-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp29-price = `20`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9996`.
    temp29-name = `Tablet Pouch`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp29-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp29-price = `20`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9997`.
    temp29-name = `e-Book Reader ReadMe`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Smartphones and Tablets`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp29-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp29-price = `33`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9998`.
    temp29-name = `Smartphone Beta`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Smartphones and Tablets`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp29-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp29-price = `30`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `HT-9999`.
    temp29-name = `Maxi Tablet`.
    temp29-maincategory = `Smartphones & Tablets`.
    temp29-category = `Tablets`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp29-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp29-price = `749`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    temp29-productid = `PF-1000`.
    temp29-name = `Flyer`.
    temp29-maincategory = `Computer Systems`.
    temp29-category = `Accessories`.
    temp29-suppliername = `Titanium`.
    temp29-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp29-description = `Flyer for our product palette`.
    temp29-price = `0`.
    temp29-currencycode = `EUR`.
    INSERT temp29 INTO TABLE temp28.
    t_products = temp28.

    " /ProductCollectionStats/Filters/1/values - the twelve suppliers
    
    CLEAR temp30.
    
    temp31-text = `Titanium`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Technocom`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Red Point Stores`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Very Best Screens`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Smartcards`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Alpha Printers`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Printer for All`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Oxynum`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Fasttech`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Ultrasonic United`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Speaker Experts`.
    INSERT temp31 INTO TABLE temp30.
    temp31-text = `Brainsoft`.
    INSERT temp31 INTO TABLE temp30.
    t_suppliers = temp30.

  ENDMETHOD.

ENDCLASS.
