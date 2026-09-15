" @keywords table sap.m tablescrolltoindex flexiblecolumnlayout dynamicpage dynamicpagetitle title overflowtoolbar toolbarspacer searchfield column text
" @summary This sample demonstrates the scroll-to-index functionality.
" @origin sap.m.sample.TableScrollToIndex - https://sdk.openui5.org/entity/sap.m.Table/sample/sap.m.sample.TableScrollToIndex (status: generated - machine-written, not yet reviewed)
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
    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_app_575=>ty_s_product.
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
          DATA temp5 TYPE string_table.
          DATA temp1 LIKE LINE OF temp5.
        DATA query TYPE string.
          DATA temp7 TYPE z2ui5_cl_smpc_app_575=>ty_t_product.
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
        IF sy-subrc = 0.
          product_ix = sy-tabix - 1.
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
          
          CLEAR temp5.
          INSERT `productsTable` INTO TABLE temp5.
          INSERT `scrollToIndex` INTO TABLE temp5.
          
          temp1 = |{ press_index }|.
          INSERT temp1 INTO TABLE temp5.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = temp5 ).
        ENDIF.

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
        FIELD-SYMBOLS <temp18> LIKE LINE OF t_seg.
        DATA temp19 LIKE sy-tabix.
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
        route  = `master`.
        layout = `OneColumn`.

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

      WHEN OTHERS.
        " the single-segment ':layout:' master route, e.g. '#/OneColumn'
        route  = `master`.
        
        
        temp19 = sy-tabix.
        READ TABLE t_seg INDEX 1 ASSIGNING <temp18>.
        sy-tabix = temp19.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        layout = <temp18>.
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
    DATA temp20 TYPE z2ui5_cl_smpc_app_575=>ty_t_product.
    DATA temp21 LIKE LINE OF temp20.
    CLEAR temp20.
    
    temp21-productid = `HT-1000`.
    temp21-name = `Notebook Basic 15`.
    temp21-quantity = `10`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg`.
    temp21-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp21-price = `956`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1001`.
    temp21-name = `Notebook Basic 17`.
    temp21-quantity = `20`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1001.jpg`.
    temp21-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp21-price = `1249`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1002`.
    temp21-name = `Notebook Basic 18`.
    temp21-quantity = `10`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1002.jpg`.
    temp21-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp21-price = `1570`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1003`.
    temp21-name = `Notebook Basic 19`.
    temp21-quantity = `15`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Smartcards`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1003.jpg`.
    temp21-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp21-price = `1650`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1007`.
    temp21-name = `ITelO Vault`.
    temp21-quantity = `15`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1007.jpg`.
    temp21-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp21-price = `299`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1010`.
    temp21-name = `Notebook Professional 15`.
    temp21-quantity = `16`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1010.jpg`.
    temp21-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp21-price = `1999`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1011`.
    temp21-name = `Notebook Professional 17`.
    temp21-quantity = `17`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1011.jpg`.
    temp21-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp21-price = `2299`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1020`.
    temp21-name = `ITelO Vault Net`.
    temp21-quantity = `14`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1020.jpg`.
    temp21-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp21-price = `459`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1021`.
    temp21-name = `ITelO Vault SAT`.
    temp21-quantity = `50`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1021.jpg`.
    temp21-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp21-price = `149`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1022`.
    temp21-name = `Comfort Easy`.
    temp21-quantity = `30`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1022.jpg`.
    temp21-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp21-price = `1679`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1023`.
    temp21-name = `Comfort Senior`.
    temp21-quantity = `24`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1023.jpg`.
    temp21-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp21-price = `512`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1030`.
    temp21-name = `Ergo Screen E-I`.
    temp21-quantity = `14`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screen Monitors`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1030.jpg`.
    temp21-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp21-price = `230`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1031`.
    temp21-name = `Ergo Screen E-II`.
    temp21-quantity = `24`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screen Monitors`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1031.jpg`.
    temp21-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp21-price = `285`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1032`.
    temp21-name = `Ergo Screen E-III`.
    temp21-quantity = `50`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screen Monitors`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1032.jpg`.
    temp21-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp21-price = `345`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1035`.
    temp21-name = `Flat Basic`.
    temp21-quantity = `23`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screen Monitors`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1035.jpg`.
    temp21-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp21-price = `399`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1036`.
    temp21-name = `Flat Future`.
    temp21-quantity = `22`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screen Monitors`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1036.jpg`.
    temp21-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp21-price = `430`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1037`.
    temp21-name = `Flat XL`.
    temp21-quantity = `23`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screen Monitors`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1037.jpg`.
    temp21-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp21-price = `1230`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1040`.
    temp21-name = `Laser Professional Eco`.
    temp21-quantity = `21`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Printers`.
    temp21-suppliername = `Alpha Printers`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1040.jpg`.
    temp21-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp21-price = `830`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1041`.
    temp21-name = `Laser Basic`.
    temp21-quantity = `8`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Printers`.
    temp21-suppliername = `Alpha Printers`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1041.jpg`.
    temp21-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp21-price = `490`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1042`.
    temp21-name = `Laser Allround`.
    temp21-quantity = `9`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Printers`.
    temp21-suppliername = `Alpha Printers`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1042.jpg`.
    temp21-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp21-price = `349`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1050`.
    temp21-name = `Ultra Jet Super Color`.
    temp21-quantity = `17`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Printers`.
    temp21-suppliername = `Alpha Printers`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1050.jpg`.
    temp21-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp21-price = `139`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1051`.
    temp21-name = `Ultra Jet Mobile`.
    temp21-quantity = `18`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Printers`.
    temp21-suppliername = `Printer for All`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1051.jpg`.
    temp21-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp21-price = `99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1052`.
    temp21-name = `Ultra Jet Super Highspeed`.
    temp21-quantity = `25`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Printers`.
    temp21-suppliername = `Printer for All`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1052.jpg`.
    temp21-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp21-price = `170`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1055`.
    temp21-name = `Multi Print`.
    temp21-quantity = `16`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Multifunction Printers`.
    temp21-suppliername = `Printer for All`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1055.jpg`.
    temp21-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp21-price = `99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1056`.
    temp21-name = `Multi Color`.
    temp21-quantity = `5`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Multifunction Printers`.
    temp21-suppliername = `Printer for All`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1056.jpg`.
    temp21-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp21-price = `119`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1060`.
    temp21-name = `Cordless Mouse`.
    temp21-quantity = `25`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Mice`.
    temp21-suppliername = `Oxynum`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1060.jpg`.
    temp21-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp21-price = `9`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1061`.
    temp21-name = `Speed Mouse`.
    temp21-quantity = `12`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Mice`.
    temp21-suppliername = `Oxynum`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1061.jpg`.
    temp21-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp21-price = `7`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1062`.
    temp21-name = `Track Mouse`.
    temp21-quantity = `12`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Mice`.
    temp21-suppliername = `Oxynum`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1062.jpg`.
    temp21-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp21-price = `11`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1063`.
    temp21-name = `Ergonomic Keyboard`.
    temp21-quantity = `50`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Keyboards`.
    temp21-suppliername = `Oxynum`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1063.jpg`.
    temp21-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp21-price = `14`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1064`.
    temp21-name = `Internet Keyboard`.
    temp21-quantity = `35`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Keyboards`.
    temp21-suppliername = `Oxynum`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1064.jpg`.
    temp21-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp21-price = `16`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1065`.
    temp21-name = `Media Keyboard`.
    temp21-quantity = `26`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Keyboards`.
    temp21-suppliername = `Oxynum`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1065.jpg`.
    temp21-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp21-price = `26`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1066`.
    temp21-name = `Mousepad`.
    temp21-quantity = `12`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Mousepads`.
    temp21-suppliername = `Oxynum`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1066.jpg`.
    temp21-description = `Nice mouse pad with ITelO Logo`.
    temp21-price = `6.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1067`.
    temp21-name = `Ergo Mousepad`.
    temp21-quantity = `16`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Mousepads`.
    temp21-suppliername = `Oxynum`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1067.jpg`.
    temp21-description = `Ergonomic mouse pad with ITelO Logo`.
    temp21-price = `8.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1068`.
    temp21-name = `Designer Mousepad`.
    temp21-quantity = `26`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Mousepads`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1068.jpg`.
    temp21-description = `ITelO Mousepad Special Edition`.
    temp21-price = `12.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1069`.
    temp21-name = `Universal card reader`.
    temp21-quantity = `22`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Computer System Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1069.jpg`.
    temp21-description = `Universal card reader`.
    temp21-price = `14`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1070`.
    temp21-name = `Proctra X`.
    temp21-quantity = `15`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Graphic Cards`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1070.jpg`.
    temp21-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp21-price = `70.9`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1071`.
    temp21-name = `Gladiator MX`.
    temp21-quantity = `16`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Graphic Cards`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1071.jpg`.
    temp21-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp21-price = `81.7`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1072`.
    temp21-name = `Hurricane GX`.
    temp21-quantity = `13`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Graphic Cards`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1072.jpg`.
    temp21-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp21-price = `101.2`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1073`.
    temp21-name = `Hurricane GX/LN`.
    temp21-quantity = `5`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Graphic Cards`.
    temp21-suppliername = `Smartcards`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1073.jpg`.
    temp21-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp21-price = `139.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1080`.
    temp21-name = `Photo Scan`.
    temp21-quantity = `8`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Scanners`.
    temp21-suppliername = `Printer for All`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1080.jpg`.
    temp21-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp21-price = `129`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1081`.
    temp21-name = `Power Scan`.
    temp21-quantity = `11`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Scanners`.
    temp21-suppliername = `Printer for All`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1081.jpg`.
    temp21-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp21-price = `89`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1082`.
    temp21-name = `Jet Scan Professional`.
    temp21-quantity = `13`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Scanners`.
    temp21-suppliername = `Printer for All`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1082.jpg`.
    temp21-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp21-price = `169`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1083`.
    temp21-name = `Jet Scan Professional`.
    temp21-quantity = `10`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Scanners`.
    temp21-suppliername = `Printer for All`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1083.jpg`.
    temp21-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp21-price = `189`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1085`.
    temp21-name = `Copymaster`.
    temp21-quantity = `10`.
    temp21-maincategory = `Printers & Scanners`.
    temp21-category = `Multifunction Printers`.
    temp21-suppliername = `Alpha Printers`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1085.jpg`.
    temp21-description = `Copymaster`.
    temp21-price = `1499`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1090`.
    temp21-name = `Surround Sound`.
    temp21-quantity = `20`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Speakers`.
    temp21-suppliername = `Speaker Experts`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1090.jpg`.
    temp21-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp21-price = `39`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1091`.
    temp21-name = `Blaster Extreme`.
    temp21-quantity = `15`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Speakers`.
    temp21-suppliername = `Speaker Experts`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1091.jpg`.
    temp21-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp21-price = `26`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1092`.
    temp21-name = `Sound Booster`.
    temp21-quantity = `50`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Speakers`.
    temp21-suppliername = `Speaker Experts`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1092.jpg`.
    temp21-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp21-price = `45`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1095`.
    temp21-name = `Lovely Sound 5.1 Wireless`.
    temp21-quantity = `12`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1095.jpg`.
    temp21-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp21-price = `49`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1096`.
    temp21-name = `Lovely Sound 5.1`.
    temp21-quantity = `18`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1096.jpg`.
    temp21-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp21-price = `39`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1097`.
    temp21-name = `Lovely Sound Stereo`.
    temp21-quantity = `21`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1097.jpg`.
    temp21-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp21-price = `29`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1100`.
    temp21-name = `Smart Office`.
    temp21-quantity = `25`.
    temp21-maincategory = `Software`.
    temp21-category = `Software`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1100.jpg`.
    temp21-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp21-price = `89.9`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1101`.
    temp21-name = `Smart Design`.
    temp21-quantity = `26`.
    temp21-maincategory = `Software`.
    temp21-category = `Software`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1101.jpg`.
    temp21-description = `Complete package, 1 User, Image editing, processing`.
    temp21-price = `79.9`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1102`.
    temp21-name = `Smart Network`.
    temp21-quantity = `28`.
    temp21-maincategory = `Software`.
    temp21-category = `Software`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1102.jpg`.
    temp21-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp21-price = `69`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1103`.
    temp21-name = `Smart Multimedia`.
    temp21-quantity = `9`.
    temp21-maincategory = `Software`.
    temp21-category = `Software`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1103.jpg`.
    temp21-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp21-price = `77`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1104`.
    temp21-name = `Smart Games`.
    temp21-quantity = `13`.
    temp21-maincategory = `Software`.
    temp21-category = `Software`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1104.jpg`.
    temp21-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp21-price = `55`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1105`.
    temp21-name = `Smart Internet Antivirus`.
    temp21-quantity = `17`.
    temp21-maincategory = `Software`.
    temp21-category = `Software`.
    temp21-suppliername = `Brainsoft`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1105.jpg`.
    temp21-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp21-price = `29`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1106`.
    temp21-name = `Smart Firewall`.
    temp21-quantity = `19`.
    temp21-maincategory = `Software`.
    temp21-category = `Software`.
    temp21-suppliername = `Brainsoft`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1106.jpg`.
    temp21-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp21-price = `34`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1107`.
    temp21-name = `Smart Money`.
    temp21-quantity = `18`.
    temp21-maincategory = `Software`.
    temp21-category = `Software`.
    temp21-suppliername = `Brainsoft`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1107.jpg`.
    temp21-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp21-price = `29.9`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1110`.
    temp21-name = `PC Lock`.
    temp21-quantity = `14`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Computer System Accessories`.
    temp21-suppliername = `Red Point Stores`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1110.jpg`.
    temp21-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp21-price = `8.9`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1111`.
    temp21-name = `Notebook Lock`.
    temp21-quantity = `20`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Computer System Accessories`.
    temp21-suppliername = `Red Point Stores`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1111.jpg`.
    temp21-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp21-price = `6.9`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1112`.
    temp21-name = `Web cam reality`.
    temp21-quantity = `27`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Computer System Accessories`.
    temp21-suppliername = `Red Point Stores`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1112.jpg`.
    temp21-description = `Color webcam, color, High-Speed USB`.
    temp21-price = `39`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1113`.
    temp21-name = `Screen clean`.
    temp21-quantity = `17`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Computer System Accessories`.
    temp21-suppliername = `Red Point Stores`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1113.jpg`.
    temp21-description = `10 separately packed screen wipes`.
    temp21-price = `2.3`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1114`.
    temp21-name = `Fabric bag professional`.
    temp21-quantity = `14`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Computer System Accessories`.
    temp21-suppliername = `Red Point Stores`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1114.jpg`.
    temp21-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp21-price = `31`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1115`.
    temp21-name = `Wireless DSL Router`.
    temp21-quantity = `16`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Telecommunications`.
    temp21-suppliername = `Red Point Stores`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1115.jpg`.
    temp21-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp21-price = `49`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1116`.
    temp21-name = `Wireless DSL Router / Repeater`.
    temp21-quantity = `12`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Telecommunications`.
    temp21-suppliername = `Red Point Stores`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1116.jpg`.
    temp21-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp21-price = `59`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1117`.
    temp21-name = `Wireless DSL Router / Repeater and Print Server`.
    temp21-quantity = `12`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Telecommunications`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1117.jpg`.
    temp21-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp21-price = `69`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1118`.
    temp21-name = `USB Stick`.
    temp21-quantity = `14`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Computer System Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1118.jpg`.
    temp21-description = `USB 2.0 High-Speed 64 GB`.
    temp21-price = `35`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1119`.
    temp21-name = `Travel Adapter`.
    temp21-quantity = `10`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1119.jpg`.
    temp21-description = `Universal Travel Adapter`.
    temp21-price = `79`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1120`.
    temp21-name = `Cordless Bluetooth Keyboard, english international`.
    temp21-quantity = `13`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Keyboards`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1120.jpg`.
    temp21-description = `Cordless Bluetooth Keyboard with English keys`.
    temp21-price = `29`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1137`.
    temp21-name = `Flat XXL`.
    temp21-quantity = `10`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screen Monitors`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1137.jpg`.
    temp21-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp21-price = `1430`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1138`.
    temp21-name = `Pocket Mouse`.
    temp21-quantity = `20`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Mice`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1138.jpg`.
    temp21-description = `Portable pocket Mouse with retracting cord`.
    temp21-price = `23`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1210`.
    temp21-name = `PC Power Station`.
    temp21-quantity = `22`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `PCs`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1210.jpg`.
    temp21-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp21-price = `2399`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1251`.
    temp21-name = `Astro Laptop 1516`.
    temp21-quantity = `23`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1251.jpg`.
    temp21-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp21-price = `989`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1252`.
    temp21-name = `Astro Phone 6`.
    temp21-quantity = `28`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Smartphones and Tablets`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1252.jpg`.
    temp21-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp21-price = `649`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1253`.
    temp21-name = `Benda Laptop 1408`.
    temp21-quantity = `27`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1253.jpg`.
    temp21-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp21-price = `976`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1254`.
    temp21-name = `Bending Screen 21HD`.
    temp21-quantity = `23`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screens`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1254.jpg`.
    temp21-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp21-price = `250`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1255`.
    temp21-name = `Broad Screen 22HD`.
    temp21-quantity = `5`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Flat Screens`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1255.jpg`.
    temp21-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp21-price = `270`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1256`.
    temp21-name = `Cerdik Phone 7`.
    temp21-quantity = `19`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Smartphones and Tablets`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1256.jpg`.
    temp21-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp21-price = `549`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1257`.
    temp21-name = `Cepat Tablet 10.5`.
    temp21-quantity = `17`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Smartphones and Tablets`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1257.jpg`.
    temp21-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp21-price = `549`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1258`.
    temp21-name = `Cepat Tablet 8`.
    temp21-quantity = `24`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Smartphones and Tablets`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1258.jpg`.
    temp21-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp21-price = `529`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1500`.
    temp21-name = `Server Basic`.
    temp21-quantity = `24`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Servers`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1500.jpg`.
    temp21-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp21-price = `5000`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1501`.
    temp21-name = `Server Professional`.
    temp21-quantity = `26`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Servers`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1501.jpg`.
    temp21-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp21-price = `15000`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1502`.
    temp21-name = `Server Power Pro`.
    temp21-quantity = `34`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Servers`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1502.jpg`.
    temp21-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp21-price = `25000`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1600`.
    temp21-name = `Family PC Basic`.
    temp21-quantity = `10`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Desktop Computers`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1600.jpg`.
    temp21-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp21-price = `600`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1601`.
    temp21-name = `Family PC Pro`.
    temp21-quantity = `20`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Desktop Computers`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1601.jpg`.
    temp21-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp21-price = `900`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1602`.
    temp21-name = `Gaming Monster`.
    temp21-quantity = `24`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Desktop Computers`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1602.jpg`.
    temp21-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp21-price = `1200`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-1603`.
    temp21-name = `Gaming Monster Pro`.
    temp21-quantity = `25`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Desktop Computers`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-1603.jpg`.
    temp21-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp21-price = `1700`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-2000`.
    temp21-name = `7" Widescreen Portable DVD Player w MP3`.
    temp21-quantity = `20`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2000.jpg`.
    temp21-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp21-price = `249.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-2001`.
    temp21-name = `10" Portable DVD player`.
    temp21-quantity = `21`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2001.jpg`.
    temp21-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp21-price = `449.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-2002`.
    temp21-name = `Portable DVD Player with 9" LCD Monitor`.
    temp21-quantity = `50`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2002.jpg`.
    temp21-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp21-price = `853.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-2025`.
    temp21-name = `CD/DVD case: 264 sleeves`.
    temp21-quantity = `26`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2025.jpg`.
    temp21-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp21-price = `44.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-2026`.
    temp21-name = `Audio/Video Cable Kit - 4m`.
    temp21-quantity = `16`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2026.jpg`.
    temp21-description = `Quality cables for notebooks and projectors`.
    temp21-price = `29.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-2027`.
    temp21-name = `Removable CD/DVD Laser Labels`.
    temp21-quantity = `25`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-2027.jpg`.
    temp21-description = `Removable jewel case labels, zero residues (100)`.
    temp21-price = `8.99`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6100`.
    temp21-name = `Beam Breaker B-1`.
    temp21-quantity = `32`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6100.jpg`.
    temp21-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp21-price = `469`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6101`.
    temp21-name = `Beam Breaker B-2`.
    temp21-quantity = `18`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6101.jpg`.
    temp21-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp21-price = `679`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6102`.
    temp21-name = `Beam Breaker B-3`.
    temp21-quantity = `16`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Technocom`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6102.jpg`.
    temp21-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp21-price = `889`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6110`.
    temp21-name = `Play Movie`.
    temp21-quantity = `15`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6110.jpg`.
    temp21-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp21-price = `130`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6111`.
    temp21-name = `Record Movie`.
    temp21-quantity = `24`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6111.jpg`.
    temp21-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp21-price = `288`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6120`.
    temp21-name = `ITelo MusicStick`.
    temp21-quantity = `15`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6120.jpg`.
    temp21-description = `64 GB USB Music-on-Available-Stick`.
    temp21-price = `45`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6121`.
    temp21-name = `ITelo Jog-Mate`.
    temp21-quantity = `24`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6121.jpg`.
    temp21-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp21-price = `63`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6122`.
    temp21-name = `Power Pro Player 40`.
    temp21-quantity = `23`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6122.jpg`.
    temp21-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp21-price = `167`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6123`.
    temp21-name = `Power Pro Player 80`.
    temp21-quantity = `13`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6123.jpg`.
    temp21-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp21-price = `299`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6130`.
    temp21-name = `Flat Watch HD32`.
    temp21-quantity = `16`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Flat Screen TVs`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6130.jpg`.
    temp21-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp21-price = `1459`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6131`.
    temp21-name = `Flat Watch HD37`.
    temp21-quantity = `14`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Flat Screen TVs`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6131.jpg`.
    temp21-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp21-price = `1199`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-6132`.
    temp21-name = `Flat Watch HD41`.
    temp21-quantity = `13`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Flat Screen TVs`.
    temp21-suppliername = `Very Best Screens`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-6132.jpg`.
    temp21-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp21-price = `899`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-7000`.
    temp21-name = `Copperberry`.
    temp21-quantity = `5`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7000.jpg`.
    temp21-description = `Our new multifunctional Handheld with phone function in copper`.
    temp21-price = `549`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-7010`.
    temp21-name = `Silverberry`.
    temp21-quantity = `9`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7010.jpg`.
    temp21-description = `Our new multifunctional Handheld with phone function in silver`.
    temp21-price = `549`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-7020`.
    temp21-name = `Goldberry`.
    temp21-quantity = `11`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7020.jpg`.
    temp21-description = `Our new multifunctional Handheld with phone function in gold`.
    temp21-price = `549`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-7030`.
    temp21-name = `Platinberry`.
    temp21-quantity = `12`.
    temp21-maincategory = `Computer Components`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Fasttech`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-7030.jpg`.
    temp21-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp21-price = `549`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-8000`.
    temp21-name = `ITelO FlexTop I4000`.
    temp21-quantity = `11`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8000.jpg`.
    temp21-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp21-price = `799`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-8001`.
    temp21-name = `ITelO FlexTop I6300c`.
    temp21-quantity = `20`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8001.jpg`.
    temp21-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp21-price = `799`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-8002`.
    temp21-name = `ITelO FlexTop I9100`.
    temp21-quantity = `20`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8002.jpg`.
    temp21-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp21-price = `1199`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-8003`.
    temp21-name = `ITelO FlexTop I9800`.
    temp21-quantity = `22`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Laptops`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-8003.jpg`.
    temp21-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp21-price = `1388`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9991`.
    temp21-name = `Smartphone Leather Case`.
    temp21-quantity = `12`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9991.jpg`.
    temp21-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp21-price = `25`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9992`.
    temp21-name = `Smartphone Alpha`.
    temp21-quantity = `13`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Smartphones and Tablets`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9992.jpg`.
    temp21-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp21-price = `599`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9993`.
    temp21-name = `Mini Tablet`.
    temp21-quantity = `10`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Smartphones and Tablets`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9993.jpg`.
    temp21-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp21-price = `833`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9994`.
    temp21-name = `Camcorder View`.
    temp21-quantity = `50`.
    temp21-maincategory = `TV, Video & HiFi`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Ultrasonic United`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9994.jpg`.
    temp21-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp21-price = `1388`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9995`.
    temp21-name = `Tablet Pouch`.
    temp21-quantity = `34`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9995.jpg`.
    temp21-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp21-price = `20`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9996`.
    temp21-name = `Tablet Pouch`.
    temp21-quantity = `34`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9996.jpg`.
    temp21-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp21-price = `20`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9997`.
    temp21-name = `e-Book Reader ReadMe`.
    temp21-quantity = `23`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Smartphones and Tablets`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9997.jpg`.
    temp21-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp21-price = `33`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9998`.
    temp21-name = `Smartphone Beta`.
    temp21-quantity = `21`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Smartphones and Tablets`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9998.jpg`.
    temp21-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp21-price = `30`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `HT-9999`.
    temp21-name = `Maxi Tablet`.
    temp21-quantity = `20`.
    temp21-maincategory = `Smartphones & Tablets`.
    temp21-category = `Tablets`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/HT-9999.jpg`.
    temp21-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp21-price = `749`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    temp21-productid = `PF-1000`.
    temp21-name = `Flyer`.
    temp21-quantity = `33`.
    temp21-maincategory = `Computer Systems`.
    temp21-category = `Accessories`.
    temp21-suppliername = `Titanium`.
    temp21-productpicurl = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/PF-1000.jpg`.
    temp21-description = `Flyer for our product palette`.
    temp21-price = `0`.
    temp21-currencycode = `EUR`.
    INSERT temp21 INTO TABLE temp20.
    t_products = temp20.

  ENDMETHOD.

ENDCLASS.
