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

## Phase 2: Enhanced Core & Security
- [ ] Audit Log: ghi lịch sử Thêm/Sửa/Xóa vào Firestore `logs`.
- [ ] Settlement Logic: tính nợ chéo và chốt nợ phải thanh toán hết một lần.
- [ ] VietQR Integration: tạo mã QR thanh toán từ kết quả settlement.
- [ ] Rời phòng: Admin duyệt và chỉ cho rời khi công nợ bằng 0.
- [ ] Quản lý profile ngân hàng cá nhân để phục vụ VietQR.

## Phase 3: Fast Access & Room Experience
- [ ] QR Join Room: tạo và quét mã QR để vào phòng nhanh.
- [ ] Tối ưu luồng vào phòng: validate local trước, giảm số lần gọi Firestore.
- [ ] Tạo màn hình thông tin phòng với mã mời, QR, danh sách thành viên và quyền admin.

## Phase 4: Automation & Intelligence
- [ ] Recurring Expenses: thiết lập khoản chi định kỳ hàng tháng.
- [ ] Cơ chế materialize khoản chi định kỳ an toàn, không tạo trùng dữ liệu.
- [ ] AI Assistant: chatbot Gemini chỉ phản hồi bằng văn bản dựa trên dữ liệu Firestore.
- [ ] Xây lớp tổng hợp dữ liệu trung gian cho AI để không query raw data từ UI.
- [ ] OCR hóa đơn bằng Gemini API: chụp ảnh, trích xuất số tiền/ngày, cho người dùng xác nhận trước khi lưu.

## Phase 5: Analytics & Export
- [ ] Pie Chart Analytics: thống kê chi tiêu theo Tag với dữ liệu aggregate/cache `O(1)`.
- [ ] Member Analytics: thống kê chi tiêu theo thành viên.
- [ ] Export Data: xuất báo cáo tháng ra CSV.
- [ ] Mở rộng Export Data ra Excel nếu cần.
- [ ] Tối ưu biểu đồ và export flow để không block UI thread.

## Phase 6: Final Polish for Redmi Note 13
- [ ] Kiểm thử thực tế trên Redmi Note 13 ở 60Hz/120Hz.
- [ ] Đo hiệu năng khi dữ liệu lớn: startup time, scroll smoothness, frame drops.
- [ ] Giảm shader jank, tránh animation/layout nặng.
- [ ] Hoàn thiện error handling toàn app.
- [ ] Rà soát security rules và kiến trúc Firestore cho các collection mới.

## Technical Guardrails
- [ ] Tuân thủ tuyệt đối `.cursorrules`: Feature-First, Repository Pattern, GetX clean architecture.
- [ ] UI và Controller không gọi trực tiếp Firestore.
- [ ] Mọi truy xuất lặp trong `build` phải được thay bằng cache/lookup `O(1)`.
- [ ] Các tác vụ nặng phải xử lý ngoài `build`, ưu tiên precompute khi dữ liệu thay đổi.
- [ ] Toàn bộ giao diện dùng Material 3, tiếng Việt 100%, có Haptic Feedback và Empty State khi cần.
