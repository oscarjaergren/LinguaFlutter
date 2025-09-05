---
description: 'Dart usage patterns and API design principles following official recommendations.'
applyTo: '**/*.dart'
---

# Dart Usage & Design

Best practices for Dart language usage and API design principles. These instructions were taken from [Effective Dart](https://dart.dev/effective-dart).

## Usage Rules

### Libraries

*   DO use strings in `part of` directives.
*   DON'T import libraries that are inside the `src` directory of another package.
*   DON'T allow an import path to reach into or out of `lib`.
*   PREFER relative import paths.

### Null

*   DON'T explicitly initialize variables to `null`.
*   DON'T use an explicit default value of `null`.
*   DON'T use `true` or `false` in equality operations.
*   AVOID `late` variables if you need to check whether they are initialized.
*   CONSIDER type promotion or null-check patterns for using nullable types.

### Strings

*   DO use adjacent strings to concatenate string literals.
*   PREFER using interpolation to compose strings and values.
*   AVOID using curly braces in interpolation when not needed.

### Collections

*   DO use collection literals when possible.
*   DON'T use `.length` to see if a collection is empty.
*   AVOID using `Iterable.forEach()` with a function literal.
*   DON'T use `List.from()` unless you intend to change the type of the result.
*   DO use `whereType()` to filter a collection by type.
*   DON'T use `cast()` when a nearby operation will do.
*   AVOID using `cast()`.

### Functions

*   DO use a function declaration to bind a function to a name.
*   DON'T create a lambda when a tear-off will do.

### Variables

*   DO follow a consistent rule for `var` and `final` on local variables.
*   AVOID storing what you can calculate.

### Members

*   DON'T wrap a field in a getter and setter unnecessarily.
*   PREFER using a `final` field to make a read-only property.
*   CONSIDER using `=>` for simple members.
*   DON'T use `this.` except to redirect to a named constructor or to avoid shadowing.
*   DO initialize fields at their declaration when possible.

### Constructors

*   DO use initializing formals when possible.
*   DON'T use `late` when a constructor initializer list will do.
*   DO use `;` instead of `{}` for empty constructor bodies.
*   DON'T use `new`.
*   DON'T use `const` redundantly.

### Error Handling

*   AVOID catches without `on` clauses.
*   DON'T discard errors from catches without `on` clauses.
*   DO throw objects that implement `Error` only for programmatic errors.
*   DON'T explicitly catch `Error` or types that implement it.
*   DO use `rethrow` to rethrow a caught exception.

### Asynchrony

*   PREFER async/await over using raw futures.
*   DON'T use `async` when it has no useful effect.
*   CONSIDER using higher-order methods to transform a stream.
*   AVOID using Completer directly.
*   DO test for `Future<T>` when disambiguating a `FutureOr<T>` whose type argument could be `Object`.

## Design Rules

### Names

*   DO use terms consistently.
*   AVOID abbreviations.
*   PREFER putting the most descriptive noun last.
*   CONSIDER making the code read like a sentence.
*   PREFER a noun phrase for a non-boolean property or variable.
*   PREFER a non-imperative verb phrase for a boolean property or variable.
*   CONSIDER omitting the verb for a named boolean parameter.
*   PREFER the "positive" name for a boolean property or variable.
*   PREFER an imperative verb phrase for a function or method whose main purpose is a side effect.
*   PREFER a noun phrase or non-imperative verb phrase for a function or method if returning a value is its primary purpose.
*   CONSIDER an imperative verb phrase for a function or method if you want to draw attention to the work it performs.
*   AVOID starting a method name with `get`.
*   PREFER naming a method `to...()` if it copies the object's state to a new object.
*   PREFER naming a method `as...()` if it returns a different representation backed by the original object.
*   AVOID describing the parameters in the function's or method's name.
*   DO follow existing mnemonic conventions when naming type parameters.

### Libraries

*   PREFER making declarations private.
*   CONSIDER declaring multiple classes in the same library.

### Classes and Mixins

*   AVOID defining a one-member abstract class when a simple function will do.
*   AVOID defining a class that contains only static members.
*   AVOID extending a class that isn't intended to be subclassed.
*   DO use class modifiers to control if your class can be extended.
*   AVOID implementing a class that isn't intended to be an interface.
*   DO use class modifiers to control if your class can be an interface.
*   PREFER defining a pure `mixin` or pure `class` to a `mixin class`.

### Constructors

*   CONSIDER making your constructor `const` if the class supports it.

### Members

*   PREFER making fields and top-level variables `final`.
*   DO use getters for operations that conceptually access properties.
*   DO use setters for operations that conceptually change properties.
*   DON'T define a setter without a corresponding getter.
*   AVOID using runtime type tests to fake overloading.
*   AVOID public `late final` fields without initializers.
*   AVOID returning nullable `Future`, `Stream`, and collection types.
*   AVOID returning `this` from methods just to enable a fluent interface.

### Types

*   DO type annotate variables without initializers.
*   DO type annotate fields and top-level variables if the type isn't obvious.
*   DON'T redundantly type annotate initialized local variables.
*   DO annotate return types on function declarations.
*   DO annotate parameter types on function declarations.
*   DON'T annotate inferred parameter types on function expressions.
*   DON'T type annotate initializing formals.
*   DO write type arguments on generic invocations that aren't inferred.
*   DON'T write type arguments on generic invocations that are inferred.
*   AVOID writing incomplete generic types.
*   DO annotate with `dynamic` instead of letting inference fail.
*   PREFER signatures in function type annotations.
*   DON'T specify a return type for a setter.
*   DON'T use the legacy typedef syntax.
*   PREFER inline function types over typedefs.
*   PREFER using function type syntax for parameters.
*   AVOID using `dynamic` unless you want to disable static checking.
*   DO use `Future<void>` as the return type of asynchronous members that do not produce values.
*   AVOID using `FutureOr<T>` as a return type.

### Parameters

*   AVOID positional boolean parameters.
*   AVOID optional positional parameters if the user may want to omit earlier parameters.
*   AVOID mandatory parameters that accept a special "no argument" value.
*   DO use inclusive start and exclusive end parameters to accept a range.

### Equality

*   DO override `hashCode` if you override `==`.
*   DO make your `==` operator obey the mathematical rules of equality.
*   AVOID defining custom equality for mutable classes.
*   DON'T make the parameter to `==` nullable.
