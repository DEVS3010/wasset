# Wasset advertisement implementation report — 2026-10-11

## 1. Root cause

The checkout already contained the earlier `created_by` and 422 fixes. Those were verified rather than reimplemented. The historical listing bug was `AdModel.toEntity()` using `WassetUser.fromModel()`, whose `email!` assertion failed for `{id, name}` creators. HTTP success does not guarantee successful deserialization. Historical creation hazards also included `response!`, taking the first element of empty data, and `ApiService.post()` accessing a late response after an exception. Without a production stack trace, the exact historical 422 crash branch cannot be proven.

Current gaps: detailed `VerifyLicenseEntity` data only reaches the transient REGA preview, not the published `AdEntity`; `AdDetailsBody` omitted licensing fields and a map, printed nullable numeric values as `null`, and used horizontal contact text that could overflow. `AdModel.fromJson()` converted missing boolean fields to false. Preview contact labels incorrectly used the advertiser's name/phone instead of the separately modeled responsible employee.

## 2. Changes implemented

| File | Change |
|---|---|
| `lib/features/advertisement/data/models/ad_model.dart` | Preserve unknown optional booleans as null; accept bool and established 0/1 representations. |
| `lib/features/advertisement/data/models/ad_failure.dart` | Debug-only failure type/status diagnostics, with no response body, token or license logged by this handler. Existing useful-message and duplicate handling retained. |
| `lib/features/advertisement/presentation/advertiser_check/advertiser_check_page.dart` | Correct responsible-employee preview fields and expiration label; reject publication when verification identifiers are incomplete; remove raw verification error logging. No additional manual REGA fields. |
| `lib/features/advertisement/presentation/ad_details/widgets/ad_regulatory_details.dart` | New grouped RTL regulatory display, explicit missing values, required warning and existing Google Maps provider. Reject absent, nonfinite, out-of-range and placeholder (0,0) coordinates. |
| `lib/features/advertisement/presentation/ad_details/widgets/ad_details_body.dart` | Integrate regulatory groups; preserve images, descriptions and contact actions; wrap long location, price and creator text; avoid literal null presentation. |
| `test/features/advertisement/data/datasources/ad_datasource_test.dart` | Add custom 422 message and same-owner/different-license creation regressions. |
| `test/features/advertisement/presentation/ad_regulatory_details_test.dart` | Required labels, actual details body with minimal creator, long text, narrow RTL layout, missing values, boolean contract and coordinates. |
| `test/features/advertisement/presentation/advertisement_preview_test.dart` | Actual publish-screen error/snackbar, button re-enable and incomplete-verification regressions. |
| `docs/advertisement_requirements_audit.md` | Audit matrix recorded before implementation. |
| `docs/advertisement_acceptance.md` | Exact screenshot checklist, backend gaps and manual acceptance steps. |
| `docs/advertisement_validation.json` | Analyzer severity counts and comparison with untouched HEAD, by file/rule while ignoring shifted lines. |

Edit: no working edit route exists; `AdRepositoryImpl.updateAd` is unimplemented and no update contract/identity payload is documented. Navigation and authenticated user models were not changed. No notification files, backend code or dependencies were changed.

## 3. Required field audit

`V` means the verification endpoint model; it does **not** prove persistence in published ads. `L` means an existing legacy wizard field. All edit entries are pending an update contract. Published unavailable values display `غير متوفر`. The API column describes repository evidence, not an observed live response. `CONFIRM` means `NEEDS_BACKEND_CONFIRMATION`.

