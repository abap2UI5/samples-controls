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
    TYPES temp1_a3713cf5ce TYPE STANDARD TABLE OF ty_s_product WITH DEFAULT KEY.
DATA t_products TYPE temp1_a3713cf5ce.
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
    TYPES ty_t_event_item TYPE STANDARD TABLE OF ty_s_event_item WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    CONSTANTS c_img_base TYPE string VALUE `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/`.

    METHODS view_display.
    METHODS on_event.
    METHODS event_items
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_event_item.
    METHODS json_objects
      IMPORTING
        json          TYPE string
      RETURNING
        VALUE(result) TYPE string_table.
    METHODS json_get_value
      IMPORTING
        json          TYPE string
        name          TYPE string
      RETURNING
        VALUE(result) TYPE string.
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

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    DATA temp2 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `mySelectDialog` INTO TABLE temp1.
    INSERT `items` INTO TABLE temp1.
    INSERT `filter` INTO TABLE temp1.
    INSERT `NAME` INTO TABLE temp1.
    INSERT `Contains` INTO TABLE temp1.
    INSERT `${$parameters>/value}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `valueHelpDialog` INTO TABLE temp2.
    INSERT `items` INTO TABLE temp2.
    INSERT `filter` INTO TABLE temp2.
    INSERT `NAME` INTO TABLE temp2.
    INSERT `Contains` INTO TABLE temp2.
    INSERT `${$parameters>/value}` INTO TABLE temp2.
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
                                                                             t_arg = temp1 )
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
                                                                            t_arg = temp2 )
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
        DATA temp3 LIKE LINE OF t_products.
        DATA lr LIKE REF TO temp3.
          DATA temp1 TYPE xsdboolean.
        DATA temp4 TYPE string_table.
        DATA sel_items TYPE z2ui5_cl_smpc_app_103=>ty_t_event_item.
          DATA sel_names TYPE string.
          DATA temp6 LIKE LINE OF sel_items.
          DATA sel LIKE REF TO temp6.
            DATA temp7 TYPE string.
        DATA temp8 TYPE string_table.

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
        
        
        LOOP AT t_products REFERENCE INTO lr.
          
          temp1 = boolc( lr->name = product_value ).
          lr->selected = temp1.
        ENDLOOP.
        
        CLEAR temp4.
        INSERT `valueHelpDialog` INTO TABLE temp4.
        INSERT `open` INTO TABLE temp4.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp4 ).

      WHEN `CONFIRM`.
        " onDialogClose: name every chosen product, or say that none was
        " picked. The original reads selectedContexts and maps getObject().Name;
        " a Context is not a control, so the wire carries the selectedItems
        " ARRAY instead - the frontend projects each StandardListItem to its
        " public properties, and title is the bound Name. Cancel fires the same
        " handler with no selection, which is the original's else branch
        
        sel_items = event_items( client->get_event_arg( ) ).
        IF sel_items IS INITIAL.
          client->message_toast_display( `No new item was selected.` ).
        ELSE.
          
          sel_names = ``.
          
          
          LOOP AT sel_items REFERENCE INTO sel.
            
            IF sel_names IS INITIAL.
              temp7 = sel->title.
            ELSE.
              temp7 = |{ sel_names }, { sel->title }|.
            ENDIF.
            sel_names = temp7.
          ENDLOOP.
          client->message_toast_display( |You have chosen { sel_names }| ).
        ENDIF.
        " ... and the last line of onDialogClose:
        " oEvent.getSource( ).getBinding( 'items' ).filter( [] ) - so the
        " search a user typed is gone the next time the dialog opens. A
        " binding_call filter with no values is exactly that clear (the
        " client leaves the filter empty when value1 and value2 both are)
        
        CLEAR temp8.
        INSERT `mySelectDialog` INTO TABLE temp8.
        INSERT `items` INTO TABLE temp8.
        INSERT `filter` INTO TABLE temp8.
        client->follow_up_action( val   = client->cs_event-binding_call
                                  t_arg = temp8 ).

      WHEN `VH_CLOSE`.
        " onValueHelpDialogClose: the picked title lands in the input, and a
        " close with no selection resets it (the original's resetProperty)
        product_value = client->get_event_arg( ).

    ENDCASE.

  ENDMETHOD.


  METHOD event_items.

    DATA json TYPE string.
    DATA temp10 TYPE string_table.
    DATA object LIKE LINE OF temp10.
      DATA temp11 TYPE z2ui5_cl_smpc_app_103=>ty_s_event_item.
    json = condense( val ).
    IF json IS INITIAL.
      RETURN.
    ENDIF.

    " The frontend marshals each control into an object of its ID plus ALL
    " its public properties, so this reads the fields the port models and
    " ignores the rest - which is what the corresponding-only mapping used
    " to do. Written by hand: there is no released JSON parser, and the
    " vendored ajson copy is framework-internal.
    
    temp10 = json_objects( json ).
    
    LOOP AT temp10 INTO object.
      
      CLEAR temp11.
      temp11-id = json_get_value( json = object name = `id` ).
      temp11-title = json_get_value( json = object name = `title` ).
      INSERT temp11 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


  METHOD open_dialog.
      DATA temp12 TYPE string_table.
      DATA temp14 TYPE string_table.
    DATA temp16 TYPE string_table.

    multi_select      = multi.
    remember          = rem.
    growing           = grow.
    growing_threshold = threshold.
    show_clear        = clear.
    confirm_text      = confirmtext.
    draggable         = drag.
    resizable         = resize.

    IF responsive = abap_true.
      
      CLEAR temp12.
      INSERT `mySelectDialog` INTO TABLE temp12.
      INSERT `addStyleClass` INTO TABLE temp12.
      INSERT `sapUiResponsivePadding--header sapUiResponsivePadding--subHeader sapUiResponsivePadding--content sapUiResponsivePadding--footer` INTO TABLE temp12.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = temp12 ).
    ELSE.
      
      CLEAR temp14.
      INSERT `mySelectDialog` INTO TABLE temp14.
      INSERT `removeStyleClass` INTO TABLE temp14.
      INSERT `sapUiResponsivePadding--header sapUiResponsivePadding--subHeader sapUiResponsivePadding--content sapUiResponsivePadding--footer` INTO TABLE temp14.
      client->follow_up_action( val   = client->cs_event-control_by_id
                                t_arg = temp14 ).
    ENDIF.

    
    CLEAR temp16.
    INSERT `mySelectDialog` INTO TABLE temp16.
    INSERT `open` INTO TABLE temp16.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp16 ).

  ENDMETHOD.


  METHOD json_objects.

    " Cut the array into its objects. abap2UI5 releases no JSON parser and
    " the vendored ajson copy is framework-internal (the linter's
    " non-released-api rule reports it, correctly), so the split is one
    " character walk - and it is a walk rather than a SPLIT on `},{` because
    " a brace inside a STRING is text, not structure.
    DATA depth TYPE i.
    DATA in_string LIKE abap_false.
    DATA escaped LIKE abap_false.
    DATA start TYPE i.
    DATA pos TYPE i.
    DATA length TYPE i.
      DATA char TYPE string.
        DATA temp2 TYPE xsdboolean.
    depth     = 0.
    
    in_string = abap_false.
    
    escaped = abap_false.
    
    start     = 0.
    
    pos       = 0.
    
    length    = strlen( json ).

    WHILE pos < length.
      
      char = substring( val = json off = pos len = 1 ).

      IF escaped = abap_true.
        escaped = abap_false.
      ELSEIF in_string = abap_true AND char = `\`.
        escaped = abap_true.
      ELSEIF char = `"`.
        
        temp2 = boolc( in_string = abap_false ).
        in_string = temp2.
      ELSEIF in_string = abap_false AND char = `{`.
        IF depth = 0.
          start = pos.
        ENDIF.
        depth = depth + 1.
      ELSEIF in_string = abap_false AND char = `}`.
        depth = depth - 1.
        IF depth = 0.
          INSERT substring( val = json off = start len = pos - start + 1 ) INTO TABLE result.
        ENDIF.
      ENDIF.

      pos = pos + 1.
    ENDWHILE.

  ENDMETHOD.


  METHOD json_get_value.

    " One string field of ONE object: find `"<name>":"` and take what stands
    " up to the next quote. The search is case-insensitive because the key is
    " the UI5 property name (camelCase) and this reads it in lower case.
    " Same reader as Z2UI5_CL_SMP_APP_327 in abap2UI5/samples, and the same
    " limit: it reads what the FRAMEWORK wrote and does not resolve escapes,
    " which a payload composed from free user input would need.
    DATA marker TYPE string.
    DATA offset TYPE i.
    marker = |"{ name }":"|.

    
    offset = find( val = json sub = marker case = abap_false ).
    IF offset < 0.
      RETURN.
    ENDIF.

    result = substring_before( val = substring( val = json
                                                off = offset + strlen( marker ) )
                               sub = `"` ).

  ENDMETHOD.


  METHOD model_init.
    DATA temp18 LIKE t_products.
    DATA temp19 LIKE LINE OF temp18.
    DATA temp20 LIKE LINE OF t_products.
    DATA product LIKE REF TO temp20.

    " the original's view seeds the input with this product
    product_value = `Astro Phone 6`.

    
    CLEAR temp18.
    
    temp19-name = `Notebook Basic 15`.
    temp19-productid = `HT-1000`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Notebook Basic 15 with 2,80 GHz quad core, 15" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp19-width = `30`.
    temp19-depth = `18`.
    temp19-height = `3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `10`.
    temp19-price = '956.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Notebook Basic 17`.
    temp19-productid = `HT-1001`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Notebook Basic 17 with 2,80 GHz quad core, 17" LCD, 4 GB DDR3 RAM, 500 GB Hard Disc, Windows 8 Pro`.
    temp19-width = `29`.
    temp19-depth = `17`.
    temp19-height = `3.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '1249.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Notebook Basic 18`.
    temp19-productid = `HT-1002`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Notebook Basic 18 with 2,80 GHz quad core, 18" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp19-width = `28`.
    temp19-depth = `19`.
    temp19-height = `2.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `10`.
    temp19-price = '1570.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Notebook Basic 19`.
    temp19-productid = `HT-1003`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Smartcards`.
    temp19-description = `Notebook Basic 19 with 2,80 GHz quad core, 19" LCD, 8 GB DDR3 RAM, 1000 GB Hard Disc, Windows 8 Pro`.
    temp19-width = `32`.
    temp19-depth = `21`.
    temp19-height = `4`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `15`.
    temp19-price = '1650.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelO Vault`.
    temp19-productid = `HT-1007`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Digital Organizer with State-of-the-Art Storage Encryption`.
    temp19-width = `32`.
    temp19-depth = `22`.
    temp19-height = `3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `15`.
    temp19-price = '299.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Notebook Professional 15`.
    temp19-productid = `HT-1010`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Notebook Professional 15 with 2,80 GHz quad core, 15" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp19-width = `33`.
    temp19-depth = `20`.
    temp19-height = `3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `16`.
    temp19-price = '1999.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Notebook Professional 17`.
    temp19-productid = `HT-1011`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Notebook Professional 17 with 2,80 GHz quad core, 17" Multitouch LCD, 8 GB DDR3 RAM, 500 GB SSD - DVD-Writer (DVD-R/+R/-RW/-RAM),Windows 8 Pro`.
    temp19-width = `33`.
    temp19-depth = `23`.
    temp19-height = `2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.1`.
    temp19-weightunit = `KG`.
    temp19-quantity = `17`.
    temp19-price = '2299.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelO Vault Net`.
    temp19-productid = `HT-1020`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Network Communications`.
    temp19-width = `10`.
    temp19-depth = `1.8`.
    temp19-height = `17`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.16`.
    temp19-weightunit = `KG`.
    temp19-quantity = `14`.
    temp19-price = '459.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelO Vault SAT`.
    temp19-productid = `HT-1021`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Digital Organizer with State-of-the-Art Encryption for Storage and Secure Stellite Link`.
    temp19-width = `11`.
    temp19-depth = `1.7`.
    temp19-height = `18`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.18`.
    temp19-weightunit = `KG`.
    temp19-quantity = `50`.
    temp19-price = '149.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Comfort Easy`.
    temp19-productid = `HT-1022`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `32 GB Digital Assistant with high-resolution color screen`.
    temp19-width = `84`.
    temp19-depth = `1.5`.
    temp19-height = `14`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `30`.
    temp19-price = '1679.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Comfort Senior`.
    temp19-productid = `HT-1023`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `64 GB Digital Assistant with high-resolution color screen and synthesized voice output`.
    temp19-width = `80`.
    temp19-depth = `1.6`.
    temp19-height = `13`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `24`.
    temp19-price = '512.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Ergo Screen E-I`.
    temp19-productid = `HT-1030`.
    temp19-category = `Flat Screen Monitors`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Optimum Hi-Resolution max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm`.
    temp19-width = `37`.
    temp19-depth = `12`.
    temp19-height = `36`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `21`.
    temp19-weightunit = `KG`.
    temp19-quantity = `14`.
    temp19-price = '230.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Ergo Screen E-II`.
    temp19-productid = `HT-1031`.
    temp19-category = `Flat Screen Monitors`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Optimum Hi-Resolution max. 1920 x 1200 @ 85Hz, Dot Pitch: 0.26mm`.
    temp19-width = `40.8`.
    temp19-depth = `19`.
    temp19-height = `43`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `21`.
    temp19-weightunit = `KG`.
    temp19-quantity = `24`.
    temp19-price = '285.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Ergo Screen E-III`.
    temp19-productid = `HT-1032`.
    temp19-category = `Flat Screen Monitors`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Optimum Hi-Resolution max. 2560 x 1440 @ 85Hz, Dot Pitch: 0.25mm`.
    temp19-width = `40.8`.
    temp19-depth = `19`.
    temp19-height = `43`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `21`.
    temp19-weightunit = `KG`.
    temp19-quantity = `50`.
    temp19-price = '345.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Flat Basic`.
    temp19-productid = `HT-1035`.
    temp19-category = `Flat Screen Monitors`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Optimum Hi-Resolution max. 1600 x 1200 @ 85Hz, Dot Pitch: 0.24mm`.
    temp19-width = `39`.
    temp19-depth = `20`.
    temp19-height = `41`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `14`.
    temp19-weightunit = `KG`.
    temp19-quantity = `23`.
    temp19-price = '399.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Flat Future`.
    temp19-productid = `HT-1036`.
    temp19-category = `Flat Screen Monitors`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Optimum Hi-Resolution max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.26mm`.
    temp19-width = `45`.
    temp19-depth = `26`.
    temp19-height = `46`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `15`.
    temp19-weightunit = `KG`.
    temp19-quantity = `22`.
    temp19-price = '430.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Flat XL`.
    temp19-productid = `HT-1037`.
    temp19-category = `Flat Screen Monitors`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `Optimum Hi-Resolution max. 2016 x 1512 @ 85Hz, Dot Pitch: 0.24mm`.
    temp19-width = `54.5`.
    temp19-depth = `22.1`.
    temp19-height = `39.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `17`.
    temp19-weightunit = `KG`.
    temp19-quantity = `23`.
    temp19-price = '1230.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Laser Professional Eco`.
    temp19-productid = `HT-1040`.
    temp19-category = `Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Alpha Printers`.
    temp19-description = `Print 2400 dpi image quality color documents at speeds of up to 32 ppm (color) or 36 ppm (monochrome), letter/A4. Powerful 500 MHz processor, 512MB of memory`.
    temp19-width = `51`.
    temp19-depth = `46`.
    temp19-height = `30`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `32`.
    temp19-weightunit = `KG`.
    temp19-quantity = `21`.
    temp19-price = '830.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Laser Basic`.
    temp19-productid = `HT-1041`.
    temp19-category = `Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Alpha Printers`.
    temp19-description = `Up to 22 ppm color or 24 ppm monochrome A4/letter, powerful 500 MHz processor and 128MB of memory`.
    temp19-width = `48`.
    temp19-depth = `42`.
    temp19-height = `26`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `23`.
    temp19-weightunit = `KG`.
    temp19-quantity = `8`.
    temp19-price = '490.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Laser Allround`.
    temp19-productid = `HT-1042`.
    temp19-category = `Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Alpha Printers`.
    temp19-description = `Print up to 25 ppm letter and 24 ppm A4 color or monochrome, with Available first-page-out-time of less than 13 seconds for monochrome and less than 15 seconds for color`.
    temp19-width = `53`.
    temp19-depth = `50`.
    temp19-height = `65`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `17`.
    temp19-weightunit = `KG`.
    temp19-quantity = `9`.
    temp19-price = '349.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Ultra Jet Super Color`.
    temp19-productid = `HT-1050`.
    temp19-category = `Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Alpha Printers`.
    temp19-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB, Ethernet`.
    temp19-width = `41`.
    temp19-depth = `41`.
    temp19-height = `28`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `17`.
    temp19-price = '139.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Ultra Jet Mobile`.
    temp19-productid = `HT-1051`.
    temp19-category = `Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Printer for All`.
    temp19-description = `1000 dpi x 1000 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB - excellent dimensions for the small office`.
    temp19-width = `46`.
    temp19-depth = `32`.
    temp19-height = `25`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1.9`.
    temp19-weightunit = `KG`.
    temp19-quantity = `18`.
    temp19-price = '99.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Ultra Jet Super Highspeed`.
    temp19-productid = `HT-1052`.
    temp19-category = `Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Printer for All`.
    temp19-description = `4800 dpi x 1200 dpi - up to 35 ppm (mono) / up to 34 ppm (color) - capacity: 250 sheets - Hi-Speed USB2.0, Ethernet`.
    temp19-width = `41`.
    temp19-depth = `41`.
    temp19-height = `28`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `18`.
    temp19-weightunit = `KG`.
    temp19-quantity = `25`.
    temp19-price = '170.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Multi Print`.
    temp19-productid = `HT-1055`.
    temp19-category = `Multifunction Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Printer for All`.
    temp19-description = `1000 dpi x 1000 dpi - up to 16 ppm (mono) / up to 15 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 1200dpi x 2400dpi)`.
    temp19-width = `55`.
    temp19-depth = `45`.
    temp19-height = `29`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `6.3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `16`.
    temp19-price = '99.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Multi Color`.
    temp19-productid = `HT-1056`.
    temp19-category = `Multifunction Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Printer for All`.
    temp19-description = `1200 dpi x 1200 dpi - up to 25 ppm (mono) / up to 24 ppm (color)- capacity 80 sheets - scanner (216 x 297 mm, 2400dpi x 4800dpi, high resolution)`.
    temp19-width = `51`.
    temp19-depth = `41.3`.
    temp19-height = `22`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `5`.
    temp19-price = '119.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Cordless Mouse`.
    temp19-productid = `HT-1060`.
    temp19-category = `Mice`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Oxynum`.
    temp19-description = `Cordless Optical USB Mice, Laptop, Color: Black, Plug&Play`.
    temp19-width = `6`.
    temp19-depth = `14.5`.
    temp19-height = `3.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.09`.
    temp19-weightunit = `KG`.
    temp19-quantity = `25`.
    temp19-price = '9.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Speed Mouse`.
    temp19-productid = `HT-1061`.
    temp19-category = `Mice`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Oxynum`.
    temp19-description = `Optical USB, PS/2 Mouse, Color: Blue, 3-button-functionality (incl. Scroll wheel)`.
    temp19-width = `7`.
    temp19-depth = `15`.
    temp19-height = `3.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.09`.
    temp19-weightunit = `KG`.
    temp19-quantity = `12`.
    temp19-price = '7.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Track Mouse`.
    temp19-productid = `HT-1062`.
    temp19-category = `Mice`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Oxynum`.
    temp19-description = `Optical USB Mouse, Color: Red, 5-button-functionality(incl. Scroll wheel), Plug&Play`.
    temp19-width = `3`.
    temp19-depth = `7`.
    temp19-height = `4`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.03`.
    temp19-weightunit = `KG`.
    temp19-quantity = `12`.
    temp19-price = '11.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Ergonomic Keyboard`.
    temp19-productid = `HT-1063`.
    temp19-category = `Keyboards`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Oxynum`.
    temp19-description = `Ergonomic USB Keyboard for Desktop, Plug&Play`.
    temp19-width = `50`.
    temp19-depth = `21`.
    temp19-height = `3.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.1`.
    temp19-weightunit = `KG`.
    temp19-quantity = `50`.
    temp19-price = '14.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Internet Keyboard`.
    temp19-productid = `HT-1064`.
    temp19-category = `Keyboards`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Oxynum`.
    temp19-description = `Corded Keyboard with special keys for Internet Usability, USB`.
    temp19-width = `52`.
    temp19-depth = `25`.
    temp19-height = `3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `35`.
    temp19-price = '16.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Media Keyboard`.
    temp19-productid = `HT-1065`.
    temp19-category = `Keyboards`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Oxynum`.
    temp19-description = `Corded Ergonomic Keyboard with special keys for Media Usability, USB`.
    temp19-width = `51.4`.
    temp19-depth = `23`.
    temp19-height = `4`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `26`.
    temp19-price = '26.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Mousepad`.
    temp19-productid = `HT-1066`.
    temp19-category = `Mousepads`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Oxynum`.
    temp19-description = `Nice mouse pad with ITelO Logo`.
    temp19-width = `15`.
    temp19-depth = `6`.
    temp19-height = `0.2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `80`.
    temp19-weightunit = `G`.
    temp19-quantity = `12`.
    temp19-price = '6.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Ergo Mousepad`.
    temp19-productid = `HT-1067`.
    temp19-category = `Mousepads`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Oxynum`.
    temp19-description = `Ergonomic mouse pad with ITelO Logo`.
    temp19-width = `15`.
    temp19-depth = `6`.
    temp19-height = `0.2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `80`.
    temp19-weightunit = `G`.
    temp19-quantity = `16`.
    temp19-price = '8.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Designer Mousepad`.
    temp19-productid = `HT-1068`.
    temp19-category = `Mousepads`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `ITelO Mousepad Special Edition`.
    temp19-width = `24`.
    temp19-depth = `24`.
    temp19-height = `0.6`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `90`.
    temp19-weightunit = `G`.
    temp19-quantity = `26`.
    temp19-price = '12.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Universal card reader`.
    temp19-productid = `HT-1069`.
    temp19-category = `Computer System Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `Universal card reader`.
    temp19-width = `6`.
    temp19-depth = `6`.
    temp19-height = `3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `45`.
    temp19-weightunit = `G`.
    temp19-quantity = `22`.
    temp19-price = '14.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Proctra X`.
    temp19-productid = `HT-1070`.
    temp19-category = `Graphic Cards`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `Proctra X: PCI-E GDDR5 3072MB`.
    temp19-width = `22`.
    temp19-depth = `35`.
    temp19-height = `17`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.255`.
    temp19-weightunit = `KG`.
    temp19-quantity = `15`.
    temp19-price = '70.90'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Gladiator MX`.
    temp19-productid = `HT-1071`.
    temp19-category = `Graphic Cards`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `Gladiator XLN: PCI-E GDDR5 3072MB DVI Out, TV Out low-noise`.
    temp19-width = `22`.
    temp19-depth = `35`.
    temp19-height = `17`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `16`.
    temp19-price = '81.70'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Hurricane GX`.
    temp19-productid = `HT-1072`.
    temp19-category = `Graphic Cards`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `Hurricane GX: PCI-E 691 GFLOPS game-optimized`.
    temp19-width = `22`.
    temp19-depth = `35`.
    temp19-height = `17`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.4`.
    temp19-weightunit = `KG`.
    temp19-quantity = `13`.
    temp19-price = '101.20'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Hurricane GX/LN`.
    temp19-productid = `HT-1073`.
    temp19-category = `Graphic Cards`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Smartcards`.
    temp19-description = `Hurricane GX/LN: PCI-E 691 GFLOPS game-optimized, low-noise.`.
    temp19-width = `22`.
    temp19-depth = `35`.
    temp19-height = `17`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.4`.
    temp19-weightunit = `KG`.
    temp19-quantity = `5`.
    temp19-price = '139.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Photo Scan`.
    temp19-productid = `HT-1080`.
    temp19-category = `Scanners`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Printer for All`.
    temp19-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - Hi-Speed USB - Bluetooth`.
    temp19-width = `34`.
    temp19-depth = `48`.
    temp19-height = `5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `8`.
    temp19-price = '129.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Power Scan`.
    temp19-productid = `HT-1081`.
    temp19-category = `Scanners`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Printer for All`.
    temp19-description = `Flatbed scanner - 9.600 × 9.600 dpi - 216 x 297 mm - SCSI for backward compatibility`.
    temp19-width = `31`.
    temp19-depth = `43`.
    temp19-height = `7`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.4`.
    temp19-weightunit = `KG`.
    temp19-quantity = `11`.
    temp19-price = '89.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Jet Scan Professional`.
    temp19-productid = `HT-1082`.
    temp19-category = `Scanners`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Printer for All`.
    temp19-description = `Flatbed scanner - Letter - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp19-width = `33`.
    temp19-depth = `41`.
    temp19-height = `12`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `13`.
    temp19-price = '169.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Jet Scan Professional`.
    temp19-productid = `HT-1083`.
    temp19-category = `Scanners`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Printer for All`.
    temp19-description = `Flatbed scanner - A4 - 2400 dpi x 2400 dpi - 216 x 297 mm - add-on module`.
    temp19-width = `35`.
    temp19-depth = `40`.
    temp19-height = `10`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `10`.
    temp19-price = '189.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Copymaster`.
    temp19-productid = `HT-1085`.
    temp19-category = `Multifunction Printers`.
    temp19-maincategory = `Printers & Scanners`.
    temp19-suppliername = `Alpha Printers`.
    temp19-description = `Copymaster`.
    temp19-width = `45`.
    temp19-depth = `42`.
    temp19-height = `22`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `23.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `10`.
    temp19-price = '1499.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Surround Sound`.
    temp19-productid = `HT-1090`.
    temp19-category = `Speakers`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Speaker Experts`.
    temp19-description = `PC multimedia speakers - 5 Watt (Total)`.
    temp19-width = `12`.
    temp19-depth = `10`.
    temp19-height = `16`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '39.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Blaster Extreme`.
    temp19-productid = `HT-1091`.
    temp19-category = `Speakers`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Speaker Experts`.
    temp19-description = `PC multimedia speakers - 10 Watt (Total) - 2-way`.
    temp19-width = `13`.
    temp19-depth = `11`.
    temp19-height = `17.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1.4`.
    temp19-weightunit = `KG`.
    temp19-quantity = `15`.
    temp19-price = '26.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Sound Booster`.
    temp19-productid = `HT-1092`.
    temp19-category = `Speakers`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Speaker Experts`.
    temp19-description = `PC multimedia speakers - optimized for Blutooth/A2DP`.
    temp19-width = `12.4`.
    temp19-depth = `10.4`.
    temp19-height = `18.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.1`.
    temp19-weightunit = `KG`.
    temp19-quantity = `50`.
    temp19-price = '45.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Lovely Sound 5.1 Wireless`.
    temp19-productid = `HT-1095`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `5.1 Headset, 40 Hz-20 kHz, Wireless`.
    temp19-width = `24`.
    temp19-depth = `19`.
    temp19-height = `23`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `80`.
    temp19-weightunit = `G`.
    temp19-quantity = `12`.
    temp19-price = '49.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Lovely Sound 5.1`.
    temp19-productid = `HT-1096`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `5.1 Headset, 40 Hz-20 kHz, 3m cable`.
    temp19-width = `25`.
    temp19-depth = `17`.
    temp19-height = `19`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `130`.
    temp19-weightunit = `G`.
    temp19-quantity = `18`.
    temp19-price = '39.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Lovely Sound Stereo`.
    temp19-productid = `HT-1097`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `5.1 Headset, 40 Hz-20 kHz, 1m cable`.
    temp19-width = `21.3`.
    temp19-depth = `2.4`.
    temp19-height = `19.7`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `60`.
    temp19-weightunit = `G`.
    temp19-quantity = `21`.
    temp19-price = '29.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smart Office`.
    temp19-productid = `HT-1100`.
    temp19-category = `Software`.
    temp19-maincategory = `Software`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Complete package, 1 User, Office Applications (word processing, spreadsheet, presentations)`.
    temp19-width = `15`.
    temp19-depth = `6.5`.
    temp19-height = `2.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `25`.
    temp19-price = '89.90'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smart Design`.
    temp19-productid = `HT-1101`.
    temp19-category = `Software`.
    temp19-maincategory = `Software`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Complete package, 1 User, Image editing, processing`.
    temp19-width = `14`.
    temp19-depth = `6.7`.
    temp19-height = `24`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `26`.
    temp19-price = '79.90'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smart Network`.
    temp19-productid = `HT-1102`.
    temp19-category = `Software`.
    temp19-maincategory = `Software`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Complete package, 1 User, Network Software Utilities, Useful Applications and Documentation`.
    temp19-width = `16`.
    temp19-depth = `6`.
    temp19-height = `27`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `28`.
    temp19-price = '69.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smart Multimedia`.
    temp19-productid = `HT-1103`.
    temp19-category = `Software`.
    temp19-maincategory = `Software`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Complete package, 1 User, different Multimedia applications, playing music, watching DVDs, only with this Smart package`.
    temp19-width = `11`.
    temp19-depth = `3.4`.
    temp19-height = `22`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `9`.
    temp19-price = '77.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smart Games`.
    temp19-productid = `HT-1104`.
    temp19-category = `Software`.
    temp19-maincategory = `Software`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Complete package, 1 User, various games for amusement, logic, action, jump&run`.
    temp19-width = `10`.
    temp19-depth = `3`.
    temp19-height = `30`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1.1`.
    temp19-weightunit = `KG`.
    temp19-quantity = `13`.
    temp19-price = '55.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smart Internet Antivirus`.
    temp19-productid = `HT-1105`.
    temp19-category = `Software`.
    temp19-maincategory = `Software`.
    temp19-suppliername = `Brainsoft`.
    temp19-description = `Complete package, 1 User, highly recommended for internet users as anti-virus protection`.
    temp19-width = `16`.
    temp19-depth = `4`.
    temp19-height = `21`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.7`.
    temp19-weightunit = `KG`.
    temp19-quantity = `17`.
    temp19-price = '29.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smart Firewall`.
    temp19-productid = `HT-1106`.
    temp19-category = `Software`.
    temp19-maincategory = `Software`.
    temp19-suppliername = `Brainsoft`.
    temp19-description = `Complete package, 1 User, recommended for internet users, protect your PC against cyber-crime`.
    temp19-width = `17.9`.
    temp19-depth = `4.2`.
    temp19-height = `23.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.9`.
    temp19-weightunit = `KG`.
    temp19-quantity = `19`.
    temp19-price = '34.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smart Money`.
    temp19-productid = `HT-1107`.
    temp19-category = `Software`.
    temp19-maincategory = `Software`.
    temp19-suppliername = `Brainsoft`.
    temp19-description = `Complete package, 1 User, bring your money in your mind, see what you have and what you want`.
    temp19-width = `12`.
    temp19-depth = `1.5`.
    temp19-height = `19`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `18`.
    temp19-price = '29.90'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `PC Lock`.
    temp19-productid = `HT-1110`.
    temp19-category = `Computer System Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Red Point Stores`.
    temp19-description = `Robust 3m anti-burglary protection for your laptop computer`.
    temp19-width = `20`.
    temp19-depth = `8`.
    temp19-height = `4.3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.03`.
    temp19-weightunit = `KG`.
    temp19-quantity = `14`.
    temp19-price = '8.90'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Notebook Lock`.
    temp19-productid = `HT-1111`.
    temp19-category = `Computer System Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Red Point Stores`.
    temp19-description = `Robust 1m anti-burglary protection for your desktop computer`.
    temp19-width = `31`.
    temp19-depth = `9`.
    temp19-height = `7`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.02`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '6.90'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Web cam reality`.
    temp19-productid = `HT-1112`.
    temp19-category = `Computer System Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Red Point Stores`.
    temp19-description = `Color webcam, color, High-Speed USB`.
    temp19-width = `9`.
    temp19-depth = `8.2`.
    temp19-height = `1.3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.075`.
    temp19-weightunit = `KG`.
    temp19-quantity = `27`.
    temp19-price = '39.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Screen clean`.
    temp19-productid = `HT-1113`.
    temp19-category = `Computer System Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Red Point Stores`.
    temp19-description = `10 separately packed screen wipes`.
    temp19-width = `2`.
    temp19-depth = `2`.
    temp19-height = `0.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.05`.
    temp19-weightunit = `KG`.
    temp19-quantity = `17`.
    temp19-price = '2.30'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Fabric bag professional`.
    temp19-productid = `HT-1114`.
    temp19-category = `Computer System Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Red Point Stores`.
    temp19-description = `Notebook bag, plenty of room for stationery and writing materials`.
    temp19-width = `42`.
    temp19-depth = `32`.
    temp19-height = `7`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `14`.
    temp19-price = '31.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Wireless DSL Router`.
    temp19-productid = `HT-1115`.
    temp19-category = `Telecommunications`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Red Point Stores`.
    temp19-description = `Wireless DSL Router (available in blue, black and silver)`.
    temp19-width = `19.3`.
    temp19-depth = `18`.
    temp19-height = `5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.45`.
    temp19-weightunit = `KG`.
    temp19-quantity = `16`.
    temp19-price = '49.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Wireless DSL Router / Repeater`.
    temp19-productid = `HT-1116`.
    temp19-category = `Telecommunications`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Red Point Stores`.
    temp19-description = `Wireless DSL Router / Repeater (available in blue, black and silver)`.
    temp19-width = `19.3`.
    temp19-depth = `18`.
    temp19-height = `5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.45`.
    temp19-weightunit = `KG`.
    temp19-quantity = `12`.
    temp19-price = '59.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Wireless DSL Router / Repeater and Print Server`.
    temp19-productid = `HT-1117`.
    temp19-category = `Telecommunications`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Wireless DSL Router / Repeater and Print Server (available in blue, black and silver)`.
    temp19-width = `19.3`.
    temp19-depth = `18`.
    temp19-height = `5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.45`.
    temp19-weightunit = `KG`.
    temp19-quantity = `12`.
    temp19-price = '69.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `USB Stick`.
    temp19-productid = `HT-1118`.
    temp19-category = `Computer System Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Technocom`.
    temp19-description = `USB 2.0 High-Speed 64 GB`.
    temp19-width = `1.5`.
    temp19-depth = `8.7`.
    temp19-height = `1.2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.015`.
    temp19-weightunit = `KG`.
    temp19-quantity = `14`.
    temp19-price = '35.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Travel Adapter`.
    temp19-productid = `HT-1119`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Universal Travel Adapter`.
    temp19-width = `2`.
    temp19-depth = `3.1`.
    temp19-height = `3.9`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `88`.
    temp19-weightunit = `G`.
    temp19-quantity = `10`.
    temp19-price = '79.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Cordless Bluetooth Keyboard, english international`.
    temp19-productid = `HT-1120`.
    temp19-category = `Keyboards`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Cordless Bluetooth Keyboard with English keys`.
    temp19-width = `51.4`.
    temp19-depth = `23`.
    temp19-height = `4`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1`.
    temp19-weightunit = `KG`.
    temp19-quantity = `13`.
    temp19-price = '29.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Flat XXL`.
    temp19-productid = `HT-1137`.
    temp19-category = `Flat Screen Monitors`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Optimum Hi-Resolution max. 2048 × 1536 @ 85Hz, Dot Pitch: 0.24mm`.
    temp19-width = `54`.
    temp19-depth = `22`.
    temp19-height = `38`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `18`.
    temp19-weightunit = `KG`.
    temp19-quantity = `10`.
    temp19-price = '1430.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Pocket Mouse`.
    temp19-productid = `HT-1138`.
    temp19-category = `Mice`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Portable pocket Mouse with retracting cord`.
    temp19-width = `0.3`.
    temp19-depth = `0.5`.
    temp19-height = `1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.02`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '23.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `PC Power Station`.
    temp19-productid = `HT-1210`.
    temp19-category = `PCs`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Technocom`.
    temp19-description = `PC Power Station with 3,4 Ghz quad-core, 32 GB DDR3 SDRAM, feels like Available PC, Windows 8 Pro`.
    temp19-width = `28`.
    temp19-depth = `31`.
    temp19-height = `43`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `22`.
    temp19-price = '2399.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Astro Laptop 1516`.
    temp19-productid = `HT-1251`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `Flexible Laptop with 2,5 GHz Quad Core, 15" HD TN, 16 GB DDR SDRAM, 256 GB SSD, Windows 10 Pro`.
    temp19-width = `30`.
    temp19-depth = `18`.
    temp19-height = `3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `23`.
    temp19-price = '989.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Astro Phone 6`.
    temp19-productid = `HT-1252`.
    temp19-category = `Smartphones and Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `6 inch 1280x800 HD display (216 ppi), Quad-core processor, 8 GB internal storage (actual formatted capacity will be less), 3050 mAh battery (Up to 8 hours of active use), grey or black`.
    temp19-width = `8`.
    temp19-depth = `6`.
    temp19-height = `1.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.75`.
    temp19-weightunit = `KG`.
    temp19-quantity = `28`.
    temp19-price = '649.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Benda Laptop 1408`.
    temp19-productid = `HT-1253`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `Flexible Laptop with 2,5 GHz Dual Core, 14" HD+ TN, 8 GB DDR SDRAM, 324 GB SSD, Windows 10 Pro`.
    temp19-width = `30`.
    temp19-depth = `18`.
    temp19-height = `3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `27`.
    temp19-price = '976.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Bending Screen 21HD`.
    temp19-productid = `HT-1254`.
    temp19-category = `Flat Screens`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `Optimum Hi-Resolution Widescreen max. 1920 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp19-width = `37`.
    temp19-depth = `12`.
    temp19-height = `36`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `15`.
    temp19-weightunit = `KG`.
    temp19-quantity = `23`.
    temp19-price = '250.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Broad Screen 22HD`.
    temp19-productid = `HT-1255`.
    temp19-category = `Flat Screens`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `Optimum Hi-Resolution Widescreen max. 2048 x 1080 @ 85Hz, Dot Pitch: 0.27mm, HDMI, Discontinued-Sub`.
    temp19-width = `39`.
    temp19-depth = `12`.
    temp19-height = `38`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `16`.
    temp19-weightunit = `KG`.
    temp19-quantity = `5`.
    temp19-price = '270.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Cerdik Phone 7`.
    temp19-productid = `HT-1256`.
    temp19-category = `Smartphones and Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp19-width = `9`.
    temp19-depth = `15`.
    temp19-height = `1.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.75`.
    temp19-weightunit = `KG`.
    temp19-quantity = `19`.
    temp19-price = '549.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Cepat Tablet 10.5`.
    temp19-productid = `HT-1257`.
    temp19-category = `Smartphones and Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `10.5-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `17`.
    temp19-price = '549.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Cepat Tablet 8`.
    temp19-productid = `HT-1258`.
    temp19-category = `Smartphones and Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `8-inch Multitouch HD Screen (2000 x 1500) 32GB Internal Memory, Wireless N Wi-Fi, Bluetooth, GPS Enabled, 1.5 GHz Quad-Core Processor`.
    temp19-width = `38`.
    temp19-depth = `21`.
    temp19-height = `3.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `24`.
    temp19-price = '529.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Server Basic`.
    temp19-productid = `HT-1500`.
    temp19-category = `Servers`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Dual socket, quad-core processing server with 1333 MHz Front Side Bus with 10Gb connectivity`.
    temp19-width = `34`.
    temp19-depth = `35`.
    temp19-height = `23`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `18`.
    temp19-weightunit = `KG`.
    temp19-quantity = `24`.
    temp19-price = '5000.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Server Professional`.
    temp19-productid = `HT-1501`.
    temp19-category = `Servers`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 10Gb connectivity`.
    temp19-width = `29`.
    temp19-depth = `30`.
    temp19-height = `27`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `25`.
    temp19-weightunit = `KG`.
    temp19-quantity = `26`.
    temp19-price = '15000.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Server Power Pro`.
    temp19-productid = `HT-1502`.
    temp19-category = `Servers`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Technocom`.
    temp19-description = `Dual socket, quad-core processing server with 1644 MHz Front Side Bus with 100Gb connectivity`.
    temp19-width = `22`.
    temp19-depth = `27.3`.
    temp19-height = `37`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `35`.
    temp19-weightunit = `KG`.
    temp19-quantity = `34`.
    temp19-price = '25000.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Family PC Basic`.
    temp19-productid = `HT-1600`.
    temp19-category = `Desktop Computers`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Graphic Card: Proctra X, Windows 8`.
    temp19-width = `21.4`.
    temp19-depth = `29`.
    temp19-height = `38`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `10`.
    temp19-price = '600.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Family PC Pro`.
    temp19-productid = `HT-1601`.
    temp19-category = `Desktop Computers`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `2,8 Ghz dual core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp19-width = `25`.
    temp19-depth = `31.7`.
    temp19-height = `40.2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `5.3`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '900.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Gaming Monster`.
    temp19-productid = `HT-1602`.
    temp19-category = `Desktop Computers`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `3,4 Ghz quad core, 8 GB DDR3 SDRAM, 2000 GB Hard Disc, Graphic Card: Gladiator MX, Windows 8`.
    temp19-width = `26.5`.
    temp19-depth = `34`.
    temp19-height = `47`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `5.9`.
    temp19-weightunit = `KG`.
    temp19-quantity = `24`.
    temp19-price = '1200.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Gaming Monster Pro`.
    temp19-productid = `HT-1603`.
    temp19-category = `Desktop Computers`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `3,4 Ghz quad core, 16 GB DDR3 SDRAM, 4000 GB Hard Disc, Graphic Card: Hurricane GX, Windows 8`.
    temp19-width = `27`.
    temp19-depth = `28`.
    temp19-height = `42`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `6.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `25`.
    temp19-price = '1700.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `7" Widescreen Portable DVD Player w MP3`.
    temp19-productid = `HT-2000`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Titanium`.
    temp19-description = `7" LCD Screen, storage battery holds up to 6 hours!`.
    temp19-width = `21.4`.
    temp19-depth = `19`.
    temp19-height = `27.6`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.79`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '249.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `10" Portable DVD player`.
    temp19-productid = `HT-2001`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Titanium`.
    temp19-description = `10" LCD Screen, storage battery holds up to 8 hours`.
    temp19-width = `24`.
    temp19-depth = `19.5`.
    temp19-height = `29`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.84`.
    temp19-weightunit = `KG`.
    temp19-quantity = `21`.
    temp19-price = '449.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Portable DVD Player with 9" LCD Monitor`.
    temp19-productid = `HT-2002`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Technocom`.
    temp19-description = `9" LCD Screen, storage holds up to 8 hours, 2 speakers included`.
    temp19-width = `21`.
    temp19-depth = `16.5`.
    temp19-height = `14`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.72`.
    temp19-weightunit = `KG`.
    temp19-quantity = `50`.
    temp19-price = '853.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `CD/DVD case: 264 sleeves`.
    temp19-productid = `HT-2025`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Organizer and protective case for 264 CDs and DVDs`.
    temp19-width = `13`.
    temp19-depth = `13`.
    temp19-height = `20`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.65`.
    temp19-weightunit = `KG`.
    temp19-quantity = `26`.
    temp19-price = '44.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Audio/Video Cable Kit - 4m`.
    temp19-productid = `HT-2026`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Quality cables for notebooks and projectors`.
    temp19-width = `21`.
    temp19-depth = `10.2`.
    temp19-height = `13`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `16`.
    temp19-price = '29.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Removable CD/DVD Laser Labels`.
    temp19-productid = `HT-2027`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Removable jewel case labels, zero residues (100)`.
    temp19-width = `5.5`.
    temp19-depth = `2`.
    temp19-height = `2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.15`.
    temp19-weightunit = `KG`.
    temp19-quantity = `25`.
    temp19-price = '8.99'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Beam Breaker B-1`.
    temp19-productid = `HT-6100`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Titanium`.
    temp19-description = `720p, DLP Projector max. 8,45 Meter, 2D`.
    temp19-width = `30.4`.
    temp19-depth = `23.1`.
    temp19-height = `23`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1.7`.
    temp19-weightunit = `KG`.
    temp19-quantity = `32`.
    temp19-price = '469.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Beam Breaker B-2`.
    temp19-productid = `HT-6101`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Technocom`.
    temp19-description = `1080p, DLP max.9,34 Meter, 2D-ready`.
    temp19-width = `30.4`.
    temp19-depth = `23.1`.
    temp19-height = `23`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `18`.
    temp19-price = '679.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Beam Breaker B-3`.
    temp19-productid = `HT-6102`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Technocom`.
    temp19-description = `1080p, DLP max. 12,3 Meter, 3D-ready`.
    temp19-width = `30.4`.
    temp19-depth = `23.1`.
    temp19-height = `23`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `16`.
    temp19-price = '889.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Play Movie`.
    temp19-productid = `HT-6110`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp19-width = `37`.
    temp19-depth = `24`.
    temp19-height = `6`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.4`.
    temp19-weightunit = `KG`.
    temp19-quantity = `15`.
    temp19-price = '130.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Record Movie`.
    temp19-productid = `HT-6111`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `160 GB HDD, CD-RW, DVD+R/RW, DVD-R/RW, MPEG 2 (Video-DVD), MPEG 4, VCD, SVCD, DivX, Xvid`.
    temp19-width = `38`.
    temp19-depth = `26`.
    temp19-height = `6.2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.1`.
    temp19-weightunit = `KG`.
    temp19-quantity = `24`.
    temp19-price = '288.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelo MusicStick`.
    temp19-productid = `HT-6120`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `64 GB USB Music-on-Available-Stick`.
    temp19-width = `1.5`.
    temp19-depth = `6`.
    temp19-height = `1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `134`.
    temp19-weightunit = `G`.
    temp19-quantity = `15`.
    temp19-price = '45.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelo Jog-Mate`.
    temp19-productid = `HT-6121`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `ITelo Jog-Mate 64 GB HDD and Color Display, can play movies`.
    temp19-width = `5.1`.
    temp19-depth = `8`.
    temp19-height = `9.2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `134`.
    temp19-weightunit = `G`.
    temp19-quantity = `24`.
    temp19-price = '63.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Power Pro Player 40`.
    temp19-productid = `HT-6122`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `MP3-Player with 40 GB HDD and Color Display, can play movies`.
    temp19-width = `5.1`.
    temp19-depth = `8`.
    temp19-height = `9.2`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `266`.
    temp19-weightunit = `G`.
    temp19-quantity = `23`.
    temp19-price = '167.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Power Pro Player 80`.
    temp19-productid = `HT-6123`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `MP3-Player with 80 GB SSD and Color Display, can play movies`.
    temp19-width = `4`.
    temp19-depth = `6`.
    temp19-height = `0.8`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `267`.
    temp19-weightunit = `G`.
    temp19-quantity = `13`.
    temp19-price = '299.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Flat Watch HD32`.
    temp19-productid = `HT-6130`.
    temp19-category = `Flat Screen TVs`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `32-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp19-width = `78`.
    temp19-depth = `22.1`.
    temp19-height = `55`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.6`.
    temp19-weightunit = `KG`.
    temp19-quantity = `16`.
    temp19-price = '1459.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Flat Watch HD37`.
    temp19-productid = `HT-6131`.
    temp19-category = `Flat Screen TVs`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `37-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp19-width = `99.1`.
    temp19-depth = `26`.
    temp19-height = `61`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `2.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `14`.
    temp19-price = '1199.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Flat Watch HD41`.
    temp19-productid = `HT-6132`.
    temp19-category = `Flat Screen TVs`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Very Best Screens`.
    temp19-description = `41-inch, 1366x768 Pixel, 16:9, HDTV ready`.
    temp19-width = `128`.
    temp19-depth = `23`.
    temp19-height = `79.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `1.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `13`.
    temp19-price = '899.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Copperberry`.
    temp19-productid = `HT-7000`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `Our new multifunctional Handheld with phone function in copper`.
    temp19-width = `8.1`.
    temp19-depth = `13`.
    temp19-height = `12.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `5`.
    temp19-price = '549.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Silverberry`.
    temp19-productid = `HT-7010`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `Our new multifunctional Handheld with phone function in silver`.
    temp19-width = `8.1`.
    temp19-depth = `13`.
    temp19-height = `12.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `9`.
    temp19-price = '549.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Goldberry`.
    temp19-productid = `HT-7020`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `Our new multifunctional Handheld with phone function in gold`.
    temp19-width = `8.1`.
    temp19-depth = `13`.
    temp19-height = `12.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `11`.
    temp19-price = '549.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Platinberry`.
    temp19-productid = `HT-7030`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Components`.
    temp19-suppliername = `Fasttech`.
    temp19-description = `Our new multifunctional Handheld with phone function in platinum`.
    temp19-width = `8.1`.
    temp19-depth = `13`.
    temp19-height = `12.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `12`.
    temp19-price = '549.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelO FlexTop I4000`.
    temp19-productid = `HT-8000`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Notebook with 2,80 GHz dual core, 4 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp19-width = `31`.
    temp19-depth = `19`.
    temp19-height = `3.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4`.
    temp19-weightunit = `KG`.
    temp19-quantity = `11`.
    temp19-price = '799.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelO FlexTop I6300c`.
    temp19-productid = `HT-8001`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Notebook with 2,80 GHz dual core, 8 GB DDR3 SDRAM, 500 GB Hard Disc, Windows 8`.
    temp19-width = `32`.
    temp19-depth = `20`.
    temp19-height = `3.4`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `4.2`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '799.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelO FlexTop I9100`.
    temp19-productid = `HT-8002`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Notebook with 2,80 GHz quad core, 4 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp19-width = `38`.
    temp19-depth = `21`.
    temp19-height = `4.1`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.5`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '1199.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `ITelO FlexTop I9800`.
    temp19-productid = `HT-8003`.
    temp19-category = `Laptops`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Notebook with 2,80 GHz quad core, 8 GB DDR3 SDRAM, 1000 GB Hard Disc, Windows 8`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `22`.
    temp19-price = '1388.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smartphone Leather Case`.
    temp19-productid = `HT-9991`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `Button Clasp, Quality Material, 100% Leather, compatible with many smartphone models`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.02`.
    temp19-weightunit = `KG`.
    temp19-quantity = `12`.
    temp19-price = '25.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smartphone Alpha`.
    temp19-productid = `HT-9992`.
    temp19-category = `Smartphones and Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage (actual formatted capacity will be less), 4325 mAh battery (Up to 8 hours of active use), white or black`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.75`.
    temp19-weightunit = `KG`.
    temp19-quantity = `13`.
    temp19-price = '599.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Mini Tablet`.
    temp19-productid = `HT-9993`.
    temp19-category = `Smartphones and Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `7 inch 1280x800 HD display (216 ppi), Quad-core processor, 16 GB internal storage, 4325 mAh battery (Up to 8 hours of active use)`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `10`.
    temp19-price = '833.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Camcorder View`.
    temp19-productid = `HT-9994`.
    temp19-category = `Accessories`.
    temp19-maincategory = `TV, Video & HiFi`.
    temp19-suppliername = `Ultrasonic United`.
    temp19-description = `1920x1080 Full HD, image stabilization reduces blur, 27x Optical / 32x Extended Zoom, wide angle Lens, 2.7" wide LCD display`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `27`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `50`.
    temp19-price = '1388.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Tablet Pouch`.
    temp19-productid = `HT-9995`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp19-width = `25`.
    temp19-depth = `40`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.03`.
    temp19-weightunit = `KG`.
    temp19-quantity = `34`.
    temp19-price = '20.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Tablet Pouch`.
    temp19-productid = `HT-9996`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Stylish tablet pouch, protects from scratches, color: black`.
    temp19-width = `25`.
    temp19-depth = `40`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.03`.
    temp19-weightunit = `KG`.
    temp19-quantity = `34`.
    temp19-price = '20.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `e-Book Reader ReadMe`.
    temp19-productid = `HT-9997`.
    temp19-category = `Smartphones and Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Titanium`.
    temp19-description = `6-Inch E Ink Screen, Access To e-book Store, Adjustable Font Styles and Sizes, Stores Up To 1,000 Books`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `23`.
    temp19-price = '33.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Smartphone Beta`.
    temp19-productid = `HT-9998`.
    temp19-category = `Smartphones and Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Titanium`.
    temp19-description = `5 Megapixel Camera, Wi-Fi 802.11 b/g/n, Bluetooth, GPS Available-GPS support`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.75`.
    temp19-weightunit = `KG`.
    temp19-quantity = `21`.
    temp19-price = '30.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Maxi Tablet`.
    temp19-productid = `HT-9999`.
    temp19-category = `Tablets`.
    temp19-maincategory = `Smartphones & Tablets`.
    temp19-suppliername = `Titanium`.
    temp19-description = `10.1-inch Multitouch HD Screen (1280 x 800), 16GB Internal Memory, Wireless N Wi-Fi; Bluetooth, GPS Enabled, 1GHz Dual-Core Processor`.
    temp19-width = `48`.
    temp19-depth = `31`.
    temp19-height = `4.5`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `3.8`.
    temp19-weightunit = `KG`.
    temp19-quantity = `20`.
    temp19-price = '749.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    temp19-name = `Flyer`.
    temp19-productid = `PF-1000`.
    temp19-category = `Accessories`.
    temp19-maincategory = `Computer Systems`.
    temp19-suppliername = `Titanium`.
    temp19-description = `Flyer for our product palette`.
    temp19-width = `46`.
    temp19-depth = `30`.
    temp19-height = `3`.
    temp19-dimunit = `cm`.
    temp19-weightmeasure = `0.01`.
    temp19-weightunit = `KG`.
    temp19-quantity = `33`.
    temp19-price = '0.00'.
    temp19-currencycode = `EUR`.
    INSERT temp19 INTO TABLE temp18.
    t_products = temp18.

    " ProductPicUrl is derivable from the product id (the mock's
    " test-resources/.../<id>.jpg), built from a shared base pointing at the
    " OpenUI5 host (like app 006's image flattening)
    
    
    LOOP AT t_products REFERENCE INTO product.
      product->productpicurl = |{ c_img_base }{ product->productid }.jpg|.
    ENDLOOP.

  ENDMETHOD.


ENDCLASS.
