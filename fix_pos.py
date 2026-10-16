import re

file_path = "lib/views/Workshop pos app/Product Grid/pos_product_grid_view.dart"
with open(file_path, 'r') as f:
    content = f.read()

target_block = """                                              }
                                            },
                                      style: ElevatedButton.styleFrom("""

replacement_block = """                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom("""

if target_block in content:
    content = content.replace(target_block, replacement_block)
    with open(file_path, 'w') as f:
        f.write(content)
    print("Replaced Successfully!")
else:
    print("Target block not found.")

