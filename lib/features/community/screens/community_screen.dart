import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../models/community_story_model.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final Set<String> _likedStoryIds = {};

  void _toggleLike(String id) {
    setState(() {
      if (_likedStoryIds.contains(id)) {
        _likedStoryIds.remove(id);
      } else {
        _likedStoryIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Community')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: communityStories.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final story = communityStories[i];
                return _StoryCard(
                  story: story,
                  liked: _likedStoryIds.contains(story.id),
                  onToggleLike: () => _toggleLike(story.id),
                );
              },
            ),
          ),
          const _JoinCommunityFooter(),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.liked, required this.onToggleLike});

  final CommunityStory story;
  final bool liked;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final likeCount = story.likeCount + (liked ? 1 : 0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  story.initials,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  story.habitType,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '🔥 ${story.daysQuit} days',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '"${story.quote}"',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              GestureDetector(
                onTap: onToggleLike,
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_outline,
                  size: 20,
                  color: liked ? AppColors.secondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$likeCount',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinCommunityFooter extends StatelessWidget {
  const _JoinCommunityFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: double.infinity,
            child: AppButton(label: 'Join Community', onPressed: null),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coming soon',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
