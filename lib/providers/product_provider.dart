import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/product.dart';

part 'product_provider.g.dart';

/// 판매할 상품 목록을 제공하는 provider.
/// 지금은 정적 데이터지만, 나중에 비동기 로딩으로 쉽게 교체할 수 있다.
List<Product> productlist = [
  Product(
    id: 1,
    name: 'Vintage Film Camera',
    description: '잘 작동하는 빈티지 필름 카메라',
    price: 89.99,
    imageUrl: 'https://picsum.photos/seed/camera/400/400',
  ),
  Product(
    id: 2,
    name: 'Leather Backpack',
    description: '가죽 백팩, 사용감 약간 있음',
    price: 45.00,
    imageUrl: 'https://picsum.photos/seed/backpack/400/400',
  ),
  Product(
    id: 3,
    name: 'Acoustic Guitar',
    description: '입문용 어쿠스틱 기타',
    price: 120.00,
    imageUrl: 'https://picsum.photos/seed/guitar/400/400',
  ),
  Product(
    id: 4,
    name: 'Desk Lamp',
    description: '따뜻한 빛의 책상 램프',
    price: 18.50,
    imageUrl: 'https://picsum.photos/seed/lamp/400/400',
  ),
  Product(
    id: 5,
    name: 'Vinyl Records (10장)',
    description: '70-80년대 LP 모음',
    price: 60.00,
    imageUrl: 'https://picsum.photos/seed/vinyl/400/400',
  ),
  Product(
    id: 6,
    name: 'Wooden Chair',
    description: '튼튼한 원목 의자',
    price: 35.00,
    imageUrl: 'https://picsum.photos/seed/chair/400/400',
  ),
  Product(
    id: 7,
    name: 'Mountain Bike',
    description: '21단 산악 자전거',
    price: 210.00,
    imageUrl: 'https://picsum.photos/seed/bike/400/400',
  ),
  Product(
    id: 8,
    name: 'Coffee Maker',
    description: '드립 커피 메이커',
    price: 27.99,
    imageUrl: 'https://picsum.photos/seed/coffee/400/400',
  ),
  Product(
    id: 9,
    name: 'Board Game Set',
    description: '보드게임 세트 (부품 모두 포함)',
    price: 22.00,
    imageUrl: 'https://picsum.photos/seed/boardgame/400/400',
  ),
  Product(
    id: 10,
    name: 'Potted Plant',
    description: '실내용 화분 식물',
    price: 14.00,
    imageUrl: 'https://picsum.photos/seed/plant/400/400',
  ),
  Product(
    id: 11,
    name: '에어팟',
    description: '애플 이어폰',
    price: 14.00,
    imageUrl: 'https://picsum.photos/seed/korea/400/400',
  ),
];

@riverpod
List<Product> products(Ref ref) {
  return productlist;
}
