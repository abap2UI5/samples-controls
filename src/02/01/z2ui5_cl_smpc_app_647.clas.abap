CLASS z2ui5_cl_smpc_app_647 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_item,
        key       TYPE string,
        firstname TYPE string,
        lastname  TYPE string,
        size      TYPE string,
        city      TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.
    DATA t_items TYPE ty_t_item.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " every person the MetadataHelper knows, and the Items state (visible keys in order)
    DATA t_persons TYPE ty_t_item.
    DATA t_state TYPE string_table.

    METHODS view_display.
    METHODS set_p13n_data.
    METHODS on_event.
    METHODS handle_state_change.
    METHODS p13n_names
      IMPORTING
        json          TYPE string
      RETURNING
        VALUE(result) TYPE string_table.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_647 IMPLEMENTATION.

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
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:f`    v = `sap.f`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:p13n` v = `sap.m.p13n`
        )->a( n = `xmlns:app`  v = `http://schemas.sap.com/sapui5/extension/sap.ui.core.CustomData/1`
        )->a( n = `height`     v = `100%`
        )->a( n = `class`      v = `sapUiContentPadding`

        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin`
            )->a( n = `width` v = `95%`

            )->ele( `Toolbar`
                )->a( n = `class` v = `sapUiSmallMarginBottom`

                )->ele( `content`
                    )->tag( `Title`
                        )->a( n = `id`   v = `title`
                        )->a( n = `text` v = `Persons`
                    )->tag( `ToolbarSeparator`
                    " the sap.ui.fl VariantManagement (p13nVm) is dropped - see the sidecar
                    )->tag( `ToolbarSpacer`
                    )->tag( `Button`
                        )->a( n = `icon`  v = `sap-icon://action-settings`
                        )->a( n = `press` v = client->_event( `OPEN_PERSO` )

                )->end(
            )->end(

            )->ele( n = `GridList` ns = `f`
                )->a( n = `id`    v = `persoList`
                )->a( n = `items` v = client->_bind( t_items )

                )->ele( n = `items` ns = `f`
                    )->ele( `CustomListItem`
                        )->a( n = `type` v = `Active`

                        )->ele( `layoutData`
                            )->tag( `FlexItemData`
                                )->a( n = `growFactor`   v = `1`
                                )->a( n = `shrinkFactor` v = `0`

                        )->end(
                        )->ele( `HBox`
                            )->a( n = `justifyContent` v = `SpaceBetween`

                            )->ele( `VBox`
                                )->a( n = `justifyContent` v = `SpaceBetween`
                                )->a( n = `class`          v = `sapUiSmallMarginTop sapUiSmallMarginBegin`

                                )->ele( `VBox`
                                    )->a( n = `app:p13nKey` v = `firstName`

                                    )->tag( `Title`
                                        )->a( n = `text` v = `First Name`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `{FIRSTNAME}`

                                )->end(
                                )->ele( `VBox`
                                    )->a( n = `app:p13nKey` v = `lastName`

                                    )->tag( `Title`
                                        )->a( n = `text` v = `Last Name`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `{LASTNAME}`

                                )->end(
                                )->ele( `VBox`
                                    )->a( n = `app:p13nKey` v = `city`

                                    )->tag( `Title`
                                        )->a( n = `text` v = `City`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `{CITY}`

                                )->end(
                                )->ele( `VBox`
                                    )->a( n = `app:p13nKey` v = `size`

                                    )->tag( `Title`
                                        )->a( n = `text` v = `Size`
                                    )->tag( `Label`
                                        )->a( n = `text` v = `{SIZE}`

                                )->end(
                            )->end(

                            )->tag( n = `Icon` ns = `core`
                                )->a( n = `src`   v = `sap-icon://customer`
                                )->a( n = `size`  v = `2.5rem`
                                )->a( n = `class` v = `sapUiSmallMarginTop sapUiSmallMarginEnd sapUiSmallMarginBottom`

                        )->end(
                    )->end(
                )->end(

                " the popup Engine.show( ) creates for the Items SelectionController
                )->ele( n = `dependents` ns = `f`
                    )->ele( n = `Popup` ns = `p13n`
                        )->a( n = `id`    v = `p13nPopup`
                        )->a( n = `close` v = client->_event(
                            val   = `P13N_CLOSE`
                            t_arg = VALUE #( ( `${$parameters>/reason}` )
                                             ( `$event.oSource.getPanels()[0].getP13nData(true)` ) ) )

                        )->ele( n = `panels` ns = `p13n`
                            )->tag( n = `SelectionPanel` ns = `p13n`
                                )->a( n = `id`          v = `itemsPanel`
                                )->a( n = `showHeader`  v = `true`
                                )->a( n = `enableCount` v = `true` ).

    client->view_display( view->stringify( ) ).

    " a rebuilt view carries a fresh, empty panel
    set_p13n_data( ).

  ENDMETHOD.


  METHOD set_p13n_data.

    " the SelectionController's panel data: the visible persons in state order,
    " then the hidden ones sorted by label
    DATA(json) = ``.
    LOOP AT t_state INTO DATA(key).
      DATA(person) = t_persons[ key = key ].
      json = |{ json },\{"name":"{ key }","label":"{ person-firstname } { person-lastname }","visible":true\}|.
    ENDLOOP.

    DATA(hidden) = t_persons.
    LOOP AT hidden INTO person.
      IF line_exists( t_state[ table_line = person-key ] ).
        DELETE hidden WHERE key = person-key.
      ENDIF.
    ENDLOOP.
    SORT hidden BY firstname lastname.
    LOOP AT hidden INTO person.
      json = |{ json },\{"name":"{ person-key }","label":"{ person-firstname } { person-lastname }","visible":false\}|.
    ENDLOOP.

    json = |[{ shift_left( val = json sub = `,` ) }]|.

    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = VALUE #( ( `itemsPanel` ) ( `setP13nData` ) ( json ) ) ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).

      WHEN `OPEN_PERSO`.
        " Engine.show( ): the panel shows the current state, a cancelled edit is gone
        set_p13n_data( ).
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = VALUE #( ( `p13nPopup` ) ( `open` ) ) ).

      WHEN `P13N_CLOSE`.
        " the Engine applies the panel state on Ok only
        IF client->get_event_arg( ) = `Ok`.
          t_state = p13n_names( client->get_event_arg( 2 ) ).
          handle_state_change( ).
        ENDIF.

    ENDCASE.

  ENDMETHOD.


  METHOD handle_state_change.

    " like handleStateChange: the items become the visible persons, in state order
    t_items = VALUE #( FOR key IN t_state ( t_persons[ key = key ] ) ).

  ENDMETHOD.


  METHOD p13n_names.

    " getP13nData( true ) arrives as a JSON array of the panel's flat item
    " objects; collect their names in order
    SPLIT json AT `}` INTO TABLE DATA(objects).
    LOOP AT objects INTO DATA(object).
      DATA(offset) = find( val = object sub = `"name":"` ).
      IF offset >= 0.
        INSERT substring_before( val = substring( val = object off = offset + 8 ) sub = `"` ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    t_persons = VALUE #(
        ( key = `person1` firstname = `Peter`  lastname = `Mueller`  size = `1.75` city = `Walldorf` )
        ( key = `person2` firstname = `Petra`  lastname = `Maier`    size = `1.85` city = `Walldorf` )
        ( key = `person3` firstname = `Thomas` lastname = `Smith`    size = `1.95` city = `Walldorf` )
        ( key = `person4` firstname = `Maria`  lastname = `Jones`    size = `1.55` city = `Walldorf` )
        ( key = `person5` firstname = `John`   lastname = `Williams` size = `1.65` city = `Walldorf` ) ).

    t_items = t_persons.
    t_state = VALUE #( FOR person IN t_persons ( person-key ) ).

  ENDMETHOD.

ENDCLASS.
