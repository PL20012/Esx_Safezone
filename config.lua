Config = {}

-- ─────────────────────────────────────────────────────────────────
--  Framework ที่ใช้งาน
-- ─────────────────────────────────────────────────────────────────
--  ตัวเลือก: "qb" | "qbox" | "ox" | "esx" | "standalone"
--  - "qb"         = QBCore
--  - "qbox"       = Qbox (QBCore fork)
--  - "ox"         = OX Core (ox_core)
--  - "esx"        = ESX Legacy
--  - "standalone" = ไม่ใช้ framework (ทำงานแบบ pure FiveM)
-- ─────────────────────────────────────────────────────────────────
Config.Framework = "esx"

-- ─────────────────────────────────────────────────────────────────
--  โซนปลอดภัย (Safe Zones)
-- ─────────────────────────────────────────────────────────────────
--  shape       : "circle" | "polygon"
--  circle      : ใช้ coords + radius
--  polygon     : ใช้ points + minZ + maxZ
--  allowVehicle: true = อนุญาตให้ขับรถเข้า, false = บล็อครถ
-- ─────────────────────────────────────────────────────────────────

Config.Zones = {

    -- ── Circle Zone #1 (Sandy Shores) ────────────────────────────
    {
        name            = "SAFE ZONE",
        shape           = "circle",
        coords          = vector3(234.4, 3995.28, 49.92),
        radius          = 150.0,
        allowVehicle    = true,
        blipColor       = 2,
        blipSprite      = 398,
        markerColor     = {r = 231, g = 198, b = 77, a = 155},
    },

    -- ── Polygon Zone #1 (Legion Square) ──────────────────────────
    {
        name            = "SAFE ZONE",
        shape           = "polygon",
        points          = {
            vector2(187.64, -848.84),
            vector2(169.8, -886.24),
            vector2(133.2, -986.36),
            vector2(209.32, -1013.72),
            vector2(259.88, -874.32),
            vector2(189.2, -848.64),
        },
        minZ            = 25.0,
        maxZ            = 50.0,
        allowVehicle    = false,
        blipColor       = 2,
        blipSprite      = 398,
        markerColor     = {r = 100, g = 200, b = 255, a = 155},
    },

}

-- ─────────────────────────────────────────────────────────────────
--  การตั้งค่าทั่วไป
-- ─────────────────────────────────────────────────────────────────
Config.Debug = {
    showMarkers     = false,    -- เปิด/ปิดการแสดง marker
    markerDrawDist  = 300.0,    -- ระยะที่วาด marker
    labelDrawDist   = 80.0,     -- ระยะที่แสดง label
}

Config.VehicleBlock = {
    lookahead       = 6.0,      -- ระยะมองล่วงหน้าของรถ
    freezeDuration  = 80,       -- ระยะเวลา freeze รถ (ms)
}

Config.Notification = {
    debounceMs      = 300,      -- กันข้อความซ้ำ (ms)
    soundFile       = "1.mp3",  -- ไฟล์เสียงแจ้งเตือน
    useFrameworkNotify = true,  -- true = ใช้ notify ของ framework, false = ใช้ NUI อย่างเดียว
}

-- ─────────────────────────────────────────────────────────────────
--  ปุ่มที่ถูกปิดการใช้งานใน Safe Zone
-- ─────────────────────────────────────────────────────────────────
Config.DisabledControls = {
    -- การโจมตี
    {group = 0, control = 24},   -- Attack
    {group = 0, control = 25},   -- Aim
    {group = 0, control = 257},  -- Attack 2

    -- การโจมตีบนรถ
    {group = 0, control = 68},   -- Vehicle Attack
    {group = 0, control = 69},   -- Vehicle Attack 2
    {group = 0, control = 70},   -- Vehicle Passenger Attack
    {group = 0, control = 91},   -- Vehicle Fly Attack
    {group = 0, control = 92},   -- Vehicle Fly Attack 2
    {group = 0, control = 106},  -- Vehicle Melee Hold

    -- การต่อสู้ระยะประชิด
    {group = 0, control = 140},  -- Melee Attack Light
    {group = 0, control = 141},  -- Melee Attack Heavy
    {group = 0, control = 142},  -- Melee Attack Alternate
    {group = 0, control = 143},  -- Melee Block
    {group = 0, control = 263},  -- Melee Attack 1
    {group = 0, control = 264},  -- Melee Attack 2
}