| Required field | Flutter model | API evidence | Published details | Add/Edit | Status |
|---|---|---|---|---|---|
| License number | advertisingLicenseNumber | advertising_license_number | Value | V + L / pending | DONE when supplied |
| Expiration | V.endDate | Verification only | Unavailable | V / pending | CONFIRM |
| Responsible mobile | V.responsibleEmployeePhoneNumber | Published contact_phone role unconfirmed | Unavailable; advertiser contact separate | V + L contact / pending | CONFIRM |
| Responsible name | V.responsibleEmployeeName | Published advertiser_name role unconfirmed | Unavailable; advertiser separate | V + L advertiser / pending | CONFIRM |
| Unit price | price | price | Value | V + L / pending | DONE when supplied |
| Property type | category.name | category | Value | V + L / pending | DONE when supplied |
| Plan number | V.planNumber | Verification only | Unavailable | V / pending | CONFIRM |
| Property age | propertyAge | property_age | Value | V + L / pending | DONE when supplied |
| Guarantees/duration | V.guaranteesAndTheirDuration | Published warranties is boolean only | Unavailable; boolean separate | V + L boolean / pending | CONFIRM |
| Usage | V.propertyUsages | Verification only | Unavailable | V / pending | CONFIRM |
| Plot number | V.landNumber | Verification only | Unavailable | V / pending | CONFIRM |
| Rooms | V.numberOfRooms | Verification only | Unavailable | V / pending | CONFIRM |
| Obligations | V.obligationsOnTheProperty | Published property_dispute is boolean only | Unavailable; dispute separate | V + L boolean / pending | CONFIRM |
| Area | landSpace | land_space | Value | V + L / pending | DONE when supplied |
| Frontage | facade | facade | Value | V + L / pending | DONE when supplied |
| Street width | V.streetWidth | Published streets_count is count only | Unavailable; count separate | V + L count / pending | CONFIRM |
| Services | electricityMeter/waterMeter/sewerage; V.propertyUtilities | Legacy booleans; full list verification only | Available booleans | V + L / pending | PARTIAL; CONFIRM full list |
| Deed location description | V.locationDescriptionOnMOJDeed | Verification only; extra_info is not deed text | Unavailable, before warning/map | V / pending | CONFIRM |
| Region | V.location.region | Verification only | Unavailable | V / pending | CONFIRM |
| District | neighborhood.name | neighborhood | Value | V + L / pending | DONE when supplied |
| City | city.name | city | Value | V + L / pending | DONE when supplied |
| Property title | No dedicated field | No established key | Unavailable | No new input / pending | CONFIRM |
| Property map | latitude/longitude | latitude/longitude | Valid property marker or missing state | V + L / pending | DONE when supplied |

No live published API response or backend schema was supplied; consequently this task cannot honestly classify the unresolved values as confirmed server omissions or declare full legal compliance. See the acceptance document for current published keys, missing properties and proposed reuse of existing verification names.

## 4. 422 / REGA result

Duplicate license wording maps to `هذه الرخصة مرتبطة بإعلان موجود بالفعل.`. Expired/invalid/custom validation errors retain the API's useful message. Service failures retain a useful backend message; network failure and malformed/null/message-less bodies use `تعذر إتمام الطلب. يرجى المحاولة مرة أخرى.`. HTTP 422 alone is not considered a duplicate.

Inspected create response/error handling does not assert nullable error values. Guarded file-path assertions are unrelated to the 422 branch. Datasource and actual publish-screen tests establish no null-check crash for the tested cases; they do not prove every possible live backend payload. Buttons remain usable after errors. Multiple ads for the same user with distinct valid licenses remain allowed.

## 5. created_by

Previously advertisement conversion depended on a full authenticated user with ID, name and email. Current `AdCreatorSummary` supports `{id: 111, name: "..."}`, a null creator, nullable contact/profile fields, and legacy complete creator responses. ID/name/phone/profile and profile name/phone/image are nullable in the summary. Authenticated-user requirements remain independent; no fake emails or phone values were introduced.

## 6. Existing-ad redirection

Not implemented. No observed duplicate response with a reliable owned advertisement ID or ownership-verifiable lookup is available. Backend must provide that documented contract. Existing navigation can use `Screens.adDetails` with an entity or query parameter `id` after identity and ownership are established.

## 7. Verification

