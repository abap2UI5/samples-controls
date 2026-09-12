" @keywords carousel sap.m user browse title verticallayout image text scrollcontainer list standardlistitem
" @summary With the Carousel a user can browse through multi-page content by swiping left or right.
" @origin sap.m.sample.CarouselWithControls - https://sdk.openui5.org/entity/sap.m.Carousel/sample/sap.m.sample.CarouselWithControls (status: checked - verified in a running system)
CLASS z2ui5_cl_smpc_app_006 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_product,
        name          TYPE string,
        productid     TYPE string,
        productpicurl TYPE string,
      END OF ty_s_product.
    DATA t_products TYPE STANDARD TABLE OF ty_s_product WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " not bound - the shared image base URL, kept out of PUBLIC so the round-trip model scan stays small
    DATA base_url TYPE string.

    METHODS view_display.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_smpc_app_006 IMPLEMENTATION.

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

    DATA(lorem) = `Lorem ipsum dolor st amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.` &&
      ` At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.` &&
      ` Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.` &&
      ` Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat`.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n = `View` ns = `mvc`
        )->a( n = `height`    v = `100%`
        )->a( n = `xmlns`     v = `sap.m`
        )->a( n = `xmlns:l`   v = `sap.ui.layout`
        )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`

        )->tag( `Title`
            )->a( n = `id`    v = `carouselTitle`
            )->a( n = `class` v = `sapUiSmallMarginTop`
            )->a( n = `text`  v = `Carousel with Different Controls`

        )->ele( `Carousel`
            )->a( n = `ariaLabelledBy` v = `carouselTitle`
            )->a( n = `class`          v = `sapUiContentPadding`

            )->ele( n = `VerticalLayout` ns = `l`
                )->tag( `Image`
                    )->a( n = `src` t = base_url && `HT-7777-large.jpg`
                    )->a( n = `alt` v = `Example picture of speakers`

            )->end(
            )->tag( `Image`
                )->a( n = `src` t = base_url && `HT-6120-large.jpg`
                )->a( n = `alt` v = `Example picture of USB flash drive`

            )->tag( `Text`
                )->a( n = `class` v = `sapUiSmallMargin`
                )->a( n = `text`  t = lorem

            )->ele( `ScrollContainer`
                )->a( n = `height`     v = `100%`
                )->a( n = `width`      v = `100%`
                )->a( n = `horizontal` v = `false`
                )->a( n = `vertical`   v = `true`

                )->ele( `List`
                    )->a( n = `headerText` v = `Some List Content 1`
                    )->a( n = `items`      v = client->_bind( t_products )

                    )->tag( `StandardListItem`
                        )->a( n = `title`            v = `{NAME}`
                        )->a( n = `description`      v = `{PRODUCTID}`
                        )->a( n = `icon`             v = `{PRODUCTPICURL}`
                        )->a( n = `iconDensityAware` v = `false`
                        )->a( n = `iconInset`        v = `false`

                )->end(
            )->end(
            )->tag( `Image`
                )->a( n = `src` t = base_url && `HT-6100-large.jpg`
                )->a( n = `alt` v = `Example picture of spotlight` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD model_init.

    " Image URLs of the mock models sap/ui/demo/mock/img.json and products.json used by the original sample
    base_url = `https://sdk.openui5.org/test-resources/sap/ui/documentation/sdk/images/`.

    " full mock /ProductCollection (sap/ui/demo/mock/products.json) of the original sample
    t_products = VALUE #(
      ( name = `Notebook Basic 15`                                  productid = `HT-1000` productpicurl = base_url && `HT-1000.jpg` )
      ( name = `Notebook Basic 17`                                  productid = `HT-1001` productpicurl = base_url && `HT-1001.jpg` )
      ( name = `Notebook Basic 18`                                  productid = `HT-1002` productpicurl = base_url && `HT-1002.jpg` )
      ( name = `Notebook Basic 19`                                  productid = `HT-1003` productpicurl = base_url && `HT-1003.jpg` )
      ( name = `ITelO Vault`                                        productid = `HT-1007` productpicurl = base_url && `HT-1007.jpg` )
      ( name = `Notebook Professional 15`                           productid = `HT-1010` productpicurl = base_url && `HT-1010.jpg` )
      ( name = `Notebook Professional 17`                           productid = `HT-1011` productpicurl = base_url && `HT-1011.jpg` )
      ( name = `ITelO Vault Net`                                    productid = `HT-1020` productpicurl = base_url && `HT-1020.jpg` )
      ( name = `ITelO Vault SAT`                                    productid = `HT-1021` productpicurl = base_url && `HT-1021.jpg` )
      ( name = `Comfort Easy`                                       productid = `HT-1022` productpicurl = base_url && `HT-1022.jpg` )
      ( name = `Comfort Senior`                                     productid = `HT-1023` productpicurl = base_url && `HT-1023.jpg` )
      ( name = `Ergo Screen E-I`                                    productid = `HT-1030` productpicurl = base_url && `HT-1030.jpg` )
      ( name = `Ergo Screen E-II`                                   productid = `HT-1031` productpicurl = base_url && `HT-1031.jpg` )
      ( name = `Ergo Screen E-III`                                  productid = `HT-1032` productpicurl = base_url && `HT-1032.jpg` )
      ( name = `Flat Basic`                                         productid = `HT-1035` productpicurl = base_url && `HT-1035.jpg` )
      ( name = `Flat Future`                                        productid = `HT-1036` productpicurl = base_url && `HT-1036.jpg` )
      ( name = `Flat XL`                                            productid = `HT-1037` productpicurl = base_url && `HT-1037.jpg` )
      ( name = `Laser Professional Eco`                             productid = `HT-1040` productpicurl = base_url && `HT-1040.jpg` )
      ( name = `Laser Basic`                                        productid = `HT-1041` productpicurl = base_url && `HT-1041.jpg` )
      ( name = `Laser Allround`                                     productid = `HT-1042` productpicurl = base_url && `HT-1042.jpg` )
      ( name = `Ultra Jet Super Color`                              productid = `HT-1050` productpicurl = base_url && `HT-1050.jpg` )
      ( name = `Ultra Jet Mobile`                                   productid = `HT-1051` productpicurl = base_url && `HT-1051.jpg` )
      ( name = `Ultra Jet Super Highspeed`                          productid = `HT-1052` productpicurl = base_url && `HT-1052.jpg` )
      ( name = `Multi Print`                                        productid = `HT-1055` productpicurl = base_url && `HT-1055.jpg` )
      ( name = `Multi Color`                                        productid = `HT-1056` productpicurl = base_url && `HT-1056.jpg` )
      ( name = `Cordless Mouse`                                     productid = `HT-1060` productpicurl = base_url && `HT-1060.jpg` )
      ( name = `Speed Mouse`                                        productid = `HT-1061` productpicurl = base_url && `HT-1061.jpg` )
      ( name = `Track Mouse`                                        productid = `HT-1062` productpicurl = base_url && `HT-1062.jpg` )
      ( name = `Ergonomic Keyboard`                                 productid = `HT-1063` productpicurl = base_url && `HT-1063.jpg` )
      ( name = `Internet Keyboard`                                  productid = `HT-1064` productpicurl = base_url && `HT-1064.jpg` )
      ( name = `Media Keyboard`                                     productid = `HT-1065` productpicurl = base_url && `HT-1065.jpg` )
      ( name = `Mousepad`                                           productid = `HT-1066` productpicurl = base_url && `HT-1066.jpg` )
      ( name = `Ergo Mousepad`                                      productid = `HT-1067` productpicurl = base_url && `HT-1067.jpg` )
      ( name = `Designer Mousepad`                                  productid = `HT-1068` productpicurl = base_url && `HT-1068.jpg` )
      ( name = `Universal card reader`                              productid = `HT-1069` productpicurl = base_url && `HT-1069.jpg` )
      ( name = `Proctra X`                                          productid = `HT-1070` productpicurl = base_url && `HT-1070.jpg` )
      ( name = `Gladiator MX`                                       productid = `HT-1071` productpicurl = base_url && `HT-1071.jpg` )
      ( name = `Hurricane GX`                                       productid = `HT-1072` productpicurl = base_url && `HT-1072.jpg` )
      ( name = `Hurricane GX/LN`                                    productid = `HT-1073` productpicurl = base_url && `HT-1073.jpg` )
      ( name = `Photo Scan`                                         productid = `HT-1080` productpicurl = base_url && `HT-1080.jpg` )
      ( name = `Power Scan`                                         productid = `HT-1081` productpicurl = base_url && `HT-1081.jpg` )
      ( name = `Jet Scan Professional`                              productid = `HT-1082` productpicurl = base_url && `HT-1082.jpg` )
      ( name = `Jet Scan Professional`                              productid = `HT-1083` productpicurl = base_url && `HT-1083.jpg` )
      ( name = `Copymaster`                                         productid = `HT-1085` productpicurl = base_url && `HT-1085.jpg` )
      ( name = `Surround Sound`                                     productid = `HT-1090` productpicurl = base_url && `HT-1090.jpg` )
      ( name = `Blaster Extreme`                                    productid = `HT-1091` productpicurl = base_url && `HT-1091.jpg` )
      ( name = `Sound Booster`                                      productid = `HT-1092` productpicurl = base_url && `HT-1092.jpg` )
      ( name = `Lovely Sound 5.1 Wireless`                          productid = `HT-1095` productpicurl = base_url && `HT-1095.jpg` )
      ( name = `Lovely Sound 5.1`                                   productid = `HT-1096` productpicurl = base_url && `HT-1096.jpg` )
      ( name = `Lovely Sound Stereo`                                productid = `HT-1097` productpicurl = base_url && `HT-1097.jpg` )
      ( name = `Smart Office`                                       productid = `HT-1100` productpicurl = base_url && `HT-1100.jpg` )
      ( name = `Smart Design`                                       productid = `HT-1101` productpicurl = base_url && `HT-1101.jpg` )
      ( name = `Smart Network`                                      productid = `HT-1102` productpicurl = base_url && `HT-1102.jpg` )
      ( name = `Smart Multimedia`                                   productid = `HT-1103` productpicurl = base_url && `HT-1103.jpg` )
      ( name = `Smart Games`                                        productid = `HT-1104` productpicurl = base_url && `HT-1104.jpg` )
      ( name = `Smart Internet Antivirus`                           productid = `HT-1105` productpicurl = base_url && `HT-1105.jpg` )
      ( name = `Smart Firewall`                                     productid = `HT-1106` productpicurl = base_url && `HT-1106.jpg` )
      ( name = `Smart Money`                                        productid = `HT-1107` productpicurl = base_url && `HT-1107.jpg` )
      ( name = `PC Lock`                                            productid = `HT-1110` productpicurl = base_url && `HT-1110.jpg` )
      ( name = `Notebook Lock`                                      productid = `HT-1111` productpicurl = base_url && `HT-1111.jpg` )
      ( name = `Web cam reality`                                    productid = `HT-1112` productpicurl = base_url && `HT-1112.jpg` )
      ( name = `Screen clean`                                       productid = `HT-1113` productpicurl = base_url && `HT-1113.jpg` )
      ( name = `Fabric bag professional`                            productid = `HT-1114` productpicurl = base_url && `HT-1114.jpg` )
      ( name = `Wireless DSL Router`                                productid = `HT-1115` productpicurl = base_url && `HT-1115.jpg` )
      ( name = `Wireless DSL Router / Repeater`                     productid = `HT-1116` productpicurl = base_url && `HT-1116.jpg` )
      ( name = `Wireless DSL Router / Repeater and Print Server`    productid = `HT-1117` productpicurl = base_url && `HT-1117.jpg` )
      ( name = `USB Stick`                                          productid = `HT-1118` productpicurl = base_url && `HT-1118.jpg` )
      ( name = `Travel Adapter`                                     productid = `HT-1119` productpicurl = base_url && `HT-1119.jpg` )
      ( name = `Cordless Bluetooth Keyboard, english international` productid = `HT-1120` productpicurl = base_url && `HT-1120.jpg` )
      ( name = `Flat XXL`                                           productid = `HT-1137` productpicurl = base_url && `HT-1137.jpg` )
      ( name = `Pocket Mouse`                                       productid = `HT-1138` productpicurl = base_url && `HT-1138.jpg` )
      ( name = `PC Power Station`                                   productid = `HT-1210` productpicurl = base_url && `HT-1210.jpg` )
      ( name = `Astro Laptop 1516`                                  productid = `HT-1251` productpicurl = base_url && `HT-1251.jpg` )
      ( name = `Astro Phone 6`                                      productid = `HT-1252` productpicurl = base_url && `HT-1252.jpg` )
      ( name = `Benda Laptop 1408`                                  productid = `HT-1253` productpicurl = base_url && `HT-1253.jpg` )
      ( name = `Bending Screen 21HD`                                productid = `HT-1254` productpicurl = base_url && `HT-1254.jpg` )
      ( name = `Broad Screen 22HD`                                  productid = `HT-1255` productpicurl = base_url && `HT-1255.jpg` )
      ( name = `Cerdik Phone 7`                                     productid = `HT-1256` productpicurl = base_url && `HT-1256.jpg` )
      ( name = `Cepat Tablet 10.5`                                  productid = `HT-1257` productpicurl = base_url && `HT-1257.jpg` )
      ( name = `Cepat Tablet 8`                                     productid = `HT-1258` productpicurl = base_url && `HT-1258.jpg` )
      ( name = `Server Basic`                                       productid = `HT-1500` productpicurl = base_url && `HT-1500.jpg` )
      ( name = `Server Professional`                                productid = `HT-1501` productpicurl = base_url && `HT-1501.jpg` )
      ( name = `Server Power Pro`                                   productid = `HT-1502` productpicurl = base_url && `HT-1502.jpg` )
      ( name = `Family PC Basic`                                    productid = `HT-1600` productpicurl = base_url && `HT-1600.jpg` )
      ( name = `Family PC Pro`                                      productid = `HT-1601` productpicurl = base_url && `HT-1601.jpg` )
      ( name = `Gaming Monster`                                     productid = `HT-1602` productpicurl = base_url && `HT-1602.jpg` )
      ( name = `Gaming Monster Pro`                                 productid = `HT-1603` productpicurl = base_url && `HT-1603.jpg` )
      ( name = `7" Widescreen Portable DVD Player w MP3`            productid = `HT-2000` productpicurl = base_url && `HT-2000.jpg` )
      ( name = `10" Portable DVD player`                            productid = `HT-2001` productpicurl = base_url && `HT-2001.jpg` )
      ( name = `Portable DVD Player with 9" LCD Monitor`            productid = `HT-2002` productpicurl = base_url && `HT-2002.jpg` )
      ( name = `CD/DVD case: 264 sleeves`                           productid = `HT-2025` productpicurl = base_url && `HT-2025.jpg` )
      ( name = `Audio/Video Cable Kit - 4m`                         productid = `HT-2026` productpicurl = base_url && `HT-2026.jpg` )
      ( name = `Removable CD/DVD Laser Labels`                      productid = `HT-2027` productpicurl = base_url && `HT-2027.jpg` )
      ( name = `Beam Breaker B-1`                                   productid = `HT-6100` productpicurl = base_url && `HT-6100.jpg` )
      ( name = `Beam Breaker B-2`                                   productid = `HT-6101` productpicurl = base_url && `HT-6101.jpg` )
      ( name = `Beam Breaker B-3`                                   productid = `HT-6102` productpicurl = base_url && `HT-6102.jpg` )
      ( name = `Play Movie`                                         productid = `HT-6110` productpicurl = base_url && `HT-6110.jpg` )
      ( name = `Record Movie`                                       productid = `HT-6111` productpicurl = base_url && `HT-6111.jpg` )
      ( name = `ITelo MusicStick`                                   productid = `HT-6120` productpicurl = base_url && `HT-6120.jpg` )
      ( name = `ITelo Jog-Mate`                                     productid = `HT-6121` productpicurl = base_url && `HT-6121.jpg` )
      ( name = `Power Pro Player 40`                                productid = `HT-6122` productpicurl = base_url && `HT-6122.jpg` )
      ( name = `Power Pro Player 80`                                productid = `HT-6123` productpicurl = base_url && `HT-6123.jpg` )
      ( name = `Flat Watch HD32`                                    productid = `HT-6130` productpicurl = base_url && `HT-6130.jpg` )
      ( name = `Flat Watch HD37`                                    productid = `HT-6131` productpicurl = base_url && `HT-6131.jpg` )
      ( name = `Flat Watch HD41`                                    productid = `HT-6132` productpicurl = base_url && `HT-6132.jpg` )
      ( name = `Copperberry`                                        productid = `HT-7000` productpicurl = base_url && `HT-7000.jpg` )
      ( name = `Silverberry`                                        productid = `HT-7010` productpicurl = base_url && `HT-7010.jpg` )
      ( name = `Goldberry`                                          productid = `HT-7020` productpicurl = base_url && `HT-7020.jpg` )
      ( name = `Platinberry`                                        productid = `HT-7030` productpicurl = base_url && `HT-7030.jpg` )
      ( name = `ITelO FlexTop I4000`                                productid = `HT-8000` productpicurl = base_url && `HT-8000.jpg` )
      ( name = `ITelO FlexTop I6300c`                               productid = `HT-8001` productpicurl = base_url && `HT-8001.jpg` )
      ( name = `ITelO FlexTop I9100`                                productid = `HT-8002` productpicurl = base_url && `HT-8002.jpg` )
      ( name = `ITelO FlexTop I9800`                                productid = `HT-8003` productpicurl = base_url && `HT-8003.jpg` )
      ( name = `Smartphone Leather Case`                            productid = `HT-9991` productpicurl = base_url && `HT-9991.jpg` )
      ( name = `Smartphone Alpha`                                   productid = `HT-9992` productpicurl = base_url && `HT-9992.jpg` )
      ( name = `Mini Tablet`                                        productid = `HT-9993` productpicurl = base_url && `HT-9993.jpg` )
      ( name = `Camcorder View`                                     productid = `HT-9994` productpicurl = base_url && `HT-9994.jpg` )
      ( name = `Tablet Pouch`                                       productid = `HT-9995` productpicurl = base_url && `HT-9995.jpg` )
      ( name = `Tablet Pouch`                                       productid = `HT-9996` productpicurl = base_url && `HT-9996.jpg` )
      ( name = `e-Book Reader ReadMe`                               productid = `HT-9997` productpicurl = base_url && `HT-9997.jpg` )
      ( name = `Smartphone Beta`                                    productid = `HT-9998` productpicurl = base_url && `HT-9998.jpg` )
      ( name = `Maxi Tablet`                                        productid = `HT-9999` productpicurl = base_url && `HT-9999.jpg` )
      ( name = `Flyer`                                              productid = `PF-1000` productpicurl = base_url && `PF-1000.jpg` ) ).

  ENDMETHOD.

ENDCLASS.
