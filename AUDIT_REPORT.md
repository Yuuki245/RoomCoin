# RoomCoin Audit Report

## Muc tieu

- Kiem toan GetX state, async flow, UI/UX va kien truc Repository Pattern.
- Uu tien cac loi gay mat dong bo du lieu, submit trung va vi pham phan tang.

## Loi da uu tien sua

| Muc | Muc do | Trang thai | Ghi chu |
| --- | --- | --- | --- |
| Delete expense chi xoa local state | Nghiem trong | Da sua | Xoa qua `ExpenseRepository.deleteExpense()` va dong bo bang stream Firestore |
| Controller goi Firestore truc tiep | Canh bao | Da sua | Truy van member name da chuyen sang `ExpenseRepository.getMemberOptions()` |
| Nut luu khong lang nghe `isSaving` | Canh bao | Da sua | Nut luu duoc boc `Obx`, disable khi dang luu |
| Race condition khi doi `roomId` | Nghiem trong | Da sua | Dung `ever`, request id va load members/tags truoc khi bind expenses |
| Worker trong `AuthController` khong dispose | Canh bao | Da sua | Luu `Worker` va dispose trong `onClose()` |

## Thay doi chinh

### 1. Repository-First

- Them `lib/features/expense/models/member_option.dart`.
- Chuyen truy van user display name sang `lib/features/expense/repositories/expense_repository.dart`.
- Them `deleteExpense()` tai `ExpenseRepository` de xoa du lieu tren Firestore.

### 2. On dinh luong du lieu room -> members/tags -> expenses

- `ExpenseController` chi con lang nghe `roomId` qua `ever`.
- Moi lan doi room se:
  - huy stream cu,
  - reset state,
  - load members,
  - load tags,
  - sau cung moi bind stream expenses.
- Dung `requestId` de chan ket qua cu ghi de vao room moi.

### 3. Chong submit trung

- Nut luu trong `lib/features/expense/screens/add_expense_screen.dart` da duoc boc `Obx`.
- Khi `isSaving = true`, nut se bi disable va hien thi trang thai dang luu.
- Screen dong bo lai `_selectedTag`, `_splitBetweenUids` va `_paidByUid` khi du lieu reactive thay doi.

### 4. Error handling

- Them `try-catch` trong `ExpenseController.addExpense()`, `ExpenseController.deleteExpense()`, `_handleRoomChange()` va stream error callback.
- Hien thi `Snackbar` tieng Viet khi Firestore hoac luong dong bo gap loi.

## Cac muc con lai nen tiep tuc xu ly

| Muc | Muc do | De xuat |
| --- | --- | --- |
| Logging debug ra file va HTTP trong startup | Nghiem trong | Boc bang `kDebugMode` hoac loai khoi production |
| `AppGate` co the treo loading neu user doc null | Canh bao | Them state recovery hoac tao lai user doc |
| Sign-in UI chua hien thong bao loi dang nhap ro rang | Canh bao | Bat loi Google/Firebase va hien snackbar tieng Viet |
| Tag hien van la mock data trong controller | Goi y toi uu | Tach tiep sang repository/service rieng khi backend tag san sang |

## File da thay doi

- `lib/features/auth/controllers/auth_controller.dart`
- `lib/features/expense/controllers/expense_controller.dart`
- `lib/features/expense/models/member_option.dart`
- `lib/features/expense/repositories/expense_repository.dart`
- `lib/features/expense/screens/add_expense_screen.dart`
- `lib/features/expense/screens/expense_calendar_screen.dart`
- `lib/features/expense/screens/expense_detail_screen.dart`
