" @keywords tree sap.m treejsonlazyloading standardtreeitem
" @summary Shows how lazy loading with a JSON model can be done using the toggleOpenState event.
" @origin sap.m.sample.TreeJSONLazyLoading - https://sdk.openui5.org/entity/sap.m.Tree/sample/sap.m.sample.TreeJSONLazyLoading (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_496 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " one structure per nesting depth (ABAP has no recursive types) - the number is the depth the controller's loadData( iLevel ) builds, 1 = a root node
    TYPES:
      BEGIN OF ty_s_leaf,
        text  TYPE string,
        dummy TYPE abap_bool,
      END OF ty_s_leaf,
      BEGIN OF ty_s_great_great_grandchild,
        text  TYPE string,
        dummy TYPE abap_bool,
        nodes TYPE STANDARD TABLE OF ty_s_leaf WITH DEFAULT KEY,
      END OF ty_s_great_great_grandchild,
      BEGIN OF ty_s_great_grandchild,
        text  TYPE string,
        dummy TYPE abap_bool,
        nodes TYPE STANDARD TABLE OF ty_s_great_great_grandchild WITH DEFAULT KEY,
      END OF ty_s_great_grandchild,
      BEGIN OF ty_s_grandchild,
        text  TYPE string,
        dummy TYPE abap_bool,
        nodes TYPE STANDARD TABLE OF ty_s_great_grandchild WITH DEFAULT KEY,
      END OF ty_s_grandchild,
      BEGIN OF ty_s_child,
        text  TYPE string,
        dummy TYPE abap_bool,
        nodes TYPE STANDARD TABLE OF ty_s_grandchild WITH DEFAULT KEY,
      END OF ty_s_child,
      BEGIN OF ty_s_root,
        text  TYPE string,
        dummy TYPE abap_bool,
        nodes TYPE STANDARD TABLE OF ty_s_child WITH DEFAULT KEY,
      END OF ty_s_root.

    TYPES temp1_537bfb1c6c TYPE STANDARD TABLE OF ty_s_root WITH DEFAULT KEY.
DATA t_nodes TYPE temp1_537bfb1c6c.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_496 IMPLEMENTATION.

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
    INSERT `${$parameters>/itemIndex}` INTO TABLE temp1.
    INSERT `${$parameters>/itemContext}.getPath()` INTO TABLE temp1.
    INSERT `${$parameters>/expanded}` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns`     v = `sap.m`

        )->ele( `Tree`
            )->a( n = `id`                 v = `Tree`
            " items path '/' - bind the root table; the nested `nodes` drive the depth
            )->a( n = `items`              v = client->_bind( t_nodes )
            )->a( n = `busyIndicatorDelay` v = `0`
            " onToggleOpenState toasts the three event parameters and loads the level
            " below when the expanded node still holds the dummy child - the same three
            " values travel to the backend, which appends the nodes
            )->a( n = `toggleOpenState`    v = client->_event( val   = `TOGGLE`
                                                               t_arg = temp1 )

            )->tag( `StandardTreeItem`
                )->a( n = `title` v = `{TEXT}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.

    TYPES temp52 TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
