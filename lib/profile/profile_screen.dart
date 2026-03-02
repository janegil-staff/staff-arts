import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user.displayName ?? user.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover & avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: user.coverImage != null
                      ? CachedNetworkImage(
                          imageUrl: user.coverImage!, fit: BoxFit.cover)
                      : null,
                ),
                Positioned(
                  bottom: -40,
                  left: 16,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: user.avatar != null
                        ? CachedNetworkImageProvider(user.avatar!)
                        : null,
                    child: user.avatar == null
                        ? Text(user.name[0],
                            style: const TextStyle(fontSize: 32))
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName ?? user.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(user.bio),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stat(context, '${user.followersCount}', 'Followers'),
                      const SizedBox(width: 24),
                      _stat(context, '${user.followingCount}', 'Following'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(count,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
