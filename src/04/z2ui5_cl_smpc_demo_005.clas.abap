" @keywords bulletin board app table toolbar label toolbarspacer searchfield column text columnlistitem objectidentifier
" @summary Worklist app created with the 'Testing' tutorial. - the UI5 demo app "Bulletin Board", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Bulletin Board (sap.m/tutorial/testing) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Bulletin Board</p>
"!
"! The UI5 demo app Bulletin Board - the app the demo kit's "Testing"
"! tutorial builds - rebuilt as ONE abap2UI5 class, page for page and
"! control for control: the Shell and its App, the worklist of posts with
"! its counted table header, its search, its price states, the flag toggle
"! and the e-mail share action, and the post page with its header and the
"! two tabs the tutorial ends on. The original's router is kept: both
"! routes of its manifest.json are calls of route_to( ) here, which puts the
"! same page into the App, forward to the post and back to the worklist.
"!
"! Where it differs from the original, and why - only what an app without a
"! browser-side model layer or a URL cannot do the same way:
"!
"!  - the OData V2 service and its mock server become ABAP data - the 23
"!    posts of the mock, verbatim. The search keeps the mock server's
"!    semantics (a case-sensitive substringof on the Title), the table the
"!    sorter's order (Title ascending, compared the way the mock server's
"!    `<` does), and the flag is an ordinary two-way bound row field where
"!    the original converts the mock's 0/1 with its FlaggedType - a
"!    toggle stays in the rows like the pending change of the TwoWay OData
"!    model does, and is never written anywhere either.
"!  - the formatter module is business logic and moves to the backend: the
"!    two-decimal price (numberUnit) and the ValueState its four bands
"!    produce (priceState). The post's Timestamp - an Edm.DateTime the
"!    OData model hands the untyped Text as a JS Date, which the string
"!    property turns into its toString( ) - goes through the curated
"!    Formatter.DateCreateObject, so the Text receives the same JS Date and
"!    reads exactly as there, in the browser's time zone.
"!  - there is no URL, so a route is a method call rather than a hash. The
"!    post page's Back button walks the history of the routes taken
"!    (myNavBack's history.go(-1)) instead of the browser's, and a deep link
"!    to Post/{postId} has nothing that could carry it.
"!  - the share action runs sap.m.URLHelper.triggerEmail in the browser, as
"!    there, with the same subject and body, and the page URL at startup
"!    where onInit reads window.location.href. The line break (\r\n) the
"!    body puts before that URL is a blank: abap2UI5's URLHELPER action
"!    refuses CR/LF in every parameter, a mail-header injection guard.
"!  - the busy handling has nothing to wait for: the App's busy state until
"!    the OData metadata has loaded, the post page's busy state while its
"!    entity is requested and the worklist table's busyIndicatorDelay that
"!    onInit lowers until the first updateFinished. The App's delay of 0
"!    (appView>/delay) and the post page's static one are kept.
"!  - both views have a page with the id `page`; one view needs unique ids,
"!    so they are `worklistPage` and `postPage`.
"!  - the i18n resource bundle becomes literals.
"!  - the tutorial's OPA5 and QUnit tests have no equivalent: an abap2UI5
"!    app is tested with ABAP Unit against the view it builds (see the
"!    abap2UI5 insight "ABAP Unit for a screen"), and the demo kit's journeys
"!    do not port.
"!
"! Original: src/sap.m/test/sap/m/demokit/tutorial/testing/14 in OpenUI5,
"! archived under ui5/demoapps/sap.m/tutorial/testing.
"! Demo apps: https://sdk.openui5.org/demoapps
CLASS z2ui5_cl_smpc_demo_005 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " Edm.Decimal, Scale 4
    TYPES ty_price TYPE p LENGTH 12 DECIMALS 4.
    " one post as a worklist row shows it
    TYPES:
      BEGIN OF ty_s_row,
        postid      TYPE string,
        title       TYPE string,
        category    TYPE string,
        price_text  TYPE string,
        price_state TYPE string,
        currency    TYPE string,
        flagged     TYPE abap_bool,
      END OF ty_s_row.
    " the post the post page is bound to (Post._onPostMatched's bindElement)
    TYPES:
      BEGIN OF ty_s_post_view,
        title       TYPE string,
        price_text  TYPE string,
        currency    TYPE string,
        timestamp   TYPE string,
        description TYPE string,
      END OF ty_s_post_view.

    DATA t_rows        TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA s_post        TYPE ty_s_post_view.
    " the worklistView model of Worklist.onInit
    DATA table_title   TYPE string.
    DATA share_subject TYPE string.
    DATA share_message TYPE string.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_post,
        postid      TYPE string,
        title       TYPE string,
        category    TYPE string,
        price       TYPE ty_price,
        currency    TYPE string,
        flagged     TYPE abap_bool,
        " Edm.DateTime, the mock's /Date(ms)/ as an ISO date-time in UTC
        timestamp   TYPE string,
        description TYPE string,
      END OF ty_s_post.
    TYPES:
      BEGIN OF ty_s_route,
        name   TYPE string,
        postid TYPE string,
      END OF ty_s_route.

    DATA client       TYPE REF TO z2ui5_if_client.
    DATA t_all        TYPE STANDARD TABLE OF ty_s_post WITH EMPTY KEY.
    " the query of the last search (onFilterPosts)
    DATA search_query TYPE string.
    " the route on show and the ones before it - what the browser history
    " holds there, walked by the Back button
    DATA s_route      TYPE ty_s_route.
    DATA t_history    TYPE STANDARD TABLE OF ty_s_route WITH EMPTY KEY.
    " the page the App shows, re-issued after a rebuilt view
    DATA page_current TYPE string VALUE `worklistPage`.

    METHODS view_display.
    METHODS page_worklist
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_post
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS on_event.
    METHODS route_to
      IMPORTING
        name    TYPE string
        postid  TYPE string    OPTIONAL
        replace TYPE abap_bool DEFAULT abap_false.
    METHODS nav_back.
    METHODS nav_to
      IMPORTING
        page TYPE string.
    METHODS post_bind
      IMPORTING
        postid TYPE string.
    METHODS list_refresh.
    METHODS number_unit
      IMPORTING
        price         TYPE ty_price
      RETURNING
        VALUE(result) TYPE string.
    METHODS price_state
      IMPORTING
        price         TYPE ty_price
      RETURNING
        VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_demo_005 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      model_init( ).
      list_refresh( ).
      route_to( `worklist` ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " App.view.xml, with the two routing targets - Worklist.view.xml and
    " Post.view.xml - as the App's pages. The core:require is the curated
    " formatter module the post's Timestamp goes through
    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock`   v = `true`
            )->a( n = `height`         v = `100%`
            )->a( n = `xmlns`          v = `sap.m`
            )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
            )->a( n = `xmlns:core`     v = `sap.ui.core`
            )->a( n = `xmlns:semantic` v = `sap.m.semantic`
            )->a( n = `xmlns:form`     v = `sap.ui.layout.form`
            )->a( n = `core:require`   v = `{Formatter: 'z2ui5/model/formatter'}` ).

    DATA(app) = view->ele( `Shell`
        )->ele( `App`
            )->a( n = `id`                 v = `app`
            )->a( n = `busyIndicatorDelay` v = `0` ).

    page_worklist( app ).
    page_post( app ).

    client->view_display( view->stringify( ) ).

    " a rebuilt App starts on its first page while the route on show
    " survives as class state - re-issue it
    IF page_current <> `worklistPage`.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `app` ) ( `to` ) ( page_current ) ) ).
    ENDIF.

  ENDMETHOD.


  METHOD page_worklist.

    " Worklist.view.xml
    DATA(page) = parent->ele( n = `FullscreenPage` ns = `semantic`
        )->a( n = `id`    v = `worklistPage`
        )->a( n = `title` v = `Bulletin Board` ).

    " the growing table over /Posts, sorted by Title; the header counts the
    " rows (onUpdateFinished, done in list_refresh)
    DATA(table) = page->ele( n = `content` ns = `semantic`
        )->ele( `Table`
            )->a( n = `id`      v = `table`
            )->a( n = `width`   v = `auto`
            )->a( n = `class`   v = `sapUiResponsiveMargin`
            )->a( n = `growing` b = abap_true
            )->a( n = `items`   v = client->_bind( t_rows ) ).

    " onFilterPosts: the query travels as the event's argument, the field
    " is not bound - as in the original, where nothing binds its value
    table->ele( `headerToolbar`
        )->ele( `Toolbar`

            )->tag( `Label`
                )->a( n = `id`   v = `tableHeader`
                )->a( n = `text` v = client->_bind( table_title )
            )->tag( `ToolbarSpacer`
            )->tag( `SearchField`
                )->a( n = `id`     v = `searchField`
                )->a( n = `width`  v = `auto`
                )->a( n = `search` v = client->_event( val = `SEARCH` arg = `${$parameters>/query}` ) ).

    table->ele( `columns`
        )->ele( `Column`
            )->a( n = `id`     v = `nameColumn`
            )->a( n = `width`  v = `33%`
            )->a( n = `vAlign` v = `Middle`

            )->tag( `Text`
                )->a( n = `id`   v = `nameColumnTitle`
                )->a( n = `text` v = `Name`

        )->end(
        )->ele( `Column`
            )->a( n = `id`     v = `categoryColumn`
            )->a( n = `width`  v = `33%`
            )->a( n = `vAlign` v = `Middle`

            )->tag( `Text`
                )->a( n = `id`   v = `categoryColumnTitle`
                )->a( n = `text` v = `Category`

        )->end(
        )->ele( `Column`
            )->a( n = `id`     v = `unitNumberColumn`
            )->a( n = `width`  v = `33%`
            )->a( n = `hAlign` v = `End`
            )->a( n = `vAlign` v = `Middle`

            )->tag( `Text`
                )->a( n = `id`   v = `unitNumberColumnTitle`
                )->a( n = `text` v = `Price`

        )->end(
        )->tag( `Column`
            )->a( n = `id`          v = `flaggedColumn`
            )->a( n = `width`       v = `80px`
            )->a( n = `demandPopin` b = abap_true
            )->a( n = `vAlign`      v = `Middle` ).

    " onPress: navTo("post") with the pressed row's PostID
    table->ele( `items`
        )->ele( `ColumnListItem`
            )->a( n = `vAlign` v = `Middle`
            )->a( n = `type`   v = `Navigation`
            )->a( n = `press`  v = client->_event( val = `POST` arg = `${POSTID}` )

            )->ele( `cells`

                )->tag( `ObjectIdentifier`
                    )->a( n = `title` v = `{TITLE}`
                )->tag( `Text`
                    )->a( n = `text` v = `{CATEGORY}`
                )->tag( `ObjectNumber`
                    )->a( n = `number` v = `{PRICE_TEXT}`
                    )->a( n = `state`  v = `{PRICE_STATE}`
                    )->a( n = `unit`   v = `{CURRENCY}`
                )->tag( `ToggleButton`
                    )->a( n = `id`      v = `flaggedButton`
                    )->a( n = `tooltip` v = `Mark this post as flagged`
                    )->a( n = `icon`    v = `sap-icon://flag`
                    )->a( n = `pressed` v = `{FLAGGED}`
                    )->a( n = `class`   v = `sapUiMediumMarginBeginEnd` ).

    " onShareEmailPress: URLHelper.triggerEmail(null, subject, message) with
    " the two texts of the worklistView model - in the browser, no round-trip
    DATA(share) = |\{ SUBJECT: $\{{ client->_bind_path( share_subject ) }\}, | &&
                  |BODY: $\{{ client->_bind_path( share_message ) }\} \}|.

    page->ele( n = `sendEmailAction` ns = `semantic`
        )->tag( n = `SendEmailAction` ns = `semantic`
            )->a( n = `id`    v = `shareEmail`
            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-urlhelper
                                                            t_arg = VALUE #( ( `TRIGGER_EMAIL` ) ( share ) ) ) ).

  ENDMETHOD.


  METHOD page_post.

    " Post.view.xml
    DATA(content) = parent->ele( n = `FullscreenPage` ns = `semantic`
        )->a( n = `id`                 v = `postPage`
        )->a( n = `busyIndicatorDelay` v = `0`
        )->a( n = `navButtonPress`     v = client->_event( `BACK` )
        )->a( n = `showNavButton`      b = abap_true
        )->a( n = `title`              v = `Post`

        )->ele( n = `content` ns = `semantic` ).

    content->tag( `ObjectHeader`
        )->a( n = `id`               v = `objectHeader`
        )->a( n = `title`            v = client->_bind( s_post-title )
        )->a( n = `number`           v = client->_bind( s_post-price_text )
        )->a( n = `numberUnit`       v = client->_bind( s_post-currency )
        )->a( n = `backgroundDesign` v = `Translucent` ).

    DATA(tabs) = content->ele( `IconTabBar`
        )->a( n = `id`       v = `iconTabBar`
        )->a( n = `expanded` v = `{= !${device>/system/phone} }`
        )->a( n = `class`    v = `sapUiNoContentPadding`

        )->ele( `items` ).

    " the untyped {Timestamp} of the original shows the JS Date the OData
    " model holds; DateCreateObject hands the Text the same Date
    tabs->ele( `IconTabFilter`
        )->a( n = `icon` v = `sap-icon://hint`
        )->a( n = `key`  v = `info`

        )->ele( n = `SimpleForm` ns = `form`
            )->a( n = `layout` v = `ResponsiveGridLayout`

            )->ele( n = `content` ns = `form`

                )->tag( `Label`
                    )->a( n = `text` v = `Posted At`
                )->tag( `Text`
                    )->a( n = `text` v = |\{ path: '{ client->_bind_path( s_post-timestamp ) }', formatter: 'Formatter.DateCreateObject' \}|
                )->tag( `Label`
                    )->a( n = `text` v = `Description`
                )->tag( `Text`
                    )->a( n = `text` v = client->_bind( s_post-description ) ).

    tabs->ele( `IconTabFilter`
        )->a( n = `icon` v = `sap-icon://inspection`
        )->a( n = `key`  v = `statistics`

        )->tag( `Text`
            )->a( n = `text`  v = `Viewed 55555 times`
            )->a( n = `id`    v = `viewCounter`
            )->a( n = `class` v = `sapUiSmallMargin` ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SEARCH`.
        " onFilterPosts - an empty query removes the filter
        search_query = client->get_event_arg( ).
        list_refresh( ).

      WHEN `POST`.
        route_to( name = `post` postid = client->get_event_arg( ) ).

      WHEN `BACK`.
        " Post.onNavBack
        nav_back( ).

    ENDCASE.

  ENDMETHOD.


  METHOD route_to.

    " router.navTo( ): what was on show goes onto the history the Back
    " button walks - unless the entry is replaced - then the route's target
    " is displayed and its pattern-matched handler runs
    IF s_route-name IS NOT INITIAL AND replace = abap_false.
      INSERT s_route INTO TABLE t_history.
    ENDIF.
    s_route = VALUE #( name = name postid = postid ).

    CASE name.
      WHEN `post`.
        " Post._onPostMatched
        post_bind( postid ).
        nav_to( `postPage` ).
      WHEN OTHERS.
        nav_to( `worklistPage` ).
    ENDCASE.

  ENDMETHOD.


  METHOD nav_back.

    " BaseController.myNavBack("worklist"): back in the history if there is
    " a previous entry, otherwise to the worklist, replacing the entry
    IF t_history IS INITIAL.
      route_to( name = `worklist` replace = abap_true ).
      RETURN.
    ENDIF.

    DATA(previous) = t_history[ lines( t_history ) ].
    DELETE t_history INDEX lines( t_history ).
    s_route = VALUE #( ).
    route_to( name = previous-name postid = previous-postid replace = abap_true ).

  ENDMETHOD.


  METHOD nav_to.

    " the targets' levels decide the direction, as sap.m.routing does: the
    " post (level 2) slides in with to( ), the worklist (level 1) comes
    " back with backToPage( )
    IF page = page_current.
      RETURN.
    ENDIF.
    page_current = page.

    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `app` )
                                               ( COND #( WHEN page = `postPage` THEN `to` ELSE `backToPage` ) )
                                               ( page ) ) ).

  ENDMETHOD.


  METHOD post_bind.

    " bindElement("/Posts('<postId>')") - an unknown id leaves the page empty
    DATA(post) = VALUE ty_s_post( t_all[ postid = postid ] OPTIONAL ).

    s_post = VALUE #( title       = post-title
                      price_text  = COND #( WHEN post-postid IS NOT INITIAL THEN number_unit( post-price ) )
                      currency    = post-currency
                      timestamp   = post-timestamp
                      description = post-description ).

  ENDMETHOD.


  METHOD list_refresh.

    " the flag is bound two-way, so a toggle is already back in the rows -
    " carry it into the posts first, so a row the new filter hides keeps it
    LOOP AT t_all ASSIGNING FIELD-SYMBOL(<post>).
      IF line_exists( t_rows[ postid = <post>-postid ] ).
        <post>-flagged = t_rows[ postid = <post>-postid ]-flagged.
      ENDIF.
    ENDLOOP.

    t_rows = VALUE #( ).
    LOOP AT t_all INTO DATA(post).
      " the Contains filter on Title - the mock server's substringof, which
      " is case-sensitive
      IF search_query IS NOT INITIAL AND find( val = post-title sub = search_query ) < 0.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( postid      = post-postid
                      title       = post-title
                      category    = post-category
                      price_text  = number_unit( post-price )
                      price_state = price_state( post-price )
                      currency    = post-currency
                      flagged     = post-flagged ) INTO TABLE t_rows.
    ENDLOOP.

    " the sorter on Title, ascending - binary, like the mock server's `<`
    SORT t_rows BY title.

    " onUpdateFinished takes the counted title only when the table HAS rows and
    " falls back to the plain worklistTableTitle when it is empty
    table_title = COND #( WHEN t_rows IS INITIAL THEN `Posts` ELSE |Posts ({ lines( t_rows ) })| ).

  ENDMETHOD.


  METHOD number_unit.

    " formatter.numberUnit: parseFloat(sValue).toFixed(2)
    result = |{ price DECIMALS = 2 NUMBER = RAW }|.

  ENDMETHOD.


  METHOD price_state.

    " formatter.priceState: the four price bands
    result = COND #( WHEN price < 50 THEN `Success`
                     WHEN price < 250 THEN `None`
                     WHEN price < 2000 THEN `Warning`
                     ELSE `Error` ).

  ENDMETHOD.


  METHOD model_init.

    " Worklist.onInit: the worklistView model's share texts - the message
    " carries the app's URL (window.location.href)
    DATA(config) = client->get( )-s_config.
    share_subject = `<Email subject PLEASE REPLACE ACCORDING TO YOUR USE CASE>`.
    share_message = |<Email body PLEASE REPLACE ACCORDING TO YOUR USE CASE> | &&
                    |{ config-origin }{ config-pathname }{ config-search }{ config-hash }|.

    " localService/mockdata/Posts.json - the full row set, the OData
    " /Date(ms)/ timestamps converted to the instant they carry
    t_all = VALUE #(
        ( postid = `PostID_1` title = `29'er Mountain Bike (red)` category = `Bicycles`
          price = 81 currency = `USD` flagged = abap_false timestamp = `2015-04-05T08:49:40Z`
          description = `A great mountainbike, barely used and good as new. Pedals and saddle included` )
        ( postid = `PostID_2` title = `Football (rare with signatures)` category = `Sports`
          price = 420 currency = `EUR` flagged = abap_false timestamp = `2015-04-08T14:46:22Z`
          description = `A trophy for collectors, 2014 football with original signatures from the german national soccer team and the spirit of the world cup.` )
        ( postid = `PostID_3` title = `Video Games` category = `Multimedia`
          price = 27 currency = `USD` flagged = abap_false timestamp = `2015-06-03T18:49:53Z`
          description = `A collection of 22 classic video games from 1986 to 1992, old but still a lot of fun` )
        ( postid = `PostID_4` title = `Fluffy Teddy Bear` category = `Toys`
          price = 13 currency = `USD` flagged = abap_true timestamp = `2015-04-24T16:27:57Z`
          description = `This little companion is looking for a new friend, it is brown and has black eyes. One ear is missing.` )
        ( postid = `PostID_5` title = `Car Tires, 22 Inch` category = `Car parts`
          price = 121 currency = `USD` flagged = abap_false timestamp = `2015-02-10T14:46:02Z`
          description = `Spare winter tires for a compact-size car, 4 tires with good profile.` )
        ( postid = `PostID_6` title = `Garage Door with Blue Stripes, 4m x 2,2m` category = `Car parts`
          price = 481 currency = `USD` flagged = abap_true timestamp = `2015-05-14T11:46:11Z`
          description = `Good as new, a garage door for a standard double garage, keeps cars dry and carjackers away.` )
        ( postid = `PostID_7` title = `Kids Toys, a Whole Box of Stuff` category = `Toys`
          price = 63 currency = `USD` flagged = abap_false timestamp = `2015-06-29T18:43:35Z`
          description = `Best suited for kids aged from 4-10, a whole box of toys including model cars, marble balls, toy figures, and much more.` )
        ( postid = `PostID_8` title = `Screwdrivers` category = `Miscellaneous`
          price = 28 currency = `USD` flagged = abap_false timestamp = `2015-08-11T06:08:54Z`
          description = `20-Piece Multibit Ratcheting Screwdriver Set` )
        ( postid = `PostID_9` title = `Comfortable Bike Saddle` category = `Bicycles`
          price = 25 currency = `USD` flagged = abap_false timestamp = `2015-03-17T15:35:23Z`
          description = `A brand-new, unused bike saddle with black covering` )
        ( postid = `PostID_10` title = `Bike Rack` category = `Bicycles`
          price = 106 currency = `USD` flagged = abap_true timestamp = `2015-04-24T10:23:41Z`
          description = `Suitable for camper or RV, used` )
        ( postid = `PostID_11` title = `DVD: Trains of Europe` category = `Multimedia`
          price = 61 currency = `USD` flagged = abap_false timestamp = `2015-03-04T05:14:18Z`
          description = `An amazing collection of train models all around Europe, total runtime 412 minutes.` )
        ( postid = `PostID_12` title = `Matress` category = `Miscellaneous`
          price = 306 currency = `USD` flagged = abap_false timestamp = `2015-06-29T21:18:30Z`
          description = `Bed Mattress 30 x 70 inch, filled with natural fibers, barely used` )
        ( postid = `PostID_13` title = `High-End Gamer PC` category = `Furniture`
          price = 256 currency = `USD` flagged = abap_false timestamp = `2015-07-09T09:47:42Z`
          description = `3Ghz dual core, 16gb RAM, high tower. Great for playing the latest games.` )
        ( postid = `PostID_14` title = `Cooking Pot Set` category = `Miscellaneous`
          price = 234 currency = `USD` flagged = abap_false timestamp = `2015-04-02T01:32:28Z`
          description = `Stainless steel cooking pots (10 pcs) with a matching lid each.` )
        ( postid = `PostID_15` title = `Jeans` category = `Clothing`
          price = 34 currency = `EUR` flagged = abap_false timestamp = `2015-07-19T04:27:48Z`
          description = `Used-look Jeans european size 32x34, only worn once.` )
        ( postid = `PostID_16` title = `Moving Boxes` category = `Miscellaneous`
          price = 60 currency = `USD` flagged = abap_false timestamp = `2015-02-23T01:06:33Z`
          description = `100 Cardboard boxes perfect for relocating, only used once and in a pretty good shape.` )
        ( postid = `PostID_17` title = `Car VW Golf (white)` category = `Car Parts`
          price = 3006 currency = `USD` flagged = abap_false timestamp = `2015-07-15T02:23:39Z`
          description = `Only 160.000 km and in really good shape, grip shift, contact me for appointment and more details.` )
        ( postid = `PostID_18` title = `Swimming Pool` category = `Miscellaneous`
          price = 4587 currency = `USD` flagged = abap_false timestamp = `2015-07-09T00:44:01Z`
          description = `Perfect for your very own pool parties in the garden, measures: 5x10m, fill with ~500.000l water and enjoy.` )
        ( postid = `PostID_19` title = `Travel Suitcases` category = `Miscellaneous`
          price = 560 currency = `USD` flagged = abap_false timestamp = `2015-03-20T07:52:18Z`
          description = `New and in original packaging, a set of 5 high-quality suitcases from small to large sizes.` )
        ( postid = `PostID_20` title = `Rainbow Stickers` category = `Miscellaneous`
          price = 45 currency = `USD` flagged = abap_true timestamp = `2015-05-07T01:22:13Z`
          description = `A vast collection of rainbow stickers for collectors, about 2.000 individual pieces in all shapes and sizes` )
        ( postid = `PostID_21` title = `Notebook` category = `Multimedia`
          price = 23 currency = `USD` flagged = abap_false timestamp = `2015-07-30T20:05:26Z`
          description = `Used notebook with broken display, needs repair. A bargain for the DIY tech guy.` )
        ( postid = `PostID_22` title = `Plasma TV 60"!` category = `Multimedia`
          price = 360 currency = `USD` flagged = abap_false timestamp = `2015-03-04T20:37:48Z`
          description = `I got a larger one, so selling this one cheap for all the movie lovers out there` )
        ( postid = `PostID_23` title = `Cheap Boat` category = `Miscellaneous`
          price = 26263 currency = `USD` flagged = abap_false timestamp = `2015-08-14T14:08:33Z`
          description = `Living close to a lake or the ocean? This dream of a yacht (30ft long!) comes with lots of extras. Get it and fulfill yourself a dream.` )
    ).

  ENDMETHOD.

ENDCLASS.
