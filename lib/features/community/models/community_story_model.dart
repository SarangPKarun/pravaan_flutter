class CommunityStory {
  const CommunityStory({
    required this.id,
    required this.initials,
    required this.habitType,
    required this.daysQuit,
    required this.quote,
    required this.likeCount,
  });

  final String id;
  final String initials;
  final String habitType;
  final int daysQuit;
  final String quote;
  final int likeCount;
}

const List<CommunityStory> communityStories = [
  CommunityStory(
    id: 'priya_m',
    initials: 'PM',
    habitType: 'Cigarettes',
    daysQuit: 45,
    quote: "Never thought I'd make it past a week. Day 45 and I finally taste food again.",
    likeCount: 132,
  ),
  CommunityStory(
    id: 'rohan_d',
    initials: 'RD',
    habitType: 'Alcohol',
    daysQuit: 90,
    quote: 'My kids get their dad back every evening now. 90 days sober.',
    likeCount: 210,
  ),
  CommunityStory(
    id: 'aisha_k',
    initials: 'AK',
    habitType: 'Gutka',
    daysQuit: 21,
    quote: 'The urge still hits during chai breaks, but 21 days clean feels like a superpower.',
    likeCount: 58,
  ),
  CommunityStory(
    id: 'vikram_s',
    initials: 'VS',
    habitType: 'Junk Food',
    daysQuit: 60,
    quote: 'Lost 6kg and my energy is through the roof. 60 days of real food.',
    likeCount: 97,
  ),
  CommunityStory(
    id: 'meera_r',
    initials: 'MR',
    habitType: 'Gambling',
    daysQuit: 120,
    quote: 'Rebuilt my savings from zero. 120 days and counting — one day at a time.',
    likeCount: 145,
  ),
  CommunityStory(
    id: 'farhan_a',
    initials: 'FA',
    habitType: 'Cigarettes',
    daysQuit: 7,
    quote: 'First week is brutal but every craving I beat makes the next one easier.',
    likeCount: 34,
  ),
  CommunityStory(
    id: 'divya_n',
    initials: 'DN',
    habitType: 'Alcohol',
    daysQuit: 365,
    quote: 'One year today. I used to think I needed it to relax — turns out I just needed time.',
    likeCount: 402,
  ),
  CommunityStory(
    id: 'karan_t',
    initials: 'KT',
    habitType: 'Gutka',
    daysQuit: 180,
    quote: 'Half a year clean. My dentist actually smiled at my last checkup.',
    likeCount: 76,
  ),
];
