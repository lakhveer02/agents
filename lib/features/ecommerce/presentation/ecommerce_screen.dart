import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/features/ecommerce/presentation/providers/ecommerce_provider.dart';
import 'package:agents/core/theme/app_theme.dart';
import 'package:agents/widgets/premium_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EcommerceScreen extends ConsumerWidget {
  const EcommerceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecommerceState = ref.watch(ecommerceProvider);
    final preferenceController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shopping Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildMemorySection(ecommerceState),
            const SizedBox(height: 40),
            
            const Text(
              'Smart Preferences',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPreferenceInput(ref, preferenceController),
            const SizedBox(height: 40),
            
            const Text(
              'Curated for You',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (ecommerceState.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildProductGrid(ecommerceState.recommendations),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMemorySection(EcommerceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Neural Shopping History',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.memories.isEmpty)
          Text('No preferences learned yet.', style: TextStyle(color: Colors.white.withOpacity(0.3)))
        else
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.memories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                    ),
                    child: Text(
                      state.memories[index],
                      style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildPreferenceInput(WidgetRef ref, TextEditingController controller) {
    return PremiumGlassCard(
      opacity: 0.05,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g., I love minimalist tech...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref.read(ecommerceProvider.notifier).savePreference(controller.text);
                  controller.clear();
                }
              },
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<String> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildProductCard(String name) {
    return PremiumGlassCard(
      opacity: 0.03,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.shopping_bag_rounded, size: 40, color: Colors.white24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '\$1,299',
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded, size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale();
  }
}