- `flutter pub get`: passed, without dependency changes.
- `flutter test --no-pub`: 39 passed (38 advertisement tests plus the existing app widget test). Tests use constructed/mock payloads and do not publish production ads.
- `git diff --check`: passed.
- Untouched HEAD analyzed in a temporary snapshot using the same package configuration: 446 diagnostics (55 warnings, 391 info), zero errors.
- Final `flutter analyze --no-pub`: exit 1, 443 diagnostics (55 warnings, 388 info), zero errors. Source/test comparison with untouched HEAD: no new diagnostics and ten removed informational diagnostics. Seven informational dependency-order diagnostics occur in generated `build/` copies of `pay_platform_interface/pubspec.yaml`, absent from the clean snapshot. The repository is not lint-clean; existing warnings/info remain. See `advertisement_validation.json`.
- Default `flutter build apk --debug --no-pub`: failed at `processDevelopmentDebugGoogleServices`; configured Firebase has no client for `sa.morph.waseet1.dev`.
- `flutter build apk --debug --flavor production --no-pub`: passed. Artifact: `build/app/outputs/flutter-apk/app-production-debug.apk`. Existing Gradle/Kotlin/Java deprecation warnings remain.
- No Android device was connected. Live list/create/map integration was not run. No production data was mutated.

## 8. Screenshots

Follow the seven numbered captures in `advertisement_acceptance.md`: list; details license; property; deed; services; location/description/warning/map; duplicate validation. Details license capture must be opened from the list, covering navigation evidence. Split large sections into overlapping shots on small devices. Actual populated backend values are required for compliance approval; placeholders demonstrate missing-data handling only.

## 9. Remaining backend requirements

Document and persist verification information into listing/details, confirm responsible-employee versus advertiser roles, complete services, coordinate mapping, units and a dedicated title. Publish an update contract and a duplicate-ad ownership/identity contract. The acceptance document enumerates each field and established verification key; no guessed envelope or new request key was implemented.

## 10. Manual acceptance

Use the nine steps in `advertisement_acceptance.md`: minimal/null creator list→details; known data and narrow display; invalid/valid map; new license; second distinct license for same owner; duplicate; expired/invalid/outage; partial/malformed 422; fresh fetch/persistence and remaining edit gap.

## 11. Addendum — verification-envelope and crash hardening (2026-10-11, session 2)

All prior work above was preserved (nothing reverted). The referenced Postman
collections (`Waseet_Full_API_Postman_REGA_Test.json`, NHC collection) are not
present in the repository, so no endpoint contract could be re-verified from
them; endpoint conclusions below rest on code evidence plus the prior session's
documented fixtures.

Additional confirmed Flutter fixes (no new endpoints, keys, or backend claims):

| File | Change |
|---|---|
| `lib/features/advertisement/data/models/verify_license_response.dart` | `VerifyLicenseModel.fromMap` unwraps `result.advertisement` / `advertisement` / `data` envelopes so the Wasset `data` wrapper is never confused with the NHC advertisement object; all string/num/int/list casts are coercion-tolerant (numeric ids, numeric strings, non-string channel entries no longer throw). |
| `lib/features/advertisement/data/datasources/ad_datasource.dart` | `verifyLicense` accepts flat or nested payloads but still returns failure when no license identifiers are present (null/empty `data` cannot produce an empty preview). Previously the non-null `data` cast itself could throw. |
| `lib/res/api_service.dart` | `get`/`put`/`patch` use the same direct-response pattern as the earlier `post` fix; the `late Response` variables (LateInitializationError on any non-200 success, e.g. 201) and the unawaited 408 self-recursion are removed. `get` keeps its existing error-body contract; `put`/`patch` keep routing through `errorInterceptor`. |
| `lib/features/advertisement/data/models/ad_model.dart` | `toEntity()` maps a city object without an `id` to a null city instead of throwing `FormatException` and failing the whole list/details conversion. Advertisement `id` remains required. |
| `lib/features/user/data/models/home/cities_model.dart` | `created_at` uses `DateTime.tryParse(...toString())`; a malformed date no longer crashes advertisement conversion. |
| `lib/res/response/base_pagination.response.dart` | Non-map entries in list `data` (and non-map single `data`) are skipped instead of throwing on `as Map<String, dynamic>`. |
| `lib/features/advertisement/presentation/ad_details/widgets/ad_details_body.dart` | Unknown negotiability renders `غير متوفر` instead of the incorrect `غير قابل للتفاوض` (null vs false distinction). |
| `test/features/advertisement/data/datasources/ad_datasource_test.dart` | 8 new regressions: NHC envelope unwrap with coercions, flat numeric payload, 3 identifier-less failure shapes, city-without-id, malformed city date, malformed pagination entries. |

