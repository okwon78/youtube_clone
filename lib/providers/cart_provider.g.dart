// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 장바구니 상태를 관리하는 Notifier.
/// 상품 추가/삭제/수량 변경을 처리한다.

@ProviderFor(Cart)
final cartProvider = CartProvider._();

/// 장바구니 상태를 관리하는 Notifier.
/// 상품 추가/삭제/수량 변경을 처리한다.
final class CartProvider extends $NotifierProvider<Cart, Set<CartItem>> {
  /// 장바구니 상태를 관리하는 Notifier.
  /// 상품 추가/삭제/수량 변경을 처리한다.
  CartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartHash();

  @$internal
  @override
  Cart create() => Cart();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<CartItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<CartItem>>(value),
    );
  }
}

String _$cartHash() => r'9e861e82f080c69f9dad7dc7b8d1936e5fdb65ef';

/// 장바구니 상태를 관리하는 Notifier.
/// 상품 추가/삭제/수량 변경을 처리한다.

abstract class _$Cart extends $Notifier<Set<CartItem>> {
  Set<CartItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<CartItem>, Set<CartItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<CartItem>, Set<CartItem>>,
              Set<CartItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 장바구니에 담긴 총 상품 개수(수량 합계)를 제공하는 provider.

@ProviderFor(cartItemCount)
final cartItemCountProvider = CartItemCountProvider._();

/// 장바구니에 담긴 총 상품 개수(수량 합계)를 제공하는 provider.

final class CartItemCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 장바구니에 담긴 총 상품 개수(수량 합계)를 제공하는 provider.
  CartItemCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartItemCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartItemCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return cartItemCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$cartItemCountHash() => r'b6e377cde02c574c62745a0dcbea6f2e8f647ce1';

/// 장바구니 총 금액을 제공하는 provider.

@ProviderFor(cartTotalPrice)
final cartTotalPriceProvider = CartTotalPriceProvider._();

/// 장바구니 총 금액을 제공하는 provider.

final class CartTotalPriceProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// 장바구니 총 금액을 제공하는 provider.
  CartTotalPriceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartTotalPriceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartTotalPriceHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return cartTotalPrice(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$cartTotalPriceHash() => r'5a4a532174d0ebec14a7b52015a6516fee5ac896';
