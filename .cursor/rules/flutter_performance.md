# PERFORMANCE & ARCHITECTURE RULES

- **O(1) Access over O(N) Search**: Tuyệt đối không sử dụng các hàm duyệt mảng (`where`, `firstWhere`, `any`) bên trong hàm `build` hoặc các getter được gọi liên tục bởi UI. Ưu tiên convert dữ liệu sang `Map` hoặc `Set` để truy xuất nhanh.
- **Granular Obx**: Sử dụng `Obx` ở cấp độ nhỏ nhất có thể (Widget cấp thấp). Tránh bao bọc các Widget lớn hoặc phức tạp (như List, Calendar) trong một `Obx` duy nhất nếu không cần thiết.
- **Efficient GetX Controllers**: 
  - Thực hiện tính toán logic nặng trong `onInit` hoặc khi nhận dữ liệu mới từ Stream. 
  - Lưu kết quả vào các biến reactive thay vì tính toán lại trong hàm getter.
  - Luôn dispose `Worker` và `StreamSubscription` trong `onClose` để tránh Memory Leak.
- **UI Responsiveness**: Đảm bảo mọi tác vụ nặng đều chạy bất đồng bộ và không chặn UI Thread. Sử dụng `compute` nếu cần xử lý lượng dữ liệu cực lớn.
- **Naming & Logic**: Tuân thủ Repository Pattern. Controller chỉ quản lý trạng thái, Repository quản lý dữ liệu.