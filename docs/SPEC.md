# ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS)
## Ứng dụng quản lý và theo dõi thói quen hằng ngày – Flutter

- **Tên dự án tạm thời:** Habit Tracker
- **Nền tảng:** Android và iOS (Flutter)
- **Ngôn ngữ giao diện:** Tiếng Việt
- **Phiên bản tài liệu:** 1.0
- **Trạng thái:** Đặc tả cơ sở để triển khai đồ án

---

## 1. Tổng quan

### 1.1. Mục đích
Xây dựng ứng dụng di động giúp người dùng tạo, quản lý, nhắc nhở và theo dõi việc thực hiện các thói quen hằng ngày. Ứng dụng hướng đến việc rèn luyện tính kỷ luật cá nhân thông qua thao tác đơn giản, phản hồi trực quan và thống kê tiến độ.

### 1.2. Phạm vi phiên bản MVP
Phiên bản đầu tiên tập trung vào:
1. Xem danh sách thói quen.
2. Thêm, sửa và xóa thói quen.
3. Đánh dấu hoàn thành hoặc bỏ đánh dấu trong ngày.
4. Cấu hình tần suất thực hiện.
5. Cấu hình thời gian nhắc nhở.
6. Lưu dữ liệu cục bộ, không mất khi đóng/mở lại ứng dụng.
7. Xem thống kê theo ngày, tuần và tháng.

Không nằm trong phạm vi MVP: đăng nhập, đồng bộ đám mây, chia sẻ xã hội, nhiều người dùng, bảng xếp hạng, AI đề xuất thói quen và đồng bộ đa thiết bị.

### 1.3. Đối tượng sử dụng
Một cá nhân muốn hình thành và duy trì các thói quen như đọc sách, tập thể dục, uống nước, học tập hoặc thiền.

### 1.4. Giả định và quyết định thiết kế
- Mỗi lần cài đặt ứng dụng phục vụ một người dùng cục bộ, không cần tài khoản.
- Dữ liệu được lưu trên thiết bị.
- Một thói quen có thể được lên lịch vào một hoặc nhiều ngày trong tuần.
- Mỗi thói quen chỉ có tối đa một bản ghi hoàn thành cho một ngày.
- Ngày được tính theo múi giờ địa phương của thiết bị. Khi lưu ngày, sử dụng khóa ngày dạng `YYYY-MM-DD` để tránh sai lệch do giờ UTC.
- Chọn **SQLite** làm phương án lưu trữ chính vì dữ liệu có quan hệ giữa thói quen và lịch sử hoàn thành, cần truy vấn thống kê. SharedPreferences chỉ phù hợp với cài đặt nhỏ, không nên dùng làm kho dữ liệu chính.
- Thông báo nhắc nhở là thông báo cục bộ; cần xin quyền thông báo trên các phiên bản hệ điều hành yêu cầu.

---

## 2. Mục tiêu và tiêu chí thành công

Ứng dụng được xem là đáp ứng mục tiêu khi:
- Người dùng tạo, xem, cập nhật và xóa được thói quen.
- Người dùng đánh dấu hoàn thành theo ngày; trạng thái được giữ sau khi khởi động lại.
- Danh sách trong ngày phản ánh đúng lịch thực hiện của từng thói quen.
- Thống kê ngày/tuần/tháng được tính từ lịch sử hoàn thành và không tính các ngày thói quen không được lên lịch.
- Nhắc nhở được lên lịch theo cấu hình và có thể hủy/cập nhật khi thói quen thay đổi.
- Các thao tác nhập liệu có kiểm tra hợp lệ và thông báo lỗi dễ hiểu.
- Giao diện sử dụng được trên các kích thước màn hình điện thoại phổ biến.

---

## 3. Vai trò và luồng sử dụng

### 3.1. Vai trò
- **Người dùng:** quản lý toàn bộ thói quen trên thiết bị.

### 3.2. Luồng chính
1. Mở ứng dụng và xem danh sách thói quen cần thực hiện hôm nay.
2. Chọn nút thêm để tạo thói quen.
3. Nhập tên, mô tả tùy chọn, tần suất và thời gian nhắc.
4. Lưu thói quen; ứng dụng ghi dữ liệu vào SQLite và lên lịch thông báo nếu được bật.
5. Trong ngày, người dùng chạm nút/check để đánh dấu hoàn thành.
6. Ứng dụng lưu lịch sử hoàn thành và cập nhật tiến độ.
7. Người dùng mở màn hình thống kê để xem kết quả theo ngày, tuần hoặc tháng.
8. Người dùng có thể sửa hoặc xóa thói quen; thao tác xóa phải xử lý cả lịch nhắc và dữ liệu liên quan theo quy tắc đã định.

