# 💰 Đồ Án PRM393: Ứng Dụng Quản Lý Chi Tiêu (Envelope Budgeting)

Chào mừng team đến với dự án cuối kỳ môn Lập trình Mobile (PRM393). Dự án này ứng dụng phương pháp "Túi tiền" để quản lý tài chính cá nhân một cách thông minh và thực tế.

Do chúng ta chỉ có **1 Sprint duy nhất** để chạy nước rút, mọi người VUI LÒNG ĐỌC KỸ các quy tắc dưới đây trước khi gõ dòng code đầu tiên.

---

## 🏗️ 1. Cấu trúc thư mục (Kiến trúc 3 lớp)
Để code không bị rối, project áp dụng kiến trúc tinh gọn với 3 thư mục chính nằm trong `lib/`:

* 📂 `lib/models/`: Đã định nghĩa sẵn 5 cái khuôn dữ liệu (NguoiDung, TuiTien, GiaoDich, MucTieu, SoNo). **Không code giao diện ở đây.**
* 📂 `lib/services/`: Chứa `database_service.dart` (xử lý SQLite) và các logic tính toán nền. Các màn hình chỉ việc gọi hàm từ đây ra xài.
* 📂 `lib/screens/`: Nơi chứa giao diện 10 màn hình. Ai được phân công màn hình nào thì tạo file `.dart` ở trong này nhé.

---

## 🚀 2. Hướng dẫn Setup lần đầu (Dành cho thành viên)
Sau khi clone project từ nhánh `develop` về máy tính, hãy làm theo các bước sau:

1. Mở Terminal (trong VS Code hoặc Android Studio) tại thư mục gốc của project.
2. Chạy lệnh cài đặt các thư viện (Provider, SQLite, fl_chart...):
   ```bash
   flutter pub g

3. Lệnh seed lại data mẫu khi đã có data thật:
   adb shell pm clear com.example.expense_tracker