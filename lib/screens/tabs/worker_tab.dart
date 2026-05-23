import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../widgets/common/responsive_widgets.dart';
import '../../models/worker_model.dart';
import '../../models/order_model.dart';
import '../worker/add_worker_screen.dart';
import '../../core/utils/design_system.dart';
import '../../core/utils/responsive.dart';
import '../worker/worker_details_screen.dart';
import '../worker/worker_assigned_work_list_screen.dart';

class WorkerTab extends StatefulWidget {
  const WorkerTab({super.key});

  @override
  State<WorkerTab> createState() => _WorkerTabState();
}

class _WorkerTabState extends State<WorkerTab> {
  final ScrollController _scrollController = ScrollController();
  Map<String, List<OrderModel>> _workerOrderMap = {};
  Map<String, int> _workerCompletedMap = {};
  Map<String, int> _workerDelayedMap = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {}

  void _buildWorkerMaps(List<OrderModel> allOrders) {
    _workerOrderMap = {};
    _workerCompletedMap = {};
    _workerDelayedMap = {};

    for (final order in allOrders) {
      if (order.assignedWorkerId == null) continue;
      final wid = order.assignedWorkerId!;

      if (order.status == 'delivered') {
        _workerCompletedMap[wid] = (_workerCompletedMap[wid] ?? 0) + 1;
      } else if (!order.isCancelled) {
        _workerOrderMap.putIfAbsent(wid, () => []).add(order);
        if (order.deliveryDate != null && order.deliveryDate!.isBefore(DateTime.now())) {
          _workerDelayedMap[wid] = (_workerDelayedMap[wid] ?? 0) + 1;
        }
      }
    }
  }

  List<OrderModel>? _lastOrders;

