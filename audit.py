import os, glob

def check_structure():
    print('AUDITING DIRECTORY STRUCTURE...')
    dirs = ['backend', 'frontend', 'mobile']
    for d in dirs:
        if os.path.exists('d:/Alz-AI/' + d):
            print(f'FOUND {d}')
        else:
            print(f'MISSING {d}')

    print('\\nCOUNTING BACKEND FILES...')
    backend_py = glob.glob('d:/Alz-AI/backend/app/**/*.py', recursive=True)
    print(f'Backend Python files: {len(backend_py)}')

    print('\\nCOUNTING FRONTEND FILES...')
    f_pages = glob.glob('d:/Alz-AI/frontend/src/pages/**/*.jsx', recursive=True)
    f_comps = glob.glob('d:/Alz-AI/frontend/src/components/**/*.jsx', recursive=True)
    f_servs = glob.glob('d:/Alz-AI/frontend/src/services/**/*.js', recursive=True)
    f_hooks = glob.glob('d:/Alz-AI/frontend/src/hooks/**/*.js', recursive=True)
    print(f'Frontend Pages: {len(f_pages)}')
    print(f'Frontend Components: {len(f_comps)}')
    print(f'Frontend Services: {len(f_servs)}')
    print(f'Frontend Hooks: {len(f_hooks)}')

    print('\\nCOUNTING MOBILE FILES...')
    m_screens = glob.glob('d:/Alz-AI/mobile/lib/screens/**/*.dart', recursive=True)
    m_widgets = glob.glob('d:/Alz-AI/mobile/lib/widgets/**/*.dart', recursive=True)
    m_services = glob.glob('d:/Alz-AI/mobile/lib/services/**/*.dart', recursive=True)
    m_providers = glob.glob('d:/Alz-AI/mobile/lib/providers/**/*.dart', recursive=True)
    m_models = glob.glob('d:/Alz-AI/mobile/lib/models/**/*.dart', recursive=True)
    print(f'Mobile Screens: {len(m_screens)}')
    print(f'Mobile Widgets: {len(m_widgets)}')
    print(f'Mobile Services: {len(m_services)}')
    print(f'Mobile Providers: {len(m_providers)}')
    print(f'Mobile Models: {len(m_models)}')

    print('\\nCHECKING MIGRATIONS...')
    migrations = glob.glob('d:/Alz-AI/backend/alembic/versions/**/*.py', recursive=True)
    print(f'Alembic migrations: {len(migrations)}')

    print('\\nCHECKING FRONTEND RECHARTS AND ROUTES...')
    front_files = glob.glob('d:/Alz-AI/frontend/src/**/*.jsx', recursive=True)
    for f in front_files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            if 'recharts' in content:
                print(f"Recharts used in: {os.path.basename(f)}")
                
    print('\\nCHECKING FLUTTER FOR DOCTOR/CARETAKER...')
    flutter_files = glob.glob('d:/Alz-AI/mobile/lib/**/*.dart', recursive=True)
    found_violators = []
    for f in flutter_files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read().lower()
            if 'caretaker' in content or 'doctor' in content:
                found_violators.append(f)
    print(f'Violating files found: {len(found_violators)}')
    for v in found_violators: print(f' -- {v}')

check_structure()
