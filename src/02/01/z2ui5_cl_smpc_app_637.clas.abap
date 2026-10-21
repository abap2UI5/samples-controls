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
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

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

    sizetypes = VALUE #(
        ( key = `Auto`       text = `Auto` )
        ( key = `Base`       text = `Base` )
        ( key = `ExtraSmall` text = `ExtraSmall` )
        ( key = `Small`      text = `Small` )
        ( key = `Medium`     text = `Medium` )
        ( key = `Large`      text = `Large` ) ).

    " original onInit: every value of sap.m.IllustratedMessageType, in declaration order, without its sapIllus- prefix
    DATA(m_types) = VALUE string_table(
        ( `BeforeSearch` )
        ( `NoActivities` )
        ( `NoData` )
        ( `NoMail` )
        ( `NoMail_v1` )
        ( `NoEntries` )
        ( `NoNotifications` )
        ( `NoSavedItems` )
        ( `NoSavedItems_v1` )
        ( `NoSearchResults` )
        ( `NoTasks` )
        ( `NoTasks_v1` )
        ( `NoDimensionsSet` )
        ( `NoColumnsSet` )
        ( `UnableToLoad` )
        ( `UnableToLoadImage` )
        ( `UnableToUpload` )
        ( `UploadToCloud` )
        ( `AddColumn` )
        ( `AddPeople` )
        ( `AddDimensions` )
        ( `BalloonSky` )
        ( `Connection` )
        ( `EmptyCalendar` )
        ( `EmptyList` )
        ( `EmptyPlanningCalendar` )
        ( `ErrorScreen` )
        ( `FilterTable` )
        ( `GroupTable` )
        ( `NewMail` )
        ( `NoFilterResults` )
        ( `PageNotFound` )
        ( `ReloadScreen` )
        ( `ResizeColumn` )
        ( `SearchEarth` )
        ( `SearchFolder` )
        ( `SignOut` )
        ( `SimpleBalloon` )
        ( `SimpleBell` )
        ( `SimpleCalendar` )
        ( `SimpleCheckMark` )
        ( `SimpleConnection` )
        ( `SimpleEmptyDoc` )
        ( `SimpleEmptyList` )
        ( `SimpleError` )
        ( `SimpleMagnifier` )
        ( `SimpleMail` )
        ( `SimpleNoSavedItems` )
        ( `SimpleNotFoundMagnifier` )
        ( `SimpleReload` )
        ( `SimpleTask` )
        ( `SleepingBell` )
        ( `SortColumn` )
        ( `SuccessBalloon` )
        ( `SuccessCheckMark` )
        ( `SuccessHighFive` )
        ( `SuccessScreen` )
        ( `Survey` )
        ( `Tent` )
        ( `NoChartData` )
        ( `AddingColumns` )
        ( `AddPeopleToCalendar` )
        ( `FilteringColumns` )
        ( `GroupingColumns` )
        ( `ResizingColumns` )
        ( `SortingColumns` )
        ( `ReceiveAppreciation` )
        ( `DragFilesToUpload` )
        ( `UserHasSignedUp` )
        ( `Achievement` )
        ( `KeyTask` )
        ( `UploadCollection` ) ).

    LOOP AT m_types INTO DATA(m_type).
      INSERT VALUE #( key  = |sap-illustration://{ m_type }|
                      text = |sap-illustration://{ m_type }| ) INTO TABLE typetypes.
    ENDLOOP.

    " ... then every value of sap.tnt.IllustratedMessageType, without its tnt- prefix
    DATA(tnt_types) = VALUE string_table(
        ( `Avatar` )
        ( `Calculator` )
        ( `ChartArea` )
        ( `ChartArea2` )
        ( `ChartBar` )
        ( `ChartBPMNFlow` )
        ( `ChartBullet` )
        ( `ChartDoughnut` )
        ( `ChartFlow` )
        ( `ChartGantt` )
        ( `ChartOrg` )
        ( `ChartPie` )
        ( `CodePlaceholder` )
        ( `Company` )
        ( `Compass` )
        ( `Components` )
        ( `Dialog` )
        ( `EmptyContentPane` )
        ( `ExternalLink` )
        ( `FaceID` )
        ( `Fingerprint` )
        ( `Handshake` )
        ( `Help` )
        ( `Lock` )
        ( `Mission` )
        ( `MissionFailed` )
        ( `NoApplications` )
        ( `NoFlows` )
        ( `NoUsers` )
        ( `Radar` )
        ( `RoadMap` )
        ( `Secrets` )
        ( `Services` )
        ( `SessionExpired` )
        ( `SessionExpiring` )
        ( `Settings` )
        ( `Success` )
        ( `SuccessfulAuth` )
        ( `Systems` )
        ( `Teams` )
        ( `Tools` )
        ( `Tutorials` )
        ( `UnableToLoad` )
        ( `Unlock` )
        ( `UnsuccessfulAuth` )
        ( `User2` ) ).

    LOOP AT tnt_types INTO DATA(tnt_type).
      INSERT VALUE #( key  = |sap-illustration://tnt/{ tnt_type }|
                      text = |sap-illustration://tnt/{ tnt_type }| ) INTO TABLE typetypes.
    ENDLOOP.

    sselectedsize = sizetypes[ 1 ]-key.
    sselectedsrc  = typetypes[ 1 ]-key.

  ENDMETHOD.

ENDCLASS.
