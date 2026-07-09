import 'package:docs/emma/anchors/docs_emma_anchors.dart';
import 'package:docs/provider/cloud_doc_provider.dart';
import 'package:docs/widgets/show_custom_date_range_picker.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class DocumentFilterBar extends ConsumerStatefulWidget {
  final bool isForTemplates;
  
  const DocumentFilterBar({
    super.key,
    this.isForTemplates = false,
  });

  @override
  ConsumerState<DocumentFilterBar> createState() => _DocumentFilterBarState();
}

class _DocumentFilterBarState extends ConsumerState<DocumentFilterBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final filters = ref.watch(
      widget.isForTemplates ? templateFiltersProvider : documentFiltersProvider,
    );
    final searchText = filters['search']?.toString() ?? '';
    if (_searchController.text != searchText) {
      _searchController.text = searchText;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchField(ref, widget.isForTemplates),
          ),
          const SizedBox(width: 12),
          if (!widget.isForTemplates) _buildStatusFilter(ref),
          const SizedBox(width: 12),
          _buildDateFilter(ref, widget.isForTemplates),
          const SizedBox(width: 12),
          _buildOrderingDropdown(ref, widget.isForTemplates),
          const SizedBox(width: 12),
          if (filters.isNotEmpty) _buildClearFiltersButton(ref, widget.isForTemplates),
        ],
      ),
    );
  }

  Widget _buildSearchField(WidgetRef ref, bool isForTemplates) {
    final theme = ref.watch(themeColorsProvider);
    
    return TextField(
      cursorColor: theme.textColor,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        hintText: isForTemplates ? 'Search templates...' : 'Search documents...',
        hintStyle: TextStyle(color: theme.textColor),
        filled: true,
        fillColor: theme.dashboardContainer,
        prefixIcon: Icon(Icons.search, color: theme.textColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dashboardBoarder, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (value) {
        final provider = isForTemplates 
            ? templateFiltersProvider 
            : documentFiltersProvider;
        ref.read(provider.notifier).update((state) {
          if (value.isEmpty) {
            final newState = Map<String, dynamic>.from(state);
            newState.remove('search');
            return newState;
          } else {
            return {...state, 'search': value};
          }
        });
      },
      controller: _searchController,
    );
  }

  Widget _buildStatusFilter(WidgetRef ref) {
    final filters = ref.watch(documentFiltersProvider);
    final status = filters['status']?.toString() ?? '';
    final statusIn = filters['status_in']?.toString() ?? '';
    final theme = ref.watch(themeColorsProvider);
    final textStyle = TextStyle(color:theme.textColor);
    return EmmaUiAnchorTarget(
       anchorKey: DocsEmmaAnchors.documentFilterBar.anchorKey,

       spec: DocsEmmaAnchors.documentFilterBar,
       runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
       tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      child: PopupMenuButton<String>(
        tooltip: 'Filter by status',
        color: theme.dashboardContainer,
        onSelected: (value) {
          ref.read(documentFiltersProvider.notifier).update((state) {
            if (value == 'all') {
              final newState = Map<String, dynamic>.from(state);
              newState.remove('status');
              newState.remove('status_in');
              return newState;
            } else if (value == 'multiple') {
              _showMultiStatusDialog(ref);
              return state;
            } else {
              final newState = Map<String, dynamic>.from(state);
              newState.remove('status_in');
              return {...newState, 'status': value};
            }
          });
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'all',
            child: Text('All Statuses', style: textStyle),
          ),
          PopupMenuItem(
            value: 'draft',
            child: Text('Draft', style: textStyle),
          ),
          PopupMenuItem(
            value: 'in_progress',
            child: Text('In Progress', style: textStyle),
          ),
          PopupMenuItem(
            value: 'review',
            child: Text('Review', style: textStyle),
          ),
          PopupMenuItem(
            value: 'completed',
            child: Text('Completed', style: textStyle),
          ),
          PopupMenuItem(
            value: 'multiple',
            child: Text('Multiple Statuses...', style: textStyle),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 16),
              const SizedBox(width: 4),
              Text(
                status.isNotEmpty 
                  ? 'Status: $status'
                  : statusIn.isNotEmpty
                    ? 'Multiple Statuses'
                    : 'Status',
                style:TextStyle(fontSize: 14, color: theme.textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMultiStatusDialog(WidgetRef ref) {
    final filters = ref.read(documentFiltersProvider);
    final currentStatusIn = filters['status_in']?.toString() ?? '';
    final selectedStatuses = currentStatusIn.split(',');
    final theme = ref.watch(themeColorsProvider);
    showDialog(
      context: ref.context,
      builder: (context) {
        final statusOptions = ['draft', 'in_progress', 'review', 'completed'];
        final selected = List<bool>.from(
          statusOptions.map((s) => selectedStatuses.contains(s)),
        );
        
        return AlertDialog(
          backgroundColor: theme.dashboardContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(6),
          ),
          title: Text('Select Statuses',style: TextStyle(color: theme.textColor),),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: statusOptions.map((status) {
                  final index = statusOptions.indexOf(status);
                  return CheckboxListTile(
                    title: Text(status, style: TextStyle(color: theme.textColor),),
                    value: selected[index],
                    activeColor: theme.themeColor,
                    checkColor: theme.themeTextColor,
                    onChanged: (value) {
                      setState(() {
                        selected[index] = value!;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',  style: TextStyle(color: theme.textColor)),
            ),
            TextButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(6)
                  )
                ),
               onPressed: () {
                final selectedList = <String>[];
                for (int i = 0; i < statusOptions.length; i++) {
                  if (selected[i]) {
                    selectedList.add(statusOptions[i]);
                  }
                }
                
                if (selectedList.isNotEmpty) {
                  ref.read(documentFiltersProvider.notifier).update((state) {
                    final newState = Map<String, dynamic>.from(state);
                    newState.remove('status');
                    return {...newState, 'status_in': selectedList.join(',')};
                  });
                } else {
                  ref.read(documentFiltersProvider.notifier).update((state) {
                    final newState = Map<String, dynamic>.from(state);
                    newState.remove('status');
                    newState.remove('status_in');
                    return newState;
                  });
                }
                Navigator.pop(context);
              },
              child: Text('Apply',style: TextStyle(color: theme.themeColorText)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateFilter(WidgetRef ref, bool isForTemplates) {
    final filters = ref.watch(
      isForTemplates ? templateFiltersProvider : documentFiltersProvider,
    );
    final theme = ref.watch(themeColorsProvider);
    final textStyle = TextStyle(color:theme.textColor);
    final hasDateFilter = filters.containsKey(
      isForTemplates ? 'date_created_after' : 'date_updated_after',
    );
    
    return EmmaUiAnchorTarget(
      anchorKey: DocsEmmaAnchors.dateFilterButton.anchorKey,

      spec: DocsEmmaAnchors.dateFilterButton,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      child: PopupMenuButton<DateTimeRange>(
        color: theme.dashboardContainer,
        tooltip: 'Filter by date',
        onSelected: (range) {
          final provider = isForTemplates 
              ? templateFiltersProvider 
              : documentFiltersProvider;
          
          ref.read(provider.notifier).update((state) {
            final newState = Map<String, dynamic>.from(state);
            
            if (isForTemplates) {
              newState['date_created_after'] = range.start.toIso8601String().split('T').first;
              newState['date_created_before'] = range.end.toIso8601String().split('T').first;
            } else {
              newState['date_updated_after'] = range.start.toIso8601String().split('T').first;
              newState['date_updated_before'] = range.end.toIso8601String().split('T').first;
            }
            
            return newState;
          });
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            child: Text('Custom Range...', style: TextStyle(color: theme.textColor),),
            onTap: () {
                Future.delayed(Duration.zero, () {
              showCustomDateRangePicker(
                context: context,
                ref: ref,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                ),
              ).then((range) {
                if (range != null) {
                  final provider = isForTemplates
                      ? templateFiltersProvider
                      : documentFiltersProvider;
                  
                  ref.read(provider.notifier).update((state) {
                    final newState = Map<String, dynamic>.from(state);
                    
                    if (isForTemplates) {
                      newState['date_created_after'] = range.start.toIso8601String().split('T').first;
                      newState['date_created_before'] = range.end.toIso8601String().split('T').first;
                    } else {
                      newState['date_updated_after'] = range.start.toIso8601String().split('T').first;
                      newState['date_updated_before'] = range.end.toIso8601String().split('T').first;
                    }
                    
                    return newState;
                  });
                }
              });
            });
            },
          ),
          PopupMenuItem(
            value: DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
            child: Text('Last 7 days',style: textStyle),
          ),
          PopupMenuItem(
            value: DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
            child:Text('Last 30 days',style: textStyle),
          ),
          PopupMenuItem(
            value: DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 90)),
              end: DateTime.now(),
            ),
            child:Text('Last 90 days',style: textStyle),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.date_range, size: 16, color:theme.textColor,),
              const SizedBox(width: 4),
              Text(
                hasDateFilter ? 'Date Filtered' : 'Date',
                style:TextStyle(fontSize: 14, color: theme.textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderingDropdown(WidgetRef ref, bool isForTemplates) {
    final filters = ref.watch(
      isForTemplates ? templateFiltersProvider : documentFiltersProvider,
    );
    final theme = ref.watch(themeColorsProvider);
    final textStyle = TextStyle(color:theme.textColor);
    final currentOrdering = filters['ordering']?.toString() ?? '';
    
    return EmmaUiAnchorTarget(
        anchorKey: DocsEmmaAnchors.sortButton.anchorKey,

        spec: DocsEmmaAnchors.sortButton,
        runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      child: PopupMenuButton<String>(
        color: theme.dashboardContainer,
        tooltip: 'Sort results',
        onSelected: (value) {
          final provider = isForTemplates 
              ? templateFiltersProvider 
              : documentFiltersProvider;
          
          ref.read(provider.notifier).update((state) {
            if (value.isEmpty) {
              final newState = Map<String, dynamic>.from(state);
              newState.remove('ordering');
              return newState;
            } else {
              return {...state, 'ordering': value};
            }
          });
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: '',
            child: Text('Default Order', style: textStyle),
          ),
          if (!isForTemplates) ...[
            PopupMenuItem(
              value: '-date_updated',
              child: Text('Last Updated (Newest First)',style: textStyle),
            ),
            PopupMenuItem(
              value: 'date_updated',
              child: Text('Last Updated (Oldest First)',style: textStyle),
            ),
            PopupMenuItem(
              value: '-createdAt',
              child: Text('Created At (Newest First)',style: textStyle),
            ),
            PopupMenuItem(
              value: 'createdAt',
              child: Text('Created At (Oldest First)',style: textStyle),
            ),
          ],
          if (isForTemplates) ...[
            PopupMenuItem(
              value: '-date_updated',
              child: Text('Last Updated (Newest First)',style: textStyle),
            ),
            PopupMenuItem(
              value: '-date_created',
              child: Text('Created Date (Newest First)',style: textStyle),
            ),
            PopupMenuItem(
              value: 'name',
              child: Text('Name (A-Z)',style: textStyle),
            ),
            PopupMenuItem(
              value: '-name',
              child: Text('Name (Z-A)',style: textStyle),
            ),
          ],
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.sort, size: 16),
              const SizedBox(width: 4),
              Text(
                currentOrdering.isNotEmpty ? 'Sorted' : 'Sort',
                style: TextStyle(fontSize: 14, color: theme.textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton(WidgetRef ref, bool isForTemplates) {
    final theme = ref.watch(themeColorsProvider);
    return EmmaUiAnchorTarget(
        anchorKey: DocsEmmaAnchors.clearFiltersButton.anchorKey,

        spec: DocsEmmaAnchors.clearFiltersButton,
        runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
        tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      child: IconButton(
        icon:Icon(Icons.clear_all, color: theme.textColor,),
        tooltip: 'Clear all filters',
        onPressed: () {
          final provider = isForTemplates 
              ? templateFiltersProvider 
              : documentFiltersProvider;
          ref.read(provider.notifier).state = {};
        },
      ),
    );
  }
}