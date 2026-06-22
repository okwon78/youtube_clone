import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider).toList();
    final totalPrice = ref.watch(cartTotalPriceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('비우기'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(child: Text('장바구니가 비어 있어요'))
          : ListView.separated(
              itemCount: cart.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cart[index];
                // 상품 id를 key로 줘서, 목록이 바뀌어도 각 행의 노출 상태가
                // 올바른 항목에 유지되도록 한다.
                return _CartItemTile(
                  key: ValueKey(item.product.id),
                  item: item,
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('합계', style: TextStyle(fontSize: 16)),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// 장바구니의 개별 행.
/// 오른쪽으로 스와이프하면 삭제 버튼을 노출하고, 다시 오른쪽으로 스와이프하면 숨긴다.
/// 노출된 삭제 버튼을 누르면 해당 상품을 장바구니에서 제거한다.
class _CartItemTile extends ConsumerStatefulWidget {
  const _CartItemTile({super.key, required this.item});

  final CartItem item;

  @override
  ConsumerState<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<_CartItemTile> {
  /// 삭제 버튼 노출 여부.
  bool _revealed = false;

  /// 노출 시 컨텐츠가 오른쪽으로 밀려나며 드러나는 영역(삭제 버튼)의 너비.
  static const double _actionWidth = 85;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final product = item.product;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 0) {
          // 오른쪽으로 스와이프 → 토글(노출 ↔ 숨김)
          setState(() => _revealed = !_revealed);
        } else if (velocity < 0) {
          // 왼쪽으로 스와이프 → 닫기
          setState(() => _revealed = false);
        }
      },
      child: Stack(
        children: [
          // 컨텐츠 뒤(왼쪽)에 깔리는 삭제 버튼.
          Positioned.fill(
            child: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _actionWidth,
                child: TextButton(
                  onPressed: () =>
                      ref.read(cartProvider.notifier).remove(product),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        '삭제',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 스와이프에 따라 좌우로 미끄러지는 실제 항목 컨텐츠.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              _revealed ? _actionWidth : 0,
              0,
              0,
            ),
            // 닫힌 상태에서 뒤의 빨간 배경이 비치지 않도록 불투명 배경을 깐다.
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListTile(
                // 노출 상태에서 항목을 탭하면 삭제 버튼을 닫는다.
                onTap: _revealed
                    ? () => setState(() => _revealed = false)
                    : null,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    product.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
                title: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      // 수량이 1개이면 감소 버튼을 비활성화한다.
                      onPressed: item.quantity <= 1
                          ? null
                          : () => ref
                                .read(cartProvider.notifier)
                                .decrease(product),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () =>
                          ref.read(cartProvider.notifier).add(product),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
