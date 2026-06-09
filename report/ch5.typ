= Kiểm thử và đánh giá
    == Thiết lập thử nghiệm
        Để hỗ trợ quá trình kiểm thử và hiệu chỉnh PID, một công cụ thu thập dữ liệu thời gian thực được xây dựng bằng giao tiếp UART.  Dữ liệu từ vi điều khiển được truyền qua bộ chuyển đổi USB-to-TTL đến máy tính.
        
        Thư viện `pyserial` được sử dụng để đọc dữ liệu được gửi từ vi điều khiển, cho phép thu thập thông tin về vị trí hiện tại của quả bóng, vị trí mục tiêu và tín hiệu điều khiển trong thời gian thực.

        Thư viện `matplotlib` được sử dụng để trực quan hóa dữ liệu dưới dạng đồ thị, giúp đánh giá đáp ứng của hệ thống và hỗ trợ quá trình tối ưu tham số điều khiển.

    == Kết quả, phân tích và đánh giá
        #figure(
            image("assets/graph_data_1.png", width: 90%),
            caption: [Đồ thị biểu diễn sự thay đổi về đầu vào/ra của hai trục X/Y \ (09/06/2026 - 16:38:50)]
        )

        #figure(
            image("assets/graph_data_2.png", width: 90%),
            caption: [Đồ thị biểu diễn sự thay đổi về đầu vào/ra của hai trục X/Y \ (09/06/2026 - 16:58:05)]
        )

        #pagebreak()
        #figure(
            table(
                columns: (1.5fr, 1.25fr, 1.25fr),
                inset: 7pt,
                align: left + horizon,
                stroke: 0.5pt + black,
                fill: (x, y) => if y == 0 { gray.lighten(80%) },

                [*Đặc tính*], [*Trục X*], [*Trục Y*],
                [Sai số cực đại], 
                [82.761 mm], [28.786 mm],
                [Sai số cực tiểu],
                [-78.366 mm], [-20.643 mm],
                [Biên độ xuất lực Max], 
                [0.078], [0.030],
                [Sai số xác lập trung bình], 
                [2.138 mm], [2.937 mm],
                [Độ lệch chuẩn pha cuối], 
                [2.506 mm], [2.498 mm],
                [Thời gian xác lập], 
                [29.3 s], [35.6 s]
            ),
            caption: [Thống kê đặc tính của hệ thống]
        )

        Từ các số liệu trên, có thể rút ra một số nhận xét đặc tính của hệ thống như sau:

        *a) Sai số xác lập:* Hệ thống đạt được sai số xác lập trung bình lần lượt là $2.138 "mm"$ (trục X) và $2.937 "mm"$ (trục Y), Kết quả này cho thấy bộ điều khiển có khả năng đưa quả bóng về gần vị trí mục tiêu, tuy nhiên sai số vẫn chưa được triệt tiêu hoàn toàn.

        *b) Tính đối xứng giữa hai trục:* Độ lệch chuẩn ở trạng thái xác lập của hai trục gần như tương đương nhau ($2.506 "mm"$ và $2.498 "mm"$), cho thấy đáp ứng của hệ thống tương đối đồng nhất trên cả hai phương chuyển động.

        *c) Khả năng hiệu chỉnh sai lệch lớn:* Các giá trị sai số cực đại và cực tiểu cho thấy hệ thống có khả năng đưa quả bóng trở lại vùng cân bằng ngay cả khi xuất hiện sai lệch vị trí tương đối lớn. Điều này thể hiện tính ổn định và khả năng phục hồi của bộ điều khiển. Tuy nhiên ở vùng biên có thể xuất hiện hiện tượng không ổn định hoặc dao động lớn.

        *d) Thời gian xác lập:* Hệ thống đạt trạng thái ổn định sau khoảng $29.3 "s"$ (trục X) và $35.6 "s"$ (trục Y). Mặc dù hệ thống có khả năng hội tụ ổn định, thời gian xác lập vẫn còn tương đối lớn, đặc biệt trên trục Y.

        *e) Dao động tại trạng thái xác lập:* Sau khi kết thúc giai đoạn quá độ, hệ thống vẫn tồn tại dao động rất nhỏ quanh vị trí cân bằng.
