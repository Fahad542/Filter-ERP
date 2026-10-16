import 'dart:io';

void main() {
  final file = File('lib/widgets/pos_widgets.dart');
  String content = file.readAsStringSync();
  
  // The issue occurred because when we replaced the body content, we stripped these closing brackets
  // We need to restore `                  ],
  //               ),
  //             ),` right before `            ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }`
  
  content = content.replaceFirst('''
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionBottomSheet''', '''
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionBottomSheet''');
  
  file.writeAsStringSync(content);
}
