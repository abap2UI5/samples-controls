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
"!    STORE_DATA frontend action writes - with a payload this class composes
"!    as JSON, because that action destructures its one argument and a
"!    `${ _bind( ) }` in it is resolved only for a VIEW-WIRED action, so the
"!    binding a handler passes arrives as text and the frontend deletes the
"!    key instead of writing it - and the invisible z2ui5.cc.Storage
"!    control reads the key back into its two-way bound `value`, so what it
"!    found is in s_storage-value by the time the `finished` event is
"!    handled - no JSON is parsed anywhere in this class. So a closed
"!    browser loses nothing here either - and the backend still sees the
"!    cart on every round-trip, which is where a price, a reservation or an
"!    order would be decided. Only a round-trip that CHANGED the cart writes
"!    (cart_refresh); startup and the restore mirror the tables into the
"!    bound structure without writing (cart_mirror), and the read wire
"!    carries check_queue_last - the two halves of the restart that did not
"!    survive until 2026-09-14.
"!  - the formatter module is business logic and moves to the backend: the
"!    price format, the status text and its ValueState, the cart total.
"!  - search and category filtering run in ABAP, where the data is.
"!  - the Welcome page keeps its three panels (promoted, recently viewed,
"!    favorites) but not the original's BlockLayout-and-Grid arrangement of
"!    them: one list per panel instead of a hand-built cell per product.
"!    Its carousel is dropped with the four teaser images it shows. The
"!    Emphasized cart-3 button the original puts on every tile stays, as an
"!    ACTIVE ObjectStatus in the row's secondStatus - an ObjectListItem takes
"!    no button, and without it the welcome page had no way to fill the cart
"!    at all. ObjectStatus rather than the ACTIVE ObjectAttribute this was
"!    until 2026-09-14: an ObjectAttribute carries no icon, so the original's
"!    cart-3 was missing from every row - and the favorites panel had no
"!    add-to-cart at all, where the original has it on all three sections.
"!  - the wizard validates in ABAP rather than through the Wizard's own
"!    validated/setNextStep API, and reports with a MessageBox - which is
"!    what the original's own validation does for the credit-card step.
"!  - the i18n resource bundle becomes literals, the device model's
"!    smallScreenMode branches are gone (the FCL does that itself now), and
"!    the LightBox on the product picture is dropped.
"!  - the cart's Edit mode is not rebuilt: the original toggles the two lists
"!    into Delete mode with an Edit/Save Changes button and confirms every
"!    removal with a dialog. Here Save for Later and Remove are row links, so
"!    the same two actions are reachable without a mode.
"!  - the review page is one page with the summary on it, not the original's
"!    per-section forms each with an edit button back into its wizard step.
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
    TYPES ty_t_entry TYPE STANDARD TABLE OF ty_s_entry WITH DEFAULT KEY.

    TYPES temp1_a91376a05f TYPE STANDARD TABLE OF ty_s_category WITH DEFAULT KEY.
DATA t_categories   TYPE temp1_a91376a05f.
    TYPES temp2_a91376a05f TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA t_search       TYPE temp2_a91376a05f.
    TYPES temp3_a91376a05f TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA t_category     TYPE temp3_a91376a05f.
    TYPES temp4_a91376a05f TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA t_promoted     TYPE temp4_a91376a05f.
    TYPES temp5_a91376a05f TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA t_viewed       TYPE temp5_a91376a05f.
    TYPES temp6_a91376a05f TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA t_favorite     TYPE temp6_a91376a05f.
    TYPES:
      BEGIN OF ty_s_store,
        cart  TYPE ty_t_entry,
        saved TYPE ty_t_entry,
      END OF ty_s_store.
    TYPES:
      BEGIN OF ty_s_storage,
        type   TYPE string,
        prefix TYPE string,
        key    TYPE string,
        value  TYPE ty_s_store,
      END OF ty_s_storage.

    DATA t_cart         TYPE ty_t_entry.
    DATA t_saved        TYPE ty_t_entry.
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
    " the payment type as the summary shows it. pay_type carries the wizard
    " STEP the branch jumps to, which is this port's mechanism and not a text
    " the user should read
    DATA pay_name       TYPE string.
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
    TYPES temp7_a91376a05f TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_all         TYPE temp7_a91376a05f.
    TYPES temp8_a91376a05f TYPE STANDARD TABLE OF ty_s_featured WITH DEFAULT KEY.