DATA indices  TYPE temp52.
    DATA segments TYPE string_table.
    DATA node1    TYPE REF TO ty_s_root.
    DATA node2    TYPE REF TO ty_s_child.
    DATA node3    TYPE REF TO ty_s_grandchild.
    DATA node4    TYPE REF TO ty_s_great_grandchild.
    DATA node5    TYPE REF TO ty_s_great_great_grandchild.
      DATA item_index TYPE string.
      DATA item_path TYPE string.
      DATA temp3 TYPE abap_bool.
      DATA expanded LIKE temp3.
      DATA temp4 TYPE string.
      DATA segment LIKE LINE OF segments.
          DATA temp5 LIKE LINE OF indices.
          DATA temp1 LIKE LINE OF indices.
      DATA level TYPE i.
      DATA suffix TYPE string.
      DATA suffix2 TYPE string.
      DATA is_last TYPE abap_bool.
      DATA temp53 TYPE xsdboolean.
          FIELD-SYMBOLS <temp6> TYPE z2ui5_cl_smpc_app_496=>ty_s_root.
          FIELD-SYMBOLS <temp1> LIKE LINE OF indices.
          DATA temp27 LIKE sy-tabix.
          DATA temp7 TYPE z2ui5_cl_smpc_app_496=>ty_s_root-nodes.
          DATA temp8 LIKE LINE OF temp7.
          DATA temp2 TYPE z2ui5_cl_smpc_app_496=>ty_s_child-nodes.
          DATA temp6 LIKE LINE OF temp2.
          DATA temp23 TYPE z2ui5_cl_smpc_app_496=>ty_s_grandchild-text.
          DATA temp54 TYPE xsdboolean.
          FIELD-SYMBOLS <temp9> TYPE z2ui5_cl_smpc_app_496=>ty_s_child.
          FIELD-SYMBOLS <temp28> LIKE LINE OF t_nodes.
          DATA temp29 LIKE sy-tabix.
          FIELD-SYMBOLS <temp2> LIKE LINE OF indices.
          DATA temp28 LIKE sy-tabix.
          FIELD-SYMBOLS <temp29> LIKE LINE OF indices.
          DATA temp30 LIKE sy-tabix.
          DATA temp10 TYPE z2ui5_cl_smpc_app_496=>ty_s_child-nodes.
          DATA temp11 LIKE LINE OF temp10.
          DATA temp9 TYPE z2ui5_cl_smpc_app_496=>ty_s_grandchild-nodes.
          DATA temp12 LIKE LINE OF temp9.
          DATA temp24 TYPE z2ui5_cl_smpc_app_496=>ty_s_great_grandchild-text.
          DATA temp55 TYPE xsdboolean.
          FIELD-SYMBOLS <temp12> TYPE z2ui5_cl_smpc_app_496=>ty_s_grandchild.
          FIELD-SYMBOLS <temp30> LIKE LINE OF t_nodes.
          DATA temp31 LIKE sy-tabix.
          FIELD-SYMBOLS <temp31> LIKE LINE OF indices.
          DATA temp32 LIKE sy-tabix.
          FIELD-SYMBOLS <temp33> LIKE LINE OF <temp30>-nodes.
          DATA temp34 LIKE sy-tabix.
          FIELD-SYMBOLS <temp3> LIKE LINE OF indices.
          DATA temp37 LIKE sy-tabix.
          FIELD-SYMBOLS <temp38> LIKE LINE OF indices.
          DATA temp39 LIKE sy-tabix.
          DATA temp13 TYPE z2ui5_cl_smpc_app_496=>ty_s_grandchild-nodes.
          DATA temp14 LIKE LINE OF temp13.
          DATA temp15 TYPE z2ui5_cl_smpc_app_496=>ty_s_great_grandchild-nodes.
          DATA temp18 LIKE LINE OF temp15.
          DATA temp25 TYPE z2ui5_cl_smpc_app_496=>ty_s_great_great_grandchild-text.
          DATA temp56 TYPE xsdboolean.
          FIELD-SYMBOLS <temp15> TYPE z2ui5_cl_smpc_app_496=>ty_s_great_grandchild.
          FIELD-SYMBOLS <temp32> LIKE LINE OF t_nodes.
          DATA temp33 LIKE sy-tabix.
          FIELD-SYMBOLS <temp35> LIKE LINE OF indices.
          DATA temp36 LIKE sy-tabix.
          FIELD-SYMBOLS <temp37> LIKE LINE OF <temp32>-nodes.
          DATA temp38 LIKE sy-tabix.
          FIELD-SYMBOLS <temp40> LIKE LINE OF indices.
          DATA temp41 LIKE sy-tabix.
          FIELD-SYMBOLS <temp42> LIKE LINE OF <temp37>-nodes.
          DATA temp43 LIKE sy-tabix.
          FIELD-SYMBOLS <temp4> LIKE LINE OF indices.
          DATA temp44 LIKE sy-tabix.
          FIELD-SYMBOLS <temp45> LIKE LINE OF indices.
          DATA temp46 LIKE sy-tabix.
          DATA temp16 TYPE z2ui5_cl_smpc_app_496=>ty_s_great_grandchild-nodes.
          DATA temp17 LIKE LINE OF temp16.
          DATA temp21 TYPE z2ui5_cl_smpc_app_496=>ty_s_great_great_grandchild-nodes.
          DATA temp22 LIKE LINE OF temp21.
          DATA temp26 TYPE z2ui5_cl_smpc_app_496=>ty_s_leaf-text.
          DATA temp57 TYPE xsdboolean.
          FIELD-SYMBOLS <temp18> TYPE z2ui5_cl_smpc_app_496=>ty_s_great_great_grandchild.
          FIELD-SYMBOLS <temp34> LIKE LINE OF t_nodes.
          DATA temp35 LIKE sy-tabix.
          FIELD-SYMBOLS <temp39> LIKE LINE OF indices.
          DATA temp40 LIKE sy-tabix.
          FIELD-SYMBOLS <temp41> LIKE LINE OF <temp34>-nodes.
          DATA temp42 LIKE sy-tabix.
          FIELD-SYMBOLS <temp44> LIKE LINE OF indices.
          DATA temp45 LIKE sy-tabix.
          FIELD-SYMBOLS <temp46> LIKE LINE OF <temp41>-nodes.
          DATA temp47 LIKE sy-tabix.
          FIELD-SYMBOLS <temp47> LIKE LINE OF indices.
          DATA temp48 LIKE sy-tabix.
          FIELD-SYMBOLS <temp49> LIKE LINE OF <temp46>-nodes.
          DATA temp50 LIKE sy-tabix.
          FIELD-SYMBOLS <temp5> LIKE LINE OF indices.
          DATA temp49 LIKE sy-tabix.
          FIELD-SYMBOLS <temp50> LIKE LINE OF indices.
          DATA temp51 LIKE sy-tabix.
          DATA temp19 TYPE z2ui5_cl_smpc_app_496=>ty_s_great_great_grandchild-nodes.
          DATA temp20 LIKE LINE OF temp19.

    IF client->get_event( ) = `TOGGLE`.

      
      item_index = client->get_event_arg( ).
      
      item_path  = client->get_event_arg( 2 ).
      
      temp3 = client->get_event_arg( 3 ).
      
      expanded = temp3.

      
      IF expanded = abap_true.
        temp4 = `true`.
      ELSE.
        temp4 = `false`.
      ENDIF.
      client->message_toast_display(
          text     = |Item index: { item_index }| &&
                     |\nItem context (path): { item_path }| &&
                     |\nExpanded: { temp4 }|
          duration = `5000` ).

      IF expanded = abap_false.
        RETURN.
      ENDIF.

      " abap2UI5 sends /T_NODES/1/NODES/0 - NOT the original sample's /1/nodes/0:
      " the root is the bound attribute's name and the model is serialized
      " upper-cased, so matching a literal `nodes` never fires. Keep the numeric
      " segments and ignore the named ones, the way app 546's index_of does.
      SPLIT item_path AT `/` INTO TABLE segments.
      
      LOOP AT segments INTO segment.
        IF segment IS NOT INITIAL AND segment CO `0123456789`.
          
          temp5 = segment.
          
          temp1 = temp5 + 1.
          APPEND temp1 TO indices.
        ENDIF.
      ENDLOOP.

      " loadData replaces the dummy child of the expanded node with the next two
      " nodes; the level decides their name and whether they stay expandable
      
      level   = lines( indices ) - 1.
      
      suffix  = repeat( val = `-1` occ = level + 2 ).
      
      suffix2 = repeat( val = `-2` occ = level + 2 ).
      
      
      temp53 = boolc( level >= 5 ).
      is_last = temp53.

      CASE lines( indices ).

        WHEN 1.
          
          
          
          temp27 = sy-tabix.
          READ TABLE indices INDEX 1 ASSIGNING <temp1>.
          sy-tabix = temp27.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE t_nodes INDEX <temp1> ASSIGNING <temp6>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.
