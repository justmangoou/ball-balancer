#import "@preview/fletcher:0.5.8": diagram, node, edge
#import "constants.typ": HEARTBEAT_TIMER, HEARTBEAT_INTERVAL, HEARTBEAT_FREQUENCY, ACTUATOR_TIMER, ACTUATOR_INTERVAL, ACTUATOR_FREQUENCY

= Thiết kế và triển khai hệ thống
    == Thiết kế tổng thể
        Hệ thống được thiết kế theo mô hình điều khiển vòng kín, trong đó vị trí của quả bóng được đo liên tục và sử dụng làm tín hiệu phản hồi để điều chỉnh trạng thái của hệ thống.

        Về mặt chức năng, hệ thống bao gồm ba khối chính:

        - *Khối cảm biến:* sử dụng màn hình cảm ứng điện trở để xác định tọa độ $(x, y)$ của quả bóng.
        - *Khối xử lý:* vi điều khiển thực hiện nhiệm vụ thu nhận dữ liệu và tính toán tín hiệu điều khiển.
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
                node((0,3), [Động cơ bước], name: <motor>, corner-radius: 2pt),
                node((0,4), [Mặt phẳng], name: <plate>, corner-radius: 2pt),
                node((1,4), [Bóng], name: <ball>, corner-radius: 2pt),

                // Left labels
                node((-2,0), [*Khối cảm biến*], name: <lsensor>),
                node((-2,1), [*Khối xử lý*], name: <lcontroller>),
                node((-2,3), [*Khối chấp hành*], name: <lactuator>),

                // Main flow
                edge(<sensor>, <controller>, "-|>"),
                edge(<controller>, <driver>, "-|>"),
                edge(<driver>, <motor>, "-|>"),
                edge(<motor>, <plate>, "-|>"),
                edge(<plate>, <ball>, "-|>"),

                // Feedback
                edge(<ball>, (1,3), (1,0), <sensor>, "-|>")[Vị trí],

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
                *STM32F411CEU6 (Blackpill)* là vi điều khiển thuộc dòng STM32F4 của STMicroelectronics, sử dụng nhân ARM Cortex-M4 tích hợp Floating Point Unit (FPU), cho phép xử lý hiệu quả các phép toán số thực, phù hợp với các hệ thống điều khiển yêu cầu hiệu suất cao.

                #figure(
                    caption: [Thông số kỹ thuật STM32F411CEU6],
                    table(
                        columns: (1fr, 1fr),
                        inset: 7pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,
            
                        [*Nhân*],                    
                        [ARM 32-bit Cortex-M4],

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
                    image("assets/STM32F411CEU6-pinout.png", width: 75%),
                    caption: [Sơ đồ chân của STM32F411CEU6 (Blackpill)],
                )

            ==== Màn cảm ứng điện trở
                *Màn hình cảm ứng điện trở* được sử dụng để thu nhận thông tin vị trí tiếp xúc trên bề mặt. Với cấu trúc 4 dây điện trở, thiết bị có khả năng xác định vị trí chạm với độ chính xác tương đối cao và ổn định. Nhờ kích thước vùng hoạt động lớn và cấu tạo đơn giản, loại màn hình này phù hợp với các ứng dụng yêu cầu xác định vị trí trên mặt phẳng với chi phí thấp. Nguyên lý hoạt động được trình bày tại @resistive_touch_mechanism.

                #figure(
                    caption: [Thông số kỹ thuật màn cảm ứng điện trở],
                    table(
                        columns: (1fr, 1fr),
                        inset: 7pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,

                        [*Kích thước*], [9 inch],

                        [*Vùng hoạt động*], [$210 times 126$ mm],

                        [*Vật liệu bề mặt*], [Màng phim + kính],
                    )
                )

                #figure(
                    image("assets/resistive-touch.png", width: 50%),
                    caption: [Màn hình cảm ứng điện trở 9"],
                )
                #linebreak()

            ==== Driver TMC2208
                *Driver TMC2208* là bộ điều khiển động cơ bước tích hợp các công nghệ StealthChop2$trademark$ và SpreadCycle$trademark$ của Trinamic. Các công nghệ này giúp hạn chế tiếng ồn, đồng thời đảm bảo chuyển động mượt với độ chính xác cao thông qua cơ chế vi bước. Đồng thời, driver tối ưu hiệu suất năng lượng và giảm sinh nhiệt trong quá trình vận hành lâu dài. Dòng điện cấp cho động cơ có thể được điều chỉnh thông qua điện áp tham chiếu ($V_"ref"$) hoặc giao tiếp UART, cho phép tự cấu hình tùy theo yêu cầu hệ thống.

                #linebreak()
                #figure(
                    caption: [Thông số kỹ thuật driver TMC2208],
                    table(
                        columns: (1fr, 1fr),
                        inset: 7pt,
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
                    image("assets/TMC2208-pinout.png", width: 50%),
                    caption: [Sơ đồ chân cắm mạch điều khiển động cơ bước TMC2208],
                ) 
                #linebreak()

            ==== Động cơ bước 17HS4401S
                *Động cơ bước 17HS4401S (chuẩn NEMA 17)* là động cơ bước hai pha (bipolar) được sử dụng phổ biến trong các hệ thống yêu cầu độ chính xác và độ ổn định cao. Động cơ có góc bước cơ bản nhỏ và mô-men giữ tương đối lớn.

                #figure(
                    caption: [Thông số kỹ thuật động cơ bước 17HS4401S],
                    table(
                        columns: (1fr, 1fr),
                        inset: 7pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,

                        [*Góc bước cơ bản*], 
                        [$1.8 degree plus.minus 0.09 degree$],

                        [*Kích thước mặt bích*], 
                        [$42.3 times 42.3$ mm],

                        [*Dòng điện định mức*], 
                        [$1.5A$ / pha],

                        [*Mô-men xoắn giữ*], 
                        [$40 N dot$ cm],

                        [*Khối lượng*], 
                        [$~300$ g],
                    )
                )

                #figure(
                    image("assets/17HS4401S.png", width: 36%),
                    caption: [Động cơ bước 17HS4401S],
                )
                #linebreak()
                #figure(
                    image("assets/17HS4401S-blueprint.png", width: 75%),
                    caption: [Bản vẽ kỹ thuật động cơ bước 17HS4401S],
                )
                #linebreak()
            
            ==== Module hạ áp LM2596
                *Module hạ áp DC-DC LM2596 (tích hợp vôn kế)* là bộ chuyển đổi điện áp một chiều có khả năng hạ điện áp đầu vào xuống mức thấp hơn, hoạt động theo nguyên lý chuyển mạch tần số cao, cho hiệu suất chuyển đổi cao. Module được tích hợp màn hình LED và vi điều khiển đo điện áp, giúp giám sát trực tiếp điện áp đầu vào/đầu ra trong quá trình vận hành với độ chính xác khoảng $plus.minus 0.05V$. Điện áp đầu ra có thể thay đổi thông qua việc điều chỉnh biến trở tích hợp trên module.
                
                #pagebreak() // CHECK: may break
                #figure(
                    caption: [Thông số kỹ thuật module hạ áp DC-DC LM2596],
                    table(
                        columns: (1.2fr, 2.25fr),
                        inset: 7pt,
                        align: left + horizon,
                        stroke: 0.5pt + black,
            
                        [*Điện áp đầu vào $V_"in"$*],                    
                        [$4.0V$ đến $40V$ \ (Vôn kế hoạt động khi $V_"in" > 4.5V$)],
                        
                        [*Điện áp đầu ra $V_"out"$*],                    
                        [$1.25V$ đến $37V$ \ (Điều chỉnh bằng biến trở)],
                        
                        [*Dòng điện đầu ra*],          
                        [$2.0A$ RMS \ (Tối đa $~3.0A$ với tản nhiệt)],

                        [*Công suất đầu ra tối đa*],
                        [$20 W$ \ Tản nhiệt nếu P > 15W],

                        [*Hiệu suất chuyển đổi*],
                        [$~ 88%$],

                        [*Kích thước*],              
                        [$65 times 39.3$ mm],
                    )
                )

                #figure(
                    image("assets/LM2596.png", width: 30%),
                    caption: [Module hạ áp DC-DC LM2596 (tích hợp vôn kế)],
                )
                #linebreak()
                
            ==== Linh kiện phụ trợ
                #figure(
                    caption: [Danh sách các linh kiện phụ trợ],
                    table(
                    columns: (1fr, 1fr),
                    inset: 7pt,
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
        // TODO: make this pro
        === Sơ đồ nối mạch
            Sơ đồ nối mạch thể hiện cách liên kết tổng thể giữa các thành phần chính trong hệ thống, bao gồm vi điều khiển, cảm biến, driver động cơ và nguồn cấp. Sơ đồ này giúp minh họa trực quan cấu trúc phần cứng và luồng kết nối giữa các khối chức năng.

            #v(0.7em)

            #figure(
                image("assets/board.png", width: 75%),
                caption: [Sơ đồ kết nối tổng thể giữa vi điều khiển, driver động cơ và các khối chức năng],
            )
            #pagebreak()

        === Sơ đồ chân nối
            Bảng dưới đây trình bày chi tiết kết nối giữa các chân của linh kiện và chân của vi điều khiển, bao gồm cả cấu hình I/O tương ứng. 

            #figure(
                table(
                    columns: (1.5fr, 0.55fr, 0.6fr, 1.5fr),
                    inset: 7pt,
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
                    [TMC2208 B], [DIR], [PB4], [GPIO Out],
                    [TMC2208 B], [EN], [PB12], [GPIO Out],
        
                    [TMC2208 C], [STEP], [PB7], [GPIO Out],
                    [TMC2208 C], [DIR], [PB6], [GPIO Out],
                    [TMC2208 C], [EN], [PB12], [GPIO Out],

                    [LM2596], [OUT+], [3V3], [-],
                    [LM2596], [OUT-], [GND], [-],
                ),
                caption: [Sơ đồ chân nối với vi điều khiển],
            )

            #v(-1em)
            #h(0em)

            Trong đó, các chân điều khiển của driver TMC2208 (STEP, DIR, EN) được kết nối trực tiếp với các chân GPIO của vi điều khiển, cho phép điều khiển độc lập từng động cơ. Các chân EN được nối chung để có thể bật/tắt đồng thời toàn bộ driver. 
            
            Đối với màn cảm ứng điện trở, các chân được cấu hình linh hoạt giữa chế độ GPIO và ADC để thực hiện việc đo tọa độ, theo nguyên lý hoạt động đã trình bày tại @resistive_touch_mechanism.

            #v(1em)
            #figure(
                table(
                    columns: (0.5fr, 1fr),
                    inset: 7pt,
                    align: left + horizon,
                    stroke: 0.5pt + black,
                    fill: (x, y) => if y == 0 { gray.lighten(80%) },
        
                    [*Chân driver*], [*Kết nối / chức năng*],
        
                    [VM],  [Nguồn động cơ (DC 24V)],
                    [VIO], [Nguồn logic (3.3V)],
                    [GND], [Đất chung],
                    [M1A], [Cuộn 1 - Động cơ bước],
                    [M1B], [Cuộn 1 - Động cơ bước],
                    [M2A], [Cuộn 2 - Động cơ bước],
                    [M2B], [Cuộn 2 - Động cơ bước],
                    
                    [MS1], [3V3 - Cấu hình vi bước],
                    [MS2], [3V3 - Cấu hình vi bước],
                ),
                caption: [Sơ đồ kết nối các chân của driver TMC2208 với nguồn và động cơ bước],
            )

            #v(-1em)
            #h(0em)

            Việc thiết lập các chân MS1 và MS2 ở mức cao (3.3V) cấu hình driver hoạt động ở chế độ vi bước 1/16. Chế độ này giúp cải thiện độ mượt của chuyển động, tăng độ phân giải điều khiển và giảm rung động cũng như tiếng ồn của động cơ bước.

            Trong thiết kế này, giao tiếp UART của driver không được sử dụng. Thay vào đó, các tham số hoạt động được cấu hình thông qua các chân phần cứng (MS1, MS2). Cách tiếp cận này giúp giảm độ phức tạp của hệ thống, đơn giản hóa việc lập trình và giảm yêu cầu về tài nguyên vi điều khiển, đồng thời vẫn đáp ứng đủ yêu cầu điều khiển của bài toán.

        #pagebreak()

    == Thiết kế cơ khí
        #figure(
            image("assets/3d-design.png", width: 55%),
            caption: [Mô hình 3D thiết kế cơ khí],
        )

        #v(1em)

        #figure(
            image("assets/technical-drawing.png", width: 100%),
            caption: [Bản vẽ kỹ thuật]
        )

        #pagebreak()
    == Kiến trúc phần mềm 
        === Công cụ phát triển
            Trong quá trình phát triển hệ thống, các công cụ phần mềm sau được sử dụng:

            - #link("https://www.st.com/en/development-tools/stm32cubemx.html")[*STM32CubeMX*]: dùng để cấu hình vi điều khiển, thiết lập clock, GPIO, ADC và các ngoại vi cần thiết, đồng thời sinh mã khởi tạo ban đầu.

            - #link("http://openocd.org/")[*OpenOCD*] và #link("https://www.st.com/en/development-tools/stm32cubeprog.html")[*STM32CubeProgrammer*]: được sử dụng để nạp chương trình xuống vi điều khiển và thực hiện debug trong quá trình phát triển.

            - #link("https://www.jetbrains.com/clion/")[*CLion*]: môi trường phát triển tích hợp (IDE) dùng để viết, quản lý và debug mã nguồn chương trình.

            - #link("https://cmake.org/")[*CMake*]: công cụ tạo hệ thống biên dịch, dùng để cấu hình và sinh các tệp phục vụ quá trình biên dịch và liên kết chương trình (ví dụ: Makefile, Ninja).

        === Cấu hình xung nhịp hệ thống
            Hệ thống sử dụng nguồn xung nhịp ngoài HSE với tần số 25 MHz. Thông qua bộ nhân tần PLL với các tham số cấu hình $M=25$, $N=200$ và $P=2$, vi điều khiển đạt xung nhịp hệ thống (SYSCLK) 100 MHz.

            Các tham số này được lựa chọn nhằm đảm bảo các điều kiện hoạt động tối ưu của PLL: hệ số $M=25$ đưa tần số đầu vào của PLL về 1 MHz (thuộc trong dải khuyến nghị), hệ số $N=200$ tạo tần số VCO đạt 200 MHz (thuộc dải hoạt động cho phép), và hệ số $P=2$ chia tần số này xuống 100 MHz, tương ứng với tần số tối đa của hệ thống.

            #figure(
                image("assets/clock-config.png", width: 75%),
                caption: [Cấu hình xung nhịp hệ thống],
            )

            Cấu hình này đảm bảo hiệu năng xử lý đủ cao cho các tác vụ thời gian thực, bao gồm thu thập dữ liệu cảm biến, xử lý thuật toán điều khiển và phát xung điều khiển động cơ với độ chính xác cao: 
            - _HCLK (AHB bus):_ 100 MHz.
            - _PCLK1 (APB1):_ 50 MHz (Timer đạt 100 MHz).
            - _PCLK2 (APB2):_ 100 MHz.
            
            Ngoài ra, bộ đếm chu kỳ DWT (Data Watchpoint and Trace) được sử dụng để xây dựng các hàm trễ chính xác ở mức micro giây ($mu s$), hỗ trợ đồng bộ hóa và điều khiển thời gian trong hệ thống.

        === Thiết lập Timer
            ==== Timer điều khiển (#HEARTBEAT_TIMER)
                Timer #HEARTBEAT_TIMER đảm nhiệm làm nhiệm vụ điều khiển chính cho việc đọc cảm biến và cập nhật thuật toán điều khiển.

                Cấu hình:
                - Prescaler: $"PSC" = 99$
                - Auto-reload: $"ARR" = 4999$
                
                $ f = (100 "Mhz")/(("PSC" + 1)("ARR" + 1)) = (100 times 10^6)/(100 times 5000) = #HEARTBEAT_FREQUENCY $

                #v(0.5em)
                Tương ứng với chu kỳ #HEARTBEAT_INTERVAL.

            ==== Timer chấp hành (#ACTUATOR_TIMER)
                Timer #ACTUATOR_TIMER đảm nhiệm làm nhiệm vụ thực hiện xung PWM điều khiển động cơ bước.

                Cấu hình:
                - Prescaler: $"PSC" = 99$
                - Auto-reload: $"ARR" = 24$
                
                $ f = (100 "Mhz")/(("PSC" + 1)("ARR" + 1)) = (100 times 10^6)/(100 times 25) = #ACTUATOR_FREQUENCY $
                
                #v(0.5em)
                Tương ứng với chu kỳ #ACTUATOR_INTERVAL.
