import 'package:flutter/material.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const TodoHomePage(),
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

enum Priority { low, medium, high }

class Todo {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  Priority priority;
  DateTime createdAt;
  DateTime? dueDate;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = Priority.medium,
    DateTime? createdAt,
    this.dueDate,
  }) : createdAt = createdAt ?? DateTime.now();
}

// ─── Home Page ────────────────────────────────────────────────────────────────

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage>
    with SingleTickerProviderStateMixin {
  final List<Todo> _todos = [
    Todo(
      id: '1',
      title: 'Buy groceries',
      description: 'Milk, eggs, bread, and fruits',
      priority: Priority.high,
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
    Todo(
      id: '2',
      title: 'Read a book',
      priority: Priority.low,
    ),
    Todo(
      id: '3',
      title: 'Exercise for 30 minutes',
      priority: Priority.medium,
      isCompleted: true,
    ),
  ];

  late TabController _tabController;
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Todo> get _filteredTodos {
    List<Todo> result = List.from(_todos);
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (t.description
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }
    return result;
  }

  List<Todo> get _activeTodos =>
      _filteredTodos.where((t) => !t.isCompleted).toList();

  List<Todo> get _completedTodos =>
      _filteredTodos.where((t) => t.isCompleted).toList();

  void _addTodo() async {
    final todo = await showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditTodoSheet(),
    );
    if (todo != null) {
      setState(() => _todos.insert(0, todo));
    }
  }

  void _editTodo(Todo todo) async {
    final updated = await showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTodoSheet(todo: todo),
    );
    if (updated != null) {
      setState(() {
        final index = _todos.indexWhere((t) => t.id == updated.id);
        if (index != -1) _todos[index] = updated;
      });
    }
  }

  void _toggleTodo(Todo todo) {
    setState(() => todo.isCompleted = !todo.isCompleted);
  }

  void _deleteTodo(Todo todo) {
    setState(() => _todos.remove(todo));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${todo.title}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => _todos.add(todo)),
        ),
      ),
    );
  }

  void _deleteCompleted() {
    setState(() => _todos.removeWhere((t) => t.isCompleted));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Completed tasks cleared')));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completedCount = _todos.where((t) => t.isCompleted).length;
    final totalCount = _todos.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search todos...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Todos',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$completedCount / $totalCount completed',
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          if (_completedTodos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear completed',
              onPressed: _deleteCompleted,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${_filteredTodos.length})'),
            Tab(text: 'Active (${_activeTodos.length})'),
            Tab(text: 'Done (${_completedTodos.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (totalCount > 0) _buildProgressBar(colorScheme, completedCount, totalCount),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(_filteredTodos),
                _buildTodoList(_activeTodos),
                _buildTodoList(_completedTodos),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTodo,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildProgressBar(
      ColorScheme cs, int completed, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: completed / total,
          minHeight: 6,
          backgroundColor: cs.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
        ),
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 72,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No tasks here!',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _TodoCard(
          todo: todo,
          onToggle: () => _toggleTodo(todo),
          onEdit: () => _editTodo(todo),
          onDelete: () => _deleteTodo(todo),
        );
      },
    );
  }
}

// ─── Todo Card ────────────────────────────────────────────────────────────────

class _TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoCard({
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color _priorityColor(Priority p, ColorScheme cs) {
    switch (p) {
      case Priority.high:
        return Colors.red.shade400;
      case Priority.medium:
        return Colors.orange.shade400;
      case Priority.low:
        return Colors.green.shade400;
    }
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOverdue = todo.dueDate != null &&
        todo.dueDate!.isBefore(DateTime.now()) &&
        !todo.isCompleted;

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: cs.surfaceContainerLow,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                // Priority indicator
                Container(
                  width: 4,
                  height: 56,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: _priorityColor(todo.priority, cs),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Checkbox
                Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => onToggle(),
                  shape: const CircleBorder(),
                ),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.isCompleted
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                      if (todo.description != null &&
                          todo.description!.isNotEmpty)
                        Text(
                          todo.description!,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _priorityColor(todo.priority, cs)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _priorityLabel(todo.priority),
                              style: TextStyle(
                                fontSize: 10,
                                color: _priorityColor(todo.priority, cs),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (todo.dueDate != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color:
                                  isOverdue ? Colors.red : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatDate(todo.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                color: isOverdue
                                    ? Colors.red
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(
                todo.isCompleted
                    ? Icons.radio_button_unchecked
                    : Icons.check_circle_outline,
              ),
              title: Text(todo.isCompleted ? 'Mark active' : 'Mark complete'),
              onTap: () {
                Navigator.pop(ctx);
                onToggle();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title:
                  const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add/Edit Sheet ───────────────────────────────────────────────────────────

class AddEditTodoSheet extends StatefulWidget {
  final Todo? todo;
  const AddEditTodoSheet({super.key, this.todo});

  @override
  State<AddEditTodoSheet> createState() => _AddEditTodoSheetState();
}

class _AddEditTodoSheetState extends State<AddEditTodoSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late Priority _priority;
  DateTime? _dueDate;
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.todo?.title ?? '');
    _descCtrl =
        TextEditingController(text: widget.todo?.description ?? '');
    _priority = widget.todo?.priority ?? Priority.medium;
    _dueDate = widget.todo?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final todo = Todo(
      id: widget.todo?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      priority: _priority,
      isCompleted: widget.todo?.isCompleted ?? false,
      createdAt: widget.todo?.createdAt,
      dueDate: _dueDate,
    );
    Navigator.pop(context, todo);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? 'Edit Task' : 'New Task',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Title
            TextFormField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Task title *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.task_alt_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // Priority
            Text('Priority',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(
              children: Priority.values.map((p) {
                final colors = {
                  Priority.low: Colors.green.shade400,
                  Priority.medium: Colors.orange.shade400,
                  Priority.high: Colors.red.shade400,
                };
                final labels = {
                  Priority.low: 'Low',
                  Priority.medium: 'Medium',
                  Priority.high: 'High',
                };
                final isSelected = _priority == p;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors[p]!.withOpacity(0.2)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: colors[p]!, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            labels[p]!,
                            style: TextStyle(
                              color: isSelected
                                  ? colors[p]
                                  : cs.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Due date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate == null
                          ? 'Set due date (optional)'
                          : 'Due: ${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.close,
                            size: 18, color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Add Task',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}