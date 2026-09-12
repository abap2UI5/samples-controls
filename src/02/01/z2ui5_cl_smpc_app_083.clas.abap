" @keywords standardlistitem standard list item sap.m avatar index bindings
" @summary This list item offers a standardized user interface for list content with title, description, and avatar.
" @origin sap.m.sample.StandardListItemAvatar - https://sdk.openui5.org/entity/sap.m.StandardListItem/sample/sap.m.sample.StandardListItemAvatar (status: reviewed - read against the original, not run)
CLASS z2ui5_cl_smpc_app_083 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_083 IMPLEMENTATION.

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

    " the original binds the List element to /ProductCollection and the items address rows by index ({0/Name}..{3/Name})

    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `List`
            )->a( n = `id`         v = `ShortProductList`
            )->a( n = `headerText` v = `Products`
            )->a( n = `binding`    v = |\{{ client->_bind_path( t_products ) }\}|

            )->ele( `items`
                )->ele( `StandardListItem`
                    )->a( n = `title`            v = `{0/NAME}`
                    )->a( n = `description`      v = `{0/PRODUCTID}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `adaptTitleSize`   v = `false`
                    " the avatar aggregation (since UI5 1.98) and sap.m.Avatar (since 1.73) are kept 1:1 - needs UI5 >= 1.98
                    )->ele( `avatar`
                        )->tag( `Avatar`
                            )->a( n = `src`          v = `{0/PRODUCTPICURL}`
                            )->a( n = `displayShape` v = `Square`
                            )->a( n = `imageFitType` v = `Cover`
                            )->a( n = `showBorder`   v = `true`

                    )->end(
                )->end(
                )->ele( `StandardListItem`
                    )->a( n = `title`          v = `{1/NAME}`
                    )->a( n = `description`    v = ``
                    )->a( n = `iconInset`      v = `false`
                    )->a( n = `adaptTitleSize` v = `false`
                    )->ele( `avatar`
                        )->tag( `Avatar`
                            )->a( n = `src`        v = `{1/PRODUCTPICURL}`
                            )->a( n = `showBorder` v = `true`

                    )->end(
                )->end(
                )->ele( `StandardListItem`
                    )->a( n = `title`            v = `{2/NAME}`
                    )->a( n = `description`      v = `{2/PRODUCTID}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `true`
                    )->a( n = `adaptTitleSize`   v = `false`
                    )->ele( `avatar`
                        )->tag( `Avatar`
                            )->a( n = `src`          v = `{2/PRODUCTPICURL}`
                            )->a( n = `displayShape` v = `Square`
                            )->a( n = `showBorder`   v = `true`

                    )->end(
                )->end(
                )->tag( `StandardListItem`
                    )->a( n = `title`            v = `{3/NAME}`
                    )->a( n = `icon`             v = `{3/PRODUCTPICURL}`
                    )->a( n = `iconDensityAware` v = `false`
                    )->a( n = `iconInset`        v = `false`
                    )->a( n = `adaptTitleSize`   v = `false`

            )->end(
        )->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " full mock /ProductCollection (sap/ui/demo/mock/products.json); the view addresses rows 0-3 by index, ProductPicUrl absolute
    t_products = VALUE #( FOR s_product IN z2ui5_cl_smpc_mock=>products( ) ( CORRESPONDING #( s_product ) ) ).

  ENDMETHOD.

ENDCLASS.
