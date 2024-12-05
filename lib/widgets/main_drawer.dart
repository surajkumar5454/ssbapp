ListTile(
  leading: const Icon(Icons.business_center_outlined),
  title: const Text('e-DAS'),
  subtitle: const Text('Deputation Application System'),
  trailing: Consumer<DeputationService>(
    builder: (context, service, _) {
      if (!service.hasNewOpenings) return null;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${service.eligibleOpenings.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    },
  ),
  onTap: () => Navigator.pushNamed(context, '/deputation'),
), 