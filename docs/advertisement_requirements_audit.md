# Pre-implementation audit (2026-10-11)

The repository already contains the earlier creator-summary and typed 422 fixes. Working tree was clean. No backend source, OpenAPI schema, live response capture, or advertisement edit route is present. Do not infer a published response envelope from the verification endpoint.

| Required field | UI/request | Published response/model | Details before | Status |
|---|---|---|---|---|
| License | verification adLicenseNumber; legacy advertising_license_number | advertising_license_number / advertisingLicenseNumber | absent | EXISTS_NOT_DISPLAYED |
| Expiration | REGA endDate | no established published key | absent | NEEDS_VERIFICATION |
| Responsible name/mobile | verification responsibleEmployeeName/PhoneNumber; legacy advertiser_name/contact_phone | advertiser_name/contact_phone; role equivalence unconfirmed | generic contact only | NEEDS_VERIFICATION |
| Unit price/type | legacy price/category_id; verification propertyPrice/propertyType | price/category | present | EXISTS_AND_OK |
| Age/area/frontage | legacy property_age/land_space/facade | matching model fields | present; null text unsafe presentation | EXISTS_BUT_BROKEN |
| Plan/plot/rooms/usage | REGA planNumber/landNumber/numberOfRooms/propertyUsages | absent from established published model | absent | NEEDS_VERIFICATION |
| Guarantees/duration | REGA guaranteesAndTheirDuration; legacy warranties boolean | warranties boolean only | absent | NEEDS_VERIFICATION |
| Obligations | REGA obligationsOnTheProperty; legacy property_dispute boolean | propertyDispute boolean only | absent | NEEDS_VERIFICATION |
| Street width | REGA streetWidth; legacy streets_count is count, not width | no width | absent | NEEDS_VERIFICATION |
| Services | REGA propertyUtilities; legacy meters/sewerage booleans | electricityMeter/waterMeter/sewerage | present; missing becomes false | EXISTS_BUT_BROKEN |
| Deed description/region | REGA locationDescriptionOnMOJDeed/location.region | absent | absent | NEEDS_VERIFICATION |
| City/district | legacy city_id/neighborhood_id; REGA location | city/neighborhood entities | present | EXISTS_AND_OK |
| Title | no dedicated input/request/response field | absent; extra_info is general description | absent | NEEDS_VERIFICATION |
| Map | latitude/longitude in legacy request/model | optional doubles | absent | EXISTS_NOT_DISPLAYED |

Active creation route: AdvertiserCheckPage → verifyLicense → AdvertisementPreviewPage → createAdWithVerification → repository → datasource → ApiService/Dio. Verification details are transient and are not attached to the published AdEntity. Creating local copies only would lose data on refresh. Legacy wizard uses AddNewAdCubit/AddAdRequest. updateAd throws UnimplementedError and has no supported edit route/identifier request contract.

Listing and details: AdResponse → AdModel → AdEntity → AdvertisementsCubit/AdDetailsCubit → body. Details opened from list reuse the entity; direct ID lookup uses getAdById. Existing tests cover minimal/null/full creators and creation failure/success. No generated ad serializers, copyWith, or entity equality mapping exist.

Implementation decision: reuse established published fields, explicitly mark unavailable regulatory values, preserve optional booleans, add responsive RTL groups and the existing Google Maps provider with validated property coordinates. Do not invent published REGA keys, responsible-person role equivalence, a property title, width from street count, guarantees from a boolean, or an update endpoint.
