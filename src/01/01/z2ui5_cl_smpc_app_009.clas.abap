" @keywords column sap.m allows define specific properties table overflowtoolbar title toolbarspacer combobox item
" @summary The table shares many features with the list and, in addition, introduces columns. The table is fully responsive and can hide columns or shown them in-place if the screen space is not sufficient.
" @origin sap.m.sample.Table - https://sdk.openui5.org/entity/sap.m.Column/sample/sap.m.sample.Table (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_009 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid     TYPE string,
        name          TYPE string,
        suppliername  TYPE string,
        weightmeasure TYPE p LENGTH 8 DECIMALS 3,
        weightunit    TYPE string,
        weight_state  TYPE string,
        price         TYPE p LENGTH 8 DECIMALS 2,
        currencycode  TYPE string,
        width         TYPE p LENGTH 4 DECIMALS 1,
        depth         TYPE p LENGTH 4 DECIMALS 1,
        height        TYPE p LENGTH 4 DECIMALS 1,
        dimunit       TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.
    DATA t_sticky TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA popin_key TYPE string.
    DATA toggle_pressed TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_009 IMPLEMENTATION.

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
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        " sticky + popinLayout are set imperatively by the original controller (onSelect / onPopinLayoutChanged) - bound properties here
        )->ele( `Table`
            )->a( n = `id`          v = `idProductsTable`
            )->a( n = `inset`       v = `false`
            )->a( n = `items`       v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'NAME' \} \}|
            )->a( n = `sticky`      v = client->_bind( t_sticky )
            )->a( n = `popinLayout` v = |\{= ${ client->_bind( popin_key ) } === 'GridLarge' \|\| ${ client->_bind( popin_key ) } === 'GridSmall' ? ${ client->_bind( popin_key ) } : 'Block' \}|

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->ele( `content`
                        )->tag( `Title`
                            )->a( n = `text`  v = `Products`
                            )->a( n = `level` v = `H2`
                        )->tag( `ToolbarSpacer`

                        " the original change handler's PopinLayout switch lives in the Table's popinLayout expression binding
                        )->ele( `ComboBox`
                            )->a( n = `id`          v = `idPopinLayout`
                            )->a( n = `placeholder` v = `Popin layout options`
                            )->a( n = `selectedKey` v = client->_bind( popin_key )

                            )->ele( `items`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `text` v = `Block`
                                    )->a( n = `key`  v = `Block`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `text` v = `Grid Large`
                                    )->a( n = `key`  v = `GridLarge`
                                )->tag( n = `Item` ns = `core`
                                    )->a( n = `text` v = `Grid Small`
                                    )->a( n = `key`  v = `GridSmall`

                            )->end(
                        )->end(
                        )->tag( `Label`
                            )->a( n = `text` v = `Sticky options:`
                        )->tag( `CheckBox`
                            )->a( n = `text`   v = `ColumnHeaders`
                            )->a( n = `select` v = client->_event( val   = `STICKY_SELECT`
                                                                   t_arg = VALUE #( ( `${$source>/text}` ) ( `${$parameters>/selected}` ) ) )
                        )->tag( `CheckBox`
                            )->a( n = `text`   v = `HeaderToolbar`
                            )->a( n = `select` v = client->_event( val   = `STICKY_SELECT`
                                                                   t_arg = VALUE #( ( `${$source>/text}` ) ( `${$parameters>/selected}` ) ) )
                        )->tag( `CheckBox`
                            )->a( n = `text`   v = `InfoToolbar`
                            )->a( n = `select` v = client->_event( val   = `STICKY_SELECT`
                                                                   t_arg = VALUE #( ( `${$source>/text}` ) ( `${$parameters>/selected}` ) ) )
                        " the original press handler (infoToolbar.setVisible(!pressed)) is the visible expression binding on the infoToolbar below
                        )->tag( `ToggleButton`
                            )->a( n = `id`      v = `toggleInfoToolbar`
                            )->a( n = `text`    v = `Hide/Show InfoToolbar`
                            )->a( n = `pressed` v = client->_bind( toggle_pressed )

                    )->end(
                )->end(
            )->end(
            )->ele( `infoToolbar`
                )->ele( `OverflowToolbar`
                    )->a( n = `visible` v = |\{= !${ client->_bind( toggle_pressed ) } \}|

                    )->tag( `Label`
                        )->a( n = `text` v = `Wide range of available products`

                )->end(
            )->end(
            )->ele( `columns`
                )->ele( `Column`
                    )->a( n = `width` v = `12em`

                    " p:ColumnAIAction dependents dropped - plugin class newer than 1.71, see DROPPED_171 (as app 022)
                    )->tag( `Text`
                        )->a( n = `text` v = `Product`

                )->end(
                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Tablet`
                    )->a( n = `demandPopin`    v = `true`

                    )->tag( `Text`
                        )->a( n = `text` v = `Supplier`

                )->end(
                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Desktop`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Dimensions`

                )->end(
                )->ele( `Column`
                    )->a( n = `minScreenWidth` v = `Desktop`
                    )->a( n = `demandPopin`    v = `true`
                    )->a( n = `hAlign`         v = `Center`

                    )->tag( `Text`
                        )->a( n = `text` v = `Weight`

                )->end(
                )->ele( `Column`
                    )->a( n = `hAlign` v = `End`

                    )->tag( `Text`
                        )->a( n = `text` v = `Price`

                )->end(
            )->end(
            )->ele( `items`
                )->ele( `ColumnListItem`
                    )->a( n = `vAlign` v = `Middle`

                    )->ele( `cells`
                        )->tag( `ObjectIdentifier`
                            )->a( n = `title` v = `{NAME}`
                            )->a( n = `text`  v = `{PRODUCTID}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{SUPPLIERNAME}`
                        )->tag( `Text`
                            )->a( n = `text` v = `{WIDTH} x {DEPTH} x {HEIGHT} {DIMUNIT}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{WEIGHTMEASURE}`
                            )->a( n = `unit`   v = `{WEIGHTUNIT}`
                            )->a( n = `state`  v = `{WEIGHT_STATE}`
                        )->tag( `ObjectNumber`
                            )->a( n = `number` v = `{ parts: [{path: 'PRICE'}, {path: 'CURRENCYCODE'}], type: 'sap.ui.model.type.Currency', formatOptions: {showMeasure: false} }`
                            )->a( n = `unit`   v = `{CURRENCYCODE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    DATA selected TYPE abap_bool.

    IF client->get_event( ) = `STICKY_SELECT`.
      DATA(sticky_text) = client->get_event_arg( ).
      selected = client->get_event_arg( 2 ).
      IF selected = abap_true.
        INSERT sticky_text INTO TABLE t_sticky.
      ELSE.
        DELETE t_sticky WHERE table_line = sticky_text.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " the shared mock /ProductCollection flattened to the bound columns, all 123 rows kept verbatim (see the model-flattening NOTE)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).


    " weightState is business logic (KG conversion + Success/Warning/Error
    " thresholds), not presentation - abap2UI5 is a thin frontend, so the
    " ObjectNumber state is computed here in the backend (the original does it in
    " its frontend Formatter.js, which a faithful port moves server-side).
    LOOP AT t_products REFERENCE INTO DATA(product).
      DATA(weight_kg) = product->weightmeasure.
      IF product->weightunit = `G`.
        weight_kg = weight_kg / 1000.
      ENDIF.
      product->weight_state = COND #( WHEN weight_kg < 0 THEN `None`
                                         WHEN weight_kg < 1 THEN `Success`
                                         WHEN weight_kg < 5 THEN `Warning`
                                         ELSE `Error` ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
