import importlib.util
import sys
import os
import traceback

def import_and_run(script_path):
    name = os.path.splitext(os.path.basename(script_path))[0]
    print(f"⏳ Loading {name} from {script_path} ...")  # Debug start
    try:
        spec = importlib.util.spec_from_file_location(name, script_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        print(f"✅ {name} loaded.")
        if hasattr(module, "main"):
            print(f"🚀 Launching {name}.main()")
            module.main()
        else:
            print(f"⚠️  {name} has no main(), only loaded.")
    except Exception as e:
        print(f"❌ Error loading {name}: {e}")
        traceback.print_exc()

if len(sys.argv) < 2:
    print("Usage: python3 tester.py script1.py [script2.py ...]")
else:
    for path in sys.argv[1:]:
        import_and_run(path)


