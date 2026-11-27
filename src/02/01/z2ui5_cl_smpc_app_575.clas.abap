" @keywords table sap.m tablescrolltoindex flexiblecolumnlayout dynamicpage dynamicpagetitle title overflowtoolbar toolbarspacer searchfield column text
" @summary This sample demonstrates the scroll-to-index functionality.
" @origin sap.m.sample.TableScrollToIndex - https://sdk.openui5.org/entity/sap.m.Table/sample/sap.m.sample.TableScrollToIndex (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_575 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid     TYPE string,
        name          TYPE string,
        quantity      TYPE string,
        maincategory  TYPE string,
        category      TYPE string,
        suppliername  TYPE string,
        productpicurl TYPE string,
        description   TYPE string,
        price         TYPE p LENGTH 9 DECIMALS 2,
        currencycode  TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.

    DATA t_products   TYPE ty_t_product.
    " the rows the search leaves; the full set stays in T_PRODUCTS
    DATA t_rows       TYPE ty_t_product.

    " the FlexibleColumnLayout state the router drives in the original
    DATA layout       TYPE string VALUE `OneColumn`.
    DATA total_count  TYPE i.
    " the product the mid column shows (bindElement in the detail controller)
    DATA d_name          TYPE string.
    DATA d_productid     TYPE string.
    DATA d_maincategory  TYPE string.
    DATA d_category      TYPE string.
    DATA d_suppliername  TYPE string.
    DATA d_productpicurl TYPE string.
    DATA d_description   TYPE string.
    DATA d_price         TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    " Master.controller stores the index of the row it navigated from
    " (this.iIndex) so onColumnResize can scroll it back into view. Not bound,
    " so it stays out of the round-trip model scan
    DATA press_index TYPE i VALUE -1.

    " the router state the original keeps (currentRouteName + the route's
    " arguments): the original routes by INDEX into the mock collection
    DATA route      TYPE string VALUE `master`.
    DATA product_ix TYPE i.

    METHODS view_display.
    METHODS detail_bind IMPORTING productid TYPE string.
    METHODS row_index IMPORTING productid     TYPE string
                      RETURNING VALUE(result) TYPE i.
    METHODS on_event.
    METHODS hash_apply IMPORTING hash TYPE string.
    METHODS hash_push IMPORTING check_replace TYPE abap_bool OPTIONAL.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_575 IMPLEMENTATION.

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
    DATA temp1 TYPE string_table.
    DATA fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA detail TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp3 TYPE string_table.
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
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:uxap` v = `sap.uxap`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`                           v = `fcl`
            )->a( n = `autoFocus`                    v = `false`
            )->a( n = `restoreFocusOnBackNavigation` v = `true`
            )->a( n = `backgroundDesign`             v = `Translucent`
            " onColumnResize (@since 1.76) carries the same beginColumn flag the
            " original's handler guards on - it fires once the begin column's
            " resize has completed, which is when the pressed row has to be
            " scrolled back into view
            )->a( n = `columnResize`                 v = client->_event( val = `COLUMN_RESIZE` arg = `${$parameters>/beginColumn}` )
            " the original wires stateChange to onStateChanged: only a layout
            " change by a NAVIGATION ARROW replace-navTo's the URL - the flag
            " and the new layout travel with the event, the backend guards on it
            )->a( n = `stateChange`                  v = client->_event( val = `STATE_CHANGED` t_arg = temp1 )
            )->a( n = `layout`                       v = client->_bind( layout ) ).

    " Master.view.xml - the DynamicPage with the products table
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
                    )->a( n = `id`      v = `productsTable`
                    )->a( n = `sticky`  v = `ColumnHeaders,HeaderToolbar`
                    )->a( n = `inset`   v = `false`
                    )->a( n = `growing` v = `true`
                    )->a( n = `class`   v = `sapFDynamicPageAlignContent`
                    )->a( n = `width`   v = `auto`
                    )->a( n = `items`   v = |\{ path: '{ client->_bind_path( t_rows ) }', sorter: \{ path: 'NAME' \} \}|

                    )->ele( `headerToolbar`
                        )->ele( `OverflowToolbar`
                            )->tag( `ToolbarSpacer`
                            )->tag( `SearchField`
                                )->a( n = `width`  v = `17.5rem`
                                )->a( n = `search` v = client->_event( val = `SEARCH` arg = `${$parameters>/query}` )

                        )->end(
                    )->end(
                    )->ele( `columns`
                        )->ele( `Column`

                            )->tag( `Text`
                                )->a( n = `text` v = `Product`

                        )->end(
                        )->ele( `Column`
                            )->a( n = `minScreenWidth` v = `Desktop`
                            )->a( n = `demandPopin`    v = `true`

                            )->tag( `Text`
                                )->a( n = `text` v = `Quantity`

                        )->end(
                        )->ele( `Column`
                            )->a( n = `minScreenWidth` v = `Desktop`
                            )->a( n = `demandPopin`    v = `true`

                            )->tag( `Text`
                                )->a( n = `text` v = `Description`

                        )->end(
                        )->ele( `Column`
                            )->a( n = `hAlign` v = `End`

                            )->tag( `Text`
                                )->a( n = `text` v = `Price`

                        )->end(
                    )->end(
                    )->ele( `items`
                        )->ele( `ColumnListItem`
                            )->a( n = `type`   v = `Navigation`
                            )->a( n = `vAlign` v = `Middle`
                            )->a( n = `press`  v = client->_event( val = `LIST_ITEM` arg = `${PRODUCTID}` )

                            )->ele( `cells`
                                )->tag( `ObjectIdentifier`
                                    )->a( n = `title` v = `{NAME}`
                                    )->a( n = `text`  v = `{PRODUCTID}`
                                )->tag( `ObjectIdentifier`
                                    )->a( n = `text` v = `{QUANTITY}`
                                )->tag( `ObjectIdentifier`
                                    )->a( n = `text` v = `{DESCRIPTION}`
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

    detail->ele( n = `headerTitle` ns = `uxap`
        )->ele( n = `ObjectPageDynamicHeaderTitle` ns = `uxap`

            )->ele( n = `expandedHeading` ns = `uxap`
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
                    )->a( n = `type`    v = `Transparent`
                    )->a( n = `icon`    v = `sap-icon://full-screen`
                    )->a( n = `tooltip` v = `Enter Full Screen Mode`
                    )->a( n = `visible` v = |\{= ${ client->_bind( layout ) } !== 'MidColumnFullScreen' \}|
                    )->a( n = `press`   v = client->_event( `FULL_SCREEN` )
                )->tag( `OverflowToolbarButton`
                    )->a( n = `type`    v = `Transparent`
                    )->a( n = `icon`    v = `sap-icon://exit-full-screen`
                    )->a( n = `tooltip` v = `Exit Full Screen Mode`
                    )->a( n = `visible` v = |\{= ${ client->_bind( layout ) } === 'MidColumnFullScreen' \}|
                    )->a( n = `press`   v = client->_event( `EXIT_FULL_SCREEN` )
                )->tag( `OverflowToolbarButton`
                    )->a( n = `type`    v = `Transparent`
                    )->a( n = `icon`    v = `sap-icon://decline`
                    )->a( n = `tooltip` v = `Close column`
                    )->a( n = `visible` v = |\{= ${ client->_bind( layout ) } !== 'OneColumn' \}|
                    )->a( n = `press`   v = client->_event( `CLOSE_COLUMN` )

            )->end(
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

    detail->ele( n = `sections` ns = `uxap`
        )->ele( n = `ObjectPageSection` ns = `uxap`
            )->a( n = `title` v = `General Information`

            )->ele( n = `subSections` ns = `uxap`
                )->ele( n = `ObjectPageSubSection` ns = `uxap`

                    )->ele( n = `blocks` ns = `uxap`
                        )->ele( n = `SimpleForm` ns = `form`
                            )->a( n = `editable`   v = `false`
                            )->a( n = `layout`     v = `ResponsiveGridLayout`
                            )->a( n = `labelSpanL` v = `12`
                            )->a( n = `labelSpanM` v = `12`
                            )->a( n = `emptySpanL` v = `0`
                            )->a( n = `emptySpanM` v = `0`
                            )->a( n = `columnsL`   v = `1`
                            )->a( n = `columnsM`   v = `1`

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
        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).

    " the original's router, app-owned: the hash carries the route the way
    " the manifest patterns spell it, and a hash change the app did not
    " write (browser Back/Forward, a manual edit) round-trips as
    " HASH_CHANGED. Re-asserted per render - it dies with an app switch
    
    CLEAR temp3.
    INSERT `HASH_CHANGED` INTO TABLE temp3.
    client->follow_up_action( val   = client->cs_event-hash_attach_changed
                              t_arg = temp3 ).

  ENDMETHOD.


  METHOD detail_bind.

    " Detail.controller's bindElement( '/ProductCollection/<n>' ) - the relative
    " bindings of the original resolve against the bound element, the port folds
    " them to root-seeded fields (app 229 idiom)
    " IS ASSIGNED, not sy-subrc: a SUCCESSFUL dynamic ASSIGN does not reset
    " sy-subrc on every release (abap2UI5 #1937)
    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_app_575=>ty_s_product.
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


  METHOD row_index.

    " the items binding renders T_ROWS sorted on NAME, so the row index the
    " original reads off the aggregation is the position in that order
    DATA rows LIKE t_rows.
    DATA row LIKE LINE OF rows.
    rows = t_rows.
    SORT rows BY name AS TEXT ASCENDING.

    result = -1.
    
    LOOP AT rows INTO row.
      IF row-productid = productid.
        result = sy-tabix - 1.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD on_event.
        DATA temp5 LIKE sy-subrc.
          DATA temp6 LIKE sy-subrc.
          DATA temp7 TYPE string_table.
          DATA temp1 LIKE LINE OF temp7.
        DATA query TYPE string.
          DATA temp9 TYPE z2ui5_cl_smpc_app_575=>ty_t_product.
          DATA product LIKE LINE OF t_products.

    CASE client->get_event( ).

      WHEN `LIST_ITEM`.
        " onListItemPress: navigate to the detail route, which opens the mid
        " column - the route carries the product's INDEX into the collection
        " (the bindingContext path index of the original)
        detail_bind( client->get_event_arg( ) ).
        " oItem.getParent( )->indexOfItem( oItem ) - the index of the pressed row
        " in the RENDERED items, which the items binding sorts on NAME
        press_index = row_index( client->get_event_arg( ) ).
        
        READ TABLE t_products WITH KEY productid = client->get_event_arg( ) TRANSPORTING NO FIELDS.
        temp5 = sy-subrc.
        IF temp5 = 0.
          
          READ TABLE t_products WITH KEY productid = client->get_event_arg( ) TRANSPORTING NO FIELDS.
          temp6 = sy-tabix.
          product_ix = temp6 - 1.
        ENDIF.
        route  = `detail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `FULL_SCREEN`.
        route  = `detail`.
        layout = `MidColumnFullScreen`.
        hash_push( ).

      WHEN `EXIT_FULL_SCREEN`.
        route  = `detail`.
        layout = `TwoColumnsMidExpanded`.
        hash_push( ).

      WHEN `CLOSE_COLUMN`.
        " handleClose: navTo('master') - the ':layout:' route
        route  = `master`.
        layout = `OneColumn`.
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
        " the router's routeMatched: derive route, index and layout from the
        " hash this request carries. The instance itself is untouched, so the
        " search text survives like in the original
        hash_apply( client->get( )-s_config-hash ).

      WHEN `COLUMN_RESIZE`.
        " onColumnResize: oTable.scrollToIndex( iIndex ) once the begin column
        " has finished resizing, so the row the user pressed stays in view. The
        " original also asks oTable.$( )->is( ':visible' ); the begin column is
        " hidden exactly while the mid column is full screen, which the backend
        " reads off LAYOUT instead of the DOM
        IF client->get_event_arg( ) = abap_true
           AND press_index >= 0
           AND layout <> `MidColumnFullScreen`.
          
          CLEAR temp7.
          INSERT `productsTable` INTO TABLE temp7.
          INSERT `scrollToIndex` INTO TABLE temp7.
          
          temp1 = |{ press_index }|.
          INSERT temp1 INTO TABLE temp7.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp7 ).
        ENDIF.

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
              INSERT product INTO TABLE t_rows.
            ENDIF.
          ENDLOOP.
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD hash_apply.

    " the router's routeMatched, read side: parse the app hash back into
    " route, index and layout. The original's patterns: '' (master start),
    " '{layout}' (the ':layout:' master route), 'detail/{product}/{layout}' -
    " product is an INDEX into the mock collection, defaulting to 0 like the
    " original's `arguments.product || this._product || "0"`
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
        FIELD-SYMBOLS <temp20> LIKE LINE OF t_seg.
        DATA temp21 LIKE sy-tabix.
    path = hash.
    IF path CS `#`.
      path = substring_after( val = path sub = `#` ).
    ENDIF.
    path = shift_left( val = path sub = `/` ).
    
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
        route  = `master`.
        layout = `OneColumn`.

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

      WHEN OTHERS.
        " the single-segment ':layout:' master route, e.g. '#/OneColumn'
        route  = `master`.
        
        
        temp21 = sy-tabix.
        READ TABLE t_seg INDEX 1 ASSIGNING <temp20>.
        sy-tabix = temp21.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        layout = <temp20>.
    ENDCASE.

  ENDMETHOD.


  METHOD hash_push.

    DATA hash TYPE string.
    " the router's navTo, write side: compose the current route the way the
    " manifest patterns spell it and push it as the app-owned hash
    CASE route.
      WHEN `detail`.
        hash = |/detail/{ product_ix }/{ layout }|.
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
    " keeps its own sorter on NAME
    DATA temp22 TYPE z2ui5_cl_smpc_app_575=>ty_t_product.
    DATA temp23 LIKE LINE OF temp22.
    CLEAR temp22.
    
    temp23-productid = `HT-1000`.
    temp23-name = `Notebook Basic 15`.
    temp23-quantity = `10`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp23-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp23-price = `956`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1001`.
    temp23-name = `Notebook Basic 17`.
    temp23-quantity = `20`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp23-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp23-price = `1249`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1002`.
    temp23-name = `Notebook Basic 18`.
    temp23-quantity = `10`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp23-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp23-price = `1570`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1003`.
    temp23-name = `Notebook Basic 19`.
    temp23-quantity = `15`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Smartcards`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp23-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp23-price = `1650`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1007`.
    temp23-name = `ITelO Vault`.
    temp23-quantity = `15`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp23-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp23-price = `299`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1010`.
    temp23-name = `Notebook Professional 15`.
    temp23-quantity = `16`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp23-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp23-price = `1999`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1011`.
    temp23-name = `Notebook Professional 17`.
    temp23-quantity = `17`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp23-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp23-price = `2299`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1020`.
    temp23-name = `ITelO Vault Net`.
    temp23-quantity = `14`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp23-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp23-price = `459`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1021`.
    temp23-name = `ITelO Vault SAT`.
    temp23-quantity = `50`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp23-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp23-price = `149`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1022`.
    temp23-name = `Comfort Easy`.
    temp23-quantity = `30`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp23-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp23-price = `1679`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1023`.
    temp23-name = `Comfort Senior`.
    temp23-quantity = `24`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp23-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp23-price = `512`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1030`.
    temp23-name = `Ergo Screen E-I`.
    temp23-quantity = `14`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screen Monitors`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp23-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp23-price = `230`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1031`.
    temp23-name = `Ergo Screen E-II`.
    temp23-quantity = `24`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screen Monitors`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp23-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp23-price = `285`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1032`.
    temp23-name = `Ergo Screen E-III`.
    temp23-quantity = `50`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screen Monitors`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp23-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp23-price = `345`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1035`.
    temp23-name = `Flat Basic`.
    temp23-quantity = `23`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screen Monitors`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp23-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp23-price = `399`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1036`.
    temp23-name = `Flat Future`.
    temp23-quantity = `22`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screen Monitors`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp23-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp23-price = `430`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1037`.
    temp23-name = `Flat XL`.
    temp23-quantity = `23`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screen Monitors`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp23-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp23-price = `1230`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1040`.
    temp23-name = `Laser Professional Eco`.
    temp23-quantity = `21`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Printers`.
    temp23-suppliername = `Alpha Printers`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp23-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp23-price = `830`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1041`.
    temp23-name = `Laser Basic`.
    temp23-quantity = `8`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Printers`.
    temp23-suppliername = `Alpha Printers`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp23-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp23-price = `490`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1042`.
    temp23-name = `Laser Allround`.
    temp23-quantity = `9`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Printers`.
    temp23-suppliername = `Alpha Printers`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp23-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp23-price = `349`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1050`.
    temp23-name = `Ultra Jet Super Color`.
    temp23-quantity = `17`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Printers`.
    temp23-suppliername = `Alpha Printers`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp23-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp23-price = `139`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1051`.
    temp23-name = `Ultra Jet Mobile`.
    temp23-quantity = `18`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Printers`.
    temp23-suppliername = `Printer for All`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp23-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp23-price = `99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1052`.
    temp23-name = `Ultra Jet Super Highspeed`.
    temp23-quantity = `25`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Printers`.
    temp23-suppliername = `Printer for All`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp23-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp23-price = `170`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1055`.
    temp23-name = `Multi Print`.
    temp23-quantity = `16`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Multifunction Printers`.
    temp23-suppliername = `Printer for All`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp23-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp23-price = `99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1056`.
    temp23-name = `Multi Color`.
    temp23-quantity = `5`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Multifunction Printers`.
    temp23-suppliername = `Printer for All`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp23-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp23-price = `119`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1060`.
    temp23-name = `Cordless Mouse`.
    temp23-quantity = `25`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Mice`.
    temp23-suppliername = `Oxynum`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp23-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp23-price = `9`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1061`.
    temp23-name = `Speed Mouse`.
    temp23-quantity = `12`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Mice`.
    temp23-suppliername = `Oxynum`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp23-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp23-price = `7`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1062`.
    temp23-name = `Track Mouse`.
    temp23-quantity = `12`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Mice`.
    temp23-suppliername = `Oxynum`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp23-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp23-price = `11`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1063`.
    temp23-name = `Ergonomic Keyboard`.
    temp23-quantity = `50`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Keyboards`.
    temp23-suppliername = `Oxynum`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp23-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp23-price = `14`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1064`.
    temp23-name = `Internet Keyboard`.
    temp23-quantity = `35`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Keyboards`.
    temp23-suppliername = `Oxynum`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp23-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp23-price = `16`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1065`.
    temp23-name = `Media Keyboard`.
    temp23-quantity = `26`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Keyboards`.
    temp23-suppliername = `Oxynum`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp23-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp23-price = `26`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1066`.
    temp23-name = `Mousepad`.
    temp23-quantity = `12`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Mousepads`.
    temp23-suppliername = `Oxynum`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp23-description = `Nice mouse pad with ITelO Logo`.
    temp23-price = `6.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1067`.
    temp23-name = `Ergo Mousepad`.
    temp23-quantity = `16`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Mousepads`.
    temp23-suppliername = `Oxynum`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp23-description = `Ergonomic mouse pad with ITelO Logo`.
    temp23-price = `8.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1068`.
    temp23-name = `Designer Mousepad`.
    temp23-quantity = `26`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Mousepads`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp23-description = `ITelO Mousepad Special Edition`.
    temp23-price = `12.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1069`.
    temp23-name = `Universal card reader`.
    temp23-quantity = `22`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Computer System Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp23-description = `Universal card reader`.
    temp23-price = `14`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1070`.
    temp23-name = `Proctra X`.
    temp23-quantity = `15`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Graphic Cards`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp23-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp23-price = `70.9`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1071`.
    temp23-name = `Gladiator MX`.
    temp23-quantity = `16`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Graphic Cards`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp23-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp23-price = `81.7`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1072`.
    temp23-name = `Hurricane GX`.
    temp23-quantity = `13`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Graphic Cards`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp23-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp23-price = `101.2`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1073`.
    temp23-name = `Hurricane GX/LN`.
    temp23-quantity = `5`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Graphic Cards`.
    temp23-suppliername = `Smartcards`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp23-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp23-price = `139.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1080`.
    temp23-name = `Photo Scan`.
    temp23-quantity = `8`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Scanners`.
    temp23-suppliername = `Printer for All`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp23-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp23-price = `129`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1081`.
    temp23-name = `Power Scan`.
    temp23-quantity = `11`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Scanners`.
    temp23-suppliername = `Printer for All`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp23-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp23-price = `89`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1082`.
    temp23-name = `Jet Scan Professional`.
    temp23-quantity = `13`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Scanners`.
    temp23-suppliername = `Printer for All`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp23-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp23-price = `169`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1083`.
    temp23-name = `Jet Scan Professional`.
    temp23-quantity = `10`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Scanners`.
    temp23-suppliername = `Printer for All`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp23-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp23-price = `189`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1085`.
    temp23-name = `Copymaster`.
    temp23-quantity = `10`.
    temp23-maincategory = `Printers & Scanners`.
    temp23-category = `Multifunction Printers`.
    temp23-suppliername = `Alpha Printers`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp23-description = `Copymaster`.
    temp23-price = `1499`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1090`.
    temp23-name = `Surround Sound`.
    temp23-quantity = `20`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Speakers`.
    temp23-suppliername = `Speaker Experts`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp23-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp23-price = `39`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1091`.
    temp23-name = `Blaster Extreme`.
    temp23-quantity = `15`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Speakers`.
    temp23-suppliername = `Speaker Experts`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp23-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp23-price = `26`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1092`.
    temp23-name = `Sound Booster`.
    temp23-quantity = `50`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Speakers`.
    temp23-suppliername = `Speaker Experts`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp23-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp23-price = `45`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1095`.
    temp23-name = `Lovely Sound 5.1 Wireless`.
    temp23-quantity = `12`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp23-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp23-price = `49`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1096`.
    temp23-name = `Lovely Sound 5.1`.
    temp23-quantity = `18`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp23-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp23-price = `39`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1097`.
    temp23-name = `Lovely Sound Stereo`.
    temp23-quantity = `21`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp23-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp23-price = `29`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1100`.
    temp23-name = `Smart Office`.
    temp23-quantity = `25`.
    temp23-maincategory = `Software`.
    temp23-category = `Software`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp23-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp23-price = `89.9`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1101`.
    temp23-name = `Smart Design`.
    temp23-quantity = `26`.
    temp23-maincategory = `Software`.
    temp23-category = `Software`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp23-description = `Complete package, 1 User, Image editing, processing`.
    temp23-price = `79.9`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1102`.
    temp23-name = `Smart Network`.
    temp23-quantity = `28`.
    temp23-maincategory = `Software`.
    temp23-category = `Software`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp23-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp23-price = `69`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1103`.
    temp23-name = `Smart Multimedia`.
    temp23-quantity = `9`.
    temp23-maincategory = `Software`.
    temp23-category = `Software`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp23-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp23-price = `77`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1104`.
    temp23-name = `Smart Games`.
    temp23-quantity = `13`.
    temp23-maincategory = `Software`.
    temp23-category = `Software`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp23-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp23-price = `55`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1105`.
    temp23-name = `Smart Internet Antivirus`.
    temp23-quantity = `17`.
    temp23-maincategory = `Software`.
    temp23-category = `Software`.
    temp23-suppliername = `Brainsoft`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp23-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp23-price = `29`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1106`.
    temp23-name = `Smart Firewall`.
    temp23-quantity = `19`.
    temp23-maincategory = `Software`.
    temp23-category = `Software`.
    temp23-suppliername = `Brainsoft`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp23-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp23-price = `34`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1107`.
    temp23-name = `Smart Money`.
    temp23-quantity = `18`.
    temp23-maincategory = `Software`.
    temp23-category = `Software`.
    temp23-suppliername = `Brainsoft`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp23-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp23-price = `29.9`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1110`.
    temp23-name = `PC Lock`.
    temp23-quantity = `14`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Computer System Accessories`.
    temp23-suppliername = `Red Point Stores`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp23-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp23-price = `8.9`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1111`.
    temp23-name = `Notebook Lock`.
    temp23-quantity = `20`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Computer System Accessories`.
    temp23-suppliername = `Red Point Stores`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp23-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp23-price = `6.9`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1112`.
    temp23-name = `Web cam reality`.
    temp23-quantity = `27`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Computer System Accessories`.
    temp23-suppliername = `Red Point Stores`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp23-description = `Color webcam, color, High-Speed USB`.
    temp23-price = `39`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1113`.
    temp23-name = `Screen clean`.
    temp23-quantity = `17`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Computer System Accessories`.
    temp23-suppliername = `Red Point Stores`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp23-description = `10 separately packed screen wipes`.
    temp23-price = `2.3`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1114`.
    temp23-name = `Fabric bag professional`.
    temp23-quantity = `14`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Computer System Accessories`.
    temp23-suppliername = `Red Point Stores`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp23-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp23-price = `31`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1115`.
    temp23-name = `Wireless DSL Router`.
    temp23-quantity = `16`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Telecommunications`.
    temp23-suppliername = `Red Point Stores`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp23-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp23-price = `49`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1116`.
    temp23-name = `Wireless DSL Router / Repeater`.
    temp23-quantity = `12`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Telecommunications`.
    temp23-suppliername = `Red Point Stores`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp23-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp23-price = `59`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1117`.
    temp23-name = `Wireless DSL Router / Repeater and Print Server`.
    temp23-quantity = `12`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Telecommunications`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp23-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp23-price = `69`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1118`.
    temp23-name = `USB Stick`.
    temp23-quantity = `14`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Computer System Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp23-description = `USB 2.0 High-Speed 64 GB`.
    temp23-price = `35`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1119`.
    temp23-name = `Travel Adapter`.
    temp23-quantity = `10`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp23-description = `Universal Travel Adapter`.
    temp23-price = `79`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1120`.
    temp23-name = `Cordless Bluetooth Keyboard, english international`.
    temp23-quantity = `13`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Keyboards`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp23-description = `Cordless Bluetooth Keyboard with English keys`.
    temp23-price = `29`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1137`.
    temp23-name = `Flat XXL`.
    temp23-quantity = `10`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screen Monitors`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp23-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp23-price = `1430`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1138`.
    temp23-name = `Pocket Mouse`.
    temp23-quantity = `20`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Mice`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp23-description = `Portable pocket Mouse with retracting cord`.
    temp23-price = `23`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1210`.
    temp23-name = `PC Power Station`.
    temp23-quantity = `22`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `PCs`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp23-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp23-price = `2399`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1251`.
    temp23-name = `Astro Laptop 1516`.
    temp23-quantity = `23`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp23-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp23-price = `989`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1252`.
    temp23-name = `Astro Phone 6`.
    temp23-quantity = `28`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Smartphones and Tablets`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp23-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp23-price = `649`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1253`.
    temp23-name = `Benda Laptop 1408`.
    temp23-quantity = `27`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp23-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp23-price = `976`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1254`.
    temp23-name = `Bending Screen 21HD`.
    temp23-quantity = `23`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screens`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp23-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp23-price = `250`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1255`.
    temp23-name = `Broad Screen 22HD`.
    temp23-quantity = `5`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Flat Screens`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp23-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp23-price = `270`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1256`.
    temp23-name = `Cerdik Phone 7`.
    temp23-quantity = `19`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Smartphones and Tablets`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp23-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp23-price = `549`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1257`.
    temp23-name = `Cepat Tablet 10.5`.
    temp23-quantity = `17`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Smartphones and Tablets`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp23-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp23-price = `549`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1258`.
    temp23-name = `Cepat Tablet 8`.
    temp23-quantity = `24`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Smartphones and Tablets`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp23-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp23-price = `529`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1500`.
    temp23-name = `Server Basic`.
    temp23-quantity = `24`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Servers`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp23-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp23-price = `5000`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1501`.
    temp23-name = `Server Professional`.
    temp23-quantity = `26`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Servers`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp23-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp23-price = `15000`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1502`.
    temp23-name = `Server Power Pro`.
    temp23-quantity = `34`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Servers`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp23-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp23-price = `25000`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1600`.
    temp23-name = `Family PC Basic`.
    temp23-quantity = `10`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Desktop Computers`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp23-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp23-price = `600`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1601`.
    temp23-name = `Family PC Pro`.
    temp23-quantity = `20`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Desktop Computers`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp23-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp23-price = `900`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1602`.
    temp23-name = `Gaming Monster`.
    temp23-quantity = `24`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Desktop Computers`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp23-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp23-price = `1200`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-1603`.
    temp23-name = `Gaming Monster Pro`.
    temp23-quantity = `25`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Desktop Computers`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp23-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp23-price = `1700`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-2000`.
    temp23-name = `7" Widescreen Portable DVD Player w MP3`.
    temp23-quantity = `20`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp23-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp23-price = `249.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-2001`.
    temp23-name = `10" Portable DVD player`.
    temp23-quantity = `21`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp23-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp23-price = `449.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-2002`.
    temp23-name = `Portable DVD Player with 9" LCD Monitor`.
    temp23-quantity = `50`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp23-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp23-price = `853.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-2025`.
    temp23-name = `CD/DVD case: 264 sleeves`.
    temp23-quantity = `26`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp23-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp23-price = `44.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-2026`.
    temp23-name = `Audio/Video Cable Kit - 4m`.
    temp23-quantity = `16`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp23-description = `Quality cables for notebooks and projectors`.
    temp23-price = `29.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-2027`.
    temp23-name = `Removable CD/DVD Laser Labels`.
    temp23-quantity = `25`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp23-description = `Removable jewel case labels, zero residues (100)`.
    temp23-price = `8.99`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6100`.
    temp23-name = `Beam Breaker B-1`.
    temp23-quantity = `32`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp23-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp23-price = `469`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6101`.
    temp23-name = `Beam Breaker B-2`.
    temp23-quantity = `18`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp23-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp23-price = `679`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6102`.
    temp23-name = `Beam Breaker B-3`.
    temp23-quantity = `16`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Technocom`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp23-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp23-price = `889`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6110`.
    temp23-name = `Play Movie`.
    temp23-quantity = `15`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp23-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp23-price = `130`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6111`.
    temp23-name = `Record Movie`.
    temp23-quantity = `24`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp23-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp23-price = `288`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6120`.
    temp23-name = `ITelo MusicStick`.
    temp23-quantity = `15`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp23-description = `64 GB USB Music-on-Available-Stick`.
    temp23-price = `45`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6121`.
    temp23-name = `ITelo Jog-Mate`.
    temp23-quantity = `24`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp23-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp23-price = `63`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6122`.
    temp23-name = `Power Pro Player 40`.
    temp23-quantity = `23`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp23-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp23-price = `167`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6123`.
    temp23-name = `Power Pro Player 80`.
    temp23-quantity = `13`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp23-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp23-price = `299`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6130`.
    temp23-name = `Flat Watch HD32`.
    temp23-quantity = `16`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Flat Screen TVs`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp23-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp23-price = `1459`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6131`.
    temp23-name = `Flat Watch HD37`.
    temp23-quantity = `14`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Flat Screen TVs`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp23-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp23-price = `1199`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-6132`.
    temp23-name = `Flat Watch HD41`.
    temp23-quantity = `13`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Flat Screen TVs`.
    temp23-suppliername = `Very Best Screens`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp23-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp23-price = `899`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-7000`.
    temp23-name = `Copperberry`.
    temp23-quantity = `5`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp23-description = `Our new multifunctional Handheld with phone function in copper`.
    temp23-price = `549`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-7010`.
    temp23-name = `Silverberry`.
    temp23-quantity = `9`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp23-description = `Our new multifunctional Handheld with phone function in silver`.
    temp23-price = `549`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-7020`.
    temp23-name = `Goldberry`.
    temp23-quantity = `11`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp23-description = `Our new multifunctional Handheld with phone function in gold`.
    temp23-price = `549`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-7030`.
    temp23-name = `Platinberry`.
    temp23-quantity = `12`.
    temp23-maincategory = `Computer Components`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Fasttech`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp23-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp23-price = `549`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-8000`.
    temp23-name = `ITelO FlexTop I4000`.
    temp23-quantity = `11`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp23-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp23-price = `799`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-8001`.
    temp23-name = `ITelO FlexTop I6300c`.
    temp23-quantity = `20`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp23-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp23-price = `799`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-8002`.
    temp23-name = `ITelO FlexTop I9100`.
    temp23-quantity = `20`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp23-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp23-price = `1199`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-8003`.
    temp23-name = `ITelO FlexTop I9800`.
    temp23-quantity = `22`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Laptops`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp23-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp23-price = `1388`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9991`.
    temp23-name = `Smartphone Leather Case`.
    temp23-quantity = `12`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp23-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp23-price = `25`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9992`.
    temp23-name = `Smartphone Alpha`.
    temp23-quantity = `13`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Smartphones and Tablets`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp23-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp23-price = `599`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9993`.
    temp23-name = `Mini Tablet`.
    temp23-quantity = `10`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Smartphones and Tablets`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp23-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp23-price = `833`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9994`.
    temp23-name = `Camcorder View`.
    temp23-quantity = `50`.
    temp23-maincategory = `TV, Video & HiFi`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Ultrasonic United`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp23-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp23-price = `1388`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9995`.
    temp23-name = `Tablet Pouch`.
    temp23-quantity = `34`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp23-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp23-price = `20`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9996`.
    temp23-name = `Tablet Pouch`.
    temp23-quantity = `34`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp23-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp23-price = `20`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9997`.
    temp23-name = `e-Book Reader ReadMe`.
    temp23-quantity = `23`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Smartphones and Tablets`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp23-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp23-price = `33`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9998`.
    temp23-name = `Smartphone Beta`.
    temp23-quantity = `21`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Smartphones and Tablets`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp23-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp23-price = `30`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `HT-9999`.
    temp23-name = `Maxi Tablet`.
    temp23-quantity = `20`.
    temp23-maincategory = `Smartphones & Tablets`.
    temp23-category = `Tablets`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp23-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp23-price = `749`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    temp23-productid = `PF-1000`.
    temp23-name = `Flyer`.
    temp23-quantity = `33`.
    temp23-maincategory = `Computer Systems`.
    temp23-category = `Accessories`.
    temp23-suppliername = `Titanium`.
    temp23-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp23-description = `Flyer for our product palette`.
    temp23-price = `0`.
    temp23-currencycode = `EUR`.
    INSERT temp23 INTO TABLE temp22.
    t_products = temp22.

  ENDMETHOD.

ENDCLASS.
