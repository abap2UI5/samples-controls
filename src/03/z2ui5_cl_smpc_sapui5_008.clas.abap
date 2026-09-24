" @keywords networkgraph.graph graph layeredlayout node elementattribute actionbutton nodeimage line quickview quickviewpage avatar quickviewgroup
" @summary sap.suite.ui.commons.networkgraph.Graph expressed in abap2UI5 - a SAPUI5-only control, so the demo kit original is outside OpenUI5 and this is orientation rather than a 1:1 port.
" @origin sap.suite.ui.commons.networkgraph.Graph - https://ui5.sap.com/#/entity/sap.suite.ui.commons.networkgraph.Graph (status: collection - SAPUI5-only, hand-written, not a port)
"! <p class="shorttext">sap.suite.ui.commons - networkgraph.Graph</p>
"!
"! SAPUI5-only control: it ships with SAPUI5, not with OpenUI5, so there is no
"! demo kit original in this repo's sample universe and no 1:1 port (AGENTS section 3).
"! Collected here as orientation - how the control is expressed in abap2UI5.
"!
"! SAPUI5 demo kit: https://ui5.sap.com/#/entity/sap.suite.ui.commons.networkgraph.Graph
CLASS z2ui5_cl_smpc_sapui5_008 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_attributes3,
        label TYPE i,
        value TYPE string,
      END OF ty_s_attributes3.
    TYPES ty_t_attributes3 TYPE STANDARD TABLE OF ty_s_attributes3 WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_nodes2,
        id         TYPE string,
        title      TYPE string,
        src        TYPE string,
        attributes TYPE ty_t_attributes3,
        team       TYPE i,
        supervisor TYPE string,
        location   TYPE string,
        position   TYPE string,
        email      TYPE string,
        phone      TYPE string,
      END OF ty_s_nodes2.
    TYPES:
      BEGIN OF ty_s_lines4,
        from TYPE string,
        to   TYPE string,
      END OF ty_s_lines4.
    TYPES ty_t_nodes2 TYPE STANDARD TABLE OF ty_s_nodes2 WITH DEFAULT KEY.
    TYPES ty_t_lines4 TYPE STANDARD TABLE OF ty_s_lines4 WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_json1,
        nodes TYPE ty_t_nodes2,
        lines TYPE ty_t_lines4,
      END OF ty_s_json1.
    DATA mt_data TYPE ty_s_json1.

    METHODS view_display.
    METHODS on_event.
    METHODS detail_popover
      IMPORTING
        id   TYPE string
        node TYPE ty_s_nodes2.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

  PRIVATE SECTION.
ENDCLASS.

