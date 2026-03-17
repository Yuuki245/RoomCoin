Globs: lib/core/repositories/**, lib/features/**/repositories/**
# Database Schema (Firebase Firestore)

Cấu trúc NoSQL cho ứng dụng RoomCoin:

## Collections

### 1. `users`
- `uid` (String, Document ID): ID người dùng (từ Firebase Auth).
- `displayName` (String): Tên hiển thị.
- `email` (String): Địa chỉ email.
- `photoURL` (String, nullable): Ảnh đại diện.
- `bankName` (String, nullable): Tên ngân hàng.
- `bankAccountNumber` (String, nullable): Số tài khoản ngân hàng (dùng tạo VietQR).
- `joinedRooms` (Array<String>): Danh sách các ID phòng đã tham gia.
- `createdAt` (Timestamp): Thời gian tạo tài khoản.

### 2. `rooms`
- `id` (String, Document ID): ID phòng (sinh tự động).
- `inviteCode` (String): Mã 6 số để mời thành viên.
- `name` (String): Tên phòng trọ.
- `adminId` (String): UID của Trưởng phòng (người tạo phòng).
- `members` (Array<String>): Danh sách UID các thành viên trong phòng.
- `createdAt` (Timestamp): Thời gian tạo phòng.

### 3. `tags` (Sub-collection trong `rooms/{roomId}/tags` hoặc Global Collection)
*Nên đặt làm Sub-collection trong từng room để user tự định nghĩa, hoặc Global nếu dùng chung (tuân theo requirement hiện tại, ta cho user tự định nghĩa tag).*
- `id` (String, Document ID): ID tag.
- `name` (String): Tên danh mục (VD: Tiền điện, Ăn uống).
- `iconCode` (int/String): Mã icon hiển thị.
- `colorHex` (String): Màu sắc hiển thị chuẩn Hex.
- `roomId` (String): ID của phòng sở hữu tag.

### 4. `expenses`
- `id` (String, Document ID): ID khoản chi.
- `roomId` (String): ID phòng phát sinh khoản chi.
- `amount` (Number): Số tiền chi.
- `paidBy` (String): UID của người đã trả tiền.
- `splitBetween` (Array<String>): Danh sách UID của những người chịu chung khoản chi này (bị chia).
- `tagId` (String): ID của Tag (danh mục).
- `date` (Timestamp): Ngày tháng phát sinh chi tiêu.
- `note` (String, nullable): Ghi chú bổ sung.
- `createdAt` (Timestamp): Thời gian tạo bản ghi.
