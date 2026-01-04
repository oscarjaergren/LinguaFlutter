import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/models/word_data.dart';

void main() {
  group('WordType', () {
    test('should have all expected values', () {
      expect(WordType.values.length, 6);
      expect(WordType.values, contains(WordType.verb));
      expect(WordType.values, contains(WordType.noun));
      expect(WordType.values, contains(WordType.adjective));
      expect(WordType.values, contains(WordType.adverb));
      expect(WordType.values, contains(WordType.phrase));
      expect(WordType.values, contains(WordType.other));
    });
  });

  group('WordData', () {
    group('VerbData', () {
      test('should create verb with defaults', () {
        const verb = WordData.verb();

        expect(verb, isA<VerbData>());
        final verbData = verb as VerbData;
        expect(verbData.isRegular, true);
        expect(verbData.isSeparable, false);
        expect(verbData.separablePrefix, isNull);
        expect(verbData.auxiliary, 'haben');
        expect(verbData.presentDu, isNull);
        expect(verbData.presentEr, isNull);
        expect(verbData.pastSimple, isNull);
        expect(verbData.pastParticiple, isNull);
      });

      test('should create regular verb', () {
        const verb = WordData.verb(isRegular: true, auxiliary: 'haben');

        final verbData = verb as VerbData;
        expect(verbData.isRegular, true);
        expect(verbData.auxiliary, 'haben');
      });

      test('should create irregular verb with conjugations', () {
        const verb = WordData.verb(
          isRegular: false,
          presentDu: 'sprichst',
          presentEr: 'spricht',
          pastSimple: 'sprach',
          pastParticiple: 'gesprochen',
        );

        final verbData = verb as VerbData;
        expect(verbData.isRegular, false);
        expect(verbData.presentDu, 'sprichst');
        expect(verbData.presentEr, 'spricht');
        expect(verbData.pastSimple, 'sprach');
        expect(verbData.pastParticiple, 'gesprochen');
      });

      test('should create separable verb', () {
        const verb = WordData.verb(isSeparable: true, separablePrefix: 'auf');

        final verbData = verb as VerbData;
        expect(verbData.isSeparable, true);
        expect(verbData.separablePrefix, 'auf');
      });

      test('should create verb with sein auxiliary', () {
        const verb = WordData.verb(
          auxiliary: 'sein',
          pastParticiple: 'gegangen',
        );

        final verbData = verb as VerbData;
        expect(verbData.auxiliary, 'sein');
        expect(verbData.pastParticiple, 'gegangen');
      });

      test('should serialize verb to JSON and back', () {
        const original = WordData.verb(
          isRegular: false,
          isSeparable: true,
          separablePrefix: 'an',
          auxiliary: 'haben',
          presentDu: 'rufst an',
          presentEr: 'ruft an',
          pastSimple: 'rief an',
          pastParticiple: 'angerufen',
        );

        final json = original.toJson();
        final restored = WordData.fromJson(json);

        expect(restored, isA<VerbData>());
        final restoredVerb = restored as VerbData;
        expect(restoredVerb.isRegular, false);
        expect(restoredVerb.isSeparable, true);
        expect(restoredVerb.separablePrefix, 'an');
        expect(restoredVerb.pastParticiple, 'angerufen');
      });
    });

    group('NounData', () {
      test('should create noun with required gender', () {
        const noun = WordData.noun(gender: 'der');

        expect(noun, isA<NounData>());
        final nounData = noun as NounData;
        expect(nounData.gender, 'der');
        expect(nounData.plural, isNull);
        expect(nounData.genitive, isNull);
      });

      test('should create masculine noun', () {
        const noun = WordData.noun(
          gender: 'der',
          plural: 'Tische',
          genitive: 'des Tisches',
        );

        final nounData = noun as NounData;
        expect(nounData.gender, 'der');
        expect(nounData.plural, 'Tische');
        expect(nounData.genitive, 'des Tisches');
      });

      test('should create feminine noun', () {
        const noun = WordData.noun(gender: 'die', plural: 'Lampen');

        final nounData = noun as NounData;
        expect(nounData.gender, 'die');
        expect(nounData.plural, 'Lampen');
      });

      test('should create neuter noun', () {
        const noun = WordData.noun(
          gender: 'das',
          plural: 'Bücher',
          genitive: 'des Buches',
        );

        final nounData = noun as NounData;
        expect(nounData.gender, 'das');
        expect(nounData.plural, 'Bücher');
        expect(nounData.genitive, 'des Buches');
      });

      test('should serialize noun to JSON and back', () {
        const original = WordData.noun(
          gender: 'das',
          plural: 'Häuser',
          genitive: 'des Hauses',
        );

        final json = original.toJson();
        final restored = WordData.fromJson(json);

        expect(restored, isA<NounData>());
        final restoredNoun = restored as NounData;
        expect(restoredNoun.gender, 'das');
        expect(restoredNoun.plural, 'Häuser');
        expect(restoredNoun.genitive, 'des Hauses');
      });
    });

    group('AdjectiveData', () {
      test('should create adjective with defaults', () {
        const adj = WordData.adjective();

        expect(adj, isA<AdjectiveData>());
        final adjData = adj as AdjectiveData;
        expect(adjData.comparative, isNull);
        expect(adjData.superlative, isNull);
      });

      test('should create adjective with comparison forms', () {
        const adj = WordData.adjective(
          comparative: 'größer',
          superlative: 'größten',
        );

        final adjData = adj as AdjectiveData;
        expect(adjData.comparative, 'größer');
        expect(adjData.superlative, 'größten');
      });

      test('should create adjective with irregular comparison', () {
        const adj = WordData.adjective(
          comparative: 'besser',
          superlative: 'besten',
        );

        final adjData = adj as AdjectiveData;
        expect(adjData.comparative, 'besser');
        expect(adjData.superlative, 'besten');
      });

      test('should serialize adjective to JSON and back', () {
        const original = WordData.adjective(
          comparative: 'schneller',
          superlative: 'schnellsten',
        );

        final json = original.toJson();
        final restored = WordData.fromJson(json);

        expect(restored, isA<AdjectiveData>());
        final restoredAdj = restored as AdjectiveData;
        expect(restoredAdj.comparative, 'schneller');
        expect(restoredAdj.superlative, 'schnellsten');
      });
    });

    group('AdverbData', () {
      test('should create adverb with defaults', () {
        const adv = WordData.adverb();

        expect(adv, isA<AdverbData>());
        final advData = adv as AdverbData;
        expect(advData.usageNote, isNull);
      });

      test('should create adverb with usage note', () {
        const adv = WordData.adverb(
          usageNote: 'Used primarily in formal contexts',
        );

        final advData = adv as AdverbData;
        expect(advData.usageNote, 'Used primarily in formal contexts');
      });

      test('should serialize adverb to JSON and back', () {
        const original = WordData.adverb(usageNote: 'Colloquial usage');

        final json = original.toJson();
        final restored = WordData.fromJson(json);

        expect(restored, isA<AdverbData>());
        final restoredAdv = restored as AdverbData;
        expect(restoredAdv.usageNote, 'Colloquial usage');
      });
    });

    group('Pattern matching', () {
      test('should match verb pattern', () {
        const data = WordData.verb(isRegular: true);

        final result = switch (data) {
          VerbData(:final isRegular) => 'Verb: regular=$isRegular',
          NounData(:final gender) => 'Noun: $gender',
          AdjectiveData() => 'Adjective',
          AdverbData() => 'Adverb',
        };

        expect(result, 'Verb: regular=true');
      });

      test('should match noun pattern', () {
        const data = WordData.noun(gender: 'die');

        final result = switch (data) {
          VerbData() => 'Verb',
          NounData(:final gender) => 'Noun: $gender',
          AdjectiveData() => 'Adjective',
          AdverbData() => 'Adverb',
        };

        expect(result, 'Noun: die');
      });

      test('should match adjective pattern', () {
        const data = WordData.adjective(comparative: 'besser');

        final result = switch (data) {
          VerbData() => 'Verb',
          NounData() => 'Noun',
          AdjectiveData(:final comparative) => 'Adjective: $comparative',
          AdverbData() => 'Adverb',
        };

        expect(result, 'Adjective: besser');
      });

      test('should match adverb pattern', () {
        const data = WordData.adverb(usageNote: 'formal');

        final result = switch (data) {
          VerbData() => 'Verb',
          NounData() => 'Noun',
          AdjectiveData() => 'Adjective',
          AdverbData(:final usageNote) => 'Adverb: $usageNote',
        };

        expect(result, 'Adverb: formal');
      });
    });

    group('Equality', () {
      test('should be equal for identical verbs', () {
        const verb1 = WordData.verb(isRegular: true, auxiliary: 'haben');
        const verb2 = WordData.verb(isRegular: true, auxiliary: 'haben');

        expect(verb1, equals(verb2));
      });

      test('should not be equal for different verbs', () {
        const verb1 = WordData.verb(isRegular: true);
        const verb2 = WordData.verb(isRegular: false);

        expect(verb1, isNot(equals(verb2)));
      });

      test('should be equal for identical nouns', () {
        const noun1 = WordData.noun(gender: 'der', plural: 'Tische');
        const noun2 = WordData.noun(gender: 'der', plural: 'Tische');

        expect(noun1, equals(noun2));
      });

      test('should not be equal for different types', () {
        const verb = WordData.verb();
        const noun = WordData.noun(gender: 'der');

        expect(verb, isNot(equals(noun)));
      });
    });

    group('CopyWith', () {
      test('should copy verb with changes', () {
        const original = WordData.verb(isRegular: true, auxiliary: 'haben');
        final copied = (original as VerbData).copyWith(auxiliary: 'sein');

        expect(copied.isRegular, true);
        expect(copied.auxiliary, 'sein');
      });

      test('should copy noun with changes', () {
        const original = WordData.noun(gender: 'der', plural: 'Tische');
        final copied = (original as NounData).copyWith(genitive: 'des Tisches');

        expect(copied.gender, 'der');
        expect(copied.plural, 'Tische');
        expect(copied.genitive, 'des Tisches');
      });

      test('should copy adjective with changes', () {
        const original = WordData.adjective(comparative: 'größer');
        final copied = (original as AdjectiveData).copyWith(
          superlative: 'größten',
        );

        expect(copied.comparative, 'größer');
        expect(copied.superlative, 'größten');
      });
    });
  });
}
