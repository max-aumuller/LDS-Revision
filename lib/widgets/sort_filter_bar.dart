import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/data_browser_provider.dart';

class SortFilterBar extends StatefulWidget {
  const SortFilterBar({super.key});

  @override
  State<SortFilterBar> createState() => _SortFilterBarState();
}

class _SortFilterBarState extends State<SortFilterBar> {
  String? _selectedRangeField;
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataBrowserProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: provider.sortField,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(value: 'location', child: Text('Location')),
                        DropdownMenuItem(value: 'dailyMeanTemp', child: Text('Mean Temp')),
                        DropdownMenuItem(value: 'dailyTotalRainfall', child: Text('Rainfall')),
                        DropdownMenuItem(value: 'dailyMeanWindSpeed', child: Text('Wind Speed')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.sortBy(value);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(provider.ascending ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () => provider.sortBy(provider.sortField),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    value: provider.selectedLocation,
                    hint: const Text('All Locations'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Locations')),
                      DropdownMenuItem(value: 'Camborne', child: Text('Camborne')),
                      DropdownMenuItem(value: 'Heathrow', child: Text('Heathrow')),
                      DropdownMenuItem(value: 'Hurn', child: Text('Hurn')),
                      DropdownMenuItem(value: 'Leeming', child: Text('Leeming')),
                      DropdownMenuItem(value: 'Leuchars', child: Text('Leuchars')),
                      DropdownMenuItem(value: 'Beijing', child: Text('Beijing')),
                      DropdownMenuItem(value: 'Jacksonville', child: Text('Jacksonville')),
                      DropdownMenuItem(value: 'Perth', child: Text('Perth')),
                    ],
                    onChanged: (value) {
                      provider.filterByLocation(value);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String?>(
                      value: _selectedRangeField,
                      isExpanded: true,
                      hint: const Text('Filter by range...'),
                      items: const [
                        DropdownMenuItem(value: 'dailyMeanTemp', child: Text('Mean Temp')),
                        DropdownMenuItem(value: 'dailyTotalRainfall', child: Text('Rainfall')),
                        DropdownMenuItem(value: 'dailyMeanWindSpeed', child: Text('Wind Speed')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRangeField = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _minController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Min'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Max'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      final min = double.tryParse(_minController.text);
                      final max = double.tryParse(_maxController.text);
                      if (_selectedRangeField != null && min != null && max != null) {
                        provider.filterByRange(_selectedRangeField, min, max);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedRangeField = null;
                        _minController.clear();
                        _maxController.clear();
                      });
                      provider.filterByRange(null, null, null);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}