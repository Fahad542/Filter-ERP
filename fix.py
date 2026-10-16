import re

file_path = "lib/views/Workshop pos app/Product Grid/pos_product_grid_view.dart"
with open(file_path, 'r') as f:
    content = f.read()

# Specifically target the end of the onPressed block for the ElevatedButton on line 600
# It seems there's a missing brace for the if/else block inside onPressed
match_str = """                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom("""

replace_str = """                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom("""

# Actually perform a correct replacement
match_str2 = """                                                  }
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom("""

replace_str2 = """                                                  }
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom("""

match_str3 = """                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom("""
replace_str3 = """                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom("""

fixed_content = content.replace("""                                                  }
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(""", """                                                  }
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(""")

with open(file_path, 'w') as f:
    f.write(fixed_content)

print("Formatting attempted.")