---

## 4. Yêu cầu chức năng

Mức ưu tiên: **Must** = bắt buộc cho MVP; **Should** = nên có; **Could** = mở rộng.

### FR-01 – Danh sách thói quen (Must)
- Hiển thị các thói quen đang hoạt động.
- Mỗi mục hiển thị tối thiểu: tên, mô tả rút gọn (nếu có), lịch thực hiện, trạng thái hôm nay và nút đánh dấu hoàn thành.
- Mặc định hiển thị thói quen được lên lịch cho ngày hiện tại.
- Có trạng thái rỗng hướng dẫn người dùng tạo thói quen đầu tiên.
- Có thể mở màn hình sửa từ một mục thói quen.
- Hiển thị tiến độ hôm nay: số đã hoàn thành / tổng số đến hạn hôm nay.

**Quy tắc:** Thói quen không được lên lịch vào hôm nay không xuất hiện trong danh sách cần hoàn thành hôm nay; có thể cung cấp bộ lọc “Tất cả” để xem các thói quen khác.

### FR-02 – Thêm thói quen (Must)
Trường dữ liệu:
- Tên: bắt buộc, 1–60 ký tự sau khi trim.
- Mô tả: không bắt buộc, tối đa 500 ký tự.
- Tần suất: bắt buộc, một trong:
  - Hằng ngày.
  - Các ngày trong tuần do người dùng chọn (Thứ 2 đến Chủ nhật).
- Nhắc nhở: bật/tắt.
- Thời gian nhắc: bắt buộc nếu bật nhắc nhở; định dạng giờ:phút.

Khi lưu:
- Kiểm tra dữ liệu.
- Ghi thói quen vào SQLite.
- Nếu bật nhắc nhở và có quyền phù hợp, lên lịch thông báo.
- Quay về danh sách và hiển thị thói quen vừa tạo.

### FR-03 – Sửa thói quen (Must)
- Mở biểu mẫu với dữ liệu hiện tại.
- Cho phép cập nhật tất cả trường.
- Lưu thay đổi vào SQLite.
- Cập nhật hoặc hủy/lên lịch lại thông báo tương ứng.
- Không làm mất lịch sử hoàn thành cũ khi chỉ sửa tên, mô tả, tần suất hoặc giờ nhắc.

**Quy tắc thay đổi tần suất:** Lịch sử đã ghi nhận được giữ nguyên. Thống kê trong quá khứ phải dựa trên lịch thực hiện có hiệu lực tại thời điểm đó nếu hệ thống lưu lịch sử lịch; nếu MVP không lưu lịch sử lịch, tài liệu phải nêu rõ thống kê quá khứ có thể bị ảnh hưởng khi sửa tần suất. Khuyến nghị MVP: lưu `created_at` và `updated_at`, đồng thời không cho sửa ngược lịch sử hoàn thành.

### FR-04 – Xóa thói quen (Must)
- Yêu cầu xác nhận trước khi xóa.
- Hủy các thông báo đã lên lịch cho thói quen.
- Xóa hoặc lưu trữ dữ liệu hoàn thành liên quan theo chính sách nhất quán.
- Khuyến nghị: xóa mềm (`is_archived`) để giữ lịch sử và tránh làm sai thống kê trước đó. Nếu chọn xóa cứng, phải xóa lịch sử liên quan trong transaction và thông báo rõ cho người dùng.

### FR-05 – Đánh dấu hoàn thành (Must)
- Cho phép đánh dấu hoàn thành thói quen trong ngày.
- Cho phép bỏ đánh dấu nếu người dùng thao tác nhầm.
- Mỗi cặp `habit_id + completion_date` chỉ có một bản ghi.
- Cập nhật UI ngay sau thao tác; nếu ghi DB thất bại thì hoàn nguyên trạng thái và hiển thị lỗi.
- Trạng thái hoàn thành được giữ sau khi đóng/mở ứng dụng.

### FR-06 – Thống kê tiến độ (Must)
Có bộ chọn:
- Ngày.
- Tuần.
- Tháng.

Hiển thị tối thiểu:
- Số lượt hoàn thành.
- Số lượt cần thực hiện.
- Tỷ lệ hoàn thành.
- Biểu đồ trực quan phù hợp (cột hoặc đường).
- Danh sách hoặc phân tích theo từng thói quen.

