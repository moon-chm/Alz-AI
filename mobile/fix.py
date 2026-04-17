import os

repo_dir = r"d:\Alz-AI\mobile\lib"

replacements = {
    # from core/config/router.dart
    "import '../providers/": "import 'package:mobile/providers/",
    "import '../screens/": "import 'package:mobile/screens/",
    "import '../core/utils/": "import 'package:mobile/core/utils/",
    
    # from core/widgets/
    "import '../models/": "import 'package:mobile/models/",
    "import '../core/config/": "import 'package:mobile/core/config/",
    "import '../providers/saathi_provider.dart';": "import 'package:mobile/providers/saathi_provider.dart';",

    # from screens
    "import '../../config/": "import 'package:mobile/core/config/",
    "import '../../widgets/": "import 'package:mobile/core/widgets/",
    
    # theme CardTheme fix
    "CardTheme(": "CardThemeData(",
}

for root, dirs, files in os.walk(repo_dir):
    for f in files:
        if f.endswith(".dart"):
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8") as file:
                content = file.read()
                
            orig = content
            for k, v in replacements.items():
                content = content.replace(k, v)
                
            if orig != content:
                print(f"Fixed {path}")
                with open(path, "w", encoding="utf-8") as file:
                    file.write(content)
