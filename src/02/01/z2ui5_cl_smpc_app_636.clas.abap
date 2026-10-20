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
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

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

    sizetypes = VALUE #(
        ( key = `Auto`       text = `Auto` )
        ( key = `Base`       text = `Base` )
        ( key = `ExtraSmall` text = `ExtraSmall` )
        ( key = `Small`      text = `Small` )
        ( key = `Medium`     text = `Medium` )
        ( key = `Large`      text = `Large` ) ).

    " original _populateIllustrationTypes: every key of sap.tnt.IllustratedMessageType, in declaration order
    DATA(tnt_keys) = VALUE string_table(
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

    LOOP AT tnt_keys INTO DATA(tnt_key).
      INSERT VALUE #( key = |tnt-{ tnt_key }| text = tnt_key ) INTO TABLE typetypes.
    ENDLOOP.

    sselectedsize = sizetypes[ 1 ]-key.
    sselectedtype = typetypes[ 1 ]-key.

  ENDMETHOD.

ENDCLASS.
