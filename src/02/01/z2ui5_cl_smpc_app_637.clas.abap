" @keywords illustratedmessage illustrated message sap.m illustratedmessageinpagewithuri simpleform label columnelementdata switch text select item
" @summary The available illustrations are from the default illustration set with the use of the 'src' property.
" @origin sap.m.sample.IllustratedMessageInPageWithURI - https://sdk.openui5.org/entity/sap.m.IllustratedMessage/sample/sap.m.sample.IllustratedMessageInPageWithURI (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_637 DEFINITION PUBLIC.

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
    DATA sselectedsrc TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_637 IMPLEMENTATION.

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
                                              |'IllustratedMessage chooses its size automatically according to its parent container height.' : | &&
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
                                              |'IllustratedMessage chooses its size automatically according to its parent container width.' : | &&
                                              |'Forced State. IllustratedMessage will keep its size even if the parent container width is changed.'\}|
                    )->a( n = `textAlign` v = `Center`

                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `12`
                            )->a( n = `cellsLarge` v = `12`

                    )->end(
                )->end(

                )->ele( `Label`
                    )->a( n = `text` v = `Illustration URI`

                    )->ele( `layoutData`
                        )->tag( n = `ColumnElementData` ns = `form`
                            )->a( n = `cellsSmall` v = `4`
                            )->a( n = `cellsLarge` v = `-1`

                    )->end(
                )->end(

                " original onSelectType - selectedKey two-way bound instead of the change handler
                )->ele( `Select`
                    )->a( n = `selectedKey` v = client->_bind( sselectedsrc )
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
                )->a( n = `title`                        v = `Sample Title`
                )->a( n = `description`                  v = `Sample Description`
                )->a( n = `illustrationSize`             v = client->_bind( sselectedsize )
                )->a( n = `src`                          v = client->_bind( sselectedsrc )
                )->a( n = `enableVerticalResponsiveness` v = client->_bind( sselectedevs )

                )->ele( `additionalContent`
                    )->tag( `Button`
                        )->a( n = `text` v = `Action (optional)` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    DATA temp1 TYPE z2ui5_cl_smpc_app_637=>ty_t_item.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 TYPE string_table.
    DATA m_types LIKE temp3.
    DATA m_type LIKE LINE OF m_types.
      DATA temp5 TYPE z2ui5_cl_smpc_app_637=>ty_s_item.
    DATA temp6 TYPE string_table.
    DATA tnt_types LIKE temp6.
    DATA tnt_type LIKE LINE OF tnt_types.
      DATA temp8 TYPE z2ui5_cl_smpc_app_637=>ty_s_item.
    FIELD-SYMBOLS <temp9> LIKE LINE OF sizetypes.
    DATA temp10 LIKE sy-tabix.
    FIELD-SYMBOLS <temp11> LIKE LINE OF typetypes.
    DATA temp12 LIKE sy-tabix.
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

    " original onInit: every value of sap.m.IllustratedMessageType, in declaration order, without its sapIllus- prefix
    
    CLEAR temp3.
    INSERT `BeforeSearch` INTO TABLE temp3.
    INSERT `NoActivities` INTO TABLE temp3.
    INSERT `NoData` INTO TABLE temp3.
    INSERT `NoMail` INTO TABLE temp3.
    INSERT `NoMail_v1` INTO TABLE temp3.
    INSERT `NoEntries` INTO TABLE temp3.
    INSERT `NoNotifications` INTO TABLE temp3.
    INSERT `NoSavedItems` INTO TABLE temp3.
    INSERT `NoSavedItems_v1` INTO TABLE temp3.
    INSERT `NoSearchResults` INTO TABLE temp3.
    INSERT `NoTasks` INTO TABLE temp3.
    INSERT `NoTasks_v1` INTO TABLE temp3.
    INSERT `NoDimensionsSet` INTO TABLE temp3.
    INSERT `NoColumnsSet` INTO TABLE temp3.
    INSERT `UnableToLoad` INTO TABLE temp3.
    INSERT `UnableToLoadImage` INTO TABLE temp3.
    INSERT `UnableToUpload` INTO TABLE temp3.
    INSERT `UploadToCloud` INTO TABLE temp3.
    INSERT `AddColumn` INTO TABLE temp3.
    INSERT `AddPeople` INTO TABLE temp3.
    INSERT `AddDimensions` INTO TABLE temp3.
    INSERT `BalloonSky` INTO TABLE temp3.
    INSERT `Connection` INTO TABLE temp3.
    INSERT `EmptyCalendar` INTO TABLE temp3.
    INSERT `EmptyList` INTO TABLE temp3.
    INSERT `EmptyPlanningCalendar` INTO TABLE temp3.
    INSERT `ErrorScreen` INTO TABLE temp3.
    INSERT `FilterTable` INTO TABLE temp3.
    INSERT `GroupTable` INTO TABLE temp3.
    INSERT `NewMail` INTO TABLE temp3.
    INSERT `NoFilterResults` INTO TABLE temp3.
    INSERT `PageNotFound` INTO TABLE temp3.
    INSERT `ReloadScreen` INTO TABLE temp3.
    INSERT `ResizeColumn` INTO TABLE temp3.
    INSERT `SearchEarth` INTO TABLE temp3.
    INSERT `SearchFolder` INTO TABLE temp3.
    INSERT `SignOut` INTO TABLE temp3.
    INSERT `SimpleBalloon` INTO TABLE temp3.
    INSERT `SimpleBell` INTO TABLE temp3.
    INSERT `SimpleCalendar` INTO TABLE temp3.
    INSERT `SimpleCheckMark` INTO TABLE temp3.
    INSERT `SimpleConnection` INTO TABLE temp3.
    INSERT `SimpleEmptyDoc` INTO TABLE temp3.
    INSERT `SimpleEmptyList` INTO TABLE temp3.
    INSERT `SimpleError` INTO TABLE temp3.
    INSERT `SimpleMagnifier` INTO TABLE temp3.
    INSERT `SimpleMail` INTO TABLE temp3.
    INSERT `SimpleNoSavedItems` INTO TABLE temp3.
    INSERT `SimpleNotFoundMagnifier` INTO TABLE temp3.
    INSERT `SimpleReload` INTO TABLE temp3.
    INSERT `SimpleTask` INTO TABLE temp3.
    INSERT `SleepingBell` INTO TABLE temp3.
    INSERT `SortColumn` INTO TABLE temp3.
    INSERT `SuccessBalloon` INTO TABLE temp3.
    INSERT `SuccessCheckMark` INTO TABLE temp3.
    INSERT `SuccessHighFive` INTO TABLE temp3.
    INSERT `SuccessScreen` INTO TABLE temp3.
    INSERT `Survey` INTO TABLE temp3.
    INSERT `Tent` INTO TABLE temp3.
    INSERT `NoChartData` INTO TABLE temp3.
    INSERT `AddingColumns` INTO TABLE temp3.
    INSERT `AddPeopleToCalendar` INTO TABLE temp3.
    INSERT `FilteringColumns` INTO TABLE temp3.
    INSERT `GroupingColumns` INTO TABLE temp3.
    INSERT `ResizingColumns` INTO TABLE temp3.
    INSERT `SortingColumns` INTO TABLE temp3.
    INSERT `ReceiveAppreciation` INTO TABLE temp3.
    INSERT `DragFilesToUpload` INTO TABLE temp3.
    INSERT `UserHasSignedUp` INTO TABLE temp3.
    INSERT `Achievement` INTO TABLE temp3.
    INSERT `KeyTask` INTO TABLE temp3.
    INSERT `UploadCollection` INTO TABLE temp3.
    
    m_types = temp3.

    
    LOOP AT m_types INTO m_type.
      
      CLEAR temp5.
      temp5-key = |sap-illustration://{ m_type }|.
      temp5-text = |sap-illustration://{ m_type }|.
      INSERT temp5 INTO TABLE typetypes.
    ENDLOOP.

    " ... then every value of sap.tnt.IllustratedMessageType, without its tnt- prefix
    
    CLEAR temp6.
    INSERT `Avatar` INTO TABLE temp6.
    INSERT `Calculator` INTO TABLE temp6.
    INSERT `ChartArea` INTO TABLE temp6.
    INSERT `ChartArea2` INTO TABLE temp6.
    INSERT `ChartBar` INTO TABLE temp6.
    INSERT `ChartBPMNFlow` INTO TABLE temp6.
    INSERT `ChartBullet` INTO TABLE temp6.
    INSERT `ChartDoughnut` INTO TABLE temp6.
    INSERT `ChartFlow` INTO TABLE temp6.
    INSERT `ChartGantt` INTO TABLE temp6.
    INSERT `ChartOrg` INTO TABLE temp6.
    INSERT `ChartPie` INTO TABLE temp6.
    INSERT `CodePlaceholder` INTO TABLE temp6.
    INSERT `Company` INTO TABLE temp6.
    INSERT `Compass` INTO TABLE temp6.
    INSERT `Components` INTO TABLE temp6.
    INSERT `Dialog` INTO TABLE temp6.
    INSERT `EmptyContentPane` INTO TABLE temp6.
    INSERT `ExternalLink` INTO TABLE temp6.
    INSERT `FaceID` INTO TABLE temp6.
    INSERT `Fingerprint` INTO TABLE temp6.
    INSERT `Handshake` INTO TABLE temp6.
    INSERT `Help` INTO TABLE temp6.
    INSERT `Lock` INTO TABLE temp6.
    INSERT `Mission` INTO TABLE temp6.
    INSERT `MissionFailed` INTO TABLE temp6.
    INSERT `NoApplications` INTO TABLE temp6.
    INSERT `NoFlows` INTO TABLE temp6.
    INSERT `NoUsers` INTO TABLE temp6.
    INSERT `Radar` INTO TABLE temp6.
    INSERT `RoadMap` INTO TABLE temp6.
    INSERT `Secrets` INTO TABLE temp6.
    INSERT `Services` INTO TABLE temp6.
    INSERT `SessionExpired` INTO TABLE temp6.
    INSERT `SessionExpiring` INTO TABLE temp6.
    INSERT `Settings` INTO TABLE temp6.
    INSERT `Success` INTO TABLE temp6.
    INSERT `SuccessfulAuth` INTO TABLE temp6.
    INSERT `Systems` INTO TABLE temp6.
    INSERT `Teams` INTO TABLE temp6.
    INSERT `Tools` INTO TABLE temp6.
    INSERT `Tutorials` INTO TABLE temp6.
    INSERT `UnableToLoad` INTO TABLE temp6.
    INSERT `Unlock` INTO TABLE temp6.
    INSERT `UnsuccessfulAuth` INTO TABLE temp6.
    INSERT `User2` INTO TABLE temp6.
    
    tnt_types = temp6.

    
    LOOP AT tnt_types INTO tnt_type.
      
      CLEAR temp8.
      temp8-key = |sap-illustration://tnt/{ tnt_type }|.
      temp8-text = |sap-illustration://tnt/{ tnt_type }|.
      INSERT temp8 INTO TABLE typetypes.
    ENDLOOP.

    
    
    temp10 = sy-tabix.
    READ TABLE sizetypes INDEX 1 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    sselectedsize = <temp9>-key.
    
    
    temp12 = sy-tabix.
    READ TABLE typetypes INDEX 1 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    sselectedsrc  = <temp11>-key.

  ENDMETHOD.

ENDCLASS.
