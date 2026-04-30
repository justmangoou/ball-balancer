= Giới thiệu
    == Bài toán
        Hệ thống cân bằng bóng trên mặt phẳng là một bài toán điển hình trong lĩnh vực điều khiển tự động, thường được dùng để minh họa điều khiển phản hồi và khả năng ổn định của một hệ cơ điện tử. 

        Đây là một bài toán _thách thức_ vì hệ có nhiều yếu tố phi tuyến và không lý tưởng. Chuyển động của bóng phụ thuộc vào góc nghiêng của mặt phẳng, ma sát và đặc tính bề mặt; đồng thời hệ có độ trễ và nhiễu do phần cơ khí và trong quá trình đo lường. Những yếu tố này khiến hệ dễ xuất hiện dao động hoặc không đạt yêu cầu về đáp ứng biên độ và tốc độ nếu không được thiết kế hệ thống điều khiển hợp lý.

    == Mục tiêu và phạm vi của đề tài
        Mục tiêu của đề tài là xây dựng một hệ thống có khả năng:
    
        - Xác định vị trí quả bóng trên mặt phẳng: thu nhận và xử lý tín hiệu để ước lượng tọa độ $(x, y)$ của bóng.
        - Điều khiển mặt phẳng để đưa bóng về vị trí đặt: xây dựng thuật toán điều khiển nhằm điều chỉnh chuyển động của mặt phẳng để giảm sai lệch vị trí.
        - Duy trì trạng thái cân bằng ổn định: hạn chế dao động, nhiễu và đảm bảo sai số xác lập nhỏ quanh vị trí mong muốn.

        #linebreak()

        Trong phạm vi đề tài, hệ thống được triển khai trong môi trường thí nghiệm với một quả bi thép đơn và mặt phẳng kích thước cố định. Bài toán tập trung vào điều khiển vị trí trong một vùng làm việc giới hạn trên mặt phẳng và đánh giá chất lượng điều khiển thông qua các tiêu chí như: thời gian đáp ứng, độ vượt quá, độ dao động và sai số xác lập.

    == Cơ sở tham khảo
        Đề tài tham khảo mô hình Ball Balancer được đăng trên nền tảng Instructables (https://www.instructables.com/Ball-Balancer/).

        Trong đề tài này, thiết kế cơ khí được kế thừa với kích thước và tỉ lệ được điều chỉnh cho phù hợp với phần cứng. Sơ đồ nối mạch cũng dựa trên nguyên lý tương tự, với một số thay đổi để đảm bảo tính tương thích với linh kiện được sử dụng.