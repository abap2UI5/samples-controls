CLASS z2ui5_cl_smpc_app_655 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        id             TYPE string,
        filename       TYPE string,
        mediatype      TYPE string,
        imageurl       TYPE string,
        url            TYPE string,
        revision       TYPE string,
        status         TYPE string,
        filesize       TYPE i,
        lastmodifiedby TYPE string,
        lastmodified   TYPE string,
        documenttype   TYPE string,
        previewable    TYPE abap_bool,
        trustedsource  TYPE abap_bool,
        uploadstate    TYPE string,
        icon           TYPE string,
        filesize_units TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
    " the three arrays of documents.json, one per table
    DATA t_items          TYPE ty_t_item.
    DATA t_itemsinstance2 TYPE ty_t_item.
    DATA t_itemsinstance3 TYPE ty_t_item.
    " onSelectionChange: each table's Download button follows its selection
    DATA download_enabled  TYPE abap_bool.
    DATA download_enabled2 TYPE abap_bool.
    DATA download_enabled3 TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA remove_path TYPE string.
    DATA upload_no   TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS row_new
      IMPORTING
        filename      TYPE string
        mediatype     TYPE string
        filesize      TYPE i
      RETURNING
        VALUE(result) TYPE ty_s_item.
    METHODS row_index
      IMPORTING
        path          TYPE string
      RETURNING
        VALUE(result) TYPE i.
    METHODS row_derive
      CHANGING
        row TYPE ty_s_item.
    METHODS icon_for
      IMPORTING
        mediatype     TYPE string
        filename      TYPE string
      RETURNING
        VALUE(result) TYPE string.
    METHODS size_with_units
      IMPORTING
        size          TYPE i
      RETURNING
        VALUE(result) TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_655 IMPLEMENTATION.

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
        )->a( n = `xmlns`         v = `sap.m`
        )->a( n = `xmlns:mvc`     v = `sap.ui.core.mvc`
        )->a( n = `xmlns:f`       v = `sap.f`
        )->a( n = `xmlns:core`    v = `sap.ui.core`
        )->a( n = `xmlns:upload`  v = `sap.m.upload`
        )->a( n = `xmlns:plugins` v = `sap.m.plugins`
        )->a( n = `height`        v = `100%`
        )->a( n = `displayBlock`  v = `true`

        )->ele( n = `DynamicPage` ns = `f`
            )->a( n = `id` v = `page`

            )->ele( n = `content` ns = `f`
                )->ele( `VBox`
                    )->ele( `Table`
                        )->a( n = `id`              v = `table-uploadSet`
                        )->a( n = `sticky`          v = `ColumnHeaders,HeaderToolbar`
                        )->a( n = `width`           v = `auto`
                        )->a( n = `mode`            v = `MultiSelect`
                        )->a( n = `fixedLayout`     v = `false`
                        )->a( n = `inset`           v = `true`
                        )->a( n = `autoPopinMode`   v = `true`
                        )->a( n = `hiddenInPopin`   v = `None`
                        )->a( n = `items`           v = |\{ path: '{ client->_bind( val                = t_items
                                                                                    path               = abap_true
                                                                                    omit_initial_paths = VALUE #( ( `IMAGEURL` )
                                                                                                                  ( `UPLOADSTATE` ) ) ) }', templateShareable: false \}|
                        )->a( n = `selectionChange` v = client->_event( val   = `SELECTION`
                                                                        t_arg = VALUE #( ( `$event.oSource.getId()` )
                                                                                         ( `$event.oSource.getSelectedContexts().length` ) ) )

                        )->ele( `headerToolbar`
                            )->ele( `OverflowToolbar`
                                )->tag( `Title`
                                    )->a( n = `text`  v = |Documents (\{= ${ client->_bind( t_items ) }.length\})|
                                    )->a( n = `level` v = `H2`
                                )->tag( `ToolbarSpacer`

                                " onSearch filters the FIRST table whichever field is typed in
                                )->ele( `SearchField`
                                    )->a( n = `width`      v = `20%`
                                    )->a( n = `liveChange` v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                                         t_arg = VALUE #( ( `table-uploadSet` )
                                                                                                          ( `items` )
                                                                                                          ( `filter` )
                                                                                                          ( `FILENAME` )
                                                                                                          ( `Contains` )
                                                                                                          ( `${$source>/value}` ) ) )

                                    )->ele( `layoutData`
                                        )->tag( `OverflowToolbarLayoutData`
                                            )->a( n = `priority` v = `NeverOverflow`

                                    )->end(
                                )->end(
                                )->tag( `ToolbarSeparator`
                                )->tag( n = `ActionsPlaceholder` ns = `upload`
                                    )->a( n = `id`             v = `uploadButton`
                                    )->a( n = `placeholderFor` v = `UploadButtonPlaceholder`
                                )->tag( `Button`
                                    )->a( n = `id`      v = `downloadSelectedButton`
                                    )->a( n = `text`    v = `Download`
                                    )->a( n = `enabled` v = client->_bind( download_enabled )
                                    )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                      t_arg = VALUE #( ( `uploadSetPlugin` )
                                                                                                       ( `download` )
                                                                                                       ( `$controller.getView().byId('table-uploadSet').getSelectedContexts()[0]` )
                                                                                                       ( `true` ) ) )

                            )->end(
                        )->end(
                        )->ele( `dependents`
                            )->ele( n = `UploadSetwithTable` ns = `plugins`
                                )->a( n = `id`                     v = `uploadSetPlugin`
                                )->a( n = `uploadUrl`              v = `/uploadFiles`
                                )->a( n = `multiple`               v = `true`
                                )->a( n = `beforeUploadStarts`     v = client->_event( val    = `UPLOAD`
                                                                                       t_arg  = VALUE #( ( `${$parameters>/item}.getFileName()` )
                                                                                                         ( `${$parameters>/item}.getMediaType()` )
                                                                                                         ( `${$parameters>/item}.getFileObject().size` )
                                                                                                         ( `$event.oSource.data('itemsPath')` ) )
                                                                                       s_ctrl = VALUE #( check_prevent_default = abap_true
                                                                                                         check_queue_last      = abap_true ) )
                                )->a( n = `cloudFilePickerEnabled` v = `true`
                                )->a( n = `actions`                v = `uploadButton`

                                )->ele( n = `rowConfiguration` ns = `plugins`
                                    )->tag( n = `UploadItemConfiguration` ns = `upload`
                                        )->a( n = `fileNamePath`        v = `FILENAME`
                                        )->a( n = `mediaTypePath`       v = `MEDIATYPE`
                                        )->a( n = `urlPath`             v = `URL`
                                        )->a( n = `previewablePath`     v = `PREVIEWABLE`
                                        )->a( n = `fileSizePath`        v = `FILESIZE`
                                        )->a( n = `isTrustedSourcePath` v = `TRUSTEDSOURCE`

                                )->end(
                                )->ele( n = `customData` ns = `plugins`
                                    )->tag( n = `CustomData` ns = `core`
                                        )->a( n = `key`        v = `itemsPath`
                                        )->a( n = `value`      v = `items`
                                        )->a( n = `writeToDom` v = `false`

                                )->end(
                            )->end(
                        )->end(
                        )->ele( `columns`
                            )->ele( `Column`
                                )->a( n = `id`         v = `fileName`
                                )->a( n = `importance` v = `High`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Name`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `id`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `ID`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `revision`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Revision`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `status`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Status`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `fileSize`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Size`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `lastModified`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Last Modified`

                                )->end(
                            )->end(
                            )->tag( `Column`
                                )->a( n = `id`         v = `actionButton`
                                )->a( n = `importance` v = `High`

                        )->end(
                        )->ele( `items`
                            )->ele( `ColumnListItem`
                                )->a( n = `highlight` v = `{= ${UPLOADSTATE} === 'Complete' ? 'Indication05' : null }`

                                )->ele( `cells`
                                    )->ele( `HBox`
                                        )->tag( `Image`
                                            )->a( n = `src`     v = `{IMAGEURL}`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} !== undefined}`
                                        )->tag( n = `Icon` ns = `core`
                                            )->a( n = `src`     v = `{ICON}`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`

                                        )->ele( `VBox`
                                            )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                            )->tag( `Link`
                                                )->a( n = `text`  v = `{FILENAME}`
                                                )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                                t_arg = VALUE #( ( `uploadSetPlugin` )
                                                                                                                 ( `openFilePreview` )
                                                                                                                 ( `$event.oSource.getBindingContext()` ) ) )
                                                )->a( n = `class` v = `sapUiTinyMarginBottom`
                                            )->tag( `Text`
                                                )->a( n = `text` v = `{DOCUMENTTYPE}`

                                        )->end(
                                    )->end(
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{ID}`
                                    )->tag( `Link`
                                        )->a( n = `text` v = `{REVISION}`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{STATUS}`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{FILESIZE_UNITS}`

                                    )->ele( `VBox`
                                        )->tag( `Text`
                                            )->a( n = `text` v = `{LASTMODIFIEDBY}`
                                        )->tag( `Text`
                                            )->a( n = `class` v = `sapUiTinyMarginTop`
                                            )->a( n = `text`  v = `{LASTMODIFIED}`

                                    )->end(
                                    )->tag( `Button`
                                        )->a( n = `class` v = `sapUiTinyMarginBegin`
                                        )->a( n = `type`  v = `Transparent`
                                        )->a( n = `icon`  v = `sap-icon://decline`
                                        )->a( n = `press` v = client->_event( val   = `REMOVE_ROW`
                                                                              t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                                               ( `${FILENAME}` ) ) )

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                    )->ele( `Table`
                        )->a( n = `id`              v = `table-uploadSet-instance2`
                        )->a( n = `sticky`          v = `ColumnHeaders,HeaderToolbar`
                        )->a( n = `width`           v = `auto`
                        )->a( n = `mode`            v = `MultiSelect`
                        )->a( n = `fixedLayout`     v = `false`
                        )->a( n = `inset`           v = `true`
                        )->a( n = `autoPopinMode`   v = `true`
                        )->a( n = `hiddenInPopin`   v = `None`
                        )->a( n = `items`           v = |\{ path: '{ client->_bind( val                = t_itemsinstance2
                                                                                    path               = abap_true
                                                                                    omit_initial_paths = VALUE #( ( `IMAGEURL` )
                                                                                                                  ( `UPLOADSTATE` ) ) ) }', templateShareable: false \}|
                        )->a( n = `selectionChange` v = client->_event( val   = `SELECTION`
                                                                        t_arg = VALUE #( ( `$event.oSource.getId()` )
                                                                                         ( `$event.oSource.getSelectedContexts().length` ) ) )

                        )->ele( `headerToolbar`
                            )->ele( `OverflowToolbar`
                                )->tag( `Title`
                                    )->a( n = `text`  v = |Documents (\{= ${ client->_bind( t_itemsinstance2 ) }.length\})|
                                    )->a( n = `level` v = `H2`
                                )->tag( `ToolbarSpacer`

                                " onSearch filters the FIRST table whichever field is typed in
                                )->ele( `SearchField`
                                    )->a( n = `width`      v = `20%`
                                    )->a( n = `liveChange` v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                                         t_arg = VALUE #( ( `table-uploadSet` )
                                                                                                          ( `items` )
                                                                                                          ( `filter` )
                                                                                                          ( `FILENAME` )
                                                                                                          ( `Contains` )
                                                                                                          ( `${$source>/value}` ) ) )

                                    )->ele( `layoutData`
                                        )->tag( `OverflowToolbarLayoutData`
                                            )->a( n = `priority` v = `NeverOverflow`

                                    )->end(
                                )->end(
                                )->tag( `ToolbarSeparator`
                                )->tag( n = `ActionsPlaceholder` ns = `upload`
                                    )->a( n = `id`             v = `uploadButtonInstance2`
                                    )->a( n = `placeholderFor` v = `UploadButtonPlaceholder`
                                )->tag( `Button`
                                    )->a( n = `id`      v = `downloadSelectedButton-instance2`
                                    )->a( n = `text`    v = `Download`
                                    )->a( n = `enabled` v = client->_bind( download_enabled2 )
                                    )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                      t_arg = VALUE #( ( `uploadSetPlugin-instance2` )
                                                                                                       ( `download` )
                                                                                                       ( `$controller.getView().byId('table-uploadSet-instance2').getSelectedContexts()[0]` )
                                                                                                       ( `true` ) ) )

                            )->end(
                        )->end(
                        )->ele( `dependents`
                            )->ele( n = `UploadSetwithTable` ns = `plugins`
                                )->a( n = `id`                     v = `uploadSetPlugin-instance2`
                                )->a( n = `uploadUrl`              v = `/uploadFiles`
                                )->a( n = `multiple`               v = `true`
                                )->a( n = `beforeUploadStarts`     v = client->_event( val    = `UPLOAD`
                                                                                       t_arg  = VALUE #( ( `${$parameters>/item}.getFileName()` )
                                                                                                         ( `${$parameters>/item}.getMediaType()` )
                                                                                                         ( `${$parameters>/item}.getFileObject().size` )
                                                                                                         ( `$event.oSource.data('itemsPath')` ) )
                                                                                       s_ctrl = VALUE #( check_prevent_default = abap_true
                                                                                                         check_queue_last      = abap_true ) )
                                )->a( n = `cloudFilePickerEnabled` v = `true`
                                )->a( n = `actions`                v = `uploadButtonInstance2`

                                )->ele( n = `rowConfiguration` ns = `plugins`
                                    )->tag( n = `UploadItemConfiguration` ns = `upload`
                                        )->a( n = `fileNamePath`        v = `FILENAME`
                                        )->a( n = `mediaTypePath`       v = `MEDIATYPE`
                                        )->a( n = `urlPath`             v = `URL`
                                        )->a( n = `previewablePath`     v = `PREVIEWABLE`
                                        )->a( n = `fileSizePath`        v = `FILESIZE`
                                        )->a( n = `isTrustedSourcePath` v = `TRUSTEDSOURCE`

                                )->end(
                                )->ele( n = `customData` ns = `plugins`
                                    )->tag( n = `CustomData` ns = `core`
                                        )->a( n = `key`        v = `itemsPath`
                                        )->a( n = `value`      v = `items-instance2`
                                        )->a( n = `writeToDom` v = `false`

                                )->end(
                            )->end(
                        )->end(
                        )->ele( `columns`
                            )->ele( `Column`
                                )->a( n = `id`         v = `fileName-instance2`
                                )->a( n = `importance` v = `High`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Name`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `id-instance-2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `ID`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `revision-instance2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Revision`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `status-instance2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Status`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `fileSize-instance2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Size`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `lastModified-instance2`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Last Modified`

                                )->end(
                            )->end(
                            )->tag( `Column`
                                )->a( n = `id`         v = `actionButton-instance2`
                                )->a( n = `importance` v = `High`

                        )->end(
                        )->ele( `items`
                            )->ele( `ColumnListItem`
                                )->a( n = `highlight` v = `{= ${UPLOADSTATE} === 'Complete' ? 'Indication05' : null }`

                                )->ele( `cells`
                                    )->ele( `HBox`
                                        )->tag( `Image`
                                            )->a( n = `src`     v = `{IMAGEURL}`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} !== undefined}`
                                        )->tag( n = `Icon` ns = `core`
                                            )->a( n = `src`     v = `{ICON}`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`

                                        )->ele( `VBox`
                                            )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                            )->tag( `Link`
                                                )->a( n = `text`  v = `{FILENAME}`
                                                )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                                t_arg = VALUE #( ( `uploadSetPlugin-instance2` )
                                                                                                                 ( `openFilePreview` )
                                                                                                                 ( `$event.oSource.getBindingContext()` ) ) )
                                                )->a( n = `class` v = `sapUiTinyMarginBottom`
                                            )->tag( `Text`
                                                )->a( n = `text` v = `{DOCUMENTTYPE}`

                                        )->end(
                                    )->end(
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{ID}`
                                    )->tag( `Link`
                                        )->a( n = `text` v = `{REVISION}`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{STATUS}`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{FILESIZE_UNITS}`

                                    )->ele( `VBox`
                                        )->tag( `Text`
                                            )->a( n = `text` v = `{LASTMODIFIEDBY}`
                                        )->tag( `Text`
                                            )->a( n = `class` v = `sapUiTinyMarginTop`
                                            )->a( n = `text`  v = `{LASTMODIFIED}`

                                    )->end(
                                    )->tag( `Button`
                                        )->a( n = `class` v = `sapUiTinyMarginBegin`
                                        )->a( n = `type`  v = `Transparent`
                                        )->a( n = `icon`  v = `sap-icon://decline`
                                        )->a( n = `press` v = client->_event( val   = `REMOVE_ROW`
                                                                              t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                                               ( `${FILENAME}` ) ) )

                                )->end(
                            )->end(
                        )->end(
                    )->end(
                    )->ele( `Table`
                        )->a( n = `id`              v = `table-uploadSet-instance3`
                        )->a( n = `sticky`          v = `ColumnHeaders,HeaderToolbar`
                        )->a( n = `width`           v = `auto`
                        )->a( n = `mode`            v = `MultiSelect`
                        )->a( n = `fixedLayout`     v = `false`
                        )->a( n = `inset`           v = `true`
                        )->a( n = `autoPopinMode`   v = `true`
                        )->a( n = `hiddenInPopin`   v = `None`
                        )->a( n = `items`           v = |\{ path: '{ client->_bind( val                = t_itemsinstance3
                                                                                    path               = abap_true
                                                                                    omit_initial_paths = VALUE #( ( `IMAGEURL` )
                                                                                                                  ( `UPLOADSTATE` ) ) ) }', templateShareable: false \}|
                        )->a( n = `selectionChange` v = client->_event( val   = `SELECTION`
                                                                        t_arg = VALUE #( ( `$event.oSource.getId()` )
                                                                                         ( `$event.oSource.getSelectedContexts().length` ) ) )

                        )->ele( `headerToolbar`
                            )->ele( `OverflowToolbar`
                                )->tag( `Title`
                                    )->a( n = `text`  v = |Documents (\{= ${ client->_bind( t_itemsinstance3 ) }.length\})|
                                    )->a( n = `level` v = `H2`
                                )->tag( `ToolbarSpacer`

                                " onSearch filters the FIRST table whichever field is typed in
                                )->ele( `SearchField`
                                    )->a( n = `width`      v = `20%`
                                    )->a( n = `liveChange` v = client->follow_up_action( val   = client->cs_event-binding_call
                                                                                         t_arg = VALUE #( ( `table-uploadSet` )
                                                                                                          ( `items` )
                                                                                                          ( `filter` )
                                                                                                          ( `FILENAME` )
                                                                                                          ( `Contains` )
                                                                                                          ( `${$source>/value}` ) ) )

                                    )->ele( `layoutData`
                                        )->tag( `OverflowToolbarLayoutData`
                                            )->a( n = `priority` v = `NeverOverflow`

                                    )->end(
                                )->end(
                                )->tag( `ToolbarSeparator`
                                )->tag( n = `ActionsPlaceholder` ns = `upload`
                                    )->a( n = `id`             v = `uploadButtonInstance3`
                                    )->a( n = `placeholderFor` v = `UploadButtonPlaceholder`
                                )->tag( `Button`
                                    )->a( n = `id`      v = `downloadSelectedButton-instance3`
                                    )->a( n = `text`    v = `Download`
                                    )->a( n = `enabled` v = client->_bind( download_enabled3 )
                                    )->a( n = `press`   v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                      t_arg = VALUE #( ( `uploadSetPlugin-instance3` )
                                                                                                       ( `download` )
                                                                                                       ( `$controller.getView().byId('table-uploadSet-instance3').getSelectedContexts()[0]` )
                                                                                                       ( `true` ) ) )

                            )->end(
                        )->end(
                        )->ele( `dependents`
                            )->ele( n = `UploadSetwithTable` ns = `plugins`
                                )->a( n = `id`                     v = `uploadSetPlugin-instance3`
                                )->a( n = `uploadUrl`              v = `/uploadFiles`
                                )->a( n = `multiple`               v = `true`
                                )->a( n = `beforeUploadStarts`     v = client->_event( val    = `UPLOAD`
                                                                                       t_arg  = VALUE #( ( `${$parameters>/item}.getFileName()` )
                                                                                                         ( `${$parameters>/item}.getMediaType()` )
                                                                                                         ( `${$parameters>/item}.getFileObject().size` )
                                                                                                         ( `$event.oSource.data('itemsPath')` ) )
                                                                                       s_ctrl = VALUE #( check_prevent_default = abap_true
                                                                                                         check_queue_last      = abap_true ) )
                                )->a( n = `cloudFilePickerEnabled` v = `true`
                                )->a( n = `actions`                v = `uploadButtonInstance3`

                                )->ele( n = `rowConfiguration` ns = `plugins`
                                    )->tag( n = `UploadItemConfiguration` ns = `upload`
                                        )->a( n = `fileNamePath`        v = `FILENAME`
                                        )->a( n = `mediaTypePath`       v = `MEDIATYPE`
                                        )->a( n = `urlPath`             v = `URL`
                                        )->a( n = `previewablePath`     v = `PREVIEWABLE`
                                        )->a( n = `fileSizePath`        v = `FILESIZE`
                                        )->a( n = `isTrustedSourcePath` v = `TRUSTEDSOURCE`

                                )->end(
                                )->ele( n = `customData` ns = `plugins`
                                    )->tag( n = `CustomData` ns = `core`
                                        )->a( n = `key`        v = `itemsPath`
                                        )->a( n = `value`      v = `items-instance3`
                                        )->a( n = `writeToDom` v = `false`

                                )->end(
                            )->end(
                        )->end(
                        )->ele( `columns`
                            )->ele( `Column`
                                )->a( n = `id`         v = `fileName-instance3`
                                )->a( n = `importance` v = `High`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Name`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `id-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `ID`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `revision-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Revision`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `status-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Status`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `fileSize-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `File Size`

                                )->end(
                            )->end(
                            )->ele( `Column`
                                )->a( n = `id` v = `lastModified-instance3`

                                )->ele( `header`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `Last Modified`

                                )->end(
                            )->end(
                            )->tag( `Column`
                                )->a( n = `id`         v = `actionButton-instance3`
                                )->a( n = `importance` v = `High`

                        )->end(
                        )->ele( `items`
                            )->ele( `ColumnListItem`
                                )->a( n = `highlight` v = `{= ${UPLOADSTATE} === 'Complete' ? 'Indication05' : null }`

                                )->ele( `cells`
                                    )->ele( `HBox`
                                        )->tag( `Image`
                                            )->a( n = `src`     v = `{IMAGEURL}`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} !== undefined}`
                                        )->tag( n = `Icon` ns = `core`
                                            )->a( n = `src`     v = `{ICON}`
                                            )->a( n = `visible` v = `{= ${IMAGEURL} === undefined || ${IMAGEURL} === '' }`
                                            )->a( n = `class`   v = `sapMUSTItemImage sapMUSTItemIcon`

                                        )->ele( `VBox`
                                            )->a( n = `class` v = `sapUiTinyMargin sapUiSmallMarginBegin`

                                            )->tag( `Link`
                                                )->a( n = `text`  v = `{FILENAME}`
                                                )->a( n = `press` v = client->follow_up_action( val   = client->cs_event-control_by_id
                                                                                                t_arg = VALUE #( ( `uploadSetPlugin-instance3` )
                                                                                                                 ( `openFilePreview` )
                                                                                                                 ( `$event.oSource.getBindingContext()` ) ) )
                                                )->a( n = `class` v = `sapUiTinyMarginBottom`
                                            )->tag( `Text`
                                                )->a( n = `text` v = `{DOCUMENTTYPE}`

                                        )->end(
                                    )->end(
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{ID}`
                                    )->tag( `Link`
                                        )->a( n = `text` v = `{REVISION}`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{STATUS}`
                                    )->tag( `Text`
                                        )->a( n = `text` v = `{FILESIZE_UNITS}`

                                    )->ele( `VBox`
                                        )->tag( `Text`
                                            )->a( n = `text` v = `{LASTMODIFIEDBY}`
                                        )->tag( `Text`
                                            )->a( n = `class` v = `sapUiTinyMarginTop`
                                            )->a( n = `text`  v = `{LASTMODIFIED}`

                                    )->end(
                                    )->tag( `Button`
                                        )->a( n = `class` v = `sapUiTinyMarginBegin`
                                        )->a( n = `type`  v = `Transparent`
                                        )->a( n = `icon`  v = `sap-icon://decline`
                                        )->a( n = `press` v = client->_event( val   = `REMOVE_ROW`
                                                                              t_arg = VALUE #( ( `$event.oSource.getBindingContext().getPath()` )
                                                                                               ( `${FILENAME}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `SELECTION`.
        " onSelectionChange tells the three tables apart by their ids
        DATA(table_id) = client->get_event_arg( ).
        DATA(selected) = xsdbool( client->get_event_arg( 2 ) > 0 ).
        IF table_id CS `instance2`.
          download_enabled2 = selected.
        ELSEIF table_id CS `instance3`.
          download_enabled3 = selected.
        ELSE.
          download_enabled = selected.
        ENDIF.

      WHEN `REMOVE_ROW`.
        " removeItem - MessageBox.warning; the icon is the warning box's own
        remove_path = client->get_event_arg( ).
        client->message_box_display( text             = |Are you sure you want to remove the document { client->get_event_arg( 2 ) } ?|
                                     type             = `warning`
                                     actions          = VALUE #( ( `Remove` ) ( `CANCEL` ) )
                                     emphasizedaction = `Remove`
                                     styleclass       = `sapMUSTRemovePopoverContainer`
                                     initialfocus     = `CANCEL`
                                     onclose          = `REMOVE_CLOSE` ).

      WHEN `REMOVE_CLOSE`.
        " as in the sample, the row's index is spliced out of /items and the
        " first table's selection is cleared, whichever table the row was in
        IF client->get_event_arg( ) = `Remove`.
          DATA(index) = row_index( remove_path ).
          IF index BETWEEN 1 AND lines( t_items ).
            DELETE t_items INDEX index.
          ENDIF.
          client->follow_up_action( val   = client->cs_event-control_by_id
                                    t_arg = VALUE #( ( `table-uploadSet` ) ( `removeSelections` ) ) ).
          download_enabled = abap_false.
        ENDIF.

      WHEN `UPLOAD`.
        " the mock server answers into the array the plugin's itemsPath names
        DATA(row) = row_new( filename  = client->get_event_arg( )
                             mediatype = client->get_event_arg( 2 )
                             filesize  = CONV #( client->get_event_arg( 3 ) ) ).
        CASE client->get_event_arg( 4 ).
          WHEN `items-instance2`.
            INSERT row INTO t_itemsinstance2 INDEX 1.
          WHEN `items-instance3`.
            INSERT row INTO t_itemsinstance3 INDEX 1.
          WHEN OTHERS.
            INSERT row INTO t_items INDEX 1.
        ENDCASE.
        client->message_toast_display( `Document Added` ).

    ENDCASE.

  ENDMETHOD.


  METHOD row_new.

    " the mock server's Create branch
    upload_no = upload_no + 1.
    result = VALUE #( id             = |{ upload_no }|
                      filename       = filename
                      mediatype      = mediatype
                      uploadstate    = `Complete`
                      revision       = `00`
                      status         = `In work`
                      filesize       = filesize
                      lastmodifiedby = `Jane Burns`
                      lastmodified   = `10/03/21, 10:03:00 PM`
                      documenttype   = `Invoice`
                      trustedsource  = abap_true ).
    row_derive( CHANGING row = result ).

  ENDMETHOD.


  METHOD row_index.

    " a row's binding path ends in its 0-based index: /T_ITEMS/3 is the 4th row
    DATA(slash) = find( val = path sub = `/` occ = -1 ).
    IF slash < 0.
      RETURN.
    ENDIF.
    DATA(digits) = substring( val = path off = slash + 1 ).
    IF digits IS INITIAL OR digits CN `0123456789`.
      RETURN.
    ENDIF.
    result = CONV i( digits ) + 1.

  ENDMETHOD.


  METHOD row_derive.

    row-icon           = icon_for( mediatype = row-mediatype filename = row-filename ).
    row-filesize_units = size_with_units( row-filesize ).

  ENDMETHOD.


  METHOD icon_for.

    " UploadSetwithTable.getIconForFileType: IconPool's media type table, or the
    " file extension when there is no media type
    IF mediatype IS NOT INITIAL.
      CASE to_lower( mediatype ).
        WHEN `application/msword` OR `application/vnd.google-apps.document` OR `application/rtf`
            OR `application/vnd.openxmlformats-officedocument.wordprocessingml.document`.
          result = `sap-icon://doc-attachment`.
        WHEN `application/pdf`.
          result = `sap-icon://pdf-attachment`.
        WHEN `application/msexcel` OR `application/vnd.ms-excel` OR `application/vnd.google-apps.spreadsheet`
            OR `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
            OR `application/vnd.ms-excel.sheet.macroenabled.12`
            OR `application/vnd.openxmlformats-officedocument.spreadsheetml.template`
            OR `application/vnd.ms-excel.template.macroenabled.12`
            OR `application/vnd.ms-excel.sheet.binary.macroenabled.12`
            OR `application/vnd.ms-excel.addin.macroenabled.12`.
          result = `sap-icon://excel-attachment`.
        WHEN `application/vnd.ms-powerpoint` OR `application/vnd.google-apps.presentation` OR `application/mspowerpoint`
            OR `application/vnd.openxmlformats-officedocument.presentationml.presentation`
            OR `application/vnd.openxmlformats-officedocument.presentationml.slideshow`.
          result = `sap-icon://ppt-attachment`.
        WHEN `application/xml` OR `application/xhtml+xml` OR `application/x-httpd-php` OR `application/x-javascript`
            OR `text/html`.
          result = `sap-icon://attachment-html`.
        WHEN `application/gzip` OR `application/x-rar-compressed` OR `application/x-tar` OR `application/zip`.
          result = `sap-icon://attachment-zip-file`.
        WHEN `audio/mpeg` OR `audio/voxware` OR `audio/x-aiff` OR `audio/x-midi` OR `audio/x-mpeg` OR `audio/x-m4a`
            OR `audio/x-pn-realaudio` OR `audio/x-pn-realaudio-plugin` OR `audio/x-qt-stream` OR `audio/x-wav`.
          result = `sap-icon://attachment-audio`.
        WHEN `image/png` OR `image/tiff` OR `image/bmp` OR `image/jpeg` OR `image/gif`.
          result = `sap-icon://attachment-photo`.
        WHEN `text/plain` OR `text/comma-separated-values` OR `text/css` OR `text/javascript` OR `text/richtext`
            OR `text/rtf` OR `text/tab-separated-values` OR `text/xml`.
          result = `sap-icon://attachment-text-file`.
        WHEN `video/mpeg` OR `video/mp4` OR `video/quicktime` OR `video/x-msvideo` OR `application/x-shockwave-flash`.
          result = `sap-icon://attachment-video`.
        WHEN OTHERS.
          result = `sap-icon://document`.
      ENDCASE.
      RETURN.
    ENDIF.

    DATA(dot) = find( val = filename sub = `.` occ = -1 ).
    IF dot < 0.
      result = `sap-icon://document`.
      RETURN.
    ENDIF.
    CASE to_lower( substring( val = filename off = dot + 1 ) ).
      WHEN `bmp` OR `jpg` OR `jpeg` OR `png`.
        result = `sap-icon://card`.
      WHEN `csv` OR `xls` OR `xlsx`.
        result = `sap-icon://excel-attachment`.
      WHEN `doc` OR `docx` OR `odt`.
        result = `sap-icon://doc-attachment`.
      WHEN `pdf`.
        result = `sap-icon://pdf-attachment`.
      WHEN `ppt` OR `pptx`.
        result = `sap-icon://ppt-attachment`.
      WHEN `txt`.
        result = `sap-icon://document-text`.
      WHEN OTHERS.
        result = `sap-icon://document`.
    ENDCASE.

  ENDMETHOD.


  METHOD size_with_units.

    " UploadSetwithTable.getFileSizeWithUnits - KB below a megabyte, then MB, then GB
    CONSTANTS kilobyte TYPE i VALUE 1024.
    DATA(bytes) = CONV decfloat34( size ).
    IF size < kilobyte * kilobyte.
      result = |{ bytes / kilobyte DECIMALS = 2 } KB|.
    ELSEIF size < kilobyte * kilobyte * kilobyte.
      result = |{ bytes / kilobyte / kilobyte DECIMALS = 2 } MB|.
    ELSE.
      result = |{ bytes / kilobyte / kilobyte / kilobyte DECIMALS = 2 } GB|.
    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " model/documents.json, all three arrays - the document URLs point at the OpenUI5 host
    t_items = VALUE #(
      ( id = `23004569` filename = `Invoice summary.doc` mediatype = `application/msword`
        imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png` url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Agenda.doc`
        revision = `01` status = `In work` filesize = 200 lastmodifiedby = `Jane Burns` lastmodified = `10/03/21, 10:03:00 PM`
        documenttype = `Invoice` previewable = abap_true )
      ( id = `23004589` filename = `Business Plan Topics.xls` mediatype = `application/vnd.ms-excel`
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business Plan Topics.xls`
        revision = `00` status = `In work` filesize = 2400 lastmodifiedby = `Jane Burns` lastmodified = `10/03/21, 10:03:00 PM`
        documenttype = `Invoice` previewable = abap_true )
      ( id = `23004578` filename = `Instructions.pdf` mediatype = `application/pdf`
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf`
        revision = `01` status = `In work` filesize = 30000 lastmodifiedby = `Jane Burns` lastmodified = `10/03/21, 10:03:00 PM`
        documenttype = `Specification` previewable = abap_true trustedsource = abap_true ) ).
    t_itemsinstance2 = VALUE #(
      ( id = `23004579` filename = `Document.txt` mediatype = `text/plain`
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt`
        revision = `42` status = `In work` filesize = 420 lastmodifiedby = `Jane Burns` lastmodified = `10/03/21, 10:03:00 PM`
        documenttype = `Document` previewable = abap_true )
      ( id = `23004581` filename = `Test Image.png` mediatype = `image/png`
        imageurl = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png` url = `https://sdk.openui5.org/test-resources/sap/m/images/invoice_manager.png`
        revision = `06` status = `In work` filesize = 420 lastmodifiedby = `Jane Burns` lastmodified = `10/03/21, 10:03:00 PM`
        documenttype = `Attachment` previewable = abap_true )
      ( id = `23004582` filename = `Test Attachment.gif` mediatype = `image/gif`
        imageurl = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif` url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Animation.gif`
        revision = `11` status = `In work` filesize = 420 lastmodifiedby = `Jane Burns` lastmodified = `10/03/21, 10:03:00 PM`
        documenttype = `Attachment` previewable = abap_true ) ).
    t_itemsinstance3 = VALUE #(
      ( id = `23004583` filename = `Test Video.mp4` mediatype = `video/mp4`
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Video.mp4`
        revision = `99` status = `In work` filesize = 420000 lastmodifiedby = `Jane Burns` lastmodified = `10/03/21, 10:03:00 PM`
        documenttype = `Attachment` previewable = abap_true )
      ( id = `23004590` filename = `Sample Zip File.zip` mediatype = `application/zip`
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/sample-zip-file.zip`
        revision = `00` status = `In work` filesize = 42000 lastmodifiedby = `Jane Burns` lastmodified = `10/03/22, 10:20:00 PM`
        documenttype = `Attachment` previewable = abap_true )
      ( id = `23004584` filename = `Transmission.vds` mediatype = `model/vnd.sap.vds`
        url = `https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/transmission.vds`
        revision = `42` status = `In work` filesize = 123 lastmodifiedby = `Jane Burns` lastmodified = `10/03/22, 10:20:00 PM`
        documenttype = `Attachment` previewable = abap_true ) ).
    LOOP AT t_items REFERENCE INTO DATA(row).
      row_derive( CHANGING row = row->* ).
    ENDLOOP.
    LOOP AT t_itemsinstance2 REFERENCE INTO row.
      row_derive( CHANGING row = row->* ).
    ENDLOOP.
    LOOP AT t_itemsinstance3 REFERENCE INTO row.
      row_derive( CHANGING row = row->* ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
