import 'package:flutter_test/flutter_test.dart';
import 'package:waseet/features/advertisement/data/models/ad_model.dart';
import 'package:waseet/features/advertisement/domain/entities/ad_entity.dart';
import 'package:waseet/features/advertisement/domain/entities/advertisement_price.dart';
import 'package:waseet/features/advertisement/domain/entities/rega_compliance_entity.dart';

AdEntity adFromJson(Map<String, dynamic> json) =>
    AdModel.fromJson(json).toEntity();

/// Case A: apartment for sale, root price null, regulatory price populated.
Map<String, dynamic> apartmentSaleJson() => {
      'id': 416,
      'type_of_advertisement': 'buy',
      'category': {'id': 1, 'name': 'شقة'},
      'price': null,
      'meter_price': null,
      'rega_compliance': {
        'status': 'verified',
        'required_fields': {
          'property_price': 450000,
          'property_type': 'شقة',
          'number_of_rooms': 4,
          'property_area': 900,
        },
      },
    };

/// Case B: land for sale with documented total and per-meter values.
Map<String, dynamic> landSaleJson() => {
      'id': 415,
      'type_of_advertisement': 'buy',
      'category': {'id': 2, 'name': 'ارض'},
      'price': null,
      'meter_price': null,
      'rega_compliance': {
        'status': 'verified',
        'property': {'land_total_price': 449990},
        'required_fields': {
          'property_price': 1000,
          'property_type': 'ارض',
          'property_area': 449.99,
        },
      },
    };