GET REFERENCE OF <temp6> INTO node1.
          IF node1 IS INITIAL.
            RETURN.
          ENDIF.
          
          CLEAR temp7.
          
          temp8-text = |Node{ suffix }|.
          INSERT temp8 INTO TABLE temp7.
          temp8-text = |Node{ suffix2 }|.
          
          CLEAR temp2.
          
          
          IF is_last = abap_true.
            temp23 = `Last node`.
          ELSE.
            temp23 = ``.
          ENDIF.
          temp6-text = temp23.
          
          temp54 = boolc( is_last = abap_false ).
          temp6-dummy = temp54.
          INSERT temp6 INTO TABLE temp2.
          temp8-nodes = temp2.
          INSERT temp8 INTO TABLE temp7.
          node1->nodes = temp7.

        WHEN 2.
          
          
          
          temp29 = sy-tabix.
          
          
          temp28 = sy-tabix.
          READ TABLE indices INDEX 1 ASSIGNING <temp2>.
          sy-tabix = temp28.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE t_nodes INDEX <temp2> ASSIGNING <temp28>.
          sy-tabix = temp29.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp30 = sy-tabix.
          READ TABLE indices INDEX 2 ASSIGNING <temp29>.
          sy-tabix = temp30.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp28>-nodes INDEX <temp29> ASSIGNING <temp9>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.
