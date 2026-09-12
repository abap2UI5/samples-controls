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
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

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

    " the router also matches a deep link / reload (`#/detail/1/
    " TwoColumnsMidExpanded`): the live hash rides in s_config-hash on every
    " request; applying it is idempotent, so a rebuild whose hash matches the
    " state simply re-derives it
    DATA(hash) = client->get( )-s_config-hash.
    IF hash IS NOT INITIAL AND hash <> `#`.
      hash_apply( hash ).
    ENDIF.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(fcl) = view->ele( n = `View` ns = `mvc`
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
            )->a( n = `stateChange`                  v = client->_event( val = `STATE_CHANGED` t_arg = VALUE #( ( `${$parameters>/isNavigationArrow}` ) ( `${$parameters>/layout}` ) ) )
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
    DATA(detail) = fcl->ele( n = `midColumnPages` ns = `f`
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


  METHOD row_index.

    " the items binding renders T_ROWS sorted on NAME, so the row index the
    " original reads off the aggregation is the position in that order
    DATA(rows) = t_rows.
    SORT rows BY name AS TEXT ASCENDING.

    result = -1.
    LOOP AT rows INTO DATA(row).
      IF row-productid = productid.
        result = sy-tabix - 1.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD on_event.

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
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = VALUE #( ( `productsTable` ) ( `scrollToIndex` ) ( |{ press_index }| ) ) ).
        ENDIF.

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

    ENDCASE.

  ENDMETHOD.


  METHOD hash_apply.

    " the router's routeMatched, read side: parse the app hash back into
    " route, index and layout. The original's patterns: '' (master start),
    " '{layout}' (the ':layout:' master route), 'detail/{product}/{layout}' -
    " product is an INDEX into the mock collection, defaulting to 0 like the
    " original's `arguments.product || this._product || "0"`
    DATA(path) = hash.
    IF path CS `#`.
      path = substring_after( val = path sub = `#` ).
    ENDIF.
    SHIFT path LEFT DELETING LEADING `/`.
    SPLIT path AT `/` INTO TABLE DATA(t_seg).
    DELETE t_seg WHERE table_line IS INITIAL.

    DATA(seg2) = VALUE string( t_seg[ 2 ] OPTIONAL ).
    DATA(seg3) = VALUE string( t_seg[ 3 ] OPTIONAL ).

    CASE VALUE string( t_seg[ 1 ] OPTIONAL ).
      WHEN ``.
        route  = `master`.
        layout = `OneColumn`.

      WHEN `detail`.
        route      = `detail`.
        product_ix = COND #( WHEN seg2 CO `0123456789` AND seg2 IS NOT INITIAL AND strlen( seg2 ) <= 4 THEN seg2 ).
        layout     = COND #( WHEN seg3 IS NOT INITIAL THEN seg3 ELSE `TwoColumnsMidExpanded` ).
        IF product_ix < lines( t_products ).
          detail_bind( t_products[ product_ix + 1 ]-productid ).
        ENDIF.

      WHEN OTHERS.
        " the single-segment ':layout:' master route, e.g. '#/OneColumn'
        route  = `master`.
        layout = t_seg[ 1 ].
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
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
