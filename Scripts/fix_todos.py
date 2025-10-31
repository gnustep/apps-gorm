#!/usr/bin/env python3
"""
Batch document all remaining header files with proper autogsdoc documentation.
This replaces TODO markers with proper documentation based on method names and context.
"""

import re
import sys
from pathlib import Path
from typing import Tuple, Optional

def analyze_method_signature(signature: str) -> Tuple[str, bool, bool, str]:
    """Analyze a method signature and return (method_name, is_setter, is_getter, description)."""
    sig = signature.strip()
    
    # Class method (+) vs instance method (-)
    is_class_method = sig.startswith('+')
    
    # Extract method name
    if ':' in sig:
        # Method with parameters
        parts = re.findall(r'([a-zA-Z_][a-zA-Z0-9_]*)\s*:', sig)
        method_name = ':'.join(parts) + ':'
    else:
        # Simple getter
        match = re.search(r'[-+]\s*\([^)]+\)\s*([a-zA-Z_][a-zA-Z0-9_]*)', sig)
        method_name = match.group(1) if match else ""
    
    # Determine type based on method name
    is_setter = method_name.startswith('set') and ':' in method_name
    is_getter = not ':' in method_name and not is_class_method
    
    # Generate appropriate description
    if 'init' in method_name.lower():
        desc = "Initializes and returns a new instance."
    elif method_name in ['dealloc', 'release']:
        desc = "Releases resources and deallocates the instance."
    elif method_name == 'copy':
        desc = "Returns a copy of the receiver."
    elif is_setter:
        prop = method_name[3:].replace(':', '').strip()
        prop = prop[0].lower() + prop[1:] if prop else "value"
        desc = f"Sets the {prop}."
    elif is_getter and method_name.startswith('is'):
        desc = f"Returns YES if {method_name[2:]}, NO otherwise."
    elif is_getter and method_name.startswith('has'):
        desc = f"Returns YES if {method_name[3:]}, NO otherwise."
    elif is_getter and method_name.startswith('should'):
        desc = f"Returns YES if should {method_name[6:]}, NO otherwise."
    elif is_getter:
        desc = f"Returns the {method_name}."
    elif 'add' in method_name.lower():
        desc = "Adds an object to the collection."
    elif 'remove' in method_name.lower():
        desc = "Removes an object from the collection."
    elif 'delete' in method_name.lower():
        desc = "Deletes the specified object."
    elif 'open' in method_name.lower():
        desc = "Opens the specified resource or editor."
    elif 'close' in method_name.lower():
        desc = "Closes the resource or editor."
    elif 'activate' in method_name.lower():
        desc = "Activates the object."
    elif 'deactivate' in method_name.lower():
        desc = "Deactivates the object."
    elif 'refresh' in method_name.lower():
        desc = "Refreshes the display or data."
    elif 'update' in method_name.lower():
        desc = "Updates the object's state."
    elif 'reload' in method_name.lower():
        desc = "Reloads the data."
    elif 'select' in method_name.lower():
        desc = "Selects the specified object or objects."
    elif 'contains' in method_name.lower():
        desc = "Returns YES if contains the object, NO otherwise."
    elif 'paste' in method_name.lower():
        desc = "Pastes objects from the pasteboard."
    elif 'copy' in method_name.lower() and ':' in method_name:
        desc = "Copies the selection to the pasteboard."
    elif 'orderFront' in method_name:
        desc = "Orders the window or panel to the front."
    elif 'window' == method_name:
        desc = "Returns the window associated with this object."
    elif 'document' == method_name:
        desc = "Returns the document associated with this object."
    elif 'rect' in method_name.lower():
        desc = "Returns the rectangle for the specified object."
    elif 'group' in method_name.lower():
        desc = "Groups the selected objects."
    elif 'ungroup' in method_name.lower():
        desc = "Ungroups the selected objects."
    elif method_name == 'fileTypes':
        desc = "Returns an array of supported file types."
    elif method_name == 'objects':
        desc = "Returns an array of all objects managed by this editor."
    else:
        desc = f"Performs {method_name.replace(':', ' ')} operation."
    
    return method_name, is_setter, is_getter, desc

def fix_file(filepath: Path) -> bool:
    """Fix all TODO markers in a file."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"  ✗ Error reading {filepath}: {e}")
        return False
    
    if 'TODO' not in content:
        return False
    
    lines = content.split('\n')
    output_lines = []
    i = 0
    modified = False
    
    while i < len(lines):
        line = lines[i]
        
        # Check if this is a TODO comment followed by a method
        if 'TODO: Add method documentation' in line or 'TODO: add description' in line:
            # Look ahead for the method signature
            if i + 2 < len(lines):
                next_line = lines[i + 2].strip()
                if next_line.startswith(('-', '+')):
                    # Analyze the method
                    _, _, _, desc = analyze_method_signature(next_line)
                    # Replace the TODO line
                    output_lines.append(line.replace('TODO: Add method documentation.', desc).replace('TODO: add description.', desc))
                    modified = True
                    i += 1
                    continue
            # If it's a class/protocol description
            if 'TODO: add description' in line and i + 2 < len(lines):
                next_line = lines[i + 2].strip()
                if next_line.startswith('@interface') or next_line.startswith('@protocol'):
                    match = re.search(r'@(?:interface|protocol)\s+([a-zA-Z_][a-zA-Z0-9_]*)', next_line)
                    if match:
                        class_name = match.group(1)
                        # Keep generic for now
                        output_lines.append(line.replace('TODO: add description', f'{class_name} class or protocol'))
                        modified = True
                        i += 1
                        continue
        
        output_lines.append(line)
        i += 1
    
    if modified:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write('\n'.join(output_lines))
            return True
        except Exception as e:
            print(f"  ✗ Error writing {filepath}: {e}")
            return False
    
    return False

def main():
    """Main function."""
    base_dir = Path("/Users/heron/Development/gnustep/apps-gorm")
    
    # Find all .h files with TODO markers
    todo_files = []
    for pattern in ["GormCore/*.h", "InterfaceBuilder/*.h", "Applications/Gorm/*.h",
                    "GormObjCHeaderParser/*.h", "Plugins/**/*.h", "Tools/**/*.h"]:
        for f in base_dir.glob(pattern):
            if "Examples" not in str(f):
                try:
                    with open(f, 'r', encoding='utf-8', errors='ignore') as file:
                        if 'TODO' in file.read():
                            todo_files.append(f)
                except:
                    pass
    
    print(f"Found {len(todo_files)} files with TODO markers")
    print("=" * 60)
    
    fixed_count = 0
    for filepath in sorted(todo_files):
        rel_path = filepath.relative_to(base_dir)
        if fix_file(filepath):
            print(f"  ✓ Fixed: {rel_path}")
            fixed_count += 1
    
    print("=" * 60)
    print(f"Fixed {fixed_count} files")

if __name__ == "__main__":
    main()
