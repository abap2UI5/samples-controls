" @keywords tabcontainer tab container sap.m tabcontainermhc navcontainer overflowtoolbar toolbarspacer overflowtoolbarbutton column text columnlistitem
" @summary Allows detail view / edit in sap.m.TabContainer after selecting items from table.
" @origin sap.m.sample.TabContainerMHC - https://sdk.openui5.org/entity/sap.m.TabContainer/sample/sap.m.sample.TabContainerMHC (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_558 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid    TYPE string,
        name         TYPE string,
        suppliername TYPE string,
        description  TYPE string,
        price        TYPE p LENGTH 14 DECIMALS 2,
        currencycode TYPE string,
        selected     TYPE abap_bool,
        " _oNewUnsavedItems: rows the add-new button created and nobody saved yet
        unsaved      TYPE abap_bool,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    " one row per open tab - a COPY of the product, which is what makes Cancel a
    " pure discard (the original edits a deepExtend copy in its own JSONModel)
    TYPES:
      BEGIN OF ty_s_tab,
        productid    TYPE string,
        name         TYPE string,
        suppliername TYPE string,
        description  TYPE string,
        price        TYPE p LENGTH 14 DECIMALS 2,
        currencycode TYPE string,
        modified     TYPE abap_bool,
      END OF ty_s_tab.
    TYPES ty_t_tab TYPE STANDARD TABLE OF ty_s_tab WITH EMPTY KEY.

    DATA t_products     TYPE ty_t_product.
    DATA t_tabs         TYPE ty_t_tab.
    DATA open_visible   TYPE abap_bool.
    DATA edit_visible   TYPE abap_bool VALUE abap_true.
    DATA save_visible   TYPE abap_bool.
    DATA cancel_visible TYPE abap_bool.
    DATA add_name        TYPE string.
    DATA add_supplier    TYPE string.
    DATA add_price       TYPE p LENGTH 14 DECIMALS 2.
    DATA add_description TYPE string.

  PROTECTED SECTION.
    DATA client         TYPE REF TO z2ui5_if_client.
    DATA selected_tab   TYPE string.
    DATA pending_close  TYPE string.
    " _bEditMode of the add-item page
    DATA add_mode       TYPE abap_bool.
    DATA add_product_id TYPE string.
    DATA new_counter    TYPE i.

    " The page the LIVE navCon was last sent to, so a rebuilt view can be sent
    " there again (see view_display). Empty until something navigated, which is
    " the guard. PROTECTED, not PUBLIC: it is bookkeeping and not model data,
    " and only PUBLIC attributes are serialized into the view model - and not
    " PRIVATE, because the draft serialization walks the attributes with a
    " dynamic ASSIGN obj->(name) that cannot reach a PRIVATE one
    DATA nav_page TYPE string.

    METHODS view_display.
    METHODS buttons_state
      IMPORTING edit   TYPE abap_bool DEFAULT abap_false
                save   TYPE abap_bool DEFAULT abap_false
                cancel TYPE abap_bool DEFAULT abap_false.
    METHODS nav_to_table.
    METHODS nav_back.
    METHODS unsaved_reset IMPORTING productid TYPE string OPTIONAL.
    METHODS tab_close IMPORTING productid TYPE string.
    METHODS tab_save.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_558 IMPLEMENTATION.

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

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(pages) = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`     v = `100%`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`

        )->ele( `NavContainer`
            )->a( n = `id` v = `navCon` ).

    DATA(table_page) = pages->ele( `Page`
        )->a( n = `id`    v = `table`
        )->a( n = `title` v = `Product List` ).

    table_page->ele( `Table`
        )->a( n = `id`              v = `idProductsTable`
        )->a( n = `mode`            v = `MultiSelect`
        )->a( n = `items`           v = client->_bind( t_products )
        " onInit attaches selectionChange to keep the footer button in sync
        )->a( n = `selectionChange` v = client->_event( `SELECTION_CHANGE` )

        )->ele( `headerToolbar`
            )->ele( `OverflowToolbar`
                )->tag( `ToolbarSpacer`
                )->tag( `OverflowToolbarButton`
                    )->a( n = `type`    v = `Transparent`
                    )->a( n = `icon`    v = `sap-icon://add`
                    )->a( n = `tooltip` v = `Add`
                    )->a( n = `press`   v = client->_event( `NEW_ITEM_ADD` )

            )->end(
        )->end(
        )->ele( `columns`
            )->ele( `Column`
                )->a( n = `width` v = `12em`

                )->tag( `Text`
                    )->a( n = `text` v = `Product`

            )->end(
            )->ele( `Column`
                )->a( n = `width` v = `12em`

                )->tag( `Text`
                    )->a( n = `text` v = `Supplier`

            )->end(
        )->end(
        )->ele( `items`
            )->ele( `ColumnListItem`
                " the original reads the selection with getSelectedContexts; the flag
                " is bound two-way here so the backend has it on every round trip
                )->a( n = `selected` v = `{SELECTED}`

                )->ele( `cells`
                    )->tag( `Text`
                        )->a( n = `text` v = `{NAME}`
                    )->tag( `Text`
                        )->a( n = `text` v = `{SUPPLIERNAME}`

                )->end(
            )->end(
        )->end(
    )->end( ).

    table_page->ele( `footer`
        )->ele( `Toolbar`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `id`      v = `idOpenSelected`
                )->a( n = `text`    v = `Open selected item(s)`
                )->a( n = `type`    v = `Emphasized`
                )->a( n = `visible` v = client->_bind( open_visible )
                )->a( n = `press`   v = client->_event( `OPEN_SELECTED` ) ).

    DATA(tab_page) = pages->ele( `Page`
        )->a( n = `id`             v = `tabContainerPage`
        )->a( n = `title`          v = `Tab Container`
        )->a( n = `showNavButton`  v = `true`
        )->a( n = `navButtonPress` v = client->_event( `NAV_BACK` ) ).

    " openSelectedItems builds the TabContainer in the controller and inserts it
    " into the page; here it is declared and its items are bound to the open tabs
    " sap.m.TabContainer has no default aggregation, so the item template sits in
    " an explicit items element next to the items binding
    DATA(tab_item) = tab_page->ele( `TabContainer`
        )->a( n = `id`                v = `idTabContainer`
        )->a( n = `showAddNewButton`  v = `true`
        )->a( n = `addNewButtonPress` v = client->_event( `TAB_ADD_NEW` )
        " _handleTabContainerItemClose opens with oEvent.preventDefault( ) and
        " closes the tab itself once the user has confirmed. check_prevent_default
        " IS that call: the control does not close the tab, the event still
        " reaches the backend, and tab_close( ) decides
        )->a( n = `itemClose`         v = client->_event( val    = `TAB_CLOSE`
                                                          arg    = `${$parameters>/item}.getKey()`
                                                          s_ctrl = VALUE #( check_prevent_default = abap_true ) )
        )->a( n = `itemSelect`        v = client->_event( val = `TAB_SELECT` arg = `${$parameters>/item}.getKey()` )
        )->a( n = `items`             v = client->_bind( t_tabs )

        )->ele( `items`
            )->ele( `TabContainerItem`
                )->a( n = `key`      v = `{PRODUCTID}`
                )->a( n = `name`     v = `{NAME}`
                )->a( n = `modified` v = `{MODIFIED}` ).

    DATA(tab_content) = tab_item->ele( `content` ).

    " the Display fragment - what a tab shows while it is not being edited
    tab_content->ele( `ObjectHeader`
        )->a( n = `visible`    v = |\{= !$\{MODIFIED\} \}|
        )->a( n = `title`      v = `{NAME}`
        )->a( n = `number`     v = |\{ parts:[\{path:'PRICE'\},\{path:'CURRENCYCODE'\}], type:'sap.ui.model.type.Currency', formatOptions:\{showMeasure:false\} \}|
        )->a( n = `numberUnit` v = `{CURRENCYCODE}`

        )->ele( `attributes`
            )->tag( `ObjectAttribute`
                )->a( n = `text` v = `{SUPPLIERNAME}`
            )->tag( `ObjectAttribute`
                )->a( n = `text` v = `{DESCRIPTION}`

        )->end(
    )->end( ).

    " the Edit fragment - the tab edits its OWN copy of the row, which is what
    " makes Cancel a pure discard
    tab_content->ele( n = `SimpleForm` ns = `form`
        )->a( n = `visible`  v = |\{= $\{MODIFIED\} \}|
        )->a( n = `editable` v = `true`
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->tag( `Label`
            )->a( n = `text` v = `Name`
        )->tag( `Input`
            )->a( n = `value` v = `{NAME}`
            )->a( n = `type`  v = `Text`
        )->tag( `Label`
            )->a( n = `text` v = `Supplier`
        )->tag( `Input`
            )->a( n = `value` v = `{SUPPLIERNAME}`
            )->a( n = `type`  v = `Text`
        )->tag( `Label`
            )->a( n = `text` v = `Price`
        )->tag( `Input`
            )->a( n = `value` v = `{PRICE}`
            )->a( n = `type`  v = `Number`
        )->tag( `Label`
            )->a( n = `text` v = `Description`
        )->tag( `TextArea`
            )->a( n = `value` v = `{DESCRIPTION}` ).

    DATA(add_page) = pages->ele( `Page`
        )->a( n = `id`             v = `addItemPage`
        )->a( n = `showNavButton`  v = `true`
        )->a( n = `navButtonPress` v = client->_event( `NAV_BACK` ) ).

    " handleNewItemAdd loads the same Edit fragment into the add page, over a fresh
    " JSONModel; here the add page's form binds the four add_* fields
    add_page->ele( n = `SimpleForm` ns = `form`
        )->a( n = `id`       v = `myForm`
        )->a( n = `editable` v = `true`
        )->a( n = `layout`   v = `ResponsiveGridLayout`

        )->tag( `Label`
            )->a( n = `text` v = `Name`
        )->tag( `Input`
            )->a( n = `value` v = client->_bind( add_name )
            )->a( n = `type`  v = `Text`
        )->tag( `Label`
            )->a( n = `text` v = `Supplier`
        )->tag( `Input`
            )->a( n = `value` v = client->_bind( add_supplier )
            )->a( n = `type`  v = `Text`
        )->tag( `Label`
            )->a( n = `text` v = `Price`
        )->tag( `Input`
            )->a( n = `value` v = client->_bind( add_price )
            )->a( n = `type`  v = `Number`
        )->tag( `Label`
            )->a( n = `text` v = `Description`
        )->tag( `TextArea`
            )->a( n = `value` v = client->_bind( add_description ) ).

    add_page->ele( `footer`
        )->ele( `Toolbar`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `text`  v = `Save`
                )->a( n = `type`  v = `Emphasized`
                )->a( n = `press` v = client->_event( `NEW_ITEM_SAVE` )
            )->tag( `Button`
                )->a( n = `text`  v = `Cancel`
                )->a( n = `type`  v = `Default`
                )->a( n = `press` v = client->_event( `NEW_ITEM_CANCEL` ) ).

    tab_page->ele( `footer`
        )->ele( `Toolbar`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `id`      v = `idEditItem`
                )->a( n = `text`    v = `Edit`
                )->a( n = `type`    v = `Default`
                )->a( n = `visible` v = client->_bind( edit_visible )
                )->a( n = `press`   v = client->_event( `TAB_EDIT` )
            )->tag( `Button`
                )->a( n = `id`      v = `idSaveItem`
                )->a( n = `text`    v = `Save`
                )->a( n = `type`    v = `Emphasized`
                )->a( n = `visible` v = client->_bind( save_visible )
                )->a( n = `press`   v = client->_event( `TAB_SAVE` )
            )->tag( `Button`
                )->a( n = `id`      v = `idCancel`
                )->a( n = `text`    v = `Cancel`
                )->a( n = `type`    v = `Default`
                )->a( n = `visible` v = client->_bind( cancel_visible )
                )->a( n = `press`   v = client->_event( `TAB_CANCEL` ) ).

    client->view_display( view->stringify( ) ).

    " The NavContainer's position is live control state: view_display( )
    " destroys the MAIN slot and XMLView.create builds a fresh tree, so navCon
    " comes back on its FIRST page - the table, this NavContainer declaring no
    " initialPage - while selected_tab, save_visible and cancel_visible survive
    " as class state. Four of the five branches that call view_display( ) are
    " reachable only FROM tabContainerPage (TAB_CANCEL, TAB_CLOSE,
    " CLOSE_TAB_CLOSED, TAB_ADD_NEW), so pressing + on the tab bar created the
    " tab and dropped the user on the product list while the buttons claimed an
    " open tab in edit mode. Re-issued from the LAST-issued target rather than
    " re-derived, so the branches that DO want the table (nav_to_table, the
    " tab_close redirect when the last tab goes) park `table` and are skipped
    " here by the same guard. The app-000 idiom
    IF nav_page IS NOT INITIAL AND nav_page <> `table`.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `navCon` ) ( `to` ) ( nav_page ) ) ).
    ENDIF.

    " onInit: oModel.setSizeLimit(200) - the collection is 123 rows and the
    " JSONModel caps a bound aggregation at 100, so without this the table
    " stops 23 rows short (the app-252 / app-444 idiom)
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = VALUE #( ( `200` ) ( client->cs_view-main ) ) ).

  ENDMETHOD.


  METHOD buttons_state.

    edit_visible   = edit.
    save_visible   = save.
    cancel_visible = cancel.

  ENDMETHOD.


  METHOD nav_to_table.

    " fnGoBackToTablePage: back to the table page, and the footer button follows
    " the selection that is left
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `navCon` ) ( `back` ) ) ).
    nav_page = `table`.
    open_visible = xsdbool( line_exists( t_products[ selected = abap_true ] ) ).

  ENDMETHOD.


  METHOD nav_back.

    " fnNavBackButton: leaving a page with unsaved edits asks first
    DATA(modified_names) = ``.
    LOOP AT t_tabs INTO DATA(tab) WHERE modified = abap_true.
      modified_names = modified_names && |\n| && tab-name.
    ENDLOOP.

    IF add_mode = abap_true OR modified_names IS NOT INITIAL.
      client->message_box_display(
          text         = |Your changes to the following tabs will be lost when you leave the page: \n{ modified_names }|
          type         = `warning`
          title        = `Warning`
          actions      = VALUE #( ( `Leave Page` ) ( `CANCEL` ) )
          initialfocus = `CANCEL`
          onclose      = `LEAVE_CLOSED` ).
      RETURN.
    ENDIF.

    nav_to_table( ).

  ENDMETHOD.


  METHOD unsaved_reset.

    " _resetUnsavedItems: drop the rows the add-new button created and nobody saved
    IF productid IS INITIAL.
      DELETE t_products WHERE unsaved = abap_true.
      RETURN.
    ENDIF.
    DATA(del_id) = productid.
    DELETE t_products WHERE unsaved = abap_true AND productid = del_id.

  ENDMETHOD.


  METHOD tab_close.

    DATA(del_id) = productid.
    DELETE t_tabs WHERE productid = del_id.

    " un-check the row in the table, exactly as _closeItemInTabContainer does
    ASSIGN t_products[ productid = del_id ] TO FIELD-SYMBOL(<product>).
    IF sy-subrc = 0.
      <product>-selected = abap_false.
    ENDIF.

    unsaved_reset( del_id ).

    " redirect to the table if no tab is left
    IF t_tabs IS INITIAL.
      nav_to_table( ).
    ENDIF.

  ENDMETHOD.


  METHOD tab_save.

    " handleTabContainerSaveItem: the tab's copy is written back to the product
    ASSIGN t_tabs[ productid = selected_tab ] TO FIELD-SYMBOL(<saved_tab>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    <saved_tab>-modified = abap_false.

    ASSIGN t_products[ productid = selected_tab ] TO FIELD-SYMBOL(<target>).
    IF sy-subrc = 0.
      <target>-name         = <saved_tab>-name.
      <target>-suppliername = <saved_tab>-suppliername.
      <target>-description  = <saved_tab>-description.
      <target>-price        = <saved_tab>-price.
      <target>-currencycode = <saved_tab>-currencycode.
      " the row is a real product now, not an unsaved one
      <target>-unsaved      = abap_false.
    ENDIF.

    buttons_state( edit = abap_true ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SELECTION_CHANGE`.
        open_visible = xsdbool( line_exists( t_products[ selected = abap_true ] ) ).

      WHEN `OPEN_SELECTED`.
        " openSelectedItems: one tab per selected row, filtered by ProductId
        t_tabs = VALUE #( ).
        LOOP AT t_products INTO DATA(product) WHERE selected = abap_true.
          APPEND CORRESPONDING #( product ) TO t_tabs.
        ENDLOOP.
        selected_tab = VALUE #( t_tabs[ 1 ]-productid OPTIONAL ).
        buttons_state( edit = abap_true ).
        nav_page = `tabContainerPage`.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `navCon` ) ( `to` ) ( nav_page ) ) ).

      WHEN `TAB_SELECT`.
        selected_tab = client->get_event_arg( ).
        " _handleTabContainerItemSelect: the buttons follow the tab's modified flag
        DATA(is_modified) = xsdbool( line_exists( t_tabs[ productid = selected_tab modified = abap_true ] ) ).
        buttons_state( edit = xsdbool( is_modified = abap_false ) save = is_modified cancel = is_modified ).

      WHEN `TAB_EDIT`.
        " handleTabContainerEditItem: the tab goes into edit mode over its own copy
        ASSIGN t_tabs[ productid = selected_tab ] TO FIELD-SYMBOL(<tab>).
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
        <tab>-modified = abap_true.
        buttons_state( save = abap_true cancel = abap_true ).

      WHEN `TAB_SAVE`.
        tab_save( ).

      WHEN `TAB_CANCEL`.
        " handleTabContainerCancelUpdate: a never-saved row disappears with its tab,
        " an existing one falls back to the stored product
        buttons_state( edit = abap_true ).
        IF line_exists( t_products[ productid = selected_tab unsaved = abap_true ] ).
          tab_close( selected_tab ).
        ELSE.
          ASSIGN t_tabs[ productid = selected_tab ] TO FIELD-SYMBOL(<reset_tab>).
          IF sy-subrc = 0.
            <reset_tab> = CORRESPONDING #( t_products[ productid = selected_tab ] ).
          ENDIF.
        ENDIF.
        view_display( ).

      WHEN `TAB_CLOSE`.
        pending_close = client->get_event_arg( ).
        " _handleTabContainerItemClose: a modified tab asks before it goes
        IF line_exists( t_tabs[ productid = pending_close modified = abap_true ] ).
          client->message_box_display( text         = `Your changes will be lost when you close this tab`
                                       type         = `warning`
                                       title        = `Warning`
                                       actions      = VALUE #( ( `Close Tab` ) ( `CANCEL` ) )
                                       initialfocus = `CANCEL`
                                       onclose      = `CLOSE_TAB_CLOSED` ).
        ELSE.
          tab_close( pending_close ).
        ENDIF.
        " the close was vetoed on the wire, so the tab is still there either way:
        " a confirmed close removes its row and this display drops it, a
        " cancelled one leaves the row and the tab simply stays
        view_display( ).

      WHEN `CLOSE_TAB_CLOSED`.
        IF client->get_event_arg( ) <> `CANCEL`.
          tab_close( pending_close ).
        ENDIF.
        view_display( ).

      WHEN `TAB_ADD_NEW`.
        " _handleTabContainerAddNewButtonPress: a blank product joins the collection,
        " gets selected in the table, opens as a tab and starts in edit mode
        new_counter = new_counter + 1.
        DATA(new_id) = |ProductId-{ new_counter }|.
        APPEND VALUE #( productid    = new_id
                        currencycode = `EUR`
                        selected     = abap_true
                        unsaved      = abap_true ) TO t_products.
        APPEND VALUE #( productid = new_id currencycode = `EUR` modified = abap_true ) TO t_tabs.
        selected_tab = new_id.
        buttons_state( save = abap_true cancel = abap_true ).
        view_display( ).

      WHEN `NEW_ITEM_ADD`.
        " handleNewItemAdd: a fresh edit model on the add page
        new_counter = new_counter + 1.
        add_product_id = |ProductId-{ new_counter }|.
        add_name = VALUE #( ).
        add_supplier = VALUE #( ).
        add_description = VALUE #( ).
        add_price = 0.
        add_mode = abap_true.
        nav_page = `addItemPage`.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `navCon` ) ( `to` ) ( nav_page ) ) ).

      WHEN `NEW_ITEM_SAVE`.
        " handleNewItemSave: the form's data joins the collection
        APPEND VALUE #( productid    = add_product_id
                        name         = add_name
                        suppliername = add_supplier
                        description  = add_description
                        price        = add_price
                        currencycode = `EUR` ) TO t_products.
        add_mode = abap_false.
        nav_to_table( ).

      WHEN `NEW_ITEM_CANCEL`.
        add_mode = abap_false.
        nav_to_table( ).

      WHEN `NAV_BACK`.
        nav_back( ).

      WHEN `LEAVE_CLOSED`.
        " the confirmation's non-cancel action: leave the page and drop every row
        " the add-new button created and nobody saved
        IF client->get_event_arg( ) <> `CANCEL`.
          add_mode = abap_false.
          nav_to_table( ).
          unsaved_reset( ).
          " a tab whose product is gone goes with it
          LOOP AT t_tabs REFERENCE INTO DATA(tab).
            IF NOT line_exists( t_products[ productid = tab->productid ] ).
              DELETE t_tabs INDEX sy-tabix.
            ENDIF.
          ENDLOOP.
          view_display( ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " the full mock /ProductCollection (sap/ui/demo/mock/products.json), all 123
    " rows - onInit raises the model size limit to 200 so the table shows them all
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