**Công thức:**

`completion_rate = completed_occurrences / scheduled_occurrences * 100`

Trong đó:
- `scheduled_occurrences`: số lần thói quen được lên lịch trong khoảng thời gian được chọn và nằm trong thời gian thói quen còn hiệu lực.
- `completed_occurrences`: số lần trong số đó có bản ghi hoàn thành.
- Nếu `scheduled_occurrences = 0`, hiển thị “Chưa có dữ liệu”, không chia cho 0.
- Không tính ngày không được lên lịch vào mẫu số.

### FR-07 – Nhắc nhở cục bộ (Must nếu yêu cầu nhắc nhở được đánh giá; nếu không, có thể xếp Should)
- Người dùng bật/tắt nhắc nhở cho từng thói quen.
- Chọn giờ nhắc.
- Lên lịch thông báo lặp theo các ngày đã chọn.
- Nội dung thông báo gồm tên thói quen và lời nhắc ngắn.
- Sửa/xóa thói quen phải cập nhật/hủy lịch thông báo.
- Xử lý trường hợp người dùng từ chối quyền thông báo: vẫn cho lưu thói quen, thông báo trạng thái rằng nhắc nhở chưa hoạt động.
- Kiểm tra hành vi sau khi khởi động lại thiết bị và các giới hạn lập lịch của Android/iOS.

### FR-08 – Điều hướng (Must)
- Có thể chuyển giữa Danh sách, Thống kê và biểu mẫu Thêm/Sửa.
- Nút quay lại hoạt động đúng.
- Không mất dữ liệu biểu mẫu ngoài ý muốn khi điều hướng.

### FR-09 – Cài đặt cơ bản (Could)
- Chọn giao diện sáng/tối hoặc theo hệ thống.
- Chọn ngày bắt đầu tuần.
- Giới thiệu và thông tin phiên bản.

---

## 5. Đặc tả giao diện và UX

### 5.1. Màn hình danh sách – `HabitListScreen`
Thành phần:
- AppBar: tên ứng dụng và truy cập thống kê/cài đặt.
- Khu vực ngày hiện tại.
- Thanh tiến độ tổng quan hôm nay.
- Danh sách thói quen dạng card/list tile.
- Nút thêm thói quen (FAB).
- Bottom navigation hoặc điều hướng tương đương.

Trạng thái cần thiết:
- Loading.
- Có dữ liệu.
- Danh sách rỗng.
- Lỗi tải dữ liệu.
- Không có thói quen đến hạn hôm nay.
- Đã hoàn thành tất cả thói quen hôm nay.

### 5.2. Màn hình thêm/sửa – `HabitFormScreen`
Thành phần:
- TextField tên.
- TextField mô tả.
- Bộ chọn tần suất.
- Các nút chọn thứ trong tuần (khi chọn lịch tùy chỉnh).
- Switch bật/tắt nhắc nhở.
- TimePicker chọn giờ.
- Nút Lưu và Hủy.

Validation:
- Tên không được rỗng.
- Giới hạn độ dài.
- Phải chọn ít nhất một ngày nếu chọn lịch tùy chỉnh.
- Nếu bật nhắc nhở thì phải có thời gian hợp lệ.

### 5.3. Màn hình thống kê – `StatisticsScreen`
Thành phần:
- Segmented control hoặc TabBar: Ngày / Tuần / Tháng.
- Thông tin tổng quan tỷ lệ hoàn thành.
- Biểu đồ tiến độ.
- Danh sách tỷ lệ theo thói quen.
- Điều hướng kỳ trước/kỳ tiếp theo nếu phù hợp.

### 5.4. Nguyên tắc UX
- Ưu tiên thao tác một tay.
- Nút đánh dấu hoàn thành đủ lớn, dễ nhận biết.
- Màu sắc có tương phản tốt; không chỉ dùng màu để thể hiện trạng thái.
- Có nhãn và trạng thái hỗ trợ accessibility.
- Có xác nhận khi xóa.
- Dùng SnackBar hoặc thông báo tương đương cho kết quả thao tác.
- Định dạng ngày/giờ theo locale tiếng Việt.

---

## 6. Mô hình dữ liệu

### 6.1. Bảng `habits`

