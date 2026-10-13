# Advertisement acceptance and project-manager screenshots

Use staging/test accounts and licenses for submission tests. No production advertisement was created by this task. Screenshots with `غير متوفر` demonstrate safe missing-data handling, **not regulatory compliance**. Capture final compliance evidence again once the published API returns the missing persisted values.

## Exact screenshot checklist

1. **Advertisements list.** Sign in with an account whose home shows **الاعلانات** → tap **الاعلانات** → **جميع الاعلانات**. Capture the tab title and at least two loaded cards, preferably two owned by the same test user. No scroll if cards are already visible; otherwise scroll until the chosen card is visible. Use a captured GET response with `created_by: {id, name}` to accompany this screenshot: the image alone cannot prove the backend response shape.
2. **Published details / license information, opened from that list.** Tap the chosen card from screenshot 1 → scroll to **معلومات الترخيص**. Capture **رقم ترخيص الإعلان**, **تاريخ انتهاء رخصة الإعلان**, **اسم مسؤول الإعلان**, **رقم جوال مسؤول الإعلان** and their values. Include enough of the property header to match the list card when possible. This is also the required list-to-details navigation screenshot; a separate identical details capture is unnecessary.
3. **Published details / property information.** Continue on the same ad → scroll to **معلومات العقار**. Capture **عنوان العقار**, **نوع العقار**, **سعر الوحدة**, **عمر العقار**, **استخدام العقار**, **مساحة العقار**, **عدد الغرف**. This proves type/price plus the property requirements and exposes missing data. Split into two overlapping captures if the viewport cannot show the complete section.
4. **Published details / land and deed.** Continue scrolling to **معلومات الأرض والصك**. Capture **رقم المخطط**, **رقم القطعة**, **واجهة العقار**, **عرض الشارع**, **الضمانات ومدتها**, **الالتزامات الأخرى على العقار**. Include **عدد الشوارع**, **وجود ضمانات**, **وجود نزاع على العقار** when possible to show these distinct meanings are not substituted for width/duration/obligations. Split with overlap if necessary.
5. **Published details / services.** Scroll to **خدمات العقار**. Capture electricity meter, water meter and sewerage values. These prove the services presently available in the legacy contract; confirm the backend's complete `propertyUtilities` list before treating this as the full regulatory services requirement.
6. **Published details / location and map order.** Scroll so **المنطقة**, **المدينة**, **الحي**, **وصف موقع العقار حسب الصك** appear above **نأمل مطابقة الموقع أدناه مع الموقع المذكور في وصف موقع العقار المكتوب**, followed by the property marker/map. Use a real test property's known coordinates and confirm its marker. On a small device, take two overlapping captures: first location fields + deed description + warning + top of map, second warning + complete map. This proves the required order. If coordinates are absent, separately capture **موقع العقار غير متوفر**; that is a missing-location test, not a compliant map screenshot.
7. **Duplicate license validation in the creation flow.** Sign in as a broker (وسيط) → home **+**, or your empty **مكتبي** ads section → **اضف اعلان جديد** → enter **رقم الهوية / المنشأة** and the already active **رقم الترخيص** → **التالي**. If verification succeeds, scroll the preview to **تأكيد ونشر الإعلان** and tap it. Capture **هذه الرخصة مرتبطة بإعلان موجود بالفعل.** in the snackbar, with the creation/preview screen and usable button still visible. The snackbar lasts three seconds; capture immediately. If the backend rejects duplication at verification, capture the error on the initial check page instead. Do this on staging, where test submissions are authorized.

The original A/B/C requests are split because the actual screen uses vertical, wrapping sections. Screenshot 2 covers both license information and navigation from the list; screenshot 3 covers its price/type requirement. This avoids squeezing unreadable sections into a single capture.

## Manual acceptance test plan

1. On staging, load advertisements with minimal `created_by` and then a null creator. Expect loaded cards; open each card and expect safe details/contact placeholders. Capture screenshot 1 then 2.
2. Open an ad containing known legacy price, type, age, area, frontage, city, district, and services. Expect the corresponding values under screenshots 3–6, without literal `null`, overflow, or invented data.
3. Test null, NaN/infinite and out-of-range coordinates through a staging fixture. Expect **موقع العقار غير متوفر** and no Google Map. Test known valid coordinates; expect the property marker, not the viewer's location. Check deed description → exact warning → map.
4. Create an ad using a new valid test license. Expect success, a new list item, and data surviving a fresh fetch. This requires actual backend support for each published field; do not accept preview-only values as persistence evidence.
5. Create another ad for the same test owner with a different valid license. Expect another successful creation, with no user-wide limit.
6. Submit an active duplicate license. Expect the Arabic duplicate message, unchanged usable form and no crash. Capture screenshot 7.
7. Submit expired and invalid test licenses. Expect the backend's specific messages. Simulate a service outage/network loss; expect the useful backend message or **تعذر إتمام الطلب. يرجى المحاولة مرة أخرى.**
8. Using mocked/staging responses, return 422 with a custom message, no message, null errors, malformed HTML, and incomplete verification identifiers. Expect safe messages; incomplete verification must not submit an empty license. Retry after a failure and verify the button is enabled.
9. Close/reopen details and refresh the list. Expect persisted published values to survive; enumerate anything that still displays **غير متوفر** before project-manager approval. Edit acceptance remains pending: there is no working advertisement edit route or documented update contract in this repository.

## Published backend contract work still needed

Current Flutter published schema is `GET /api/v1/advertisements` and the existing get-by-ID filtering of that endpoint. No live response capture was available. The detailed values below exist in the verification endpoint model, but no persisted published mapping is established. These are **contract-confirmation gaps**, not a claim that an inspected live server omitted them.

| Requirement | Current published Flutter contract | Existing verification key to reuse after backend agreement |
|---|---|---|
| Expiration | none | `endDate` |
| Responsible employee | generic `advertiser_name` / `contact_phone`; role unconfirmed | `responsibleEmployeeName` / `responsibleEmployeePhoneNumber` |
| Plan / plot | none | `planNumber` / `landNumber` |
| Rooms | none | `numberOfRooms` |
| Usage | advertisement sale/rental type is not property usage | `propertyUsages` / `mainLandUseTypeName` |
| Guarantees and duration | `warranties` boolean only | `guaranteesAndTheirDuration` |
| Obligations | `property_dispute` boolean only | `obligationsOnTheProperty` |
| Street width | `streets_count` counts streets | `streetWidth` |
| Full services | meter/sewerage booleans only | `propertyUtilities` |
| Deed location description | `extra_info` is general text | `locationDescriptionOnMOJDeed` |
| Region | no published region | `location.region` |
| Property title | no dedicated field in either existing model | agree a dedicated title field, e.g. `title` (proposal only) |

Backend should persist verified data during creation and expose it consistently on listing/detail fetches, with documented nullability/envelope, coordinate mapping and price/area units. Confirm whether existing license/advertiser/contact fields are exact licensing equivalents. Do not send these proposed mappings from Flutter until the published/update contract is confirmed.

Safe duplicate navigation additionally needs a documented existing advertisement ID and current-user ownership evidence (or an ownership-verifiable lookup). An arbitrary response `id` is not sufficient. The existing route is `Screens.adDetails`, accepting an `AdEntity` or query parameter `id`.

For editing, provide a supported endpoint/method, advertisement identity, allowed manual fields and rules for re-verification. `AdRepositoryImpl.updateAd` currently throws `UnimplementedError`; no edit route is wired. No fabricated update endpoint or duplicate manual REGA fields were introduced.
