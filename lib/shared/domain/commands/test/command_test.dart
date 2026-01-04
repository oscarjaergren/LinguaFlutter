import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_flutter/shared/domain/commands/command.dart';

void main() {
  group('Result', () {
    group('Creation', () {
      test('should create success result with data', () {
        final result = Result.success('test data');

        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.data, 'test data');
        expect(result.error, isNull);
      });

      test('should create success result with complex data', () {
        final data = {'key': 'value', 'number': 42};
        final result = Result.success(data);

        expect(result.isSuccess, true);
        expect(result.data, data);
      });

      test('should create empty success result', () {
        final result = Result<String>.successEmpty();

        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.data, isNull);
        expect(result.error, isNull);
      });

      test('should create failure result with error message', () {
        final result = Result<String>.failure('Something went wrong');

        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.data, isNull);
        expect(result.error, 'Something went wrong');
      });

      test('should create failure result from exception', () {
        final exception = Exception('Test exception');
        final result = Result<String>.fromException(exception);

        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.error, contains('Test exception'));
      });
    });

    group('isFailure', () {
      test('should return false for success', () {
        final result = Result.success('data');

        expect(result.isFailure, false);
      });

      test('should return true for failure', () {
        final result = Result<String>.failure('error');

        expect(result.isFailure, true);
      });
    });

    group('dataOrThrow', () {
      test('should return data for success result', () {
        final result = Result.success(42);

        expect(result.dataOrThrow, 42);
      });

      test('should throw exception for failure result', () {
        final result = Result<int>.failure('Something failed');

        expect(() => result.dataOrThrow, throwsException);
      });

      test('should include error message in thrown exception', () {
        final result = Result<int>.failure('Specific error message');

        expect(
          () => result.dataOrThrow,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Specific error message'),
            ),
          ),
        );
      });
    });

    group('dataOr', () {
      test('should return data for success result', () {
        final result = Result.success(42);

        expect(result.dataOr(0), 42);
      });

      test('should return default value for failure result', () {
        final result = Result<int>.failure('error');

        expect(result.dataOr(99), 99);
      });

      test('should work with nullable types', () {
        final result = Result<String?>.success(null);

        expect(result.dataOr('default'), isNull);
      });
    });

    group('map', () {
      test('should transform success data', () {
        final result = Result.success(5);
        final mapped = result.map((data) => data * 2);

        expect(mapped.isSuccess, true);
        expect(mapped.data, 10);
      });

      test('should transform to different type', () {
        final result = Result.success(42);
        final mapped = result.map((data) => 'Number: $data');

        expect(mapped.isSuccess, true);
        expect(mapped.data, 'Number: 42');
      });

      test('should pass through failure without transforming', () {
        final result = Result<int>.failure('Original error');
        final mapped = result.map((data) => data * 2);

        expect(mapped.isFailure, true);
        expect(mapped.error, 'Original error');
      });

      test('should catch exceptions during transformation', () {
        final result = Result.success(0);
        final mapped = result.map<int>(
          (data) => throw Exception('Transform error'),
        );

        expect(mapped.isFailure, true);
        expect(mapped.error, contains('Transform error'));
      });
    });

    group('onSuccess', () {
      test('should execute callback on success', () {
        var callbackExecuted = false;
        int? receivedData;
        final result = Result.success(42);

        result.onSuccess((data) {
          callbackExecuted = true;
          receivedData = data;
        });

        expect(callbackExecuted, true);
        expect(receivedData, 42);
      });

      test('should not execute callback on failure', () {
        var callbackExecuted = false;
        final result = Result<int>.failure('error');

        result.onSuccess((data) {
          callbackExecuted = true;
        });

        expect(callbackExecuted, false);
      });

      test('should return same result for chaining', () {
        final result = Result.success(42);
        final returned = result.onSuccess((data) {});

        expect(identical(result, returned), true);
      });
    });

    group('onFailure', () {
      test('should execute callback on failure', () {
        var callbackExecuted = false;
        String? receivedError;
        final result = Result<int>.failure('Something failed');

        result.onFailure((error) {
          callbackExecuted = true;
          receivedError = error;
        });

        expect(callbackExecuted, true);
        expect(receivedError, 'Something failed');
      });

      test('should not execute callback on success', () {
        var callbackExecuted = false;
        final result = Result.success(42);

        result.onFailure((error) {
          callbackExecuted = true;
        });

        expect(callbackExecuted, false);
      });

      test('should return same result for chaining', () {
        final result = Result<int>.failure('error');
        final returned = result.onFailure((error) {});

        expect(identical(result, returned), true);
      });
    });

    group('Chaining', () {
      test('should chain onSuccess and onFailure', () {
        var successCalled = false;
        var failureCalled = false;

        Result.success(42)
            .onSuccess((data) => successCalled = true)
            .onFailure((error) => failureCalled = true);

        expect(successCalled, true);
        expect(failureCalled, false);
      });

      test('should chain multiple map operations', () {
        final result = Result.success(5)
            .map((data) => data * 2)
            .map((data) => data + 3)
            .map((data) => 'Result: $data');

        expect(result.isSuccess, true);
        expect(result.data, 'Result: 13');
      });
    });

    group('toString', () {
      test('should return success string for success result', () {
        final result = Result.success('test');
        final str = result.toString();

        expect(str, 'Result.success(test)');
      });

      test('should return failure string for failure result', () {
        final result = Result<String>.failure('error message');
        final str = result.toString();

        expect(str, 'Result.failure(error message)');
      });
    });

    group('Type safety', () {
      test('should maintain type through transformations', () {
        final result = Result.success(42);
        final stringResult = result.map((data) => data.toString());

        expect(stringResult.data, isA<String>());
        expect(stringResult.data, '42');
      });

      test('should work with custom types', () {
        final result = Result.success(_TestData(value: 'test'));

        expect(result.data, isA<_TestData>());
        expect(result.data?.value, 'test');
      });

      test('should work with lists', () {
        final result = Result.success([1, 2, 3]);
        final mapped = result.map((data) => data.map((e) => e * 2).toList());

        expect(mapped.data, [2, 4, 6]);
      });
    });
  });
}

class _TestData {
  final String value;
  _TestData({required this.value});
}
