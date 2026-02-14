import 'package:flutter/material.dart';

import 'tags_section.dart';
import 'tasks_section.dart';

class SidebarSections extends StatelessWidget {
  const SidebarSections({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 如果高度不足，使用滚动视图
          if (constraints.maxHeight < 300) {
            return SingleChildScrollView(
              child: Column(
                children: const [
                  SizedBox(height: 150, child: TasksSection()),
                  SizedBox(height: 200, child: TagsSection()),
                ],
              ),
            );
          }
          // 正常情况下使用 Expanded 布局
          return Column(
            children: const [
              SizedBox(height: 200, child: TasksSection()),
              Expanded(child: TagsSection()),
            ],
          );
        },
      ),
    );
  }
}
