= Cơ sở lý thuyết
    == Mô hình Robot 3-RPS
        Robot 3RPS là một cơ cấu song song gồm 3 chân (3 nhánh) có chuỗi khớp theo thứ tự: *R* (Revolute – khớp quay) ở đế, *P* (Prismatic – khớp tịnh tiến, thường là cơ cấu vít me/đai ốc hoặc thanh trượt được dẫn động) và *S* (Spherical – khớp cầu) nối với bàn công tác. Nhờ cấu trúc song song, 3RPS có độ cứng vững tốt, sai số tích lũy nhỏ và phù hợp cho các bài toán điều khiển nghiêng mặt phẳng (tilt) như cân bằng bi.

        Về bậc tự do, với bố trí đối xứng thường gặp, 3RPS tạo ra 3 bậc tự do của bàn công tác (thường là 2 góc nghiêng *roll/pitch* và 1 tịnh tiến theo trục *z*). Khi điều khiển cân bằng bi trên mặt phẳng, ta chủ yếu quan tâm đến hai góc nghiêng của bàn; còn độ cao *z* thường được xem là hằng hoặc biến thiên nhỏ tùy theo thiết kế.

        Để mô tả động học, đặt hệ tọa độ gốc {B} gắn với đế, hệ {P} gắn với bàn công tác. Gọi $B_i$ là tọa độ các điểm gắn chân trên đế trong {B}, và $P_i$ là tọa độ các điểm gắn chân trên bàn trong {P}, với $i = 1..3$. Tư thế của bàn được mô tả bởi ma trận quay $R$ và vectơ tịnh tiến $p$ (từ {B} đến gốc {P}). Khi đó vectơ chân thứ $i$ trong {B} là:

        $ l_i = p + R P_i - B_i $

        Chiều dài (hoặc hành trình hiệu dụng) của chân $i$ là:

        $ q_i = ||l_i|| $

        Đây là dạng *động học nghịch* điển hình: cho tư thế mong muốn $(R, p)$, ta tính được $q_1, q_2, q_3$ để sinh lệnh cho các cơ cấu tịnh tiến (xung bước/độ quay motor → dịch chuyển). Ngược lại, *động học thuận* (từ $q_i$ suy ra $(R,p)$) thường phức tạp hơn và hay được giải bằng phương pháp số; trong bài toán cân bằng, hệ thống có thể dùng cảm biến (màn cảm ứng) để phản hồi trực tiếp trạng thái bi nên không nhất thiết phải giải động học thuận chính xác ở mọi thời điểm.

    == Màn cảm ứng điện trở
        Màn cảm ứng điện trở hoạt động dựa trên hai lớp dẫn điện được ngăn cách bởi một lớp cách điện mỏng. Khi có lực tác động lên bề mặt, hai lớp này tiếp xúc tại điểm chạm, tạo thành một cầu điện trở. Bằng cách đo điện áp tại điểm tiếp xúc, hệ thống có thể xác định tọa độ theo hai trục X và Y.

        Ưu điểm của loại màn này là chi phí thấp và có thể sử dụng với nhiều vật liệu tiếp xúc. Tuy nhiên, nhược điểm là độ bền không cao, độ nhạy kém hơn so với màn cảm ứng điện dung và không hỗ trợ đa điểm hiệu quả.

        #figure(
            image("assets/resistive-touch-mechanism.png", width: 340pt),
            caption: [Cấu tạo của màn cảm ứng điện trở],
        )

    == Điều khiển động cơ bước thông qua driver
        Động cơ bước (stepper) di chuyển theo từng bước rời rạc; driver nhận các xung điều khiển (xung bước) và tín hiệu hướng để quay theo bước hoặc hướng tương ứng. Các driver phổ biến (ví dụ A4988, DRV8825) hỗ trợ microstepping để tăng độ mịn chuyển động bằng cách điều khiển dòng cuộn dây. Khi tích hợp, cần cấu hình giới hạn dòng, nối các chân `STEP`, `DIR` và `ENABLE`, và đảm bảo cấp nguồn/phân tản nhiệt cho driver để tránh quá nhiệt.

    == Thuật toán điều khiển PID
        Thuật toán điều khiển Proportional–Integral–Derivative (PID) là phương pháp điều khiển phản hồi dựa trên sai lệch giữa giá trị đặt và giá trị thực. Bộ điều khiển gồm ba thành phần:

        - *Thành phần tỉ lệ (P)*: phản ứng theo sai số tức thời.
        - *Thành phần tích phân (I)*: tích lũy sai số theo thời gian nhằm loại bỏ sai số tĩnh.
        - *Thành phần vi phân (D)*: dự đoán xu hướng thay đổi của sai số để giảm dao động.

        Công thức tổng quát trong miền thời gian:

        $ u(t) = K_p e(t) + K_i integral e(t) dif t + K_d (dif e(t))/(dif t) $

        Trong đó, $e(t)$ là sai lệch giữa giá trị mong muốn và giá trị đo được, còn $K_p$, $K_i$, $K_d$ là các hệ số điều khiển. Trong thực tế, các tham số này cần được điều chỉnh (tuning) để đạt đáp ứng mong muốn như thời gian ổn định ngắn, độ vượt quá nhỏ và sai số xác lập thấp.

