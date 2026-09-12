" @keywords input sap.m inputgrouping verticallayout label item column columnlistitem
" @summary Items in the Input could be grouped by a property
" @origin sap.m.sample.InputGrouping - https://sdk.openui5.org/entity/sap.m.Input/sample/sap.m.sample.InputGrouping (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_507 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name         TYPE string,
        productid    TYPE string,
        suppliername TYPE string,
        price        TYPE p LENGTH 8 DECIMALS 2,
        currencycode TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products TYPE ty_t_product.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_507 IMPLEMENTATION.

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

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:l`    v = `sap.ui.layout`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( n = `VerticalLayout` ns = `l`
            )->a( n = `class` v = `sapUiContentPadding`
            )->a( n = `width` v = `100%`

            )->tag( `Label`
                )->a( n = `text`     v = `Input with grouped suggestions`
                )->a( n = `labelFor` v = `productInputWithList`
            )->ele( `Input`
                )->a( n = `id`              v = `productInputWithList`
                )->a( n = `placeholder`     v = `Enter product`
                )->a( n = `showSuggestion`  v = `true`
                )->a( n = `suggestionItems` v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'SUPPLIERNAME', group: true, ascending: false \} \}|

                )->ele( `suggestionItems`
                    )->tag( n = `Item` ns = `core`
                        )->a( n = `text` v = `{NAME}`

                )->end(
            )->end(

            )->tag( `Label`
                )->a( n = `text`     v = `Input with grouped tabular suggestions`
                )->a( n = `labelFor` v = `productInputWithTable`
            )->ele( `Input`
                )->a( n = `id`                           v = `productInputWithTable`
                )->a( n = `placeholder`                  v = `Enter product`
                )->a( n = `showSuggestion`               v = `true`
                )->a( n = `showTableSuggestionValueHelp` v = `false`
                )->a( n = `suggestionRows`               v = |\{ path: '{ client->_bind_path( t_products ) }', sorter: \{ path: 'SUPPLIERNAME', group: true, ascending: false \} \}|

                )->ele( `suggestionColumns`
                    )->ele( `Column`
                        )->a( n = `popinDisplay` v = `Inline`
                        )->a( n = `demandPopin`  v = `true`

                        )->tag( `Label`
                            )->a( n = `text` v = `Name`

                    )->end(

                    )->ele( `Column`
                        )->a( n = `hAlign`         v = `Center`
                        )->a( n = `popinDisplay`   v = `Inline`
                        )->a( n = `demandPopin`    v = `true`
                        )->a( n = `minScreenWidth` v = `Tablet`

                        )->tag( `Label`
                            )->a( n = `text` v = `Product ID`

                    )->end(

                    )->ele( `Column`
                        )->a( n = `hAlign`         v = `Center`
                        )->a( n = `popinDisplay`   v = `Inline`
                        )->a( n = `minScreenWidth` v = `Tablet`

                        )->tag( `Label`
                            )->a( n = `text` v = `Supplier Name`

                    )->end(

                    )->ele( `Column`
                        )->a( n = `hAlign`       v = `End`
                        )->a( n = `popinDisplay` v = `Inline`
                        )->a( n = `demandPopin`  v = `true`

                        )->tag( `Label`
                            )->a( n = `text` v = `Price`

                    )->end(
                )->end(

                )->ele( `suggestionRows`
                    )->ele( `ColumnListItem`
                        )->tag( `Label`
                            )->a( n = `text` v = `{NAME}`
                        )->tag( `Label`
                            )->a( n = `text` v = `{PRODUCTID}`
                        )->tag( `Label`
                            )->a( n = `text` v = `{SUPPLIERNAME}`
                        )->tag( `Label`
                            )->a( n = `text` v = |\{ parts:[\{path:'PRICE'\}, \{path:'CURRENCYCODE'\}], type: 'sap.ui.model.type.Currency', formatOptions: \{showMeasure: true\} \}| ).

    client->view_display( view->stringify( ) ).
    " onInit: oModel.setSizeLimit(100000) - "the default limit of the model is set
    " to 100. We want to show all the entries." Without it the bound suggestionItems
    " and suggestionRows stop at 100 of the 123 products, and the descending
    " SupplierName sorter makes the rows cut whole supplier groups
    client->follow_up_action( val   = client->cs_event-set_size_limit
                              t_arg = VALUE #( ( `100000` ) ( client->cs_view-main ) ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection of ui5/mock/products.json (the bound fields);
    " the original raises the model's size limit so every row is offered
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
