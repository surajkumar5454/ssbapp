import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'twitter_feed.dart';

class SocialMediaFeed extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String url;

  const SocialMediaFeed({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (!url.contains('twitter.com') && !url.contains('x.com')) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildTwitterFeed(),
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterFeed() {
    final username = url.split('/').last;
    return TwitterFeed(username: username);
  }
} 