CLASS z2ui5_cl_smpc_sapui5_008 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.
      DATA temp1 TYPE z2ui5_cl_smpc_sapui5_008=>ty_t_nodes2.
      DATA temp2 LIKE LINE OF temp1.
      DATA temp5 TYPE z2ui5_cl_smpc_sapui5_008=>ty_t_attributes3.
      DATA temp6 LIKE LINE OF temp5.
      DATA temp7 TYPE z2ui5_cl_smpc_sapui5_008=>ty_t_attributes3.
      DATA temp8 LIKE LINE OF temp7.
      DATA temp9 TYPE z2ui5_cl_smpc_sapui5_008=>ty_t_attributes3.
      DATA temp10 LIKE LINE OF temp9.
      DATA temp3 TYPE z2ui5_cl_smpc_sapui5_008=>ty_t_lines4.
      DATA temp4 LIKE LINE OF temp3.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      CLEAR mt_data.
      
      CLEAR temp1.
      
      temp2-id = `Dinter`.
      temp2-title = `Sophie Dinter`.
      temp2-src = `https://ui5.sap.com/test-resources/sap/suite/ui/commons/demokit/images/people/female_IngallsB.jpg`.
      
      CLEAR temp5.
      
      temp6-label = 35.
      temp6-value = ``.
      INSERT temp6 INTO TABLE temp5.
      temp2-attributes = temp5.
      temp2-team = 13.
      temp2-location = `Walldorf`.
      temp2-position = `lobal Solutions Manager`.
      temp2-email = `sophie.dinter@example.com`.
      temp2-phone = `+000 423 230 000`.
      INSERT temp2 INTO TABLE temp1.
      temp2-id = `Ninsei`.
      temp2-title = `Yamasaki Ninsei`.
      temp2-src = `https://ui5.sap.com/test-resources/sap/suite/ui/commons/demokit/images/people/male_GordonR.jpg`.
      
      CLEAR temp7.
      
      temp8-label = 9.
      temp8-value = ``.
      INSERT temp8 INTO TABLE temp7.
      temp2-attributes = temp7.
      temp2-supervisor = `Dinter`.
      temp2-team = 9.
      temp2-location = `Walldorf`.
      temp2-position = `Lead Markets Manage`.
      temp2-email = `yamasaki.ninsei@example.com`.
      temp2-phone = `+000 423 230 002`.
      INSERT temp2 INTO TABLE temp1.
      temp2-id = `Mills`.
      temp2-title = `Henry Mills`.
      temp2-src = `https://ui5.sap.com/test-resources/sap/suite/ui/commons/demokit/images/people/male_MillerM.jpg`.
      
      CLEAR temp9.
      
      temp10-label = 4.
      temp10-value = ``.
      INSERT temp10 INTO TABLE temp9.
      temp2-attributes = temp9.
      temp2-supervisor = `Ninsei`.
      temp2-team = 4.
      temp2-location = `Praha`.
      temp2-position = `Sales Manager`.
      temp2-email = `henry.mills@example.com`.
      temp2-phone = `+000 423 232 003`.
      INSERT temp2 INTO TABLE temp1.
      temp2-id = `Polak`.
      temp2-title = `Adam Polak`.
      temp2-src = `https://ui5.sap.com/test-resources/sap/suite/ui/commons/demokit/images/people/male_PlatteR.jpg`.
      temp2-supervisor = `Mills`.
      temp2-location = `Praha`.
      temp2-position = `Marketing Specialist`.
      temp2-email = `adam.polak@example.com`.
      temp2-phone = `+000 423 232 004`.
      INSERT temp2 INTO TABLE temp1.
      temp2-id = `Sykorova`.
      temp2-title = `Vlasta Sykorova`.
      temp2-src = `https://ui5.sap.com/test-resources/sap/suite/ui/commons/demokit/images/people/female_SpringS.jpg`.
      temp2-supervisor = `Mills`.
      temp2-location = `Praha`.
      temp2-position = `Human Assurance Officer`.
      temp2-email = `vlasta.sykorova@example.com`.
      temp2-phone = `+000 423 232 005`.
      INSERT temp2 INTO TABLE temp1.
      mt_data-nodes = temp1.
      
      CLEAR temp3.
      
      temp4-from = `Dinter`.
      temp4-to = `Ninsei`.
      INSERT temp4 INTO TABLE temp3.
      temp4-from = `Ninsei`.
      temp4-to = `Mills`.
      INSERT temp4 INTO TABLE temp3.
      temp4-from = `Mills`.
      temp4-to = `Polak`.
      INSERT temp4 INTO TABLE temp3.
      temp4-from = `Mills`.
      temp4-to = `Sykorova`.
      INSERT temp4 INTO TABLE temp3.
      mt_data-lines = temp3.

      view_display( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ENDIF.

    on_event( ).

  ENDMETHOD.


  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 TYPE string_table.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    CLEAR temp1.
    INSERT `${$source>/id}` INTO TABLE temp1.
    INSERT `${ID}` INTO TABLE temp1.
    view->ele( n = `View` ns = `mvc`
        )->a( n = `displayBlock`       v = `true`
        )->a( n = `height`             v = `100%`
        )->a( n = `xmlns`              v = `sap.m`
        )->a( n = `xmlns:mvc`          v = `sap.ui.core.mvc`
        )->a( n = `xmlns:networkgraph` v = `sap.suite.ui.commons.networkgraph`
        )->a( n = `xmlns:nglayout`     v = `sap.suite.ui.commons.networkgraph.layout`

        )->ele( `Page`
            )->a( n = `title`          v = `abap2UI5 - Network Graph - Org Tree`
            )->a( n = `navButtonPress` v = client->_event_nav_app_leave( )
            )->a( n = `showNavButton`  b = client->check_app_prev_stack( )

            )->ele( n = `Graph` ns = `networkgraph`
                )->a( n = `id`              v = `graph`
                )->a( n = `orientation`     v = `TopBottom`
                )->a( n = `nodes`           v = client->_bind( mt_data-nodes )
                )->a( n = `lines`           v = client->_bind( mt_data-lines )
                )->a( n = `layout`          v = `Layered`
                )->a( n = `searchSuggest`   v = `suggest`
                )->a( n = `search`          v = `search`
                )->a( n = `enableWheelZoom` b = abap_false

                )->ele( n = `layoutAlgorithm` ns = `networkgraph`
                    )->tag( n = `LayeredLayout` ns = `nglayout`
                        )->a( n = `nodePlacement` v = `Simple`
                        )->a( n = `nodeSpacing`   v = `40`
                        )->a( n = `mergeEdges`    b = abap_true

                )->end(

                )->ele( n = `nodes` ns = `networkgraph`
                    )->ele( n = `Node` ns = `networkgraph`
                        )->a( n = `icon`                  v = `sap-icon://action-settings`
                        )->a( n = `key`                   v = `{ID}`
                        )->a( n = `description`           v = `{TITLE}`
                        )->a( n = `title`                 v = `{TITLE}`
                        )->a( n = `width`                 v = `90`
                        )->a( n = `collapsed`             v = `{COLLAPSED}`
                        )->a( n = `attributes`            v = `{ATTRIBUTES}`
                        )->a( n = `descriptionLineSize`   v = `0`
                        )->a( n = `shape`                 v = `Box`
                        )->a( n = `showActionLinksButton` b = abap_false
                        )->a( n = `showDetailButton`      b = abap_false

                        )->ele( n = `attributes` ns = `networkgraph`
                            )->tag( n = `ElementAttribute` ns = `networkgraph`
                                )->a( n = `label` v = `{LABEL}`
                                )->a( n = `value` v = `{VALUE}`

                        )->end(

                        )->ele( `actionButtons`
                            )->tag( n = `ActionButton` ns = `networkgraph`
                                " the id is deliberately not set: the graph assigns one, and the
                                " press handler reads it back through ${$source>/id}
                                )->a( n = `position` v = `Left`
                                )->a( n = `title`    v = `Detail`
                                )->a( n = `icon`     v = `sap-icon://employee`
                                )->a( n = `press`    v = client->_event( val   = `DETAIL_POPOVER`
                                                                         t_arg = temp1 )

                        )->end(

                        )->ele( n = `image` ns = `networkgraph`
                            )->tag( n = `NodeImage` ns = `networkgraph`
                                )->a( n = `src`    v = `{SRC}`
                                )->a( n = `width`  v = `80`
                                )->a( n = `height` v = `100`

                        )->end(
                    )->end(
                )->end(

                )->ele( `lines`
                    )->tag( n = `Line` ns = `networkgraph`
                        )->a( n = `from`             v = `{FROM}`
                        )->a( n = `to`               v = `{TO}`
                        )->a( n = `arrowOrientation` v = `None`
                        )->a( n = `press`            v = client->_event( `LINE_PRESS` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA t_arg TYPE string_table.
        DATA s_node TYPE z2ui5_cl_smpc_sapui5_008=>ty_s_nodes2.
        FIELD-SYMBOLS <temp5> LIKE LINE OF t_arg.
        DATA temp6 LIKE sy-tabix.
          FIELD-SYMBOLS <temp3> LIKE LINE OF t_arg.
          DATA temp4 LIKE sy-tabix.

    CASE client->get_event( ).
      WHEN `LINE_PRESS`.
        client->message_toast_display( `LINE_PRESSED` ).

      WHEN `DETAIL_POPOVER`.
        
        t_arg = client->get( )-t_event_arg.

        
        
        
        temp6 = sy-tabix.
        READ TABLE t_arg INDEX 2 ASSIGNING <temp5>.
        sy-tabix = temp6.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        READ TABLE mt_data-nodes INTO s_node WITH KEY id = <temp5>.

        IF sy-subrc = 0.
          
          
          temp4 = sy-tabix.
          READ TABLE t_arg INDEX 1 ASSIGNING <temp3>.
          sy-tabix = temp4.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          detail_popover( id   = <temp3>
                          node = s_node ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD detail_popover.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA group TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA temp5 TYPE string.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    
    group = view->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`

        )->ele( `QuickView`
            )->a( n = `placement` v = `Left`

            )->ele( `QuickViewPage`
                )->a( n = `header` v = `Employee`
                )->a( n = `title`       t = node-title
                )->a( n = `description` t = node-position

                )->ele( `avatar`
                    )->tag( `Avatar`
                        )->a( n = `src`          t = node-src
                        )->a( n = `displayShape` v = `Square`

                )->end(

                )->ele( `QuickViewGroup`
                    )->a( n = `heading` v = `Contact Detail`

                    )->tag( `QuickViewGroupElement`
                        )->a( n = `label` v = `Location`
                        )->a( n = `value` t = node-location
                    )->tag( `QuickViewGroupElement`
                        )->a( n = `label` v = `Mobile`
                        )->a( n = `value` t = node-phone
                        )->a( n = `type` v = `phone`
                    )->tag( `QuickViewGroupElement`
                        )->a( n = `label` v = `Email`
                        )->a( n = `value`        t = node-email
                        )->a( n = `type` v = `email`
                        )->a( n = `emailSubject` t = |Contact{ node-id }|

                )->end( ).

    IF node-team IS NOT INITIAL.
      
      temp5 = node-team.
      group->ele( `QuickViewGroup`
          )->a( n = `heading` v = `Team`

          )->tag( `QuickViewGroupElement`
              )->a( n = `label` v = `Size`
              )->a( n = `value` t = temp5 ).
    ENDIF.

    client->popover_display( xml = view->stringify( ) by_id = id ).

  ENDMETHOD.

ENDCLASS.
