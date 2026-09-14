" @keywords bulletin board app table toolbar label toolbarspacer searchfield column text columnlistitem objectidentifier
" @summary Worklist app created with the 'Testing' tutorial. - the UI5 demo app "Bulletin Board", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Bulletin Board (sap.m/tutorial/testing) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Bulletin Board</p>
"!
"! The UI5 demo app Bulletin Board - the app the demo kit's "Testing"
"! tutorial builds - rebuilt as ONE abap2UI5 class: the worklist of posts
"! with its search, its price states and the flag toggle, and the post page
"! with the two tabs the tutorial ends on.
"!
"! Where it differs from the original, and why:
"!
"!  - the OData V2 service and its mock server become ABAP data - the 23
"!    posts of the mock, verbatim.
"!  - the formatter module is business logic and moves to the backend: the
"!    two-decimal price and the ValueState its four bands produce.
"!  - search runs in ABAP, where the posts are; the flag is an ordinary
"!    two-way bound row field rather than a custom `flagged` model type.
"!  - the two views are two pages of one NavContainer instead of two routing
"!    targets, so a post opens with one round-trip and no view rebuild.
"!  - the share menu opens a mailto: URL from the client, which is what
"!    sap.m.URLHelper does one layer down. Not verified in a running system.
"!  - the i18n resource bundle becomes literals, and the busy handling has
"!    nothing to do here.
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

    DATA t_rows       TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA table_title  TYPE string.
    DATA search_term  TYPE string.
    DATA post_title   TYPE string.
    DATA post_price   TYPE string.
    DATA post_currency TYPE string.
    DATA post_date    TYPE string.
    DATA post_text    TYPE string.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_post,
        postid      TYPE string,
        title       TYPE string,
        category    TYPE string,
        price       TYPE i,
        currency    TYPE string,
        flagged     TYPE abap_bool,
        timestamp   TYPE string,
        description TYPE string,
      END OF ty_s_post.

    DATA client TYPE REF TO z2ui5_if_client.
    DATA t_all  TYPE STANDARD TABLE OF ty_s_post WITH EMPTY KEY.

    METHODS view_display.
    METHODS on_event.
    METHODS post_show
      IMPORTING
        postid TYPE string.
    METHODS list_refresh.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_demo_005 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      model_init( ).
      list_refresh( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock`   v = `true`
            )->a( n = `height`         v = `100%`
            )->a( n = `xmlns`          v = `sap.m`
            )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
            )->a( n = `xmlns:semantic` v = `sap.m.semantic`
            )->a( n = `xmlns:form`     v = `sap.ui.layout.form` ).

    DATA(nav) = view->ele( `NavContainer`
        )->a( n = `id` v = `nav` ).

    " ---------------------------------------------------------- worklist
    DATA(worklist) = nav->ele( n = `FullscreenPage` ns = `semantic`
        )->a( n = `id`    v = `page-worklist`
        )->a( n = `title` v = `Bulletin Board` ).

    DATA(table) = worklist->ele( n = `content` ns = `semantic`
        )->ele( `Table`
            )->a( n = `id`      v = `table`
            )->a( n = `width`   v = `auto`
            )->a( n = `class`   v = `sapUiResponsiveMargin`
            )->a( n = `growing` b = abap_true
            )->a( n = `items`   v = client->_bind( t_rows ) ).

    table->ele( `headerToolbar`
        )->ele( `Toolbar`
            )->tag( `Label`
                )->a( n = `id`   v = `tableHeader`
                )->a( n = `text` v = client->_bind( table_title )
            )->tag( `ToolbarSpacer`
            )->tag( `SearchField`
                )->a( n = `id`     v = `searchField`
                )->a( n = `width`  v = `auto`
                )->a( n = `value`  v = client->_bind( search_term )
                )->a( n = `search` v = client->_event( `SEARCH` ) ).

    table->ele( `columns`
        )->ele( `Column`
            )->a( n = `id`    v = `nameColumn`
            )->a( n = `width` v = `33%`
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

    worklist->ele( n = `sendEmailAction` ns = `semantic`
        )->tag( n = `SendEmailAction` ns = `semantic`
            )->a( n = `id`    v = `shareEmail`
            )->a( n = `press` v = client->_event( `SHARE_EMAIL` ) ).

    " -------------------------------------------------------------- post
    DATA(post) = nav->ele( n = `FullscreenPage` ns = `semantic`
        )->a( n = `id`             v = `page-post`
        )->a( n = `title`          v = `Post`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `BACK` ) ).

    DATA(content) = post->ele( n = `content` ns = `semantic` ).

    content->tag( `ObjectHeader`
        )->a( n = `id`               v = `objectHeader`
        )->a( n = `title`            v = client->_bind( post_title )
        )->a( n = `number`           v = client->_bind( post_price )
        )->a( n = `numberUnit`       v = client->_bind( post_currency )
        )->a( n = `backgroundDesign` v = `Translucent` ).

    DATA(tabs) = content->ele( `IconTabBar`
        )->a( n = `id`       v = `iconTabBar`
        )->a( n = `expanded` b = abap_true
        )->a( n = `class`    v = `sapUiNoContentPadding`

        )->ele( `items` ).

    tabs->ele( `IconTabFilter`
        )->a( n = `icon` v = `sap-icon://hint`
        )->a( n = `key`  v = `info`

        )->ele( n = `SimpleForm` ns = `form`
            )->a( n = `layout` v = `ResponsiveGridLayout`

            )->ele( n = `content` ns = `form`
                )->tag( `Label`
                    )->a( n = `text` v = `Posted At`
                )->tag( `Text`
                    )->a( n = `text` v = client->_bind( post_date )
                )->tag( `Label`
                    )->a( n = `text` v = `Description`
                )->tag( `Text`
                    )->a( n = `text` v = client->_bind( post_text ) ).

    tabs->ele( `IconTabFilter`
        )->a( n = `icon` v = `sap-icon://inspection`
        )->a( n = `key`  v = `statistics`

        )->tag( `Text`
            )->a( n = `id`    v = `viewCounter`
            )->a( n = `text`  v = `Viewed 55555 times`
            )->a( n = `class` v = `sapUiSmallMargin` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SEARCH`.
        list_refresh( ).

      WHEN `POST`.
        post_show( client->get_event_arg( ) ).

      WHEN `BACK`.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `nav` ) ( `to` ) ( `page-worklist` ) ) ).

      WHEN `SHARE_EMAIL`.
        client->follow_up_action( val   = client->cs_event-open_new_tab
                                  t_arg = VALUE #( ( `mailto:?subject=Bulletin%20Board` ) ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD post_show.

    ASSIGN t_all[ postid = postid ] TO FIELD-SYMBOL(<post>).
    IF <post> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    post_title    = <post>-title.
    post_price    = |{ <post>-price }.00|.
    post_currency = <post>-currency.
    post_date     = <post>-timestamp.
    post_text     = <post>-description.

    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `nav` ) ( `to` ) ( `page-post` ) ) ).

  ENDMETHOD.


  METHOD list_refresh.

    " the flag is bound two-way, so a toggle is already back in the rows -
    " carry it over into the rebuilt list
    DATA(flags) = t_rows.
    t_rows = VALUE #( ).

    LOOP AT t_all INTO DATA(post).
      IF search_term IS NOT INITIAL AND to_upper( post-title ) NS to_upper( search_term ).
        CONTINUE.
      ENDIF.
      INSERT VALUE #( postid      = post-postid
                      title       = post-title
                      category    = post-category
                      price_text  = |{ post-price }.00|
                      " the priceState formatter's four bands
                      price_state = COND #( WHEN post-price < 50 THEN `Success`
                                            WHEN post-price < 250 THEN `None`
                                            WHEN post-price < 2000 THEN `Warning`
                                            ELSE `Error` )
                      currency    = post-currency
                      flagged     = COND #( WHEN line_exists( flags[ postid = post-postid ] )
                                            THEN flags[ postid = post-postid ]-flagged
                                            ELSE post-flagged ) ) INTO TABLE t_rows.
    ENDLOOP.

    SORT t_rows BY title AS TEXT.

    " onUpdateFinished takes the counted title only when the table HAS rows and
    " falls back to the plain worklistTableTitle when it is empty
    table_title = COND #( WHEN t_rows IS INITIAL THEN `Posts` ELSE |Posts ({ lines( t_rows ) })| ).

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Posts.json - the full row set, the OData
    " /Date(ms)/ timestamps converted to the date they carry
    t_all = VALUE #(
        ( postid = `PostID_1` title = `29'er Mountain Bike (red)` category = `Bicycles`
          price = 81 currency = `USD` flagged = abap_false timestamp = `2015-04-05`
          description = `A great mountainbike, barely used and good as new. Pedals and saddle included` )
        ( postid = `PostID_2` title = `Football (rare with signatures)` category = `Sports`
          price = 420 currency = `EUR` flagged = abap_false timestamp = `2015-04-08`
          description = `A trophy for collectors, 2014 football with original signatures from the german national soccer team and the spirit of the world cup.` )
        ( postid = `PostID_3` title = `Video Games` category = `Multimedia`
          price = 27 currency = `USD` flagged = abap_false timestamp = `2015-06-03`
          description = `A collection of 22 classic video games from 1986 to 1992, old but still a lot of fun` )
        ( postid = `PostID_4` title = `Fluffy Teddy Bear` category = `Toys`
          price = 13 currency = `USD` flagged = abap_true timestamp = `2015-04-24`
          description = `This little companion is looking for a new friend, it is brown and has black eyes. One ear is missing.` )
        ( postid = `PostID_5` title = `Car Tires, 22 Inch` category = `Car parts`
          price = 121 currency = `USD` flagged = abap_false timestamp = `2015-02-10`
          description = `Spare winter tires for a compact-size car, 4 tires with good profile.` )
        ( postid = `PostID_6` title = `Garage Door with Blue Stripes, 4m x 2,2m` category = `Car parts`
          price = 481 currency = `USD` flagged = abap_true timestamp = `2015-05-14`
          description = `Good as new, a garage door for a standard double garage, keeps cars dry and carjackers away.` )
        ( postid = `PostID_7` title = `Kids Toys, a Whole Box of Stuff` category = `Toys`
          price = 63 currency = `USD` flagged = abap_false timestamp = `2015-06-29`
          description = `Best suited for kids aged from 4-10, a whole box of toys including model cars, marble balls, toy figures, and much more.` )
        ( postid = `PostID_8` title = `Screwdrivers` category = `Miscellaneous`
          price = 28 currency = `USD` flagged = abap_false timestamp = `2015-08-11`
          description = `20-Piece Multibit Ratcheting Screwdriver Set` )
        ( postid = `PostID_9` title = `Comfortable Bike Saddle` category = `Bicycles`
          price = 25 currency = `USD` flagged = abap_false timestamp = `2015-03-17`
          description = `A brand-new, unused bike saddle with black covering` )
        ( postid = `PostID_10` title = `Bike Rack` category = `Bicycles`
          price = 106 currency = `USD` flagged = abap_true timestamp = `2015-04-24`
          description = `Suitable for camper or RV, used` )
        ( postid = `PostID_11` title = `DVD: Trains of Europe` category = `Multimedia`
          price = 61 currency = `USD` flagged = abap_false timestamp = `2015-03-04`
          description = `An amazing collection of train models all around Europe, total runtime 412 minutes.` )
        ( postid = `PostID_12` title = `Matress` category = `Miscellaneous`
          price = 306 currency = `USD` flagged = abap_false timestamp = `2015-06-29`
          description = `Bed Mattress 30 x 70 inch, filled with natural fibers, barely used` )
        ( postid = `PostID_13` title = `High-End Gamer PC` category = `Furniture`
          price = 256 currency = `USD` flagged = abap_false timestamp = `2015-07-09`
          description = `3Ghz dual core, 16gb RAM, high tower. Great for playing the latest games.` )
        ( postid = `PostID_14` title = `Cooking Pot Set` category = `Miscellaneous`
          price = 234 currency = `USD` flagged = abap_false timestamp = `2015-04-02`
          description = `Stainless steel cooking pots (10 pcs) with a matching lid each.` )
        ( postid = `PostID_15` title = `Jeans` category = `Clothing`
          price = 34 currency = `EUR` flagged = abap_false timestamp = `2015-07-19`
          description = `Used-look Jeans european size 32x34, only worn once.` )
        ( postid = `PostID_16` title = `Moving Boxes` category = `Miscellaneous`
          price = 60 currency = `USD` flagged = abap_false timestamp = `2015-02-23`
          description = `100 Cardboard boxes perfect for relocating, only used once and in a pretty good shape.` )
        ( postid = `PostID_17` title = `Car VW Golf (white)` category = `Car Parts`
          price = 3006 currency = `USD` flagged = abap_false timestamp = `2015-07-15`
          description = `Only 160.000 km and in really good shape, grip shift, contact me for appointment and more details.` )
        ( postid = `PostID_18` title = `Swimming Pool` category = `Miscellaneous`
          price = 4587 currency = `USD` flagged = abap_false timestamp = `2015-07-09`
          description = `Perfect for your very own pool parties in the garden, measures: 5x10m, fill with ~500.000l water and enjoy.` )
        ( postid = `PostID_19` title = `Travel Suitcases` category = `Miscellaneous`
          price = 560 currency = `USD` flagged = abap_false timestamp = `2015-03-20`
          description = `New and in original packaging, a set of 5 high-quality suitcases from small to large sizes.` )
        ( postid = `PostID_20` title = `Rainbow Stickers` category = `Miscellaneous`
          price = 45 currency = `USD` flagged = abap_true timestamp = `2015-05-07`
          description = `A vast collection of rainbow stickers for collectors, about 2.000 individual pieces in all shapes and sizes` )
        ( postid = `PostID_21` title = `Notebook` category = `Multimedia`
          price = 23 currency = `USD` flagged = abap_false timestamp = `2015-07-30`
          description = `Used notebook with broken display, needs repair. A bargain for the DIY tech guy.` )
        ( postid = `PostID_22` title = `Plasma TV 60"!` category = `Multimedia`
          price = 360 currency = `USD` flagged = abap_false timestamp = `2015-03-04`
          description = `I got a larger one, so selling this one cheap for all the movie lovers out there` )
        ( postid = `PostID_23` title = `Cheap Boat` category = `Miscellaneous`
          price = 26263 currency = `USD` flagged = abap_false timestamp = `2015-08-14`
          description = `Living close to a lake or the ocean? This dream of a yacht (30ft long!) comes with lots of extras. Get it and fulfill yourself a dream.` )
    ).

  ENDMETHOD.

ENDCLASS.
