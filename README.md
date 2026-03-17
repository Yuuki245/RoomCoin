RoomCoin - Smart Expense Manager for Roommates
RoomCoin là ứng dụng di động giúp sinh viên và người thuê trọ quản lý chi tiêu chung một cách minh bạch, công bằng và tức thì. Dự án được phát triển bởi một sinh viên IT năm 4 với mục tiêu tối ưu hóa việc quản lý tài chính cá nhân và nhóm.

✨ Tính năng chính (Key Features)
🔐 Đăng nhập thông minh: Hỗ trợ đăng nhập nhanh qua Google Account.

🏠 Quản lý phòng trọ: Tạo hoặc tham gia phòng mới thông qua mã mời 6 chữ số ngẫu nhiên.

💸 Ghi chép chi tiêu: Thêm khoản chi nhanh chóng, hỗ trợ phân loại theo Danh mục (Tags) và ghi chú chi tiết.


🔄 Đồng bộ Real-time: Sử dụng Firestore Streams để cập nhật dữ liệu tức thì giữa tất cả các thành viên trong phòng mà không cần tải lại app.

📅 Lịch chi tiêu (Calendar View): Theo dõi biến động dòng tiền theo ngày và tháng một cách trực quan thông qua giao diện lịch tích hợp.

🎨 Giao diện hiện đại: Thiết kế theo chuẩn Material 3, hỗ trợ hoàn toàn tiếng Việt và tối ưu hóa cho các dòng máy Android (đặc biệt là Xiaomi/HyperOS).

🛠️ Công nghệ & Kiến trúc (Tech Stack & Architecture)
Dự án tuân thủ nghiêm ngặt các tiêu chuẩn lập trình sạch (Clean Code) để dễ dàng bảo trì và mở rộng: 

Framework: Flutter (Sound Null Safety).


State Management: GetX (Reactive Programming) giúp quản lý trạng thái app mượt mà.


Backend: Firebase (Authentication & Cloud Firestore).


Architecture: Feature-First Architecture kết hợp với Repository Pattern để tách biệt logic nghiệp vụ và dữ liệu.

UX/UI: Tích hợp Shimmer Loading và Haptic Feedback để tăng cường trải nghiệm người dùng.

🚀 Hướng dẫn cài đặt (Setup)
Clone dự án:

Bash
git clone https://github.com/your-username/RoomCoin.git
Cài đặt dependencies:

Bash
flutter pub get
Cấu hình Firebase:

Thêm file google-services.json vào thư mục android/app/.

Đảm bảo đã bật Google Sign-in và Firestore trong Firebase Console.

Chạy ứng dụng:

Bash
flutter run
