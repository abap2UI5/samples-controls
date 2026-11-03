" @keywords illustratedmessage illustrated message sap.m illustratedmessageinpagetnt simpleform label columnelementdata select item text button
" @summary The available properties of the IllustratedMessage are configurable in this sample. The available illustrations are from the 'tnt' illustration set.
" @origin sap.m.sample.IllustratedMessageInPageTNT - https://sdk.openui5.org/entity/sap.m.IllustratedMessage/sample/sap.m.sample.IllustratedMessageInPageTNT (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_636 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.

    DATA sizetypes TYPE ty_t_item.
    DATA typetypes TYPE ty_t_item.
    DATA sselectedsize TYPE string.
    DATA sselectedtype TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_636 IMPLEMENTATION.

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

                )->ele( `Label`
                    )->a( n = `text` v = `Illustration Size`

                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `4`
                            )->a( n = `cellsLarge` v = `-1`

                    )->end(
                )->end(

                " original onSelectSize - selectedKey two-way bound instead of the change handler
                )->ele( `Select`
                    )->a( n = `selectedKey` v = client->_bind( sselectedsize )
                    )->a( n = `items`       v = client->_bind( sizetypes )

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{KEY}`
                        )->a( n = `text` v = `{TEXT}`
                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `8`
                            )->a( n = `cellsLarge` v = `-1`

                    )->end(
                )->end(

                )->ele( `Text`
                    )->a( n = `text`      v = |\{= ${ client->_bind( sselectedsize ) } === 'Auto' ? | &&
                                              |'IllustratedMessage will choose its size automatically according to its parent container width.' : | &&
                                              |'Forced State. IllustratedMessage will keep its size even if the parent container width is changed.'\}|
                    )->a( n = `textAlign` v = `Center`

                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `12`
                            )->a( n = `cellsLarge` v = `12`

                    )->end(
                )->end(

                )->ele( `Label`
                    )->a( n = `text` v = `Illustration Type`

                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `4`
                            )->a( n = `cellsLarge` v = `-1`

                    )->end(
                )->end(

                " original onSelectType - selectedKey two-way bound instead of the change handler
                )->ele( `Select`
                    )->a( n = `selectedKey` v = client->_bind( sselectedtype )
                    )->a( n = `items`       v = client->_bind( typetypes )

                    )->tag( n = `Item` ns = `core`
                        )->a( n = `key`  v = `{KEY}`
                        )->a( n = `text` v = `{TEXT}`
                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `8`
                            )->a( n = `cellsLarge` v = `-1`

                    )->end(
                )->end(
            )->end(

            " the tnt illustration set is registered by the original Component (IllustrationPool) - see the sidecar
            )->ele( `IllustratedMessage`
                )->a( n = `title`            v = `Sample Title`
                )->a( n = `description`      v = `Sample Description`
                )->a( n = `illustrationSize` v = client->_bind( sselectedsize )
                )->a( n = `illustrationType` v = client->_bind( sselectedtype )

                )->ele( `additionalContent`
                    )->tag( `Button`
                        )->a( n = `text` v = `Action (optional)` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    DATA temp1 TYPE z2ui5_cl_smpc_app_636=>ty_t_item.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 TYPE string_table.
    DATA tnt_keys LIKE temp3.
    DATA tnt_key LIKE LINE OF tnt_keys.
      DATA temp5 TYPE z2ui5_cl_smpc_app_636=>ty_s_item.
    FIELD-SYMBOLS <temp6> LIKE LINE OF sizetypes.
    DATA temp7 LIKE sy-tabix.
    FIELD-SYMBOLS <temp8> LIKE LINE OF typetypes.
    DATA temp9 LIKE sy-tabix.
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

    " original _populateIllustrationTypes: every key of sap.tnt.IllustratedMessageType, in declaration order
    
    CLEAR temp3.
    INSERT `Avatar` INTO TABLE temp3.
    INSERT `Calculator` INTO TABLE temp3.
    INSERT `ChartArea` INTO TABLE temp3.
    INSERT `ChartArea2` INTO TABLE temp3.
    INSERT `ChartBar` INTO TABLE temp3.
    INSERT `ChartBPMNFlow` INTO TABLE temp3.
    INSERT `ChartBullet` INTO TABLE temp3.
    INSERT `ChartDoughnut` INTO TABLE temp3.
    INSERT `ChartFlow` INTO TABLE temp3.
    INSERT `ChartGantt` INTO TABLE temp3.
    INSERT `ChartOrg` INTO TABLE temp3.
    INSERT `ChartPie` INTO TABLE temp3.
    INSERT `CodePlaceholder` INTO TABLE temp3.
    INSERT `Company` INTO TABLE temp3.
    INSERT `Compass` INTO TABLE temp3.
    INSERT `Components` INTO TABLE temp3.
    INSERT `Dialog` INTO TABLE temp3.
    INSERT `EmptyContentPane` INTO TABLE temp3.
    INSERT `ExternalLink` INTO TABLE temp3.
    INSERT `FaceID` INTO TABLE temp3.
    INSERT `Fingerprint` INTO TABLE temp3.
    INSERT `Handshake` INTO TABLE temp3.
    INSERT `Help` INTO TABLE temp3.
    INSERT `Lock` INTO TABLE temp3.
    INSERT `Mission` INTO TABLE temp3.
    INSERT `MissionFailed` INTO TABLE temp3.
    INSERT `NoApplications` INTO TABLE temp3.
    INSERT `NoFlows` INTO TABLE temp3.
    INSERT `NoUsers` INTO TABLE temp3.
    INSERT `Radar` INTO TABLE temp3.
    INSERT `RoadMap` INTO TABLE temp3.
    INSERT `Secrets` INTO TABLE temp3.
    INSERT `Services` INTO TABLE temp3.
    INSERT `SessionExpired` INTO TABLE temp3.
    INSERT `SessionExpiring` INTO TABLE temp3.
    INSERT `Settings` INTO TABLE temp3.
    INSERT `Success` INTO TABLE temp3.
    INSERT `SuccessfulAuth` INTO TABLE temp3.
    INSERT `Systems` INTO TABLE temp3.
    INSERT `Teams` INTO TABLE temp3.
    INSERT `Tools` INTO TABLE temp3.
    INSERT `Tutorials` INTO TABLE temp3.
    INSERT `UnableToLoad` INTO TABLE temp3.
    INSERT `Unlock` INTO TABLE temp3.
    INSERT `UnsuccessfulAuth` INTO TABLE temp3.
    INSERT `User2` INTO TABLE temp3.
    
    tnt_keys = temp3.

    
    LOOP AT tnt_keys INTO tnt_key.
      
      CLEAR temp5.
      temp5-key = |tnt-{ tnt_key }|.
      temp5-text = tnt_key.
      INSERT temp5 INTO TABLE typetypes.
    ENDLOOP.

    
    
    temp7 = sy-tabix.
    READ TABLE sizetypes INDEX 1 ASSIGNING <temp6>.
    sy-tabix = temp7.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    sselectedsize = <temp6>-key.
    
    
    temp9 = sy-tabix.
    READ TABLE typetypes INDEX 1 ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    sselectedtype = <temp8>-key.

  ENDMETHOD.

ENDCLASS.
