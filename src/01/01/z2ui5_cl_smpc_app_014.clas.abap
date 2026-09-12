" @keywords customlistitem custom list item sap.m content hbox icon vbox link label dialog
" @summary With the Custom List Item you can add any kind of content to lists.
" @origin sap.m.sample.CustomListItem - https://sdk.openui5.org/entity/sap.m.CustomListItem/sample/sap.m.sample.CustomListItem (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_014 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        productid     TYPE string,
        name          TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS popup_display_image
      IMPORTING
        pic_url TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_014 IMPLEMENTATION.

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
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`

        )->ele( `List`
            )->a( n = `headerText` v = `Custom Content`
            )->a( n = `mode`       v = `Delete`
            )->a( n = `items`      v = client->_bind( t_products )

            )->ele( `CustomListItem`
                )->ele( `HBox`
                    )->tag( n = `Icon` ns = `core`
                        )->a( n = `size`  v = `2rem`
                        )->a( n = `src`   v = `sap-icon://attachment-photo`
                        )->a( n = `class` v = `sapUiSmallMarginBegin sapUiSmallMarginTopBottom`

                    )->ele( `VBox`
                        )->a( n = `class` v = `sapUiSmallMarginBegin sapUiSmallMarginTopBottom`

                        )->tag( `Link`
                            )->a( n = `text`   v = `{NAME}`
                            )->a( n = `target` v = `{PRODUCTPICURL}`
                            )->a( n = `press`  v = client->_event( val = `LINK_PRESS` arg = `${PRODUCTPICURL}` )
                        )->tag( `Label`
                            )->a( n = `text` v = `{PRODUCTID}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    IF client->get_event( ) = `LINK_PRESS`.
      popup_display_image( client->get_event_arg( ) ).
    ENDIF.

  ENDMETHOD.


  METHOD popup_display_image.

    " the controller-built Dialog (handlePress), rebuilt as a fragment shown via popup_display
    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `Dialog`
            )->tag( `Image`
                )->a( n = `src` t = pic_url

            )->ele( `beginButton`
                )->tag( `Button`
                    )->a( n = `text`  v = `Close`
                    )->a( n = `press` v = client->follow_up_action( client->cs_event-popup_close ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " mock /ProductCollection flattened to the three bound columns (ProductId, Name, ProductPicUrl)
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