DATA t_featured    TYPE temp8_a91376a05f.
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
    METHODS search_refresh.
    METHODS cart_refresh.
    METHODS storage_json
      RETURNING
        VALUE(result) TYPE string.
    METHODS entries_json
      IMPORTING
        entries       TYPE ty_t_entry
      RETURNING
        VALUE(result) TYPE string.
    METHODS json_escape
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS cart_mirror.
    METHODS cart_restore.
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

    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    " the chain hangs off the factory( ), so `view` holds the mvc:View and the
    " statements below add INTO it (view-chain-layout)
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE z2ui5_if_client=>ty_s_event_control.
    DATA fcl TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA nav_begin TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA nav_mid TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA nav_end TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp2 TYPE string_table.
    DATA temp4 TYPE string_table.
    DATA temp3 TYPE string.
    view = z2ui5_cl_ui5_view_builder=>factory(
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
    
    CLEAR temp1.
    temp1-check_queue_last = abap_true.
    view->tag( n = `Storage` ns = `z2ui5`
        )->a( n = `type`     v = client->_bind( s_storage-type )
        )->a( n = `prefix`   v = client->_bind( s_storage-prefix )
        )->a( n = `key`      v = client->_bind( s_storage-key )
        )->a( n = `value`    v = client->_bind( s_storage-value )
        )->a( n = `finished` v = client->_event( val    = `CART_LOADED`
                                                 " no arg: the value is BOUND, so it arrives in
                                                 " s_storage-value with this event and the handler
                                                 " reads it there (cart_restore). An event argument
                                                 " would hand the same payload over a second time,
                                                 " as JSON the app would then have to parse.
                                                 "
                                                 " the control reads and fires while the INITIAL view
                                                 " renders - i.e. while that very roundtrip still counts
                                                 " as in flight, which drops an ordinary wire's event
                                                 " (View1.eB busy guard) and with it the whole restore.
                                                 " check_queue_last keeps it and dispatches it once the
                                                 " response has landed
                                                 s_ctrl = temp1 ) ).

    
    fcl = view->ele( `App`
        )->a( n = `id` v = `app`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`               v = `layout`
            )->a( n = `layout`           v = client->_bind( layout )
            )->a( n = `backgroundDesign` v = `Translucent` ).

    
    nav_begin = fcl->ele( n = `beginColumnPages` ns = `f`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav-begin` ).
    page_home( nav_begin ).
    page_category( nav_begin ).

    
    nav_mid = fcl->ele( n = `midColumnPages` ns = `f`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav-mid` ).
    page_welcome( nav_mid ).
    page_product( nav_mid ).

    
    nav_end = fcl->ele( n = `endColumnPages` ns = `f`
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
      
      CLEAR temp2.
      INSERT `paymentTypeStep` INTO TABLE temp2.
      INSERT `setNextStep` INTO TABLE temp2.
      INSERT pay_type INTO TABLE temp2.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = temp2 ).
    ENDIF.
    
    CLEAR temp4.
    INSERT `invoiceAddressStep` INTO TABLE temp4.
    INSERT `setNextStep` INTO TABLE temp4.
    
    IF del_different = abap_true.
      temp3 = `deliveryAddressStep`.
    ELSE.
      temp3 = `deliveryTypeStep`.
    ENDIF.
    INSERT temp3 INTO TABLE temp4.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp4 ).

  ENDMETHOD.


  METHOD page_home.

    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    page = parent->ele( `Page`
        )->a( n = `id`               v = `page-home`
        )->a( n = `title`            v = `Product Catalog`
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

    
    content = page->ele( `content` ).

    " the search results - one ObjectListItem list per panel, written out at
    " each site rather than through a parameterized helper: a helper whose id
    " and items are parameters cannot be reconstructed, and an unreconstructable
    " view is one the render gate skips (port-a-sample, "one builder chain per
    " view")
    content->ele( `List`
        )->a( n = `id`         v = `productList`
        )->a( n = `visible`    v = client->_bind( search_visible )
        )->a( n = `mode`       v = `SingleSelectMaster`
        " a click in SingleSelectMaster mode SELECTS the row: ListItemBase.ontap
        " takes the isIncludedIntoSelection( ) branch and never fires the item's
        " press, whatever its type says. So the navigation hangs off the LIST's
        " selectionChange, exactly as the original's does - its item press is
        " the phone wire, where the mode is None
        )->a( n = `selectionChange` v = client->_event( val = `PRODUCT`
                                                       arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )
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
        " _search( ) shows ONE of the two lists: the categories give way to the
        " search results and come back when the field is cleared
        )->a( n = `visible`    v = |\{= !${ client->_bind( search_visible ) } \}|
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

    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    page = parent->ele( `Page`
        )->a( n = `id`               v = `page-category`
        )->a( n = `title`            v = client->_bind( category_name )
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `showNavButton`    b = abap_true
        )->a( n = `navButtonPress`   v = client->_event( `BACK_HOME` ) ).

    
    content = page->ele( `content` ).

    content->ele( `List`
        )->a( n = `id`         v = `categoryProductList`
        )->a( n = `mode`       v = `SingleSelectMaster`
        " a click in SingleSelectMaster mode SELECTS the row: ListItemBase.ontap
        " takes the isIncludedIntoSelection( ) branch and never fires the item's
        " press, whatever its type says. So the navigation hangs off the LIST's
        " selectionChange, exactly as the original's does - its item press is
        " the phone wire, where the mode is None
        )->a( n = `selectionChange` v = client->_event( val = `PRODUCT`
                                                       arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )
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

    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA promoted TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA promoted_content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA viewed TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA viewed_content TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA favorite TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA favorite_content TYPE REF TO z2ui5_cl_ui5_view_builder.
    page = parent->ele( `Page`
        )->a( n = `id`    v = `page-welcome`
        )->a( n = `title` v = `Shopping Cart` ).

    page->ele( `customHeader`
        )->ele( `Bar`
            )->ele( `contentMiddle`
                )->tag( `Title`
                    )->a( n = `level`   v = `H2`
                    )->a( n = `text`    v = `Welcome to the Shopping Cart`
                    )->a( n = `tooltip` v = `This demo app shows you how to use the sap.m library for a classical shopping cart. ` &&
                                            `You can browse and search a catalog of products, add the chosen products to your ` &&
                                            `shopping cart and, once happy with your selection order the cart contents.`

            )->end(
            )->ele( `contentRight`
                )->tag( `ToggleButton`
                    )->a( n = `icon`    v = `sap-icon://cart`
                    " what the original binds: `{= ${layout}.startsWith('ThreeColumns') }`.
                    " Derived from the bound layout rather than from a flag of its
                    " own, so the button on the OTHER page follows too - and an
                    " expression binding cannot be written back, which a two-way
                    " bound `pressed` would be, inverting TOGGLE_CART twice
                    )->a( n = `pressed` v = |\{= ${ client->_bind( layout ) }.startsWith('ThreeColumns') \}|
                    )->a( n = `tooltip` v = `Show Shopping Cart`
                    )->a( n = `press`   v = client->_event( `TOGGLE_CART` ) ).

    
    content = page->ele( `content` ).

    
    promoted = content->ele( `Panel`
        )->a( n = `id`               v = `panelPromoted`
        )->a( n = `headerText`       v = `Promoted Items`
        )->a( n = `backgroundDesign` v = `Transparent` ).
    
    promoted_content = promoted->ele( `content` ).

    promoted_content->ele( `List`
        )->a( n = `id`         v = `promotedList`
        )->a( n = `mode`       v = `SingleSelectMaster`
        " a click in SingleSelectMaster mode SELECTS the row: ListItemBase.ontap
        " takes the isIncludedIntoSelection( ) branch and never fires the item's
        " press, whatever its type says. So the navigation hangs off the LIST's
        " selectionChange, exactly as the original's does - its item press is
        " the phone wire, where the mode is None
        )->a( n = `selectionChange` v = client->_event( val = `PRODUCT`
                                                       arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )
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

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}`

                " Add to cart, from the list itself. The original puts an
                " Emphasized cart-3 Button on every welcome tile, and this
                " rebuild replaced its carousel with three lists (see the
                " class header) - which dropped the only way to fill the cart
                " without opening a product first. An ObjectListItem takes no
                " button, so the action is an ACTIVE ObjectStatus in the free
                " secondStatus slot - active/press are @since 1.54, and unlike
                " the ACTIVE ObjectAttribute this used to be it carries the
                " original's cart-3 ICON

                )->end(
                )->ele( `secondStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `icon`    v = `sap-icon://cart-3`
                        )->a( n = `text`    v = `Add to Cart`
                        )->a( n = `active`  b = abap_true
                        )->a( n = `tooltip` v = `Add to Shopping Cart`
                        )->a( n = `press`   v = client->_event( val = `ADD_TO_CART` arg = `${PRODUCTID}` ) ).

    
    viewed = content->ele( `Panel`
        )->a( n = `id`               v = `panelViewed`
        )->a( n = `headerText`       v = `Recently Viewed Items`
        )->a( n = `backgroundDesign` v = `Transparent` ).
    
    viewed_content = viewed->ele( `content` ).

    viewed_content->ele( `List`
        )->a( n = `id`         v = `viewedList`
        )->a( n = `mode`       v = `SingleSelectMaster`
        " a click in SingleSelectMaster mode SELECTS the row: ListItemBase.ontap
        " takes the isIncludedIntoSelection( ) branch and never fires the item's
        " press, whatever its type says. So the navigation hangs off the LIST's
        " selectionChange, exactly as the original's does - its item press is
        " the phone wire, where the mode is None
        )->a( n = `selectionChange` v = client->_event( val = `PRODUCT`
                                                       arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )
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

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}`

                " Add to cart, from the list itself. The original puts an
                " Emphasized cart-3 Button on every welcome tile, and this
                " rebuild replaced its carousel with three lists (see the
                " class header) - which dropped the only way to fill the cart
                " without opening a product first. An ObjectListItem takes no
                " button, so the action is an ACTIVE ObjectStatus in the free
                " secondStatus slot - active/press are @since 1.54, and unlike
                " the ACTIVE ObjectAttribute this used to be it carries the
                " original's cart-3 ICON

                )->end(
                )->ele( `secondStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `icon`    v = `sap-icon://cart-3`
                        )->a( n = `text`    v = `Add to Cart`
                        )->a( n = `active`  b = abap_true
                        )->a( n = `tooltip` v = `Add to Shopping Cart`
                        )->a( n = `press`   v = client->_event( val = `ADD_TO_CART` arg = `${PRODUCTID}` ) ).

    
    favorite = content->ele( `Panel`
        )->a( n = `id`               v = `panelFavorite`
        )->a( n = `headerText`       v = `Favorites`
        )->a( n = `backgroundDesign` v = `Transparent` ).
    
    favorite_content = favorite->ele( `content` ).

    favorite_content->ele( `List`
        )->a( n = `id`         v = `favoriteList`
        )->a( n = `mode`       v = `SingleSelectMaster`
        " a click in SingleSelectMaster mode SELECTS the row: ListItemBase.ontap
        " takes the isIncludedIntoSelection( ) branch and never fires the item's
        " press, whatever its type says. So the navigation hangs off the LIST's
        " selectionChange, exactly as the original's does - its item press is
        " the phone wire, where the mode is None
        )->a( n = `selectionChange` v = client->_event( val = `PRODUCT`
                                                       arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )
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
                        )->a( n = `state` v = `{STATUS_STATE}`

                " Add to cart, from the list itself. The original puts an
                " Emphasized cart-3 Button on every welcome tile, and this
                " rebuild replaced its carousel with three lists (see the
                " class header) - which dropped the only way to fill the cart
                " without opening a product first. An ObjectListItem takes no
                " button, so the action is an ACTIVE ObjectStatus in the free
                " secondStatus slot - active/press are @since 1.54, and unlike
                " the ACTIVE ObjectAttribute this used to be it carries the
                " original's cart-3 ICON

                )->end(
                )->ele( `secondStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `icon`    v = `sap-icon://cart-3`
                        )->a( n = `text`    v = `Add to Cart`
                        )->a( n = `active`  b = abap_true
                        )->a( n = `tooltip` v = `Add to Shopping Cart`
                        )->a( n = `press`   v = client->_event( val = `ADD_TO_CART` arg = `${PRODUCTID}` ) ).

  ENDMETHOD.


  METHOD page_product.

    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    page = parent->ele( `Page`
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
                    " what the original binds: `{= ${layout}.startsWith('ThreeColumns') }`.
                    " Derived from the bound layout rather than from a flag of its
                    " own, so the button on the OTHER page follows too - and an
                    " expression binding cannot be written back, which a two-way
                    " bound `pressed` would be, inverting TOGGLE_CART twice
                    )->a( n = `pressed` v = |\{= ${ client->_bind( layout ) }.startsWith('ThreeColumns') \}|
                    )->a( n = `tooltip` v = `Show Shopping Cart`
                    )->a( n = `press`   v = client->_event( `TOGGLE_CART` ) ).

    page->ele( `footer`
        )->ele( `Toolbar`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `text`  v = `Add to Cart`
                )->a( n = `type`  v = `Emphasized`
                )->a( n = `press` v = client->_event( `ADD_TO_CART` ) ).

    
    content = page->ele( `content` ).

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

    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    page = parent->ele( `Page`
        )->a( n = `id`             v = `page-cart`
        )->a( n = `title`          v = `Shopping Cart`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `TOGGLE_CART` ) ).

    
    content = page->ele( `content` ).

    content->ele( `List`
        )->a( n = `id`         v = `entryList`
        )->a( n = `headerText` v = `Items in Shopping Cart`
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
                        )->a( n = `active` b = abap_true
                        )->a( n = `text`   v = `Save for Later`
                        )->a( n = `press`  v = client->_event( val = `SAVE_LATER` arg = `${PRODUCTID}` )
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` b = abap_true
                        )->a( n = `text`   v = `Remove`
                        )->a( n = `press`  v = client->_event( val = `CART_REMOVE` arg = `${PRODUCTID}` ) ).

    content->ele( `List`
        )->a( n = `id`         v = `savedList`
        )->a( n = `headerText` v = `Items saved for later`
        )->a( n = `noDataText` v = `No items saved for later`
        )->a( n = `items`      v = client->_bind( t_saved )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `title`      v = `{NAME}`
                )->a( n = `icon`       v = `{PICTUREURL}`
                )->a( n = `number`     v = `{PRICE_TEXT}`
                )->a( n = `numberUnit` v = `{CURRENCYCODE}`

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` b = abap_true
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

    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA wizard TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA contents TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA payment TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA credit TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA bank TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA cod TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA invoice TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA delivery TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA delivery_type TYPE REF TO z2ui5_cl_ui5_view_builder.
    page = parent->ele( `Page`
        )->a( n = `id`             v = `page-checkout`
        )->a( n = `title`          v = `Checkout`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `BACK_CART` ) ).

    " enableBranching + subsequentSteps is what lets the payment type pick the
    " step after it; the branch itself is set from the backend with
    " setNextStep, and re-issued on every render (see view_display)
    
    wizard = page->ele( `content`
        )->ele( `Wizard`
            )->a( n = `id`              v = `checkoutWizard`
            )->a( n = `enableBranching` b = abap_true
            )->a( n = `complete`        v = client->_event( `WIZARD_COMPLETE` ) ).

    
    contents = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `contentsStep`
        )->a( n = `title`     v = `Items`
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

    
    payment = wizard->ele( `WizardStep`
        )->a( n = `id`              v = `paymentTypeStep`
        )->a( n = `title`           v = `Payment Type`
        )->a( n = `validated`       b = abap_true
        )->a( n = `subsequentSteps` v = `creditCardStep, bankAccountStep, cashOnDeliveryStep` ).

    payment->tag( `Text`
        )->a( n = `text` v = `We accept all major credit cards with no additional charging. ` &&
                             `Bank transfer and cash on delivery are only possible for inland deliveries. ` &&
                             `For those, we will charge additional 2.99 EUR. ` &&
                             `Orders payed with bank transfer, will be shipped direcly after the payment is received.` ).

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

    
    credit = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `creditCardStep`
        )->a( n = `title`     v = `Credit Card Details`
        )->a( n = `validated` b = abap_true
        )->a( n = `nextStep`  v = `invoiceAddressStep` ).

    credit->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable` b = abap_true
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Cardholder's Name`
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
                )->a( n = `text` v = `Expiration Date (MM/YYYY)`
            )->tag( `Input`
                )->a( n = `id`          v = `creditCardExpirationDate`
                )->a( n = `value`       v = client->_bind( cc_expire )
                )->a( n = `placeholder` v = `MM/YY` ).

    
    bank = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `bankAccountStep`
        )->a( n = `title`     v = `Bank Account Details`
        )->a( n = `validated` b = abap_true
        )->a( n = `nextStep`  v = `invoiceAddressStep` ).

    bank->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable` b = abap_false
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Beneficiary Name`
            )->tag( `Text`
                )->a( n = `text` v = `Singapore Hardware e-Commerce LTD`
            )->tag( `Label`
                )->a( n = `text` v = `Bank`
            )->tag( `Text`
                )->a( n = `text` v = `CITY BANK, SINGAPORE BRANCH`
            )->tag( `Label`
                )->a( n = `text` v = `Account Number`
            )->tag( `Text`
                )->a( n = `text` v = `06110702027218` ).

    
    cod = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `cashOnDeliveryStep`
        )->a( n = `title`     v = `Details for Cash on Delivery`
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
                )->a( n = `text` v = `Phone Number`
            )->tag( `Input`
                )->a( n = `id`    v = `cashOnDeliveryPhoneNumber`
                )->a( n = `value` v = client->_bind( cod_phone )
            )->tag( `Label`
                )->a( n = `text` v = `E-mail Address`
            )->tag( `Input`
                )->a( n = `id`    v = `cashOnDeliveryEmail`
                )->a( n = `value` v = client->_bind( cod_email ) ).

    
    invoice = wizard->ele( `WizardStep`
        )->a( n = `id`              v = `invoiceAddressStep`
        )->a( n = `title`           v = `Invoice Address`
        )->a( n = `validated`       b = abap_true
        )->a( n = `subsequentSteps` v = `deliveryAddressStep, deliveryTypeStep` ).

    invoice->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable` b = abap_true
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Use Different Address for Delivery`
            )->tag( `CheckBox`
                )->a( n = `id`       v = `differentDeliveryAddress`
                )->a( n = `selected` v = client->_bind( del_different )
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
                )->a( n = `text` v = `Zip Code`
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

    
    delivery = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `deliveryAddressStep`
        )->a( n = `title`     v = `Shipping Address`
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
                )->a( n = `text` v = `Zip Code`
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

    
    delivery_type = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `deliveryTypeStep`
        )->a( n = `title`     v = `Delivery Type`
        )->a( n = `validated` b = abap_true ).

    delivery_type->tag( `Text`
        )->a( n = `text` v = `Standard delivery time is 5 workdays. During high-season sales, please allow one additional day. ` &&
                             `Express delivery is delivered within 36 hours. For express delivery on workdays, we charge a ` &&
                             `service fee of 5.49 EUR, for a express delivery on holidays, the service fee is 8,00 EUR. ` &&
                             `Express delivery is only available for inland deliveries. For deliveries abroud, please check ` &&
                             `the specific conditions.` ).

    delivery_type->ele( `SegmentedButton`
        )->a( n = `selectedKey` v = client->_bind( del_type )

        )->ele( `items`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`  v = `Standard Delivery`
                )->a( n = `text` v = `Standard`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`  v = `Express Delivery`
                )->a( n = `text` v = `Express` ).

  ENDMETHOD.


  METHOD page_review.

    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA content TYPE REF TO z2ui5_cl_ui5_view_builder.
    page = parent->ele( `Page`
        )->a( n = `id`             v = `page-review`
        )->a( n = `title`          v = `Order Summary`
        )->a( n = `showNavButton`  b = abap_true
        )->a( n = `navButtonPress` v = client->_event( `BACK_CHECKOUT` ) ).

    
    content = page->ele( `content` ).

    content->ele( `List`
        )->a( n = `headerText` v = `Items`
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
                )->a( n = `text` v = `Selected Payment Type`
            )->tag( `Text`
                " the payment NAME, not the step id pay_type carries for the
                " branch: the original's summary reads {/SelectedPayment}, which
                " is what its SegmentedButton keys are
                )->a( n = `text` v = client->_bind( pay_name )
            )->tag( `Label`
                )->a( n = `text` v = `Invoice Address`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( inv_address )
            )->tag( `Label`
                )->a( n = `text` v = `Selected Delivery Type`
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

    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    page = parent->ele( `Page`
        )->a( n = `id`               v = `page-ordercompleted`
        )->a( n = `title`            v = `Order Completed`
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `class`            v = `sapUiContentPadding` ).

    page->ele( `content`
        )->tag( `FormattedText`
            )->a( n = `htmlText` v = `<h3>Thank you for your order!</h3><p><strong>Your order number: 20171941</strong></p>` &&
                                     `<p>You will receive an e-mail confirmation shortly.</p>` &&
                                     `<p>When the shipment is ready, you will also get an e-mail notification.</p>` &&
                                     `<p>Want to stay informed?</p><p>Please subscribe to our monthly newsletter. ` &&
                                     `Send a mail to <em><a href="mailto:newsletter@openui5isgreat.corp">newsletter@openui5isgreat.corp</a></em>.</p>` ).

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
        DATA category TYPE string.
        DATA temp6 TYPE string.
        DATA temp7 TYPE z2ui5_cl_smpc_demo_004=>ty_s_category.
        DATA temp8 LIKE t_category.
        DATA product LIKE LINE OF t_all.
        DATA add_id TYPE string.
        DATA temp1 TYPE xsdboolean.
        DATA temp9 TYPE string.
        DATA saved_id TYPE string.
        FIELD-SYMBOLS <entry> TYPE z2ui5_cl_smpc_demo_004=>ty_s_entry.
        DATA moved_id TYPE string.
        DATA temp10 TYPE string.
        DATA temp11 TYPE string_table.
        DATA temp13 TYPE string_table.
        DATA temp15 TYPE string_table.
        DATA temp17 TYPE string_table.
        DATA temp4 TYPE string.
        DATA missing TYPE string.

    CASE client->get_event( ).

      WHEN `CART_LOADED`.
        " the browser had a cart under the key: it wins over what this app
        " instance holds, exactly as the original's model does - the storage
        " IS the model there
        cart_restore( ).

      WHEN `SEARCH`.
        search_refresh( ).

      WHEN `CATEGORY`.
        
        category = client->get_event_arg( ).
        
        CLEAR temp6.
        
        READ TABLE t_categories INTO temp7 WITH KEY category = category.
        IF sy-subrc = 0.
          temp6 = temp7-categoryname.
        ENDIF.
        category_name = temp6.
        
        CLEAR temp8.
        t_category = temp8.
        
        LOOP AT t_all INTO product WHERE category = category.
          INSERT row_of( product ) INTO TABLE t_category.
        ENDLOOP.
        SORT t_category BY name AS TEXT.
        nav_to( nav = `nav-begin` page = `page-category` ).

      WHEN `PRODUCT`.
        product_show( client->get_event_arg( ) ).

      WHEN `BACK_HOME`.
        nav_to( nav = `nav-begin` page = `page-home` ).

      WHEN `BACK_WELCOME`.
        nav_to( nav = `nav-mid` page = `page-welcome` ).

      WHEN `ADD_TO_CART`.
        " two call shapes on one wire, as in the original: the product page's
        " footer button adds the product it SHOWS and sends nothing, a row
        " action on the welcome page sends the row's id. That is the same
        " split the original has between BaseController onAddToCart and
        " Welcome.controller onAddToCart
        
        add_id = client->get_event_arg( ).
        IF add_id IS INITIAL.
          add_id = prod_id.
        ENDIF.
        cart_add( add_id ).

      WHEN `TOGGLE_CART`.
        
        temp1 = boolc( cart_open = abap_false ).
        cart_open = temp1.
        
        IF cart_open = abap_true.
          temp9 = `ThreeColumnsMidExpanded`.
        ELSE.
          temp9 = `TwoColumnsMidExpanded`.
        ENDIF.
        layout = temp9.
        IF cart_open = abap_true.
          nav_to( nav = `nav-end` page = `page-cart` ).
        ENDIF.

      WHEN `SAVE_LATER`.
        
        saved_id = client->get_event_arg( ).
        
        READ TABLE t_cart WITH KEY productid = saved_id ASSIGNING <entry>.
        IF <entry> IS ASSIGNED.
          INSERT <entry> INTO TABLE t_saved.
          DELETE t_cart WHERE productid = saved_id.
          cart_refresh( ).
        ENDIF.

      WHEN `MOVE_TO_CART`.
        
        moved_id = client->get_event_arg( ).
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
        
        CASE pay_type.
          WHEN `creditCardStep`.
            temp10 = `Credit Card`.
          WHEN `bankAccountStep`.
            temp10 = `Bank Transfer`.
          WHEN `cashOnDeliveryStep`.
            temp10 = `Cash on Delivery`.
          WHEN OTHERS.
            temp10 = pay_type.
        ENDCASE.
        pay_name = temp10.
        
        CLEAR temp11.
        INSERT `checkoutWizard` INTO TABLE temp11.
        INSERT `discardProgress` INTO TABLE temp11.
        INSERT `paymentTypeStep` INTO TABLE temp11.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp11 ).
        
        CLEAR temp13.
        INSERT `paymentTypeStep` INTO TABLE temp13.
        INSERT `setNextStep` INTO TABLE temp13.
        INSERT pay_type INTO TABLE temp13.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp13 ).

      WHEN `DELIVERY_DIFFERENT`.
        del_different = client->get_event_arg( ).
        
        CLEAR temp15.
        INSERT `checkoutWizard` INTO TABLE temp15.
        INSERT `discardProgress` INTO TABLE temp15.
        INSERT `invoiceAddressStep` INTO TABLE temp15.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp15 ).
        
        CLEAR temp17.
        INSERT `invoiceAddressStep` INTO TABLE temp17.
        INSERT `setNextStep` INTO TABLE temp17.
        
        IF del_different = abap_true.
          temp4 = `deliveryAddressStep`.
        ELSE.
          temp4 = `deliveryTypeStep`.
        ENDIF.
        INSERT temp4 INTO TABLE temp17.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp17 ).

      WHEN `WIZARD_COMPLETE`.
        " the original validates the credit card step in its controller and
        " reports with a MessageBox; the whole check runs in ABAP here
        
        missing = ``.
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
    DATA temp19 TYPE string_table.

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

    
    CLEAR temp19.
    INSERT nav INTO TABLE temp19.
    INSERT `to` INTO TABLE temp19.
    INSERT page INTO TABLE temp19.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp19 ).

  ENDMETHOD.


  METHOD product_show.

    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_demo_004=>ty_s_product.
    DATA temp21 TYPE string.
    DATA temp22 TYPE string.
    READ TABLE t_all WITH KEY productid = productid ASSIGNING <product>.
    IF <product> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    prod_id       = <product>-productid.
    prod_name     = <product>-name.
    prod_supplier = <product>-suppliername.
    prod_desc     = <product>-shortdescription.
    prod_price    = price_text( <product>-price ).
    prod_currency = <product>-currencycode.
    prod_picture  = picture_url( <product>-pictureurl ).
    
    CASE <product>-status.
      WHEN `A`.
        temp21 = `Available`.
      WHEN `O`.
        temp21 = `Out of stock`.
      WHEN `D`.
        temp21 = `Discontinued`.
      WHEN OTHERS.
        temp21 = <product>-status.
    ENDCASE.
    prod_status   = temp21.
    
    CASE <product>-status.
      WHEN `A`.
        temp22 = `Success`.
      WHEN `O`.
        temp22 = `Warning`.
      WHEN `D`.
        temp22 = `Error`.
      WHEN OTHERS.
        temp22 = `None`.
    ENDCASE.
    prod_state    = temp22.
    prod_weight   = |{ <product>-weight } { <product>-weightunit }|.
    prod_measures = |{ <product>-dimensionwidth } { <product>-dimensionunit }, | &&
                    |{ <product>-dimensiondepth } { <product>-dimensionunit }, | &&
                    |{ <product>-dimensionheight } { <product>-dimensionunit }|.

    nav_to( nav = `nav-mid` page = `page-product` ).
    IF layout IS INITIAL OR layout = `OneColumn`.
      layout = `TwoColumnsMidExpanded`.
    ENDIF.

  ENDMETHOD.


  METHOD search_refresh.

    " the home list IS the search result; the original hides it while the search
    " is empty and shows the categories instead
    DATA temp23 LIKE t_search.
      DATA found LIKE LINE OF t_all.
    DATA temp2 TYPE xsdboolean.
    CLEAR temp23.
    t_search = temp23.
    IF search_term IS NOT INITIAL.
      
      LOOP AT t_all INTO found WHERE name IS NOT INITIAL.
        IF to_upper( found-name ) CS to_upper( search_term ).
          INSERT row_of( found ) INTO TABLE t_search.
        ENDIF.
      ENDLOOP.
      " the productList of the original sorts by Name
      SORT t_search BY name AS TEXT.
    ENDIF.
    
    temp2 = boolc( search_term IS NOT INITIAL ).
    search_visible = temp2.

  ENDMETHOD.


  METHOD cart_add.

    FIELD-SYMBOLS <product> TYPE z2ui5_cl_smpc_demo_004=>ty_s_product.
    FIELD-SYMBOLS <entry> TYPE z2ui5_cl_smpc_demo_004=>ty_s_entry.
      DATA temp24 TYPE z2ui5_cl_smpc_demo_004=>ty_s_entry.
    READ TABLE t_all WITH KEY productid = productid ASSIGNING <product>.
    IF <product> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    
    READ TABLE t_cart WITH KEY productid = productid ASSIGNING <entry>.
    IF <entry> IS ASSIGNED.
      <entry>-quantity = <entry>-quantity + 1.
    ELSE.
      
      CLEAR temp24.
      temp24-productid = <product>-productid.
      temp24-name = <product>-name.
      temp24-pictureurl = picture_url( <product>-pictureurl ).
      temp24-price_text = price_text( <product>-price ).
      temp24-currencycode = <product>-currencycode.
      temp24-quantity = 1.
      INSERT temp24 INTO TABLE t_cart.
    ENDIF.

    cart_refresh( ).
    client->message_toast_display( |{ <product>-name } has been added to your shopping cart.| ).

  ENDMETHOD.


  METHOD cart_mirror.

    " the totalPrice formatter of the original, computed where the prices are
    DATA total TYPE ty_amount.

    FIELD-SYMBOLS <product> TYPE ty_s_product.

    DATA entry LIKE LINE OF t_cart.
        DATA temp25 TYPE ty_amount.
    LOOP AT t_cart INTO entry.
      " UNASSIGN first: inside a loop a field symbol stays assigned from the
      " previous round, so IS ASSIGNED alone would read the PREVIOUS row
      UNASSIGN <product>.
      READ TABLE t_all WITH KEY productid = entry-productid ASSIGNING <product>.
      IF <product> IS ASSIGNED.
        
        temp25 = <product>-price.
        total = total + temp25 * entry-quantity.
      ENDIF.
    ENDLOOP.

    cart_total = |Total: { price_text( |{ total }| ) } EUR|.

    " entryList and saveForLaterList both sort by Name in the original, and the
    " checkout's two cart lists bind the same table
    SORT t_cart BY name AS TEXT.
    SORT t_saved BY name AS TEXT.

    " the mirror is what keeps the reading control quiet - it compares by
    " value and fires only on a difference
    CLEAR s_storage-value.
    s_storage-value-cart = t_cart.
    s_storage-value-saved = t_saved.

  ENDMETHOD.


  METHOD cart_refresh.
    DATA temp26 TYPE string_table.

    " the mirror plus the WRITE half: the same two tables into the browser's
    " local storage, under the key the original uses. Only a round-trip that
    " CHANGED the cart writes. Startup and the restore itself mirror without
    " writing (cart_mirror): the app knows nothing about the browser's cart
    " when model_init runs, and a write there put an empty cart over the
    " stored one before the reading control had reported it - which is
    " exactly the cart that went missing on every app restart
    cart_mirror( ).

    " STORE_DATA takes ONE argument and the frontend destructures it as
    " \{ TYPE, PREFIX, KEY, VALUE \}: an argument that parses as JSON is embedded
    " as real JSON, anything else stays a string. `${ _bind( s_storage ) }` -
    " what sample z2ui5_cl_smp_app_327 passes - is a BINDING, which only a
    " VIEW-WIRED action has UI5 resolve; from a handler the action is queued
    " and the argument arrives as the literal text `${/S_STORAGE}`. Until
    " abap2UI5 8574816 (2026-09-14, in the pin since #211) that text was
    " destructured as the payload, all four parts undefined, and an empty
    " VALUE is the frontend's signal to REMOVE the key - so this wrote nothing,
    " ever, and said nothing either. The frontend reads a string payload as a
    " MODEL PATH now and resolves it itself, so the binding form works from a
    " handler too; the payload stays composed here because a JSON argument is
    " the form that works on every pin this class has run on
    
    CLEAR temp26.
    INSERT storage_json( ) INTO TABLE temp26.
    client->follow_up_action( val   = client->cs_event-store_data
                              t_arg = temp26 ).

  ENDMETHOD.


  METHOD storage_json.

    " the STORE_DATA payload, as JSON: the same two tables the Storage control
    " holds in its bound `value`, so what is written is what the control reads
    " back and compares against, and it stays quiet on the next render
    result = |\{"TYPE":"{ s_storage-type }","PREFIX":"{ s_storage-prefix }",| &&
             |"KEY":"{ s_storage-key }","VALUE":\{| &&
             |"CART":{ entries_json( t_cart ) },"SAVED":{ entries_json( t_saved ) }\}\}|.

  ENDMETHOD.


  METHOD entries_json.

    " a JSON array of the six fields the bound value carries back
    DATA rows TYPE string.
    DATA entry LIKE LINE OF entries.
    rows = ``.

    
    LOOP AT entries INTO entry.
      IF rows IS NOT INITIAL.
        rows = |{ rows },|.
      ENDIF.
      rows = |{ rows }\{"PRODUCTID":"{ json_escape( entry-productid ) }",| &&
             |"NAME":"{ json_escape( entry-name ) }",| &&
             |"PICTUREURL":"{ json_escape( entry-pictureurl ) }",| &&
             |"PRICE_TEXT":"{ json_escape( entry-price_text ) }",| &&
             |"CURRENCYCODE":"{ json_escape( entry-currencycode ) }",| &&
             |"QUANTITY":{ entry-quantity }\}|.
    ENDLOOP.

    result = |[{ rows }]|.

  ENDMETHOD.


  METHOD json_escape.

    " the characters a JSON string cannot carry raw: the two delimiters and
    " the three line/tab controls a text field can hold (same shape as
    " samples-stack app 489). The backslash first, or it would escape the
    " escapes added after it
    result = replace( val = val    sub = `\`  with = `\\` occ = 0 ).
    result = replace( val = result sub = |\n| with = `\n`  occ = 0 ).
    result = replace( val = result sub = |\r| with = `\r`  occ = 0 ).
    result = replace( val = result sub = |\t| with = `\t`  occ = 0 ).
    result = replace( val = result sub = `"`  with = `\"`  occ = 0 ).

  ENDMETHOD.


  METHOD cart_restore.

    " NOTHING IS PARSED HERE. `value` is bound two-way
    " (client->_bind( s_storage-value ) on the Storage control), so the
    " value the control read out of the browser is written into the model by
    " UI5, travels back with THIS very event, and the framework has put it
    " into s_storage-value before on_event( ) runs - whole_value_apply in
    " z2ui5_cl_ui5_srv_model converts a whole object with
    " to_abap( iv_corresponding = abap_true ), which IS the
    " corresponding-only mapping an app would otherwise reach a JSON reader
    " for. The stored payload is nested (two arrays of six-field rows), and
    " nested is exactly the case a hand-written `find` walk does not answer:
    " binding the value is the answer instead.
    t_cart  = s_storage-value-cart.
    t_saved = s_storage-value-saved.

    " mirror, no write: what was just read IS what is stored, and the mirror
    " is what stops the reading control from reporting it again on the next
    " render
    cart_mirror( ).

  ENDMETHOD.


  METHOD order_submit.

    " the original posts nothing either - it clears the cart and shows the
    " completed page
    DATA temp28 TYPE z2ui5_cl_smpc_demo_004=>ty_t_entry.
    CLEAR temp28.
    t_cart     = temp28.
    cart_total = ``.
    cart_refresh( ).
    nav_to( nav = `nav-end` page = `page-ordercompleted` ).

  ENDMETHOD.


  METHOD row_of.
    DATA temp5 TYPE z2ui5_cl_smpc_demo_004=>ty_s_row-status_text.
    DATA temp6 TYPE z2ui5_cl_smpc_demo_004=>ty_s_row-status_state.

    CLEAR result.
    result-productid = product-productid.
    result-name = product-name.
    result-suppliername = product-suppliername.
    result-price_text = price_text( product-price ).
    result-currencycode = product-currencycode.
    result-pictureurl = picture_url( product-pictureurl ).
    
    CASE product-status.
      WHEN `A`.
        temp5 = `Available`.
      WHEN `O`.
        temp5 = `Out of stock`.
      WHEN `D`.
        temp5 = `Discontinued`.
      WHEN OTHERS.
        temp5 = product-status.
    ENDCASE.
    result-status_text = temp5.
    
    CASE product-status.
      WHEN `A`.
        temp6 = `Success`.
      WHEN `O`.
        temp6 = `Warning`.
      WHEN `D`.
        temp6 = `Error`.
      WHEN OTHERS.
        temp6 = `None`.
    ENDCASE.
    result-status_state = temp6.

  ENDMETHOD.


  METHOD picture_url.

    " the original's pictureUrl formatter: `sap.ui.require.toUrl( )` against
    " the resource root the app declares for `sap/ui/demo/mock`. Here that
    " root is the demo kit's deployed copy of the folder (see c_base), so the
    " prefix is what gets replaced - a path without it is left alone rather
    " than silently prefixed, because then it is not a mock path
    DATA len TYPE i.
    len = strlen( c_mock_prefix ).

    result = val.
    IF strlen( result ) > len AND result(len) = c_mock_prefix.
      result = |{ c_base }{ result+len }|.
    ENDIF.

  ENDMETHOD.


  METHOD price_text.

    " the price formatter of the original: two decimals, "." between the
    " thousands and "," before them - a NumberFormat in the browser there,
    " ABAP here, because a format is not a decision the frontend should make
    DATA temp29 TYPE ty_amount.
    DATA amount LIKE temp29.
    DATA raw TYPE string.
    DATA whole TYPE string.
    DATA fraction TYPE string.
    DATA grouped TYPE string.
      DATA cut TYPE i.
    temp29 = val.
    
    amount = temp29.
    
    raw = |{ amount DECIMALS = 2 NUMBER = RAW }|.

    
    
    SPLIT raw AT `.` INTO whole fraction.
    
    grouped = ``.
    WHILE strlen( whole ) > 3.
      
      cut = strlen( whole ) - 3.
      grouped = |.{ substring( val = whole off = cut len = 3 ) }{ grouped }|.
      whole   = substring( val = whole len = cut ).
    ENDWHILE.

    result = |{ whole }{ grouped },{ fraction }|.

  ENDMETHOD.


  METHOD model_init.

    FIELD-SYMBOLS <featured_product> TYPE ty_s_product.

    " localService/mockdata/ProductCategories.json - the categoryList of the
    " original sorts by CategoryName, so the rows are seeded verbatim (see
    " data_fidelity) and sorted at the end of model_init
    DATA temp30 LIKE t_categories.
    DATA temp31 LIKE LINE OF temp30.
    DATA temp32 LIKE t_featured.
    DATA temp33 LIKE LINE OF temp32.
    DATA temp34 LIKE t_all.
    DATA temp35 LIKE LINE OF temp34.
    DATA featured LIKE LINE OF t_featured.
    CLEAR temp30.
    
    temp31-category = `AC`.
    temp31-categoryname = `Accessories`.
    temp31-numberofproducts = 34.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `DC`.
    temp31-categoryname = `Desktop Computers`.
    temp31-numberofproducts = 5.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `FS`.
    temp31-categoryname = `Flat Screens`.
    temp31-numberofproducts = 3.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `KB`.
    temp31-categoryname = `Keyboards`.
    temp31-numberofproducts = 4.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `LT`.
    temp31-categoryname = `Laptops`.
    temp31-numberofproducts = 11.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `PR`.
    temp31-categoryname = `Printers`.
    temp31-numberofproducts = 9.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `ST`.
    temp31-categoryname = `Smartphones and Tablets`.
    temp31-numberofproducts = 9.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `MI`.
    temp31-categoryname = `Mice`.
    temp31-numberofproducts = 7.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `CSA`.
    temp31-categoryname = `Computer System Accessories`.
    temp31-numberofproducts = 7.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `GC`.
    temp31-categoryname = `Graphics Card`.
    temp31-numberofproducts = 4.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `SC`.
    temp31-categoryname = `Scanners`.
    temp31-numberofproducts = 4.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `SP`.
    temp31-categoryname = `Speakers`.
    temp31-numberofproducts = 3.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `SW`.
    temp31-categoryname = `Software`.
    temp31-numberofproducts = 8.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `TC`.
    temp31-categoryname = `Telecommunication`.
    temp31-numberofproducts = 3.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `SV`.
    temp31-categoryname = `Servers`.
    temp31-numberofproducts = 3.
    INSERT temp31 INTO TABLE temp30.
    temp31-category = `FST`.
    temp31-categoryname = `Flat Screen TVs`.
    temp31-numberofproducts = 3.
    INSERT temp31 INTO TABLE temp30.
    t_categories = temp30.

    " localService/mockdata/FeaturedProducts.json - the three panels of the
    " welcome page
    
    CLEAR temp32.
    
    temp33-productid = `HT-6132`.
    temp33-type = `Promoted`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-1000`.
    temp33-type = `Promoted`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-1113`.
    temp33-type = `Promoted`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-6130`.
    temp33-type = `Promoted`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-1040`.
    temp33-type = `Promoted`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-9992`.
    temp33-type = `Viewed`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-6130`.
    temp33-type = `Viewed`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-6110`.
    temp33-type = `Viewed`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-9997`.
    temp33-type = `Viewed`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-8000`.
    temp33-type = `Favorite`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-6100`.
    temp33-type = `Favorite`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-6111`.
    temp33-type = `Favorite`.
    INSERT temp33 INTO TABLE temp32.
    temp33-productid = `HT-1041`.
    temp33-type = `Favorite`.
    INSERT temp33 INTO TABLE temp32.
    t_featured = temp32.

    " localService/mockdata/Products.json - the full 123-row mock, verbatim
    
    CLEAR temp34.
    
    temp35-productid = `HT-1000`.
    temp35-name = `Notebook Basic 15`.
    temp35-category = `LT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1000.jpg`.
    temp35-price = `956`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `30`.
    temp35-dimensiondepth = `18`.
    temp35-dimensionheight = `3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1001`.
    temp35-name = `Notebook Basic 17`.
    temp35-category = `LT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1001.jpg`.
    temp35-price = `1249`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `29`.
    temp35-dimensiondepth = `17`.
    temp35-dimensionheight = `3.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1002`.
    temp35-name = `Notebook Basic 18`.
    temp35-category = `LT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1002.jpg`.
    temp35-price = `1570`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `28`.
    temp35-dimensiondepth = `19`.
    temp35-dimensionheight = `2.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1003`.
    temp35-name = `Notebook Basic 19`.
    temp35-category = `LT`.
    temp35-suppliername = `Smartcards`.
    temp35-shortdescription = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1003.jpg`.
    temp35-price = `1650`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `32`.
    temp35-dimensiondepth = `21`.
    temp35-dimensionheight = `4`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1007`.
    temp35-name = `ITelO Vault`.
    temp35-category = `AC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1007.jpg`.
    temp35-price = `299`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `0.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `32`.
    temp35-dimensiondepth = `22`.
    temp35-dimensionheight = `3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1010`.
    temp35-name = `Notebook Professional 15`.
    temp35-category = `AC`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1010.jpg`.
    temp35-price = `1999`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `33`.
    temp35-dimensiondepth = `20`.
    temp35-dimensionheight = `3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1011`.
    temp35-name = `Notebook Professional 17`.
    temp35-category = `LT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1011.jpg`.
    temp35-price = `2299`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `4.1`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `33`.
    temp35-dimensiondepth = `23`.
    temp35-dimensionheight = `2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1020`.
    temp35-name = `ITelO Vault Net`.
    temp35-category = `AC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1020.jpg`.
    temp35-price = `459`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `0.16`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `10`.
    temp35-dimensiondepth = `1.8`.
    temp35-dimensionheight = `17`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1021`.
    temp35-name = `ITelO Vault SAT`.
    temp35-category = `AC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1021.jpg`.
    temp35-price = `149`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `0.18`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `11`.
    temp35-dimensiondepth = `1.7`.
    temp35-dimensionheight = `18`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1022`.
    temp35-name = `Comfort Easy`.
    temp35-category = `AC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `32 GB Digital Assistant with high-resolution color screen`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1022.jpg`.
    temp35-price = `1679`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `84`.
    temp35-dimensiondepth = `1.5`.
    temp35-dimensionheight = `14`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1023`.
    temp35-name = `Comfort Senior`.
    temp35-category = `AC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1023.jpg`.
    temp35-price = `512`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `80`.
    temp35-dimensiondepth = `1.6`.
    temp35-dimensionheight = `13`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1030`.
    temp35-name = `Ergo Screen E-I`.
    temp35-category = `FT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1030.jpg`.
    temp35-price = `230`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `21`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `37`.
    temp35-dimensiondepth = `12`.
    temp35-dimensionheight = `36`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1031`.
    temp35-name = `Ergo Screen E-II`.
    temp35-category = `FT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1031.jpg`.
    temp35-price = `285`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `21`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `40.8`.
    temp35-dimensiondepth = `19`.
    temp35-dimensionheight = `43`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1032`.
    temp35-name = `Ergo Screen E-III`.
    temp35-category = `FT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1032.jpg`.
    temp35-price = `345`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `21`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `40.8`.
    temp35-dimensiondepth = `19`.
    temp35-dimensionheight = `43`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1035`.
    temp35-name = `Flat Basic`.
    temp35-category = `FT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1035.jpg`.
    temp35-price = `399`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `14`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `39`.
    temp35-dimensiondepth = `20`.
    temp35-dimensionheight = `41`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1036`.
    temp35-name = `Flat Future`.
    temp35-category = `FT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1036.jpg`.
    temp35-price = `430`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `15`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `45`.
    temp35-dimensiondepth = `26`.
    temp35-dimensionheight = `46`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1037`.
    temp35-name = `Flat XL`.
    temp35-category = `FT`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1037.jpg`.
    temp35-price = `1230`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `17`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `54.5`.
    temp35-dimensiondepth = `22.1`.
    temp35-dimensionheight = `39.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1040`.
    temp35-name = `Laser Professional Eco`.
    temp35-category = `PR`.
    temp35-suppliername = `Alpha Printers`.
    temp35-shortdescription = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1040.jpg`.
    temp35-price = `830`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `32`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `51`.
    temp35-dimensiondepth = `46`.
    temp35-dimensionheight = `30`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1041`.
    temp35-name = `Laser Basic`.
    temp35-category = `PR`.
    temp35-suppliername = `Alpha Printers`.
    temp35-shortdescription = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1041.jpg`.
    temp35-price = `490`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `23`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `42`.
    temp35-dimensionheight = `26`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1042`.
    temp35-name = `Laser Allround`.
    temp35-category = `PR`.
    temp35-suppliername = `Alpha Printers`.
    temp35-shortdescription = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with a first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1042.jpg`.
    temp35-price = `349`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `17`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `53`.
    temp35-dimensiondepth = `50`.
    temp35-dimensionheight = `65`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1050`.
    temp35-name = `Ultra Jet Super Color`.
    temp35-category = `PR`.
    temp35-suppliername = `Alpha Printers`.
    temp35-shortdescription = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1050.jpg`.
    temp35-price = `139`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `41`.
    temp35-dimensiondepth = `41`.
    temp35-dimensionheight = `28`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1051`.
    temp35-name = `Ultra Jet Mobile`.
    temp35-category = `PR`.
    temp35-suppliername = `Printer for All`.
    temp35-shortdescription = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1051.jpg`.
    temp35-price = `99`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `1.9`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `46`.
    temp35-dimensiondepth = `32`.
    temp35-dimensionheight = `25`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1052`.
    temp35-name = `Ultra Jet Super Highspeed`.
    temp35-category = `PR`.
    temp35-suppliername = `Printer for All`.
    temp35-shortdescription = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1052.jpg`.
    temp35-price = `170`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `18`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `41`.
    temp35-dimensiondepth = `41`.
    temp35-dimensionheight = `28`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1055`.
    temp35-name = `Multi Print`.
    temp35-category = `PR`.
    temp35-suppliername = `Printer for All`.
    temp35-shortdescription = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1055.jpg`.
    temp35-price = `99`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `6.3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `55`.
    temp35-dimensiondepth = `45`.
    temp35-dimensionheight = `29`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1056`.
    temp35-name = `Multi Color`.
    temp35-category = `PR`.
    temp35-suppliername = `Printer for All`.
    temp35-shortdescription = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1056.jpg`.
    temp35-price = `119`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `51`.
    temp35-dimensiondepth = `41.3`.
    temp35-dimensionheight = `22`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1060`.
    temp35-name = `Cordless Mouse`.
    temp35-category = `MI`.
    temp35-suppliername = `Oxynum`.
    temp35-shortdescription = `Cordless Optical USB MI, Laptop, Color: Black, Plug&Play`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1060.jpg`.
    temp35-price = `9`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `0.09`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `6`.
    temp35-dimensiondepth = `14.5`.
    temp35-dimensionheight = `3.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1061`.
    temp35-name = `Speed Mouse`.
    temp35-category = `MI`.
    temp35-suppliername = `Oxynum`.
    temp35-shortdescription = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1061.jpg`.
    temp35-price = `7`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `0.09`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `7`.
    temp35-dimensiondepth = `15`.
    temp35-dimensionheight = `3.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1062`.
    temp35-name = `Track Mouse`.
    temp35-category = `MI`.
    temp35-suppliername = `Oxynum`.
    temp35-shortdescription = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1062.jpg`.
    temp35-price = `11`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `0.03`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `3`.
    temp35-dimensiondepth = `7`.
    temp35-dimensionheight = `4`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1063`.
    temp35-name = `Ergonomic Keyboard`.
    temp35-category = `KB`.
    temp35-suppliername = `Oxynum`.
    temp35-shortdescription = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1063.jpg`.
    temp35-price = `14`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `2.1`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `50`.
    temp35-dimensiondepth = `21`.
    temp35-dimensionheight = `3.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1064`.
    temp35-name = `Internet Keyboard`.
    temp35-category = `KB`.
    temp35-suppliername = `Oxynum`.
    temp35-shortdescription = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1064.jpg`.
    temp35-price = `16`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `1.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `52`.
    temp35-dimensiondepth = `25`.
    temp35-dimensionheight = `3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1065`.
    temp35-name = `Media Keyboard`.
    temp35-category = `KB`.
    temp35-suppliername = `Oxynum`.
    temp35-shortdescription = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1065.jpg`.
    temp35-price = `26`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `51.4`.
    temp35-dimensiondepth = `23`.
    temp35-dimensionheight = `4`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1066`.
    temp35-name = `Mousepad`.
    temp35-category = `MI`.
    temp35-suppliername = `Oxynum`.
    temp35-shortdescription = `Nice mouse pad with ITelO Logo`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1066.jpg`.
    temp35-price = `6.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `80`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `15`.
    temp35-dimensiondepth = `6`.
    temp35-dimensionheight = `0.2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1067`.
    temp35-name = `Ergo Mousepad`.
    temp35-category = `MI`.
    temp35-suppliername = `Oxynum`.
    temp35-shortdescription = `Ergonomic mouse pad with ITelO Logo`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1067.jpg`.
    temp35-price = `8.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `80`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `15`.
    temp35-dimensiondepth = `6`.
    temp35-dimensionheight = `0.2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1068`.
    temp35-name = `Designer Mousepad`.
    temp35-category = `MI`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `ITelO Mousepad Special Edition`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1068.jpg`.
    temp35-price = `12.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `90`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `24`.
    temp35-dimensiondepth = `24`.
    temp35-dimensionheight = `0.6`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1069`.
    temp35-name = `Universal card reader`.
    temp35-category = `CSA`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `Universal card reader`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1069.jpg`.
    temp35-price = `14`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `45`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `6`.
    temp35-dimensiondepth = `6`.
    temp35-dimensionheight = `3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1070`.
    temp35-name = `Proctra X`.
    temp35-category = `GC`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `Proctra X: PCI-E GDDR5 3072MB`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1070.jpg`.
    temp35-price = `70.9`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.255`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `22`.
    temp35-dimensiondepth = `35`.
    temp35-dimensionheight = `17`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1071`.
    temp35-name = `Gladiator MX`.
    temp35-category = `GC`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1071.jpg`.
    temp35-price = `81.7`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `22`.
    temp35-dimensiondepth = `35`.
    temp35-dimensionheight = `17`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1072`.
    temp35-name = `Hurricane GX`.
    temp35-category = `GC`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1072.jpg`.
    temp35-price = `101.2`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.4`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `22`.
    temp35-dimensiondepth = `35`.
    temp35-dimensionheight = `17`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1073`.
    temp35-name = `Hurricane GX/LN`.
    temp35-category = `GC`.
    temp35-suppliername = `Smartcards`.
    temp35-shortdescription = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1073.jpg`.
    temp35-price = `139.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.4`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `22`.
    temp35-dimensiondepth = `35`.
    temp35-dimensionheight = `17`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1080`.
    temp35-name = `Photo Scan`.
    temp35-category = `SC`.
    temp35-suppliername = `Printer for All`.
    temp35-shortdescription = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1080.jpg`.
    temp35-price = `129`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `34`.
    temp35-dimensiondepth = `48`.
    temp35-dimensionheight = `5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1081`.
    temp35-name = `Power Scan`.
    temp35-category = `SC`.
    temp35-suppliername = `Printer for All`.
    temp35-shortdescription = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1081.jpg`.
    temp35-price = `89`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.4`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `31`.
    temp35-dimensiondepth = `43`.
    temp35-dimensionheight = `7`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1082`.
    temp35-name = `Jet Scan Professional`.
    temp35-category = `SC`.
    temp35-suppliername = `Printer for All`.
    temp35-shortdescription = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1082.jpg`.
    temp35-price = `169`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `33`.
    temp35-dimensiondepth = `41`.
    temp35-dimensionheight = `12`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1083`.
    temp35-name = `Jet Scan Professional`.
    temp35-category = `SC`.
    temp35-suppliername = `Printer for All`.
    temp35-shortdescription = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1083.jpg`.
    temp35-price = `189`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `35`.
    temp35-dimensiondepth = `40`.
    temp35-dimensionheight = `10`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1085`.
    temp35-name = `Copymaster`.
    temp35-category = `PR`.
    temp35-suppliername = `Alpha Printers`.
    temp35-shortdescription = `Copymaster`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1085.jpg`.
    temp35-price = `1499`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `23.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `45`.
    temp35-dimensiondepth = `42`.
    temp35-dimensionheight = `22`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1090`.
    temp35-name = `Surround Sound`.
    temp35-category = `SP`.
    temp35-suppliername = `Speaker Experts`.
    temp35-shortdescription = `PC multimedia speakers - 5 Watt (Total)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1090.jpg`.
    temp35-price = `39`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `12`.
    temp35-dimensiondepth = `10`.
    temp35-dimensionheight = `16`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1091`.
    temp35-name = `Blaster Extreme`.
    temp35-category = `SP`.
    temp35-suppliername = `Speaker Experts`.
    temp35-shortdescription = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1091.jpg`.
    temp35-price = `26`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `1.4`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `13`.
    temp35-dimensiondepth = `11`.
    temp35-dimensionheight = `17.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1092`.
    temp35-name = `Sound Booster`.
    temp35-category = `SP`.
    temp35-suppliername = `Speaker Experts`.
    temp35-shortdescription = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1092.jpg`.
    temp35-price = `45`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.1`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `12.4`.
    temp35-dimensiondepth = `10.4`.
    temp35-dimensionheight = `18.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1100`.
    temp35-name = `Smart Office`.
    temp35-category = `SW`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1100.jpg`.
    temp35-price = `89.9`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `1.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `15`.
    temp35-dimensiondepth = `6.5`.
    temp35-dimensionheight = `2.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1101`.
    temp35-name = `Smart Design`.
    temp35-category = `SW`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Complete package, 1 User, Image editing, processing`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1101.jpg`.
    temp35-price = `79.9`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `0.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `14`.
    temp35-dimensiondepth = `6.7`.
    temp35-dimensionheight = `24`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1102`.
    temp35-name = `Smart Network`.
    temp35-category = `SW`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1102.jpg`.
    temp35-price = `69`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `16`.
    temp35-dimensiondepth = `6`.
    temp35-dimensionheight = `27`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1103`.
    temp35-name = `Smart Multimedia`.
    temp35-category = `SW`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1103.jpg`.
    temp35-price = `77`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `11`.
    temp35-dimensiondepth = `3.4`.
    temp35-dimensionheight = `22`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1104`.
    temp35-name = `Smart Games`.
    temp35-category = `SW`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1104.jpg`.
    temp35-price = `55`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `1.1`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `10`.
    temp35-dimensiondepth = `3`.
    temp35-dimensionheight = `30`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1105`.
    temp35-name = `Smart Internet Antivirus`.
    temp35-category = `SW`.
    temp35-suppliername = `Brainsoft`.
    temp35-shortdescription = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1105.jpg`.
    temp35-price = `29`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.7`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `16`.
    temp35-dimensiondepth = `4`.
    temp35-dimensionheight = `21`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1106`.
    temp35-name = `Smart Firewall`.
    temp35-category = `SW`.
    temp35-suppliername = `Brainsoft`.
    temp35-shortdescription = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1106.jpg`.
    temp35-price = `34`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.9`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `17.9`.
    temp35-dimensiondepth = `4.2`.
    temp35-dimensionheight = `23.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1107`.
    temp35-name = `Smart Money`.
    temp35-category = `SW`.
    temp35-suppliername = `Brainsoft`.
    temp35-shortdescription = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1107.jpg`.
    temp35-price = `29.9`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `0.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `12`.
    temp35-dimensiondepth = `1.5`.
    temp35-dimensionheight = `19`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1110`.
    temp35-name = `PC Lock`.
    temp35-category = `CSA`.
    temp35-suppliername = `Red Point Stores`.
    temp35-shortdescription = `Robust 3m anti-burglary protection for your laptop computer`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1110.jpg`.
    temp35-price = `8.9`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.03`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `20`.
    temp35-dimensiondepth = `8`.
    temp35-dimensionheight = `4.3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1111`.
    temp35-name = `Notebook Lock`.
    temp35-category = `CSA`.
    temp35-suppliername = `Red Point Stores`.
    temp35-shortdescription = `Robust 1m anti-burglary protection for your desktop computer`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1111.jpg`.
    temp35-price = `6.9`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.02`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `31`.
    temp35-dimensiondepth = `9`.
    temp35-dimensionheight = `7`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1112`.
    temp35-name = `Web cam reality`.
    temp35-category = `CSA`.
    temp35-suppliername = `Red Point Stores`.
    temp35-shortdescription = `Color webcam, color, High-Speed USB`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1112.jpg`.
    temp35-price = `39`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.075`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `9`.
    temp35-dimensiondepth = `8.2`.
    temp35-dimensionheight = `1.3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1113`.
    temp35-name = `Screen clean`.
    temp35-category = `CSA`.
    temp35-suppliername = `Red Point Stores`.
    temp35-shortdescription = `10 separately packed screen wipes`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1113.jpg`.
    temp35-price = `2.3`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.05`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `2`.
    temp35-dimensiondepth = `2`.
    temp35-dimensionheight = `0.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1114`.
    temp35-name = `Fabric bag professional`.
    temp35-category = `CSA`.
    temp35-suppliername = `Red Point Stores`.
    temp35-shortdescription = `Notebook bag, plenty of room for stationery and writing materials`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1114.jpg`.
    temp35-price = `31`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `1.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `42`.
    temp35-dimensiondepth = `32`.
    temp35-dimensionheight = `7`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1115`.
    temp35-name = `Wireless DSL Router`.
    temp35-category = `TC`.
    temp35-suppliername = `Red Point Stores`.
    temp35-shortdescription = `Wireless DSL Router (available in blue, black and silver)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1115.jpg`.
    temp35-price = `49`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `0.45`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `19.3`.
    temp35-dimensiondepth = `18`.
    temp35-dimensionheight = `5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1116`.
    temp35-name = `Wireless DSL Router / Repeater`.
    temp35-category = `TC`.
    temp35-suppliername = `Red Point Stores`.
    temp35-shortdescription = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1116.jpg`.
    temp35-price = `59`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.45`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `19.3`.
    temp35-dimensiondepth = `18`.
    temp35-dimensionheight = `5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1117`.
    temp35-name = `Wireless DSL Router / Repeater and Print Server`.
    temp35-category = `TC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1117.jpg`.
    temp35-price = `69`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `0.45`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `19.3`.
    temp35-dimensiondepth = `18`.
    temp35-dimensionheight = `5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1118`.
    temp35-name = `USB Stick`.
    temp35-category = `CSA`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `USB 2.0 High-Speed 64 GB`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1118.jpg`.
    temp35-price = `35`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.015`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `1.5`.
    temp35-dimensiondepth = `8.7`.
    temp35-dimensionheight = `1.2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1120`.
    temp35-name = `Cordless Bluetooth Keyboard, english international`.
    temp35-category = `KB`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Cordless Bluetooth Keyboard with English keys`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1120.jpg`.
    temp35-price = `29`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `1`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `51.4`.
    temp35-dimensiondepth = `23`.
    temp35-dimensionheight = `4`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1137`.
    temp35-name = `Flat XXL`.
    temp35-category = `FS`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1137.jpg`.
    temp35-price = `1430`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `18`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `54`.
    temp35-dimensiondepth = `22`.
    temp35-dimensionheight = `38`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1138`.
    temp35-name = `Pocket Mouse`.
    temp35-category = `MI`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Portable pocket Mouse with retracting cord`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1138.jpg`.
    temp35-price = `23`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.02`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `0.3`.
    temp35-dimensiondepth = `0.5`.
    temp35-dimensionheight = `1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1210`.
    temp35-name = `PC Power Station`.
    temp35-category = `DC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like a PC, Windows 8 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1210.jpg`.
    temp35-price = `2399`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `28`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `43`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1500`.
    temp35-name = `Server Basic`.
    temp35-category = `SV`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1500.jpg`.
    temp35-price = `5000`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `18`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `34`.
    temp35-dimensiondepth = `35`.
    temp35-dimensionheight = `23`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1501`.
    temp35-name = `Server Professional`.
    temp35-category = `SV`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1501.jpg`.
    temp35-price = `15000`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `25`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `29`.
    temp35-dimensiondepth = `30`.
    temp35-dimensionheight = `27`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1502`.
    temp35-name = `Server Power Pro`.
    temp35-category = `SV`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1502.jpg`.
    temp35-price = `25000`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `35`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `22`.
    temp35-dimensiondepth = `27.3`.
    temp35-dimensionheight = `37`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6130`.
    temp35-name = `Flat Watch HD32`.
    temp35-category = `FST`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6130.jpg`.
    temp35-price = `1459`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.6`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `78`.
    temp35-dimensiondepth = `22.1`.
    temp35-dimensionheight = `55`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6131`.
    temp35-name = `Flat Watch HD37`.
    temp35-category = `FST`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6131.jpg`.
    temp35-price = `1199`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `99.1`.
    temp35-dimensiondepth = `26`.
    temp35-dimensionheight = `61`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6132`.
    temp35-name = `Flat Watch HD41`.
    temp35-category = `FST`.
    temp35-suppliername = `Very Best Screens`.
    temp35-shortdescription = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6132.jpg`.
    temp35-price = `899`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `1.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `128`.
    temp35-dimensiondepth = `23`.
    temp35-dimensionheight = `79.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-7030`.
    temp35-name = `Platinberry`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `Our new multifunctional Handheld with phone function in platinum`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-7030.jpg`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `0.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `8.1`.
    temp35-dimensiondepth = `13`.
    temp35-dimensionheight = `12.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-7020`.
    temp35-name = `Goldberry`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `Our new multifunctional Handheld with phone function in gold`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-7020.jpg`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `8.1`.
    temp35-dimensiondepth = `13`.
    temp35-dimensionheight = `12.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-7010`.
    temp35-name = `Silverberry`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `Our new multifunctional Handheld with phone function in silver`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-7010.jpg`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `8.1`.
    temp35-dimensiondepth = `13`.
    temp35-dimensionheight = `12.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-7000`.
    temp35-name = `Copperberry`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `Our new multifunctional Handheld with phone function in copper`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-7000.jpg`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `8.1`.
    temp35-dimensiondepth = `13`.
    temp35-dimensionheight = `12.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1095`.
    temp35-name = `Lovely Sound 5.1 Wireless`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1095.jpg`.
    temp35-price = `49`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `80`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `24`.
    temp35-dimensiondepth = `19`.
    temp35-dimensionheight = `23`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1096`.
    temp35-name = `Lovely Sound 5.1`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1096.jpg`.
    temp35-price = `39`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `130`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `25`.
    temp35-dimensiondepth = `17`.
    temp35-dimensionheight = `19`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1097`.
    temp35-name = `Lovely Sound Stereo`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1097.jpg`.
    temp35-price = `29`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `60`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `21.3`.
    temp35-dimensiondepth = `2.4`.
    temp35-dimensionheight = `19.7`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6123`.
    temp35-name = `Power Pro Player 80`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6123.jpg`.
    temp35-price = `299`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `267`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `4`.
    temp35-dimensiondepth = `6`.
    temp35-dimensionheight = `0.8`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6122`.
    temp35-name = `Power Pro Player 40`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6122.jpg`.
    temp35-price = `167`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `266`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `5.1`.
    temp35-dimensiondepth = `8`.
    temp35-dimensionheight = `9.2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6121`.
    temp35-name = `ITelo Jog-Mate`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6121.jpg`.
    temp35-price = `63`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `134`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `5.1`.
    temp35-dimensiondepth = `8`.
    temp35-dimensionheight = `9.2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6120`.
    temp35-name = `ITelo MusicStick`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `64 GB USB Music-on-a-Stick`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6120.jpg`.
    temp35-price = `45`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `134`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `1.5`.
    temp35-dimensiondepth = `6`.
    temp35-dimensionheight = `1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6111`.
    temp35-name = `Record Movie`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6111.jpg`.
    temp35-price = `288`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `3.1`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `38`.
    temp35-dimensiondepth = `26`.
    temp35-dimensionheight = `6.2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6110`.
    temp35-name = `Play Movie`.
    temp35-category = `AC`.
    temp35-suppliername = `Fasttech`.
    temp35-shortdescription = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6110.jpg`.
    temp35-price = `130`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `2.4`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `37`.
    temp35-dimensiondepth = `24`.
    temp35-dimensionheight = `6`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6102`.
    temp35-name = `Beam Breaker B-3`.
    temp35-category = `AC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6102.jpg`.
    temp35-price = `889`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `30.4`.
    temp35-dimensiondepth = `23.1`.
    temp35-dimensionheight = `23`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6101`.
    temp35-name = `Beam Breaker B-2`.
    temp35-category = `AC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6101.jpg`.
    temp35-price = `679`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `30.4`.
    temp35-dimensiondepth = `23.1`.
    temp35-dimensionheight = `23`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2002`.
    temp35-name = `Portable DVD Player with 9" LCD Monitor`.
    temp35-category = `AC`.
    temp35-suppliername = `Technocom`.
    temp35-shortdescription = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-2002.jpg`.
    temp35-price = `853.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `0.72`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `21`.
    temp35-dimensiondepth = `16.5`.
    temp35-dimensionheight = `14`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-6100`.
    temp35-name = `Beam Breaker B-1`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-6100.jpg`.
    temp35-price = `469`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `1.7`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `30.4`.
    temp35-dimensiondepth = `23.1`.
    temp35-dimensionheight = `23`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2027`.
    temp35-name = `Removable CD/DVD Laser Labels`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Removable jewel case labels, zero residues (100)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-2027.jpg`.
    temp35-price = `8.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.15`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `5.5`.
    temp35-dimensiondepth = `2`.
    temp35-dimensionheight = `2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2026`.
    temp35-name = `Audio/Video Cable Kit - 4m`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Quality cables for notebooks and projectors`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-2026.jpg`.
    temp35-price = `29.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `D`.
    temp35-weight = `0.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `21`.
    temp35-dimensiondepth = `10.2`.
    temp35-dimensionheight = `13`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2025`.
    temp35-name = `CD/DVD case: 264 sleeves`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Organizer and protective case for 264 CDs and DVDs`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-2025.jpg`.
    temp35-price = `44.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.65`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `13`.
    temp35-dimensiondepth = `13`.
    temp35-dimensionheight = `20`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2001`.
    temp35-name = `10" Portable DVD player`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-2001.jpg`.
    temp35-price = `449.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.84`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `24`.
    temp35-dimensiondepth = `19.5`.
    temp35-dimensionheight = `29`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-2000`.
    temp35-name = `7" Widescreen Portable DVD Player w MP3`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-2000.jpg`.
    temp35-price = `249.99`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `0.79`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `21.4`.
    temp35-dimensiondepth = `19`.
    temp35-dimensionheight = `27.6`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1603`.
    temp35-name = `Gaming Monster Pro`.
    temp35-category = `DC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1603.jpg`.
    temp35-price = `1700`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `6.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `27`.
    temp35-dimensiondepth = `28`.
    temp35-dimensionheight = `42`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1602`.
    temp35-name = `Gaming Monster`.
    temp35-category = `DC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1602.jpg`.
    temp35-price = `1200`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `5.9`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `26.5`.
    temp35-dimensiondepth = `34`.
    temp35-dimensionheight = `47`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1601`.
    temp35-name = `Family PC Pro`.
    temp35-category = `DC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1601.jpg`.
    temp35-price = `900`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `5.3`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `25`.
    temp35-dimensiondepth = `31.7`.
    temp35-dimensionheight = `40.2`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1600`.
    temp35-name = `Family PC Basic`.
    temp35-category = `DC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1600.jpg`.
    temp35-price = `600`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `4.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `21.4`.
    temp35-dimensiondepth = `29`.
    temp35-dimensionheight = `38`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1119`.
    temp35-name = `Travel Adapter`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Universal Travel Adapter`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1119.jpg`.
    temp35-price = `79`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `88`.
    temp35-weightunit = `G`.
    temp35-dimensionwidth = `2`.
    temp35-dimensiondepth = `3.1`.
    temp35-dimensionheight = `3.9`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-8000`.
    temp35-name = `ITelO FlexTop I4000`.
    temp35-category = `LT`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-8000.jpg`.
    temp35-price = `799`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `31`.
    temp35-dimensiondepth = `19`.
    temp35-dimensionheight = `3.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-8001`.
    temp35-name = `ITelO FlexTop I6300c`.
    temp35-category = `LT`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-8001.jpg`.
    temp35-price = `799`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `32`.
    temp35-dimensiondepth = `20`.
    temp35-dimensionheight = `3.4`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-8002`.
    temp35-name = `ITelO FlexTop I9100`.
    temp35-category = `LT`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-8002.jpg`.
    temp35-price = `1199`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `38`.
    temp35-dimensiondepth = `21`.
    temp35-dimensionheight = `4.1`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-8003`.
    temp35-name = `ITelO FlexTop I9800`.
    temp35-category = `LT`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-8003.jpg`.
    temp35-price = `1388`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `PF-1000`.
    temp35-name = `Flyer`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Flyer for our product palette`.
    temp35-pictureurl = `sap/ui/demo/mock/images/PF-1000.jpg`.
    temp35-price = `0`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.01`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `46`.
    temp35-dimensiondepth = `30`.
    temp35-dimensionheight = `3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9999`.
    temp35-name = `Maxi Tablet`.
    temp35-category = `ST`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9999.jpg`.
    temp35-price = `749`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9998`.
    temp35-name = `Smartphone Beta`.
    temp35-category = `ST`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS A-GPS support`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9998.jpg`.
    temp35-price = `699`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.75`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9997`.
    temp35-name = `e-Book Reader ReadMe`.
    temp35-category = `ST`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9997.jpg`.
    temp35-price = `633`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9996`.
    temp35-name = `Tablet Pouch`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Stylish tablet pouch, protects from scratches, color: black`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9996.jpg`.
    temp35-price = `20`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.03`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `25`.
    temp35-dimensiondepth = `40`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9995`.
    temp35-name = `Smartphone Cover`.
    temp35-category = `AC`.
    temp35-suppliername = `Titanium`.
    temp35-shortdescription = `Durable high quality plastic bump-sleeve, lightweight, protects from scratches, rubber coating, multiple colors available, Accurate design and cut-outs for your device, snap-on design`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9995.jpg`.
    temp35-price = `15`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.02`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9994`.
    temp35-name = `Camcorder View`.
    temp35-category = `AC`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9994.jpg`.
    temp35-price = `1388`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `27`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9993`.
    temp35-name = `Mini Tablet`.
    temp35-category = `ST`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9993.jpg`.
    temp35-price = `833`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `3.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9992`.
    temp35-name = `Smartphone Alpha`.
    temp35-category = `ST`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9992.jpg`.
    temp35-price = `599`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.75`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-9991`.
    temp35-name = `Smartphone Leather Case`.
    temp35-category = `AC`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-9991.jpg`.
    temp35-price = `25`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.02`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1251`.
    temp35-name = `Astro Laptop 1516`.
    temp35-category = `LT`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1251.jpg`.
    temp35-price = `989`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `30`.
    temp35-dimensiondepth = `18`.
    temp35-dimensionheight = `3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1252`.
    temp35-name = `Astro Phone 6`.
    temp35-category = `ST`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1252.jpg`.
    temp35-price = `649`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.75`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `8`.
    temp35-dimensiondepth = `6`.
    temp35-dimensionheight = `1.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1253`.
    temp35-name = `Benda Laptop 1408`.
    temp35-category = `LT`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1253.jpg`.
    temp35-price = `976`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `4.2`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `30`.
    temp35-dimensiondepth = `18`.
    temp35-dimensionheight = `3`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1254`.
    temp35-name = `Bending Screen 21HD`.
    temp35-category = `FS`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, D-Sub`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1254.jpg`.
    temp35-price = `250`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `15`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `37`.
    temp35-dimensiondepth = `12`.
    temp35-dimensionheight = `36`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1255`.
    temp35-name = `Broad Screen 22HD`.
    temp35-category = `FS`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, D-Sub`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1255.jpg`.
    temp35-price = `270`.
    temp35-currencycode = `EUR`.
    temp35-status = `O`.
    temp35-weight = `16`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `39`.
    temp35-dimensiondepth = `12`.
    temp35-dimensionheight = `38`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1256`.
    temp35-name = `Cerdik Phone 7`.
    temp35-category = `ST`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1256.jpg`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `0.75`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `9`.
    temp35-dimensiondepth = `15`.
    temp35-dimensionheight = `1.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1257`.
    temp35-name = `Cepat Tablet 10.5`.
    temp35-category = `ST`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1257.jpg`.
    temp35-price = `549`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.8`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `48`.
    temp35-dimensiondepth = `31`.
    temp35-dimensionheight = `4.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    temp35-productid = `HT-1258`.
    temp35-name = `Cepat Tablet 8`.
    temp35-category = `ST`.
    temp35-suppliername = `Ultrasonic United`.
    temp35-shortdescription = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp35-pictureurl = `sap/ui/demo/mock/images/HT-1258.jpg`.
    temp35-price = `529`.
    temp35-currencycode = `EUR`.
    temp35-status = `A`.
    temp35-weight = `2.5`.
    temp35-weightunit = `KG`.
    temp35-dimensionwidth = `38`.
    temp35-dimensiondepth = `21`.
    temp35-dimensionheight = `3.5`.
    temp35-dimensionunit = `cm`.
    INSERT temp35 INTO TABLE temp34.
    t_all = temp34.

    
    LOOP AT t_featured INTO featured.
      " UNASSIGN first - see cart_refresh
      UNASSIGN <featured_product>.
      READ TABLE t_all WITH KEY productid = featured-productid ASSIGNING <featured_product>.
      IF <featured_product> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.
      CASE featured-type.
        WHEN `Promoted`.
          INSERT row_of( <featured_product> ) INTO TABLE t_promoted.
        WHEN `Viewed`.
          INSERT row_of( <featured_product> ) INTO TABLE t_viewed.
        WHEN OTHERS.
          INSERT row_of( <featured_product> ) INTO TABLE t_favorite.
      ENDCASE.
    ENDLOOP.

    " the categoryList's own sorter
    SORT t_categories BY categoryname AS TEXT.

    layout = `TwoColumnsMidExpanded`.

    " what the original's checkout model starts on: SelectedPayment "Credit Card"
    " and SelectedDeliveryMethod "Standard Delivery". Not a cosmetic default - the
    " payment step's branch is an association, and with pay_type initial nothing
    " ever set it, so a user who ACCEPTED the default could not leave the step at
    " all. The original does not have the problem because its own goToPaymentStep
    " defaults to the credit-card step; here view_display( ) re-issues the branch
    " on every render as long as pay_type is filled
    pay_type = `creditCardStep`.
    pay_name = `Credit Card`.
    del_type = `Standard Delivery`.

    " the original's LocalStorageModel("SHOPPING_CART", ...) - same storage,
    " same key
    s_storage-type = `local`.
    s_storage-key  = `SHOPPING_CART`.

    " mirror only - the browser's cart has not been read yet, so writing here
    " would put this empty one over it
    cart_mirror( ).

  ENDMETHOD.

ENDCLASS.
