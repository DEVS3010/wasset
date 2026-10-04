# Advertisement bug investigation

## Root causes and evidence

**Listing:** `AdDatasource.getAds()` parses `AdResponse`, then calls `AdModel.toEntity()`. Previously that called `WassetUser.fromModel()`, which asserts `entity.id!`, `entity.email!`, and `entity.name!`. A creator containing only `{id, name}` therefore throws at `entity.email!`, despite HTTP 200. The datasource converts that exception to `ResourceError`; `AdvertisementsCubit.init()` consequently enters its error state. `getFavAds()` and creation use the same conversion.

**Creation:** `AdDatasource.createAdWithVerification()` and `createAd()` used the same full-user conversion, so a successful response with a minimal creator produces the same null assertion. They also asserted `response!`. `ApiService.post()` used a late response variable, while `errorInterceptor()` discarded validation details by throwing a plain `Exception(message)`. A response-less/network or non-map error could leave that variable uninitialized. This produces a separate `LateInitializationError`, rather than the reported null assertion. Nullable bodies and empty data lists were additional unsafe paths.

These causes are established from the code and regression fixtures. No production stack trace or captured backend response was supplied, so the exact branch taken by the reported production creation incident cannot be confirmed.

## Architecture and contract evidence

The active `Screens.addNewAd` route opens `AdvertiserCheckPage`. `_search()` calls `AdRepository.verifyLicense()`; `AdvertisementPreviewPage` then calls `createAdWithVerification()`. `AdRepositoryImpl` forwards to `AdDatasource`, which builds multipart requests through `ApiService`/Dio. The older wizard uses `AddNewAdCubit` and `AddAdRequest`. No Retrofit, Freezed, or generated advertisement serializers participate.

Existing request keys and endpoints were preserved:

- `POST /advertisements/verify-license`: `advertiserId`, `adLicenseNumber`.
- `POST /advertisements/create-with-verification`: those fields, optional `extra_info`, and indexed `attachment_files`.
- The legacy wizard posts its existing snake-case payload to `/advertisements`.
- Listing/details use `GET /advertisements`, including existing filters.

The existing `AdResponse` expects `data` to be an advertisement object or list, with optional `status`, `message`, `errors`, `meta`, and `links`. The supplied new creator contract is `{ "id": 111, "name": "User" }`. The legacy user parser supports optional email, phone, profile, type, and gender, but its authenticated entity conversion requires identity/email/name.

No stored/runtime duplicate 422 response, error identifier, or existing-ad ownership payload was found. The following are **constructed regression fixtures**, not observed production responses:

```json
{"data":{"id":10,"created_by":{"id":111,"name":"User"}}}
```

```json
{"message":"Validation failed","errors":{"adLicenseNumber":["The license has already been taken."]}}
```

Other fixtures cover expired/invalid/service Arabic messages, `{ "message": null, "data": null, "errors": null }`, missing bodies, non-map bodies, and empty data arrays.

Dio's existing default status validation rejects 422. `receiveDataWhenStatusError = true` retains its body. The updated existing interceptor converts it into `ApiFailure`, preserving status and validation fields; datasource failures still use the existing `ResourceError` architecture.

## Changes by file

| File | Change and reason |
|---|---|
| `lib/res/api_service.dart` | Return the awaited POST response directly; route failures through the existing interceptor. Removes uninitialized response access and preserves failure information. |
| `lib/res/api_failure.dart` | Typed exception used by that interceptor, with nullable-body parsing, meaningful messages, status, validation fields, and an Arabic fallback. |
| `lib/features/advertisement/data/models/ad_failure.dart` | Advertisement-specific license message selection, returning the established `ResourceError` type. |
| `lib/features/advertisement/domain/entities/ad_creator_summary.dart` | Optional creator identity/name/contact summary with optional legacy profile presentation fields. |
| `lib/features/advertisement/data/models/ad_model.dart` | Parse the summary directly; preserve required advertisement/city identity; allow absent city presentation image/name. |
| `lib/features/advertisement/domain/entities/ad_entity.dart` | Store the creator summary instead of an authenticated user. |
| `lib/features/advertisement/data/datasources/ad_datasource.dart` | Guard missing bodies/data and empty single-result arrays, preserve API failure details, use safe fallback messages, and remove upload debug logs. |
| `lib/features/advertisement/presentation/advertiser_check/advertiser_check_page.dart` | Guard concurrent submissions and mounted contexts after requests; remove forced error-state casts. |
| `lib/features/advertisement/presentation/add_new_ad/cubit/add_new_ad_cubit.dart` | Guard concurrent submissions and empty selector lists; keep unexpected exception diagnostics out of user messages. |
| `lib/features/advertisement/presentation/advertisements/cubit/advertisements_cubit.dart` | Allow absent category/neighborhood/city during filters and search. |
| `lib/features/advertisement/presentation/ad_details/widgets/ad_details_body.dart` | Guard absent advertisement/creator/contact values; use available advertisement or creator contact information. |
| `lib/features/advertisement/presentation/my_ads/widgets/ad_card.dart` | Only create a chat when the creator ID exists. |
| `test/features/advertisement/data/datasources/ad_datasource_test.dart` | Model, datasource, validation, network, Arabic text, and interceptor regressions. |
| `test/features/advertisement/presentation/advertisement_state_test.dart` | Listing loaded state and creation success/error lifecycle with a concurrent-request guard. |

