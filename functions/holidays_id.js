"use strict";

/**
 * Indonesian national holidays (libur nasional) and joint leave days (cuti
 * bersama), owner request 2026-11-23: the admin sees them on the calendar
 * and decides per day whether the centre opens.
 *
 * Source, copied from the official pages (never typed from memory):
 * - 2027: SKB 3 Menteri Nomor 1205, 3, 2 Tahun 2026, as published on
 *   setneg.go.id "Inilah SKB 3 Menteri Libur Nasional dan Cuti Bersama
 *   2027" (15 September 2026): 18 libur nasional, 8 cuti bersama.
 *   Isra Mikraj falls twice in 2027 (5 January and 26 December).
 * - December 2026: SKB 3 Menteri Nomor 1497, 2, 5 Tahun 2025 (Natal on
 *   25 December, cuti bersama on 24 December).
 * A new year's list is added here when its SKB is out; the admin can also
 * add a centre day by hand on the calendar.
 */
const HOLIDAYS = [
  ["2026-12-24", "cuti_bersama", "Cuti Bersama Kelahiran Yesus Kristus (Natal)"],
  ["2026-12-25", "national", "Kelahiran Yesus Kristus (Natal)"],
  ["2027-01-01", "national", "Tahun Baru 2027 Masehi"],
  ["2027-01-05", "national", "Isra Mikraj Nabi Muhammad SAW"],
  ["2027-02-05", "cuti_bersama", "Cuti Bersama Tahun Baru Imlek 2578 Kongzili"],
  ["2027-02-06", "national", "Tahun Baru Imlek 2578 Kongzili"],
  ["2027-03-08", "national", "Hari Suci Nyepi (Tahun Baru Saka 1949)"],
  ["2027-03-09", "cuti_bersama", "Cuti Bersama Idulfitri 1448 Hijriah"],
  ["2027-03-10", "national", "Idulfitri 1448 Hijriah"],
  ["2027-03-11", "national", "Idulfitri 1448 Hijriah"],
  ["2027-03-12", "cuti_bersama", "Cuti Bersama Idulfitri 1448 Hijriah"],
  ["2027-03-15", "cuti_bersama", "Cuti Bersama Idulfitri 1448 Hijriah"],
  ["2027-03-25", "cuti_bersama", "Cuti Bersama Wafat Yesus Kristus"],
  ["2027-03-26", "national", "Wafat Yesus Kristus"],
  ["2027-03-28", "national", "Hari Kebangkitan Yesus Kristus (Paskah)"],
  ["2027-05-01", "national", "Hari Buruh Internasional"],
  ["2027-05-06", "national", "Kenaikan Yesus Kristus"],
  ["2027-05-17", "national", "Iduladha 1448 Hijriah"],
  ["2027-05-18", "cuti_bersama", "Cuti Bersama Iduladha 1448 Hijriah"],
  ["2027-05-19", "cuti_bersama", "Cuti Bersama Waisak 2571 BE"],
  ["2027-05-20", "national", "Hari Raya Waisak 2571 BE"],
  ["2027-06-01", "national", "Hari Lahir Pancasila"],
  ["2027-06-06", "national", "1 Muharam Tahun Baru Islam 1449 Hijriah"],
  ["2027-08-15", "national", "Maulid Nabi Muhammad SAW"],
  ["2027-08-17", "national", "Proklamasi Kemerdekaan"],
  ["2027-12-24", "cuti_bersama", "Cuti Bersama Kelahiran Yesus Kristus (Natal)"],
  ["2027-12-25", "national", "Kelahiran Yesus Kristus (Natal)"],
  ["2027-12-26", "national", "Isra Mikraj Nabi Muhammad SAW"],
];

/** The holidays on or after [fromDate] (`YYYY-MM-DD`) as plain objects. */
function holidaysFrom(fromDate, list = HOLIDAYS) {
  return list.filter(([d]) => d >= fromDate).map(([date, kind, name]) => ({date, kind, name}));
}

module.exports = {HOLIDAYS, holidaysFrom};
