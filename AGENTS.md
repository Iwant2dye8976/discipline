# AGENTS.md – Quy tắc làm việc cho dự án Habit Tracker

Tài liệu này cung cấp hướng dẫn bắt buộc cho AI coding agents và cộng tác viên khi phân tích, triển khai, kiểm thử hoặc bảo trì dự án Flutter Habit Tracker.

## 1. Nguồn yêu cầu và thứ tự ưu tiên

Trước khi thực hiện công việc:
1. Đọc `AGENTS.md`.
2. Đọc `docs/SPEC.md` (hoặc đường dẫn đặc tả được nhóm thống nhất).
3. Kiểm tra source code hiện tại, `pubspec.yaml`, cấu hình nền tảng và test.
4. Nếu code hiện tại khác đặc tả, không tự ý phá vỡ hành vi đang có. Báo cáo khác biệt và đề xuất hướng xử lý.

Thứ tự ưu tiên:
- Yêu cầu trực tiếp mới nhất của người dùng/nhóm.
- Đặc tả đã được phê duyệt.
- Quy ước trong file này.
- Quy ước và kiến trúc đang tồn tại trong codebase.

Nếu có mâu thuẫn hoặc thiếu thông tin ảnh hưởng đến dữ liệu, bảo mật hoặc kiến trúc, hãy hỏi trước khi triển khai.

## 2. Mục tiêu sản phẩm

Xây dựng ứng dụng Flutter quản lý thói quen cá nhân với các chức năng cốt lõi:
- Danh sách thói quen.
- Thêm, sửa, xóa/lưu trữ thói quen.
- Tần suất hằng ngày hoặc các ngày trong tuần.
- Đánh dấu/bỏ đánh dấu hoàn thành theo ngày.
- Nhắc nhở cục bộ.
- Thống kê theo ngày, tuần và tháng.
- Lưu dữ liệu bền vững trên thiết bị.

Giao diện mặc định bằng tiếng Việt. Giữ thuật ngữ kỹ thuật tiếng Anh trong code và tài liệu khi phù hợp.

## 3. Quy tắc an toàn khi sửa code

- Không xóa, ghi đè hoặc di chuyển file không liên quan đến nhiệm vụ.
- Không thay đổi cấu hình build, signing, bundle ID, package name hoặc quyền nền tảng nếu chưa có lý do và chưa thông báo.
- Không thêm dependency nếu chưa kiểm tra package hiện có, tính tương thích và lý do cần thiết.
- Không chạy lệnh phá hủy dữ liệu hoặc lệnh không rõ tác dụng.
- Không đưa API key, token, mật khẩu hoặc secret vào source control.
- Không sửa dữ liệu người dùng thật trong quá trình kiểm thử.
- Không tuyên bố hoàn thành nếu chưa chạy kiểm tra phù hợp.
- Trước thay đổi lớn, kiểm tra `git status` và tránh ghi đè thay đổi chưa commit của người dùng.

## 4. Kiến trúc và phân tách trách nhiệm

Tuân thủ kiến trúc hiện có của dự án. Nếu dự án mới, ưu tiên cấu trúc feature-first, phân lớp vừa đủ:

- `presentation`: Screen, Widget, state/controller và UI logic.
- `domain`: entity, quy tắc nghiệp vụ và use case khi thực sự cần.
- `data`: model, repository implementation, database và data source.
- `core`: tiện ích, lỗi, hằng số và thành phần dùng chung.

Quy tắc:
- Widget không được chứa SQL hoặc truy cập database trực tiếp.
- Không đặt business logic phức tạp trong `build()`.
- UI gọi state/controller; state/controller gọi repository/service.
- Repository chịu trách nhiệm truy cập và chuyển đổi dữ liệu.
- Reminder service chịu trách nhiệm lập lịch/hủy thông báo.
- Statistics logic phải tách khỏi UI và có unit test.
- Tránh abstraction, interface hoặc layer không mang lại lợi ích thực tế.
- Không tạo một file khổng lồ chứa toàn bộ ứng dụng.

Luồng dữ liệu chuẩn:

`Screen/Widget → State Controller → Repository/Service → SQLite hoặc Platform API`

