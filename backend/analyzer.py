import os
import ast

def analyze_directory(path):
    for root, dirs, files in os.walk(path):
        for file in files:
            file_path = os.path.join(root, file)
            size = os.path.getsize(file_path)
            content = ""
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()
            except Exception:
                pass
            print(f"FILE: {file_path} SIZE: {size} bytes")
            if file_path.endswith(".py") and content:
                try:
                    tree = ast.parse(content)
                    passes = [node for node in ast.walk(tree) if isinstance(node, ast.Pass)]
                    if passes:
                        print(f"  -> WARNING: Found {len(passes)} 'pass' statements!")
                except SyntaxError:
                    print("  -> ERROR: Syntax Error")
            if size == 0:
                print("  -> WARNING: File is empty!")

if __name__ == "__main__":
    analyze_directory("d:\\Alz-AI")
