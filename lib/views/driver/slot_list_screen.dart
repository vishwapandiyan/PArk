import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/slot_controller.dart';
import '../../widgets/slot_card.dart';

class SlotListScreen extends StatefulWidget {
  const SlotListScreen({super.key});

  @override
  State<SlotListScreen> createState() => _SlotListScreenState();
}

class _SlotListScreenState extends State<SlotListScreen> {
  @override
  void initState() {
    super.initState();
    // In real app, pass current location
    context.read<SlotController>().fetchNearby(lat: 0, lng: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Slots')),
      body: BlocBuilder<SlotController, SlotState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(child: Text(state.errorMessage!));
          }
          if (state.slots.isEmpty) {
            return const Center(child: Text('No slots found'));
          }
          return ListView.builder(
            itemCount: state.slots.length,
            itemBuilder: (context, index) {
              final slot = state.slots[index];
              return SlotCard(
                slot: slot,
                onTap: () => Navigator.of(context).pushNamed('/slot_detail', arguments: slot),
              );
            },
          );
        },
      ),
    );
  }
}