## 5. Quy tắc Flutter và Dart

- Dùng null safety.
- Tuân thủ `dart format`.
- Chạy `flutter analyze` và xử lý lỗi do thay đổi gây ra.
- Đặt tên theo Dart conventions: `UpperCamelCase` cho type, `lowerCamelCase` cho biến/hàm, `snake_case.dart` cho file.
- Ưu tiên widget nhỏ, có trách nhiệm rõ ràng.
- Dùng `const` constructor khi có thể.
- Không dùng `BuildContext` sau `await` nếu không kiểm tra `mounted` phù hợp.
- Xử lý loading, empty, error và success state.
- Không nuốt exception; chuyển thành lỗi có ý nghĩa và hiển thị thông báo phù hợp.
- Không dùng hard-coded magic values nếu có thể đặt thành hằng số có tên.
- Giữ UI responsive và kiểm tra overflow.

## 6. State management

- Dùng duy nhất giải pháp state management đã được dự án lựa chọn.
- Nếu chưa có, đề xuất Provider hoặc Riverpod và thống nhất trước khi triển khai diện rộng.
- Không trộn Provider, Riverpod, Bloc hoặc setState tùy tiện.
- State phải phản ánh trạng thái dữ liệu thực tế.
- Khi thao tác bất đồng bộ thất bại, UI không được giữ trạng thái thành công giả.
- Ưu tiên cập nhật state nhất quán; chỉ dùng optimistic update khi có rollback khi lỗi.

## 7. Quy tắc dữ liệu và SQLite

SQLite là nguồn dữ liệu chính cho habits và completion history, trừ khi đặc tả được phê duyệt thay đổi.

### Quy tắc schema
- Dùng migration có version.
- Bật foreign key enforcement.
- Dùng transaction khi cập nhật nhiều bảng.
- Tạo unique constraint chống hoàn thành trùng.
- Dùng parameterized queries; không nối chuỗi input người dùng vào SQL.
- Có index cho truy vấn theo ngày và habit ID khi cần.
- Không thay đổi schema mà bỏ qua migration.

### Quy tắc ngày và thời gian
- `completion_date` lưu theo ngày địa phương dạng `YYYY-MM-DD`.
- Timestamp lưu ISO-8601 và phải thống nhất cách xử lý timezone.
- Không so sánh ngày bằng chuỗi timestamp tùy tiện.
- Việc xác định weekday, tuần và tháng phải dùng một quy tắc nhất quán; mặc định tuần bắt đầu Thứ 2 theo locale Việt Nam.
- Không tạo completion trùng cho `(habit_id, completion_date)`.

### Quy tắc nghiệp vụ
- Tên thói quen sau trim không được rỗng.
- Lịch tùy chỉnh phải có ít nhất một weekday.
- Bật reminder thì cần giờ hợp lệ.
- Bỏ đánh dấu chỉ tác động completion của đúng ngày đang chọn.
- Sửa thông tin thói quen không được vô tình xóa lịch sử.
- Archive/xóa phải xử lý notification và dữ liệu liên quan nhất quán.
- Không tính ngày không được lên lịch vào mẫu số thống kê.
- Nếu không có lượt cần thực hiện, hiển thị “Chưa có dữ liệu”, không chia cho 0.

## 8. Nhắc nhở và quyền hệ điều hành

- Chỉ yêu cầu quyền thông báo khi tính năng nhắc nhở cần dùng.
- Không yêu cầu camera, GPS, danh bạ hoặc microphone nếu không có yêu cầu chức năng mới được phê duyệt.
- Người dùng từ chối quyền thông báo vẫn phải sử dụng được CRUD và theo dõi thói quen.
- Lưu/định danh notification ID ổn định để có thể cập nhật và hủy.
- Khi sửa giờ/tần suất, hủy lịch cũ trước hoặc trong cùng quy trình tạo lịch mới một cách an toàn.
- Khi archive/xóa, hủy các thông báo tương ứng.
- Kiểm tra khác biệt Android/iOS và phiên bản plugin trước khi sửa native configuration.
- Không khẳng định thông báo chắc chắn xuất hiện nếu chưa kiểm thử trên nền tảng mục tiêu.

