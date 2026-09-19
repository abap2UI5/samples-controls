" @keywords objectpagesubsection object sub section sap.uxap objectpagesubsectionsized objectpagelayout objectpageheader togglebutton
" @summary This example shows how the size of the blocks and be either specified or automatic
" @origin sap.uxap.sample.ObjectPageSubSectionSized - https://sdk.openui5.org/entity/sap.uxap.ObjectPageSubSection/sample/sap.uxap.sample.ObjectPageSubSectionSized (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_599 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " the ConfigModel the two ToggleButtons write, folded onto root fields
    DATA subsection_layout TYPE string.
    DATA two_columns       TYPE abap_bool.

  PROTECTED SECTION.
    " the ten sections and their 86 subsections - the matrix the view walks
    TYPES:
      BEGIN OF ty_s_subsection,
        title       TYPE string,
        block_count TYPE i,
      END OF ty_s_subsection.
    TYPES ty_t_subsections TYPE STANDARD TABLE OF ty_s_subsection WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_s_section,
        title       TYPE string,
        subsections TYPE ty_t_subsections,
      END OF ty_s_section.
    TYPES ty_t_sections TYPE STANDARD TABLE OF ty_s_section WITH DEFAULT KEY.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_599 IMPLEMENTATION.

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

    " the sections in document order. A subsection title spells the columnLayout
    " of its blocks ('a-1' = auto, 1; '2-a-a' = 2, auto, auto), the last five
    " sections put one fixed layout on 1..6 blocks - see the sidecar on why the
    " layout itself has no target in the inlined form
    DATA temp1 TYPE ty_t_sections.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp4 LIKE LINE OF temp3.
    DATA temp5 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp6 LIKE LINE OF temp5.
    DATA temp7 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp8 LIKE LINE OF temp7.
    DATA temp9 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp10 LIKE LINE OF temp9.
    DATA temp11 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp12 LIKE LINE OF temp11.
    DATA temp13 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp14 LIKE LINE OF temp13.
    DATA temp15 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp16 LIKE LINE OF temp15.
    DATA temp17 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp18 LIKE LINE OF temp17.
    DATA temp19 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp20 LIKE LINE OF temp19.
    DATA temp21 TYPE z2ui5_cl_smpc_app_599=>ty_t_subsections.
    DATA temp22 LIKE LINE OF temp21.
    DATA t_sections LIKE temp1.
    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA sections TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA button_no TYPE i.
    DATA section LIKE LINE OF t_sections.
      DATA subsections TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA subsection LIKE LINE OF section-subsections.
        DATA blocks TYPE REF TO z2ui5_cl_ui5_view_builder.
    CLEAR temp1.
    
    temp2-title = `2 blocks`.
    
    CLEAR temp3.
    
    temp4-title = `a-1`.
    temp4-block_count = 2.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `a-2`.
    temp4-block_count = 2.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `a-3`.
    temp4-block_count = 2.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `1-a`.
    temp4-block_count = 2.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `2 -a`.
    temp4-block_count = 2.
    INSERT temp4 INTO TABLE temp3.
    temp4-title = `3-a`.
    temp4-block_count = 2.
    INSERT temp4 INTO TABLE temp3.
    temp2-subsections = temp3.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `3 blocks`.
    
    CLEAR temp5.
    
    temp6-title = `a-a-1`.
    temp6-block_count = 3.
    INSERT temp6 INTO TABLE temp5.
    temp6-title = `a-a-2`.
    temp6-block_count = 3.
    INSERT temp6 INTO TABLE temp5.
    temp6-title = `1-a-1`.
    temp6-block_count = 3.
    INSERT temp6 INTO TABLE temp5.
    temp6-title = `1-a-2`.
    temp6-block_count = 3.
    INSERT temp6 INTO TABLE temp5.
    temp6-title = `2-a-a`.
    temp6-block_count = 3.
    INSERT temp6 INTO TABLE temp5.
    temp6-title = `2-a-1`.
    temp6-block_count = 3.
    INSERT temp6 INTO TABLE temp5.
    temp6-title = `2-1-a`.
    temp6-block_count = 3.
    INSERT temp6 INTO TABLE temp5.
    temp2-subsections = temp5.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `4 blocks`.
    
    CLEAR temp7.
    
    temp8-title = `a-a-a-1`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp8-title = `a-a-a-2`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp8-title = `a-1-a-1`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp8-title = `1-a-1-a`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp8-title = `1-a-a-1`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp8-title = `a-2-a-1`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp8-title = `a-2-a-2`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp8-title = `2-a-a-2`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp8-title = `3-a-3-a`.
    temp8-block_count = 4.
    INSERT temp8 INTO TABLE temp7.
    temp2-subsections = temp7.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `5 blocks`.
    
    CLEAR temp9.
    
    temp10-title = `1-a-a-a-1`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `2-a-a-a-2`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `3-a-a-a-1`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `3-a-a-a-2`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-a-1-1-a`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-a-1-a-1`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-3-a-a-2`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-2-a-a-1`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-2-a-a-2`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-1-a-1-a`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-1-a-2-a`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-2-a-1-a`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `a-3-a-1-a`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `1-a-1-a-1`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `1-a-a-1-a`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `1-a-2-a-1`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `1-a-3-a-2`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `2-a-a-2-a`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp10-title = `3-a-a-3-a`.
    temp10-block_count = 5.
    INSERT temp10 INTO TABLE temp9.
    temp2-subsections = temp9.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `6 blocks`.
    
    CLEAR temp11.
    
    temp12-title = `1-a-a-a-a-1`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `1-a-a-a-a-3`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-a-a-1-a-a`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-a-a-2-a-a`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-a-1-a-a-a`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-a-2-a-a-a`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-a-3-a-a-a`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-1-a-a-1-a`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-2-a-a-2-a`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-3-a-a-3-a`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-1-a-a-a-1`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-2-a-a-a-1`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-1-a-1-a-1`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-2-a-2-a-2`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp12-title = `a-3-a-2-a-1`.
    temp12-block_count = 6.
    INSERT temp12 INTO TABLE temp11.
    temp2-subsections = temp11.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `All default`.
    
    CLEAR temp13.
    
    temp14-title = `1 block`.
    temp14-block_count = 1.
    INSERT temp14 INTO TABLE temp13.
    temp14-title = `2 blocks`.
    temp14-block_count = 2.
    INSERT temp14 INTO TABLE temp13.
    temp14-title = `3 blocks`.
    temp14-block_count = 3.
    INSERT temp14 INTO TABLE temp13.
    temp14-title = `4 blocks`.
    temp14-block_count = 4.
    INSERT temp14 INTO TABLE temp13.
    temp14-title = `5 blocks`.
    temp14-block_count = 5.
    INSERT temp14 INTO TABLE temp13.
    temp14-title = `6 blocks`.
    temp14-block_count = 6.
    INSERT temp14 INTO TABLE temp13.
    temp2-subsections = temp13.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `All 1`.
    
    CLEAR temp15.
    
    temp16-title = `1 block`.
    temp16-block_count = 1.
    INSERT temp16 INTO TABLE temp15.
    temp16-title = `2 blocks`.
    temp16-block_count = 2.
    INSERT temp16 INTO TABLE temp15.
    temp16-title = `3 blocks`.
    temp16-block_count = 3.
    INSERT temp16 INTO TABLE temp15.
    temp16-title = `4 blocks`.
    temp16-block_count = 4.
    INSERT temp16 INTO TABLE temp15.
    temp16-title = `5 blocks`.
    temp16-block_count = 5.
    INSERT temp16 INTO TABLE temp15.
    temp16-title = `6 blocks`.
    temp16-block_count = 6.
    INSERT temp16 INTO TABLE temp15.
    temp2-subsections = temp15.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `All 2`.
    
    CLEAR temp17.
    
    temp18-title = `1 block`.
    temp18-block_count = 1.
    INSERT temp18 INTO TABLE temp17.
    temp18-title = `2 blocks`.
    temp18-block_count = 2.
    INSERT temp18 INTO TABLE temp17.
    temp18-title = `3 blocks`.
    temp18-block_count = 3.
    INSERT temp18 INTO TABLE temp17.
    temp18-title = `4 blocks`.
    temp18-block_count = 4.
    INSERT temp18 INTO TABLE temp17.
    temp18-title = `5 blocks`.
    temp18-block_count = 5.
    INSERT temp18 INTO TABLE temp17.
    temp18-title = `6 blocks`.
    temp18-block_count = 6.
    INSERT temp18 INTO TABLE temp17.
    temp2-subsections = temp17.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `All 3`.
    
    CLEAR temp19.
    
    temp20-title = `1 block`.
    temp20-block_count = 1.
    INSERT temp20 INTO TABLE temp19.
    temp20-title = `2 blocks`.
    temp20-block_count = 2.
    INSERT temp20 INTO TABLE temp19.
    temp20-title = `3 blocks`.
    temp20-block_count = 3.
    INSERT temp20 INTO TABLE temp19.
    temp20-title = `4 blocks`.
    temp20-block_count = 4.
    INSERT temp20 INTO TABLE temp19.
    temp20-title = `5 blocks`.
    temp20-block_count = 5.
    INSERT temp20 INTO TABLE temp19.
    temp20-title = `6 blocks`.
    temp20-block_count = 6.
    INSERT temp20 INTO TABLE temp19.
    temp2-subsections = temp19.
    INSERT temp2 INTO TABLE temp1.
    temp2-title = `All 4`.
    
    CLEAR temp21.
    
    temp22-title = `1 block`.
    temp22-block_count = 1.
    INSERT temp22 INTO TABLE temp21.
    temp22-title = `2 blocks`.
    temp22-block_count = 2.
    INSERT temp22 INTO TABLE temp21.
    temp22-title = `3 blocks`.
    temp22-block_count = 3.
    INSERT temp22 INTO TABLE temp21.
    temp22-title = `4 blocks`.
    temp22-block_count = 4.
    INSERT temp22 INTO TABLE temp21.
    temp22-title = `5 blocks`.
    temp22-block_count = 5.
    INSERT temp22 INTO TABLE temp21.
    temp22-title = `6 blocks`.
    temp22-block_count = 6.
    INSERT temp22 INTO TABLE temp21.
    temp2-subsections = temp21.
    INSERT temp2 INTO TABLE temp1.
    
    t_sections = temp1.

    
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    " Block->content inlining (app 401/416 precedent): all 359 blocks are one
    " BlockBase, sample:InfoButton, around a single full-width Button. What the
    " BlockBase carries and the Button cannot is columnLayout - see sidecar
    
    sections = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns`     v = `sap.uxap`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:m`   v = `sap.m`

        )->ele( `ObjectPageLayout`
            )->a( n = `id`                          v = `ObjectPageLayout`
            " both are bindable properties, so the two toggles write them
            " through the model rather than through a frontend action
            )->a( n = `useTwoColumnsForLargeScreen` v = client->_bind( two_columns )
            )->a( n = `subSectionLayout`            v = client->_bind( subsection_layout )
            )->a( n = `upperCaseAnchorBar`          v = `false`

            )->ele( `headerTitle`
                )->ele( `ObjectPageHeader`
                    )->a( n = `objectTitle` v = `Subsection with blocks using column layout`
                    )->ele( `actions`
                        )->tag( n = `ToggleButton` ns = `m`
                            )->a( n = `text`  v = `Use Title on the Left`
                            )->a( n = `press` v = client->_event( `TOGGLE_TITLE` )
                        )->tag( n = `ToggleButton` ns = `m`
                            )->a( n = `text`  v = `Use Two Columns Mode`
                            )->a( n = `press` v = client->_event( `TOGGLE_TWO_COLUMNS` )

                    )->end(
                )->end(
            )->end(

            )->ele( `sections` ).

    " the 359 buttons are numbered through the whole page, infoButton1..359
    
    button_no = 0.

    
    LOOP AT t_sections INTO section.
      
      subsections = sections->ele( `ObjectPageSection`
          )->a( n = `titleUppercase` v = `false`
          )->a( n = `title`          v = section-title
          )->a( n = `showTitle`      v = `true`
          )->ele( `subSections` ).

      
      LOOP AT section-subsections INTO subsection.
        
        blocks = subsections->ele( `ObjectPageSubSection`
            )->a( n = `title`          v = subsection-title
            )->a( n = `titleUppercase` v = `false`
            )->ele( `blocks` ).

        DO subsection-block_count TIMES.
          button_no = button_no + 1.
          " sample:InfoButton inlined
          blocks->tag( n = `Button` ns = `m`
              )->a( n = `id`    v = |infoButton{ button_no }|
              )->a( n = `width` v = `100%`
              )->a( n = `text`  v = `infoButton`
              )->a( n = `type`  v = `Emphasized` ).
        ENDDO.
      ENDLOOP.
    ENDLOOP.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD on_event.
        DATA temp3 TYPE string.
        DATA temp1 TYPE xsdboolean.

    CASE client->get_event( ).

      WHEN `TOGGLE_TITLE`.
        " toggleTitle: ConfigModel>/subSectionLayout flips TitleOnTop <-> TitleOnLeft
        
        IF subsection_layout = `TitleOnTop`.
          temp3 = `TitleOnLeft`.
        ELSE.
          temp3 = `TitleOnTop`.
        ENDIF.
        subsection_layout = temp3.

      WHEN `TOGGLE_TWO_COLUMNS`.
        " toggleUseTwoColumns: ConfigModel>/useTwoColumnsForLargeScreen flips
        
        temp1 = boolc( two_columns = abap_false ).
        two_columns = temp1.

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " the ConfigModel the controller seeds in onInit
    subsection_layout = `TitleOnTop`.
    two_columns       = abap_false.

  ENDMETHOD.

ENDCLASS.
