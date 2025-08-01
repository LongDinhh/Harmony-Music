import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../navigator.dart';
import '../../utils/haptic_utils.dart';

class CategoryButtons extends StatefulWidget {
  const CategoryButtons({super.key});

  @override
  State<CategoryButtons> createState() => _CategoryButtonsState();
}

class _CategoryButtonsState extends State<CategoryButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Danh sách các danh mục
  final List<String> _categories = [
    'Dễ ngủ',
    'Nạp năng lượng',
    'Thư giãn',
    'Tập trung',
    'Vui vẻ',
    'Lãng mạn',
    'Năng động',
    'Dịu êm',
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedIndex;
          return Container(
            margin: EdgeInsets.only(
              right: index == _categories.length - 1 ? 0 : 12.0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15.0),
                onTap: () {
                  _animationController.forward().then((_) {
                    _animationController.reverse();
                  });
                  HapticUtils.screenNavigationHaptic();

                  setState(() {
                    _selectedIndex = index;
                  });

                  // Chuyển đến màn hình tìm kiếm với danh mục được chọn
                  Get.toNamed(ScreenNavigationSetup.searchScreen,
                      id: ScreenNavigationSetup.id,
                      arguments: {
                        'focus': true,
                        'category': _categories[index]
                      });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).focusColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Theme.of(context).focusColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _categories[index],
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
