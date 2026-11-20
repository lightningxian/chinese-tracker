# Trial day checklist (admin)

Build 8, "Then". For the person who runs the trial at the centre.

## A week before

- [ ] Live accounts made with `py -I scripts/seed_trial.py live --credentials …`
      (dry run first); passwords printed and put in sealed envelopes, one per
      respondent (from `scripts/trial/passwords.local.json`, never committed).
- [ ] The 731 questions are in (`docs/TRIAL_KIT.md` §5: every row "done").
- [ ] Test codes made for every level, plus the two extra HSK 3 codes.
- [ ] Teachers confirmed their schedules (Jadwal → Minggu).
- [ ] Midtrans is in **sandbox** mode (never production keys before MT-05).
- [ ] Print: 30 student task sheets, 4 teacher, 1 admin, 35 SUS forms
      (`docs/trial/*.html`, print from the browser on A4).

## On the day

- [ ] Wi-Fi works for 35 devices; the room has power for chargers.
- [ ] Devices: students bring their phones (web app added to the home screen
      from the browser) or use the centre's computers; one spare device.
- [ ] Each respondent signs in once with their envelope password.
- [ ] Order: 1 admin approvals → 2 teachers confirm and start sessions →
      3 students book, practise, sit the test with the token → 4 teachers
      close the sessions and mark → 5 admin dashboard, promotion, payments,
      monthly report → 6 everyone fills the SUS form.
- [ ] One helper writes the black-box results (`docs/trial/blackbox_template.md`).

## After

- [ ] Type the SUS forms into `docs/trial/sus_results.csv` (template:
      `sus_results_template.csv`) and run `node tool/sus_score.mjs docs/trial/sus_results.csv`.
- [ ] Org settings → **Cek voucher** (VC-05) and the Midtrans sandbox
      dashboard check (MT-05).
- [ ] Laporan → Laporan bulanan → Hitung ulang for the trial month.
