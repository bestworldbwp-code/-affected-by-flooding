# แบบแจ้งหยุดงานเนื่องจากอุทกภัย

ระบบนี้เป็นเว็บแบบ static ใช้ Supabase เก็บข้อมูลและรูป แล้วนำขึ้นบน Vercel

- `index.html`: หน้าแบบฟอร์มให้พนักงานกรอก พนักงานไม่ต้องล็อกอิน และตรวจสอบสถานะได้ด้วยเลขคำขอคู่กับรหัสพนักงาน
- `admin.html`: หน้าสำหรับฝ่ายบุคคล ต้องล็อกอินก่อนจึงจะดูรายการ ดูรูป อนุมัติหรือไม่อนุมัติ และดาวน์โหลด CSV ได้
- `supabase/setup.sql`: สร้างตาราง สิทธิ์ (RLS) และ bucket สำหรับเก็บรูป

## ตั้งค่าครั้งแรก

1. เข้า Supabase Dashboard แล้วไปที่ **SQL Editor** วางเนื้อหาไฟล์ `supabase/setup.sql` แล้วกด **Run**
2. ไปที่ **Authentication → Users → Add user** เพื่อสร้างบัญชีให้เจ้าหน้าที่ HR โดยกำหนดอีเมลและรหัสผ่าน และติ๊ก Auto confirm
3. กลับไปที่ SQL Editor แล้วรันคำสั่งนี้ โดยใส่อีเมลของ HR:
   ```sql
   insert into public.hr_admins (email) values ('hr@yourcompany.com');
   ```
4. แนะนำให้ปิดการสมัครสมาชิกเอง ที่ **Authentication → Sign In / Providers → ปิด Allow new users to sign up**

## นำขึ้น Vercel

ไปที่ vercel.com/new แล้ว Import repository นี้ เลือก Framework Preset เป็น **Other** ไม่ต้องตั้ง build command แล้วกด Deploy

## ความปลอดภัย

anon key ใน `config.js` เป็นคีย์สาธารณะที่ออกแบบมาให้ใส่ในหน้าเว็บได้ ข้อมูลได้รับการป้องกันด้วย Row Level Security ดังนี้

- คนทั่วไป: ส่งคำขอและอัปโหลดรูปได้เท่านั้น อ่านข้อมูลไม่ได้
- อีเมลที่อยู่ในตาราง `hr_admins`: อ่านและแก้สถานะได้ ดูรูปได้ผ่านลิงก์ชั่วคราวที่มีอายุ 1 ชั่วโมง
