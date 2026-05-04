= Giới thiệu
    == Bài toán
        Hệ thống cân bằng bóng trên mặt phẳng là một bài toán điển hình trong lĩnh vực điều khiển tự động, thường được dùng để minh họa điều khiển phản hồi và khả năng ổn định của một hệ cơ điện tử. 

        Đây là một bài toán _thách thức_ do hệ có nhiều yếu tố phi tuyến và không lý tưởng. Chuyển động của bóng phụ thuộc vào góc nghiêng của mặt phẳng, ma sát và đặc tính bề mặt. Ngoài ra, hệ chịu ảnh hưởng của độ trễ và nhiễu phát sinh từ phần cơ khí cũng như từ quá trình đo lường. Những yếu tố này khiến hệ có xu hướng xuất hiện dao động hoặc không đáp ứng được yêu cầu về biên độ và tốc độ nếu hệ thống không được thiết kế và hiệu chỉnh phù hợp.

    == Mục tiêu và phạm vi của đề tài
        Mục tiêu của đề tài là xây dựng một hệ thống có khả năng:
    
        - *Xác định vị trí quả bóng trên mặt phẳng*: thu nhận và xử lý tín hiệu để xác định tọa độ $(x, y)$ của bóng.
        - *Điều khiển mặt phẳng để đưa bóng về vị trí đặt*: xây dựng thuật toán điều khiển nhằm điều chỉnh chuyển động của mặt phẳng để giảm sai lệch vị trí.
        - *Duy trì trạng thái cân bằng ổn định*: hạn chế dao động, nhiễu và đảm bảo sai số xác lập nhỏ quanh vị trí mong muốn.

        #v(-1em)
        #h(0em)

        Trong phạm vi đề tài, hệ thống được triển khai trong môi trường thí nghiệm với một quả bi thép đơn và mặt phẳng kích thước cố định. Bài toán tập trung vào điều khiển vị trí trong một vùng làm việc giới hạn trên mặt phẳng và đánh giá chất lượng điều khiển thông qua các tiêu chí như: thời gian đáp ứng, độ dao động và sai số xác lập.

    == Cơ sở tham khảo
        Đề tài tham khảo mô hình _Ball Balancer_ của Aaed Musa được đăng trên nền tảng Instructables: https://www.instructables.com/Ball-Balancer/.

        Trong đề tài này, thiết kế cơ khí được kế thừa với kích thước và tỉ lệ được điều chỉnh phù hợp với phần cứng. Sơ đồ kết nối mạch được dựa trên nguyên lý tương tự, với một số thay đổi nhằm đảm bảo sự tương thích với linh kiện được sử dụng.