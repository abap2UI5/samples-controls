" @keywords dynamicpage dynamic sap.f dynamicpageanalyticaltable dynamicpagetitle title label overflowtoolbar generictag objectnumber toolbarspacer button
" @summary Dynamic Page containing an Analytical Table in the content area aligned with the SAP Fiori List Report floorplan.
" @origin sap.f.sample.DynamicPageAnalyticalTable - https://sdk.openui5.org/entity/sap.f.DynamicPage/sample/sap.f.sample.DynamicPageAnalyticalTable (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_559 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_named,
        name TYPE string,
      END OF ty_s_named.
    TYPES:
      BEGIN OF ty_s_product,
        productid      TYPE string,
        name           TYPE string,
        quantity       TYPE i,
        status         TYPE string,
        price          TYPE p LENGTH 9 DECIMALS 2,
        currencycode   TYPE string,
        suppliername   TYPE string,
        productpicurl  TYPE string,
        category       TYPE string,
        weightmeasure  TYPE p LENGTH 9 DECIMALS 3,
        " derived in initSampleDataModel, reproduced in model_init
        available      TYPE abap_bool,
        availablestate TYPE string,
        availableicon  TYPE string,
        heavy          TYPE string,
        deliverydate   TYPE string,
      END OF ty_s_product.

    DATA productcollection TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA suppliers         TYPE STANDARD TABLE OF ty_s_named WITH EMPTY KEY.
    DATA categories        TYPE STANDARD TABLE OF ty_s_named WITH EMPTY KEY.
    " initSampleDataModel puts headerExpanded on the model and the page binds it
    DATA headerexpanded    TYPE abap_bool VALUE abap_true.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS popover_display IMPORTING by_id TYPE string.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_559 IMPLEMENTATION.

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

    DATA(page) = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`      v = `100%`
        )->a( n = `xmlns`       v = `sap.m`
        )->a( n = `xmlns:mvc`   v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core`  v = `sap.ui.core`
        )->a( n = `xmlns:u`     v = `sap.ui.unified`
        )->a( n = `xmlns:table` v = `sap.ui.table`
        )->a( n = `xmlns:f`     v = `sap.f`
        )->a( n = `xmlns:l`     v = `sap.ui.layout`

        )->ele( n = `DynamicPage` ns = `f`
            )->a( n = `id`                          v = `dynamicPageId`
            )->a( n = `preserveHeaderStateOnScroll` v = `true`
            )->a( n = `headerExpanded`              v = client->_bind( headerexpanded )
            )->a( n = `showFooter`                  v = `true`
            )->a( n = `fitContent`                  v = `true` ).

    " DynamicPage Title
    DATA(title) = page->ele( n = `title` ns = `f`
        )->ele( n = `DynamicPageTitle` ns = `f` ).

    title->ele( n = `heading` ns = `f`
        )->tag( `Title`
            )->a( n = `text` v = `Header Title`

    )->end(
        )->ele( n = `expandedContent` ns = `f`
            )->tag( `Label`
                )->a( n = `text` v = `This is a subheading`

        )->end(
        )->ele( n = `snappedContent` ns = `f`
            )->tag( `Label`
                )->a( n = `text` v = `This is a subheading`

        )->end(
        )->ele( n = `snappedTitleOnMobile` ns = `f`
            )->tag( `Title`
                )->a( n = `text` v = `This is a subheading`

        )->end(
        )->ele( n = `content` ns = `f`
            )->ele( `OverflowToolbar`

                )->ele( `GenericTag`
                    )->a( n = `text`   v = `SR`
                    )->a( n = `status` v = `Error`
                    )->a( n = `design` v = `StatusIconHidden`
                    " onGenericTagPress anchors the card popover on the pressed tag
                    )->a( n = `press`  v = client->_event( val = `GENERIC_TAG` arg = `$event.oSource.sId` )

                    )->tag( `ObjectNumber`
                        )->a( n = `number`     v = `2`
                        )->a( n = `unit`       v = `M`
                        )->a( n = `emphasized` v = `false`
                        )->a( n = `state`      v = `Error`

                )->end(
            )->end(
        )->end(
        )->ele( n = `actions` ns = `f`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `text` v = `Edit`
                )->a( n = `type` v = `Emphasized`
            )->tag( `Button`
                )->a( n = `text` v = `Delete`
                )->a( n = `type` v = `Transparent`
            )->tag( `Button`
                )->a( n = `text` v = `Copy`
                )->a( n = `type` v = `Transparent`
            )->tag( `Button`
                )->a( n = `icon`    v = `sap-icon://action`
                )->a( n = `tooltip` v = `Share`
                )->a( n = `type`    v = `Transparent` ).

    " DynamicPage Header
    page->ele( n = `header` ns = `f`
        )->ele( n = `DynamicPageHeader` ns = `f`
            )->a( n = `pinnable` v = `true`

            )->ele( `FlexBox`
                )->a( n = `alignItems`     v = `Start`
                )->a( n = `justifyContent` v = `SpaceBetween`

                )->ele( `items`
                    )->ele( `Panel`
                        )->a( n = `backgroundDesign` v = `Transparent`
                        )->a( n = `class`            v = `sapUiNoContentPadding`

                        )->ele( `content`
                            )->ele( n = `HorizontalLayout` ns = `l`
                                )->a( n = `allowWrapping` v = `true`

                                )->ele( n = `VerticalLayout` ns = `l`
                                    )->a( n = `class` v = `sapUiMediumMarginEnd`

                                    )->tag( `ObjectAttribute`
                                        )->a( n = `title` v = `Location`
                                        )->a( n = `text`  v = `Warehouse A`
                                    )->tag( `ObjectAttribute`
                                        )->a( n = `title` v = `Halway`
                                        )->a( n = `text`  v = `23L`
                                    )->tag( `ObjectAttribute`
                                        )->a( n = `title` v = `Rack`
                                        )->a( n = `text`  v = `34`

                                )->end(
                                )->ele( n = `VerticalLayout` ns = `l`

                                    )->tag( `ObjectAttribute`
                                        )->a( n = `title` v = `Availability`
                                    )->tag( `ObjectStatus`
                                        )->a( n = `text`  v = `In Stock`
                                        )->a( n = `state` v = `Success`

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    DATA(columns) = page->ele( n = `content` ns = `f`
        )->ele( n = `Table` ns = `table`
            )->a( n = `rows`          v = client->_bind( productcollection )
            )->a( n = `selectionMode` v = `MultiToggle`
            )->a( n = `rowMode`       v = `Auto`

            )->ele( n = `extension` ns = `table`
                )->ele( `OverflowToolbar`
                    )->a( n = `style` v = `Clear`

                    )->tag( `Title`
                        )->a( n = `text` v = `Products`

                )->end(
            )->end(
            )->ele( n = `columns` ns = `table` ).

    columns->ele( n = `Column` ns = `table`
        )->a( n = `width` v = `11rem`
        )->tag( `Label`
            )->a( n = `text` v = `Product Name`
        )->ele( n = `template` ns = `table`
            )->tag( `Text`
                )->a( n = `text`     v = `{NAME}`
                )->a( n = `wrapping` v = `false`

        )->end(
    )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `11rem`
            )->tag( `Label`
                )->a( n = `text` v = `Product Id`
            )->ele( n = `template` ns = `table`
                )->tag( `Input`
                    )->a( n = `value` v = `{PRODUCTID}`

            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width`  v = `6rem`
            )->a( n = `hAlign` v = `End`
            )->tag( `Label`
                )->a( n = `text` v = `Quantity`
            )->ele( n = `template` ns = `table`
                )->tag( `Label`
                    )->a( n = `text` v = `{QUANTITY}`

            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `9rem`
            )->tag( `Label`
                )->a( n = `text` v = `Status`
            )->ele( n = `template` ns = `table`
                )->tag( `ObjectStatus`
                    )->a( n = `text`  v = `{STATUS}`
                    " formatAvailableToObjectState is computed in ABAP (thin frontend)
                    )->a( n = `state` v = `{AVAILABLESTATE}`

            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `9rem`
            )->tag( `Label`
                )->a( n = `text` v = `Price`
            )->ele( n = `template` ns = `table`
                )->tag( n = `Currency` ns = `u`
                    )->a( n = `value`    v = `{PRICE}`
                    )->a( n = `currency` v = `{CURRENCYCODE}`

            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `12rem`
            )->tag( `Label`
                )->a( n = `text` v = `Supplier`
            )->ele( n = `template` ns = `table`
                )->ele( `ComboBox`
                    )->a( n = `value` v = `{SUPPLIERNAME}`
                    )->a( n = `items` v = |\{ path: '{ client->_bind_path( suppliers ) }', templateShareable: false \}|

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `text` v = `{NAME}`

                )->end(
            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `9rem`
            )->tag( `Label`
                )->a( n = `text` v = `Image`
            )->ele( n = `template` ns = `table`
                )->tag( `Link`
                    )->a( n = `text`   v = `Show Image`
                    )->a( n = `href`   v = `{PRODUCTPICURL}`
                    )->a( n = `target` v = `_blank`

            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `9rem`
            )->tag( `Label`
                )->a( n = `text` v = `Details`
            )->ele( n = `template` ns = `table`
                " handleDetailsPress toasts the row's ProductId - the row field
                " resolves on the client, so no round-trip
                )->tag( `Button`
                    )->a( n = `text`  v = `Show Details`
                    )->a( n = `press` v = client->follow_up_action(
                              val   = client->cs_event-control_global
                              t_arg = VALUE #( ( `MESSAGE_TOAST` )
                                               ( `show` )
                                               ( `Details for product with id {0}` )
                                               ( `${PRODUCTID}` ) ) )

            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `7rem`
            )->tag( `Label`
                )->a( n = `text` v = `Heavy Weight`
            )->ele( n = `template` ns = `table`
                )->tag( `CheckBox`
                    )->a( n = `selected` v = |\{ path: 'HEAVY', type: 'sap.ui.model.type.String' \}|

            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `12rem`
            )->tag( `Label`
                )->a( n = `text` v = `Category`
            )->ele( n = `template` ns = `table`
                )->ele( `Select`
                    )->a( n = `selectedKey` v = `{CATEGORY}`
                    )->a( n = `items`       v = |\{ path: '{ client->_bind_path( categories ) }', templateShareable: false \}|

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `text` v = `{NAME}`
                        )->a( n = `key`  v = `{NAME}`

                )->end(
            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width`  v = `6rem`
            )->a( n = `hAlign` v = `Center`
            )->tag( `Label`
                )->a( n = `text` v = `Status`
            )->ele( n = `template` ns = `table`
                )->tag( n = `Icon` ns = `core`
                    " formatAvailableToIcon is computed in ABAP (thin frontend)
                    )->a( n = `src` v = `{AVAILABLEICON}`

            )->end(
        )->end(
        )->ele( n = `Column` ns = `table`
            )->a( n = `width`  v = `11rem`
            )->a( n = `hAlign` v = `Center`
            )->tag( `Label`
                )->a( n = `text` v = `Delivery Date`
            )->ele( n = `template` ns = `table`
                )->tag( `DatePicker`
                    )->a( n = `value` v = |\{ path: 'DELIVERYDATE', type: 'sap.ui.model.type.Date', formatOptions: \{ source: \{ pattern: 'yyyy-MM-dd' \} \} \}|

            )->end(
        )->end(
    )->end(
    )->end( ).

    " DynamicPage Footer
    page->ele( n = `footer` ns = `f`
        )->ele( `OverflowToolbar`
            )->tag( `ToolbarSpacer`
            )->tag( `Button`
                )->a( n = `type` v = `Accept`
                )->a( n = `text` v = `Accept`
            )->tag( `Button`
                )->a( n = `type` v = `Reject`
                )->a( n = `text` v = `Reject` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD popover_display.

    " Card.fragment.xml - the numeric card the GenericTag opens
    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:f`    v = `sap.f`
        )->a( n = `xmlns:card` v = `sap.f.cards`

        )->ele( `Popover`
            )->a( n = `placement`    v = `Right`
            )->a( n = `showHeader`   v = `false`
            )->a( n = `contentWidth` v = `300px`

            )->ele( n = `Card` ns = `f`
                )->a( n = `width` v = `300px`

                )->ele( n = `header` ns = `f`
                    )->ele( n = `NumericHeader` ns = `card`
                        )->a( n = `title`             v = `Sales Revenue`
                        )->a( n = `subtitle`          v = `Sales revenue in the current quarter`
                        )->a( n = `unitOfMeasurement` v = `EUR`
                        )->a( n = `number`            v = `2.16`
                        )->a( n = `scale`             v = `M`
                        )->a( n = `trend`             v = `Down`
                        )->a( n = `state`             v = `Error`

                        )->ele( n = `sideIndicators` ns = `card`
                            )->tag( n = `NumericSideIndicator` ns = `card`
                                )->a( n = `number` v = `4.74`
                                )->a( n = `unit`   v = `M`
                                )->a( n = `title`  v = `Target`
                            )->tag( n = `NumericSideIndicator` ns = `card`
                                )->a( n = `number` v = `-54.49`
                                )->a( n = `unit`   v = `%`
                                )->a( n = `title`  v = `Deviation` ).

    client->popover_display( xml = popup->stringify( ) by_id = by_id ).

  ENDMETHOD.


  METHOD on_event.

    " onGenericTagPress is the sample's only handler that reaches the backend
    IF client->get_event( ) = `GENERIC_TAG`.
      popover_display( client->get_event_arg( ) ).
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