GET REFERENCE OF <temp9> INTO node2.
          IF node2 IS INITIAL.
            RETURN.
          ENDIF.
          
          CLEAR temp10.
          
          temp11-text = |Node{ suffix }|.
          INSERT temp11 INTO TABLE temp10.
          temp11-text = |Node{ suffix2 }|.
          
          CLEAR temp9.
          
          
          IF is_last = abap_true.
            temp24 = `Last node`.
          ELSE.
            temp24 = ``.
          ENDIF.
          temp12-text = temp24.
          
          temp55 = boolc( is_last = abap_false ).
          temp12-dummy = temp55.
          INSERT temp12 INTO TABLE temp9.
          temp11-nodes = temp9.
          INSERT temp11 INTO TABLE temp10.
          node2->nodes = temp10.

        WHEN 3.
          
          
          
          temp31 = sy-tabix.
          
          
          temp32 = sy-tabix.
          READ TABLE indices INDEX 1 ASSIGNING <temp31>.
          sy-tabix = temp32.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE t_nodes INDEX <temp31> ASSIGNING <temp30>.
          sy-tabix = temp31.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp34 = sy-tabix.
          
          
          temp37 = sy-tabix.
          READ TABLE indices INDEX 2 ASSIGNING <temp3>.
          sy-tabix = temp37.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp30>-nodes INDEX <temp3> ASSIGNING <temp33>.
          sy-tabix = temp34.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp39 = sy-tabix.
          READ TABLE indices INDEX 3 ASSIGNING <temp38>.
          sy-tabix = temp39.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp33>-nodes INDEX <temp38> ASSIGNING <temp12>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.
GET REFERENCE OF <temp12> INTO node3.
          IF node3 IS INITIAL.
            RETURN.
          ENDIF.
          
          CLEAR temp13.
          
          temp14-text = |Node{ suffix }|.
          INSERT temp14 INTO TABLE temp13.
          temp14-text = |Node{ suffix2 }|.
          
          CLEAR temp15.
          
          
          IF is_last = abap_true.
            temp25 = `Last node`.
          ELSE.
            temp25 = ``.
          ENDIF.
          temp18-text = temp25.
          
          temp56 = boolc( is_last = abap_false ).
          temp18-dummy = temp56.
          INSERT temp18 INTO TABLE temp15.
          temp14-nodes = temp15.
          INSERT temp14 INTO TABLE temp13.
          node3->nodes = temp13.

        WHEN 4.
          
          
          
          temp33 = sy-tabix.
          
          
          temp36 = sy-tabix.
          READ TABLE indices INDEX 1 ASSIGNING <temp35>.
          sy-tabix = temp36.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE t_nodes INDEX <temp35> ASSIGNING <temp32>.
          sy-tabix = temp33.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp38 = sy-tabix.
          
          
          temp41 = sy-tabix.
          READ TABLE indices INDEX 2 ASSIGNING <temp40>.
          sy-tabix = temp41.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp32>-nodes INDEX <temp40> ASSIGNING <temp37>.
          sy-tabix = temp38.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp43 = sy-tabix.
          
          
          temp44 = sy-tabix.
          READ TABLE indices INDEX 3 ASSIGNING <temp4>.
          sy-tabix = temp44.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp37>-nodes INDEX <temp4> ASSIGNING <temp42>.
          sy-tabix = temp43.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp46 = sy-tabix.
          READ TABLE indices INDEX 4 ASSIGNING <temp45>.
          sy-tabix = temp46.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp42>-nodes INDEX <temp45> ASSIGNING <temp15>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.
