= Thiết kế và triển khai hệ thống
    == Thiết kế tổng thể
    == Thiết kế phần cứng
        === Danh sách linh kiện
            ==== Vi điều khiển STM32F411CEU6
                *Vi điều khiển STM32F411CEU6* (còn được gọi là “Blackpill”) là vi điều khiển thuộc dòng STM32F4 của STMicroelectronics, sử dụng nhân ARM Cortex-M4 và được tích hợp bộ xử lý số học dấu chấm động (Floating Point Unit – FPU), cho phép thực thi các phép toán số thực với hiệu năng cao.
            
                Trong hệ thống điều khiển, vi điều khiển đóng vai trò trung tâm, thực hiện việc thu thập dữ liệu từ các cảm biến, xử lý thông tin và phát tín hiệu điều khiển đến các cơ cấu chấp hành như động cơ, v.v..

                #linebreak()
                #figure(
                    image("assets/STM32F411CEU6-pinout.png", width: 360pt),
                    caption: [Sơ đồ chân của STM32F411CEU6 (Blackpill)],
                ) <glacier>
                #linebreak()

            ==== Màn cảm ứng điện trở 9”
                *Màn hình cảm ứng điện trở (kích thước 9 inch)* đóng vai trò là cảm biến vị trí. Nguyên lý hoạt động của màn cảm ứng điện trở dựa trên sự thay đổi điện áp khi có lực tác động lên bề mặt, làm hai lớp dẫn điện tiếp xúc với nhau. Bằng cách lần lượt cấp điện áp theo hai trục X và Y và đo giá trị điện áp tại điểm tiếp xúc thông qua bộ ADC, hệ thống có thể xác định được tọa độ của điểm chạm.
                
                Trong hệ thống, màn hình nhận tọa độ tiếp xúc của quả bóng trên bề mặt, từ đó cung cấp dữ liệu đầu vào cho bộ điều khiển nhằm xác định sai lệch vị trí và phục vụ quá trình cân bằng.

                #linebreak()
                #figure(
                    image("assets/resistive-touch.png", width: 200pt),
                    caption: [Màn hình cảm ứng điện trở 9"],
                ) <glacier>
                #linebreak()

            ==== Mạch điều khiển động cơ bước TMC2208
                *TMC2208* là mạch điều khiển động cơ bước tích hợp, hỗ trợ điều khiển vi bước (microstepping) và điều chỉnh dòng điện thông minh nhằm tối ưu hiệu suất hoạt động của động cơ. Nguyên lý hoạt động của driver dựa trên việc nhận tín hiệu STEP/DIR từ vi điều khiển để xác định số bước và chiều quay, đồng thời sử dụng kỹ thuật điều chế dòng (chopper current control) để kiểm soát dòng điện qua các cuộn dây của động cơ.

                Trong hệ thống cân bằng bóng, driver này đóng vai trò trung gian giữa vi điều khiển và động cơ bước, giúp chuyển đổi tín hiệu điều khiển thành chuyển động quay mượt mà, giảm rung và nhiễu cơ học. 

                #linebreak()
                #figure(
                    image("assets/TMC2208-pinout.png", width: 200pt),
                    caption: [Sơ đồ chân cắm mạch điều khiển động cơ bước TMC2208],
                ) <glacier>
                #linebreak()

            ==== Động cơ bước 17HS4401S
                *Động cơ bước 17HS4401S* là cơ cấu chấp hành chính trong hệ thống, được sử dụng để điều chỉnh góc nghiêng của mặt phẳng theo hai trục. Nguyên lý hoạt động của động cơ bước dựa trên việc chuyển đổi các xung điều khiển thành các bước quay rời rạc, trong đó mỗi xung tương ứng với một góc quay xác định.

                #linebreak()
                #figure(
                    image("assets/17HS4401S.png", width: 200pt),
                    caption: [Động cơ bước 17HS4401S],
                ) <glacier>
                #linebreak()

                #linebreak()
                #figure(
                    image("assets/17HS4401S-blueprint.png", width: 360pt),
                    caption: [Bản vẽ kỹ thuật động cơ bước 17HS4401S],
                ) <glacier>
                #linebreak()
            
            ==== Mạch hạ áp LM2596
                *Mạch hạ áp LM2596* được sử dụng để chuyển đổi điện áp đầu vào từ nguồn cung cấp xuống mức điện áp phù hợp với các linh kiện điện tử trong hệ thống, đảm bảo hoạt động ổn định và an toàn.

                #linebreak()
                #figure(
                    image("assets/LM2596.png", width: 200pt),
                    caption: [Mạch hạ áp LM2596],
                ) <glacier>
                #linebreak()
            ==== Các linh kiện khác
        === Sơ đồ nối mạch
            #linebreak()
            #figure(
                image("assets/board.png", width: 100%),
                caption: [Sơ đồ nối mạch],
            ) <glacier>
            #linebreak()

        === Sơ đồ chân
            #figure(
                table(
                    columns: (1fr, 1fr, 1.2fr, 1fr),
                    inset: 10pt,
                    align: left + horizon,
                    stroke: 0.5pt + black,
                    fill: (x, y) => if y == 0 { gray.lighten(80%) },
        
                    [*Linh kiện*], [*Chân linh kiện*], [*Chân vi điều khiển*], [*Cấu hình I/O*],
        
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
                caption: [Bảng sơ đồ nối mạch],
            ) <glacier>
            #linebreak()
    == Thiết kế cơ khí
    == Kiến trúc phần mềm 


            