" @keywords shopping cart app flexiblecolumnlayout navcontainer viewsettingsfilteritem viewsettingsitem viewsettingscustomitem verticallayout rangeslider messageitem link
" @summary The classic business process of finding and ordering products. - the UI5 demo app "Shopping Cart", rebuilt as one self-contained abap2UI5 class.
" @origin demo app Shopping Cart (sap.m/cart) - https://sdk.openui5.org/demoapps (status: generated - machine-written, not yet reviewed)
"! <p class="shorttext">demo app - Shopping Cart</p>
"!
"! The UI5 demo app Shopping Cart - the demo kit's showcase application -
"! rebuilt as ONE abap2UI5 class, page for page and control for control:
"! the category list with its live search, the product list per category
"! with its filter dialog, the welcome page, the product page, the product
"! comparison, the cart with its edit mode and save-for-later, the checkout
"! wizard with payment branch, addresses, delivery type and its summary,
"! and the order confirmation - with every MessageBox and MessageToast the
"! original shows. The original's FlexibleColumnLayout and its router are
"! kept: every route of its manifest.json is a call of route_to( ) here,
"! which puts the same pages into the same three columns, and the column
"! layouts its controllers set are set at the same moments.
"!
"! Where it differs from the original, and why - only what an app without a
"! browser-side model layer or a URL cannot do the same way:
"!
"!  - the OData V2 service and its mock server become ABAP data: the 123
"!    products, the 16 categories and the 13 featured products of the demo
"!    kit mock, verbatim. The search keeps the mock server's semantics (a
"!    case-sensitive substringof on the name), the category filter the
"!    original's Filter objects (OR inside a group, AND across groups).
"!  - there is no URL, so a route is a method call rather than a hash. The
"!    Back buttons (shown on small screens only, as there) walk the history
"!    of the routes taken instead of the browser's, and the NotFound target
"!    - reachable only through an unknown id typed into the URL - has
"!    nothing that could reach it and is not rebuilt.
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
"!    carries check_queue_last. The comparison model's own local storage
"!    key (PRODUCT_COMPARISON) is not kept: every route that shows a
"!    comparison carries its two products, so the stored copy is never read.
"!  - the formatter module is business logic and moves to the backend: the
"!    price format, the status text and its ValueState, the cart total. The
"!    welcome tiles keep the original's CurrencyType binding, which formats
"!    in the browser's locale - a type, not a formatter.
"!  - the wizard's input checks run in ABAP. The original types every
"!    required input with a StringType (minLength, a `search` regex) or its
"!    EmailType, so a changed field turns red with the type's message, the
"!    message lands in the message model its footer's MessagePopover lists,
"!    and each step's change handler calls validateStep/invalidateStep. Here
"!    the same constraints are ABAP (input_error), decided on the same
"!    change events; the value states, the message list behind the same
"!    footer button and each step's bound `validated` follow from them. The
"!    regexes are the original's with \s spelled as a space and \w as
"!    [a-zA-Z0-9_], the one spelling ABAP POSIX and JavaScript read alike
"!    inside a bracket expression.
"!  - the original's _setDiscardableProperty compares a step with
"!    Wizard.getProgressStep( ), which no backend can read. The activate
"!    events of the steps behind the payment step and behind the invoice
"!    step set a flag instead (payment_passed, invoice_passed), and the
"!    Yes/No warnings ask on those.
"!  - the carousel's eight-second advance is a z2ui5.cc.Timer wired to the
"!    carousel's next( ) and restarted on every page change, without a
"!    round-trip; its random start page and the two promoted items are drawn
"!    in ABAP with cl_abap_random_int - once per app start, as there.
"!  - the i18n resource bundle becomes literals. The busy indicator the
"!    original shows until its OData metadata has loaded has nothing to wait
"!    for here, and the content density is abap2UI5's shell's to pick.
"!  - the style.css rules ride along in a core:HTML style block, because a
"!    port has no manifest to link a stylesheet from - scoped under the same
"!    `.sapUiDemoCart` class the App and the FlexibleColumnLayout carry.
"!
"! Original: src/sap.m/test/sap/m/demokit/cart in OpenUI5, archived under
"! ui5/demoapps/sap.m/cart.
"! Demo apps: https://sdk.openui5.org/demoapps
CLASS z2ui5_cl_smpc_demo_004 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES ty_amount TYPE p LENGTH 13 DECIMALS 2.
    TYPES:
      BEGIN OF ty_s_category,
        category         TYPE string,
        categoryname     TYPE string,
        numberofproducts TYPE i,
      END OF ty_s_category.
    " one product as a list row or a welcome tile shows it
    TYPES:
      BEGIN OF ty_s_row,
        productid    TYPE string,
        category     TYPE string,
        name         TYPE string,
        suppliername TYPE string,
        price        TYPE ty_amount,
        price_text   TYPE string,
        currencycode TYPE string,
        pictureurl   TYPE string,
        status       TYPE string,
        status_text  TYPE string,
        status_state TYPE string,
        selected     TYPE abap_bool,
      END OF ty_s_row.
    TYPES ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    " one product as the product page and a comparison panel show it
    TYPES:
      BEGIN OF ty_s_detail,
        productid        TYPE string,
        category         TYPE string,
        name             TYPE string,
        suppliername     TYPE string,
        shortdescription TYPE string,
        price_text       TYPE string,
        pictureurl       TYPE string,
        status_text      TYPE string,
        status_state     TYPE string,
        weight_text      TYPE string,
        measures_text    TYPE string,
      END OF ty_s_detail.
    " one cart entry - the fields the cart lists, the checkout and the
    " summary show, and what the browser's local storage keeps
    TYPES:
      BEGIN OF ty_s_entry,
        productid    TYPE string,
        category     TYPE string,
        name         TYPE string,
        pictureurl   TYPE string,
        price_text   TYPE string,
        currencycode TYPE string,
        quantity     TYPE i,
        status_text  TYPE string,
        status_state TYPE string,
      END OF ty_s_entry.
    TYPES ty_t_entry TYPE STANDARD TABLE OF ty_s_entry WITH EMPTY KEY.
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
    TYPES:
      BEGIN OF ty_s_supplier,
        suppliername TYPE string,
        selected     TYPE abap_bool,
      END OF ty_s_supplier.
    " one entry of the checkout's message model, as its MessagePopover lists it
    TYPES:
      BEGIN OF ty_s_message,
        type           TYPE string,
        message        TYPE string,
        additionaltext TYPE string,
      END OF ty_s_message.
    " one component per checked input, named like the field it checks: the
    " value state the original's StringType constraints put on a field when
    " it is changed, and the type's message. Enum-typed, so `None` and never
    " empty (model_init)
    TYPES:
      BEGIN OF ty_s_checks,
        cc_name       TYPE string,
        cc_number     TYPE string,
        cc_code       TYPE string,
        cc_expire     TYPE string,
        cod_firstname TYPE string,
        cod_lastname  TYPE string,
        cod_phone     TYPE string,
        cod_email     TYPE string,
        inv_address   TYPE string,
        inv_city      TYPE string,
        inv_zip       TYPE string,
        inv_country   TYPE string,
        del_address   TYPE string,
        del_city      TYPE string,
        del_zip       TYPE string,
        del_country   TYPE string,
      END OF ty_s_checks.

    " the app view model of the original (appView>): the FCL layout and the
    " smallScreenMode its stateChange handler keeps - true until the first
    " stateChange says otherwise, as there
    DATA layout            TYPE string.
    DATA small_screen      TYPE abap_bool VALUE abap_true.

    " Home
    DATA search_term       TYPE string.
    DATA search_visible    TYPE abap_bool.
    DATA t_search          TYPE ty_t_row.
    DATA t_categories      TYPE STANDARD TABLE OF ty_s_category WITH EMPTY KEY.

    " Category, and its filter dialog
    DATA category_name     TYPE string.
    DATA t_category        TYPE ty_t_row.
    DATA t_suppliers       TYPE STANDARD TABLE OF ty_s_supplier WITH EMPTY KEY.
    DATA flt_available     TYPE abap_bool.
    DATA flt_out_of_stock  TYPE abap_bool.
    DATA flt_discontinued  TYPE abap_bool.
    DATA flt_low           TYPE i.
    DATA flt_high          TYPE i VALUE 5000.
    DATA flt_price_count   TYPE i.
    DATA info_visible      TYPE abap_bool.
    DATA info_text         TYPE string.

    " Welcome
    DATA t_promoted        TYPE ty_t_row.
    DATA t_viewed          TYPE ty_t_row.
    DATA t_favorite        TYPE ty_t_row.

    " Product - enum-typed status_state: the UI5 default until a product is
    " opened, an empty value is rejected outright
    DATA s_prod            TYPE ty_s_detail.

    " Comparison
    DATA s_cmp1            TYPE ty_s_detail.
    DATA s_cmp2            TYPE ty_s_detail.
    DATA cmp1_visible      TYPE abap_bool.
    DATA cmp2_visible      TYPE abap_bool.
    DATA cmp_placeholder   TYPE abap_bool.

    " Cart - the original's cfg> model is in_delete; the title follows it
    DATA t_cart            TYPE ty_t_entry.
    DATA t_saved           TYPE ty_t_entry.
    " what the original's LocalStorageModel is: the cart under its own key in
    " the browser's local storage. The whole structure is what STORE_DATA
    " writes, and `value` is what the z2ui5.cc.Storage control reads back
    DATA s_storage         TYPE ty_s_storage.
    DATA cart_total        TYPE string.
    DATA in_delete         TYPE abap_bool.
    " formatter.hasItems for the Edit button (either list) and for Proceed
    " (the cart)
    DATA cart_any          TYPE abap_bool.
    DATA cart_filled       TYPE abap_bool.
    DATA cart_title        TYPE string VALUE `Shopping Cart`.

    " Checkout - the original's one JSON model, one flat set of fields
    DATA pay_type          TYPE string.
    DATA cc_name           TYPE string.
    DATA cc_number         TYPE string.
    DATA cc_code           TYPE string.
    DATA cc_expire         TYPE string.
    DATA cod_firstname     TYPE string.
    DATA cod_lastname      TYPE string.
    DATA cod_phone         TYPE string.
    DATA cod_email         TYPE string.
    DATA inv_address       TYPE string.
    DATA inv_city          TYPE string.
    DATA inv_zip           TYPE string.
    DATA inv_country       TYPE string.
    DATA inv_note          TYPE string.
    DATA del_different     TYPE abap_bool.
    DATA del_address       TYPE string.
    DATA del_city          TYPE string.
    DATA del_zip           TYPE string.
    DATA del_country       TYPE string.
    DATA del_note          TYPE string.
    DATA del_type          TYPE string.
    DATA s_state           TYPE ty_s_checks.
    DATA s_state_text      TYPE ty_s_checks.
    " the four steps with inputs, validated="false" in the original until
    " their check passes - bound to each step's `validated`
    DATA cc_valid          TYPE abap_bool.
    DATA cod_valid         TYPE abap_bool.
    DATA inv_valid         TYPE abap_bool.
    DATA del_valid         TYPE abap_bool.
    " the message model: one entry per input that failed its type
    DATA t_messages        TYPE STANDARD TABLE OF ty_s_message WITH EMPTY KEY.
    DATA msg_count         TYPE i.

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
    TYPES:
      BEGIN OF ty_s_featured,
        productid TYPE string,
        type      TYPE string,
      END OF ty_s_featured.
    " a route of the original's manifest.json with its arguments - what the
    " URL hash holds there
    TYPES:
      BEGIN OF ty_s_route,
        name     TYPE string,
        category TYPE string,
        product  TYPE string,
        item1    TYPE string,
        item2    TYPE string,
      END OF ty_s_route.

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

    " the welcome carousel's four teaser images are files of the APP, not of
    " the mock: the original resolves `sap/ui/demo/cart/img/...` with
    " `sap.ui.require.toUrl( )` against its own webapp root. Same answer as
    " c_base, one folder up
    CONSTANTS c_img         TYPE string
      VALUE `https://sdk.openui5.org/test-resources/sap/m/demokit/cart/webapp/img/`.

    DATA client          TYPE REF TO z2ui5_if_client.
    DATA t_all           TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_featured      TYPE STANDARD TABLE OF ty_s_featured WITH EMPTY KEY.
    " the route on show and the ones before it - what the browser history
    " holds there, walked by the Back buttons
    DATA s_route         TYPE ty_s_route.
    DATA t_history       TYPE STANDARD TABLE OF ty_s_route WITH EMPTY KEY.
    " the page each NavContainer shows, re-issued after a rebuilt view
    DATA page_begin      TYPE string VALUE `page-home`.
    DATA page_mid        TYPE string VALUE `page-welcome`.
    DATA page_end        TYPE string VALUE `page-cart`.
    DATA page_wizard     TYPE string VALUE `wizardContentPage`.
    " the carousel page drawn at start (onInit's random setActivePage)
    DATA carousel_page   TYPE string.
    " the comparison model of the original: the category and the two items
    DATA cmp_category    TYPE string.
    DATA cmp_item1       TYPE string.
    DATA cmp_item2       TYPE string.
    " the slider values of the last confirmed filter - the original's
    " _iLowFilterPreviousValue / _iHighFilterPreviousValue
    DATA flt_low_prev    TYPE i.
    DATA flt_high_prev   TYPE i VALUE 5000.
    " the filter the list binding carries since the last confirm - it stays
    " when another category is opened, as a binding's filters do
    DATA flt_status      TYPE string_table.
    DATA flt_supplier    TYPE string_table.
    DATA flt_price       TYPE abap_bool.
    " the out-of-stock product waiting for the OK of its confirmation box
    DATA add_pending     TYPE string.
    " the cart entry waiting for the DELETE of its confirmation box
    DATA delete_pending  TYPE string.
    DATA delete_list     TYPE string.
    " the wizard's progress is past the payment step / the invoice step -
    " set by the activate events of every step behind it, cleared when that
    " progress is discarded. What getProgressStep( ) tells the original
    DATA payment_passed  TYPE abap_bool.
    DATA invoice_passed  TYPE abap_bool.
    " the values before the change a warning asks about: NO puts them back,
    " as the original's _oHistory
    DATA pay_type_prev   TYPE string.
    DATA del_prev        TYPE abap_bool.

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
    METHODS page_comparison
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_cart
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_checkout
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_summary
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS page_order_completed
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS dialogs
      IMPORTING
        parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS on_event.
    METHODS on_event_shop
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS on_event_cart
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS on_event_checkout
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS route_to
      IMPORTING
        name     TYPE string
        category TYPE string OPTIONAL
        product  TYPE string OPTIONAL
        item1    TYPE string OPTIONAL
        item2    TYPE string OPTIONAL.
    METHODS route_apply.
    METHODS set_layout
      IMPORTING
        columns TYPE string.
    METHODS nav_to
      IMPORTING
        nav  TYPE string
        page TYPE string.
    METHODS category_load
      IMPORTING
        category  TYPE string
        productid TYPE string OPTIONAL.
    METHODS filter_confirm.
    METHODS filter_match
      IMPORTING
        product       TYPE ty_s_product
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS category_rows
      IMPORTING
        category  TYPE string
        productid TYPE string OPTIONAL.
    METHODS product_show
      IMPORTING
        productid TYPE string.
    METHODS product_route
      IMPORTING
        productid TYPE string
        name      TYPE string DEFAULT `product`.
    METHODS category_of
      IMPORTING
        productid     TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS detail_of
      IMPORTING
        productid     TYPE string
      RETURNING
        VALUE(result) TYPE ty_s_detail.
    METHODS comparison_show.
    METHODS cart_add
      IMPORTING
        productid TYPE string.
    METHODS cart_add_request
      IMPORTING
        productid TYPE string.
    METHODS cart_delete.
    METHODS cart_edit_toggle.
    METHODS cart_show_product
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
    METHODS entry_of
      IMPORTING
        productid     TYPE string
      RETURNING
        VALUE(result) TYPE ty_s_entry.
    METHODS input_check
      IMPORTING
        field TYPE string.
    METHODS input_error
      IMPORTING
        field         TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS string_error
      IMPORTING
        val           TYPE string
        min           TYPE i
        max           TYPE i OPTIONAL
        regex         TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE string.
    METHODS step_valid
      IMPORTING
        fields        TYPE string_table
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS steps_check.
    METHODS messages_refresh.
    METHODS messages_clear.
    METHODS pay_type_apply.
    METHODS delivery_apply.
    METHODS wizard_branch.
    METHODS wizard_reset.
    METHODS wizard_to_step
      IMPORTING
        step TYPE string.
    METHODS row_of
      IMPORTING
        product       TYPE ty_s_product
      RETURNING
        VALUE(result) TYPE ty_s_row.
    METHODS status_text
      IMPORTING
        status        TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS status_state
      IMPORTING
        status        TYPE string
      RETURNING
        VALUE(result) TYPE string.
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
            )->a( n = `xmlns:l`      v = `sap.ui.layout`
            )->a( n = `xmlns:form`   v = `sap.ui.layout.form`
            )->a( n = `xmlns:core`   v = `sap.ui.core`
            )->a( n = `xmlns:z2ui5`  v = `z2ui5.cc` ).

    " the read half of the original's LocalStorageModel: an invisible control
    " that reads the key and fires `finished` when what it finds differs from
    " the bound value. The write half is the STORE_DATA action in cart_refresh( )
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
                                                 s_ctrl = VALUE #( check_queue_last = abap_true ) ) ).

    " Welcome.controller's carousel loop: every eight seconds the carousel's
    " next( ), and a page change restarts the wait (onCarouselPageChanged,
    " wired on the carousel below). Both are control calls wired into the
    " view, so the loop runs in the browser with no round-trip, as there
    view->tag( n = `Timer` ns = `z2ui5`
        )->a( n = `id`          v = `carouselTimer`
        )->a( n = `delayMS`     v = `8000`
        )->a( n = `checkRepeat` b = abap_true
        )->a( n = `finished`    v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                              t_arg = VALUE #( ( `welcomeCarousel` ) ( `next` ) ) ) ).

    dialogs( view ).

    " App.view.xml: the App and its FlexibleColumnLayout, both with the
    " sapUiDemoCart class the style.css rules are scoped under. stateChange
    " is BaseController.onStateChange - it keeps smallScreenMode and turns a
    " OneColumn layout back into two columns once there is room. The FCL
    " fires it while the initial view renders, which is why the wire queues
    " (check_queue_last), like the storage read above
    DATA(fcl) = view->ele( `App`
        )->a( n = `id`    v = `app`
        )->a( n = `class` v = `sapUiDemoCart`

        )->ele( n = `FlexibleColumnLayout` ns = `f`
            )->a( n = `id`               v = `layout`
            )->a( n = `layout`           v = client->_bind( layout )
            )->a( n = `backgroundDesign` v = `Translucent`
            )->a( n = `class`            v = `sapUiDemoCart`
            )->a( n = `stateChange`      v = client->_event( val    = `STATE_CHANGE`
                                                             t_arg  = VALUE #( ( `${$parameters>/maxColumnsCount}` )
                                                                               ( `${$parameters>/layout}` ) )
                                                             s_ctrl = VALUE #( check_queue_last = abap_true ) ) ).

    " the router's targets, column by column (manifest.json): home, category,
    " checkout and ordercompleted go to the begin column, welcome, product
    " and comparison to the mid column, the cart to the end column
    DATA(nav_begin) = fcl->ele( n = `beginColumnPages` ns = `f`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav-begin` ).
    page_home( nav_begin ).
    page_category( nav_begin ).
    page_checkout( nav_begin ).
    page_order_completed( nav_begin ).

    DATA(nav_mid) = fcl->ele( n = `midColumnPages` ns = `f`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav-mid` ).
    page_welcome( nav_mid ).
    page_product( nav_mid ).
    page_comparison( nav_mid ).

    DATA(nav_end) = fcl->ele( n = `endColumnPages` ns = `f`
        )->ele( `NavContainer`
            )->a( n = `id` v = `nav-end` ).
    page_cart( nav_end ).

    client->view_display( view->stringify( ) ).

    " a rebuilt NavContainer starts on its first page while the page a column
    " should show survives as class state - re-issue all of them
    nav_to( nav = `nav-begin`          page = page_begin ).
    nav_to( nav = `nav-mid`            page = page_mid ).
    nav_to( nav = `nav-end`            page = page_end ).
    nav_to( nav = `wizardNavContainer` page = page_wizard ).

    " the same for the wizard's branches: nextStep is an association no
    " binding can carry, and XMLView.create has just rebuilt the steps, so the
    " payment branch and the delivery-address branch are re-issued here or
    " they are gone after any redisplay (sample z2ui5_cl_smp_app_202, and the
    " linter's control-state-lost-on-rebuild)
    wizard_branch( ).

    " Welcome.controller.onInit: the carousel opens on a page drawn at random
    " (model_init draws it, so a rebuilt view opens on the same one)
    IF carousel_page IS NOT INITIAL.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `welcomeCarousel` ) ( `setActivePage` ) ( carousel_page ) ) ).
    ENDIF.

  ENDMETHOD.


  METHOD dialogs.

    " the two popups the original creates in its controllers - the category
    " filter (CategoryFilterDialog.fragment.xml) and the checkout's
    " MessagePopover - held in the view's dependents and opened by id from a
    " view-wired control call, so opening either costs no round-trip
    DATA(dependents) = parent->ele( n = `dependents` ns = `mvc` ).

    " every selection of the dialog is two-way bound: the ViewSettingsItems'
    " `selected`, the RangeSlider's two values and the custom item's
    " filterCount. The dialog restores its items itself on cancel, so what
    " arrives with confirm, cancel and reset is what it shows
    dependents->ele( `ViewSettingsDialog`
        )->a( n = `id`           v = `categoryFilterDialog`
        )->a( n = `confirm`      v = client->_event( `FILTER_CONFIRM` )
        )->a( n = `cancel`       v = client->_event( `FILTER_CANCEL` )
        )->a( n = `resetFilters` v = client->_event( `FILTER_RESET` )

        )->ele( `filterItems`
            )->ele( `ViewSettingsFilterItem`
                )->a( n = `text` v = `Availability`
                )->a( n = `key`  v = `availabilityKey`

                )->ele( `items`
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text`     v = `Available`
                        )->a( n = `key`      v = `Available`
                        )->a( n = `selected` v = client->_bind( flt_available )
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text`     v = `Out of Stock`
                        )->a( n = `key`      v = `OutOfStock`
                        )->a( n = `selected` v = client->_bind( flt_out_of_stock )
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text`     v = `Discontinued`
                        )->a( n = `key`      v = `Discontinued`
                        )->a( n = `selected` v = client->_bind( flt_discontinued )

                )->end(
            )->end(
            )->ele( `ViewSettingsCustomItem`
                )->a( n = `text`        v = `Price`
                )->a( n = `key`         v = `Price`
                )->a( n = `filterCount` v = client->_bind( flt_price_count )

                )->ele( `customControl`
                    )->ele( n = `VerticalLayout` ns = `l`
                        )->a( n = `width` v = `100%`
                        )->a( n = `class` v = `sapUiContentPadding`

                        )->tag( `RangeSlider`
                            )->a( n = `id`     v = `rangeSlider`
                            )->a( n = `width`  v = `100%`
                            )->a( n = `value`  v = client->_bind( flt_low )
                            )->a( n = `value2` v = client->_bind( flt_high )
                            )->a( n = `class`  v = `sapUiSmallMarginTop`
                            )->a( n = `max`    v = `5000`
                            )->a( n = `step`   v = `10`
                            )->a( n = `change` v = client->_event( val   = `FILTER_CHANGE`
                                                                   t_arg = VALUE #( ( `${$parameters>/range}[0]` )
                                                                                    ( `${$parameters>/range}[1]` ) ) )

                    )->end(
                )->end(
            )->end(
            )->ele( `ViewSettingsFilterItem`
                )->a( n = `text`  v = `Supplier`
                )->a( n = `key`   v = `supplierKey`
                )->a( n = `items` v = client->_bind( t_suppliers )

                )->ele( `items`
                    )->tag( `ViewSettingsItem`
                        )->a( n = `text`     v = `{SUPPLIERNAME}`
                        )->a( n = `key`      v = `{SUPPLIERNAME}`
                        )->a( n = `selected` v = `{SELECTED}` ).

    " Checkout.controller.onShowMessagePopoverPress: the message model's
    " entries, each with the original's "Show more information" link
    dependents->ele( `MessagePopover`
        )->a( n = `id`    v = `messagePopover`
        )->a( n = `items` v = client->_bind( t_messages )

        )->ele( `items`
            )->ele( `MessageItem`
                )->a( n = `type`     v = `{TYPE}`
                )->a( n = `title`    v = `{MESSAGE}`
                )->a( n = `subtitle` v = `{ADDITIONALTEXT}`

                )->ele( `link`
                    )->tag( `Link`
                        )->a( n = `text`   v = `Show more information`
                        )->a( n = `href`   v = `http://sap.com`
                        )->a( n = `target` v = `_blank` ).

  ENDMETHOD.


  METHOD page_home.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `page-home`
        )->a( n = `title`            v = `Product Catalog`
        )->a( n = `backgroundDesign` v = `Solid` ).

    page->ele( `landmarkInfo`
        )->tag( `PageAccessibleLandmarkInfo`
            )->a( n = `rootRole`       v = `Region`
            )->a( n = `rootLabel`      v = `Product Catalog Search and Navigation`
            )->a( n = `subHeaderRole`  v = `Search`
            )->a( n = `subHeaderLabel` v = `Products`
            )->a( n = `contentRole`    v = `Navigation`
            )->a( n = `contentLabel`   v = `List Of Categories`
            )->a( n = `headerRole`     v = `Region`
            )->a( n = `headerLabel`    v = `Home Header` ).

    page->ele( `headerContent`
        )->tag( `Button`
            )->a( n = `icon`    v = `sap-icon://home`
            )->a( n = `press`   v = client->_event( `HOME` )
            )->a( n = `visible` v = client->_bind( small_screen ) ).

    " the search runs on every keystroke (liveChange), as the original's
    " does. The text travels as the event's argument and the field's value is
    " NOT bound: a bound value would come back with every response and
    " overwrite what was typed while the round-trip was on its way. The queue
    " keeps the last keystroke when they come faster than the round-trips
    page->ele( `subHeader`
        )->ele( `Toolbar`
            )->a( n = `id` v = `searchBar33343`

            )->tag( `SearchField`
                )->a( n = `id`          v = `searchField`
                )->a( n = `liveChange`  v = client->_event( val    = `SEARCH`
                                                            arg    = `${$parameters>/newValue}`
                                                            s_ctrl = VALUE #( check_queue_last = abap_true
                                                                              check_no_busy    = abap_true ) )
                )->a( n = `placeholder` v = `Search`
                )->a( n = `tooltip`     v = `Search`
                )->a( n = `width`       v = `100%` ).

    DATA(content) = page->ele( `content` ).

    content->tag( `PullToRefresh`
        )->a( n = `id`      v = `pullToRefresh`
        )->a( n = `visible` v = `{device>/support/touch}`
        )->a( n = `refresh` v = client->_event( `SEARCH_REFRESH` ) ).

    " the search results. On a desktop the list is SingleSelectMaster and a
    " click SELECTS the row - ListItemBase.ontap takes the
    " isIncludedIntoSelection( ) branch and never fires the item's press - so
    " the navigation hangs off the list's selectionChange; on a phone the
    " list has no mode and the item's press carries it, as there
    content->ele( `List`
        )->a( n = `id`                 v = `productList`
        )->a( n = `visible`            v = client->_bind( search_visible )
        )->a( n = `mode`               v = `{= ${device>/system/phone} ? 'None' : 'SingleSelectMaster'}`
        )->a( n = `selectionChange`    v = client->_event( val = `PRODUCT_SELECT`
                                                           arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )
        )->a( n = `noDataText`         v = `No products found`
        )->a( n = `busyIndicatorDelay` v = `0`
        )->a( n = `items`              v = client->_bind( t_search )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `type`             v = `{= ${device>/system/phone} ? 'Active' : 'Inactive'}`
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `EUR`
                )->a( n = `press`            v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )
                )->a( n = `iconDensityAware` b = abap_false

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `text` v = `{SUPPLIERNAME}`

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

    content->ele( `List`
        )->a( n = `id`                 v = `categoryList`
        )->a( n = `headerText`         v = `Categories`
        " _search( ) shows ONE of the two lists: the categories give way to the
        " search results and come back when the field is cleared
        )->a( n = `visible`            v = |\{= !${ client->_bind( search_visible ) } \}|
        )->a( n = `mode`               v = `None`
        )->a( n = `busyIndicatorDelay` v = `0`
        )->a( n = `items`              v = client->_bind( t_categories )

        )->ele( `items`
            )->tag( `StandardListItem`
                )->a( n = `title`   v = `{CATEGORYNAME}`
                )->a( n = `type`    v = `Active`
                )->a( n = `counter` v = `{NUMBEROFPRODUCTS}`
                )->a( n = `press`   v = client->_event( val = `CATEGORY` arg = `${CATEGORY}` )
                )->a( n = `tooltip` v = `Open category {CATEGORYNAME}` ).

  ENDMETHOD.


  METHOD page_category.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `page-category`
        )->a( n = `title`            v = client->_bind( category_name )
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `showNavButton`    b = abap_true
        )->a( n = `navButtonPress`   v = client->_event( `BACK_CATEGORIES` ) ).

    page->ele( `landmarkInfo`
        )->tag( `PageAccessibleLandmarkInfo`
            )->a( n = `rootRole`     v = `Region`
            )->a( n = `rootLabel`    v = `Category`
            )->a( n = `contentRole`  v = `Main`
            )->a( n = `contentLabel` v = |{ client->_bind( category_name ) } Items of Category|
            )->a( n = `footerRole`   v = `Region`
            )->a( n = `footerLabel`  v = `Filter`
            )->a( n = `headerRole`   v = `Region`
            )->a( n = `headerLabel`  v = `Category Header` ).

    page->ele( `headerContent`
        )->tag( `Button`
            )->a( n = `id`    v = `masterListFilterButton`
            )->a( n = `icon`  v = `sap-icon://filter`
            )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                            t_arg = VALUE #( ( `categoryFilterDialog` ) ( `open` ) ) ) ).

    " the product list of the category. `selected` is bound, so the product
    " a product route opens is the selected row, as fnDataReceived selects it
    page->ele( `content`
        )->ele( `List`
            )->a( n = `id`                 v = `categoryProductList`
            )->a( n = `mode`               v = `{= ${device>/system/phone} ? 'None' : 'SingleSelectMaster'}`
            )->a( n = `selectionChange`    v = client->_event( val = `CATEGORY_PRODUCT`
                                                               arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )
            )->a( n = `noDataText`         v = `No products found`
            )->a( n = `busyIndicatorDelay` v = `0`
            )->a( n = `items`              v = client->_bind( t_category )

            )->ele( `infoToolbar`
                )->ele( `Toolbar`
                    )->a( n = `id`      v = `categoryInfoToolbar`
                    )->a( n = `visible` v = client->_bind( info_visible )

                    )->ele( `content`
                        )->tag( `Title`
                            )->a( n = `id`   v = `categoryInfoToolbarTitle`
                            )->a( n = `text` v = client->_bind( info_text )

                    )->end(
                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ObjectListItem`
                    )->a( n = `type`             v = `{= ${device>/system/phone} ? 'Active' : 'Inactive'}`
                    )->a( n = `icon`             v = `{PICTUREURL}`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `number`           v = `{PRICE_TEXT}`
                    )->a( n = `numberUnit`       v = `{CURRENCYCODE}`
                    )->a( n = `press`            v = client->_event( val = `CATEGORY_PRODUCT` arg = `${PRODUCTID}` )
                    )->a( n = `iconDensityAware` b = abap_false
                    )->a( n = `tooltip`          v = `Open details for {NAME}`
                    )->a( n = `selected`         v = `{SELECTED}`

                    )->ele( `attributes`
                        )->tag( `ObjectAttribute`
                            )->a( n = `visible` b = abap_true
                            )->a( n = `text`    v = `{SUPPLIERNAME}`
                        )->tag( `ObjectAttribute`
                            )->a( n = `visible` v = `{device>/system/desktop}`
                            )->a( n = `active`  b = abap_true
                            )->a( n = `text`    v = `Compare`
                            )->a( n = `press`   v = client->_event( val = `COMPARE` arg = `${PRODUCTID}` )

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

    page->ele( `landmarkInfo`
        )->tag( `PageAccessibleLandmarkInfo`
            )->a( n = `rootRole`     v = `Region`
            )->a( n = `rootLabel`    v = `Product Details`
            )->a( n = `contentRole`  v = `Main`
            )->a( n = `contentLabel` v = `Product Description`
            )->a( n = `headerRole`   v = `Region`
            )->a( n = `headerLabel`  v = `Product Header`
            )->a( n = `footerRole`   v = `Region`
            )->a( n = `footerLabel`  v = `Product Footer` ).

    page->ele( `customHeader`
        )->ele( `Bar`
            )->ele( `contentLeft`
                )->tag( `Button`
                    )->a( n = `type`    v = `Back`
                    )->a( n = `visible` v = client->_bind( small_screen )
                    )->a( n = `press`   v = client->_event( `BACK` )

            )->end(
            )->ele( `contentMiddle`
                )->tag( `Title`
                    )->a( n = `level` v = `H2`
                    )->a( n = `text`  v = client->_bind( s_prod-name )

            )->end(
            )->ele( `contentRight`
                )->tag( `Button`
                    )->a( n = `icon`    v = `sap-icon://customer`
                    )->a( n = `press`   v = client->_event( `AVATAR` )
                    )->a( n = `tooltip` v = `Login`
                )->tag( `ToggleButton`
                    )->a( n = `icon`    v = `sap-icon://cart`
                    " what the original binds: `{= ${layout}.startsWith('ThreeColumns') }`.
                    " Derived from the bound layout rather than from a flag of its
                    " own, so the button on the OTHER page follows too - and an
                    " expression binding cannot be written back, which a two-way
                    " bound `pressed` would be, inverting TOGGLE_CART twice
                    )->a( n = `pressed` v = |\{= ${ client->_bind( layout ) }.startsWith('ThreeColumns') \}|
                    )->a( n = `tooltip` v = `Show Shopping Cart`
                    )->a( n = `press`   v = client->_event( val = `TOGGLE_CART` arg = `product` ) ).

    page->ele( `footer`
        )->ele( `Toolbar`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `text`  v = `Add to Cart`
                )->a( n = `type`  v = `Emphasized`
                )->a( n = `press` v = client->_event( `ADD_TO_CART` ) ).

    DATA(content) = page->ele( `content` ).

    content->ele( `ObjectHeader`
        )->a( n = `title`      v = client->_bind( s_prod-name )
        )->a( n = `titleLevel` v = `H3`
        )->a( n = `number`     v = client->_bind( s_prod-price_text )
        )->a( n = `numberUnit` v = `EUR`

        )->ele( `attributes`
            )->tag( `ObjectAttribute`
                )->a( n = `title` v = `Supplier`
                )->a( n = `text`  v = client->_bind( s_prod-suppliername )
            )->tag( `ObjectAttribute`
                )->a( n = `title` v = `Description`
                )->a( n = `text`  v = client->_bind( s_prod-shortdescription )
            )->tag( `ObjectAttribute`
                )->a( n = `title` v = `Weight`
                )->a( n = `text`  v = client->_bind( s_prod-weight_text )
            )->tag( `ObjectAttribute`
                )->a( n = `title` v = `Measures`
                )->a( n = `text`  v = client->_bind( s_prod-measures_text )

        )->end(
        )->ele( `statuses`
            )->tag( `ObjectStatus`
                )->a( n = `text`  v = client->_bind( s_prod-status_text )
                )->a( n = `state` v = client->_bind( s_prod-status_state ) ).

    " the picture opens full size in the LightBox of its detailBox - the
    " Image does that itself on press, no round-trip
    content->ele( `VBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `renderType` v = `Div`

        )->ele( `Image`
            )->a( n = `id`           v = `productImage`
            )->a( n = `src`          v = client->_bind( s_prod-pictureurl )
            )->a( n = `decorative`   b = abap_true
            )->a( n = `densityAware` b = abap_false
            )->a( n = `class`        v = `sapUiSmallMargin`
            )->a( n = `width`        v = `100%`
            )->a( n = `height`       v = `100%`

            )->ele( `detailBox`
                )->ele( `LightBox`
                    )->a( n = `id` v = `lightBox`

                    )->ele( `imageContent`
                        )->tag( `LightBoxItem`
                            )->a( n = `imageSrc` v = client->_bind( s_prod-pictureurl )
                            )->a( n = `title`    v = client->_bind( s_prod-name ) ).

  ENDMETHOD.


  METHOD page_comparison.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `page-comparison`
        )->a( n = `backgroundDesign` v = `Solid` ).

    page->ele( `customHeader`
        )->ele( `Bar`
            )->ele( `contentMiddle`
                )->tag( `Title`
                    )->a( n = `level` v = `H2`
                    )->a( n = `text`  v = `Product Comparison`

            )->end(
            )->ele( `contentRight`
                )->tag( `Button`
                    )->a( n = `icon`    v = `sap-icon://customer`
                    )->a( n = `press`   v = client->_event( `AVATAR` )
                    )->a( n = `tooltip` v = `Login`
                )->tag( `ToggleButton`
                    )->a( n = `icon`    v = `sap-icon://cart`
                    )->a( n = `pressed` v = |\{= ${ client->_bind( layout ) }.startsWith('ThreeColumns') \}|
                    )->a( n = `tooltip` v = `Show Shopping Cart`
                    )->a( n = `press`   v = client->_event( val = `TOGGLE_CART` arg = `comparison` ) ).

    " the two ComparisonItem fragments, written out once each: the panel of
    " a product the route does not carry is hidden, and the placeholder with
    " the how-to shows instead (_onRoutePatternMatched's updatePanel)
    DATA(box) = page->ele( `content`
        )->ele( `ScrollContainer`
            )->a( n = `height`     v = `100%`
            )->a( n = `width`      v = `100%`
            )->a( n = `horizontal` b = abap_false
            )->a( n = `vertical`   b = abap_true
            )->a( n = `focusable`  b = abap_false

            )->ele( `HBox`
                )->a( n = `class` v = `comparebox`
                )->a( n = `id`    v = `comparisonContainer` ).

    box->ele( `Panel`
        )->a( n = `height`  v = `100%`
        )->a( n = `visible` v = client->_bind( cmp1_visible )

        )->ele( `headerToolbar`
            )->ele( `Toolbar`
                )->tag( `Text`
                    )->a( n = `text` v = |{ client->_bind( s_cmp1-name ) } - { client->_bind( s_cmp1-productid ) }|
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `icon`    v = `sap-icon://sys-cancel`
                    )->a( n = `press`   v = client->_event( val = `CMP_REMOVE` arg = `1` )
                    )->a( n = `tooltip` v = `Remove Product from Comparison`

            )->end(
        )->end(
        )->ele( `HBox`
            )->a( n = `class` v = `comparebox`

            )->ele( `VBox`
                )->ele( `Image`
                    )->a( n = `src`          v = client->_bind( s_cmp1-pictureurl )
                    )->a( n = `alt`          v = `Enlarge picture of product`
                    )->a( n = `densityAware` b = abap_false
                    )->a( n = `class`        v = `sapUiSmallMarginTop`
                    )->a( n = `width`        v = `100%`
                    )->a( n = `height`       v = `100%`

                    )->ele( `detailBox`
                        )->ele( `LightBox`
                            )->ele( `imageContent`
                                )->tag( `LightBoxItem`
                                    )->a( n = `imageSrc` v = client->_bind( s_cmp1-pictureurl )
                                    )->a( n = `title`    v = client->_bind( s_cmp1-name )

                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
            )->ele( `VBox`
                )->a( n = `alignItems` v = `End`

                )->tag( `ObjectListItem`
                    )->a( n = `class`      v = `productPrice welcomePrice`
                    )->a( n = `number`     v = client->_bind( s_cmp1-price_text )
                    )->a( n = `numberUnit` v = `EUR`
                )->tag( `ObjectStatus`
                    )->a( n = `class` v = `sapUiSmallMarginBottom`
                    )->a( n = `text`  v = client->_bind( s_cmp1-status_text )
                    )->a( n = `state` v = client->_bind( s_cmp1-status_state )
                )->tag( `Button`
                    )->a( n = `text`  v = `Add to Cart`
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->_event( val = `CMP_ADD_TO_CART` arg = `1` )

            )->end(
        )->end(
        )->ele( n = `Form` ns = `form`
            )->a( n = `editable` b = abap_false

            )->ele( n = `layout` ns = `form`
                )->tag( n = `ResponsiveGridLayout` ns = `form`
                    )->a( n = `labelSpanXL`             v = `12`
                    )->a( n = `labelSpanL`              v = `12`
                    )->a( n = `labelSpanM`              v = `12`
                    )->a( n = `labelSpanS`              v = `12`
                    )->a( n = `adjustLabelSpan`         b = abap_false
                    )->a( n = `emptySpanXL`             v = `4`
                    )->a( n = `emptySpanL`              v = `4`
                    )->a( n = `emptySpanM`              v = `4`
                    )->a( n = `emptySpanS`              v = `0`
                    )->a( n = `singleContainerFullSize` b = abap_false

            )->end(
            )->ele( n = `formContainers` ns = `form`
                )->ele( n = `FormContainer` ns = `form`
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Supplier`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( s_cmp1-suppliername )

                        )->end(
                    )->end(
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Description`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( s_cmp1-shortdescription )

                        )->end(
                    )->end(
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Weight`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( s_cmp1-weight_text )

                        )->end(
                    )->end(
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Measures`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( s_cmp1-measures_text ) ).

    box->ele( `Panel`
        )->a( n = `height`  v = `100%`
        )->a( n = `visible` v = client->_bind( cmp2_visible )

        )->ele( `headerToolbar`
            )->ele( `Toolbar`
                )->tag( `Text`
                    )->a( n = `text` v = |{ client->_bind( s_cmp2-name ) } - { client->_bind( s_cmp2-productid ) }|
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `icon`    v = `sap-icon://sys-cancel`
                    )->a( n = `press`   v = client->_event( val = `CMP_REMOVE` arg = `2` )
                    )->a( n = `tooltip` v = `Remove Product from Comparison`

            )->end(
        )->end(
        )->ele( `HBox`
            )->a( n = `class` v = `comparebox`

            )->ele( `VBox`
                )->ele( `Image`
                    )->a( n = `src`          v = client->_bind( s_cmp2-pictureurl )
                    )->a( n = `alt`          v = `Enlarge picture of product`
                    )->a( n = `densityAware` b = abap_false
                    )->a( n = `class`        v = `sapUiSmallMarginTop`
                    )->a( n = `width`        v = `100%`
                    )->a( n = `height`       v = `100%`

                    )->ele( `detailBox`
                        )->ele( `LightBox`
                            )->ele( `imageContent`
                                )->tag( `LightBoxItem`
                                    )->a( n = `imageSrc` v = client->_bind( s_cmp2-pictureurl )
                                    )->a( n = `title`    v = client->_bind( s_cmp2-name )

                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
            )->ele( `VBox`
                )->a( n = `alignItems` v = `End`

                )->tag( `ObjectListItem`
                    )->a( n = `class`      v = `productPrice welcomePrice`
                    )->a( n = `number`     v = client->_bind( s_cmp2-price_text )
                    )->a( n = `numberUnit` v = `EUR`
                )->tag( `ObjectStatus`
                    )->a( n = `class` v = `sapUiSmallMarginBottom`
                    )->a( n = `text`  v = client->_bind( s_cmp2-status_text )
                    )->a( n = `state` v = client->_bind( s_cmp2-status_state )
                )->tag( `Button`
                    )->a( n = `text`  v = `Add to Cart`
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->_event( val = `CMP_ADD_TO_CART` arg = `2` )

            )->end(
        )->end(
        )->ele( n = `Form` ns = `form`
            )->a( n = `editable` b = abap_false

            )->ele( n = `layout` ns = `form`
                )->tag( n = `ResponsiveGridLayout` ns = `form`
                    )->a( n = `labelSpanXL`             v = `12`
                    )->a( n = `labelSpanL`              v = `12`
                    )->a( n = `labelSpanM`              v = `12`
                    )->a( n = `labelSpanS`              v = `12`
                    )->a( n = `adjustLabelSpan`         b = abap_false
                    )->a( n = `emptySpanXL`             v = `4`
                    )->a( n = `emptySpanL`              v = `4`
                    )->a( n = `emptySpanM`              v = `4`
                    )->a( n = `emptySpanS`              v = `0`
                    )->a( n = `singleContainerFullSize` b = abap_false

            )->end(
            )->ele( n = `formContainers` ns = `form`
                )->ele( n = `FormContainer` ns = `form`
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Supplier`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( s_cmp2-suppliername )

                        )->end(
                    )->end(
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Description`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( s_cmp2-shortdescription )

                        )->end(
                    )->end(
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Weight`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( s_cmp2-weight_text )

                        )->end(
                    )->end(
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Measures`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = client->_bind( s_cmp2-measures_text ) ).

    box->ele( `Panel`
        )->a( n = `id`      v = `placeholder`
        )->a( n = `visible` v = client->_bind( cmp_placeholder )

        )->ele( `headerToolbar`
            )->ele( `Toolbar`
                )->tag( `Text`
                    )->a( n = `text` v = `How to Compare Products`

            )->end(
        )->end(
        )->ele( n = `Form` ns = `form`
            )->a( n = `editable` b = abap_false

            )->ele( n = `layout` ns = `form`
                )->tag( n = `ResponsiveGridLayout` ns = `form`
                    )->a( n = `labelSpanXL`             v = `12`
                    )->a( n = `labelSpanL`              v = `12`
                    )->a( n = `labelSpanM`              v = `12`
                    )->a( n = `labelSpanS`              v = `12`
                    )->a( n = `adjustLabelSpan`         b = abap_false
                    )->a( n = `emptySpanXL`             v = `4`
                    )->a( n = `emptySpanL`              v = `4`
                    )->a( n = `emptySpanM`              v = `4`
                    )->a( n = `emptySpanS`              v = `0`
                    )->a( n = `singleContainerFullSize` b = abap_false

            )->end(
            )->ele( n = `formContainers` ns = `form`
                )->ele( n = `FormContainer` ns = `form`
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Add`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = `Choose 'Compare' for each product you want to add to the comparison.`

                        )->end(
                    )->end(
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Compare`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = `As soon as you have selected two products, you can compare the specifications.`

                        )->end(
                    )->end(
                    )->ele( n = `FormElement` ns = `form`
                        )->a( n = `label` v = `Remove`

                        )->ele( n = `fields` ns = `form`
                            )->tag( `Text`
                                )->a( n = `text` v = `Choose 'x' for a product to remove it from the selection.` ).

  ENDMETHOD.


  METHOD page_cart.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `page-cart`
        )->a( n = `title`            v = client->_bind( cart_title )
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `showNavButton`    v = client->_bind( small_screen )
        )->a( n = `navButtonPress`   v = client->_event( `BACK` )
        )->a( n = `showFooter`       b = abap_true ).

    page->ele( `landmarkInfo`
        )->tag( `PageAccessibleLandmarkInfo`
            )->a( n = `rootRole`     v = `Region`
            )->a( n = `rootLabel`    v = `Shopping Cart`
            )->a( n = `contentRole`  v = `Main`
            )->a( n = `contentLabel` v = `Items in Shopping Cart`
            )->a( n = `footerRole`   v = `Region`
            )->a( n = `footerLabel`  v = `Shopping Cart Footer`
            )->a( n = `headerRole`   v = `Region`
            )->a( n = `headerLabel`  v = `Shopping Cart Header` ).

    " the cfg> model of Cart.controller: inDelete switches the two lists into
    " Delete mode, hides Edit and Proceed and shows Save Changes
    page->ele( `headerContent`
        )->tag( `Button`
            )->a( n = `id`      v = `editButton`
            )->a( n = `icon`    v = `sap-icon://edit`
            )->a( n = `enabled` v = client->_bind( cart_any )
            )->a( n = `visible` v = |\{= !${ client->_bind( in_delete ) } \}|
            )->a( n = `press`   v = client->_event( `EDIT_TOGGLE` )
            )->a( n = `tooltip` v = `Edit your cart` ).

    page->ele( `footer`
        )->ele( `Toolbar`
            )->tag( `Text`
                )->a( n = `id`    v = `totalPriceText`
                )->a( n = `text`  v = client->_bind( cart_total )
                )->a( n = `class` v = `sapUiTinyMarginBegin`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `id`      v = `proceedButton`
                )->a( n = `type`    v = `Accept`
                )->a( n = `text`    v = `Proceed`
                )->a( n = `enabled` v = client->_bind( cart_filled )
                )->a( n = `visible` v = |\{= !${ client->_bind( in_delete ) } \}|
                )->a( n = `press`   v = client->_event( `PROCEED` )
            )->tag( `Button`
                )->a( n = `id`      v = `doneButton`
                )->a( n = `text`    v = `Save Changes`
                )->a( n = `enabled` b = abap_true
                )->a( n = `visible` v = client->_bind( in_delete )
                )->a( n = `press`   v = client->_event( `EDIT_TOGGLE` ) ).

    DATA(content) = page->ele( `content` ).

    " a row of either list opens its product: on a desktop through the
    " SingleSelectMaster selection (onEntryListSelect), on a phone through the
    " item press (onEntryListPress) - which also closes the cart
    content->ele( `List`
        )->a( n = `delete`          v = client->_event( val   = `CART_DELETE`
                                                        t_arg = VALUE #( ( `entryList` )
                                                                         ( `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` ) ) )
        )->a( n = `id`              v = `entryList`
        )->a( n = `items`           v = client->_bind( t_cart )
        )->a( n = `mode`            v = |\{= ${ client->_bind( in_delete ) } ? 'Delete' : $\{device>/system/phone\} ? 'None' : 'SingleSelectMaster' \}|
        )->a( n = `noDataText`      v = `Your cart is empty`
        )->a( n = `selectionChange` v = client->_event( val = `CART_SELECT`
                                                        arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )

        )->ele( `headerToolbar`
            )->ele( `Toolbar`
                )->tag( `Title`
                    )->a( n = `level`      v = `H6`
                    )->a( n = `text`       v = `Items in Shopping Cart`
                    )->a( n = `titleStyle` v = `H6`

            )->end(
        )->end(
        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `intro`            v = `{QUANTITY} x`
                )->a( n = `type`             v = |\{= ${ client->_bind( in_delete ) } ? 'Inactive' : $\{device>/system/phone\} ? 'Active' : 'Inactive' \}|
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `EUR`
                )->a( n = `press`            v = client->_event( val = `CART_PRESS` arg = `${PRODUCTID}` )
                )->a( n = `iconDensityAware` b = abap_false

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` b = abap_true
                        )->a( n = `press`  v = client->_event( val = `SAVE_LATER` arg = `${PRODUCTID}` )
                        )->a( n = `text`   v = `Save for Later`

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

    content->ele( `List`
        )->a( n = `delete`          v = client->_event( val   = `CART_DELETE`
                                                        t_arg = VALUE #( ( `saveForLaterList` )
                                                                         ( `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` ) ) )
        )->a( n = `id`              v = `saveForLaterList`
        )->a( n = `items`           v = client->_bind( t_saved )
        )->a( n = `mode`            v = |\{= ${ client->_bind( in_delete ) } ? 'Delete' : $\{device>/system/phone\} ? 'None' : 'SingleSelectMaster' \}|
        )->a( n = `noDataText`      v = `No items saved for later`
        )->a( n = `selectionChange` v = client->_event( val = `CART_SELECT`
                                                        arg = `${$parameters>/listItem}.getBindingContext().getProperty('PRODUCTID')` )

        )->ele( `headerToolbar`
            )->ele( `Toolbar`
                )->tag( `Title`
                    )->a( n = `level`      v = `H6`
                    )->a( n = `text`       v = `Items saved for later`
                    )->a( n = `titleStyle` v = `H6`

            )->end(
        )->end(
        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `intro`            v = `{QUANTITY} x`
                )->a( n = `type`             v = |\{= ${ client->_bind( in_delete ) } ? 'Inactive' : $\{device>/system/phone\} ? 'Active' : 'Inactive' \}|
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `EUR`
                )->a( n = `press`            v = client->_event( val = `CART_PRESS` arg = `${PRODUCTID}` )
                )->a( n = `iconDensityAware` b = abap_false

                )->ele( `attributes`
                    )->tag( `ObjectAttribute`
                        )->a( n = `active` b = abap_true
                        )->a( n = `press`  v = client->_event( val = `ADD_BACK` arg = `${PRODUCTID}` )
                        )->a( n = `text`   v = `Add to Shopping Cart`

                )->end(
                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

  ENDMETHOD.


  METHOD page_welcome.

    " the i18n bundle's two-line carousel texts (`\r\n` in the properties file).
    " A literal line break survives the attribute: the builder writes it as the
    " character reference `&#xA;`, which XML attribute-value normalization -
    " it turns a raw LF into a plain space - then leaves alone
    DATA(line_break) = cl_abap_char_utilities=>newline.

    " core:require as the original's view declares it: the tiles' prices are
    " a CurrencyType binding
    DATA(page) = parent->ele( `Page`
        )->a( n = `id`           v = `page-welcome`
        )->a( n = `core:require` v = `{CurrencyType: 'sap/ui/model/type/Currency'}` ).

    page->ele( `landmarkInfo`
        )->tag( `PageAccessibleLandmarkInfo`
            )->a( n = `rootRole`     v = `Region`
            )->a( n = `rootLabel`    v = `Welcome Page`
            )->a( n = `contentRole`  v = `Main`
            )->a( n = `contentLabel` v = `Selected Products`
            )->a( n = `headerRole`   v = `Region`
            )->a( n = `headerLabel`  v = `Welcome Header` ).

    page->ele( `customHeader`
        )->ele( `Bar`
            )->ele( `contentLeft`
                )->tag( `Button`
                    )->a( n = `icon`    v = `sap-icon://menu2`
                    )->a( n = `press`   v = client->_event( `SHOW_CATEGORIES` )
                    )->a( n = `visible` v = client->_bind( small_screen )

            )->end(
            )->ele( `contentMiddle`
                )->tag( `Title`
                    )->a( n = `level`   v = `H2`
                    )->a( n = `text`    v = `Welcome to the Shopping Cart`
                    )->a( n = `tooltip` v = `This demo app shows you how to use the sap.m library for a classical shopping cart. ` &&
                                            `You can browse and search a catalog of products, add the chosen products to your ` &&
                                            `shopping cart and, once happy with your selection order the cart contents.`

            )->end(
            )->ele( `contentRight`
                )->tag( `Button`
                    )->a( n = `icon`    v = `sap-icon://customer`
                    )->a( n = `tooltip` v = `Login`
                    )->a( n = `press`   v = client->_event( `AVATAR` )
                )->tag( `ToggleButton`
                    )->a( n = `icon`    v = `sap-icon://cart`
                    " what the original binds: `{= ${layout}.startsWith('ThreeColumns') }`.
                    " Derived from the bound layout rather than from a flag of its
                    " own, so the button on the OTHER page follows too - and an
                    " expression binding cannot be written back, which a two-way
                    " bound `pressed` would be, inverting TOGGLE_CART twice
                    )->a( n = `pressed` v = |\{= ${ client->_bind( layout ) }.startsWith('ThreeColumns') \}|
                    )->a( n = `tooltip` v = `Show Shopping Cart`
                    )->a( n = `press`   v = client->_event( val = `TOGGLE_CART` arg = `welcome` ) ).

    DATA(content) = page->ele( `content` ).

    " the app's style.css, rule for rule, under the same `.sapUiDemoCart`
    " scope - the class the App and the FlexibleColumnLayout carry here as
    " there. \{ \} escaped: the XMLView parser reads an unescaped brace as a
    " binding
    content->tag( n = `HTML` ns = `core`
        )->a( n = `content` v = `<style>.sapUiDemoCart .welcomePrice\{width:100%;padding:0;border-bottom-width:0\}` &&
                                `.sapUiDemoCart .welcomeCarouselText\{color:white;display:block;position:fixed;bottom:0;` &&
                                `padding:1rem;font-size:1.5rem;width:100%;text-shadow:0 0 0.125rem black\}` &&
                                `.productPrice\{background-color:transparent\}` &&
                                `.comparebox > div\{width:48%;margin-left:1%;margin-right:1%\}</style>` ).

    " the welcome carousel. Its four teaser images are files of the demo app
    " itself - `sap/ui/demo/cart/img/...` resolved by sap.ui.require.toUrl
    " against the app's own webapp root - so they come from the demo kit's
    " deployed copy of that folder (c_img), the same rule c_base follows for
    " the product pictures
    content->ele( n = `BlockLayout` ns = `l`
        )->a( n = `background` v = `Light`

        )->ele( n = `BlockLayoutRow` ns = `l`
            )->ele( n = `BlockLayoutCell` ns = `l`
                )->a( n = `class` v = `sapUiNoContentPadding`

                " a page change restarts the eight-second wait of the timer in
                " view_display (onCarouselPageChanged), in the browser
                )->ele( `Carousel`
                    )->a( n = `id`                v = `welcomeCarousel`
                    )->a( n = `showPageIndicator` v = `false`
                    )->a( n = `loop`              v = `true`
                    )->a( n = `pageChanged`       v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                t_arg = VALUE #( ( `carouselTimer` ) ( `delayedCall` ) ) )
                    )->a( n = `visible`           v = `{=!${device>/system/phone}}`
                    )->a( n = `tooltip`           v = `This demo app shows you how to use the sap.m library for a classical shopping cart. ` &&
                                                     `You can browse and search a catalog of products, add the chosen products to your ` &&
                                                     `shopping cart and, once happy with your selection order the cart contents.`

                    )->ele( `pages`
                        )->ele( `VBox`
                            )->a( n = `id`         v = `carouselShipping`
                            )->a( n = `renderType` v = `Bare`

                            )->tag( `Image`
                                )->a( n = `src`    v = |{ c_img }Shipping_273087.jpg|
                                )->a( n = `width`  v = `100%`
                                )->a( n = `height` v = `100%`
                            )->tag( `Text`
                                )->a( n = `text`  v = |Enjoy free shipping{ line_break }for orders over 50 Euro|
                                )->a( n = `class` v = `welcomeCarouselText`

                        )->end(
                        )->ele( `VBox`
                            )->a( n = `id`         v = `carouselInviteFriend`
                            )->a( n = `renderType` v = `Bare`

                            )->tag( `Image`
                                )->a( n = `src`    v = |{ c_img }InviteFriend_276352.jpg|
                                )->a( n = `width`  v = `100%`
                                )->a( n = `height` v = `100%`
                            )->tag( `Text`
                                )->a( n = `text`  v = |Refer a Friend{ line_break } Get 20 Euro credit!|
                                )->a( n = `class` v = `welcomeCarouselText`

                        )->end(
                        )->ele( `VBox`
                            )->a( n = `id`         v = `carouselTablet`
                            )->a( n = `renderType` v = `Bare`

                            )->tag( `Image`
                                )->a( n = `src`    v = |{ c_img }Tablet_275777.jpg|
                                )->a( n = `width`  v = `100%`
                                )->a( n = `height` v = `100%`
                            )->tag( `Text`
                                )->a( n = `text`  v = |Deal of the Day{ line_break }10% on all tablets!|
                                )->a( n = `class` v = `welcomeCarouselText`

                        )->end(
                        )->ele( `VBox`
                            )->a( n = `id`         v = `carouselCreditCard`
                            )->a( n = `renderType` v = `Bare`

                            )->tag( `Image`
                                )->a( n = `src`    v = |{ c_img }CreditCard_277268.jpg|
                                )->a( n = `width`  v = `100%`
                                )->a( n = `height` v = `100%`
                            )->tag( `Text`
                                )->a( n = `text`  v = |Pay fast and safely{ line_break }with Credit Card|
                                )->a( n = `class` v = `welcomeCarouselText` ).

    " Promoted Items. The panel's rows are an aggregation binding on the
    " BlockLayoutRow's `content`, with the cell as its template - the original's
    " own shape, one tile per featured product
    DATA(promoted) = content->ele( `Panel`
        )->a( n = `id`               v = `panelPromoted`
        )->a( n = `accessibleRole`   v = `Region`
        )->a( n = `backgroundDesign` v = `Transparent`
        )->a( n = `class`            v = `sapUiNoContentPadding` ).

    promoted->ele( `headerToolbar`
        )->ele( `Toolbar`
            )->tag( `Title`
                )->a( n = `text`       v = `Promoted Items`
                )->a( n = `level`      v = `H3`
                )->a( n = `titleStyle` v = `H2`
                )->a( n = `class`      v = `sapUiMediumMarginTopBottom` ).

    promoted->ele( `content`
        )->ele( n = `BlockLayout` ns = `l`
            )->a( n = `background` v = `Dashboard`

            )->ele( n = `BlockLayoutRow` ns = `l`
                )->a( n = `id`      v = `promotedRow`
                )->a( n = `content` v = client->_bind( t_promoted )

                )->ele( n = `content` ns = `l`
                    )->ele( n = `BlockLayoutCell` ns = `l`
                        )->ele( n = `Grid` ns = `l`
                            )->a( n = `defaultSpan` v = `XL12 L12 M12 S12`
                            )->a( n = `vSpacing`    v = `0`
                            )->a( n = `hSpacing`    v = `0`

                            )->ele( `FlexBox`
                                )->a( n = `height`     v = `3.5rem`
                                )->a( n = `renderType` v = `Bare`

                                )->ele( n = `VerticalLayout` ns = `l`
                                    )->tag( `ObjectIdentifier`
                                        )->a( n = `title`       v = `{NAME}`
                                        )->a( n = `titleActive` v = `true`
                                        )->a( n = `titlePress`  v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )
                                        )->a( n = `tooltip`     v = `Open details for {NAME}`
                                        )->a( n = `class`       v = `sapUiTinyMarginBottom`
                                    )->tag( `ObjectStatus`
                                        )->a( n = `text`  v = `{STATUS_TEXT}`
                                        )->a( n = `state` v = `{STATUS_STATE}`

                                )->end(
                            )->end(
                            )->ele( `FlexBox`
                                )->a( n = `renderType`     v = `Bare`
                                )->a( n = `justifyContent` v = `Center`

                                )->tag( `Image`
                                    )->a( n = `src`          v = `{PICTUREURL}`
                                    )->a( n = `densityAware` v = `false`
                                    )->a( n = `width`        v = `50%`
                                    )->a( n = `height`       v = `50%`
                                    )->a( n = `press`        v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )
                                    )->a( n = `tooltip`      v = `Open details for {NAME}`
                                    )->a( n = `alt`          v = `This image shows {NAME}`

                            )->end(
                            )->ele( `Button`
                                )->a( n = `tooltip` v = `Add to Shopping Cart`
                                )->a( n = `type`    v = `Emphasized`
                                )->a( n = `press`   v = client->_event( val = `ADD_TO_CART` arg = `${PRODUCTID}` )
                                )->a( n = `icon`    v = `sap-icon://cart-3`

                                )->ele( `layoutData`
                                    )->tag( n = `GridData` ns = `l`
                                        )->a( n = `span` v = `XL4 L4 M4 S4`

                                )->end(
                            )->end(
                            )->ele( `ObjectListItem`
                                )->a( n = `class`      v = `welcomePrice`
                                " the original's CurrencyType binding, formatted in the
                                " browser's locale - not the price formatter the lists use
                                )->a( n = `number`     v = `{ parts: [ { path: 'PRICE' }, { path: 'CURRENCYCODE' } ], type: 'CurrencyType', formatOptions: { showMeasure: false } }`
                                )->a( n = `numberUnit` v = `{CURRENCYCODE}`

                                )->ele( `layoutData`
                                    )->tag( n = `GridData` ns = `l`
                                        )->a( n = `span` v = `XL8 L8 M8 S8` ).

    DATA(viewed) = content->ele( `Panel`
        )->a( n = `id`               v = `panelViewed`
        )->a( n = `accessibleRole`   v = `Region`
        )->a( n = `backgroundDesign` v = `Transparent`
        )->a( n = `class`            v = `sapUiNoContentPadding` ).

    viewed->ele( `headerToolbar`
        )->ele( `Toolbar`
            )->tag( `Title`
                )->a( n = `text`       v = `Recently Viewed Items`
                )->a( n = `level`      v = `H3`
                )->a( n = `titleStyle` v = `H2`
                )->a( n = `class`      v = `sapUiMediumMarginTopBottom` ).

    viewed->ele( `content`
        )->ele( n = `BlockLayout` ns = `l`
            )->a( n = `background` v = `Dashboard`

            )->ele( n = `BlockLayoutRow` ns = `l`
                )->a( n = `id`      v = `viewedRow`
                )->a( n = `content` v = client->_bind( t_viewed )

                )->ele( n = `content` ns = `l`
                    )->ele( n = `BlockLayoutCell` ns = `l`
                        )->a( n = `class` v = `sapUiContentPadding`

                        )->ele( n = `Grid` ns = `l`
                            )->a( n = `defaultSpan` v = `XL12 L12 M12 S12`
                            )->a( n = `vSpacing`    v = `0`
                            )->a( n = `hSpacing`    v = `0`

                            )->ele( `FlexBox`
                                )->a( n = `height`     v = `3.5rem`
                                )->a( n = `renderType` v = `Bare`

                                )->ele( n = `VerticalLayout` ns = `l`
                                    )->tag( `ObjectIdentifier`
                                        )->a( n = `title`       v = `{NAME}`
                                        )->a( n = `tooltip`     v = `Open details for {NAME}`
                                        )->a( n = `titleActive` v = `true`
                                        )->a( n = `titlePress`  v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )
                                        )->a( n = `class`       v = `sapUiTinyMarginBottom`
                                    )->tag( `ObjectStatus`
                                        )->a( n = `text`  v = `{STATUS_TEXT}`
                                        )->a( n = `state` v = `{STATUS_STATE}`

                                )->end(
                            )->end(
                            )->ele( `FlexBox`
                                )->a( n = `renderType`     v = `Bare`
                                )->a( n = `justifyContent` v = `Center`

                                )->tag( `Image`
                                    )->a( n = `src`     v = `{PICTUREURL}`
                                    )->a( n = `width`   v = `100%`
                                    )->a( n = `height`  v = `100%`
                                    )->a( n = `press`   v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )
                                    )->a( n = `tooltip` v = `Open details for {NAME}`
                                    )->a( n = `alt`     v = `This image shows {NAME}`

                            )->end(
                            )->ele( `Button`
                                )->a( n = `tooltip` v = `Add to Shopping Cart`
                                )->a( n = `press`   v = client->_event( val = `ADD_TO_CART` arg = `${PRODUCTID}` )
                                )->a( n = `icon`    v = `sap-icon://cart-3`
                                )->a( n = `type`    v = `Emphasized`

                                )->ele( `layoutData`
                                    )->tag( n = `GridData` ns = `l`
                                        )->a( n = `span` v = `XL4 L4 M4 S4`

                                )->end(
                            )->end(
                            )->ele( `ObjectListItem`
                                )->a( n = `class`      v = `welcomePrice`
                                " the original's CurrencyType binding, formatted in the
                                " browser's locale - not the price formatter the lists use
                                )->a( n = `number`     v = `{ parts: [ { path: 'PRICE' }, { path: 'CURRENCYCODE' } ], type: 'CurrencyType', formatOptions: { showMeasure: false } }`
                                )->a( n = `numberUnit` v = `{CURRENCYCODE}`

                                )->ele( `layoutData`
                                    )->tag( n = `GridData` ns = `l`
                                        )->a( n = `span` v = `XL8 L8 M8 S8` ).

    DATA(favorite) = content->ele( `Panel`
        )->a( n = `id`               v = `panelFavorite`
        )->a( n = `accessibleRole`   v = `Region`
        )->a( n = `backgroundDesign` v = `Transparent`
        )->a( n = `class`            v = `sapUiNoContentPadding` ).

    favorite->ele( `headerToolbar`
        )->ele( `Toolbar`
            )->tag( `Title`
                )->a( n = `text`       v = `Favorites`
                )->a( n = `level`      v = `H3`
                )->a( n = `titleStyle` v = `H2`
                )->a( n = `class`      v = `sapUiMediumMarginTopBottom` ).

    favorite->ele( `content`
        )->ele( n = `BlockLayout` ns = `l`
            )->a( n = `background` v = `Dashboard`

            )->ele( n = `BlockLayoutRow` ns = `l`
                )->a( n = `id`      v = `favoriteRow`
                )->a( n = `content` v = client->_bind( t_favorite )

                )->ele( n = `content` ns = `l`
                    )->ele( n = `BlockLayoutCell` ns = `l`
                        )->a( n = `class` v = `sapUiContentPadding`

                        )->ele( n = `Grid` ns = `l`
                            )->a( n = `defaultSpan` v = `XL12 L12 M12 S12`
                            )->a( n = `vSpacing`    v = `0`
                            )->a( n = `hSpacing`    v = `0`

                            )->ele( `FlexBox`
                                )->a( n = `height`     v = `3.5rem`
                                )->a( n = `renderType` v = `Bare`

                                )->ele( n = `VerticalLayout` ns = `l`
                                    )->tag( `ObjectIdentifier`
                                        )->a( n = `title`       v = `{NAME}`
                                        )->a( n = `tooltip`     v = `Open details for {NAME}`
                                        )->a( n = `titleActive` v = `true`
                                        )->a( n = `titlePress`  v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )
                                        )->a( n = `class`       v = `sapUiTinyMarginBottom`
                                    )->tag( `ObjectStatus`
                                        )->a( n = `text`  v = `{STATUS_TEXT}`
                                        )->a( n = `state` v = `{STATUS_STATE}`

                                )->end(
                            )->end(
                            )->ele( `FlexBox`
                                )->a( n = `renderType`     v = `Bare`
                                )->a( n = `justifyContent` v = `Center`

                                )->tag( `Image`
                                    )->a( n = `src`     v = `{PICTUREURL}`
                                    )->a( n = `width`   v = `100%`
                                    )->a( n = `height`  v = `100%`
                                    )->a( n = `press`   v = client->_event( val = `PRODUCT` arg = `${PRODUCTID}` )
                                    )->a( n = `tooltip` v = `Open details for {NAME}`
                                    )->a( n = `alt`     v = `This image shows {NAME}`

                            )->end(
                            )->ele( `Button`
                                )->a( n = `tooltip` v = `Add to Shopping Cart`
                                )->a( n = `type`    v = `Emphasized`
                                )->a( n = `press`   v = client->_event( val = `ADD_TO_CART` arg = `${PRODUCTID}` )
                                )->a( n = `icon`    v = `sap-icon://cart-3`

                                )->ele( `layoutData`
                                    )->tag( n = `GridData` ns = `l`
                                        )->a( n = `span` v = `XL4 L4 M4 S4`

                                )->end(
                            )->end(
                            )->ele( `ObjectListItem`
                                )->a( n = `class`      v = `welcomePrice`
                                " the original's CurrencyType binding, formatted in the
                                " browser's locale - not the price formatter the lists use
                                )->a( n = `number`     v = `{ parts: [ { path: 'PRICE' }, { path: 'CURRENCYCODE' } ], type: 'CurrencyType', formatOptions: { showMeasure: false } }`
                                )->a( n = `numberUnit` v = `{CURRENCYCODE}`

                                )->ele( `layoutData`
                                    )->tag( n = `GridData` ns = `l`
                                        )->a( n = `span` v = `XL8 L8 M8 S8` ).

  ENDMETHOD.


  METHOD page_checkout.

    " Checkout.view.xml is one NavContainer with two pages - the wizard and
    " its summary - and sits in the begin column, which the checkout route
    " shows alone (OneColumn)
    DATA(checkout) = parent->ele( `NavContainer`
        )->a( n = `id` v = `wizardNavContainer`

        )->ele( `pages` ).

    DATA(page) = checkout->ele( `Page`
        )->a( n = `id`    v = `wizardContentPage`
        )->a( n = `title` v = `Checkout` ).

    page->ele( `landmarkInfo`
        )->tag( `PageAccessibleLandmarkInfo`
            )->a( n = `rootRole`     v = `Region`
            )->a( n = `rootLabel`    v = `Checkout`
            )->a( n = `contentRole`  v = `Main`
            )->a( n = `contentLabel` v = `Checkout Wizard`
            )->a( n = `footerRole`   v = `Region`
            )->a( n = `footerLabel`  v = `Checkout Footer` ).

    page->ele( `headerContent`
        )->tag( `Button`
            )->a( n = `id`    v = `wizardReturnToShopButton`
            )->a( n = `type`  v = `Emphasized`
            )->a( n = `text`  v = `Return to Shop`
            )->a( n = `press` v = client->_event( `RETURN_TO_SHOP` ) ).

    " the footer bar shows while the message model holds a message; its
    " button opens the MessagePopover of dialogs( ) at itself, in the browser
    page->ele( `footer`
        )->ele( `Bar`
            )->a( n = `id`      v = `wizardFooterBar`
            )->a( n = `visible` v = |\{= ${ client->_bind( msg_count ) } === 0 ? false : true \}|

            )->ele( `contentLeft`
                )->tag( `Button`
                    )->a( n = `id`    v = `showPopoverButton`
                    )->a( n = `icon`  v = `sap-icon://message-popup`
                    )->a( n = `text`  v = client->_bind( msg_count )
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                    t_arg = VALUE #( ( `messagePopover` )
                                                                                     ( `openBy` )
                                                                                     ( `showPopoverButton` ) ) ) ).

    " enableBranching + subsequentSteps is what lets the payment type pick the
    " step after it; the branch itself is set from the backend with
    " setNextStep, and re-issued on every render (see view_display)
    DATA(wizard) = page->ele( `content`
        )->ele( `Wizard`
            )->a( n = `id`               v = `shoppingCartWizard`
            )->a( n = `complete`         v = client->_event( `WIZARD_COMPLETE` )
            )->a( n = `enableBranching`  b = abap_true
            )->a( n = `finishButtonText` v = `Order Summary` ).

    DATA(contents) = wizard->ele( `WizardStep`
        )->a( n = `id`       v = `contentsStep`
        )->a( n = `nextStep` v = `paymentTypeStep`
        )->a( n = `title`    v = `Items`
        )->a( n = `icon`     v = `sap-icon://cart` ).

    contents->ele( `List`
        )->a( n = `id`         v = `checkoutEntryList`
        )->a( n = `noDataText` v = `Your cart is empty`
        )->a( n = `items`      v = client->_bind( t_cart )

        )->ele( `items`
            )->ele( `ObjectListItem`
                )->a( n = `intro`            v = `{QUANTITY} x`
                )->a( n = `icon`             v = `{PICTUREURL}`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `number`           v = `{PRICE_TEXT}`
                )->a( n = `numberUnit`       v = `EUR`
                )->a( n = `iconDensityAware` b = abap_false

                )->ele( `firstStatus`
                    )->tag( `ObjectStatus`
                        )->a( n = `text`  v = `{STATUS_TEXT}`
                        )->a( n = `state` v = `{STATUS_STATE}` ).

    contents->ele( `Bar`
        )->ele( `contentRight`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cart_total ) ).

    DATA(payment) = wizard->ele( `WizardStep`
        )->a( n = `id`              v = `paymentTypeStep`
        )->a( n = `title`           v = `Payment Type`
        )->a( n = `subsequentSteps` v = `creditCardStep, bankAccountStep, cashOnDeliveryStep`
        )->a( n = `icon`            v = `sap-icon://money-bills` ).

    payment->tag( `Text`
        )->a( n = `class` v = `sapUiSmallMarginBottom`
        )->a( n = `text`  v = `We accept all major credit cards with no additional charging. ` &&
                              `Bank transfer and cash on delivery are only possible for inland deliveries. ` &&
                              `For those, we will charge additional 2.99 EUR. ` &&
                              `Orders payed with bank transfer, will be shipped direcly after the payment is received.` ).

    payment->ele( `HBox`
        )->a( n = `renderType`     v = `Bare`
        )->a( n = `alignItems`     v = `Center`
        )->a( n = `justifyContent` v = `Center`
        )->a( n = `width`          v = `100%`

        )->ele( `SegmentedButton`
            )->a( n = `selectionChange` v = client->_event( `PAY_TYPE` )
            )->a( n = `id`              v = `paymentMethodSelection`
            )->a( n = `selectedKey`     v = client->_bind( pay_type )

            )->ele( `items`
                )->tag( `SegmentedButtonItem`
                    )->a( n = `id`   v = `payViaCC`
                    )->a( n = `key`  v = `Credit Card`
                    )->a( n = `text` v = `Credit Card`
                )->tag( `SegmentedButtonItem`
                    )->a( n = `id`   v = `payViaBank`
                    )->a( n = `key`  v = `Bank Transfer`
                    )->a( n = `text` v = `Bank Transfer`
                )->tag( `SegmentedButtonItem`
                    )->a( n = `id`   v = `payViaCOD`
                    )->a( n = `key`  v = `Cash on Delivery`
                    )->a( n = `text` v = `Cash on Delivery` ).

    " the four forms below are the original's: required labels, its
    " placeholders, the MaskInputs and the MM/YYYY DatePicker of the card.
    " Every checked input carries the value state input_check( ) decides and
    " sends CHECK_INPUT on `change` - the event the original's
    " checkCreditCardStep & co. hang on - and every step with inputs sends
    " CHECK_STEP on `activate` (onCheckStepActivation). The original gives
    " each label XL4 L4 M4 S12 and each field XL8 L8 M8 S12 as GridData; the
    " form's label spans say the same once per form
    DATA(credit) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `creditCardStep`
        )->a( n = `title`     v = `Credit Card Details`
        )->a( n = `icon`      v = `sap-icon://credit-card`
        )->a( n = `validated` v = client->_bind( cc_valid )
        )->a( n = `activate`  v = client->_event( val = `CHECK_STEP` arg = `creditCardStep` )
        )->a( n = `nextStep`  v = `invoiceStep` ).

    credit->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable`    b = abap_true
        )->a( n = `layout`      v = `ResponsiveGridLayout`
        )->a( n = `labelSpanXL` v = `4`
        )->a( n = `labelSpanL`  v = `4`
        )->a( n = `labelSpanM`  v = `4`
        )->a( n = `labelSpanS`  v = `12`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text`     v = `Cardholder's Name`
                )->a( n = `labelFor` v = `creditCardHolderName`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `creditCardHolderName`
                )->a( n = `placeholder`    v = `Enter card holder name`
                )->a( n = `value`          v = client->_bind( cc_name )
                )->a( n = `valueState`     v = client->_bind( s_state-cc_name )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-cc_name )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `CC_NAME` )
            )->tag( `Label`
                )->a( n = `text`     v = `Card Number`
                )->a( n = `labelFor` v = `creditCardNumber`
                )->a( n = `required` b = abap_true
            )->ele( `MaskInput`
                )->a( n = `id`                v = `creditCardNumber`
                )->a( n = `placeholder`       v = `Enter card number`
                )->a( n = `mask`              v = `CCCC-CCCC-CCCC-CCCC`
                )->a( n = `placeholderSymbol` v = `_`
                )->a( n = `value`             v = client->_bind( cc_number )
                )->a( n = `valueState`        v = client->_bind( s_state-cc_number )
                )->a( n = `valueStateText`    v = client->_bind( s_state_text-cc_number )
                )->a( n = `change`            v = client->_event( val = `CHECK_INPUT` arg = `CC_NUMBER` )

                )->ele( `rules`
                    )->tag( `MaskInputRule`
                        )->a( n = `maskFormatSymbol` v = `C`
                        )->a( n = `regex`            v = `[0-9]`

                )->end(
            )->end(
            )->tag( `Label`
                )->a( n = `text`     v = `Security Code`
                )->a( n = `labelFor` v = `creditCardSecurityNumber`
                )->a( n = `required` b = abap_true
            )->ele( `MaskInput`
                )->a( n = `id`                v = `creditCardSecurityNumber`
                )->a( n = `placeholder`       v = `Enter the 3-digits security number`
                )->a( n = `mask`              v = `CCC`
                )->a( n = `placeholderSymbol` v = `_`
                )->a( n = `value`             v = client->_bind( cc_code )
                )->a( n = `valueState`        v = client->_bind( s_state-cc_code )
                )->a( n = `valueStateText`    v = client->_bind( s_state_text-cc_code )
                )->a( n = `change`            v = client->_event( val = `CHECK_INPUT` arg = `CC_CODE` )

                )->ele( `rules`
                    )->tag( `MaskInputRule`
                        )->a( n = `maskFormatSymbol` v = `C`
                        )->a( n = `regex`            v = `[0-9]`

                )->end(
            )->end(
            " no `required` on this label in the original either: the asterisk
            " comes from the DatePicker's own `required`
            )->tag( `Label`
                )->a( n = `text` v = `Expiration Date (MM/YYYY)`
            )->tag( `DatePicker`
                )->a( n = `id`             v = `creditCardExpirationDate`
                )->a( n = `value`          v = client->_bind( cc_expire )
                )->a( n = `valueFormat`    v = `MM/YYYY`
                )->a( n = `displayFormat`  v = `MM/YYYY`
                )->a( n = `required`       b = abap_true
                )->a( n = `valueState`     v = client->_bind( s_state-cc_expire )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-cc_expire )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `CC_EXPIRE` ) ).

    DATA(bank) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `bankAccountStep`
        )->a( n = `title`     v = `Bank Account Details`
        )->a( n = `icon`      v = `sap-icon://official-service`
        )->a( n = `validated` b = abap_true
        )->a( n = `activate`  v = client->_event( `PAYMENT_PASSED` )
        )->a( n = `nextStep`  v = `invoiceStep` ).

    bank->ele( `Panel`
        )->ele( n = `Grid` ns = `l`
            )->a( n = `defaultSpan` v = `L6 M6 S10`
            )->a( n = `hSpacing`    v = `2`

            )->tag( `Label`
                )->a( n = `text`   v = `Beneficiary Name`
                )->a( n = `design` v = `Bold`
            )->tag( `Label`
                )->a( n = `text` v = `Singapore Hardware e-Commerce LTD`
            )->tag( `Label`
                )->a( n = `text`   v = `Bank`
                )->a( n = `design` v = `Bold`
            )->tag( `Label`
                )->a( n = `text` v = `CITY BANK, SINGAPORE BRANCH`
            )->tag( `Label`
                )->a( n = `text`   v = `Account Number`
                )->a( n = `design` v = `Bold`
            )->tag( `Label`
                )->a( n = `text` v = `06110702027218` ).

    DATA(cod) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `cashOnDeliveryStep`
        )->a( n = `title`     v = `Details for Cash on Delivery`
        )->a( n = `icon`      v = `sap-icon://money-bills`
        )->a( n = `validated` v = client->_bind( cod_valid )
        )->a( n = `activate`  v = client->_event( val = `CHECK_STEP` arg = `cashOnDeliveryStep` )
        )->a( n = `nextStep`  v = `invoiceStep` ).

    cod->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable`    b = abap_true
        )->a( n = `layout`      v = `ResponsiveGridLayout`
        )->a( n = `labelSpanXL` v = `4`
        )->a( n = `labelSpanL`  v = `4`
        )->a( n = `labelSpanM`  v = `4`
        )->a( n = `labelSpanS`  v = `12`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text`     v = `First Name`
                )->a( n = `labelFor` v = `cashOnDeliveryName`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `cashOnDeliveryName`
                )->a( n = `placeholder`    v = `Enter your first name`
                )->a( n = `value`          v = client->_bind( cod_firstname )
                )->a( n = `valueState`     v = client->_bind( s_state-cod_firstname )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-cod_firstname )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `COD_FIRSTNAME` )
            )->tag( `Label`
                )->a( n = `text`     v = `Last Name`
                )->a( n = `labelFor` v = `cashOnDeliveryLastName`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `cashOnDeliveryLastName`
                )->a( n = `placeholder`    v = `Enter your last name`
                )->a( n = `value`          v = client->_bind( cod_lastname )
                )->a( n = `valueState`     v = client->_bind( s_state-cod_lastname )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-cod_lastname )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `COD_LASTNAME` )
            )->tag( `Label`
                )->a( n = `text`     v = `Phone Number`
                )->a( n = `labelFor` v = `cashOnDeliveryPhoneNumber`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `cashOnDeliveryPhoneNumber`
                )->a( n = `placeholder`    v = `Enter your phone number`
                )->a( n = `value`          v = client->_bind( cod_phone )
                )->a( n = `valueState`     v = client->_bind( s_state-cod_phone )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-cod_phone )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `COD_PHONE` )
            )->tag( `Label`
                )->a( n = `text`     v = `E-mail Address`
                )->a( n = `labelFor` v = `cashOnDeliveryEmail`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `cashOnDeliveryEmail`
                )->a( n = `placeholder`    v = `Enter your email address`
                )->a( n = `value`          v = client->_bind( cod_email )
                )->a( n = `valueState`     v = client->_bind( s_state-cod_email )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-cod_email )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `COD_EMAIL` ) ).

    DATA(invoice) = wizard->ele( `WizardStep`
        )->a( n = `id`              v = `invoiceStep`
        )->a( n = `title`           v = `Invoice Address`
        )->a( n = `icon`            v = `sap-icon://sales-quote`
        )->a( n = `validated`       v = client->_bind( inv_valid )
        )->a( n = `activate`        v = client->_event( val = `CHECK_STEP` arg = `invoiceStep` )
        )->a( n = `subsequentSteps` v = `deliveryAddressStep, deliveryTypeStep` ).

    invoice->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable`    b = abap_true
        )->a( n = `layout`      v = `ResponsiveGridLayout`
        )->a( n = `labelSpanXL` v = `4`
        )->a( n = `labelSpanL`  v = `4`
        )->a( n = `labelSpanM`  v = `4`
        )->a( n = `labelSpanS`  v = `12`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Use Different Address for Delivery`
            )->tag( `CheckBox`
                )->a( n = `id`       v = `differentDeliveryAddress`
                )->a( n = `selected` v = client->_bind( del_different )
                )->a( n = `select`   v = client->_event( `DELIVERY_DIFFERENT` )
            )->tag( `Label`
                )->a( n = `text`     v = `Address`
                )->a( n = `labelFor` v = `invoiceAddressAddress`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `invoiceAddressAddress`
                )->a( n = `placeholder`    v = `Enter your street name and house number`
                )->a( n = `value`          v = client->_bind( inv_address )
                )->a( n = `valueState`     v = client->_bind( s_state-inv_address )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-inv_address )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `INV_ADDRESS` )
            )->tag( `Label`
                )->a( n = `text`     v = `City`
                )->a( n = `labelFor` v = `invoiceAddressCity`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `invoiceAddressCity`
                )->a( n = `placeholder`    v = `Enter your city`
                )->a( n = `value`          v = client->_bind( inv_city )
                )->a( n = `valueState`     v = client->_bind( s_state-inv_city )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-inv_city )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `INV_CITY` )
            )->tag( `Label`
                )->a( n = `text`     v = `Zip Code`
                )->a( n = `labelFor` v = `invoiceAddressZip`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `invoiceAddressZip`
                )->a( n = `placeholder`    v = `Enter your zip code`
                )->a( n = `value`          v = client->_bind( inv_zip )
                )->a( n = `valueState`     v = client->_bind( s_state-inv_zip )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-inv_zip )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `INV_ZIP` )
            )->tag( `Label`
                )->a( n = `text`     v = `Country`
                )->a( n = `labelFor` v = `invoiceAddressCountry`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `invoiceAddressCountry`
                )->a( n = `placeholder`    v = `Enter your country`
                )->a( n = `value`          v = client->_bind( inv_country )
                )->a( n = `valueState`     v = client->_bind( s_state-inv_country )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-inv_country )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `INV_COUNTRY` )
            )->tag( `Label`
                )->a( n = `text` v = `Note`
            )->tag( `TextArea`
                )->a( n = `id`          v = `invoiceAddressNote`
                )->a( n = `rows`        v = `8`
                )->a( n = `placeholder` v = `Additional comments (max 500 characters)`
                )->a( n = `value`       v = client->_bind( inv_note ) ).

    DATA(delivery) = wizard->ele( `WizardStep`
        )->a( n = `id`        v = `deliveryAddressStep`
        )->a( n = `title`     v = `Shipping Address`
        )->a( n = `icon`      v = `sap-icon://sales-quote`
        )->a( n = `validated` v = client->_bind( del_valid )
        )->a( n = `activate`  v = client->_event( val = `CHECK_STEP` arg = `deliveryAddressStep` )
        )->a( n = `nextStep`  v = `deliveryTypeStep` ).

    delivery->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable`    b = abap_true
        )->a( n = `layout`      v = `ResponsiveGridLayout`
        )->a( n = `labelSpanXL` v = `4`
        )->a( n = `labelSpanL`  v = `4`
        )->a( n = `labelSpanM`  v = `4`
        )->a( n = `labelSpanS`  v = `12`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text`     v = `Address`
                )->a( n = `labelFor` v = `deliveryAddressAddress`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `deliveryAddressAddress`
                )->a( n = `placeholder`    v = `Enter your street name and house number`
                )->a( n = `value`          v = client->_bind( del_address )
                )->a( n = `valueState`     v = client->_bind( s_state-del_address )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-del_address )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `DEL_ADDRESS` )
            )->tag( `Label`
                )->a( n = `text`     v = `City`
                )->a( n = `labelFor` v = `deliveryAddressCity`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `deliveryAddressCity`
                )->a( n = `placeholder`    v = `Enter your city`
                )->a( n = `value`          v = client->_bind( del_city )
                )->a( n = `valueState`     v = client->_bind( s_state-del_city )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-del_city )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `DEL_CITY` )
            )->tag( `Label`
                )->a( n = `text`     v = `Zip Code`
                )->a( n = `labelFor` v = `deliveryAddressZip`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `deliveryAddressZip`
                )->a( n = `placeholder`    v = `Enter your zip code`
                )->a( n = `value`          v = client->_bind( del_zip )
                )->a( n = `valueState`     v = client->_bind( s_state-del_zip )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-del_zip )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `DEL_ZIP` )
            )->tag( `Label`
                )->a( n = `text`     v = `Country`
                )->a( n = `labelFor` v = `deliveryAddressCountry`
                )->a( n = `required` b = abap_true
            )->tag( `Input`
                )->a( n = `id`             v = `deliveryAddressCountry`
                )->a( n = `placeholder`    v = `Enter your country`
                )->a( n = `value`          v = client->_bind( del_country )
                )->a( n = `valueState`     v = client->_bind( s_state-del_country )
                )->a( n = `valueStateText` v = client->_bind( s_state_text-del_country )
                )->a( n = `change`         v = client->_event( val = `CHECK_INPUT` arg = `DEL_COUNTRY` )
            )->tag( `Label`
                )->a( n = `text` v = `Note`
            )->tag( `TextArea`
                )->a( n = `id`          v = `deliveryAddressNote`
                )->a( n = `rows`        v = `8`
                )->a( n = `placeholder` v = `Additional comments (max 500 characters)`
                )->a( n = `value`       v = client->_bind( del_note ) ).

    " the original's deliveryTypeStep has no activate; the one here only
    " tells the backend the wizard is past the invoice step (invoice_passed)
    DATA(delivery_type) = wizard->ele( `WizardStep`
        )->a( n = `id`       v = `deliveryTypeStep`
        )->a( n = `title`    v = `Delivery Type`
        )->a( n = `icon`     v = `sap-icon://insurance-car`
        )->a( n = `activate` v = client->_event( `INVOICE_PASSED` ) ).

    delivery_type->tag( `Text`
        )->a( n = `class` v = `sapUiSmallMarginBottom`
        )->a( n = `text`  v = `Standard delivery time is 5 workdays. During high-season sales, please allow one additional day. ` &&
                              `Express delivery is delivered within 36 hours. For express delivery on workdays, we charge a ` &&
                              `service fee of 5.49 EUR, for a express delivery on holidays, the service fee is 8,00 EUR. ` &&
                              `Express delivery is only available for inland deliveries. For deliveries abroud, please check ` &&
                              `the specific conditions.` ).

    delivery_type->ele( `HBox`
        )->a( n = `renderType`     v = `Bare`
        )->a( n = `alignItems`     v = `Center`
        )->a( n = `justifyContent` v = `Center`
        )->a( n = `width`          v = `100%`

        )->ele( `SegmentedButton`
            )->a( n = `id`          v = `deliveryType`
            )->a( n = `selectedKey` v = client->_bind( del_type )

            )->ele( `items`
                )->tag( `SegmentedButtonItem`
                    )->a( n = `key`  v = `Standard Delivery`
                    )->a( n = `text` v = `Standard`
                )->tag( `SegmentedButtonItem`
                    )->a( n = `id`   v = `expressDelivery`
                    )->a( n = `key`  v = `Express Delivery`
                    )->a( n = `text` v = `Express` ).

    page_summary( checkout ).

  ENDMETHOD.


  METHOD page_summary.

    " the summary page: one section per wizard step, each with the edit
    " button back into its step (_navBackToStep), and Submit / Cancel
    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `summaryPage`
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `showHeader`       b = abap_false ).

    page->ele( `landmarkInfo`
        )->tag( `PageAccessibleLandmarkInfo`
            )->a( n = `rootRole`     v = `Region`
            )->a( n = `rootLabel`    v = `Checkout`
            )->a( n = `contentRole`  v = `Main`
            )->a( n = `contentLabel` v = `Checkout Summary`
            )->a( n = `footerRole`   v = `Banner`
            )->a( n = `footerLabel`  v = `Checkout Footer` ).

    DATA(content) = page->ele( `content` ).

    DATA(items) = content->ele( `Panel` ).

    items->ele( `headerToolbar`
        )->ele( `Toolbar`
            )->a( n = `id` v = `toolbarProductList`

            )->tag( `Title`
                )->a( n = `id`         v = `checkoutItems`
                )->a( n = `text`       v = `Items`
                )->a( n = `level`      v = `H2`
                )->a( n = `titleStyle` v = `H4`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `id`      v = `backtoList`
                )->a( n = `icon`    v = `sap-icon://edit`
                )->a( n = `tooltip` v = `Back to Wizard`
                )->a( n = `type`    v = `Emphasized`
                )->a( n = `press`   v = client->_event( val = `EDIT_STEP` arg = `contentsStep` ) ).

    items->ele( `content`
        )->ele( `List`
            )->a( n = `id`         v = `summaryEntryList`
            )->a( n = `noDataText` v = `Your cart is empty`
            )->a( n = `items`      v = client->_bind( t_cart )

            )->ele( `items`
                )->ele( `ObjectListItem`
                    )->a( n = `intro`            v = `{QUANTITY} x`
                    )->a( n = `icon`             v = `{PICTUREURL}`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `number`           v = `{PRICE_TEXT}`
                    )->a( n = `numberUnit`       v = `EUR`
                    )->a( n = `iconDensityAware` b = abap_false

                    )->ele( `firstStatus`
                        )->tag( `ObjectStatus`
                            )->a( n = `text`  v = `{STATUS_TEXT}`
                            )->a( n = `state` v = `{STATUS_STATE}` ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `layout`         v = `ResponsiveGridLayout`
        )->a( n = `ariaLabelledBy` v = `totalPriceTitle`

        )->ele( n = `toolbar` ns = `form`
            )->ele( `Toolbar`
                )->a( n = `id` v = `toolbarTotalPrice`

                )->tag( `ToolbarSpacer`
                )->tag( `Title`
                    )->a( n = `id`         v = `totalPriceTitle`
                    )->a( n = `level`      v = `H3`
                    )->a( n = `titleStyle` v = `H4`
                    )->a( n = `text`       v = client->_bind( cart_total ) ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable`       b = abap_false
        )->a( n = `layout`         v = `ResponsiveGridLayout`
        )->a( n = `ariaLabelledBy` v = `toolbarPaymentTitle`

        )->ele( n = `toolbar` ns = `form`
            )->ele( `Toolbar`
                )->a( n = `id` v = `toolbarPayment`

                )->tag( `Title`
                    )->a( n = `id`         v = `toolbarPaymentTitle`
                    )->a( n = `text`       v = `Payment Type`
                    )->a( n = `level`      v = `H2`
                    )->a( n = `titleStyle` v = `H4`
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `id`      v = `backToPaymentType`
                    )->a( n = `icon`    v = `sap-icon://edit`
                    )->a( n = `tooltip` v = `Back to Wizard`
                    )->a( n = `type`    v = `Emphasized`
                    )->a( n = `press`   v = client->_event( val = `EDIT_STEP` arg = `paymentTypeStep` )

            )->end(
        )->end(
        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Selected Payment Type`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( pay_type ) ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `visible`        v = |\{= ${ client->_bind( pay_type ) }==='Credit Card' ? true : false\}|
        )->a( n = `editable`       b = abap_false
        )->a( n = `layout`         v = `ResponsiveGridLayout`
        )->a( n = `ariaLabelledBy` v = `creditCardPaymentTitle`

        )->ele( n = `toolbar` ns = `form`
            )->ele( `Toolbar`
                )->a( n = `id` v = `toolbarCreditCard`

                )->tag( `Title`
                    )->a( n = `id`         v = `creditCardPaymentTitle`
                    )->a( n = `text`       v = `Credit Card Payment`
                    )->a( n = `level`      v = `H2`
                    )->a( n = `titleStyle` v = `H4`
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `id`      v = `backToCreditCard`
                    )->a( n = `icon`    v = `sap-icon://edit`
                    )->a( n = `tooltip` v = `Back to Wizard`
                    )->a( n = `type`    v = `Emphasized`
                    )->a( n = `press`   v = client->_event( val = `EDIT_STEP` arg = `creditCardStep` )

            )->end(
        )->end(
        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Cardholder's Name`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cc_name )
            )->tag( `Label`
                )->a( n = `text` v = `Card Number`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cc_number )
            )->tag( `Label`
                )->a( n = `text` v = `Security Code`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cc_code )
            )->tag( `Label`
                )->a( n = `text` v = `Expiration Date (MM/YYYY)`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cc_expire ) ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `visible`  v = |\{= ${ client->_bind( pay_type ) }==='Bank Transfer' ? true : false\}|
        )->a( n = `title`    v = `Bank Transfer`
        )->a( n = `editable` b = abap_false
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text`   v = `Beneficiary Name`
                )->a( n = `design` v = `Bold`
            )->tag( `Text`
                )->a( n = `text` v = `Singapore Hardware e-Commerce LTD`
            )->tag( `Label`
                )->a( n = `text`   v = `Bank`
                )->a( n = `design` v = `Bold`
            )->tag( `Text`
                )->a( n = `text` v = `CITY BANK, SINGAPORE BRANCH`
            )->tag( `Label`
                )->a( n = `text`   v = `Account Number`
                )->a( n = `design` v = `Bold`
            )->tag( `Text`
                )->a( n = `text` v = `06110702027218` ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `visible`        v = |\{= ${ client->_bind( pay_type ) }==='Cash on Delivery' ? true : false\}|
        )->a( n = `editable`       b = abap_false
        )->a( n = `layout`         v = `ResponsiveGridLayout`
        )->a( n = `ariaLabelledBy` v = `cashOnDeliveryTitle`

        )->ele( n = `toolbar` ns = `form`
            )->ele( `Toolbar`
                )->a( n = `id` v = `toolbarCOD`

                )->tag( `Title`
                    )->a( n = `id`         v = `cashOnDeliveryTitle`
                    )->a( n = `text`       v = `Cash on Delivery`
                    )->a( n = `level`      v = `H2`
                    )->a( n = `titleStyle` v = `H4`
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `id`      v = `backToCashOnDelivery`
                    )->a( n = `icon`    v = `sap-icon://edit`
                    )->a( n = `tooltip` v = `Back to Wizard`
                    )->a( n = `type`    v = `Emphasized`
                    )->a( n = `press`   v = client->_event( val = `EDIT_STEP` arg = `cashOnDeliveryStep` )

            )->end(
        )->end(
        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `First Name`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cod_firstname )
            )->tag( `Label`
                )->a( n = `text` v = `Last Name`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cod_lastname )
            )->tag( `Label`
                )->a( n = `text` v = `Phone Number`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cod_phone )
            )->tag( `Label`
                )->a( n = `text` v = `E-mail Address`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( cod_email ) ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `title`          v = ``
        )->a( n = `editable`       b = abap_false
        )->a( n = `layout`         v = `ResponsiveGridLayout`
        )->a( n = `ariaLabelledBy` v = `invoiceAddressTitle`

        )->ele( n = `toolbar` ns = `form`
            )->ele( `Toolbar`
                )->a( n = `id` v = `toolbarInvoice`

                )->tag( `Title`
                    )->a( n = `id`         v = `invoiceAddressTitle`
                    )->a( n = `text`       v = `Invoice Address`
                    )->a( n = `level`      v = `H2`
                    )->a( n = `titleStyle` v = `H4`
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `id`      v = `backToInvoiceAddress`
                    )->a( n = `icon`    v = `sap-icon://edit`
                    )->a( n = `tooltip` v = `Back to Wizard`
                    )->a( n = `type`    v = `Emphasized`
                    )->a( n = `press`   v = client->_event( val = `EDIT_STEP` arg = `invoiceStep` )

            )->end(
        )->end(
        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Address`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( inv_address )
            )->tag( `Label`
                )->a( n = `text` v = `City`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( inv_city )
            )->tag( `Label`
                )->a( n = `text` v = `Zip Code`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( inv_zip )
            )->tag( `Label`
                )->a( n = `text` v = `Country`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( inv_country )
            )->tag( `Label`
                )->a( n = `text` v = `Note`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( inv_note ) ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `title`          v = ``
        )->a( n = `editable`       b = abap_false
        )->a( n = `layout`         v = `ResponsiveGridLayout`
        )->a( n = `ariaLabelledBy` v = `deliveryTypeTitle`

        )->ele( n = `toolbar` ns = `form`
            )->ele( `Toolbar`
                )->a( n = `id` v = `toolbarShippping`

                )->tag( `Title`
                    )->a( n = `id`         v = `deliveryTypeTitle`
                    )->a( n = `text`       v = `Delivery Type`
                    )->a( n = `level`      v = `H2`
                    )->a( n = `titleStyle` v = `H4`
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `id`      v = `backToDeliveryType`
                    )->a( n = `icon`    v = `sap-icon://edit`
                    )->a( n = `tooltip` v = `Back to Wizard`
                    )->a( n = `type`    v = `Emphasized`
                    )->a( n = `press`   v = client->_event( val = `EDIT_STEP` arg = `deliveryTypeStep` )

            )->end(
        )->end(
        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Selected Delivery Type`
            )->tag( `Text`
                )->a( n = `id`   v = `selectedDeliveryMethod`
                )->a( n = `text` v = client->_bind( del_type ) ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable`       b = abap_false
        )->a( n = `layout`         v = `ResponsiveGridLayout`
        )->a( n = `visible`        v = |\{= ${ client->_bind( del_different ) }\}|
        )->a( n = `ariaLabelledBy` v = `shippingAddressTitle1`

        )->ele( n = `toolbar` ns = `form`
            )->ele( `Toolbar`
                )->a( n = `id` v = `toolbar5ShippingAddress`

                )->tag( `Title`
                    )->a( n = `id`         v = `shippingAddressTitle1`
                    )->a( n = `text`       v = `Shipping Address`
                    )->a( n = `level`      v = `H2`
                    )->a( n = `titleStyle` v = `H4`
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `id`      v = `backToDeliveryAddress`
                    )->a( n = `icon`    v = `sap-icon://edit`
                    )->a( n = `tooltip` v = `Back to Wizard`
                    )->a( n = `type`    v = `Emphasized`
                    )->a( n = `press`   v = client->_event( val = `EDIT_STEP` arg = `deliveryAddressStep` )

            )->end(
        )->end(
        )->ele( n = `content` ns = `form`
            )->tag( `Label`
                )->a( n = `text` v = `Address`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( del_address )
            )->tag( `Label`
                )->a( n = `text` v = `City`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( del_city )
            )->tag( `Label`
                )->a( n = `text` v = `Zip Code`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( del_zip )
            )->tag( `Label`
                )->a( n = `text` v = `Country`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( del_country )
            )->tag( `Label`
                )->a( n = `text` v = `Note`
            )->tag( `Text`
                )->a( n = `text` v = client->_bind( del_note ) ).

    content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `editable`       b = abap_false
        )->a( n = `layout`         v = `ResponsiveGridLayout`
        )->a( n = `visible`        v = |\{= !${ client->_bind( del_different ) }\}|
        )->a( n = `ariaLabelledBy` v = `shippingAddressTitle2`

        )->ele( n = `toolbar` ns = `form`
            )->ele( `Toolbar`
                )->a( n = `id` v = `toolbar5SameAsInvoice`

                )->tag( `Title`
                    )->a( n = `id`         v = `shippingAddressTitle2`
                    )->a( n = `text`       v = `Shipping Address`
                    )->a( n = `level`      v = `H2`
                    )->a( n = `titleStyle` v = `H4`
                )->tag( `ToolbarSpacer`
                )->tag( `Button`
                    )->a( n = `id`      v = `backToDifferentDeliveryAddress`
                    )->a( n = `icon`    v = `sap-icon://edit`
                    )->a( n = `tooltip` v = `Back to Wizard`
                    )->a( n = `type`    v = `Emphasized`
                    )->a( n = `press`   v = client->_event( val = `EDIT_STEP` arg = `invoiceStep` )

            )->end(
        )->end(
        )->ele( n = `content` ns = `form`
            )->tag( `Text`
                )->a( n = `text` v = `Same as invoice address` ).

    page->ele( `footer`
        )->ele( `Bar`
            )->a( n = `id` v = `summaryFooterBar`

            )->ele( `contentRight`
                )->tag( `Button`
                    )->a( n = `id`    v = `submitOrder`
                    )->a( n = `type`  v = `Accept`
                    )->a( n = `text`  v = `Submit`
                    )->a( n = `press` v = client->_event( `WIZARD_SUBMIT` )
                )->tag( `Button`
                    )->a( n = `id`    v = `cancelOrder`
                    )->a( n = `type`  v = `Reject`
                    )->a( n = `text`  v = `Cancel`
                    )->a( n = `press` v = client->_event( `WIZARD_CANCEL` ) ).

  ENDMETHOD.


  METHOD page_order_completed.

    DATA(page) = parent->ele( `Page`
        )->a( n = `id`               v = `orderCompletedPage`
        )->a( n = `title`            v = `Order Completed`
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `class`            v = `sapUiContentPadding` ).

    page->ele( `landmarkInfo`
        )->tag( `PageAccessibleLandmarkInfo`
            )->a( n = `rootRole`     v = `Region`
            )->a( n = `rootLabel`    v = `Order Completed`
            )->a( n = `contentRole`  v = `Main`
            )->a( n = `contentLabel` v = `Order Completed Message`
            )->a( n = `headerRole`   v = `Region`
            )->a( n = `headerLabel`  v = `Order Completed Title`
            )->a( n = `footerRole`   v = `Region`
            )->a( n = `footerLabel`  v = `Order Completed Footer` ).

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
                    )->a( n = `type`  v = `Emphasized`
                    )->a( n = `text`  v = `Return to Shop`
                    )->a( n = `press` v = client->_event( `RETURN_TO_SHOP` ) ).

  ENDMETHOD.


  METHOD on_event.

    " three dispatchers, one per area of the original's controllers - each
    " answers whether the event was its own
    IF on_event_shop( ) = abap_false AND on_event_cart( ) = abap_false.
      on_event_checkout( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event_shop.

    result = abap_true.

    CASE client->get_event( ).

      WHEN `CART_LOADED`.
        " the browser had a cart under the key: it wins over what this app
        " instance holds, exactly as the original's model does - the storage
        " IS the model there
        cart_restore( ).

      WHEN `STATE_CHANGE`.
        " BaseController.onStateChange: one column means a small screen; with
        " room for more, a OneColumn layout goes back to two columns
        small_screen = xsdbool( client->get_event_arg( ) = `1` ).
        IF small_screen = abap_false AND client->get_event_arg( 2 ) = `OneColumn`.
          set_layout( `Two` ).
        ENDIF.

      WHEN `AVATAR`.
        " BaseController.onAvatarPress: a MessageToast and nothing else -
        " there is no login behind it
        client->message_toast_display( `You are now successfully logged in` ).

      WHEN `SEARCH`.
        search_term = client->get_event_arg( ).
        search_refresh( ).

      WHEN `SEARCH_REFRESH`.
        " Home.onRefresh: the search once more, then the pull-down closes
        search_refresh( ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `pullToRefresh` ) ( `hide` ) ) ).

      WHEN `HOME`.
        route_to( `home` ).

      WHEN `SHOW_CATEGORIES` OR `BACK_CATEGORIES`.
        " Welcome.onShowCategories and Category.onBack
        route_to( `categories` ).

      WHEN `BACK`.
        " BaseController.onBack: the route before this one, or home
        IF t_history IS INITIAL.
          route_to( `home` ).
        ELSE.
          s_route = t_history[ lines( t_history ) ].
          DELETE t_history INDEX lines( t_history ).
          route_apply( ).
        ENDIF.

      WHEN `CATEGORY`.
        route_to( name = `category` category = client->get_event_arg( ) ).

      WHEN `PRODUCT` OR `PRODUCT_SELECT`.
        " a search result (Home._showProduct) or a welcome tile
        " (Welcome.onSelectProduct): the product's route, which shows its
        " category in the begin column and the product in the mid column
        product_route( client->get_event_arg( ) ).

      WHEN `CATEGORY_PRODUCT`.
        " Category.onProductDetails: two columns - or three, if the cart was
        " open, which the productCart route then opens again
        DATA(cart_visible) = xsdbool( layout CP `Three*` ).
        set_layout( `Two` ).
        product_route( productid = client->get_event_arg( )
                       name      = COND #( WHEN cart_visible = abap_true THEN `productCart` ELSE `product` ) ).

      WHEN `COMPARE`.
        " Category.compareProducts: the first product compared stays item 1,
        " the one chosen now becomes item 2
        DATA(compare_id) = client->get_event_arg( ).
        route_to( name     = `comparison`
                  category = category_of( compare_id )
                  item1    = COND #( WHEN cmp_item1 IS NOT INITIAL THEN cmp_item1 ELSE compare_id )
                  item2    = COND #( WHEN cmp_item1 IS NOT INITIAL AND cmp_item1 <> compare_id
                                     THEN compare_id
                                     ELSE cmp_item2 ) ).

      WHEN `CMP_REMOVE`.
        " Comparison.onRemoveComparison: the other product stays, as item 1
        route_to( name     = `comparison`
                  category = cmp_category
                  item1    = COND #( WHEN client->get_event_arg( ) = `1` THEN cmp_item2 ELSE cmp_item1 ) ).

      WHEN `TOGGLE_CART`.
        " onToggleCart of Welcome, Product and Comparison. The ToggleButton's
        " new state is the opposite of the layout its `pressed` is derived from
        DATA(pressed) = xsdbool( layout NP `ThreeColumns*` ).
        set_layout( COND #( WHEN pressed = abap_true THEN `Three` ELSE `Two` ) ).
        CASE client->get_event_arg( ).
          WHEN `welcome`.
            route_to( COND #( WHEN pressed = abap_true THEN `cart` ELSE `home` ) ).
          WHEN `product`.
            route_to( name     = COND #( WHEN pressed = abap_true THEN `productCart` ELSE `product` )
                      category = s_prod-category
                      product  = s_prod-productid ).
          WHEN OTHERS.
            route_to( name     = COND #( WHEN pressed = abap_true THEN `comparisonCart` ELSE `comparison` )
                      category = cmp_category
                      item1    = cmp_item1
                      item2    = cmp_item2 ).
        ENDCASE.

      WHEN `ADD_TO_CART`.
        " the product page's footer button adds the product it shows and sends
        " nothing, a welcome tile sends its row's id - the split the original
        " has between BaseController.onAddToCart and Welcome.onAddToCart
        DATA(add_id) = client->get_event_arg( ).
        IF add_id IS INITIAL.
          add_id = s_prod-productid.
        ENDIF.
        cart_add_request( add_id ).

      WHEN `CMP_ADD_TO_CART`.
        cart_add_request( COND #( WHEN client->get_event_arg( ) = `1` THEN s_cmp1-productid ELSE s_cmp2-productid ) ).

      WHEN `OUT_OF_STOCK_CLOSED`.
        " the onClose of the original's confirmation box: only OK orders
        IF client->get_event_arg( ) = `OK`.
          cart_add( add_pending ).
        ENDIF.
        CLEAR add_pending.

      WHEN `FILTER_CONFIRM`.
        " Category.handleConfirm: the slider values become the previous ones,
        " then _applyFilter
        flt_low_prev  = flt_low.
        flt_high_prev = flt_high.
        filter_confirm( ).

      WHEN `FILTER_CANCEL`.
        " handleCancel: the slider goes back to the last confirmed values
        flt_low         = flt_low_prev.
        flt_high        = flt_high_prev.
        flt_price_count = COND #( WHEN flt_low_prev > 0 OR flt_high_prev <> 5000 THEN 1 ELSE 0 ).

      WHEN `FILTER_CHANGE`.
        " handleChange: the Price item counts as a filter once the range is
        " narrower than the slider
        flt_price_count = COND #( WHEN CONV i( client->get_event_arg( ) ) <> 0
                                    OR CONV i( client->get_event_arg( 2 ) ) <> 5000
                                  THEN 1
                                  ELSE 0 ).

      WHEN `FILTER_RESET`.
        " handleResetFilters - the dialog clears its own items
        flt_low         = 0.
        flt_high        = 5000.
        flt_price_count = 0.

      WHEN OTHERS.
        result = abap_false.

    ENDCASE.

  ENDMETHOD.


  METHOD on_event_cart.

    result = abap_true.

    CASE client->get_event( ).

      WHEN `EDIT_TOGGLE`.
        cart_edit_toggle( ).

      WHEN `SAVE_LATER`.
        " Cart._changeList: into the saved list - unless it is there already -
        " and out of the cart
        DATA(saved_id) = client->get_event_arg( ).
        IF NOT line_exists( t_saved[ productid = saved_id ] ).
          INSERT VALUE #( t_cart[ productid = saved_id ] OPTIONAL ) INTO TABLE t_saved.
        ENDIF.
        DELETE t_cart WHERE productid = saved_id.
        cart_refresh( ).

      WHEN `ADD_BACK`.
        " onAddBackToBasket: the same move the other way, quantity and all
        DATA(back_id) = client->get_event_arg( ).
        IF NOT line_exists( t_cart[ productid = back_id ] ).
          INSERT VALUE #( t_saved[ productid = back_id ] OPTIONAL ) INTO TABLE t_cart.
        ENDIF.
        DELETE t_saved WHERE productid = back_id.
        cart_refresh( ).

      WHEN `CART_DELETE`.
        " _deleteProduct: every removal is confirmed first
        delete_list    = client->get_event_arg( ).
        delete_pending = client->get_event_arg( 2 ).
        client->message_box_display( text    = `Do you want to remove this entry from your cart?`
                                     type    = `show`
                                     title   = `Confirmation`
                                     actions = VALUE #( ( `DELETE` ) ( `CANCEL` ) )
                                     onclose = `CART_DELETE_CLOSED` ).

      WHEN `CART_DELETE_CLOSED`.
        IF client->get_event_arg( ) = `DELETE`.
          cart_delete( ).
        ENDIF.
        CLEAR: delete_pending, delete_list.

      WHEN `CART_SELECT`.
        cart_show_product( client->get_event_arg( ) ).

      WHEN `CART_PRESS`.
        " _showProduct on a phone: the cart closes
        set_layout( `Two` ).
        product_route( client->get_event_arg( ) ).

      WHEN `PROCEED`.
        route_to( `checkout` ).

      WHEN OTHERS.
        result = abap_false.

    ENDCASE.

  ENDMETHOD.


  METHOD on_event_checkout.

    result = abap_true.

    CASE client->get_event( ).

      WHEN `RETURN_TO_SHOP`.
        " onReturnToShopButtonPress of Checkout and OrderCompleted
        set_layout( `Two` ).
        route_to( `home` ).

      WHEN `PAY_TYPE`.
        " setPaymentMethod -> _setDiscardableProperty: once the wizard is past
        " the payment step, a new payment type throws that progress away, so
        " the user is asked first. Before that it simply becomes the branch
        IF payment_passed = abap_true.
          client->message_box_display( text    = `Are you sure you want to change the payment type? This will discard your progress.`
                                       type    = `warning`
                                       actions = VALUE #( ( `YES` ) ( `NO` ) )
                                       onclose = `PAY_TYPE_DECIDE` ).
        ELSE.
          pay_type_apply( ).
        ENDIF.

      WHEN `PAY_TYPE_DECIDE`.
        IF client->get_event_arg( ) = `YES`.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = VALUE #( ( `shoppingCartWizard` ) ( `discardProgress` ) ( `paymentTypeStep` ) ) ).
          payment_passed = abap_false.
          invoice_passed = abap_false.
          pay_type_apply( ).
        ELSE.
          " NO keeps the progress, and the SegmentedButton shows the old
          " payment type again through its bound selectedKey
          pay_type = pay_type_prev.
        ENDIF.

      WHEN `PAYMENT_PASSED`.
        " the bank transfer step has no inputs to check - it only moves the
        " progress past the payment step
        payment_passed = abap_true.

      WHEN `DELIVERY_DIFFERENT`.
        " setDifferentDeliveryAddress - the same question once the wizard is
        " past the invoice step
        IF invoice_passed = abap_true.
          client->message_box_display( text    = `Are you sure you want to change the shipping address? This will discard your progress`
                                       type    = `warning`
                                       actions = VALUE #( ( `YES` ) ( `NO` ) )
                                       onclose = `DELIVERY_DECIDE` ).
        ELSE.
          delivery_apply( ).
        ENDIF.

      WHEN `DELIVERY_DECIDE`.
        IF client->get_event_arg( ) = `YES`.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = VALUE #( ( `shoppingCartWizard` ) ( `discardProgress` ) ( `invoiceStep` ) ) ).
          invoice_passed = abap_false.
          delivery_apply( ).
        ELSE.
          del_different = del_prev.
        ENDIF.

      WHEN `INVOICE_PASSED`.
        payment_passed = abap_true.
        invoice_passed = abap_true.

      WHEN `CHECK_INPUT`.
        " the change handlers of the original (checkCreditCardStep & co.):
        " the changed field shows what its type says about it - the original's
        " handleValidation - and the steps are decided again
        input_check( client->get_event_arg( ) ).
        steps_check( ).

      WHEN `CHECK_STEP`.
        " onCheckStepActivation: the messages go (_clearMessages), then the
        " step just opened is decided without marking a field, as
        " _checkInputFields only asks the types. Every step that sends it lies
        " behind the payment step, the delivery address behind the invoice
        payment_passed = abap_true.
        IF client->get_event_arg( ) = `deliveryAddressStep`.
          invoice_passed = abap_true.
        ENDIF.
        messages_clear( ).
        steps_check( ).

      WHEN `WIZARD_COMPLETE`.
        " checkCompleted: no summary while the message model holds a message
        IF t_messages IS NOT INITIAL.
          client->message_box_display( text = `One or more fields contain invalid information` type = `error` ).
        ELSE.
          nav_to( nav = `wizardNavContainer` page = `summaryPage` ).
        ENDIF.

      WHEN `EDIT_STEP`.
        wizard_to_step( client->get_event_arg( ) ).

      WHEN `WIZARD_SUBMIT`.
        client->message_box_display( text    = `Are you sure you want to submit your order?`
                                     type    = `confirm`
                                     actions = VALUE #( ( `YES` ) ( `NO` ) )
                                     onclose = `WIZARD_SUBMIT_CLOSED` ).

      WHEN `WIZARD_CANCEL`.
        client->message_box_display( text    = `Are you sure you want to cancel your order?`
                                     type    = `warning`
                                     actions = VALUE #( ( `YES` ) ( `NO` ) )
                                     onclose = `WIZARD_CANCEL_CLOSED` ).

      WHEN `WIZARD_SUBMIT_CLOSED` OR `WIZARD_CANCEL_CLOSED`.
        " _handleSubmitOrCancel: YES resets the wizard, empties the cart - the
        " saved-for-later list stays - and goes on to the order confirmation or
        " home. The original posts nothing either
        IF client->get_event_arg( ) = `YES`.
          wizard_reset( ).
          t_cart = VALUE #( ).
          cart_refresh( ).
          route_to( COND #( WHEN client->get_event( ) = `WIZARD_SUBMIT_CLOSED` THEN `ordercompleted` ELSE `home` ) ).
        ENDIF.

      WHEN OTHERS.
        result = abap_false.

    ENDCASE.

  ENDMETHOD.


  METHOD route_to.

    " router.navTo( ): what was on show goes onto the history the Back
    " buttons walk, then the new route is displayed
    IF s_route-name IS NOT INITIAL.
      INSERT s_route INTO TABLE t_history.
    ENDIF.
    s_route = VALUE #( name     = name
                       category = category
                       product  = product
                       item1    = item1
                       item2    = item2 ).
    route_apply( ).

  ENDMETHOD.


  METHOD route_apply.

    " the targets of each route of manifest.json, column by column, and what
    " the controllers' route-matched handlers load for them
    CASE s_route-name.
      WHEN `category`.
        category_load( s_route-category ).
        nav_to( nav = `nav-begin` page = `page-category` ).
        nav_to( nav = `nav-mid`   page = `page-welcome` ).
      WHEN `product` OR `productCart`.
        category_load( category = s_route-category productid = s_route-product ).
        nav_to( nav = `nav-begin` page = `page-category` ).
        product_show( s_route-product ).
      WHEN `comparison` OR `comparisonCart`.
        " Category._loadSuppliers clears the comparison model, and
        " Comparison._onRoutePatternMatched fills it again from the route
        category_load( s_route-category ).
        cmp_category = s_route-category.
        cmp_item1    = s_route-item1.
        cmp_item2    = s_route-item2.
        nav_to( nav = `nav-begin` page = `page-category` ).
        comparison_show( ).
      WHEN `checkout`.
        nav_to( nav = `nav-begin` page = `wizardNavContainer` ).
      WHEN `ordercompleted`.
        nav_to( nav = `nav-begin` page = `orderCompletedPage` ).
      WHEN OTHERS.
        " home, categories and cart
        nav_to( nav = `nav-begin` page = `page-home` ).
        nav_to( nav = `nav-mid`   page = `page-welcome` ).
    ENDCASE.

    " the layouts the route-matched handlers set
    CASE s_route-name.
      WHEN `home`.
        " Welcome._onRouteMatched
        set_layout( `Two` ).
      WHEN `categories`.
        " Home._onRouteMatched
        IF small_screen = abap_true.
          set_layout( `One` ).
        ENDIF.
      WHEN `category`.
        " Category._loadCategories
        set_layout( COND #( WHEN small_screen = abap_true THEN `One` ELSE `Two` ) ).
      WHEN `checkout`.
        " the checkout route's handler in Checkout.onInit
        set_layout( `One` ).
      WHEN `cart` OR `productCart` OR `comparisonCart`.
        " Cart._routePatternMatched: three columns, and no row selected
        nav_to( nav = `nav-end` page = `page-cart` ).
        set_layout( `Three` ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `entryList` ) ( `removeSelections` ) ) ).
    ENDCASE.

  ENDMETHOD.


  METHOD set_layout.

    " BaseController._setLayout
    layout = |{ columns }Column{ COND #( WHEN columns = `One` THEN `` ELSE `sMidExpanded` ) }|.

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
      WHEN `nav-end`.
        page_end = page.
      WHEN OTHERS.
        page_wizard = page.
    ENDCASE.

    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( nav ) ( `to` ) ( page ) ) ).

  ENDMETHOD.


  METHOD category_load.

    " Category._loadCategories and _loadSuppliers: the category and its
    " products, the product of a product route selected (fnDataReceived), and
    " the comparison model cleared (_clearComparison)
    category_name = VALUE #( t_categories[ category = category ]-categoryname OPTIONAL ).
    category_rows( category = category productid = productid ).
    CLEAR: cmp_category, cmp_item1, cmp_item2.

  ENDMETHOD.


  METHOD category_rows.

    " the list binding of the category's Products, sorted by Name - with the
    " filter of the dialog still on it
    t_category = VALUE #( ).
    LOOP AT t_all INTO DATA(product) WHERE category = category.
      IF filter_match( product ) = abap_true.
        DATA(row) = row_of( product ).
        row-selected = xsdbool( product-productid = productid ).
        INSERT row INTO TABLE t_category.
      ENDIF.
    ENDLOOP.
    SORT t_category BY name AS TEXT.

  ENDMETHOD.


  METHOD filter_match.

    " _applyFilter's Filter objects: OR inside a group, AND across groups,
    " the price BT the slider's range
    result = abap_true.
    IF flt_status IS NOT INITIAL AND NOT line_exists( flt_status[ table_line = product-status ] ).
      result = abap_false.
    ELSEIF flt_supplier IS NOT INITIAL AND NOT line_exists( flt_supplier[ table_line = product-suppliername ] ).
      result = abap_false.
    ELSEIF flt_price = abap_true.
      DATA(price) = CONV ty_amount( product-price ).
      IF price < flt_low_prev OR price > flt_high_prev.
        result = abap_false.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD filter_confirm.

    " _applyFilter: the selected items become the list's filter, and the info
    " toolbar names the groups that filter - the compound keys in the
    " dialog's order, the price range last
    DATA keys TYPE string_table.

    flt_status = VALUE #( ).
    IF flt_available = abap_true.
      INSERT `A` INTO TABLE flt_status.
    ENDIF.
    IF flt_out_of_stock = abap_true.
      INSERT `O` INTO TABLE flt_status.
    ENDIF.
    IF flt_discontinued = abap_true.
      INSERT `D` INTO TABLE flt_status.
    ENDIF.
    flt_supplier = VALUE #( ).
    LOOP AT t_suppliers INTO DATA(supplier) WHERE selected = abap_true.
      INSERT supplier-suppliername INTO TABLE flt_supplier.
    ENDLOOP.
    flt_price = xsdbool( flt_low <> 0 OR flt_high <> 5000 ).

    category_rows( category  = s_route-category
                   productid = VALUE #( t_category[ selected = abap_true ]-productid OPTIONAL ) ).

    IF flt_status IS NOT INITIAL.
      INSERT `Availability` INTO TABLE keys.
    ENDIF.
    IF flt_supplier IS NOT INITIAL.
      INSERT `Supplier` INTO TABLE keys.
    ENDIF.
    IF flt_price = abap_true.
      INSERT |Price ({ flt_low_prev } - { flt_high_prev } EUR)| INTO TABLE keys.
    ENDIF.
    info_visible = xsdbool( keys IS NOT INITIAL ).
    info_text    = COND #( WHEN keys IS NOT INITIAL THEN |Filtered by { concat_lines_of( table = keys sep = `, ` ) }| ).

  ENDMETHOD.


  METHOD search_refresh.

    " Home._search: the result list IS the search and shows instead of the
    " categories while the field holds a text. The original filters with
    " Contains on Name, which the mock server answers with a case-sensitive
    " substringof - so does find( ) here
    t_search = VALUE #( ).
    IF search_term IS NOT INITIAL.
      LOOP AT t_all INTO DATA(found).
        IF find( val = found-name sub = search_term ) >= 0.
          INSERT row_of( found ) INTO TABLE t_search.
        ENDIF.
      ENDLOOP.
      " the productList of the original sorts by Name
      SORT t_search BY name AS TEXT.
    ENDIF.
    search_visible = xsdbool( search_term IS NOT INITIAL ).

  ENDMETHOD.


  METHOD product_route.

    route_to( name = name category = category_of( productid ) product = productid ).

  ENDMETHOD.


  METHOD category_of.

    result = VALUE #( t_all[ productid = productid ]-category OPTIONAL ).

  ENDMETHOD.


  METHOD product_show.

    " the product view's element binding
    s_prod = detail_of( productid ).
    nav_to( nav = `nav-mid` page = `page-product` ).

  ENDMETHOD.


  METHOD detail_of.

    ASSIGN t_all[ productid = productid ] TO FIELD-SYMBOL(<product>).
    IF <product> IS NOT ASSIGNED.
      " enum-typed: an empty state is rejected outright
      result-status_state = `None`.
      RETURN.
    ENDIF.

    result = VALUE #( productid        = <product>-productid
                      category         = <product>-category
                      name             = <product>-name
                      suppliername     = <product>-suppliername
                      shortdescription = <product>-shortdescription
                      price_text       = price_text( <product>-price )
                      pictureurl       = picture_url( <product>-pictureurl )
                      status_text      = status_text( <product>-status )
                      status_state     = status_state( <product>-status )
                      weight_text      = |{ <product>-weight } { <product>-weightunit }|
                      " Product.view.xml and ComparisonItem.fragment.xml bind
                      " `{DimensionWidth} {Unit}, ...` - and the entity has no Unit,
                      " so the original shows the three numbers with an empty unit
                      measures_text    = |{ <product>-dimensionwidth } , { <product>-dimensiondepth } , | &&
                                         |{ <product>-dimensionheight } | ).

  ENDMETHOD.


  METHOD comparison_show.

    " Comparison._onRoutePatternMatched: a panel per product of the route,
    " the placeholder while one of the two is missing
    s_cmp1       = detail_of( cmp_item1 ).
    s_cmp2       = detail_of( cmp_item2 ).
    cmp1_visible = xsdbool( cmp_item1 IS NOT INITIAL ).
    cmp2_visible = xsdbool( cmp_item2 IS NOT INITIAL ).
    cmp_placeholder = xsdbool( cmp_item1 IS INITIAL OR cmp_item2 IS INITIAL ).
    nav_to( nav = `nav-mid` page = `page-comparison` ).

  ENDMETHOD.


  METHOD cart_add_request.

    " cart.addToCart of the original: the product's status decides before
    " anything is added - a discontinued product cannot be ordered, an
    " out-of-stock one only after the user confirms it
    ASSIGN t_all[ productid = productid ] TO FIELD-SYMBOL(<product>).
    IF <product> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE <product>-status.
      WHEN `D`.
        " MessageBox.show with icon ERROR and CLOSE - its title option is
        " spelled `titles` there, so the box opens without a title. The
        " global call takes the option object 1:1, where message_box_display
        " would add the type's own title
        client->follow_up_action( val   = client->cs_event-control_global
                                  t_arg = VALUE #( ( `MESSAGE_BOX` )
                                                   ( `show` )
                                                   ( `This product has been discontinued and cannot be ordered anymore` )
                                                   ( `{"icon":"ERROR","actions":["CLOSE"]}` ) ) ).
      WHEN `O`.
        add_pending = productid.
        client->message_box_display( text    = `This product is currently out of stock, but you can order it. ` &&
                                               `It will be shipped as soon as it's available again`
                                     type    = `confirm`
                                     title   = `Confirmation`
                                     actions = VALUE #( ( `OK` ) ( `CANCEL` ) )
                                     onclose = `OUT_OF_STOCK_CLOSED` ).
      WHEN OTHERS.
        cart_add( productid ).
    ENDCASE.

  ENDMETHOD.


  METHOD cart_add.

    " cart._updateCartItem: a new entry with quantity 1, or one more of it
    DATA(entry) = entry_of( productid ).
    IF entry-productid IS INITIAL.
      RETURN.
    ENDIF.

    ASSIGN t_cart[ productid = productid ] TO FIELD-SYMBOL(<entry>).
    IF <entry> IS ASSIGNED.
      <entry>-quantity = <entry>-quantity + 1.
    ELSE.
      entry-quantity = 1.
      INSERT entry INTO TABLE t_cart.
    ENDIF.

    cart_refresh( ).
    client->message_toast_display( |Product "{ entry-name }" added to your shopping cart| ).

  ENDMETHOD.


  METHOD cart_delete.

    " the DELETE of _deleteProduct's confirmation: out of the list it was
    " deleted from, and a toast naming it
    DATA(name) = COND string( WHEN delete_list = `entryList`
                              THEN VALUE #( t_cart[ productid = delete_pending ]-name OPTIONAL )
                              ELSE VALUE #( t_saved[ productid = delete_pending ]-name OPTIONAL ) ).
    IF delete_list = `entryList`.
      DELETE t_cart WHERE productid = delete_pending.
    ELSE.
      DELETE t_saved WHERE productid = delete_pending.
    ENDIF.
    cart_refresh( ).
    client->message_toast_display( |Product "{ name }" removed from cart| ).

  ENDMETHOD.


  METHOD cart_edit_toggle.

    " Cart._toggleCfgModel: Delete mode for both lists and the page title
    " that says so
    in_delete  = xsdbool( in_delete = abap_false ).
    cart_title = COND #( WHEN in_delete = abap_true THEN `Edit Cart` ELSE `Shopping Cart` ).

  ENDMETHOD.


  METHOD cart_show_product.

    " Cart._showProduct on a desktop: the product, with the cart still open
    " if it is
    product_route( productid = productid name = COND #( WHEN layout CP `Three*` THEN `productCart` ELSE `product` ) ).

  ENDMETHOD.


  METHOD cart_mirror.

    " the totalPrice formatter of the original, computed where the prices are
    DATA total TYPE ty_amount.

    FIELD-SYMBOLS <product> TYPE ty_s_product.

    LOOP AT t_cart INTO DATA(entry).
      " UNASSIGN first: inside a loop a field symbol stays assigned from the
      " previous round, so IS ASSIGNED alone would read the PREVIOUS row
      UNASSIGN <product>.
      ASSIGN t_all[ productid = entry-productid ] TO <product>.
      IF <product> IS ASSIGNED.
        total = total + CONV ty_amount( <product>-price ) * entry-quantity.
      ENDIF.
    ENDLOOP.

    cart_total = |Total: { price_text( |{ total }| ) } EUR|.

    " formatter.hasItems - for Edit either list, for Proceed the cart
    cart_any    = xsdbool( t_cart IS NOT INITIAL OR t_saved IS NOT INITIAL ).
    cart_filled = xsdbool( t_cart IS NOT INITIAL ).

    " entryList and saveForLaterList both sort by Name in the original, and the
    " checkout's two cart lists bind the same table
    SORT t_cart BY name AS TEXT.
    SORT t_saved BY name AS TEXT.

    " the mirror is what keeps the reading control quiet - it compares by
    " value and fires only on a difference
    s_storage-value = VALUE #( cart = t_cart saved = t_saved ).

  ENDMETHOD.


  METHOD cart_refresh.

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
    client->follow_up_action( val   = client->cs_event-store_data
                              t_arg = VALUE #( ( storage_json( ) ) ) ).

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

    " a JSON array of the fields the bound value carries back
    DATA(rows) = ``.

    LOOP AT entries INTO DATA(entry).
      IF rows IS NOT INITIAL.
        rows = |{ rows },|.
      ENDIF.
      rows = |{ rows }\{"PRODUCTID":"{ json_escape( entry-productid ) }",| &&
             |"CATEGORY":"{ json_escape( entry-category ) }",| &&
             |"NAME":"{ json_escape( entry-name ) }",| &&
             |"PICTUREURL":"{ json_escape( entry-pictureurl ) }",| &&
             |"PRICE_TEXT":"{ json_escape( entry-price_text ) }",| &&
             |"CURRENCYCODE":"{ json_escape( entry-currencycode ) }",| &&
             |"QUANTITY":{ entry-quantity },| &&
             |"STATUS_TEXT":"{ json_escape( entry-status_text ) }",| &&
             |"STATUS_STATE":"{ json_escape( entry-status_state ) }"\}|.
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
    " for. The stored payload is nested (two arrays of rows), and nested is
    " exactly the case a hand-written `find` walk does not answer: binding
    " the value is the answer instead.
    DATA(stored) = s_storage-value.
    t_cart  = stored-cart.
    t_saved = stored-saved.

    " the rows keep their product and quantity; what the lists show of a
    " product is taken from the catalogue again, which also fills the fields
    " a cart stored by an older version of this class does not carry
    LOOP AT t_cart ASSIGNING FIELD-SYMBOL(<entry>).
      DATA(fresh) = entry_of( <entry>-productid ).
      IF fresh-productid IS NOT INITIAL.
        fresh-quantity = <entry>-quantity.
        <entry> = fresh.
      ENDIF.
    ENDLOOP.
    LOOP AT t_saved ASSIGNING <entry>.
      fresh = entry_of( <entry>-productid ).
      IF fresh-productid IS NOT INITIAL.
        fresh-quantity = <entry>-quantity.
        <entry> = fresh.
      ENDIF.
    ENDLOOP.

    " mirror, no write, when what was read IS what is stored - the mirror is
    " what stops the reading control from reporting it again on the next
    " render. A refreshed row is written back, so the key holds the same
    cart_mirror( ).
    IF s_storage-value <> stored.
      cart_refresh( ).
    ENDIF.

  ENDMETHOD.


  METHOD entry_of.

    ASSIGN t_all[ productid = productid ] TO FIELD-SYMBOL(<product>).
    IF <product> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    result = VALUE #( productid    = <product>-productid
                      category     = <product>-category
                      name         = <product>-name
                      pictureurl   = picture_url( <product>-pictureurl )
                      price_text   = price_text( <product>-price )
                      currencycode = <product>-currencycode
                      status_text  = status_text( <product>-status )
                      status_state = status_state( <product>-status ) ).

  ENDMETHOD.


  METHOD input_check.

    " what the original's binding type does to a field on `change`: its
    " message as the value state text, or no state at all. The component is
    " the event argument, so an unknown name changes nothing
    FIELD-SYMBOLS <state> TYPE string.
    FIELD-SYMBOLS <text>  TYPE string.

    ASSIGN COMPONENT field OF STRUCTURE s_state TO <state>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    ASSIGN COMPONENT field OF STRUCTURE s_state_text TO <text>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    <text>  = input_error( field ).
    <state> = COND #( WHEN <text> IS INITIAL THEN `None` ELSE `Error` ).
    messages_refresh( ).

  ENDMETHOD.


  METHOD input_error.

    " the constraints of the original's value bindings, one input each -
    " `type: 'StringType', constraints: { minLength, search }` and, for the
    " e-mail, its own EmailType. matches( ) anchors the whole value, which is
    " what the original's ^...$ do
    CASE field.
      WHEN `CC_NAME`.
        result = string_error( val = cc_name min = 3 regex = `[a-zA-Z]+ ?[a-zA-Z]+` ).
      WHEN `CC_NUMBER`.
        result = string_error( val = cc_number min = 16 regex = `[0-9-]+` ).
      WHEN `CC_CODE`.
        result = string_error( val = cc_code min = 3 regex = `[0-9]+` ).
      WHEN `CC_EXPIRE`.
        result = string_error( val = cc_expire min = 7 max = 7 ).
      WHEN `COD_FIRSTNAME`.
        result = string_error( val = cod_firstname min = 2 ).
      WHEN `COD_LASTNAME`.
        result = string_error( val = cod_lastname min = 2 ).
      WHEN `COD_PHONE`.
        result = string_error( val = cod_phone min = 0 regex = `[(0-9+]+[) ]?[0-9/ ]+` ).
      WHEN `COD_EMAIL`.
        " model/EmailType.js - the demo kit's own regex, and its own message
        IF string_error( val   = cod_email
                         min   = 0
                         regex = `[a-zA-Z0-9_]+[a-zA-Z0-9_+.-]*@[a-zA-Z0-9_]+([-.][a-zA-Z0-9_]+)*\.[a-zA-Z]{2,}` )
           IS NOT INITIAL.
          result = |"{ cod_email }" is not a valid email address|.
        ENDIF.
      WHEN `INV_ADDRESS`.
        result = string_error( val = inv_address min = 4 regex = `[a-zA-Z-]+\.? ?[0-9a-zA-Z ]*` ).
      WHEN `INV_CITY`.
        result = string_error( val = inv_city min = 3 regex = `[a-zA-Z ]+` ).
      WHEN `INV_ZIP`.
        result = string_error( val = inv_zip min = 3 regex = `[0-9]+` ).
      WHEN `INV_COUNTRY`.
        result = string_error( val = inv_country min = 2 regex = `[a-zA-Z]+` ).
      WHEN `DEL_ADDRESS`.
        result = string_error( val = del_address min = 4 regex = `[a-zA-Z-]+\.? ?[0-9a-zA-Z ]*` ).
      WHEN `DEL_CITY`.
        result = string_error( val = del_city min = 3 regex = `[a-zA-Z ]+` ).
      WHEN `DEL_ZIP`.
        result = string_error( val = del_zip min = 3 regex = `[0-9]+` ).
      WHEN `DEL_COUNTRY`.
        result = string_error( val = del_country min = 2 regex = `[a-zA-Z]+` ).
    ENDCASE.

  ENDMETHOD.


  METHOD string_error.

    " sap.ui.model.type.String.validateValue: every violated constraint adds
    " the message of the UI5 message bundle, and SimpleType.combineMessages
    " ends each with a period once there is more than one
    DATA messages TYPE string_table.

    IF strlen( val ) < min.
      INSERT |Enter a value with at least { min } characters| INTO TABLE messages.
    ENDIF.
    IF max > 0 AND strlen( val ) > max.
      INSERT |Enter a value with no more than { max } characters| INTO TABLE messages.
    ENDIF.
    IF regex IS NOT INITIAL AND NOT matches( val = val regex = regex ) ##REGEX_POSIX.
      INSERT `Enter a valid value` INTO TABLE messages.
    ENDIF.

    IF lines( messages ) = 1.
      result = messages[ 1 ].
    ELSEIF lines( messages ) > 1.
      result = concat_lines_of( table = messages sep = `. ` ) && `.`.
    ENDIF.

  ENDMETHOD.


  METHOD step_valid.

    " _checkInputFields: a step passes when no input of it fails its type
    result = abap_true.
    LOOP AT fields INTO DATA(field).
      IF input_error( field ) IS NOT INITIAL.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD steps_check.

    " _checkStep for all four steps at once: each flag is bound to its step's
    " `validated`, which is what shows or hides the step's Next button
    cc_valid  = step_valid( VALUE #( ( `CC_NAME` ) ( `CC_NUMBER` ) ( `CC_CODE` ) ( `CC_EXPIRE` ) ) ).
    cod_valid = step_valid( VALUE #( ( `COD_FIRSTNAME` ) ( `COD_LASTNAME` ) ( `COD_PHONE` ) ( `COD_EMAIL` ) ) ).
    inv_valid = step_valid( VALUE #( ( `INV_ADDRESS` ) ( `INV_CITY` ) ( `INV_ZIP` ) ( `INV_COUNTRY` ) ) ).
    del_valid = step_valid( VALUE #( ( `DEL_ADDRESS` ) ( `DEL_CITY` ) ( `DEL_ZIP` ) ( `DEL_COUNTRY` ) ) ).

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


  METHOD messages_refresh.

    " the message model: one Error per input whose type failed, with the
    " label of its field as the additional text - what the original's
    " handleValidation puts there, and what the footer button counts
    FIELD-SYMBOLS <state> TYPE string.
    FIELD-SYMBOLS <text>  TYPE string.
    FIELD-SYMBOLS <label> TYPE string.

    DATA(labels) = VALUE ty_s_checks( cc_name       = `Cardholder's Name`
                                      cc_number     = `Card Number`
                                      cc_code       = `Security Code`
                                      cc_expire     = `Expiration Date (MM/YYYY)`
                                      cod_firstname = `First Name`
                                      cod_lastname  = `Last Name`
                                      cod_phone     = `Phone Number`
                                      cod_email     = `E-mail Address`
                                      inv_address   = `Address`
                                      inv_city      = `City`
                                      inv_zip       = `Zip Code`
                                      inv_country   = `Country`
                                      del_address   = `Address`
                                      del_city      = `City`
                                      del_zip       = `Zip Code`
                                      del_country   = `Country` ).

    t_messages = VALUE #( ).
    DO.
      ASSIGN COMPONENT sy-index OF STRUCTURE s_state TO <state>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      ASSIGN COMPONENT sy-index OF STRUCTURE s_state_text TO <text>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      ASSIGN COMPONENT sy-index OF STRUCTURE labels TO <label>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      IF <state> = `Error`.
        INSERT VALUE #( type = `Error` message = <text> additionaltext = <label> ) INTO TABLE t_messages.
      ENDIF.
    ENDDO.
    msg_count = lines( t_messages ).

  ENDMETHOD.


  METHOD messages_clear.

    " Messaging.removeAllMessages( ): the messages go, and with them the
    " value states they put on the fields - a ValueState is an enum, so
    " `None`, never empty
    FIELD-SYMBOLS <state> TYPE string.

    DO.
      ASSIGN COMPONENT sy-index OF STRUCTURE s_state TO <state>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      <state> = `None`.
    ENDDO.
    s_state_text = VALUE #( ).
    messages_refresh( ).

  ENDMETHOD.


  METHOD pay_type_apply.

    " the payment type becomes the branch and the new history value
    " (_oHistory.prevPaymentSelect)
    pay_type_prev = pay_type.
    wizard_branch( ).

  ENDMETHOD.


  METHOD delivery_apply.

    " the checkbox becomes the branch and the new history value
    " (_oHistory.prevDiffDeliverySelect)
    del_prev = del_different.
    wizard_branch( ).

  ENDMETHOD.


  METHOD wizard_branch.

    " goToPaymentStep and invoiceAddressComplete: the step after the payment
    " step and after the invoice step. A branch is an association, set from
    " here and re-issued on every render (sample z2ui5_cl_smp_app_202) -
    " sent as soon as the choice is made, because WizardStep._complete fires
    " complete and moves on in the same tick
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `paymentTypeStep` )
                                               ( `setNextStep` )
                                               ( SWITCH #( pay_type
                                                           WHEN `Bank Transfer`    THEN `bankAccountStep`
                                                           WHEN `Cash on Delivery` THEN `cashOnDeliveryStep`
                                                           ELSE `creditCardStep` ) ) ) ).
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `invoiceStep` )
                                               ( `setNextStep` )
                                               ( COND #( WHEN del_different = abap_true
                                                         THEN `deliveryAddressStep`
                                                         ELSE `deliveryTypeStep` ) ) ) ).

  ENDMETHOD.


  METHOD wizard_to_step.

    " _navToWizardStep: back to the wizard page, then to the step
    nav_to( nav = `wizardNavContainer` page = `wizardContentPage` ).
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `shoppingCartWizard` ) ( `goToStep` ) ( step ) ) ).

  ENDMETHOD.


  METHOD wizard_reset.

    " _handleSubmitOrCancel's reset: all progress discarded, back on the
    " first step, and the checkout model on its defaults again
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `shoppingCartWizard` ) ( `discardProgress` ) ( `contentsStep` ) ) ).
    wizard_to_step( `contentsStep` ).

    pay_type      = `Credit Card`.
    pay_type_prev = pay_type.
    del_type      = `Standard Delivery`.
    del_different = abap_false.
    del_prev      = abap_false.
    CLEAR: cod_firstname, cod_lastname, cod_phone, cod_email,
           inv_address, inv_city, inv_zip, inv_country, inv_note,
           del_address, del_city, del_zip, del_country, del_note,
           cc_name, cc_number, cc_code, cc_expire,
           payment_passed, invoice_passed.
    messages_clear( ).
    steps_check( ).
    wizard_branch( ).

  ENDMETHOD.


  METHOD row_of.

    result = VALUE #( productid    = product-productid
                      category     = product-category
                      name         = product-name
                      suppliername = product-suppliername
                      price        = CONV ty_amount( product-price )
                      price_text   = price_text( product-price )
                      currencycode = product-currencycode
                      pictureurl   = picture_url( product-pictureurl )
                      status       = product-status
                      status_text  = status_text( product-status )
                      status_state = status_state( product-status ) ).

  ENDMETHOD.


  METHOD status_text.

    " formatter.statusText - the i18n texts statusA/O/D
    result = SWITCH #( status
                       WHEN `A` THEN `Available`
                       WHEN `O` THEN `Out of Stock`
                       WHEN `D` THEN `Discontinued`
                       ELSE status ).

  ENDMETHOD.


  METHOD status_state.

    " formatter.statusState
    result = SWITCH #( status
                       WHEN `A` THEN `Success`
                       WHEN `O` THEN `Warning`
                       WHEN `D` THEN `Error`
                       ELSE `None` ).

  ENDMETHOD.


  METHOD model_init.

    FIELD-SYMBOLS <featured_product> TYPE ty_s_product.

    " localService/mockdata/ProductCategories.json - the categoryList of the
    " original sorts by CategoryName, so the rows are seeded verbatim (see
    " data_fidelity) and sorted at the end of model_init
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

    " Welcome.controller: the three panels read FeaturedProducts by Type, and
    " _selectPromotedItems keeps TWO of the five Promoted rows, drawn at
    " random - drawn here, once per start, as the original draws them once
    DATA(promoted) = VALUE ty_t_row( ).
    LOOP AT t_featured INTO DATA(featured).
      " UNASSIGN first - see cart_mirror
      UNASSIGN <featured_product>.
      ASSIGN t_all[ productid = featured-productid ] TO <featured_product>.
      IF <featured_product> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.
      CASE featured-type.
        WHEN `Promoted`.
          INSERT row_of( <featured_product> ) INTO TABLE promoted.
        WHEN `Viewed`.
          INSERT row_of( <featured_product> ) INTO TABLE t_viewed.
        WHEN OTHERS.
          INSERT row_of( <featured_product> ) INTO TABLE t_favorite.
      ENDCASE.
    ENDLOOP.

    DATA(random) = cl_abap_random_int=>create( seed = cl_abap_random=>seed( ) min = 1 max = lines( promoted ) ).
    DATA(second) = random->get_next( ).
    DATA(first) = second.
    WHILE first = second.
      first = random->get_next( ).
    ENDWHILE.
    t_promoted = VALUE #( ( promoted[ first ] ) ( promoted[ second ] ) ).

    " Welcome.onInit: the carousel opens on one of its four pages, at random
    carousel_page = SWITCH #( cl_abap_random_int=>create( seed = cl_abap_random=>seed( )
                                                          min  = 1
                                                          max  = 4 )->get_next( )
                              WHEN 1 THEN `carouselShipping`
                              WHEN 2 THEN `carouselInviteFriend`
                              WHEN 3 THEN `carouselTablet`
                              ELSE `carouselCreditCard` ).

    " the categoryList's own sorter
    SORT t_categories BY categoryname AS TEXT.

    " Category._loadSuppliers: every supplier of the catalogue once, sorted -
    " the Supplier items of the filter dialog
    LOOP AT t_all INTO DATA(product).
      IF NOT line_exists( t_suppliers[ suppliername = product-suppliername ] ).
        INSERT VALUE #( suppliername = product-suppliername ) INTO TABLE t_suppliers.
      ENDIF.
    ENDLOOP.
    SORT t_suppliers BY suppliername.

    " App.controller's appView model, and the route of an empty hash
    layout       = `TwoColumnsMidExpanded`.
    s_route-name = `home`.

    " enum-typed: the UI5 default until a product is shown
    s_prod-status_state = `None`.
    s_cmp1-status_state = `None`.
    s_cmp2-status_state = `None`.

    " what the original's checkout model starts on: SelectedPayment "Credit Card"
    " and SelectedDeliveryMethod "Standard Delivery". Not a cosmetic default - the
    " payment step's branch is an association, and view_display( ) sets it from
    " pay_type on every render, so a user who ACCEPTS the default can leave the
    " step, as the original's goToPaymentStep lets them
    pay_type      = `Credit Card`.
    pay_type_prev = pay_type.
    del_type      = `Standard Delivery`.
    messages_clear( ).

    " the original's LocalStorageModel("SHOPPING_CART", ...) - same storage,
    " same key
    s_storage-type = `local`.
    s_storage-key  = `SHOPPING_CART`.

    " mirror only - the browser's cart has not been read yet, so writing here
    " would put this empty one over it
    cart_mirror( ).

  ENDMETHOD.

ENDCLASS.
