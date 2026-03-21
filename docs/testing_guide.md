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

## IV. Audit Log (Phase 2 - Implemented ✅)
- [x] **Test 6: Operation Logging**
  - **Test 6a: CREATE Log**
    - *Cách làm:* Thêm một khoản chi mới (VD: 500.000đ tiền ăn).
    - *Kỳ vọng:* Collection `logs` trên Firestore có bản ghi mới với: `action: "CREATE"`, `uid` khớp người tạo, `expenseId` khớp khoản chi vừa tạo, `newData` chứa đầy đủ thông tin (amount, paidBy, tagId, date...), `oldData` = null, `timestamp` gần thời điểm hiện tại.
  - **Test 6b: UPDATE Log**
    - *Cách làm:* Sửa khoản chi vừa tạo (VD: đổi số tiền từ 500.000đ thành 600.000đ).
    - *Kỳ vọng:* Collection `logs` có bản ghi mới: `action: "UPDATE"`, `oldData.amount = 500000`, `newData.amount = 600000`, các field khác giữ nguyên.
  - **Test 6c: DELETE Log**
    - *Cách làm:* Xóa khoản chi vừa sửa.
    - *Kỳ vọng:* Collection `logs` có bản ghi mới: `action: "DELETE"`, `oldData` chứa data đầy đủ của khoản chi, `newData` = null.
  - **Test 6d: Fire-and-Forget (Performance)**
    - *Cách làm:* Thêm khoản chi, quan sát tốc độ phản hồi UI.
    - *Kỳ vọng:* UI không bị chậm hoặc đợi thêm khi ghi log. Nếu tắt mạng ngay sau khi thêm, khoản chi vẫn lưu thành công (log có thể mất, không ảnh hưởng flow chính).
  - **Test 6e: UI Timeline Display**
    - *Cách làm:* Mở màn hình Chi tiết khoản chi (`ExpenseDetailScreen`) của khoản chi vừa thao tác Thêm/Sửa. Cuộn xuống dưới cùng xem Widget 'Lịch sử hoạt động'.
    - *Kỳ vọng:* Hiển thị Shimmer loading ngắn, sau đó ListView hiển thị timeline log với icon màu (xanh/đỏ/xanh lơ) đúng mốc thời gian. Các câu mô tả parse đúng (Ví dụ: 'Đã cập nhật số tiền từ 100,000đ thành 200,000đ'). Không làm jank khi mở màn hình.
  - **Test 6f: Edit Expense Form (120Hz)**
    - *Cách làm:* Bấm vào nút Edit trên AppBar của chi tiết khoản chi. Màn hình AddExpenseScreen sẽ mở lên ở chế độ Edit.
    - *Kỳ vọng:* Màn hình hiển thị "Sửa khoản chi", số tiền và note tự động điền sẵn không có độ trễ UI ngang (giữ vững 120Hz). Submit thành công gọi updateExpense gọi AuditAction UPDATE chứ không bị đúp bản ghi.

## V. Phase 2 Validation (Persistence & Connectivity) - Redmi Note 13
- [ ] **Test 7: Connectivity Banner on Offline**
  - *Cách làm:* Mất mạng, observe banner nhẹ ở top hoặc toast nhỏ khi Disconnect.
  - *Kỳ vọng:* Banner hiển thị ngay khi mất mạng và ẩn khi kết nối được.
- [ ] **Test 8: Offline Persistence Valid**
  - *Cách làm:* Bật chế độ offline cho Firestore và thử reload dữ liệu sau khi kết nối lại.
  - *Kỳ vọng:* Dữ liệu tháng hiện tại vẫn hiển thị từ cache, sau khi kết nối lại, dữ liệu đồng bộ đầy đủ.
- [ ] **Test 9: Month Load Lazy (118Hz friendly)**
  - *Cách làm:* Thay đổi tháng trên calendar; kiểm tra shimmer hiển thị ngay tháng mới và load data sau.
  - *Kỳ vọng:* Không có jank, ListView render nhanh và dữ liệu tháng được lấy từ stream theo monthKey.
