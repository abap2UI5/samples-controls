" @keywords objectpagesubsection object sub section sap.uxap objectpagesubsectionsized objectpagelayout objectpageheader togglebutton objectpagesection button
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
    TYPES ty_t_subsections TYPE STANDARD TABLE OF ty_s_subsection WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_section,
        title       TYPE string,
        subsections TYPE ty_t_subsections,
      END OF ty_s_section.
    TYPES ty_t_sections TYPE STANDARD TABLE OF ty_s_section WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_599 IMPLEMENTATION.

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

    " the sections in document order. A subsection title spells the columnLayout
    " of its blocks ('a-1' = auto, 1; '2-a-a' = 2, auto, auto), the last five
    " sections put one fixed layout on 1..6 blocks - see the sidecar on why the
    " layout itself has no target in the inlined form
    DATA(t_sections) = VALUE ty_t_sections(
        ( title = `2 blocks` subsections = VALUE #(
            ( title = `a-1`  block_count = 2 )
            ( title = `a-2`  block_count = 2 )
            ( title = `a-3`  block_count = 2 )
            ( title = `1-a`  block_count = 2 )
            ( title = `2 -a` block_count = 2 )
            ( title = `3-a`  block_count = 2 )
        ) )
        ( title = `3 blocks` subsections = VALUE #(
            ( title = `a-a-1` block_count = 3 )
            ( title = `a-a-2` block_count = 3 )
            ( title = `1-a-1` block_count = 3 )
            ( title = `1-a-2` block_count = 3 )
            ( title = `2-a-a` block_count = 3 )
            ( title = `2-a-1` block_count = 3 )
            ( title = `2-1-a` block_count = 3 )
        ) )
        ( title = `4 blocks` subsections = VALUE #(
            ( title = `a-a-a-1` block_count = 4 )
            ( title = `a-a-a-2` block_count = 4 )
            ( title = `a-1-a-1` block_count = 4 )
            ( title = `1-a-1-a` block_count = 4 )
            ( title = `1-a-a-1` block_count = 4 )
            ( title = `a-2-a-1` block_count = 4 )
            ( title = `a-2-a-2` block_count = 4 )
            ( title = `2-a-a-2` block_count = 4 )
            ( title = `3-a-3-a` block_count = 4 )
        ) )
        ( title = `5 blocks` subsections = VALUE #(
            ( title = `1-a-a-a-1` block_count = 5 )
            ( title = `2-a-a-a-2` block_count = 5 )
            ( title = `3-a-a-a-1` block_count = 5 )
            ( title = `3-a-a-a-2` block_count = 5 )
            ( title = `a-a-1-1-a` block_count = 5 )
            ( title = `a-a-1-a-1` block_count = 5 )
            ( title = `a-3-a-a-2` block_count = 5 )
            ( title = `a-2-a-a-1` block_count = 5 )
            ( title = `a-2-a-a-2` block_count = 5 )
            ( title = `a-1-a-1-a` block_count = 5 )
            ( title = `a-1-a-2-a` block_count = 5 )
            ( title = `a-2-a-1-a` block_count = 5 )
            ( title = `a-3-a-1-a` block_count = 5 )
            ( title = `1-a-1-a-1` block_count = 5 )
            ( title = `1-a-a-1-a` block_count = 5 )
            ( title = `1-a-2-a-1` block_count = 5 )
            ( title = `1-a-3-a-2` block_count = 5 )
            ( title = `2-a-a-2-a` block_count = 5 )
            ( title = `3-a-a-3-a` block_count = 5 )
        ) )
        ( title = `6 blocks` subsections = VALUE #(
            ( title = `1-a-a-a-a-1` block_count = 6 )
            ( title = `1-a-a-a-a-3` block_count = 6 )
            ( title = `a-a-a-1-a-a` block_count = 6 )
            ( title = `a-a-a-2-a-a` block_count = 6 )
            ( title = `a-a-1-a-a-a` block_count = 6 )
            ( title = `a-a-2-a-a-a` block_count = 6 )
            ( title = `a-a-3-a-a-a` block_count = 6 )
            ( title = `a-1-a-a-1-a` block_count = 6 )
            ( title = `a-2-a-a-2-a` block_count = 6 )
            ( title = `a-3-a-a-3-a` block_count = 6 )
            ( title = `a-1-a-a-a-1` block_count = 6 )
            ( title = `a-2-a-a-a-1` block_count = 6 )
            ( title = `a-1-a-1-a-1` block_count = 6 )
            ( title = `a-2-a-2-a-2` block_count = 6 )
            ( title = `a-3-a-2-a-1` block_count = 6 )
        ) )
        ( title = `All default` subsections = VALUE #(
            ( title = `1 block`  block_count = 1 )
            ( title = `2 blocks` block_count = 2 )
            ( title = `3 blocks` block_count = 3 )
            ( title = `4 blocks` block_count = 4 )
            ( title = `5 blocks` block_count = 5 )
            ( title = `6 blocks` block_count = 6 )
        ) )
        ( title = `All 1` subsections = VALUE #(
            ( title = `1 block`  block_count = 1 )
            ( title = `2 blocks` block_count = 2 )
            ( title = `3 blocks` block_count = 3 )
            ( title = `4 blocks` block_count = 4 )
            ( title = `5 blocks` block_count = 5 )
            ( title = `6 blocks` block_count = 6 )
        ) )
        ( title = `All 2` subsections = VALUE #(
            ( title = `1 block`  block_count = 1 )
            ( title = `2 blocks` block_count = 2 )
            ( title = `3 blocks` block_count = 3 )
            ( title = `4 blocks` block_count = 4 )
            ( title = `5 blocks` block_count = 5 )
            ( title = `6 blocks` block_count = 6 )
        ) )
        ( title = `All 3` subsections = VALUE #(
            ( title = `1 block`  block_count = 1 )
            ( title = `2 blocks` block_count = 2 )
            ( title = `3 blocks` block_count = 3 )
            ( title = `4 blocks` block_count = 4 )
            ( title = `5 blocks` block_count = 5 )
            ( title = `6 blocks` block_count = 6 )
        ) )
        ( title = `All 4` subsections = VALUE #(
            ( title = `1 block`  block_count = 1 )
            ( title = `2 blocks` block_count = 2 )
            ( title = `3 blocks` block_count = 3 )
            ( title = `4 blocks` block_count = 4 )
            ( title = `5 blocks` block_count = 5 )
            ( title = `6 blocks` block_count = 6 )
        ) )
    ).

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    " Block->content inlining (app 401/416 precedent): all 359 blocks are one
    " BlockBase, sample:InfoButton, around a single full-width Button. What the
    " BlockBase carries and the Button cannot is columnLayout - see sidecar
    DATA(sections) = view->ele( n = `View` ns = `mvc`
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
    DATA(button_no) = 0.

    LOOP AT t_sections INTO DATA(section).
      DATA(subsections) = sections->ele( `ObjectPageSection`
          )->a( n = `titleUppercase` v = `false`
          )->a( n = `title`          v = section-title
          )->a( n = `showTitle`      v = `true`
          )->ele( `subSections` ).

      LOOP AT section-subsections INTO DATA(subsection).
        DATA(blocks) = subsections->ele( `ObjectPageSubSection`
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

    CASE client->get_event( ).

      WHEN `TOGGLE_TITLE`.
        " toggleTitle: ConfigModel>/subSectionLayout flips TitleOnTop <-> TitleOnLeft
        subsection_layout = COND #( WHEN subsection_layout = `TitleOnTop` THEN `TitleOnLeft` ELSE `TitleOnTop` ).

      WHEN `TOGGLE_TWO_COLUMNS`.
        " toggleUseTwoColumns: ConfigModel>/useTwoColumnsForLargeScreen flips
        two_columns = xsdbool( two_columns = abap_false ).

    ENDCASE.

  ENDMETHOD.


  METHOD model_init.

    " the ConfigModel the controller seeds in onInit
    subsection_layout = `TitleOnTop`.
    two_columns       = abap_false.

  ENDMETHOD.

ENDCLASS.
