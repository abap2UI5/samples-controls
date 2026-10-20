" @keywords variantmanagement variant management sap.m panel overflowtoolbar title toolbarspacer button dynamicpage dynamicpagetitle variantitem
" @summary VariantManagement with dedicated items
" @origin sap.m.sample.VariantManagement - https://sdk.openui5.org/entity/sap.m.VariantManagement/sample/sap.m.sample.VariantManagement (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_651 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        key             TYPE string,
        title           TYPE string,
        author          TYPE string,
        favorite        TYPE abap_bool,
        visible         TYPE abap_bool,
        executeonselect TYPE abap_bool,
        rename          TYPE abap_bool,
        changeable      TYPE abap_bool,
        remove          TYPE abap_bool,
        sharing         TYPE string,
      END OF ty_s_item.
    DATA t_items     TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
    DATA selectedkey TYPE string.
    DATA defaultkey  TYPE string.
    DATA modified    TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS update_items.
    METHODS create_new_item.
    METHODS show_message
      IMPORTING
        !text TYPE string.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_651 IMPLEMENTATION.

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
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:f`   v = `sap.f`
        )->a( n = `height`    v = `100%`

        )->ele( `Panel`
            )->a( n = `headerText` v = `m.VariantManagement using declarative items aggregation`

            )->ele( `headerToolbar`
                )->ele( `OverflowToolbar`
                    )->a( n = `style` v = `Clear`

                    )->tag( `Title`
                        )->a( n = `text`  v = `Custom Toolbar with a header text`
                        )->a( n = `level` v = `H1`
                    )->tag( `ToolbarSpacer`
                    )->tag( `Button`
                        )->a( n = `text`  v = `Toggle Modify View`
                        )->a( n = `press` v = client->_event( `TOGGLE_MODIFIED` )

                )->end(
            )->end(

            )->ele( n = `DynamicPage` ns = `f`
                )->a( n = `id` v = `dynamicPage`

                )->ele( n = `title` ns = `f`
                    )->ele( n = `DynamicPageTitle` ns = `f`
                        )->ele( n = `heading` ns = `f`
                            " the four static VariantItem controls become one bound template, so
                            " the backend can add and remove views like the controller does
                            )->ele( `VariantManagement`
                                )->a( n = `id`           v = `vm`
                                )->a( n = `select`       v = client->_event( val = `SELECT`
                                                                             arg = `${$parameters>/key}` )
                                )->a( n = `save`         v = client->_event( val   = `SAVE`
                                                                             t_arg = VALUE #( ( `${$parameters>/name}` )
                                                                                              ( `${$parameters>/overwrite}` )
                                                                                              ( `${$parameters>/key}` )
                                                                                              ( `${$parameters>/execute}` )
                                                                                              ( `${$parameters>/def}` )
                                                                                              ( `${$parameters>/public}` ) ) )
                                )->a( n = `manage`       v = client->_event( val = `MANAGE`
                                                                             arg = `${$parameters>/deleted}` )
                                )->a( n = `selectedKey`  v = client->_bind( selectedkey )
                                )->a( n = `defaultKey`   v = client->_bind( defaultkey )
                                )->a( n = `modified`     v = client->_bind( modified )
                                )->a( n = `showFooter`   v = `true`
                                )->a( n = `popoverTitle` v = `my Favorites`
                                )->a( n = `items`        v = client->_bind( t_items )

                                )->ele( `items`
                                    )->tag( `VariantItem`
                                        )->a( n = `key`             v = `{KEY}`
                                        )->a( n = `title`           v = `{TITLE}`
                                        )->a( n = `author`          v = `{AUTHOR}`
                                        )->a( n = `favorite`        v = `{FAVORITE}`
                                        )->a( n = `visible`         v = `{VISIBLE}`
                                        )->a( n = `executeOnSelect` v = `{EXECUTEONSELECT}`
                                        )->a( n = `rename`          v = `{RENAME}`
                                        )->a( n = `changeable`      v = `{CHANGEABLE}`
                                        )->a( n = `remove`          v = `{REMOVE}`
                                        )->a( n = `sharing`         v = `{SHARING}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `TOGGLE_MODIFIED`.
        modified = xsdbool( modified = abap_false ).

      WHEN `MANAGE`.
        " renamed, favorite, executeOnSelect and the default key are written
        " back by the two-way bound item properties; only deletions need code
        update_items( ).

      WHEN `SELECT`.
        show_message( |Selected Key: { client->get_event_arg( ) }| ).
        modified = abap_false.

      WHEN `SAVE`.
        IF client->get_event_arg( 2 ) = abap_true.
          DATA(key) = client->get_event_arg( 3 ).
          DATA(title) = VALUE string( t_items[ key = key ]-title OPTIONAL ).
          show_message( |View '{ title }' updated.| ).
        ELSE.
          create_new_item( ).
        ENDIF.
        modified = abap_false.

    ENDCASE.

  ENDMETHOD.


  METHOD update_items.

    " deleted arrives as a JSON array of keys, e.g. ["3","4"]
    DATA(deleted) = client->get_event_arg( ).
    " three replace( ) calls, not translate( from = `[]"` to = `` ): the
    " transpiled runtime builds an unescaped [...] regex class from FROM, so a
    " closing bracket in it matches nothing and the key never came out clean
    deleted = replace( val = deleted sub = `[` with = `` occ = 0 ).
    deleted = replace( val = deleted sub = `]` with = `` occ = 0 ).
    deleted = replace( val = deleted sub = `"` with = `` occ = 0 ).
    SPLIT deleted AT `,` INTO TABLE DATA(keys).
    LOOP AT keys INTO DATA(key) WHERE table_line IS NOT INITIAL.
      DELETE t_items WHERE key = key.
    ENDLOOP.

    " like _checkCurrentVariant: a removed selection falls back to the standard variant
    IF NOT line_exists( t_items[ key = selectedkey ] ) AND t_items IS NOT INITIAL.
      selectedkey = t_items[ 1 ]-key.
    ENDIF.

  ENDMETHOD.


  METHOD create_new_item.

    " Date.now( ) in the original - a timestamp keeps the key unique as well
    GET TIME STAMP FIELD DATA(now).
    DATA(key) = |key_{ now }|.

    INSERT VALUE #( key             = key
                    title           = client->get_event_arg( )
                    author          = `sample`
                    favorite        = abap_true
                    visible         = abap_true
                    executeonselect = client->get_event_arg( 4 )
                    rename          = abap_true
                    changeable      = abap_true
                    remove          = abap_true
                    sharing         = COND #( WHEN client->get_event_arg( 6 ) = abap_true
                                              THEN `Public`
                                              ELSE `Private` ) ) INTO TABLE t_items.

    IF client->get_event_arg( 5 ) = abap_true.
      defaultkey = key.
    ENDIF.

    show_message( |New view '{ client->get_event_arg( ) }' created with key:'{ key }'.| ).

  ENDMETHOD.


  METHOD show_message.

    client->follow_up_action( val   = client->cs_event-control_global
                              t_arg = VALUE #( ( `MESSAGE_TOAST` )
                                               ( `show` )
                                               ( text )
                                               ( `{"closeOnBrowserNavigation":true}` ) ) ).

  ENDMETHOD.


  METHOD model_init.

    t_items = VALUE #(
        ( key = `Standard` title = `Entry1` author = `B` favorite = abap_true  visible = abap_true executeonselect = abap_false rename = abap_false changeable = abap_false remove = abap_false sharing = `Public` )
        ( key = `2`        title = `Entry2` author = `A` favorite = abap_true  visible = abap_true executeonselect = abap_false rename = abap_true  changeable = abap_true  remove = abap_true  sharing = `Private` )
        ( key = `3`        title = `Entry3` author = `A` favorite = abap_true  visible = abap_true executeonselect = abap_true  rename = abap_true  changeable = abap_true  remove = abap_true  sharing = `Private` )
        ( key = `4`        title = `Entry4` author = `A` favorite = abap_false visible = abap_true executeonselect = abap_true  rename = abap_false changeable = abap_true  remove = abap_false sharing = `Public` ) ).

    selectedkey = `2`.
    defaultkey  = `2`.

  ENDMETHOD.

ENDCLASS.
