# Luong CRUD Transaction (Chi tiet)

Tai lieu nay mo ta luong hoat dong CRUD Transaction theo code hien tai trong project, tu UI den Provider va Database.

## 1) Tong quan kien truc

- UI layer:
  - lib/screens/transaction_list_screen.dart
  - lib/screens/add_edit_transaction_screen.dart
  - lib/screens/transaction_detail_screen.dart
- State layer:
  - lib/providers/transaction_provider.dart
- Data layer:
  - lib/services/database_service.dart

Luong chuan:

1. User thao tac tren man hinh.
2. Screen goi ham cua TransactionProvider.
3. Provider goi DatabaseService de thao tac DB.
4. DatabaseService cap nhat bang transactions va wallets trong cung mot transaction SQL.
5. Provider refreshData de load lai wallets + transactions.
6. UI duoc notifyListeners cap nhat lai danh sach, so du, summary.

## 2) Read (R) - Tai danh sach va chi tiet giao dich

### 2.1 Read danh sach tren Transaction List

- Entry point: TransactionListScreen su dung Consumer<TransactionProvider>.
- Khi app khoi dong, TransactionProvider.loadInitialData() duoc goi (tu main.dart) va goi tiep refreshData().
- refreshData() se:
  - set _isLoading = true
  - clear _errorMessage
  - query:
    - getWallets()
    - getTransactionsWithWallet()
  - set _isLoading = false
  - notifyListeners()

Ket qua tren UI:

- Danh sach giao dich duoc render tu provider.transactions.
- Tong thu nhap/chi tieu va tong so du duoc tinh lai tu data moi.

### 2.2 Read chi tiet tren Transaction Detail

- Entry point: TransactionDetailScreen._loadDetail().
- Goi provider.getTransactionDetail(transactionId).
- Provider forward den DatabaseService.getTransactionDetail(transactionId).
- UI dung FutureBuilder de hien loading/error/data.

## 3) Create (C) - Them giao dich moi

### 3.1 User flow

- Tu TransactionListScreen, bam FAB +.
- Mo AddEditTransactionScreen o create mode (_isEditMode = false).

### 3.2 Validate input trong AddEditTransactionScreen._submit()

- Bat buoc chon vi (_walletId != null).
- So tien khong duoc rong.
- So tien phai > 0.
- Neu sai: show SnackBar va dung luong.

### 3.3 Ghi DB va cap nhat state

- Tao Transaction model.
- Goi provider.addTransaction(tx).
- Trong provider.addTransaction:
  - goi DatabaseService.insertTransaction(tx)
  - goi refreshData()

### 3.4 Logic data quan trong o DatabaseService.insertTransaction()

- Chay trong db.transaction(...) de dam bao tinh nhat quan.
- Insert vao bang transactions.
- Goi _applyWalletBalanceImpact(... reverse: false):
  - Neu EXPENSE -> tru balance
  - Neu INCOME -> cong balance
- Tao thong bao low-balance neu can.

### 3.5 Tra ket qua ve UI

- AddEditTransactionScreen pop voi ket qua 'created'.
- TransactionListScreen nhan result == 'created' va show SnackBar "Them giao dich thanh cong.".

## 4) Update (U) - Chinh sua giao dich

### 4.1 User flow

- Co 2 cach vao edit:
  - Tu TransactionDetailScreen bam nut edit (FAB).
  - Tu luong khac co truyen existingTransaction.
- AddEditTransactionScreen o edit mode (_isEditMode = true), form duoc prefill.

### 4.2 Save update

- _submit() validate du lieu nhu create.
- Tao Transaction model co id.
- Goi provider.updateTransaction(tx).

### 4.3 Logic data quan trong o DatabaseService.updateTransaction()

Ham nay xu ly rat dung nghiep vu so du:

1. Load giao dich cu theo id.
2. Reverse anh huong giao dich cu len vi cu:
   - old EXPENSE -> cong lai
   - old INCOME -> tru lai
3. Update dong transactions.
4. Apply anh huong giao dich moi len vi moi.
5. Check low-balance notification cho vi cu/vi moi.

Nho vay, neu doi wallet, doi type, doi amount thi balance van dung.

### 4.4 Tra ket qua ve UI

- AddEditTransactionScreen pop voi 'updated'.
- TransactionDetailScreen nhan 'updated':
  - show SnackBar "Cap nhat giao dich thanh cong."
  - setState load lai detail.

## 5) Delete (D) - Xoa giao dich

Hien tai co 2 diem xoa:

### 5.1 Xoa tu Transaction List (swipe)

- User swipe Dismissible.
- Confirm dialog.
- Neu dong y: goi provider.deleteTransaction(txId).
- Thanh cong/that bai deu show SnackBar.

### 5.2 Xoa tu AddEditTransactionScreen (edit mode)

- Bam "Xoa giao dich".
- Confirm dialog.
- Goi provider.deleteTransaction(transactionId).
- Thanh cong: pop voi ket qua 'deleted'.
- That bai: show SnackBar loi.

### 5.3 Xoa tu TransactionDetailScreen

- Bam icon thung rac.
- Confirm dialog.
- Goi provider.deleteTransaction(transactionId).
- Thanh cong: show SnackBar + pop ve man truoc.
- That bai: show SnackBar loi.

### 5.4 Logic data o DatabaseService.deleteTransaction()

- Chay trong db.transaction(...).
- Tim giao dich can xoa.
- Reverse anh huong balance cua giao dich do (de dua vi ve dung trang thai).
- Tao low-balance notification neu can.
- Xoa dong transactions.

## 6) Co che dong bo du lieu sau moi CRUD

Sau add/update/delete, provider deu goi refreshData().

Tac dung:

- Wallet balances moi nhat duoc tai lai.
- Transactions list moi nhat duoc tai lai.
- Summary (thu nhap/chi tieu), banner tong so du, list item deu cap nhat ngay.

## 7) Error handling hien tai

- Data loading:
  - refreshData() bat exception -> set _errorMessage
  - TransactionListScreen hien man hinh loi + nut Thu lai.
- Save/Delete tren form/detail/list:
  - try/catch tai screen
  - show SnackBar thanh cong/that bai.

## 8) Cac diem can luu y khi mo rong

1. Tranh duplicate logic:
- Dang co nhieu diem xoa (List, Detail, Edit) va moi noi show message rieng.
- Co the gom helper thong bao de thong nhat UX.

2. Provider hien tai luon refresh full data sau CRUD:
- Don gian, de dung.
- Doi lai ton query hon. Neu data lon co the toi uu cap nhat local list + wallet theo delta.

3. DatabaseService va DatabaseHelper dang song song:
- Luong Transaction CRUD dang dung DatabaseService.
- Nen giu 1 nguon DB chinh de tranh nham lan ve schema va migration.

## 9) Sequence tom tat (ngan)

Create:
- List FAB -> AddEdit submit -> Provider.add -> DB.insert + apply balance -> Provider.refreshData -> UI reload + SnackBar.

Update:
- Detail Edit -> AddEdit submit -> Provider.update -> DB.reverse old + update row + apply new -> Provider.refreshData -> Detail reload + SnackBar.

Delete:
- List swipe hoac Detail/Edit delete -> Provider.delete -> DB.reverse balance + delete row -> Provider.refreshData -> UI cap nhat + SnackBar.

---

Neu can, buoc tiep theo minh co the ve them so do Mermaid cho 3 luong Create/Update/Delete de ban nhin nhanh hon khi on tap.