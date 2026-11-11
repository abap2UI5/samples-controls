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
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.

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
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

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

    DATA temp1 TYPE z2ui5_cl_smpc_app_630=>ty_t_item.
    DATA temp2 LIKE LINE OF temp1.
    FIELD-SYMBOLS <temp3> LIKE LINE OF sizetypes.
    DATA temp4 LIKE sy-tabix.
    CLEAR temp1.
    
    temp2-key = `Auto`.
    temp2-text = `Auto`.
    INSERT temp2 INTO TABLE temp1.
    temp2-key = `Base`.
    temp2-text = `Base`.
    INSERT temp2 INTO TABLE temp1.
    temp2-key = `ExtraSmall`.
    temp2-text = `ExtraSmall`.
    INSERT temp2 INTO TABLE temp1.
    temp2-key = `Small`.
    temp2-text = `Small`.
    INSERT temp2 INTO TABLE temp1.
    temp2-key = `Medium`.
    temp2-text = `Medium`.
    INSERT temp2 INTO TABLE temp1.
    temp2-key = `Large`.
    temp2-text = `Large`.
    INSERT temp2 INTO TABLE temp1.
    sizetypes = temp1.

    
    
    temp4 = sy-tabix.
    READ TABLE sizetypes INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    sselectedsize = <temp3>-key.

  ENDMETHOD.

ENDCLASS.
