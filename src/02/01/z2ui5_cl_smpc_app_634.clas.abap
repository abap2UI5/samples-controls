CLASS z2ui5_cl_smpc_app_634 DEFINITION PUBLIC.

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

    sizetypes = VALUE #(
        ( key = `Auto`       text = `Auto` )
        ( key = `Base`       text = `Base` )
        ( key = `ExtraSmall` text = `ExtraSmall` )
        ( key = `Small`      text = `Small` )
        ( key = `Medium`     text = `Medium` )
        ( key = `Large`      text = `Large` ) ).

    typetypes = VALUE #(
        ( key = `sapIllus-Achievement`           text = `Achievement` )
        ( key = `sapIllus-AddDimensions`         text = `AddDimensions` )
        ( key = `sapIllus-AddPeopleToCalendar`   text = `AddPeopleToCalendar` )
        ( key = `sapIllus-AddingColumns`         text = `AddingColumns` )
        ( key = `sapIllus-BeforeSearch`          text = `BeforeSearch` )
        ( key = `sapIllus-DragFilesToUpload`     text = `DragFilesToUpload` )
        ( key = `sapIllus-EmptyPlanningCalendar` text = `EmptyPlanningCalendar` )
        ( key = `sapIllus-FilteringColumns`      text = `FilteringColumns` )
        ( key = `sapIllus-GroupingColumns`       text = `GroupingColumns` )
        ( key = `sapIllus-KeyTask`               text = `KeyTask` )
        ( key = `sapIllus-PageNotFound`          text = `PageNotFound` )
        ( key = `sapIllus-ResizingColumns`       text = `ResizingColumns` )
        ( key = `sapIllus-NewMail`               text = `NewMail` )
        ( key = `sapIllus-NoColumnsSet`          text = `NoColumnsSet` )
        ( key = `sapIllus-NoChartData`           text = `NoChartData` )
        ( key = `sapIllus-NoSearchResults`       text = `NoSearchResults` )
        ( key = `sapIllus-NoNotifications`       text = `NoNotifications` )
        ( key = `sapIllus-NoFilterResults`       text = `NoFilterResults` )
        ( key = `sapIllus-NoMail`                text = `NoMail` )
        ( key = `sapIllus-NoData`                text = `NoData` )
        ( key = `sapIllus-NoActivities`          text = `NoActivities` )
        ( key = `sapIllus-NoEntries`             text = `NoEntries` )
        ( key = `sapIllus-NoTasks`               text = `NoTasks` )
        ( key = `sapIllus-NoSavedItems`          text = `NoSavedItems` )
        ( key = `sapIllus-ReceiveAppreciation`   text = `ReceiveAppreciation` )
        ( key = `sapIllus-UnableToLoad`          text = `UnableToLoad` )
        ( key = `sapIllus-UnableToLoadImage`     text = `UnableToLoadImage` )
        ( key = `sapIllus-UploadToCloud`         text = `UploadToCloud` )
        ( key = `sapIllus-UnableToUpload`        text = `UnableToUpload` )
        ( key = `sapIllus-UserHasSignedUp`       text = `UserHasSignedUp` )
        ( key = `sapIllus-SignOut`               text = `SignOut` )
        ( key = `sapIllus-SortingColumns`        text = `SortingColumns` ) ).

    sselectedsize = sizetypes[ 1 ]-key.
    sselectedtype = typetypes[ 1 ]-key.

  ENDMETHOD.

ENDCLASS.