## Model and null-safety decision

No existing suitable creator-summary type was found. `AdCreatorSummary` keeps the endpoint's reference separate from `WassetUser`, preserving the authenticated user's required fields. Its optional profile contains only the name, phone, and image used by advertisement UI. Legacy full creators remain compatible; unrelated user/profile data is intentionally outside this summary.

Advertisement operations no longer assert a missing response, convert creators through required user email/name assertions, or read the first item of an empty single-result array. Creator phone/ID and absent details are guarded in UI. Optional filter objects use nullable access. Missing presentation images use an empty presentation value; missing advertisement or provided-city identity remains a parsing failure rather than fabricated identity.

Existing assertions backed by checks or required identity were retained. The patch does not make all domain fields nullable.

## Duplicate license behavior and navigation

`adFailure()` first inspects `errors.adLicenseNumber` or the existing legacy `advertising_license_number` key. It requires duplicate wording, rather than treating any license-field validation error as duplication. Otherwise it checks license-related duplicate wording in the API message. English and Arabic variants are supported. No undocumented backend error code is assumed, and HTTP 422 alone never selects the duplicate message.

The displayed duplicate message is exactly:

> هذه الرخصة مرتبطة بإعلان موجود بالفعل.

Other field-specific validation messages are preferred; otherwise the meaningful API message is retained. Missing useful messages fall back to:

> تعذر إتمام الطلب. يرجى المحاولة مرة أخرى.

There is no user-wide advertisement limit. No existing-ad navigation was added: it requires a verified existing advertisement ID and ownership evidence, or an ID whose ownership can be confirmed safely through the existing repository. Neither is present in the available response evidence. No advertisement ID or ownership was invented.

## Verification

- Original test suite before new tests: 1 test passed.
- Final `flutter test`: 27 tests passed, including 26 new regression cases.
- Coverage includes valid creation; duplicate, expired, invalid, service, network and incomplete errors; null/missing/id-only/name-only/minimal/legacy creators; nullable attachments/profile image/city image; required identity rejection; multiple advertisements reaching loaded state; and creation success/error plus repeated submission.
- Final `flutter analyze`: exit 1, 449 issues (55 warnings, 394 informational diagnostics), no errors. Untouched `HEAD` analyzed in a temporary snapshot with the same package configuration: 452 existing issues, no errors. Comparing diagnostic messages/rules per file while ignoring shifted line numbers shows no new source/test diagnostics and six removed existing diagnostics. The live workspace additionally contains three informational dependency-order diagnostics in pre-existing build output, absent from the clean snapshot. Existing lint issues were not broadly fixed.
- `git diff --check` passes. Every tracked diff and new source/test file was reviewed. No advertisement code generation is required.

## Remaining risks

The exact production duplicate code/message is unverified; a new wording or undocumented structured identifier may require an explicit mapping after capturing a real response. Tests use constructed payloads and do not prove the live REGA/NHC integration. The existing listing still requires its auxiliary cities/categories/favorites requests to succeed. Malformed required identity remains a failure by design. The common POST/interceptor fix also improves other callers' failures, but those features were not exhaustively integration-tested.

## Git summary

Modified: nine existing Dart files listed above.

Added: three production Dart files, two regression-test files, and this report.

No backend files changed. No unrelated UI redesign, dependency changes, generated files, commit, or push.
