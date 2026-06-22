import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/product.dart';

part 'cart_provider.g.dart';

/// 장바구니에 담긴 개별 항목. 상품과 수량을 함께 보관한다.
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }

  /// Set에서 같은 상품을 동일 항목으로 취급하기 위해 상품 id 기준으로 동등성을 비교한다.
  @override
  bool operator ==(Object other) =>
      other is CartItem && other.product.id == product.id;

  @override
  int get hashCode => product.id.hashCode;
}

/// 장바구니 상태를 관리하는 Notifier.
/// 상품 추가/삭제/수량 변경을 처리한다.
@riverpod
class Cart extends _$Cart {
  @override
  Set<CartItem> build() => const {};

  /// 상품을 장바구니에 추가한다. 이미 있으면 수량을 1 늘린다.
  void add(Product product) {
    final exists = state.any((item) => item.product.id == product.id);
    if (!exists) {
      state = {...state, CartItem(product: product)};
    } else {
      state = {
        for (final item in state)
          item.product.id == product.id
              ? item.copyWith(quantity: item.quantity + 1)
              : item,
      };
    }
  }

  /// 상품 수량을 1 줄인다. 수량이 0이 되면 항목을 제거한다.
  void decrease(Product product) {
    final item = state
        .where((item) => item.product.id == product.id)
        .firstOrNull;
    if (item == null) return;

    if (item.quantity <= 1) {
      remove(product);
    } else {
      state = {
        for (final i in state)
          i.product.id == product.id ? i.copyWith(quantity: i.quantity - 1) : i,
      };
    }
  }

  /// 상품을 장바구니에서 완전히 제거한다.
  void remove(Product product) {
    state = state.where((item) => item.product.id != product.id).toSet();
  }

  /// 장바구니를 비운다.
  void clear() {
    state = const {};
  }
}

/// 장바구니에 담긴 총 상품 개수(수량 합계)를 제공하는 provider.
@riverpod
int cartItemCount(Ref ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
}

/// 장바구니 총 금액을 제공하는 provider.
@riverpod
double cartTotalPrice(Ref ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.totalPrice);
}
