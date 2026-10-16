import os
import glob
import re

lib_dir = "lib"

# Find all dart files
dart_files = glob.glob(f"{lib_dir}/**/*.dart", recursive=True)

for file in dart_files:
    with open(file, 'r') as f:
        content = f.read()
    
    # We want to find Widget _buildHeader(BuildContext context) { ... return Row( ... children: [ Column( ... ), ElevatedButton.icon( ... ) ]
    # A bit complex with regex, better to use simple string replacement if possible or a smart regex.
    
    # Let's look for:
    # return Row(
    #   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    #   children: [
    #     Column(
    #       crossAxisAlignment: CrossAxisAlignment.start,
    
    pattern = r'(return Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*)Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,'
    
    if re.search(pattern, content):
        # We need to replace Column( with Expanded( child: Column( ... ) ), \n const SizedBox(width: 16),
        # Wait, the structure is:
        #         Column(
        #           crossAxisAlignment: CrossAxisAlignment.start,
        #           children: [
        #             ...
        #           ],
        #         ),
        #         ElevatedButton.icon(
        def replacer(match):
            prefix = match.group(1)
            return prefix + "Expanded(\n          child: Column(\n            crossAxisAlignment: CrossAxisAlignment.start,"
            
        new_content = re.sub(pattern, replacer, content)
        
        # Now we need to find the end of Column and add spacing before ElevatedButton
        # Let's assume the column ends right before ElevatedButton.icon(
        # e.g.,
        #         ),
        #         ElevatedButton.icon(
        # or
        #         ),
        #         if (x) ElevatedButton(...
        
        # We can just look for the first `),` that is at the same indentation as `Column(` or just right before the button.
        # It's better to just replace `\n        ),\n        ElevatedButton`
        # with `\n          ),\n        ),\n        const SizedBox(width: 16),\n        ElevatedButton`
        
        new_content = re.sub(
            r'\n        \),\n        ElevatedButton',
            r'\n          ),\n        ),\n        const SizedBox(width: 16),\n        ElevatedButton',
            new_content
        )
        
        # Also handle standard button
        new_content = re.sub(
            r'\n        \),\n        Container\(\n          height: 48,',
            r'\n          ),\n        ),\n        const SizedBox(width: 16),\n        Container(\n          height: 48,',
            new_content
        )
        
        if new_content != content:
            with open(file, 'w') as f:
                f.write(new_content)
            print(f"Refactored {file}")

