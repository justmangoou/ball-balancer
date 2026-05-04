#import "constants.typ": HEARTBEAT_TIMER, HEARTBEAT_INTERVAL

= Thuật toán điều khiển
    == Xử lý tín hiệu cảm biến của màn cảm ứng điện trở
        Mục tiêu của khối cảm biến là chuyển đổi tín hiệu tương tự từ màn cảm ứng điện trở thành tọa độ (x,y) ổn định, có thể sử dụng trực tiếp làm tín hiệu phản hồi. Quá trình đọc cảm biến được thực hiện định kỳ qua hàm ngắt #HEARTBEAT_TIMER với chu kỳ #HEARTBEAT_INTERVAL.

        === Quy trình đọc $x$, $y$
            Dựa theo nguyên lý hoạt động của màn cảm ứng điện trở tại @resistive_touch_mechanism, việc xác định tọa độ được thực hiện qua hai bước:

            - *Đo $x$*: Thiết lập chân $X^+$ ở mức cao và chân $X^-$ ở mức thấp, cấu hình chân $Y^+$ và $Y^-$ ở chế độ analog, sau đó đọc điện áp tại kênh tương ứng $Y^+$ thông qua ADC.
            - *Đo $y$*: Tương tự, thiết lập 2 chân $Y^+$, $Y^-$ và đọc điện áp tại chân $X^+$.

            Sau khi thiết lập, hệ thống đợi $20 mu s$ trước khi lấy mẫu để đảm bảo điện áp trên màn cảm ứng đạt trạng thái ổn định.

        === Lọc nhiễu bằng giá trị trung vị
            Hệ thống lấy mẫu nhiều lần cho mỗi trục và sử dụng giá trị trung vị để làm kết quả cuối cùng. Phương pháp này giúp giảm ảnh hưởng của các mẫu nhiễu hoặc do sai số ngẫu nhiên.

            Cụ thể, với số lượng lấy mẫu là 5 theo trục $x$: ${x_1, x_2, x_3, x_4, x_5}$, các giá trị này được sắp xếp theo thứ tự tăng dần và phần tử trung vị ($x_3$) sẽ được chọn làm $x_"raw"$. Tương tự với trục $y$. 

        === Ước lượng lực nhấn (pressure) và kiểm tra hợp lệ
            Ngoài tọa độ $(x,y)$, hệ thống ước lượng thêm một đại lượng áp lực $z$ nhằm loại bỏ các lần chạm không ổn định. Hai giá trị $z_1, z_2$ được đo từ hai kênh ADC và được sử dụng để xây dựng một chỉ số áp lực theo dạng:

            $ "pressure" = x_"raw" dot (z_2 - z_1) / z_1 $

            Trong phạm vi đề tài, đại lượng này không cần biểu diễn chính xác theo đơn vị vật lý, mục đích chính là cung cấp một giải pháp nhằm phân biệt giữa trạng thái chạm thật (khi có lực tác động đủ mạnh và ổn định) và chạm giả (nhiễu, không chạm hoặc chạm nhẹ không ổn định). 

            // TODO: improve this
            Một mẫu đo hợp lệ khi thỏa mãn các điều kiện:
            - $z in [z_"min", z_"max"] $ hay trong cấu hình hệ thống là $z_"min" = 10, z_"max" = 4000$
            - $x_"raw"$ và $y_"raw"$ < $"XY"_"saturation"$
        === Chuẩn hoá về phần trăm lệch tâm
            Tọa độ thô $(x_"raw", y_"raw")$ không phản ánh trực tiếp vị trí lệch tâm của quả bóng trên bề mặt phẳng, do đó cần chuyển sang một hệ quy chiếu phù hợp để biểu diễn vị trí của bóng.

            Trong thiết kế này, hệ quy chiếu được chọn là phần trăm lệch tâm so với tâm bàn, với vị trí  trung tâm $(0, 0)$ và giá trị dương/âm tương ứng với lệch theo hai chiều trục.  Tọa độ thô từ thang ADC 12-bit $(0,4096)$ được chuyển theo ngưỡng hiệu chuẩn ($X_"min"$, $X_"max"$, $Y_"min"$, $Y_"max"$) sang phần trăm lệch tâm:

            $ x_"pct", y_"pct" in [-100, 100] $

            Các ngưỡng $X_"min"$, $X_"max"$, $Y_"min"$, $Y_"max"$ được xác định thông qua quá trình hiệu chuẩn thực nghiệm. Cụ thể, hệ thống ghi nhận giá trị ADC khi điểm chạm được đưa tới các vị trí biên của bề mặt cảm ứng tại 4 góc, từ đó xác định giá trị nhỏ nhất và lớn nhất theo từng trục. Các giá trị này sau đó được sử dụng làm mốc để chuẩn hóa tọa độ.

        === Mất tín hiệu
            // TODO: fix here also
            Nếu đọc cảm biến thất bại liên tiếp (MISS\_THRESHOLD = 20 chu kỳ, tương đương $~ 20 m s$), hệ thống đưa lệch tâm về $0$ và reset bộ điều khiển để tránh tích phân bị “trôi” khi không còn phản hồi.
    == Thuật toán điều khiển PID
        Sau khi có $(x_"pct", y_"pct")$, hệ thống dùng hai bộ điều khiển PID độc lập cho hai trục $x$ và $y$ để tạo lệnh nghiêng bàn. Giá trị đặt (setpoint) là $0$ — nghĩa là đưa quả bóng về tâm.

        === PID rời rạc theo chu kỳ
            Với mỗi trục, sai số:
            $ e(k) = r(k) - y(k) $

            Trong đó $r(k)=0$ và $y(k)$ là vị trí đo được theo phần trăm.

            Thành phần tích phân được tính theo quy tắc hình thang:
            $ I(k) = I(k-1) + (e(k) + e(k-1)) \cdot 0.5 \cdot dif t $

            Để chống *integral windup*, $I(k)$ được giới hạn trong một khoảng nhất định.

            Thành phần vi phân dùng sai phân và được lọc thông thấp đơn giản để giảm nhiễu:
            $ D_"raw"(k) = (e(k) - e(k-1))/dif t $
            $ D(k) = 0.1\,D_"raw"(k) + 0.9\,D(k-1) $

            Tín hiệu điều khiển:
            $ u(k) = K_p e(k) + K_i I(k) + K_d D(k) $

        === Giới hạn đầu ra và chuyển sang lệnh nghiêng
            Đầu ra PID mỗi trục được giới hạn (clamp) để không yêu cầu góc nghiêng quá lớn (tránh mất ổn định và vượt giới hạn cơ khí). Trong firmware, $u_x, u_y$ bị giới hạn trong khoảng $[-0.25, 0.25]$.

            Hai giá trị này được hiểu như độ dốc của mặt phẳng theo hai trục, và được đưa vào khối động học nghịch để tính góc/độ quay của từng động cơ.

    == Tính góc nghiêng thông qua động học ngược
        // Nhiệm vụ của khối động học nghịch là: từ “tư thế bàn mong muốn” (độ cao tâm $h_z$ và độ nghiêng) suy ra góc tay đòn (hoặc vị trí tương đương) mà mỗi chân/động cơ phải đạt.

        // === Biểu diễn độ nghiêng bằng vector pháp tuyến
        //     Trong firmware, độ nghiêng được biểu diễn qua hai tham số $(n_x, n_y)$ và giả thiết $n_z > 0$. Vector pháp tuyến (chưa chuẩn hoá) được lấy là:
        //     $ n = (n_x, n_y, 1) $
        //     Sau đó chuẩn hoá:
        //     $ \hat{n} = n / ||n|| $

        //     Cách biểu diễn này phù hợp khi góc nghiêng nhỏ, vì $(n_x, n_y)$ có thể xem như “gradient” của mặt phẳng.

        // === Tách bài toán theo từng chân
        //     Bàn có 3 chân đặt lệch nhau $120^{\circ}$. Để tính riêng cho từng chân, hệ thống quay $(n_x, n_y)$ về hệ trục cục bộ của chân bằng ma trận quay 2D (dùng sẵn $\cos(\alpha)$, $\sin(\alpha)$ của từng chân):
        //     $ r_x = n_x \cos\alpha - n_y \sin\alpha $
        //     $ r_y = n_x \sin\alpha + n_y \cos\alpha $

        //     Từ đó suy ra vị trí khớp cầu tương ứng của chân (ví dụ các thành phần $joint_y$, $joint_z$) theo mô hình hình học của cơ cấu.

        // === Tính góc tay đòn
        //     Sau khi có độ dài/quan hệ tam giác giữa tay đòn và thanh nối, góc được suy ra bằng hàm $\arccos$ (có giới hạn miền giá trị để tránh lỗi số):
        //     $ \theta = \arccos(\cdot) + \arccos(\cdot) $

        //     Trong code, hàm tính toán trả về $\theta$ theo độ và có các bước *clamp* tỉ số vào $[-1,1]$ để đảm bảo an toàn số học.

        // Lưu ý: các tham số hình học (bán kính đế, bán kính bàn, chiều dài tay đòn, chiều dài thanh nối,\dots) cần được định nghĩa đúng theo thiết kế cơ khí để kết quả động học phù hợp thực tế.

    == Điều khiển động cơ bước thông qua driver
        // Sau khi tính được $\theta$ cho từng chân, hệ thống chuyển đổi sang vị trí mục tiêu của động cơ và phát xung điều khiển qua driver. Toàn bộ phần phát xung được tách khỏi vòng PID để đảm bảo thời gian thực.

        // === Hai tầng thời gian: Heartbeat và Muscle
        //     Firmware dùng 2 timer chính:
        //     - *TIM5 (Heartbeat, $1\,kHz$)*: đọc cảm biến, tính PID, cập nhật mục tiêu cho từng động cơ.
        //     - *TIM9 (Muscle, tần số cao)*: phát xung STEP/DIR theo mục tiêu hiện tại.

        // Cách tách này giúp phần tính toán (ADC, PID, động học) không làm “giật” xung điều khiển động cơ.

        // === Lập kế hoạch bước và vận tốc
        //     Với mỗi chân, đặt vị trí mục tiêu mới (new\_target) dựa trên góc gốc ORIGIN\_ANGLE và góc cần đạt $\theta$. Từ sai lệch vị trí:
        //     $ dist = |target - current| $

        //     vận tốc được chọn để hoàn thành trong 1 chu kỳ heartbeat. Ví dụ nếu TIM9 chạy $40\,kHz$ thì trong $1\,ms$ có 40 “tick”, và:
        //     $ v = dist / 40 $

        //     Trong driver, vận tốc được giới hạn để tránh phát xung quá dày.

        // === Phát xung STEP/DIR bằng bộ tích luỹ
        //     Trong mỗi tick TIM9, driver dùng cơ chế “bucket/accumulator” (tương tự Bresenham):
        //     - Cộng $v$ vào biến tích luỹ.
        //     - Khi tích luỹ $\ge 1$, phát đúng *1 xung STEP* và tăng/giảm current theo hướng DIR.

        //     Việc đặt DIR và phát STEP sử dụng thanh ghi BSRR để set/reset chân GPIO một cách nguyên tử, đồng thời đảm bảo độ rộng xung đủ lớn bằng một vòng lặp NOP ngắn.

        // Nhờ cách phát xung này, hệ thống có thể thay đổi mục tiêu mỗi $1\,ms$ nhưng vẫn giữ xung STEP đều và ổn định ở tần số cao.