# Tes RLS lewat API untuk 3 role.
# Jalankan: powershell -ExecutionPolicy Bypass -File .\03-tes-rls.ps1
#
# Catatan penting: UPDATE/DELETE yang ditolak RLS TIDAK error. Hasilnya 200 dengan
# array kosong (0 baris terpengaruh). Hanya INSERT yang error 42501. Skrip ini
# memeriksa keduanya.

$base = "https://kvrilaxiszfdawurfukb.supabase.co"
$key  = "sb_publishable_yMCzmctIY_vYowiaURzWpQ_SlOnyWjV"

# Email dan password tiap akun tes. Samakan dengan yang kamu buat di Dashboard.
$akun = @{
  admin = @{ email = "admin@test.com"; pw = "admin123" }
  staff = @{ email = "staff@test.com"; pw = "staff123" }
  owner = @{ email = "owner@test.com"; pw = "owner123" }
}

# Sesuaikan dengan kolom tabel kamu (isi semua kolom NOT NULL).
$itemBaru = @{ name = "Barang Uji RLS" }
# Sesuaikan nama kolom stock_movements di bawah ini juga.
function BodyMovement($itemId) { @{ item_id = $itemId; quantity = 1; type = "in" } }

function Login($a) {
  $body = @{ email = $a.email; password = $a.pw } | ConvertTo-Json
  Invoke-RestMethod -Method Post -Uri "$base/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $key } -ContentType "application/json" -Body $body
}

function Api($session, $method, $path, $body = $null) {
  $h = @{ apikey = $key; Authorization = "Bearer $($session.access_token)"; Prefer = "return=representation" }
  $p = @{ Method = $method; Uri = "$base/rest/v1/$path"; Headers = $h; ContentType = "application/json" }
  if ($body) { $p.Body = ($body | ConvertTo-Json) }
  try { Invoke-RestMethod @p }
  catch {
    $e = $_
    $kode = ""
    $isi = $e.ErrorDetails.Message
    try { $kode = [int]$e.Exception.Response.StatusCode } catch {}
    if (-not $isi) {
      # Windows PowerShell 5.1: isi error hanya bisa dibaca dari stream response
      try {
        $s = $e.Exception.Response.GetResponseStream()
        if ($s.CanSeek) { $s.Position = 0 }
        $isi = (New-Object System.IO.StreamReader($s)).ReadToEnd()
      } catch {}
    }
    "ERR: [$kode] $isi"
  }
}

function Hitung($r) { if ($r -is [string]) { -1 } else { @($r).Count } }

$script:gagal = 0
function Cek($label, $hasil, $harapan) {
  $err    = ($hasil -is [string]) -and $hasil.StartsWith("ERR:")
  $kosong = (-not $err) -and (@($hasil).Count -eq 0)
  $lolos = switch ($harapan) {
    "ada"        { (-not $err) -and (-not $kosong) }
    "kosong"     { $kosong }
    "rls"        { $err -and ($hasil -match "42501|\[403\]") }
    "tanpa-efek" { $kosong -or ($err -and ($hasil -match "42501|\[403\]")) }
  }
  if ($lolos) { Write-Host "[PASS]  $label" -ForegroundColor Green }
  else {
    $script:gagal++
    Write-Host "[GAGAL] $label (harapan: $harapan)" -ForegroundColor Red
    Write-Host ("        " + ($hasil | ConvertTo-Json -Compress -Depth 3))
  }
}

$admin = Login $akun.admin
$staff = Login $akun.staff
$owner = Login $akun.owner

Write-Host "`n--- Siapkan data uji (admin) ---"
$buat = Api $admin Post "items" $itemBaru
Cek "admin bisa INSERT items" $buat "ada"
$itemId = @($buat)[0].id
if (-not $itemId) { Write-Host "Item uji gagal dibuat. Cek `$itemBaru di atas." -ForegroundColor Red; return }

Write-Host "`n--- STAFF ---"
Cek "staff bisa baca items"                 (Api $staff Get "items?select=*") "ada"
Cek "staff TIDAK lihat item_prices"         (Api $staff Get "item_prices?select=*") "kosong"
Cek "staff TIDAK lihat stock_levels"        (Api $staff Get "stock_levels?select=*") "kosong"
Cek "staff TIDAK lihat stock_movements"     (Api $staff Get "stock_movements?select=*") "kosong"
Cek "staff INSERT items ditolak"            (Api $staff Post "items" $itemBaru) "rls"
Cek "staff UPDATE items tanpa efek"         (Api $staff Patch "items?id=eq.$itemId" @{ name = "diubah staff" }) "tanpa-efek"
Cek "staff DELETE items tanpa efek"         (Api $staff Delete "items?id=eq.$itemId") "tanpa-efek"
Cek "staff INSERT stock_movements ditolak"  (Api $staff Post "stock_movements" (BodyMovement $itemId)) "rls"
Cek "staff TIDAK bisa naikkan role sendiri" (Api $staff Patch "profiles?id=eq.$($staff.user.id)" @{ role = "admin" }) "tanpa-efek"

Write-Host "`n--- OWNER ---"
foreach ($t in "items", "item_prices", "stock_levels", "stock_movements") {
  $a = Hitung (Api $admin Get "${t}?select=*")
  $o = Hitung (Api $owner Get "${t}?select=*")
  if ($a -ge 0 -and $a -eq $o) { Write-Host "[PASS]  owner baca $t sama dengan admin ($o baris)" -ForegroundColor Green }
  else { $script:gagal++; Write-Host "[GAGAL] owner baca $t (admin=$a, owner=$o)" -ForegroundColor Red }
}
Cek "owner INSERT items ditolak"            (Api $owner Post "items" $itemBaru) "rls"
Cek "owner UPDATE items tanpa efek"         (Api $owner Patch "items?id=eq.$itemId" @{ name = "diubah owner" }) "tanpa-efek"
Cek "owner DELETE items tanpa efek"         (Api $owner Delete "items?id=eq.$itemId") "tanpa-efek"
Cek "owner INSERT stock_movements ditolak"  (Api $owner Post "stock_movements" (BodyMovement $itemId)) "rls"

Write-Host "`n--- Bersih-bersih (admin) ---"
Cek "admin bisa DELETE item uji" (Api $admin Delete "items?id=eq.$itemId") "ada"

Write-Host ""
if ($script:gagal -eq 0) { Write-Host "Semua tes lolos." -ForegroundColor Green }
else { Write-Host "$($script:gagal) tes gagal. Lihat detail merah di atas." -ForegroundColor Red }