| Cột | Kiểu SQLite | Ràng buộc / ý nghĩa |
|---|---|---|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| name | TEXT | NOT NULL |
| description | TEXT | NULL |
| frequency_type | TEXT | `daily` hoặc `custom` |
| reminder_enabled | INTEGER | NOT NULL, 0/1 |
| reminder_hour | INTEGER | NULL hoặc 0–23 |
| reminder_minute | INTEGER | NULL hoặc 0–59 |
| is_archived | INTEGER | NOT NULL, mặc định 0 |
| created_at | TEXT | NOT NULL, ISO-8601 |
| updated_at | TEXT | NOT NULL, ISO-8601 |

### 6.2. Bảng `habit_days`

Dùng cho lịch tùy chỉnh.

| Cột | Kiểu SQLite | Ràng buộc / ý nghĩa |
|---|---|---|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| habit_id | INTEGER | NOT NULL, FK → habits.id |
| weekday | INTEGER | NOT NULL, 1–7 (Thứ 2–Chủ nhật) |

Unique constraint: `(habit_id, weekday)`.

Với `frequency_type = daily`, không bắt buộc có bản ghi trong bảng này.

### 6.3. Bảng `habit_completions`

| Cột | Kiểu SQLite | Ràng buộc / ý nghĩa |
|---|---|---|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| habit_id | INTEGER | NOT NULL, FK → habits.id |
| completion_date | TEXT | NOT NULL, `YYYY-MM-DD` theo ngày địa phương |
| completed_at | TEXT | NOT NULL, ISO-8601 timestamp |

Unique constraint: `(habit_id, completion_date)`.

### 6.4. Quy tắc toàn vẹn
- Bật `PRAGMA foreign_keys = ON`.
- Các thao tác cập nhật nhiều bảng phải nằm trong transaction.
- Có index cho `habit_completions(completion_date)` và `habit_completions(habit_id, completion_date)`.
- Xác định rõ chính sách archive/delete và cascade.
- Tạo migration/version DB; không thay đổi schema mà không tăng version và viết migration.

---

## 7. Kiến trúc và tổ chức mã nguồn đề xuất

Áp dụng kiến trúc phân lớp vừa đủ cho đồ án, tránh over-engineering.

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/
│   ├── constants/
│   ├── utils/
│   ├── errors/
│   └── widgets/
├── data/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── migrations/
│   ├── models/
│   └── repositories/
├── features/
│   ├── habits/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── statistics/
│   │   ├── domain/
│   │   └── presentation/
│   └── reminders/
│       ├── data/
│       └── services/
└── shared/
    ├── enums/
    └── extensions/

test/
├── unit/
├── widget/
└── integration/
```

Đây là cấu trúc tham khảo; có thể điều chỉnh theo quy mô thực tế. Tránh tạo abstraction không cần thiết.

### 7.1. State management
Chọn một giải pháp thống nhất:
- Khuyến nghị: `Provider` hoặc `Riverpod`.
- Không trộn nhiều giải pháp state management nếu không có lý do rõ ràng.
- UI không trực tiếp gọi SQL.
- State/controller gọi repository; repository chịu trách nhiệm truy cập dữ liệu.

### 7.2. Luồng dữ liệu đề xuất

```text
Widget / Screen
      |
      v
Provider / ViewModel / Notifier
      |
      v
Repository
      |
      v
SQLite Data Source
```

Nhắc nhở:

```text
Habit Form
    |
    v
Habit Repository ----> SQLite
    |
    v
Reminder Service ----> Local Notification Plugin
```

Thống kê:

```text
Statistics Screen
       |
       v
Statistics Controller
       |
       v
Statistics Repository / Query
       |
       v
Completion + Habit + Schedule Data
       |
       v
