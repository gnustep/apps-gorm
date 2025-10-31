#!/usr/bin/env python3
"""
Comprehensive documentation improvement script for Gorm headers.
Replaces poor auto-generated documentation with context-aware descriptions.
"""

import re
import os
from pathlib import Path

# Comprehensive method documentation mappings
METHOD_IMPROVEMENTS = {
    # Common poor patterns to replace
    (r'Performs (\w+)\s+operation\.', r'- \(.*\)\s*\1'): 
        lambda m: f"Performs the {m.group(1)} operation.",
    
    (r'Returns the (\w+)\.', r'- \(.*\)\s*\1'):
        lambda m: f"Returns the {m.group(1)} value.",
    
    (r'Sets the property value\.', r'- \(void\)\s*set(\w+):'):
        lambda m: f"Sets the {m.group(1).lower()} property to the specified value.",
    
    (r'Opens the specified resource or editor\.', r'- \(.*\)\s*open(\w+):'):
        lambda m: f"Opens the {m.group(1).lower()} editor or resource.",
}

# Class-specific comprehensive improvements
CLASS_DOCS = {
    'GormPalettesManager': '''GormPalettesManager manages the palette panels that contain UI controls and objects available for drag-and-drop into interface designs. It loads palette bundles, maintains the palette panel display, and handles importing classes, images, and sounds from loaded palettes.''',
    
    'GormInspectorsManager': '''GormInspectorsManager coordinates the inspector panels that display and edit properties of selected objects. It maintains a cache of inspector instances, manages the inspector panel display, and handles switching between different inspector types based on the current selection.''',
    
    'GormObjectEditor': '''GormObjectEditor provides the base editor functionality for editing generic objects in the Gorm interface builder. It manages the objects palette view where top-level objects and custom instances are displayed and organized.''',
    
    'GormResourceManager': '''GormResourceManager provides the abstract base class for managing document resources such as images and sounds. Subclasses implement specific resource type handling including drag-and-drop support, resource inspection, and resource file management.''',
    
    'GormPluginManager': '''GormPluginManager handles loading and managing Gorm plugin bundles. Plugins extend Gorm's functionality by providing additional palettes, inspectors, or custom object types.''',
    
    'GormViewWithSubviewsEditor': '''GormViewWithSubviewsEditor extends GormViewEditor to handle views that contain multiple subviews. It provides subview management, selection handling within the view hierarchy, and drag-and-drop support for adding new subviews.''',
    
    'GormViewWithContentViewEditor': '''GormViewWithContentViewEditor specializes in editing views that have a designated content view, such as NSScrollView or NSBox. It manages the content view separately from the container view and handles the relationship between them.''',
    
    'GormWindowEditor': '''GormWindowEditor handles the editing of NSWindow objects, managing their content view and window-level properties. It serves as the top-level editor for window-based interface designs.''',
    
    'GormScrollViewEditor': '''GormScrollViewEditor manages editing of NSScrollView instances, handling the document view, scroll bars, and scroll view-specific attributes. It coordinates editing of both the scroll view container and its document view content.''',
    
    'GormSplitViewEditor': '''GormSplitViewEditor provides editing support for NSSplitView instances, managing the split view's subviews and divider positions. It handles the special constraints and layout requirements of split views.''',
    
    'GormSound': '''GormSound represents a sound resource within a Gorm document, encapsulating sound data that can be referenced by interface elements. It manages sound file loading, storage, and provides access to the sound data for playback or export.''',
}

# Method-specific improvements based on context
METHOD_SPECIFIC = {
    'loadPalette:': 'Loads a palette bundle from the specified file system path. The palette bundle contains UI components and resources that can be used in interface design.',
    'openPalette:': 'Opens the palette panel window, making the available UI components visible for dragging into designs.',
    'panel': 'Returns the panel window that displays the current palette contents.',
    'setCurrentPalette:': 'Sets the currently active palette to the specified palette object, updating the display to show that palette\'s contents.',
    'importClasses:withDictionary:': 'Imports custom class definitions from a palette. The classes array contains class names and the dictionary maps class names to their parent classes and configurations.',
    'importedClasses': 'Returns a dictionary of all classes that have been imported from loaded palettes, mapping class names to their configurations.',
    'importImages:withBundle:': 'Imports image resources from a palette bundle. The images become available for use in interface designs.',
    'importedImages': 'Returns an array of all image resources that have been imported from loaded palettes.',
    'importSounds:withBundle:': 'Imports sound resources from a palette bundle. The sounds become available for use in interface designs.',
    'importedSounds': 'Returns an array of all sound resources that have been imported from loaded palettes.',
    'substituteClasses': 'Returns a dictionary mapping original class names to substitute classes, used when a palette provides a replacement implementation for a standard class.',
    'setClassInspector': 'Sets the inspector panel to display the class inspector, which shows class hierarchy and allows class editing.',
    'setCurrentInspector:': 'Sets the currently active inspector to the specified inspector object, updating the panel to display that inspector\'s view.',
    'updateSelection': 'Updates the inspector panel to reflect the currently selected object or objects, switching to the appropriate inspector type if needed.',
}

def extract_method_name(line):
    """Extract method name from method declaration."""
    match = re.search(r'[-+]\s*\([^)]+\)\s*(\w+)', line)
    if match:
        return match.group(1)
    return None

def improve_file(filepath):
    """Improve documentation in a single header file."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return False
    
    original_content = content
    changed = False
    
    # Improve class documentation
    for class_name, class_doc in CLASS_DOCS.items():
        # Match class documentation
        pattern = rf'(/\*\*\s*\*\s*{class_name} provides {class_name} class or protocol\.\s*\*/)'
        replacement = f'''/**
 * {class_doc}
 */'''
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            changed = True
    
    # Improve method documentation with specific methods
    lines = content.split('\n')
    new_lines = []
    in_comment = False
    comment_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Track comment blocks
        if '/**' in line:
            in_comment = True
            comment_lines = [line]
            i += 1
            continue
        elif in_comment:
            comment_lines.append(line)
            if '*/' in line:
                # End of comment - check next line for method
                in_comment = False
                if i + 1 < len(lines):
                    next_line = lines[i + 1]
                    method_name = extract_method_name(next_line)
                    
                    # Check if we have specific documentation for this method
                    if method_name:
                        for method_sig, method_doc in METHOD_SPECIFIC.items():
                            if method_name in method_sig:
                                # Replace comment block
                                comment_lines = [
                                    '/**',
                                    f' * {method_doc}',
                                    ' */'
                                ]
                                changed = True
                                break
                
                new_lines.extend(comment_lines)
                comment_lines = []
            i += 1
            continue
        
        new_lines.append(line)
        i += 1
    
    if changed:
        new_content = '\n'.join(new_lines)
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
        except Exception as e:
            print(f"Error writing {filepath}: {e}")
            return False
    
    return False

def main():
    """Main function to process all header files."""
    base_dir = Path('/Users/heron/Development/gnustep/apps-gorm')
    
    # Find all header files
    header_files = []
    for root, dirs, files in os.walk(base_dir):
        # Skip certain directories
        if '.git' in root or 'build' in root:
            continue
        for file in files:
            if file.endswith('.h'):
                header_files.append(os.path.join(root, file))
    
    print(f"Found {len(header_files)} header files")
    
    improved_count = 0
    for filepath in sorted(header_files):
        rel_path = os.path.relpath(filepath, base_dir)
        if improve_file(filepath):
            print(f"✓ Improved: {rel_path}")
            improved_count += 1
    
    print(f"\nImproved {improved_count} files")

if __name__ == '__main__':
    main()