GET REFERENCE OF <temp15> INTO node4.
          IF node4 IS INITIAL.
            RETURN.
          ENDIF.
          
          CLEAR temp16.
          
          temp17-text = |Node{ suffix }|.
          INSERT temp17 INTO TABLE temp16.
          temp17-text = |Node{ suffix2 }|.
          
          CLEAR temp21.
          
          
          IF is_last = abap_true.
            temp26 = `Last node`.
          ELSE.
            temp26 = ``.
          ENDIF.
          temp22-text = temp26.
          
          temp57 = boolc( is_last = abap_false ).
          temp22-dummy = temp57.
          INSERT temp22 INTO TABLE temp21.
          temp17-nodes = temp21.
          INSERT temp17 INTO TABLE temp16.
          node4->nodes = temp16.

        WHEN 5.
          
          
          
          temp35 = sy-tabix.
          
          
          temp40 = sy-tabix.
          READ TABLE indices INDEX 1 ASSIGNING <temp39>.
          sy-tabix = temp40.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE t_nodes INDEX <temp39> ASSIGNING <temp34>.
          sy-tabix = temp35.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp42 = sy-tabix.
          
          
          temp45 = sy-tabix.
          READ TABLE indices INDEX 2 ASSIGNING <temp44>.
          sy-tabix = temp45.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp34>-nodes INDEX <temp44> ASSIGNING <temp41>.
          sy-tabix = temp42.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp47 = sy-tabix.
          
          
          temp48 = sy-tabix.
          READ TABLE indices INDEX 3 ASSIGNING <temp47>.
          sy-tabix = temp48.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp41>-nodes INDEX <temp47> ASSIGNING <temp46>.
          sy-tabix = temp47.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp50 = sy-tabix.
          
          
          temp49 = sy-tabix.
          READ TABLE indices INDEX 4 ASSIGNING <temp5>.
          sy-tabix = temp49.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp46>-nodes INDEX <temp5> ASSIGNING <temp49>.
          sy-tabix = temp50.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          
          
          temp51 = sy-tabix.
          READ TABLE indices INDEX 5 ASSIGNING <temp50>.
          sy-tabix = temp51.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          READ TABLE <temp49>-nodes INDEX <temp50> ASSIGNING <temp18>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.
GET REFERENCE OF <temp18> INTO node5.
          IF node5 IS INITIAL.
            RETURN.
          ENDIF.
          
          CLEAR temp19.
          
          temp20-text = |Node{ suffix }|.
          INSERT temp20 INTO TABLE temp19.
          temp20-text = |Node{ suffix2 }|.
          INSERT temp20 INTO TABLE temp19.
          node5->nodes = temp19.

        WHEN OTHERS.
          RETURN.
      ENDCASE.

    ENDIF.

  ENDMETHOD.


  METHOD model_init.

    " loadData( ) seeds the two root nodes; every deeper level is fetched when its
    " parent is expanded
    DATA temp21 LIKE t_nodes.
    DATA temp22 LIKE LINE OF temp21.
    DATA temp23 TYPE z2ui5_cl_smpc_app_496=>ty_s_root-nodes.
    DATA temp24 LIKE LINE OF temp23.
    CLEAR temp21.
    
    temp22-text = `Node-1`.
    INSERT temp22 INTO TABLE temp21.
    temp22-text = `Node-2`.
    
    CLEAR temp23.
    
    temp24-text = ``.
    temp24-dummy = abap_true.
    INSERT temp24 INTO TABLE temp23.
    temp22-nodes = temp23.
    INSERT temp22 INTO TABLE temp21.
    t_nodes = temp21.

  ENDMETHOD.

ENDCLASS.
