" @keywords list sap.m listloading overflowtoolbar title toolbarspacer button standardlistitem
" @summary You can use enableBusyIndicator property to display loading animation while the data is being loaded from server. By default, this property is true and busy indicator will be shown after 1000ms.
" @origin sap.m.sample.ListLoading - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListLoading (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_522 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    TYPES ty_t_product TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

    DATA t_products TYPE ty_t_product.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_522 IMPLEMENTATION.

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
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `List`
            )->a( n = `growing`             v = `true`
            )->a( n = `growingThreshold`    v = `10`
            )->a( n = `busyIndicatorDelay`  v = `500`
            )->a( n = `enableBusyIndicator` v = `true`
            )->a( n = `noDataText`          v = `No products available`
            )->a( n = `items`               v = client->_bind( t_products )

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`

                    )->tag( `Title`
                        )->a( n = `text`  v = `Products`
                        )->a( n = `level` v = `H2`
                    )->tag( `ToolbarSpacer`
                    " refreshDataFromBackend forces the OData model to reload - the same
                    " press re-reads the rows from the backend here
                    )->tag( `Button`
                        )->a( n = `icon`  v = `sap-icon://refresh`
                        )->a( n = `press` v = client->_event( `REFRESH` )

                )->end(
            )->end(

            )->tag( `StandardListItem`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `description`      v = `{PRODUCTID}`
                )->a( n = `icon`             v = `{PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `REFRESH`.
      model_init( ).
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " the mock server's ProductCollection - the backend the sample simulates
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
