" @keywords illustratedmessage illustrated message sap.m illustratedmessageinappcustom simpleform label select item text button
" @summary Shows how to import a Custom Illustration from an npm package into a UI5 application for usage with IllustratedMessage.
" @origin sap.m.sample.IllustratedMessageInAppCustom - https://sdk.openui5.org/entity/sap.m.IllustratedMessage/sample/sap.m.sample.IllustratedMessageInAppCustom (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_630 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

    DATA sizetypes TYPE ty_t_item.
    DATA sselectedsize TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_630 IMPLEMENTATION.

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
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:form` v = `sap.ui.layout.form`
        )->a( n = `height`     v = `100%`

        )->ele( `Page`
            )->ele( n = `SimpleForm` ns = `form`
                )->a( n = `editable` v = `true`
                )->a( n = `width`    v = `420px`

                )->tag( `Label`
                    )->a( n = `text` v = `Illustration Size:`

                " original onSelectSize - selectedKey two-way bound instead of the change handler
                )->ele( `Select`
                    )->a( n = `selectedKey` v = client->_bind( sselectedsize )
                    )->a( n = `items`       v = client->_bind( sizetypes )

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{KEY}`
                        )->a( n = `text` v = `{TEXT}`

                )->end(

                )->tag( `Text`
                    )->a( n = `text` v = |\{= ${ client->_bind( sselectedsize ) } === 'Auto' ? | &&
                                         |'IllustratedMessage will choose its size automatically according to its parent container width.' : | &&
                                         |'Forced State. IllustratedMessage will keep its size even if the parent container width is changed.'\}|

            )->end(

            " the Custom illustration set is registered by the original Component (IllustrationPool) - see the sidecar
            )->ele( `IllustratedMessage`
                )->a( n = `title`            v = `Sample Title`
                )->a( n = `description`      v = `Sample Description`
                )->a( n = `illustrationSize` v = client->_bind( sselectedsize )
                )->a( n = `illustrationType` v = `Custom-EmptyCart`

                )->ele( `additionalContent`
                    )->tag( `Button`
                        )->a( n = `text` v = `Action (optional)` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    sizetypes = VALUE #(
        ( key = `Auto`       text = `Auto` )
        ( key = `Base`       text = `Base` )
        ( key = `ExtraSmall` text = `ExtraSmall` )
        ( key = `Small`      text = `Small` )
        ( key = `Medium`     text = `Medium` )
        ( key = `Large`      text = `Large` ) ).

    sselectedsize = sizetypes[ 1 ]-key.

  ENDMETHOD.

ENDCLASS.
