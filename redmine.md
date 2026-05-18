# TravelPin

TravelPin là ứng dụng iOS giúp lưu lại các địa điểm, hình ảnh và khoảnh khắc cá nhân theo từng người dùng. Ứng dụng phù hợp để ghi lại nơi đã đi, nơi muốn đi, quán cà phê, ăn uống, check-in hoặc các phân loại tuỳ chỉnh khác.

## Chức năng chính

### Quản lý địa điểm

- Thêm địa điểm tự do theo tên, vị trí trên bản đồ và hình ảnh.
- Lưu thông tin ngày đi, phương tiện, ghi chú và trạng thái đã đi/chưa đi.
- Hỗ trợ nhiều nhóm phân loại như du lịch, cà phê, ăn uống, check-in và khác.
- Cho phép tạo thêm phân loại riêng với tên và icon tuỳ chọn.

### Bản đồ

- Hiển thị các địa điểm đã lưu trực tiếp trên bản đồ.
- Lọc địa điểm theo phân loại.
- Pin có style riêng theo loại địa điểm và trạng thái.
- Hỗ trợ xem nhanh thông tin địa điểm khi chọn pin.

### Danh sách địa điểm

- Xem toàn bộ địa điểm theo người dùng hiện tại.
- Lọc danh sách theo phân loại đã bật trong phần cá nhân hoá.
- Mở chi tiết từng địa điểm để xem hoặc chỉnh sửa thông tin.

### Thống kê

- Thống kê địa điểm theo phân loại, thành phố và quốc gia.
- Dữ liệu thống kê dựa trên địa điểm đã lưu và thông tin reverse geocoding.
- Có thể xem danh sách địa điểm tương ứng khi chọn một nhóm thống kê.

### Library và video khoảnh khắc

- Gom các địa điểm cùng phân loại thành một nhóm khoảnh khắc.
- Tạo video ngắn từ ảnh đã lưu trong từng phân loại.
- Video có hiệu ứng chuyển ảnh, text thông tin địa điểm và thời gian.
- Lưu video đã tạo trong Library.
- Xem, chia sẻ, đổi tên hoặc xoá từng video.
- Có thể xoá toàn bộ video đã tạo mà không ảnh hưởng đến địa điểm hoặc ảnh gốc.

### Người dùng và cá nhân hoá

- Hỗ trợ nhiều người dùng trên cùng thiết bị.
- Dữ liệu địa điểm được tách riêng theo từng người dùng.
- Lần đầu mở app có màn hình nhập tên hiển thị và chọn phân loại cần dùng.
- Có thể thêm người dùng mới hoặc chuyển người dùng trong phần Settings.
- Hỗ trợ tuỳ chỉnh mode hiển thị: Auto, Light hoặc Dark.

### Ảnh và vị trí

- Lưu ảnh cho từng địa điểm.
- Hỗ trợ đọc metadata vị trí từ ảnh trong thư viện nếu ảnh có thông tin GPS.
- Tự động lấy thông tin thành phố, quốc gia và địa chỉ hiển thị từ vị trí đã chọn.

### Backup dữ liệu

- Hỗ trợ xuất dữ liệu để backup thủ công.
- Hỗ trợ nhập lại dữ liệu khi đổi máy hoặc cần khôi phục.

## Công nghệ sử dụng

- Swift
- SwiftUI
- MapKit
- CoreLocation
- PhotosUI
- AVFoundation
- AVKit
- FileManager local storage

## Người tạo app

TravelPin được phát triển bởi Long Anh với mục tiêu xây dựng một ứng dụng lưu giữ địa điểm cá nhân đơn giản, dễ dùng và có cảm xúc hơn so với việc chỉ đánh dấu vị trí trên bản đồ.

Ý tưởng chính của app là giúp người dùng lưu lại những nơi đã đi, những nơi muốn đi, hình ảnh, thời gian và cảm nhận cá nhân theo từng phân loại. Từ các dữ liệu đó, app có thể tạo thành các khoảnh khắc ngắn để người dùng xem lại hành trình của mình một cách trực quan hơn.

Trong quá trình phát triển, ứng dụng tập trung vào các yếu tố:

- Trải nghiệm sử dụng rõ ràng, không phức tạp.
- Dữ liệu cá nhân được tách riêng theo từng người dùng.
- Bản đồ, hình ảnh và thống kê được kết hợp trong cùng một luồng sử dụng.
- Có thể mở rộng thêm nhiều phân loại, tuỳ chỉnh và tính năng backup trong tương lai.

## Mục tiêu ứng dụng

TravelPin hướng tới một trải nghiệm lưu giữ địa điểm cá nhân đơn giản, trực quan và có tính kỷ niệm. Người dùng không chỉ lưu một vị trí trên bản đồ, mà còn có thể gom ảnh và địa điểm thành các video ngắn để xem lại hoặc chia sẻ.
