" @keywords selectdialog select dialog sap.m product list standardlistitem verticallayout button customdata input
" @summary The Select Dialog allows the user to search for and pick an item from a possibly long option list. Basically it is a convenience function to quickly assemble a Dialog, a Search Field and a List with Standard List Items.
" @origin sap.m.sample.SelectDialog - https://sdk.openui5.org/entity/sap.m.SelectDialog/sample/sap.m.sample.SelectDialog (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_103 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " the productInput's value, bound two-way: the value help preselects the
    " row matching WHAT IS IN THE FIELD (original _configValueHelpDialog reads
    " byId('productInput').getValue()), and the close handler writes back into it
    DATA product_value TYPE string.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        description   TYPE string,
        category      TYPE string,
        maincategory  TYPE string,
        suppliername  TYPE string,
        width         TYPE string,
        depth         TYPE string,
        height        TYPE string,
        dimunit       TYPE string,
        weightmeasure TYPE string,
        weightunit    TYPE string,
        quantity      TYPE string,
        price         TYPE p LENGTH 8 DECIMALS 2,
        currencycode  TYPE string,
        productpicurl TYPE string,
        selected      TYPE abap_bool,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA multi_select TYPE abap_bool.
    DATA growing TYPE abap_bool.
    DATA growing_threshold TYPE i.
    DATA remember TYPE abap_bool.
    DATA show_clear TYPE abap_bool.
    DATA confirm_text TYPE string.
    DATA draggable TYPE abap_bool.
    DATA resizable TYPE abap_bool.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_event_item,
        id    TYPE string,
        title TYPE string,
      END OF ty_s_event_item.
    TYPES ty_t_event_item TYPE STANDARD TABLE OF ty_s_event_item WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    CONSTANTS c_img_base TYPE string VALUE `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/`.

    METHODS view_display.
    METHODS on_event.
    METHODS event_items
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_event_item.
    METHODS open_dialog IMPORTING multi       TYPE abap_bool DEFAULT abap_false
                                  rem         TYPE abap_bool DEFAULT abap_false
                                  grow        TYPE abap_bool DEFAULT abap_false
                                  threshold   TYPE i         DEFAULT 0
                                  clear       TYPE abap_bool DEFAULT abap_false
                                  confirmtext TYPE string    DEFAULT ``
                                  drag        TYPE abap_bool DEFAULT abap_false
                                  resize      TYPE abap_bool DEFAULT abap_false
                                  responsive  TYPE abap_bool DEFAULT abap_false.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_103 IMPLEMENTATION.

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

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( n = `dependents` ns = `mvc`
            )->ele( `SelectDialog`
                )->a( n = `id`                 v = `mySelectDialog`
                )->a( n = `noDataText`         v = `No Products Found`
                )->a( n = `title`              v = `Select Product`
                )->a( n = `search`             v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                             t_arg = VALUE #( ( `mySelectDialog` ) ( `items` ) ( `filter` ) ( `NAME` ) ( `Contains` ) ( `${$parameters>/value}` ) ) )
                )->a( n = `confirm`            v = client->_event( val = `CONFIRM` arg = `${$parameters>/selectedItems}` )
                )->a( n = `cancel`             v = client->_event( val = `CONFIRM` arg = `${$parameters>/selectedItems}` )
                )->a( n = `multiSelect`        v = client->_bind( multi_select )
                )->a( n = `growing`            v = client->_bind( growing )
                )->a( n = `growingThreshold`   v = client->_bind( growing_threshold )
                )->a( n = `rememberSelections` v = client->_bind( remember )
                )->a( n = `showClearButton`    v = client->_bind( show_clear )
                )->a( n = `confirmButtonText`  v = client->_bind( confirm_text )
                )->a( n = `draggable`          v = client->_bind( draggable )
                )->a( n = `resizable`          v = client->_bind( resizable )
                )->a( n = `items`              v = client->_bind( t_products )

                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `description`      v = `{PRODUCTID}`
                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `type`             v = `Active`

            )->end(
            )->ele( `SelectDialog`
                )->a( n = `id`                v = `valueHelpDialog`
                )->a( n = `noDataText`        v = `No Products Found`
                )->a( n = `title`             v = `Select Product`
                )->a( n = `search`            v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                            t_arg = VALUE #( ( `valueHelpDialog` ) ( `items` ) ( `filter` ) ( `NAME` ) ( `Contains` ) ( `${$parameters>/value}` ) ) )
                )->a( n = `searchPlaceholder` v = `Search Products`
                )->a( n = `confirm`           v = client->_event( val = `VH_CLOSE` arg = `${$parameters>/selectedItem} ? ${$parameters>/selectedItem}.getTitle() : ''` )
                )->a( n = `cancel`            v = client->_event( `VH_CLOSE` )
                )->a( n = `showClearButton`   v = `true`
                )->a( n = `items`             v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME', descending: false \} \}|

                )->tag( `StandardListItem`
                    )->a( n = `selected`         v = `{SELECTED}`
                    )->a( n = `title`            v = `{NAME}`
                    )->a( n = `description`      v = `{PRODUCTID}`
                    )->a( n = `icon`             v = `{PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `type`             v = `Active`

            )->end(
        )->end(

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog`
                )->a( n = `press` v = client->_event( `OPEN_1` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog (Remember)`
                )->a( n = `press` v = client->_event( `OPEN_2` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `remember`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog (Multi)`
                )->a( n = `press` v = client->_event( `OPEN_3` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog (Remember)`
                )->a( n = `press` v = client->_event( `OPEN_4` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `remember`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `showClearButton`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `confirmButtonText`
                        )->a( n = `value` v = `Remember Selection`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog (growingThreshold=15)`
                )->a( n = `press` v = client->_event( `OPEN_5` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `remember`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `growing`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `threshold`
                        )->a( n = `value` v = `15`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog (growing=false)`
                )->a( n = `press` v = client->_event( `OPEN_6` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `remember`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `growing`
                        )->a( n = `value` v = `false`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog (draggable=true)`
                )->a( n = `press` v = client->_event( `OPEN_7` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `draggable`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog (resizable=true)`
                )->a( n = `press` v = client->_event( `OPEN_8` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `multi`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `resizable`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->ele( `Button`
                )->a( n = `text`  v = `Show Select Dialog with Responsive Padding`
                )->a( n = `press` v = client->_event( `OPEN_9` )
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `customData`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `responsivePadding`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `resizable`
                        )->a( n = `value` v = `true`
                    )->tag( n = `CustomData` ns = `core`
                        )->a( n = `key`   v = `draggable`
                        )->a( n = `value` v = `true`

                )->end(
            )->end(
            )->tag( `Input`
                )->a( n = `id`               v = `productInput`
                )->a( n = `type`             v = `Text`
                )->a( n = `value`            v = client->_bind( product_value )
                )->a( n = `placeholder`      v = `Enter Product ...`
                )->a( n = `showValueHelp`    v = `true`
                )->a( n = `valueHelpRequest` v = client->_event( `VALUE_HELP` )
                )->a( n = `class`            v = `sapUiSmallMarginBottom`
                )->a( n = `width`            v = `15rem` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `OPEN_1`.
        open_dialog( ).

      WHEN `OPEN_2`.
        open_dialog( rem = abap_true ).

      WHEN `OPEN_3`.
        open_dialog( multi = abap_true ).

      WHEN `OPEN_4`.
        open_dialog( multi = abap_true rem = abap_true clear = abap_true confirmtext = `Remember Selection` ).

      WHEN `OPEN_5`.
        open_dialog( multi = abap_true rem = abap_true grow = abap_true threshold = 15 ).

      WHEN `OPEN_6`.
        open_dialog( multi = abap_true rem = abap_true ).

      WHEN `OPEN_7`.
        open_dialog( multi = abap_true drag = abap_true ).

      WHEN `OPEN_8`.
        open_dialog( multi = abap_true resize = abap_true ).

      WHEN `OPEN_9`.
        open_dialog( responsive = abap_true resize = abap_true drag = abap_true ).

      WHEN `VALUE_HELP`.
        " preselect the row matching the current input value (original _configValueHelpDialog)
        LOOP AT t_products REFERENCE INTO DATA(lr).
          lr->selected = xsdbool( lr->name = product_value ).
        ENDLOOP.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `valueHelpDialog` ) ( `open` ) ) ).

      WHEN `CONFIRM`.
        " onDialogClose: name every chosen product, or say that none was
        " picked. The original reads selectedContexts and maps getObject().Name;
        " a Context is not a control, so the wire carries the selectedItems
        " ARRAY instead - the frontend projects each StandardListItem to its
        " public properties, and title is the bound Name. Cancel fires the same
        " handler with no selection, which is the original's else branch
        DATA(sel_items) = event_items( client->get_event_arg( ) ).
        IF sel_items IS INITIAL.
          client->message_toast_display( `No new item was selected.` ).
        ELSE.
          DATA(sel_names) = ``.
          LOOP AT sel_items REFERENCE INTO DATA(sel).
            sel_names = COND #( WHEN sel_names IS INITIAL THEN sel->title ELSE |{ sel_names }, { sel->title }| ).
          ENDLOOP.
          client->message_toast_display( |You have chosen { sel_names }| ).
        ENDIF.
        " ... and the last line of onDialogClose:
        " oEvent.getSource( ).getBinding( 'items' ).filter( [] ) - so the
        " search a user typed is gone the next time the dialog opens. A
        " binding_call filter with no values is exactly that clear (the
        " client leaves the filter empty when value1 and value2 both are)
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = VALUE #( ( `mySelectDialog` ) ( `items` ) ( `filter` ) ) ).

      WHEN `VH_CLOSE`.
        " onValueHelpDialogClose: the picked title lands in the input, and a
        " close with no selection resets it (the original's resetProperty)
        product_value = client->get_event_arg( ).

    ENDCASE.

  ENDMETHOD.


  METHOD event_items.

    DATA(json) = condense( val ).
    IF json IS INITIAL.
      RETURN.
    ENDIF.

    IF json(1) <> `[`.
      json = |[{ json }]|.
    ENDIF.

    TRY.
        " the frontend marshals a control with ALL its public properties
        " (description, icon, type, ...), so only the fields this port models
        " are mapped - a plain to_abap( ) fails on the first extra one
        "
        " z2ui5_cl_ajson is the framework's VENDORED ajson copy and lives
        " outside the released API (src/02), so it may be renamed or
        " restructured without notice - the linter says so, and it is right.
        " There is no released JSON reader to use instead, the same reasoning
        " as app 298; declared as a deviation in the sidecar
        " abap2ui5lint-disable-next-line non-released-api -- no released JSON reader exists; see the comment above and the sidecar deviation
        z2ui5_cl_ajson=>parse( json
          )->to_abap_corresponding_only(
          )->to_abap( IMPORTING ev_container = result ).
        " abap2ui5lint-disable-next-line non-released-api -- the exception of the call above
      CATCH z2ui5_cx_ajson_error.
        result = VALUE #( ).
    ENDTRY.

  ENDMETHOD.


  METHOD open_dialog.

    multi_select      = multi.
    remember          = rem.
    growing           = grow.
    growing_threshold = threshold.
    show_clear        = clear.
    confirm_text      = confirmtext.
    draggable         = drag.
    resizable         = resize.

    IF responsive = abap_true.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `mySelectDialog` ) ( `addStyleClass` )
                                                 ( `sapUiResponsivePadding--header sapUiResponsivePadding--subHeader sapUiResponsivePadding--content sapUiResponsivePadding--footer` ) ) ).
    ELSE.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = VALUE #( ( `mySelectDialog` ) ( `removeStyleClass` )
                                                 ( `sapUiResponsivePadding--header sapUiResponsivePadding--subHeader sapUiResponsivePadding--content sapUiResponsivePadding--footer` ) ) ).
    ENDIF.

    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `mySelectDialog` ) ( `open` ) ) ).

  ENDMETHOD.


  METHOD model_init.

    " the original's view seeds the input with this product
    product_value = `Astro Phone 6`.

    t_products = VALUE #(
      ( name = `Notebook Basic 15` productid = `HT-1000` category = `Laptops` maincategory = `Computer Systems` suppliername = `Very Best Screens`
        description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`
        width = `30` depth = `18` height = `3` dimunit = `cm` weightmeasure = `4.2` weightunit = `KG`
        quantity = `10` price = '956.00' currencycode = `EUR` )
      ( name = `Notebook Basic 17` productid = `HT-1001` category = `Laptops` maincategory = `Computer Systems` suppliername = `Very Best Screens`
        description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`
        width = `29` depth = `17` height = `3.1` dimunit = `cm` weightmeasure = `4.5` weightunit = `KG`
        quantity = `20` price = '1249.00' currencycode = `EUR` )
      ( name = `Notebook Basic 18` productid = `HT-1002` category = `Laptops` maincategory = `Computer Systems` suppliername = `Very Best Screens`
        description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`
        width = `28` depth = `19` height = `2.5` dimunit = `cm` weightmeasure = `4.2` weightunit = `KG`
        quantity = `10` price = '1570.00' currencycode = `EUR` )
      ( name = `Notebook Basic 19` productid = `HT-1003` category = `Laptops` maincategory = `Computer Systems` suppliername = `Smartcards`
        description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`
        width = `32` depth = `21` height = `4` dimunit = `cm` weightmeasure = `4.2` weightunit = `KG`
        quantity = `15` price = '1650.00' currencycode = `EUR` )
      ( name = `ITelO Vault` productid = `HT-1007` category = `Accessories` maincategory = `Computer Components` suppliername = `Technocom`
        description = `Digital Organizer with State-of-the-Art Storage Encryption`
        width = `32` depth = `22` height = `3` dimunit = `cm` weightmeasure = `0.2` weightunit = `KG`
        quantity = `15` price = '299.00' currencycode = `EUR` )
      ( name = `Notebook Professional 15` productid = `HT-1010` category = `Accessories` maincategory = `Computer Systems` suppliername = `Very Best Screens`
        description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`
        width = `33` depth = `20` height = `3` dimunit = `cm` weightmeasure = `4.3` weightunit = `KG`
        quantity = `16` price = '1999.00' currencycode = `EUR` )
      ( name = `Notebook Professional 17` productid = `HT-1011` category = `Laptops` maincategory = `Computer Systems` suppliername = `Very Best Screens`
        description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`
        width = `33` depth = `23` height = `2` dimunit = `cm` weightmeasure = `4.1` weightunit = `KG`
        quantity = `17` price = '2299.00' currencycode = `EUR` )
      ( name = `ITelO Vault Net` productid = `HT-1020` category = `Accessories` maincategory = `Computer Components` suppliername = `Technocom`
        description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`
        width = `10` depth = `1.8` height = `17` dimunit = `cm` weightmeasure = `0.16` weightunit = `KG`
        quantity = `14` price = '459.00' currencycode = `EUR` )
      ( name = `ITelO Vault SAT` productid = `HT-1021` category = `Accessories` maincategory = `Computer Components` suppliername = `Technocom`
        description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`
        width = `11` depth = `1.7` height = `18` dimunit = `cm` weightmeasure = `0.18` weightunit = `KG`
        quantity = `50` price = '149.00' currencycode = `EUR` )
      ( name = `Comfort Easy` productid = `HT-1022` category = `Accessories` maincategory = `Computer Components` suppliername = `Technocom`
        description = `32 GB Digital Assistant with high-resolution color screen`
        width = `84` depth = `1.5` height = `14` dimunit = `cm` weightmeasure = `0.2` weightunit = `KG`
        quantity = `30` price = '1679.00' currencycode = `EUR` )
      ( name = `Comfort Senior` productid = `HT-1023` category = `Accessories` maincategory = `Computer Components` suppliername = `Technocom`
        description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`
        width = `80` depth = `1.6` height = `13` dimunit = `cm` weightmeasure = `0.8` weightunit = `KG`
        quantity = `24` price = '512.00' currencycode = `EUR` )
      ( name = `Ergo Screen E-I` productid = `HT-1030` category = `Flat Screen Monitors` maincategory = `Computer Components` suppliername = `Very Best Screens`
        description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`
        width = `37` depth = `12` height = `36` dimunit = `cm` weightmeasure = `21` weightunit = `KG`
        quantity = `14` price = '230.00' currencycode = `EUR` )
      ( name = `Ergo Screen E-II` productid = `HT-1031` category = `Flat Screen Monitors` maincategory = `Computer Components` suppliername = `Very Best Screens`
        description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`
        width = `40.8` depth = `19` height = `43` dimunit = `cm` weightmeasure = `21` weightunit = `KG`
        quantity = `24` price = '285.00' currencycode = `EUR` )
      ( name = `Ergo Screen E-III` productid = `HT-1032` category = `Flat Screen Monitors` maincategory = `Computer Components` suppliername = `Very Best Screens`
        description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`
        width = `40.8` depth = `19` height = `43` dimunit = `cm` weightmeasure = `21` weightunit = `KG`
        quantity = `50` price = '345.00' currencycode = `EUR` )
      ( name = `Flat Basic` productid = `HT-1035` category = `Flat Screen Monitors` maincategory = `Computer Components` suppliername = `Very Best Screens`
        description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`
        width = `39` depth = `20` height = `41` dimunit = `cm` weightmeasure = `14` weightunit = `KG`
        quantity = `23` price = '399.00' currencycode = `EUR` )
      ( name = `Flat Future` productid = `HT-1036` category = `Flat Screen Monitors` maincategory = `Computer Components` suppliername = `Very Best Screens`
        description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`
        width = `45` depth = `26` height = `46` dimunit = `cm` weightmeasure = `15` weightunit = `KG`
        quantity = `22` price = '430.00' currencycode = `EUR` )
      ( name = `Flat XL` productid = `HT-1037` category = `Flat Screen Monitors` maincategory = `Computer Components` suppliername = `Very Best Screens`
        description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`
        width = `54.5` depth = `22.1` height = `39.1` dimunit = `cm` weightmeasure = `17` weightunit = `KG`
        quantity = `23` price = '1230.00' currencycode = `EUR` )
      ( name = `Laser Professional Eco` productid = `HT-1040` category = `Printers` maincategory = `Printers & Scanners` suppliername = `Alpha Printers`
        description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`
        width = `51` depth = `46` height = `30` dimunit = `cm` weightmeasure = `32` weightunit = `KG`
        quantity = `21` price = '830.00' currencycode = `EUR` )
      ( name = `Laser Basic` productid = `HT-1041` category = `Printers` maincategory = `Printers & Scanners` suppliername = `Alpha Printers`
        description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`
        width = `48` depth = `42` height = `26` dimunit = `cm` weightmeasure = `23` weightunit = `KG`
        quantity = `8` price = '490.00' currencycode = `EUR` )
      ( name = `Laser Allround` productid = `HT-1042` category = `Printers` maincategory = `Printers & Scanners` suppliername = `Alpha Printers`
        description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`
        width = `53` depth = `50` height = `65` dimunit = `cm` weightmeasure = `17` weightunit = `KG`
        quantity = `9` price = '349.00' currencycode = `EUR` )
      ( name = `Ultra Jet Super Color` productid = `HT-1050` category = `Printers` maincategory = `Printers & Scanners` suppliername = `Alpha Printers`
        description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`
        width = `41` depth = `41` height = `28` dimunit = `cm` weightmeasure = `3` weightunit = `KG`
        quantity = `17` price = '139.00' currencycode = `EUR` )
      ( name = `Ultra Jet Mobile` productid = `HT-1051` category = `Printers` maincategory = `Printers & Scanners` suppliername = `Printer for All`
        description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`
        width = `46` depth = `32` height = `25` dimunit = `cm` weightmeasure = `1.9` weightunit = `KG`
        quantity = `18` price = '99.00' currencycode = `EUR` )
      ( name = `Ultra Jet Super Highspeed` productid = `HT-1052` category = `Printers` maincategory = `Printers & Scanners` suppliername = `Printer for All`
        description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`
        width = `41` depth = `41` height = `28` dimunit = `cm` weightmeasure = `18` weightunit = `KG`
        quantity = `25` price = '170.00' currencycode = `EUR` )
      ( name = `Multi Print` productid = `HT-1055` category = `Multifunction Printers` maincategory = `Printers & Scanners` suppliername = `Printer for All`
        description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`
        width = `55` depth = `45` height = `29` dimunit = `cm` weightmeasure = `6.3` weightunit = `KG`
        quantity = `16` price = '99.00' currencycode = `EUR` )
      ( name = `Multi Color` productid = `HT-1056` category = `Multifunction Printers` maincategory = `Printers & Scanners` suppliername = `Printer for All`
        description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`
        width = `51` depth = `41.3` height = `22` dimunit = `cm` weightmeasure = `4.3` weightunit = `KG`
        quantity = `5` price = '119.00' currencycode = `EUR` )
      ( name = `Cordless Mouse` productid = `HT-1060` category = `Mice` maincategory = `Computer Components` suppliername = `Oxynum`
        description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`
        width = `6` depth = `14.5` height = `3.5` dimunit = `cm` weightmeasure = `0.09` weightunit = `KG`
        quantity = `25` price = '9.00' currencycode = `EUR` )
      ( name = `Speed Mouse` productid = `HT-1061` category = `Mice` maincategory = `Computer Components` suppliername = `Oxynum`
        description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`
        width = `7` depth = `15` height = `3.1` dimunit = `cm` weightmeasure = `0.09` weightunit = `KG`
        quantity = `12` price = '7.00' currencycode = `EUR` )
      ( name = `Track Mouse` productid = `HT-1062` category = `Mice` maincategory = `Computer Components` suppliername = `Oxynum`
        description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`
        width = `3` depth = `7` height = `4` dimunit = `cm` weightmeasure = `0.03` weightunit = `KG`
        quantity = `12` price = '11.00' currencycode = `EUR` )
      ( name = `Ergonomic Keyboard` productid = `HT-1063` category = `Keyboards` maincategory = `Computer Components` suppliername = `Oxynum`
        description = `Ergonomic USB Keyboard for Desktop, Plug&Play`
        width = `50` depth = `21` height = `3.5` dimunit = `cm` weightmeasure = `2.1` weightunit = `KG`
        quantity = `50` price = '14.00' currencycode = `EUR` )
      ( name = `Internet Keyboard` productid = `HT-1064` category = `Keyboards` maincategory = `Computer Components` suppliername = `Oxynum`
        description = `Corded Keyboard with special keys for Internet Usability, USB`
        width = `52` depth = `25` height = `3` dimunit = `cm` weightmeasure = `1.8` weightunit = `KG`
        quantity = `35` price = '16.00' currencycode = `EUR` )
      ( name = `Media Keyboard` productid = `HT-1065` category = `Keyboards` maincategory = `Computer Components` suppliername = `Oxynum`
        description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`
        width = `51.4` depth = `23` height = `4` dimunit = `cm` weightmeasure = `2.3` weightunit = `KG`
        quantity = `26` price = '26.00' currencycode = `EUR` )
      ( name = `Mousepad` productid = `HT-1066` category = `Mousepads` maincategory = `Computer Components` suppliername = `Oxynum`
        description = `Nice mouse pad with ITelO Logo`
        width = `15` depth = `6` height = `0.2` dimunit = `cm` weightmeasure = `80` weightunit = `G`
        quantity = `12` price = '6.99' currencycode = `EUR` )
      ( name = `Ergo Mousepad` productid = `HT-1067` category = `Mousepads` maincategory = `Computer Components` suppliername = `Oxynum`
        description = `Ergonomic mouse pad with ITelO Logo`
        width = `15` depth = `6` height = `0.2` dimunit = `cm` weightmeasure = `80` weightunit = `G`
        quantity = `16` price = '8.99' currencycode = `EUR` )
      ( name = `Designer Mousepad` productid = `HT-1068` category = `Mousepads` maincategory = `Computer Components` suppliername = `Fasttech`
        description = `ITelO Mousepad Special Edition`
        width = `24` depth = `24` height = `0.6` dimunit = `cm` weightmeasure = `90` weightunit = `G`
        quantity = `26` price = '12.99' currencycode = `EUR` )
      ( name = `Universal card reader` productid = `HT-1069` category = `Computer System Accessories` maincategory = `Computer Systems` suppliername = `Fasttech`
        description = `Universal card reader`
        width = `6` depth = `6` height = `3` dimunit = `cm` weightmeasure = `45` weightunit = `G`
        quantity = `22` price = '14.00' currencycode = `EUR` )
      ( name = `Proctra X` productid = `HT-1070` category = `Graphic Cards` maincategory = `Computer Components` suppliername = `Ultrasonic United`
        description = `Proctra X: PCI-E GDDR5 3072MB`
        width = `22` depth = `35` height = `17` dimunit = `cm` weightmeasure = `0.255` weightunit = `KG`
        quantity = `15` price = '70.90' currencycode = `EUR` )
      ( name = `Gladiator MX` productid = `HT-1071` category = `Graphic Cards` maincategory = `Computer Components` suppliername = `Ultrasonic United`
        description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`
        width = `22` depth = `35` height = `17` dimunit = `cm` weightmeasure = `0.3` weightunit = `KG`
        quantity = `16` price = '81.70' currencycode = `EUR` )
      ( name = `Hurricane GX` productid = `HT-1072` category = `Graphic Cards` maincategory = `Computer Components` suppliername = `Ultrasonic United`
        description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`
        width = `22` depth = `35` height = `17` dimunit = `cm` weightmeasure = `0.4` weightunit = `KG`
        quantity = `13` price = '101.20' currencycode = `EUR` )
      ( name = `Hurricane GX/LN` productid = `HT-1073` category = `Graphic Cards` maincategory = `Computer Components` suppliername = `Smartcards`
        description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`
        width = `22` depth = `35` height = `17` dimunit = `cm` weightmeasure = `0.4` weightunit = `KG`
        quantity = `5` price = '139.99' currencycode = `EUR` )
      ( name = `Photo Scan` productid = `HT-1080` category = `Scanners` maincategory = `Printers & Scanners` suppliername = `Printer for All`
        description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`
        width = `34` depth = `48` height = `5` dimunit = `cm` weightmeasure = `2.3` weightunit = `KG`
        quantity = `8` price = '129.00' currencycode = `EUR` )
      ( name = `Power Scan` productid = `HT-1081` category = `Scanners` maincategory = `Printers & Scanners` suppliername = `Printer for All`
        description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`
        width = `31` depth = `43` height = `7` dimunit = `cm` weightmeasure = `2.4` weightunit = `KG`
        quantity = `11` price = '89.00' currencycode = `EUR` )
      ( name = `Jet Scan Professional` productid = `HT-1082` category = `Scanners` maincategory = `Printers & Scanners` suppliername = `Printer for All`
        description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`
        width = `33` depth = `41` height = `12` dimunit = `cm` weightmeasure = `3.2` weightunit = `KG`
        quantity = `13` price = '169.00' currencycode = `EUR` )
      ( name = `Jet Scan Professional` productid = `HT-1083` category = `Scanners` maincategory = `Printers & Scanners` suppliername = `Printer for All`
        description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`
        width = `35` depth = `40` height = `10` dimunit = `cm` weightmeasure = `3.2` weightunit = `KG`
        quantity = `10` price = '189.00' currencycode = `EUR` )
      ( name = `Copymaster` productid = `HT-1085` category = `Multifunction Printers` maincategory = `Printers & Scanners` suppliername = `Alpha Printers`
        description = `Copymaster`
        width = `45` depth = `42` height = `22` dimunit = `cm` weightmeasure = `23.2` weightunit = `KG`
        quantity = `10` price = '1499.00' currencycode = `EUR` )
      ( name = `Surround Sound` productid = `HT-1090` category = `Speakers` maincategory = `Computer Components` suppliername = `Speaker Experts`
        description = `PC multimedia speakers - 5 Watt (Total)`
        width = `12` depth = `10` height = `16` dimunit = `cm` weightmeasure = `3` weightunit = `KG`
        quantity = `20` price = '39.00' currencycode = `EUR` )
      ( name = `Blaster Extreme` productid = `HT-1091` category = `Speakers` maincategory = `Computer Components` suppliername = `Speaker Experts`
        description = `PC multimedia speakers - 10 Watt (Total) - 2-way`
        width = `13` depth = `11` height = `17.5` dimunit = `cm` weightmeasure = `1.4` weightunit = `KG`
        quantity = `15` price = '26.00' currencycode = `EUR` )
      ( name = `Sound Booster` productid = `HT-1092` category = `Speakers` maincategory = `Computer Components` suppliername = `Speaker Experts`
        description = `PC multimedia speakers - optimized for Blutooth/A2DP`
        width = `12.4` depth = `10.4` height = `18.1` dimunit = `cm` weightmeasure = `2.1` weightunit = `KG`
        quantity = `50` price = '45.00' currencycode = `EUR` )
      ( name = `Lovely Sound 5.1 Wireless` productid = `HT-1095` category = `Accessories` maincategory = `Computer Components` suppliername = `Fasttech`
        description = `5.1 Headset, 40 Hz-20 kHz, Wireless`
        width = `24` depth = `19` height = `23` dimunit = `cm` weightmeasure = `80` weightunit = `G`
        quantity = `12` price = '49.00' currencycode = `EUR` )
      ( name = `Lovely Sound 5.1` productid = `HT-1096` category = `Accessories` maincategory = `Computer Components` suppliername = `Fasttech`
        description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`
        width = `25` depth = `17` height = `19` dimunit = `cm` weightmeasure = `130` weightunit = `G`
        quantity = `18` price = '39.00' currencycode = `EUR` )
      ( name = `Lovely Sound Stereo` productid = `HT-1097` category = `Accessories` maincategory = `Computer Components` suppliername = `Fasttech`
        description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`
        width = `21.3` depth = `2.4` height = `19.7` dimunit = `cm` weightmeasure = `60` weightunit = `G`
        quantity = `21` price = '29.00' currencycode = `EUR` )
      ( name = `Smart Office` productid = `HT-1100` category = `Software` maincategory = `Software` suppliername = `Technocom`
        description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`
        width = `15` depth = `6.5` height = `2.1` dimunit = `cm` weightmeasure = `1.2` weightunit = `KG`
        quantity = `25` price = '89.90' currencycode = `EUR` )
      ( name = `Smart Design` productid = `HT-1101` category = `Software` maincategory = `Software` suppliername = `Technocom`
        description = `Complete package, 1 User, Image editing, processing`
        width = `14` depth = `6.7` height = `24` dimunit = `cm` weightmeasure = `0.8` weightunit = `KG`
        quantity = `26` price = '79.90' currencycode = `EUR` )
      ( name = `Smart Network` productid = `HT-1102` category = `Software` maincategory = `Software` suppliername = `Technocom`
        description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`
        width = `16` depth = `6` height = `27` dimunit = `cm` weightmeasure = `0.8` weightunit = `KG`
        quantity = `28` price = '69.00' currencycode = `EUR` )
      ( name = `Smart Multimedia` productid = `HT-1103` category = `Software` maincategory = `Software` suppliername = `Technocom`
        description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`
        width = `11` depth = `3.4` height = `22` dimunit = `cm` weightmeasure = `0.8` weightunit = `KG`
        quantity = `9` price = '77.00' currencycode = `EUR` )
      ( name = `Smart Games` productid = `HT-1104` category = `Software` maincategory = `Software` suppliername = `Technocom`
        description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`
        width = `10` depth = `3` height = `30` dimunit = `cm` weightmeasure = `1.1` weightunit = `KG`
        quantity = `13` price = '55.00' currencycode = `EUR` )
      ( name = `Smart Internet Antivirus` productid = `HT-1105` category = `Software` maincategory = `Software` suppliername = `Brainsoft`
        description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`
        width = `16` depth = `4` height = `21` dimunit = `cm` weightmeasure = `0.7` weightunit = `KG`
        quantity = `17` price = '29.00' currencycode = `EUR` )
      ( name = `Smart Firewall` productid = `HT-1106` category = `Software` maincategory = `Software` suppliername = `Brainsoft`
        description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`
        width = `17.9` depth = `4.2` height = `23.1` dimunit = `cm` weightmeasure = `0.9` weightunit = `KG`
        quantity = `19` price = '34.00' currencycode = `EUR` )
      ( name = `Smart Money` productid = `HT-1107` category = `Software` maincategory = `Software` suppliername = `Brainsoft`
        description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`
        width = `12` depth = `1.5` height = `19` dimunit = `cm` weightmeasure = `0.5` weightunit = `KG`
        quantity = `18` price = '29.90' currencycode = `EUR` )
      ( name = `PC Lock` productid = `HT-1110` category = `Computer System Accessories` maincategory = `Computer Systems` suppliername = `Red Point Stores`
        description = `Robust 3m anti-burglary protection for your laptop computer`
        width = `20` depth = `8` height = `4.3` dimunit = `cm` weightmeasure = `0.03` weightunit = `KG`
        quantity = `14` price = '8.90' currencycode = `EUR` )
      ( name = `Notebook Lock` productid = `HT-1111` category = `Computer System Accessories` maincategory = `Computer Systems` suppliername = `Red Point Stores`
        description = `Robust 1m anti-burglary protection for your desktop computer`
        width = `31` depth = `9` height = `7` dimunit = `cm` weightmeasure = `0.02` weightunit = `KG`
        quantity = `20` price = '6.90' currencycode = `EUR` )
      ( name = `Web cam reality` productid = `HT-1112` category = `Computer System Accessories` maincategory = `Computer Systems` suppliername = `Red Point Stores`
        description = `Color webcam, color, High-Speed USB`
        width = `9` depth = `8.2` height = `1.3` dimunit = `cm` weightmeasure = `0.075` weightunit = `KG`
        quantity = `27` price = '39.00' currencycode = `EUR` )
      ( name = `Screen clean` productid = `HT-1113` category = `Computer System Accessories` maincategory = `Computer Systems` suppliername = `Red Point Stores`
        description = `10 separately packed screen wipes`
        width = `2` depth = `2` height = `0.1` dimunit = `cm` weightmeasure = `0.05` weightunit = `KG`
        quantity = `17` price = '2.30' currencycode = `EUR` )
      ( name = `Fabric bag professional` productid = `HT-1114` category = `Computer System Accessories` maincategory = `Computer Systems` suppliername = `Red Point Stores`
        description = `Notebook bag, plenty of room for stationery and writing materials`
        width = `42` depth = `32` height = `7` dimunit = `cm` weightmeasure = `1.8` weightunit = `KG`
        quantity = `14` price = '31.00' currencycode = `EUR` )
      ( name = `Wireless DSL Router` productid = `HT-1115` category = `Telecommunications` maincategory = `Computer Components` suppliername = `Red Point Stores`
        description = `Wireless DSL Router (available in blue, black and silver)`
        width = `19.3` depth = `18` height = `5` dimunit = `cm` weightmeasure = `0.45` weightunit = `KG`
        quantity = `16` price = '49.00' currencycode = `EUR` )
      ( name = `Wireless DSL Router / Repeater` productid = `HT-1116` category = `Telecommunications` maincategory = `Computer Components` suppliername = `Red Point Stores`
        description = `Wireless DSL Router / Repeater (available in blue, black and silver)`
        width = `19.3` depth = `18` height = `5` dimunit = `cm` weightmeasure = `0.45` weightunit = `KG`
        quantity = `12` price = '59.00' currencycode = `EUR` )
      ( name = `Wireless DSL Router / Repeater and Print Server` productid = `HT-1117` category = `Telecommunications` maincategory = `Computer Components` suppliername = `Technocom`
        description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`
        width = `19.3` depth = `18` height = `5` dimunit = `cm` weightmeasure = `0.45` weightunit = `KG`
        quantity = `12` price = '69.00' currencycode = `EUR` )
      ( name = `USB Stick` productid = `HT-1118` category = `Computer System Accessories` maincategory = `Computer Systems` suppliername = `Technocom`
        description = `USB 2.0 High-Speed 64 GB`
        width = `1.5` depth = `8.7` height = `1.2` dimunit = `cm` weightmeasure = `0.015` weightunit = `KG`
        quantity = `14` price = '35.00' currencycode = `EUR` )
      ( name = `Travel Adapter` productid = `HT-1119` category = `Accessories` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Universal Travel Adapter`
        width = `2` depth = `3.1` height = `3.9` dimunit = `cm` weightmeasure = `88` weightunit = `G`
        quantity = `10` price = '79.00' currencycode = `EUR` )
      ( name = `Cordless Bluetooth Keyboard, english international` productid = `HT-1120` category = `Keyboards` maincategory = `Computer Components` suppliername = `Technocom`
        description = `Cordless Bluetooth Keyboard with English keys`
        width = `51.4` depth = `23` height = `4` dimunit = `cm` weightmeasure = `1` weightunit = `KG`
        quantity = `13` price = '29.00' currencycode = `EUR` )
      ( name = `Flat XXL` productid = `HT-1137` category = `Flat Screen Monitors` maincategory = `Computer Components` suppliername = `Technocom`
        description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`
        width = `54` depth = `22` height = `38` dimunit = `cm` weightmeasure = `18` weightunit = `KG`
        quantity = `10` price = '1430.00' currencycode = `EUR` )
      ( name = `Pocket Mouse` productid = `HT-1138` category = `Mice` maincategory = `Computer Components` suppliername = `Technocom`
        description = `Portable pocket Mouse with retracting cord`
        width = `0.3` depth = `0.5` height = `1` dimunit = `cm` weightmeasure = `0.02` weightunit = `KG`
        quantity = `20` price = '23.00' currencycode = `EUR` )
      ( name = `PC Power Station` productid = `HT-1210` category = `PCs` maincategory = `Computer Systems` suppliername = `Technocom`
        description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`
        width = `28` depth = `31` height = `43` dimunit = `cm` weightmeasure = `2.3` weightunit = `KG`
        quantity = `22` price = '2399.00' currencycode = `EUR` )
      ( name = `Astro Laptop 1516` productid = `HT-1251` category = `Laptops` maincategory = `Computer Systems` suppliername = `Ultrasonic United`
        description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`
        width = `30` depth = `18` height = `3` dimunit = `cm` weightmeasure = `4.2` weightunit = `KG`
        quantity = `23` price = '989.00' currencycode = `EUR` )
      ( name = `Astro Phone 6` productid = `HT-1252` category = `Smartphones and Tablets` maincategory = `Smartphones & Tablets` suppliername = `Ultrasonic United`
        description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`
        width = `8` depth = `6` height = `1.5` dimunit = `cm` weightmeasure = `0.75` weightunit = `KG`
        quantity = `28` price = '649.00' currencycode = `EUR` )
      ( name = `Benda Laptop 1408` productid = `HT-1253` category = `Laptops` maincategory = `Computer Systems` suppliername = `Ultrasonic United`
        description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`
        width = `30` depth = `18` height = `3` dimunit = `cm` weightmeasure = `4.2` weightunit = `KG`
        quantity = `27` price = '976.00' currencycode = `EUR` )
      ( name = `Bending Screen 21HD` productid = `HT-1254` category = `Flat Screens` maincategory = `Computer Components` suppliername = `Ultrasonic United`
        description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`
        width = `37` depth = `12` height = `36` dimunit = `cm` weightmeasure = `15` weightunit = `KG`
        quantity = `23` price = '250.00' currencycode = `EUR` )
      ( name = `Broad Screen 22HD` productid = `HT-1255` category = `Flat Screens` maincategory = `Computer Components` suppliername = `Ultrasonic United`
        description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`
        width = `39` depth = `12` height = `38` dimunit = `cm` weightmeasure = `16` weightunit = `KG`
        quantity = `5` price = '270.00' currencycode = `EUR` )
      ( name = `Cerdik Phone 7` productid = `HT-1256` category = `Smartphones and Tablets` maincategory = `Smartphones & Tablets` suppliername = `Ultrasonic United`
        description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`
        width = `9` depth = `15` height = `1.5` dimunit = `cm` weightmeasure = `0.75` weightunit = `KG`
        quantity = `19` price = '549.00' currencycode = `EUR` )
      ( name = `Cepat Tablet 10.5` productid = `HT-1257` category = `Smartphones and Tablets` maincategory = `Smartphones & Tablets` suppliername = `Ultrasonic United`
        description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`
        width = `48` depth = `31` height = `4.5` dimunit = `cm` weightmeasure = `2.8` weightunit = `KG`
        quantity = `17` price = '549.00' currencycode = `EUR` )
      ( name = `Cepat Tablet 8` productid = `HT-1258` category = `Smartphones and Tablets` maincategory = `Smartphones & Tablets` suppliername = `Ultrasonic United`
        description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`
        width = `38` depth = `21` height = `3.5` dimunit = `cm` weightmeasure = `2.5` weightunit = `KG`
        quantity = `24` price = '529.00' currencycode = `EUR` )
      ( name = `Server Basic` productid = `HT-1500` category = `Servers` maincategory = `Computer Systems` suppliername = `Technocom`
        description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`
        width = `34` depth = `35` height = `23` dimunit = `cm` weightmeasure = `18` weightunit = `KG`
        quantity = `24` price = '5000.00' currencycode = `EUR` )
      ( name = `Server Professional` productid = `HT-1501` category = `Servers` maincategory = `Computer Systems` suppliername = `Technocom`
        description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`
        width = `29` depth = `30` height = `27` dimunit = `cm` weightmeasure = `25` weightunit = `KG`
        quantity = `26` price = '15000.00' currencycode = `EUR` )
      ( name = `Server Power Pro` productid = `HT-1502` category = `Servers` maincategory = `Computer Systems` suppliername = `Technocom`
        description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`
        width = `22` depth = `27.3` height = `37` dimunit = `cm` weightmeasure = `35` weightunit = `KG`
        quantity = `34` price = '25000.00' currencycode = `EUR` )
      ( name = `Family PC Basic` productid = `HT-1600` category = `Desktop Computers` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`
        width = `21.4` depth = `29` height = `38` dimunit = `cm` weightmeasure = `4.8` weightunit = `KG`
        quantity = `10` price = '600.00' currencycode = `EUR` )
      ( name = `Family PC Pro` productid = `HT-1601` category = `Desktop Computers` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`
        width = `25` depth = `31.7` height = `40.2` dimunit = `cm` weightmeasure = `5.3` weightunit = `KG`
        quantity = `20` price = '900.00' currencycode = `EUR` )
      ( name = `Gaming Monster` productid = `HT-1602` category = `Desktop Computers` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`
        width = `26.5` depth = `34` height = `47` dimunit = `cm` weightmeasure = `5.9` weightunit = `KG`
        quantity = `24` price = '1200.00' currencycode = `EUR` )
      ( name = `Gaming Monster Pro` productid = `HT-1603` category = `Desktop Computers` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`
        width = `27` depth = `28` height = `42` dimunit = `cm` weightmeasure = `6.8` weightunit = `KG`
        quantity = `25` price = '1700.00' currencycode = `EUR` )
      ( name = `7" Widescreen Portable DVD Player w MP3` productid = `HT-2000` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Titanium`
        description = `7" LCD Screen, storage battery holds up to 6 hours!`
        width = `21.4` depth = `19` height = `27.6` dimunit = `cm` weightmeasure = `0.79` weightunit = `KG`
        quantity = `20` price = '249.99' currencycode = `EUR` )
      ( name = `10" Portable DVD player` productid = `HT-2001` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Titanium`
        description = `10" LCD Screen, storage battery holds up to 8 hours`
        width = `24` depth = `19.5` height = `29` dimunit = `cm` weightmeasure = `0.84` weightunit = `KG`
        quantity = `21` price = '449.99' currencycode = `EUR` )
      ( name = `Portable DVD Player with 9" LCD Monitor` productid = `HT-2002` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Technocom`
        description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`
        width = `21` depth = `16.5` height = `14` dimunit = `cm` weightmeasure = `0.72` weightunit = `KG`
        quantity = `50` price = '853.99' currencycode = `EUR` )
      ( name = `CD/DVD case: 264 sleeves` productid = `HT-2025` category = `Accessories` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Organizer and protective case for 264 CDs and DVDs`
        width = `13` depth = `13` height = `20` dimunit = `cm` weightmeasure = `0.65` weightunit = `KG`
        quantity = `26` price = '44.99' currencycode = `EUR` )
      ( name = `Audio/Video Cable Kit - 4m` productid = `HT-2026` category = `Accessories` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Quality cables for notebooks and projectors`
        width = `21` depth = `10.2` height = `13` dimunit = `cm` weightmeasure = `0.2` weightunit = `KG`
        quantity = `16` price = '29.99' currencycode = `EUR` )
      ( name = `Removable CD/DVD Laser Labels` productid = `HT-2027` category = `Accessories` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Removable jewel case labels, zero residues (100)`
        width = `5.5` depth = `2` height = `2` dimunit = `cm` weightmeasure = `0.15` weightunit = `KG`
        quantity = `25` price = '8.99' currencycode = `EUR` )
      ( name = `Beam Breaker B-1` productid = `HT-6100` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Titanium`
        description = `720p, DLP Projector max. 8,45 Meter, 2D`
        width = `30.4` depth = `23.1` height = `23` dimunit = `cm` weightmeasure = `1.7` weightunit = `KG`
        quantity = `32` price = '469.00' currencycode = `EUR` )
      ( name = `Beam Breaker B-2` productid = `HT-6101` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Technocom`
        description = `1080p, DLP max.9,34 Meter, 2D-ready`
        width = `30.4` depth = `23.1` height = `23` dimunit = `cm` weightmeasure = `2` weightunit = `KG`
        quantity = `18` price = '679.00' currencycode = `EUR` )
      ( name = `Beam Breaker B-3` productid = `HT-6102` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Technocom`
        description = `1080p, DLP max. 12,3 Meter, 3D-ready`
        width = `30.4` depth = `23.1` height = `23` dimunit = `cm` weightmeasure = `2.5` weightunit = `KG`
        quantity = `16` price = '889.00' currencycode = `EUR` )
      ( name = `Play Movie` productid = `HT-6110` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Fasttech`
        description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`
        width = `37` depth = `24` height = `6` dimunit = `cm` weightmeasure = `2.4` weightunit = `KG`
        quantity = `15` price = '130.00' currencycode = `EUR` )
      ( name = `Record Movie` productid = `HT-6111` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Fasttech`
        description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`
        width = `38` depth = `26` height = `6.2` dimunit = `cm` weightmeasure = `3.1` weightunit = `KG`
        quantity = `24` price = '288.00' currencycode = `EUR` )
      ( name = `ITelo MusicStick` productid = `HT-6120` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Fasttech`
        description = `64 GB USB Music-on-Available-Stick`
        width = `1.5` depth = `6` height = `1` dimunit = `cm` weightmeasure = `134` weightunit = `G`
        quantity = `15` price = '45.00' currencycode = `EUR` )
      ( name = `ITelo Jog-Mate` productid = `HT-6121` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Fasttech`
        description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`
        width = `5.1` depth = `8` height = `9.2` dimunit = `cm` weightmeasure = `134` weightunit = `G`
        quantity = `24` price = '63.00' currencycode = `EUR` )
      ( name = `Power Pro Player 40` productid = `HT-6122` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Fasttech`
        description = `MP3-Player with 40 GB HDD and Color Display, can play movies`
        width = `5.1` depth = `8` height = `9.2` dimunit = `cm` weightmeasure = `266` weightunit = `G`
        quantity = `23` price = '167.00' currencycode = `EUR` )
      ( name = `Power Pro Player 80` productid = `HT-6123` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Fasttech`
        description = `MP3-Player with 80 GB SSD and Color Display, can play movies`
        width = `4` depth = `6` height = `0.8` dimunit = `cm` weightmeasure = `267` weightunit = `G`
        quantity = `13` price = '299.00' currencycode = `EUR` )
      ( name = `Flat Watch HD32` productid = `HT-6130` category = `Flat Screen TVs` maincategory = `TV, Video & HiFi` suppliername = `Very Best Screens`
        description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`
        width = `78` depth = `22.1` height = `55` dimunit = `cm` weightmeasure = `2.6` weightunit = `KG`
        quantity = `16` price = '1459.00' currencycode = `EUR` )
      ( name = `Flat Watch HD37` productid = `HT-6131` category = `Flat Screen TVs` maincategory = `TV, Video & HiFi` suppliername = `Very Best Screens`
        description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`
        width = `99.1` depth = `26` height = `61` dimunit = `cm` weightmeasure = `2.2` weightunit = `KG`
        quantity = `14` price = '1199.00' currencycode = `EUR` )
      ( name = `Flat Watch HD41` productid = `HT-6132` category = `Flat Screen TVs` maincategory = `TV, Video & HiFi` suppliername = `Very Best Screens`
        description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`
        width = `128` depth = `23` height = `79.1` dimunit = `cm` weightmeasure = `1.8` weightunit = `KG`
        quantity = `13` price = '899.00' currencycode = `EUR` )
      ( name = `Copperberry` productid = `HT-7000` category = `Accessories` maincategory = `Computer Components` suppliername = `Fasttech`
        description = `Our new multifunctional Handheld with phone function in copper`
        width = `8.1` depth = `13` height = `12.1` dimunit = `cm` weightmeasure = `0.5` weightunit = `KG`
        quantity = `5` price = '549.00' currencycode = `EUR` )
      ( name = `Silverberry` productid = `HT-7010` category = `Accessories` maincategory = `Computer Components` suppliername = `Fasttech`
        description = `Our new multifunctional Handheld with phone function in silver`
        width = `8.1` depth = `13` height = `12.1` dimunit = `cm` weightmeasure = `0.5` weightunit = `KG`
        quantity = `9` price = '549.00' currencycode = `EUR` )
      ( name = `Goldberry` productid = `HT-7020` category = `Accessories` maincategory = `Computer Components` suppliername = `Fasttech`
        description = `Our new multifunctional Handheld with phone function in gold`
        width = `8.1` depth = `13` height = `12.1` dimunit = `cm` weightmeasure = `0.5` weightunit = `KG`
        quantity = `11` price = '549.00' currencycode = `EUR` )
      ( name = `Platinberry` productid = `HT-7030` category = `Accessories` maincategory = `Computer Components` suppliername = `Fasttech`
        description = `Our new multifunctional Handheld with phone function in platinum`
        width = `8.1` depth = `13` height = `12.1` dimunit = `cm` weightmeasure = `0.5` weightunit = `KG`
        quantity = `12` price = '549.00' currencycode = `EUR` )
      ( name = `ITelO FlexTop I4000` productid = `HT-8000` category = `Laptops` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`
        width = `31` depth = `19` height = `3.1` dimunit = `cm` weightmeasure = `4` weightunit = `KG`
        quantity = `11` price = '799.00' currencycode = `EUR` )
      ( name = `ITelO FlexTop I6300c` productid = `HT-8001` category = `Laptops` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`
        width = `32` depth = `20` height = `3.4` dimunit = `cm` weightmeasure = `4.2` weightunit = `KG`
        quantity = `20` price = '799.00' currencycode = `EUR` )
      ( name = `ITelO FlexTop I9100` productid = `HT-8002` category = `Laptops` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`
        width = `38` depth = `21` height = `4.1` dimunit = `cm` weightmeasure = `3.5` weightunit = `KG`
        quantity = `20` price = '1199.00' currencycode = `EUR` )
      ( name = `ITelO FlexTop I9800` productid = `HT-8003` category = `Laptops` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`
        width = `48` depth = `31` height = `4.5` dimunit = `cm` weightmeasure = `3.8` weightunit = `KG`
        quantity = `22` price = '1388.00' currencycode = `EUR` )
      ( name = `Smartphone Leather Case` productid = `HT-9991` category = `Accessories` maincategory = `Smartphones & Tablets` suppliername = `Ultrasonic United`
        description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`
        width = `48` depth = `31` height = `4.5` dimunit = `cm` weightmeasure = `0.02` weightunit = `KG`
        quantity = `12` price = '25.00' currencycode = `EUR` )
      ( name = `Smartphone Alpha` productid = `HT-9992` category = `Smartphones and Tablets` maincategory = `Smartphones & Tablets` suppliername = `Ultrasonic United`
        description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`
        width = `48` depth = `31` height = `4.5` dimunit = `cm` weightmeasure = `0.75` weightunit = `KG`
        quantity = `13` price = '599.00' currencycode = `EUR` )
      ( name = `Mini Tablet` productid = `HT-9993` category = `Smartphones and Tablets` maincategory = `Smartphones & Tablets` suppliername = `Ultrasonic United`
        description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`
        width = `48` depth = `31` height = `4.5` dimunit = `cm` weightmeasure = `3.8` weightunit = `KG`
        quantity = `10` price = '833.00' currencycode = `EUR` )
      ( name = `Camcorder View` productid = `HT-9994` category = `Accessories` maincategory = `TV, Video & HiFi` suppliername = `Ultrasonic United`
        description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`
        width = `48` depth = `31` height = `27` dimunit = `cm` weightmeasure = `3.8` weightunit = `KG`
        quantity = `50` price = '1388.00' currencycode = `EUR` )
      ( name = `Tablet Pouch` productid = `HT-9995` category = `Accessories` maincategory = `Smartphones & Tablets` suppliername = `Titanium`
        description = `Stylish tablet pouch, protects from scratches, color: black`
        width = `25` depth = `40` height = `4.5` dimunit = `cm` weightmeasure = `0.03` weightunit = `KG`
        quantity = `34` price = '20.00' currencycode = `EUR` )
      ( name = `Tablet Pouch` productid = `HT-9996` category = `Accessories` maincategory = `Smartphones & Tablets` suppliername = `Titanium`
        description = `Stylish tablet pouch, protects from scratches, color: black`
        width = `25` depth = `40` height = `4.5` dimunit = `cm` weightmeasure = `0.03` weightunit = `KG`
        quantity = `34` price = '20.00' currencycode = `EUR` )
      ( name = `e-Book Reader ReadMe` productid = `HT-9997` category = `Smartphones and Tablets` maincategory = `Smartphones & Tablets` suppliername = `Titanium`
        description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`
        width = `48` depth = `31` height = `4.5` dimunit = `cm` weightmeasure = `3.8` weightunit = `KG`
        quantity = `23` price = '33.00' currencycode = `EUR` )
      ( name = `Smartphone Beta` productid = `HT-9998` category = `Smartphones and Tablets` maincategory = `Smartphones & Tablets` suppliername = `Titanium`
        description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`
        width = `48` depth = `31` height = `4.5` dimunit = `cm` weightmeasure = `0.75` weightunit = `KG`
        quantity = `21` price = '30.00' currencycode = `EUR` )
      ( name = `Maxi Tablet` productid = `HT-9999` category = `Tablets` maincategory = `Smartphones & Tablets` suppliername = `Titanium`
        description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`
        width = `48` depth = `31` height = `4.5` dimunit = `cm` weightmeasure = `3.8` weightunit = `KG`
        quantity = `20` price = '749.00' currencycode = `EUR` )
      ( name = `Flyer` productid = `PF-1000` category = `Accessories` maincategory = `Computer Systems` suppliername = `Titanium`
        description = `Flyer for our product palette`
        width = `46` depth = `30` height = `3` dimunit = `cm` weightmeasure = `0.01` weightunit = `KG`
        quantity = `33` price = '0.00' currencycode = `EUR` ) ).

    " ProductPicUrl is derivable from the product id (the mock's
    " test-resources/.../<id>.jpg), built from a shared base pointing at the
    " OpenUI5 host (like app 006's image flattening)
    LOOP AT t_products REFERENCE INTO DATA(product).
      product->productpicurl = |{ c_img_base }{ product->productid }.jpg|.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