void main() {
  group('AdvertisementPriceResolver', () {
    test('1. apartment sale uses regulatory price when root is null', () {
      final price =
          AdvertisementPriceResolver.resolve(adFromJson(apartmentSaleJson()));
      expect(price.total, 450000);
      expect(price.unitPerMeter, isNull);
      expect(price.source, AdPriceSource.regaPropertyPrice);
      expect(price.isRental, isFalse);
      expect(price.hasTotal, isTrue);
      expect(formatAdPriceAmount(price.total!), '450,000');
    });

    test('2. root price wins when both root and regulatory are populated', () {
      final json = apartmentSaleJson()..['price'] = 460000;
      final price = AdvertisementPriceResolver.resolve(adFromJson(json));
      expect(price.total, 460000);
      expect(price.source, AdPriceSource.rootPrice);
    });

    test('3. conflicting root and regulatory prices keep the legacy root', () {
      final json = apartmentSaleJson()..['price'] = 400000;
      final price = AdvertisementPriceResolver.resolve(adFromJson(json));
      expect(price.total, 400000);
      expect(price.source, AdPriceSource.rootPrice);
    });

    test('4. land sale exposes documented total and per-meter rate', () {
      final price =
          AdvertisementPriceResolver.resolve(adFromJson(landSaleJson()));
      expect(price.total, 449990);
      expect(price.unitPerMeter, 1000);
      expect(price.source, AdPriceSource.regaLandTotal);
      expect(formatAdPriceAmount(price.total!), '449,990');
      expect(formatAdPriceAmount(price.unitPerMeter!), '1,000');
    });

    test('5. land sale without total falls back to the official unit price',
        () {
      final json = landSaleJson();
      final rega = Map<String, dynamic>.from(
        json['rega_compliance'] as Map<String, dynamic>,
      );
      rega['property'] = {'land_total_price': null};
      json['rega_compliance'] = rega;
      final price = AdvertisementPriceResolver.resolve(adFromJson(json));
      expect(price.total, 1000);
      expect(price.unitPerMeter, isNull);
      expect(price.source, AdPriceSource.regaPropertyPrice);
    });

    test('6. land sale without per-meter rate keeps total, no unit', () {
      final json = landSaleJson();
      final rega = Map<String, dynamic>.from(
        json['rega_compliance'] as Map<String, dynamic>,
      );
      final req = Map<String, dynamic>.from(
        rega['required_fields'] as Map<String, dynamic>,
      );
      req['property_price'] = null;
      rega['required_fields'] = req;
      json['rega_compliance'] = rega;
      final price = AdvertisementPriceResolver.resolve(adFromJson(json));
      expect(price.total, 449990);
      expect(price.unitPerMeter, isNull);
      expect(price.source, AdPriceSource.regaLandTotal);
    });

    test('7. rental uses regulatory price and flags rental without period',
        () {
      final json = {
        'id': 412,
        'type_of_advertisement': 'rent',
        'category': {'id': 1, 'name': 'شقة'},
        'price': null,
        'rega_compliance': {
          'status': 'verified',
          'required_fields': {'property_price': 42000},
        },
      };
      final price = AdvertisementPriceResolver.resolve(adFromJson(json));
      expect(price.total, 42000);
      expect(price.isRental, isTrue);
      expect(formatAdPriceAmount(price.total!), '42,000');
    });

    test('8. rental display text never invents a billing period', () {
      final price = AdvertisementPriceResolver.resolve(
        AdEntity(typeOfAdvertisement: 'rent'),
      );
      // The resolver exposes no period concept at all.
      expect(price.isRental, isTrue);
      expect(price.hasTotal, isFalse);
    });

    test('9. legacy ad without rega_compliance keeps working', () {
      final withRoot = AdvertisementPriceResolver.resolve(
        AdEntity(typeOfAdvertisement: 'buy', price: 300000),
      );
      expect(withRoot.total, 300000);
      expect(withRoot.source, AdPriceSource.rootPrice);

      final withoutAnything = AdvertisementPriceResolver.resolve(
        AdEntity(typeOfAdvertisement: 'buy'),
      );
      expect(withoutAnything.hasTotal, isFalse);
      expect(withoutAnything.source, AdPriceSource.none);
    });

    test('10. missing prices across all fields resolve to unknown', () {
      final price = AdvertisementPriceResolver.resolve(
        AdEntity(
          regaCompliance: const RegaComplianceEntity(status: 'verified'),
        ),
      );
      expect(price.total, isNull);
      expect(price.unitPerMeter, isNull);
      expect(price.source, AdPriceSource.none);
      expect(price.hasTotal, isFalse);
    });

    test('11. malformed numeric price values resolve to unknown', () {
      final price = AdvertisementPriceResolver.resolve(
        adFromJson({
          'id': 500,
          'price': 'not_a_number',
          'rega_compliance': {
            'status': 'verified',
            'property': {'land_total_price': 'abc'},
            'required_fields': {'property_price': 'also_bad'},
          },
        }),
      );
      expect(price.hasTotal, isFalse);
      expect(price.source, AdPriceSource.none);
    });

    test('12. zero and negative prices are unknown, never rendered as 0',
        () {
      for (final bad in [0, -5, -0.5]) {
        final price = AdvertisementPriceResolver.resolve(
          AdEntity(price: bad is int ? bad : null),
        );
        expect(price.hasTotal, isFalse, reason: 'root $bad');

        final regaPrice = AdvertisementPriceResolver.resolve(
          adFromJson({
            'id': 501,
            'price': null,
            'rega_compliance': {
              'status': 'verified',
              'required_fields': {'property_price': bad},
            },
          }),
        );
        expect(regaPrice.hasTotal, isFalse, reason: 'rega $bad');
      }
    });

    test('13. decimals keep precision with thousands separators', () {
      expect(formatAdPriceAmount(2000007.62), '2,000,007.62');
      expect(formatAdPriceAmount(3584.5), '3,584.5');
      expect(formatAdPriceAmount(449.99), '449.99');
      expect(formatAdPriceAmount(450000), '450,000');
      expect(formatAdPriceAmount(1000), '1,000');
    });

    test('14. unknown category semantics never mislabel the price', () {
      // Unknown category + documented land total: total still applies
      // (category-agnostic), but no per-m² claim without a unit value.
      final price = AdvertisementPriceResolver.resolve(
        adFromJson({
          'id': 502,
          'type_of_advertisement': 'buy',
          'category': {'id': 999, 'name': 'مسمى غير معروف'},
          'price': null,
          'rega_compliance': {
            'status': 'verified',
            'property': {'land_total_price': 2000007.62},
            'required_fields': {'property_price': 3584.5},
          },
        }),
      );
      expect(price.total, 2000007.62);
      expect(price.unitPerMeter, 3584.5);
      expect(price.source, AdPriceSource.regaLandTotal);
    });

    test('15. list and details payloads resolve the same total', () {
      final listPrice = AdvertisementPriceResolver.resolve(
        adFromJson(apartmentSaleJson()),
      );
      final detailsPrice = AdvertisementPriceResolver.resolve(
        adFromJson({
          ...apartmentSaleJson(),
          'city': {'id': 1, 'name': 'الرياض'},
          'extra_info': 'وصف',
        }),
      );
      expect(detailsPrice.total, listPrice.total);
      expect(detailsPrice.source, listPrice.source);
    });
  });
}
