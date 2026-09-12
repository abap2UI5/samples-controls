" @keywords objectpagelayout object layout sap.uxap objectpagelazyloadingwithoutblocks objectpagedynamicheadertitle title button overflowtoolbarbutton objectpagesubsection objectpagelazyloader vbox
" @summary This sample showcases the lazy loading using the stashed property of the ObjectPageLazyLoader. It enables usage of lazy loading without the need to have Blocks
" @origin sap.uxap.sample.ObjectPageLazyLoadingWithoutBlocks - https://sdk.openui5.org/entity/sap.uxap.ObjectPageLayout/sample/sap.uxap.sample.ObjectPageLazyLoadingWithoutBlocks (status: generated - machine-written, not yet reviewed)
CLASS z2ui5_cl_smpc_app_592 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " the view's bindElement( '/SupplierCollection/0' ) folded onto root fields
    DATA supplier_name TYPE string.
    DATA street        TYPE string.
    DATA housenumber   TYPE string.
    DATA zipcode       TYPE string.
    DATA city          TYPE string.
    DATA country       TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_592 IMPLEMENTATION.

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

    " twenty-one identical sections, each a stashed ObjectPageLazyLoader around the
    " same Address form - which is the sample: lazy loading WITHOUT custom blocks
    DATA(sections) = view->ele( n = `View` ns = `mvc`
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns`     v = `sap.uxap`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
        )->a( n = `xmlns:m`   v = `sap.m`
        )->a( n = `xmlns:f`   v = `sap.ui.layout.form`

        )->ele( `ObjectPageLayout`
            )->a( n = `id`                 v = `ObjectPageLayout`
            )->a( n = `enableLazyLoading`  v = `true`
            )->a( n = `upperCaseAnchorBar` v = `false`

            )->ele( `headerTitle`
                )->ele( `ObjectPageDynamicHeaderTitle`
                    )->ele( `heading`
                        )->tag( n = `Title` ns = `m`
                            )->a( n = `text` v = `ObjectPage with LazyLoading without the use of Blocks`

                    )->end(

                    )->ele( `snappedTitleOnMobile`
                        )->tag( n = `Title` ns = `m`
                            )->a( n = `text` v = `ObjectPage with LazyLoading without the use of Blocks`

                    )->end(

                    )->ele( `actions`
                        )->tag( n = `Button` ns = `m`
                            )->a( n = `text` v = `Edit`
                            )->a( n = `type` v = `Emphasized`
                        )->tag( n = `Button` ns = `m`
                            )->a( n = `type` v = `Transparent`
                            )->a( n = `text` v = `Delete`
                        )->tag( n = `Button` ns = `m`
                            )->a( n = `type` v = `Transparent`
                            )->a( n = `text` v = `Copy`
                        )->tag( n = `OverflowToolbarButton` ns = `m`
                            )->a( n = `icon`    v = `sap-icon://action`
                            )->a( n = `type`    v = `Transparent`
                            )->a( n = `text`    v = `Share`
                            )->a( n = `tooltip` v = `action`

                    )->end(
                )->end(
            )->end(

            )->ele( `sections` ).

    " the twenty-one sections differ only in their number - Section 1 ..
    " Section 21 as title, SectionN and SectionNstashed as ids
    DO 21 TIMES.
      DATA(section_no) = sy-index.

      sections->ele( `ObjectPageSection`
          )->a( n = `titleUppercase` v = `false`
          )->a( n = `title`          v = `my section`
          )->ele( `subSections`
              )->ele( `ObjectPageSubSection`
                  )->a( n = `title`          v = |Section { section_no }|
                  )->a( n = `mode`           v = `Expanded`
                  )->a( n = `id`             v = |Section{ section_no }|
                  )->a( n = `titleUppercase` v = `false`
                  )->ele( `blocks`
                      )->ele( `ObjectPageLazyLoader`
                          )->a( n = `stashed` v = `true`
                          )->a( n = `id`      v = |Section{ section_no }stashed|

                          )->ele( n = `VBox` ns = `m`
                              )->a( n = `class` v = `sapUiSmallMargin`
                              )->ele( n = `SimpleForm` ns = `f`
                                  )->a( n = `maxContainerCols` v = `2`
                                  )->a( n = `editable`         v = `false`
                                  )->a( n = `layout`           v = `ResponsiveGridLayout`
                                  )->a( n = `title`            v = `Address`
                                  )->a( n = `labelSpanL`       v = `3`
                                  )->a( n = `labelSpanM`       v = `3`
                                  )->a( n = `emptySpanL`       v = `4`
                                  )->a( n = `emptySpanM`       v = `4`
                                  )->a( n = `columnsL`         v = `1`
                                  )->a( n = `columnsM`         v = `1`
                                  )->a( n = `width`            v = `auto`
                                  )->a( n = `class`            v = `sapUxAPObjectPageSubSectionAlignContent`

                                  )->ele( n = `content` ns = `f`
                                      )->tag( n = `Label` ns = `m`
                                          )->a( n = `text` v = `Name`
                                      )->tag( n = `Text` ns = `m`
                                          )->a( n = `text` v = client->_bind( supplier_name )
                                      )->tag( n = `Label` ns = `m`
                                          )->a( n = `text` v = `Street/No.`
                                      )->tag( n = `Text` ns = `m`
                                          )->a( n = `text` v = |{ client->_bind( street ) } { client->_bind( housenumber ) }|
                                      )->tag( n = `Label` ns = `m`
                                          )->a( n = `text` v = `ZIP Code/City`
                                      )->tag( n = `Text` ns = `m`
                                          )->a( n = `text` v = |{ client->_bind( zipcode ) } { client->_bind( city ) }|
                                      )->tag( n = `Label` ns = `m`
                                          )->a( n = `text` v = `Country`
                                      )->tag( n = `Text` ns = `m`
                                          )->a( n = `text` v = client->_bind( country )

                                  )->end(
                              )->end(
                          )->end(
                      )->end(
                  )->end(
              )->end(
          )->end(
      )->end( ).
    ENDDO.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " sap/ui/demo/mock/supplier.json /SupplierCollection/0, the row the view
    " binds with bindElement
    supplier_name = `Red Point Stores`.
    street        = `Main St`.
    housenumber   = `1618`.
    zipcode       = `31415`.
    city          = `Maintown`.
    country       = `Germany`.

  ENDMETHOD.

ENDCLASS.
