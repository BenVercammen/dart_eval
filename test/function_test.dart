import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Function tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Local variable assignment with ints', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            int main() {
              var i = 3;
              {
                var k = 2;
                k = i;
                return k;
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 3);
    });

    test('Simple function call', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            int main() {
              var i = x();
              return i;
            }
            int x() {
              return 7;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 7);
    });

    test('Recursion (fibonacci)', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int fib(int n) {
              if (n <= 1) return 1;
              return fib(n - 1) + fib(n - 2);
            }
            
            int main () {
              return fib(24);
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 75025);
    });

    test('Multiple files, boxed ints and correct stack handling', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'package:example/x.dart';
            num main() {
              var i = x();
              return i + 3;
            }
            num x() {
              return x2();
            }
          ''',
          'x.dart': '''
            int x2() {
               var b = 4;
               var q = r();
               var c = 2;
               c = b;
               b = q;
               b = c;
               return b;
            }
        
            int r() {
              var ra = 99;
              return ra;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $num<num>(7));
    });

    test('Basic anonymous function', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            Function r() {
              return () {
                return 2;
              };
            }
            
            int main () {
              return r()();
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 2);
    });

    test('Basic inline anonymous function', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              var r = () {
                return 2;
              };
              return r();
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 2);
    });

    test('Anonymous function with arg', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              var myfunc = (a) {
                return a + 1;
              };
              
              return myfunc(2);
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('Anonymous function with named args, same sorting as call site', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main () {
              var myfunc = ({a, b}) {
                return a / b + 1;
              };
              
              return myfunc(a: 2, b: 4);
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $double(1.5));
    });

    test('Anonymous function with named args, different sorting from call site',
        () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main () {
              var myfunc = ({b, a}) {
                return a / b + 1;
              };
              
              return myfunc(a: 2, b: 4);
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $double(1.5));
    });

    test('Anonymous function with named args, one unspecified', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main () {
              var myfunc = ({a, b}) {
                return a + 1;
              };
              
              return myfunc(a: 2);
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(3));
    });

    test('Closure with arg', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return q()(6);
            }
            
            Function q() {
              final b = 12;
              
              var myfunc = (a) {
                return a + b;
              };
              
              return myfunc;
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 18);
    });

    test('Arrow function', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main (int y) => 2 + y;
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main', [4]), 6);
    });

    test('Arrow function expression', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              var fn = (a) => a + 1;
              return fn(4);
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 5);
    });

    test('Nullable arg', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return fun(null);
            }
            
            int fun(int? a) {
              if (a == null) {
                return 2;
              }
              return a;
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 2);
    });

    // https://github.com/ethanblake4/dart_eval/issues/74#issuecomment-1289275224
    test('Arrow function return value boxing', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main () {
              return fun() + 'd';
            }
            
            String fun() => 'Hello Worl';
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('Hello World'));
    });

    test('Basic generic function type', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return fun(() => 3);
            }
            
            int fun(void Function() a) {
              return a();
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('Indexing outer list from a closure', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              var list = [1, 2, 3];
              var fn = () => list[1];
              return fn();
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 2);
    });

    test('Default positional args', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return fun(1);
            }
            
            int fun(int a, [int b = 2]) {
              return a + b;
            }
           '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });
  });
}
