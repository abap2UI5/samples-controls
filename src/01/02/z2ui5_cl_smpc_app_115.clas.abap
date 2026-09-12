" @keywords table sap.ui.table grid overflowtoolbar title column label text input objectstatus currency combobox
" @summary Basic example showing most controls which are intended to be used inside a table.
" @origin sap.ui.table.sample.Basic - https://sdk.openui5.org/entity/sap.ui.table.Table/sample/sap.ui.table.sample.Basic (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_115 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_token,
        key  TYPE string,
        name TYPE string,
      END OF ty_s_token.
    TYPES:
      BEGIN OF ty_s_named,
        name TYPE string,
      END OF ty_s_named.
    TYPES:
      BEGIN OF ty_s_product,
        productid                     TYPE string,
        name                          TYPE string,
        quantity                      TYPE i,
        status                        TYPE string,
        price                         TYPE p LENGTH 9 DECIMALS 2,
        currencycode                  TYPE string,
        suppliername                  TYPE string,
        productpicurl                 TYPE string,
        category                      TYPE string,
        weightmeasure                 TYPE p LENGTH 9 DECIMALS 3,
        " derived in initSampleDataModel, reproduced in model_init
        available                     TYPE abap_bool,
        availablestate                TYPE string,
        availableicon                 TYPE string,
        heavy                         TYPE string,
        deliverydate                  TYPE string,
        " the MultiInput column: the sample's rows carry neither key, so both
        " start empty and the token table grows through the tokenUpdate wire
        additionalcategory            TYPE string,
        additionalcategoriesselection TYPE STANDARD TABLE OF ty_s_token WITH EMPTY KEY,
      END OF ty_s_product.
    DATA productcollection TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA suppliers         TYPE STANDARD TABLE OF ty_s_named WITH EMPTY KEY.
    DATA categories        TYPE STANDARD TABLE OF ty_s_named WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_115 IMPLEMENTATION.

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

    " the full sample: all THIRTEEN columns over the shared demo mock, with the
    " Suppliers/Categories arrays the controller derives from it. The two
    " Available formatters are computed in ABAP (thin-frontend rule) into
    " AVAILABLESTATE / AVAILABLEICON, and the DatePicker binding keeps its type
    " but takes an ISO source pattern instead of the original timestamp - the
    " model carries a date STRING, not a JS epoch number (CAPABILITIES date row)
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.ui.table`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:u`    v = `sap.ui.unified`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:m`    v = `sap.m`
        )->a( n = `height`     v = `100%`

        )->ele( n = `Page` ns = `m`
            )->a( n = `showHeader`      v = `false`
            )->a( n = `enableScrolling` v = `false`
            )->a( n = `class`           v = `sapUiContentPadding`

            )->ele( n = `content` ns = `m`
                )->ele( `Table`
                    )->a( n = `rows`           v = client->_bind( productcollection )
                    )->a( n = `selectionMode`  v = `MultiToggle`
                    " onPaste toasts the pasted data - composed on the client
                    )->a( n = `paste`          v = client->follow_up_action(
                                       val   = client->cs_event-control_global
                                       t_arg = VALUE #( ( `MESSAGE_TOAST` )
                                                        ( `show` )
                                                        ( `Pasted Data: {0}` )
                                                        ( `${$parameters>/data}` ) ) )
                    )->a( n = `ariaLabelledBy` v = `title`

                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `style` v = `Clear`
                            )->tag( n = `Title` ns = `m`
                                )->a( n = `id`   v = `title`
                                )->a( n = `text` v = `Products`

                        )->end(
                    )->end(
                    )->ele( `columns`

                        )->ele( `Column`
                            )->a( n = `width` v = `11rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Name`
                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{NAME}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `11rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Id`
                            )->ele( `template`
                                )->tag( n = `Input` ns = `m`
                                    )->a( n = `value` v = `{PRODUCTID}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width`  v = `6rem`
                            )->a( n = `hAlign` v = `End`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Quantity`
                            )->ele( `template`
                                )->tag( n = `Label` ns = `m`
                                    )->a( n = `text` v = `{QUANTITY}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `9rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Status`
                            )->ele( `template`
                                )->tag( n = `ObjectStatus` ns = `m`
                                    )->a( n = `text`  v = `{STATUS}`
                                    )->a( n = `state` v = `{AVAILABLESTATE}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `9rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Price`
                            )->ele( `template`
                                )->tag( n = `Currency` ns = `u`
                                    )->a( n = `value`    v = `{PRICE}`
                                    )->a( n = `currency` v = `{CURRENCYCODE}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `12rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Supplier`
                            )->ele( `template`
                                )->ele( n = `ComboBox` ns = `m`
                                    )->a( n = `value` v = `{SUPPLIERNAME}`
                                    )->a( n = `items` v = |\{ path: '{ client->_bind_path( suppliers ) }', templateShareable: false \}|

                                    )->ele( n = `items` ns = `m`
                                        )->tag( n = `Item` ns = `core`
                                            )->a( n = `text` v = `{NAME}`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `9rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Image`
                            )->ele( `template`
                                )->tag( n = `Link` ns = `m`
                                    )->a( n = `text`   v = `Show Image`
                                    )->a( n = `href`   v = `{PRODUCTPICURL}`
                                    )->a( n = `target` v = `_blank`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `9rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Details`
                            )->ele( `template`
                                " handleDetailsPress toasts the row's ProductId - the row
                                " field resolves on the client, so no round-trip
                                )->tag( n = `Button` ns = `m`
                                    )->a( n = `text`  v = `Show Details`
                                    )->a( n = `press` v = client->follow_up_action(
                                              val   = client->cs_event-control_global
                                              t_arg = VALUE #( ( `MESSAGE_TOAST` )
                                                               ( `show` )
                                                               ( `Details for product with id {0}` )
                                                               ( `${PRODUCTID}` ) ) )

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `7rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Heavy Weight`
                            )->ele( `template`
                                )->tag( n = `CheckBox` ns = `m`
                                    )->a( n = `selected` v = |\{ path: 'HEAVY', type: 'sap.ui.model.type.String' \}|

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `12rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Main Category`
                            )->ele( `template`
                                )->ele( n = `Select` ns = `m`
                                    )->a( n = `selectedKey` v = `{CATEGORY}`
                                    )->a( n = `items`       v = |\{ path: '{ client->_bind_path( categories ) }', templateShareable: false \}|

                                    )->ele( n = `items` ns = `m`
                                        )->tag( n = `Item` ns = `core`
                                            )->a( n = `text` v = `{NAME}`
                                            )->a( n = `key`  v = `{NAME}`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width` v = `12rem`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Additional Categories`
                            )->ele( `template`
                                )->ele( n = `MultiInput` ns = `m`
                                    " updateMultipleSelection rewrites the row's token
                                    " table after a delete - the update type, the removed
                                    " key and the row path travel, ABAP removes the entry.
                                    " The removedTokens guard is required: an ADD fires the
                                    " same event with removedTokens = [], and an unguarded
                                    " [0].getKey() throws before the round-trip even starts
                                    )->a( n = `tokenUpdate`     v = client->_event(
                                                  val   = `TOKEN_UPDATE`
                                                  t_arg = VALUE #( ( `${$parameters>/type}` )
                                                                   ( `${$parameters>/removedTokens}[0] ? ${$parameters>/removedTokens}[0].getKey() : ''` )
                                                                   ( `$event.oSource.getBindingContext().getPath()` ) ) )
                                    )->a( n = `value`           v = `{ADDITIONALCATEGORY}`
                                    )->a( n = `tokens`          v = |\{ path: 'ADDITIONALCATEGORIESSELECTION', templateShareable: false \}|
                                    )->a( n = `suggestionItems` v = |\{ path: '{ client->_bind_path( categories ) }', templateShareable: false, sorter: \{ path: 'NAME' \} \}|
                                    )->a( n = `showValueHelp`   v = `false`

                                    )->ele( n = `tokens` ns = `m`
                                        )->tag( n = `Token` ns = `m`
                                            )->a( n = `key`  v = `{KEY}`
                                            )->a( n = `text` v = `{NAME}`

                                    )->end(
                                    )->ele( n = `suggestionItems` ns = `m`
                                        )->tag( n = `Item` ns = `core`
                                            " the ORIGINAL writes key="{ProductId}" on a template bound
                                            " over /Categories, whose rows only have a Name - its own quirk,
                                            " ported verbatim (sidecar NOTE)
                                            " abap2ui5lint-disable-next-line unknown-binding-path -- the sample's own quirk
                                            )->a( n = `key`  v = `{PRODUCTID}`
                                            )->a( n = `text` v = `{NAME}`

                                    )->end(
                                )->end(
                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width`  v = `6rem`
                            )->a( n = `hAlign` v = `Center`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Status`
                            )->ele( `template`
                                )->tag( n = `Icon` ns = `core`
                                    )->a( n = `src` v = `{AVAILABLEICON}`

                            )->end(
                        )->end(
                        )->ele( `Column`
                            )->a( n = `width`  v = `11rem`
                            )->a( n = `hAlign` v = `Center`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Delivery Date`
                            )->ele( `template`
                                )->tag( n = `DatePicker` ns = `m`
                                    )->a( n = `value` v = |\{ path: 'DELIVERYDATE', type: 'sap.ui.model.type.Date', formatOptions: \{ source: \{ pattern: 'yyyy-MM-dd' \} \} \}| ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `TOKEN_UPDATE`.
      " the update type, the removed token key and the row it belongs to (its
      " binding context path ends in the row index, as in app 094). The
      " original filters the row's token list by the removed KEYS, which is
      " reproduced verbatim - an empty key matches the empty-key tokens, the
      " same set the original's filter drops
      DATA(update_type) = client->get_event_arg( ).
      DATA(removed_key) = client->get_event_arg( 2 ).
      DATA(row_path) = client->get_event_arg( 3 ).
      DATA(row_index) = CONV i( substring_after( val = row_path sub = `/` occ = -1 ) ).
      " the row is addressed through a field symbol, not a table expression:
      " abaplint's downport leaves an itab[ ] TARGET of INSERT/DELETE in
      " place, and the 702 parser rejects it
      DATA(row_no) = row_index + 1.
      IF update_type = `removed`.
        READ TABLE productcollection INDEX row_no ASSIGNING FIELD-SYMBOL(<product>).
        IF sy-subrc = 0.
          DELETE <product>-additionalcategoriesselection WHERE key = removed_key.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " sap/ui/demo/mock/products.json, all 123 rows verbatim (ui5/mock/products.json)
    productcollection = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

    " initSampleDataModel derives four things per row and two arrays from them
    LOOP AT productcollection REFERENCE INTO DATA(product).
      " Date.now() - (i % 10 * 4 days): a moving value, so it is anchored on a
      " FIXED base here (the corpus rule for now/random values, apps 164/181/289)
      " the arithmetic has to land in a TYPE d field before it is formatted: a
      " date operand inside an expression is converted to its DAY NUMBER, so
      " CONV string( CONV d( ... ) - n ) yields 739618, not 20260101, and the
      " offsets then cut that into '7.39-61-80'. Measured 2026-08-21 - every
      " row carried a nonsense date the DatePicker's yyyy-MM-dd binding could
      " not parse, and nothing failed loudly enough for a gate to see it.
      DATA(delivery) = CONV d( CONV d( `20260101` ) - ( ( sy-tabix - 1 ) MOD 10 ) * 4 ).
      product->deliverydate   = |{ delivery(4) }-{ delivery+4(2) }-{ delivery+6(2) }|.
      product->available      = xsdbool( product->status = `Available` ).
      product->availablestate = COND #( WHEN product->available = abap_true THEN `Success` ELSE `Error` ).
      product->availableicon  = COND #( WHEN product->available = abap_true
                                        THEN `sap-icon://accept`
                                        ELSE `sap-icon://decline` ).
      product->heavy          = COND #( WHEN product->weightmeasure > 1000 THEN `true` ELSE `false` ).

      IF product->suppliername IS NOT INITIAL AND NOT line_exists( suppliers[ name = product->suppliername ] ).
        INSERT VALUE #( name = product->suppliername ) INTO TABLE suppliers.
      ENDIF.
      IF product->category IS NOT INITIAL AND NOT line_exists( categories[ name = product->category ] ).
        INSERT VALUE #( name = product->category ) INTO TABLE categories.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
