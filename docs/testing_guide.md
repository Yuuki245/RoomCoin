# RoomCoin - Real Device Testing Guide (Redmi Note 13) 📱

## I. Connectivity & Offline Persistence (Phase 1)
- [ ] **Test 1: Offline Access**
  - *Cách làm:* Mở app -> Bật chế độ máy bay -> Kill app hoàn toàn -> Mở lại app.
  - *Kỳ vọng:* Dữ liệu chi tiêu tháng hiện tại vẫn hiển thị (đọc từ cache).
- [ ] **Test 2: Reconnect Stream**
  - *Cách làm:* Đang ở màn hình Lịch -> Tắt mạng -> Banner "Đang offline" hiện lên -> Bật lại mạng.
  - *Kỳ vọng:* Banner biến mất, stream dữ liệu tự động resume mà không cần load lại trang.

## II. Performance & 120Hz Smoothness (Phase 1)
- [ ] **Test 3: Scroll Jank Test**
  - *Cách làm:* Dùng 'Flutter Performance Overlay'. Cuộn nhanh danh sách chi tiêu ở những tháng có nhiều dữ liệu (>20 bản ghi).
  - *Kỳ vọng:* Biểu đồ raster/ui thread không vượt quá vạch đỏ, giữ vững 120Hz trên Redmi Note 13.
- [ ] **Test 4: Month Switching**
  - *Cách làm:* Vuốt ngang để đổi tháng liên tục trên TableCalendar.
  - *Kỳ vọng:* Chuyển cảnh mượt, Shimmer hiện lên ngay lập tức cho tháng mới và biến mất khi data đổ về.

## III. Data Logic & Month Streams (Phase 1)
- [ ] **Test 5: Month-Scoped Loading**
  - *Cách làm:* Soi Log Console khi chuyển từ tháng 3 sang tháng 4.
  - *Kỳ vọng:* Thấy Log đóng stream cũ và mở stream mới đúng `monthKey`. Cache O(1) chỉ giữ dữ liệu các tháng đang active.

## IV. Audit Log (Phase 2 - Upcoming)
- [ ] **Test 6: Operation Logging**
  - *Cách làm:* Thêm/Sửa/Xóa một khoản chi.
  - *Kỳ vọng:* Kiểm tra collection `logs` trên Firestore có bản ghi tương ứng với `oldData` và `newData`.