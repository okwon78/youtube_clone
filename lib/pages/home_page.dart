import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'cart_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    // 장바구니에 담긴 서로 다른 상품의 개수(고유 항목 수).
    final uniqueCount = ref.watch(cartProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage Sale Products'),
        actions: [
          Badge.count(
            count: uniqueCount,
            isLabelVisible: uniqueCount > 0,
            alignment: AlignmentDirectional.topStart,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              tooltip: '장바구니',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(5),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _ProductCard(product: products[index]);
        },
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 해당 상품이 장바구니에 들어 있는지 여부.
    final inCart = ref.watch(
      cartProvider.select(
        (cart) => cart.any((item) => item.product.id == product.id),
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image, size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: inCart
                        ? OutlinedButton.icon(
                            onPressed: () {
                              ref.read(cartProvider.notifier).remove(product);
                            },
                            icon: const Icon(Icons.remove_shopping_cart, size: 18),
                            label: const Text('Remove'),
                          )
                        : FilledButton.icon(
                            onPressed: () {
                              ref.read(cartProvider.notifier).add(product);
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Add to Cart'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
