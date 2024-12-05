import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deputation_opening.dart';
import '../../services/deputation_service.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';

class CreateDeputationScreen extends StatefulWidget {
  const CreateDeputationScreen({super.key});

  @override
  State<CreateDeputationScreen> createState() => _CreateDeputationScreenState();
}

class _CreateDeputationScreenState extends State<CreateDeputationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizationController = TextEditingController();
  final _notificationNumberController = TextEditingController();
  final _notificationDateController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _requiredRankController = TextEditingController();
  final _requiredExperienceController = TextEditingController();
  final _otherCriteriaController = TextEditingController();
  final _requiredBranchController = TextEditingController();
  final _experienceFromRankController = TextEditingController();

  DateTime? _notificationDate;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedRankName;
  String? _selectedBranchName;
  String? _selectedExperienceFromRankName;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizationController.dispose();
    _notificationNumberController.dispose();
    _notificationDateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _requiredRankController.dispose();
    _requiredExperienceController.dispose();
    _otherCriteriaController.dispose();
    _requiredBranchController.dispose();
    _experienceFromRankController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'notification':
            _notificationDate = picked;
            _notificationDateController.text = DateFormat('dd-MM-yyyy').format(picked);
            break;
          case 'start':
            _startDate = picked;
            _startDateController.text = DateFormat('dd-MM-yyyy').format(picked);
            break;
          case 'end':
            _endDate = picked;
            _endDateController.text = DateFormat('dd-MM-yyyy').format(picked);
            break;
        }
      });
    }
  }

  Widget _buildRankField() {
    return Autocomplete<Map<String, dynamic>>(
      initialValue: TextEditingValue(text: _selectedRankName ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const [];
        }
        return await DatabaseHelper.instance.getRanks(textEditingValue.text);
      },
      displayStringForOption: (Map<String, dynamic> option) => 
        option['rnk_nm'] as String,
      onSelected: (Map<String, dynamic> selection) {
        print('Rank selected: ${selection['rnk_nm']}');
        setState(() {
          _requiredRankController.text = selection['rnk_cd'].toString();
          _selectedRankName = selection['rnk_nm'] as String;
          _requiredBranchController.clear();
          _selectedBranchName = null;
        });
        Future.microtask(() => setState(() {}));
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (_selectedRankName != null && textEditingController.text.isEmpty) {
          textEditingController.text = _selectedRankName!;
        }
        
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Required Rank',
            hintText: 'Start typing to search ranks',
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200,
              width: 300,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option['rnk_nm'] as String),
                    onTap: () {
                      onSelected(option);
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBranchField() {
    print('Building branch field. Selected rank: $_selectedRankName');
    return Autocomplete<Map<String, dynamic>>(
      initialValue: TextEditingValue(text: _selectedBranchName ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) async {
        print('Checking rank before fetching branches: $_selectedRankName');
        if (_selectedRankName == null) {
          return const [];
        }
        final branches = await DatabaseHelper.instance.getBranches(
          _requiredRankController.text,
          textEditingValue.text,
        );
        print('Found ${branches.length} branches for rank $_selectedRankName');
        return branches;
      },
      displayStringForOption: (Map<String, dynamic> option) => 
        option['brn_nm'] as String,
      onSelected: (Map<String, dynamic> selection) {
        setState(() {
          _requiredBranchController.text = selection['brn_cd'].toString();
          _selectedBranchName = selection['brn_nm'] as String;
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (_selectedBranchName != null && textEditingController.text.isEmpty) {
          textEditingController.text = _selectedBranchName!;
        }

        final isEnabled = _selectedRankName != null;
        print('Branch field enabled: $isEnabled');

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: isEnabled,
          decoration: InputDecoration(
            labelText: 'Required Branch',
            hintText: isEnabled
              ? 'Start typing to search branches'
              : 'Select a rank first',
            suffixIcon: isEnabled
              ? null
              : const Icon(Icons.lock_outline, color: Colors.grey),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200,
              width: 300,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option['brn_nm'] as String),
                    onTap: () {
                      onSelected(option);
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExperienceFromRankField() {
    return Autocomplete<Map<String, dynamic>>(
      initialValue: TextEditingValue(text: _selectedExperienceFromRankName ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return await DatabaseHelper.instance.getSubordinateRanks('');
        }
        return await DatabaseHelper.instance.getRanks(textEditingValue.text);
      },
      displayStringForOption: (Map<String, dynamic> option) => 
        option['rnk_nm'] as String,
      onSelected: (Map<String, dynamic> selection) {
        setState(() {
          _experienceFromRankController.text = selection['rnk_cd'].toString();
          _selectedExperienceFromRankName = selection['rnk_nm'] as String;
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (_selectedExperienceFromRankName != null && textEditingController.text.isEmpty) {
          textEditingController.text = _selectedExperienceFromRankName!;
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: true,
          decoration: const InputDecoration(
            labelText: 'Count Experience From Rank',
            hintText: 'Select rank to count experience from',
          ),
          validator: (value) => _requiredExperienceController.text.isNotEmpty && value?.isEmpty == true 
            ? 'Required when experience is specified' 
            : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200,
              width: 300,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option['rnk_nm'] as String),
                    onTap: () {
                      onSelected(option);
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_requiredRankController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid rank')),
        );
        return;
      }

      if (_requiredBranchController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid branch')),
        );
        return;
      }

      if (_requiredExperienceController.text.isNotEmpty && 
          _experienceFromRankController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select rank to count experience from'),
          ),
        );
        return;
      }

      final opening = DeputationOpening(
        title: _titleController.text,
        description: _descriptionController.text,
        organization: _organizationController.text,
        notificationNumber: _notificationNumberController.text,
        notificationDate: _notificationDate!,
        startDate: _startDate!,
        endDate: _endDate!,
        requiredRank: _requiredRankController.text,
        requiredRankName: _selectedRankName,
        requiredBranch: _requiredBranchController.text,
        requiredBranchName: _selectedBranchName,
        experienceFromRank: _experienceFromRankController.text.isEmpty 
            ? null 
            : _experienceFromRankController.text,
        experienceFromRankName: _selectedExperienceFromRankName,
        requiredExperience: _requiredExperienceController.text.isEmpty 
            ? null 
            : int.parse(_requiredExperienceController.text),
        otherCriteria: _otherCriteriaController.text.isEmpty ? null : _otherCriteriaController.text,
      );

      final success = await context.read<DeputationService>().createOpening(opening);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deputation opening created successfully')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Deputation Opening'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _organizationController,
                decoration: const InputDecoration(labelText: 'Organization'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notificationNumberController,
                decoration: const InputDecoration(labelText: 'Notification Number'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notificationDateController,
                decoration: const InputDecoration(labelText: 'Notification Date'),
                readOnly: true,
                onTap: () => _selectDate(context, 'notification'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _startDateController,
                decoration: const InputDecoration(labelText: 'Start Date'),
                readOnly: true,
                onTap: () => _selectDate(context, 'start'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(labelText: 'End Date'),
                readOnly: true,
                onTap: () => _selectDate(context, 'end'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildRankField(),
              const SizedBox(height: 16),
              _buildBranchField(),
              const SizedBox(height: 16),

              TextFormField(
                controller: _requiredExperienceController,
                decoration: const InputDecoration(
                  labelText: 'Required Experience (Years)',
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _buildExperienceFromRankField(),
              const SizedBox(height: 16),

              TextFormField(
                controller: _otherCriteriaController,
                decoration: const InputDecoration(
                  labelText: 'Other Criteria',
                  hintText: 'Optional',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Create Opening'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 