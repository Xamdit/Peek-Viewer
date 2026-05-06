# 🔭 Peek - Docker Dashboard สำหรับ macOS

Peek เป็นเครื่องมือจัดการ Docker ที่เรียบง่ายและสวยงามสำหรับ macOS โดยตัวแอปจะทำงานอยู่บน Menu Bar ของคุณ ช่วยให้คุณตรวจสอบสถานะของ Container ได้อย่างรวดเร็วผ่าน Widget แบบลอยตัว และมี Dashboard สำหรับการจัดการที่ครบถ้วน

## ✨ คุณสมบัติเด่น (Features)

- **Menu Bar Integration**: เข้าถึงสถานะ Docker และเครื่องมือจัดการได้รวดเร็วโดยตรงจาก Menu Bar ของ macOS
- **Floating Widget (สไตล์ PiP)**:
  - หน้าต่างขนาดเล็กที่ลอยอยู่เหนือหน้าต่างอื่นๆ เสมอ แสดงสถานะสดของ Container
  - **Auto-Snap**: เคลื่อนที่เข้าหามุมหน้าจอที่ใกล้ที่สุดโดยอัตโนมัติเมื่อทำการลาก (Drag)
  - **Spaces Friendly**: แสดงผลค้างอยู่ในทุก Desktop (Spaces) และหน้าจอ Full-screen ตลอดเวลา
  - **Quick Action**: ดับเบิลคลิกที่ Widget เพื่อเปิดหน้า Dashboard หลักทันที
- **Dashboard ครบวงจร**:
  - ดูและจัดการ Containers, Images และ Networks
  - ตรวจสอบรายละเอียด Container (Ports, Environment variables และอื่นๆ)
  - ฟีเจอร์ "Show in Finder" สำหรับเข้าถึง Volume ของ Container ได้ทันที
  - เข้าถึง Web UI ของแอปใน Container ได้ด้วยการคลิกที่เลข Port
- **Docker Tooling Integration**:
  - ตรวจสอบการติดตั้ง Docker ในเครื่องโดยอัตโนมัติ
  - **ระบบติดตั้งในตัว**: หากเครื่องของคุณยังไม่มี Docker CLI สามารถกดติดตั้งผ่านปุ่ม **"Install"** ใน Sidebar ของโปรแกรมได้ทันที หรือติดตั้งเองผ่าน Terminal ด้วยคำสั่ง `brew install docker`
- **Premium Aesthetics**: ดีไซน์ทันสมัยตามหลักการออกแบบของ macOS รวมถึงเอฟเฟกต์กระจกฝ้า (Frosted Glass/HUD) และ Animation ที่นุ่มนวล

## 🚀 เริ่มต้นใช้งาน (Getting Started)

### ความต้องการของระบบ (Prerequisites)

- macOS 12.0 ขึ้นไป
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- ติดตั้ง Docker ในเครื่องของคุณเรียบร้อยแล้ว

### การพัฒนาและทดสอบ (Development & Testing)

หากต้องการสร้างโปรเจกต์ Xcode และรันแอปพลิเคชันในโหมด Debug:

```bash
chmod +x test.sh
./test.sh
```

### การสร้างแอปพลิเคชันเวอร์ชันใช้งานจริง (Publishing)

หากต้องการ Build แอปพลิเคชันเวอร์ชันที่พร้อมติดตั้ง (Release):

```bash
chmod +x publish.sh
./publish.sh
```
แอปพลิเคชันที่พร้อมใช้งานจะอยู่ในโฟลเดอร์ `dist/Peek.app` คุณสามารถลากไปไว้ที่โฟลเดอร์ `/Applications` ของคุณได้เลย

## 🛠 เทคโนโลยีที่ใช้ (Tech Stack)

- **Language**: Swift 5
- **UI Framework**: SwiftUI
- **Architecture**: AppKit-based Menu Bar ร่วมกับ SwiftUI views
- **Build System**: XcodeGen (กำหนดค่าโปรเจกต์ผ่าน YAML)
- **Docker Integration**: เรียกใช้งาน Docker CLI ผ่าน Native shell execution

## 📁 โครงสร้างโปรเจกต์ (Project Structure)

- `MenuBarApp/`: ไฟล์ Source code หลัก
  - `AppDelegate.swift`: ควบคุม Lifecycle ของแอปและตรรกะของ Menu Bar
  - `DashboardView.swift`: หน้าจอจัดการหลัก
  - `WidgetView.swift`: หน้าจอ Widget แบบลอยตัวขนาดเล็ก
  - `DockerMonitor.swift`: ส่วนติดต่อกับ Docker CLI
- `project.yml`: ไฟล์ตั้งค่าโปรเจกต์สำหรับ XcodeGen
- `publish.sh`: สคริปต์อัตโนมัติสำหรับการ Build เวอร์ชันใช้งานจริง
- `test.sh`: สคริปต์สำหรับการ Build และทดสอบระหว่างพัฒนา

---
พัฒนาด้วย ❤️ เพื่อผู้ใช้งาน Docker บน macOS