## 9. UI/UX và accessibility

- Giữ giao diện nhất quán, đơn giản, ưu tiên thao tác một tay.
- Nút đánh dấu hoàn thành phải dễ nhận biết và có vùng chạm phù hợp.
- Trạng thái không chỉ được biểu diễn bằng màu sắc.
- Có nhãn semantics phù hợp cho các nút/icon tương tác.
- Có xác nhận trước thao tác xóa.
- Có empty/loading/error state.
- Không để text overflow hoặc layout vỡ ở màn hình nhỏ.
- Dùng định dạng ngày/giờ phù hợp tiếng Việt.
- Không tự ý thay đổi design system hoặc theme toàn cục trong một task nhỏ nếu không cần thiết.

## 10. Kiểm thử bắt buộc

Khi thay đổi logic, bổ sung hoặc cập nhật test tương ứng.

### Unit tests
- Validation form.
- Xác định habit đến hạn theo weekday.
- Tính ngày đầu/cuối tuần và tháng.
- Tính tỷ lệ hoàn thành.
- Trường hợp không có dữ liệu.
- Chống completion trùng.
- Archive và quy tắc reminder.

### Widget tests
- Danh sách rỗng/có dữ liệu.
- Form thêm/sửa và validation.
- Đánh dấu/bỏ đánh dấu.
- Chuyển màn hình thống kê.
- Loading/error state.

### Integration tests
- CRUD và khôi phục dữ liệu sau khi khởi động lại.
- Hoàn thành habit và cập nhật thống kê.
- Cập nhật/hủy lịch reminder.
- Database migration.

Không mock phần cần kiểm chứng ở integration test nếu mục tiêu của test là xác nhận tích hợp thật. Với platform API, dùng abstraction và test mock/fake ở unit test; kiểm thử thiết bị riêng khi cần.

## 11. Quy trình thực hiện task

Với mỗi task:
1. Đọc đặc tả và các file liên quan.
2. Kiểm tra cấu trúc, quy ước và trạng thái Git.
3. Tóm tắt cách tiếp cận trước khi thay đổi nếu task lớn.
4. Xác định file dự kiến sửa và tác động dữ liệu/API.
5. Triển khai thay đổi nhỏ, có thể kiểm chứng.
6. Viết/cập nhật test.
7. Chạy `dart format` cho file liên quan.
8. Chạy `flutter analyze`.
9. Chạy test phù hợp (`flutter test` và integration test nếu cần).
10. Kiểm tra diff, phát hiện file ngoài phạm vi.
11. Báo cáo kết quả, lệnh đã chạy, test pass/fail và phần chưa xác minh.

Không tự ý chuyển sang task khác khi task hiện tại chưa được kiểm chứng.

## 12. Quy tắc Git và tài liệu

- Không tự ý commit, push, merge hoặc tạo release nếu chưa được yêu cầu.
- Không reset/rebase hoặc force push nếu chưa có xác nhận.
- Không đưa file build, cache, secret hoặc file môi trường cá nhân vào commit.
- Cập nhật README khi thay đổi cách cài đặt/chạy ứng dụng.
- Cập nhật tài liệu kiến trúc khi thay đổi cấu trúc hoặc luồng dữ liệu.
- Đặc tả nằm tại `docs/SPEC.md` (điều chỉnh nếu repository đã có quy ước khác).

## 13. Định dạng báo cáo sau mỗi task

Kết thúc mỗi task bằng báo cáo ngắn:

### Summary
- Những gì đã thực hiện.

### Files changed
- Danh sách file và mục đích thay đổi.

### Validation
- Lệnh đã chạy.
- Kết quả analyze/test/build.

### Risks / Follow-ups
- Vấn đề còn tồn tại.
- Giả định hoặc điểm cần người dùng xác nhận.

### Evidence
- File/class/function liên quan khi giải thích hành vi kỹ thuật.

## 14. Nguyên tắc quan trọng nhất

**Không đoán thay cho việc kiểm tra source code. Không đánh đổi tính đúng đắn của dữ liệu để lấy UI cập nhật nhanh. Không báo cáo thành công nếu chưa có bằng chứng kiểm chứng.**
