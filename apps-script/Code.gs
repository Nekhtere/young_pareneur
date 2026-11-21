/**
 * Apps Script — email tiket Acara Puncak Forum Batam 2026.
 * Deploy sebagai Web App: Execute as "Me", Who has access "Anyone".
 * Lihat README.md untuk setup.
 */

var SCRIPT_SECRET = PropertiesService.getScriptProperties().getProperty('SCRIPT_SECRET') || '';
var SUPABASE_URL = PropertiesService.getScriptProperties().getProperty('SUPABASE_URL') || '';
var SUPABASE_SERVICE_KEY = PropertiesService.getScriptProperties().getProperty('SUPABASE_SERVICE_KEY') || '';

// ---------- KONFIGURASI TAMPILAN TIKET ----------
var CFG = {
  judulBaris1: 'Business Growth & Digital',
  judulBaris2: 'Readiness Forum Batam 2026',
  waLink: 'https://chat.whatsapp.com/LczP3SJHP2aKeCa7XxJXr5',
  panitia: [
    { nama: 'Bapak Adi', wa: '0852 6615 7631' },
    { nama: 'Ibu Dewi', wa: '0812 7747 387' },
    { nama: 'Ahmad Hafiz Habibie Purba', wa: '0895 3764 48353' },
    { nama: 'Rafi Ikhwansyah', wa: '0821 7243 4429' },
    { nama: 'Andri Yani Meuraxa', wa: '0823 8327 6076' },
    { nama: 'Alendea Resta Amaira', wa: '0856 6902 5240' }
  ],
  // Opsional: isi Script Property LOGO_URL dengan URL gambar strip logo (https, publik).
  // Jika kosong, ditampilkan nama penyelenggara dalam teks.
  logoUrl: PropertiesService.getScriptProperties().getProperty('LOGO_URL') || '',
  penyelenggara: ['Pemerintah Provinsi Kepulauan Riau', 'DKUKM Kepri', 'Inovasi Strategi Konsultan', 'Lembaga Inkubator Bisnis Merah Putih', 'Koperasi Inovasi Bisnis Sejahtera']
};

var C = {
  navy: '#0B1B47',
  navyText: '#12214D',
  gold: '#C9A25F',
  bg: '#F1EEE9',
  muted: '#5B6482',
  soft: '#D6DCEE'
};

function doGet(e) {
  var p = e.parameter || {};
  var cb = /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(p.callback || '') ? p.callback : 'cb';

  if (!SCRIPT_SECRET || p.secret !== SCRIPT_SECRET) {
    return jsonp(cb, { ok: false, error: 'UNAUTHORIZED' });
  }
  var kode = String(p.kode || '').trim();
  if (!kode) return jsonp(cb, { ok: false, error: 'NO_CODE' });

  var d = getTicket(kode);
  if (!d) return jsonp(cb, { ok: false, error: 'NOT_FOUND_OR_PENDING' });

  try {
    var html = buildTicketHtml(d);
    GmailApp.sendEmail(d.email, '[Acara Puncak] Tiket Anda - ' + d.kode,
      'Screenshot email ini dan tunjukkan di meja registrasi.', { htmlBody: html });
    return jsonp(cb, { ok: true });
  } catch (err) {
    return jsonp(cb, { ok: false, error: String((err && err.message) || err) });
  }
}

function jsonp(cb, obj) {
  return ContentService.createTextOutput(cb + '(' + JSON.stringify(obj) + ');')
    .setMimeType(ContentService.MimeType.JAVASCRIPT);
}

function getTicket(kode) {
  if (!SUPABASE_SERVICE_KEY) return null;
  var url = SUPABASE_URL.replace(/\/$/, '') + '/rest/v1/rpc/ticket_payload';
  var res = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    headers: {
      apikey: SUPABASE_SERVICE_KEY,
      Authorization: 'Bearer ' + SUPABASE_SERVICE_KEY
    },
    payload: JSON.stringify({ p_kode: kode }),
    muteHttpExceptions: true
  });
  if (res.getResponseCode() !== 200) return null;
  return JSON.parse(res.getContentText() || 'null') || null;
}

