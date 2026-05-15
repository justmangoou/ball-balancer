#import "constants.typ": HEARTBEAT_TIMER, HEARTBEAT_INTERVAL,  HEARTBEAT_INTERVAL_MS, HEARTBEAT_FREQUENCY, HEARTBEAT_FREQUENCY_KHZ, ACTUATOR_FREQUENCY_KHZ, ACTUATOR_FREQUENCY, ACTUATOR_FREQUENCY_KHZ, MISS_THRESHOLD, PID_OUTPUT_LIMIT, Z_MIN, Z_MAX, XY_SATURATION

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

            Cụ thể, với số lượng lấy mẫu là 5 theo trục $x$: ${x_1, x_2, x_3, x_4, x_5}$, các giá trị này được sắp xếp theo thứ tự tăng dần và phần tử trung vị ($x_3$) sẽ được chọn làm $x_"raw"$. Tương tự với trục $y$ ($y_"raw"$). 

        === Ước lượng lực nhấn (pressure) và kiểm tra hợp lệ
            Ngoài tọa độ $(x,y)$, hệ thống ước lượng thêm một đại lượng áp lực $z$ nhằm loại bỏ các lần chạm không ổn định dựa theo nguyên lý tại @resistive_touch_mechanism. Hai giá trị $z_1, z_2$ được đo từ hai kênh ADC và được sử dụng để xây dựng một chỉ số áp lực theo dạng:

            $ z = x_"raw" dot (z_2 - z_1) / z_1 $

            Trong phạm vi đề tài, đại lượng này không cần biểu diễn chính xác theo đơn vị vật lý, mục đích chính là cung cấp một giải pháp nhằm phân biệt giữa trạng thái chạm thật (khi có lực tác động đủ mạnh và ổn định) và chạm giả (nhiễu, không chạm hoặc chạm nhẹ không ổn định). 

            Trong thiết kế hiện tại, một mẫu đo hợp lệ khi thỏa mãn các điều kiện sau:
            - $z in [#Z_MIN, #Z_MAX]$
            - $x_"raw"$ và $y_"raw"$ < #XY_SATURATION 

        === Chuẩn hoá về phần trăm lệch tâm
            Tọa độ thô $(x_"raw", y_"raw")$ không phản ánh trực tiếp vị trí lệch tâm của quả bóng trên bề mặt phẳng, do đó cần chuyển sang một hệ quy chiếu phù hợp để biểu diễn vị trí của bóng.

            Trong thiết kế này, hệ quy chiếu được chọn là phần trăm lệch tâm so với tâm bàn, với vị trí  trung tâm $(0, 0)$ và giá trị dương/âm tương ứng với lệch theo hai chiều trục.  Tọa độ thô từ thang ADC 12-bit $(0,4096)$ được chuyển theo ngưỡng hiệu chuẩn ($X_"min"$, $X_"max"$, $Y_"min"$, $Y_"max"$) sang phần trăm lệch tâm:

            $ x_"pct", y_"pct" in [-100, 100] $

            Các ngưỡng $X_"min"$, $X_"max"$, $Y_"min"$, $Y_"max"$ được xác định thông qua quá trình hiệu chuẩn thực nghiệm. Cụ thể, hệ thống ghi nhận giá trị ADC khi điểm chạm được đưa tới các vị trí biên của bề mặt cảm ứng tại 4 góc, từ đó xác định giá trị nhỏ nhất và lớn nhất theo từng trục. Các giá trị này sau đó được sử dụng làm mốc để chuẩn hóa tọa độ.

        === Mất tín hiệu
            Nếu tín hiệu từ cảm biến không hợp lệ (ví dụ: không phát hiện tiếp xúc, tiếp xúc không ổn định hoặc nhiễu vượt ngưỡng) vượt quá ngưỡng #MISS_THRESHOLD chu kỳ (tương đương #{HEARTBEAT_INTERVAL_MS * MISS_THRESHOLD} ms), hệ thống sẽ xác nhận mất tín hiệu, chuyển sang trạng thái “không tìm thấy” và đặt các giá trị phản hồi về $0$ nhằm tránh sử dụng dữ liệu không đáng tin cậy trong điều khiển.

    == Thuật toán điều khiển PID
        Sau khi xác định được vị trí chuẩn hóa của quả bóng $(x_"pct", y_"pct")$, hệ thống dùng hai bộ điều khiển PID độc lập cho hai trục $x$ và $y$ để tính giá trị điều khiển tương ứng với độ nghiêng của mặt phẳng. Nguyên lý tổng quát của thuật toán được trình bày trong @pid_control_algorithm.

        Thuật toán được thực thi trong cùng một hàm ngắt #HEARTBEAT_TIMER với chu kỳ #HEARTBEAT_INTERVAL, do đó mỗi bước lấy mẫu có $Delta t = 1 m s$.

        Trong phạm vi của báo cáo, điểm đặt (setpoint) của thuật toán PID được chọn là $0$ (tương ứng với tâm của mặt phẳng).

        === PID rời rạc theo chu kỳ
            Với mỗi trục, sai số tại thời điểm rời rạc $k$ được xác định:
            $ e[k] = r[k] - y[k] $

            Trong đó:
            - $r[k]$ là giá trị đặt
            - $y[k]$ là giá trị đo được chuẩn hoá.

            Thành phần tích phân được tính theo quy tắc hình thang (Trapezoidal rule):
            $ I[k] = I[k-1] + (e[k] + e[k-1])/2 dot Delta t $
            
            Để tránh *integral windup*, $I[k]$ được giới hạn trong một khoảng phụ thuộc vào hệ số $K_i$:
            $ I[k] in [-I_"max"/K_i, I_"max"/K_i] $

            Trong đó $I_"max"$ là giá trị giới hạn tích phân được xác định dựa trên đặc tính của hệ thống và yêu cầu đáp ứng.

            Thành phần vi phân được tính xấp xỉ qua sai phân và áp dụng bộ lọc thông thấp bậc nhất nhằm giảm nhiễu:
            $ D[k] = 0.1 dot (e[k] - e[k-1]) dif t + 0.9 dot D[k-1] $

            Tổng hợp lại, tín hiệu điều khiển được xác định bởi:
            $ u[k] = K_p dot e[k] + K_i dot I[k] + K_d dot D[k] $

        === Giới hạn đầu ra và chuyển sang lệnh nghiêng
            Tín hiệu điều khiển của mỗi trục được giới hạn trong một khoảng xác định nhằm tránh yêu cầu góc nghiêng vượt quá khả năng cơ khí và đảm bảo tính ổn định của hệ thống. Các giá trị điều khiển này được diễn giải như độ dốc của mặt phẳng theo hai trục $x$ và $y$.
            
            Theo thiết kế này, các giá trị $u_x$ và $u_y$ được ràng buộc trong khoảng $[-#PID_OUTPUT_LIMIT, #PID_OUTPUT_LIMIT]$.

    == Tính góc nghiêng thông qua động học ngược
       Tín hiệu điều khiển từ bộ PID $(u_x, u_y)$ được sử dụng để xác định góc nghiêng mong muốn của mặt phẳng, bao gồm độ nghiêng và độ cao tham chiếu $h_z$. Nhiệm vụ của khối động học nghịch là ánh xạ từ tư thế này sang các góc quay (hoặc vị trí tương đương) của từng cơ cấu chấp hành, sao cho mặt phẳng đạt được trạng thái mong muốn.

        === Biểu diễn độ nghiêng bằng vector pháp tuyến
            Độ nghiêng của mặt phẳng được biểu diễn thông qua vector pháp tuyến chưa chuẩn hoá:

            $ n = (n_x, n_y, 1) $

            trong đó $(n_x, n_y)$ được suy ra trực tiếp từ tín hiệu điều khiển $(u_x, u_y)$ và giả thiết $n_z > 0$. Vector này sau đó được chuẩn hoá:

            $ accent(n, hat) = n /(||n||) $

            Cách biểu diễn này phù hợp trong miền góc nghiêng nhỏ, khi $(n_x, n_y)$ có thể được xem như xấp xỉ độ dốc (gradient) của mặt phẳng.

        === Tách bài toán theo từng chân
            Hệ thống gồm ba cơ cấu chấp hành được bố trí lệch nhau $120 degree$. Để tính toán độc lập cho từng chân, vector $(n_x, n_y)$ được biến đổi sang hệ trục cục bộ của từng cơ cấu thông qua phép quay phẳng:

            $ r_x = n_x cos alpha - n_y sin alpha $
            $ r_y = n_x sin alpha + n_y cos alpha $

            trong đó $alpha$ là góc định hướng của từng chân.

            Từ các thành phần này, vị trí tương đối của khớp cầu (ví dụ các tọa độ $"joint_y"$, $"joint_z"$) được xác định dựa trên mô hình hình học của cơ cấu.

        === Tính góc tay đòn
            Từ các tọa độ hình học $("joint_y", "joint_z")$, độ dài tương đương được xác định:

            $ "mag" = sqrt("joint"_y^2 + "joint"_z^2) $

            Để đảm bảo ổn định số, trường hợp $"mag"$ tiến gần về $0$ được loại bỏ nhằm tránh phép chia không xác định.

            Dựa trên các tham số hình học đã định nghĩa trước, các tỉ số trung gian được xác định:
            
            $ "ratio"_1 = "joint"_y / "mag", " " "ratio"_2 = ("mag"^2 + (L_a^2 - L_r^2))/(2L_a dot "mag") $

            trong đó:
                - $L_a$ là chiều dài tay đòn (ARM_LENGTH)
                - $L_r$ là chiều dài thanh nối (ROD_LENGTH)
            Các tỉ số này được ràng buộc trong miền $[-1, 1]$ để đảm bảo tính hợp lệ của hàm lượng giác ngược. Từ đó, góc quay của tay đòn sau đó được xác định:

            $ theta degree = arccos("ratio"_1) + arccos("ratio"_2) $
                    
    == Cập nhật toạ độ điều khiển cho cơ cấu chấp hành
        Từ các giá trị góc $theta$ tính được từ khối động học nghịch, hệ thống xác định vị trí mục tiêu mới cho từng động cơ bước:

        $ p_"target" = theta_"origin" - theta $

        Để đảm bảo cơ cấu chấp hành đạt vị trí mục tiêu trong một chu kỳ điều khiển, vận tốc được tính dựa trên khoảng cách giữa vị trí hiện tại và vị trí mục tiêu:

        $ v = (|p_"target" - p_"current"|)/N $

        trong đó:
        - $p_"current"$ là vị trí hiện tại của động cơ,
        - $N$ là số chu kỳ tạo xung của động cơ bước trong một chu kỳ điều khiển chính.

        Trong thiết kế này, bộ điều khiển chính hoạt động ở tần số #HEARTBEAT_FREQUENCY, trong khi bộ tạo xung cho cơ cấu chấp hành hoạt động ở tần số #ACTUATOR_FREQUENCY, tương ứng với:

        $ N = #ACTUATOR_FREQUENCY / #HEARTBEAT_FREQUENCY = #{ACTUATOR_FREQUENCY_KHZ / HEARTBEAT_FREQUENCY_KHZ} $
        
        Các giá trị vị trí mục tiêu và vận tốc sau đó được cập nhật vào bộ điều khiển động cơ bước để thực hiện nội suy chuyển động liên tục giữa các chu kỳ điều khiển.

    == Điều khiển cơ cấu chấp hành
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