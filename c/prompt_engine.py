import os
import re
import sys
import argparse

def load_file(path):
    with open(path, 'r') as f:
        return f.read()

def parse_simple_yaml(yaml_str):
    """Simple parser for key: value pairs in YAML frontmatter."""
    config = {}
    for line in yaml_str.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            config[key.strip()] = value.strip()
    return config

def assemble_prompt(system_path, template_path, target_file_path):
    # 1. Load the system prompt
    system_prompt = load_file(system_path)

    # 2. Load the template and parse YAML frontmatter
    template_raw = load_file(template_path)
    
    # Split YAML frontmatter from markdown body
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n(.*)', template_raw, re.DOTALL)
    if not match:
        raise ValueError("Template must have YAML frontmatter (--- at top and bottom)")
    
    config_yaml = match.group(1)
    template_body = match.group(2)
    
    config = parse_simple_yaml(config_yaml)
    
    # 3. Load the target code and substitute placeholder
    code = load_file(target_file_path)
    final_user_prompt = template_body.replace("{{CODE}}", code)
    
    return {
        "system": system_prompt,
        "user": final_user_prompt,
        "config": config
    }

def main():
    parser = argparse.ArgumentParser(
        description="Assembles LLM prompts for C refactoring by combining system personas and templates.",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        "files", 
        nargs="+", 
        help="One or more C files to be processed for refactoring."
    )
    
    parser.add_argument(
        "-n", "--dry-run", 
        action="store_true", 
        help="Dry run: Explain what would be done without assembling the prompts (outputs to stderr)."
    )

    args = parser.parse_args()

    # Determine the script directory to locate prompts
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sys_p = os.path.join(script_dir, "prompts", "system", "senior-c-dev.md")
    temp_p = os.path.join(script_dir, "prompts", "templates", "coding", "refactor.md")

    # Verify prompt files exist first
    if not os.path.exists(sys_p):
        print(f"Error: System prompt not found at {sys_p}", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(temp_p):
        print(f"Error: Template prompt not found at {temp_p}", file=sys.stderr)
        sys.exit(1)

    for target_file in args.files:
        if not os.path.exists(target_file):
            print(f"Warning: File '{target_file}' not found. Skipping.", file=sys.stderr)
            continue

        if args.dry_run:
            print(f"Dry run: Would assemble prompt for '{target_file}' using '{temp_p}' and '{sys_p}'.", file=sys.stderr)
        else:
            try:
                result = assemble_prompt(sys_p, temp_p, target_file)
                
                print("-" * 40)
                print(f"PROMPT ASSEMBLY FOR: {target_file}")
                print("-" * 40)
                
                print("\n=== CONFIGURATION ===")
                for k, v in result['config'].items():
                    print(f"{k}: {v}")
                
                print("\n=== SYSTEM PROMPT ===")
                print(result['system'])
                
                print("\n=== USER PROMPT ===")
                print(result['user'])
                print("\n" + "=" * 40 + "\n")
                
            except Exception as e:
                print(f"Error processing {target_file}: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