function esc(v) {
  return String(v == null ? '-' : v)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function waNum(s) {
  var d = String(s || '').replace(/\D/g, '');
  if (d.indexOf('0') === 0) d = '62' + d.slice(1);
  return d;
}

function buildTicketHtml(d) {
  var FONT = 'Arial,Helvetica,sans-serif';
  var h = [];
  var firstName = String(d.nama || '').split(/\s+/)[0];
  var jam = d.waktu || '14.00-17.00 WIB';
  var tempat = d.tempat || 'Hotel Golden View Batam';
  var tanggal = d.tanggal || 'Jumat, 27 November 2026';

  h.push('<!doctype html><html><head><meta charset="utf-8">');
  h.push('<meta name="viewport" content="width=device-width,initial-scale=1">');
  h.push('<style>');
  h.push('table{border-collapse:collapse}img{max-width:100%;height:auto;border:0;display:block}');
  h.push('.wrap{width:100%;max-width:600px}');
  h.push('.title{font-size:25px;line-height:1.2}');
  h.push('.kode{font-size:18px;word-break:break-word}');
  h.push('.val{word-break:break-word}');
  h.push('.pan{font-size:13px;line-height:1.9}');
  h.push('@media only screen and (max-width:480px){');
  h.push('.headpad{padding:22px 18px 24px 18px!important}');
  h.push('.title{font-size:21px!important}');
  h.push('.cardrow{padding:26px 12px 6px 12px!important}');
  h.push('.cardpad{padding:20px 18px!important}');
  h.push('.infopad{padding:16px 18px 0 18px!important}');
  h.push('.pan{font-size:12px!important;line-height:1.7!important}');
  h.push('.kode{font-size:16px!important}');
  h.push('}</style></head>');

  h.push('<body style="margin:0;padding:0;background:' + C.bg + ';font-family:' + FONT + ';color:' + C.navyText + '">');
  h.push('<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" bgcolor="' + C.bg + '" style="background:' + C.bg + '"><tr><td align="center">');
  h.push('<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" class="wrap" style="max-width:600px;background:' + C.bg + '">');

  // ===== HEADER: navy + garis emas di kanan =====
  h.push('<tr><td bgcolor="' + C.navy + '" style="background:' + C.navy + '">');
  h.push('<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%"><tr>');
  h.push('<td class="headpad" style="padding:26px 24px 30px 30px" valign="top">');
  h.push('<div style="color:' + C.gold + ';font-size:11px;font-weight:700;word-break:break-word">' + esc(tanggal) + ' &nbsp;|&nbsp; ' + esc(tempat) + '</div>');
  h.push('<div class="title" style="color:#ffffff;font-size:25px;font-weight:700;margin-top:14px">' + esc(CFG.judulBaris1) + '<br>' + esc(CFG.judulBaris2) + '</div>');
  h.push('</td>');
  h.push('<td width="22" valign="top" style="padding:0 16px 0 0"><div style="background:' + C.gold + ';width:6px;height:82px;font-size:0;line-height:0">&nbsp;</div></td>');
  h.push('</tr></table>');
  h.push('</td></tr>');

  // ===== KARTU: sisi kiri emas tebal, isi navy =====
  h.push('<tr><td class="cardrow" style="padding:34px 20px 6px 20px">');
  h.push('<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" bgcolor="' + C.navy + '" style="background:' + C.navy + ';border-left:16px solid ' + C.gold + ';border-radius:0 12px 12px 0"><tr><td class="cardpad" style="padding:26px 26px 22px 26px">');

  h.push('<div class="val" style="color:#ffffff;font-size:21px;font-weight:700">Terima kasih, ' + esc(firstName) + '!</div>');
  h.push('<div style="color:' + C.soft + ';font-size:13px;margin-top:6px">Pendaftaran Anda telah disetujui.</div>');

  var rows = [
    ['Peserta', esc(d.nama) + ' - ' + esc(d.jabatan)],
    ['Usaha', esc(d.usaha) + ' - ' + esc(d.bidang)],
    ['Waktu', esc(jam)]
  ];
  for (var i = 0; i < rows.length; i++) {
    h.push('<div style="color:' + C.gold + ';font-size:11px;font-weight:700;margin-top:20px">' + rows[i][0] + '</div>');
    h.push('<div class="val" style="color:#ffffff;font-size:14px;font-weight:700;margin-top:4px;line-height:1.4">' + rows[i][1] + '</div>');
  }

  h.push('<div style="border-top:1px dashed #7887B4;margin-top:24px;font-size:0;line-height:0">&nbsp;</div>');
  h.push('<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin-top:16px"><tr>');
  h.push('<td valign="middle" style="color:' + C.soft + ';font-size:13px">Kode pendaftaran</td>');
  h.push('<td valign="middle" align="right" class="kode" style="color:' + C.gold + ';font-size:18px;font-weight:700">' + esc(d.kode) + '</td>');
  h.push('</tr></table>');

  h.push('</td></tr></table>');
  h.push('</td></tr>');

  // ===== INFO REGISTRASI =====
  h.push('<tr><td class="infopad" style="padding:18px 32px 0 32px">');
  h.push('<div style="font-size:14px;color:' + C.navyText + ';line-height:1.5">Acara diselenggarakan pukul ' + esc(jam) + ' di ' + esc(tempat) + '.</div>');
  h.push('<div style="font-size:13px;color:' + C.muted + ';margin-top:5px">Screenshot email ini dan tunjukkan di meja registrasi.</div>');
  h.push('</td></tr>');

  // ===== PANITIA =====
  h.push('<tr><td class="infopad" style="padding:24px 32px 0 32px">');
  h.push('<div style="font-size:14px;font-weight:700;color:' + C.navyText + '">Panitia - hubungi bila ada kendala</div>');
  h.push('<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin-top:8px">');
  for (var p = 0; p < CFG.panitia.length; p++) {
    var orang = CFG.panitia[p];
    h.push('<tr><td width="55%" class="pan" style="color:' + C.navyText + '">' + esc(orang.nama) + '</td>');
    h.push('<td width="45%" align="right" class="pan"><a href="https://wa.me/' + waNum(orang.wa) + '" style="color:' + C.navyText + ';text-decoration:none">' + esc(orang.wa) + '</a></td></tr>');
  }
  h.push('</table>');
  h.push('</td></tr>');

  // ===== TOMBOL GRUP WHATSAPP =====
  h.push('<tr><td style="padding:24px 20px 0 20px">');
  h.push('<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" bgcolor="' + C.navy + '" style="background:' + C.navy + ';border-radius:10px"><tr><td align="center" style="padding:16px">');
  h.push('<a href="' + esc(CFG.waLink) + '" style="text-decoration:none;display:block;color:#ffffff;font-size:16px;font-weight:700">Join grup WhatsApp peserta</a>');
  h.push('<div style="color:' + C.gold + ';font-size:12px;margin-top:6px;word-break:break-all">' + esc(CFG.waLink.replace(/^https?:\/\//, '')) + '</div>');
  h.push('</td></tr></table>');
  h.push('</td></tr>');

  // ===== PENYELENGGARA =====
  h.push('<tr><td style="padding:30px 20px 34px 20px">');
  h.push('<div style="font-size:12px;color:' + C.muted + ';padding:0 12px 8px 12px">Diselenggarakan bersama</div>');
  h.push('<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" bgcolor="#ffffff" style="background:#ffffff;border-radius:14px"><tr><td align="center" style="padding:18px 14px">');
  if (CFG.logoUrl) {
    h.push('<img src="' + esc(CFG.logoUrl) + '" alt="Penyelenggara" style="max-width:100%;height:auto;display:block;border:0">');
  } else {
    var names = [];
    for (var j = 0; j < CFG.penyelenggara.length; j++) names.push(esc(CFG.penyelenggara[j]));
    h.push('<div style="font-size:12px;font-weight:700;color:' + C.navyText + ';line-height:1.8">' + names.join(' &nbsp;&middot;&nbsp; ') + '</div>');
  }
  h.push('</td></tr></table>');
  h.push('</td></tr>');

  h.push('</table>');
  h.push('</td></tr></table>');
  h.push('</body></html>');
  return h.join('');
}
