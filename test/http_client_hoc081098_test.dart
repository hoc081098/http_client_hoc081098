import 'tests/get_test.dart' as get_test;
import 'tests/post_test.dart' as post_test;
import 'tests/put_test.dart' as put_test;
import 'tests/delete_test.dart' as delete_test;
import 'tests/patch_test.dart' as patch_test;

import 'tests/request_interceptors.dart' as request_interceptors;

void main() {
  get_test.main();
  post_test.main();
  put_test.main();
  delete_test.main();
  patch_test.main();

  request_interceptors.main();
}
