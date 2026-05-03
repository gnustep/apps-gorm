#!/usr/bin/env python3
"""
Comprehensive documentation fixer for Gorm headers.
Replaces poor automatic documentation with proper context-aware descriptions.
"""

import re
from pathlib import Path

# Mapping of common method patterns to better descriptions
METHOD_DOCS = {
    # Activation/State
    r'^\s*-\s*\(BOOL\)\s*activate\s*;': 'Activates the editor and makes it ready for use.',
    r'^\s*-\s*\(void\)\s*deactivate\s*;': 'Deactivates the editor and removes it from the view hierarchy.',
    r'^\s*-\s*\(void\)\s*close\s*;': 'Closes the editor and releases its resources.',
    r'^\s*-\s*\(BOOL\)\s*isOpened\s*;': 'Returns YES if the editor is currently open, NO otherwise.',
    r'^\s*-\s*\(void\)\s*setOpened:\s*\(BOOL\)': 'Sets whether the editor is open.',
    
    # Object access
    r'^\s*-\s*\([^)]*IBDocuments[^)]*\)\s*document\s*;': 'Returns the document that owns this editor.',
    r'^\s*-\s*\(id\)\s*editedObject\s*;': 'Returns the object being edited.',
    r'^\s*-\s*\(id\)\s*parent\s*;': 'Returns the parent editor if this is a subeditor.',
    r'^\s*-\s*\(NSArray\s*\*\)\s*selection\s*;': 'Returns an array of currently selected objects.',
    
    # View operations
    r'^\s*-\s*\(void\)\s*detachSubviews\s*;': 'Detaches subviews from the edited view.',
    r'^\s*-\s*\(void\)\s*postDraw:\s*\(NSRect\)': 'Performs post-draw operations after the view is drawn.',
    r'^\s*-\s*\(void\)\s*makeSelectionVisible:\s*\(BOOL\)': 'Shows or hides the selection markup.',
    r'^\s*-\s*\(void\)\s*frameDidChange:\s*\(id\)': 'Called when the frame of the edited view changes.',
    
    # Window operations
    r'^\s*-\s*\(NSWindow\s*\*\)\s*windowAndRect:\s*\(NSRect\s*\*\)[^;]*forObject:': 'Returns the window containing the object and fills the rect with its frame.',
    r'^\s*-\s*\(NSWindow\s*\*\)\s*window\s*;': 'Returns the window containing this editor.',
    r'^\s*-\s*\(void\)\s*orderFront\s*;': 'Orders the editor window to the front.',
    
    # Editing operations
    r'^\s*-\s*\(NSEvent\s*\*\)\s*editTextField:\s*[^;]*withEvent:': 'Begins editing a text field in response to an event.',
    r'^\s*-\s*\(void\)\s*validateFrame:\s*[^;]*withEvent:': 'Validates a frame during resizing or placement operations.',
    r'^\s*-\s*\(void\)\s*updateResizingWithFrame:': 'Updates the view during an interactive resize operation.',
    
    # Placement
    r'^\s*-\s*\(GormPlacementInfo\s*\*\)\s*initializeResizingInFrame:': 'Initializes placement information for a resize operation.',
}

# Mapping of class descriptions
CLASS_DOCS = {
    'GormViewEditor': 'GormViewEditor provides the base editor class for editing NSView and its subclasses within the Gorm interface builder. It handles view selection, manipulation, and subview management.',
    'GormViewWithSubviewsEditor': 'GormViewWithSubviewsEditor extends GormViewEditor to handle views that contain subviews, providing drag-and-drop and subview management capabilities.',
    'GormViewWithContentViewEditor': 'GormViewWithContentViewEditor handles editing of views that have a dedicated content view, such as NSScrollView and NSSplitView.',
    'GormStandaloneViewEditor': 'GormStandaloneViewEditor provides editing capabilities for views that exist outside of windows, such as custom views in the objects panel.',
    'GormWindowEditor': 'GormWindowEditor handles the editing of NSWindow objects, managing their content view and window-level properties.',
    'GormObjectEditor': 'GormObjectEditor provides the main objects panel editor that displays and manages all top-level objects in a Gorm document.',
    'GormResourceEditor': 'GormResourceEditor provides the base class for editors that manage resources such as images and sounds.',
    'GormImageEditor': 'GormImageEditor manages the display and editing of image resources within a Gorm document.',
    'GormSoundEditor': 'GormSoundEditor manages the display and editing of sound resources within a Gorm document.',
}

def fix_file(filepath: Path) -> bool:
    """Fix documentation in a file."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        return False
    
    original = content
    
    # Fix class/protocol descriptions
    for class_name, desc in CLASS_DOCS.items():
        # Look for generic descriptions
        pattern = rf'(/\*\*\s*\n\s*\*\s*){class_name}(?:\s+provides\s+{class_name}\s+class\s+or\s+protocol|[^.]*?\.)(\s*\n\s*\*/\s*\n@(?:interface|protocol)\s+{class_name})'
        replacement = rf'\g<1>{desc}\g<2>'
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    
    # Fix method documentation
    lines = content.split('\n')
    output_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Check if this line has poor documentation
        if re.match(r'^\s*\*\s*Returns the \w+\.\s*$', line) or \
           re.match(r'^\s*\*\s*Performs \w+ .*operation\.\s*$', line):
            # This is poor auto-generated documentation
            # Look ahead to find the method signature
            for j in range(i+1, min(i+5, len(lines))):
                if re.match(r'^\s*[-+]\s*\(', lines[j]):
                    # Found method signature
                    method_line = lines[j]
                    # Try to find a better description
                    for pattern, better_doc in METHOD_DOCS.items():
                        if re.match(pattern, method_line):
                            output_lines.append(re.sub(r'(^\s*\*\s*).*', rf'\g<1>{better_doc}', line))
                            i += 1
                            break
                    else:
                        output_lines.append(line)
                        i += 1
                    break
            else:
                output_lines.append(line)
                i += 1
        else:
            output_lines.append(line)
            i += 1
    
    content = '\n'.join(output_lines)
    
    if content != original:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            return False
    
    return False

def main():
    """Main function."""
    base_dir = Path("/Users/heron/Development/gnustep/apps-gorm")
    
    # Process all header files
    patterns = ["GormCore/*.h", "InterfaceBuilder/*.h", "Applications/Gorm/*.h",
                "GormObjCHeaderParser/*.h", "Plugins/**/*.h", "Tools/**/*.h"]
    
    fixed_count = 0
    for pattern in patterns:
        for filepath in base_dir.glob(pattern):
            if "Examples" not in str(filepath):
                if fix_file(filepath):
                    rel_path = filepath.relative_to(base_dir)
                    print(f"  ✓ Improved: {rel_path}")
                    fixed_count += 1
    
    print(f"\nImproved documentation in {fixed_count} files")

if __name__ == "__main__":
    main()
