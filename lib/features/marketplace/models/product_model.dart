enum ProductCategory { nrt, herbal, fitness, mentalHealth }

extension ProductCategoryLabel on ProductCategory {
  String get label => switch (this) {
        ProductCategory.nrt => 'NRT',
        ProductCategory.herbal => 'Herbal',
        ProductCategory.fitness => 'Fitness',
        ProductCategory.mentalHealth => 'Mental Health',
      };
}

class ProductReview {
  const ProductReview({required this.author, required this.rating, required this.comment});

  final String author;
  final int rating; // 1-5
  final String comment;
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.benefits,
    required this.price,
    required this.category,
    required this.emoji,
    required this.reviews,
  });

  final String id;
  final String name;
  final String brand;
  final String description;
  final List<String> benefits;
  final double price; // INR
  final ProductCategory category;
  final String emoji;
  final List<ProductReview> reviews;
}

const List<ProductModel> mockProducts = [
  ProductModel(
    id: 'nicotine_gum',
    name: 'Nicotine Gum (2mg)',
    brand: 'Nicorette',
    description: 'Sugar-free gum to curb sudden cravings on the go.',
    benefits: [
      'Relieves sudden cravings within minutes',
      'Sugar-free, won\'t harm your teeth',
      'Discreet — chew anywhere, anytime',
    ],
    price: 249,
    category: ProductCategory.nrt,
    emoji: '🍬',
    reviews: [
      ProductReview(
        author: 'Aarav K.',
        rating: 4,
        comment: 'Really helps during meetings when I can\'t step out for a smoke.',
      ),
      ProductReview(
        author: 'Priya S.',
        rating: 5,
        comment: 'Kept a pack at my desk for the first month — game changer.',
      ),
    ],
  ),
  ProductModel(
    id: 'nicotine_patches',
    name: 'Nicotine Patches (7-pack)',
    brand: 'Nicotinell',
    description: 'Slow-release 21mg patches for steady, all-day craving control.',
    benefits: [
      'One patch lasts a full 24 hours',
      'No need to remember multiple doses',
      'Steady release avoids sharp craving spikes',
    ],
    price: 899,
    category: ProductCategory.nrt,
    emoji: '🩹',
    reviews: [
      ProductReview(
        author: 'Rohan M.',
        rating: 5,
        comment: 'Set it and forget it — much easier than gum for me.',
      ),
      ProductReview(
        author: 'Sneha T.',
        rating: 4,
        comment: 'Slight itching at first but worth it for the convenience.',
      ),
    ],
  ),
  ProductModel(
    id: 'nicotine_lozenges',
    name: 'Nicotine Lozenges',
    brand: 'Nicorette',
    description: 'Discreet lozenges that dissolve cravings wherever you are.',
    benefits: [
      'No chewing required — just let it dissolve',
      'Compact and easy to carry',
      'Available in mint and fruit flavours',
    ],
    price: 349,
    category: ProductCategory.nrt,
    emoji: '💊',
    reviews: [
      ProductReview(
        author: 'Karan D.',
        rating: 4,
        comment: 'Good for late-night cravings when gum feels like too much effort.',
      ),
      ProductReview(
        author: 'Meera J.',
        rating: 5,
        comment: 'My favourite of the NRT options — very discreet at work.',
      ),
    ],
  ),
  ProductModel(
    id: 'herbal_tea',
    name: 'Herbal Craving Tea',
    brand: 'Himalaya Wellness',
    description: 'Ayurvedic blend to soothe withdrawal symptoms naturally.',
    benefits: [
      'Calms irritability during withdrawal',
      'Caffeine-free, safe for evening use',
      'Made from traditional Ayurvedic herbs',
    ],
    price: 299,
    category: ProductCategory.herbal,
    emoji: '🍵',
    reviews: [
      ProductReview(
        author: 'Divya R.',
        rating: 4,
        comment: 'Nice ritual to replace my old smoke breaks with.',
      ),
      ProductReview(
        author: 'Vikram P.',
        rating: 3,
        comment: 'Tastes a bit earthy but I do feel calmer after a cup.',
      ),
    ],
  ),
  ProductModel(
    id: 'ashwagandha',
    name: 'Ashwagandha Capsules',
    brand: 'Himalaya Wellness',
    description: 'Adaptogen supplement to ease stress-driven cravings.',
    benefits: [
      'Helps the body manage stress hormones',
      'May reduce stress-triggered cravings',
      'Simple once-daily capsule',
    ],
    price: 449,
    category: ProductCategory.herbal,
    emoji: '🌿',
    reviews: [
      ProductReview(
        author: 'Ananya B.',
        rating: 5,
        comment: 'Noticed I was less on-edge after a couple of weeks.',
      ),
      ProductReview(
        author: 'Farhan A.',
        rating: 4,
        comment: 'Pairs well with the herbal tea for an evening routine.',
      ),
    ],
  ),
  ProductModel(
    id: 'herbal_detox_kit',
    name: 'Herbal Detox Kit',
    brand: 'Patanjali',
    description: '14-day herbal cleanse to support your quit journey.',
    benefits: [
      'Full 14-day supply in one kit',
      'Supports the body through early withdrawal',
      'Includes a simple daily routine card',
    ],
    price: 699,
    category: ProductCategory.herbal,
    emoji: '🌱',
    reviews: [
      ProductReview(
        author: 'Ishaan V.',
        rating: 4,
        comment: 'Liked having a structured 2-week plan to follow.',
      ),
      ProductReview(
        author: 'Neha G.',
        rating: 4,
        comment: 'Good starter kit if you\'re not sure where to begin.',
      ),
    ],
  ),
  ProductModel(
    id: 'resistance_bands',
    name: 'Resistance Bands Set',
    brand: 'Boldfit',
    description: 'Channel a craving into a quick workout, anywhere.',
    benefits: [
      'Five resistance levels in one set',
      'Compact enough for a desk drawer or bag',
      'Great for a 2-minute craving-buster workout',
    ],
    price: 599,
    category: ProductCategory.fitness,
    emoji: '🏋️',
    reviews: [
      ProductReview(
        author: 'Aditya N.',
        rating: 5,
        comment: 'My go-to when a craving hits at my desk. Works every time.',
      ),
      ProductReview(
        author: 'Ritika C.',
        rating: 4,
        comment: 'Good quality bands, sturdy handles.',
      ),
    ],
  ),
  ProductModel(
    id: 'yoga_mat',
    name: 'Yoga Mat',
    brand: 'Decathlon',
    description: 'Non-slip mat for stress-relief stretching and breathing.',
    benefits: [
      'Non-slip surface for safe stretching',
      'Lightweight and easy to roll up',
      'Great for guided breathing exercises',
    ],
    price: 799,
    category: ProductCategory.fitness,
    emoji: '🧘',
    reviews: [
      ProductReview(
        author: 'Simran K.',
        rating: 5,
        comment: 'Ten minutes of stretching replaced my morning cigarette.',
      ),
      ProductReview(
        author: 'Yash R.',
        rating: 4,
        comment: 'Decent grip, doesn\'t slide around during workouts.',
      ),
    ],
  ),
  ProductModel(
    id: 'meditation_pass',
    name: 'Guided Meditation (3-Month Pass)',
    brand: 'Calm Mind',
    description: 'Daily calming sessions to manage stress without your habit.',
    benefits: [
      'New guided session added daily',
      'Sessions as short as 5 minutes',
      'Craving-specific meditations included',
    ],
    price: 599,
    category: ProductCategory.mentalHealth,
    emoji: '🧠',
    reviews: [
      ProductReview(
        author: 'Tanvi M.',
        rating: 5,
        comment: 'The craving-specific sessions are surprisingly effective.',
      ),
      ProductReview(
        author: 'Arjun S.',
        rating: 4,
        comment: 'Good habit to build alongside checking in on the app.',
      ),
    ],
  ),
  ProductModel(
    id: 'counseling_session',
    name: '1-on-1 Counseling Session',
    brand: 'MindWell Care',
    description: '30-minute video call with a certified quit-coach.',
    benefits: [
      '30 minutes one-on-one with a certified coach',
      'Personalised strategies for your triggers',
      'Fully confidential video session',
    ],
    price: 999,
    category: ProductCategory.mentalHealth,
    emoji: '💬',
    reviews: [
      ProductReview(
        author: 'Pooja L.',
        rating: 5,
        comment: 'Talking it through with someone made a real difference.',
      ),
      ProductReview(
        author: 'Manav H.',
        rating: 5,
        comment: 'Coach gave me a concrete plan for my worst trigger times.',
      ),
    ],
  ),
];
