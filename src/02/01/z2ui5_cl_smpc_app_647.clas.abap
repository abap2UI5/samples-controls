" @keywords engine sap.m.p13n p13n.enginegridlist vbox toolbar title toolbarseparator toolbarspacer button gridlist customlistitem flexitemdata
" @summary GridList using the personalization Engine
" @origin sap.m.sample.p13n.EngineGridList - https://sdk.openui5.org/entity/sap.m.p13n.Engine/sample/sap.m.sample.p13n.EngineGridList (status: generated - machine-written, not yet reviewed)
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
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
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
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/reason}` INTO TABLE temp1.
    INSERT `$event.oSource.getPanels()[0].getP13nData(true)` INTO TABLE temp1.
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
                            t_arg = temp1 )

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
    DATA json TYPE string.
    DATA key LIKE LINE OF t_state.
      DATA person LIKE LINE OF t_persons.
      FIELD-SYMBOLS <temp1> LIKE LINE OF t_persons.
      DATA temp2 LIKE sy-tabix.
    DATA hidden LIKE t_persons.
      DATA temp3 LIKE sy-subrc.
    DATA temp4 TYPE string_table.
    json = ``.
    
    LOOP AT t_state INTO key.
      
      
      
      temp2 = sy-tabix.
      READ TABLE t_persons WITH KEY key = key ASSIGNING <temp1>.
      sy-tabix = temp2.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      person = <temp1>.
      json = |{ json },\{"name":"{ key }","label":"{ person-firstname } { person-lastname }","visible":true\}|.
    ENDLOOP.

    
    hidden = t_persons.
    LOOP AT hidden INTO person.
      
      READ TABLE t_state WITH KEY table_line = person-key TRANSPORTING NO FIELDS.
      temp3 = sy-subrc.
      IF temp3 = 0.
        DELETE hidden WHERE key = person-key.
      ENDIF.
    ENDLOOP.
    SORT hidden BY firstname lastname.
    LOOP AT hidden INTO person.
      json = |{ json },\{"name":"{ person-key }","label":"{ person-firstname } { person-lastname }","visible":false\}|.
    ENDLOOP.

    json = |[{ shift_left( val = json sub = `,` ) }]|.

    
    CLEAR temp4.
    INSERT `itemsPanel` INTO TABLE temp4.
    INSERT `setP13nData` INTO TABLE temp4.
    INSERT json INTO TABLE temp4.
    client->follow_up_action( val   = client->cs_event-control_by_id
                              t_arg = temp4 ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp6 TYPE string_table.

    CASE client->get_event( ).

      WHEN `OPEN_PERSO`.
        " Engine.show( ): the panel shows the current state, a cancelled edit is gone
        set_p13n_data( ).
        
        CLEAR temp6.
        INSERT `p13nPopup` INTO TABLE temp6.
        INSERT `open` INTO TABLE temp6.
        client->follow_up_action( val   = client->cs_event-control_by_id
                                  t_arg = temp6 ).

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
    DATA temp8 TYPE z2ui5_cl_smpc_app_647=>ty_t_item.
    DATA key LIKE LINE OF t_state.
      FIELD-SYMBOLS <temp3> LIKE LINE OF t_persons.
      DATA temp4 LIKE sy-tabix.
    CLEAR temp8.
    
    LOOP AT t_state INTO key.
      
      
      temp4 = sy-tabix.
      READ TABLE t_persons WITH KEY key = key ASSIGNING <temp3>.
      sy-tabix = temp4.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      INSERT <temp3> INTO TABLE temp8.
    ENDLOOP.
    t_items = temp8.

  ENDMETHOD.


  METHOD p13n_names.

    " getP13nData( true ) arrives as a JSON array of the panel's flat item
    " objects; collect their names in order
    DATA objects TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA object LIKE LINE OF objects.
      DATA offset TYPE i.
    SPLIT json AT `}` INTO TABLE objects.
    
    LOOP AT objects INTO object.
      
      offset = find( val = object sub = `"name":"` ).
      IF offset >= 0.
        INSERT substring_before( val = substring( val = object off = offset + 8 ) sub = `"` ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD model_init.

    DATA temp10 TYPE z2ui5_cl_smpc_app_647=>ty_t_item.
    DATA temp11 LIKE LINE OF temp10.
    DATA temp12 TYPE string_table.
    DATA person LIKE LINE OF t_persons.
    CLEAR temp10.
    
    temp11-key = `person1`.
    temp11-firstname = `Peter`.
    temp11-lastname = `Mueller`.
    temp11-size = `1.75`.
    temp11-city = `Walldorf`.
    INSERT temp11 INTO TABLE temp10.
    temp11-key = `person2`.
    temp11-firstname = `Petra`.
    temp11-lastname = `Maier`.
    temp11-size = `1.85`.
    temp11-city = `Walldorf`.
    INSERT temp11 INTO TABLE temp10.
    temp11-key = `person3`.
    temp11-firstname = `Thomas`.
    temp11-lastname = `Smith`.
    temp11-size = `1.95`.
    temp11-city = `Walldorf`.
    INSERT temp11 INTO TABLE temp10.
    temp11-key = `person4`.
    temp11-firstname = `Maria`.
    temp11-lastname = `Jones`.
    temp11-size = `1.55`.
    temp11-city = `Walldorf`.
    INSERT temp11 INTO TABLE temp10.
    temp11-key = `person5`.
    temp11-firstname = `John`.
    temp11-lastname = `Williams`.
    temp11-size = `1.65`.
    temp11-city = `Walldorf`.
    INSERT temp11 INTO TABLE temp10.
    t_persons = temp10.

    t_items = t_persons.
    
    CLEAR temp12.
    
    LOOP AT t_persons INTO person.
      INSERT person-key INTO TABLE temp12.
    ENDLOOP.
    t_state = temp12.

  ENDMETHOD.

ENDCLASS.
