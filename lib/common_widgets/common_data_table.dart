import 'package:flutter/material.dart';

class CommonDataTable<T> extends StatefulWidget {
  final List<T> data;
  final List<DataColumn> columns;
  final List<DataRow> Function(List<T> data) rowBuilder;
  final String title;
  final bool showSearch;
  final bool showPagination;
  final int itemsPerPage;
  final Function(String)? onSearch;
  final Function()? onAdd;
  final Function(T)? onEdit;
  final Function(T)? onDelete;
  final Function(T)? onView;
  final String? searchHint;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final double? dataRowMinHeight; // Add this
  final double? dataRowMaxHeight; // Add this

  const CommonDataTable({
    super.key,
    required this.data,
    required this.columns,
    required this.rowBuilder,
    required this.title,
    this.showSearch = true,
    this.showPagination = true,
    this.itemsPerPage = 10,
    this.onSearch,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.searchHint,
    this.actions,
    this.floatingActionButton,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
  });

  @override
  State<CommonDataTable<T>> createState() => _CommonDataTableState<T>();
}

class _CommonDataTableState<T> extends State<CommonDataTable<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredData = [];
  int _currentPage = 0;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.data);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(CommonDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _filteredData = List.from(widget.data);
      _currentPage = 0;
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (widget.onSearch != null) {
      widget.onSearch!(query);
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<T> get _paginatedData {
    if (!widget.showPagination) return _filteredData;

    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(
      0,
      _filteredData.length,
    );

    return _filteredData.sublist(startIndex, endIndex);
  }

  int get _totalPages => widget.showPagination
      ? (_filteredData.length / widget.itemsPerPage).ceil()
      : 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.showSearch) ...[
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: widget.searchHint ?? 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (widget.actions != null) ...widget.actions!,
                if (widget.onAdd != null)
                  ElevatedButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  columns: widget.columns,
                  rows: widget.rowBuilder(_paginatedData),
                  columnSpacing: 26,
                  horizontalMargin: 20,
                  dataRowMinHeight: widget.dataRowMinHeight ?? 48.0, // Add this
                  dataRowMaxHeight: widget.dataRowMaxHeight ?? 80.0, // Add this
                  headingRowColor: MaterialStateProperty.all(
                    Colors.grey.shade50,
                  ),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // Pagination
          if (widget.showPagination && _totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${_currentPage * widget.itemsPerPage + 1} - '
                    '${(_currentPage * widget.itemsPerPage + _paginatedData.length)} '
                    'of ${_filteredData.length} entries',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      ...List.generate(
                        _totalPages,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _currentPage = index),
                            style: TextButton.styleFrom(
                              backgroundColor: _currentPage == index
                                  ? Colors.blue
                                  : Colors.transparent,
                              foregroundColor: _currentPage == index
                                  ? Colors.white
                                  : Colors.black87,
                              minimumSize: const Size(36, 36),
                            ),
                            child: Text('${index + 1}'),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _currentPage < _totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Action Button Widget for table rows
class TableActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const TableActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// Status Badge Widget
class StatusBadge extends StatelessWidget {
  final String status;
  final Map<String, Color>? colorMap;

  const StatusBadge({super.key, required this.status, this.colorMap});

  Color get _getStatusColor {
    final defaultColorMap = {
      'active': Colors.green,
      'inactive': Colors.grey,
      'suspended': Colors.red,
      'enrolled': Colors.blue,
      'graduated': Colors.purple,
      'dropped': Colors.orange,
      'pending': Colors.amber,
      'completed': Colors.green,
      'failed': Colors.red,
    };

    final colors = colorMap ?? defaultColorMap;
    return colors[status.toLowerCase()] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
