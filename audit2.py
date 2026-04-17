import os, json

def audit_configs():
    print("CHECKING CONFIG FILES...")
    files_to_check = ['backend/requirements.txt', 'docker-compose.yml', 'nginx.conf', '.env.example', 'mobile/pubspec.yaml']
    for f in files_to_check:
        path = f"d:/Alz-AI/{f}"
        if os.path.exists(path):
            print(f"[OK] {f} exists")
            if f == 'backend/requirements.txt':
                with open(path) as file:
                    content = file.read()
                    print(f"Dependencies count roughly: {len(content.splitlines())}")
        else:
            print(f"[FAIL] {f} missing")

audit_configs()
