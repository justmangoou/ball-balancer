= Cơ sở lý thuyết
    == Mô hình Robot 3-RPS
        Robot 3RPS là một cơ cấu song song gồm 3 chân (3 nhánh) có chuỗi khớp theo thứ tự: *R* (Revolute – khớp quay) ở đế, *P* (Prismatic – khớp tịnh tiến, thường là cơ cấu vít me/đai ốc hoặc thanh trượt được dẫn động) và *S* (Spherical – khớp cầu) nối với bàn công tác. Nhờ cấu trúc song song, 3RPS có độ cứng vững tốt, sai số tích lũy nhỏ và phù hợp cho các bài toán điều khiển nghiêng mặt phẳng (tilt) như cân bằng bi.

        Về bậc tự do, với bố trí đối xứng thường gặp, 3RPS tạo ra 3 bậc tự do của bàn công tác (thường là 2 góc nghiêng *roll/pitch* và 1 tịnh tiến theo trục *z*). Khi điều khiển cân bằng bi trên mặt phẳng, ta chủ yếu quan tâm đến hai góc nghiêng của bàn; còn độ cao *z* thường được xem là hằng hoặc biến thiên nhỏ tùy theo thiết kế.

        Để mô tả động học, đặt hệ tọa độ gốc {B} gắn với đế, hệ {P} gắn với bàn công tác. Gọi $B_i$ là tọa độ các điểm gắn chân trên đế trong {B}, và $P_i$ là tọa độ các điểm gắn chân trên bàn trong {P}, với $i = 1..3$. Tư thế của bàn được mô tả bởi ma trận quay $R$ và vectơ tịnh tiến $p$ (từ {B} đến gốc {P}). Khi đó vectơ chân thứ $i$ trong {B} là:

        $ l_i = p + R P_i - B_i $

        Chiều dài (hoặc hành trình hiệu dụng) của chân $i$ là:

        $ q_i = ||l_i|| $

        Đây là dạng *động học nghịch* điển hình: cho tư thế mong muốn $(R, p)$, ta tính được $q_1, q_2, q_3$ để sinh lệnh cho các cơ cấu tịnh tiến (xung bước/độ quay motor → dịch chuyển). Ngược lại, *động học thuận* (từ $q_i$ suy ra $(R,p)$) thường phức tạp hơn và hay được giải bằng phương pháp số; trong bài toán cân bằng, hệ thống có thể dùng cảm biến (màn cảm ứng) để phản hồi trực tiếp trạng thái bi nên không nhất thiết phải giải động học thuận chính xác ở mọi thời điểm.

    == Màn cảm ứng điện trở <resistive_touch_mechanism>
        Màn cảm ứng điện trở hoạt động dựa trên hai lớp dẫn điện được ngăn cách bởi một lớp cách điện mỏng. Khi có lực tác động lên bề mặt, hai lớp này tiếp xúc tại điểm chạm, tạo thành một cầu điện trở. Bằng cách đo điện áp tại điểm tiếp xúc, hệ thống có thể xác định tọa độ theo hai trục X và Y.

        Ưu điểm của loại màn này là chi phí thấp và có thể sử dụng với nhiều vật liệu tiếp xúc. Tuy nhiên, nhược điểm là độ bền không cao, độ nhạy kém hơn so với màn cảm ứng điện dung và không hỗ trợ đa điểm hiệu quả.

        #figure(
            image("assets/resistive-touch-mechanism.png", width: 70%),
            caption: [Cấu tạo của màn cảm ứng điện trở],
        )

    // TODO: fix this
    == Cơ sở lý thuyết động cơ bước
        Động cơ bước (stepper) chuyển động theo các bước rời rạc; mỗi xung bước tạo một bước góc xác định. Bằng cách thay đổi tần số xung bước ta điều khiển vận tốc, còn số xung tích lũy quyết định vị trí. Microstepping chia mỗi bước cơ bản thành nhiều bước nhỏ hơn bằng cách điều chỉnh dòng trên các cuộn dây, giúp tăng độ mịn và giảm rung.

    == Driver điều khiển
        Driver nhận tín hiệu điều khiển từ bộ điều khiển (chẳng hạn `STEP`, `DIR`, `ENABLE`) và cấp/dừng dòng cho cuộn dây động cơ theo trình tự phù hợp. Các driver phổ biến như A4988 hoặc DRV8825 hỗ trợ cài đặt microstepping và giới hạn dòng (current limit) để bảo vệ động cơ. Khi tích hợp, cần cấu hình giới hạn dòng, nối các chân điều khiển, và đảm bảo nguồn cùng tản nhiệt đủ để tránh quá nhiệt.

    == Phương pháp điều khiển
        Phương pháp điều khiển đơn giản nhất là gửi xung bước và thiết lập chân hướng (`DIR`) để đổi chiều quay; tốc độ được điều khiển bằng tần số xung, vị trí bằng số xung. Với microstepping, cấu hình các chân chế độ bước trên driver hoặc qua giao tiếp phù hợp. Ngoài ra, hệ thống có thể kết hợp phản hồi (encoder, cảm biến vị trí) và thuật toán điều khiển (ví dụ điều khiển đóng vòng) để cải thiện độ chính xác và độ ổn định.

    == Thuật toán điều khiển PID <pid_control_algorithm>
        Thuật toán điều khiển Proportional–Integral–Derivative (PID) là một phương pháp điều khiển phản hồi được sử dụng phổ biến trong các hệ thống. Trong đó tín hiệu điều khiển được xác định dựa trên sai lệch giữa giá trị đặt và giá trị đo được của hệ thống. Cách tiếp cận này cho phép hệ thống liên tục điều chỉnh để đạt được trạng thái mong muốn.

       Bộ điều khiển PID bao gồm ba thành phần chính:
        - *Thành phần tỉ lệ (P):* tạo ra tín hiệu điều khiển tỉ lệ với sai số tức thời, giúp hệ thống phản ứng nhanh với sự thay đổi.
        - *Thành phần tích phân (I):* tích lũy sai số theo thời gian, nhằm loại bỏ sai số xác lập và cải thiện độ chính xác lâu dài.
        - *Thành phần đạo hàm (D):* phản ánh tốc độ biến thiên của sai số, từ đó hỗ trợ giảm dao động và cải thiện tính ổn định của hệ thống.

        Biểu thức tổng quát của bộ điều khiển trong miền thời gian được viết như sau:

        $ u(t) = K_p e(t) + K_i integral e(t) dif t + K_d (dif e(t))/(dif t) $

        Trong đó:
        - $e(t)$ là sai lệch giữa giá trị mong muốn và giá trị đo được
        - $K_p$, $K_i$, $K_d$ là các hệ số điều khiển. 
        
        Các tham số này cần được hiệu chỉnh phù hợp để đảm bảo hệ thống đạt được các đặc tính đáp ứng mong muốn như thời gian xác lập ngắn, độ vượt quá nhỏ và sai số xác lập thấp.

        Trong quá trình triển khai thực tế, hiện tượng *integral windup* có thể xảy ra khi tín hiệu điều khiển bị giới hạn bởi các ràng buộc vật lý, trong khi thành phần tích phân vẫn tiếp tục tích lũy sai số, dẫn đến đáp ứng vượt mức khi hệ thống trở lại vùng hoạt động bình thường. Để khắc phục, có thể áp dụng một số kỹ thuật như giới hạn giá trị tích phân (anti-windup clamping), tạm dừng tích lũy khi đầu ra bị bão hòa, hoặc hiệu chỉnh lại thành phần tích phân dựa trên tín hiệu điều khiển thực tế.