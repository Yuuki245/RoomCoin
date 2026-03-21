# RoomCoin Project Roadmap

## Phase 0: Foundation (Completed)
- [x] Setup Flutter Project & Firebase.
- [x] Google Authentication.
- [x] Join Room via 6-digit code.
- [x] Basic Expense CRUD & Calendar View.

## Phase 1: Core Stability & Performance (Highest Priority)
- [x] Refactor Tag module theo Repository Pattern, dùng Firestore `rooms/{roomId}/tags`.
- [x] Chuẩn hóa Expense data layer: full add/update/delete flow, cache lookup `O(1)` cho tag/member/day/month.
- [x] Hoàn thiện Shimmer/Empty/Error states nhất quán cho các màn hình chính.
- [x] Tối ưu GetX rebuild scope, loại bỏ side-effect trong `build`, giữ scroll/list mượt trên Redmi Note 13.
- [x] Bổ sung Firestore indexes cần thiết cho `expenses`, `rooms`, `tags`.
- [x] Bật và kiểm thử offline persistence + xử lý reconnect state.
- [x] Tối ưu danh sách chi tiêu dài: limit theo tháng, lazy rendering, tránh jank UI thread.

## Phase 2: Rời phòng & Đồng bộ (Leave Room & Sync) - **HOÀN THIỆN 100%**
- [x] Luồng Member xin rời phòng (Yêu cầu & Chờ duyệt).
- [x] Luồng Admin rời phòng & Chuyển quyền (WriteBatch).
- [x] Xử lý Data Desync (Filter thành viên cũ, Validation sửa hóa đơn).

## Phase 3: Hệ thống Báo cáo & Thống kê Đa tầng (Advanced Reporting)
- [ ] Mở rộng Data Layer: Nghiên cứu áp dụng Firestore Aggregation `sum()` kết hợp index để query tổng tiền O(1) theo 5 mốc thời gian (Ngày/Tháng/Quý/Năm/All).
- [ ] Cấu trúc Query Report: Viết custom query `sum(amount)` nhóm theo `tagId` (Group Report) và theo `uid` (Personal Report).
- [ ] UI Báo cáo Tổng (Group): Hiển thị tổng chi tiêu cả phòng, có biểu đồ tỷ trọng (Pie Chart) theo Danh mục. Thống kê số tiền từng người đã chi.
- [ ] UI Báo cáo Cá nhân (Personal): Lấy tham số `uid`, hiển thị tổng tiền user đã chi và biểu đồ tỷ trọng bằng tiền của riêng user.
- [ ] Export Data: Trích xuất báo cáo ra định dạng CSV/Excel.

## Phase 4: Fast Access & Room Experience
- [ ] QR Join Room: tạo và quét mã QR để vào phòng nhanh.
- [ ] Tối ưu luồng vào phòng: validate local trước, giảm số lần gọi Firestore.
- [ ] Tạo màn hình thông tin phòng với mã mời, QR, danh sách thành viên và quyền admin.

## Phase 5: Automation & Intelligence
- [ ] Recurring Expenses: thiết lập khoản chi định kỳ hàng tháng.
- [ ] Cơ chế materialize khoản chi định kỳ an toàn, không tạo trùng dữ liệu.
- [ ] AI Assistant: chatbot Gemini chỉ phản hồi bằng văn bản dựa trên dữ liệu Firestore.
- [ ] Xây lớp tổng hợp dữ liệu trung gian cho AI để không query raw data từ UI.
- [ ] OCR hóa đơn bằng Gemini API: chụp ảnh, trích xuất số tiền/ngày, cho người dùng xác nhận trước khi lưu.

## Phase 6: Final Polish for Redmi Note 13
- [ ] Kiểm thử thực tế trên Redmi Note 13 ở 60Hz/120Hz.
- [ ] Đo hiệu năng biểu đồ báo cáo khi thao tác vuốt/đổi ngày: startup time, scroll smoothness, frame drops.
- [ ] Giảm shader jank, tránh animation/layout nặng.
- [ ] Hoàn thiện error handling toàn app.
- [ ] Rà soát security rules và kiến trúc Firestore.

## Technical Guardrails
- [ ] Tuân thủ tuyệt đối `.cursorrules`: Feature-First, Repository Pattern, GetX clean architecture.
- [ ] UI và Controller không gọi trực tiếp Firestore.
- [ ] Mọi truy xuất lặp trong `build` phải được thay bằng cache/lookup `O(1)`.
- [ ] Các tác vụ nặng phải xử lý ngoài `build`, ưu tiên precompute khi dữ liệu thay đổi.
- [ ] Toàn bộ giao diện dùng Material 3, tiếng Việt 100%, có Haptic Feedback và Empty State khi cần.
