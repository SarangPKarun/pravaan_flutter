// Static catalog of relatable purchases, used to translate a savings rate
// into "here's what that could buy" — sorted ascending by price.

class OpportunityItem {
  const OpportunityItem({required this.name, required this.emoji, required this.price});

  final String name;
  final String emoji;
  final double price; // INR
}

const List<OpportunityItem> opportunityItems = [
  OpportunityItem(name: 'Coffee treat', emoji: '☕', price: 150),
  OpportunityItem(name: 'Movie night', emoji: '🎬', price: 500),
  OpportunityItem(name: 'Nice dinner out', emoji: '🍽️', price: 1500),
  OpportunityItem(name: 'New sneakers', emoji: '👟', price: 4000),
  OpportunityItem(name: 'Wireless earbuds', emoji: '🎧', price: 8000),
  OpportunityItem(name: 'Weekend getaway', emoji: '🏖️', price: 15000),
  OpportunityItem(name: 'Smartwatch', emoji: '⌚', price: 25000),
  OpportunityItem(name: 'New smartphone', emoji: '📱', price: 50000),
  OpportunityItem(name: 'Laptop', emoji: '💻', price: 90000),
  OpportunityItem(name: 'International trip', emoji: '✈️', price: 150000),
];