Aggregation (day/week/month)
```

---

## 8. Công nghệ và package tham khảo

Các package dưới đây là gợi ý, không bắt buộc. Trước khi thêm dependency, cần kiểm tra phiên bản tương thích với Flutter/Dart SDK của dự án.

| Nhu cầu | Phương án tham khảo |
|---|---|
| Database | `sqflite` |
| State management | `provider` hoặc `flutter_riverpod` |
| Local notification | `flutter_local_notifications` |
| Biểu đồ | `fl_chart` |
| Date/time | `intl` |
| ID thông báo | ID ổn định sinh từ habit ID và lịch |

Không thêm package nếu Flutter SDK hoặc thư viện hiện có đã đáp ứng tốt.

---

## 9. Yêu cầu phi chức năng

### NFR-01 – Hiệu năng
- Các thao tác CRUD thông thường phản hồi mượt trên thiết bị phổ thông.
- Truy vấn thống kê không tải toàn bộ dữ liệu không cần thiết.
- Dùng index phù hợp cho truy vấn theo ngày và thói quen.

### NFR-02 – Độ tin cậy
- Dữ liệu phải còn sau khi đóng/mở ứng dụng.
- Không tạo bản ghi hoàn thành trùng cho cùng thói quen/ngày.
- Lỗi ghi dữ liệu phải được hiển thị và không để UI báo thành công giả.

### NFR-03 – Bảo trì
- Tách UI, state/business logic và data access.
- Đặt tên rõ nghĩa, tuân thủ Dart style.
- Tránh file quá lớn và logic nghiệp vụ trong Widget.
- Có test cho các quy tắc tính lịch và thống kê.

### NFR-04 – Quyền riêng tư
- Không thu thập dữ liệu cá nhân không cần thiết.
- Không yêu cầu quyền camera, GPS, danh bạ hoặc microphone vì không thuộc phạm vi chức năng cốt lõi.
- Chỉ yêu cầu quyền thông báo khi cần nhắc nhở.

### NFR-05 – Khả năng tương thích
- Hỗ trợ các kích thước màn hình điện thoại phổ biến.
- Kiểm thử trên Android; kiểm thử iOS nếu đồ án yêu cầu hỗ trợ iOS.
- Xử lý quyền thông báo theo phiên bản hệ điều hành.

---

## 10. Quy tắc nghiệp vụ và trường hợp biên

1. Không cho phép tên thói quen chỉ chứa khoảng trắng.
2. Một thói quen chỉ được hoàn thành một lần trong một ngày.
3. Bỏ đánh dấu phải xóa đúng bản ghi của ngày đang xem.
4. Thói quen lưu trữ (`is_archived = 1`) không xuất hiện trong danh sách hoạt động và không tạo nhắc nhở mới.
5. Ngày đầu/cuối tuần và tháng phải được tính theo locale/cấu hình tuần đã chọn.
6. Khi đổi múi giờ, khóa ngày hoàn thành đã lưu không tự động chuyển đổi.
7. Nếu người dùng tắt quyền thông báo, dữ liệu thói quen vẫn hoạt động bình thường.
8. Nếu giờ nhắc đã qua trong ngày, hành vi lập lịch tiếp theo phải theo quy tắc của notification plugin và được kiểm thử.
9. Khi sửa tần suất, không tự động xóa completion history.
10. Tỷ lệ thống kê không được tính các ngày trước `created_at` hoặc ngày không thuộc lịch thực hiện.
11. Khi xóa/archive, phải hủy các notification ID tương ứng.
12. Nếu database lỗi hoặc migration thất bại, hiển thị lỗi có thể hiểu được; không âm thầm xóa dữ liệu.

---

## 11. Tiêu chí nghiệm thu (Acceptance Criteria)

### AC-01 – Tạo thói quen
**Given** người dùng đang ở màn hình danh sách  
**When** nhập tên hợp lệ, chọn tần suất và lưu  
**Then** thói quen xuất hiện đúng lịch và vẫn còn sau khi khởi động lại ứng dụng.

### AC-02 – Validation
**Given** biểu mẫu thêm thói quen  
**When** người dùng để trống tên hoặc không chọn ngày cho lịch tùy chỉnh  
**Then** ứng dụng không lưu và hiển thị lỗi tại trường tương ứng.

### AC-03 – Sửa thói quen
**Given** một thói quen đã tồn tại  
**When** người dùng thay đổi thông tin và lưu  
**Then** thông tin mới được hiển thị, lịch sử hoàn thành không bị mất.

### AC-04 – Xóa thói quen
**Given** một thói quen có thể có lịch nhắc  
**When** người dùng xác nhận xóa/archive  
**Then** thói quen không còn trong danh sách hoạt động và lịch nhắc được hủy.

### AC-05 – Hoàn thành hằng ngày
**Given** thói quen đến hạn hôm nay  
**When** người dùng đánh dấu hoàn thành  
**Then** UI cập nhật, dữ liệu được lưu và không tạo bản ghi trùng.

### AC-06 – Bỏ đánh dấu
**Given** thói quen đã hoàn thành hôm nay  
**When** người dùng bỏ đánh dấu  
**Then** trạng thái trở về chưa hoàn thành và thống kê được cập nhật.

### AC-07 – Thống kê
**Given** có dữ liệu lịch và hoàn thành  
**When** người dùng chọn ngày/tuần/tháng  
**Then** số liệu và tỷ lệ được tính đúng theo công thức đã định.

### AC-08 – Nhắc nhở
**Given** người dùng bật nhắc nhở và cấp quyền thông báo  
**When** đến lịch đã cấu hình  
**Then** thiết bị nhận thông báo phù hợp; nếu không cấp quyền, ứng dụng vẫn lưu được thói quen và giải thích trạng thái.

### AC-09 – Lưu trữ cục bộ
**Given** người dùng đã tạo và hoàn thành thói quen  
**When** đóng hoàn toàn rồi mở lại ứng dụng  
**Then** thói quen và lịch sử vẫn được khôi phục chính xác.

---

## 12. Kế hoạch kiểm thử

### Unit tests
- Validation tên/mô tả.
- Xác định thói quen đến hạn theo weekday.
- Tính khoảng ngày của tuần/tháng.
- Tính tỷ lệ hoàn thành, bao gồm trường hợp mẫu số bằng 0.
- Không tạo completion trùng.
- Quy tắc archive và lịch nhắc.

### Widget tests
- Danh sách có dữ liệu và rỗng.
- Form thêm/sửa và validation.
- Nút đánh dấu hoàn thành.
- Chuyển tab thống kê.
- Trạng thái loading/error.

### Integration tests
- Tạo → đóng/mở app → dữ liệu còn.
- Tạo → hoàn thành → thống kê cập nhật.
- Sửa giờ nhắc → lịch cũ bị hủy và lịch mới được tạo.
- Archive/xóa → notification được hủy.
- Migration database từ phiên bản cũ.

---

## 13. Kế hoạch triển khai đề xuất

| Giai đoạn | Công việc | Kết quả |
|---|---|---|
| 1. Khởi tạo | Tạo Flutter project, theme, routing, cấu trúc thư mục | Khung ứng dụng |
| 2. Data layer | Thiết kế SQLite, model, repository, migration | CRUD dữ liệu nền |
| 3. Habit UI | Danh sách và form thêm/sửa | Quản lý thói quen |
| 4. Completion | Đánh dấu/bỏ đánh dấu theo ngày | Theo dõi hằng ngày |
| 5. Reminder | Xin quyền và lập lịch notification | Nhắc nhở |
| 6. Statistics | Truy vấn và tổng hợp ngày/tuần/tháng | Dashboard thống kê |
| 7. Quality | Unit/widget/integration tests, xử lý lỗi | Bản ổn định |
| 8. Hoàn thiện | Kiểm tra UX, README, ảnh chụp màn hình | Bản nộp đồ án |

---

## 14. Rủi ro và điểm cần xác nhận

- **SQLite hay SharedPreferences:** chọn SQLite cho dữ liệu nghiệp vụ; SharedPreferences chỉ dùng cho tùy chọn nhỏ.
- **Lịch sử tần suất:** nếu cần thống kê lịch sử tuyệt đối chính xác sau khi người dùng sửa lịch, cần bổ sung bảng lịch sử lịch có `effective_from`/`effective_to`. Đây có thể là phần mở rộng ngoài MVP.
- **Thông báo iOS/Android:** hành vi và quyền khác nhau theo hệ điều hành; cần kiểm thử trên thiết bị thật.
- **Notification sau reboot:** xác minh plugin và cấu hình nền tảng có hỗ trợ khôi phục lịch hay cần tự lập lịch lại.
- **Xóa hay lưu trữ:** khuyến nghị lưu trữ để không phá vỡ lịch sử thống kê.
- **Tuần bắt đầu vào ngày nào:** mặc định theo locale Việt Nam (Thứ 2), nhưng nên có quy tắc thống nhất trong toàn ứng dụng.

---

## 15. Ngoài phạm vi và hướng phát triển

Có thể phát triển sau MVP:
- Chuỗi ngày liên tiếp (streak).
- Mục tiêu số lần mỗi tuần.
- Nhóm/danh mục thói quen.
- Widget màn hình chính.
- Sao lưu/khôi phục.
- Đồng bộ đám mây và tài khoản.
- Xuất thống kê CSV/PDF.
- Nhắc nhở linh hoạt nhiều khung giờ.
- Thành tựu và gamification.

**Kết luận:** MVP cần ưu tiên tính đúng đắn của lịch thực hiện, lịch sử hoàn thành và công thức thống kê. Đây là nền tảng nghiệp vụ quan trọng hơn việc bổ sung nhiều hiệu ứng giao diện.
