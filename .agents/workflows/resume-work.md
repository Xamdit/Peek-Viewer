# 🚀 Resume Work Workflow

## 📋 Instructions
เมื่อได้รับคำสั่ง `/resume-work` หรือรันสคริปต์ `./load` ให้ดำเนินการดังนี้:

1. **Memory Recovery**: 
    - เปิดอ่านไฟล์ [.agents/workflows/complete-work.md](file:///Users/parinkanthakamala/Documents/workspace/xcode/.agents/workflows/complete-work.md) ทันที
    - อ่านหัวข้อ **Latest Progress** และ **Pending Issues** เพื่อฟื้นฟูบริบทของงาน
2. **Sync**: รัน `git pull` เพื่ออัปเดตโค้ดล่าสุดจาก repository
3. **Environment Check**: 
    - รัน `xcodegen generate` เพื่อให้มั่นใจว่าไฟล์โปรเจกต์ Xcode เป็นปัจจุบัน
    - รัน `./test.sh` เพื่อตรวจสอบว่าโปรเจกต์ยังบิลด์และรันได้ปกติ
4. **Action**: เริ่มต้นงานตามที่ระบุไว้ใน **Pending Issues** หรือตามความต้องการใหม่ของผู้ใช้
5. **Ready**: แจ้งผู้ใช้ว่าระบบพร้อมทำงานต่อแล้ว
