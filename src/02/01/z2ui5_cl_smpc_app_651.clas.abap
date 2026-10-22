" @keywords variantmanagement variant management sap.m panel overflowtoolbar title toolbarspacer button dynamicpage dynamicpagetitle
" @summary VariantManagement with dedicated items
" @origin sap.m.sample.VariantManagement - https://sdk.openui5.org/entity/sap.m.VariantManagement/sample/sap.m.sample.VariantManagement (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_651 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA selectedkey TYPE string.
    DATA defaultkey  TYPE string.
    DATA modified    TYPE abap_bool.

  PROTECTED SECTION.
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
    TYPES:
      BEGIN OF ty_s_change,
        key   TYPE string,
        value TYPE string,
      END OF ty_s_change.
    TYPES ty_t_change TYPE STANDARD TABLE OF ty_s_change WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    " the VariantItem controls of the view, as the controller leaves them
    TYPES temp1_41bd9efe29 TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.
DATA t_items TYPE temp1_41bd9efe29.

    METHODS view_display.
    METHODS on_event.
    METHODS update_items.
    METHODS manage_changes
      IMPORTING
        json          TYPE string
        field         TYPE string
      RETURNING
        VALUE(result) TYPE ty_t_change.
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
    DATA temp2 TYPE string_table.
    DATA items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA item LIKE LINE OF t_items.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `${$parameters>/name}` INTO TABLE temp1.
    INSERT `${$parameters>/overwrite}` INTO TABLE temp1.
    INSERT `${$parameters>/key}` INTO TABLE temp1.
    INSERT `${$parameters>/execute}` INTO TABLE temp1.
    INSERT `${$parameters>/def}` INTO TABLE temp1.
    INSERT `${$parameters>/public}` INTO TABLE temp1.
    
    CLEAR temp2.
    INSERT `${$parameters>/deleted}` INTO TABLE temp2.
    INSERT `${$parameters>/renamed}` INTO TABLE temp2.
    INSERT `${$parameters>/fav}` INTO TABLE temp2.
    INSERT `${$parameters>/exe}` INTO TABLE temp2.
    
    items = view->ele( n = `View` ns = `mvc`
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
                            )->ele( `VariantManagement`
                                )->a( n = `id`           v = `vm`
                                )->a( n = `select`       v = client->_event( val = `SELECT`
                                                                             arg = `${$parameters>/key}` )
                                )->a( n = `save`         v = client->_event( val   = `SAVE`
                                                                             t_arg = temp1 )
                                )->a( n = `manage`       v = client->_event( val   = `MANAGE`
                                                                             t_arg = temp2 )
                                )->a( n = `selectedKey`  v = client->_bind( selectedkey )
                                )->a( n = `defaultKey`   v = client->_bind( defaultkey )
                                )->a( n = `modified`     v = client->_bind( modified )
                                )->a( n = `showFooter`   v = `true`
                                )->a( n = `popoverTitle` v = `my Favorites`

                                )->ele( `items` ).

    " the static VariantItem controls, emitted from the backend's table so a
    " saved view can be added and a deleted one removed like the controller does
    
    LOOP AT t_items INTO item.
      " sharing is an enum: written as a literal, so the view gates can check it
      IF item-sharing = `Public`.
        items->tag( `VariantItem`
            )->a( n = `sharing` v = `Public` ).
      ELSE.
        items->tag( `VariantItem`
            )->a( n = `sharing` v = `Private` ).
      ENDIF.
      " a( ) lands on the VariantItem just added
      items->a( n = `key`             t = item-key
          )->a( n = `title`           t = item-title
          )->a( n = `author`          t = item-author
          )->a( n = `favorite`        b = item-favorite
          )->a( n = `visible`         b = item-visible
          )->a( n = `executeOnSelect` b = item-executeonselect
          )->a( n = `rename`          b = item-rename
          )->a( n = `changeable`      b = item-changeable
          )->a( n = `remove`          b = item-remove ).
    ENDLOOP.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp1 TYPE xsdboolean.
          DATA key TYPE string.
          DATA temp3 TYPE string.
          DATA temp4 TYPE z2ui5_cl_smpc_app_651=>ty_s_item.
          DATA title LIKE temp3.

    CASE client->get_event( ).

      WHEN `TOGGLE_MODIFIED`.
        
        temp1 = boolc( modified = abap_false ).
        modified = temp1.

      WHEN `MANAGE`.
        update_items( ).
        view_display( ).

      WHEN `SELECT`.
        show_message( |Selected Key: { client->get_event_arg( ) }| ).
        modified = abap_false.

      WHEN `SAVE`.
        IF client->get_event_arg( 2 ) = abap_true.
          
          key = client->get_event_arg( 3 ).
          
          CLEAR temp3.
          
          READ TABLE t_items INTO temp4 WITH KEY key = key.
          IF sy-subrc = 0.
            temp3 = temp4-title.
          ENDIF.
          
          title = temp3.
          show_message( |View '{ title }' updated.| ).
        ELSE.
          create_new_item( ).
          view_display( ).
        ENDIF.
        modified = abap_false.

    ENDCASE.

  ENDMETHOD.


  METHOD update_items.

    " deleted arrives as a JSON array of keys, e.g. ["3","4"]
    DATA deleted TYPE string.
    TYPES temp2 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA keys TYPE temp2.
    DATA key LIKE LINE OF keys.
    DATA temp5 TYPE z2ui5_cl_smpc_app_651=>ty_t_change.
    DATA change LIKE LINE OF temp5.
      DATA temp6 LIKE sy-subrc.
        FIELD-SYMBOLS <temp7> LIKE LINE OF t_items.
        DATA temp8 LIKE sy-tabix.
    DATA temp9 TYPE z2ui5_cl_smpc_app_651=>ty_t_change.
      DATA temp10 LIKE sy-subrc.
        FIELD-SYMBOLS <temp11> LIKE LINE OF t_items.
        DATA temp12 LIKE sy-tabix.
        DATA temp3 TYPE xsdboolean.
    DATA temp13 TYPE z2ui5_cl_smpc_app_651=>ty_t_change.
      DATA temp14 LIKE sy-subrc.
        FIELD-SYMBOLS <temp15> LIKE LINE OF t_items.
        DATA temp16 LIKE sy-tabix.
        DATA temp4 TYPE xsdboolean.
    DATA temp17 LIKE sy-subrc.
      FIELD-SYMBOLS <temp18> LIKE LINE OF t_items.
      DATA temp19 LIKE sy-tabix.
    deleted = client->get_event_arg( ).
    " three replace( ) calls, not translate( from = `[]"` to = `` ): the
    " transpiled runtime builds an unescaped [...] regex class from FROM, so a
    " closing bracket in it matches nothing and the key never came out clean
    deleted = replace( val = deleted sub = `[` with = `` occ = 0 ).
    deleted = replace( val = deleted sub = `]` with = `` occ = 0 ).
    deleted = replace( val = deleted sub = `"` with = `` occ = 0 ).
    

    SPLIT deleted AT `,` INTO TABLE keys.
    
    LOOP AT keys INTO key WHERE table_line IS NOT INITIAL.
      DELETE t_items WHERE key = key.
    ENDLOOP.

    " what the Manage Views dialog changed on the items: renamed, fav, exe
    " (the default key comes back through the two-way bound defaultKey)
    
    temp5 = manage_changes( json = client->get_event_arg( 2 ) field = `name` ).
    
    LOOP AT temp5 INTO change.
      
      READ TABLE t_items WITH KEY key = change-key TRANSPORTING NO FIELDS.
      temp6 = sy-subrc.
      IF temp6 = 0.
        
        
        temp8 = sy-tabix.
        READ TABLE t_items WITH KEY key = change-key ASSIGNING <temp7>.
        sy-tabix = temp8.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp7>-title = change-value.
      ENDIF.
    ENDLOOP.
    
    temp9 = manage_changes( json = client->get_event_arg( 3 ) field = `visible` ).
    LOOP AT temp9 INTO change.
      
      READ TABLE t_items WITH KEY key = change-key TRANSPORTING NO FIELDS.
      temp10 = sy-subrc.
      IF temp10 = 0.
        
        
        temp12 = sy-tabix.
        READ TABLE t_items WITH KEY key = change-key ASSIGNING <temp11>.
        sy-tabix = temp12.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        
        temp3 = boolc( change-value = `true` ).
        <temp11>-favorite = temp3.
      ENDIF.
    ENDLOOP.
    
    temp13 = manage_changes( json = client->get_event_arg( 4 ) field = `exe` ).
    LOOP AT temp13 INTO change.
      
      READ TABLE t_items WITH KEY key = change-key TRANSPORTING NO FIELDS.
      temp14 = sy-subrc.
      IF temp14 = 0.
        
        
        temp16 = sy-tabix.
        READ TABLE t_items WITH KEY key = change-key ASSIGNING <temp15>.
        sy-tabix = temp16.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        
        temp4 = boolc( change-value = `true` ).
        <temp15>-executeonselect = temp4.
      ENDIF.
    ENDLOOP.

    " like _checkCurrentVariant: a removed selection falls back to the standard variant
    
    READ TABLE t_items WITH KEY key = selectedkey TRANSPORTING NO FIELDS.
    temp17 = sy-subrc.
    IF NOT temp17 = 0 AND t_items IS NOT INITIAL.
      
      
      temp19 = sy-tabix.
      READ TABLE t_items INDEX 1 ASSIGNING <temp18>.
      sy-tabix = temp19.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      selectedkey = <temp18>-key.
    ENDIF.

  ENDMETHOD.


  METHOD manage_changes.

    " renamed/fav/exe arrive as compact JSON arrays of flat objects, keys in
    " alphabetical order: [{"key":"2","name":"New"}], [{"exe":true,"key":"3"}]
    TYPES temp3 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA t_object TYPE temp3.
    DATA object LIKE LINE OF t_object.
      DATA value TYPE string.
      DATA temp20 TYPE z2ui5_cl_smpc_app_651=>ty_s_change.
    SPLIT json AT `{"` INTO TABLE t_object.
    
    LOOP AT t_object INTO object FROM 2.
      
      value = substring_after( val = object sub = |{ field }":| ).
      IF value CP `"*`.
        " a string (the new name, the last key) runs to the quote before the brace
        value = substring_before( val = shift_left( val = value places = 1 ) sub = `"}` ).
      ELSE.
        " a boolean runs to the next comma or brace
        value = segment( val = substring_before( val = value sub = `}` ) index = 1 sep = `,` ).
      ENDIF.
      
      CLEAR temp20.
      temp20-key = substring_before( val = substring_after( val = object sub = `key":"` ) sub = `"` ).
      temp20-value = replace( val = value sub = `\"` with = `"` occ = 0 ).
      INSERT temp20 INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


  METHOD create_new_item.

    " Date.now( ) in the original - a timestamp keeps the key unique as well
    DATA now TYPE p LENGTH 8 DECIMALS 0.
    DATA key TYPE string.
    DATA temp21 TYPE z2ui5_cl_smpc_app_651=>ty_s_item.
    DATA temp4 TYPE z2ui5_cl_smpc_app_651=>ty_s_item-sharing.
    GET TIME STAMP FIELD now.
    
    key = |key_{ now }|.

    
    CLEAR temp21.
    temp21-key = key.
    temp21-title = client->get_event_arg( ).
    temp21-author = `sample`.
    temp21-favorite = abap_true.
    temp21-visible = abap_true.
    temp21-executeonselect = client->get_event_arg( 4 ).
    temp21-rename = abap_true.
    temp21-changeable = abap_true.
    temp21-remove = abap_true.
    
    IF client->get_event_arg( 6 ) = abap_true.
      temp4 = `Public`.
    ELSE.
      temp4 = `Private`.
    ENDIF.
    temp21-sharing = temp4.
    INSERT temp21 INTO TABLE t_items.

    IF client->get_event_arg( 5 ) = abap_true.
      defaultkey = key.
    ENDIF.

    show_message( |New view '{ client->get_event_arg( ) }' created with key:'{ key }'.| ).

  ENDMETHOD.


  METHOD show_message.

    DATA temp22 TYPE string_table.
    CLEAR temp22.
    INSERT `MESSAGE_TOAST` INTO TABLE temp22.
    INSERT `show` INTO TABLE temp22.
    INSERT text INTO TABLE temp22.
    INSERT `{"closeOnBrowserNavigation":true}` INTO TABLE temp22.
    client->follow_up_action( val   = client->cs_event-control_global
                              t_arg = temp22 ).

  ENDMETHOD.


  METHOD model_init.

    DATA temp24 LIKE t_items.
    DATA temp25 LIKE LINE OF temp24.
    CLEAR temp24.
    
    temp25-key = `Standard`.
    temp25-title = `Entry1`.
    temp25-author = `B`.
    temp25-favorite = abap_true.
    temp25-visible = abap_true.
    temp25-executeonselect = abap_false.
    temp25-rename = abap_false.
    temp25-changeable = abap_false.
    temp25-remove = abap_false.
    temp25-sharing = `Public`.
    INSERT temp25 INTO TABLE temp24.
    temp25-key = `2`.
    temp25-title = `Entry2`.
    temp25-author = `A`.
    temp25-favorite = abap_true.
    temp25-visible = abap_true.
    temp25-executeonselect = abap_false.
    temp25-rename = abap_true.
    temp25-changeable = abap_true.
    temp25-remove = abap_true.
    temp25-sharing = `Private`.
    INSERT temp25 INTO TABLE temp24.
    temp25-key = `3`.
    temp25-title = `Entry3`.
    temp25-author = `A`.
    temp25-favorite = abap_true.
    temp25-visible = abap_true.
    temp25-executeonselect = abap_true.
    temp25-rename = abap_true.
    temp25-changeable = abap_true.
    temp25-remove = abap_true.
    temp25-sharing = `Private`.
    INSERT temp25 INTO TABLE temp24.
    temp25-key = `4`.
    temp25-title = `Entry4`.
    temp25-author = `A`.
    temp25-favorite = abap_false.
    temp25-visible = abap_true.
    temp25-executeonselect = abap_true.
    temp25-rename = abap_false.
    temp25-changeable = abap_true.
    temp25-remove = abap_false.
    temp25-sharing = `Public`.
    INSERT temp25 INTO TABLE temp24.
    t_items = temp24.

    selectedkey = `2`.
    defaultkey  = `2`.

  ENDMETHOD.

ENDCLASS.
