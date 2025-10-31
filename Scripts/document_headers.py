#!/usr/bin/env python3
"""
Script to add autogsdoc documentation to Objective-C header files.
This script scans header files and adds properly formatted autogsdoc comments.

IMPORTANT: This script follows the autogsdoc specification:
- Uses /** */ style comments
- Has * on each line (consistently spaced)
- Does NOT use @param or @return tags (not part of autogsdoc spec)
"""

import re
import sys
from pathlib import Path

def has_documentation(lines, current_index):
    """Check if there's documentation before the current line."""
    if current_index == 0:
        return False
    
    # Check previous non-empty lines
    for i in range(current_index - 1, max(0, current_index - 10), -1):
        stripped = lines[i].strip()
        if not stripped:
            continue
        # Check for documentation comment
        if stripped.startswith('/**') or '*/' in stripped:
            return True
        # Check for regular comments or other declarations
        if stripped.startswith('//') or stripped.startswith('/*'):
            return False
        # If we hit another declaration, stop
        if stripped.startswith('@') or stripped.startswith('-') or stripped.startswith('+'):
            return False
    return False

def generate_method_doc(method_signature):
    """Generate a basic documentation comment for a method."""
    # Try to parse method signature to create meaningful documentation
    sig = method_signature.strip()
    
    # Check for common patterns
    if 'init' in sig.lower():
        return "/**\n * Initializes and returns a new instance.\n */\n"
    elif sig.startswith('+ '):
        # Class method
        if 'alloc' in sig.lower():
            return "/**\n * Allocates and returns a new instance.\n */\n"
        else:
            return "/**\n * Class method - provides TODO: add description.\n */\n"
    elif 'set' in sig.lower() and ':' in sig:
        # Setter method
        return "/**\n * Sets the property value.\n */\n"
    elif 'get' in sig.lower() or ('returns' in sig.lower() and ':' not in sig):
        # Getter method
        return "/**\n * Returns the property value.\n */\n"
    elif 'is' in sig.lower() and ':' not in sig:
        return "/**\n * Returns YES if the condition is true, NO otherwise.\n */\n"
    else:
        return "/**\n * TODO: Add method documentation.\n */\n"

def generate_interface_doc(class_name):
    """Generate documentation for an @interface."""
    return f"/**\n * {class_name} provides TODO: add description.\n */\n"

def generate_protocol_doc(protocol_name):
    """Generate documentation for an @protocol."""
    return f"/**\n * {protocol_name} defines TODO: add description.\n */\n"

def process_header_file(filepath, dry_run=False):
    """Process a single header file and add documentation where missing."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"  ✗ Error reading {filepath}: {e}")
        return False
    
    output_lines = []
    i = 0
    modified = False
    
    while i < len(lines):
        line = lines[i]
        
        # Check for interface declarations
        interface_match = re.match(r'^@interface\s+([a-zA-Z_][a-zA-Z0-9_]*)', line)
        if interface_match:
            if not has_documentation(lines, i):
                class_name = interface_match.group(1)
                doc = generate_interface_doc(class_name)
                output_lines.append(doc)
                modified = True
            output_lines.append(line)
        
        # Check for protocol declarations
        elif re.match(r'^@protocol\s+([a-zA-Z_][a-zA-Z0-9_]*)', line):
            if not has_documentation(lines, i):
                protocol_match = re.match(r'^@protocol\s+([a-zA-Z_][a-zA-Z0-9_]*)', line)
                protocol_name = protocol_match.group(1)
                doc = generate_protocol_doc(protocol_name)
                output_lines.append(doc)
                modified = True
            output_lines.append(line)
        
        # Check for method declarations (must start at beginning of line or after whitespace)
        elif re.match(r'^[-+]\s*\(', line):
            if not has_documentation(lines, i):
                doc = generate_method_doc(line)
                output_lines.append(doc)
                modified = True
            output_lines.append(line)
        
        # Check for extern variable declarations
        elif re.match(r'^extern\s+', line) and not re.search(r';\s*$', line.strip()):
            if not has_documentation(lines, i):
                output_lines.append("/** TODO: Add documentation. */\n")
                modified = True
            output_lines.append(line)
        
        else:
            output_lines.append(line)
        
        i += 1
    
    if modified and not dry_run:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(output_lines)
            return True
        except Exception as e:
            print(f"  ✗ Error writing {filepath}: {e}")
            return False
    
    return modified

def main():
    """Main function to process all header files."""
    base_dir = Path("/Users/heron/Development/gnustep/apps-gorm")
    
    # Parse command line arguments
    dry_run = '--dry-run' in sys.argv
    
    if dry_run:
        print("DRY RUN MODE - No files will be modified")
        print("=" * 60)
    
    # Find all .h files
    header_files = []
    for pattern in ["GormCore/*.h", "InterfaceBuilder/*.h", "Applications/Gorm/*.h",
                    "GormObjCHeaderParser/*.h", "Plugins/**/*.h", "Tools/**/*.h"]:
        header_files.extend(base_dir.glob(pattern))
    
    # Remove duplicates and sort
    header_files = sorted(set(header_files))
    
    # Skip example files
    header_files = [f for f in header_files if "Documentation/Examples" not in str(f)]
    
    print(f"Found {len(header_files)} header files to process")
    print("=" * 60)
    
    modified_count = 0
    for header_file in header_files:
        rel_path = header_file.relative_to(base_dir)
        if process_header_file(header_file, dry_run):
            print(f"  ✓ Would modify: {rel_path}" if dry_run else f"  ✓ Modified: {rel_path}")
            modified_count += 1
    
    print("=" * 60)
    if dry_run:
        print(f"Would modify {modified_count} files out of {len(header_files)}")
        print("\nRun without --dry-run to actually modify files")
    else:
        print(f"Modified {modified_count} files out of {len(header_files)}")

if __name__ == "__main__":
    main()
