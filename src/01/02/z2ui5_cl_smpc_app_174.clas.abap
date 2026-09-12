" @keywords table sap.ui.table rowhighlights overflowtoolbar title toolbarspacer label select item togglebutton rowsettings column
" @summary Shows how row highlights and alternating row colors can be used.
" @origin sap.ui.table.sample.RowHighlights - https://sdk.openui5.org/entity/sap.ui.table.Table/sample/sap.ui.table.sample.RowHighlights (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_174 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        status       TYPE string,
        statustext   TYPE string,
        name         TYPE string,
        productid    TYPE string,
        quantity     TYPE i,
        price        TYPE p LENGTH 13 DECIMALS 2,
        currencycode TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    " The original drives three Table properties imperatively from the toolbar
    " controllers (setSelectionMode / setAlternateRowColors / the highlight
    " rowSettingsTemplate toggle). abap2UI5 is a thin frontend, so these become
    " two-way bound fields on the one default model, shared with the Select /
    " ToggleButtons - no round-trip (AGENTS section 5, app 128/007 precedent).
    DATA selection_mode       TYPE string.
    DATA show_highlights      TYPE abap_bool.
    DATA alternate_row_colors TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_174 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    " sap.ui.table grid Table (RowHighlights sample). The row highlight bar
    " reads the status the backend classifies per row in model_init. The
    " toolbar Select and ToggleButtons two-way bind the selection mode, the
    " alternate row colors and the highlight-visibility flag directly.
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
                    )->a( n = `id`                 v = `table`
                    )->a( n = `rows`               v = client->_bind( t_products )
                    )->a( n = `selectionMode`      v = client->_bind( selection_mode )
                    )->a( n = `alternateRowColors` v = client->_bind( alternate_row_colors )
                    )->a( n = `ariaLabelledBy`     v = `title`

                    )->ele( `extension`
                        )->ele( n = `OverflowToolbar` ns = `m`
                            )->a( n = `style` v = `Clear`
                            )->tag( n = `Title` ns = `m`
                                )->a( n = `id`   v = `title`
                                )->a( n = `text` v = `Products`
                            )->tag( n = `ToolbarSpacer` ns = `m`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `SelectionMode:`
                            )->ele( n = `Select` ns = `m`
                                )->a( n = `id`          v = `select`
                                )->a( n = `selectedKey` v = client->_bind( selection_mode )
                                )->ele( n = `items` ns = `m`
                                    )->tag( n = `Item` ns = `core`
                                        )->a( n = `key`  v = `MultiToggle`
                                        )->a( n = `text` v = `MultiToggle`
                                    )->tag( n = `Item` ns = `core`
                                        )->a( n = `key`  v = `Single`
                                        )->a( n = `text` v = `Single`
                                    )->tag( n = `Item` ns = `core`
                                        )->a( n = `key`  v = `None`
                                        )->a( n = `text` v = `None`

                                )->end(
                            )->end(
                            )->tag( n = `ToggleButton` ns = `m`
                                )->a( n = `text`    v = `Toggle Highlights`
                                )->a( n = `pressed` v = client->_bind( show_highlights )
                            )->tag( n = `ToggleButton` ns = `m`
                                )->a( n = `text`    v = `Toggle Alternate Row Colors`
                                )->a( n = `pressed` v = client->_bind( alternate_row_colors )

                        )->end(
                    )->end(

                    )->ele( `rowSettingsTemplate`
                        )->tag( `RowSettings`
                            )->a( n = `highlight`     v = |\{= ${ client->_bind( show_highlights ) } ? $\{STATUS\} : 'None' \}|
                            )->a( n = `highlightText` v = `{STATUSTEXT}`

                    )->end(

                    )->ele( `columns`
                        )->ele( `Column`
                            )->a( n = `sortProperty`   v = `STATUS`
                            )->a( n = `filterProperty` v = `STATUS`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Status`
                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{STATUS}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(

                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Name`
                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{NAME}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(

                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Product Id`
                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{PRODUCTID}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(

                        )->ele( `Column`
                            )->a( n = `hAlign` v = `End`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Quantity`
                            )->ele( `template`
                                )->tag( n = `Text` ns = `m`
                                    )->a( n = `text`     v = `{QUANTITY}`
                                    )->a( n = `wrapping` v = `false`

                            )->end(
                        )->end(

                        )->ele( `Column`
                            )->tag( n = `Label` ns = `m`
                                )->a( n = `text` v = `Price`
                            )->ele( `template`
                                )->tag( n = `Currency` ns = `u`
                                    )->a( n = `value`    v = `{PRICE}`
                                    )->a( n = `currency` v = `{CURRENCYCODE}`

                            )->end(
                        )->end(
                    )->end(
                )->end(
            )->end(
        )->end(
    )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " initial toolbar state - the original starts with MultiToggle selection,
    " highlights on (ToggleButton pressed=true) and alternate colors off
    selection_mode       = `MultiToggle`.
    show_highlights      = abap_true.
    alternate_row_colors = abap_false.

    " the shared 123-row demo ProductCollection (sap/ui/demo/mock/products.json)
    " projected onto the columns the sample binds (Name, ProductId, Quantity,
    " Price, CurrencyCode); Price is packed for the numeric u:Currency value
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

    " classify each row exactly as the sample controller does: the first five
    " rows carry fixed highlight states, the rest are derived from the Price
    " thresholds (thin-frontend - the original computes this in the controller)
    LOOP AT t_products ASSIGNING FIELD-SYMBOL(<product>).
      CASE sy-tabix.
        WHEN 1.
          <product>-status = `Success`.
        WHEN 2.
          <product>-status = `Warning`.
        WHEN 3.
          <product>-status = `Error`.
        WHEN 4.
          <product>-status = `Information`.
        WHEN 5.
          <product>-status = `None`.
        WHEN OTHERS.
          IF <product>-price < 300.
            <product>-status     = `Success`.
            <product>-statustext = `Custom success highlight text`.
          ELSEIF <product>-price < 600.
            <product>-status     = `Warning`.
            <product>-statustext = `Custom warning highlight text`.
          ELSEIF <product>-price < 900.
            <product>-status     = `Error`.
            <product>-statustext = `Custom error highlight text`.
          ELSEIF <product>-price < 1200.
            <product>-status     = `Information`.
            <product>-statustext = `Custom information highlight text`.
          ELSEIF <product>-price < 1500.
            <product>-status     = `Indication01`.
            <product>-statustext = `Custom indication highlight text`.
          ELSE.
            <product>-status = `None`.
          ENDIF.
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
