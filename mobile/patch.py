import os

filepath = r'C:\Users\HP\AppData\Local\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle'
if os.path.exists(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'namespace' not in content and 'android {' in content:
        content = content.replace('android {\n', 'android {\n    namespace "dev.isar.isar_flutter_libs"\n', 1)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Patched isar_flutter_libs build.gradle')
    else:
        print('Already patched or not found')
