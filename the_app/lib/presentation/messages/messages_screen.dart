import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routing/routes.dart';
import '../../core/providers/message_provider.dart';
import '../../data/models/message_model.dart';
import '../shared_widgets/custom_app_bar.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/shimmer_loading.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: CustomAppBar(
          title: 'الرسائل',
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              onPressed: () {
                // Search in conversations
              },
            ),
          ],
        ),
        body: Consumer<MessageProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingConversations && provider.conversations.isEmpty) {
              return _buildLoadingState();
            }

            if (provider.conversationsError != null && provider.conversations.isEmpty) {
              return _buildErrorState(provider);
            }

            if (provider.conversations.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.chat_bubble_outline,
                title: 'لا توجد رسائل',
                message: 'ابدأ محادثة مع المتاجر للحصول على الدعم',
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadConversations(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                itemCount: provider.conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 88),
                itemBuilder: (context, index) {
                  final conversation = provider.conversations[index];
                  return _buildConversationTile(conversation);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing20,
              vertical: AppTheme.spacing12,
            ),
            child: Row(
              children: [
                const ShimmerBox(width: 56, height: 56, borderRadius: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 120, height: 16),
                      SizedBox(height: 8),
                      ShimmerBox(width: double.infinity, height: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const ShimmerBox(width: 40, height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(MessageProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'تعذر تحميل الرسائل',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => provider.loadConversations(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: conversation.userId,
              userName: conversation.displayName,
              userAvatar: conversation.avatarUrl,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing20,
          vertical: AppTheme.spacing12,
        ),
        child: Row(
          children: [
            // Avatar with unread indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: conversation.avatarUrl != null
                        ? Image.network(
                            conversation.avatarUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(conversation);
                            },
                          )
                        : _buildDefaultAvatar(conversation),
                  ),
                ),
                if (conversation.unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        conversation.unreadCount > 9
                            ? '9+'
                            : conversation.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.displayName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: conversation.unreadCount > 0
                              ? AppColors.primaryPurple
                              : AppColors.textHint,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (conversation.isSender) ...[
                        Icon(
                          Icons.done_all,
                          size: 16,
                          color: AppColors.primaryPurple,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            color: conversation.unreadCount > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

  Widget _buildDefaultAvatar(Conversation conversation) {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.primaryPurple.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        conversation.displayName.isNotEmpty
            ? conversation.displayName[0].toUpperCase()
            : '?',
        style: TextStyle(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}