  @override
  Widget build(BuildContext context) {
    final workerProvider = WorkerProviderWrapper.of(context);
    final orderProvider = OrderProviderWrapper.of(context);

    final orders = orderProvider.orders;
    if (_lastOrders == null || _lastOrders != orders) {
      _lastOrders = orders;
      _buildWorkerMaps(orders);
    }

    final totalCompleted = _workerCompletedMap.values.fold(0, (a, b) => a + b);
    final totalActive = _workerOrderMap.values.fold(0, (a, b) => a + b.length);

    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await workerProvider.fetchWorkers();
          await orderProvider.fetchOrders();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topSafePadding(context) + R.value(context, regular: 16, smallPhone: 12))),

            SliverToBoxAdapter(
              child: ConstrainedContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: DesignSystem.charcoal),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: DesignSystem.s12),
                              Text('WORKSHOP', style: DesignSystem.pageTitle),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerAssignedWorkListScreen())),
                                child: Container(
                                  padding: EdgeInsets.all(R.value(context, regular: 10, smallPhone: 8)),
                                  decoration: BoxDecoration(
                                    color: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                                  ),
                                  child: Icon(Icons.assignment_rounded, color: DesignSystem.primaryContainer, size: R.value(context, regular: 22, smallPhone: 20)),
                                ),
                              ),
                              const SizedBox(width: DesignSystem.md),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWorkerScreen())),
                                child: Container(
                                  padding: EdgeInsets.all(R.value(context, regular: 10, smallPhone: 8)),
                                  decoration: BoxDecoration(
                                    color: DesignSystem.primaryContainer.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
                                  ),
                                  child: Icon(Icons.person_add_rounded, color: DesignSystem.primaryContainer, size: R.value(context, regular: 22, smallPhone: 20)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: R.value(context, regular: 4, smallPhone: 2)),
                      Text('${workerProvider.workers.length} workers \u00B7 $totalCompleted completed', style: DesignSystem.greetingText),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: R.sectionGap(context))),

            if (workerProvider.workers.isNotEmpty)
              SliverToBoxAdapter(
                child: ConstrainedContent(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                    child: Breakpoints.isTabletOrWider(context)
                        ? ResponsiveCardGrid(childAspectRatio: 3.0, children: [
                            _perfCard(icon: Icons.check_circle_rounded, value: totalCompleted.toString(), label: 'Completed', color: DesignSystem.tertiaryContainer),
                            _perfCard(icon: Icons.work_rounded, value: totalActive.toString(), label: 'In Progress', color: DesignSystem.info),
                          ])
                        : Row(children: [
                            Expanded(child: _perfCard(icon: Icons.check_circle_rounded, value: totalCompleted.toString(), label: 'Completed', color: DesignSystem.tertiaryContainer)),
                            SizedBox(width: R.gap(context)),
                            Expanded(child: _perfCard(icon: Icons.work_rounded, value: totalActive.toString(), label: 'In Progress', color: DesignSystem.info)),
                          ]),
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: R.sectionGap(context))),

            if (workerProvider.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (workerProvider.hasError && workerProvider.workers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateWidget(
                  title: 'Connection Error',
                  subtitle: 'Unable to load workers. Please check your connection.',
                  onRetry: () => workerProvider.fetchWorkers(),
                ),
              )
            else if (workerProvider.workers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(R.cardPadding(context)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(DesignSystem.s16),
                          decoration: BoxDecoration(
                            color: DesignSystem.primaryContainer.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.groups_rounded, size: 40, color: DesignSystem.primaryContainer),
                        ),
                        const SizedBox(height: DesignSystem.md),
                        Text('No workers yet', style: DesignSystem.cardTitle),
                        const SizedBox(height: DesignSystem.s4),
                        Text('Add your first worker to track performance', style: DesignSystem.caption, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: R.pagePadding(context)),
                sliver: SliverToBoxAdapter(
                  child: ConstrainedContent(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: workerProvider.workers.length,
                      itemBuilder: (context, index) {
                        final worker = workerProvider.workers[index];
                        final activeOrders = _workerOrderMap[worker.id] ?? [];
                        final completedCount = _workerCompletedMap[worker.id] ?? 0;
                        final delayedCount = _workerDelayedMap[worker.id] ?? 0;
                        final workloadCount = activeOrders.length;

                        return RepaintBoundary(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: R.value(context, regular: 12, smallPhone: 8)),
                            child: _workerCard(worker, activeOrders, completedCount, delayedCount, workloadCount),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: effectiveBottomPadding(context) + 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfCard({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.all(R.value(context, regular: 16, smallPhone: 12)),
      decoration: DesignSystem.card,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignSystem.s8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: DesignSystem.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: DesignSystem.statValue),
              Text(label, style: DesignSystem.statLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workerCard(WorkerModel worker, List<OrderModel> activeOrders, int completedCount, int delayedCount, int workloadCount) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerDetailsScreen(worker: worker))),
      child: Container(
        decoration: BoxDecoration(
          color: DesignSystem.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
          border: Border.all(color: DesignSystem.outlineVariant),
          boxShadow: DesignSystem.cardShadow,
        ),
        child: Padding(
          padding: EdgeInsets.all(R.cardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: DesignSystem.info.withValues(alpha: 0.1),
                        child: Text(worker.name[0].toUpperCase(), style: GoogleFonts.manrope(color: DesignSystem.info, fontWeight: FontWeight.w800, fontSize: 18)),
                      ),
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: worker.isActive ? DesignSystem.tertiaryContainer : DesignSystem.muted,
                          shape: BoxShape.circle,
                          border: Border.all(color: DesignSystem.surfaceContainerLowest, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: DesignSystem.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(worker.name, style: DesignSystem.cardTitle),
                        const SizedBox(height: DesignSystem.s2),
                        Text(
                          worker.salaryType == SalaryType.piece_rate ? 'Piece Rate' : 'Monthly',
                          style: DesignSystem.caption,
                        ),
                      ],
                    ),
                  ),
                  if (delayedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s8, vertical: DesignSystem.s4),
                      decoration: BoxDecoration(
                        color: DesignSystem.errorContainer,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                      ),
                      child: Text('$delayedCount', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: DesignSystem.error)),
                    ),
                ],
              ),
              const SizedBox(height: DesignSystem.s12),
              Row(
                children: [
                  _statBadge(completedCount, 'Done', DesignSystem.tertiaryContainer),
                  const SizedBox(width: DesignSystem.s8),
                  _statBadge(workloadCount, 'Active', workloadCount == 0 ? DesignSystem.tertiaryContainer : workloadCount > 5 ? DesignSystem.error : DesignSystem.warning),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      final phone = worker.phone ?? '';
                      if (phone.isNotEmpty) launchUrl(Uri.parse('tel:$phone'));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(DesignSystem.s8),
                      decoration: BoxDecoration(
                        color: DesignSystem.tertiaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
                      ),
                      child: const Icon(Icons.call_rounded, color: DesignSystem.tertiaryContainer, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBadge(int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignSystem.s8, vertical: DesignSystem.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count.toString(), style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: DesignSystem.s4),
          Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
