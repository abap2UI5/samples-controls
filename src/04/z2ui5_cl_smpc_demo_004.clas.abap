" @keywords shopping cart app flexiblecolumnlayout navcontainer toolbar searchfield objectlistitem objectattribute objectstatus standardlistitem bar
" @summary The classic business process of finding and ordering products. - the UI5 demo app "Shopping Cart", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Shopping Cart (sap.m/cart) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Shopping Cart</p>
"!
"! The UI5 demo app Shopping Cart - the demo kit's showcase application -
"! rebuilt as ONE abap2UI5 class: the category list with its search, the
"! product list per category, the product page, the cart with its
"! save-for-later, and the checkout wizard with payment branch, addresses,
"! delivery type and the order summary. The three columns of the original's
"! FlexibleColumnLayout are the three columns here, each holding a
"! NavContainer, so a page switch inside a column costs no round-trip.
"!
"! Where it differs from the original, and why:
"!
"!  - the OData V2 service and its mock server become ABAP data: the 123
"!    products, the 16 categories and the 13 featured products of the demo
"!    kit mock, verbatim.
"!  - the cart and the saved-for-later list stay in the BROWSER's local
"!    storage, exactly as the original's LocalStorageModel keeps them, under
"!    the same key (SHOPPING_CART). abap2UI5 ships both halves: the
"!    STORE_DATA frontend action writes, and the invisible z2ui5.cc.Storage
"!    control reads the key back and reports it through its `finished` event,
"!    where z2ui5_cl_ui5_json parses it into the bound tables. So a closed
"!    browser loses nothing here either - and the backend still sees the
"!    cart on every round-trip, which is where a price, a reservation or an
"!    order would be decided.
"!  - the formatter module is business logic and moves to the backend: the
"!    price format, the status text and its ValueState, the cart total.
"!  - search and category filtering run in ABAP, where the data is.
"!  - the Welcome page keeps its three panels (promoted, recently viewed,
"!    favorites) but not the original's BlockLayout-and-Grid arrangement of
"!    them: one list per panel instead of a hand-built cell per product.
"!    Its carousel is dropped with the four teaser images it shows. The
"!    Emphasized cart-3 button the original puts on every tile stays, as an
"!    ACTIVE ObjectAttribute on the row - an ObjectListItem takes no button,
"!    and without it the welcome page had no way to fill the cart at all.
"!  - the wizard validates in ABAP rather than through the Wizard's own
"!    validated/setNextStep API, and reports with a MessageBox - which is
"!    what the original's own validation does for the credit-card step.
"!  - the i18n resource bundle becomes literals, the device model's
"!    smallScreenMode branches are gone (the FCL does that itself now), and
"!    the LightBox on the product picture is dropped.
"!  - the product comparison view is not rebuilt: it is a desktop-only extra
"!    reachable from one ObjectAttribute, and it needs a two-product
"!    side-by-side layout that says nothing new about the framework. Named
"!    here rather than left to be noticed.
"!
"! Original: src/sap.m/test/sap/m/demokit/cart in OpenUI5, archived under
"! ui5/demoapps/sap.m/cart.
"! Demo apps: https://sdk.openui5.org/demoapps
CLASS z2ui5_cl_smpc_demo_004 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_category,
        category         TYPE string,
        categoryname     TYPE string,
        numberofproducts TYPE i,
      END OF ty_s_category.
    TYPES:
      BEGIN OF ty_s_row,
        productid    TYPE string,
        name         TYPE string,
        suppliername TYPE string,
        price_text   TYPE string,
        currencycode TYPE string,
        pictureurl   TYPE string,
        status_text  TYPE string,
        status_state TYPE string,
      END OF ty_s_row.
    TYPES:
      BEGIN OF ty_s_entry,
        productid    TYPE string,
        name         TYPE string,
        pictureurl   TYPE string,
        price_text   TYPE string,
        currencycode TYPE string,
        quantity     TYPE i,
      END OF ty_s_entry.

    DATA t_categories   TYPE STANDARD TABLE OF ty_s_category WITH EMPTY KEY.
    DATA t_search       TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA t_category     TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA t_promoted     TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA t_viewed       TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA t_favorite     TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_store,
        cart  TYPE STANDARD TABLE OF ty_s_entry WITH EMPTY KEY,
        saved TYPE STANDARD TABLE OF ty_s_entry WITH EMPTY KEY,
      END OF ty_s_store.
    TYPES:
      BEGIN OF ty_s_storage,
        type   TYPE string,
        prefix TYPE string,
        key    TYPE string,
        value  TYPE ty_s_store,
      END OF ty_s_storage.

    DATA t_cart         TYPE STANDARD TABLE OF ty_s_entry WITH EMPTY KEY.
    DATA t_saved        TYPE STANDARD TABLE OF ty_s_entry WITH EMPTY KEY.
    " what the original's LocalStorageModel is: the cart under its own key in
    " the browser's local storage. The whole structure is what STORE_DATA
    " writes, and `value` is what the z2ui5.cc.Storage control reads back
    DATA s_storage      TYPE ty_s_storage.
    DATA layout         TYPE string.
    DATA search_term    TYPE string.
    DATA search_visible TYPE abap_bool.
    DATA category_name  TYPE string.
    DATA cart_total     TYPE string.
    DATA cart_open      TYPE abap_bool.
    DATA prod_name      TYPE string.
    DATA prod_supplier  TYPE string.
    DATA prod_desc      TYPE string.
    DATA prod_price     TYPE string.
    DATA prod_currency  TYPE string.
    DATA prod_picture   TYPE string.
    DATA prod_status    TYPE string.
    " enum-typed: an empty value is rejected outright (validateProperty), so
    " the product page carries the UI5 default until a product is opened
    DATA prod_state     TYPE string VALUE `None`.
    DATA prod_weight    TYPE string.
    DATA prod_measures  TYPE string.
    " the checkout wizard's own fields - one flat set, as the original's
    " one JSON model holds them
    DATA pay_type       TYPE string.
    DATA cc_name        TYPE string.
    DATA cc_number      TYPE string.
    DATA cc_code        TYPE string.
    DATA cc_expire      TYPE string.
    DATA cod_firstname  TYPE string.
    DATA cod_lastname   TYPE string.
    DATA cod_phone      TYPE string.
    DATA cod_email      TYPE string.
    DATA inv_address    TYPE string.
    DATA inv_city       TYPE string.
    DATA inv_zip        TYPE string.
    DATA inv_country    TYPE string.
    DATA inv_note       TYPE string.
    DATA del_different  TYPE abap_bool.
    DATA del_address    TYPE string.
    DATA del_city       TYPE string.
    DATA del_zip        TYPE string.
    DATA del_country    TYPE string.
    DATA del_note       TYPE string.
    DATA del_type       TYPE string.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_product,
        productid        TYPE string,
        name             TYPE string,
        category         TYPE string,
        suppliername     TYPE string,
        shortdescription TYPE string,
        pictureurl       TYPE string,
        price            TYPE string,
        currencycode     TYPE string,
        status           TYPE string,
        weight           TYPE string,
        weightunit       TYPE string,
        dimensionwidth   TYPE string,
        dimensiondepth   TYPE string,
        dimensionheight  TYPE string,
        dimensionunit    TYPE string,
      END OF ty_s_product.
    TYPES ty_amount TYPE p LENGTH 13 DECIMALS 2.
    TYPES:
      BEGIN OF ty_s_featured,
        productid TYPE string,
        type      TYPE string,
      END OF ty_s_featured.

    " What the original's pictureUrl formatter resolves a mock path against.
    "
    " The mock rows carry the original's own spelling, `sap/ui/demo/mock/
    " images/HT-1000.jpg` (data_fidelity compares them against Products.json,
    " so they stay verbatim), and the original resolves it with
    " `sap.ui.require.toUrl( )` against a resource root the app DECLARES:
    " test/testsuite.qunit.js maps `sap/ui/demo/mock` to
    " `./../localService/mockdata`, and its formatter unit test asserts
    " exactly that. So the images are files of the demo app, not assets of
    " the UI5 runtime - `/resources/sap/ui/demo/mock/...`, which is what this
    " constant used to say, is a 404 and left every product without a
    " picture.
    "
    " A port has no app folder to serve them from, so the prefix is replaced
    " with the demo kit's deployed copy of that folder - the same
    " sdk.openui5.org/test-resources host the src/03 collection already uses
    " for sample images.
    CONSTANTS c_mock_prefix TYPE string VALUE `sap/ui/demo/mock/`.
    CONSTANTS c_base        TYPE string
      VALUE `https://sdk.openui5.org/test-resources/sap/m/demokit/cart/webapp/localService/mockdata/`.

    DATA client        TYPE REF TO z2ui5_if_client.
    " the product on show: the key ADD_TO_CART needs, never bound - so
    " PROTECTED, where the round-trip still carries it
    DATA prod_id       TYPE string.
    DATA t_all         TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_featured    TYPE STANDARD TABLE OF ty_s_featured WITH EMPTY KEY.
    DATA page_begin    TYPE string VALUE `page-home`.
    DATA page_mid      TYPE string VALUE `page-welcome`.
    DATA page_end      TYPE string VALUE `page-cart`.

    METHODS view_display.
    METHODS page_home
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_category
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_welcome
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_product
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_cart
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_checkout
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_review
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_order_completed
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS on_event.
    METHODS nav_to
      IMPORTING
        nav  TYPE string
        page TYPE string.
    METHODS product_show
      IMPORTING
        productid TYPE string.
    METHODS cart_add
      IMPORTING
        productid TYPE string.
    METHODS cart_refresh.
    METHODS cart_restore
      IMPORTING
        json TYPE string.
    METHODS order_submit.
    METHODS row_of
      IMPORTING
        product       TYPE ty_s_product
      RETURNING
        VALUE(result) TYPE ty_s_row.
    METHODS price_text
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS picture_url
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_demo_004 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " the chain hangs off the factory( ), so `view` holds the mvc:View and the
    " statements below add INTO it (view-chain-layout)
    DATA(view) = z2ui5_cl_ui5_view_builder=>factory(
        )->ele( n = `View` ns = `mvc`
            )->a( n = `displayBlock` v = `true`
            )->a( n = `height`       v = `100%`
            )->a( n = `xmlns`        v = `sap.m`
            )->a( n = `xmlns:mvc`    v = `sap.ui.core.mvc`
            )->a( n = `xmlns:f`      v = `sap.f`
            )->a( n = `xmlns:form`   v = `sap.ui.layout.form`
            )->a( n = `xmlns:z2ui5`  v = `z2ui5.cc` ).

    " the read half of the original's LocalStorageModel: an invisible control
    " that reads the key and fires `finished` when what it finds differs from
    " the bound value. The write half is the STORE_DATA action in cart_store( )
    view->tag( n = `Storage` ns = `z2ui5`
        )->a( n = `type`     v = client->_bind( s_storage-type )
        )->a( n = `prefix`   v = client->_bind( s_storage-prefix )
        )->a( n = `key`      v = client->_bind( s_storage-key )
        )->a( n = `value`    v = client->_bind( s_storage-value )
        )->a( n = `finished` v = client->_event( val = `CART_LOADED`
                                                 arg = `${$parameters>/value}` ) ).

    DATA(fcl) = view->ele( `App`
        )->a( n = `id` v = `app`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`               v = `layout`
            )->a( n = `layout`           v = client->_bind( layout )
            )->a( n = `backgroundDesign` v = `Translucent` ).

    DATA(nav_begin) = fcl->ele( n = `beginColumnPages` ns = `f`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav-begin` ).
    page_home( nav_begin ).
    page_category( nav_begin ).

    DATA(nav_mid) = fcl->ele( n = `midColumnPages` ns = `f`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav-mid` ).
    page_welcome( nav_mid ).
    page_product( nav_mid ).

    DATA(nav_end) = fcl->ele( n = `endColumnPages` ns = `f`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav-end` ).
    page_cart( nav_end ).
    page_checkout( nav_end ).
    page_review( nav_end ).
    page_order_completed( nav_end ).

    client->view_display( view->stringify( ) ).

    " a rebuilt NavContainer starts on its first page while the page a column
    " should show survives as class state - re-issue all three
    nav_to( nav = `nav-begin` page = page_begin ).
    nav_to( nav = `nav-mid`   page = page_mid ).
    nav_to( nav = `nav-end`   page = page_end ).

    " the same for the wizard's branches: nextStep is an association no
    " binding can carry, and XMLView.create has just rebuilt the steps, so the
    " payment branch and the delivery-address branch are re-issued here or
    " they are gone after any redisplay (sample z2ui5_cl_smp_app_202, and the
    " linter's control-state-lost-on-rebuild)
    IF pay_type IS NOT INITIAL.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `paymentTypeStep` ) ( `setNextStep` ) ( pay_type ) ) ).
    ENDIF.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `invoiceAddressStep` )
                                               ( `setNextStep` )
                                               ( COND #( WHEN del_different = abap_true
                                                         THEN `deliveryAddressStep`
                                                         ELSE `deliveryTypeStep` ) ) ) ).

  ENDMETHOD.


  METHOD page_home.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `page-home`
        )->a( n = `title`            v = `Shop`
        )->a( n = `backgroundDesign` v = `Solid` ).

    page->ele( `subHeader`
        )->ele( `Toolbar`
            )->tag( `SearchField`
                )->a( n = `id`          v = `searchField`
                )->a( n = `placeholder` v = `Search for products`
                )->a( n = `tooltip`     v = `Search for products`
                )->a( n = `value`       v = client->_bind( search_term )
                )->a( n = `search`      v = client->_event( `SEARCH` )
                )->a( n = `width`       v = `100%` ).

    DATA(content) = page->ele( `content` ).

    " the search results - one ObjectListItem list per panel, written out at
    " each site rather than through a parameterized helper: a helper whose id
    " and items are parameters cannot be reconstructed, and an unreconstructable
    " view is one the render gate skips (port-a-sample, "one builder chain per
    " view")
    content->ele( `List`
        )->a( n = `id`         v = `productList`
        )->a( n = `visible`    b = search_visible
        )->a( n = `mode`       v = `SingleSelectMaster`
        )->a( n = `noDataText` v = `No products found`
        )->a( n = `items`      v = client->_bind( t_search )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `type`             v = `Active`
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `{CURRENCYCODE}`
                )->a( n = `iconDensityAware` b = abap_false
                )->a( n = `tooltip`          v = `Open product details for {NAME}`
                )->a( n = `press`            v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `text` v = `{SUPPLIERNAME}`

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

    content->ele( `List`
        )->a( n = `id`         v = `categoryList`
        )->a( n = `headerText` v = `Categories`
        )->a( n = `mode`       v = `None`
        )->a( n = `items`      v = client->_bind( t_categories )

        )->ele( `items`
            )->tag( `StandardListItem`
                )->a( n = `title`   v = `{CATEGORYNAME}`
                )->a( n = `type`    v = `Active`
                )->a( n = `counter` v = `{NUMBEROFPRODUCTS}`
                )->a( n = `tooltip` v = `Open category {CATEGORYNAME}`
                )->a( n = `press`   v = client->_event( val = `CATEGORY` arg = `${CATEGORY}` ) ).

  ENDMETHOD.


  METHOD page_category.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `page-category`
        )->a( n = `title`            v = client->_bind( category_name )
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `showNavButton`    b = abap_true
        )->a( n = `navButtonPress`   v = client->_event( `BACK_HOME` ) ).

    DATA(content) = page->ele( `content` ).

    content->ele( `List`
        )->a( n = `id`         v = `categoryProductList`
        )->a( n = `mode`       v = `SingleSelectMaster`
        )->a( n = `noDataText` v = `No products in this category`
        )->a( n = `items`      v = client->_bind( t_category )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `type`             v = `Active`
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `{CURRENCYCODE}`
                )->a( n = `iconDensityAware` b = abap_false
                )->a( n = `tooltip`          v = `Open product details for {NAME}`
                )->a( n = `press`            v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `text` v = `{SUPPLIERNAME}`

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

  ENDMETHOD.


  METHOD page_welcome.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`    v = `page-welcome`
        )->a( n = `title` v = `Shopping Cart` ).

    page->ele( `customHeader`
        )->ele( `Bar`
            )->ele( `contentMiddle`
                )->tag( `Title`
                    )->a( n = `level`   v = `H2`
                    )->a( n = `text`    v = `Shopping Cart`
                    )->a( n = `tooltip` v = `Welcome to the Shopping Cart`

            )->end(
            )->ele( `contentRight`
                )->tag( `ToggleButton`
                    )->a( n = `icon`    v = `sap-icon://cart`
                    )->a( n = `pressed` b = cart_open
                    )->a( n = `tooltip` v = `Show the cart`
                    )->a( n = `press`   v = client->_event( `TOGGLE_CART` ) ).

    DATA(content) = page->ele( `content` ).

    DATA(promoted) = content->ele( `Panel`
        )->a( n = `id`               v = `panelPromoted`
        )->a( n = `headerText`       v = `Promoted Products`
        )->a( n = `backgroundDesign` v = `Transparent` ).
    DATA(promoted_content) = promoted->ele( `content` ).

    promoted_content->ele( `List`
        )->a( n = `id`         v = `promotedList`
        )->a( n = `mode`       v = `SingleSelectMaster`
        )->a( n = `noDataText` v = `No promoted products`
        )->a( n = `items`      v = client->_bind( t_promoted )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `type`             v = `Active`
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `{CURRENCYCODE}`
                )->a( n = `iconDensityAware` b = abap_false
                )->a( n = `tooltip`          v = `Open product details for {NAME}`
                )->a( n = `press`            v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `text` v = `{SUPPLIERNAME}`
                    " Add to cart, from the list itself. The original puts an
                    " Emphasized cart-3 Button on every welcome tile, and this
                    " rebuild replaced its carousel with two lists (see the
                    " class header) - which dropped the only way to fill the
                    " cart without opening a product first. An ObjectListItem
                    " takes no button, so the action is an ACTIVE
                    " ObjectAttribute: the same idiom the original itself uses
                    " for "Compare With" in its category list
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` b = abap_true
                        )->a( n = `text`   v = `Add to Cart`
                        )->a( n = `press`  v = client->_event( val = `ADD_TO_CART` arg = `${PRODUCTID}` )

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

    DATA(viewed) = content->ele( `Panel`
        )->a( n = `id`               v = `panelViewed`
        )->a( n = `headerText`       v = `Recently Viewed`
        )->a( n = `backgroundDesign` v = `Transparent` ).
    DATA(viewed_content) = viewed->ele( `content` ).

    viewed_content->ele( `List`
        )->a( n = `id`         v = `viewedList`
        )->a( n = `mode`       v = `SingleSelectMaster`
        )->a( n = `noDataText` v = `Nothing viewed yet`
        )->a( n = `items`      v = client->_bind( t_viewed )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `type`             v = `Active`
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `{CURRENCYCODE}`
                )->a( n = `iconDensityAware` b = abap_false
                )->a( n = `tooltip`          v = `Open product details for {NAME}`
                )->a( n = `press`            v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `text` v = `{SUPPLIERNAME}`
                    " Add to cart, from the list itself. The original puts an
                    " Emphasized cart-3 Button on every welcome tile, and this
                    " rebuild replaced its carousel with two lists (see the
                    " class header) - which dropped the only way to fill the
                    " cart without opening a product first. An ObjectListItem
                    " takes no button, so the action is an ACTIVE
                    " ObjectAttribute: the same idiom the original itself uses
                    " for "Compare With" in its category list
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` b = abap_true
                        )->a( n = `text`   v = `Add to Cart`
                        )->a( n = `press`  v = client->_event( val = `ADD_TO_CART` arg = `${PRODUCTID}` )

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

    DATA(favorite) = content->ele( `Panel`
        )->a( n = `id`               v = `panelFavorite`
        )->a( n = `headerText`       v = `Your Favorites`
        )->a( n = `backgroundDesign` v = `Transparent` ).
    DATA(favorite_content) = favorite->ele( `content` ).

    favorite_content->ele( `List`
        )->a( n = `id`         v = `favoriteList`
        )->a( n = `mode`       v = `SingleSelectMaster`
        )->a( n = `noDataText` v = `No favorites yet`
        )->a( n = `items`      v = client->_bind( t_favorite )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `type`             v = `Active`
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `{CURRENCYCODE}`
                )->a( n = `iconDensityAware` b = abap_false
                )->a( n = `tooltip`          v = `Open product details for {NAME}`
                )->a( n = `press`            v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `text` v = `{SUPPLIERNAME}`

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

  ENDMETHOD.


  METHOD page_product.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `page-product`
        )->a( n = `backgroundDesign` v = `Solid` ).

    page->ele( `customHeader`
        )->ele( `Bar`
            )->ele( `contentLeft`
                )->tag( `Button`
                    )->a( n = `type`  v = `Back`
                    )->a( n = `press` v = client->_event( `BACK_WELCOME` )

            )->end(
            )->ele( `contentMiddle`
                )->tag( `Title`
                    )->a( n = `level` v = `H2`
                    )->a( n = `text`  v = client->_bind( prod_name )

            )->end(
            )->ele( `contentRight`
                )->tag( `ToggleButton`
                    )->a( n = `icon`    v = `sap-icon://cart`
                    )->a( n = `pressed` b = cart_open
                    )->a( n = `tooltip` v = `Show the cart`
                    )->a( n = `press`   v = client->_event( `TOGGLE_CART` ) ).

    page->ele( `footer`
        )->ele( `Toolbar`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `text`  v = `Add to Cart`
                )->a( n = `type`  v = `Emphasized`
                )->a( n = `press` v = client->_event( `ADD_TO_CART` ) ).

    DATA(content) = page->ele( `content` ).

    content->ele( `ObjectHeader`
        )->a( n = `title`      v = client->_bind( prod_name )
        )->a( n = `titleLevel` v = `H3`
        )->a( n = `number`     v = client->_bind( prod_price )
        )->a( n = `numberUnit` v = client->_bind( prod_currency )

        )->ele( `attributes`
            )->tag( `ObjectAttribute`
                )->a( n = `title` v = `Supplier`
                )->a( n = `text`  v = client->_bind( prod_supplier )
            )->tag( `ObjectAttribute`
                )->a( n = `title` v = `Description`
                )->a( n = `text`  v = client->_bind( prod_desc )
            )->tag( `ObjectAttribute`
                )->a( n = `title` v = `Weight`
                )->a( n = `text`  v = client->_bind( prod_weight )
            )->tag( `ObjectAttribute`
                )->a( n = `title` v = `Measures`
                )->a( n = `text`  v = client->_bind( prod_measures )

        )->end(
        )->ele( `statuses`
            )->tag( `ObjectStatus`
                )->a( n = `text`  v = client->_bind( prod_status )
                )->a( n = `state` v = client->_bind( prod_state ) ).

    content->ele( `VBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `renderType` v = `Div`

        )->tag( `Image`
            )->a( n = `id`            v = `productImage`
            )->a( n = `src`           v = client->_bind( prod_picture )
            )->a( n = `decorative`    b = abap_true
            )->a( n = `densityAware`  b = abap_false
            )->a( n = `class`         v = `sapUiSmallMargin`
            )->a( n = `width`         v = `100%`
            )->a( n = `height`        v = `100%` ).

  ENDMETHOD.


  METHOD page_cart.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`             v = `page-cart`
        )->a( n = `title`          v = `Your Cart`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `TOGGLE_CART` ) ).

    DATA(content) = page->ele( `content` ).

    content->ele( `List`
        )->a( n = `id`         v = `entryList`
        )->a( n = `headerText` v = `Your Items`
        )->a( n = `noDataText` v = `Your cart is empty`
        )->a( n = `items`      v = client->_bind( t_cart )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `title`      v = `{NAME}`
                )->a( n = `icon`       v = `{PICTUREURL}`
                )->a( n = `number`     v = `{PRICE_TEXT}`
                )->a( n = `numberUnit` v = `{CURRENCYCODE}`

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `title` v = `Quantity`
                        )->a( n = `text`  v = `{QUANTITY}`
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` v = `true`
                        )->a( n = `text`   v = `Save for Later`
                        )->a( n = `press`  v = client->_event( val = `SAVE_LATER` arg = `${PRODUCTID}` )
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` v = `true`
                        )->a( n = `text`   v = `Remove`
                        )->a( n = `press`  v = client->_event( val = `CART_REMOVE` arg = `${PRODUCTID}` ) ).

    content->ele( `List`
        )->a( n = `id`         v = `savedList`
        )->a( n = `headerText` v = `Saved for Later`
        )->a( n = `noDataText` v = `Nothing saved for later`
        )->a( n = `items`      v = client->_bind( t_saved )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `title`      v = `{NAME}`
                )->a( n = `icon`       v = `{PICTUREURL}`
                )->a( n = `number`     v = `{PRICE_TEXT}`
                )->a( n = `numberUnit` v = `{CURRENCYCODE}`

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` v = `true`
                        )->a( n = `text`   v = `Move to Cart`
                        )->a( n = `press`  v = client->_event( val = `MOVE_TO_CART` arg = `${PRODUCTID}` ) ).

    page->ele( `footer`
        )->ele( `OverflowToolbar`
            )->tag( `Title`
                )->a( n = `text` v = client->_bind( cart_total )
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `id`    v = `proceedButton`
                )->a( n = `text`  v = `Proceed`
                )->a( n = `type`  v = `Accept`
                )->a( n = `press` v = client->_event( `PROCEED` ) ).

  ENDMETHOD.


  METHOD page_checkout.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`             v = `page-checkout`
        )->a( n = `title`          v = `Checkout`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `BACK_CART` ) ).

    " enableBranching + subsequentSteps is what lets the payment type pick the
    " step after it; the branch itself is set from the backend with
    " setNextStep, and re-issued on every render (see view_display)
    DATA(wizard) = page->ele( `content`
        )->ele( `Wizard`
            )->a( n = `id`              v = `checkoutWizard`
            )->a( n = `enableBranching` b = abap_true
            )->a( n = `complete`        v = client->_event( `WIZARD_COMPLETE` ) ).

    DATA(contents) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `contentsStep`
        )->a( n = `title`     v = `Contents`
        )->a( n = `validated` b = abap_true
        )->a( n = `nextStep`  v = `paymentTypeStep` ).

    contents->ele( `List`
        )->a( n = `noDataText` v = `Your cart is empty`
        )->a( n = `items`      v = client->_bind( t_cart )

        )->ele( `items`
            )->tag( `ObjectListItem`
                )->a( n = `title`      v = `{NAME}`
                )->a( n = `icon`       v = `{PICTUREURL}`
                )->a( n = `number`     v = `{PRICE_TEXT}`
                )->a( n = `numberUnit` v = `{CURRENCYCODE}` ).

    contents->tag( `Text`
        )->a( n = `text`  v = client->_bind( cart_total )
        )->a( n = `class` v = `sapUiSmallMarginTop` ).

    DATA(payment) = wizard->ele( `WizardStep`
        )->a( n = `id`              v = `paymentTypeStep`
        )->a( n = `title`           v = `Payment Type`
        )->a( n = `validated`       b = abap_true
        )->a( n = `subsequentSteps` v = `creditCardStep, bankAccountStep, cashOnDeliveryStep` ).

    payment->tag( `Text`
        )->a( n = `text` v = `Select the payment type` ).

    payment->ele( `SegmentedButton`
        )->a( n = `selectedKey`     v = client->_bind( pay_type )
        )->a( n = `selectionChange` v = client->_event( val = `PAY_TYPE` arg = `${$parameters>/item}.getKey()` )

        )->ele( `items`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`  v = `creditCardStep`
                )->a( n = `text` v = `Credit Card`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`  v = `bankAccountStep`
                )->a( n = `text` v = `Bank Transfer`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`  v = `cashOnDeliveryStep`
                )->a( n = `text` v = `Cash on Delivery` ).

    DATA(credit) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `creditCardStep`
        )->a( n = `title`     v = `Credit Card`
        )->a( n = `validated` b = abap_true
        )->a( n = `nextStep`  v = `invoiceAddressStep` ).

    credit->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable` b = abap_true
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Card Holder Name`
            )->tag( `Input`
                )->a( n = `id`          v = `creditCardHolderName`
                )->a( n = `value`       v = client->_bind( cc_name )
                )->a( n = `placeholder` v = `Enter the name on the card`
            )->tag( `Label`
                )->a( n = `text` v = `Card Number`
            )->tag( `Input`
                )->a( n = `id`          v = `creditCardNumber`
                )->a( n = `value`       v = client->_bind( cc_number )
                )->a( n = `placeholder` v = `16 digits`
            )->tag( `Label`
                )->a( n = `text` v = `Security Code`
            )->tag( `Input`
                )->a( n = `id`          v = `creditCardSecurityCode`
                )->a( n = `value`       v = client->_bind( cc_code )
                )->a( n = `placeholder` v = `3 digits`
            )->tag( `Label`
                )->a( n = `text` v = `Expiration Date`
            )->tag( `Input`
                )->a( n = `id`          v = `creditCardExpirationDate`
                )->a( n = `value`       v = client->_bind( cc_expire )
                )->a( n = `placeholder` v = `MM/YY` ).

    DATA(bank) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `bankAccountStep`
        )->a( n = `title`     v = `Bank Transfer`
        )->a( n = `validated` b = abap_true
        )->a( n = `nextStep`  v = `invoiceAddressStep` ).

    bank->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable` b = abap_false
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Beneficiary`
            )->tag( `Text`
                )->a( n = `text` v = `SAP SE`
            )->tag( `Label`
                )->a( n = `text` v = `Bank Name`
            )->tag( `Text`
                )->a( n = `text` v = `Deutsche Bank`
            )->tag( `Label`
                )->a( n = `text` v = `Account Number`
            )->tag( `Text`
                )->a( n = `text` v = `DE11 5001 0517 0648 4898 90` ).

    DATA(cod) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `cashOnDeliveryStep`
        )->a( n = `title`     v = `Cash on Delivery`
        )->a( n = `validated` b = abap_true
        )->a( n = `nextStep`  v = `invoiceAddressStep` ).

    cod->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable` b = abap_true
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `First Name`
            )->tag( `Input`
                )->a( n = `id`    v = `cashOnDeliveryName`
                )->a( n = `value` v = client->_bind( cod_firstname )
            )->tag( `Label`
                )->a( n = `text` v = `Last Name`
            )->tag( `Input`
                )->a( n = `id`    v = `cashOnDeliveryLastName`
                )->a( n = `value` v = client->_bind( cod_lastname )
            )->tag( `Label`
                )->a( n = `text` v = `Phone`
            )->tag( `Input`
                )->a( n = `id`    v = `cashOnDeliveryPhoneNumber`
                )->a( n = `value` v = client->_bind( cod_phone )
            )->tag( `Label`
                )->a( n = `text` v = `Email`
            )->tag( `Input`
                )->a( n = `id`    v = `cashOnDeliveryEmail`
                )->a( n = `value` v = client->_bind( cod_email ) ).

    DATA(invoice) = wizard->ele( `WizardStep`
        )->a( n = `id`              v = `invoiceAddressStep`
        )->a( n = `title`           v = `Invoice Address`
        )->a( n = `validated`       b = abap_true
        )->a( n = `subsequentSteps` v = `deliveryAddressStep, deliveryTypeStep` ).

    invoice->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable` b = abap_true
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Different Delivery Address`
            )->tag( `CheckBox`
                )->a( n = `id`       v = `differentDeliveryAddress`
                )->a( n = `selected` b = del_different
                )->a( n = `select`   v = client->_event( val = `DELIVERY_DIFFERENT` arg = `${$parameters>/selected}` )
            )->tag( `Label`
                )->a( n = `text` v = `Address`
            )->tag( `Input`
                )->a( n = `id`    v = `invoiceAddressAddress`
                )->a( n = `value` v = client->_bind( inv_address )
            )->tag( `Label`
                )->a( n = `text` v = `City`
            )->tag( `Input`
                )->a( n = `id`    v = `invoiceAddressCity`
                )->a( n = `value` v = client->_bind( inv_city )
            )->tag( `Label`
                )->a( n = `text` v = `ZIP Code`
            )->tag( `Input`
                )->a( n = `id`    v = `invoiceAddressZip`
                )->a( n = `value` v = client->_bind( inv_zip )
            )->tag( `Label`
                )->a( n = `text` v = `Country`
            )->tag( `Input`
                )->a( n = `id`    v = `invoiceAddressCountry`
                )->a( n = `value` v = client->_bind( inv_country )
            )->tag( `Label`
                )->a( n = `text` v = `Note`
            )->tag( `TextArea`
                )->a( n = `id`    v = `invoiceAddressNote`
                )->a( n = `value` v = client->_bind( inv_note ) ).

    DATA(delivery) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `deliveryAddressStep`
        )->a( n = `title`     v = `Delivery Address`
        )->a( n = `validated` b = abap_true
        )->a( n = `nextStep`  v = `deliveryTypeStep` ).

    delivery->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable` b = abap_true
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Address`
            )->tag( `Input`
                )->a( n = `id`    v = `deliveryAddressAddress`
                )->a( n = `value` v = client->_bind( del_address )
            )->tag( `Label`
                )->a( n = `text` v = `City`
            )->tag( `Input`
                )->a( n = `id`    v = `deliveryAddressCity`
                )->a( n = `value` v = client->_bind( del_city )
            )->tag( `Label`
                )->a( n = `text` v = `ZIP Code`
            )->tag( `Input`
                )->a( n = `id`    v = `deliveryAddressZip`
                )->a( n = `value` v = client->_bind( del_zip )
            )->tag( `Label`
                )->a( n = `text` v = `Country`
            )->tag( `Input`
                )->a( n = `id`    v = `deliveryAddressCountry`
                )->a( n = `value` v = client->_bind( del_country )
            )->tag( `Label`
                )->a( n = `text` v = `Note`
            )->tag( `TextArea`
                )->a( n = `id`    v = `deliveryAddressNote`
                )->a( n = `value` v = client->_bind( del_note ) ).

    DATA(delivery_type) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `deliveryTypeStep`
        )->a( n = `title`     v = `Delivery Type`
        )->a( n = `validated` b = abap_true ).

    delivery_type->tag( `Text`
        )->a( n = `text` v = `Select the delivery type` ).

    delivery_type->ele( `SegmentedButton`
        )->a( n = `selectedKey` v = client->_bind( del_type )

        )->ele( `items`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`  v = `Standard Delivery`
                )->a( n = `text` v = `Standard Delivery`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`  v = `Express Delivery`
                )->a( n = `text` v = `Express Delivery (10 EUR)` ).

  ENDMETHOD.


  METHOD page_review.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`             v = `page-review`
        )->a( n = `title`          v = `Order Summary`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `BACK_CHECKOUT` ) ).

    DATA(content) = page->ele( `content` ).

    content->ele( `List`
        )->a( n = `headerText` v = `Your Items`
        )->a( n = `items`      v = client->_bind( t_cart )

        )->ele( `items`
            )->tag( `ObjectListItem`
                )->a( n = `title`      v = `{NAME}`
                )->a( n = `number`     v = `{PRICE_TEXT}`
                )->a( n = `numberUnit` v = `{CURRENCYCODE}` ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `title`    v = `Payment`
        )->a( n = `editable` b = abap_false
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Payment Type`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( pay_type )
            )->tag( `Label`
                )->a( n = `text` v = `Invoice Address`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( inv_address )
            )->tag( `Label`
                )->a( n = `text` v = `Delivery Type`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( del_type )
            )->tag( `Label`
                )->a( n = `text` v = `Total`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cart_total ) ).

    page->ele( `footer`
        )->ele( `Bar`
            )->ele( `contentRight`
                )->tag( `Button`
                    )->a( n = `id`    v = `submitOrderButton`
                    )->a( n = `text`  v = `Submit Order`
                    )->a( n = `type`  v = `Accept`
                    )->a( n = `press` v = client->_event( `SUBMIT_ORDER` ) ).

  ENDMETHOD.


  METHOD page_order_completed.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `page-ordercompleted`
        )->a( n = `title`            v = `Order Completed`
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `class`            v = `sapUiContentPadding` ).

    page->ele( `content`
        )->tag( `FormattedText`
            )->a( n = `htmlText` v = `<p>Thank you for your order. You will receive a confirmation email shortly.</p>` ).

    page->ele( `footer`
        )->ele( `Bar`
            )->ele( `contentRight`
                )->tag( `Button`
                    )->a( n = `id`    v = `returnToShopButton`
                    )->a( n = `text`  v = `Return to Shop`
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->_event( `RETURN_TO_SHOP` ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `CART_LOADED`.
        " the browser had a cart under the key: it wins over what this app
        " instance holds, exactly as the original's model does - the storage
        " IS the model there
        cart_restore( client->get_event_arg( ) ).

      WHEN `SEARCH`.
        " the home list is the search result; the original hides it while the
        " search is empty and shows the categories instead
        t_search = VALUE #( ).
        IF search_term IS NOT INITIAL.
          LOOP AT t_all INTO DATA(found) WHERE name IS NOT INITIAL.
            IF to_upper( found-name ) CS to_upper( search_term ).
              INSERT row_of( found ) INTO TABLE t_search.
            ENDIF.
          ENDLOOP.
        ENDIF.
        search_visible = xsdbool( search_term IS NOT INITIAL ).

      WHEN `CATEGORY`.
        DATA(category) = client->get_event_arg( ).
        category_name = VALUE #( t_categories[ category = category ]-categoryname OPTIONAL ).
        t_category = VALUE #( ).
        LOOP AT t_all INTO DATA(product) WHERE category = category.
          INSERT row_of( product ) INTO TABLE t_category.
        ENDLOOP.
        SORT t_category BY name.
        nav_to( nav = `nav-begin` page = `page-category` ).

      WHEN `PRODUCT`.
        product_show( client->get_event_arg( ) ).

      WHEN `BACK_HOME`.
        nav_to( nav = `nav-begin` page = `page-home` ).

      WHEN `BACK_WELCOME`.
        nav_to( nav = `nav-mid` page = `page-welcome` ).

      WHEN `ADD_TO_CART`.
        cart_add( prod_id ).

      WHEN `TOGGLE_CART`.
        cart_open = xsdbool( cart_open = abap_false ).
        layout = COND #( WHEN cart_open = abap_true THEN `ThreeColumnsMidExpanded` ELSE `TwoColumnsMidExpanded` ).
        IF cart_open = abap_true.
          nav_to( nav = `nav-end` page = `page-cart` ).
        ENDIF.

      WHEN `SAVE_LATER`.
        DATA(saved_id) = client->get_event_arg( ).
        ASSIGN t_cart[ productid = saved_id ] TO FIELD-SYMBOL(<entry>).
        IF sy-subrc = 0.
          INSERT <entry> INTO TABLE t_saved.
          DELETE t_cart WHERE productid = saved_id.
          cart_refresh( ).
        ENDIF.

      WHEN `MOVE_TO_CART`.
        DATA(moved_id) = client->get_event_arg( ).
        DELETE t_saved WHERE productid = moved_id.
        cart_add( moved_id ).

      WHEN `CART_REMOVE`.
        DELETE t_cart WHERE productid = client->get_event_arg( ).
        cart_refresh( ).

      WHEN `PROCEED`.
        IF t_cart IS INITIAL.
          client->message_box_display( text = `Your cart is empty` type = `error` ).
        ELSE.
          layout = `EndColumnFullScreen`.
          nav_to( nav = `nav-end` page = `page-checkout` ).
        ENDIF.

      WHEN `PAY_TYPE`.
        " the branch of a branching Wizard is an association: it is set from
        " here and re-issued on every render (sample z2ui5_cl_smp_app_202)
        pay_type = client->get_event_arg( ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `checkoutWizard` ) ( `discardProgress` ) ( `paymentTypeStep` ) ) ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `paymentTypeStep` ) ( `setNextStep` ) ( pay_type ) ) ).

      WHEN `DELIVERY_DIFFERENT`.
        del_different = client->get_event_arg( ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `checkoutWizard` ) ( `discardProgress` ) ( `invoiceAddressStep` ) ) ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `invoiceAddressStep` )
                                                   ( `setNextStep` )
                                                   ( COND #( WHEN del_different = abap_true
                                                             THEN `deliveryAddressStep`
                                                             ELSE `deliveryTypeStep` ) ) ) ).

      WHEN `WIZARD_COMPLETE`.
        " the original validates the credit card step in its controller and
        " reports with a MessageBox; the whole check runs in ABAP here
        DATA(missing) = ``.
        IF pay_type = `creditCardStep` AND ( cc_name IS INITIAL OR cc_number IS INITIAL ).
          missing = `Enter the card holder name and the card number.`.
        ELSEIF pay_type = `cashOnDeliveryStep` AND ( cod_firstname IS INITIAL OR cod_email IS INITIAL ).
          missing = `Enter your name and your email address.`.
        ELSEIF inv_address IS INITIAL OR inv_city IS INITIAL.
          missing = `Enter the invoice address.`.
        ELSEIF del_different = abap_true AND del_address IS INITIAL.
          missing = `Enter the delivery address.`.
        ENDIF.
        IF missing IS NOT INITIAL.
          client->message_box_display( text = missing type = `error` ).
        ELSE.
          nav_to( nav = `nav-end` page = `page-review` ).
        ENDIF.

      WHEN `BACK_CHECKOUT`.
        nav_to( nav = `nav-end` page = `page-checkout` ).

      WHEN `BACK_CART`.
        layout = `ThreeColumnsMidExpanded`.
        nav_to( nav = `nav-end` page = `page-cart` ).

      WHEN `SUBMIT_ORDER`.
        order_submit( ).

      WHEN `RETURN_TO_SHOP`.
        cart_open = abap_false.
        layout    = `TwoColumnsMidExpanded`.
        nav_to( nav = `nav-end` page = `page-cart` ).
        nav_to( nav = `nav-mid` page = `page-welcome` ).

    ENDCASE.

  ENDMETHOD.


  METHOD nav_to.

    " a NavContainer page switch: no round-trip when it is wired to a
    " control, one when the backend decides which page comes next - as here,
    " where the page depends on what the event did
    CASE nav.
      WHEN `nav-begin`.
        page_begin = page.
      WHEN `nav-mid`.
        page_mid = page.
      WHEN OTHERS.
        page_end = page.
    ENDCASE.

    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( nav ) ( `to` ) ( page ) ) ).

  ENDMETHOD.


  METHOD product_show.

    ASSIGN t_all[ productid = productid ] TO FIELD-SYMBOL(<product>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    prod_id       = <product>-productid.
    prod_name     = <product>-name.
    prod_supplier = <product>-suppliername.
    prod_desc     = <product>-shortdescription.
    prod_price    = price_text( <product>-price ).
    prod_currency = <product>-currencycode.
    prod_picture  = picture_url( <product>-pictureurl ).
    prod_status   = SWITCH #( <product>-status
                              WHEN `A` THEN `Available`
                              WHEN `O` THEN `Out of stock`
                              WHEN `D` THEN `Discontinued`
                              ELSE <product>-status ).
    prod_state    = SWITCH #( <product>-status
                              WHEN `A` THEN `Success`
                              WHEN `O` THEN `Warning`
                              WHEN `D` THEN `Error`
                              ELSE `None` ).
    prod_weight   = |{ <product>-weight } { <product>-weightunit }|.
    prod_measures = |{ <product>-dimensionwidth } { <product>-dimensionunit }, | &&
                    |{ <product>-dimensiondepth } { <product>-dimensionunit }, | &&
                    |{ <product>-dimensionheight } { <product>-dimensionunit }|.

    nav_to( nav = `nav-mid` page = `page-product` ).
    IF layout IS INITIAL OR layout = `OneColumn`.
      layout = `TwoColumnsMidExpanded`.
    ENDIF.

  ENDMETHOD.


  METHOD cart_add.

    ASSIGN t_all[ productid = productid ] TO FIELD-SYMBOL(<product>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    ASSIGN t_cart[ productid = productid ] TO FIELD-SYMBOL(<entry>).
    IF sy-subrc = 0.
      <entry>-quantity = <entry>-quantity + 1.
    ELSE.
      INSERT VALUE #( productid    = <product>-productid
                      name         = <product>-name
                      pictureurl   = picture_url( <product>-pictureurl )
                      price_text   = price_text( <product>-price )
                      currencycode = <product>-currencycode
                      quantity     = 1 ) INTO TABLE t_cart.
    ENDIF.

    cart_refresh( ).
    client->message_toast_display( |{ <product>-name } has been added to your shopping cart.| ).

  ENDMETHOD.


  METHOD cart_refresh.

    " the totalPrice formatter of the original, computed where the prices are
    DATA total TYPE ty_amount.

    LOOP AT t_cart INTO DATA(entry).
      ASSIGN t_all[ productid = entry-productid ] TO FIELD-SYMBOL(<product>).
      IF sy-subrc = 0.
        total = total + CONV ty_amount( <product>-price ) * entry-quantity.
      ENDIF.
    ENDLOOP.

    cart_total = |Total: { price_text( |{ total }| ) } EUR|.

    " the write half: the same two tables into the browser's local storage,
    " under the key the original uses. The mirror is what keeps the reading
    " control quiet - it compares by value and fires only on a difference
    s_storage-value = VALUE #( cart = t_cart saved = t_saved ).
    client->follow_up_action( val   = client->cs_event-store_data
                              t_arg = VALUE #( ( |${ client->_bind( s_storage ) }| ) ) ).

  ENDMETHOD.


  METHOD cart_restore.

    " the control reports what it read as JSON; z2ui5_cl_ui5_json is the
    " released reader for app code (a released JSON parser is the one thing
    " no ABAP release ships portably - see its own documentation). The pinned
    " linter 0.6.1 predates the class and reads it as an internal; its main
    " branch already lists it, so this waiver goes with the next pin move
    " abap2ui5lint-disable-next-line non-released-api -- released in src/02, newer than the pinned 0.6.1
    DATA(reader) = z2ui5_cl_ui5_json=>factory( json ).

    t_cart = VALUE #( ).
    LOOP AT reader->members( `/CART` ) INTO DATA(cart_index).
      DATA(cart_path) = |/CART/{ cart_index }|.
      INSERT VALUE #( productid    = reader->get_string( |{ cart_path }/PRODUCTID| )
                      name         = reader->get_string( |{ cart_path }/NAME| )
                      pictureurl   = reader->get_string( |{ cart_path }/PICTUREURL| )
                      price_text   = reader->get_string( |{ cart_path }/PRICE_TEXT| )
                      currencycode = reader->get_string( |{ cart_path }/CURRENCYCODE| )
                      quantity     = reader->get_integer( |{ cart_path }/QUANTITY| ) ) INTO TABLE t_cart.
    ENDLOOP.

    t_saved = VALUE #( ).
    LOOP AT reader->members( `/SAVED` ) INTO DATA(saved_index).
      DATA(saved_path) = |/SAVED/{ saved_index }|.
      INSERT VALUE #( productid    = reader->get_string( |{ saved_path }/PRODUCTID| )
                      name         = reader->get_string( |{ saved_path }/NAME| )
                      pictureurl   = reader->get_string( |{ saved_path }/PICTUREURL| )
                      price_text   = reader->get_string( |{ saved_path }/PRICE_TEXT| )
                      currencycode = reader->get_string( |{ saved_path }/CURRENCYCODE| )
                      quantity     = reader->get_integer( |{ saved_path }/QUANTITY| ) ) INTO TABLE t_saved.
    ENDLOOP.

    cart_refresh( ).

  ENDMETHOD.


  METHOD order_submit.

    " the original posts nothing either - it clears the cart and shows the
    " completed page
    t_cart     = VALUE #( ).
    cart_total = ``.
    cart_refresh( ).
    nav_to( nav = `nav-end` page = `page-ordercompleted` ).

  ENDMETHOD.


  METHOD row_of.

    result = VALUE #( productid    = product-productid
                      name         = product-name
                      suppliername = product-suppliername
                      price_text   = price_text( product-price )
                      currencycode = product-currencycode
                      pictureurl   = picture_url( product-pictureurl )
                      status_text  = SWITCH #( product-status
                                               WHEN `A` THEN `Available`
                                               WHEN `O` THEN `Out of stock`
                                               WHEN `D` THEN `Discontinued`
                                               ELSE product-status )
                      status_state = SWITCH #( product-status
                                               WHEN `A` THEN `Success`
                                               WHEN `O` THEN `Warning`
                                               WHEN `D` THEN `Error`
                                               ELSE `None` ) ).

  ENDMETHOD.


  METHOD picture_url.

    " the original's pictureUrl formatter: `sap.ui.require.toUrl( )` against
    " the resource root the app declares for `sap/ui/demo/mock`. Here that
    " root is the demo kit's deployed copy of the folder (see c_base), so the
    " prefix is what gets replaced - a path without it is left alone rather
    " than silently prefixed, because then it is not a mock path
    DATA(len) = strlen( c_mock_prefix ).

    result = val.
    IF strlen( result ) > len AND result(len) = c_mock_prefix.
      result = |{ c_base }{ result+len }|.
    ENDIF.

  ENDMETHOD.


  METHOD price_text.

    " the price formatter of the original: two decimals, "." between the
    " thousands and "," before them - a NumberFormat in the browser there,
    " ABAP here, because a format is not a decision the frontend should make
    DATA(amount) = CONV ty_amount( val ).
    DATA(raw) = |{ amount DECIMALS = 2 NUMBER = RAW }|.

    SPLIT raw AT `.` INTO DATA(whole) DATA(fraction).
    DATA(grouped) = ``.
    WHILE strlen( whole ) > 3.
      DATA(cut) = strlen( whole ) - 3.
      grouped = |.{ substring( val = whole off = cut len = 3 ) }{ grouped }|.
      whole   = substring( val = whole len = cut ).
    ENDWHILE.

    result = |{ whole }{ grouped },{ fraction }|.

  ENDMETHOD.


  METHOD model_init.

    " localService/mockdata/ProductCategories.json
    t_categories = VALUE #(
        ( category = `AC`  categoryname = `Accessories`                 numberofproducts = 34 )
        ( category = `DC`  categoryname = `Desktop Computers`           numberofproducts = 5 )
        ( category = `FS`  categoryname = `Flat Screens`                numberofproducts = 3 )
        ( category = `KB`  categoryname = `Keyboards`                   numberofproducts = 4 )
        ( category = `LT`  categoryname = `Laptops`                     numberofproducts = 11 )
        ( category = `PR`  categoryname = `Printers`                    numberofproducts = 9 )
        ( category = `ST`  categoryname = `Smartphones and Tablets`     numberofproducts = 9 )
        ( category = `MI`  categoryname = `Mice`                        numberofproducts = 7 )
        ( category = `CSA` categoryname = `Computer System Accessories` numberofproducts = 7 )
        ( category = `GC`  categoryname = `Graphics Card`               numberofproducts = 4 )
        ( category = `SC`  categoryname = `Scanners`                    numberofproducts = 4 )
        ( category = `SP`  categoryname = `Speakers`                    numberofproducts = 3 )
        ( category = `SW`  categoryname = `Software`                    numberofproducts = 8 )
        ( category = `TC`  categoryname = `Telecommunication`           numberofproducts = 3 )
        ( category = `SV`  categoryname = `Servers`                     numberofproducts = 3 )
        ( category = `FST` categoryname = `Flat Screen TVs`             numberofproducts = 3 ) ).

    " localService/mockdata/FeaturedProducts.json - the three panels of the
    " welcome page
    t_featured = VALUE #(
        ( productid = `HT-6132` type = `Promoted` )
        ( productid = `HT-1000` type = `Promoted` )
        ( productid = `HT-1113` type = `Promoted` )
        ( productid = `HT-6130` type = `Promoted` )
        ( productid = `HT-1040` type = `Promoted` )
        ( productid = `HT-9992` type = `Viewed` )
        ( productid = `HT-6130` type = `Viewed` )
        ( productid = `HT-6110` type = `Viewed` )
        ( productid = `HT-9997` type = `Viewed` )
        ( productid = `HT-8000` type = `Favorite` )
        ( productid = `HT-6100` type = `Favorite` )
        ( productid = `HT-6111` type = `Favorite` )
        ( productid = `HT-1041` type = `Favorite` ) ).

    " localService/mockdata/Products.json - the full 123-row mock, verbatim
    t_all = VALUE #(
        ( productid = `HT-1000` name = `Notebook Basic 15` category = `LT` suppliername = `Very Best Screens`
          shortdescription = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1000.jpg` price = `956` currencycode = `EUR` status = `A`
          weight = `4.2` weightunit = `KG` dimensionwidth = `30` dimensiondepth = `18` dimensionheight = `3` dimensionunit = `cm` )
        ( productid = `HT-1001` name = `Notebook Basic 17` category = `LT` suppliername = `Very Best Screens`
          shortdescription = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1001.jpg` price = `1249` currencycode = `EUR` status = `A`
          weight = `4.5` weightunit = `KG` dimensionwidth = `29` dimensiondepth = `17` dimensionheight = `3.1` dimensionunit = `cm` )
        ( productid = `HT-1002` name = `Notebook Basic 18` category = `LT` suppliername = `Very Best Screens`
          shortdescription = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1002.jpg` price = `1570` currencycode = `EUR` status = `A`
          weight = `4.2` weightunit = `KG` dimensionwidth = `28` dimensiondepth = `19` dimensionheight = `2.5` dimensionunit = `cm` )
        ( productid = `HT-1003` name = `Notebook Basic 19` category = `LT` suppliername = `Smartcards`
          shortdescription = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1003.jpg` price = `1650` currencycode = `EUR` status = `A`
          weight = `4.2` weightunit = `KG` dimensionwidth = `32` dimensiondepth = `21` dimensionheight = `4` dimensionunit = `cm` )
        ( productid = `HT-1007` name = `ITelO Vault` category = `AC` suppliername = `Technocom`
          shortdescription = `Digital Organizer with State-of-the-Art Storage Encryption`
          pictureurl = `sap/ui/demo/mock/images/HT-1007.jpg` price = `299` currencycode = `EUR` status = `D`
          weight = `0.2` weightunit = `KG` dimensionwidth = `32` dimensiondepth = `22` dimensionheight = `3` dimensionunit = `cm` )
        ( productid = `HT-1010` name = `Notebook Professional 15` category = `AC` suppliername = `Very Best Screens`
          shortdescription = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1010.jpg` price = `1999` currencycode = `EUR` status = `A`
          weight = `4.3` weightunit = `KG` dimensionwidth = `33` dimensiondepth = `20` dimensionheight = `3` dimensionunit = `cm` )
        ( productid = `HT-1011` name = `Notebook Professional 17` category = `LT` suppliername = `Very Best Screens`
          shortdescription = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1011.jpg` price = `2299` currencycode = `EUR` status = `O`
          weight = `4.1` weightunit = `KG` dimensionwidth = `33` dimensiondepth = `23` dimensionheight = `2` dimensionunit = `cm` )
        ( productid = `HT-1020` name = `ITelO Vault Net` category = `AC` suppliername = `Technocom`
          shortdescription = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`
          pictureurl = `sap/ui/demo/mock/images/HT-1020.jpg` price = `459` currencycode = `EUR` status = `O`
          weight = `0.16` weightunit = `KG` dimensionwidth = `10` dimensiondepth = `1.8` dimensionheight = `17` dimensionunit = `cm` )
        ( productid = `HT-1021` name = `ITelO Vault SAT` category = `AC` suppliername = `Technocom`
          shortdescription = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`
          pictureurl = `sap/ui/demo/mock/images/HT-1021.jpg` price = `149` currencycode = `EUR` status = `D`
          weight = `0.18` weightunit = `KG` dimensionwidth = `11` dimensiondepth = `1.7` dimensionheight = `18` dimensionunit = `cm` )
        ( productid = `HT-1022` name = `Comfort Easy` category = `AC` suppliername = `Technocom`
          shortdescription = `32 GB Digital Assistant with high-resolution color screen`
          pictureurl = `sap/ui/demo/mock/images/HT-1022.jpg` price = `1679` currencycode = `EUR` status = `A`
          weight = `0.2` weightunit = `KG` dimensionwidth = `84` dimensiondepth = `1.5` dimensionheight = `14` dimensionunit = `cm` )
        ( productid = `HT-1023` name = `Comfort Senior` category = `AC` suppliername = `Technocom`
          shortdescription = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`
          pictureurl = `sap/ui/demo/mock/images/HT-1023.jpg` price = `512` currencycode = `EUR` status = `A`
          weight = `0.8` weightunit = `KG` dimensionwidth = `80` dimensiondepth = `1.6` dimensionheight = `13` dimensionunit = `cm` )
        ( productid = `HT-1030` name = `Ergo Screen E-I` category = `FT` suppliername = `Very Best Screens`
          shortdescription = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`
          pictureurl = `sap/ui/demo/mock/images/HT-1030.jpg` price = `230` currencycode = `EUR` status = `D`
          weight = `21` weightunit = `KG` dimensionwidth = `37` dimensiondepth = `12` dimensionheight = `36` dimensionunit = `cm` )
        ( productid = `HT-1031` name = `Ergo Screen E-II` category = `FT` suppliername = `Very Best Screens`
          shortdescription = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`
          pictureurl = `sap/ui/demo/mock/images/HT-1031.jpg` price = `285` currencycode = `EUR` status = `O`
          weight = `21` weightunit = `KG` dimensionwidth = `40.8` dimensiondepth = `19` dimensionheight = `43` dimensionunit = `cm` )
        ( productid = `HT-1032` name = `Ergo Screen E-III` category = `FT` suppliername = `Very Best Screens`
          shortdescription = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`
          pictureurl = `sap/ui/demo/mock/images/HT-1032.jpg` price = `345` currencycode = `EUR` status = `A`
          weight = `21` weightunit = `KG` dimensionwidth = `40.8` dimensiondepth = `19` dimensionheight = `43` dimensionunit = `cm` )
        ( productid = `HT-1035` name = `Flat Basic` category = `FT` suppliername = `Very Best Screens`
          shortdescription = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`
          pictureurl = `sap/ui/demo/mock/images/HT-1035.jpg` price = `399` currencycode = `EUR` status = `A`
          weight = `14` weightunit = `KG` dimensionwidth = `39` dimensiondepth = `20` dimensionheight = `41` dimensionunit = `cm` )
        ( productid = `HT-1036` name = `Flat Future` category = `FT` suppliername = `Very Best Screens`
          shortdescription = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`
          pictureurl = `sap/ui/demo/mock/images/HT-1036.jpg` price = `430` currencycode = `EUR` status = `O`
          weight = `15` weightunit = `KG` dimensionwidth = `45` dimensiondepth = `26` dimensionheight = `46` dimensionunit = `cm` )
        ( productid = `HT-1037` name = `Flat XL` category = `FT` suppliername = `Very Best Screens`
          shortdescription = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`
          pictureurl = `sap/ui/demo/mock/images/HT-1037.jpg` price = `1230` currencycode = `EUR` status = `A`
          weight = `17` weightunit = `KG` dimensionwidth = `54.5` dimensiondepth = `22.1` dimensionheight = `39.1` dimensionunit = `cm` )
        ( productid = `HT-1040` name = `Laser Professional Eco` category = `PR` suppliername = `Alpha Printers`
          shortdescription = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`
          pictureurl = `sap/ui/demo/mock/images/HT-1040.jpg` price = `830` currencycode = `EUR` status = `A`
          weight = `32` weightunit = `KG` dimensionwidth = `51` dimensiondepth = `46` dimensionheight = `30` dimensionunit = `cm` )
        ( productid = `HT-1041` name = `Laser Basic` category = `PR` suppliername = `Alpha Printers`
          shortdescription = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`
          pictureurl = `sap/ui/demo/mock/images/HT-1041.jpg` price = `490` currencycode = `EUR` status = `A`
          weight = `23` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `42` dimensionheight = `26` dimensionunit = `cm` )
        ( productid = `HT-1042` name = `Laser Allround` category = `PR` suppliername = `Alpha Printers`
          shortdescription = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with a first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`
          pictureurl = `sap/ui/demo/mock/images/HT-1042.jpg` price = `349` currencycode = `EUR` status = `A`
          weight = `17` weightunit = `KG` dimensionwidth = `53` dimensiondepth = `50` dimensionheight = `65` dimensionunit = `cm` )
        ( productid = `HT-1050` name = `Ultra Jet Super Color` category = `PR` suppliername = `Alpha Printers`
          shortdescription = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`
          pictureurl = `sap/ui/demo/mock/images/HT-1050.jpg` price = `139` currencycode = `EUR` status = `A`
          weight = `3` weightunit = `KG` dimensionwidth = `41` dimensiondepth = `41` dimensionheight = `28` dimensionunit = `cm` )
        ( productid = `HT-1051` name = `Ultra Jet Mobile` category = `PR` suppliername = `Printer for All`
          shortdescription = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`
          pictureurl = `sap/ui/demo/mock/images/HT-1051.jpg` price = `99` currencycode = `EUR` status = `A`
          weight = `1.9` weightunit = `KG` dimensionwidth = `46` dimensiondepth = `32` dimensionheight = `25` dimensionunit = `cm` )
        ( productid = `HT-1052` name = `Ultra Jet Super Highspeed` category = `PR` suppliername = `Printer for All`
          shortdescription = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`
          pictureurl = `sap/ui/demo/mock/images/HT-1052.jpg` price = `170` currencycode = `EUR` status = `A`
          weight = `18` weightunit = `KG` dimensionwidth = `41` dimensiondepth = `41` dimensionheight = `28` dimensionunit = `cm` )
        ( productid = `HT-1055` name = `Multi Print` category = `PR` suppliername = `Printer for All`
          shortdescription = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`
          pictureurl = `sap/ui/demo/mock/images/HT-1055.jpg` price = `99` currencycode = `EUR` status = `A`
          weight = `6.3` weightunit = `KG` dimensionwidth = `55` dimensiondepth = `45` dimensionheight = `29` dimensionunit = `cm` )
        ( productid = `HT-1056` name = `Multi Color` category = `PR` suppliername = `Printer for All`
          shortdescription = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`
          pictureurl = `sap/ui/demo/mock/images/HT-1056.jpg` price = `119` currencycode = `EUR` status = `A`
          weight = `4.3` weightunit = `KG` dimensionwidth = `51` dimensiondepth = `41.3` dimensionheight = `22` dimensionunit = `cm` )
        ( productid = `HT-1060` name = `Cordless Mouse` category = `MI` suppliername = `Oxynum`
          shortdescription = `Cordless Optical USB MI, Laptop, Color: Black, Plug&Play`
          pictureurl = `sap/ui/demo/mock/images/HT-1060.jpg` price = `9` currencycode = `EUR` status = `O`
          weight = `0.09` weightunit = `KG` dimensionwidth = `6` dimensiondepth = `14.5` dimensionheight = `3.5` dimensionunit = `cm` )
        ( productid = `HT-1061` name = `Speed Mouse` category = `MI` suppliername = `Oxynum`
          shortdescription = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`
          pictureurl = `sap/ui/demo/mock/images/HT-1061.jpg` price = `7` currencycode = `EUR` status = `D`
          weight = `0.09` weightunit = `KG` dimensionwidth = `7` dimensiondepth = `15` dimensionheight = `3.1` dimensionunit = `cm` )
        ( productid = `HT-1062` name = `Track Mouse` category = `MI` suppliername = `Oxynum`
          shortdescription = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`
          pictureurl = `sap/ui/demo/mock/images/HT-1062.jpg` price = `11` currencycode = `EUR` status = `O`
          weight = `0.03` weightunit = `KG` dimensionwidth = `3` dimensiondepth = `7` dimensionheight = `4` dimensionunit = `cm` )
        ( productid = `HT-1063` name = `Ergonomic Keyboard` category = `KB` suppliername = `Oxynum`
          shortdescription = `Ergonomic USB Keyboard for Desktop, Plug&Play`
          pictureurl = `sap/ui/demo/mock/images/HT-1063.jpg` price = `14` currencycode = `EUR` status = `D`
          weight = `2.1` weightunit = `KG` dimensionwidth = `50` dimensiondepth = `21` dimensionheight = `3.5` dimensionunit = `cm` )
        ( productid = `HT-1064` name = `Internet Keyboard` category = `KB` suppliername = `Oxynum`
          shortdescription = `Corded Keyboard with special keys for Internet Usability, USB`
          pictureurl = `sap/ui/demo/mock/images/HT-1064.jpg` price = `16` currencycode = `EUR` status = `A`
          weight = `1.8` weightunit = `KG` dimensionwidth = `52` dimensiondepth = `25` dimensionheight = `3` dimensionunit = `cm` )
        ( productid = `HT-1065` name = `Media Keyboard` category = `KB` suppliername = `Oxynum`
          shortdescription = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`
          pictureurl = `sap/ui/demo/mock/images/HT-1065.jpg` price = `26` currencycode = `EUR` status = `A`
          weight = `2.3` weightunit = `KG` dimensionwidth = `51.4` dimensiondepth = `23` dimensionheight = `4` dimensionunit = `cm` )
        ( productid = `HT-1066` name = `Mousepad` category = `MI` suppliername = `Oxynum`
          shortdescription = `Nice mouse pad with ITelO Logo`
          pictureurl = `sap/ui/demo/mock/images/HT-1066.jpg` price = `6.99` currencycode = `EUR` status = `A`
          weight = `80` weightunit = `G` dimensionwidth = `15` dimensiondepth = `6` dimensionheight = `0.2` dimensionunit = `cm` )
        ( productid = `HT-1067` name = `Ergo Mousepad` category = `MI` suppliername = `Oxynum`
          shortdescription = `Ergonomic mouse pad with ITelO Logo`
          pictureurl = `sap/ui/demo/mock/images/HT-1067.jpg` price = `8.99` currencycode = `EUR` status = `O`
          weight = `80` weightunit = `G` dimensionwidth = `15` dimensiondepth = `6` dimensionheight = `0.2` dimensionunit = `cm` )
        ( productid = `HT-1068` name = `Designer Mousepad` category = `MI` suppliername = `Fasttech`
          shortdescription = `ITelO Mousepad Special Edition`
          pictureurl = `sap/ui/demo/mock/images/HT-1068.jpg` price = `12.99` currencycode = `EUR` status = `A`
          weight = `90` weightunit = `G` dimensionwidth = `24` dimensiondepth = `24` dimensionheight = `0.6` dimensionunit = `cm` )
        ( productid = `HT-1069` name = `Universal card reader` category = `CSA` suppliername = `Fasttech`
          shortdescription = `Universal card reader`
          pictureurl = `sap/ui/demo/mock/images/HT-1069.jpg` price = `14` currencycode = `EUR` status = `O`
          weight = `45` weightunit = `G` dimensionwidth = `6` dimensiondepth = `6` dimensionheight = `3` dimensionunit = `cm` )
        ( productid = `HT-1070` name = `Proctra X` category = `GC` suppliername = `Ultrasonic United`
          shortdescription = `Proctra X: PCI-E GDDR5 3072MB`
          pictureurl = `sap/ui/demo/mock/images/HT-1070.jpg` price = `70.9` currencycode = `EUR` status = `A`
          weight = `0.255` weightunit = `KG` dimensionwidth = `22` dimensiondepth = `35` dimensionheight = `17` dimensionunit = `cm` )
        ( productid = `HT-1071` name = `Gladiator MX` category = `GC` suppliername = `Ultrasonic United`
          shortdescription = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`
          pictureurl = `sap/ui/demo/mock/images/HT-1071.jpg` price = `81.7` currencycode = `EUR` status = `A`
          weight = `0.3` weightunit = `KG` dimensionwidth = `22` dimensiondepth = `35` dimensionheight = `17` dimensionunit = `cm` )
        ( productid = `HT-1072` name = `Hurricane GX` category = `GC` suppliername = `Ultrasonic United`
          shortdescription = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`
          pictureurl = `sap/ui/demo/mock/images/HT-1072.jpg` price = `101.2` currencycode = `EUR` status = `A`
          weight = `0.4` weightunit = `KG` dimensionwidth = `22` dimensiondepth = `35` dimensionheight = `17` dimensionunit = `cm` )
        ( productid = `HT-1073` name = `Hurricane GX/LN` category = `GC` suppliername = `Smartcards`
          shortdescription = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`
          pictureurl = `sap/ui/demo/mock/images/HT-1073.jpg` price = `139.99` currencycode = `EUR` status = `A`
          weight = `0.4` weightunit = `KG` dimensionwidth = `22` dimensiondepth = `35` dimensionheight = `17` dimensionunit = `cm` )
        ( productid = `HT-1080` name = `Photo Scan` category = `SC` suppliername = `Printer for All`
          shortdescription = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`
          pictureurl = `sap/ui/demo/mock/images/HT-1080.jpg` price = `129` currencycode = `EUR` status = `A`
          weight = `2.3` weightunit = `KG` dimensionwidth = `34` dimensiondepth = `48` dimensionheight = `5` dimensionunit = `cm` )
        ( productid = `HT-1081` name = `Power Scan` category = `SC` suppliername = `Printer for All`
          shortdescription = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`
          pictureurl = `sap/ui/demo/mock/images/HT-1081.jpg` price = `89` currencycode = `EUR` status = `A`
          weight = `2.4` weightunit = `KG` dimensionwidth = `31` dimensiondepth = `43` dimensionheight = `7` dimensionunit = `cm` )
        ( productid = `HT-1082` name = `Jet Scan Professional` category = `SC` suppliername = `Printer for All`
          shortdescription = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`
          pictureurl = `sap/ui/demo/mock/images/HT-1082.jpg` price = `169` currencycode = `EUR` status = `A`
          weight = `3.2` weightunit = `KG` dimensionwidth = `33` dimensiondepth = `41` dimensionheight = `12` dimensionunit = `cm` )
        ( productid = `HT-1083` name = `Jet Scan Professional` category = `SC` suppliername = `Printer for All`
          shortdescription = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`
          pictureurl = `sap/ui/demo/mock/images/HT-1083.jpg` price = `189` currencycode = `EUR` status = `A`
          weight = `3.2` weightunit = `KG` dimensionwidth = `35` dimensiondepth = `40` dimensionheight = `10` dimensionunit = `cm` )
        ( productid = `HT-1085` name = `Copymaster` category = `PR` suppliername = `Alpha Printers`
          shortdescription = `Copymaster`
          pictureurl = `sap/ui/demo/mock/images/HT-1085.jpg` price = `1499` currencycode = `EUR` status = `A`
          weight = `23.2` weightunit = `KG` dimensionwidth = `45` dimensiondepth = `42` dimensionheight = `22` dimensionunit = `cm` )
        ( productid = `HT-1090` name = `Surround Sound` category = `SP` suppliername = `Speaker Experts`
          shortdescription = `PC multimedia speakers - 5 Watt (Total)`
          pictureurl = `sap/ui/demo/mock/images/HT-1090.jpg` price = `39` currencycode = `EUR` status = `A`
          weight = `3` weightunit = `KG` dimensionwidth = `12` dimensiondepth = `10` dimensionheight = `16` dimensionunit = `cm` )
        ( productid = `HT-1091` name = `Blaster Extreme` category = `SP` suppliername = `Speaker Experts`
          shortdescription = `PC multimedia speakers - 10 Watt (Total) - 2-way`
          pictureurl = `sap/ui/demo/mock/images/HT-1091.jpg` price = `26` currencycode = `EUR` status = `A`
          weight = `1.4` weightunit = `KG` dimensionwidth = `13` dimensiondepth = `11` dimensionheight = `17.5` dimensionunit = `cm` )
        ( productid = `HT-1092` name = `Sound Booster` category = `SP` suppliername = `Speaker Experts`
          shortdescription = `PC multimedia speakers - optimized for Blutooth/A2DP`
          pictureurl = `sap/ui/demo/mock/images/HT-1092.jpg` price = `45` currencycode = `EUR` status = `A`
          weight = `2.1` weightunit = `KG` dimensionwidth = `12.4` dimensiondepth = `10.4` dimensionheight = `18.1` dimensionunit = `cm` )
        ( productid = `HT-1100` name = `Smart Office` category = `SW` suppliername = `Technocom`
          shortdescription = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`
          pictureurl = `sap/ui/demo/mock/images/HT-1100.jpg` price = `89.9` currencycode = `EUR` status = `D`
          weight = `1.2` weightunit = `KG` dimensionwidth = `15` dimensiondepth = `6.5` dimensionheight = `2.1` dimensionunit = `cm` )
        ( productid = `HT-1101` name = `Smart Design` category = `SW` suppliername = `Technocom`
          shortdescription = `Complete package, 1 User, Image editing, processing`
          pictureurl = `sap/ui/demo/mock/images/HT-1101.jpg` price = `79.9` currencycode = `EUR` status = `O`
          weight = `0.8` weightunit = `KG` dimensionwidth = `14` dimensiondepth = `6.7` dimensionheight = `24` dimensionunit = `cm` )
        ( productid = `HT-1102` name = `Smart Network` category = `SW` suppliername = `Technocom`
          shortdescription = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`
          pictureurl = `sap/ui/demo/mock/images/HT-1102.jpg` price = `69` currencycode = `EUR` status = `A`
          weight = `0.8` weightunit = `KG` dimensionwidth = `16` dimensiondepth = `6` dimensionheight = `27` dimensionunit = `cm` )
        ( productid = `HT-1103` name = `Smart Multimedia` category = `SW` suppliername = `Technocom`
          shortdescription = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`
          pictureurl = `sap/ui/demo/mock/images/HT-1103.jpg` price = `77` currencycode = `EUR` status = `A`
          weight = `0.8` weightunit = `KG` dimensionwidth = `11` dimensiondepth = `3.4` dimensionheight = `22` dimensionunit = `cm` )
        ( productid = `HT-1104` name = `Smart Games` category = `SW` suppliername = `Technocom`
          shortdescription = `Complete package, 1 User, various games for amusement, logic, action, jump&run`
          pictureurl = `sap/ui/demo/mock/images/HT-1104.jpg` price = `55` currencycode = `EUR` status = `O`
          weight = `1.1` weightunit = `KG` dimensionwidth = `10` dimensiondepth = `3` dimensionheight = `30` dimensionunit = `cm` )
        ( productid = `HT-1105` name = `Smart Internet Antivirus` category = `SW` suppliername = `Brainsoft`
          shortdescription = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`
          pictureurl = `sap/ui/demo/mock/images/HT-1105.jpg` price = `29` currencycode = `EUR` status = `A`
          weight = `0.7` weightunit = `KG` dimensionwidth = `16` dimensiondepth = `4` dimensionheight = `21` dimensionunit = `cm` )
        ( productid = `HT-1106` name = `Smart Firewall` category = `SW` suppliername = `Brainsoft`
          shortdescription = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`
          pictureurl = `sap/ui/demo/mock/images/HT-1106.jpg` price = `34` currencycode = `EUR` status = `A`
          weight = `0.9` weightunit = `KG` dimensionwidth = `17.9` dimensiondepth = `4.2` dimensionheight = `23.1` dimensionunit = `cm` )
        ( productid = `HT-1107` name = `Smart Money` category = `SW` suppliername = `Brainsoft`
          shortdescription = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`
          pictureurl = `sap/ui/demo/mock/images/HT-1107.jpg` price = `29.9` currencycode = `EUR` status = `D`
          weight = `0.5` weightunit = `KG` dimensionwidth = `12` dimensiondepth = `1.5` dimensionheight = `19` dimensionunit = `cm` )
        ( productid = `HT-1110` name = `PC Lock` category = `CSA` suppliername = `Red Point Stores`
          shortdescription = `Robust 3m anti-burglary protection for your laptop computer`
          pictureurl = `sap/ui/demo/mock/images/HT-1110.jpg` price = `8.9` currencycode = `EUR` status = `A`
          weight = `0.03` weightunit = `KG` dimensionwidth = `20` dimensiondepth = `8` dimensionheight = `4.3` dimensionunit = `cm` )
        ( productid = `HT-1111` name = `Notebook Lock` category = `CSA` suppliername = `Red Point Stores`
          shortdescription = `Robust 1m anti-burglary protection for your desktop computer`
          pictureurl = `sap/ui/demo/mock/images/HT-1111.jpg` price = `6.9` currencycode = `EUR` status = `A`
          weight = `0.02` weightunit = `KG` dimensionwidth = `31` dimensiondepth = `9` dimensionheight = `7` dimensionunit = `cm` )
        ( productid = `HT-1112` name = `Web cam reality` category = `CSA` suppliername = `Red Point Stores`
          shortdescription = `Color webcam, color, High-Speed USB`
          pictureurl = `sap/ui/demo/mock/images/HT-1112.jpg` price = `39` currencycode = `EUR` status = `A`
          weight = `0.075` weightunit = `KG` dimensionwidth = `9` dimensiondepth = `8.2` dimensionheight = `1.3` dimensionunit = `cm` )
        ( productid = `HT-1113` name = `Screen clean` category = `CSA` suppliername = `Red Point Stores`
          shortdescription = `10 separately packed screen wipes`
          pictureurl = `sap/ui/demo/mock/images/HT-1113.jpg` price = `2.3` currencycode = `EUR` status = `A`
          weight = `0.05` weightunit = `KG` dimensionwidth = `2` dimensiondepth = `2` dimensionheight = `0.1` dimensionunit = `cm` )
        ( productid = `HT-1114` name = `Fabric bag professional` category = `CSA` suppliername = `Red Point Stores`
          shortdescription = `Notebook bag, plenty of room for stationery and writing materials`
          pictureurl = `sap/ui/demo/mock/images/HT-1114.jpg` price = `31` currencycode = `EUR` status = `A`
          weight = `1.8` weightunit = `KG` dimensionwidth = `42` dimensiondepth = `32` dimensionheight = `7` dimensionunit = `cm` )
        ( productid = `HT-1115` name = `Wireless DSL Router` category = `TC` suppliername = `Red Point Stores`
          shortdescription = `Wireless DSL Router (available in blue, black and silver)`
          pictureurl = `sap/ui/demo/mock/images/HT-1115.jpg` price = `49` currencycode = `EUR` status = `O`
          weight = `0.45` weightunit = `KG` dimensionwidth = `19.3` dimensiondepth = `18` dimensionheight = `5` dimensionunit = `cm` )
        ( productid = `HT-1116` name = `Wireless DSL Router / Repeater` category = `TC` suppliername = `Red Point Stores`
          shortdescription = `Wireless DSL Router / Repeater (available in blue, black and silver)`
          pictureurl = `sap/ui/demo/mock/images/HT-1116.jpg` price = `59` currencycode = `EUR` status = `A`
          weight = `0.45` weightunit = `KG` dimensionwidth = `19.3` dimensiondepth = `18` dimensionheight = `5` dimensionunit = `cm` )
        ( productid = `HT-1117` name = `Wireless DSL Router / Repeater and Print Server` category = `TC` suppliername = `Technocom`
          shortdescription = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`
          pictureurl = `sap/ui/demo/mock/images/HT-1117.jpg` price = `69` currencycode = `EUR` status = `O`
          weight = `0.45` weightunit = `KG` dimensionwidth = `19.3` dimensiondepth = `18` dimensionheight = `5` dimensionunit = `cm` )
        ( productid = `HT-1118` name = `USB Stick` category = `CSA` suppliername = `Technocom`
          shortdescription = `USB 2.0 High-Speed 64 GB`
          pictureurl = `sap/ui/demo/mock/images/HT-1118.jpg` price = `35` currencycode = `EUR` status = `A`
          weight = `0.015` weightunit = `KG` dimensionwidth = `1.5` dimensiondepth = `8.7` dimensionheight = `1.2` dimensionunit = `cm` )
        ( productid = `HT-1120` name = `Cordless Bluetooth Keyboard, english international` category = `KB` suppliername = `Technocom`
          shortdescription = `Cordless Bluetooth Keyboard with English keys`
          pictureurl = `sap/ui/demo/mock/images/HT-1120.jpg` price = `29` currencycode = `EUR` status = `A`
          weight = `1` weightunit = `KG` dimensionwidth = `51.4` dimensiondepth = `23` dimensionheight = `4` dimensionunit = `cm` )
        ( productid = `HT-1137` name = `Flat XXL` category = `FS` suppliername = `Technocom`
          shortdescription = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`
          pictureurl = `sap/ui/demo/mock/images/HT-1137.jpg` price = `1430` currencycode = `EUR` status = `A`
          weight = `18` weightunit = `KG` dimensionwidth = `54` dimensiondepth = `22` dimensionheight = `38` dimensionunit = `cm` )
        ( productid = `HT-1138` name = `Pocket Mouse` category = `MI` suppliername = `Technocom`
          shortdescription = `Portable pocket Mouse with retracting cord`
          pictureurl = `sap/ui/demo/mock/images/HT-1138.jpg` price = `23` currencycode = `EUR` status = `A`
          weight = `0.02` weightunit = `KG` dimensionwidth = `0.3` dimensiondepth = `0.5` dimensionheight = `1` dimensionunit = `cm` )
        ( productid = `HT-1210` name = `PC Power Station` category = `DC` suppliername = `Technocom`
          shortdescription = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like a PC, Windows 8 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1210.jpg` price = `2399` currencycode = `EUR` status = `A`
          weight = `2.3` weightunit = `KG` dimensionwidth = `28` dimensiondepth = `31` dimensionheight = `43` dimensionunit = `cm` )
        ( productid = `HT-1500` name = `Server Basic` category = `SV` suppliername = `Technocom`
          shortdescription = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`
          pictureurl = `sap/ui/demo/mock/images/HT-1500.jpg` price = `5000` currencycode = `EUR` status = `A`
          weight = `18` weightunit = `KG` dimensionwidth = `34` dimensiondepth = `35` dimensionheight = `23` dimensionunit = `cm` )
        ( productid = `HT-1501` name = `Server Professional` category = `SV` suppliername = `Technocom`
          shortdescription = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`
          pictureurl = `sap/ui/demo/mock/images/HT-1501.jpg` price = `15000` currencycode = `EUR` status = `O`
          weight = `25` weightunit = `KG` dimensionwidth = `29` dimensiondepth = `30` dimensionheight = `27` dimensionunit = `cm` )
        ( productid = `HT-1502` name = `Server Power Pro` category = `SV` suppliername = `Technocom`
          shortdescription = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`
          pictureurl = `sap/ui/demo/mock/images/HT-1502.jpg` price = `25000` currencycode = `EUR` status = `A`
          weight = `35` weightunit = `KG` dimensionwidth = `22` dimensiondepth = `27.3` dimensionheight = `37` dimensionunit = `cm` )
        ( productid = `HT-6130` name = `Flat Watch HD32` category = `FST` suppliername = `Very Best Screens`
          shortdescription = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`
          pictureurl = `sap/ui/demo/mock/images/HT-6130.jpg` price = `1459` currencycode = `EUR` status = `A`
          weight = `2.6` weightunit = `KG` dimensionwidth = `78` dimensiondepth = `22.1` dimensionheight = `55` dimensionunit = `cm` )
        ( productid = `HT-6131` name = `Flat Watch HD37` category = `FST` suppliername = `Very Best Screens`
          shortdescription = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`
          pictureurl = `sap/ui/demo/mock/images/HT-6131.jpg` price = `1199` currencycode = `EUR` status = `A`
          weight = `2.2` weightunit = `KG` dimensionwidth = `99.1` dimensiondepth = `26` dimensionheight = `61` dimensionunit = `cm` )
        ( productid = `HT-6132` name = `Flat Watch HD41` category = `FST` suppliername = `Very Best Screens`
          shortdescription = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`
          pictureurl = `sap/ui/demo/mock/images/HT-6132.jpg` price = `899` currencycode = `EUR` status = `A`
          weight = `1.8` weightunit = `KG` dimensionwidth = `128` dimensiondepth = `23` dimensionheight = `79.1` dimensionunit = `cm` )
        ( productid = `HT-7030` name = `Platinberry` category = `AC` suppliername = `Fasttech`
          shortdescription = `Our new multifunctional Handheld with phone function in platinum`
          pictureurl = `sap/ui/demo/mock/images/HT-7030.jpg` price = `549` currencycode = `EUR` status = `D`
          weight = `0.5` weightunit = `KG` dimensionwidth = `8.1` dimensiondepth = `13` dimensionheight = `12.1` dimensionunit = `cm` )
        ( productid = `HT-7020` name = `Goldberry` category = `AC` suppliername = `Fasttech`
          shortdescription = `Our new multifunctional Handheld with phone function in gold`
          pictureurl = `sap/ui/demo/mock/images/HT-7020.jpg` price = `549` currencycode = `EUR` status = `A`
          weight = `0.5` weightunit = `KG` dimensionwidth = `8.1` dimensiondepth = `13` dimensionheight = `12.1` dimensionunit = `cm` )
        ( productid = `HT-7010` name = `Silverberry` category = `AC` suppliername = `Fasttech`
          shortdescription = `Our new multifunctional Handheld with phone function in silver`
          pictureurl = `sap/ui/demo/mock/images/HT-7010.jpg` price = `549` currencycode = `EUR` status = `A`
          weight = `0.5` weightunit = `KG` dimensionwidth = `8.1` dimensiondepth = `13` dimensionheight = `12.1` dimensionunit = `cm` )
        ( productid = `HT-7000` name = `Copperberry` category = `AC` suppliername = `Fasttech`
          shortdescription = `Our new multifunctional Handheld with phone function in copper`
          pictureurl = `sap/ui/demo/mock/images/HT-7000.jpg` price = `549` currencycode = `EUR` status = `A`
          weight = `0.5` weightunit = `KG` dimensionwidth = `8.1` dimensiondepth = `13` dimensionheight = `12.1` dimensionunit = `cm` )
        ( productid = `HT-1095` name = `Lovely Sound 5.1 Wireless` category = `AC` suppliername = `Fasttech`
          shortdescription = `5.1 Headset, 40 Hz-20 kHz, Wireless`
          pictureurl = `sap/ui/demo/mock/images/HT-1095.jpg` price = `49` currencycode = `EUR` status = `A`
          weight = `80` weightunit = `G` dimensionwidth = `24` dimensiondepth = `19` dimensionheight = `23` dimensionunit = `cm` )
        ( productid = `HT-1096` name = `Lovely Sound 5.1` category = `AC` suppliername = `Fasttech`
          shortdescription = `5.1 Headset, 40 Hz-20 kHz, 3m cable`
          pictureurl = `sap/ui/demo/mock/images/HT-1096.jpg` price = `39` currencycode = `EUR` status = `A`
          weight = `130` weightunit = `G` dimensionwidth = `25` dimensiondepth = `17` dimensionheight = `19` dimensionunit = `cm` )
        ( productid = `HT-1097` name = `Lovely Sound Stereo` category = `AC` suppliername = `Fasttech`
          shortdescription = `5.1 Headset, 40 Hz-20 kHz, 1m cable`
          pictureurl = `sap/ui/demo/mock/images/HT-1097.jpg` price = `29` currencycode = `EUR` status = `A`
          weight = `60` weightunit = `G` dimensionwidth = `21.3` dimensiondepth = `2.4` dimensionheight = `19.7` dimensionunit = `cm` )
        ( productid = `HT-6123` name = `Power Pro Player 80` category = `AC` suppliername = `Fasttech`
          shortdescription = `MP3-Player with 80 GB SSD and Color Display, can play movies`
          pictureurl = `sap/ui/demo/mock/images/HT-6123.jpg` price = `299` currencycode = `EUR` status = `A`
          weight = `267` weightunit = `G` dimensionwidth = `4` dimensiondepth = `6` dimensionheight = `0.8` dimensionunit = `cm` )
        ( productid = `HT-6122` name = `Power Pro Player 40` category = `AC` suppliername = `Fasttech`
          shortdescription = `MP3-Player with 40 GB HDD and Color Display, can play movies`
          pictureurl = `sap/ui/demo/mock/images/HT-6122.jpg` price = `167` currencycode = `EUR` status = `A`
          weight = `266` weightunit = `G` dimensionwidth = `5.1` dimensiondepth = `8` dimensionheight = `9.2` dimensionunit = `cm` )
        ( productid = `HT-6121` name = `ITelo Jog-Mate` category = `AC` suppliername = `Fasttech`
          shortdescription = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`
          pictureurl = `sap/ui/demo/mock/images/HT-6121.jpg` price = `63` currencycode = `EUR` status = `A`
          weight = `134` weightunit = `G` dimensionwidth = `5.1` dimensiondepth = `8` dimensionheight = `9.2` dimensionunit = `cm` )
        ( productid = `HT-6120` name = `ITelo MusicStick` category = `AC` suppliername = `Fasttech`
          shortdescription = `64 GB USB Music-on-a-Stick`
          pictureurl = `sap/ui/demo/mock/images/HT-6120.jpg` price = `45` currencycode = `EUR` status = `A`
          weight = `134` weightunit = `G` dimensionwidth = `1.5` dimensiondepth = `6` dimensionheight = `1` dimensionunit = `cm` )
        ( productid = `HT-6111` name = `Record Movie` category = `AC` suppliername = `Fasttech`
          shortdescription = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`
          pictureurl = `sap/ui/demo/mock/images/HT-6111.jpg` price = `288` currencycode = `EUR` status = `O`
          weight = `3.1` weightunit = `KG` dimensionwidth = `38` dimensiondepth = `26` dimensionheight = `6.2` dimensionunit = `cm` )
        ( productid = `HT-6110` name = `Play Movie` category = `AC` suppliername = `Fasttech`
          shortdescription = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`
          pictureurl = `sap/ui/demo/mock/images/HT-6110.jpg` price = `130` currencycode = `EUR` status = `O`
          weight = `2.4` weightunit = `KG` dimensionwidth = `37` dimensiondepth = `24` dimensionheight = `6` dimensionunit = `cm` )
        ( productid = `HT-6102` name = `Beam Breaker B-3` category = `AC` suppliername = `Technocom`
          shortdescription = `1080p, DLP max. 12,3 Meter, 3D-ready`
          pictureurl = `sap/ui/demo/mock/images/HT-6102.jpg` price = `889` currencycode = `EUR` status = `A`
          weight = `2.5` weightunit = `KG` dimensionwidth = `30.4` dimensiondepth = `23.1` dimensionheight = `23` dimensionunit = `cm` )
        ( productid = `HT-6101` name = `Beam Breaker B-2` category = `AC` suppliername = `Technocom`
          shortdescription = `1080p, DLP max.9,34 Meter, 2D-ready`
          pictureurl = `sap/ui/demo/mock/images/HT-6101.jpg` price = `679` currencycode = `EUR` status = `A`
          weight = `2` weightunit = `KG` dimensionwidth = `30.4` dimensiondepth = `23.1` dimensionheight = `23` dimensionunit = `cm` )
        ( productid = `HT-2002` name = `Portable DVD Player with 9" LCD Monitor` category = `AC` suppliername = `Technocom`
          shortdescription = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`
          pictureurl = `sap/ui/demo/mock/images/HT-2002.jpg` price = `853.99` currencycode = `EUR` status = `D`
          weight = `0.72` weightunit = `KG` dimensionwidth = `21` dimensiondepth = `16.5` dimensionheight = `14` dimensionunit = `cm` )
        ( productid = `HT-6100` name = `Beam Breaker B-1` category = `AC` suppliername = `Titanium`
          shortdescription = `720p, DLP Projector max. 8,45 Meter, 2D`
          pictureurl = `sap/ui/demo/mock/images/HT-6100.jpg` price = `469` currencycode = `EUR` status = `O`
          weight = `1.7` weightunit = `KG` dimensionwidth = `30.4` dimensiondepth = `23.1` dimensionheight = `23` dimensionunit = `cm` )
        ( productid = `HT-2027` name = `Removable CD/DVD Laser Labels` category = `AC` suppliername = `Titanium`
          shortdescription = `Removable jewel case labels, zero residues (100)`
          pictureurl = `sap/ui/demo/mock/images/HT-2027.jpg` price = `8.99` currencycode = `EUR` status = `A`
          weight = `0.15` weightunit = `KG` dimensionwidth = `5.5` dimensiondepth = `2` dimensionheight = `2` dimensionunit = `cm` )
        ( productid = `HT-2026` name = `Audio/Video Cable Kit - 4m` category = `AC` suppliername = `Titanium`
          shortdescription = `Quality cables for notebooks and projectors`
          pictureurl = `sap/ui/demo/mock/images/HT-2026.jpg` price = `29.99` currencycode = `EUR` status = `D`
          weight = `0.2` weightunit = `KG` dimensionwidth = `21` dimensiondepth = `10.2` dimensionheight = `13` dimensionunit = `cm` )
        ( productid = `HT-2025` name = `CD/DVD case: 264 sleeves` category = `AC` suppliername = `Titanium`
          shortdescription = `Organizer and protective case for 264 CDs and DVDs`
          pictureurl = `sap/ui/demo/mock/images/HT-2025.jpg` price = `44.99` currencycode = `EUR` status = `A`
          weight = `0.65` weightunit = `KG` dimensionwidth = `13` dimensiondepth = `13` dimensionheight = `20` dimensionunit = `cm` )
        ( productid = `HT-2001` name = `10" Portable DVD player` category = `AC` suppliername = `Titanium`
          shortdescription = `10" LCD Screen, storage battery holds up to 8 hours`
          pictureurl = `sap/ui/demo/mock/images/HT-2001.jpg` price = `449.99` currencycode = `EUR` status = `A`
          weight = `0.84` weightunit = `KG` dimensionwidth = `24` dimensiondepth = `19.5` dimensionheight = `29` dimensionunit = `cm` )
        ( productid = `HT-2000` name = `7" Widescreen Portable DVD Player w MP3` category = `AC` suppliername = `Titanium`
          shortdescription = `7" LCD Screen, storage battery holds up to 6 hours!`
          pictureurl = `sap/ui/demo/mock/images/HT-2000.jpg` price = `249.99` currencycode = `EUR` status = `O`
          weight = `0.79` weightunit = `KG` dimensionwidth = `21.4` dimensiondepth = `19` dimensionheight = `27.6` dimensionunit = `cm` )
        ( productid = `HT-1603` name = `Gaming Monster Pro` category = `DC` suppliername = `Titanium`
          shortdescription = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`
          pictureurl = `sap/ui/demo/mock/images/HT-1603.jpg` price = `1700` currencycode = `EUR` status = `A`
          weight = `6.8` weightunit = `KG` dimensionwidth = `27` dimensiondepth = `28` dimensionheight = `42` dimensionunit = `cm` )
        ( productid = `HT-1602` name = `Gaming Monster` category = `DC` suppliername = `Titanium`
          shortdescription = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`
          pictureurl = `sap/ui/demo/mock/images/HT-1602.jpg` price = `1200` currencycode = `EUR` status = `A`
          weight = `5.9` weightunit = `KG` dimensionwidth = `26.5` dimensiondepth = `34` dimensionheight = `47` dimensionunit = `cm` )
        ( productid = `HT-1601` name = `Family PC Pro` category = `DC` suppliername = `Titanium`
          shortdescription = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`
          pictureurl = `sap/ui/demo/mock/images/HT-1601.jpg` price = `900` currencycode = `EUR` status = `A`
          weight = `5.3` weightunit = `KG` dimensionwidth = `25` dimensiondepth = `31.7` dimensionheight = `40.2` dimensionunit = `cm` )
        ( productid = `HT-1600` name = `Family PC Basic` category = `DC` suppliername = `Titanium`
          shortdescription = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`
          pictureurl = `sap/ui/demo/mock/images/HT-1600.jpg` price = `600` currencycode = `EUR` status = `O`
          weight = `4.8` weightunit = `KG` dimensionwidth = `21.4` dimensiondepth = `29` dimensionheight = `38` dimensionunit = `cm` )
        ( productid = `HT-1119` name = `Travel Adapter` category = `AC` suppliername = `Titanium`
          shortdescription = `Universal Travel Adapter`
          pictureurl = `sap/ui/demo/mock/images/HT-1119.jpg` price = `79` currencycode = `EUR` status = `A`
          weight = `88` weightunit = `G` dimensionwidth = `2` dimensiondepth = `3.1` dimensionheight = `3.9` dimensionunit = `cm` )
        ( productid = `HT-8000` name = `ITelO FlexTop I4000` category = `LT` suppliername = `Titanium`
          shortdescription = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`
          pictureurl = `sap/ui/demo/mock/images/HT-8000.jpg` price = `799` currencycode = `EUR` status = `A`
          weight = `4` weightunit = `KG` dimensionwidth = `31` dimensiondepth = `19` dimensionheight = `3.1` dimensionunit = `cm` )
        ( productid = `HT-8001` name = `ITelO FlexTop I6300c` category = `LT` suppliername = `Titanium`
          shortdescription = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`
          pictureurl = `sap/ui/demo/mock/images/HT-8001.jpg` price = `799` currencycode = `EUR` status = `A`
          weight = `4.2` weightunit = `KG` dimensionwidth = `32` dimensiondepth = `20` dimensionheight = `3.4` dimensionunit = `cm` )
        ( productid = `HT-8002` name = `ITelO FlexTop I9100` category = `LT` suppliername = `Titanium`
          shortdescription = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`
          pictureurl = `sap/ui/demo/mock/images/HT-8002.jpg` price = `1199` currencycode = `EUR` status = `A`
          weight = `3.5` weightunit = `KG` dimensionwidth = `38` dimensiondepth = `21` dimensionheight = `4.1` dimensionunit = `cm` )
        ( productid = `HT-8003` name = `ITelO FlexTop I9800` category = `LT` suppliername = `Titanium`
          shortdescription = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`
          pictureurl = `sap/ui/demo/mock/images/HT-8003.jpg` price = `1388` currencycode = `EUR` status = `A`
          weight = `3.8` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `PF-1000` name = `Flyer` category = `AC` suppliername = `Titanium`
          shortdescription = `Flyer for our product palette`
          pictureurl = `sap/ui/demo/mock/images/PF-1000.jpg` price = `0` currencycode = `EUR` status = `A`
          weight = `0.01` weightunit = `KG` dimensionwidth = `46` dimensiondepth = `30` dimensionheight = `3` dimensionunit = `cm` )
        ( productid = `HT-9999` name = `Maxi Tablet` category = `ST` suppliername = `Titanium`
          shortdescription = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`
          pictureurl = `sap/ui/demo/mock/images/HT-9999.jpg` price = `749` currencycode = `EUR` status = `A`
          weight = `3.8` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-9998` name = `Smartphone Beta` category = `ST` suppliername = `Titanium`
          shortdescription = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS A-GPS support`
          pictureurl = `sap/ui/demo/mock/images/HT-9998.jpg` price = `699` currencycode = `EUR` status = `A`
          weight = `0.75` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-9997` name = `e-Book Reader ReadMe` category = `ST` suppliername = `Titanium`
          shortdescription = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`
          pictureurl = `sap/ui/demo/mock/images/HT-9997.jpg` price = `633` currencycode = `EUR` status = `A`
          weight = `3.8` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-9996` name = `Tablet Pouch` category = `AC` suppliername = `Titanium`
          shortdescription = `Stylish tablet pouch, protects from scratches, color: black`
          pictureurl = `sap/ui/demo/mock/images/HT-9996.jpg` price = `20` currencycode = `EUR` status = `A`
          weight = `0.03` weightunit = `KG` dimensionwidth = `25` dimensiondepth = `40` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-9995` name = `Smartphone Cover` category = `AC` suppliername = `Titanium`
          shortdescription = `Durable high quality plastic bump-sleeve, lightweight, protects from scratches, rubber coating, multiple colors available, Accurate design and cut-outs for your device, snap-on design`
          pictureurl = `sap/ui/demo/mock/images/HT-9995.jpg` price = `15` currencycode = `EUR` status = `A`
          weight = `0.02` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-9994` name = `Camcorder View` category = `AC` suppliername = `Ultrasonic United`
          shortdescription = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`
          pictureurl = `sap/ui/demo/mock/images/HT-9994.jpg` price = `1388` currencycode = `EUR` status = `A`
          weight = `3.8` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `27` dimensionunit = `cm` )
        ( productid = `HT-9993` name = `Mini Tablet` category = `ST` suppliername = `Ultrasonic United`
          shortdescription = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`
          pictureurl = `sap/ui/demo/mock/images/HT-9993.jpg` price = `833` currencycode = `EUR` status = `A`
          weight = `3.8` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-9992` name = `Smartphone Alpha` category = `ST` suppliername = `Ultrasonic United`
          shortdescription = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`
          pictureurl = `sap/ui/demo/mock/images/HT-9992.jpg` price = `599` currencycode = `EUR` status = `A`
          weight = `0.75` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-9991` name = `Smartphone Leather Case` category = `AC` suppliername = `Ultrasonic United`
          shortdescription = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`
          pictureurl = `sap/ui/demo/mock/images/HT-9991.jpg` price = `25` currencycode = `EUR` status = `A`
          weight = `0.02` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-1251` name = `Astro Laptop 1516` category = `LT` suppliername = `Ultrasonic United`
          shortdescription = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1251.jpg` price = `989` currencycode = `EUR` status = `A`
          weight = `4.2` weightunit = `KG` dimensionwidth = `30` dimensiondepth = `18` dimensionheight = `3` dimensionunit = `cm` )
        ( productid = `HT-1252` name = `Astro Phone 6` category = `ST` suppliername = `Ultrasonic United`
          shortdescription = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`
          pictureurl = `sap/ui/demo/mock/images/HT-1252.jpg` price = `649` currencycode = `EUR` status = `A`
          weight = `0.75` weightunit = `KG` dimensionwidth = `8` dimensiondepth = `6` dimensionheight = `1.5` dimensionunit = `cm` )
        ( productid = `HT-1253` name = `Benda Laptop 1408` category = `LT` suppliername = `Ultrasonic United`
          shortdescription = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`
          pictureurl = `sap/ui/demo/mock/images/HT-1253.jpg` price = `976` currencycode = `EUR` status = `A`
          weight = `4.2` weightunit = `KG` dimensionwidth = `30` dimensiondepth = `18` dimensionheight = `3` dimensionunit = `cm` )
        ( productid = `HT-1254` name = `Bending Screen 21HD` category = `FS` suppliername = `Ultrasonic United`
          shortdescription = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, D-Sub`
          pictureurl = `sap/ui/demo/mock/images/HT-1254.jpg` price = `250` currencycode = `EUR` status = `A`
          weight = `15` weightunit = `KG` dimensionwidth = `37` dimensiondepth = `12` dimensionheight = `36` dimensionunit = `cm` )
        ( productid = `HT-1255` name = `Broad Screen 22HD` category = `FS` suppliername = `Ultrasonic United`
          shortdescription = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, D-Sub`
          pictureurl = `sap/ui/demo/mock/images/HT-1255.jpg` price = `270` currencycode = `EUR` status = `O`
          weight = `16` weightunit = `KG` dimensionwidth = `39` dimensiondepth = `12` dimensionheight = `38` dimensionunit = `cm` )
        ( productid = `HT-1256` name = `Cerdik Phone 7` category = `ST` suppliername = `Ultrasonic United`
          shortdescription = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`
          pictureurl = `sap/ui/demo/mock/images/HT-1256.jpg` price = `549` currencycode = `EUR` status = `A`
          weight = `0.75` weightunit = `KG` dimensionwidth = `9` dimensiondepth = `15` dimensionheight = `1.5` dimensionunit = `cm` )
        ( productid = `HT-1257` name = `Cepat Tablet 10.5` category = `ST` suppliername = `Ultrasonic United`
          shortdescription = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`
          pictureurl = `sap/ui/demo/mock/images/HT-1257.jpg` price = `549` currencycode = `EUR` status = `A`
          weight = `2.8` weightunit = `KG` dimensionwidth = `48` dimensiondepth = `31` dimensionheight = `4.5` dimensionunit = `cm` )
        ( productid = `HT-1258` name = `Cepat Tablet 8` category = `ST` suppliername = `Ultrasonic United`
          shortdescription = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`
          pictureurl = `sap/ui/demo/mock/images/HT-1258.jpg` price = `529` currencycode = `EUR` status = `A`
          weight = `2.5` weightunit = `KG` dimensionwidth = `38` dimensiondepth = `21` dimensionheight = `3.5` dimensionunit = `cm` )
    ).

    LOOP AT t_featured INTO DATA(featured).
      ASSIGN t_all[ productid = featured-productid ] TO FIELD-SYMBOL(<product>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      CASE featured-type.
        WHEN `Promoted`.
          INSERT row_of( <product> ) INTO TABLE t_promoted.
        WHEN `Viewed`.
          INSERT row_of( <product> ) INTO TABLE t_viewed.
        WHEN OTHERS.
          INSERT row_of( <product> ) INTO TABLE t_favorite.
      ENDCASE.
    ENDLOOP.

    layout = `TwoColumnsMidExpanded`.

    " the original's LocalStorageModel("SHOPPING_CART", ...) - same storage,
    " same key
    s_storage-type = `local`.
    s_storage-key  = `SHOPPING_CART`.

    cart_refresh( ).

  ENDMETHOD.

ENDCLASS.
