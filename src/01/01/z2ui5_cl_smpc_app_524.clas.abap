" @keywords list sap.m listdeletion standardlistitem
" @summary Setting 'Delete' mode on a List means you can trigger the deletion of single items with a single press. The application has to decide if an additional confirmation is required.
" @origin sap.m.sample.ListDeletion - https://sdk.openui5.org/entity/sap.m.List/sample/sap.m.sample.ListDeletion (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_524 DEFINITION PUBLIC.

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


CLASS z2ui5_cl_smpc_app_524 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `List`
            )->a( n = `id`                  v = `list`
            )->a( n = `mode`                v = `Delete`
            " handleDelete sends an OData remove for the row's path - here the row is
            " deleted from the bound table, which is the same disappearance
            )->a( n = `delete`              v = client->_event( val = `DELETE` arg = `${$parameters>/listItem}.getDescription()` )
            )->a( n = `enableBusyIndicator` v = `true`
            )->a( n = `headerText`          v = `Products`
            )->a( n = `growing`             v = `true`
            )->a( n = `items`               v = client->_bind( t_products )

            )->tag( `StandardListItem`
                )->a( n = `title`            v = `{NAME}`
                )->a( n = `description`      v = `{PRODUCTID}`
                )->a( n = `icon`             v = `{PRODUCTPICURL}`
                )->a( n = `iconDensityAware` v = `false`
                )->a( n = `iconInset`        v = `false` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `DELETE`.
      DATA(del_productid) = client->get_event_arg( ).
      DELETE t_products WHERE productid = del_productid.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " the mock server's ProductCollection - the backend the sample simulates
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
