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

    DATA t_rows       TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
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
    DATA t_all  TYPE STANDARD TABLE OF ty_s_post WITH DEFAULT KEY.

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

    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      list_refresh( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA nav TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA worklist TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA post TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA tabs TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock`   v = `true`
            )->a( n = `height`         v = `100%`
            )->a( n = `xmlns`          v = `sap.m`
            )->a( n = `xmlns:mvc`      v = `sap.ui.core.mvc`
            )->a( n = `xmlns:semantic` v = `sap.m.semantic`
            )->a( n = `xmlns:form`     v = `sap.ui.layout.form` ).

    
    nav = view->ele( `NavContainer`
        )->a( n = `id` v = `nav` ).

    " ---------------------------------------------------------- worklist
    
    worklist = nav->ele( n = `FullscreenPage` ns = `semantic`
        )->a( n = `id`    v = `page-worklist`
        )->a( n = `title` v = `Bulletin Board` ).

    
    table = worklist->ele( n = `content` ns = `semantic`
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
    
    post = nav->ele( n = `FullscreenPage` ns = `semantic`
        )->a( n = `id`             v = `page-post`
        )->a( n = `title`          v = `Post`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `BACK` ) ).

    
    content = post->ele( n = `content` ns = `semantic` ).

    content->tag( `ObjectHeader`
        )->a( n = `id`               v = `objectHeader`
        )->a( n = `title`            v = client->_bind( post_title )
        )->a( n = `number`           v = client->_bind( post_price )
        )->a( n = `numberUnit`       v = client->_bind( post_currency )
        )->a( n = `backgroundDesign` v = `Translucent` ).

    
    tabs = content->ele( `IconTabBar`
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
        DATA temp1 TYPE string_table.
        DATA temp3 TYPE string_table.

    CASE client->get_event( ).

      WHEN `SEARCH`.
        list_refresh( ).

      WHEN `POST`.
        post_show( client->get_event_arg( ) ).

      WHEN `BACK`.
        
        CLEAR temp1.
        INSERT `nav` INTO TABLE temp1.
        INSERT `to` INTO TABLE temp1.
        INSERT `page-worklist` INTO TABLE temp1.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp1 ).

      WHEN `SHARE_EMAIL`.
        
        CLEAR temp3.
        INSERT `mailto:?subject=Bulletin%20Board` INTO TABLE temp3.
        client->follow_up_action( val   = client->cs_event-open_new_tab
                                  t_arg = temp3 ).

    ENDCASE.

  ENDMETHOD.


  METHOD post_show.

    FIELD-SYMBOLS <post> TYPE z2ui5_cl_smpc_demo_005=>ty_s_post.
    DATA temp5 TYPE string_table.
    READ TABLE t_all WITH KEY postid = postid ASSIGNING <post>.
    IF <post> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    post_title    = <post>-title.
    post_price    = |{ <post>-price }.00|.
    post_currency = <post>-currency.
    post_date     = <post>-timestamp.
    post_text     = <post>-description.

    
    CLEAR temp5.
    INSERT `nav` INTO TABLE temp5.
    INSERT `to` INTO TABLE temp5.
    INSERT `page-post` INTO TABLE temp5.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp5 ).

  ENDMETHOD.


  METHOD list_refresh.

    " the flag is bound two-way, so a toggle is already back in the rows -
    " carry it over into the rebuilt list
    DATA flags LIKE t_rows.
    DATA temp7 LIKE t_rows.
    DATA post LIKE LINE OF t_all.
      DATA temp8 TYPE z2ui5_cl_smpc_demo_005=>ty_s_row.
      DATA temp1 TYPE z2ui5_cl_smpc_demo_005=>ty_s_row-price_state.
      DATA temp2 TYPE abap_bool.
      DATA temp3 LIKE sy-subrc.
        FIELD-SYMBOLS <temp4> LIKE LINE OF flags.
        DATA temp5 LIKE sy-tabix.
    DATA temp9 TYPE string.
    flags = t_rows.
    
    CLEAR temp7.
    t_rows = temp7.

    
    LOOP AT t_all INTO post.
      IF search_term IS NOT INITIAL AND to_upper( post-title ) NS to_upper( search_term ).
        CONTINUE.
      ENDIF.
      
      CLEAR temp8.
      temp8-postid = post-postid.
      temp8-title = post-title.
      temp8-category = post-category.
      temp8-price_text = |{ post-price }.00|.
      
      IF post-price < 50.
        temp1 = `Success`.
      ELSEIF post-price < 250.
        temp1 = `None`.
      ELSEIF post-price < 2000.
        temp1 = `Warning`.
      ELSE.
        temp1 = `Error`.
      ENDIF.
      temp8-price_state = temp1.
      temp8-currency = post-currency.
      
      
      READ TABLE flags WITH KEY postid = post-postid TRANSPORTING NO FIELDS.
      temp3 = sy-subrc.
      IF temp3 = 0.
        
        
        temp5 = sy-tabix.
        READ TABLE flags WITH KEY postid = post-postid ASSIGNING <temp4>.
        sy-tabix = temp5.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        temp2 = <temp4>-flagged.
      ELSE.
        temp2 = post-flagged.
      ENDIF.
      temp8-flagged = temp2.
      INSERT temp8 INTO TABLE t_rows.
    ENDLOOP.

    SORT t_rows BY title AS TEXT.

    " onUpdateFinished takes the counted title only when the table HAS rows and
    " falls back to the plain worklistTableTitle when it is empty
    
    IF t_rows IS INITIAL.
      temp9 = `Posts`.
    ELSE.
      temp9 = |Posts ({ lines( t_rows ) })|.
    ENDIF.
    table_title = temp9.

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/Posts.json - the full row set, the OData
    " /Date(ms)/ timestamps converted to the date they carry
    DATA temp10 LIKE t_all.
    DATA temp11 LIKE LINE OF temp10.
    CLEAR temp10.
    
    temp11-postid = `PostID_1`.
    temp11-title = `29'er Mountain Bike (red)`.
    temp11-category = `Bicycles`.
    temp11-price = 81.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-04-05`.
    temp11-description = `A great mountainbike, barely used and good as new. Pedals and saddle included`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_2`.
    temp11-title = `Football (rare with signatures)`.
    temp11-category = `Sports`.
    temp11-price = 420.
    temp11-currency = `EUR`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-04-08`.
    temp11-description = `A trophy for collectors, 2014 football with original signatures from the german national soccer team and the spirit of the world cup.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_3`.
    temp11-title = `Video Games`.
    temp11-category = `Multimedia`.
    temp11-price = 27.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-06-03`.
    temp11-description = `A collection of 22 classic video games from 1986 to 1992, old but still a lot of fun`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_4`.
    temp11-title = `Fluffy Teddy Bear`.
    temp11-category = `Toys`.
    temp11-price = 13.
    temp11-currency = `USD`.
    temp11-flagged = abap_true.
    temp11-timestamp = `2015-04-24`.
    temp11-description = `This little companion is looking for a new friend, it is brown and has black eyes. One ear is missing.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_5`.
    temp11-title = `Car Tires, 22 Inch`.
    temp11-category = `Car parts`.
    temp11-price = 121.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-02-10`.
    temp11-description = `Spare winter tires for a compact-size car, 4 tires with good profile.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_6`.
    temp11-title = `Garage Door with Blue Stripes, 4m x 2,2m`.
    temp11-category = `Car parts`.
    temp11-price = 481.
    temp11-currency = `USD`.
    temp11-flagged = abap_true.
    temp11-timestamp = `2015-05-14`.
    temp11-description = `Good as new, a garage door for a standard double garage, keeps cars dry and carjackers away.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_7`.
    temp11-title = `Kids Toys, a Whole Box of Stuff`.
    temp11-category = `Toys`.
    temp11-price = 63.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-06-29`.
    temp11-description = `Best suited for kids aged from 4-10, a whole box of toys including model cars, marble balls, toy figures, and much more.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_8`.
    temp11-title = `Screwdrivers`.
    temp11-category = `Miscellaneous`.
    temp11-price = 28.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-08-11`.
    temp11-description = `20-Piece Multibit Ratcheting Screwdriver Set`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_9`.
    temp11-title = `Comfortable Bike Saddle`.
    temp11-category = `Bicycles`.
    temp11-price = 25.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-03-17`.
    temp11-description = `A brand-new, unused bike saddle with black covering`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_10`.
    temp11-title = `Bike Rack`.
    temp11-category = `Bicycles`.
    temp11-price = 106.
    temp11-currency = `USD`.
    temp11-flagged = abap_true.
    temp11-timestamp = `2015-04-24`.
    temp11-description = `Suitable for camper or RV, used`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_11`.
    temp11-title = `DVD: Trains of Europe`.
    temp11-category = `Multimedia`.
    temp11-price = 61.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-03-04`.
    temp11-description = `An amazing collection of train models all around Europe, total runtime 412 minutes.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_12`.
    temp11-title = `Matress`.
    temp11-category = `Miscellaneous`.
    temp11-price = 306.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-06-29`.
    temp11-description = `Bed Mattress 30 x 70 inch, filled with natural fibers, barely used`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_13`.
    temp11-title = `High-End Gamer PC`.
    temp11-category = `Furniture`.
    temp11-price = 256.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-07-09`.
    temp11-description = `3Ghz dual core, 16gb RAM, high tower. Great for playing the latest games.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_14`.
    temp11-title = `Cooking Pot Set`.
    temp11-category = `Miscellaneous`.
    temp11-price = 234.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-04-02`.
    temp11-description = `Stainless steel cooking pots (10 pcs) with a matching lid each.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_15`.
    temp11-title = `Jeans`.
    temp11-category = `Clothing`.
    temp11-price = 34.
    temp11-currency = `EUR`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-07-19`.
    temp11-description = `Used-look Jeans european size 32x34, only worn once.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_16`.
    temp11-title = `Moving Boxes`.
    temp11-category = `Miscellaneous`.
    temp11-price = 60.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-02-23`.
    temp11-description = `100 Cardboard boxes perfect for relocating, only used once and in a pretty good shape.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_17`.
    temp11-title = `Car VW Golf (white)`.
    temp11-category = `Car Parts`.
    temp11-price = 3006.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-07-15`.
    temp11-description = `Only 160.000 km and in really good shape, grip shift, contact me for appointment and more details.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_18`.
    temp11-title = `Swimming Pool`.
    temp11-category = `Miscellaneous`.
    temp11-price = 4587.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-07-09`.
    temp11-description = `Perfect for your very own pool parties in the garden, measures: 5x10m, fill with ~500.000l water and enjoy.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_19`.
    temp11-title = `Travel Suitcases`.
    temp11-category = `Miscellaneous`.
    temp11-price = 560.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-03-20`.
    temp11-description = `New and in original packaging, a set of 5 high-quality suitcases from small to large sizes.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_20`.
    temp11-title = `Rainbow Stickers`.
    temp11-category = `Miscellaneous`.
    temp11-price = 45.
    temp11-currency = `USD`.
    temp11-flagged = abap_true.
    temp11-timestamp = `2015-05-07`.
    temp11-description = `A vast collection of rainbow stickers for collectors, about 2.000 individual pieces in all shapes and sizes`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_21`.
    temp11-title = `Notebook`.
    temp11-category = `Multimedia`.
    temp11-price = 23.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-07-30`.
    temp11-description = `Used notebook with broken display, needs repair. A bargain for the DIY tech guy.`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_22`.
    temp11-title = `Plasma TV 60"!`.
    temp11-category = `Multimedia`.
    temp11-price = 360.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-03-04`.
    temp11-description = `I got a larger one, so selling this one cheap for all the movie lovers out there`.
    INSERT temp11 INTO TABLE temp10.
    temp11-postid = `PostID_23`.
    temp11-title = `Cheap Boat`.
    temp11-category = `Miscellaneous`.
    temp11-price = 26263.
    temp11-currency = `USD`.
    temp11-flagged = abap_false.
    temp11-timestamp = `2015-08-14`.
    temp11-description = `Living close to a lake or the ocean? This dream of a yacht (30ft long!) comes with lots of extras. Get it and fulfill yourself a dream.`.
    INSERT temp11 INTO TABLE temp10.
    t_all = temp10.

  ENDMETHOD.

ENDCLASS.
