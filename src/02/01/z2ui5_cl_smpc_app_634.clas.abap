" @keywords illustratedmessage illustrated message sap.m illustratedmessageinpage simpleform label columnelementdata switch text select item
" @summary The available illustrations are from the default ('sapIllus') illustration set.
" @origin sap.m.sample.IllustratedMessageInPage - https://sdk.openui5.org/entity/sap.m.IllustratedMessage/sample/sap.m.sample.IllustratedMessageInPage (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_634 DEFINITION PUBLIC.

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
    DATA sselectedevs TYPE abap_bool.
    DATA sselectedtype TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_634 IMPLEMENTATION.

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
                )->a( n = `width`    v = `450px`

                )->ele( `Label`
                    )->a( n = `text` v = `Enable Vertical Responsiveness`

                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `8`
                            )->a( n = `cellsLarge` v = `-1`

                    )->end(
                )->end(

                " original onSwitchEVS - the state is already two-way bound, so the change handler is dropped
                )->ele( `Switch`
                    )->a( n = `state` v = client->_bind( sselectedevs )

                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `4`
                            )->a( n = `cellsLarge` v = `-1`

                    )->end(
                )->end(

                )->ele( `Text`
                    )->a( n = `text`      v = |\{= ${ client->_bind( sselectedsize ) } === 'Auto' && ${ client->_bind( sselectedevs ) } ? | &&
                                              |'IllustratedMessage will choose its size automatically according to its parent container height.' : | &&
                                              |'Forced State. IllustratedMessage will keep its size even if the parent container height is changed.'\}|
                    )->a( n = `textAlign` v = `Center`

                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `12`
                            )->a( n = `cellsLarge` v = `12`

                    )->end(
                )->end(

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

            )->ele( `IllustratedMessage`
                )->a( n = `id`                           v = `im`
                )->a( n = `illustrationSize`             v = client->_bind( sselectedsize )
                )->a( n = `illustrationType`             v = client->_bind( sselectedtype )
                )->a( n = `enableVerticalResponsiveness` v = client->_bind( sselectedevs )

                )->ele( `additionalContent`
                    )->tag( `Button`
                        )->a( n = `text` v = `Action (optional)`
                    )->ele( `MenuButton`
                        )->a( n = `text` v = `File`

                        )->ele( `menu`
                            )->ele( `Menu`
                                )->ele( `MenuItem`
                                    )->a( n = `text` v = `Edit`
                                    )->a( n = `icon` v = `sap-icon://edit`

                                    )->ele( `customData`
                                        )->tag( n = `CustomData` ns = `core`
                                            )->a( n = `key`   v = `target`
                                            )->a( n = `value` v = `p1`

                                    )->end(
                                )->end(

                                )->tag( `MenuItem`
                                    )->a( n = `text` v = `Save`
                                    )->a( n = `icon` v = `sap-icon://save`
                                )->tag( `MenuItem`
                                    )->a( n = `text` v = `Open`
                                    )->a( n = `icon` v = `sap-icon://open-folder` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    DATA temp1 TYPE z2ui5_cl_smpc_app_634=>ty_t_item.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 TYPE z2ui5_cl_smpc_app_634=>ty_t_item.
    DATA temp4 LIKE LINE OF temp3.
    FIELD-SYMBOLS <temp5> LIKE LINE OF sizetypes.
    DATA temp6 LIKE sy-tabix.
    FIELD-SYMBOLS <temp7> LIKE LINE OF typetypes.
    DATA temp8 LIKE sy-tabix.
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

    
    CLEAR temp3.
    
    temp4-key = `sapIllus-Achievement`.
    temp4-text = `Achievement`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-AddDimensions`.
    temp4-text = `AddDimensions`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-AddPeopleToCalendar`.
    temp4-text = `AddPeopleToCalendar`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-AddingColumns`.
    temp4-text = `AddingColumns`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-BeforeSearch`.
    temp4-text = `BeforeSearch`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-DragFilesToUpload`.
    temp4-text = `DragFilesToUpload`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-EmptyPlanningCalendar`.
    temp4-text = `EmptyPlanningCalendar`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-FilteringColumns`.
    temp4-text = `FilteringColumns`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-GroupingColumns`.
    temp4-text = `GroupingColumns`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-KeyTask`.
    temp4-text = `KeyTask`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-PageNotFound`.
    temp4-text = `PageNotFound`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-ResizingColumns`.
    temp4-text = `ResizingColumns`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NewMail`.
    temp4-text = `NewMail`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoColumnsSet`.
    temp4-text = `NoColumnsSet`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoChartData`.
    temp4-text = `NoChartData`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoSearchResults`.
    temp4-text = `NoSearchResults`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoNotifications`.
    temp4-text = `NoNotifications`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoFilterResults`.
    temp4-text = `NoFilterResults`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoMail`.
    temp4-text = `NoMail`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoData`.
    temp4-text = `NoData`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoActivities`.
    temp4-text = `NoActivities`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoEntries`.
    temp4-text = `NoEntries`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoTasks`.
    temp4-text = `NoTasks`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-NoSavedItems`.
    temp4-text = `NoSavedItems`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-ReceiveAppreciation`.
    temp4-text = `ReceiveAppreciation`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-UnableToLoad`.
    temp4-text = `UnableToLoad`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-UnableToLoadImage`.
    temp4-text = `UnableToLoadImage`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-UploadToCloud`.
    temp4-text = `UploadToCloud`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-UnableToUpload`.
    temp4-text = `UnableToUpload`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-UserHasSignedUp`.
    temp4-text = `UserHasSignedUp`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-SignOut`.
    temp4-text = `SignOut`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = `sapIllus-SortingColumns`.
    temp4-text = `SortingColumns`.
    INSERT temp4 INTO TABLE temp3.
    typetypes = temp3.

    
    
    temp6 = sy-tabix.
    READ TABLE sizetypes INDEX 1 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    sselectedsize = <temp5>-key.
    
    
    temp8 = sy-tabix.
    READ TABLE typetypes INDEX 1 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    sselectedtype = <temp7>-key.

  ENDMETHOD.

ENDCLASS.