Verification (session 2):

- `flutter pub get`: passed, no dependency changes.
- `flutter test --no-pub`: 47 passed (46 advertisement + existing app widget test).
- `flutter test test/features/advertisement --no-pub`: 46 passed.
- `flutter analyze --no-pub`: 438 issues, zero errors; touched files carry only pre-existing infos plus two fixed line-length infos (no new diagnostics; `ad_datasource.dart:201` and `test:237` long lines are pre-existing).
- `git diff --check`: passed.
- `flutter build apk --debug --flavor production --no-pub`: passed (`build/app/outputs/flutter-apk/app-production-debug.apk`, only the pre-existing Kotlin-version warning). Default dev flavor still has no Firebase client for `sa.morph.waseet1.dev` — unchanged, not modified.
- Installed on emulator-5554 (`adb install -r`: Success); app process starts (pid observed) with no app FATAL in logcat (only unrelated systemui/bluetooth lines). In-app navigation and screenshots remain manual — see acceptance doc.
- Live API: BLOCKED. Base URL is production (`https://waseetco.sa/api/v1/`); no staging credentials, test license, or auth token available in-repo. No live requests were made; no production data mutated.

`updateAd` remains `UnimplementedError` by design: no verified update contract exists in-repo.

## 12. Addendum — advertisement price mapping (2026-10-13, session 3)

Root cause: the details header and all cards rendered only root `price`;
verified ads (e.g. 416, root `null`, regulatory `450000`) showed `غير متوفر`
(or literal `null` on cards) while the regulatory section showed the official
price. Fix: `AdvertisementPriceResolver` (new
`lib/features/advertisement/domain/entities/advertisement_price.dart`, pure
Dart) with precedence root → documented `land_total_price` (unit =
`property_price` per-m²) → regulatory `property_price` → unknown; zero,
negative, malformed = unknown; rentals never gain a period; no multiplication,
no category-name matching, no `extra_info` parsing. `land_total_price` added
to `RegaProperty` model/entity. Header, shared `AdCard` (all lists/favs/my
ads), and regulatory `سعر الوحدة` (grouped display, same official value) use
it; land ads gain `إجمالي سعر الأرض` + `سعر المتر المربع` rows only when a
documented total exists. Incidental: card price row `Flexible`+ellipsis and
feature-chips `SingleChildScrollView` stop narrow-screen overflow stripes.

Verification: 19 new tests
(`test/features/advertisement/domain/advertisement_price_test.dart`,
`.../presentation/advertisement_price_ui_test.dart`); full suite 93 passed;
analyze zero errors; production debug APK rebuilt/reinstalled on
Medium_Phone_API_36.0 (emulator-5554), no app FATAL. Live read-only deep-link
checks of production ads 416/415/414/412: headers `450,000` / `449,990` /
`2,000,007.62` / `42,000 ريال`, land rows `449,990` + `1,000 ريال/م²` and
`2,000,007.62` + `3,584.5 ريال/م²`, no invented rental period. Evidence:
`test_evidence/pricing/` (xml dumps + manager screenshots). SDK: repo pins
nothing; verified with 3.32.4 (matches `.dart_tool/package_config.json`).

Open pricing questions for the backend (Egyptian Arabic): rental billing
period field; confirm `property_price` = per-m² rate whenever `land_total_price`
is present; confirm zero must stay "unknown"; odd deed values on ad 416
(`1629 / م 2`) are displayed as-is. No duplicate root price fields requested.
Unrelated pre-existing issue: `AdCard` feature chips show placeholder
`landSpace`/`id` values with TODOs; map blankness (if any) untouched.
