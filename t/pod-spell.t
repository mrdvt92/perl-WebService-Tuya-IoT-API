use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
API
IoT
Tuya
TuyaCloud
api
openapi
tuyaus
ua
v1
TinyTuya
iOS
JSON
