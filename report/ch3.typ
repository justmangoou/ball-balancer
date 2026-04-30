#import "@preview/fletcher:0.5.8": diagram, node, edge

= Thiết kế và triển khai hệ thống
    == Thiết kế tổng thể
        Hệ thống được thiết kế theo mô hình điều khiển vòng kín (closed-loop control), trong đó vị trí của quả bóng được đo liên tục và sử dụng làm tín hiệu phản hồi để điều chỉnh trạng thái của hệ thống.

        Về mặt chức năng, hệ thống bao gồm ba khối chính:

        - *Khối cảm biến:* sử dụng màn hình cảm ứng điện trở để xác định tọa độ $(x, y)$ của quả bóng.
        - *Khối xử lý:* vi điều khiển thực hiện việc thu nhận dữ liệu và tính toán tín hiệu điều khiển.
        - *Khối chấp hành:* bao gồm driver và các động cơ bước để điều chỉnh góc nghiêng của mặt phẳng.

        #linebreak()

        #figure(
            align(center)[
                #diagram(
                node-stroke: 1pt,

                // Main nodes
                node((0,0), [Cảm biến], name: <sensor>, corner-radius: 2pt),
                node((0,1), [Vi điều khiển], name: <controller>, corner-radius: 2pt),
                node((0,2), [Driver], name: <driver>, corner-radius: 2pt),
                node((0,3), [Động cơ], name: <motor>, corner-radius: 2pt),
                node((0,4), [Mặt phẳng], name: <plate>, corner-radius: 2pt),

                // Left labels
                node((-2,0), [*Khối cảm biến*], name: <lsensor>),
                node((-2,1), [*Khối xử lý*], name: <lcontroller>),
                node((-2,3), [*Khối chấp hành*], name: <lactuator>),

                // Main flow
                edge(<sensor>, <controller>, "-|>"),
                edge(<controller>, <driver>, "-|>"),
                edge(<driver>, <motor>, "-|>"),
                edge(<motor>, <plate>, "-|>"),

                // Feedback
                edge(<plate>, (1,4), (1,0), <sensor>, "-|>")[Phản hồi],

                // Group connectors (no arrow)
                edge(<lsensor>, <sensor>, "-"),
                edge(<lcontroller>, <controller>, "-"),
                edge(<lactuator>, <driver>, "-"),
                edge(<lactuator>, <motor>, "-"),
                )
            ],
            caption: [Sơ đồ khối tổng thể của hệ thống]
        )

        Nguyên lý hoạt động của hệ thống như sau: tín hiệu vị trí từ cảm biến được đưa về bộ điều khiển để xác định sai lệch so với vị trí đặt. Tín hiệu điều khiển sau đó được gửi tới các động cơ bước nhằm điều chỉnh góc nghiêng của mặt phẳng, từ đó chi phối chuyển động của quả bóng. Quá trình này được lặp lại liên tục theo thời gian thực để đảm bảo hệ thống duy trì trạng thái cân bằng ổn định.
        
        #pagebreak()

    == Thiết kế phần cứng
        === Danh sách linh kiện
            ==== Vi điều khiển STM32F411CEU6
                *STM32F411CEU6 (Blackpill)* là vi điều khiển thuộc dòng STM32F4 của STMicroelectronics, sử dụng lõi ARM Cortex-M4 tích hợp Floating Point Unit (FPU), cho phép xử lý hiệu quả các phép toán số thực, phù hợp với các hệ thống điều khiển yêu cầu hiệu suất cao.

                #figure(
                    caption: [Thông số kỹ thuật STM32F411CEU6],
                    table(
                        columns: (1fr, 1fr),
                        inset: 10pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,
            
                        [*Nhân*],                    
                        [ARM 32-bit Cortex-M4 CPU với FPU],

                        [*Tốc độ xung nhịp tối đa*], 
                        [100 MHz],

                        [*Bộ nhớ Flash (ROM)*],      
                        [512 KB],

                        [*Bộ nhớ SRAM*],             
                        [128 KB],

                        [*GPIO*],                    
                        [34 chân I/O],

                        [*ADC*],                     
                        [12-bit, 9 kênh],

                        [*Kích thước*],              
                        [21 x 53 mm],
                    )
                )

                #figure(
                    image("assets/STM32F411CEU6-pinout.png", width: 340pt),
                    caption: [Sơ đồ chân của STM32F411CEU6 (Blackpill)],
                ) <glacier>

            ==== Màn cảm ứng điện trở
                *Màn hình cảm ứng điện trở* được sử dụng để thu nhận thông tin vị trí tiếp xúc trên bề mặt. Với cấu trúc 4 dây điện trở, thiết bị có khả năng phát hiện vị trí chạm với độ chính xác tương đối cao và ổn định. Nhờ kích thước vùng hoạt động lớn và cấu tạo đơn giản, loại màn hình này phù hợp với các ứng dụng yêu cầu xác định vị trí trên mặt phẳng với chi phí thấp.

                #figure(
                    caption: [Thông số kỹ thuật màn cảm ứng điện trở],
                    table(
                        columns: (1fr, 1fr),
                        inset: 10pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,

                        [*Kích thước*], [9 inch],

                        [*Vùng hoạt động*], [$210 times 126$ mm],

                        [*Vật liệu bề mặt*], [Màng phim + kính],
                    )
                )

                #figure(
                    image("assets/resistive-touch.png", width: 180pt),
                    caption: [Màn hình cảm ứng điện trở 9"],
                ) <glacier>
                #linebreak()

            ==== Driver TMC2208
                *Driver TMC2208* là bộ điều khiển động cơ bước tích hợp các công nghệ StealthChop2$trademark$ và SpreadCycle$trademark$ của Trinamic. Các công nghệ này giúp hạn chế tiếng ồn, đồng thời đảm bảo chuyển động mượt với độ chính xác cao thông qua cơ chế vi bước. Đồng thời, driver tối ưu hiệu suất năng lượng và giảm sinh nhiệt trong quá trình vận hành lâu dài. Dòng điện cấp cho động cơ có thể được điều chỉnh thông qua điện áp tham chiếu ($V_"ref"$) hoặc giao tiếp UART, cho phép tự cấu hình tùy theo yêu cầu hệ thống.

                #linebreak()
                #figure(
                    caption: [Thông số kỹ thuật driver TMC2208],
                    table(
                        columns: (1fr, 1fr),
                        inset: 10pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,
            
                        [*Điện áp động cơ ($V_M$)*],                    
                        [$4.75V$ đến $36V$],

                        [*Điện áp logic ($V_"IO"$)*],                    
                        [$3V$ đến $5V$],
                        
                        [*Dòng điện*],
                        [$1.2A$ RMS \ (Tối đa $~2.0A$ với tản nhiệt)],

                        [*Độ phân giải vi bước*],              
                        [Tối đa 1 / 256 bước],

                        [*Kích thước*],              
                        [$20.2 times 15.4$ mm],
                    )
                )

                #figure(
                    image("assets/TMC2208-pinout.png", width: 180pt),
                    caption: [Sơ đồ chân cắm mạch điều khiển động cơ bước TMC2208],
                ) <glacier>
                #linebreak()

            ==== Động cơ bước 17HS4401S
                *Động cơ bước 17HS4401S (chuẩn NEMA 17)* là loại động cơ bước hai pha (bipolar) được sử dụng phổ biến trong các ứng dụng yêu cầu độ chính xác và độ ổn định cao. Với góc bước nhỏ và mô-men xoắn giữ tương đối lớn, động cơ cho phép thực hiện các chuyển động chính xác và ổn định trong quá trình vận hành.

                #figure(
                    caption: [Thông số kỹ thuật động cơ bước 17HS4401S],
                    table(
                        columns: (1fr, 1fr),
                        inset: 10pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,

                        [*Góc bước cơ bản*], [$1.8 degree plus.minus 0.09 degree$],

                        [*Kích thước mặt bích*], [$42.3 times 42.3$ mm],

                        [*Dòng điện định mức*], [$1.5A$ / pha],

                        [*Mô-men xoắn giữ*], [$40 N dot$ cm],

                        [*Khối lượng*], [$~300$ g],
                    )
                )

                #figure(
                    image("assets/17HS4401S.png", width: 180pt),
                    caption: [Động cơ bước 17HS4401S],
                ) <glacier>
                #linebreak()
                #figure(
                    image("assets/17HS4401S-blueprint.png", width: 360pt),
                    caption: [Bản vẽ kỹ thuật động cơ bước 17HS4401S],
                ) <glacier>
                #linebreak()
            
            ==== Module hạ áp LM2596
                *Module hạ áp DC-DC LM2596 (tích hợp vôn kế)* là bộ chuyển đổi điện áp một chiều có khả năng hạ điện áp đầu vào xuống mức thấp hơn, hoạt động theo nguyên lý chuyển mạch tần số cao, cho hiệu suất chuyển đổi cao. Module được tích hợp màn hình LED và vi điều khiển đo điện áp, giúp giám sát trực tiếp điện áp đầu vào/đầu ra trong quá trình vận hành với độ chính xác khoảng $plus.minus 0.05V$. Điện áp đầu ra có thể thay đổi thông qua việc điều chỉnh biến trở tích hợp trên module.

                #v(4.6em)
                #figure(
                    caption: [Thông số kỹ thuật module hạ áp DC-DC LM2596],
                    table(
                        columns: (1fr, 1.75fr),
                        inset: 10pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,
            
                        [*Điện áp đầu vào $V_"in"$*],                    
                        [$4.0V$ đến $40V$ \ (Vôn kế hoạt động ổn định khi $V_"in" > 4.5V$)],
                        
                        [*Điện áp đầu ra $V_"out"$*],                    
                        [$1.25V$ đến $37V$ \ (Điều chỉnh bằng biến trở)],
                        
                        [*Dòng điện đầu ra*],          
                        [$2.0A$ RMS \ (Tối đa $~3.0A$ với tản nhiệt)],

                        [*Công suất đầu ra tối đa*],
                        [$20 W$ \ (Khuyến nghị tản nhiệt khi công suất lớn hơn $15 W$)],

                        [*Hiệu suất chuyển đổi*],
                        [$~ 88%$],

                        [*Kích thước*],              
                        [$65 times 39.3$ mm],
                    )
                )

                #figure(
                    image("assets/LM2596.png", width: 140pt),
                    caption: [Module hạ áp DC-DC LM2596 (tích hợp vôn kế)],
                ) <glacier>
                #linebreak()
            ==== Linh kiện phụ trợ
                #figure(
                    caption: [Danh sách các linh kiện phụ trợ],
                    table(
                    columns: (1fr, 1fr),
                    inset: 10pt,
                    align: left + horizon,
                    stroke: 0.5pt + black,
                    
                    [*Tụ điện*],                    
                    [$220 mu F$ – $35V$],

                    [*Nguồn DC*],                    
                    [$24V$ – $5A$],

                    [*Cầu đầu điện*],          
                    [$6$ cổng - $15A$],

                    [*Mạch chuyển FPC/FFC sang DIP*], 
                    [],
                    )
                )
        === Sơ đồ nối mạch
            #linebreak()
            #figure(
                image("assets/board.png", width: 100%),
                caption: [Sơ đồ nối mạch],
            ) <glacier>
            #pagebreak()

        === Sơ đồ chân
            #figure(
                table(
                    columns: (1fr, 1fr, 1.2fr, 1fr),
                    inset: 10pt,
                    align: left + horizon,
                    stroke: 0.5pt + black,
                    fill: (x, y) => if y == 0 { gray.lighten(80%) },
        
                    [*Linh kiện*], [*Chân linh kiện*], [*Chân vi điều khiển*], [*Cấu hình I/O*],
        
                    [Màn cảm ứng], [X+], [PA1], [ADC / GPIO Out],
                    [Màn cảm ứng], [Y+], [PA2], [ADC / GPIO Out],
                    [Màn cảm ứng], [X-], [PA3], [ADC / GPIO In],
                    [Màn cảm ứng], [Y-], [PA4], [ADC / GPIO In],
                    
                    [TMC2208 A], [STEP], [PA15], [GPIO Out],
                    [TMC2208 A], [DIR], [PB3], [GPIO Out],
                    [TMC2208 A], [EN], [PB12], [GPIO Out],
        
                    [TMC2208 B], [STEP], [PB5], [GPIO Out],
                    [TMC2208 B], [DIR], [PA4], [GPIO Out],
                    [TMC2208 B], [EN], [PB12], [GPIO Out],
        
                    [TMC2208 C], [STEP], [PB7], [GPIO Out],
                    [TMC2208 C], [DIR], [PB6], [GPIO Out],
                    [TMC2208 C], [EN], [PB12], [GPIO Out],

                    [LM2596], [3.3V Logic Rail], [3V3 Pin], [Power In],
                ),
                caption: [Bảng sơ đồ chân nối với vi điều khiển],
            ) <glacier>
            #linebreak()

            #figure(
                table(
                    columns: (1fr, 1fr, 1.2fr),
                    inset: 10pt,
                    align: left + horizon,
                    stroke: 0.5pt + black,
                    fill: (x, y) => if y == 0 { gray.lighten(80%) },
        
                    [*Linh kiện*], [*Chân linh kiện*], [*Chân vi điều khiển*],
        
                    [Màn cảm ứng], [X+], [PA0], [ADC / GPIO Out],
                    [Màn cảm ứng], [Y+], [PA1], [ADC / GPIO Out],
                    [Màn cảm ứng], [X-], [PA2], [ADC / GPIO In],
                    [Màn cảm ứng], [Y-], [PA3], [ADC / GPIO In],
                    
                    [TMC2208 A], [STEP], [PA15], [GPIO Out],
                    [TMC2208 A], [DIR], [PB3], [GPIO Out],
                    [TMC2208 A], [EN], [PB12], [GPIO Out],
        
                    [TMC2208 B], [STEP], [PB5], [GPIO Out],
                    [TMC2208 B], [DIR], [PA4], [GPIO Out],
                    [TMC2208 B], [EN], [PB12], [GPIO Out],
        
                    [TMC2208 C], [STEP], [PB7], [GPIO Out],
                    [TMC2208 C], [DIR], [PB6], [GPIO Out],
                    [TMC2208 C], [EN], [PB12], [GPIO Out],

                    [Voltage Regulator], [5V Logic Rail], [5V Pin], [Power In],
                    [Voltage Regulator], [3.3V Logic Rail], [3V3 Pin], [Power In],
                ),
                caption: [Bảng sơ đồ chân nối với mạch điều khiển động cơ TMC2208 đến các linh kiện],
            ) <glacier>
            #linebreak()

        #pagebreak()

    == Thiết kế cơ khí
    == Kiến trúc phần mềm 
        === Công cụ phát triển
            Trong quá trình phát triển hệ thống, các công cụ phần mềm sau được sử dụng:

            - #link("https://www.st.com/en/development-tools/stm32cubemx.html")[*STM32CubeMX*]: dùng để cấu hình vi điều khiển, thiết lập clock, GPIO, ADC và các ngoại vi cần thiết, đồng thời sinh mã khởi tạo ban đầu.

            - #link("http://openocd.org/")[*OpenOCD*] và #link("https://www.st.com/en/development-tools/stsw-link004.html")[*ST-Link Utility*]: được sử dụng để nạp chương trình xuống vi điều khiển và thực hiện debug trong quá trình phát triển.

            - #link("https://www.jetbrains.com/clion/")[*CLion*]: môi trường phát triển tích hợp (IDE) dùng để viết, quản lý và debug mã nguồn chương trình.

            - #link("https://cmake.org/")[*CMake*]: công cụ tạo hệ thống biên dịch, dùng để cấu hình và sinh các tệp phục vụ quá trình biên dịch và liên kết chương trình (ví dụ: Makefile, Ninja).

            